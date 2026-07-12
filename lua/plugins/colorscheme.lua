-- Segue o modo claro/escuro do sistema (macOS).
-- Le o AppleInterfaceStyle direto do SO, entao funciona ate dentro do tmux.
return {
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      update_interval = 3000, -- checa o sistema a cada 3s
      set_dark_mode = function()
        vim.o.background = "dark"
        vim.cmd.colorscheme("tokyonight-night")
      end,
      set_light_mode = function()
        vim.o.background = "light"
        vim.cmd.colorscheme("tokyonight-day")
      end,
    },
  },
}
