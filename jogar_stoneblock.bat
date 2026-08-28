@echo off
:: Script de Sincronizacao Blindado com Auto-Launch - Stoneblock 2 (1.12.2)
chcp 65001 > nul
setlocal enabledelayedexpansion

:: ==========================================
:: CONFIGURAÇÕES REAIS (DIRETÓRIOS E GITHUB)
:: ==========================================
set "REPO_URL=https://github.com"
set "MINECRAFT_DIR=C:\Users\mateo.somavilla\AppData\Roaming\PrismLauncher\instances\FTB Presents Stoneblock 2\minecraft"
set "SAVES_DIR=%MINECRAFT_DIR%\saves\stoneblock"

:: 1. Trava Anti-Duplicacao: Impede rodar o script duas vezes
tasklist /fi "windowtitle eq SCRIPT_STONE_ATIVO" 2>nul | find /i "cmd.exe" >nul
if %errorlevel% equ 0 (
    echo [ERRO] O script ja esta rodando em outra janela! Fechando esta...
    timeout /t 3 >nul
    exit /b
)
title SCRIPT_STONE_ATIVO

:: 2. Executa Flush de Sistema Silencioso (Pre-Launch)
cmd /c "ipconfig /flushdns && del /q /f /s "%TEMP%\*" 2>nul"

:: Tenta localizar o executavel real do Prism Launcher
set "PRISM_EXE=C:\Program Files\Prism Launcher\prismlauncher.exe"
if not exist "%PRISM_EXE%" set "PRISM_EXE=%LOCALAPPDATA%\PrismLauncher\prismlauncher.exe"
if not exist "%PRISM_EXE%" set "PRISM_EXE=%APPDATA%\PrismLauncher\prismlauncher.exe"

if not exist "%SAVES_DIR%" mkdir "%SAVES_DIR%"

:: ==========================================
:: FLUXO GITHUB: ANTES DO JOGO (PULL)
:: ==========================================
echo =======================================================
echo [SINCRO] VERIFICANDO ATUALIZAÇÕES NO GITHUB...
echo =======================================================
cd /d "%SAVES_DIR%"

if not exist ".git" (
    echo [GITHUB] Inicializando repositorio Git na subpasta unica do mundo...
    git init
    git remote add origin %REPO_URL%
    echo [GITHUB] Verificando arquivos no repositorio remoto...
    git fetch origin
    git checkout main -f 2>nul
    git pull origin main --rebase 2>nul
) else (
    echo [GITHUB] Atualizando progresso do mundo com o GitHub...
    git pull origin main --rebase
)

:: ==========================================
:: INICIALIZAÇÃO TOTALMENTE AUTOMÁTICA
:: ==========================================
echo.
echo =======================================================
echo [JOGO] INICIANDO O STONEBLOCK 2 AUTOMATICAMENTE
echo =======================================================
echo [INFO] Disparando o jogo pelo motor do Prism Launcher...

if exist "%PRISM_EXE%" (
    start "" "%PRISM_EXE%" --launch "FTB Presents Stoneblock 2"
) else (
    start "" "C:\Users\mateo.somavilla\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Prism Launcher.lnk" --launch "FTB Presents Stoneblock 2"
)

echo [AGUARDANDO] Monitorando a inicializacao do Java...

:: Loop de espera: Aguarda o processo javaw.exe (Minecraft) iniciar
:esperar_jogo
timeout /t 2 /nobreak >nul
tasklist /fi "imagename eq javaw.exe" 2>nul | find /i "javaw.exe" >nul
if errorlevel 1 (
    goto esperar_jogo
)

echo [DETECTADO] Stoneblock 2 aberto com sucesso!
echo [INFO] O terminal ficara travado monitorando o jogo. Pode jogar em paz.

:: Loop de travamento: Fica aqui ate o javaw.exe fechar de verdade
:jogo_rodando
timeout /t 5 /nobreak >nul
tasklist /fi "imagename eq javaw.exe" 2>nul | find /i "javaw.exe" >nul
if errorlevel 1 (
    goto verificar_fechamento
)
goto jogo_rodando

:verificar_fechamento
if not exist "%SAVES_DIR%\level.dat" (
    echo.
    echo =======================================================
    echo [ALERTA CRÍTICO] O JOGO CRASHOU OU O MUNDO SUMIU!
    echo [SEGURANÇA] Envio cancelado para nao quebrar o seu backup remoto.
    echo =======================================================
    pause
    exit /b
)

:: ==========================================
:: FLUXO GITHUB: PÓS-JOGO (PUSH + AUTO-SCRIPT)
:: ==========================================
echo.
echo =======================================================
echo [GITHUB] MINECRAFT FECHADO NORMALMENTE! ENVIANDO BACKUP...
echo =======================================================
cd /d "%SAVES_DIR%"
git checkout main 2>nul || git checkout -b main

if exist "session.lock" del /q /f "session.lock"
copy /y "%~f0" "%SAVES_DIR%\jogar_stoneblock.bat" > nul

git add .
git commit -m "Backup automatico Stoneblock 2: %date% %time%"
git push origin main -f

echo.
echo =======================================================
echo [SUCESSO] PROGRESSO E SCRIPT ENVIADOS PARA O GITHUB!
echo [OK] O computador da PUC ja pode resetar em paz.
echo =======================================================
pause
exit /b
