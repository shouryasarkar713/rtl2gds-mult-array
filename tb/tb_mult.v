//----------------------------------------------------------------------------
// tb_mult.v
// Exhaustive, self-checking testbench for mult_array (Part A).
//
// Requirements implemented (assignment, Part A):
//   * clock with a 10 ns period;
//   * rst_n held low for the first 2 clock cycles;
//   * applies all 256 input combinations (a = 0..15, b = 0..15);
//   * for each combination waits for the 2-cycle latency, then compares
//     p with the expected value a * b ("*" is allowed in the testbench only);
//   * prints a line for every mismatch;
//   * at the end prints exactly one summary line:
//         PASS: 256 vectors checked, 0 errors
//     or  FAIL: 256 vectors checked, <n> errors
//   * writes the waveform file mult.vcd.
//----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_mult;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;
    wire [7:0] p;

    integer    i, j;
    integer    errors;

    //------------------------------------------------------------------
    // Device under test
    //------------------------------------------------------------------
    mult_array dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    //------------------------------------------------------------------
    // Clock: 10 ns period (toggle every 5 ns)
    //------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    //------------------------------------------------------------------
    // Stimulus + checking
    //------------------------------------------------------------------
    initial begin
        // waveform dump
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        errors = 0;
        rst_n  = 1'b0;      // reset asserted
        a      = 4'd0;
        b      = 4'd0;

        // hold rst_n low for the first 2 clock cycles
        @(posedge clk);
        @(posedge clk);
        #1  rst_n = 1'b1;   // release reset just after the 2nd edge

        // apply all 256 input combinations
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a = i[3:0];
                b = j[3:0];

                // 2-cycle latency: edge 1 captures a/b into the input
                // registers, edge 2 captures the product into p
                @(posedge clk);
                @(posedge clk);
                #3;  // let outputs settle (also safe for unit-delay GLS)

                if (p !== (a * b)) begin
                    errors = errors + 1;
                    $display("MISMATCH: a=%0d b=%0d -> p=%0d, expected %0d",
                             a, b, p, a * b);
                end
            end
        end

        // exactly one summary line
        if (errors == 0)
            $display("PASS: 256 vectors checked, 0 errors");
        else
            $display("FAIL: 256 vectors checked, %0d errors", errors);

        $finish;
    end

endmodule
