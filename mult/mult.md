# 乘法器设计——初版

## 最初

也许有人会问，直接用乘号 * 来完成 2 个数的相乘不是更快更简单吗？如果你有这个疑问，说明你对硬件描述语言的认知还有所不足。就像之前所说，Verilog 描述的是硬件电路，直接用乘号完成相乘过程，编译器在编译的时候也会把这个乘法表达式映射成默认的乘法器，但其构造程序员不得而知。

例如，在 FPGA 设计中，可以直接调用 IP 核来生成一个高性能的乘法器。在位宽较小的时候，一个周期内就可以输出结果，位宽较大时也可以流水输出。在能满足要求的前提下，谨慎的用 * 或直接调用 IP 来完成乘法运算。但乘法器 IP 也有很多的缺陷，例如位宽的限制，未知的时序等。尤其使用乘号，会为数字设计的不确定性埋下很大的隐瞒。

很多时候，常数的乘法都会用移位相加的形式实现，例如：

```verilog
A = A<<1 ;       //完成A * 2
A = (A<<1) + A ;   //对应A * 3
A = (A<<3) + (A<<2) + (A<<1) + A ; //对应A * 15
```

## 思考与原理

**有时候数字电路在一个周期内并不能够完成多个变量同时相加的操作**。所以数字设计中，最保险的加法操作是同一时刻只对 2 个数据进行加法运算。如果设计中对过多数据同时进行加法运算，那么该设计就会有危险，可能导致时序不满足。此时，设计参数可配、时序可控的流水线式乘法器就显得有必要了。

从小学学到的十进制乘法得到的启示，二进制的乘法计算也是类似的。例如：

```
        1 1 0 1 (13)    mult1
    x     1 0 1 (5)     mult2
 ----------------------
        1 1 0 1
      0 0 0 0
    1 1 0 1
 ----------------------
    1 0 0 0 0 1 (65)    sum
```


由此可知，被乘数按照乘数对应 bit 位进行移位累加，便可完成相乘的过程。假设每个周期只能完成一次累加，那么一次乘法计算时间最少的时钟数恰好是乘数的位宽。**因此，将位宽窄的数当做乘数，以缩短计算周期。**

将两个乘数分别记为 `mult1` 和 `mult2`，再记最终积为 `product`。Verilog 代码如下：

```verilog
  input [N-1:0]     mult1,
  input [M-1:0]     mult2,
  output [N+M-1:0]  product,
```

思路：每次根据 `mult2` 的 LSB 位决定是否累加 `mult1` 到 `product` 中，然后右移动 `mult2`，并要左移 `mult1` 一位，直到 `mult2` 为 0。

思路理清楚后，就是用 Verilog 代码实现，由于 Verilog 语法限制，需要做到以下几步：
1. 将 wire 类型的数据全放到 reg 类型，然后在 always 模块中操作
2. 需要用户额外提供两个输入的数据何时有效的信号（否则一直在那边尬算），而乘法器也需要提供输出何时有效的信号
3. 上述思路的直接实现需要用到循环，但可综合语句中可不能这样写，因此需要一个计数器

## 实现步骤

接下来开始细致拆分代码实现过程。首先是定义需要的 reg 数据类型

```verilog
  input             data_rdy,
  input             clk,
  input             rstn,
  output            product_rdy,

  //multiply
  reg [M-1:0]       mult2_shift ;
  reg [M+N-1:0]     mult1_shift ;
  reg [M+N-1:0]     mult1_acc ;
  //calculate counter
  reg [31:0]        cnt ;
  //乘法周期计数器
  wire [31:0]       cnt_next;
```

然后，假设 `mult2` 的位数是最短的那个（这里的假设有点不太严谨，但先不管这个）。我们要设计一个计数器，计数拍数为 M （即 `mult2` 的位数），
以方便知晓何时乘法器的移位加法可以完成。并要求，该计数器必须在等到 `data_rdy` 信号就绪后才能开始计数，计数过程中乘法器需要跟着节奏工作。
但需要注意，`data_rdy` 信号可能在 M 拍之内就会被撤回，而计数器必须要计数到 M 拍才行。

```verilog
  assign cnt_next = (cnt == M)? 'b0 : cnt + 1'b1;

  always@(posedge clk, negedge rstn) begin
    if (!rstn) begin
        cnt <= 'b0;
    end else if (data_rdy || cnt != 0) begin
        cnt <= cnt_next;
    end else
        cnt <= 'b0;
  end
```

然后就是乘法器本体的设计，按照之前思路说的，左移 `mult1` 每一拍需要左移一位，而 `mult2` 要右移动一位。当然，需要在计数器开始计数时，初始化各个移位器和累加器的值，注意 `cnt` 为 0 时就已经把 `mult2` 放入到 `mult2_acc` 中了，所以拍数没问题。

```verilog
  always@(posedge clk, negedge rstn) begin
    if (!rstn) begin
        // do not mention that
        mult2_shift <= 'b0;
        mult1_shift <= 'b0;
        mult1_acc   <= 'b0;
    end else if (data_rdy && cnt == 'b0) begin    // 初始化
        mult1_shift <= {{(N){1'b0}}, mult1} << 1 ;
        mult2_shift <= mult2 >> 1 ;
        mult1_acc   <= mult2[0] ? {{(N){1'b0}}, mult1} : 'b0 ;
    end else if (cnt != M) begin
        mult1_shift <= mult1_shift << 1 ;  //被乘数乘2
        mult2_shift <= mult2_shift >> 1 ;  //乘数右移，方便判断
        //判断乘数对应为是否为1，为1则累加
        mult1_acc <= mult2_shift[0] ? mult1_acc + mult1_shift : mult1_acc ;
    end else begin
        mult2_shift <= 'b0;
        mult1_shift <= 'b0;
        mult1_acc   <= 'b0;
    end
  end

```

最后，需要把得到的积输出，在计数器计数到 M 拍时，结果就出来了：

```verilog
//results
  reg [M+N-1:0]        product_r ;
  reg                  product_rdy_r ;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      product_r          <= 'b0 ;
      product_rdy_r      <= 'b0 ;
    end else if (cnt == M) begin
      product_r          <= mult1_acc ;  //乘法周期结束时输出结果
      product_rdy_r      <= 1'b1 ;
    end else begin
      product_r          <= 'b0 ;
      product_rdy_r      <= 'b0 ;
    end
  end
  
  assign product_rdy       = product_rdy_r;
  assign product           = product_r;
```