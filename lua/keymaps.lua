-- Move current line or selection up/down

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Normal mode
keymap("n", "<A-Up>", ":m .-2<CR>==", opts)
keymap("n", "<A-Down>", ":m .+1<CR>==", opts)
keymap("n", "<A-;>", "<Esc>mzA;<Esc>`z")
keymap("n", "<A-,>", "<Esc>mzA,<Esc>`z")

-- Insert mode
keymap("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", opts)
keymap("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", opts)
keymap("i", "<A-;>", "<Esc>mzA;<Esc>`za")
keymap("i", "<A-,>", "<Esc>mzA,<Esc>`za")

-- Visual mode
keymap("v", "<A-Up>", ":m '<-2<CR>gv=gv", opts)
keymap("v", "<A-Down>", ":m '>+1<CR>gv=gv", opts)

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  callback = function()
    -- Insert mode keymap: Ctrl+\ closes terminal
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>:q<CR>]], {
      buffer = true,
      noremap = true,
      silent = true,
    })

    vim.keymap.set("n", "<Esc><Esc>", [[<C-\><C-n>:q<CR>]], {
      buffer = true,
      noremap = true,
      silent = true,
    })

    -- vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
  end,
})

local wk = require "which-key"
local get_icon = require("astroui").get_icon

-- harpoon
local harpoon = require "harpoon"
wk.add {
  { "<leader>a", group = get_icon("Bookmarks", 1, true) .. "Harpoon" },
  { "<leader>a ", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, desc = "Toggle quick menu" },
  { "<leader>aa", function() harpoon:list():add() end, desc = "Add file to harpoon" },
  { "<leader>ah", function() harpoon:list():prev() end, desc = "Goto previous mark" },
  { "<leader>al", function() harpoon:list():next() end, desc = "Goto next mark" },
}

-- yank
local function yank_and_restore(motion)
  return function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("normal " .. motion)
    vim.api.nvim_win_set_cursor(0, pos)
  end
end

wk.add {
  { "<leader>y", group = "Yank" },
  { "<leader>ya", "<Cmd>%y<CR><CR>", desc = "Yank all text from file" },
  { "<leader>yf", yank_and_restore "yaf", desc = "Yank function" },
  { "<leader>yk", yank_and_restore "yak", desc = "Yank current block" },
  { "<leader>yi", yank_and_restore "yai", desc = "Yank current scope" },
}

local function spotify_terminal()
  local astro = require "astrocore"
  astro.toggle_term_cmd { cmd = "spotify_player", direction = "float" }
end

wk.add {
  { "<leader>ts", spotify_terminal, desc = "Spotify" },
}
