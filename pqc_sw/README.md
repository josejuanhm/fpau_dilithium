# Post-Quantum Cryptography Software

This folder contains the modified PQC schemes reference code taken from the official repositories as forks. Documentation about the designed instructions and how they are used is described in the [README.md](../rtl/README.md) file of the rtl folder.

Within Dilithium's *ref* folder, an fpau_switches.h file is included with macros that can be activated/deactivated to make cycles profiling and exporting data via UART, as well as to use the FPAU instructions (activated by default).

The following files are generated as build outputs when using [build_dilithium_riscv.sh](dilithium/ref/build_dilithium_riscv.sh):
- **generated_asm_test_*test*.txt**: Contains the assembly instructions with C code references of the program output.
- ***test*.ihex**: File used by Vivado to load data to DRAM (just used for simulation in the ORCA project.)
- ***test*.coe**: File used by Vivado to load data to DDR. This is the one used when implementing in the Zybo board (or any Zynq system). When a new program needs to be loaded without resynthesizing, it is possible to just load the *.coe* file (see step 4 in [README.md](../README.md) quick start guide).
- ***test*.hex**: Pure instructions in hexadecimal format. When building for STEEL, this file is copied to overwrite the [program.mem](../riscv_cores/riscv-steel-core/hello_world/program.mem) file that is used to load the program in BRAM when synthesized.

In the following tables, the use of the FPAU instructions within each of the PQC schemes reference software is described.

## CRYSTALS-Dilithium

| **Function**                            | **File**  | **Operation used** | **Description**                              |
|:---------------------------------------:|:---------:|:------------------:|:--------------------------------------------:|
| ntt()                                   | ntt.c     | fpau.dil.bf        | NTT of a polynomial of 256 coefficients.     |
| invntt()                                | ntt.c     | fpau.dil.bfinv     | INTT of a polynomial of 256 coefficients.    |
| poly\_add()                             | poly.c    | fpau.dil.bf        | Addition of two polynomials                  |
| poly\_sub()                             | poly.c    | fpau.dil.bf        | Subtraction of twpolynomials.                |
| polyvecl\_pointwise\_poly\_montgomery() | polyvec.c | fpau.dil.mac       | Pointwise multiplication of L polynomials.   | 
| polyveck\_pointwise\_poly\_montgomery() | polyvec.c | fpau.dil.mac       | Pointwise multiplication of K polynomials.   |
| polyvecl\_pointwise\_acc\_montgomery()  | polyvec.c | fpau.dil.mac       | Pointwise multiply-accumulate L polynomials. |
