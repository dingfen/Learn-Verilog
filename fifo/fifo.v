module fifo
   #(
      parameter   BUF_WIDTH = 3,
      parameter   BUF_SIZE = 8
   )
   (
   // reset, system clock, write enable and read enable.
   input             rst,
   input             clk,
   input             wr_en,
   input             rd_en,
   // data input to be pushed to buffer
   input [7:0]       buf_in,
   // port to output the data using pop.
   output reg [7:0]  buf_out,
   // buffer empty and full indication
   output reg        buf_empty,
   output reg        buf_full,
   // number of data pushed in to buffer
   output reg [BUF_WIDTH :0] fifo_counter);

   // pointer to read and write addresses
   reg[BUF_WIDTH -1:0]  rd_ptr, wr_ptr;
   reg[7:0]             buf_mem[BUF_SIZE -1 : 0];

   always @(fifo_counter) begin
      buf_empty = (fifo_counter==0);
      buf_full = (fifo_counter== BUF_SIZE);
   end
   
   always @(posedge clk or posedge rst) begin
      if(rst)
         fifo_counter <= 0;
      else if((!buf_full && wr_en) && (!buf_empty && rd_en))
         fifo_counter <= fifo_counter;
   
      else if( !buf_full && wr_en )
         fifo_counter <= fifo_counter + 1;
   
      else if( !buf_empty && rd_en )
         fifo_counter <= fifo_counter - 1;
      else
         fifo_counter <= fifo_counter;
   end
   
   always @( posedge clk or posedge rst) begin
      if( rst )
         buf_out <= 0;
      else begin
         if( rd_en && !buf_empty )
            buf_out <= buf_mem[rd_ptr];
   
         else
            buf_out <= buf_out;
   
      end
   end
   
   always @(posedge clk) begin
      if(wr_en && !buf_full)
         buf_mem[ wr_ptr ] <= buf_in;
      else
         buf_mem[ wr_ptr ] <= buf_mem[ wr_ptr ];
   end
   
   always@(posedge clk or posedge rst) begin
      if( rst )
      begin
         wr_ptr <= 0;
         rd_ptr <= 0;
      end
      else
      begin
         if( !buf_full && wr_en )    wr_ptr <= wr_ptr + 1;
            else  wr_ptr <= wr_ptr;
   
         if( !buf_empty && rd_en )   rd_ptr <= rd_ptr + 1;
         else rd_ptr <= rd_ptr;
      end
   
   end
endmodule
