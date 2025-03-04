-- beepboop.nvim lets users add sound effects on cues to Neovim
---@module 'beepboop'

---@class BeepBoop
---@field state State
---@field setup fun(opts: Config): BeepBoop
---@field play fun(trigger_name: string)
---@field enable fun()
---@field disable fun()
---@field toggle fun()
local M = {}

---@param opts Config?
M.setup = function(opts)
	M.state = require("beepboop.state")
	M.state.config = vim.tbl_deep_extend("force", M.state.config, opts or {})

	M.state.companion:initialize(M.state.config)
	M.state.companion:load_sound_files(M.state.config)
	M.state.companion:play_sound("chestopen")

	return M
end

M.play = function(trigger_name)
	M.state.companion:play_sound(trigger_name)
end

return M
