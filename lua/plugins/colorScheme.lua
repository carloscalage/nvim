return {
  -- Este bloco não instala plugin, só executa o config
  config = function()
    local function set_colorscheme()
      if vim.o.background == "dark" then
        vim.cmd("colorscheme poimandres")
      else
        vim.cmd("colorscheme tokyonight-day")
      end
    end

    set_colorscheme()

    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "background",
      callback = set_colorscheme,
    })
  end,
  lazy = false,
  priority = 999,
}
