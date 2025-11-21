
local cjson = require "cjson"
print("11")
local cjson2 = cjson.new()
local lua_object = {
	["name"] = "1231"
}
print(cjson2.encode(lua_object))
