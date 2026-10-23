-- 单元测试入口：在项目根目录执行
--   skynet/3rd/lua/lua test/unit/run.lua [test_xxx.lua ...]
-- 不带参数跑 test/unit/ 下所有 test_*.lua。每个文件返回 {用例名 = function}

package.path = "lualib/?.lua;lualib/?/init.lua;test/unit/?.lua;" .. package.path
package.cpath = "skynet/luaclib/?.so;" .. package.cpath

local file_list = {...}
if #file_list == 0 then
	local p = io.popen("ls test/unit/test_*.lua")
	for line in p:lines() do
		file_list[#file_list + 1] = line
	end
	p:close()
end

local pass, fail = 0, 0
for _, file in ipairs(file_list) do
	local chunk, err = loadfile(file)
	if not chunk then
		print("FAIL load " .. file .. ": " .. err)
		fail = fail + 1
	else
		local ok, cases = pcall(chunk)
		if not ok then
			print("FAIL init " .. file .. ": " .. tostring(cases))
			fail = fail + 1
		else
			local name_list = {}
			for name in pairs(cases) do
				name_list[#name_list + 1] = name
			end
			table.sort(name_list)
			for _, name in ipairs(name_list) do
				local ok2, err2 = xpcall(cases[name], debug.traceback)
				if ok2 then
					pass = pass + 1
				else
					fail = fail + 1
					print(string.format("FAIL %s %s\n%s", file, name, err2))
				end
			end
		end
	end
end
print(string.format("unit tests: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
