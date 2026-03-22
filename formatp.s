global formatp
extern strlen
extern clear_buffer

BUF_SZ equ 64

section .bss
formatp_buf: resb BUF_SZ

section .text

;--------------
; Num2Str - converts decimal number to string of bytes (uses stack to reverse the order)
; Input:  rax    = number to convert
;         es:rdi -> destination to convert into
; Output: rcx = amount of characters written
; Destr:  rax, rdi, rbx, rdx 
;--------------
Num2Str:
	mov rbx, 10
  xor rcx, rcx
  test rax, rax
  jz .zero
.windup:
	test rax, rax
	jz .pre_unwind
	xor rdx, rdx
	div rbx ; rax = rax/rbx, rdx = rax % rbx
	add dl, '0'
  dec rsp
  mov byte [rsp], dl
  inc rcx
  jmp .windup
.pre_unwind:
  mov rbx, rcx
.unwind:
  test rcx, rcx
  jz .exit
  mov byte dl, [rsp]
  inc rsp
  mov byte [rdi], dl
  inc rdi
  loop .unwind
.exit:
  mov rcx, rbx
  ret
.zero:
  mov [rdi], '0'
  inc rdi
  mov rcx, 1
  ret

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
    mov rdi, formatp_buf
    call strlen ; call to a libc function

    mov rdx, rax ; strlen return is now used as count
  	mov rax, 0x1
  	mov rsi, formatp_buf
  	mov rdi, 0x1
  	syscall
    mov rdi, formatp_buf
    call clear_buffer ; call to my own function in main.c

    pop rbp

    add rsp, 8 * 6 ; equivalent to pop rdi, rsi, ..., r9
    push r15 ; push saved ret address onto the stack
    ret

handle_fmt_str:
  mov r13, 2 ; how many 8 offsets are we into the stack
  mov rdi, formatp_buf
  .loop:
    mov al, [rsi]
    cmp al, '%'
    jne .not_escape
      inc rsi
      mov al, [rsi]
      inc rsi
      cmp al, 'c'
      jne .not_char
      mov al, [rbp + r13 * 8]
      inc r13
      stosb
      jmp .loop
      .not_char:
      cmp al, '%'
      jne .error
      mov al, '%'
      stosb
      jmp .loop
    .not_escape:
    cmp al, 0
    je .return
    movsb
  jmp .loop
  .return:
    ret
  .error:
    push rax

    mov rdi, formatp_buf
    call clear_buffer

    mov rsi, fmt_error_str
    push rsi
    push rbp ; save rbp
    mov rbp, rsp
    call handle_fmt_str
    pop rbp
    add rsp, 8 * 2
    ret

section .data

fmt_error_str: db 0x0A, "[ERROR]: Unrecognized escape sequence: '%%%c'", 0x0A
fmt_error_str_len equ $ - fmt_error_str
