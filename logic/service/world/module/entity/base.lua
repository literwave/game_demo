
local saveFieldTbl = {
}

clsEntity = clsObject:Inherit()

function clsEntity:__init__(oci)
	Super(clsEntity).__init__(self)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end
