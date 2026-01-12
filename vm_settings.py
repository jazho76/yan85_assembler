#!/usr/bin/env python3


class VmSettings:
    def __init__(self):
        self.reg_a = 0x10  # 400
        self.reg_b = 0x02  # 401
        self.reg_c = 0x40  # 402
        self.reg_d = 0x01  # 403
        self.reg_s = 0x08  # 404
        self.reg_f = 0x20  # 406
        self.reg_i = 0x04  # 405

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

    def inst_reader(self, data):
        assert len(data) == 3
        arg2 = data[0]
        op = data[1]
        arg1 = data[2]
        return Instruction(op, arg1, arg2)

    def inst_writer(self, instruction):
        data = b""
        data += instruction.arg2.to_bytes(1, byteorder="little")
        data += instruction.op.to_bytes(1, byteorder="little")
        data += instruction.arg1.to_bytes(1, byteorder="little")
        return data


class Instruction:
    def __init__(self, op, arg1, arg2):
        self.op = op
        self.arg1 = arg1
        self.arg2 = arg2
