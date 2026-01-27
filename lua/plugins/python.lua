return {
  -- 1. Configurando o LSP (Language Server Protocol)
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- A chave 'servers' é onde definimos quais linguagens queremos
      servers = {

        -- Configuração do PYRIGHT (Focado em Hover e Tipagem)
        pyright = {
          settings = {
            python = {
              analysis = {
                -- Aqui replicamos as configs do artigo para ele não reclamar de tudo
                typeCheckingMode = "off",
                diagnosticMode = "off", -- Desliga diagnósticos (deixa pro Ruff)
                useLibraryCodeForTypes = true,
              },
            },
          },
          -- O LazyVim permite definir chaves (keymaps) específicas para o LSP aqui, se quiser
        },

        -- Configuração do RUFF (Focado em Linter e Velocidade)
        ruff = {
          -- Comandos para ignorar erros específicos (como no artigo)
          init_options = {
            settings = {
              args = { "--ignore", "F821", "--ignore", "E402" },
            },
          },
          -- Aqui está o "pulo do gato" para desligar o Hover do Ruff
          -- No LazyVim, podemos passar uma função para rodar quando o LSP liga
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },

  -- 2. Garantir que eles sejam instalados automaticamente
  -- O LazyVim usa o Mason, vamos garantir que ele baixe esses dois
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "ruff",
      },
    },
  },
}
