@echo off
setlocal EnableExtensions DisableDelayedExpansion
pushd "%~dp0"
if errorlevel 1 goto error_carpeta

call "%~dp0setup.bat"
if errorlevel 1 goto error
echo Iniciando la interfaz de tiempo real en el puerto 30003...
".python\tools\python.exe" -E -s -B -X utf8 -u "codigos\tiempo_real.py"
set "UR_SALIDA=%errorlevel%"
goto finalizar

:error
set "UR_SALIDA=1"
:finalizar
echo.
if not "%UR_SALIDA%"=="0" echo El programa ha terminado con un error. Revisa el mensaje anterior.
pause
popd
exit /b %UR_SALIDA%

:error_carpeta
echo ERROR: No se puede abrir la carpeta del programa.
pause
exit /b 1
