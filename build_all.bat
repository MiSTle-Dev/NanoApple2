
@echo off
set GWSH=C:\Gowin\Gowin_V1.9.10.03_x64\IDE\bin\gw_sh

echo.
echo ============ build nano 20k  ===============
echo.
%GWSH% build_tn20k.tcl
echo.
echo ============ build console 60k LCD ===============
echo.
%GWSH% build_tc60k.tcl
echo.

echo "done."
dir impl\pnr\*.fs

