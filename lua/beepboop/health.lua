--- Health checks for beepboop.nvim

---@class Health
---@field config_msg string?
---@field companion_val_msg string?
---@field companion_init_msg string?
---@field load_sound_msg string?
---@field set_triggers_msg string?
local M = {
	config_msg = nil,
	companion_val_msg = nil,
	companion_init_msg = nil,
	load_sound_msg = nil,
	set_triggers_msg = nil
}

M.check = function ()
	if M.config_msg then
		vim.health.error(M.config_msg)
		return
	else
		vim.health.ok("Validated plugin and theme configuration")
	end

	if M.companion_val_msg then
		vim.health.error(M.companion_val_msg)
		return
	else
		vim.health.ok("Validated companion configuration")
	end

	if M.companion_init_msg then
		vim.health.error(M.companion_init_msg)
		return
	else
		vim.health.ok("Initialized companion ok")
	end

	if M.load_sound_msg then
		vim.health.error(M.load_sound_msg)
		return
	else
		vim.health.ok("Loaded sounds to companion ok")
	end

	if M.set_triggers_msg then
		vim.health.error(M.set_triggers_msg)
		return
	else
		vim.health.ok("Triggers set for theme ok")
	end
end

return M
