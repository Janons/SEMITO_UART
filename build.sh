#!/bin/bash
set -e # Stop if any command fails

echo "--- STARTING BUILD ---"
yosys -p "read_verilog transmitter.v topModule.v; synth_gowin -json hardware.json"
nextpnr-himbaechel --json hardware.json --write pnr.json --device GW1NR-LV9QN88PC6/I5 --vopt family=GW1N-9C --vopt cst=constraints.cst
gowin_pack -d GW1N-9C -o pack.fs pnr.json
sudo openFPGALoader -b tangnano9k pack.fs
echo "--- FLASH COMPLETE ---"