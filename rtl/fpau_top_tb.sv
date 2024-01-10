`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////////////
// Author:      José Juan Hernández-Morales
// E-mail:      josejuanhm@inaoep.mx
// Create Date: 10/08/2023 02:28:03 PM
// Module Name: fpau_top_tb
// Description: Test bench for the finite field polynomial arithmetic unit, containing one test per
//              operation. Running one test per simulation is recommended since big amounts of data 
//              stored in hard disk are produced (and reset with a new simulation session in case 
//              of Vivado).
// Repository:  https://github.com/josejuanhm/fpau
//////////////////////////////////////////////////////////////////////////////////////////////////

module fpau_top_tb();
    reg clk;
    reg en;
    reg [3:0] op;

    // inputs
    reg signed [31:0] a0;
    reg signed [31:0] a1;
    reg signed [31:0] acc;
    reg signed [31:0] omega;

    // outputs
    reg signed[31:0] rsum;
    reg signed[31:0] out2;

    //reference variables
    reg signed[31:0] bf1_ref;
    reg signed[31:0] bf2_ref;
    reg signed[31:0] mac_ref;

    // schemes' parameters
    localparam int q_kyber     = 3329;
    localparam int q_dilithium = 8380417;

    // testing parameters (tunable, lower values increment coverage and runtime) (default values to approximate a 20 ms simulation per test)
    localparam int a0_increment_dilithium     = 2500;     // a0 increments in all dilithium tests
    localparam int a1_increment_dilithium     = 1500000;  // a1 increments in dil.bf and dil.bfinv
    localparam int a1_increment_dilithium_mac = 12500;    // a1 increments in dil.mac
    localparam int acc_increment_dilithium    = 4190208;  // dil.mac accumulator increments

    localparam int omegas_dilithium[255:0] = {
             0, -3572223,  3765607,  3761513, -3201494, -2883726, -3145678, -3201430,  -601683,  3542485,  2682288,  2129892,  3764867, -1005239,   557458, -1221177, 
      -3370349, -4063053,  2663378, -1674615, -3524442,  -434125,   676590, -1335936, -3227876,  1714295,  2453983,  1460718,  -642628, -3585098,  2815639,  2283733, 
       3602218,  3182878,  2740543, -3586446, -3110818,  2101410,  3704823,  1159875,   394148,   928749,  1095468, -3506380,  2071829, -4018989,  3241972,  2156050, 
       3415069,  1759347,  -817536, -3574466,  3756790, -1935799, -1716988, -3950053, -2897314,  3192354,   556856,  3870317,  2917338,  1853806,  3345963,  1858416, 
       3073009,  1277625, -2635473,  3852015,  4183372, -3222807, -3121440,  -274060,  2508980,  2028118,  1937570, -3815725,  2811291, -2983781, -1109516,  4158088, 
       1528066,   482649,  1148858, -2962264,  -565603,   169688,  2462444, -3334383, -4166425, -3488383,  1987814, -3197248,  1736313,   235407, -3250154,  3258457, 
      -2579253,  1787943, -2391089, -2254727,  3482206, -4182915, -1300016, -2362063, -1317678,  2461387,  3035980,   621164,  3901472, -1226661,  2925816,  3374250, 
       1356448, -2775755,  2683270, -2778788, -3467665,  2312838,  -653275,  -459163,   348812,  -327848,  1011223, -2354215, -3818627, -1922253, -2236726,  1744507, 
          1753, -1935420, -2659525, -1455890,  2660408, -1780227,   -59148,  2772600,  1182243,    87208,   636927, -3965306, -3956745, -2296397, -3284915, -3716946, 
        -27812,   822541,  1009365, -2454145, -1979497,  1596822, -3956944, -3759465, -1685153, -3410568,  2678278, -3768948, -3551006,   635956,  -250446, -2455377, 
      -4146264, -1772588,  2192938, -1727088,  2387513, -3611750,  -268456, -3180456,  3747250,  2296099,  1239911, -3838479,  3195676,  2642980,  1254190,   -12417, 
       2998219,   141835,   -89301,  2513018, -1354892,   613238, -1310261, -2218467,  -458740, -1921994,  4040196, -3472069,  2039144, -1879878,  -818761, -2178965, 
      -1623354,  2105286, -2374402, -2033807,   586241, -1179613,   527981, -2743411, -1476985,  1994046,  2491325, -1393159,   507927, -1187885,  -724804, -1834526, 
      -3033742,  -338420,  2647994,  3009748, -2612853,  4148469,   749577, -4022750,  3980599,  2569011, -1615530,  1723229,  1665318,  2028038,  1163598, -3369273, 
       3994671,   -11879, -1370517,  3020393,  3363542,   214880,   545376,  -770441,  3105558, -1103344,   508145,  -553718,   860144,  3430436,   140244, -1514152, 
      -2185084,  3123762,  2358373, -2193087, -3014420, -1716814,  2926054,  -392707,  -303005,  3531229, -3974485, -3773731,  1900052,  -781875,  1054478, -731434
    };
    
    assign en = 1;
    
    fpau_top fpau_top_dut(
      .CLK   (clk),
      .en    (en),
      .op    (op),
      .a0    (a0),
      .a1    (a1),
      .acc   (acc),
      .omega (omega),
      .rsum  (rsum),
      .out2  (out2)
    );
    
    initial begin
        clk = 1'b0;
        forever #1 clk = ~clk;
    end
    
    initial begin
        $monitor("time=%0d, a0=%0d \n", $time, a0);

        /////////////////////////////////////////////////////////////////////
        ////////////////////       DILITHIUM TESTS       ////////////////////
        /////////////////////////////////////////////////////////////////////
        
        // test Dilithium butterfly operation (fpau.dil.bf)
        op = 6;
        a0 = -q_dilithium + 1;
        while (a0 < q_dilithium) begin
          a1 = -q_dilithium + 1;
          while (a1 < q_dilithium) begin
            for (int i = 255; i > -1; i--) begin
              omega = omegas_dilithium[i];
              #1;
              bf1_ref = bf1(a0, a1, omega, q_dilithium);
              bf2_ref = bf2(a0, a1, omega, q_dilithium);
              assert (rsum == bf1_ref || rsum == dil_neg(bf1_ref) || rsum == dil_pos(bf1_ref)) else $error("Out1 dil.bf error! reference_result=%0d, a0=%0d, a1=%0d, omega=%0d, acc=%0d, out1=%0d, out2=%0d", bf1_ref, a0, a1, omega, acc, rsum, out2);
              assert (out2 == bf2_ref || out2 == dil_neg(bf2_ref) || out2 == dil_pos(bf2_ref)) else $error("Out2 dil.bf error! reference_result=%0d, a0=%0d, a1=%0d, omega=%0d, acc=%0d, out1=%0d, out2=%0d", bf2_ref, a0, a1, omega, acc, rsum, out2);
            end
            a1 = a1 + a1_increment_dilithium;
          end
          a0 = a0 + a0_increment_dilithium;
        end

        // test Dilithium inverse butterfly operation (fpau.dil.bfinv)
        op = 7;
        a0 = -q_dilithium + 1;
        while (a0 < q_dilithium) begin
          a1 = -q_dilithium + 1;
          while (a1 < q_dilithium) begin
            for (int i = 255; i > -1; i--) begin
              omega = omegas_dilithium[i];
              #1;
              bf1_ref = bfinv1(a0, a1, omega, q_dilithium);
              bf2_ref = bfinv2(a0, a1, omega, q_dilithium);
              assert (rsum == bf1_ref || rsum == dil_neg(bf1_ref) || rsum == dil_pos(bf1_ref)) else $error("Out1 dil.bfinv error! reference_result=%0d, a0=%0d, a1=%0d, omega=%0d, acc=%0d, out1=%0d, out2=%0d", bf1_ref, a0, a1, omega, acc, rsum, out2);
              assert (out2 == bf2_ref || out2 == dil_neg(bf2_ref) || out2 == dil_pos(bf2_ref)) else $error("Out2 dil.bfinv error! reference_result=%0d, a0=%0d, a1=%0d, omega=%0d, acc=%0d, out1=%0d, out2=%0d", bf2_ref, a0, a1, omega, acc, rsum, out2);
            end
            a1 = a1 + a1_increment_dilithium;
          end
          a0 = a0 + a0_increment_dilithium;
        end

        // test Dilithium mac operation (fpau.dil.mac)
        op = 5;
        a0 = -q_dilithium + 1;
        while (a0 < q_dilithium) begin
          a1 = a0;
          while (a1 < q_dilithium) begin
            acc = -q_dilithium + 1;
            while (acc < q_dilithium) begin
              #1;
              mac_ref = mac(a0, a1, acc, q_dilithium);
              assert (rsum == mac_ref || rsum == dil_neg(mac_ref) || rsum == dil_pos(mac_ref)) else $error("Out1 dil.mac error! reference_result=%0d, a0=%0d, a1=%0d, omega=%0d, acc=%0d, out1=%0d, out2=%0d", mac_ref, a0, a1, omega, acc, rsum, out2);
              acc = acc + acc_increment_dilithium;
            end
            a1 = a1 + a1_increment_dilithium_mac;
          end
          a0 = a0 + a0_increment_dilithium;
        end
        
    end
    
    // Reference results functions
    function int bf1;
      input int a0;
      input int a1;
      input int omega;
      input int q;

      longint product;
      int result;

      product = a0 + (a1*omega);
      result = (product % q + q) % q;

      if (result > q>>>1) 
        result = result - q;

      return result;
    endfunction

    function int bf2;
      input int a0;
      input int a1;
      input int omega;
      input int q;

      longint product;
      int result;

      product = a0 - (a1*omega);
      result = (product % q + q) % q;

      if (result > q>>>1) 
        result = result - q;

      return result;
    endfunction

    function int bfinv1;
      input int a0;
      input int a1;
      input int omega;
      input int q;

      longint sum;
      int result;

      sum = a0 + a1;
      result = (sum % q + q) % q;

      if (result > q>>>1) 
        result = result - q;

      return result;
    endfunction

    function int bfinv2;
      input int a0;
      input int a1;
      input int omega;
      input int q;

      longint product;
      int result;

      product = (a0 - a1)*omega;
      result = (product % q + q) % q;

      if (result > q>>>1) 
        result = result - q;

      return result;
    endfunction

    function int mac;
      input int a0;
      input int a1;
      input int acc;
      input int q;

      longint product;
      int result;

      product = (a0*a1) + acc;
      result = (product % q + q) % q;

      if (result > q>>>1) 
        result = result - q;

      return result;
    endfunction

    function int dil_neg;
      input int op_res;
      int q = 8380417;

      int result;
 
      result = op_res - q;

      return result;
    endfunction

    function int dil_pos;
      input int op_res;
      int q = 8380417;

      int result;
 
      result = op_res + q;

      return result;
    endfunction
    
endmodule
