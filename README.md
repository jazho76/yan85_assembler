# Yan85 Assembler & Disassembler

**yan85** is a small, intentionally constrained virtual machine architecture encountered in reverse-engineering and binary exploitation challenges.

It is designed to be simple to implement, awkward to program, and interesting to reverse.

The architecture uses a fixed-width instruction format, a minimal register set, and a compact instruction set that exposes low-level execution details such as explicit stack manipulation, flag-based control flow and a syscall interface.

yan85 is not intended to model a real CPU. Instead, it serves as a pedagogical and challenge-oriented VM.

This repository provides a minimal assembler and disassembler to make working with yan85 programs practical while preserving the low-level nature of the VM.

## Overview

This repository provides:

- asm: Assembler
- disasm: Disassembler
- vm_settings.py: Centralized ISA definition (registers, opcodes, syscalls)

## Assembler Usage

```bash
./asm program.asm program.bin
```

## Disassembler Usage

```bash
./disasm program.bin
```

## Registers

The Yan85 VM exposes a small, fixed set of registers.  
They are referenced symbolically in assembly and have predefined roles in the execution model.

| Register | Type    | Purpose                                              |
| -------- | ------- | ---------------------------------------------------- |
| `a`      | General | Arithmetic, data movement, comparisons, syscall args |
| `b`      | General | Arithmetic, data movement, comparisons, syscall args |
| `c`      | General | Arithmetic, data movement, comparisons, syscall args |
| `d`      | General | Arithmetic, data movement, comparisons, syscall args |
| `s`      | Special | Stack pointer for stack operations                   |
| `f`      | Special | Flags from comparisons, used by jumps                |
| `i`      | Special | Instruction pointer for control flow                 |

## Labels

Labels are resolved to instruction indices (not byte offsets):

```asm
loop:
    imm a loop
    jmp al a
```

## Comments

Comments start with a semicolon (`;`) and continue to the end of the line:

```asm
; This is a comment
imm a 0x41  ; Load ASCII 'A' into register a
```

## Instruction Set

The yan85 instruction set is small and orthogonal.

### `imm <dst> <value|label>`

Load an immediate value or label address into a register.

- `<dst>`: destination register
- `<value|label>`: numeric literal, character literal, or label

Example:

```asm
imm a 0x41
imm b 'A'
imm c start
```

### `add <dst> <src>`

Add the value of one register to another.

- `<dst>`: destination register
- `<src>`: source register

Example:

```asm
add a b
```

### `stk <reg|none> <reg|none>`

Perform a stack operation.

At least one operand must be a register. The instruction behaves as a push or pop depending on which operand is `none`.

- `<reg|none>`: source/destination register or `none`

Example:

```asm
stk a none  ; push a onto stack
stk none b  ; pop from stack into b
```

### `stm <dst> <src>`

Store the value of a register into memory.

- `<dst>`: destination register, which holds the memory address
- `<src>`: source register with the value to store

Example:

```asm
stm a b
```

### `ldm <dst> <src>`

Load a value from memory into a register.

- `<dst>`: destination register, which will receive the loaded value
- `<src>`: source register, which holds the memory address

Example:

```asm
ldm a b
```

### `cmp <reg1> <reg2>`

Compare two registers and update the flags register.

The result of the comparison is stored implicitly in the flags register and is used by conditional jump instructions.

- `<reg1>`: first register
- `<reg2>`: second register

Example:

```asm
cmp a b
```

### `jmp <cond> <reg>`

Perform a conditional jump based on the current state of the flags register.

If the condition evaluates to true, execution continues at the address stored in `<reg>`.

- `<cond>`: jump condition
- `<reg>`: register containing the jump target

Supported conditions:

- `al` — always
- `eq` — equal
- `ne` — not equal
- `lt` — less than
- `gt` — greater than
- `z` — zero
- `nz` — not zero

Example:

```asm
jmp eq a
jmp ne b
```

### `sys <call> <reg>`

Invoke a system call.

The specific operation is selected by `<call>`. The register operand is used as the syscall argument or handle, depending on the call.

- `<call>`: syscall selector
- `<reg>`: register used by the syscall

Supported syscalls:

| Syscall | Description |
| ------- | ----------- |
| `op`    | Open        |
| `rm`    | Read memory |
| `rc`    | Read code   |
| `wr`    | Write       |
| `sl`    | Sleep       |
| `ex`    | Exit        |

Example:

```asm
sys op a
sys wr a
```
