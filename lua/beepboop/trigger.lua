--- For handling triggers like autocommands to key maps
--- @module 'trigger'

---@class Trigger
local M = {}

---@param state State
M.set_autocmds = function(state)
	vim.api.nvim_create_augroup("beepboop_triggers", {})

	for _, sound_map in pairs(state.config.sound_maps) do
		if sound_map.auto_command then
			vim.api.nvim_create_autocmd(sound_map.auto_command, {
				callback = function()
					state.companion:play_sound(sound_map.trigger_name)
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

---@param sound_map SoundMap
---@param companion Companion
local set_blocking_key_map = function (sound_map, companion)
	vim.keymap.set(sound_map.key_map.mode, sound_map.key_map.key_chord, function ()
		companion:play_sound(sound_map.trigger_name)
	end)
end

--- For blocing keymaps, just override whatever was present
---@param sound_map SoundMap
---@param existing string|table<string, any>
---@param companion Companion
local set_transparent_key_map = function (sound_map, existing, companion)
	if type(existing) == "string" then
		--- Pre-existing maps that are a simple sequence of key strokes
		vim.keymap.set(sound_map.key_map.mode, sound_map.key_map.key_chord, function()
			companion:play_sound(sound_map.trigger_name)

			vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes(sound_map.key_map.key_chord, true, true, false),
				'n',
				true
			)
		end, { expr = true })
	else
		--- More complex maps that may be entire functions
		vim.keymap.set(sound_map.key_map.mode, sound_map.key_map.key_chord, function()
			companion:play_sound(sound_map.trigger_name)

			if existing.rhs ~= nil and not vim.tbl_isempty(existing.rhs) then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes(existing.rhs, true, true, true),
					'n',
					true
				)
			else
				existing.callback()
			end
		end, { expr = true })
	end
end

---@param state State
M.set_key_maps = function (state)
	for _, sound_map in pairs(state.config.sound_maps) do
		if sound_map.key_map then

			local existing = vim.fn.maparg(sound_map.key_map.key_chord, sound_map.key_map.mode, false, true)

			if sound_map.key_map.blocking or #existing == 0 then
				set_blocking_key_map(sound_map, state.companion)
			else
				set_transparent_key_map(sound_map, existing, state.companion)
			end
		end
	end
end

local initialize_key_maps = (function(sound_map)
	for trigger_name, sound in pairs(sound_map) do
		if sound.key_map ~= nil then
			if sound.key_map.blocking then
				vim.keymap.set(sound.key_map.mode, sound.key_map.key_chord, (function()
					M.play_audio(trigger_name)
				end))
			else
				local existing = vim.fn.maparg(sound.key_map.key_chord, sound.key_map.mode, false, true)

				if vim.tbl_isempty(existing) then
					vim.keymap.set(sound.key_map.mode, sound.key_map.key_chord, (function()
						M.play_audio(trigger_name)
						vim.api.nvim_feedkeys(
							vim.api.nvim_replace_termcodes(sound.key_map.key_chord, true, true, true),
							'n',
							true
						)
					end),
						{ expr = true })
				else
					vim.keymap.set(sound.key_map.mode, sound.key_map.key_chord, (function()
						M.play_audio(trigger_name)
						if existing.rhs ~= nil and not vim.tbl_isempty(existing.rhs) then
							if existing.expr == 1 then
							else
								vim.api.nvim_feedkeys(
									vim.api.nvim_replace_termcodes(existing.rhs, true, true, true),
									'n',
									true
								)
							end
						else
							existing.callback()
						end
					end),
						{ expr = true })
				end
			end
		end
	end
end)

return M
