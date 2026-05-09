---Utilities for beepboop development

local M = {}

---@return string
M.get_os = function ()
	local os = jit.os:lower()
	if os == "osx" or os == "mac" then
		return "macos"
	end
	return os
end

---@return string
M.get_arch = function ()
	local arch = jit.arch:lower()
	if arch == "x64" then
		arch = "x86"
	end

	return arch
end

---@param path string
---@return Theme
M.read_json = function (path)
	local file = io.open(path, "r")
	assert(file, string.format("File at %s could not be read", path))

	local json = vim.fn.json_decode(file:read("*all"))
	file:close()

    return json
end

---@param url string
---@return string
M.directory_name_from_remote_url = function (url)
	if string.sub(url, -1) == "/" then
		url = string.sub(url, 1, -2)
	end

	if string.sub(url, -4) == ".git" then
		url = string.sub(url, 1, -5)
	end

	local parts = {}
	for part in string.gmatch(url, "[^/]+") do
		table.insert(parts, part)
	end

	return parts[#parts]
end

return M
