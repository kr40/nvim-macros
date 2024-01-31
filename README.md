# Macroni

Save your macros to an easily mappable format for future use in Neovim!

## Rationale

Q: Why use Macroni at all when you can just yank directly from your register?

A: Because then you have to deal with escaping termcodes, quotes, etc. yourself. Macroni escapes all that stuff for you, so you can paste directly to a mapping or function!

> _Note: Telescope picker coming soon!_

## Usage

Simply run `:YankMacro [register]` to yank a recorded macro from a register, then paste the macro directly into a custom mapping or function in your config 🤌

### Example

For example, say we record a short macro to the `q` register to make a todo list item on the current line. We can then run `:YankMacro q`, and paste into a mapping like so:

```lua
vim.keymap.set('n', '<Leader>t', '^i-<Space>[<Space>]<Space><Esc>', { remap = true })
```

_Note: It is recommended that you set the `remap = true` option, to ensure that your macro is run more accurately as if you had manually run it yourself!_

### Advanced Usage

You can also use macroni's `run()` helper to execute the macro from within a function:

```lua
local make_todo_list_item = function ()
  require('macroni').run('^i-<Space>[<Space>]<Space><Esc>')
end

vim.keymap.set('n', '<Leader>t', make_todo_list_item, { remap = true })
```
