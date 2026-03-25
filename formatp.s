global fformatp_
extern strlen
extern clear_buffer

; r12, r13, r14, r15, rbx, rsp, rbp are CALLEE-saved
; rest are CALLER-saved

BUF_SIZE equ 16
REG_SIZE equ 8

section .bss
formatp_buf: resb BUF_SIZE

section .text

fformatp_:
  pop r15  ; save return address since we will iterate through stack

  push r9  ; push register args to stack so that all 
  push r8  ; args are on stack in order
  push rcx ; from top to bottom
  push rdx ; as first to last
  push rsi ; for reference, r9 is sixth arg, and 
  push rdi ; rdi is the first arg (fd, second one is fmt str)

  push rbp ; save rbp
  mov rbp, rsp
  call handle_fmt_str
 
  .return:
    pop rbp

    pop rdi
    pop rsi
    pop rdx
    pop rcx 
    pop r8
    pop r9

    push r15 ; push saved ret address onto the stack
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

NULL_CHAR equ 0

handle_fmt_str:
  ; r9 will store how many REG_SIZE sized shifts are we into processing the args
  mov r9, FMT_ARGS_START_INDEX
  mov rdi, formatp_buf
  fmt_str_loop:
    mov al, [rsi]
    cmp al, '%'
    je .escape
      cmp al, NULL_CHAR
      je fmt_str_return
      call buf_movsb
      jmp fmt_str_loop
    .escape:
      inc rsi
      xor rax, rax
      mov al, [rsi]
      inc rsi

      xor cl, cl  ; cl is 0 (32 bit arg)
      cmp al, 'l' ; 64 bit arg instead of 32
      jne fmt_str_handle_fmt_char
      .set_long_arg_flag:
      inc cl      ; cl is now 1 (64 bit arg)
      mov al, [rsi]
      inc rsi

      fmt_str_handle_fmt_char:
      cmp al, 'X' ; edge case no. 1
      je fmt_hex_u
      cmp al, 'B' ; edge case no. 2
      je fmt_bool 
      cmp al, '%' ; edge case no. 3
      je fmt_percent
      cmp al, JMP_TABLE_FIRST_CHAR ; any below is def-tly an error
      jb fmt_error
      cmp al, JMP_TABLE_LAST_CHAR  ; any above is def-tly an error
      ja fmt_error
        
      mov rbx, [jmp_table + (rax - JMP_TABLE_FIRST_CHAR) * REG_SIZE]
      jmp rbx
    fmt_str_return:
      mov rdx, rdi
      sub rdx, formatp_buf ; now rdx has count of written bytes
  	  mov rsi, formatp_buf
  	  call buf_flush
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

fmt_bool:
  push rsi
  mov rdx, rdi
  sub rdx, formatp_buf
  mov rsi, formatp_buf
  call buf_flush

  call load_64_arg
  mov rsi, rax
  test rsi, rsi
  jz .false
  .true:
  mov rsi, true_str
  mov rdx, true_str_len
  FD_WRITE
  pop rsi
  mov rdi, formatp_buf
  jmp fmt_str_loop
  .false:
  mov rsi, false_str
  mov rdx, false_str_len
  FD_WRITE
  pop rsi
  mov rdi, formatp_buf
  jmp fmt_str_loop

fmt_percent:
  mov al, '%'
  call buf_append_ch 
  jmp fmt_str_loop

fmt_char:
  call load_8_arg
  call buf_append_ch
  jmp fmt_str_loop

fmt_string:
  push rsi
  mov rdx, rdi
  sub rdx, formatp_buf
  mov rsi, formatp_buf
  call buf_flush

  call load_64_arg
  mov rsi, rax
  test rsi, rsi
  jz .null
  .nonnull:
  mov rdi, rsi
  call strlen
  mov rdx, rax 
  FD_WRITE
  pop rsi
  mov rdi, formatp_buf
  jmp fmt_str_loop
  .null:
  mov rdx, null_str_len
  mov rsi, null_str
  FD_WRITE
  pop rsi
  mov rdi, formatp_buf
  jmp fmt_str_loop

fmt_hex_u:
  call load_arg
  mov rbx, 16
  mov r14, hex_alpha_upper
  call num2str
  jmp fmt_str_loop

fmt_hex_l:
  call load_arg
  mov rbx, 16
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

fmt_decimal:
  call load_arg
  test cl, cl
  jz  fmt_32_decimal
  jmp fmt_64_decimal

append_minus:
  push rax
  mov al, '-'
  call buf_append_ch
  pop rax
  ret

SIGN_BIT_MASK equ 0x80000000

fmt_32_decimal:
  test eax, SIGN_BIT_MASK
  jz fmt_decimal_common
  call append_minus
  not eax
  inc eax
  jmp fmt_decimal_common

fmt_64_decimal:
  test rax, SIGN_BIT_MASK
  jz fmt_decimal_common
  call append_minus  
  not rax
  inc rax
  jmp fmt_decimal_common

fmt_unsign_decimal:
  call load_arg
  fmt_decimal_common:
  mov rbx, 10
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

fmt_binary:
  call load_arg
  mov rbx, 2
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

fmt_octal:
  call load_arg
  mov rbx, 8
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

STDERR_FD equ 2
FMT_ERROR_ARGC equ 4

fmt_error:
  push [rbp + FMT_STR_ARG_INDEX * REG_SIZE] ; fmt str we failed to parse will be %s
  push rax ; push the char we failed to recognize as %c

  push rcx
  mov rdx, rdi
  sub rdx, formatp_buf
  mov rsi, formatp_buf
  call buf_flush
  pop rcx

  test cl, cl
  jz .error_32 ; there was no 'l' specificator before
  mov rsi, fmt_error_str_64
  jmp .error_str_loaded
  .error_32:
  mov rsi, fmt_error_str_32
  .error_str_loaded:
  push rsi
  push STDERR_FD
  push rbp
  mov rbp, rsp
  call handle_fmt_str
  pop rbp
  add rsp, REG_SIZE * FMT_ERROR_ARGC
  jmp fmt_str_return

buf_movsb:
  ;push rax
  mov al, [rsi]
  call buf_append_ch
  inc rsi
  ;pop rax
  ret 

; appends a character at AL to buffer. If buffer is full, flushes it
buf_append_ch:
  cmp rdi, formatp_buf + BUF_SIZE
  je .flush
  .store:
  stosb
  ret
  .flush:
  push rax
  push rsi
  mov rsi, formatp_buf
  mov rdx, BUF_SIZE
  call buf_flush
  pop rsi
  pop rax
  mov rdi, formatp_buf
  jmp .store

buf_flush:
  FD_WRITE
  mov rdi, formatp_buf
  call clear_buffer ; call to my own function in main.c
  ret

;--------------
; num2str - converts number to string of bytes (uses stack to reverse the order)
; Input:  rax    = number to convert
;         rbx    = radix
;         r14 -> alphabet string
;         rdi -> destination to convert into
; Destr:  rax, rdi, rdx, rcx 
;--------------
num2str:
  xor rcx, rcx
  test rax, rax
  jz .zero
.windup:
	test rax, rax
	jz .unwind
	xor rdx, rdx
	div rbx ; rax = rax / rbx, rdx = rax % rbx
  mov dl, [r14 + rdx]
  dec rsp
  mov byte [rsp], dl
  inc rcx
  jmp .windup
.unwind:
  test rcx, rcx
  jz .exit
  mov byte al, [rsp]
  inc rsp
  push rcx
  call buf_append_ch
  pop rcx
  loop .unwind
.exit:
  ret
.zero:
  mov al, '0'
  call buf_append_ch
  ret

section .data

hex_alpha_lower: db "0123456789abcdef"
hex_alpha_upper: db "0123456789ABCDEF"

null_str: db "(null)"
null_str_len equ $ - null_str

false_str: db "false"
false_str_len equ $ - false_str
true_str: db "true"
true_str_len equ $ - true_str

fmt_error_str_64: db 0x0A, "[ERROR]: Unrecognized escape sequence: '%%l%c' in ", 0x22, "%s", 0x22, 0x0A, 0
fmt_error_str_32: db 0x0A, "[ERROR]: Unrecognized escape sequence: '%%%c' in ", 0x22, "%s", 0x22, 0x0A, 0

JMP_TABLE_FIRST_CHAR equ 'b'
JMP_TABLE_LAST_CHAR  equ 'x'

jmp_table:
                          dq fmt_binary
                          dq fmt_char
                          dq fmt_decimal
  times ('o' - 'd' - 1)   dq fmt_error
                          dq fmt_octal
  times ('s' - 'o' - 1)   dq fmt_error
                          dq fmt_string
  times ('u' - 's' - 1)   dq fmt_error
                          dq fmt_unsign_decimal
  times ('x' - 'u' - 1)   dq fmt_error
                          dq fmt_hex_l
