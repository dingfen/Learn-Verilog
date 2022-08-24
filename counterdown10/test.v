`timescale 10ns/1ns

module counter10_TB;

reg rstn;
reg clk;

wire cout;
wire [3:0] count;

initial
begin
    rstn = 1'b1;
    clk = 1'b0;
    #10 rstn = 1'b0;            // 按下rst 按钮后又弹起
    #12 rstn = 1'b1;

    
    repeat(100)
        #1 clk = ~clk;

    #10 $finish(2);

end

initial
begin            
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, counter10_TB);    //tb模块名称
end

    counter10 counter10_1 (
        // Inputs
        .rstn(rstn),
        .clk(clk),

        // Outputs
        .cout(cout),
        .cnt(count)
    );

endmodule