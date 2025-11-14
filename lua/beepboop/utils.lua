---Utilities for beepboop development
---@module 'utils'

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

---@type string
M.path_seperator = M.get_os() == "windows" and "\\" or "/"

---@param path string
---@return Theme
M.read_json = function (path)
	local file = io.open(path, "r")
	assert(file, string.format("File at %s could not be read", path))

	local json = vim.fn.json_decode(file:read("*all"))
	file:close()

    return json
end

---@param directory_path string
M.trailing_directory_slash = function (directory_path)
	local path_seperator = M.path_seperator
	if string.sub(directory_path, -1) ~= path_seperator then
		directory_path = directory_path .. path_seperator
	end
	return directory_path
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
