Account = { b=0 }  

function Account.withdrow(v)
    Account.b = Account.b - v
end

Account.withdrow(100.0)

-- a,Account = Account,nil
a = Account   
Account = nil

a.withdrow(100.0)

for i,v in pairs(a) do
    print(i)
    print(v)
end

d = {}
e = d
d = nil


-- print(e)