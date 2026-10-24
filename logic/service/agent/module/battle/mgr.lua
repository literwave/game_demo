local skynet = require "skynet"

-- 同一个目标固定进同一个战斗服务，多支部队打同一个目标时按顺序结算
local function battle_call(target_id, cmd, ...)
	local cnt = tonumber(skynet.getenv("battle_cnt")) or 1
	return skynet.call(".battle" .. (target_id % cnt + 1), "lua", cmd, ...)
end

local function troop_side(user, troop)
	local user_id = user:get_user_id()
	local units = {}
	for pos, info in pairs(troop:get_pos_tbl()) do
		local hero = HERO_MGR.get_hero_by_type(user_id, info._hero_idx)
		if hero then
			local skills = {}
			for skill_id, lv in pairs(hero:get_skill_tbl()) do
				skills[#skills + 1] = {id = skill_id, lv = lv}
			end
			table.sort(skills, function(a, b)
				return a.id < b.id
			end)
			units[#units + 1] = {
				pos = pos,
				kind = CONST.BATTLE_UNIT.HERO,
				cfg_id = info._hero_idx,
				level = hero:get_level(),
				soldier = info._soldier_cnt - info._hurt_cnt,
				count = info._soldier_cnt,
				hurt = info._hurt_cnt,
				skills = skills,
			}
		end
	end
	return {owner_id = user_id, name = user:get_name(), power = user:get_power(), units = units}
end

local function monster_side(group)
	local units = {}
	for _, m in ipairs(group.Monsters) do
		local conf = DATA_COMMON.get_monster_conf(m.mid)
		if conf then
			units[#units + 1] = {
				pos = m.pos,
				kind = CONST.BATTLE_UNIT.MONSTER,
				cfg_id = m.mid,
				level = conf.Level,
				soldier = conf.Soldier,
				count = conf.Soldier,
				hurt = 0,
			}
		end
	end
	return {owner_id = 0, name = group.Name, power = group.Power, units = units}
end

-- 损失的兵按 BATTLE_HURT_RATE 转伤兵，其余阵亡；返回各站位战后的 {count, hurt}
local function apply_troop_loss(troop, atk_left)
	local after = {}
	local changes = {}
	for pos, info in pairs(troop:get_pos_tbl()) do
		local left = atk_left[pos]
		if left then
			local lost = info._soldier_cnt - info._hurt_cnt - left
			local wounded = math.floor(lost * CONST.BATTLE_HURT_RATE / 100)
			changes[#changes + 1] = {
				pos = pos,
				hero_idx = info._hero_idx,
				count = info._soldier_cnt - (lost - wounded),
				hurt = info._hurt_cnt + wounded,
			}
		end
	end
	for _, c in ipairs(changes) do
		troop:set_pos(c.pos, c.hero_idx, c.count, c.hurt)
		after[c.pos] = {count = c.count, hurt = c.hurt}
	end
	return after
end

local function report_side(side, after)
	local units = {}
	for _, u in ipairs(side.units) do
		local a = after[u.pos] or {count = u.count, hurt = u.hurt}
		units[#units + 1] = {
			_pos = u.pos,
			_cfg_id = u.cfg_id,
			_level = u.level,
			_before_count = u.count,
			_before_hurt = u.hurt,
			_after_count = a.count,
			_after_hurt = a.hurt,
		}
	end
	return {_owner_id = side.owner_id, _name = side.name, _power = side.power, _units = units}
end

local function report_actions(actions)
	local list = {}
	for _, act in ipairs(actions) do
		local effects = {}
		for _, eff in ipairs(act.effects) do
			effects[#effects + 1] = {
				_target_side = eff.target_side,
				_target_pos = eff.target_pos,
				_value = eff.value,
				_after_soldier = eff.after_soldier,
				_flags = eff.flags,
			}
		end
		list[#list + 1] = {
			_round = act.round,
			_act_type = act.act_type,
			_from_side = act.from_side,
			_from_pos = act.from_pos,
			_skill_id = act.skill_id,
			_effects = effects,
		}
	end
	return list
end

local function battle_side_pto(side)
	local units = {}
	for _, u in ipairs(side.units) do
		units[#units + 1] = {
			pos = u.pos,
			cfgId = u.cfg_id,
			level = u.level,
			soldier = {count = u.count, hurtCount = u.hurt},
		}
	end
	return {ownerId = side.owner_id, name = side.name, power = side.power, units = units}
end

-- 部队到达野怪：打一场，赢了才击杀并发奖。部队状态已置为到达，回城由调用方处理
function attack_monster(user, troop)
	local user_id = user:get_user_id()
	local entity_id = troop:get_target_id()
	local pos = MARCH_MGR.world_call("monster_pos", entity_id)
	if not pos then
		USER_MGR.tell_me(user_id, "目标已消失")
		return
	end
	local group = DATA_COMMON.get_monster_group(pos.cfg_id)
	if not group then
		return
	end
	local atk = troop_side(user, troop)
	local def = monster_side(group)
	local res = battle_call(entity_id, "fight_batch", def, {atk})[1]
	local atk_after = apply_troop_loss(troop, res.atk_left)
	local def_after = {}
	for p, left in pairs(res.def_left) do
		def_after[p] = {count = left, hurt = 0}
	end
	local rewards = {}
	if res.result == CONST.BATTLE_RESULT.WIN and MARCH_MGR.world_call("kill_monster", entity_id) and group.Reward then
		for _, rw in ipairs(REWARD_MGR.reward_user(user_id, group.Reward, {CONST.FLOW_REASON.BATTLE, pos.cfg_id})) do
			rewards[#rewards + 1] = {_reward_type = rw.reward_type, _item_id = rw.item_id, _item_count = rw.item_count}
		end
	end
	local report = REPORT_MGR.add_report(user_id, {
		_report_type = CONST.REPORT_TYPE.ATTACK_MONSTER,
		_target_type = CONST.TARGET_TYPE.ATTACK_MONSTER,
		_target_id = pos.cfg_id,
		_result = res.result,
		_time = TIME.os_bj_sec(),
		_is_read = false,
		_x = pos.x,
		_y = pos.y,
		_atk_side = report_side(atk, atk_after),
		_def_side = report_side(def, def_after),
		_rewards = rewards,
		_max_round = res.max_round,
		_actions = report_actions(res.actions),
	})
	local fd = USER_MGR.get_fd_by_user_id(user_id)
	if not fd then
		return
	end
	for_caller.s2c_sync_troop(fd, {troopInfo = troop:get_pto_info()})
	local battle_id = report._report_id
	for_caller.s2c_battle_start(fd, {
		battleId = battle_id,
		reportType = report._report_type,
		targetType = report._target_type,
		targetId = report._target_id,
		pos = {x = pos.x, y = pos.y},
		atkSide = battle_side_pto(atk),
		defSide = battle_side_pto(def),
	})
	for_caller.s2c_battle_result(fd, {
		battleId = battle_id,
		result = res.result,
		reportId = report._report_id,
		rewardList = REPORT_MGR.reward_pto_list(report._rewards),
	})
end

-- 结算在到达时已经做完，跳过只是告诉客户端不用播了
local function on_battle_skip(fd, packet)
	if not USER_MGR.get_user_id_by_fd(fd) then
		return
	end
	for_caller.s2c_battle_skip(fd, {battleId = packet.battleId})
end

function __init__()
	for_maker.c2s_battle_skip = on_battle_skip
end
