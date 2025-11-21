
local loadstring = rawget(_G, "loadstring") or load

g_pickle = {}
function g_pickle.eval(str)--注意,不能写变量名,后面直接为{},不能加上变量�?,因为return +变量�?会报�?
	if type(str) == "string" then
	    return loadstring("return " .. str)()
	elseif type(str) == "number" then
	    return loadstring("return " .. tostring(str))()
	else
	    error("is not a string")
	end
end

--misc tabletostr 没空去比较这两具函数
function g_pickle.serializeTable(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or true
	depth = depth or 0
	local tmp = string.rep("", depth)
	if name then 
	  if type(name) == "number" then
	      tmp = tmp ..'['.. name .. "]=" 
	  else
	      if string.byte(name,1,1) < 58 and string.byte(name,1,1) >47 then 
	          tmp = tmp .. string.format("[\"%s\"]=", name) --不要用\',这样就存不进数据库了,因为又有'号双�?号数据库语句识别不了
	      else
	          tmp = tmp .. name .. "=" 
	      end
	  end
	end
	if type(val) == "table" then
	    tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
	    for k, v in pairs(val) do
	        tmp =  tmp .. g_pickle.serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
	    end
	    tmp = tmp .. string.rep("", depth) .. "}"
	elseif type(val) == "number" then
	    tmp = tmp ..tostring(val)
	elseif type(val) == "string" then
	    tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
	    tmp = tmp .. (val and "true" or "false")
	else
	    tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
	end
	return tmp
end

function lambda(lambda_string,argument)
--验证是否仅存在一个：�?
	pos = string.find(lambda_string,":")
	if pos ~= nil then
	    if string.find(lambda_string,":",pos+1)~= nil then
	        error('more than one ":"')
	     end
	end
	if type(lambda_string) ~= "string" then
	    error("is not a string")
	end
	--lambda x:x+x 将其分割�?参数 x �?表达�?x+x 的形�?
	parameter = string.sub(lambda_string,1,pos-1)
	expression = string.sub(lambda_string,pos+1,-1)
	--根据需要可以更详细的对参数进行验证，这里就不做�?
	fun = string.format("return function(%s) return %s end",parameter,expression)
	print (fun)
	func = loadstring(fun)()(loadstring("return " .. tostring(argument))())
end


