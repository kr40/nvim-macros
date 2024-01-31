-- Set default configuration
local config = {
	json_file_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/macros.json"),
}

-- Load base64 module
local base64 = require("nvim-macros.base64")

local M = {}

-- Set user configuration
function M.setup(user_config)
	if user_config ~= nil then
		for key, value in pairs(user_config) do
			if config[key] ~= nil then
				config[key] = value
			else
				print("Invalid configuration key: " .. key)
			end
		end
	end
end

-----------------------------------------------------------Helper Functions--------------------------------------------

-- Print error message
local function print_error(message)
	vim.notify(message, vim.log.levels.ERROR, { title = "nvim-macros" })
end

-- Get default register ("unnamed" or "unnamedplus")
local function get_default_register()
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
local function set_decoded_macro_to_register(encoded_content, target_register)
	if not encoded_content or encoded_content == "" then
		print_error("Encoded macro content is empty. Cannot set to register.")
		return
	end

	local decoded_content = base64.dec(encoded_content)
	if not decoded_content or decoded_content == "" then
		print_error("Decoding failed or decoded content is empty.")
		return
	end

	vim.fn.setreg(target_register, decoded_content)
	print("Decoded macro set to register `" .. target_register .. "`")
end

-- Set macro to register (Escaped termcodes)
local function set_macro_to_register(macro_content)
	if not macro_content then
		print_error("Macro content is empty. Cannot set to register.")
		return
	end

	local default_register = get_default_register()
	vim.fn.setreg(default_register, macro_content)
	vim.fn.setreg('"', macro_content)
end

-- JSON file handler
local function handle_json_file(mode, data)
	if not config.json_file_path or config.json_file_path == "" then
		print_error("JSON file path is invalid.")
		return mode == "r" and { macros = {} } or nil
	end

	local file_path = config.json_file_path
	if mode == "r" then
		local file = io.open(file_path, "r")
		if not file then
			print_error("Failed to read file")
			print("Initializing new file: " .. file_path)
			return handle_json_file("w", { macros = {} })
		end
		local content = file:read("*a")
		file:close()
		if not content or content == "" then
			print_error("File is empty")
			print("Initializing with default structure.")
			return handle_json_file("w", { macros = {} })
		else
			local decoded_content = vim.fn.json_decode(content)
			if not decoded_content then
				print_error("Invalid JSON content")
				print("Initializing with default structure.")
				return handle_json_file("w", { macros = {} })
			end
			return decoded_content
		end
	elseif mode == "w" then
		local file, err = io.open(file_path, "w")
		if not file then
			print_error("Failed to open file for writing: " .. err)
			return nil
		end
		local content = vim.fn.json_encode(data)
		file:write(content)
		file:close()
	else
		print_error("Invalid mode for JSON file handling. Mode should be 'r' or 'w'.")
	end
end

------------------------------------------------------------Main Functions---------------------------------------------

-- Yank macro from register to default register (Escaped termcodes)
function M.yank(register)
	register = register or vim.fn.input("Please specify a register to yank from: ")
	local register_content = vim.fn.getreg(register)
	if not register_content or register_content == "" then
		print_error("Register is empty or has invalid content!")
		return
	end

	local macro = vim.fn.keytrans(register_content)
	set_macro_to_register(macro)
	print("Yanked macro from register `" .. register .. "`")
end

-- Run macros from inside a function (For keymaps)
function M.run(macro)
	if not macro then
		print_error("Macro is Empty. Cannot run.")
		return
	end
	vim.cmd.normal(vim.api.nvim_replace_termcodes(macro, true, true, true))
end

-- Save macro to JSON file (Saves raw and escaped termcodes)
function M.save_macro(register)
	register = register or vim.fn.input("Please specify a register to save from: ")
	local register_content = vim.fn.getreg(register)
	if not register_content or register_content == "" then
		print_error("Register is empty or has invalid content!")
		return
	end

	local macro = vim.fn.keytrans(register_content)
	local macro_raw = base64.enc(register_content)
	local name = vim.fn.input("Name your macro: ")
	if not name or name == "" then
		print_error("Invalid or empty name for macro.")
		return
	end

	local macros = handle_json_file("r")
	if not macros then
		print_error("Failed to read macros from JSON. Creating a new file.")
		macros = { macros = {} }
	end

	table.insert(macros.macros, { name = name, content = macro, raw = macro_raw })
	handle_json_file("w", macros)
	print("Macro saved as " .. name)
end

-- Select and yank macro from JSON file (Yanks raw or escaped termcodes)
function M.select_and_yank_macro()
	local macros = handle_json_file("r")
	if not macros or not macros.macros or #macros.macros == 0 then
		print_error("No macros found.")
		return
	end

	local choices = {}
	local name_to_content_map = {}
	local name_to_encoded_content_map = {}
	for _, macro in ipairs(macros.macros) do
		if macro.name and macro.content and macro.raw then
			local display_text = macro.name .. " | " .. string.sub(macro.content, 1, 150)
			table.insert(choices, display_text)
			name_to_content_map[display_text] = macro.content
			name_to_encoded_content_map[display_text] = macro.raw
		end
	end

	if next(choices) == nil then
		print_error("No valid macros to select.")
		return
	end

	vim.ui.select(choices, { prompt = "Select a macro:" }, function(choice)
		if not choice then
			print_error("No macro selected.")
			return
		end

		local macro_content = name_to_content_map[choice]
		local encoded_content = name_to_encoded_content_map[choice]
		if not macro_content or not encoded_content then
			print_error("Selected macro has missing content.")
			return
		end

		local yank_option = vim.fn.input("Yank as (1) Escaped (Yank to Clipboard), (2) Raw Macro: ")

		if yank_option == "1" then
			set_macro_to_register(macro_content)
			print("Yanked to Clipboard (p to paste): " .. choice:match("^[^|]+"))
		elseif yank_option == "2" then
			local target_register = vim.fn.input("Please specify a register to set the macro to: ")
			if not target_register or target_register == "" then
				print_error("Invalid or empty register specified.")
				return
			end
			set_decoded_macro_to_register(encoded_content, target_register)
			print("Yanked Raw Macro: " .. choice:match("^[^|]+") .. " into register `" .. target_register .. "`")
		else
			print_error("Invalid yank option selected.")
		end
	end)
end

return M
