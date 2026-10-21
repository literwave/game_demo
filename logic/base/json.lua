-----------------------------------------------------------------------------
-- JSON4Lua: JSON encoding / decoding support for the Lua language.
-- json Module.
-- Author: Craig Mason-Jones
-- Homepage: http://github.com/craigmj/json4lua/
-- Version: 1.0.0
-- This module is released under the MIT License (MIT).
-- Please see LICENCE.txt for details.
--
-- USAGE:
-- This module exposes two functions:
--   json.encode(o)
--     Returns the table / string / boolean / number / nil / json.null value as a JSON-encoded string.
--   json.decode(json_string)
--     Returns a Lua object populated with the data encoded in the JSON string json_string.
--
-- REQUIREMENTS:
--   compat-5.1 if using Lua 5.0
--
-- CHANGELOG
--   0.9.20 Introduction of local Lua functions for private functions (removed _ function prefix). 
--          Fixed Lua 5.1 compatibility issues.
--      Introduced json.null to have null values in associative arrays.
--          json.encode() performance improvement (more than 50%) through table.concat rather than ..
--          Introduced decode ability to ignore /**/ comments in the JSON string.
--   0.9.10 Fix to array encoding / decoding to correctly manage nil/null values in arrays.
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Imports and dependencies
-----------------------------------------------------------------------------
local math = require('math')
local string = require("string")
local table = require("table")

-----------------------------------------------------------------------------
-- Module declaration
-----------------------------------------------------------------------------
local json = {}             -- Public namespace
local json_private = {}     -- Private namespace

-- Public functions

-- Private functions
local decode_scan_array
local decode_scan_comment
local decode_scan_constant
local decode_scan_number
local decode_scan_object
local decode_scan_string
local decode_scan_whitespace
local encode_string
local is_array
local is_encodable

-----------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-----------------------------------------------------------------------------
--- Encodes an arbitrary Lua object / variable.
-- @param v The Lua object / variable to be JSON encoded.
-- @return String containing the JSON encoding in internal Lua string format (i.e. not unicode)
function json.encode (v)
  -- Handle nil values
  if v==nil then
	return "null"
  end
  
  local vtype = type(v)

  -- Handle strings
  if vtype=='string' then    
	return '"' .. json_private.encode_string(v) .. '"'     -- Need to handle encoding in string
  end
  
  -- Handle booleans
  if vtype=='number' or vtype=='boolean' then
	return tostring(v)
  end
  
  -- Handle tables
  if vtype=='table' then
	local rval = {}
	-- Consider arrays separately
	local b_array, max_count = is_array(v)
	if b_array then
	  for i = 1,max_count do
	    table.insert(rval, json.encode(v[i]))
	  end
	else  -- An object, not an array
	  for i,j in pairs(v) do
	    if is_encodable(i) and is_encodable(j) then
	      table.insert(rval, '"' .. json_private.encode_string(i) .. '":' .. json.encode(j))
	    end
	  end
	end
	if b_array then
	  return '[' .. table.concat(rval,',') ..']'
	else
	  return '{' .. table.concat(rval,',') .. '}'
	end
  end
  
  -- Handle null values
  if vtype=='function' and v==null then
	return 'null'
  end
  
  assert(false,'encode attempt to encode unsupported type ' .. vtype .. ':' .. tostring(v))
end


--- Decodes a JSON string and returns the decoded value as a Lua data structure / value.
-- @param s The string to scan.
-- @param [startPos] Optional starting position where the JSON string is located. Defaults to 1.
-- @param Lua object, number The object that was scanned, as a Lua table / string / number / boolean or nil,
-- and the position of the first character after
-- the scanned JSON object.
function json.decode(s, start_pos)
  start_pos = start_pos and start_pos or 1
  start_pos = decode_scan_whitespace(s,start_pos)
  assert(start_pos<=string.len(s), 'Unterminated JSON encoded object found at position in [' .. s .. ']')
  local cur_char = string.sub(s,start_pos,start_pos)
  -- Object
  if cur_char=='{' then
	return decode_scan_object(s,start_pos)
  end
  -- Array
  if cur_char=='[' then
	return decode_scan_array(s,start_pos)
  end
  -- Number
  if string.find("+-0123456789.e", cur_char, 1, true) then
	return decode_scan_number(s,start_pos)
  end
  -- String
  if cur_char==[["]] or cur_char==[[']] then
	return decode_scan_string(s,start_pos)
  end
  if string.sub(s,start_pos,start_pos+1)=='/*' then
	return decode(s, decode_scan_comment(s,start_pos))
  end
  -- Otherwise, it must be a constant
  return decode_scan_constant(s,start_pos)
end

--- The null function allows one to specify a null value in an associative array (which is otherwise
-- discarded if you set the value with 'nil' in Lua. Simply set t = { first=json.null }
function null()
  return null -- so json.null() will also return null ;-)
end
-----------------------------------------------------------------------------
-- Internal, PRIVATE functions.
-- Following a Python-like convention, I have prefixed all these 'PRIVATE'
-- functions with an underscore.
-----------------------------------------------------------------------------

--- Scans an array from JSON into a Lua object
-- startPos begins at the start of the array.
-- Returns the array and the next starting position
-- @param s The string being scanned.
-- @param startPos The starting position for the scan.
-- @return table, int The scanned array as a table, and the position of the next character to scan.
function decode_scan_array(s,start_pos)
  local array = {}  -- The return value
  local string_len = string.len(s)
  assert(string.sub(s,start_pos,start_pos)=='[','decode_scanArray called but array does not start at position ' .. start_pos .. ' in string:\n'..s )
  start_pos = start_pos + 1
  -- Infinite loop for array elements
  repeat
	start_pos = decode_scan_whitespace(s,start_pos)
	assert(start_pos<=string_len,'JSON String ended unexpectedly scanning array.')
	local cur_char = string.sub(s,start_pos,start_pos)
	if (cur_char==']') then
	  return array, start_pos+1
	end
	if (cur_char==',') then
	  start_pos = decode_scan_whitespace(s,start_pos+1)
	end
	assert(start_pos<=string_len, 'JSON String ended unexpectedly scanning array.')
	object, start_pos = json.decode(s,start_pos)
	table.insert(array,object)
  until false
end

--- Scans a comment and discards the comment.
-- Returns the position of the next character following the comment.
-- @param string s The JSON string to scan.
-- @param int startPos The starting position of the comment
function decode_scan_comment(s, start_pos)
  assert( string.sub(s,start_pos,start_pos+1)=='/*', "decode_scanComment called but comment does not start at position " .. start_pos)
  local end_pos = string.find(s,'*/',start_pos+2)
  assert(end_pos~=nil, "Unterminated comment in string at " .. start_pos)
  return end_pos+2  
end

--- Scans for given constants: true, false or null
-- Returns the appropriate Lua type, and the position of the next character to read.
-- @param s The string being scanned.
-- @param startPos The position in the string at which to start scanning.
-- @return object, int The object (true, false or nil) and the position at which the next character should be 
-- scanned.
function decode_scan_constant(s, start_pos)
  local consts = { ["true"] = true, ["false"] = false, ["null"] = nil }
  local const_names = {"true","false","null"}

  for i,k in pairs(const_names) do
	if string.sub(s,start_pos, start_pos + string.len(k) -1 )==k then
	  return consts[k], start_pos + string.len(k)
	end
  end
  assert(nil, 'Failed to scan constant from string ' .. s .. ' at starting position ' .. start_pos)
end

--- Scans a number from the JSON encoded string.
-- (in fact, also is able to scan numeric +- eqns, which is not
-- in the JSON spec.)
-- Returns the number, and the position of the next character
-- after the number.
-- @param s The string being scanned.
-- @param startPos The position at which to start scanning.
-- @return number, int The extracted number and the position of the next character to scan.
function decode_scan_number(s,start_pos)
  local end_pos = start_pos+1
  local string_len = string.len(s)
  local acceptable_chars = "+-0123456789.e"
  while (string.find(acceptable_chars, string.sub(s,end_pos,end_pos), 1, true)
  and end_pos<=string_len
  ) do
	end_pos = end_pos + 1
  end
  local string_value = 'return ' .. string.sub(s,start_pos, end_pos-1)
  local string_eval = loadstring(string_value)
  assert(string_eval, 'Failed to scan number [ ' .. string_value .. '] in JSON string at position ' .. start_pos .. ' : ' .. end_pos)
  return string_eval(), end_pos
end

--- Scans a JSON object into a Lua object.
-- startPos begins at the start of the object.
-- Returns the object and the next starting position.
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return table, int The scanned object as a table and the position of the next character to scan.
function decode_scan_object(s,start_pos)
  local object = {}
  local string_len = string.len(s)
  local key, value
  assert(string.sub(s,start_pos,start_pos)=='{','decode_scanObject called but object does not start at position ' .. start_pos .. ' in string:\n' .. s)
  start_pos = start_pos + 1
  repeat
	start_pos = decode_scan_whitespace(s,start_pos)
	assert(start_pos<=string_len, 'JSON string ended unexpectedly while scanning object.')
	local cur_char = string.sub(s,start_pos,start_pos)
	if (cur_char=='}') then
	  return object,start_pos+1
	end
	if (cur_char==',') then
	  start_pos = decode_scan_whitespace(s,start_pos+1)
	end
	assert(start_pos<=string_len, 'JSON string ended unexpectedly scanning object.')
	-- Scan the key
	key, start_pos = json.decode(s,start_pos)
	assert(start_pos<=string_len, 'JSON string ended unexpectedly searching for value of key ' .. key)
	start_pos = decode_scan_whitespace(s,start_pos)
	assert(start_pos<=string_len, 'JSON string ended unexpectedly searching for value of key ' .. key)
	assert(string.sub(s,start_pos,start_pos)==':','JSON object key-value assignment mal-formed at ' .. start_pos)
	start_pos = decode_scan_whitespace(s,start_pos+1)
	assert(start_pos<=string_len, 'JSON string ended unexpectedly searching for value of key ' .. key)
	value, start_pos = json.decode(s,start_pos)
	object[key]=value
  until false -- infinite loop while key-value pairs are found
end

-- START SoniEx2
-- Initialize some things used by decode_scanString
-- You know, for efficiency
local escape_sequences = {
  ["\\t"] = "\t",
  ["\\f"] = "\f",
  ["\\r"] = "\r",
  ["\\n"] = "\n",
  ["\\b"] = "\b"
}
setmetatable(escape_sequences, {__index = function(t,k)
  -- skip "\" aka strip escape
  return string.sub(k,2)
end})
-- END SoniEx2

--- Scans a JSON string from the opening inverted comma or single quote to the
-- end of the string.
-- Returns the string extracted as a Lua string,
-- and the position of the next non-string character
-- (after the closing inverted comma or single quote).
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return string, int The extracted string as a Lua string, and the next character to parse.
function decode_scan_string(s,start_pos)
  assert(start_pos, 'decode_scanString(..) called without start position')
  local start_char = string.sub(s,start_pos,start_pos)
  -- START SoniEx2
  -- PS: I don't think single quotes are valid JSON
  assert(start_char == [["]] or start_char == [[']],'decode_scanString called for a non-string')
  --assert(startPos, "String decoding failed: missing closing " .. startChar .. " for string at position " .. oldStart)
  local t = {}
  local i,j = start_pos,start_pos
  while string.find(s, start_char, j+1) ~= j+1 do
	local oldj = j
	i,j = string.find(s, "\\.", j+1)
	local x,y = string.find(s, start_char, oldj+1)
	if not i or x < i then
	  i,j = x,y-1
	end
	table.insert(t, string.sub(s, oldj+1, i-1))
	if string.sub(s, i, j) == "\\u" then
	  local a = string.sub(s,j+1,j+4)
	  j = j + 4
	  local n = tonumber(a, 16)
	  assert(n, "String decoding failed: bad Unicode escape " .. a .. " at position " .. i .. " : " .. j)
	  -- math.floor(x/2^y) == lazy right shift
	  -- a % 2^b == bitwise_and(a, (2^b)-1)
	  -- 64 = 2^6
	  -- 4096 = 2^12 (or 2^6 * 2^6)
	  local x
	  if n < 0x80 then
	    x = string.char(n % 0x80)
	  elseif n < 0x800 then
	    -- [110x xxxx] [10xx xxxx]
	    x = string.char(0xC0 + (math.floor(n/64) % 0x20), 0x80 + (n % 0x40))
	  else
	    -- [1110 xxxx] [10xx xxxx] [10xx xxxx]
	    x = string.char(0xE0 + (math.floor(n/4096) % 0x10), 0x80 + (math.floor(n/64) % 0x40), 0x80 + (n % 0x40))
	  end
	  table.insert(t, x)
	else
	  table.insert(t, escape_sequences[string.sub(s, i, j)])
	end
  end
  table.insert(t,string.sub(j, j+1))
  assert(string.find(s, start_char, j+1), "String decoding failed: missing closing " .. start_char .. " at position " .. j .. "(for string at position " .. start_pos .. ")")
  return table.concat(t,""), j+2
  -- END SoniEx2
end

--- Scans a JSON string skipping all whitespace from the current start position.
-- Returns the position of the first non-whitespace character, or nil if the whole end of string is reached.
-- @param s The string being scanned
-- @param startPos The starting position where we should begin removing whitespace.
-- @return int The first position where non-whitespace was encountered, or string.len(s)+1 if the end of string
-- was reached.
function decode_scan_whitespace(s,start_pos)
  local whitespace=" \n\r\t"
  local string_len = string.len(s)
  while ( string.find(whitespace, string.sub(s,start_pos,start_pos), 1, true)  and start_pos <= string_len) do
	start_pos = start_pos + 1
  end
  return start_pos
end

--- Encodes a string to be JSON-compatible.
-- This just involves back-quoting inverted commas, back-quotes and newlines, I think ;-)
-- @param s The string to return as a JSON encoded (i.e. backquoted string)
-- @return The string appropriately escaped.

local escape_list = {
	['"']  = '\\"',
	['\\'] = '\\\\',
	['/']  = '\\/', 
	['\b'] = '\\b',
	['\f'] = '\\f',
	['\n'] = '\\n',
	['\r'] = '\\r',
	['\t'] = '\\t'
}

function json_private.encode_string(s)
 local s = tostring(s)
 return s:gsub(".", function(c) return escape_list[c] end) -- SoniEx2: 5.0 compat
end

-- Determines whether the given Lua type is an array or a table / dictionary.
-- We consider any table an array if it has indexes 1..n for its n items, and no
-- other data in the table.
-- I think this method is currently a little 'flaky', but can't think of a good way around it yet...
-- @param t The table to evaluate as an array
-- @return boolean, number True if the table can be represented as an array, false otherwise. If true,
-- the second returned value is the maximum
-- number of indexed elements in the array. 
function is_array(t)
  -- Next we count all the elements, ensuring that any non-indexed elements are not-encodable 
  -- (with the possible exception of 'n')
  local max_index = 0
  for k,v in pairs(t) do
	if (type(k)=='number' and math.floor(k)==k and 1<=k) then -- k,v is an indexed pair
	  if (not is_encodable(v)) then return false end -- All array elements must be encodable
	  max_index = math.max(max_index,k)
	else
	  if (k=='n') then
	    if v ~= table.getn(t) then return false end  -- False if n does not hold the number of elements
	  else -- Else of (k=='n')
	    if is_encodable(v) then return false end
	  end  -- End of (k~='n')
	end -- End of k,v not an indexed pair
  end  -- End of loop across all pairs
  return true, max_index
end

--- Determines whether the given Lua object / table / variable can be JSON encoded. The only
-- types that are JSON encodable are: string, boolean, number, nil, table and json.null.
-- In this implementation, all other types are ignored.
-- @param o The object to examine.
-- @return boolean True if the object should be JSON encoded, false if it should be ignored.
function is_encodable(o)
  local t = type(o)
  return (t=='string' or t=='boolean' or t=='number' or t=='nil' or t=='table') or (t=='function' and o==null) 
end

return json
