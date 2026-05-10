--- Creates and executes user commands

---@class Commands
local M = {}

--- @param companion Companion
M.create_commands = function (companion)
	vim.api.nvim_create_user_command("BeepBoopMute", function ()
		companion:set_mute(true)
	end, {})

	vim.api.nvim_create_user_command("BeepBoopUnmute", function ()
		companion:set_mute(false)
	end, {})

	vim.api.nvim_create_user_command("BeepBoopToggleMute", function ()
		companion:toggle_mute()
	end, {})

	vim.api.nvim_create_user_command("BeepBoopVolume", function (args)
		if #args.fargs == 0 then
			vim.print("[beepboop] Usage: BeepBoopVolume {number 0 - 100})")
			return;
		end

		local result = tonumber(args.fargs[1])
		if result == nil then
			vim.print("[beepboop] Usage: BeepBoopVolume {number 0 - 100})")
			return
		end

		result = math.max(0, math.min(result, 100))
		companion:set_volume(result)
	end, { nargs = 1 })
end

return M
