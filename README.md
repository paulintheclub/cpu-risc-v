# RV32HM: 32-Bit RISC-V Processor with Harvard Architecture and Multiplication Support

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Architecture](#architecture)
- [Modules](#modules)
- [Memory Protocol](#memory-protocol)
- [Error Handling](#error-handling)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Simulation](#simulation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Introduction

**RV32HM** is a meticulously designed 32-bit processor based on the RISC-V architecture, implementing a subset of the RV32I instruction set with extended support for multiplication operations (RV32IM). The processor adopts a Harvard architecture, featuring separate buses for instructions and data, which enhances performance by allowing simultaneous access to both instruction and data memories.

This project is developed using Verilog and is intended for simulation and verification in environments like ModelSim. RV32HM is designed to handle little-endian data storage and utilizes an active-low asynchronous reset mechanism. It robustly manages error conditions, ensuring reliable operation by halting execution and signaling errors when encountering invalid instructions or misaligned memory accesses.

## Features

- **32-Bit RISC-V Core:** Implements a subset of the RV32I instruction set with support for multiplication operations.
- **Harvard Architecture:** Separate instruction (`I-Bus`) and data (`D-Bus`) buses allow parallel instruction fetch and data access.
- **Supported Instructions:**
  - **Control Flow:** `JAL`, `JALR`, `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
  - **Arithmetic and Logical Operations (ALOs):** `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`
  - **Immediate Operations:** `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`
  - **Multiplication:** `MUL`, `MULH`, `MULHSU`, `MULHU`
  - **Memory Access:** `LW`, `SW`
  - **Upper Immediate:** `LUI`, `AUIPC`
- **Memory Protocol:** Two-cycle access with overlapping address and data phases for optimized performance. Enforces 4-byte alignment for memory access instructions.
- **Asynchronous Reset:** Active-low reset signal allows quick and reliable initialization.
- **Error Handling:** Detects and handles invalid instructions and misaligned memory accesses by halting execution and asserting an `ERROR` signal.
- **Modular Design:** Comprises well-defined modules for ease of maintenance and scalability.

## Architecture

RV32HM follows a classic five-stage pipeline architecture:

1. **RESET:** Initializes the processor, setting the Program Counter (PC) to the boot address and clearing registers.
2. **FETCH:** Retrieves the next instruction from instruction memory using the `I-Bus`.
3. **DECODE:** Interprets the fetched instruction, extracting opcode, register addresses, immediate values, and determining the operation type.
4. **EXECUTE:** Performs the required arithmetic or logical operation using the ALU. For multiplication operations, the ALU interacts with the `multiplier` module to handle multi-cycle execution.
5. **MEMORY:** Accesses data memory via the `D-Bus` for load and store instructions.
6. **WRITEBACK:** Writes the result of operations back to the register file.

## Modules

### 1. `cpu_top`

The top-level module orchestrating the instruction fetch, decode, execute, memory access, and write-back stages. It integrates all other modules and manages the overall operation of the processor.

### 2. `instruction_decoder`

Decodes 32-bit instructions into their constituent fields such as opcode, register addresses, function codes, and immediate values. It also determines the validity of instructions and flags multiplication operations.

### 3. `register_file`

Manages 32 general-purpose registers (`x0` to `x31`). Ensures `x0` is always zero and handles read and write operations based on control signals.

### 4. `alu` (Arithmetic Logic Unit)

Performs arithmetic and logical operations, including multi-cycle multiplication handled by the `multiplier` module. It interacts with other components to execute instructions and manage the processor's state.

### 5. `multiplier`

Executes multiplication operations using a shift-add algorithm, supporting signed and unsigned variants. It operates over multiple cycles and can handle operation cancellation.

## Memory Protocol

Memory access in RV32HM is executed over two cycles:

1. **Address Cycle:**
   - **Write Operation:** Sets the address on the `I-Bus` or `D-Bus` and asserts the write signal (`s_dbus_write_o = 1`).
   - **Read Operation:** Sets the address on the `I-Bus` or `D-Bus` without asserting the write signal (`s_dbus_write_o = 0`).

2. **Data Cycle:**
   - **Write Operation:** Transmits the data to be written to memory via `s_dbus_val_o`.
   - **Read Operation:** Receives the data from memory via `s_dbus_val_i`.

The protocol allows for overlapping address and data phases in subsequent operations to enhance throughput. All data is stored in little-endian format, and memory access instructions must use 4-byte aligned addresses.

## Error Handling

RV32HM incorporates robust error detection mechanisms:

- **Invalid Instructions:** If an instruction cannot be decoded as one of the supported types, the processor halts execution and sets the `s_error_o` signal to `1`.
- **Misaligned Memory Access:** Accessing memory with addresses not aligned to 4 bytes for load/store operations results in halting execution and asserting the `s_error_o` signal.
  
These measures ensure that the processor operates reliably and prevents undefined behavior.

## Getting Started

### Prerequisites

- **Verilog Simulator:** [ModelSim](https://www.intel.com/content/www/us/en/programmable/products/design-software/fpga-design-software/model-sim.html) or any other compatible Verilog simulation tool.
- **Overleaf Account:** For collaborative editing and LaTeX documentation (optional).

### Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/paulintheclub/cpu-risc-v.git
