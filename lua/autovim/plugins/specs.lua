return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- Compatible with Neovim 0.10/0.11; main needs newer Neovim.
    lazy = false, -- Upstream explicitly does not support lazy-loading this plugin.
    build = ":TSUpdate",
    config = function()
      local parser_dir = vim.fn.stdpath("data") .. "/treesitter"
      vim.fn.mkdir(parser_dir, "p")
      vim.opt.rtp:prepend(parser_dir)
      require("nvim-treesitter.configs").setup({
        parser_install_dir = parser_dir,
        ensure_installed = { "lua", "vim", "vimdoc", "query", "bash", "c", "cpp", "python", "cmake", "json", "yaml", "markdown", "markdown_inline",
          "asm", "nasm", "java", "html", "css", "javascript", "typescript", "tsx", "rust", "go", "gomod", "zig", "nim" },
        auto_install = false,
        sync_install = vim.env.AUTOVIM_BOOTSTRAP == "1",
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = false },
      })
    end,
  },
  {
    "mason-org/mason.nvim",
    tag = "v2.3.1",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    config = function() require("autovim.lsp.installer").setup() end,
  },
  {
    "hrsh7th/nvim-cmp", tag = "v0.0.2", event = "InsertEnter",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
    config = function() require("autovim.lsp.completion").setup() end,
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    tag = "0.1.8", -- Its API and Neovim requirements are known for this config.
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { defaults = {
      sorting_strategy = "ascending",
      layout_strategy = "horizontal",
      layout_config = { width = 0.9, height = 0.8, prompt_position = "top", preview_cutoff = 85 },
      border = true,
      winblend = 0,
      color_devicons = false,
      path_display = { "truncate" },
    } },
  },
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeHide" },
    init = function()
      vim.g.undotree_DiffAutoOpen = 0
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_StatusLine = 0
      vim.g.undotree_ShortIndicators = 1
      vim.g.undotree_CustomUndotreeCmd = "AutoVimUndoBuffer"
    end,
    config = function()
      -- Its public commands follow the same panel rules as the rail/keymap.
      for name, action in pairs({ UndotreeToggle = "toggle", UndotreeShow = "open", UndotreeHide = "close" }) do
        vim.api.nvim_create_user_command(name, function() require("autovim.sidebar")[action]("undo") end, { force = true })
      end
    end,
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    event = "VeryLazy", -- Restore saved tabline pins after the first screen renders.
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("autovim.harpoon").configure() end,
  },
}
