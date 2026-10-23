cls_troop = cls_object:Inherit()

function cls_troop:__init__(oci)
	Super(cls_troop).__init__(self, oci)
	self._data = ORM.new(ORM.CLS_TROOP_DATA, oci)
	ORM.get(MONGO_SLAVE.COL.USER_TROOP, self._data._user_id)._troops[self._data._troop_idx] = self._data
	TROOP_MGR.ref_troop(self)
end

function cls_troop:get_user_id()
	return self._data._user_id
end

function cls_troop:get_troop_idx()
	return self._data._troop_idx
end

function cls_troop:get_pos_hero_tbl()
	return self._data._pos_hero_tbl
end

function cls_troop:set_pos_hero(pos, hero_idx)
	self._data._pos_hero_tbl[pos] = hero_idx
end

function cls_troop:clear_pos_hero()
	local pos_list = {}
	for pos in pairs(self:get_pos_hero_tbl()) do
		pos_list[#pos_list + 1] = pos
	end
	for _, pos in ipairs(pos_list) do
		self:set_pos_hero(pos, nil)
	end
end

function cls_troop:get_pto_info()
	local pos_hero_map = {}
	for pos, hero_idx in pairs(self:get_pos_hero_tbl()) do
		pos_hero_map[#pos_hero_map + 1] = {
			key = pos,
			value = hero_idx,
		}
	end
	return {
		troopIdx = self:get_troop_idx(),
		pos2HeroMap = pos_hero_map,
	}
end
