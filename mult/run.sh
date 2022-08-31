#! /bin/sh

proj_name="mult_low"

test_file="test.v"
source_file="mult_low.v"

iverilog -o ${proj_name} ${source_file} ${test_file}
vvp -n ${proj_name}
gtkwave wave.vcd