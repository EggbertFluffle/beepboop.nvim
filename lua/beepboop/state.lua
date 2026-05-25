---Holds all the state necessary for the plugin to run

---@class State
---@field config Config
---@field companion Companion Binary companion for playing audio
---@field mute boolean
local M = {}

M.config = require("beepboop.config").defult_config
M.companion = require("beepboop.companion")

return M
