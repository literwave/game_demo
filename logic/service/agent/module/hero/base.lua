
local saveFieldTbl = {
	_heroType = function ()
		return nil
	end,
	_userId = function ()
		return nil
	end,
	_exp = function ()
		return 0
	end,
	_level = function ()
		return 1
	end,
	_star = function ()
		return 1
	end,
	_equipTbl = function()
		return {}
		--[[
			[pos] = equipId,
		--]]
	end,
	_skillTbl = function ()
		return {
		}
		--[[
			[skillId] = skillLevel,
		]]
	end,
	_newTag = function ()
		return false
	end,
	_state = function ()
		return nil
	end,
}

clsHero = clsObject:Inherit()

function clsHero:__init__(oci)
	Super(clsHero).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function clsHero:saveField(keyList, val)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_HERO_COL, self._userId, self._heroType, table.unpack(keyList)}, val)
end

function clsHero:getUserId()
	return self._userId
end

function clsHero:serialize(tbl)
	for key, _ in pairs(saveFieldTbl) do
		tbl[key] = self[key]
	end
end

function clsHero:saveToDB()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_HERO_COL, self._userId, self._heroType}, info)
end

function clsHero:getNewTag()
	return self._newTag
end

function clsHero:setNewTag(newTag)
	self._newTag = newTag
	self:saveField({"_newTag"}, newTag)
end

function clsHero:getHeroType()
	return self._heroType
end

function clsHero:getStar()
	return self._star
end

function clsHero:getHeroPTOBaseInfo()
	local skillList = {}
	for skillId, skillLv in pairs(self._skillTbl) do
		table.insert(skillList, {
			k = skillId,
			v = skillLv,
		})
	end
	return {
		heroType = self._heroType,
		exp = self._exp,
		lv = self._level,
		star = self:getStar(),
		state = self._state or 0,
		skillList = skillList,
		newTag = self:getNewTag(),
	}
end

function clsHero:syncToClient()
	local fd = USER_MGR.getFdByUserId(self._userId)
	for_caller.s2c_sync_hero_base_info(fd, {heroInfo = self:getHeroPTOBaseInfo()})
end

function clsHero:getSkillTbl()
	return self._skillTbl
end

function clsHero:setSkillLv(skillId, skillLv)
	self._skillTbl[skillId] = skillLv
	self:saveField({"_skillTbl", skillId}, skillLv)
end