local M = {}

local default_symbols = {
  -- Core Agda / type-theory vocabulary.
  ["\\to"] = "→",
  ["\\->"] = "→",
  ["\\from"] = "←",
  ["\\<-"] = "←",
  ["\\mapsto"] = "↦",
  ["\\lambda"] = "λ",
  ["\\lam"] = "λ",
  ["\\forall"] = "∀",
  ["\\exists"] = "∃",
  ["\\circ"] = "∘",
  ["\\comp"] = "∘",

  -- Equality and relations.
  ["\\equiv"] = "≡",
  ["\\eq"] = "≡",
  ["\\neq"] = "≠",
  ["\\le"] = "≤",
  ["\\ge"] = "≥",
  ["\\approx"] = "≈",
  ["\\sim"] = "∼",

  -- Logic.
  ["\\not"] = "¬",
  ["\\and"] = "∧",
  ["\\or"] = "∨",
  ["\\top"] = "⊤",
  ["\\bot"] = "⊥",

  -- Common data/type symbols.
  ["\\Nat"] = "ℕ",
  ["\\N"] = "ℕ",
  ["\\Int"] = "ℤ",
  ["\\Z"] = "ℤ",
  ["\\Rat"] = "ℚ",
  ["\\Q"] = "ℚ",
  ["\\Real"] = "ℝ",
  ["\\R"] = "ℝ",
  ["\\times"] = "×",
  ["\\x"] = "×",
  ["\\sum"] = "Σ",
  ["\\Sigma"] = "Σ",
  ["\\prod"] = "Π",
  ["\\Pi"] = "Π",
  ["\\uplus"] = "⊎",
  ["\\::"] = "∷",
  ["\\in"] = "∈",
  ["\\notin"] = "∉",
  ["\\subset"] = "⊂",
  ["\\subseteq"] = "⊆",
  ["\\superset"] = "⊃",
  ["\\superseteq"] = "⊇",

  -- A few useful primes/subscripts/superscripts.
  ["\\'"] = "′",
  ["\\''"] = "″",
  ["\\_0"] = "₀",
  ["\\_1"] = "₁",
  ["\\_2"] = "₂",
  ["\\_3"] = "₃",
  ["\\_4"] = "₄",
  ["\\_5"] = "₅",
  ["\\_6"] = "₆",
  ["\\_7"] = "₇",
  ["\\_8"] = "₈",
  ["\\_9"] = "₉",
  ["\\^0"] = "⁰",
  ["\\^1"] = "¹",
  ["\\^2"] = "²",
  ["\\^3"] = "³",
  ["\\^4"] = "⁴",
  ["\\^5"] = "⁵",
  ["\\^6"] = "⁶",
  ["\\^7"] = "⁷",
  ["\\^8"] = "⁸",
  ["\\^9"] = "⁹",
}

local symbols = vim.deepcopy(default_symbols)

local function register_filetypes()
  vim.filetype.add({
    extension = {
      agda = "agda",
      lagda = "lagda",
    },
    pattern = {
      [".*%.lagda%.md"] = "lagda",
      [".*%.lagda%.org"] = "lagda",
      [".*%.lagda%.rst"] = "lagda",
      [".*%.lagda%.tex"] = "lagda",
      [".*%.lagda%.tree"] = "lagda",
      [".*%.lagda%.typ"] = "lagda",
    },
  })
end

local function ensure_current_filetype()
  if vim.bo.filetype ~= "" then
    return
  end

  local filetype = vim.filetype.match({ buf = 0 })
  if filetype == "agda" or filetype == "lagda" then
    vim.bo.filetype = filetype
  end
end

local function token_before_cursor()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)

  return before:match("(\\[%w_%-=<>|/%.:%+%*%?!'~%^#&]+)$")
end

local function sorted_symbol_entries()
  local entries = {}

  for abbreviation, expansion in pairs(symbols) do
    table.insert(entries, { abbreviation = abbreviation, expansion = expansion })
  end

  table.sort(entries, function(left, right)
    return left.abbreviation < right.abbreviation
  end)

  return entries
end

local function sorted_matches(token)
  local matches = {}

  for _, entry in ipairs(sorted_symbol_entries()) do
    if entry.abbreviation:sub(1, #token) == token then
      table.insert(matches, entry)
    end
  end

  return matches
end

local function markdown_code(value)
  return "`" .. tostring(value):gsub("`", "\\`"):gsub("|", "\\|") .. "`"
end

local function display_width(value)
  return vim.fn.strdisplaywidth(value)
end

local function pad_right(value, width)
  local padding = width - display_width(value)

  if padding <= 0 then
    return value
  end

  return value .. string.rep(" ", padding)
end

local function markdown_table_row(abbreviation, expansion, abbreviation_width, expansion_width)
  return "| "
    .. pad_right(abbreviation, abbreviation_width)
    .. " | "
    .. pad_right(expansion, expansion_width)
    .. " |"
end

local function abbreviation_table_column_widths(entries)
  local abbreviation_width = display_width("Abbreviation")
  local expansion_width = display_width("Expansion")

  for _, entry in ipairs(entries) do
    abbreviation_width = math.max(abbreviation_width, display_width(markdown_code(entry.abbreviation)))
    expansion_width = math.max(expansion_width, display_width(markdown_code(entry.expansion)))
  end

  return abbreviation_width, expansion_width
end

local function abbreviation_table_lines()
  local entries = sorted_symbol_entries()
  local abbreviation_width, expansion_width = abbreviation_table_column_widths(entries)
  local lines = {
    "# Agda abbreviations",
    "",
    "Press `<Tab>` in insert mode after a full abbreviation or unique prefix to expand it.",
    "",
    markdown_table_row("Abbreviation", "Expansion", abbreviation_width, expansion_width),
    markdown_table_row(string.rep("-", abbreviation_width), string.rep("-", expansion_width), abbreviation_width, expansion_width),
  }

  for _, entry in ipairs(entries) do
    table.insert(
      lines,
      markdown_table_row(markdown_code(entry.abbreviation), markdown_code(entry.expansion), abbreviation_width, expansion_width)
    )
  end

  return lines
end

local function notify_matches(token, matches)
  vim.schedule(function()
    local lines = {}
    for _, match in ipairs(matches) do
      table.insert(lines, match.abbreviation .. " → " .. match.expansion)
    end

    vim.notify(
      "Ambiguous Agda abbreviation: " .. token .. "\n" .. table.concat(lines, "\n"),
      vim.log.levels.INFO
    )
  end)
end

local function find_expansion(token)
  -- Exact matches win even if the token is also a prefix of longer names.
  if symbols[token] then
    return symbols[token]
  end

  local matches = sorted_matches(token)

  if #matches == 1 then
    return matches[1].expansion
  end

  if #matches > 1 then
    notify_matches(token, matches)
  else
    vim.schedule(function()
      vim.notify("Unknown Agda abbreviation: " .. token, vim.log.levels.INFO)
    end)
  end

  return nil
end

function M.expand_or_tab()
  local token = token_before_cursor()

  if not token then
    return "<Tab>"
  end

  local expansion = find_expansion(token)
  if not expansion then
    return ""
  end

  return string.rep("<BS>", #token) .. expansion
end

function M.open_abbreviations()
  vim.cmd("botright split")

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buffer)

  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "markdown"

  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, abbreviation_table_lines())
  vim.bo[buffer].modifiable = false

  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = buffer,
    silent = true,
    desc = "Close Agda abbreviation table",
  })
end

local function register_commands()
  pcall(vim.api.nvim_del_user_command, "AgdaAbbrv")
  vim.api.nvim_create_user_command("AgdaAbbrv", function()
    M.open_abbreviations()
  end, { desc = "Open Agda abbreviation table" })
end

function M.setup(opts)
  opts = opts or {}
  symbols = vim.tbl_extend("force", vim.deepcopy(default_symbols), opts.symbols or {})
  M.symbols = symbols

  register_filetypes()
  register_commands()

  local augroup = vim.api.nvim_create_augroup("UserAgdaSymbols", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "agda", "lagda" },
    callback = function(args)
      vim.keymap.set("i", "<Tab>", M.expand_or_tab, {
        buffer = args.buf,
        expr = true,
        desc = "Expand Agda symbol abbreviation",
      })
    end,
  })

  ensure_current_filetype()
end

M.symbols = symbols
M.default_symbols = default_symbols

return M
