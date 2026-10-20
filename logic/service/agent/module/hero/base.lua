clsHero = clsObject:Inherit()

function clsHero:__init__(oci)
	Super(clsHero).__init__(self, oci)
	if ORM.is_cls(oci, ORM.CLS_HERO_DATA) then
		self._data = oci
	else
		self._data = ORM.create(ORM.CLS_HERO_DATA, oci)
	end
	ORM.put(MONGO_SLAVE.COL.USER_HERO, self._data._userId, "_heroes", self._data._heroType, self._data)
end

function clsHero:getUserId()
	return self._data._userId
end

function clsHero:getNewTag()
	return self._data._newTag
end

function clsHero:setNewTag(newTag)
	self._data._newTag = newTag and true or false
end

function clsHero:getHeroType()
	return self._data._heroType
end

function clsHero:getStar()
	return self._data._star
end

function clsHero:getHeroPTOBaseInfo()
	local skillList = {}
	for skillId, skillLv in pairs(self._data._skillTbl) do
		table.insert(skillList, {
			k = skillId,
			v = skillLv,
		})
	end
	return {
		heroType = self._data._heroType,
		exp = self._data._exp,
		lv = self._data._level,
		star = self:getStar(),
		state = self._data._state or 0,
		skillList = skillList,
		newTag = self:getNewTag(),
	}
end

function clsHero:syncToClient()
	local fd = USER_MGR.getFdByUserId(self:getUserId())
	for_caller.s2c_sync_hero_base_info(fd, {heroInfo = self:getHeroPTOBaseInfo()})
end

function clsHero:getSkillTbl()
	return self._data._skillTbl
end

function clsHero:setSkillLv(skillId, skillLv)
	self._data._skillTbl[skillId] = skillLv
end

function clsHero:getEquipTbl()
	return self._data._equipTbl
end
