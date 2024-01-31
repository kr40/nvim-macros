local util = require("nvim-macros.util")

local M = {}

M.handle_json_file = function(json_file_path, mode, data)
	if not json_file_path or json_file_path == "" then
		util.print_error("JSON file path is invalid.")
		return mode == "r" and { macros = {} } or nil
	end

	local file_path = json_file_path
	if mode == "r" then
		local file = io.open(file_path, "r")
		if not file then
			util.print_error("Failed to read file")
			print("Initializing new file: " .. file_path)
			return M.handle_json_file("w", { macros = {} })
		end
		local content = file:read("*a")
		file:close()
		if not content or content == "" then
			util.print_error("File is empty")
			print("Initializing with default structure.")
			return M.handle_json_file("w", { macros = {} })
		else
			local decoded_content = vim.fn.json_decode(content)
			if not decoded_content then
				util.print_error("Invalid JSON content")
				print("Initializing with default structure.")
				return M.handle_json_file("w", { macros = {} })
			end
			return decoded_content
		end
	elseif mode == "w" then
		local file, err = io.open(file_path, "w")
		if not file then
			util.print_error("Failed to open file for writing: " .. err)
			return nil
		end
		local content = vim.fn.json_encode(data)
		file:write(content)
		file:close()
	else
		util.print_error("Invalid mode for JSON file handling. Mode should be 'r' or 'w'.")
	end
end

return M
