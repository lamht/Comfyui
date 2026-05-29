@echo off
setlocal enabledelayedexpansion

:: ==============================
:: SET SCRIPT AND BASE PATH
:: ==============================
set "SCRIPT_DIR=%~dp0"
set "COMFY_PATH=%SCRIPT_DIR%ComfyUI"
set "BASE=%COMFY_PATH%\models"
set "HF_HUB_ENABLE_HF_TRANSFER=1"

:: ==============================
:: HF TOKEN
:: ==============================
if "%HF_TOKEN%"=="" (
    echo ERROR: HF_TOKEN is not set.
    echo Set your Hugging Face token in the environment or uncomment the line below.
    echo.
    echo   set HF_TOKEN=hf_your_new_token_here
    echo.
    exit /b 1
)

:: ==============================
:: INSTALL HF CLI IF NEEDED
:: ==============================
 powershell -NoProfile -ExecutionPolicy Bypass -Command "if ((Get-Command hf -ErrorAction SilentlyContinue) -eq $null -and (Get-Command huggingface-cli -ErrorAction SilentlyContinue) -eq $null) { irm https://hf.co/cli/install.ps1 | iex }"
if errorlevel 1 (
    echo ERROR: Failed to install or find Hugging Face CLI.
    exit /b 1
)

:: ==============================
:: CHOOSE CLI COMMAND
:: ==============================
set "HF_CLI=huggingface-cli"
powershell -NoProfile -Command "if ((Get-Command hf -ErrorAction SilentlyContinue) -ne $null) { exit 0 } else { exit 1 }" >nul 2>&1
if errorlevel 1 (
    set "HF_CLI=huggingface-cli"
) else (
    set "HF_CLI=hf"
)

:: ==============================
:: LOGIN
:: ==============================
%HF_CLI% login --token %HF_TOKEN%
if errorlevel 1 (
    echo ERROR: Hugging Face login failed.
    exit /b 1
)

:: ==============================
:: CREATE MODEL FOLDERS
:: ==============================
if not exist "%BASE%" mkdir "%BASE%"
for %%D in ("%BASE%\loras" "%BASE%\diffusion_models" "%BASE%\clip" "%BASE%\vae") do (
    if not exist "%%~D" mkdir "%%~D"
)

:: ==============================
:: DOWNLOAD ASSETS
:: ==============================
set "FAIL=0"
%HF_CLI% download BuckyDroid/test_lora ^
  --include scg-anatomy-female-v2.safetensors ^
  --local-dir "%BASE%\loras"
if errorlevel 1 set "FAIL=1"

%HF_CLI% download Alissonerdx/BFS-Best-Face-Swap ^
  --include bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors ^
  --local-dir "%BASE%\loras"
if errorlevel 1 set "FAIL=1"

%HF_CLI% download black-forest-labs/FLUX.2-klein-9B ^
  --include flux-2-klein-9b.safetensors ^
  --local-dir "%BASE%\diffusion_models"
if errorlevel 1 set "FAIL=1"

%HF_CLI% download Comfy-Org/vae-text-encorder-for-flux-klein-9b ^
  --include split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors ^
  --local-dir "%BASE%\clip"
if errorlevel 1 set "FAIL=1"

%HF_CLI% download Comfy-Org/vae-text-encorder-for-flux-klein-9b ^
  --include split_files/vae/flux2-vae.safetensors ^
  --local-dir "%BASE%\vae"
if errorlevel 1 set "FAIL=1"

if "%FAIL%"=="1" (
    echo ERROR: One or more downloads failed.
    exit /b 1
)

echo Download complete!
endlocal