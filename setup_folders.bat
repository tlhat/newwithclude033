@echo off
chcp 65001 >nul
REM usage: put this file in the SAME folder as all downloaded files, then run:
REM   setup_folders.bat "C:\path\to\your\project"
if "%~1"=="" (
  echo Usage: setup_folders.bat "C:\path\to\your\project"
  exit /b 1
)
set P=%~1
if not exist "%P%\pubspec.yaml" (
  echo pubspec.yaml not found in %P%
  exit /b 1
)
mkdir "%P%\tools" 2>nul
mkdir "%P%\assets\audio" 2>nul
mkdir "%P%\lib\core\services" 2>nul
mkdir "%P%\lib\shared\components" 2>nul
mkdir "%P%\test" 2>nul

call :put local_audio_library.dart "%P%\lib\core\services"
call :put elevenlabs_voice_service.dart "%P%\lib\core\services"
call :put calm_voice_service.dart "%P%\lib\core\services"
call :put app_state_manager.dart "%P%\lib\shared\components"
call :put build_audio_index.py "%P%\tools"
call :put audio_manifest.json "%P%\tools"
call :put audio_index.json "%P%\assets\audio"
call :put local_audio_library_test.dart "%P%\test"
call :put pubspec.yaml "%P%"

for %%Z in (audio_storyteller audio_cheerful_friend audio_haneen audio_other) do (
  if exist "%%Z.zip.txt" ren "%%Z.zip.txt" "%%Z.zip"
  if exist "%%Z.zip" tar -xf "%%Z.zip" -C "%P%\assets\audio"
)
echo Done. Now run: python tools\build_audio_index.py
exit /b 0

:put
if exist "%~1.txt" ren "%~1.txt" "%~1"
if exist "%~1" (copy /Y "%~1" "%~2\%~1" >nul & echo placed %~1) else echo MISSING %~1
exit /b 0
