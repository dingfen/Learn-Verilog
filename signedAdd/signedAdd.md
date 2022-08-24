# 有符号的加减法实现

## 溢出

当两个数相加，由于得到的和表示的位宽有限，会出现结果溢出导致计算错误的情况：
1. 当两个正数 a 与 b 相加，会得到一个负数 s，且 $ s = a + b - 2^{WIDTH} $
2. 当两个负数 a 与 b 相加，会得到一个正数 s，且 $ s = a + b + 2^{WIDTH} $

## 举例说明

检查加法是否出现下溢出和上溢出：首先简单地分析一下 4-bit 的例子。为更方便地展示出是否出现溢出，我自己多扩展了第 5 个 bit：


例1：正常运算，未发生溢出：
```
  3 : [0]0011
+ 3 : [0]0011
= 6 : [0]0110
```

例2：负数的正常运算：
```
  -3 : [1]1101 
+ -3 : [1]1101
= -6 : [1]1010
```

例3：正数相加产生过大的结果，发生上溢出，注意到 +8 是无法用 4-bit 的补码表示的：
```
  +7 : [0]0111
+ +1 : [0]0001 
= +8 : [0]1000
```

例4：负数相加产生过小的结果，发生下溢出，-9 无法用 4-bit 的补码表示：
```
  -8 : [1]1000
+ -1 : [1]1111
= -9 : [1]0111 
```

## 观察得出规律

注意到，是否产生了上溢出和下溢出，都可以通过多增加的 1 bit 符号位的变化判断。当多增加的 1 bit 与最高位为 01 时，产生了上溢出；为 10 时，产生了下溢出。因此在 verilog 实现时，一个小技巧是多增加一位加法运算，利用多增加的符号位，轻松地判断出加法是否产生上溢出/下溢出：

```verilog
localparam WIDTH = 4;
localparam MSB   = WIDTH-1;
logic [WIDTH-1:0] a;
logic [WIDTH-1:0] b;
logic [WIDTH-1:0] result;
logic extra;
logic overflow;
logic underflow;


always @* begin
  {extra, result} = {a[MSB], a} + {b[MSB], b} ;
  overflow  = ({extra, result[MSB]} == 2’b01 );
  underflow = ({extra, result[MSB]} == 2’b10 );
end
```

Regarding multiplication I do not understand why you can not have a 32 bit register. even if you reduce the final output to 16.

When performing the bit reduction you would need to check that the value is under the max and above the minimum negative number that you can support with the reduced width.

NB: In addition the result grows 1 bit bigger than largest input. The overflow/underflow occurs when truncating back to original width.

With multiplication the result is the width of both added together, 16bits * 16bits results in a 32 bit answer. Pretty sure you do not need 33 bits. If you do not keep the full width then it is pretty hard to tell if the result will overflow when truncated. It is quite common to design these things with a wide combinatorial result and only output so many bits through a flip-flop for the final output from the ALU.

I think that keeping a 32 bit output and comparing it to the max/min of a signed 16 bit number, will synthesise smaller than only using 16 bit multiplier and extra logic to detect the overflow condition.