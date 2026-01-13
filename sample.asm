; Loop from 0 to 3, sleep 1 second between counts,
; use the stack to store the counter, then exit.

start:
    imm a 0          ; counter = 0
    stk a none       ; push counter
    imm b 3          ; limit = 3

loop:
    ; sleep(1)
    imm c 1
    sys sl c

    ; pop counter into a
    stk none a

    ; a = a + 1
    imm c 1
    add a c

    ; push updated counter
    stk a none

    ; if a < limit, continue looping
    cmp a b
    imm d loop
    jmp lt d

    ; exit(0)
    imm a 0
    sys ex a
