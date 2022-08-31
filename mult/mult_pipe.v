module    mult_cell
    #(parameter N=4,
      parameter M=4)
    (
      input                     clk,
      input                     rstn,
      input                     en,
      input [M+N-1:0]           mult1,      //被乘数
      input [M-1:0]             mult2,      //乘数
      input [M+N-1:0]           mult1_acci, //上次累加结果

      output reg [M+N-1:0]      mult1_o,     //被乘数移位后保存值
      output reg [M-1:0]        mult2_shift, //乘数移位后保存值
      output reg [N+M-1:0]      mult1_acco,  //当前累加结果
      output reg                rdy );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rdy            <= 'b0 ;
            mult1_o        <= 'b0 ;
            mult1_acco     <= 'b0 ;
            mult2_shift    <= 'b0 ;
        end
        else if (en) begin
            rdy            <= 1'b1 ;
            mult2_shift    <= mult2 >> 1 ;
            mult1_o        <= mult1 << 1 ;
            if (mult2[0]) begin
                //乘数对应位为1则累加
                mult1_acco  <= mult1_acci + mult1 ;  
            end
            else begin
                mult1_acco  <= mult1_acci ; //乘数对应位为1则保持
            end
        end
        else begin
            rdy            <= 'b0 ;
            mult1_o        <= 'b0 ;
            mult1_acco     <= 'b0 ;
            mult2_shift    <= 'b0 ;
        end
    end

endmodule


module    mult_pipe
    #(parameter N=4,
      parameter M=4)
    (
      input                     clk,
      input                     rstn,
      input                     data_rdy ,
      input [N-1:0]             mult1,
      input [M-1:0]             mult2,

      output                    res_rdy ,
      output [N+M-1:0]          res );

    wire [N+M-1:0]       mult1_t [M-1:0] ;
    wire [M-1:0]         mult2_t [M-1:0] ;
    wire [N+M-1:0]       mult1_acc_t [M-1:0] ;
    wire [M-1:0]         rdy_t ;

    //第一次例化相当于初始化，不能用 generate 语句
    mult_cell      #(.N(N), .M(M))
    u_mult_step0
    (
      .clk              (clk),
      .rstn             (rstn),
      .en               (data_rdy),
      .mult1            ({{(M){1'b0}}, mult1}),
      .mult2            (mult2),
      .mult1_acci       ({(N+M){1'b0}}),
      //output
      .mult1_acco       (mult1_acc_t[0]),
      .mult2_shift      (mult2_t[0]),
      .mult1_o          (mult1_t[0]),
      .rdy              (rdy_t[0]) );

    //多次模块例化，用 generate 语句
    genvar               i ;
    generate
        for(i=1; i<=M-1; i=i+1) begin: mult_stepx
            mult_cell      #(.N(N), .M(M))
            u_mult_step
            (
              .clk              (clk),
              .rstn             (rstn),
              .en               (rdy_t[i-1]),
              .mult1            (mult1_t[i-1]),
              .mult2            (mult2_t[i-1]),
              //上一次累加结果作为下一次累加输入
              .mult1_acci       (mult1_acc_t[i-1]),
              //output
              .mult1_acco       (mult1_acc_t[i]),                                      
              .mult1_o          (mult1_t[i]),  //被乘数移位状态传递
              .mult2_shift      (mult2_t[i]),  //乘数移位状态传递
              .rdy              (rdy_t[i]) );
        end
    endgenerate

    assign res_rdy       = rdy_t[M-1];
    assign res           = mult1_acc_t[M-1];

endmodule