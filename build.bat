@echo off
echo.
echo === Starting Tang Nano 9K Build ===

:: Create impl folder if it doesn't exist
if not exist impl mkdir impl

echo.
echo [1/4] Synthesizing with Yosys...
yosys -p "read_verilog src/topModule.v src/transmitter.v src/receiver.v; synth_gowin -top topModule -json impl/top.json"
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo [2/4] Place and Route with NextPNR...
nextpnr-himbaechel --json impl/top.json --write impl/pnr.json --device GW1NR-LV9QN88PC6/I5 --vopt family=GW1N-9C --vopt cst=cst/constraints.cst
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo [3/4] Packing Bitstream...
gowin_pack -d GW1N-9C -o impl/pack.fs impl/pnr.json
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo [4/4] Flashing to Board...
openFPGALoader -b tangnano9k impl/pack.fs

echo.
echo === Build Complete! ===
pause