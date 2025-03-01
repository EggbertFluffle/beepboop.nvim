local io = require("io")

local binary = "./src/bin/boopbeep"
local sound_file = "./src/bin/chestopen.wav"
local sound_trigger_name = "chestopen"

local function on_output()
	if data then
		print(event .. ": " .. table.concat(data, "\n"))
	end
end

local job_id = vim.fn.jobstart({binary}, {
	on_stdout = function (_, data, _)
		on_output(_, data, "stdout")
	end,
	on_stderr = function ()
		on_output(_, data, "stderr")
	end
})

vim.fn.chansend(job_id, "load_sound " .. sound_trigger_name .. " " .. sound_file .. "\n")
vim.fn.chansend(job_id, "play_sound " .. sound_trigger_name .. "\n")

os.execute("sleep 5")

vim.fn.chansend(job_id, "quit\n")

vim.fn.jobstop(job_id)
