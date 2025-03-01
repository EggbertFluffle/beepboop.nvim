local path = "/home/eggbert/programs/lua/beepboop.nvim/src/bin/"
local binary = path .. "boopbeep"

local job_id = vim.fn.jobstart({binary}, {
	stdout_buffered = true,
	on_stdout = function(_, data, _)
		print("Received:", table.concat(data, "\n"))
	end,
	on_exit = function(_, code) vim.print("Process exited with exit code: " .. code) end
})

vim.print("Process started with job_id: " .. job_id)

vim.fn.chansend(job_id, "chestopen\n")
vim.fn.chansend(job_id, "chestopen\n")
vim.fn.chansend(job_id, "chestopen\n")
vim.fn.chansend(job_id, "chestopen\n")
vim.fn.chansend(job_id, "chestopen\n")
vim.fn.chansend(job_id, "chestopen\n")

vim.keymap.set("n", "<leader>jk", function ()
	if vim.fn.jobpid(job_id) > 0 then
		vim.fn.chansend(job_id, "chestopen\n")
	end
end)

vim.keymap.set("n", "<leader>jj", function ()
	vim.fn.jobstop(job_id)
end)
