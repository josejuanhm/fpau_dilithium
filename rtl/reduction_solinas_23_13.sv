`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022-2023 José Juan Hernández-Morales
// This source describes Open Hardware and is licensed under the CERN-OHL-W-2.0.
// You may redistribute and modify this source and make products using it under the terms of the
// CERN-OHL-W-2.0 (https://ohwr.org/cern_ohl_w_v2.txt), subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of this source.
//////////////////////////////////////////////////////////////////////////////////
// Author:      José Juan Hernández-Morales
// Create Date: 10/18/2022 10:07:45 PM
// Module Name: reduction_solinas_23_13
// Description: Solinas reduction designed for CRYSTALS-Dilithium (q = 8380417).
// Repository:  github.com/josejuanhm/fpau
//////////////////////////////////////////////////////////////////////////////////

`define MAX_BITS 23

module reduction_solinas_23_13(
    input wire[`MAX_BITS*2 - 1:0] in_c,
    output integer red_c
    );
    
    wire[22:0] t;
    wire[22:0] s1;
    wire[22:0] s2;
    wire[22:0] s3;
    wire[22:0] d1;
    wire[22:0] d2;
    wire[22:0] d3;
    
    assign t  = {in_c[22:0]};
    assign s1 = {in_c[32:23], 13'b0}; 
    assign s2 = {in_c[42:33], 13'b0}; 
    assign s3 = {7'b0, in_c[45:43], 13'b0};
    assign d1 = in_c[45:23];
    assign d2 = {10'b0, in_c[45:33]};
    assign d3 = {20'b0, in_c[45:43]};
    
    assign red_c = t + s1 + s2 + s3 - d1 - d2 - d3;
    
endmodule
