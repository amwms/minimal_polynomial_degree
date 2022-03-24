global polynomial_degree

section .text

polynomial_degree:
    ;ABI
    push r15
    push r12
    push rbp
    mov rbp, rsp

    ; finding number of 8-bajt blocks needed for array y
    mov rax, rsi ; rax = n
    mov r12, rax ; r12 = n
    add rax, 32 ; rax = n + 32
    shr rax, 6 ; rax = (n + 32) / 64
    add rax, 1 ; rax = (n + 32) / 64 + 1
    mov r15, rax ; number of fragments in one number
    mul rsi ; rax = n * ((n + 32)/ 64 + 1) 
    lea rax, [rax + rax * 7] ; rax = n * ((n + 32)/ 64  +1) * 8
    sub rsp, rax ; saving space for all th numbers on the stack

    ; r15 -  number of blocks in one number
    ; r12 - n

    ; read all y_k


    ;ABI
    mov rsp, rbp
    pop rbp
    pop r12
    pop r15

    ret

bigint_sub: ; two arguments: pointer to end of number A, pointer to end of number B, number of blocks in one number
    ;ABI
    push rbx
    push rbp
    mov rbp, rsp

    ; subtract two numbers
    mov rbx, [rdi]
    mov r12, [rsi] ; read parameters
    mov rcx, rdx ; number of blocks

.loop:
    sub rbx, r12
    mov [rdi], rbx ; write answer in the place of number A 
    pushf
    add rdi, 0x8 ; move pionter to next block of number A
    add rsi, 0x8 ; move pionter to next block of number B
    popf
    loop .loop

    
; .loop:
;     loop .loop
;     sub rbx, r12 ; summ last two blocks of A and B
;     mov [rdi], rbx ; write answer in the place of number A 
;     add rdi, 0x8 ; move pionter to next block of number A
;     add rsi, 0x8 ; move pionter to next block of number B


    ;ABI
    mov rsp, rbp
    pop rbp
    pop rbx

    ret

    
    
