--- Health checks for beepboop.nvim

local M = {}

M.check = function ()
	vim.health.start("beepboop.nvim")

	vim.health.ok("Yipee you are healthy")
end

return M
