# 除法器设计

## 原理

回想一下小学时我们如何做除法运算：例如，计算1274➗15：

```
          84
      ----------
  15 /  1274
        120
    ------------
          74
          60
    ------------
          14
```

事实上，二进制的除法运算与十进制的运算十分相似，举例计算27➗5：

```
              101   (5)
          ----------
 101 (5) /  11011   (27)
            101
        ------------
            0011
            0000
        ------------
              111
              101
        ------------
               10   (2)
```

通过观察，可总结除法运算过程如下（仅考虑无符号正数除法）：

1. 取被除数的高几位数据，位宽要与除数相同。
2. 将被除数高位数据与除数作比较
   1. 如果前者不小于后者，则可得到对应位的商为 1，两者做差得到第一步的余数
   2. 否则得到对应的商为 0，将前者直接作为余数。
3. 将上一步中的余数与被除数剩余最高位 1bit 数据拼接成新的数据，然后再和除数做比较。可以得到新的商和余数。
4. 重复过程 (3)，直到被除数最低位数据也参与计算。

注意，商的位宽应该与被除数保持一致，因为除数有可能为1，而余数的位宽至多与除数相同。此外，在实际编程中，第一步所要求的“取出位宽与除数相同的数据”难以实现（虽说人眼可以看出从哪里开始填数字，但计算机不行）。但硬件可以采取更笨拙的办法——高位补0。先取数字 27 最高位 1，再补两个前导0（即3'b001） 与 3'b101 做比较，此时得到商0，也不影响结果。

根据此计算过程，设计位宽可配置的流水线式除法器，流水延迟周期个数与被除数位宽一致。

## 单步流程

我们肯定想要得到一个能流水的除法器（否则性能就太差了😅）。而设计流水线除法器的**重点就是找到可重复可流水的部分**，然后通过输入输出数据的不断迭代得到结果。所以什么上面的流程中，哪些是可重复的呢？

仔细观察除法步骤：被除数的部分 bits 每次都要与除数比较，然后写下商（1或者0），然后商和被除数都需要右移一位，再继续比较。

BTW，先明确一下除法器的输入输出信号，以方便我们后续讨论。除了必要的那些，当然要有被除数 `[N-1:0] dividend` 和除数 `[M-1:0] divisor`，以及商 `[N-1:0] quotient` 和余数 `[M-1:0] remainder`。

```verilog
    input   clk,
    input   rstn,
    input   ready,

    input [N-1:0]   dividend,
    input [M-1:0]   divisor,

    output  res_ready,
    output [N-1:0]  quotient,
    output [M-1:0]  remainder
```

万事俱备！现在我们来用 verilog 实现一下**除法器中流水线的一级**：

> 被除数的部分 bits 每次都要与除数比较，然后写下商（1或者0），然后商和被除数都需要右移一位，再继续比较。

其实，抛开一切繁杂的细节（这只会让我们犹豫不决），上述语言转化为 verilog 代码其实就是：

```verilog
input   clk,
input   rstn,
input   data_ready,

input [M:0]               dividend,
input [M-1:0]             divisor,
input [N-M:0]             merchant_ci , //上一级输出的商
input [N-M-1:0]           dividend_ci , //原始除数

output reg [N-M-1:0]      dividend_kp,  //原始被除数信息
output reg [M-1:0]        divisor_kp,   //原始除数信息
output reg                rdy ,
output reg [N-M:0]        merchant ,  //运算单元输出商
output reg [M-1:0]        remainder   //运算单元输出余数

if (dividend >= divisor) begin
    quotient    <= (quotient<<1) + 1'b1;    // 商为1，右移动后写入
    remainder   <= dividend - divisor;      // 求余
end else begin
    quotient    <= quotient<<1;         // 商为0
    remainder   <= dividend;            // 余数不变
end
```

当然这样写肯定是不对的😅。但不必担心，编写 verilog 程序本就是不断试错的过程。然后，我们加上复位和非ready的情况，完善上面的代码：

```verilog
always@(posedge clk or negedge rstn) begin
    if (!rstn) begin
        res_ready <= 0;
        quotient  <= 0;
        remainder <= 0;
    end else if (data_ready) begin
        if (dividend >= divisor) begin
            quotient    <= (quotient<<1) + 1'b1;    // 商为1，右移动后写入
            remainder   <= dividend - divisor;      // 求余
        end else begin
            quotient    <= quotient<<1;         // 商为0
            remainder   <= dividend;            // 余数不变
        end
    end else begin
        res_ready <= 0;
        quotient  <= 0;
        remainder <= 0;
    end
end
```