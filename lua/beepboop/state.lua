---Holds all the state necessary for the plugin to run
---@module 'state'

---@class State
---@field config Config
---@field companion Companion Binary companion for playing audio
---@field enabled boolean
local M = {}

---@class KeyMap
---@field mode string
---@field key_chord string
local key_map = {}

---@class SoundMap
---@field auto_command? string
---@field trigger_name? string
---@field key_map? KeyMap
---@field sounds? string[]
---@field sound? string
local sound_maps = {}

---@class Config
---@field enabled? boolean
---@field max_sounds? number
---@field sound_directory? string
---@field sound_maps? (SoundMap?)[]
---@field theme? string
---@field binary_path? string
M.config = {
	enabled = true,
	max_sounds = 20,
	sound_directory = vim.fn.stdpath("config") .. "/sounds/",
	sound_maps = {},
	binary_path = "/home/eggbert/programs/lua/beepboop.nvim/src/bin/boopbeep" -- TODO: Change to a default location
}

M.companion = require("beepboop.companion")

return M
