@echo off
setlocal EnableExtensions DisableDelayedExpansion
pushd "%~dp0"
if errorlevel 1 exit /b 1

rem Python y los paquetes se preparan dentro de esta carpeta, sin instaladores,
rem permisos de administrador, Internet ni Python del sistema. No se usa venv:
rem el Python incluido tambien funciona si despues se mueve toda la carpeta.
set "UR_PYTHON=%CD%\.python\tools\python.exe"
set "UR_PAQUETES=ImageIO==2.38.1 markdown-it-py==4.2.0 mdurl==0.1.2 meshio==5.3.5 numpy==2.4.6 pillow==12.3.0 psutil==7.2.2 pybullet==3.2.7 pybullet_planning==0.6.1 Pygments==2.21.0 recordclass==0.24.1 rich==15.0.0 scipy==1.17.1 termcolor==3.3.0"
set "UR_VERSION=import sys, struct, ssl, zipfile; from pip._internal.cli.main import main; sys.exit(not (sys.version_info[:3] == (3, 11, 9) and struct.calcsize('P') == 8))"

if not exist "%UR_PYTHON%" goto preparar_python
"%UR_PYTHON%" -I -c "%UR_VERSION%" >nul 2>&1
if not errorlevel 1 goto comprobar_runtime

:preparar_python
if not exist "material\python-3.11.9-win64.zip" goto faltan_archivos
echo Preparando el Python incluido. El primer arranque puede tardar un poco...
rem -Force tambien permite recuperar una extraccion que se interrumpio.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath 'material\python-3.11.9-win64.zip' -DestinationPath '.python' -Force"
if errorlevel 1 goto error_python
"%UR_PYTHON%" -I -c "%UR_VERSION%"
if errorlevel 1 goto error_python

:comprobar_runtime
rem PyBullet necesita MSVCP140. El wheel de Numpy ya incluye esta biblioteca
rem de Microsoft. Se conservan las licencias del wheel original y se usa tambien
rem la biblioteca con el nombre que pide PyBullet.
if exist ".python\tools\msvcp140.dll" goto comprobar_paquetes
if not exist "material\dependencias\numpy-2.4.6-cp311-cp311-win_amd64.whl" goto faltan_archivos
"%UR_PYTHON%" -I -c "import sys, zipfile; from pathlib import Path; z=zipfile.ZipFile('material/dependencias/numpy-2.4.6-cp311-cp311-win_amd64.whl'); names=[n for n in z.namelist() if n.startswith('numpy.libs/msvcp140-') and n.endswith('.dll')]; assert len(names)==1, 'No se encuentra la biblioteca MSVCP140 incluida'; target=Path(sys.executable).with_name('msvcp140.dll'); temp=target.with_suffix('.dll.tmp'); temp.write_bytes(z.read(names[0])); temp.replace(target); z.close()"
if errorlevel 1 goto error_runtime

:comprobar_paquetes
set "UR_COMPROBAR=from importlib.metadata import version; import os; pairs=[package.split('==') for package in os.environ['UR_PAQUETES'].split()]; assert all(version(name) == wanted for name,wanted in pairs); assert version('UR3e-rg2') == '0.1.0'; from UR3e_rg2.dynamic_ur3e import UR3eRG2; from importlib.resources import files; assert files('UR3e_rg2').joinpath('robot_description_files/ur3e_rg2/ur3e_rg2.urdf').is_file()"
"%UR_PYTHON%" -I -c "%UR_COMPROBAR%" >nul 2>&1
if not errorlevel 1 goto listo

if not exist "material\ur3e_rg2-0.1.0-py3-none-any.whl" goto faltan_archivos
if not exist "material\dependencias\*.whl" goto faltan_archivos
echo Preparando los paquetes incluidos. No hace falta Internet.
"%UR_PYTHON%" -I -m pip --isolated install --disable-pip-version-check --no-input --no-cache-dir --no-warn-script-location --force-reinstall --no-index --only-binary=:all: --find-links "material\dependencias" %UR_PAQUETES% "material\ur3e_rg2-0.1.0-py3-none-any.whl"
if errorlevel 1 goto error_instalacion
"%UR_PYTHON%" -I -m pip --isolated check
if errorlevel 1 goto error_instalacion
"%UR_PYTHON%" -I -c "%UR_COMPROBAR%"
if errorlevel 1 goto error_instalacion

:listo
echo Entorno preparado.
popd
exit /b 0

:faltan_archivos
echo ERROR: Faltan archivos del proyecto o de la carpeta material.
echo Extrae el ZIP completo. El BAT no funciona por separado.
goto error

:error_python
echo ERROR: No se ha podido preparar el Python incluido.
echo Necesitas Windows de 64 bits, el ZIP completo y una carpeta con permiso de escritura.
echo Puedes volver a ejecutar el BAT para reintentar la preparacion.
goto error

:error_instalacion
echo ERROR: No se han podido preparar las dependencias.
echo Revisa el mensaje anterior y que hayas extraido el ZIP completo.
goto error

:error_runtime
echo ERROR: No se ha podido preparar la biblioteca de Microsoft incluida.
echo Revisa el mensaje anterior y que puedas escribir en esta carpeta.

:error
popd
exit /b 1
