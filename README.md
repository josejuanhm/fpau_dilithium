# Finite Field Polynomial Arithmetic Unit (FPAU)

The FPAU is a hardware accelerator targeting modular arithmetic done within lattice-based cryptography algorithms, which includes the Number-Theoretic Transform (NTT) used for accelerating polynomial multiplication. This tightly-coupled accelerator is meant to be inserted in any RISC-V core following the RV32I ISA specification. An instruction set extension was designed for the FPAU supported operations.

This repository contains the FPAU's RTL design and testing source code. It can be configured/synthesized as a **single-cycle** (35 MHz) or **multiple-cycles** hardware module (currently supporting 3 cycles) to be able to increase the working frequency.

Tested implementations in the **STEEL** core for the single-cycle variant and the **ORCA** core for the multiple-cycles variant are included in this repository, as well as the FPAU instructions usage within the **CRYSTALS-Dilithium** digital signature scheme selected for standardization by the NIST for post-quantum cryptography.

## Files Organization

The following folder structure is used:

- [pqc_sw](pqc_sw/README.md): Forks of the reference code repositories for the post-quantum cryptography schemes tested with the FPAU instructions modifications. 
  - dilithium
- [riscv_cores](riscv_cores/README.md): Forks of the RISC-V cores repositories with the FPAU inserted within the pipeline.
  - orca
  - riscv-steel-core
- [rtl](rtl/README.md): SystemVerilog files with the FPAU hardware description and the modular reduction submodules.

Clicking the folder name above sends to the markdown file with more information.

## Requirements

Based on the Xilinx tools, the following are the software and hardware versions used for the implementation and testing (in an Artix-7 FPGA) of the RISC-V cores with the respective FPAU variant:

* Single-Cycle FPAU (STEEL core)
  - Vivado Design Suite 2021.2
  - Arty A7-35T board
* Multiple-Cycles FPAU (ORCA core)
  - Vivado Design Suite 2017.1
  - Zybo Z7-10 board
* Both variants
  - [riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain/tree/2022.09.30), version tag 2022.09.30

## Quick Start Guide

Since the structure of this repository contains forks as subdmodules, it shall be cloned with the following command to get all the files locally:

    git clone --recurse-submodules https://github.com/josejuanhm/fpau_dilithium.git

As a **prerequisite**, the riscv-gnu-toolchain repository shall be cloned and the following files shall be replaced with the ones in this repository ([opcodes](pqc_sw/opcodes/) folder) before building the compiler:
* binutils/opcodes/riscv-opc.c with [riscv-opc.c](pqc_sw/opcodes/riscv-opc.c)
* binutils/include/opcode/riscv-opc.h with [riscv-opc.h](pqc_sw/opcodes/riscv-opc.h)

To build the compiler, go to your riscv-gnu-toolchain folder and run:
```
sudo ./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi-ilp32 
sudo make clean 
sudo make
```

Then, follow these steps to run an FPAU accelerated CRYSTALS-Dilithium scheme with the variant of your choice:

1. Build the software
    - Within pqc_sw/dilithium/ref/, Run the following command choosing just one argument for -t (test) and -c (core):
        ```
        sudo ./build_dilithium_riscv.sh -t [test_dilithium2|test_dilithium3|test_dilithium5] -c [orca|steel]
        ```
        > Note: The tests test_dilithium3 and test_dilithium5 do not fit in the STEEL core memory. The default [program.mem](riscv_cores/riscv-steel-core/hello_world/program.mem) file already contains the test_dilithium2 test.
2. Build a RISC-V core
    - For ORCA (multiple-cycles FPAU, 100 MHz), within riscv_cores/orca/systems/zedboard/ run:
        ```
        sudo make
        ```
      > Note: Building ORCA again is needed only if modifications to the rtl code are made. To update the program memory with new or modified software, just follow step 4.
    - For STEEL (single-cycle FPAU, 35 MHz):
      - Verify the boot address by checking the <\_start> function in the generated_asm_test_...txt file output of the sw build (in pqc_sw/dilithium/ref/test/).
      - Modify the address accordingly in riscv_steel_core_instance signal *boot_address* in the [hello_world.v](riscv_cores/riscv-steel-core/hello_world/hello_world.v) file.
      - Within the Vivado GUI, open the project in riscv_cores/riscv-steel-core/steel_fpau/steel_fpau.xpr
      - Run the "Generate Bistream" step within the Vivado GUI Flow Navigator.
      > Note: Building STEEL is needed when a change is made in the rtl code or in software code, since the synthesis process loads the program memory. The default bitstream already contains the STEEL core with the FPAU module inserted and the test_dilithium2 software in program memory.
3. Open a serial terminal, e.g. Putty, and connect to the development board.
    - ORCA (Zybo): baudrate 115200 
    - STEEL (Arty):  baudrate 9600 
4. Load program 
    - For ORCA: In riscv_cores/orca/systems/zedboard, run the following command to load the bitstream to the Zybo development board:
      ```
      sudo make pgm
      ```
      To load the program, use the following command:
      ```
      sudo make run SW_DIR=[coe_path] TEST=[test_dilithium2|test_dilithium3|test_dilithium5]
      ```
      where *coe_path* shall be:
      - ../../../../pqc_sw/dilithium/ref/test 
    - For STEEL: Load the bitstream (already containing the program) from the Vivado GUI.
      - Open Hardware Manager/Open Target/Autoconnect/Program Device/Program
      > Note: Verify the bitstream file riscv_cores/riscv-steel-core/steel_fpau/steel_fpau.runs/impl_1/hello_world.bit is the default bitstream file being programmed.

Data should start to be received and visualized in the serial terminal after succesfully loading the program.

**For simulation**, follow step 1 and the instructions contained in the [RISC-V cores readme file](riscv_cores/README.md). The software should be compiled with the UART macro commented in the [fpau_switches.h](pqc_sw/dilithium/ref/fpau_switches.h) file.