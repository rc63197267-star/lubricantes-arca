# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec para compilar el servidor API de Lubricantes Arca.
Genera: dist/api.exe  (estructura de un solo archivo)

Uso en Windows:
    pyinstaller LubricantesArcaAPI.spec
o (equivalente en un entorno con Python):
    pyinstaller --onefile --name api run.py --add-data ".env;." --add-data ".env.example;."
"""

import os

spec_dir = os.path.abspath(os.path.dirname(os.path.abspath(__file__))) if "__file__" in dir() else os.getcwd()

# Dependencias internas de uvicorn/fastapi que usan importación dinámica
hiddenimports = [
    "uvicorn",
    "uvicorn.logging",
    "uvicorn.loops",
    "uvicorn.loops.auto",
    "uvicorn.loops.asyncio",
    "uvicorn.protocols",
    "uvicorn.protocols.http",
    "uvicorn.protocols.http.auto",
    "uvicorn.protocols.http.h11_impl",
    "uvicorn.protocols.websockets",
    "uvicorn.protocols.websockets.auto",
    "uvicorn.lifespan",
    "uvicorn.lifespan.on",
    "anyio",
    "starlette",
    "starlette.middleware",
    "fastapi",
]

a = Analysis(
    [os.path.join(spec_dir, "run.py")],
    pathex=[spec_dir],
    binaries=[],
    datas=[
        (os.path.join(spec_dir, ".env.example"), "."),
    ],
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="api",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=os.path.join(os.path.dirname(spec_dir), "logo", "logo.ico"),
)