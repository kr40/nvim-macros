local base64 = require("nvim-macros.base64")
local util = require("nvim-macros.util")
local json = require("nvim-macros.json")

local M = {}

M.config = {
	json_file_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/macros.json"),
}
-- Set user configuration
function M.setup(user_config)
	if user_config ~= nil then
		for key, value in pairs(user_config) do
			if M.config[key] ~= nil then
				M.config[key] = value
			else
				print("Invalid configuration key: " .. key)
			end
		end
	end
end

-- Yank macro from register to default register (Escaped termcodes)
M.yank = function(register)
	register = register or vim.fn.input("Please specify a register to yank from: ")
	local register_content = vim.fn.getreg(register)
	if not register_content or register_content == "" then
		util.print_error("Register is empty or has invalid content!")
		return
	end

	local macro = vim.fn.keytrans(register_content)
	util.set_macro_to_register(macro)
	print("Yanked macro from register `" .. register .. "`")
end

-- Run macros from inside a function (For keymaps)
M.run = function(macro)
	if not macro then
		util.print_error("Macro is Empty. Cannot run.")
		return
	end
	vim.cmd.normal(vim.api.nvim_replace_termcodes(macro, true, true, true))
end

-- Save macro to JSON file (Saves raw and escaped termcodes)
M.save_macro = function(register)
	register = register or vim.fn.input("Please specify a register to save from: ")
	local register_content = vim.fn.getreg(register)
	if not register_content or register_content == "" then
		util.print_error("Register is empty or has invalid content!")
		return
	end

	local macro = vim.fn.keytrans(register_content)
	local macro_raw = base64.enc(register_content)
	local name = vim.fn.input("Name your macro: ")
	if not name or name == "" then
		util.print_error("Invalid or empty name for macro.")
		return
	end

	local macros = json.handle_json_file("r")
	if not macros then
		util.print_error("Failed to read macros from JSON. Creating a new file.")
		macros = { macros = {} }
	end

	table.insert(macros.macros, { name = name, content = macro, raw = macro_raw })
	json.handle_json_file("w", macros)
	print("Macro saved as " .. name)
end

M.delete_macro = function()
	local macros = json.handle_json_file("r")
	if not macros or not macros.macros or #macros.macros == 0 then
		util.print_error("No macros found.")
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
		util.print_error("No valid macros to select for deletion.")
		return
	end

	vim.ui.select(choices, { prompt = "Select a macro to delete:" }, function(choice)
		if not choice then
			util.print_error("No macro selected for deletion.")
			return
		end

		local macro_index = name_to_index_map[choice]
		if not macro_index then
			util.print_error("Selected macro is not valid.")
			return
		end

		-- Remove the selected macro from the list
		table.remove(macros.macros, macro_index)
		json.handle_json_file("w", macros) -- Write the updated list back to the JSON file
		print("Macro deleted: " .. choice:match("^[^|]+"))
	end)
end

-- Select and yank macro from JSON file (Yanks raw or escaped termcodes)
M.select_and_yank_macro = function()
	local macros = json.handle_json_file("r")
	if not macros or not macros.macros or #macros.macros == 0 then
		util.print_error("No macros found.")
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
		util.print_error("No valid macros to select.")
		return
	end

	vim.ui.select(choices, { prompt = "Select a macro:" }, function(choice)
		if not choice then
			util.print_error("No macro selected.")
			return
		end

		local macro_content = name_to_content_map[choice]
		local encoded_content = name_to_encoded_content_map[choice]
		if not macro_content or not encoded_content then
			util.print_error("Selected macro has missing content.")
			return
		end

		local yank_option = vim.fn.input("Yank as (1) Escaped (Yank to Clipboard), (2) Raw Macro: ")

		if yank_option == "1" then
			util.set_macro_to_register(macro_content)
			print("Yanked to Clipboard (p to paste): " .. choice:match("^[^|]+"))
		elseif yank_option == "2" then
			local target_register = vim.fn.input("Please specify a register to set the macro to: ")
			if not target_register or target_register == "" then
				util.print_error("Invalid or empty register specified.")
				return
			end
			util.set_decoded_macro_to_register(encoded_content, target_register)
			print("Yanked Raw Macro: " .. choice:match("^[^|]+") .. "into register `" .. target_register .. "`")
		else
			util.print_error("Invalid yank option selected.")
		end
	end)
end

return M
