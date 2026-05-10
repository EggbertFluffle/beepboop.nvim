---@class BeepBoop
local M = {}

local config = require("beepboop.config")
local trigger = require("beepboop.trigger")
local commands = require("beepboop.commands")
local theme = require("beepboop.theme")
local health = require("beepboop.health")

---@param opts Config? BeepBoop configuration
---@return BeepBoop
M.setup = function(opts)
	vim.validate({ opts = { opts, 'table' } })

	M.state = require("beepboop.state")
	M.state.config = vim.tbl_deep_extend("force", config.default_config, opts or {})

	vim.api.nvim_create_augroup("beepboop_core", { clear = true })

	local config_suc, config_err = pcall(config.validate, M.state.config)
	if not config_suc then
		health.config_msg = config_err
		vim.print(config_err)
		return M
	end

	local companion_val_suc, companion_val_err = pcall(M.state.companion.validate, M.state.config)
	if not companion_val_suc then
		health.companion_val_msg = companion_val_err
		vim.print(companion_val_err)
		return M
	end

	local companion_init_suc, companion_init_err = pcall(M.state.companion.initialize, M.state.companion, M.state.config)
	if not companion_init_suc then
		health.companion_init_msg = companion_init_err
		vim.print(companion_init_err)
		return M
	end

	local load_sound_suc, load_sound_err = pcall(theme.load_sound_files, M.state.config.theme, M.state.companion)
	if not load_sound_suc then
		health.load_sound_msg = load_sound_err
		vim.print(load_sound_err)
		return M
	end

	local set_triggers_suc, set_triggers_err = pcall(trigger.set_theme_triggers, M.state.config.theme, M.state.companion)
	if not set_triggers_suc then
		health.set_triggers_msg = set_triggers_err
		vim.print(set_triggers_err)
		return M
	end

	commands.create_commands(M.state.companion)

	return M
end

---@param trigger_name string Name of audio trigger
M.play = function(trigger_name)
	vim.validate({ trigger_name = { trigger_name, "string" } })
	M.state.companion:play_sound(trigger_name)
end

M.mute = function ()
	M.state.companion:set_mute(true)
end

M.unmute = function ()
	M.state.companion:set_mute(false)
end

M.toggle_mute = function ()
	M.state.companion:toggle_mute()
end

---@param volume integer Volume of beepboop from 0 - 100
M.set_volume = function (volume)
	M.state.companion:set_volume(volume)
end

return M
