; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------

#include "uart.S"
#include "fifo-buffer.S"
#include "utils.S"
#ifndef _OUT_BUFFER
#define _OUT_BUFFER uart_out_buffer
#endif

.macro UART_OUT_INT 
	FIFO_BUFFER_POP _UART_OUT_BUFFER ; tmp1 -> byte readed  tmp2 -> error if not zero
	tst tmp2
	brne _udrl1_
	out _SFR_IO_ADDR(UDR), tmp1
	reti
_udrl1_:
	; disable udr_empty interrupt - we are done, or error with buffer
	UART_STOP_SEND
.endm

.macro UART_OUT_INIT length
	UART_INIT_TX
	FIFO_BUFFER_INIT _UART_OUT_BUFFER, \length
.endm

.macro UART_OUT_STRING str
	FIFO_BUFFER_COPY_STR _UART_OUT_BUFFER, \str
	UART_START_SEND
.endm

.macro UART_OUT_BYTE byte
	ldi tmp1, \byte
	UART_OUT_TMP1
.endm

.macro UART_OUT_REG reg
	mov tmp1, \reg
	UART_OUT_TMP1
.endm

.macro UART_OUT_TMP1
	push tmp1
	call hex_to_ascii
	ldi tmp1, '0'
	FIFO_BUFFER_PUSH _UART_OUT_BUFFER, tmp1
	ldi tmp1, 'x'
	FIFO_BUFFER_PUSH _UART_OUT_BUFFER, tmp1
	FIFO_BUFFER_PUSH _UART_OUT_BUFFER, tmp2
	FIFO_BUFFER_PUSH _UART_OUT_BUFFER, tmp3
	pop tmp1
.endm

.macro UART_OUT_NL 
	push tmp1
	ldi tmp1, 0x0A
	FIFO_BUFFER_PUSH _UART_OUT_BUFFER tmp1
	ldi tmp1, 0x0D
	FIFO_BUFFER_PUSH _UART_OUT_BUFFER tmp1
	pop tmp1
.endm
