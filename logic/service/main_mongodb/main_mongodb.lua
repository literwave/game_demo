local skynet = require "skynet"
require "skynet.manager"

local MONGODB = nil
local CMD = {}

function CMD.shutdown()
	MONGODB:disconnect()
	skynet.exit()
end

function CMD.start()
	MONGODB = MONGO_OBJ.cls_mongo_db:New()
end

function CMD.insert(args)
	MONGODB:insert(args)
end

function CMD.insert_batch(args)
	MONGODB:insert_batch(args)
end

function CMD.delete(args)
	MONGODB:delete(args)
end

function CMD.find_one(args)
	return MONGODB:find_one(args)
end

function CMD.find_all(args)
	return MONGODB:find_all(args)
end

function CMD.update(args)
	MONGODB:update(args)
end

function CMD.save_data(all_cmd_tbl)
	local data_base = GAME.get_data_base()
	local args = {
		database = data_base
	}
	for col, cmd_list in pairs(all_cmd_tbl) do
		for _, cmd in ipairs(cmd_list) do
			args.collection = col
			args.selector = {["_id"] = cmd.key,}
			if cmd.op_type == "del_doc" then
				MONGODB:delete(args)
			elseif cmd.op_type == "$set" then
				local split_list = string.split(cmd.field_str, ".")
				local new_val_tbl = {}
				local current = new_val_tbl
				-- 构建嵌套结构
				for i = 1, #split_list - 1 do
					current[split_list[i]] = {}
					current = current[split_list[i]]
				end
				-- 设置最终值
				current[split_list[#split_list]] = cmd.value
				args.update = { ["$set"] = { [cmd.field_str] = cmd.value} }
				args.upsert = true
				args.multi = false
				MONGODB:update(args)
			elseif cmd.op_type == "$unset" then
				local split_list = string.split(cmd.field_str, ".")
				local new_val_tbl = {}
				local current = new_val_tbl
				
				-- 构建嵌套结构
				for i = 1, #split_list - 1 do
					current[split_list[i]] = {}
					current = current[split_list[i]]
				end
				-- 设置删除标记
				current[split_list[#split_list]] = ""
				args.update = new_val_tbl
				args.upsert = false
				args.multi = false
				MONGODB:update(args)
			end
		end
	end
end

skynet.start(function()
	dofile "../logic/service/main_mongodb/preload.lua"
	skynet.dispatch("lua", function(session, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			local ret = f(...)
			if session ~= 0 then
				skynet.ret(skynet.pack(ret))	
			end
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register ".mongodb"
end)
