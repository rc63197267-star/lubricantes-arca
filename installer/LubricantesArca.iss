; ============================================================
; Lubricantes Arca - Instalador de Windows (Inno Setup 6)
; ============================================================
; Genera: LubricantesArca-Setup.exe
;
; El instalador NO instala XAMPP ni MySQL. Solo instala:
;   - La aplicacion Flutter Windows (LubricantesArca.exe)
;   - El backend Python compilado (backend/api.exe)
;   - Configuracion (.env), logo y acceso directo en el escritorio.
;
; Requisitos previos para compilar este instalador:
;   1) flutter build windows --release
;   2) python_backend\build_backend.bat  (genera python_backend\dist\api.exe)
;   3) Inno Setup 6 instalado.
; ============================================================

#define MyAppName "Lubricantes Arca"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Lubricantes Arca"
#define MyAppExeName "LubricantesArca.exe"

[Setup]
AppId={{8A4E9C6B-3F1E-4D2B-9A7C-1B5D8E3F6A20}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Se instala por usuario (sin pedir permisos de administrador). El puerto 8000 no requiere admin.
PrivilegesRequired=lowest
OutputDir=..\
OutputBaseFilename=LubricantesArca-Setup
SetupIconFile=..\logo\logo.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Informar que el servidor/API debe estar corriendo (lo maneja el acceso directo/autostart)
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "autostart"; Description: "Iniciar el servidor (API) automaticamente al encender Windows"; GroupDescription: "Opciones de inicio:"; Flags: checkedonce

[Files]
; --- Aplicacion Flutter Windows (Release) ---
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion createallsubdirs
; --- Backend Python compilado ---
Source: "..\python_backend\dist\api.exe"; DestDir: "{app}\backend"; Flags: ignoreversion
; --- Configuracion de la base de datos (no se sobrescribe al reinstalar) ---
Source: "..\python_backend\.env"; DestDir: "{app}\backend"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "..\python_backend\.env.example"; DestDir: "{app}\backend"; Flags: ignoreversion uninsneveruninstall
; --- Script de inicio del servidor ---
Source: "..\start_server.bat"; DestDir: "{app}"; Flags: ignoreversion
; --- Logo ---
Source: "..\logo\logo.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Acceso directo principal en el escritorio
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\logo.ico"; WorkingDir: "{app}"
; Acceso directo para iniciar/detener manualmente el servidor
Name: "{userdesktop}\{#MyAppName} - Iniciar Servidor"; Filename: "{app}\start_server.bat"; IconFilename: "{app}\logo.ico"; WorkingDir: "{app}"
; Menu de inicio
Name: "{userprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\logo.ico"; WorkingDir: "{app}"
; Arranque automatico del servidor con Windows (solo si se marco la tarea)
Name: "{userstartup}\{#MyAppName} - Servidor"; Filename: "{app}\start_server.bat"; IconFilename: "{app}\logo.ico"; WorkingDir: "{app}"; Tasks: autostart

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir {#MyAppName} ahora"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\backend\__pycache__"

[Code]
// Verifica que existan los archivos necesarios antes de compilar el instalador.
function InitializeSetup(): Boolean;
begin
  Result := True;
end;

// Tras instalar: si no existe .env, crea uno por defecto desde .env.example.
procedure CurStepChanged(CurStep: TSetupStep);
var
  EnvFile, EnvExample: String;
begin
  if CurStep = ssPostInstall then
  begin
    EnvFile := ExpandConstant('{app}\backend\.env');
    EnvExample := ExpandConstant('{app}\backend\.env.example');
    if (not FileExists(EnvFile)) and FileExists(EnvExample) then
    begin
      FileCopy(EnvExample, EnvFile, False);
    end;
  end;
end;