--- Creates and executes user commands
--- @module 'commands'

---@class Commands
local M = {}

--- @param companion Companion
M.create_commands = function (companion)
	--- Mute
	vim.api.nvim_create_user_command("BeepBoopMute", function ()
		companion:mute()
	end, {})

	vim.api.nvim_create_user_command("BeepBoopUnmute", function ()
		companion:unmute()
	end, {})

	vim.api.nvim_create_user_command("BeepBoopToggleMute", function ()
		companion:toggle_mute()
	end, {})

	--- Volume
	--- Reload (maybe)
	vim.api.nvim_create_user_command("BeepBoopVolume", function (args)
		local result = tonumber(args.args)

		if type(result) == "number" then
			result = math.max(0, math.min(result, 100))
			companion:set_volume(result)
		else
			error("Usage: BeepBoopVolume {number 0 - 100})")
		end
	end, {})
end

return M
