
mingeban.utils = {}
mingeban.colors = {
	Cyan = Color(127, 255, 255),
	Green = Color(127, 255, 127),
	Red = Color(255, 127, 127),
	Yellow = Color(255, 255, 127)
}

function mingeban.utils.print(color, ...)
	MsgC(color, "[mingeban] ") print(...)
end

function mingeban.utils.checkParam(param, typ, num, fnName)
	assert(type(param) == typ, "bad argument #" .. tostring(num) .. " to '" .. fnName .. "' (" .. typ .. " expected, got " .. type(param) .. ")")
end

mingeban.utils.CmdPrefix = "^[%$%.!/]"
mingeban.utils.CmdArgGrouper = "[\"']"
mingeban.utils.CmdArgSeparators = "[%s,]"
mingeban.utils.CmdEscapeChar = "[\\]"

function mingeban.utils.parseArgs(str) -- featuring no continues and better parsing than aowl!
	mingeban.utils.checkParam(str, "string", 1, "parseArgs")

	local chars = str:Split("")
	local grouping = false
	local escaping = false
	local grouper = false
	local separator = false
	local arg = ""
	local ret = {}

	for k, c in next, chars do
		local cont = true

		local before = chars[k - 1] -- check if there's anything behind the current char
		local after = chars[k + 1] -- check if there's anything after the current char

		if c:match(mingeban.utils.CmdEscapeChar) then
			escaping = true
			cont = false -- we're escaping a char, no need to continue
		end

		if cont then
			if ((arg ~= "" and grouping) or (arg == "" and not grouping)) and c:match(grouper or mingeban.utils.CmdArgGrouper) then -- do we try to group

				if not before or before and not escaping then -- are we escaping or starting a command
					if not grouper then
						grouper = c -- pick the current grouper
					end
					grouping = not grouping -- toggle group mode
					if arg ~= "" then
						ret[#ret + 1] = arg -- finish the job, add arg to list
						arg = "" -- reset arg
					end
					cont = false -- we toggled grouping mode
				elseif escaping then
					escaping = false -- we escaped the character, disable it
				end

			end

			if cont then
				if c:match(separator or mingeban.utils.CmdArgSeparators) and not grouping then -- are we separating and not grouping

					if not separator then
						separator = c -- pick the current separator
					end
					if before and not before:match(grouper or mingeban.utils.CmdArgGrouper) then -- arg ~= "" then
						ret[#ret + 1] = arg -- finish the job, add arg to list
						arg = "" -- reset arg
					end
					cont = false -- let's get the next arg going

				end

				if cont then
					arg = arg .. c -- go on with the arg
					if not after then -- in case this is the end of the sentence, add last thing written
						ret[#ret + 1] = arg
					end
				end

			end
		end

	end

	return ret -- give results!!
end

-- From original mingeban, could be useful
-- Written by Xaotic, optimized by Tenrys
function mingeban.utils.findEntity(str)
	mingeban.utils.checkParam(str, "string", 1, "findEntity")

	local found = {}
	str = str:Trim()
	local plys = player.GetAll()

	if str:StartWith("#") and str:len() > 1 then
		local tag = str:lower():sub(2)
		if tag == "all" then
			for _, ply in next, plys do
				found[#found + 1] = ply
			end
		elseif tag == "me" then
			found[#found + 1] = mingeban.CurrentPlayer
		elseif tag:StartWith("rank:") and tag:len() > 4 then
			local rank = tag:sub(4):lower()
			for _, ply in next, plys do
				if ply:GetUserGroup():lower() == rank then
					found[#found + 1] = ply
				end
			end
		elseif tag:StartWith("rankf:") and tag:len() > 4 then
			local rank = tag:sub(5):lower()
			for _, ply in next, plys do
				if ply:GetUserGroup():lower():match(rank) then
					found[#found + 1] = ply
				end
			end
		end
	end

	if IsValid(player.GetByUniqueID(str)) then
		found[#found + 1] = player.GetByUniqueID(str)
	end

	for _, ply in next, plys do
		if str:StartWith("STEAM_0:") then
			if ply:SteamID() == str:upper() then
				found[#found + 1] = ply
			end
		end

		if ply:Nick():lower():match(str:lower()) then
			found[#found + 1] = ply
		end
	end

	if str:StartWith("_") and str:len() > 1 then
		local ent = Entity(tonumber(str:sub(2)))
		if ent then
			found[#found + 1] = ent
		end
	end

	for _, ent in next, ents.GetAll() do
		--[[ might be needed?

		local nonum = str:gsub("(%d+)", "")
		if nonum == "" then
			nonum = nil
		end

		]]
		if ent:GetClass():match(str) then
			found[#found + 1] = ent
		end

		if ent:GetName():match(str) then
			found[#found + 1] = ent
		end

		if ent.GetModel and isstring(ent:GetModel()) and ent:GetModel():match(str) then
			found[#found + 1] = ent
		end
	end

	local foundNodupes = {}

	for _, ent in next, found do
		if not table.HasValue(foundNodupes, ent) then
			foundNodupes[#foundNodupes + 1] = ent
		end
	end

	return foundNodupes
end

function mingeban.utils.findPlayer(str)
	local results = mingeban.utils.findEntity(str)
	local plys = {}
	for _, ent in next, results do
		if ent:IsPlayer() then
			plys[#plys + 1] = ent
		end
	end
	return plys
end

function mingeban.utils.accessorFunc(tbl, keyName, key, noAddSet)
	-- noAddSet would be false for server, false for client
	-- so no Set function will be added
	if not noAddSet and not tbl["Set" .. keyName] then
		tbl["Set" .. keyName] = function(self, value)
			self[key] = value
			return self
		end
	end
	tbl["Get" .. keyName] = function(self)
		return self[key]
	end
end

