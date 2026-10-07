@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Lubricantes Arca - Servidor API
cd /d "%~dp0"

set "API_PORT=8000"
set "EXE="

rem Ubica el ejecutable del backend (instalado o en desarrollo)
if exist "%~dp0backend\api.exe"          set "EXE=%~dp0backend\api.exe"
if exist "%~dp0python_backend\api.exe"   set "EXE=%~dp0python_backend\api.exe"

rem ------------------------------------------------------------
rem 1) Evitar una segunda instancia si el puerto ya está escuchando
rem ------------------------------------------------------------
netstat -ano | findstr /C:":%API_PORT%" | findstr /C:"LISTENING" >nul
if %errorlevel%==0 (
    echo.
    echo  [i] Ya hay un servidor de Lubricantes Arca escuchando
    echo      en el puerto %API_PORT%. No se abre otra instancia.
    echo.
    timeout /t 5 >nul
    exit /b 0
)

rem ------------------------------------------------------------
rem 2) Iniciar el backend
rem ------------------------------------------------------------
if defined EXE (
    echo.
    echo  [*] Iniciando servidor de Lubricantes Arca...
    echo      %EXE%
    echo.
    rem Entrar al directorio del backend para que api.exe encuentre el .env
    for %%F in ("%EXE%") do cd /d "%%~dpF"
    start "Lubricantes Arca - Servidor API" /MIN "%EXE%"
) else (
    echo.
    echo  [*] No se encontro api.exe. Iniciando con Python (modo desarrollo)...
    echo.
    cd /d "%~dp0python_backend"
    python run.py
)

exit /b 0