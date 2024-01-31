vim.api.nvim_create_user_command("MacroYank", function(opts)
	require("macroni").yank(unpack(opts.fargs))
end, { nargs = "*" })

vim.api.nvim_create_user_command("MacroSave", function(opts)
	require("macroni").save_macro(unpack(opts.fargs))
end, { nargs = "*" })

vim.api.nvim_create_user_command("MacroSelect", function()
	require("macroni").select_and_yank_macro()
end, {})
