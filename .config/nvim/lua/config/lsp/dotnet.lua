vim.lsp.config("roslyn_ls", {
  cmd = {
    "dotnet",
    "/home/envilogger/work/roslyn-ls/content/LanguageServer/linux-x64/Microsoft.CodeAnalysis.LanguageServer.dll",
    "--logLevel",
    "Debug",
    "--extensionLogDirectory",
    "/tmp/roslyn_ls/logs",
    "--stdio",
  },
})

vim.lsp.enable("roslyn_ls")
