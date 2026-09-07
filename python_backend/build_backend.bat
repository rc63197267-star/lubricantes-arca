@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Compilar servidor de Lubricantes Arca (PyInstaller)
cd /d "%~dp0"

echo.
echo [*] Instalando dependencias del backend y PyInstaller...
python -m pip install --upgrade -r requirements.txt pyinstaller
if %errorlevel%==1 (
    echo [!] Fallo al instalar dependencias. Abortando.
    pause
    exit /b 1
)

echo.
echo [*] Compilando api.exe con PyInstaller...
pyinstaller --noconfirm --clean LubricantesArcaAPI.spec
if %errorlevel%==1 (
    echo [!] Fallo la compilacion. Abortando.
    pause
    exit /b 1
)

echo.
echo [*] Listo. El ejecutable esta en: dist\api.exe
echo     Copialo a la carpeta "backend" junto al instalador.
echo.
pause
exit /b 0