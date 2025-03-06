-- beepboop.nvim lets users add sound effects on cues to Neovim
---@module 'beepboop'

---@class BeepBoop
---@field state State
---@field enable fun()
---@field disable fun()
---@field toggle fun()
local M = {}

---@param opts Config? BeepBoop configuration
---@return BeepBoop
M.setup = function(opts)
	M.state = require("beepboop.state")
	vim.validate({ opts = { opts, 'table' } })
	M.state.config = vim.tbl_deep_extend("force", M.state.config, opts or {})

	M.state.config = require("beepboop.validate").validate_config(M.state.config)

	vim.api.nvim_create_augroup("beepboop", {
		clear = true
	})

	M.state.companion:initialize(M.state.config)
	M.state.companion:load_sound_files(M.state.config)

	M.play("chestopen")

	return M
end

---@param trigger_name string Name of audio trigger
M.play = function(trigger_name)
	vim.validate({ trigger_name = { trigger_name, "string" } })
	M.state.companion:play_sound(trigger_name)
end

M.enable = function ()
	M.state.enabled = true
end

M.disable = function ()
	M.state.enabled = true
end

M.toggle = function ()
	M.state.enabled = not M.state.enabled
end

return M
