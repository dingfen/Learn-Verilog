#! /bin/sh

proj_name="mult_low"

test_file="test.v"
source_file="mult_low.v"


if test $1 = "pipe"
then
    proj_name="mult_pipe"
    test_file="test_pipe.v"
    source_file="mult_pipe.v"
else
    proj_name="mult_low"
    test_file="test.v"
    source_file="mult_low.v"
fi

iverilog -o ${proj_name} ${source_file} ${test_file}
vvp -n ${proj_name}
gtkwave wave.vcd