#! /bin/sh

proj_name="fifo"

test_file="test.v"
source_file="fifo.v"

iverilog -o ${proj_name} ${source_file} ${test_file}
vvp -n ${proj_name}
gtkwave wave.vcd