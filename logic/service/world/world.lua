local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.fork(skynet.exit)
end

function CMD.hot_update(_, path_list)
	return hot_update(path_list)
end

function CMD.sync_to_map(oci)
	ENTITY_MGR.sync_to_map(oci)
end

function CMD.alloc_birth_pos()
	return MAP_MGR.alloc_birth_pos()
end

function CMD.upsert_city(_, user_id, x, y)
	AOI_MGR.upsert_city(user_id, x, y)
end

function CMD.find_march_path(_, sx, sy, ex, ey)
	return MAP_MGR.find_march_path(sx, sy, ex, ey)
end

function CMD.start_march(_, info)
	return AOI_MGR.start_march(info)
end

function CMD.remove_troop(_, user_id, troop_idx)
	AOI_MGR.remove_troop(user_id, troop_idx)
end

function CMD.monster_pos(_, entity_id)
	return AOI_MGR.monster_pos(entity_id)
end

function CMD.kill_monster(_, entity_id)
	return AOI_MGR.kill_monster(entity_id)
end

function CMD.aoi_focus(_, user_id, x, y)
	return AOI_MGR.focus(user_id, x, y)
end

skynet.start(function()
	skynet.error("boot world success")
	dofile "../logic/service/world/preload.lua"
	skynet.dispatch("lua", function (session, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				f(address, ...)
			end
		end
	end)
	skynet.register(".world")
end)
