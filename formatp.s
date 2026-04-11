default rel

global fformatp_
extern strlen
extern memset

; r12, r13, r14, r15, rbx, rsp, rbp are CALLEE-saved
; rest are CALLER-saved

BUF_SIZE equ 64
REG_SIZE equ 8

section .bss
formatp_buf: resb BUF_SIZE

section .text

REG_ARGC equ 6

fformatp_:
  pop r10  ; save return address since we will iterate through stack

  push r9  ; push register args to stack so that all 
  push r8  ; args are on stack in order
  push rcx ; from top to bottom
  push rdx ; as first to last
  push rsi ; for reference, r9 is sixth arg, and 
  push rdi ; rdi is the first arg (fd, second one is fmt str)

  push rbp ; save rbp
  mov rbp, rsp
  push r10
  push rbx
  push rax
  call handle_fmt_str
 
  .return:
    pop rax
    pop rbx
    pop r10
    pop rbp

    add rsp, REG_ARGC * REG_SIZE
    ;pop rdi
    ;pop rsi
    ;pop rdx
    ;pop rcx 
    ;pop r8
    ;pop r9
    push r10 ; push saved ret address onto the stack
    ret

; stack starting from rbp looks like this
; [0 - saved rbp][1 - fd arg][2 - fmt str arg][3+ fmt params]
FD_ARG_INDEX         equ 1
FMT_STR_ARG_INDEX    equ 2
FMT_ARGS_START_INDEX equ 3

%macro FD_WRITE 0 
  mov rax, 0x1
  mov rdi, [rbp + FD_ARG_INDEX * REG_SIZE] ; get fd we are currently working with
  syscall
%endmacro

NULL_CHAR   equ 0
CONV_SPEC   equ '%'
CHAR_SPEC   equ 'c'
STR_SPEC    equ 's'
DEC_SPEC    equ 'd'
UNSIGN_SPEC equ 'u'
BIN_SPEC    equ 'b'
TERN_SPEC   equ 't'
QUAT_SPEC   equ 'q'
OCT_SPEC    equ 'o'
LONG_SPEC   equ 'l'
HEX_U_SPEC  equ 'X'
HEX_L_SPEC  equ 'x'
BOOL_SPEC   equ 'B'

handle_fmt_str:
  ; r9 will store how many REG_SIZE sized shifts are we into processing the args
  mov r9,  FMT_ARGS_START_INDEX
  lea rdi, [formatp_buf]
  fmt_str_loop:
     lodsb
     cmp al, CONV_SPEC
     je .escape
       cmp al, NULL_CHAR
       je fmt_str_return
       call buf_append_ch
       jmp fmt_str_loop

     .escape:
       xor eax, eax
       lodsb
    
       xor cl, cl  ; cl is 0 (32 bit arg)
       cmp al, LONG_SPEC ; 64 bit arg instead of 32
       jne fmt_str_handle_fmt_char
       .set_long_arg_flag:
       inc cl      ; cl is now 1 (64 bit arg)
       lodsb
  
       fmt_str_handle_fmt_char:
       cmp al, HEX_U_SPEC ; edge case no. 1
       je fmt_hex_u
       cmp al, BOOL_SPEC ; edge case no. 2
       je fmt_bool 
       cmp al, CONV_SPEC ; edge case no. 3
       je fmt_percent
       cmp al, JMP_TABLE_FIRST_CHAR ; any below is def-tly an error
       jb fmt_error
       cmp al, JMP_TABLE_LAST_CHAR  ; any above is def-tly an error
       ja fmt_error
       
       lea rbx, [jmp_table]
       push rcx
       ; move with sign extension
       movsx rcx, dword [rbx + (rax - JMP_TABLE_FIRST_CHAR) * REG_SIZE]
       ; add [jmp_table] so that we compensate the relativeness of jmp_table's contents
       add rbx, rcx
       pop rcx
       jmp rbx
  fmt_str_return:
  	call buf_force_flush
    ret

fmt_bool:
  call ensure_no_64_prefix
  call load_64_arg
  push rsi
  test rax, rax
  jz .false
  .true:
  mov rcx, true_str_len
  lea rsi, [true_str]
  jmp .loop
  .false:
  mov rcx, false_str_len
  lea rsi, [false_str]
  .loop:
    lodsb
    call buf_append_ch
    loop .loop
  pop rsi
  jmp fmt_str_loop

fmt_percent:
  call ensure_no_64_prefix
  mov al, CONV_SPEC
  call buf_append_ch 
  jmp fmt_str_loop

fmt_char:
  call ensure_no_64_prefix
  call load_8_arg
  call buf_append_ch
  jmp fmt_str_loop

fmt_string:
  call ensure_no_64_prefix
  push rsi
  call buf_force_flush

  call load_64_arg
  mov rsi, rax
  test rsi, rsi
  jz .null
  .nonnull:
  mov rdi, rsi
  call strlen wrt ..plt
  mov rdx, rax 
  FD_WRITE
  pop rsi
  lea rdi, [formatp_buf]
  jmp fmt_str_loop
  .null:
  mov rdx, null_str_len
  lea rsi, [null_str]
  FD_WRITE
  pop rsi
  lea rdi, [formatp_buf]
  jmp fmt_str_loop

fmt_hex_u:
  call load_arg
  call hex2str_u
  jmp fmt_str_loop

fmt_hex_l:
  call load_arg
  call hex2str_l
  jmp fmt_str_loop

fmt_decimal:
  call load_arg
  test cl, cl
  jz  fmt_32_decimal
  jmp fmt_64_decimal

SIGN_BIT_MASK equ 0x80000000

fmt_32_decimal:
  test eax, SIGN_BIT_MASK
  jz fmt_decimal_common
  push rax
  call append_minus
  pop rax
  not eax
  inc eax
  jmp fmt_decimal_common

fmt_64_decimal:
  test rax, SIGN_BIT_MASK
  jz fmt_decimal_common
  push rax
  call append_minus
  pop rax
  not rax
  inc rax
  jmp fmt_decimal_common
  
fmt_unsign_decimal:
  call load_arg
  fmt_decimal_common:
  mov rbx, 10
  lea r10, [alpha_lower]
  call num2str
  jmp fmt_str_loop

fmt_binary:
  call load_arg
  call bin2str
  jmp fmt_str_loop

fmt_ternary:
  call load_arg
  mov rbx, 3
  lea r10, [alpha_lower]
  call num2str
  jmp fmt_str_loop

fmt_quat:
  call load_arg
  call quat2str
  jmp fmt_str_loop
  
fmt_octal:
  call load_arg
  call oct2str
  jmp fmt_str_loop

STDERR_FD equ 2
FMT_ERROR_ARGC equ 4

fmt_error:
  push [rbp + FMT_STR_ARG_INDEX * REG_SIZE] ; fmt str we failed to parse will be %s
  push rax ; push the char we failed to recognize as %c

  push rcx
  call buf_force_flush
  pop rcx
  
  test cl, cl
  jz .error_32 ; there was no LONG_SPEC specificator before
  lea rsi, [fmt_error_str_64]
  jmp .error_str_loaded
  .error_32:
  lea rsi, [fmt_error_str_32]
  .error_str_loaded:
  push rsi
  push STDERR_FD
  push rbp
  mov rbp, rsp
  call handle_fmt_str
  pop rbp
  add rsp, REG_SIZE * FMT_ERROR_ARGC
  jmp fmt_str_return

ensure_no_64_prefix:
  test cl, cl
  jz .no_error
  .error:
  add rsp, 1 * REG_SIZE ; pop the ret addr since we wont use it
  jmp fmt_error
  .no_error:
  ret

; Loads arg (if cl = 0, loads eax, otherwise loads rax), and increments r9
load_arg:
  test cl, cl
  jz .load_32
  .load_64:
  call load_64_arg
  ret
  .load_32:
  call load_32_arg
  ret

load_32_arg:
  mov eax, [rbp + r9 * REG_SIZE]
  inc r9
  ret

load_64_arg:
  mov rax, [rbp + r9 * REG_SIZE]
  inc r9
  ret

load_8_arg:
  mov al,  [rbp + r9 * REG_SIZE]
  inc r9
  ret

; appends a character at AL to buffer. If buffer is full, flushes it
buf_append_ch:
  lea r10, [formatp_buf + BUF_SIZE]
  cmp rdi, r10
  je .flush
  .store:
  stosb
  ret
  .flush:
  push rax
  push rsi
  lea rsi, [formatp_buf]
  mov rdx, BUF_SIZE
  call buf_flush
  pop rsi
  pop rax
  lea rdi, [formatp_buf]
  jmp .store

buf_force_flush:
  mov rdx, rdi
  lea rsi, [formatp_buf]
  sub rdx, rsi
  call buf_flush

buf_flush:
  FD_WRITE
  lea rdi, [formatp_buf]
  call clear_buf
  ret

append_minus:
  mov al, '-'
  call buf_append_ch
  ret

append_zero:
  mov al, '0'
  call buf_append_ch
  ret

clear_buf:
  mov rdx, rdi 
  lea rdi, [formatp_buf]
  sub rdx, rdi
  xor esi, esi ; rsi = NULL_TERM
  call memset wrt ..plt
  ret

%macro power_of_2_radix_to_str_func 2
  power_of_2_radix_to_str_func %1, %2, alpha
%endmacro

; macro for converting given power of 2 into str
; declares a label %1 that uses %2 shift and mask derived from it
; to get indexes of alphabet symbols from %3 and put them on the stack,
; then unwind and append it all to formatp_buf
%macro power_of_2_radix_to_str_func 3
 %1:
  test rax, rax
  jz num_zero
  xor ecx, ecx
  lea r10, [%3]
  .windup:
	  test rax, rax
	  jz num_unwind
	  mov rdx, rax
    and rdx, (1 << %2) - 1
    mov dl, [r10 + rdx]
    dec rsp
    mov byte [rsp], dl
	  shr rax, %2
    inc rcx
    jmp .windup
  jmp num_unwind 
%endmacro

BINARY_SHIFT equ 1
power_of_2_radix_to_str_func bin2str, BINARY_SHIFT

QUATERNARY_SHIFT equ 2
power_of_2_radix_to_str_func quat2str, QUATERNARY_SHIFT

OCTAL_SHIFT equ 3
power_of_2_radix_to_str_func oct2str, OCTAL_SHIFT

HEX_SHIFT equ 4
power_of_2_radix_to_str_func hex2str_l, HEX_SHIFT, alpha_lower
power_of_2_radix_to_str_func hex2str_u, HEX_SHIFT, alpha_upper

;--------------
; num2str - converts number to string of bytes (uses stack to reverse the order)
; Input:  rax    = number to convert
;         rbx    = radix
;         r10 -> alphabet string
;         rdi -> destination to convert into
; Destr:  rax, rdi, rdx, rcx 
;--------------
num2str:
  test rax, rax
  jz num_zero
  xor ecx, ecx
  .windup:
	  test rax, rax
	  jz num_unwind
	  xor edx, edx
	  div rbx ; rax = rax / rbx, rdx = rax % rbx
    mov dl, [r10 + rdx]
    dec rsp
    mov byte [rsp], dl
    inc rcx
    jmp .windup
  jmp num_unwind

num_zero:
  call append_zero
  ret

num_unwind:
  .loop:
    test rcx, rcx
    jz .exit
    mov byte al, [rsp]
    inc rsp
    push rcx
    call buf_append_ch
    pop rcx
    loop .loop
  .exit:
    ret

section .rodata

alpha equ alpha_lower
alpha_lower: db "0123456789abcdef"
alpha_upper: db "0123456789ABCDEF"

null_str: db "(null)"
null_str_len equ $ - null_str

false_str: db "false"
false_str_len equ $ - false_str
true_str: db "true"
true_str_len equ $ - true_str

fmt_error_str_64: db 0x0A, "[ERROR]: Unrecognized escape sequence: '%%l%c' in ", 0x22, "%s", 0x22, 0x0A, 0
fmt_error_str_32: db 0x0A, "[ERROR]: Unrecognized escape sequence: '%%%c' in ", 0x22, "%s", 0x22, 0x0A, 0

JMP_TABLE_FIRST_CHAR equ BIN_SPEC
JMP_TABLE_LAST_CHAR  equ HEX_L_SPEC

jmp_table:
                                         dq fmt_binary         - jmp_table
                                         dq fmt_char           - jmp_table
                                         dq fmt_decimal        - jmp_table
  times (OCT_SPEC - DEC_SPEC - 1)        dq fmt_error          - jmp_table
                                         dq fmt_octal          - jmp_table
  times (QUAT_SPEC - OCT_SPEC - 1)       dq fmt_error          - jmp_table
                                         dq fmt_quat           - jmp_table
  times (STR_SPEC - QUAT_SPEC - 1)       dq fmt_error          - jmp_table
                                         dq fmt_string         - jmp_table
                                         dq fmt_ternary        - jmp_table
                                         dq fmt_unsign_decimal - jmp_table
  times (HEX_L_SPEC - UNSIGN_SPEC - 1)   dq fmt_error          - jmp_table
                                         dq fmt_hex_l          - jmp_table
