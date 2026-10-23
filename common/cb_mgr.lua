-- 模块变量热更时保留，不能写成 local，否则已注册的定时回调全丢
cb_global_id = 0

call_back_tbl = {}

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