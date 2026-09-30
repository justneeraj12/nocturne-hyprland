vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.fillchars = { eob = " ", vert = "│" }

local c = {
  bg = "#0f111a", panel = "#15161e", fg = "#c0caf5", muted = "#565f89",
  blue = "#7aa2f7", cyan = "#73daca", purple = "#bb9af7", green = "#9ece6a",
}

vim.cmd("highlight clear")
for group, style in pairs({
  Normal = { fg = c.fg, bg = c.bg },
  NormalFloat = { fg = c.fg, bg = c.panel },
  CursorLine = { bg = c.panel },
  LineNr = { fg = c.muted },
  CursorLineNr = { fg = c.blue, bold = true },
  StatusLine = { fg = c.bg, bg = c.blue, bold = true },
  StatusLineNC = { fg = c.muted, bg = c.panel },
  VertSplit = { fg = "#283457", bg = c.bg },
  NocturneLogo = { fg = c.blue, bold = true },
  NocturneHint = { fg = c.cyan },
  NocturneKey = { fg = c.purple, bold = true },
  NocturneDim = { fg = c.muted },
}) do
  vim.api.nvim_set_hl(0, group, style)
end

local function dashboard()
  if vim.fn.argc() ~= 0 then return end
  local logo = {
    "",
    "███╗   ██╗ ██████╗  ██████╗████████╗██╗   ██╗██████╗ ███╗   ██╗███████╗",
    "████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██║   ██║██╔══██╗████╗  ██║██╔════╝",
    "██╔██╗ ██║██║   ██║██║        ██║   ██║   ██║██████╔╝██╔██╗ ██║█████╗  ",
    "██║╚██╗██║██║   ██║██║        ██║   ██║   ██║██╔══██╗██║╚██╗██║██╔══╝  ",
    "██║ ╚████║╚██████╔╝╚██████╗   ██║   ╚██████╔╝██║  ██║██║ ╚████║███████╗",
    "╚═╝  ╚═══╝ ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝",
    "",
    "                 a quiet desktop for loud ideas",
    "",
    "              f   Find file       n   New file",
    "              g   Find text       r   Recent files",
    "              c   Config          q   Quit",
    "",
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, logo)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.cursorline = false
  for i = 1, 7 do vim.api.nvim_buf_add_highlight(buf, -1, "NocturneLogo", i, 0, -1) end
  vim.api.nvim_buf_add_highlight(buf, -1, "NocturneDim", 8, 0, -1)
  for i = 10, 12 do vim.api.nvim_buf_add_highlight(buf, -1, "NocturneHint", i, 0, -1) end
  vim.keymap.set("n", "f", ":find ", { buffer = buf })
  vim.keymap.set("n", "n", ":enew<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "g", ":vimgrep // **/*", { buffer = buf })
  vim.keymap.set("n", "r", ":oldfiles<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "c", ":edit $MYVIMRC<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "q", ":quit<CR>", { buffer = buf, silent = true })
end

vim.api.nvim_create_autocmd("VimEnter", { callback = dashboard })

