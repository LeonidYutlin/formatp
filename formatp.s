global formatp
extern strlen
extern clear_buffer

BUF_SZ equ 16

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
  .convert:
    mov rax, rdi
  	mov rdi, formatp_buf
  	call Num2Str
 
  .print:
    mov rdi, formatp_buf
    call strlen ; call to a libc function

    mov rdx, rax ; strlen return is now used as count
  	mov rax, 0x1
  	mov rsi, formatp_buf
  	mov rdi, 0x1
  	syscall

    mov rdi, formatp_buf
    mov rsi, rdx ; still using that strlen return as count
                 ; since it is not changed by prev syscall
    call clear_buffer ; call to my own function in main.c
  ret

formatp1:
  .convert:
    mov rax, rdi
  	mov rdi, formatp_buf
  	call Num2Str
 
  .print:
  	mov rdx, rcx
  	mov rax, 0x1
  	mov rsi, formatp_buf
  	mov rdi, 0x1
  	syscall
  ret
