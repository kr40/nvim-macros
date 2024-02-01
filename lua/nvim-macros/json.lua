local util = require("nvim-macros.util")

local M = {}

M.handle_json_file = function(json_file_path, mode, data)
	if not json_file_path or json_file_path == "" then
		util.print_error("Invalid JSON file path.")
		return mode == "r" and { macros = {} } or nil
	end

	local file_path = json_file_path
	if mode == "r" then
		local file = io.open(file_path, "r")
		if not file then
			util.print_info("No JSON found. Creating new file: " .. file_path)
			M.handle_json_file(json_file_path, "w", { macros = {} })
			return { macros = {} }
		end
		local content = file:read("*a")
		file:close()
		if not content or content == "" then
			util.print_info("File is empty. Initializing with default structure.")
			return { macros = {} }
		else
			local status, decoded_content = pcall(vim.fn.json_decode, content)
			if not status or not decoded_content then
				util.print_error("Invalid JSON content: " .. file_path)
				util.print_info("Correct the JSON manually or delete the file to reset.")
				return nil
			end
			return decoded_content
		end
	elseif mode == "w" then
		local file = io.open(file_path, "w")
		if not file then
			util.print_error("Unable to open JSON file for writing: " .. file_path)
			return nil
		end
		local content = vim.fn.json_encode(data)
		file:write(content)
		file:close()
	else
		util.print_error("Invalid mode: '" .. mode .. "'. Use 'r' or 'w'.")
	end
end

return M
