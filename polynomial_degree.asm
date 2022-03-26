global polynomial_degree

section .text

polynomial_degree:
    ; ABI
    push rbx
    push r15
    push r12
    push rbp
    mov rbp, rsp

    ; finding number of 8-byte blocks needed for array y
    mov rax, rsi                    ; rax = n
    mov [rel n], rsi
    add rax, 32                     ; rax = n + 32
    shr rax, 6                      ; rax = (n + 32) / 64
    add rax, 1                      ; rax = (n + 32) / 64 + 1
    mov [rel blocks_number], rax    ; number of blocks in one number
    mul rsi                         ; rax = n * ((n + 32)/ 64 + 1) 
    lea rax, [rax + rax * 7]        ; rax = n * ((n + 32)/ 64  +1) * 8
    sub rsp, rax                    ; saving space for all th numbers on the stack

    ; read the input array and save it on the stack
    mov r10, 0                      ; set global counter of zeros to 0
    mov rcx, [rel n]                ; init counter (int i in loop)
    mov rbx, rdi                    ; read first argument's value
    mov rdi, rsp                    ; init first argument of function fill_number (as the bottom of the stack because thaat is the end of the number)                     
.loop:
    movsxd rsi, [rbx]               ; init second argument of function fill_number -> value of y_k -> it is under pionter in rbx 

    cmp rsi, 0
    jnz .answer_is_not_zero
    inc r10                         ; if the number y_k (currently in register rsi) was a zero we increase the global counter of zeros
.answer_is_not_zero: 

    call fill_number

    lea rdi, [rdi + 8]              ; after call fill_number rdi is set to the first block on the number that was just filled, so to go to the end of the next number we need to add 8 bajts 
    lea rbx, [rbx + 4]              ; go to the pionter to the next number in the array y_n
    loop .loop

    ; count the degree
    cmp r10, [rel n]                               ; if the array consists of only zeros return -1
    jne .not_only_zeros
    mov rax, -1
    jmp .end

.not_only_zeros:                                   ; if the array doesn't consist of only zeros count the degree in a loop (using an algorithm)
    mov r12, [rel blocks_number]
    mov rax, [rel n]

.counting_degree:
    mov rdi, rsp                                   ; set first argument of bigint_sub to the first number in the stack
    mov rsi, rsp
    lea rsi, [rsi + r12 * 8]                       ; set second argument of bigint_sub to the second number in the stack

    mov r10, 0                                     ; set global counter of not zeros to 0

    mov rcx, rax
    dec rcx                                        ; we only need to do [rax] - 1 subtractoins because there are [rax] numbers that we do subtractions between 
    jz .subtracting_end                            ; if rcx = 0 ommit the loop -> no need to subtract anything
.subtracting_loop:
    call bigint_sub                                ; at the end of this function the pointers are already set at the begining of the next numbers to subtract
    loop .subtracting_loop 

.subtracting_end:
    cmp r10, 0
    je .counting_end                               ; if all the answers of the subtractions were = 0 then we end the loop

    dec rax
    jnz .counting_degree
.counting_end:

    sub [rel n], rax
    mov rax, [rel n]

.end:

    ; ABI
    mov rsp, rbp
    pop rbp
    pop r12
    pop r15
    pop rbx

    ret

; two arguments: pionter to the end of number A destination, value of number A
; saves the number onto the stack and fills the rest of the 8-byte blocks (that were not filled by the number but are used to represent the number)
; with 0 or 1 (if the number is < 0 then the rest of the 8-byte blocks need to be filled with 1's to keep the numbers original value - 
; analogically if the number is > 0 but the 8-byte blocks need to be filled with 0's)
fill_number: 
    ; ABI
    push rcx
    push r12
    push rbx
    push rbp
    mov rbp, rsp

    mov QWORD[rel sign], 0;            ; init sign to zero (we suggest the number is not < 0)
    cmp rsi, [rel sign]                ; check the sign of the number
    jnl .end_if                        ; if the number is < 0 we need to fill the rest of the registers with 1 if not we fill it with 0
    mov QWORD[rel sign], -1            ; fill sign with 1
.end_if:
    mov [rdi], rsi                     ; move number value of A to destination
    mov rcx, [rel blocks_number]       ; i = number of blocks - 1
    dec rcx                            ; ---------====------------
    
    jz .end                            ; if rcx = 0 ommit the loop
.loop:                                 ; fill rest of blocks with [rel sign]
    lea rdi, [rdi + 8]                 ; move to the next block
    mov r12, [rel sign]
    mov [rdi], r12
    loop .loop
.end:

    ; ABI
    mov rsp, rbp
    pop rbp
    pop rbx
    pop r12
    pop rcx

    ret

; two arguments: pointer to end of number A, pointer to end of number B, number of blocks in one number
; subtracts two big numbers (represented in the form of [blocks_number] number of 8-byte blocks) from eachother 
bigint_sub: 
    ; ABI
    push r12
    push rcx
    push rbx
    push rbp
    mov rbp, rsp

    ; read parameters
    mov rcx, [rel blocks_number]    ; number of blocks
    clc                             ; clear carry flag

.loop:
    mov rbx, [rdi]                  ; number A
    mov r12, [rsi]                  ; number B
    
    sbb rbx, r12                    ; subtraction
    mov [rdi], rbx                  ; write answer in the place of number A 

    jz .answer_is_zero
    inc r10                         ; if the result of sbb was not zero we increase the global counter of results of subtractions that were not 0
.answer_is_zero:
    
    lea rdi, [rdi + 8]              ; move pionter to next block of number A
    lea rsi, [rsi + 8]              ; move pionter to next block of number B
    loop .loop

    ; ABI
    mov rsp, rbp
    pop rbp
    pop rbx
    pop rcx
    pop r12

    ret
    
section .bss
blocks_number: resq 1 
n: resq 1
sign: resq 1