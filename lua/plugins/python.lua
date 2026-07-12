-- Ajustes de Python por cima do extra `lang.python` do LazyVim.
-- O extra ja instala e configura pyright + ruff, lint e formatacao base.
-- Aqui so ficam as minhas mudancas.
return {
  -- pyright cuida so de hover e tipagem. Diagnostico fica com o ruff.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "off",
                diagnosticMode = "off",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        -- ignora regras especificas do ruff sem desligar o linter
        ruff = {
          init_options = {
            settings = {
              args = { "--ignore", "F821", "--ignore", "E402" },
            },
          },
        },
      },
    },
  },

  -- formatacao de Python com ruff: organiza imports e formata no save
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
    },
  },
}
