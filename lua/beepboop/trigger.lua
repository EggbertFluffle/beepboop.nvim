--- For handling triggers like autocommands to key maps

---@class Trigger
local M = {}

---@param sound_map SoundMap
---@param companion Companion
local set_blocking_keymap = function (sound_map, companion)
	vim.keymap.set(sound_map.keymap.mode, sound_map.keymap.keychord, function ()
		companion:play_sound(sound_map.trigger)
	end)
end

--- For blocing keymaps, just override whatever was present
---@param sound_map SoundMap
---@param companion Companion
local set_transparent_keymap = function (sound_map, companion)
	local existing = vim.fn.maparg(sound_map.keymap.keychord, sound_map.keymap.mode, false, true)

	vim.keymap.set(sound_map.keymap.mode, sound_map.keymap.keychord, function()
		companion:play_sound(sound_map.trigger)

		if existing.callback then
			existing.callback()
		else
			vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes(sound_map.keymap.keychord, true, false, true),
				"nt",
				false)
		end
	end)
end

---@param theme Theme
---@param companion Companion
local set_keymaps = function (theme, companion)
	for _, sound_map in pairs(theme.sound_maps) do
		if sound_map.keymap then
			if sound_map.keymap.blocking then
				set_blocking_keymap(sound_map, companion)
			else
				set_transparent_keymap(sound_map, companion)
			end
		end
	end
end

---@param theme Theme
---@param companion Companion
local set_autocmds = function(theme, companion)
	vim.api.nvim_create_augroup("beepboop_triggers", {})

	for _, sound_map in pairs(theme.sound_maps) do
		if sound_map.autocommand then
			vim.api.nvim_create_autocmd(sound_map.autocommand, {
				callback = function()
					companion:play_sound(sound_map.trigger)
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
	set_keymaps(theme, companion)
end

return M
