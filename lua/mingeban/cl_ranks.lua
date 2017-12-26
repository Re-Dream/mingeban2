
local Rank = mingeban.objects.Rank

net.Receive("mingeban_getranks", function()
	local ranks = net.ReadTable()
	local users = net.ReadTable()

	for level, rank in next, ranks do
		ranks[level] = setmetatable(rank, Rank)
	end

	mingeban.ranks = ranks
	mingeban.users = users
end)

