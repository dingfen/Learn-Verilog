module counter10 (
    // ports
    input           rstn,
    input           clk,
    output [3:0]    cnt,
    output          cout);

    reg [3:0] cnt_reg;

    always @(posedge clk, negedge rstn) begin
        if (!rstn)
            cnt_reg <= 4'd10;
        else if (cnt_reg == 4'd0) begin
            cnt_reg <= 4'd10;
        end else begin
            cnt_reg <= cnt_reg - 1'b1;
        end
    end

    assign cout = (cnt_reg == 4'd0);
    assign cnt = cnt_reg;
    
endmodule