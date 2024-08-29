.globl r_exponent, r_strcpy, r_memcpy, r_strlen, r_strncpy, r_strcat, r_strncat, r_memset, r_memcmp, r_strlen, r_strchr, r_strcmp, r_strncmp, r_atoi


.text
r_exponent:
    pushq %rdi
    xorq %rcx, %rcx
    movq %rdi, %rax

    cmpq $0, %rsi
    je r_exponent_zero

    decq %rsi

r_exponent_loop:
    cmpq %rsi, %rcx
    je r_exponent_exit

    mulq %rdi
    incq %rcx
    jmp r_exponent_loop

r_exponent_zero:
    movq $1, %rax

r_exponent_exit:
    popq %rdi
    ret

# Input:
# RDI - Dest
# RSI - Source
# RDX - Bytes to move
# RAX - Dest ptr
r_memcpy:
    pushq %rbx

    xorq %rbx, %rbx
    movq %rdx, %rbx

    xorq %rcx, %rcx
    jmp r_memcpy_cpy
r_memcpy_cpy:
    movb (%rsi, %rcx), %al
    movb %al, (%rdi, %rcx)
    cmpq $0, %rbx
    je r_memcpy_exit

    incq %rcx
    decq %rbx
    jmp r_memcpy_cpy
r_memcpy_exit:
    popq %rbx
    movq %rdi, %rax
    ret

# Input:
# RDI - Dest
# RSI - Char to set
# RDX - Bytes to set in dest
# RAX - ptr to dest
r_memset:
    xorq %rcx, %rcx # counter
r_memset_loop:
    cmpq %rdx, %rcx
    je r_memset_exit

    movb %sil, (%rdi, %rcx) # cpy char to dest

    incq %rcx # increase counter
    jmp r_memset_loop
r_memset_exit:
    movq %rdi, %rax # mov dest ptr to rax
    ret

# Input:
# RDI - Str1
# RSI - Str2
# RDX - Bytes to compare
# RAX - Result from -1 to 1
r_memcmp:
    pushq %rbx # it'll store our str1 byte
    xorq %rbx, %rbx

    xorq %rcx, %rcx # counter
r_memcmp_loop:
    movb (%rsi, %rcx), %al
    movb (%rdi, %rcx), %bl

    cmpb %al, %bl
    jl r_memcmp_str2
    jg r_memcmp_str1

    cmpq %rcx, %rdx
    je r_memcmp_eq

    incq %rcx
    jmp r_memcmp_loop
r_memcmp_str1:
    movq $1, %rax
    jmp r_memcmp_exit
r_memcmp_str2:
    movq $-1, %rax
    jmp r_memcmp_exit
r_memcmp_eq:
    movq $0, %rax
    jmp r_memcmp_exit
r_memcmp_exit:
    popq %rbx
    ret

# Input:
# RDI - Dest
# RSI - Source
# RDX - Bytes to move
# Output:
# RAX - ptr to dest
r_strncat:
    pushq %rdi

    call r_strlen
    addq %rax, %rdi # add dest length to the dest address, so we get at the end of the dest string

    call r_strncpy
    # movb $0, (%rdi, %rdx) # null terminate, though, r_strncpy does it for us

    popq %rdi
    movq %rdi, %rax
    ret

# Input:
# RDI - Dest
# RSI - Source
# Output:
# RAX - Ptr to dest
r_strcat:
    pushq %rdi
    
    call r_strlen
    addq %rax, %rdi # add dest length to the dest address, so we get at the end of the dest string
    
    call r_strcpy

    popq %rdi
    movq %rdi, %rax
    ret


# Input:
# RDI - Dest
# RSI - Source
# Output:
# RAX - Ptr to dest
r_strcpy:
    xorq %rcx, %rcx
    jmp r_strcpy_cpy
r_strcpy_cpy:
    movb (%rsi, %rcx), %al
    movb %al, (%rdi, %rcx)
    testb %al, %al
    je r_strcpy_exit
    incq %rcx
    jmp r_strcpy_cpy
r_strcpy_exit:
    movq %rdi, %rax
    ret

# Input:
# RDI - Dest
# RSI - Source
# RDX - Bytes to move
# Output:
# RAX - ptr to dest
r_strncpy:
    xorq %rcx, %rcx # counter
r_strncpy_loop:
    cmpq %rcx, %rdx # check if we moved enough
    je r_strncpy_finalize

    movb (%rsi, %rcx), %al # move byte to buffer
    movb %al, (%rdi, %rcx) # move byte to dst before je

    cmpb $0, %al # check if its nullptr
    je r_strncpy_finalize # if it is, finalize the string with zeros

    incq %rcx # increase counter before iteration
    jmp r_strncpy_loop
r_strncpy_finalize:
    cmpq %rcx, %rdx # if we have space, do zeros
    je r_strncpy_exit

    movb $0, (%rdi, %rcx) # fill with zeros
    incq %rcx
    jmp r_strncpy_finalize
r_strncpy_exit:
    movb $0, (%rdi, %rdx) # null terminate the last byte
    movq %rdi, %rax
    ret

# Input:
# RDI - Str to search in
# RSI - Char to search for
# Output:
# RAX - Ptr to the first occurence in dst, or null if not found
r_strchr:
    pushq %rdx # used as buffer
    pushq %rbx # used to store rdi strlen
    xorq %rcx, %rcx # used as counter

    call r_strlen # get rdi len and store in rbx
    movq %rax, %rbx
    movq $0, %rax # mov nullptr to rax as not found value
r_strchr_loop:
    cmpq %rcx, %rbx # check if we came over all str now
    je r_strchr_exit

    movb (%rdi, %rcx), %dl

    cmpb %dl, %sil
    je r_strchr_found

    incq %rcx
    jmp r_strchr_loop
r_strchr_found:
    pushq %rdi # push our real rdi to stack
    addq %rcx, %rdi # now we have first occurence address
    movq %rdi, %rax # mov this address to output
    popq %rdi # get rdi back
    jmp r_strchr_exit # exit now
r_strchr_exit:
    popq %rbx
    popq %rdx
    ret

# Input:
# RDI - Str1
# RSI - Str2
# Output:
# RAX - value from 0 to 1
r_strcmp:
    pushq %rdx
    call r_strlen
    movq %rax, %rdx
    call r_memcmp
    popq %rdx
    ret

# Input:
# RDI - Str1
# RSI - Str2
# RDX - Bytes to compare
# Output:
# RAX - value from 0 to 1
r_strncmp:
    call r_memcmp
    ret

# Input:
# RDI - String pointer
# Output:
# RAX - String length
r_strlen:
    pushq %rsi

    movq %rdi, %rsi
    xorq %rcx, %rcx

r_strlen_loop:
    movb (%rsi, %rcx), %al  # Load byte at address (%rsi + %rcx) into %al
    testb %al, %al          # Test if the byte is zero (null terminator)
    je r_strlen_done
    incq %rcx
    jmp r_strlen_loop
r_strlen_done:
    movq %rcx, %rax

    popq %rsi
    ret

# Input:
# RDI - Str to convert
# Output:
# RAX - Converted value or nullptr if not a number
r_atoi:
    pushq %rdx
    xorq %rax, %rax
    xorq %rdx, %rdx
    xorq %rcx, %rcx

r_atoi_loop:
    movb (%rdi, %rcx), %al
    testb %al, %al
    je r_atoi_finalize

    cmpb $'0', %al
    jb r_atoi_abort

    cmpb $'9', %al
    ja r_atoi_abort

    subb $'0', %al
    imulq $10, %rdx
    addq %rax, %rdx

    incq %rcx
    jmp r_atoi_loop

r_atoi_abort:
    xorq %rax, %rax
    jmp r_atoi_exit

r_atoi_finalize:
    movq %rdx, %rax

r_atoi_exit:
    popq %rdx
    ret