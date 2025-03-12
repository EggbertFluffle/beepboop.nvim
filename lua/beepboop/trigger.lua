--- For handling triggers like autocommands to key maps
--- @module 'trigger'

---@class Trigger
local M = {}

---@param sound_map SoundMap
---@param companion Companion
local set_blocking_key_map = function (sound_map, companion)
	vim.keymap.set(sound_map.key_map.mode, sound_map.key_map.key_chord, function ()
		companion:play_sound(sound_map.trigger_name)
	end)
end

--- For blocing keymaps, just override whatever was present
---@param sound_map SoundMap
---@param companion Companion
local set_transparent_key_map = function (sound_map, companion)
	local existing = vim.fn.maparg(sound_map.key_map.key_chord, sound_map.key_map.mode, false, true)

	vim.keymap.set(sound_map.key_map.mode, sound_map.key_map.key_chord, function()
		companion:play_sound(sound_map.trigger_name)

		if existing.callback then
			existing.callback()
		else
			vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes(sound_map.key_map.key_chord, true, false, true),
				"nt",
				false)
		end
	end)
end

---@param theme Theme
---@param companion Companion
local set_key_maps = function (theme, companion)
	for _, sound_map in pairs(theme.sound_maps) do
		if sound_map.key_map then
			if sound_map.key_map.blocking then
				set_blocking_key_map(sound_map, companion)
			else
				set_transparent_key_map(sound_map, companion)
			end
		end
	end
end

---@param theme Theme
---@param companion Companion
local set_autocmds = function(theme, companion)
	vim.api.nvim_create_augroup("beepboop_triggers", {})

	for _, sound_map in pairs(theme.sound_maps) do
		if sound_map.auto_command then
			vim.api.nvim_create_autocmd(sound_map.auto_command, {
				callback = function()
					companion:play_sound(sound_map.trigger_name)
				end,
				group = "beepboop_triggers",
			})
		end
	end
end

M.clear_autocmds = function ()
	vim.api.nvim_clear_autocmds({
		group = "beepboop_triggers"
	})
end

---@param theme Theme
---@param companion Companion
M.set_theme_triggers = function (theme, companion)
	set_autocmds(theme, companion)
	set_key_maps(theme, companion)
end

return M
