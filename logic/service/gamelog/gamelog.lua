local skynet = require "skynet"
require "skynet.manager"

-- 行由调用方 logic/base/log.lua 拼好，这里只负责按 (名字, 日期) 落文件
-- common_<level>_<yyyymmdd>.log：运行日志；flow_<kind>_<yyyymmdd>.log：资源流水

local LOG_PATH = skynet.getenv("logpath") or "../log"
local FLUSH_INTERVAL = 100	-- 1 秒
local CONSOLE_LEVEL_TBL = {
	info = true,
	warn = true,
	error = true,
}

local CMD = {}

-- [name] = {fh = file, date = "yyyymmdd"}
local file_tbl = {}
-- 关服后改成每行直接落盘，关服期间其他服务的日志也不丢
local is_flush_each_line = false

local function get_file(name)
	local date = os.date("%Y%m%d")
	local f = file_tbl[name]
	if f and f.date == date then
		return f.fh
	end
	if f then
		f.fh:close()
		file_tbl[name] = nil
	end
	local file_name = string.format("%s/%s_%s.log", LOG_PATH, name, date)
	local fh, err = io.open(file_name, "a")
	if not fh then
		skynet.error("gamelog open failed", file_name, err)
		return
	end
	fh:setvbuf("full")
	file_tbl[name] = {fh = fh, date = date}
	return fh
end

local function write_line(name, line, is_flush)
	local fh = get_file(name)
	if not fh then
		return
	end
	fh:write(line, "\n")
	if is_flush or is_flush_each_line then
		fh:flush()
	end
end

local function flush_all()
	for _, f in pairs(file_tbl) do
		f.fh:flush()
	end
end

function CMD.log(level, line)
	if CONSOLE_LEVEL_TBL[level] then
		print(line)
	end
	write_line("common_" .. level, line, level == "error")
end

function CMD.flow(kind, line)
	write_line("flow_" .. kind, line)
end

function CMD.flush()
	flush_all()
end

-- 不退出：关服流程后面还会有日志，进程由 http_agent abort 结束
function CMD.shutdown()
	flush_all()
	is_flush_each_line = true
end

local function flush_loop()
	while true do
		skynet.sleep(FLUSH_INTERVAL)
		flush_all()
	end
end

skynet.start(function()
	os.execute(string.format("mkdir -p %q", LOG_PATH))
	skynet.dispatch("lua", function(session, _, cmd, ...)
		local f = CMD[cmd]
		if not f then
			skynet.error("gamelog unknown cmd", cmd)
			if session ~= 0 then
				skynet.ret(skynet.pack(nil))
			end
			return
		end
		f(...)
		if session ~= 0 then
			skynet.ret(skynet.pack(true))
		end
	end)
	skynet.fork(flush_loop)
	skynet.register(".gamelog")
end)
