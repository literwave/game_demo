
local saveFieldTbl = {
	_heroType = function ()
		return nil
	end,
	_userId = function ()
		return nil
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
	return {
		heroType = self._heroType,
		lv = self._lv,
		star = self:getStar(),
		newTag = self:getNewTag(),
	}
end

function clsHero:syncToClient()
	local fd = USER_MGR.getFdByUserId(self._userId)
	for_caller.s2c_sync_hero_base_info(fd, self:getHeroPTOBaseInfo())
end