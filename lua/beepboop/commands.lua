--- Creates and executes user commands

---@class Commands
local M = {}

--- @param companion Companion
M.create_commands = function (companion)
	local commands = {
		mute =  function ()
			companion:set_mute(true)
		end,
		unmute = function ()
			companion:set_mute(false)
		end,
		toggle_mute = function ()
			companion:toggle_mute()
		end,
		volume = function (args)
			if #args.fargs < 2 then
				vim.print("[beepboop] Usage: Beepboop volume {NUMBER 0-100}")
				return;
			end

			local result = tonumber(args.fargs[2])
			if result == nil then
				vim.print("[beepboop] Usage: Beepboop volume {NUMBER 0-100}")
				return
			end

			result = math.max(0, math.min(result, 100))
			companion:set_volume(result)
		end,
		theme = function (args)
			if #args.fargs < 2 then
				vim.print("[beepboop] Usage: BeepboopTheme <THEME_URI>")
				return
			end

			local beepboop = require("beepboop")
			beepboop.state.config.theme = args.fargs[2]
			beepboop.setup(beepboop.state.config)
		end
	}

	vim.api.nvim_create_user_command("Beepboop", function (args)
		if #args.fargs == 0 then
			vim.print("[beepboop] Usage: Beepboop <COMMAND>")
			return
		end

		commands[args.fargs[1]](args)
	end, {
		desc = "Access to commands for beepboop.nvim",
		nargs = "+",
		complete = function (arglead, _)
			local cmds = vim.tbl_keys(commands)

			return vim.tbl_filter(function (item)
				return item:find(arglead, 1, true) == 1
			end, cmds)
		end
	})
end

return M
