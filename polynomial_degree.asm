global polynomial_degree

section .text

; Counts and returns the smallest degree of the polynomial w(x), such that w(x + kr) = y_k 
; (for a certain real number x, a certain non-zero real number r and k = 0, 1, 2, … , n−1).
;
; two arguments: 
; - rdi: pointer to the beginning of an array
; - rsi: size of the array
;
; return result:
; - rax: smallest degree of the polynomial w(x) that we were looking for
;
; modified registers:
; - rax, r10, rcx, rsi, rdi, rbp (but returned value), rsp (but returned value)
polynomial_degree:
        ; ABI
        push    rbp
        mov     rbp, rsp

; finding number of 8-byte blocks needed for array y
        mov     rax, rsi                   ; rax = n
        mov     [rel n], rsi
        add     rax, 32                    ; rax = n + 32
        shr     rax, 6                     ; rax = (n + 32) / 64
        add     rax, 1                     ; rax = (n + 32) / 64 + 1
        mov     [rel blocks_number], rax   ; number of blocks in one number
        mul     rsi                        ; rax = n * ((n + 32) / 64 + 1) 
        shl rax, 3                         ; rax = n * ((n + 32) / 64 + 1) * 8
        sub     rsp, rax                   ; saving space for all the numbers on the stack

; read the input array and save it on the stack
        mov     r10, 0                     ; set global counter of zeros to 0
        mov     rcx, [rel n]               ; init counter (int i in loop)
        mov     rax, rdi                   ; read first argument's value
        mov     rdi, rsp                   ; init first argument of function fill_number (as the pointer to bottom 
                                           ; of the stack because that is the end of the first number)                     
.loop:
        movsxd  rsi, [rax]                 ; init second argument of function fill_number which is the value of y_k
                                           ; (it is under pointer in rax) 
        cmp     rsi, 0
        jnz     .answer_is_not_zero        ; if the number y_k (currently in register rsi) was a zero
        inc     r10                        ; we increase the global counter of zeros

.answer_is_not_zero: 
        call    fill_number
                                           ; after call fill_number rdi is set to the first block of the number that was
        lea     rdi, [rdi + 8]             ; just filled, so to go to the end of the next number we need to add 8 bytes 
        lea     rax, [rax + 4]             ; go to the pointer to the next number in the array y_n
        loop    .loop

; count the smallest degree
        cmp     r10, [rel n]               ; if the array consists of only zeros return -1
        jne     .not_only_zeros
        mov     rax, -1
        jmp     .end

.not_only_zeros:                           ; if the array doesn't consist of only zeros count the degree in a loop
        mov     r11, [rel blocks_number]
        mov     rax, [rel n]

.counting_degree:
        mov     rdi, rsp                   ; set first argument of bigint_sub to the first number in the stack
        mov     rsi, rsp
        lea     rsi, [rsi + r11 * 8]       ; set second argument of bigint_sub to the second number in the stack

        mov     r10, 0                     ; set global counter of not zeros to 0

        mov     rcx, rax
        dec     rcx                        ; we only need to do [rax] - 1 subtractions because there are [rax] numbers 
        jz      .subtracting_end           ; if rcx = 0 omit the loop -> no need to subtract anything

.subtracting_loop:
        call    bigint_sub                 ; after this function the pointers point to the "end" of the next numbers
        loop    .subtracting_loop 

.subtracting_end:
        cmp     r10, 0
        je      .counting_end              ; if all the answers of the subtractions were = 0 then we end the loop

        dec     rax
        jnz     .counting_degree
        
.counting_end:
        sub     [rel n], rax
        mov     rax, [rel n]

.end:
        ; ABI
        mov rsp, rbp
        pop rbp

        ret

; Saves the number onto the stack and fills the rest of the 8-byte blocks (that were not filled by the number but are
; used to represent the number) with 0 or 1 (if the number is < 0 then the rest of the 8-byte blocks need to be 
; filled with 1's to keep the numbers original value - analogically if the number is > 0 but the 8-byte blocks need 
; to be filled with 0's).
;
; two arguments: 
; - rdi: pointer to the "end" of number A destination,
; - rax: value of number A
;
; return result:
; - saves number A on the stack in its destination
;
; modified registers:
; - r9, rdi, rcx (but returned value)

fill_number: 
        push    rcx

        mov     QWORD[rel sign], 0;        ; init sign to zero (we assume the number is not < 0)
        cmp     rsi, [rel sign]            ; check the sign of the number
        jnl     .end_if                    ; if the number is < 0 we need to fill the rest of the 8-byte blocks with 1
        mov     QWORD[rel sign], -1        ; fill all the bits in [sign] with 1's (make it equal to -1)

.end_if:
        mov     [rdi], rsi                 ; move number value of A to its destination on the stack
        mov     rcx, [rel blocks_number]   ; i = number of blocks - 1
        dec     rcx                        ; ---------====------------
        
        jz      .end                       ; if rcx = 0 omit the loop
.loop:                                     ; fill rest of blocks with [rel sign]
        lea     rdi, [rdi + 8]             ; move to the next block
        mov     r9, [rel sign]
        mov     [rdi], r9                  ; fill the 8-byte block with the appropriate sign
        loop    .loop
.end:
        pop rcx                            ; end of function and return the value of rcx from before calling the function

        ret

; Subtracts two big numbers A and B (represented in the form of [blocks_number] number of 8-byte blocks) 
; from each other, saving the result in the place of number A.
;
; two arguments: 
; - rdi: pointer to end of number A
; - rsi: pointer to end of number B
;
; return result:
; - saves the difference of A and B in the place of number A on the stack
; - rdi and rsi point to the "end" of the next two numbers on the stack
;
; modified registers:
; - r9, rdi, rsi, rcx (but returned value) 

bigint_sub: 
        push    rcx

        mov     rcx, [rel blocks_number]   ; read the number of blocks
        clc                                ; clear carry flag

.loop:
        mov     r9, [rdi]                  ; load number A to subtract number B from it
        sbb     r9, [rsi]                  ; subtraction between one block of number A and B
        mov     [rdi], r9                  ; write the answer in the place of number A 

        jz      .answer_is_zero            ; check if the result of the subtraction was equal 0
        inc     r10                        ; update the global counter of differences (of A and B) that were not 0

.answer_is_zero:
        lea     rdi, [rdi + 8]             ; move pointer to next block of number A
        lea     rsi, [rsi + 8]             ; move pointer to next block of number B
        loop    .loop

        pop rcx                            ; end function and return the value of rcx from before calling the function

        ret
    
section .bss
blocks_number: resq 1 
n: resq 1
sign: resq 1