@echo off
setlocal
set "NODE_HOME=d:\node-v20.17.0-win-x64"
set "PATH=%NODE_HOME%;%PATH%"
set "DANGEROUSLY_OMIT_AUTH=true"

if not exist "%NODE_HOME%\npm.cmd" (
    echo ERROR: npm.cmd not found under %NODE_HOME%.
    pause
    exit /b 1
)

echo Starting MCP Inspector...
echo When the URL appears (e.g. http://localhost:6274/), open it in your browser

echo with:

echo   ?serversFile=d:/adaptopolis/tools/mcp_inspector_config.json

echo appended to the end. Example:

echo   http://127.0.0.1:6274/?serversFile=d:/adaptopolis/tools/mcp_inspector_config.json

echo --------------------------------------------------------------
call "%NODE_HOME%\npm.cmd" exec --package @modelcontextprotocol/inspector -- mcp-inspector
if errorlevel 1 (
    echo.
    echo MCP Inspector exited with an error.
    pause
) else (
    echo.
    echo MCP Inspector has terminated.
    pause
)
