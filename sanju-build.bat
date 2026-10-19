@echo off
setlocal
cd /d "%~dp0"
echo === Sanju Security OS builder ===

wsl --status >nul 2>&1
if errorlevel 1 goto install
wsl -d Debian --exec true >nul 2>&1
if errorlevel 1 goto install
goto run

:install
echo Installing WSL + Debian (run this file as Administrator the first time).
wsl --install -d Debian
echo.
echo Restart Windows if asked. Then open "Debian" from the Start menu once,
echo set a username/password, and run this file again.
pause
exit /b 1

:run
for /f "delims=" %%i in ('wsl -d Debian --exec wslpath -a "%cd%"') do set "WP=%%i"
echo Working folder in WSL: %WP%

wsl -d Debian --exec sed -i "s/\r$//" "%WP%/sanju-wsl-build.sh"
wsl -d Debian -u root --exec apt-get update -q
wsl -d Debian -u root --exec apt-get install -y -q sudo

wsl -d Debian --exec bash "%WP%/sanju-wsl-build.sh" "%WP%"
if errorlevel 1 (
  echo.
  echo BUILD FAILED. See the last lines above, or run:
  echo   wsl -d Debian --exec bash -c "tail -50 ~/sanju-security-os/build/build.log"
  pause
  exit /b 1
)
echo.
echo ISO is in: %cd%
pause
