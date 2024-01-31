local base64 = require("nvim-macros.base64")

local M = {}

-- Print error message
M.print_error = function(message)
	vim.notify(message, vim.log.levels.ERROR, { title = "nvim-macros" })
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

-- Decode and set macro to register
M.set_decoded_macro_to_register = function(encoded_content, target_register)
	if not encoded_content or encoded_content == "" then
		M.print_error("Encoded macro content is empty. Cannot set to register.")
		return
	end

	local decoded_content = base64.dec(encoded_content)
	if not decoded_content or decoded_content == "" then
		M.print_error("Decoding failed or decoded content is empty.")
		return
	end

	vim.fn.setreg(target_register, decoded_content)
	print("Decoded macro set to register `" .. target_register .. "`")
end

-- Set macro to register (Escaped termcodes)
M.set_macro_to_register = function(macro_content)
	if not macro_content then
		M.print_error("Macro content is empty. Cannot set to register.")
		return
	end

	local default_register = M.get_default_register()
	vim.fn.setreg(default_register, macro_content)
	vim.fn.setreg('"', macro_content)
end

return M
