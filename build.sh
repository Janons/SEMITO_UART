#!/bin/bash

# Stop on any error
set -e

echo "-- Starting Synthesis --"
yosys -p "read_verilog *.v; synth_gowin -json hardware.json"

echo "-- Starting Place & Route --"
nextpnr-gowin --json hardware.json \
              --write pnr.json \
              --device GW1NR-LV9QN88PC6/I5 \
              --family GW1N-9C \
              --cst constraints.cst

echo "-- Generating Bitstream --"
gowin_pack -d GW1N-9C -o pack.fs pnr.json

echo "-- Programming FPGA --"
openFPGALoader -b tangnano9k pack.fs