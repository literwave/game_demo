local skynet = require "skynet"
local snax = require "skynet.snax"
local protobuf = require "protobuf"
-- local posix = require "posix"

skynet.start(function()

  local ppath = skynet.getenv("ppath")
  --待修�?会使用posix 去遍历文�?相关接口 stat file
  -- 暂时使用字符串连接的方式
	local files = {
	  ppath.."login.pb",
	  ppath.."chat.pb"
	}
	for _,file in ipairs(files) do 
	    --skynet.error("注册协议文件�?..file)
	    protobuf.register_file(file)
	end
end)
