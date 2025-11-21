
package.path = "./test/?.lua;" .. package.path

-- local new = {}
-- local func = loadfile("testa.lua", "bt", new)
-- print(func())
-- -- local new = {}
-- -- local z = setfenv(func, new)()
-- print(new)
-- for k, v in pairs(new) do
--     print(k, type(v))
-- end
local new = {}
setmetatable(new, {__index = _G})
loadfile("testa.lua", "bt", new)()

-- local new = {}
-- local z = setfenv(func, new)()
print(new.tedsta(2))
for k, v in pairs(new) do
	print(k, type(v))
end
-- print(new.tedsta())
loadfile("testa.lua", "bt", new)()
print(new.tedsta(1), "zzz")
for k, v in pairs(new) do
	print(k, type(v))
end
