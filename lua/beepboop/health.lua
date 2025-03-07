--- Health checks for beepboop.nvim

local M = {}

M.check = function ()
	vim.health.start("beepboop.nvim")
end

return M
