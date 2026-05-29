@echo off
setlocal enabledelayedexpansion

:: ==============================
:: SET COMFYUI PATH
:: ==============================
set "SCRIPT_DIR=%~dp0"
set "COMFY_PATH=%SCRIPT_DIR%ComfyUI"
set "ALL_REQ=%COMFY_PATH%\all.txt"
set "FINAL_REQ=%COMFY_PATH%\final.txt"
set "LOG_FILE=%COMFY_PATH%\install.log"

echo Using ComfyUI at: %COMFY_PATH%

echo.
:: ==============================
:: ACTIVATE VENV
:: ==============================
if exist "%COMFY_PATH%\venv\Scripts\activate.bat" (
    call "%COMFY_PATH%\venv\Scripts\activate.bat"
)

echo.
:: ==============================
:: INSTALL CORE
:: ==============================
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r "%COMFY_PATH%\requirements.txt" --prefer-binary
if errorlevel 1 (
    echo ERROR: Failed to install core requirements.
    exit /b 1
)

echo.
:: ==============================
:: INSTALL CUSTOM NODES
:: ==============================
if exist "%ALL_REQ%" del /f /q "%ALL_REQ%"
if exist "%FINAL_REQ%" del /f /q "%FINAL_REQ%"

if exist "%COMFY_PATH%\custom_nodes" (
    for /r "%COMFY_PATH%\custom_nodes" %%f in (requirements.txt) do (
        if exist "%%f" (
            type "%%f" >> "%ALL_REQ%"
            echo. >> "%ALL_REQ%"
        )
    )
) else (
    echo No custom_nodes directory found.
)

echo Installing pip-tools...
python -m pip install pip-tools
if errorlevel 1 (
    echo ERROR: Failed to install pip-tools.
    exit /b 1
)

echo Compiling custom node requirements to "%FINAL_REQ%"...
python -m piptools.pip_compile "%ALL_REQ%" -o "%FINAL_REQ%" --resolver=backtracking > "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [!] Compile failed -> fallback to all.txt
    copy /y "%ALL_REQ%" "%FINAL_REQ%" >nul
) else (
    echo [+] Compile success
)

echo Installing custom node requirements...
python -m pip install -r "%FINAL_REQ%" --prefer-binary --upgrade-strategy only-if-needed >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo ERROR: pip install failed. Check "%LOG_FILE%" for details.
    exit /b 1
)

echo.
:: ==============================
:: FIX TORCH
:: ==============================
python -m pip uninstall torch torchvision torchaudio -y >nul 2>&1
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130
if errorlevel 1 (
    echo WARNING: Failed to reinstall torch packages from PyTorch index.
)

echo.
echo DONE!
pause