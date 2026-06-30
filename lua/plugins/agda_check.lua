local M = {}

local namespace = vim.api.nvim_create_namespace("agda-check")
local running_jobs = {}
local buffers_with_diagnostics = {}

local function joinpath(...)
    if vim.fs and vim.fs.joinpath then
        return vim.fs.joinpath(...)
    end

    return table.concat({ ... }, "/")
end

local function normalize_path(path)
    return vim.fn.fnamemodify(path, ":p")
end

local function buffer_file(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name == "" then
        return nil
    end

    return normalize_path(name)
end

local function file_directory(path)
    return vim.fn.fnamemodify(path, ":p:h")
end

local function find_agda_library_root(file)
    local directory = file_directory(file)

    while directory and directory ~= "" do
        local libraries = vim.fn.glob(joinpath(directory, "*.agda-lib"), false, true)

        if #libraries > 0 then
            return directory, libraries[1]
        end

        local parent = vim.fn.fnamemodify(directory, ":h")
        if parent == directory then
            return nil, nil
        end

        directory = parent
    end

    return nil, nil
end

local function check_spec(file)
    local root = find_agda_library_root(file)

    if root then
        return {
            command = { "agda", "--build-library" },
            cwd = root,
            key = root,
        }
    end

    local directory = file_directory(file)

    return {
        command = { "agda", vim.fn.fnamemodify(file, ":t") },
        cwd = directory,
        key = file,
    }
end

local function severity_from_text(text)
    text = text:lower()

    if text == "warning" or text == "warn" then
        return vim.diagnostic.severity.WARN
    end

    if text == "information" or text == "info" then
        return vim.diagnostic.severity.INFO
    end

    if text == "hint" then
        return vim.diagnostic.severity.HINT
    end

    return vim.diagnostic.severity.ERROR
end

local function parse_location(line)
    local file, start_line, start_col, end_line, end_col, severity, message =
        line:match("^(.-):(%d+)%.(%d+)%-(%d+)%.(%d+):%s*([%a]+):%s*(.*)$")

    if file then
        return {
            file = normalize_path(file),
            lnum = tonumber(start_line) - 1,
            col = tonumber(start_col) - 1,
            end_lnum = tonumber(end_line) - 1,
            end_col = tonumber(end_col),
            severity = severity_from_text(severity),
            source = "agda",
            message_lines = { message },
        }
    end

    file, start_line, start_col, end_col, severity, message =
        line:match("^(.-):(%d+)%.(%d+)%-(%d+):%s*([%a]+):%s*(.*)$")

    if file then
        return {
            file = normalize_path(file),
            lnum = tonumber(start_line) - 1,
            col = tonumber(start_col) - 1,
            end_lnum = tonumber(start_line) - 1,
            end_col = tonumber(end_col),
            severity = severity_from_text(severity),
            source = "agda",
            message_lines = { message },
        }
    end

    file, start_line, start_col, severity, message =
        line:match("^(.-):(%d+)%.(%d+):%s*([%a]+):%s*(.*)$")

    if file then
        local col = tonumber(start_col) - 1

        return {
            file = normalize_path(file),
            lnum = tonumber(start_line) - 1,
            col = col,
            end_lnum = tonumber(start_line) - 1,
            end_col = col + 1,
            severity = severity_from_text(severity),
            source = "agda",
            message_lines = { message },
        }
    end

    return nil
end

local function finish_diagnostic(diagnostics, diagnostic)
    if not diagnostic then
        return
    end

    while #diagnostic.message_lines > 1 and diagnostic.message_lines[#diagnostic.message_lines] == "" do
        table.remove(diagnostic.message_lines)
    end

    diagnostic.message = table.concat(diagnostic.message_lines, "\n")
    diagnostic.message_lines = nil

    if diagnostic.end_lnum == diagnostic.lnum and diagnostic.end_col <= diagnostic.col then
        diagnostic.end_col = diagnostic.col + 1
    end

    table.insert(diagnostics, diagnostic)
end

local function parse_output(output)
    local diagnostics = {}
    local current = nil

    for _, line in ipairs(vim.split(output, "\n", { plain = true })) do
        local next_diagnostic = parse_location(line)

        if next_diagnostic then
            finish_diagnostic(diagnostics, current)
            current = next_diagnostic
        elseif current then
            table.insert(current.message_lines, line)
        end
    end

    finish_diagnostic(diagnostics, current)

    return diagnostics
end

local function diagnostics_by_file(diagnostics)
    local grouped = {}

    for _, diagnostic in ipairs(diagnostics) do
        grouped[diagnostic.file] = grouped[diagnostic.file] or {}
        table.insert(grouped[diagnostic.file], diagnostic)
    end

    return grouped
end

local function reset_previous_diagnostics()
    for bufnr, _ in pairs(buffers_with_diagnostics) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.diagnostic.reset(namespace, bufnr)
        end
    end

    buffers_with_diagnostics = {}
end

local function diagnostic_type(severity)
    if severity == vim.diagnostic.severity.ERROR then
        return "E"
    end

    if severity == vim.diagnostic.severity.WARN then
        return "W"
    end

    if severity == vim.diagnostic.severity.INFO then
        return "I"
    end

    return "H"
end

local function set_quickfix(diagnostics)
    local items = {}

    for _, diagnostic in ipairs(diagnostics) do
        table.insert(items, {
            filename = diagnostic.file,
            lnum = diagnostic.lnum + 1,
            col = diagnostic.col + 1,
            end_lnum = diagnostic.end_lnum + 1,
            end_col = diagnostic.end_col,
            type = diagnostic_type(diagnostic.severity),
            text = diagnostic.message,
        })
    end

    vim.fn.setqflist({}, "r", {
        title = "AgdaCheck",
        items = items,
    })
end

local function fallback_diagnostic(file, output)
    local message = vim.trim(output)

    if message == "" then
        message = "agda exited with an error, but did not report a location"
    end

    return {
        file = file,
        lnum = 0,
        col = 0,
        end_lnum = 0,
        end_col = 1,
        severity = vim.diagnostic.severity.ERROR,
        source = "agda",
        message = message,
    }
end

local function apply_diagnostics(file, output, exit_code)
    local diagnostics = parse_output(output)

    if exit_code ~= 0 and #diagnostics == 0 then
        table.insert(diagnostics, fallback_diagnostic(file, output))
    end

    reset_previous_diagnostics()

    for diagnostic_file, file_diagnostics in pairs(diagnostics_by_file(diagnostics)) do
        local bufnr = vim.fn.bufadd(diagnostic_file)
        vim.diagnostic.set(namespace, bufnr, file_diagnostics, {})
        buffers_with_diagnostics[bufnr] = true
    end

    set_quickfix(diagnostics)

    if exit_code == 0 and #diagnostics == 0 then
        vim.notify("AgdaCheck passed", vim.log.levels.INFO)
    elseif #diagnostics > 0 then
        vim.notify("AgdaCheck found " .. #diagnostics .. " diagnostic(s)", vim.log.levels.WARN)
    end
end

local function cancel_previous_job(key)
    local job = running_jobs[key]
    running_jobs[key] = nil

    if job then
        pcall(function()
            job:kill(15)
        end)
    end
end

function M.check(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local file = buffer_file(bufnr)
    if not file then
        vim.notify("AgdaCheck requires a file-backed buffer", vim.log.levels.WARN)
        return
    end

    if vim.fn.executable("agda") ~= 1 then
        vim.notify("AgdaCheck could not find `agda` on PATH", vim.log.levels.ERROR)
        return
    end

    local spec = check_spec(file)
    cancel_previous_job(spec.key)

    local job
    job = vim.system(spec.command, {
        cwd = spec.cwd,
        text = true,
    }, function(result)
        if running_jobs[spec.key] ~= job then
            return
        end

        running_jobs[spec.key] = nil

        vim.schedule(function()
            local output = table.concat({ result.stdout or "", result.stderr or "" }, "\n")
            apply_diagnostics(file, output, result.code)
        end)
    end)

    running_jobs[spec.key] = job
end

local function first_line(message)
    return tostring(message):match("^[^\n]*") or ""
end

function M.setup()
    vim.diagnostic.config({
        signs = true,
        underline = true,
        update_in_insert = false,
        virtual_text = {
            source = "if_many",
            format = function(diagnostic)
                return first_line(diagnostic.message)
            end,
        },
    }, namespace)

    pcall(vim.api.nvim_del_user_command, "AgdaCheck")
    vim.api.nvim_create_user_command("AgdaCheck", function()
        M.check(0)
    end, { desc = "Run agda and publish diagnostics" })

    local augroup = vim.api.nvim_create_augroup("UserAgdaCheck", { clear = true })

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = augroup,
        pattern = { "*.agda", "*.lagda", "*.lagda.*" },
        callback = function(args)
            M.check(args.buf)
        end,
    })
end

return M
