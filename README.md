# 16-bit Booth Multiplier (Verilog HDL)

## Overview

A 16-bit sequential Booth Multiplier implemented in Verilog HDL using separate datapath and control path modules. The design employs Booth's algorithm to perform signed multiplication efficiently by reducing the number of addition and subtraction operations.

The architecture follows a classic FSM-based controller and datapath approach, demonstrating fundamental digital design concepts used in processor datapaths and arithmetic units.

---

## Features

* 16-bit Signed Multiplication
* Booth Multiplication Algorithm
* Separate Datapath and Control Path
* FSM-based Controller
* Arithmetic Shift Operations
* Sequential Multiplier Architecture
* Parameterized Counter-based Iteration
* Functional Verification Testbench
* GTKWave Simulation Support

---

## Booth's Algorithm

Booth's algorithm reduces the number of arithmetic operations required for signed multiplication by examining the multiplier bits in pairs.

Decision logic:

| Q₀ | Q₋₁ | Operation    |
| -- | --- | ------------ |
| 0  | 0   | No Operation |
| 0  | 1   | A = A + M    |
| 1  | 0   | A = A - M    |
| 1  | 1   | No Operation |

After each operation, an arithmetic right shift is performed on:

```text
[A Q Q-1]
```

The process repeats for `N` iterations.

---

## Architecture

```text
                +------------------+
                |  Control Unit    |
                |    (FSM)         |
                +--------+---------+
                         |
                         |
                         v
+------------------------------------------------+
|                  Datapath                      |
|                                                |
| +---------+     +---------+    +-----------+ |
| | Acc(A)  |<--->|   ALU   |<-->| Multiplicand|
| +---------+     +---------+    +-----------+ |
|                                                |
| +---------+                                   |
| | Reg(Q)  |                                   |
| +---------+                                   |
|                                                |
| +---------+                                   |
| | Q(-1)   |                                   |
| +---------+                                   |
|                                                |
| +---------+                                   |
| | Counter |                                   |
| +---------+                                   |
+------------------------------------------------+
```

---

## Module Description

### `datapath`

Implements the arithmetic portion of the Booth multiplier.

Components:

* Accumulator Register (A)
* Multiplier Register (Q)
* Multiplicand Register (M)
* Q(-1) Flip-Flop
* ALU
* Iteration Counter

---

### `controlpath`

Finite State Machine (FSM) controlling:

* Register loading
* Addition/Subtraction selection
* Shift operations
* Counter decrement
* Multiplication completion

States:

```text
S0 : Idle
S1 : Initialization
S2 : Decision State
S3 : Add Multiplicand
S4 : Subtract Multiplicand
S5 : Shift and Decrement
S6 : Done
```

---

## Datapath Components

### Shift Register

Performs:

* Parallel Load
* Arithmetic Right Shift
* Clear Operation

### ALU

Supports:

* Addition
* Subtraction

### Counter

Maintains multiplication iteration count.

Initial value:

```text
16
```

Decrements after each shift operation.

---

## Project Structure

```text
.
├── datapath.v
├── controlpath.v
├── booth_test.v
├── booth.vcd
└── README.md
```

---

## Simulation

### Compile

```bash
iverilog -g2012 -o booth.out *.v
```

### Run

```bash
vvp booth.out
```

### View Waveforms

```bash
gtkwave booth.vcd
```

---

## Verification

The design was verified using a dedicated testbench.

Example:

```text
Multiplicand = 7
Multiplier   = 3

Expected Product = 21
```

Simulation monitors:

* Accumulator Register (A)
* Multiplier Register (Q)
* Product
* Counter Value
* Completion Flag

---

## Sample Simulation Output

```text
t=0     A=0  Q=3  product=0   count=16 done=0
...
t=...   A=0  Q=21 product=21  count=0  done=1
```

---

## Key Concepts Demonstrated

* Booth Multiplication Algorithm
* Finite State Machine (FSM)
* Datapath and Control Path Separation
* Sequential Arithmetic Circuits
* Shift Registers
* Signed Number Multiplication
* RTL Design using Verilog HDL
* Functional Verification

---

## Tools Used

* Verilog HDL
* Icarus Verilog
* GTKWave

---

## Future Improvements

* Fully Parameterized Bit Width
* Pipelined Booth Multiplier
* Radix-4 Booth Encoding
* Synthesis and Timing Analysis
* SystemVerilog Assertions for Verification

---

## Author

**Ansh Shinde**
