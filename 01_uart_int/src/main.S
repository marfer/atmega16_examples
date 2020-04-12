#define BAUD_DIVIDER F_CPU/(16*BAUD_RATE)-1

#include <avr/io.h>
#include "macro.S"

.text
.org 0x0000

#include "vectors.S"

rx_ok:
	in tmp2, _SFR_IO_ADDR(UDR)
	
	ldi ZL, lo8(str_entered)
	ldi ZH, hi8(str_entered)
	; initiate transmission
	cbi _SFR_IO_ADDR(UCSRB), RXCIE 
	sbi _SFR_IO_ADDR(UCSRB), UDRIE
	reti

; send next byte until we get 0x00
udr_empty:
	lpm tmp1, Z+
	tst tmp1
	breq udrl0
	out _SFR_IO_ADDR(UDR), tmp1
	reti
udrl0:
	tst tmp2	; test if we have something in tmp2, if so send it also
	breq udrl1	; we done, wait for incoming byte 
	out _SFR_IO_ADDR(UDR), tmp2
	clr tmp2
	ldi ZL, lo8(str_prompt)
	ldi ZH, hi8(str_prompt)
	reti
udrl1:
	; disable udrie interrupts - we are done
	cbi _SFR_IO_ADDR(UCSRB), UDRIE
	sbi _SFR_IO_ADDR(UCSRB), RXCIE
	reti

tx_ok:
	reti

init:
	INIT
	; init usart 	
	; baud rate:
	OUTI _SFR_IO_ADDR(UBRRH), hi8(BAUD_DIVIDER)
	OUTI _SFR_IO_ADDR(UBRRL), lo8(BAUD_DIVIDER)
	;OUTI _SFR_IO_ADDR(UBRRL), 0x08
	; transmit enable
	; UCSRA :
	;  RXC: Receive complete
	;  TXC: Transmit complete
	; UDRE: Data register empty (UDR)
	; FE  : Frame error
	;  DOR: Data OverRun
	; PE  : Parity error
	; U2X : Double speed
	; MPCM: Multy processor communication
	OUTI _SFR_IO_ADDR(UCSRA), 0

	; UCSRB:
	; RXCIE: RX complete interrupt enable
	; TXCIE: TX complete interrupt enable
	; UDRIE: Data register empty interrupt enable
	; RXEN : Receive enable
	; TXEN : Transmit enable
	; UCSZ2: Frame size (2 bit)
	; RX8  : in case frame is 9 bit this is 9 bit in frame
	; TX8  : Same, but for transmit
	OUTI _SFR_IO_ADDR(UCSRB), 1 << TXEN | 1 << RXEN
	
	; UCSRC:
	; URSEL: 1 for write to UCSRC, 0 for UBRRH
	; UMSEL: 0 - Async mode, 1 - Sync
	; UPM1 :
	; UPM0 : Parity mode
	; USBS : Stop bit select
	; UCSZ1:
	; UCSZ0: Frame size (also in UCSRB -> UCSZ2)
	; UCPOL: Clock polarity (Sync mode only)
	OUTI _SFR_IO_ADDR(UCSRC), 1 << URSEL | 1 << UCSZ1 | 1 << UCSZ0 ; 8-N-1
	
	; 
	ldi ZL, lo8(str_prompt)
	ldi ZH, hi8(str_prompt)
	; enable UDRIE to initiate sending
	sbi _SFR_IO_ADDR(UCSRB), UDRIE
	sei
busy_loop:
	nop
	rjmp busy_loop	
		
; ------------------------
; output string pointed by Z index to USART
; string should be null terminated
; Z <- pointer to string

; Data
str_entered:
	.asciz "You entered -> "
str_prompt:
	.asciz "\r\nEnter any character...\r\n"

