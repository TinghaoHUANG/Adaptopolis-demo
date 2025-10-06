@echo off
setlocal

set "GODOT_PATH=d:\Godot_v4.4-stable_win64_console.exe"
set "NODE_HOME=d:\node-v20.17.0-win-x64"
set "PATH=%NODE_HOME%;%PATH%"

echo Starting Godot MCP server...
if not exist "%GODOT_PATH%" (
    echo ERROR: Godot executable not found: %GODOT_PATH%
    pause
    exit /b 1
)
if not exist "%NODE_HOME%\node.exe" (
    echo ERROR: Node.exe not found under %NODE_HOME%
    pause
    exit /b 1
)

pushd d:\godot-mcp >nul 2>&1
if errorlevel 1 (
    echo ERROR: Could not change directory to d:\godot-mcp
    pause
    exit /b 1
)

echo Using Godot at %GODOT_PATH%
echo Using Node at %NODE_HOME%\node.exe
echo (leave this window open while the MCP server is running)
echo.
"%NODE_HOME%\node.exe" build\index.js
if errorlevel 1 (
    echo.
    echo Godot MCP server exited with an error.
    pause
)

popd >nul 2>&1
