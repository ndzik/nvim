local Worktree = require("git-worktree")
local Path = require("plenary.path")

local function is_relearn()
    return not not (string.find(vim.loop.cwd(), "relearn", 1, true))
end

-- op = "switch", "create", "delete"
-- path = branch in which was swapped too
-- upstream = only present on create, upstream of create operation
Worktree.on_tree_change(function(op, path, _)
    if (op == "create" or op == "switch") and is_relearn() then
        -- vim.loop.chdir(worktree_path)
        local src_path = string.format("%s/relearn", path)
        if Path:new(src_path):exists() then
            local cmd = string.format("cd %s", src_path)
            vim.cmd(cmd)
        else
            error('Could not chang to directory: ' ..src_path)
        end
    end
end)
