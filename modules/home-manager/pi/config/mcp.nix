{
  context7 = {
    url = "https://mcp.context7.com/mcp";
    description = "Fetch current library documentation";
    exposure = "codemode";
  };
  codegraph = {
    args = [ ];
    description = "Read-only code graph MCP server; indexing remains explicit";
    exposure = "codemode";
  };
  engram = {
    args = [ ];
    description = "Pi-profile-local Engram memory; not shared with OpenCode";
    exposure = "codemode";
  };
}
