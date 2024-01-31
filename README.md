# nvim-macros 📝

nvim-macros is your go-to Neovim plugin for supercharging your macro game! 🚀 It's all about making macro management in Neovim a breeze. Say goodbye to the fuss and hello to efficiency! This plugin lets you save, yank, and run your macros like a pro, and even handles those pesky special characters with ease.

## Why You'll Love nvim-macros 😍

- **Yank Macros** 🎣: Grab macros from any register and set them up for action in your default register with just a command.
- **Save Macros** 💾: Stash your precious macros in a JSON file. Choose to save with all the fancy termcodes or keep it raw - your call!
- **Select & Yank** 📋: Pick a macro from your saved collection and yank it into a register, ready for its moment in the spotlight.
- **Smart Encoding/Decoding** 🤓: nvim-macros speaks Base64 fluently, so it effortlessly handles macros with special characters.
- **Your Storage, Your Rules** 🗂️: Point nvim-macros to your chosen JSON file for macro storage. It's your macro library, after all!

## Getting Started 🚀

Time to get nvim-macros into your Neovim setup! If you're rolling with [lazy.nvim](https://github.com/folke/lazy.nvim), just pop this line into your plugin configuration:

```lua
{
  "kr40/nvim-macros",
  cmd = {"MacroSave", "MacroYank", "MacroSelect", "MacroDelete"},
  opts = {
    json_file_path = vim.fs.normalize(vim.fn.stdpath("config") .. "/macros.json"), -- Optional
  }
}
```

## How to Use 🛠️

Once you've got nvim-macros installed, Neovim is your macro playground! 🎉

- **:MacroYank [register]**: Yanks a macro from a register. If you don't specify, it'll politely ask you to choose one.
- **:MacroSave [register]**: Saves a macro into the book of legends (aka your JSON file). It'll prompt for a register if you're feeling indecisive.
- **:MacroSelect**: Brings up your macro menu. Pick one, and it'll be ready for action.
- **:MacroDelete**: Summon a list of your macros, then select one to permanently vanish it from your collection, as if it never existed.

### Example 🌟

Imagine you've got a nifty macro recorded in the **q** register that magically turns the current line into a to-do list item. After recording it, just summon **:MacroYank q** to yank the macro. Then, you can elegantly bind it to a key sequence in your Neovim setup like this:

```lua
vim.keymap.set('n', '<Leader>t', '^i-<Space>[<Space>]<Space><Esc>', { remap = true })
```

**_📝 Note: We highly recommend setting remap = true to ensure your macro runs as smoothly as if you were performing a magic trick yourself!_**

## Making It Yours 🎨

nvim-macros loves to fit in just right. Set up your JSON file path like so:

```lua
require('nvim-macros').setup({
    json_file_path = '/your/very/own/path/to/macros.json'
})
```

No config? No worries! nvim-macros will go with the flow and use a default path.

## Join the Party 🎉

Got ideas? Found a bug? Jump in and contribute! Whether it's a pull request or a hearty discussion in the issues, your input is what makes the nvim-macros party rock.

## To-Do 📝

nvim-macros is on a quest to make your Neovim experience even more magical! Here are some enchantments we're looking to add:

- [ ] **Macro Editing**: Forge a way to edit your macros directly within Neovim. This will involve summoning a macro from the JSON grimoire into a buffer, weaving your edits, and then sealing the updated macro back into the tome.

- [ ] **Macro Tags/Categories**: Introduce the mystic arts of tagging and categorizing your macros. This will allow you to filter and search through your macros based on their assigned tags or categories, managing your macro arsenal with unparalleled ease.

- [ ] **Macro Sharing/Importing**: Develop an incantation to export and import macros, empowering you to share your macros with fellow sorcerers or swiftly set up your macro sanctum on a new system.

- [ ] **Macro Analytics**: Offer a crystal ball to gaze into your macro usage, revealing insights such as the frequency of use, helping you to understand your workflow and refine your arsenal of macros.

Feel free to jump in and contribute if you're drawn to any of these upcoming features or if you have your own ideas to sprinkle some extra magic into nvim-macros! 🌟

## Inspiration 🌱

nvim-macros didn't just spring out of thin air; it's been nurtured by some awesome ideas and projects in the Neovim community. Here's a shoutout to the sparks that ignited this project:

- [nvim-macroni by Jesse Leite](https://github.com/jesseleite/nvim-macroni): Jesse's enlightening talk and his brilliantly simple plugin sowed the seeds for nvim-macros. It's all about taking those little steps towards macro mastery!
- [cd-project.nvim by LintaoAmons](https://github.com/LintaoAmons/cd-project.nvim): The innovative use of a JSON file for data storage in this project opened up new pathways for how nvim-macros could manage and store macro magic efficiently.

Big thanks to the creators and contributors of these projects! 🙏
