; write "/flag" to 0x30
imm a 0x30
imm b '/'
imm c 1
stm a b
add a c
imm b 'f'
stm a b
add a c
imm b 'l'
stm a b
add a c
imm b 'a'
stm a b
add a c
imm b 'g'
stm a b
add a c
imm b 0x0
stm a b

; open file 
imm a 0x30
imm b 0x0
sys op a

; read mem
imm b 0x40
imm c 100
sys rm c

; write
imm a 1
imm b 0x40
sys wr a

; exit
imm a 0
sys ex a
