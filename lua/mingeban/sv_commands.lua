
-- initialize helper functions

local checkParam = mingeban.utils.checkParam

local Argument = mingeban.objects.Argument
local Command = mingeban.objects.Command

-- command registering process

function mingeban.CreateCommand(name, callback)
	checkParam(callback, "function", 2, "CreateCommand")

	if not istable(name) then checkParam(name, "string", 1, "CreateCommand") end

	if istable(name) then
		for cmdName, cmdData in next, mingeban.commands do
			if istable(cmdName) then
				for _, _cmdName in next, name do
					if table.HasValue(cmdName, _cmdName) then
						mingeban.commands[cmdName] = nil
						break
					end
				end
			end
		end
	end
	mingeban.commands[name] = setmetatable({
		callback = callback, -- caller, line, ...
		args = {},
		name = istable(name) and name[1] or name,
		aliases = istable(name) and name or nil
	}, Command)

	mingeban.NetworkCommands()

	return mingeban.commands[name]
end
mingeban.AddCommand = mingeban.CreateCommand

-- command handling

util.AddNetworkString("mingeban_cmderror")

local function cmdError(ply, reason)
	-- PrintTable(debug.getinfo(2))
	if not IsValid(ply) then
		mingeban.utils.print(mingeban.colors.Red, reason)
		return
	end

	net.Start("mingeban_cmderror")
		net.WriteString(reason or "")
	net.Send(ply)
end

local mingeban_unknowncmd_notify = CreateConVar("mingeban_unknowncmd_notify", "0", { FCVAR_ARCHIVE })
function mingeban.RunCommand(name, caller, line)
	checkParam(name, "string", 1, "RunCommand")
	checkParam(line, "string", 3, "RunCommand")

	local cmd = mingeban.GetCommand(name)
	if not cmd then
		if not IsValid(caller) or mingeban_unknowncmd_notify:GetBool() then
			cmdError(caller, "Unknown command.")
		end
		return false
	end

	if IsValid(caller) then
		local hasPermission = caller:HasPermission("command." .. cmd.name)
		if type(caller) == "Player" and not hasPermission and not caller:GetRank().root then
			cmdError(caller, "Insufficient permissions.")
			return false
		end
	else
		if cmd.allowConsole == false then
			cmdError(caller, "Command \"" .. cmd.name .. "\" unusable from console.")
			return false
		end
	end

	local args
	if #cmd.args > 0 then
		args = mingeban.utils.parseArgs(line)

		local neededArgs = 0
		for _, arg in next, cmd.args do
			if not arg.optional and arg.type ~= ARGTYPE_VARARGS then neededArgs = neededArgs + 1 end
		end

		local syntax = mingeban.GetCommandSyntax(name)
		if neededArgs > #args then
			cmdError(caller, name .. " syntax: " .. syntax)
			return false
		end

		mingeban.CurrentPlayer = caller

		for k, arg in next, args do
			local argData = cmd.args[k] or (cmd.args[#cmd.args].type == ARGTYPE_VARARGS and cmd.args[#cmd.args] or nil)
			if argData then
				local funcArg = arg

				if (argData.type == ARGTYPE_STRING or argData.type == ARGTYPE_VARARGS) and funcArg:Trim() == "" then
					funcArg = nil

				elseif argData.type == ARGTYPE_NUMBER then
					funcArg = tonumber(arg:Trim():lower())

				elseif argData.type == ARGTYPE_BOOLEAN then
					funcArg = tobool(arg:Trim():lower())

				elseif argData.type == ARGTYPE_PLAYER then
					funcArg = mingeban.utils.findPlayer(arg)[1]

				elseif argData.type == ARGTYPE_PLAYERS then
					funcArg = mingeban.utils.findPlayer(arg)

				elseif argData.type == ARGTYPE_ENTITY then
					funcArg = mingeban.utils.findEntity(arg)[1]

				elseif argData.type == ARGTYPE_ENTITIES then
					funcArg = mingeban.utils.findEntity(arg)

				end

				if argData.filter then
					if istable(funcArg) then
						local newArg = {}
						for k, arg in next, funcArg do
							local filterRet = argData.filter(caller, arg)
							newArg[#newArg + 1] = filterRet and funcArg[k] or nil
						end
						funcArg = newArg
					else
						local filterRet = argData.filter(caller, funcArg)
						funcArg = filterRet and funcArg or nil
					end
				end

				local endsWithVarargs = cmd.args[#cmd.args].type == ARGTYPE_VARARGS
				if funcArg == nil and not endsWithVarargs then
					cmdError(caller, name .. " syntax: " .. syntax)
					return false
				end

				if istable(funcArg) and #funcArg < 1 then
					cmdError(caller, "Couldn't find any " .. (argData.type == ARGTYPE_PLAYERS and "players" or "entities") .. ".")
					return false
				end

				if funcArg ~= nil then
					args[k] = funcArg
				elseif endsWithVarargs then
					args[k] = args[k]
				else
					args[k] = nil
				end
			else
				args[k] = nil
			end
		end
	end

	if type(caller) == "Player" and cmd.argRankCheck then
		for k, v in next, args do
			if type(v) == "Player" then
				if not caller:CheckUserGroupLevel(v:GetUserGroup()) then
					cmdError(caller, "Can't target " .. v:Nick() .. ".")
					return false
				end
			elseif type(v) == "table" then
				local plyNames = {}
				for k, ply in next, v do
					if ply:IsPlayer() and not caller:CheckUserGroupLevel(ply:GetUserGroup()) then
						plyNames[#plyNames + 1] = ply:Nick()
						v[k] = nil
					end
				end
				if #plyNames > 0 then
					cmdError(caller, "Can't target " .. table.concat(plyNames, ", ") .. ".")
				end
			end
		end
	end

	local ok, reason = hook.Run("MingebanCommand", caller, name, line, unpack(args or {}))
	if ok == false then
		cmdError(caller, reason)
		return false
	end

	local ok2, err2
	local ok, err = pcall(function()
		ok2, err2 = cmd.callback(IsValid(caller) and caller or NULL, line, unpack(args or {}))
	end)

	mingeban.CurrentPlayer = nil

	if not ok then
		ErrorNoHalt(err .. "\n")
		cmdError(caller, "command lua error: " .. err)
		return false
	elseif ok2 == false then
		cmdError(caller, err2)
		return false
	end

	if cmd.hideChat then return "" end
end
mingeban.CallCommand = mingeban.RunCommand

--[[

local testargsCmd = mingeban.CreateCommand("testargs", function(caller, line, ...)
	print("Line: " .. line)
	print("Arguments: ")
	for k, v in next, { ... } do
		print("\t", v, type(v))
	end
end)

testargsCmd:AddArgument(ARGTYPE_STRING)
testargsCmd:AddArgument(ARGTYPE_NUMBER)
testargsCmd:AddArgument(ARGTYPE_BOOLEAN)
testargsCmd:AddArgument(ARGTYPE_PLAYER)
testargsCmd:AddArgument(ARGTYPE_PLAYERS)
testargsCmd:AddArgument(ARGTYPE_VARARGS)

]]

-- networking

util.AddNetworkString("mingeban_getcommands")

function mingeban.NetworkCommands(ply)
	assert(ply == nil or (IsValid(ply) and ply:IsPlayer()), "bad argument #1 to 'NetworkCommands' (invalid SteamID)")

	timer.Create("mingeban_networkcommands", 1, 1, function()
		net.Start("mingeban_getcommands")
			local commands = table.Copy(mingeban.commands)
			for name, _ in next, commands do
				for k, v in next, commands[name] do
					if isfunction(v) then
						commands[name][k] = nil
					end
				end
				for _, arg in next, commands[name].args do
					for k, v in next, arg do
						if isfunction(v) then
							arg[k] = nil
						end
					end
				end
			end
			net.WriteTable(commands)
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end)
end

hook.Add("PlayerInitialSpawn", "mingeban_commands", function(ply)
	mingeban.NetworkCommands(ply)
end)

-- commands running by chat or console

util.AddNetworkString("mingeban_runcommand")

net.Receive("mingeban_runcommand", function(_, ply)
	local cmd = net.ReadString()
	local args = net.ReadString()
	mingeban.RunCommand(cmd, ply, args)
end)

concommand.Add("mingeban", function(ply, _, cmd, line)
	local cmd = cmd[1]
	if not cmd then return end

	local args = line:Split(" ")
	table.remove(args, 1)
	args = table.concat(args, " "):Trim()
	mingeban.RunCommand(cmd, ply, args)
end)

-- load commands

for _, file in next, (file.Find("mingeban/commands/*.lua", "LUA")) do
	AddCSLuaFile("mingeban/commands/" .. file)
	include("mingeban/commands/" .. file)
end

hook.Add("PlayerSay", "mingeban_commands", function(ply, txt)
	local prefix = txt:match(mingeban.utils.CmdPrefix)

	if prefix then
		local cmd = txt:Split(" ")
		cmd = cmd[1]:sub(prefix:len() + 1):lower()

		local args = txt:sub(prefix:len() + 1 + cmd:len() + 1)

		local result = mingeban.RunCommand(cmd, ply, args)
		if result == "" then return "" end
	end
end)

if istable(GAMEMODE) then
	mingeban.NetworkCommands()
end

