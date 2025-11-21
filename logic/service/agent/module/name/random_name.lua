function getRandomName()
	local language = GAME.getCurLanguage()
	local firstNameList = DATA_COMMON.getFirstNameList(language)
	local lastNameList = DATA_COMMON.getLastNameList(language)
	local firstCnt = #firstNameList
	local lastCnt = #lastNameList
	local firstNameIdx = math.random(1, firstCnt)
	local lastNameIdx = math.random(1, lastCnt)
	local firstName = firstNameList[firstNameIdx].Txt
	local lastName = lastNameList[lastNameIdx].Txt
	return string.format("%s%s", lastName, firstName)
end

function genNewUserName()
	-- 这里如果重复了咋办, 随机的让他重复吧
	local name = getRandomName()
	if USER_NAME.checkNameExsist(name) then
		return string.format("%s%s", name)
	end
	return name
end
