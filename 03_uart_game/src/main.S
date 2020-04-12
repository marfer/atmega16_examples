#define OUT_BUFFER_LENGTH 350
#define IN_BUFFER_LENGTH 250
#include <avr/io.h>
#include "macro.S"

.text
.org 0x0000

#include "vectors.S"

#include "fifo-buffer.S"
#include "uart.S"
#include "random.S"
#include "utils.S"

;------------------------------------
; interrupts:
;------------------------------------
; RX
;------------------------------------
rx_ok:
	in tmp2, _SFR_IO_ADDR(UDR)	
	cpi tmp2, 0x0D ; or 0x0A		; check for "Enter"
	breq _rx_enter
	lds tmp1, mode
	cpi tmp1, 0
	brne _rx_store_input
	reti
_rx_store_input:
	FIFO_BUFFER_PUSH in_buffer, tmp2
	FIFO_BUFFER_PUSH out_buffer, tmp2		; echo back
	FIFO_BUFFER_SIZE in_buffer
	cpi tmp1, 2
	breq _rx_enter
	rjmp _rx_replay

_rx_enter:
	lds tmp1, mode				; load game mode
	tst tmp1
	breq _rx_game_start
	;cpi tmp1, 0x01				; guessing
	rjmp _rx_guess
	
_rx_game_start:		
	ldi tmp1, 0x01
	sts mode, tmp1				; save mode 1 (start of the game)
	FIFO_BUFFER_COPY_STR out_buffer str_prompt1
	rjmp _rx_replay	

_rx_guess:
	; --------------------------------------------------------------
	;ldi tmp1, '<'
	;PUSH_BUFFER out_buffer, tmp1	
	; ------------- 
	; check size of buffer, if 0 then skip
	FIFO_BUFFER_SIZE in_buffer
	tst tmp1
	breq _rx_replay
	cpi tmp1, 2
	breq _rx_test
	; add 0 before if we have one digit in buffer
	FIFO_BUFFER_POP in_buffer
	; check this is number
	cpi tmp1, 0x30
	brlo _rx_l1
	cpi tmp1, 0x3A
	brsh _rx_l1
	mov r5, tmp1
	ldi tmp1, 0x30
	FIFO_BUFFER_PUSH in_buffer, tmp1
	FIFO_BUFFER_PUSH in_buffer, r5
	rjmp _rx_test
_rx_l1:
	rjmp _rx_not_number
	; tezt first number
_rx_test:
	FIFO_BUFFER_POP in_buffer		
	mov tmp3, tmp1
	FIFO_BUFFER_POP in_buffer
	mov tmp4, tmp1
	
	cpi tmp4, 0x30
	brlo _rx_not_number
	cpi tmp3, 0x30
	brlo _rx_not_number

	cpi tmp4, 0x3A
	brsh _rx_not_number
	cpi tmp3, 0x3A
	brsh _rx_not_number

	LDY x_number				
	ld tmp1, Y 
	cp tmp3, tmp1
	brlo _rx_lower
	cp tmp1, tmp3
	brlo _rx_greater
	; --- first match, check next
	ldd tmp1, Y+1
	cp tmp4, tmp1	
	breq _rx_win
	brlo _rx_lower
	rjmp _rx_greater

_rx_replay:
	sbi _SFR_IO_ADDR(UCSRB), UDRIE
	reti

_rx_lower:
	FIFO_BUFFER_COPY_STR out_buffer str_lower
	FIFO_BUFFER_INIT in_buffer, IN_BUFFER_LENGTH
	rjmp _rx_replay

_rx_greater:
	FIFO_BUFFER_COPY_STR out_buffer str_greater
	FIFO_BUFFER_INIT in_buffer, IN_BUFFER_LENGTH
	rjmp _rx_replay

_rx_not_number:
	FIFO_BUFFER_COPY_STR out_buffer str_not_number
	FIFO_BUFFER_INIT in_buffer, IN_BUFFER_LENGTH
	rjmp _rx_replay
	

_rx_win:
	call next_random
	FIFO_BUFFER_COPY_STR out_buffer str_win
	sts mode, ZERO
	FIFO_BUFFER_INIT in_buffer, IN_BUFFER_LENGTH
	rjmp _rx_replay
	
;------------------------------------
; UDR_EMPTY
;------------------------------------
ud_ok:
	FIFO_BUFFER_POP out_buffer ; tmp1 -> byte readed  tmp2 -> error if not zero
	tst tmp2
	brne udrl1
	out _SFR_IO_ADDR(UDR), tmp1
	reti
udrl1:
	; disable udr_empty interrupt - we are done, next enable on rx
	cbi _SFR_IO_ADDR(UCSRB), UDRIE
	reti

;------------------------------------
; TX_OK
;------------------------------------
tx_ok:
	reti

;------------------------------------
;------------------------------------
; Main entry point
;------------------------------------
;------------------------------------
init: 
	INIT
	ldi tmp1, 0xFF
	mov r2, tmp1
	clr tmp1
	clr tmp2
	clr tmp3
	clr tmp4

	FIFO_BUFFER_INIT out_buffer, OUT_BUFFER_LENGTH
	FIFO_BUFFER_INIT in_buffer, IN_BUFFER_LENGTH
	; init usart 	
	UART_INIT
	call init_rnd
	call next_random
	sts mode, ZERO
	; init random
	FIFO_BUFFER_COPY_STR out_buffer str_prompt
	; enable UDRIE to initiate sending
	sbi _SFR_IO_ADDR(UCSRB), UDRIE
	sei

busy_loop:
	; do other serious job here
	nop
	nop
	rjmp busy_loop	


next_random:
	call random
	mov a0, RND	
	call binbcd
	LDY x_number
	st Y, a0
	std Y+1, a1
	ret



; Data
str_entered_pre:
	.asciz "\r\n You entered -> ["
str_entered_post:
	.asciz "]"
	.byte 0
str_prompt:
	.ascii "\r\n Ready to play? Press 'Enter'..."
	.byte 0
str_greater:
	.asciz " - is greater than my number\r\n"
str_lower:
	.asciz " - is lower than my number\r\n"
str_prompt1:
	.ascii "\r\n"
	.ascii "\r\n   /\\     /\\"
	.ascii "\r\n  {  `---'  }"
	.ascii "\r\n  {  O   O  }"
	.ascii "\r\n  ~~>  V  <~~"
	.ascii "\r\n   \\  \\|/  /          Guess number from 0 to 99"
	.ascii "\r\n    `-----'____"
	.ascii "\r\n    /     \\    \\_"
	.ascii "\r\n   {       }\\  )_\\_   _"
	.ascii "\r\n   |  \\_/  |/ /  \\_\\_/ )"
	.ascii "\r\n    \\__/  /(_/     \\__/"
	.asciz "\r\n      (__/\r\n"
str_win:
	.ascii "\r\n"
	.ascii "\r\n      /\\___/\\"
	.ascii "\r\n     /       \\"
	.ascii "\r\n    l  u   u  l"
	.ascii "\r\n  --l----*----l--"
	.ascii "\r\n     \\   w   /     - Whoo hoo!"
	.ascii "\r\n       ======"
	.ascii "\r\n     /       \\ __"
	.ascii "\r\n     l        l\\ \\"
	.ascii "\r\n     l        l/ /"
	.ascii "\r\n     l  l l   l /"
	.ascii "\r\n     \\ ml lm /_/\r\n"
	.asciz "\r\n Wanna play again? [Enter] \r\n"
str_not_number:
	.asciz " - not a number \r\n"
.section .bss
; -> struct for out buffer
.lcomm out_buffer, OUT_BUFFER_LENGTH+FIFO_BUFFER_HEADER_LENGTH ; buffer_end_pointer(2)+read_pointer(2)+write_pointer(2)+flags(1)
; -> struct for in buffer
.lcomm in_buffer, IN_BUFFER_LENGTH+FIFO_BUFFER_HEADER_LENGTH 
.lcomm x_number, 2
.lcomm mode, 1


