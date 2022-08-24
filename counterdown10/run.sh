#! /bin/sh

proj_name="counter10"

test_file="test.v"
source_file="counter10.v"

iverilog -o ${proj_name} ${source_file} ${test_file}
vvp -n ${proj_name}
gtkwave wave.vcd