-- 现在只做按照日志存的log文件，先不存分日志等级lv存相应的文件夹的设计

package.path = SERVICE_PATH.."?.lua;" .. package.path
local TimeFormat = os.date("[%Y/%m/%W/%X]:")
local skynet = require "skynet"

function log(...) --ͬ
	-- 先不用判断测试打印
    -- if not misc.IsTest() then return end;
	local arg = {...}
	local tem = "-:"; 
  local j = 1;
  for i,v in pairs(arg) do
    if type(v) == 'table' then
      tem = tem..table2str(v).."  ";
    else
      if v == "" then 
          tem = tem.."\"\"  ";
      else
          tem = tem..tostring(v).."  ";
      end
    end
      j = j+1;
  end
	print(tem);
	if tem then writefile(tem); end
	--skynet.error(tem);
	
end
function warn(...) log("****Warn***:",...) end;
function writefile(msg, mod)
    if not mod then mod = "a+" end;
	local fileName = logPath .. "/" .. "common_error_"..os.date("%Y%m%W")..".txt"
    local file = io.open(fileName, mod);
	-- 这样会复制三份字符串数据，优缺点，但先这样写，没有好的方案
	msg = TimeFormat .. msg
	-- skynet.error(msg)
    file:write(msg.."\n");
    file:close();
end

function table2str(...)--
	local arg = {...}
	local tem = "";
	for i,v in ipairs(arg) do
		if type(v) == 'table' then
			local bok = false
			tem = tem.."{"
			for i,value in pairs(v) do
				bok = true
		     	
		     	if type(value) == 'table' then
		     		tem =tem..tostring(i).."="..table2str(value);
		     	else
		     		tem =tem..tostring(i).."="..tostring(value)--..",\t";
		     	end
			end
			tem = tem.."} "
		else
		   if v == nil then
		   		tem = tem.."nil"--.."\t"
		   end
	       tem = tem..tostring(v)--.."\t";
	    end
	 end
	return tem
end

