return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui" }, -- Optional: UI for nvim-dap
      { "theHamsta/nvim-dap-virtual-text" }, -- Optional: Inline virtual text
      { "leoluz/nvim-dap-go", ft = "go" }, -- Optional: Debug Go
      { "nvim-neotest/nvim-nio" },
    },
    config = function()
      local dap = require("dap")

      -- go debugging
      require("dap-go").setup()

      -- Keybindings for dap (example)
      vim.keymap.set("n", "<leader>dd", function()
        dap.continue()
      end, { desc = "Start/Continue Debugging" })
      vim.keymap.set("n", "<F10>", function()
        dap.step_over()
      end, { desc = "Step Over" })
      vim.keymap.set("n", "<F11>", function()
        dap.step_into()
      end, { desc = "Step Into" })
      vim.keymap.set("n", "<F12>", function()
        dap.step_out()
      end, { desc = "Step Out" })
      vim.keymap.set("n", "<leader>db", function()
        dap.toggle_breakpoint()
      end, { desc = "Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>dc", function()
        dap.clear_breakpoints()
      end, { desc = "Clear Breakpoints" })

      -- Optional: Configure UI
      require("dapui").setup()
      vim.keymap.set("n", "<leader>du", function()
        require("dapui").toggle()
      end, { desc = "Toggle DAP UI" })

      -- Optional: Virtual text for debugging
      require("nvim-dap-virtual-text").setup()
    end,
  },
}
