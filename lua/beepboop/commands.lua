--- Creates and executes user commands

---@class Commands
local M = {}

--- @param companion Companion
M.create_commands = function (companion)
	vim.api.nvim_create_user_command("BeepboopMute", function ()
		companion:set_mute(true)
	end, {})

	vim.api.nvim_create_user_command("BeepboopUnmute", function ()
		companion:set_mute(false)
	end, {})

	vim.api.nvim_create_user_command("BeepboopToggleMute", function ()
		companion:toggle_mute()
	end, {})

	vim.api.nvim_create_user_command("BeepboopVolume", function (args)
		if #args.fargs == 0 then
			vim.print("[beepboop] Usage: BeepboopVolume {NUMBER 0-100})")
			return;
		end

		local result = tonumber(args.fargs[1])
		if result == nil then
			vim.print("[beepboop] Usage: BeepboopVolume {NUMBER 0-100})")
			return
		end

		result = math.max(0, math.min(result, 100))
		companion:set_volume(result)
	end, { nargs = 1 })

	vim.api.nvim_create_user_command("BeepboopTheme", function (args)
		if #args.fargs == 0 then
			vim.print("[beepboop] Usage: BeepboopTheme <THEME_URI>")
			return
		end

		local beepboop = require("beepboop")
		beepboop.state.config.theme = args.fargs[1]
		beepboop.setup(beepboop.state.config)
	end, { nargs = 1 })
end

return M
