local function rebuild_project(co, path)
  local spinner = require("easy-dotnet.ui-modules.spinner").new()
  spinner:start_spinner "Building"
  vim.fn.jobstart(string.format("dotnet build %s", path), {
    on_exit = function(_, return_code)
      if return_code == 0 then
        spinner:stop_spinner "Built successfully"
      else
        spinner:stop_spinner("Build failed with exit code " .. return_code, vim.log.levels.ERROR)
        error "Build failed"
      end
      coroutine.resume(co)
    end,
  })
  coroutine.yield()
end

return {
  -- CSharp support
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "c_sharp" })
      end
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "csharpier" })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "csharp_ls" })
    end,
  },
  {
    "Decodetalkers/csharpls-extended-lsp.nvim",
    dependencies = {
      {
        "AstroNvim/astrolsp",
        opts = vim.fn.has "nvim-0.11" == 1
            and {
              handlers = {
                csharp_ls = function(server, opts)
                  require("lspconfig")[server].setup(opts)
                  require("csharpls_extended").buf_read_cmd_bind()
                end,
              },
            }
          or { -- TODO: drop when dropping support for Neovim v0.10
            config = {
              csharp_ls = {
                handlers = {
                  ["textDocument/definition"] = function(...) require("csharpls_extended").handler(...) end,
                  ["textDocument/typeDefinition"] = function(...) require("csharpls_extended").handler(...) end,
                },
              },
            },
          },
      },
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "coreclr" })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed =
        require("astrocore").list_insert_unique(opts.ensure_installed, { "csharp-language-server", "netcoredbg" })
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "Issafalcon/neotest-dotnet", config = function() end },
    opts = function(_, opts)
      if not opts.adapters then opts.adapters = {} end
      table.insert(opts.adapters, require "neotest-dotnet"(require("astrocore").plugin_opts "neotest-dotnet"))
    end,
  },
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    config = function()
      local dotnet = require "easy-dotnet"
      dotnet.setup()
      local wk = require "which-key"
      wk.add {
        { "<leader>n", group = "dotnet" },
        { "<leader>nc", dotnet.clean, desc = "Clean" },
        { "<leader>nb", dotnet.build, desc = "Build" },
        { "<leader>ns", dotnet.secrets, desc = "Secrets" },
        { "<leader>np", group = "package" },
        { "<leader>npa", dotnet.add_package, desc = "Add package" },
        { "<leader>npr", dotnet.remove_package, desc = "Remove package" },
        { "<leader>nl", dotnet.run, desc = "Run" },
        { "<leader>npu", dotnet.restore, desc = "Restore" },
        { "<leader>nt", group = "Test" },
        { "<leader>ntr", dotnet.testrunner, desc = "Test Runner" },
        { "<leader>ntt", dotnet.test, desc = "Test" },
      }
    end,
  },
  {
    "mfussenegger/nvim-dap",
    enabled = true,
    config = function()
      local dap = require "dap"
      local dotnet = require "easy-dotnet"
      local dapui = require "dapui"
      dap.set_log_level "TRACE"

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      vim.keymap.set("n", "q", function()
        dap.close()
        dapui.close()
      end, {})

      -- vim.keymap.set("n", "<F5>", dap.continue, {})
      -- vim.keymap.set("n", "<F10>", dap.step_over, {})
      -- vim.keymap.set("n", "<leader>dO", dap.step_over, {})
      -- vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, {})
      -- vim.keymap.set("n", "<leader>dr", dap.repl.toggle, {})
      -- vim.keymap.set("n", "<leader>dj", dap.down, {})
      -- vim.keymap.set("n", "<leader>dk", dap.up, {})
      -- vim.keymap.set("n", "<F11>", dap.step_into, {})
      -- vim.keymap.set("n", "<F12>", dap.step_out, {})
      -- vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, {})
      -- vim.keymap.set("n", "<F2>", require("dap.ui.widgets").hover, {})

      local function file_exists(path)
        local stat = vim.loop.fs_stat(path)
        return stat and stat.type == "file"
      end

      local debug_dll = nil

      local function ensure_dll()
        if debug_dll ~= nil then return debug_dll end
        local dll = dotnet.get_debug_dll()
        debug_dll = dll
        return dll
      end

      for _, value in ipairs { "cs", "fsharp" } do
        dap.configurations[value] = {
          {
            type = "coreclr",
            name = "launch - netcoredbg",
            request = "launch",
            env = function()
              local dll = ensure_dll()
              local vars = dotnet.get_environment_variables(dll.project_name, dll.absolute_project_path, false)
              return vars or nil
            end,
            program = function()
              local dll = ensure_dll()
              local co = coroutine.running()
              rebuild_project(co, dll.project_path)
              if not file_exists(dll.target_path) then
                error("Project has not been built, path: " .. dll.target_path)
              end
              return dll.target_path
            end,
            cwd = function()
              local dll = ensure_dll()
              return dll.absolute_project_path
            end,
            stopAtEntry = false,
          },
        }

        dap.listeners.before["event_terminated"]["easy-dotnet"] = function() debug_dll = nil end

        dap.adapters.coreclr = {
          type = "executable",
          command = "netcoredbg",
          args = { "--interpreter=vscode" },
        }
      end
    end,
    dependencies = {
      { "nvim-neotest/nvim-nio" },
      {
        "rcarriga/nvim-dap-ui",
        config = function() require("dapui").setup() end,
      },
    },
  },
}
