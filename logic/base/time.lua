TIME = {}

local offset = 0

function TIME.osBJSec()
	return os.time() + offset
end