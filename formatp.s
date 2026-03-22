global formatp

BUF_SZ equ 256

section .bss
outbuf: resb BUF_SZ

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
    mov rax, 890
  	mov rdi, outbuf
  	call Num2Str
 
  .print:
  	mov rdx, rcx
  	mov rax, 0x1
  	mov rsi, outbuf
  	mov rdi, 0x1
  	syscall
  ret
