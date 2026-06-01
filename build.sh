#!/usr/bin/env bash
set -e
export PATH="$HOME/.local/bin:$PATH"

# ── Config ──────────────────────────────────────────────
TOP="topModule"
DEVICE="GW1NR-LV9QN88PC6/I5"
FAMILY="GW1N-9C"
BOARD="tangnano9k"
SOURCES="src/topModule.v src/transmitter.v src/receiver.v src/fifo.v"
CST="cst/constraints.cst"
# ────────────────────────────────────────────────────────

mkdir -p impl

# Clean
if [[ "$1" == "--clean" ]]; then
    rm -rf impl && echo "Cleaned." && exit 0
fi

# Step 1 — Synthesis
echo "▶ Synthesizing..."
yosys -p "read_verilog $SOURCES; synth_gowin -top $TOP -json impl/top.json"

# Step 2 — Place & Route
echo "▶ Place & Route..."
nextpnr-himbaechel \
    --json  impl/top.json  \
    --write impl/pnr.json  \
    --device "$DEVICE"     \
    --vopt family="$FAMILY"\
    --vopt cst="$CST"

# Step 3 — Bitstream
echo "▶ Packing bitstream..."
gowin_pack -d "$FAMILY" -o impl/pack.fs impl/pnr.json

echo "✔ Build done → impl/pack.fs"

# Flash (optional)
if [[ "$1" == "--flash" ]]; then
    echo "▶ Flashing..."
    openFPGALoader -b "$BOARD" impl/pack.fs
    echo "✔ Flashed!"
else
    echo "  Run './build.sh --flash' to upload to the board"
fi