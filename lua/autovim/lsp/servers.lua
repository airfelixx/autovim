-- One place to choose servers, pinned Mason versions, and project markers.
-- These are language servers; compilers/runtimes remain managed by the user.
return {
  clangd = {
    package = 'clangd', version = '23.1.0', label = 'C / C++',
    cmd = { 'clangd', '--background-index', '--clang-tidy', '--completion-style=detailed' },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
    markers = { '.clangd', 'compile_commands.json', 'compile_flags.txt', 'CMakeLists.txt', 'Makefile' },
  },
  asm_lsp = {
    package = 'asm-lsp', version = '0.10.1', label = 'Assembly', cmd = { 'asm-lsp' },
    filetypes = { 'asm', 'nasm', 'masm' }, markers = { '.asm-lsp.toml', 'compile_commands.json', 'Makefile' },
    install_tools = { 'cargo' },
  },
  jdtls = {
    package = 'jdtls', version = 'v1.62.0', label = 'Java', cmd = { 'jdtls' },
    filetypes = { 'java' }, markers = { 'pom.xml', 'build.gradle', 'build.gradle.kts', '.project' },
    tools = { 'java', 'python3' }, install_tools = { 'python3' },
  },
  pyright = {
    package = 'pyright', version = '1.1.414', label = 'Python', cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' }, markers = { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', 'requirements.txt' },
    tools = { 'node' }, install_tools = { 'node', 'npm' },
    settings = { python = { analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true, diagnosticMode = 'openFilesOnly' } } },
  },
  html = {
    package = 'html-lsp', version = '4.10.0', label = 'HTML', cmd = { 'vscode-html-language-server', '--stdio' },
    filetypes = { 'html' }, markers = { 'package.json' }, tools = { 'node' }, install_tools = { 'node', 'npm' },
    init_options = { provideFormatter = true, embeddedLanguages = { css = true, javascript = true }, configurationSection = { 'html', 'css', 'javascript' } },
  },
  cssls = {
    package = 'css-lsp', version = '4.10.0', label = 'CSS / SCSS / Less', cmd = { 'vscode-css-language-server', '--stdio' },
    filetypes = { 'css', 'scss', 'less' }, markers = { 'package.json' }, tools = { 'node' }, install_tools = { 'node', 'npm' },
    settings = { css = { validate = true }, scss = { validate = true }, less = { validate = true } },
  },
  ts_ls = {
    package = 'typescript-language-server', version = '6.0.2', label = 'JavaScript / TypeScript',
    cmd = { 'typescript-language-server', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' }, tools = { 'node' }, install_tools = { 'node', 'npm' },
    init_options = { hostInfo = 'neovim' },
  },
  rust_analyzer = {
    package = 'rust-analyzer', version = '2026-10-19', label = 'Rust', cmd = { 'rust-analyzer' },
    filetypes = { 'rust' }, markers = { 'Cargo.toml', 'rust-project.json' }, tools = { 'cargo', 'rustc' },
    settings = { ['rust-analyzer'] = { cargo = { allFeatures = true }, check = { command = 'check' } } },
  },
  gopls = {
    package = 'gopls', version = 'v0.23.0', label = 'Go', cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' }, markers = { 'go.work', 'go.mod' },
    tools = { 'go' }, install_tools = { 'go' }, settings = { gopls = { gofumpt = true } },
  },
  zls = {
    package = 'zls', version = '0.16.1', label = 'Zig', cmd = { 'zls' },
    filetypes = { 'zig' }, markers = { 'build.zig', 'build.zig.zon', 'zls.json' }, tools = { 'zig' },
  },
  nim_langserver = {
    package = 'nimlangserver', version = 'v1.16.0', label = 'Nim', cmd = { 'nimlangserver' },
    filetypes = { 'nim' }, markers = { 'nimble.nimble', 'nimble.toml', 'config.nims', 'nim.cfg' },
    tools = { 'nim', 'nimsuggest' },
  },
}
