module SignedAddition #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output overflow,
    output underflow,
    output [WIDTH-1:0] sum
);

    localparam MSB = WIDTH-1;
    wire cout;
    assign {cout, sum} = {a[MSB], a} + {b[MSB], b};
    assign overflow = {cout, sum[MSB]} == 2'b01;
    assign underflow = {cout, sum[MSB]} == 2'b10;

endmodule