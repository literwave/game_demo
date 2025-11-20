Account = { b=0 }  

function Account.withdrow(v)
	Account.b = Account.b - v
end

Account.withdrow(100.0)

local z = {}

function tedsta(zz)
	z[1] = (z[1] or 0) + zz
	print(z[1])
	return true
end
-- a,Account = Account,nil
-- a = Account
-- Account = nil

-- a.withdrow(100.0)

-- for i,v in pairs(a) do
--     print(i)
--     print(v)
-- end

d = {}
-- print(e)
