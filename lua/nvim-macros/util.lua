local base64 = require("nvim-macros.base64")

local M = {}

-- Print error message
M.notify = function(msg, level)
	if not level then
		level = "info"
	end
	vim.notify(msg, vim.log.levels[level:upper()], { title = "nvim-macros" })
end

-- Get default register ("unnamed" or "unnamedplus")
M.get_default_register = function()
	local clipboardFlags = vim.split(vim.api.nvim_get_option("clipboard"), ",")
	if vim.tbl_contains(clipboardFlags, "unnamedplus") then
		return "+"
	end
	if vim.tbl_contains(clipboardFlags, "unnamed") then
		return "*"
	end
	return '"'
end

-- Get register input
M.get_register_input = function(prompt, default_register)
	local valid_registers = "[a-z0-9]"
	local register = vim.fn.input(prompt)

	while not (register:match("^" .. valid_registers .. "$") or register == "") do
		M.notify(
			"Invalid register: `" .. register .. "`. Register must be a single lowercase letter or number 1-9.",
			"error"
		)
		register = vim.fn.input(prompt)
	end

	if register == "" then
		register = default_register
		M.notify("No register specified. Using default `" .. default_register .. "`.")
	end

	return register
end

-- Decode and set macro to register
M.set_decoded_macro_to_register = function(encoded_content, target_register)
	if not encoded_content or encoded_content == "" then
		M.notify("Empty encoded content. Cannot set register `" .. target_register .. "`.", "error")
		return
	end

	local decoded_content = base64.dec(encoded_content)
	if not decoded_content or decoded_content == "" then
		M.notify("Failed to decode. Register `" .. target_register .. "` remains unchanged.", "error")
		return
	end

	vim.fn.setreg(target_register, decoded_content)
end

-- Set macro to register (Escaped term codes)
M.set_macro_to_register = function(macro_content)
	if not macro_content then
		M.notify("Empty macro content. Cannot set to default register.", "error")
		return
	end

	local default_register = M.get_default_register()
	vim.fn.setreg(default_register, macro_content)
	vim.fn.setreg('"', macro_content)
end

return M
