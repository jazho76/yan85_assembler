#!/usr/bin/env python3


class VmSettings:
    def __init__(self):
        self.reg_a = 0x10
        self.reg_b = 0x02
        self.reg_c = 0x40
        self.reg_d = 0x01
        self.reg_s = 0x08
        self.reg_f = 0x20
        self.reg_i = 0x04

        self.opcode_imm = 0x01
        self.opcode_add = 0x80
        self.opcode_stk = 0x02
        self.opcode_stm = 0x04
        self.opcode_ldm = 0x20
        self.opcode_cmp = 0x08
        self.opcode_jmp = 0x40
        self.opcode_sys = 0x10

        self.syscall_open = 0x20
        self.syscall_read_code = 0x02
        self.syscall_read_mem = 0x01
        self.syscall_write = 0x04
        self.syscall_sleep = 0x10
        self.syscall_exit = 0x08

        self.jmp_cond_lt = 0x08
        self.jmp_cond_gt = 0x04
        self.jmp_cond_eq = 0x10
        self.jmp_cond_nz = 0x02
        self.jmp_cond_z = 0x01


class Instruction:
    def __init__(self):
        self._order = ["op", "arg1", "arg2"]

    def from_values(self, op, arg1, arg2):
        self.op = op
        self.arg1 = arg1
        self.arg2 = arg2

    def pack(self):
        data = b""
        for field in self._order:
            value = getattr(self, field)
            data += value.to_bytes(1, byteorder="little")
        return data

    def unpack(self, data):
        assert len(data) == 3
        for i, field in enumerate(self._order):
            value = data[i]
            setattr(self, field, value)
