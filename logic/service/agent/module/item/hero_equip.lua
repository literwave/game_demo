
local saveKeyTbl = {
	_strengthenLv = function()
		return 0
	end,
	_strengthenExp = function ()
		return 0
	end,
	_forgeLv = function ()
		return 0
	end,
	_putOnHeroType = function()
		return nil
	end,
}

clsItem = CLS_BASE_ITEM.clsItem:Inherit()

function clsItem:__init__(oci)
	Super(clsItem).__init__(self, oci)
	for k, func in pairs(saveKeyTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function clsItem:serialize(tbl)
	Super(clsItem).serialize(self, tbl)
	for key, _ in pairs(saveKeyTbl) do
		tbl[key] = self[key]
	end
end

function clsItem:getItemPTOInfo()
	local info = {
		itemId = self:getItemId(),
		itemType = self:getItemType(),
		itemCnt = self:getCnt(),
		strengthenLv = self._strengthenLv,
		strengthenExp = self._strengthenExp,
		forgeLv = self._forgeLv,
	}
	return info
end

function clsItem:syncToClient()
	local info = self:getItemPTOInfo()
	local vfd = USER_MGR.getVfdByUserId(self._userId)
	if vfd then
		for_caller.c_up_hero_equip_data(vfd, {info})
	end
end

function clsItem:setPutOnHeroType(heroType)
	self._putOnHeroType = heroType
	self:saveField({"_putOnHeroType"}, self._putOnHeroType)
end

function clsItem:getPutOnHeroType()
	return self._putOnHeroType
end

function clsItem:getStrengthenLv()
	return self._strengthenLv
end

function clsItem:setStrengthenLv(strengthenLv)
	self._strengthenLv = strengthenLv
	self:saveField({"_strengthenLv"}, self._strengthenLv)
end

function clsItem:getStrengthenExp()
	return self._strengthenExp
end

function clsItem:setStrengthenExp(strengthenExp)
	self._strengthenExp = strengthenExp
	self:saveField({"_strengthenExp"}, self._strengthenExp)
end

function clsItem:getForgeLv()
	return self._forgeLv
end

function clsItem:setForgeLv(forgeLv)
	self._forgeLv = forgeLv
	self:saveField({"_forgeLv"}, self._forgeLv)
end

function clsItem:getLv()
	return self._strengthenLv
end

function clsItem:getPower()
	local strengthenPower = DATA_COMMON.getItemStrengthenPower(self._strengthenLv, self:getEquipQuality()) or 0
	local forgePower = DATA_COMMON.getItemForgePower(self._forgeLv) or 0
	return strengthenPower + forgePower
end

function clsItem:getAtt()
	local baseAtt = DATA_COMMON.getItemAtt(self:getItemType()) or 0
	local levelAtt = DATA_COMMON.getItemLevelAtt(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self._forgeLv) or 0
	return (baseAtt + levelAtt) * (1 + forgeAdd)
end

function clsItem:getDef()
	local baseDef = DATA_COMMON.getItemDef(self:getItemType()) or 0
	local levelDef = DATA_COMMON.getItemLevelDef(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self._forgeLv) or 0
	return (baseDef + levelDef) * (1 + forgeAdd)
end

function clsItem:getLife()
	local baseLife = DATA_COMMON.getItemLife(self:getItemType()) or 0
	local levelLife = DATA_COMMON.getItemLevelLife(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self._forgeLv) or 0
	return (baseLife + levelLife) * (1 + forgeAdd)
end

function clsItem:getLethality()
	local baseLethality = DATA_COMMON.getItemLethality(self:getItemType()) or 0
	local levelLethality = DATA_COMMON.getItemLevelLethality(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self._forgeLv) or 0
	return (baseLethality + levelLethality) * (1 + forgeAdd)
end

function clsItem:getEquipQuality()
	return DATA_COMMON.getEquipQuality(self._itemType)
end
