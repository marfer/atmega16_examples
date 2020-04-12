#define OUT_BUFFER_LENGTH 250
#define IN_BUFFER_LENGTH 250

#include <avr/io.h>
#include "macro.S"

.text
.org 0x0000

#include "vectors.S"
#include "uart.S"
#include "fifo-buffer.S"

;------------------------------------
; interrupts:
;------------------------------------
; RX
;------------------------------------
rx_ok:
	in tmp2, _SFR_IO_ADDR(UDR)
	cpi tmp2, 0x0D ; or 0x0A "Enter key press"
	breq rx_replay
	FIFO_BUFFER_PUSH in_buffer, tmp2
	reti

rx_replay:
	; initiate transmission
	FIFO_BUFFER_COPY_STR out_buffer str_entered_pre
	FIFO_BUFFER_COPY in_buffer out_buffer
	FIFO_BUFFER_COPY_STR out_buffer str_entered_post
	FIFO_BUFFER_COPY_STR out_buffer str_prompt
	UART_START_SEND
	reti

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
	UART_STOP_SEND
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

	FIFO_BUFFER_INIT out_buffer, OUT_BUFFER_LENGTH
	FIFO_BUFFER_INIT in_buffer, IN_BUFFER_LENGTH
	FIFO_BUFFER_COPY_STR out_buffer str_prompt

	UART_INIT
	UART_START_SEND
	sei

busy_loop:
	; do other serious job here
	nop
	nop
	rjmp busy_loop	

; Data
str_entered_pre:
	.asciz "You entered -> ["
str_entered_post:
	.asciz "]"
	.byte 0
str_prompt:
	.asciz "\r\nEnter any phrase...\r\n"

.section .bss
; -> struct for out buffer
.lcomm out_buffer, OUT_BUFFER_LENGTH+FIFO_BUFFER_HEADER_LENGTH ; buffer_end_pointer(2)+read_pointer(2)+write_pointer(2)+flags(1)
; -> struct for in buffer
.lcomm in_buffer, IN_BUFFER_LENGTH+FIFO_BUFFER_HEADER_LENGTH 

