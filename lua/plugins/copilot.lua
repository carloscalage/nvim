return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true, -- habilita ghost text
          auto_trigger = true, -- sugere automaticamente
          keymap = {
            accept = "<Tab>", -- aceita sugestão com Tab
            next = "<M-]>", -- sugere próximo
            prev = "<M-[>", -- sugere anterior
            dismiss = "<C-]>", -- fecha sugestão
          },
        },
        panel = { enabled = false },
      })
    end,
  },
}
