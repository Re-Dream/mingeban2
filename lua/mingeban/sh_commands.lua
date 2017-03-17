
local checkParam = mingeban.utils.checkParam
local accessorFunc = mingeban.utils.accessorFunc

mingeban.commands = {} -- intialize commands table

-- setup argument object

ARGTYPE_STRING  = 1
ARGTYPE_NUMBER  = 2
ARGTYPE_BOOLEAN = 3
ARGTYPE_PLAYER  = 4
ARGTYPE_PLAYERS = 5
ARGTYPE_VARARGS = 6

mingeban.argTypes = {
	[ ARGTYPE_STRING  ] = "string",
	[ ARGTYPE_NUMBER  ] = "number",
	[ ARGTYPE_BOOLEAN ] = "boolean",
	[ ARGTYPE_PLAYER  ] = "player",
	[ ARGTYPE_PLAYERS ] = "players",
	[ ARGTYPE_VARARGS ] = "varargs"
}

local Argument = {}
Argument.__index = Argument
accessorFunc(Argument, "Type", "type", CLIENT)
accessorFunc(Argument, "Name", "name", CLIENT)
accessorFunc(Argument, "Optional", "optional", CLIENT)
accessorFunc(Argument, "Filter", "filter", CLIENT)

mingeban.objects.Argument = Argument

-- setup command object, holds arguments

local Command = {}
Command.__index = Command
if SERVER then
	function Command:AddArgument(type)
		local arg = setmetatable({
			type = type,
		}, Argument)
		self.args[#self.args + 1] = arg
		return arg

	end
end
accessorFunc(Command, "Group", "group", CLIENT)

mingeban.objects.Command = Command
