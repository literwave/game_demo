
function string.split(input, delimiter)
	input = tostring(input)
	delimiter = tostring(delimiter)
	if (delimiter=='') then return false end
	local pos,arr = 0, {}
	for st,sp in function() return string.find(input, delimiter, pos, true) end do
	    table.insert(arr, string.sub(input, pos, st - 1))
	    pos = sp + 1
	end
	table.insert(arr, string.sub(input, pos))
	return arr
end

function string.splitkey(input, delimiter) --规则:自动识别Int�?Split第一个值如果为数值就为Int,Key嘛~
	input = tostring(input)
	delimiter = tostring(delimiter)
	if (delimiter=='') then return false end
	local pos,arr = 0, {}
	local s
	for st,sp in function() return string.find(input, delimiter, pos, true) end do
	  s = string.sub(input, pos, st - 1);
	  if string.byte(s,1,1) <= 57 then s = tonumber(s) end --如果第一个为Int就设置为Int
	    table.insert(arr, s)
	    pos = sp + 1
	end
	s = string.sub(input, pos)
	if string.byte(s,1,1) < 57 then s = tonumber(s) end
	table.insert(arr, s)
	return arr
end


function string.ltrim(input)
	return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
	return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
	input = string.gsub(input, "^[ \t\n\r]+", "")
	return string.gsub(input, "[ \t\n\r]+$", "")
end

