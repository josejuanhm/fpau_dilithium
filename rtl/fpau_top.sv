`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022-2023 José Juan Hernández-Morales
// This source describes Open Hardware and is licensed under the CERN-OHL-W-2.0.
// You may redistribute and modify this source and make products using it under the terms of the
// CERN-OHL-W-2.0 (https://ohwr.org/cern_ohl_w_v2.txt), subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of this source.
//////////////////////////////////////////////////////////////////////////////////////////////////
// Author:      José Juan Hernández-Morales
// E-mail:      josejuanhm@inaoep.mx
// Create Date: 10/19/2022 05:33:43 PM
// Module Name: fpau_top
// Description: Finite field polynomial arithmetic unit, designed to be inserted 
//              within a RISC-V processor.
// Repository:  https://github.com/josejuanhm/fpau
//////////////////////////////////////////////////////////////////////////////////////////////////

typedef enum {FPAU_IDLE, FPAU_MULT_DONE, FPAU_REDUCTION, FPAU_READY} state_t;
state_t fpau_state = FPAU_IDLE;

`define MULTIPLE_CYCLES

`define MAX_BITS 23

module fpau_top(
    input wire CLK,
    input wire en,
    input wire [3:0] op,
    input wire signed [31:0] a0,
    input wire signed [31:0] a1,
    input wire signed [31:0] acc,
    input wire signed [31:0] omega,
`ifdef MULTIPLE_CYCLES
    output reg signed[31:0] rsum,
    output reg signed[31:0] out2
`else
    output wire signed[31:0] rsum,
    output wire signed[31:0] out2
`endif
    );
    
    ////////////////////////
    // Signals definition //
    ////////////////////////
`ifdef MULTIPLE_CYCLES
    reg[3:0] op_reg;
    integer a11_reg;
    integer mux11_reg;
    reg en_reg;
`endif
    
    integer muxntt_mult;
    integer muxntt_subsum;
    
    integer mux1;
    integer mux11;
    integer mux2;
    integer mux22;
    integer a11;
    integer modsum_correction;
    integer modsub_correction;
    integer modsub_correction2;

    wire[`MAX_BITS*2 - 1:0] mult;

    integer mult_reduced_dilithium;
    integer mult_reduced_kyber;
    //integer mult_reduced;
    integer mult_reduced_complete;
    integer mult_reduced_complete_centered;
    integer rsub;
    integer b;
    integer rsum_prev;
    integer rsub_prev;
    integer rsub_prev2;
    integer rsum_prev_i;
    integer rsub_prev_i;
    integer rsub_prev_i2;
    
    integer rsub_prev2_inv;
    integer modsub_correction2_inv;
    integer rsub_prev_i2_inv;
    
    integer Q;
  `ifdef MULTIPLE_CYCLES
    reg signed[31:0] Q_reg;
  `endif
    
    /////////////////////////
    // Combinational logic //
    /////////////////////////
    
    assign Q = 'd8380417;

    assign mux1 = (op[1:0] == 2'b01) ? acc : a0;
    assign mux2 = (op[1:0] == 2'b01) ? a0 : omega;
    
`ifdef MULTIPLE_CYCLES
    assign muxntt_mult   = (op_reg[1:0] == 2'b11) ? rsub_prev_i2 : a11_reg;
    assign muxntt_subsum = (op_reg[1:0] == 2'b11) ?      a11_reg : mult_reduced_complete;
`else
    assign muxntt_mult   = (op[1:0] == 2'b11) ? rsub_prev_i2 : a11;
    assign muxntt_subsum = (op[1:0] == 2'b11) ?          a11 : mult_reduced_complete;
`endif
    
    // Check for negative values
    assign mux11 = (mux1 < 0) ? mux1 + Q : mux1;
`ifndef MULTIPLE_CYCLES
    assign mux22 = (mux2 < 0) ? mux2 + Q : mux2;
`endif
    assign a11   = (a1 < 0)   ? a1 + Q   : a1;
    
    assign mult = muxntt_mult * mux22;
  
    reduction_solinas_23_13 reduction_inst1
    (
        .in_c(mult),
        .red_c(mult_reduced_dilithium)
    );

`ifdef MULTIPLE_CYCLES
    assign mult_reduced_complete = (mult_reduced_dilithium > Q_reg) ? mult_reduced_dilithium - Q_reg : mult_reduced_dilithium;

    // modular sum
    assign b                 = Q_reg - muxntt_subsum;
    assign rsum_prev         = mux11_reg - b;
    assign modsum_correction = mux11_reg >= b ? 31'b0 : Q_reg;
    assign rsum_prev_i       = modsum_correction + rsum_prev;
    
    // modular sub
    assign rsub_prev         = mux11_reg - muxntt_subsum;
    assign modsub_correction = mux11_reg >= muxntt_subsum ? 31'b0 : Q_reg;
    assign rsub_prev_i       = modsub_correction + rsub_prev;
    
    // modular sub for Gentleman-Sande configuration (inverse NTT)
    assign rsub_prev2         = mux11_reg - a11_reg;
    assign modsub_correction2 = mux11_reg >= a11_reg ? 31'b0 : Q_reg;
    assign rsub_prev_i2       = modsub_correction2 + rsub_prev2;

    // center outputs (range: [-Q/2, Q/2])
    assign rsub                           = (rsub_prev_i > Q_reg>>>1)           ? rsub_prev_i - Q_reg           : rsub_prev_i;
    assign mult_reduced_complete_centered = (mult_reduced_complete > Q_reg>>>1) ? mult_reduced_complete - Q_reg : mult_reduced_complete;

`else
    assign mult_reduced_complete = (mult_reduced_dilithium > Q) ? mult_reduced_dilithium - Q     : mult_reduced_dilithium;

    // modular sum
    assign b                 =  Q - muxntt_subsum;
    assign rsum_prev         = mux11 - b;
    assign modsum_correction = mux11 >= b ? 31'b0 : Q;
    assign rsum_prev_i       = modsum_correction + rsum_prev;
    
    // modular sub
    assign rsub_prev         = mux11 - muxntt_subsum;
    assign modsub_correction = mux11 >= muxntt_subsum ? 31'b0 : Q;
    assign rsub_prev_i       = modsub_correction + rsub_prev;
    
    // modular sub for Gentleman-Sande configuration (inverse NTT)
    assign rsub_prev2         = mux11 - a11;
    assign modsub_correction2 = mux11 >= a11 ? 31'b0 : Q;
    assign rsub_prev_i2       = modsub_correction2 + rsub_prev2;

    // center outputs (range: [-Q/2, Q/2])
    assign rsub                           = (rsub_prev_i > Q>>>1)           ? rsub_prev_i - Q           : rsub_prev_i;
    assign mult_reduced_complete_centered = (mult_reduced_complete > Q>>>1) ? mult_reduced_complete - Q : mult_reduced_complete;
`endif

`ifdef MULTIPLE_CYCLES    
    always_ff @(posedge CLK) begin
        if (en)
            en_reg = 1;
            
        if (en_reg) begin
        case (fpau_state)
            FPAU_IDLE : begin // multiply and store inputs into registers
                mux22      <= (mux2 < 0) ? mux2 + Q : mux2;
                op_reg     <= op;
                a11_reg    <= a11;
                mux11_reg  <= mux11;
                Q_reg <= 'd8380417;
                fpau_state <= FPAU_MULT_DONE;
            end
            FPAU_MULT_DONE : begin // run reduction sub module
                fpau_state <= FPAU_READY;
            end
            FPAU_READY : begin // export outputs, reset enable register and go back to idle state
                rsum       <= (rsum_prev_i > Q_reg>>>1) ? rsum_prev_i - Q_reg : rsum_prev_i;
                out2       <= (op_reg[1:0] == 2'b11) ? mult_reduced_complete_centered : rsub;
                en_reg      = 0;
                fpau_state <= FPAU_IDLE;
            end
        endcase
        end
    end
`else
    assign rsum = (rsum_prev_i > Q>>>1) ? rsum_prev_i - Q : rsum_prev_i;
    assign out2 = (op[1:0] == 2'b11) ? mult_reduced_complete_centered : rsub;
`endif

endmodule
