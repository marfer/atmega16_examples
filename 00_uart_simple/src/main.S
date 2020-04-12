#define BAUD_DIVIDER F_CPU/(16*BAUD_RATE)-1

#include <avr/io.h>
#include "macro.S"

.text
.org 0x0000

#include "vectors.S"

init:
	; set stack pointer, clean and init
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
main:
	LDZ str_prompt
	call out_str
read:
	; wait for receive flag
	sbis _SFR_IO_ADDR(UCSRA), RXC
	rjmp read
	in tmp2, _SFR_IO_ADDR(UDR)
	
	; output character back:
	ldi ZL, lo8(str_entered)
	ldi ZH, hi8(str_entered)	
	call out_str
	out _SFR_IO_ADDR(UDR), tmp2 ;we don't wait here, since there are enought time to send
	; wait some time before sending one more prompt
	ldi tmp1, 0xFF
	ldi tmp2, 0xFF
busy_loop:
	subi tmp1, 0x01
	sbci tmp2, 0x00
	brne busy_loop
	cpi tmp1, 0
	breq main	
	rjmp busy_loop	
		
; ------------------------
; output string pointed by Z index to USART
; string should be null terminated
; Z <- pointer to string
out_str:
	lpm tmp1, Z+
	cpi tmp1, 0
	breq end_str
	out _SFR_IO_ADDR(UDR), tmp1
wait:
	sbis _SFR_IO_ADDR(UCSRA), UDRE 
	rjmp wait
	rjmp out_str
end_str:
	ret

; Data
str_entered:
	.asciz "You entered -> "
str_prompt:
	.asciz "\r\nEnter any character...\r\n"

