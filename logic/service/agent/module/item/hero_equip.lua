clsItem = CLS_BASE_ITEM.clsItem:Inherit()

function clsItem:__init__(oci)
	Super(clsItem).__init__(self, oci)
end

function clsItem:getItemPTOInfo()
	local d = self._data
	return {
		itemId = self:getItemId(),
		itemType = self:getItemType(),
		itemCnt = self:getCnt(),
		strengthenLv = d._strengthenLv,
		strengthenExp = d._strengthenExp,
		forgeLv = d._forgeLv,
	}
end

function clsItem:syncToClient()
	local info = self:getItemPTOInfo()
	local fd = USER_MGR.getFdByUserId(self:getUserId())
	if fd then
		for_caller.s2c_sync_item_data(fd, info)
	end
end

function clsItem:setPutOnHeroType(heroType)
	self._data._putOnHeroType = heroType or 0
	self:saveField("_putOnHeroType")
end

function clsItem:getPutOnHeroType()
	local v = self._data._putOnHeroType
	if v == 0 then
		return nil
	end
	return v
end

function clsItem:getStrengthenLv()
	return self._data._strengthenLv
end

function clsItem:setStrengthenLv(strengthenLv)
	self._data._strengthenLv = strengthenLv
	self:saveField("_strengthenLv")
end

function clsItem:getStrengthenExp()
	return self._data._strengthenExp
end

function clsItem:setStrengthenExp(strengthenExp)
	self._data._strengthenExp = strengthenExp
	self:saveField("_strengthenExp")
end

function clsItem:getForgeLv()
	return self._data._forgeLv
end

function clsItem:setForgeLv(forgeLv)
	self._data._forgeLv = forgeLv
	self:saveField("_forgeLv")
end

function clsItem:getLv()
	return self._data._strengthenLv
end

function clsItem:getPower()
	local strengthenPower = DATA_COMMON.getItemStrengthenPower(self:getStrengthenLv(), self:getEquipQuality()) or 0
	local forgePower = DATA_COMMON.getItemForgePower(self:getForgeLv()) or 0
	return strengthenPower + forgePower
end

function clsItem:getAtt()
	local baseAtt = DATA_COMMON.getItemAtt(self:getItemType()) or 0
	local levelAtt = DATA_COMMON.getItemLevelAtt(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self:getForgeLv()) or 0
	return (baseAtt + levelAtt) * (1 + forgeAdd)
end

function clsItem:getDef()
	local baseDef = DATA_COMMON.getItemDef(self:getItemType()) or 0
	local levelDef = DATA_COMMON.getItemLevelDef(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self:getForgeLv()) or 0
	return (baseDef + levelDef) * (1 + forgeAdd)
end

function clsItem:getLife()
	local baseLife = DATA_COMMON.getItemLife(self:getItemType()) or 0
	local levelLife = DATA_COMMON.getItemLevelLife(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self:getForgeLv()) or 0
	return (baseLife + levelLife) * (1 + forgeAdd)
end

function clsItem:getLethality()
	local baseLethality = DATA_COMMON.getItemLethality(self:getItemType()) or 0
	local levelLethality = DATA_COMMON.getItemLevelLethality(self:getItemType(), self:getStrengthenLv()) or 0
	local forgeAdd = DATA_COMMON.getItemForgeGradeAtt(self:getForgeLv()) or 0
	return (baseLethality + levelLethality) * (1 + forgeAdd)
end

function clsItem:getEquipQuality()
	return DATA_COMMON.getEquipQuality(self:getItemType())
end
