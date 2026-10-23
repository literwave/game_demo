local skynet = require "skynet"
local P = require "bench_proto"

-- 一个服务跑一批机器人，每个机器人一个协程一条连接
-- 每个请求发出后等对应的回包再发下一个，延迟就是这一来一回的时间

local ACTION_LIST = {
	{"c2s_req_system_open", "s2c_req_system_open"},
	{"c2s_user_base_info", "s2c_user_base_info"},
	{"c2s_req_troop", "s2c_req_troop"},
	{"c2s_req_all_hero_base_info", "s2c_req_all_hero_base_info"},
}
local HEART_BEAT = {"c2s_heart_beat", "s2c_heart_beat"}
local LOAD_OK = {"c2s_client_load_ok", "s2c_client_load_ok"}
-- 服务端 15 秒没心跳会踢人
local HEART_BEAT_INTERVAL = 500

local CMD = {}
local conf
local stat = {
	login = {},
	req = {},
	req_cnt = 0,
	login_fail = 0,
	req_fail = 0,
	timeout = 0,
	errors = {},
}
local online = 0
local running = 0
local wait_co = nil
local pending = {}		-- [ws] = 发出时间 ms
local timed_out = {}

local function now_ms()
	return skynet.hpc() / 1e6
end

local function add_error(kind, err)
	stat[kind] = stat[kind] + 1
	local key = kind .. ": " .. string.sub(tostring(err), 1, 120)
	stat.errors[key] = (stat.errors[key] or 0) + 1
end

local function request(ws, action)
	local t = now_ms()
	pending[ws] = t
	P.send(ws, action[1])
	local ok, err = P.recv_until(ws, action[2])
	pending[ws] = nil
	if timed_out[ws] then
		return false, "timeout " .. action[1]
	end
	if not ok then
		return false, action[1] .. ": " .. tostring(err)
	end
	local list = stat.req[action[1]]
	if not list then
		list = {}
		stat.req[action[1]] = list
	end
	list[#list + 1] = now_ms() - t
	stat.req_cnt = stat.req_cnt + 1
	return true
end

local function sleep_interval()
	local cs = conf.interval_ms / 10
	skynet.sleep(math.max(1, math.floor(cs * (0.8 + math.random() * 0.4))))
end

local function run_bot(idx)
	local t = now_ms()
	local conn_list = {}
	local ws, user_id = P.login(conf.login_addr, conf.server_id, conf.prefix .. idx, conf.timeout_ms / 10, function(c)
		conn_list[#conn_list + 1] = c
		pending[c] = now_ms()
	end)
	for _, c in ipairs(conn_list) do
		pending[c] = nil
		timed_out[c] = nil
	end
	if not ws then
		add_error("login_fail", user_id)
		return
	end
	stat.login[#stat.login + 1] = now_ms() - t
	online = online + 1
	local ok, err = request(ws, LOAD_OK)
	local last_heart_beat = skynet.now()
	local action_idx = idx
	while ok and skynet.now() < conf.deadline do
		local action
		if skynet.now() - last_heart_beat >= HEART_BEAT_INTERVAL then
			action = HEART_BEAT
			last_heart_beat = skynet.now()
		else
			action_idx = action_idx % #ACTION_LIST + 1
			action = ACTION_LIST[action_idx]
		end
		ok, err = request(ws, action)
		if ok then
			sleep_interval()
		end
	end
	if not ok then
		add_error("req_fail", err)
	end
	online = online - 1
	timed_out[ws] = nil
	P.close(ws)
end

local function watchdog()
	while true do
		skynet.sleep(50)
		local now = now_ms()
		for ws, t in pairs(pending) do
			if now - t > conf.timeout_ms then
				pending[ws] = nil
				timed_out[ws] = true
				stat.timeout = stat.timeout + 1
				P.close(ws)
			end
		end
	end
end

-- delay_list[i] 是 idx_list[i] 的启动延迟（厘秒），用来均匀爬坡
function CMD.start(c, idx_list, delay_list)
	conf = c
	math.randomseed(os.time() + skynet.self())
	for i, idx in ipairs(idx_list) do
		running = running + 1
		skynet.fork(function()
			skynet.sleep(delay_list[i])
			local ok, err = pcall(run_bot, idx)
			if not ok then
				add_error("req_fail", err)
			end
			running = running - 1
			if running == 0 and wait_co then
				skynet.wakeup(wait_co)
			end
		end)
	end
	skynet.fork(watchdog)
end

function CMD.progress()
	return online, stat.req_cnt
end

function CMD.wait()
	if running > 0 then
		wait_co = coroutine.running()
		skynet.wait(wait_co)
	end
	return stat
end

skynet.start(function()
	P.init()
	skynet.dispatch("lua", function(session, _, cmd, ...)
		local f = assert(CMD[cmd], cmd)
		if session ~= 0 then
			skynet.ret(skynet.pack(f(...)))
		else
			f(...)
		end
	end)
end)
