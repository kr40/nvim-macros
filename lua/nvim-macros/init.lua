local base64 = require("nvim-macros.base64")
local util = require("nvim-macros.util")
local json = require("nvim-macros.json")

-- Default configuration
---@class Config
---@field json_file_path string
---@field default_macro_register string
---@field json_formatter "none" | "jq" | "yq"
local config = {
	json_file_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/macros.json"),
	default_macro_register = "q",
	json_formatter = "none",
}

local M = {}

-- Initialize with user config
---@param user_config? Config
M.setup = function(user_config)
	if user_config ~= nil then
		for key, value in pairs(user_config) do
			if config[key] ~= nil then
				config[key] = value
			else
				util.notify("Invalid config key: " .. key, "error")
			end
		end
	end
end

M.get_config = function()
	return config
end

-- Yank macro from register to default register
M.yank = function(register)
	local valid_registers = "[a-z0-9]"
	if not register or register == "" then
		register = util.get_register_input("Specify a register to yank from: ", config.default_macro_register)
	end

	while not (register:match("^" .. valid_registers .. "$")) do
		util.notify(
			"Invalid register: `" .. register .. "`. Register must be a single lowercase letter or number 1-9.",
			"error"
		)

		register = util.get_register_input("Specify a register to yank from: ", config.default_macro_register)
	end

	local register_content = vim.fn.getreg(register)
	if not register_content or register_content == "" then
		util.notify("Register `" .. register .. "` is empty or invalid!", "error")
		return
	end

	local macro = vim.fn.keytrans(register_content)
	util.set_macro_to_register(macro)
	util.notify("Yanked macro from `" .. register .. "` to clipboard.")
end

-- Execute macro (for key mappings)
M.run = function(macro)
	if not macro then
		util.notify("Macro is empty. Cannot run.", "error")
		return
	end

	vim.cmd.normal(vim.api.nvim_replace_termcodes(macro, true, true, true))
end

-- Save macro to JSON (Raw and Escaped)
M.save_macro = function(register)
	local valid_registers = "[a-z0-9]"
	if not register or register == "" then
		register = util.get_register_input("Specify a register to save from: ", config.default_macro_register)
	end

	while not (register:match("^" .. valid_registers .. "$")) do
		util.notify(
			"Invalid register: `" .. register .. "`. Register must be a single lowercase letter or number 1-9.",
			"error"
		)

		register = util.get_register_input("Specify a register to save from: ", config.default_macro_register)
	end

	local register_content = vim.fn.getreg(register)
	if not register_content or register_content == "" then
		util.notify("Register `" .. register .. "` is empty or invalid!", "error")
		return
	end

	local name = vim.fn.input("Name your macro: ")
	if not name or name == "" then
		util.notify("Invalid or empty macro name.", "error")
		return
	end

	local macro = vim.fn.keytrans(register_content)
	local macro_raw = base64.enc(register_content)

	local macros = json.handle_json_file(config.json_formatter, config.json_file_path, "r")
	if macros then
		table.insert(macros.macros, { name = name, content = macro, raw = macro_raw })
		json.handle_json_file(config.json_formatter, config.json_file_path, "w", macros)
		util.notify("Macro `" .. name .. "` saved.")
	end
end

-- Delete macro from JSON file
M.delete_macro = function()
	local macros = json.handle_json_file(config.json_formatter, config.json_file_path, "r")
	if not macros or not macros.macros or #macros.macros == 0 then
		util.notify("No macros to delete.", "error")
		return
	end

	local choices = {}
	local name_to_index_map = {}
	for index, macro in ipairs(macros.macros) do
		if macro.name then
			local display_text = macro.name .. " | " .. string.sub(macro.content, 1, 150)
			table.insert(choices, display_text)
			name_to_index_map[display_text] = index
		end
	end

	if next(choices) == nil then
		util.notify("No valid macros for deletion.", "error")
		return
	end

	vim.ui.select(choices, { prompt = "Select a macro to delete:" }, function(choice)
		if not choice then
			util.notify("Macro deletion cancelled.", "error")
			return
		end

		local macro_index = name_to_index_map[choice]
		local macro_name = macros.macros[macro_index].name
		if not macro_index then
			util.notify("Selected macro `" .. choice .. "` is invalid.", "error")
			return
		end

		table.remove(macros.macros, macro_index)
		json.handle_json_file(config.json_formatter, config.json_file_path, "w", macros)
		util.notify("Macro `" .. macro_name .. "` deleted.")
	end)
end

-- Select and yank macro from JSON (Raw or Escaped)
M.select_and_yank_macro = function()
	local macros = json.handle_json_file(config.json_formatter, config.json_file_path, "r")
	if not macros or not macros.macros or #macros.macros == 0 then
		util.notify("No macros to select.", "error")
		return
	end

	local choices = {}
	local name_to_content_map = {}
	local name_to_encoded_content_map = {}
	local name_to_index_map = {}
	for index, macro in ipairs(macros.macros) do
		if macro.name and macro.content and macro.raw then
			local display_text = macro.name .. " | " .. string.sub(macro.content, 1, 150)
			table.insert(choices, display_text)
			name_to_index_map[display_text] = index
			name_to_content_map[display_text] = macro.content
			name_to_encoded_content_map[display_text] = macro.raw
		end
	end

	if next(choices) == nil then
		util.notify("No valid macros to yank.", "error")
		return
	end

	vim.ui.select(choices, { prompt = "Select a macro:" }, function(choice)
		if not choice then
			util.notify("Macro selection canceled.", "error")
			return
		end

		local macro_index = name_to_index_map[choice]
		local macro_name = macros.macros[macro_index].name
		local macro_content = name_to_content_map[choice]
		local encoded_content = name_to_encoded_content_map[choice]
		if not macro_content or not encoded_content then
			util.notify("Selected macro `" .. choice .. "` has missing content.", "error")
			return
		end

		local yank_option = vim.fn.input("Yank as (1) Escaped, (2) Raw Macro: ")

		if yank_option == "1" then
			util.set_macro_to_register(macro_content)
			util.notify("Yanked macro `" .. macro_name .. "` to clipboard.")
		elseif yank_option == "2" then
			local valid_registers = "[a-z0-9]"
			local target_register =
				util.get_register_input("Specify a register to yank the raw macro to: ", config.default_macro_register)

			while not (target_register:match("^" .. valid_registers .. "$")) do
				util.notify(
					"Invalid register: `"
						.. target_register
						.. "`. Register must be a single lowercase letter or number 1-9.",
					"error"
				)

				target_register = util.get_register_input(
					"Specify a register to yank the raw macro to: ",
					config.default_macro_register
				)
			end

			util.set_decoded_macro_to_register(encoded_content, target_register)
			util.notify("Yanked raw macro `" .. macro_name .. "` into register `" .. target_register .. "`.")
		else
			util.notify("Invalid yank option selected.", "error")
		end
	end)
end

return M
