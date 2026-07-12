-- Peek: abre uma previa legivel de JSON/JSONL num buffer scratch, sem tocar no arquivo.
-- Util para dataset de treinamento minificado (tudo em uma linha).
--   <leader>jp  -> leitura em arvore (expande \n e json embutido)  json: arquivo todo | jsonl: linha do cursor
--   <leader>jP  -> JSON identado valido
--   :Peek / :PeekJson  aceitam range (ex.: selecao visual)
local M = {}

local script = vim.fn.stdpath("config") .. "/scripts/peek.py"
local counter = 0

local function get_lines(range)
  if range == "line" then
    return { vim.api.nvim_get_current_line() }
  elseif type(range) == "table" then
    return vim.api.nvim_buf_get_lines(0, range[1] - 1, range[2], false)
  end
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function open_scratch(lines, mode)
  counter = counter + 1
  vim.cmd("botright vsplit")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, "peek://" .. mode .. "/" .. counter)

  if mode == "json" then
    vim.bo[buf].filetype = "json"
  else
    -- arvore: sem filetype (nao e yaml valido), realce leve feito na mao
    pcall(vim.fn.matchadd, "Comment", "[│├└─▪]") -- conectores esmaecidos
    pcall(vim.fn.matchadd, "Special", "(json)") -- marcador de json embutido
    pcall(vim.fn.matchadd, "Title", "^# record \\d\\+") -- separador de registros
    pcall(vim.fn.matchadd, "Identifier", "\\v(─ |^)@<=[^ :]+:@=") -- chave antes de ':'
  end

  -- q fecha a previa
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true })
end

function M.peek(mode, range)
  local input = table.concat(get_lines(range), "\n")
  local out = vim.fn.system({ "python3", script, "--mode", mode }, input)
  if vim.v.shell_error ~= 0 then
    vim.notify(out, vim.log.levels.ERROR, { title = "Peek" })
    return
  end
  open_scratch(vim.split(out, "\n", { plain = true }), mode)
end

-- jsonl: previa da linha do cursor. json: arquivo todo.
local function smart_range()
  if vim.bo.filetype == "jsonl" or vim.fn.expand("%:e") == "jsonl" then
    return "line"
  end
  return nil
end

vim.api.nvim_create_user_command("Peek", function(o)
  M.peek("tree", o.range > 0 and { o.line1, o.line2 } or smart_range())
end, { range = true, desc = "Peek JSON/JSONL legivel" })

vim.api.nvim_create_user_command("PeekJson", function(o)
  M.peek("json", o.range > 0 and { o.line1, o.line2 } or smart_range())
end, { range = true, desc = "Peek JSON identado" })

vim.keymap.set("n", "<leader>jp", function() M.peek("tree", smart_range()) end, { desc = "Peek legivel" })
vim.keymap.set("x", "<leader>jp", ":Peek<cr>", { desc = "Peek legivel (selecao)" })
vim.keymap.set("n", "<leader>jP", function() M.peek("json", smart_range()) end, { desc = "Peek JSON identado" })

return M
