global formatp
extern strlen
extern clear_buffer

buf_sz equ 16

section .bss
formatp_buf: resb buf_sz

section .text

formatp:
  pop r15 ; save return address since we will iterate through stack

  push r9  ; push register args to stack so that all 
  push r8  ; args are on stack in order
  push rcx ; from top to bottom
  push rdx ; as first to last
  push rsi ; for reference, r9 is sixth arg, and 
  push rdi ; rdi is the first arg (fmt str)

  push rbp ; save rbp
  mov rbp, rsp
  mov rsi, rdi ; move fmt str to source index
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

handle_fmt_str:
  mov r9, 2 ; how many 8 offsets are we into the stack
  mov rdi, formatp_buf
  fmt_str_loop:
    mov al, [rsi]
    cmp al, '%'
    je .escape
      cmp al, 0
      je fmt_str_return
      call buf_movsb
      jmp fmt_str_loop
    .escape:
      inc rsi
      xor rax, rax
      mov al, [rsi]
      inc rsi

      cmp al, 'X' ; edge case no. 1
      je fmt_hex_u 
      cmp al, '%' ; edge case no. 2
      je fmt_percent
      cmp al, 'b' ; any below is def-tly an error
      jb fmt_error
      cmp al, 'x' ; any above is def-tly an error
      ja fmt_error
        
      mov rbx, [jmp_table + (rax - 'b') * 8]
      jmp rbx
    fmt_str_return:
      mov rdi, formatp_buf
      call strlen ; call to a libc function

      mov rdx, rax ; strlen return is now used as count
  	  mov rsi, formatp_buf
  	  call buf_flush
      ret
 
fmt_percent:
  mov al, '%'
  call buf_append_ch 
  jmp fmt_str_loop

fmt_char:
  mov al, [rbp + r9 * 8]
  inc r9
  call buf_append_ch
  jmp fmt_str_loop

fmt_string:
  push rsi
  mov rdi, formatp_buf
  call strlen

  mov rdx, rax
  mov rsi, formatp_buf
  call buf_flush

  mov rsi, [rbp + r9 * 8]
  inc r9
  test rsi, rsi
  jz .null
  mov rdi, rsi
  call strlen
  mov rdx, rax
  mov rax, 0x1
  mov rdi, 0x1
  syscall
  pop rsi
  mov rdi, formatp_buf
  jmp fmt_str_loop
  .null:
  mov rdx, null_str_len
  mov rsi, null_str
  mov rdi, 0x1
  mov rax, 0x1
  syscall
  pop rsi
  mov rdi, formatp_buf
  jmp fmt_str_loop

fmt_hex_u:
  mov rax, [rbp + r9 * 8]
  inc r9
  mov rbx, 16
  mov r14, hex_alpha_upper
  call num2str
  jmp fmt_str_loop

fmt_hex_l:
  mov rax, [rbp + r9 * 8]
  inc r9
  mov rbx, 16
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

fmt_decimal:
  mov rax, [rbp + r9 * 8]
  inc r9
  mov rbx, 10
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

fmt_binary:
  mov rax, [rbp + r9 * 8]
  inc r9
  mov rbx, 2
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

fmt_octal:
  mov rax, [rbp + r9 * 8]
  inc r9
  mov rbx, 8
  mov r14, hex_alpha_lower
  call num2str
  jmp fmt_str_loop

fmt_error:
  push rax

  mov rdi, formatp_buf
  call strlen 

  mov rdx, rax 
  mov rsi, formatp_buf
  call buf_flush

  mov rsi, fmt_error_str
  push rsi
  push rbp ; save rbp
  mov rbp, rsp
  call handle_fmt_str
  pop rbp
  add rsp, 8 * 2
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
  cmp rdi, formatp_buf + buf_sz
  je .flush
  .store:
  stosb
  ret
  .flush:
  push rax
  push rsi
  mov rsi, formatp_buf
  mov rdx, buf_sz
  call buf_flush
  pop rsi
  pop rax
  mov rdi, formatp_buf
  jmp .store

buf_flush:
  mov rax, 0x1
  mov rdi, 0x1
  syscall
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
  call buf_append_ch
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

fmt_error_str: db 0x0A, "[ERROR]: Unrecognized escape sequence: '%%%c'", 0x0A, 0

jmp_table:
                          dq fmt_binary
                          dq fmt_char
                          dq fmt_decimal
  times ('o' - 'd' - 1)   dq fmt_error
                          dq fmt_octal
  times ('s' - 'o' - 1)   dq fmt_error
                          dq fmt_string
  times ('x' - 's' - 1)   dq fmt_error
                          dq fmt_hex_l
