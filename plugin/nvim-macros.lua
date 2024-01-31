vim.api.nvim_create_user_command("MacroYank", function(opts)
	require("nvim-macros").yank(unpack(opts.fargs))
end, { nargs = "*" })

vim.api.nvim_create_user_command("MacroSave", function(opts)
	require("nvim-macros").save_macro(unpack(opts.fargs))
end, { nargs = "*" })

vim.api.nvim_create_user_command("MacroSelect", function()
	require("nvim-macros").select_and_yank_macro()
end, {})

vim.api.nvim_create_user_command("MacroDelete", function()
	require("nvim-macros").delete_macro()
end, {})
