# 8-Bit Single-Cycle Computer 💻

> *"Anything can be run on my computer—assuming you can write the code for it in under 1024 instructions."*

A fully custom 8-bit, single-cycle CPU architecture built from scratch. This repository contains the hardware design (Logisim), the custom assembler pipeline (Python), and the complete instruction set architecture (ISA). 

Whether you want to calculate prime numbers, run a sorting algorithm, or render a bouncing ball on the memory-mapped VGA displays, this machine can handle it. 

### 📊 Full Documentation
For a deep dive into the hardware, memory mapping, and ALU logic, check out the complete specification here:
**👉 [Complete Architecture & ISA Spreadsheet](https://docs.google.com/spreadsheets/d/1luwAdmWhACaZFE6YptWlm71hi2atvYXI/edit?usp=sharing&ouid=109717966956151028610&rtpof=true&sd=true)**

---

## 🚀 Quick Start Guide

To write code and run it on this processor, follow these steps:

### 1. Prerequisites
* **Logisim Evolution v4.1.0** (Required to run the hardware simulation).
* **Python 3.x** (Required to run the custom assembler).

### 2. Write Your Assembly
Open the `programming` folder and write your custom code inside the `assembly.as` file. 
*(See the crash course below if you are too lazy to open the spreadsheet!)*

### 3. Assemble the Code
Run the assembler script in your terminal to compile your `.as` file into machine code:

```bash
python assembler.py
```

If your code has no syntax errors, this will automatically generate two files:
* `mach.mc`: The raw 16-bit binary output.
* `final_instruction.txt`: The formatted hex file ready for Logisim.

### 4. Boot Up the Hardware
1. Open the main `.circ` file in **Logisim Evolution v4.1.0**.
2. Right-click the **Instruction Memory (ROM)** component and select **Load Image**.
3. Select the `final_instruction.txt` file you just generated.
4. Go to the top menu: `Simulate` -> `Auto-Tick Frequency` and set it between **64 kHz and 256 kHz** (preferred range for smooth display rendering).
5. Hit `Simulate` -> `Ticks Enabled` (or press `Ctrl+K` / `Cmd+K`) to start the clock and watch your code run!

---

## 📖 Assembly Crash Course (For the Lazy)

If you just want to jump in and start coding, here is what you need to know about the architecture.

### Registers
The CPU features 16 general-purpose 8-bit registers:
* **`R0`**: Hardwired to `0`. (Reads always return `0x00`, writes are discarded).
* **`R1` to `R15`**: General purpose.

### Memory & Displays
* **Instruction ROM**: 1024 words (10-bit address space).
* **Data RAM**: 256 bytes (8-bit address space).
* **Memory-Mapped I/O (MMIO)**: Addresses `248` through `255` are hardwired to the display screens. Write to these addresses using `STR` to render graphics.

### Instruction Set Architecture (ISA)
All instructions are executed in a single clock cycle. 

| Opcode | Format | Description | Example |
| :--- | :--- | :--- | :--- |
| **NOP** | `NOP` | No operation. | `NOP` |
| **HLT** | `HLT` | Halts the CPU. | `HLT` |
| **ADD** | `OP R1 R2 W` | Add R1 + R2, store in W. | `ADD R1 R2 R3` |
| **SUB** | `OP R1 R2 W` | Subtract R1 - R2, store in W. | `SUB R5 R1 R5` |
| **AND** | `OP R1 R2 W` | Bitwise AND. | `AND R1 R2 R3` |
| **XOR** | `OP R1 R2 W` | Bitwise XOR. | `XOR R1 R2 R3` |
| **LSL** | `OP R1 R2 W` | Logical Shift Left. | `LSL R1 R2 R3` |
| **LSR** | `OP R1 R2 W` | Logical Shift Right. | `LSR R1 R2 R3` |
| **LDI** | `OP Rd imm8` | Load Immediate (8-bit val) into Rd. | `LDI R1 255` |
| **ADI** | `OP Rd imm8` | Add Immediate (8-bit val) to Rd. | `ADI R1 -5` |
| **JMP** | `OP .LABEL` | Unconditional jump to address. | `JMP .LOOP` |
| **BRH** | `OP COND .LABEL` | Branch if condition is met. | `BRH Z .DONE` |
| **CAL** | `OP .LABEL` | Push PC to stack, jump to subroutine. | `CAL .DRAW` |
| **RET** | `RET` | Pop PC from stack and return. | `RET` |
| **LOD** | `OP R1 [off] R2` | Load from RAM[R1 + offset] to R2. | `LOD R1 0 R2` |
| **STR** | `OP R1 [off] R2` | Store R2 into RAM[R1 + offset]. | `STR R1 -1 R5` |

*(Note: Memory offsets for LOD/STR must be between `-8` and `7`)*

### Branch Conditions (`BRH`)
You can use symbols or abbreviations for conditional branching:
* `Z` or `=` : Zero / Equals
* `NZ` or `!=` : Not Zero / Not Equals
* `C` or `>=` : Carry / Unsigned Greater Than or Equal
* `NC` or `<` : No Carry / Unsigned Less Than

### Pseudo-Instructions
The assembler provides a few quality-of-life shortcuts:
* `INC R1` expands to `ADI R1 1`
* `DEC R1` expands to `ADI R1 -1`
* `CMP R1 R2` expands to `SUB R1 R2 R0` (Sets flags, discards result to R0)

---

## 🏆 Acknowledgements & Inspiration

This repository is the first major project I've ever taken on, and it wouldn't have been possible without some incredible inspiration and assistance.

* **Inspiration:** Huge shoutout to **mattwings**, the legend of Minecraft combinational redstone. This entire project was deeply inspired by his *"Let's build a computer in Minecraft"* series, and relies heavily on the same foundational logic.
* **AI Assistance:** I leaned on a whole stack of AI tools to help bring this architecture to life:
    * **Antigravity Claude Sonnet 4.6:** Creating the assembler and highly optimizing the assembly code.
    * **Gemini Pro:** Brainstorming ideas and tackling tricky debugging problems.
    * **ChatGPT 5.5:** Assisting with data handling and test generation.
    * **Claude Sonnet 4.6:** General debugging and pushing through the early-stage progress.
