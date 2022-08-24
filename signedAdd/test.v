`timescale 10ns/1ns

module SignedAddition_TB;

localparam WIDTH = 16;

reg [WIDTH-1:0] a;
reg [WIDTH-1:0] b;
wire [WIDTH-1:0] sum;
wire underflow;
wire overflow;

initial
begin
    a = 16'h7101;
    b = 16'h0a41;

    #10 a = 16'h0602;
    #10 b = 16'h0451;

    #10 a = 16'h8654;
    #10 b = 16'hEa00;

    #10 a = 16'h7fff;
    #10 b = 16'h0511;

    #10 $finish(2);

end

initial
begin            
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, SignedAddition_TB);    //tb模块名称
end

    SignedAddition #(
        .WIDTH(WIDTH)
    ) SignedAddition_1 (
        // Inputs
        .a(a),
        .b(b),

        // Outputs
        .sum(sum),
        .overflow(overflow),
        .underflow(underflow)
    );

endmodule