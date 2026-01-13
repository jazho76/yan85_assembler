#!/usr/bin/env python3

import sys
from vm_settings import VmSettings, Instruction


class Yan85Assembler:
    def __init__(self, settings: VmSettings):
        self._settings = settings
        self._labels = {}

    def asm_from_file(self, src_filename, out_filename):
        src = ""
        with open(src_filename, "r") as f:
            src = f.read()

        bin = self.asm_from_src(src)

        with open(out_filename, "wb") as f:
            f.write(bin)

    def asm_from_src(self, src_text):
        ln = 1
        lines = []
        instructions = []
        self._labels = {}

        for line in src_text.splitlines():
            inst_src = line.strip()
            if ";" in inst_src:
                inst_src = inst_src.split(";")[0].strip()
            words = inst_src.split()
            if len(words) == 1 and words[0].endswith(":"):
                label = words[0][:-1]
                if label in self._labels:
                    self._stop(f"Duplicate label: {label}", ln)
                self._labels[label] = ln
            lines.append(words)
            ln = ln + 1

        ln = 1
        for words in lines:
            if not words:
                ln = ln + 1
                continue
            if len(words) == 1 and words[0].endswith(":"):
                ln = ln + 1
                continue
            if len(words) < 2:
                self._stop(f"Invalid instruction format", ln)

            inst = self._asm(words, ln)
            instructions.append(inst)
            ln = ln + 1

        bin = b""
        for inst in instructions:
            bin += inst.pack()

        return bin
    def _asm(self, words, ln):
        inst_assemblers = [
            self._asm_imm,
            self._asm_add,
            self._asm_stk,
            self._asm_stm,
            self._asm_ldm,
            self._asm_cmp,
            self._asm_jmp,
            self._asm_sys,
        ]

        for asm in inst_assemblers:
            t = asm(words, ln)
            if t:
                inst = Instruction()
                inst.from_values(t[0], t[1], t[2])
                return inst

        self._stop(f"Invalid instruction {' '.join(words)}", ln)

    def _asm_imm(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("imm", words, ln)
        if not ok:
            return None
        return [ 
            self._settings.opcode_imm,
            self._encode_reg(a1, ln),
            self._encode_value_or_label(a2, ln)
        ]

    def _asm_add(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("add", words, ln)
        if not ok:
            return None
        return [ 
            self._settings.opcode_add,
            self._encode_reg(a1, ln),
            self._encode_reg(a2, ln)
        ]

    def _asm_stk(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("stk", words, ln)
        if not ok:
            return None

        reg1 = self._encode_opt_reg(a1, ln)
        reg2 = self._encode_opt_reg(a2, ln)

        if reg1 == 0 and reg2 == 0:
            self._stop("At least one register must be specified for stk instruction", ln)

        return [ 
            self._settings.opcode_stk,
            reg1,
            reg2
        ]

    def _asm_stm(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("stm", words, ln)
        if not ok:
            return None

        reg1 = self._encode_reg(a1, ln)
        reg2 = self._encode_reg(a2, ln)

        return [ 
            self._settings.opcode_stm,
            reg1,
            reg2
        ]

    def _asm_ldm(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("ldm", words, ln)
        if not ok:
            return None

        reg1 = self._encode_reg(a1, ln)
        reg2 = self._encode_reg(a2, ln)

        return [ 
            self._settings.opcode_ldm,
            reg1,
            reg2
        ]

    def _asm_cmp(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("cmp", words, ln)
        if not ok:
            return None

        reg1 = self._encode_reg(a1, ln)
        reg2 = self._encode_reg(a2, ln)

        return [ 
            self._settings.opcode_cmp,
            reg1,
            reg2
        ]

    def _asm_jmp(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("jmp", words, ln)
        if not ok:
            return None
        return [ 
            self._settings.opcode_jmp,
            self._encode_jmp_type(a1, ln),
            self._encode_reg(a2, ln)
        ]

    def _asm_sys(self, words, ln):
        ok, a1, a2 = self._parse_inst_with_two_arg("sys", words, ln)
        if not ok:
            return None
        return [ 
            self._settings.opcode_sys,
            self._encode_syscall_type(a1, ln),
            self._encode_reg(a2, ln)
        ]

    def _encode_opt_reg(self, reg, ln):
        if reg == 'none':
            return 0
        return self._encode_reg(reg, ln)

    def _encode_reg(self, reg, ln):
        reg_dict = {
            "a": self._settings.reg_a,
            "b": self._settings.reg_b,
            "c": self._settings.reg_c,
            "d": self._settings.reg_d,
            "s": self._settings.reg_s,
            "f": self._settings.reg_f,
            "i": self._settings.reg_i,
        }
        val = reg_dict.get(reg)
        if val is None:
            self._stop(f"Invalid register: {reg}", ln)
        return val

    def _encode_jmp_type(self, jmp, ln):
        jmp_type_dict = {
            "gt": self._settings.jmp_cond_gt,
            "lt": self._settings.jmp_cond_lt,
            "eq": self._settings.jmp_cond_eq,
            "z": self._settings.jmp_cond_z,
            "nz": self._settings.jmp_cond_nz,
            "ne": self._settings.jmp_cond_lt | self._settings.jmp_cond_gt,
            "al": 0x0
        }
        val = jmp_type_dict.get(jmp)
        if val is None:
            self._stop(f"Invalid jump type: {jmp}", ln)
        return val

    def _encode_syscall_type(self, jmp, ln):
        syscall_dict = {
            "op": self._settings.syscall_open,
            "rm": self._settings.syscall_read_mem,
            "rc": self._settings.syscall_read_code,
            "wr": self._settings.syscall_write,
            "sl": self._settings.syscall_sleep,
            "ex": self._settings.syscall_exit,
        }
        val = syscall_dict.get(jmp)
        if val is None:
            self._stop(f"Invalid jump type: {jmp}", ln)
        return val

    def _encode_value_or_label(self, label_or_val, ln):
        if label_or_val in self._labels:
            return self._labels[label_or_val]
        return self._encode_value(label_or_val, ln)

    def _encode_value(self, arg, ln):
        if arg.startswith("'") and arg.endswith("'"):
            if len(arg) != 3:
                self._stop(f"Invalid character literal: {arg}", ln)
            return ord(arg[1])
        if arg.startswith("0x"):
            return int(arg, 16)
        return int(arg)

    def _parse_inst_with_single_arg(self, mnemonic, words, ln):
        if words[0] != mnemonic:
            return (False, None)
        if len(words) != 2:
            self._stop(f"Unexpected number of arguments for {mnemonic}", ln)
        return (True, words[1])

    def _parse_inst_with_two_arg(self, mnemonic, words, ln):
        if words[0] != mnemonic:
            return (False, None, None)
        if len(words) != 3:
            self._stop(f"Unexpected number of arguments for {mnemonic}", ln)
        return (True, words[1], words[2])

    def _stop(self, msg, ln):
        print(f"Error at line {ln}: {msg}")
        exit(1)


if __name__ == "__main__":
    settings = VmSettings()
    assembler = Yan85Assembler(settings)

    if len(sys.argv) != 3:
        print("Usage: assemble <source file> <output file>")
        sys.exit(1)

    assembler.asm_from_file(sys.argv[1], sys.argv[2])
