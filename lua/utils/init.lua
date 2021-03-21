local utils = { }

local scopes = { o = vim.o, b = vim.bo, w = vim.wo, g = vim.g}

function utils.opt(scope, key, value)
    if scope == 'g' then
        scopes.g.key = value
        return
    end
	scopes[scope][key] = value
	if scope ~= 'o' then
		scopes['o'][key] = value
	end
end

-- utils.map allows the setting of neovim wide keymaps and not only limited to
-- buffers or windows.
function utils.map(mode, lhs, rhs, opts)
	MapKeyWithFunction(vim.api.nvim_set_keymap, mode, lhs, rhs, opts)
end

-- utils.mapbuf allows the setting of buffer-local keymaps for the current
-- buffer.
function utils.mapbuf(mode, lhs, rhs, opts)
    local apiFunc = function(m, l, r, o)
        vim.api.nvim_buf_set_keymap(0, m, l, r, o)
    end
    MapKeyWithFunction(apiFunc, mode, lhs, rhs, opts)
end

-- utils.letg allows setting of editor global variables.
function utils.letg(key, value)
    utils.opt('g', key, value)
end

function MapKeyWithFunction(api, mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    api(mode, lhs, rhs, options)
end

return utils
