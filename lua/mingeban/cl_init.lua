
include("cl_ranks.lua")
include("cl_commands.lua")

hook.Add("Initialize", "mingeban_initialize", function()
	timer.Simple(1, function()
		hook.Run("MingebanInitialized")
	end)
end)

MsgC(Color(127, 255, 127), "[mingeban] ") MsgC(Color(255, 255, 255), "Client side loaded\n")

