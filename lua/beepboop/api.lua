--- All top level api for interacting with beepboop
--- @module 'api'

---@class BeepBoop
local M = {}

local config = require("beepboop.config")
local trigger = require("beepboop.trigger")

---@param opts Config? BeepBoop configuration
---@return BeepBoop
M.setup = function(opts)
	vim.validate({ opts = { opts, 'table' } })

	M.state = require("beepboop.state")
	M.state.config = vim.tbl_deep_extend("force", config.default_config, opts or {})

	vim.api.nvim_create_augroup("beepboop_core", { clear = true })

	config.validate(M.state.config)
	M.state.companion:initialize(M.state.config)
	trigger.set_theme_triggers(M.state.config.theme, M.state.companion)

	return M
end

---@param trigger_name string Name of audio trigger
M.play = function(trigger_name)
	vim.validate({ trigger_name = { trigger_name, "string" } })
	M.state.companion:play_sound(trigger_name)
end

M.enable = function ()
	M.state.config.enabled = true
end

M.disable = function ()
	M.state.config.enabled = true
end

M.toggle = function ()
	M.state.config.enabled = not M.state.config.enabled
end

---@param volume integer Volume of beepboop from 0 - 100
M.set_volume = function (volume)
	M.state.companion:set_volume(volume)
end

return M
