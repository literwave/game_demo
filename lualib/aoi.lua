-- cloudwu/aoi 的 Lua 封装。半径在上游写死为 10，这里不能改。
-- mode："w" 观察者，"m" 被观察者，"wm" 两者都是，"d" 移除。
-- message() 返回本次进入视野的 {观察者 id, 被观察者 id}。
-- 距离小于 10 才会出现在结果里；10 到 20 记在内部，超过 20 直接丢掉。离开视野没有单独事件。

local core = require "aoi.c"

local M = {}

function M.new()
	return core.new()
end

return M
