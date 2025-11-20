local skynet = require "skynet"
require "skynet.manager"

local MONGODB = nil
local CMD = {}
function CMD.start()
	MONGODB = MONGO_OBJ.clsMongoDb:New()
end

function CMD.insert(args)
	MONGODB:insert(args)
end

function CMD.insertBatch(args)
	MONGODB:insertBatch(args)
end

function CMD.delete(args)
	MONGODB:delete(args)
end

function CMD.findOne(args)
	return MONGODB:findOne(args)
end

function CMD.update(args)
	MONGODB:update(args)
end

function CMD.save(data)
	local dataBase = GAME.getDataBase()
	local args = {
		database = dataBase
	}
	for _, allCmdTbl in pairs(data) do
		for col, cmdList in pairs(allCmdTbl) do
			args.collection = col
			for _, cmd in ipairs(cmdList) do
				args.selector = {["_id"] = cmd.key,}
				if cmd.opType == "delDoc" then
					MONGODB:delete(args)
				elseif cmd.opType == "$set" then
					local splitList = string.split(cmd.fieldStr, ".")
					local newValTbl = {}
					local current = newValTbl
					
					-- 构建嵌套结构
					for i = 1, #splitList - 1 do
						current[splitList[i]] = {}
						current = current[splitList[i]]
					end
					
					-- 设置最终值
					current[splitList[#splitList]] = cmd.value
					
					args.update = newValTbl
					args.upsert = true
					args.multi = false
					MONGODB:update(args)
				elseif cmd.opType == "$unset" then
					local splitList = string.split(cmd.fieldStr, ".")
					local newValTbl = {}
					local current = newValTbl
					
					-- 构建嵌套结构
					for i = 1, #splitList - 1 do
						current[splitList[i]] = {}
						current = current[splitList[i]]
					end
					
					-- 设置删除标记
					current[splitList[#splitList]] = ""
					
					args.update = newValTbl
					args.upsert = false
					args.multi = false
					MONGODB:update(args)
				end
			end
		end
	end
end

skynet.start(function()
	dofile "../logic/service/main_mongodb/preload.lua"
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register ".mongodb"
end)
