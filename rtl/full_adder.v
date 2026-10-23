//----------------------------------------------------------------------------
// full_adder.v
// 1-bit full adder, combinational.
//
// Ports (as required by the assignment, Section 5):
//   a, b, cin  : inputs
//   sum, cout  : outputs
//
// Written with assign statements only (Part A requirement).
//----------------------------------------------------------------------------
`timescale 1ns/1ps

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    // sum = XOR of the three inputs
    assign sum  = a ^ b ^ cin;

    // carry-out = majority function of the three inputs
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule
