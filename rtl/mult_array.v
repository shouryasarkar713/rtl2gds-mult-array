//----------------------------------------------------------------------------
// mult_array.v
// 4-bit x 4-bit unsigned array multiplier, 8-bit product (Part A).
//
// Ports (Section 5 of the assignment):
//   clk   : input, 1 bit, rising-edge clock
//   rst_n : input, 1 bit, asynchronous reset, active low (clears all registers)
//   a     : input, 4 bits, multiplicand
//   b     : input, 4 bits, multiplier
//   p     : output, 8 bits, registered product a * b
//
// Structure (Section 2):
//   Row 0 : 4 AND gates (pp0 = a & b[0]).
//           p[0] = pp0[0]; the remaining bits pass down as
//           r0 = {1'b0, pp0[3], pp0[2], pp0[1]}.
//   Rows 1..3 : 4 AND gates + a chain of 4 full adders each (12 FAs total).
//           Row i adds partial product ppi to the value ri-1 passed down
//           from row i-1. The lowest sum bit of each row is a finished
//           product bit (p[1], p[2], p[3]); the top bits plus the final
//           carry become p[7:4].
//
// Registers: a_reg, b_reg (4+4 bits) and p (8 bits) = 16 flip-flops.
// Latency: 2 clock cycles (input regs -> combinational array -> output reg).
// Throughput: 1 result per cycle.
//
// The "*" operator is NOT used here (it is only allowed in the testbench).
// The array is built from 12 explicit instances of full_adder.
//----------------------------------------------------------------------------
`timescale 1ns/1ps

module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);

    //------------------------------------------------------------------
    // Input registers (asynchronous reset, active low)
    //------------------------------------------------------------------
    reg [3:0] a_reg, b_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'd0;
            b_reg <= 4'd0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    //------------------------------------------------------------------
    // Partial products: ppi[j] = a_reg[j] AND b_reg[i]  (16 AND gates)
    //------------------------------------------------------------------
    wire [3:0] pp0, pp1, pp2, pp3;

    assign pp0 = a_reg & {4{b_reg[0]}};
    assign pp1 = a_reg & {4{b_reg[1]}};
    assign pp2 = a_reg & {4{b_reg[2]}};
    assign pp3 = a_reg & {4{b_reg[3]}};

    //------------------------------------------------------------------
    // Row 0: AND gates only.
    //   p[0] = pp0[0] is finished; the remaining 3 bits pass down,
    //   shifted one column left: r0 = {0, pp0[3], pp0[2], pp0[1]}.
    //------------------------------------------------------------------
    wire [3:0] r0;
    assign r0 = {1'b0, pp0[3:1]};

    //------------------------------------------------------------------
    // Row 1: full adders fa10..fa13
    //   FA j adds pp1[j], r0[j] and carry c1[j]; c1[0] = 0.
    //   p[1] = s1[0]; r1 = {c1[4], s1[3], s1[2], s1[1]} passes down.
    //------------------------------------------------------------------
    wire [3:0] s1;
    wire [4:0] c1;

    full_adder fa10 (pp1[0], r0[0], c1[0], s1[0], c1[1]);
    full_adder fa11 (pp1[1], r0[1], c1[1], s1[1], c1[2]);
    full_adder fa12 (pp1[2], r0[2], c1[2], s1[2], c1[3]);
    full_adder fa13 (pp1[3], r0[3], c1[3], s1[3], c1[4]);

    assign c1[0] = 1'b0;
    wire [3:0] r1;
    assign r1 = {c1[4], s1[3:1]};

    //------------------------------------------------------------------
    // Row 2: full adders fa20..fa23 (same pattern, inputs pp2 and r1)
    //------------------------------------------------------------------
    wire [3:0] s2;
    wire [4:0] c2;

    full_adder fa20 (pp2[0], r1[0], c2[0], s2[0], c2[1]);
    full_adder fa21 (pp2[1], r1[1], c2[1], s2[1], c2[2]);
    full_adder fa22 (pp2[2], r1[2], c2[2], s2[2], c2[3]);
    full_adder fa23 (pp2[3], r1[3], c2[3], s2[3], c2[4]);

    assign c2[0] = 1'b0;
    wire [3:0] r2;
    assign r2 = {c2[4], s2[3:1]};

    //------------------------------------------------------------------
    // Row 3: full adders fa30..fa33 (inputs pp3 and r2).
    //   p[3] = s3[0]; p[7:4] = {c3[4], s3[3], s3[2], s3[1]}.
    //------------------------------------------------------------------
    wire [3:0] s3;
    wire [4:0] c3;

    full_adder fa30 (pp3[0], r2[0], c3[0], s3[0], c3[1]);
    full_adder fa31 (pp3[1], r2[1], c3[1], s3[1], c3[2]);
    full_adder fa32 (pp3[2], r2[2], c3[2], s3[2], c3[3]);
    full_adder fa33 (pp3[3], r2[3], c3[3], s3[3], c3[4]);

    assign c3[0] = 1'b0;

    //------------------------------------------------------------------
    // Combinational product (collect the finished bits)
    //   prod[0]=pp0[0], prod[1]=s1[0], prod[2]=s2[0], prod[3]=s3[0],
    //   prod[7:4] = {c3[4], s3[3:1]}
    //------------------------------------------------------------------
    wire [7:0] prod;
    assign prod = {c3[4], s3[3:1], s3[0], s2[0], s1[0], pp0[0]};

    //------------------------------------------------------------------
    // Output register (asynchronous reset, active low)
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 8'd0;
        end else begin
            p <= prod;
        end
    end

endmodule
