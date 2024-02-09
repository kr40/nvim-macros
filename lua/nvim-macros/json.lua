local util = require("nvim-macros.util")

local M = {}

-- Validate JSON content
local validate_json = function(decoded_content)
	if
		not decoded_content
		or type(decoded_content) ~= "table"
		or not decoded_content.macros
		or type(decoded_content.macros) ~= "table"
	then
		return false
	end

	for _, macro in ipairs(decoded_content.macros) do
		if
			type(macro) ~= "table"
			or type(macro.name) ~= "string"
			or macro.name == ""
			or type(macro.raw) ~= "string"
			or macro.raw == ""
			or type(macro.content) ~= "string"
			or macro.content == ""
		then
			return false
		end
	end

	return true
end

-- Pretty print JSON content using jq or yq
local pretty_print_json = function(data, formatter)
	local json_str = vim.fn.json_encode(data)

	if formatter == "jq" then
		if vim.fn.executable("jq") == 0 then
			util.notify("jq is not installed. Falling back to default 'none'.", "error")
			return json_str
		end
		local cmd = "echo " .. vim.fn.shellescape(json_str) .. " | jq --monochrome-output ."
		return vim.fn.system(cmd)
	elseif formatter == "yq" then
		if vim.fn.executable("yq") == 0 then
			util.notify("yq is not installed. Falling back to default 'none'.", "error")
			return json_str
		end
		local cmd = "echo "
			.. vim.fn.shellescape(json_str)
			.. " | yq -P --output-format=json --input-format=json --no-colors ."
		return vim.fn.system(cmd)
	else
		return json_str
	end
end

-- Get the most recent backup file
local get_latest_backup = function(backup_dir)
	local p = io.popen('ls -t "' .. backup_dir .. '"')
	if p then
		local latest_backup = p:read("*l")
		p:close()
		return latest_backup and backup_dir .. "/" .. latest_backup
	else
		return nil
	end
end

-- Restore from the most recent backup
local restore_from_backup = function(backup_file, original_file)
	if not backup_file or not original_file then
		return false
	end

	local restore_cmd = "cp -f '" .. backup_file .. "' '" .. original_file .. "'"
	return os.execute(restore_cmd) == 0
end

local cleanup_old_backups = function(backup_dir, keep_last_n)
	local p = io.popen('ls -t "' .. backup_dir .. '"')
	if not p then
		return nil
	end

	local backups = {}
	for filename in p:lines() do
		table.insert(backups, filename)
	end
	p:close()

	for i = keep_last_n + 1, #backups do
		local backup_to_delete = backup_dir .. "/" .. backups[i]
		os.remove(backup_to_delete)
	end
end

-- Handle JSON file read and write (r, w)
M.handle_json_file = function(json_formatter, json_file_path, mode, data)
	if not json_file_path or json_file_path == "" then
		util.notify("Invalid JSON file path.", "error")
		return mode == "r" and { macros = {} } or nil
	end

	local file_path = json_file_path
	local backup_dir = vim.fn.stdpath("data") .. "/nvim-macros/backups"
	vim.fn.mkdir(backup_dir, "p")

	if mode == "r" then
		local file = io.open(file_path, "r")
		if not file then
			local latest_backup = get_latest_backup(backup_dir)
			if latest_backup then
				if restore_from_backup(latest_backup, file_path) then
					util.notify("No JSON found. Restored from the most recent backup.")
					file = io.open(file_path, "r")
				end
			else
				util.notify("No JSON found. Creating new file: " .. file_path)
				file = io.open(file_path, "w")
				if file then
					local content = vim.fn.json_encode({ macros = {} })
					file:write(content)
					file:close()
					return { macros = {} }
				else
					util.notify("Failed to create new file: " .. file_path, "error")
					return nil
				end
			end
		end

		if file then
			local content = file:read("*a")
			file:close()

			if not content or content == "" then
				local latest_backup = get_latest_backup(backup_dir)
				if latest_backup then
					if restore_from_backup(latest_backup, file_path) then
						util.notify("File is empty. Restored from most recent backup.", "error")
						return M.handle_json_file(json_formatter, json_file_path, mode, data)
					end
				else
					util.notify("File is empty. Initializing with default structure.", "error")
					return { macros = {} }
				end
			end

			if content then
				local status, decoded_content = pcall(vim.fn.json_decode, content)
				if status and validate_json(decoded_content) then
					return decoded_content
				else
					util.notify("Invalid JSON content. Attempting to restore from backup.", "error")
					local latest_backup = get_latest_backup(backup_dir)
					if latest_backup and restore_from_backup(latest_backup, file_path) then
						util.notify("Successfully restored from backup.")
						return M.handle_json_file(json_formatter, json_file_path, mode, data)
					else
						util.notify("Failed to restore from backup. Manual check required.", "error")
						return nil
					end
				end
			end
		end
	elseif mode == "w" then
		local backup_file_path = backup_dir .. "/" .. os.date("%Y%m%d%H%M%S") .. "_macros.json.bak"

		local file = io.open(file_path, "w")
		if not file then
			util.print_error("Unable to write to the file.")
			return nil
		end

		local content = (json_formatter == "jq" or json_formatter == "yq") and pretty_print_json(data, json_formatter)
			or vim.fn.json_encode(data)

		file:write(content)
		file:close()

		os.execute("cp -f '" .. file_path .. "' '" .. backup_file_path .. "'")
		cleanup_old_backups(backup_dir, 3)
	else
		util.print_error("Invalid mode: '" .. mode .. "'. Use 'r' or 'w'.")
	end
end

return M
