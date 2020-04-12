#define BAUD_DIVIDER F_CPU/(16*BAUD_RATE)-1

; ----------------------------------------------------
; UART_INIT - initialize standard ATMEGA UART perepheria
; ----------------------------------------------------

.macro UART_INIT
	OUTI _SFR_IO_ADDR(UBRRH), hi8(BAUD_DIVIDER)
	OUTI _SFR_IO_ADDR(UBRRL), lo8(BAUD_DIVIDER)
	OUTI _SFR_IO_ADDR(UCSRA), 0
	OUTI _SFR_IO_ADDR(UCSRB), 1 << TXEN | 1 << RXEN | 1 << RXCIE
	OUTI _SFR_IO_ADDR(UCSRC), 1 << URSEL | 1 << UCSZ1 | 1 << UCSZ0 ; 8-N-1
.endm

.macro UART_INIT_TX
	OUTI _SFR_IO_ADDR(UBRRH), hi8(BAUD_DIVIDER)
	OUTI _SFR_IO_ADDR(UBRRL), lo8(BAUD_DIVIDER)
	OUTI _SFR_IO_ADDR(UCSRA), 0
	OUTI _SFR_IO_ADDR(UCSRB), 1 << TXEN 
	OUTI _SFR_IO_ADDR(UCSRC), 1 << URSEL | 1 << UCSZ1 | 1 << UCSZ0 ; 8-N-1
.endm

.macro UART_START_SEND
	; enable UDRIE to initiate sending
	sbi _SFR_IO_ADDR(UCSRB), UDRIE
.endm

.macro UART_STOP_SEND
	cbi _SFR_IO_ADDR(UCSRB), UDRIE
.endm


.macro UART_SEND_STR str
	LDZ str_prompt
	call uart_send_string
.endm

uart_send_string:
	lpm tmp1, Z+
	cpi tmp1, 0
	breq _uart_end_str_
	out _SFR_IO_ADDR(UDR), tmp1
_uart_wait_:
	sbis _SFR_IO_ADDR(UCSRA), UDRE 
	rjmp _uart_wait_
	rjmp uart_send_string
_uart_end_str_:
	ret
