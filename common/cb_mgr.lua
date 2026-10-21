local cb_global_id = 0

local call_back_tbl = {}

function fetch_callback_id(mod_name, func_name, ...)
	cb_global_id = cb_global_id + 1

	call_back_tbl[cb_global_id] = {
		mod_name = mod_name,
		func_name = func_name,
		param_tbl = {...},
	}

	return cb_global_id
end

function get_cb_info(id)
	return call_back_tbl[id]
end

function clear_cb_info(id)
	call_back_tbl[id] = nil
end