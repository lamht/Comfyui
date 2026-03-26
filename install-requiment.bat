@echo off

:: ==============================
:: SET COMFYUI PATH
:: ==============================
set COMFY_PATH=%~dp0ComfyUI

echo Using ComfyUI at: %COMFY_PATH%

:: ==============================
:: ACTIVATE VENV
:: ==============================
if exist "%COMFY_PATH%\venv\Scripts\activate.bat" (
    call "%COMFY_PATH%\venv\Scripts\activate.bat"
)

:: ==============================
:: INSTALL CORE
:: ==============================
pip install -r "%COMFY_PATH%\requirements.txt"

:: ==============================
:: INSTALL CUSTOM NODES
:: ==============================
for /d %%d in ("%COMFY_PATH%\custom_nodes\*") do (
    if exist "%%d\requirements.txt" (
        echo Installing %%d
        pip install -r "%%d\requirements.txt" --upgrade --no-cache-dir
    )
)

echo DONE!
pause