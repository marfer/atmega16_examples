; LCD initialization
; ------------------------------

#define BTN_PORT PORTD
#define BTN_PIN PIND
#define BTN_DDR DDRD
#define COL1 PD2
#define COL2 PD1
#define COL3 PD0
#define ROW1 PD3
#define ROW2 PD4
#define ROW3 PD5
#define ROW4 PD6
#define IO_IGN PD7

#define BTN1_MSK 0x0C
#define BTN2_MSK 0x0A
#define BTN3_MSK 0x09

#define BTN4_MSK 0x14
#define BTN5_MSK 0x12
#define BTN6_MSK 0x11

#define BTN7_MSK 0x24
#define BTN8_MSK 0x22
#define BTN9_MSK 0x21

#define BTN10_MSK 0x44
#define BTN11_MSK 0x42
#define BTN12_MSK 0x41

#include <avr/io.h>
#include "macro.S"
#include "lcd4_macro.S"

.text
.org 0
#include "vectors.S"
#include "lcd4.S"
#include "utils.S"

int0:
	cli
	LCDCLR
	WR_DATA 'I'
	WR_DATA 'N'
	WR_DATA 'T'
	WR_DATA '0'
	sbi _SFR_IO_ADDR(PORTB), 3
	sei
	reti

int1:
	cli
	LCDCLR
	WR_DATA 'I'
	WR_DATA 'N'
	WR_DATA 'T'
	WR_DATA '1'
	cbi _SFR_IO_ADDR(PORTB), 3
	sei
	reti

init:
	INIT
	; init buttons
	;sbi _SFR_IO_ADDR(PORTD), PD2	; pull-up input for int1 and int0
	;sbi _SFR_IO_ADDR(PORTD), PD3
	;cbi _SFR_IO_ADDR(DDRD), PD2
	;cbi _SFR_IO_ADDR(DDRD), PD3	
	;ldi tmp1, 1 << ISC11 | 0 << ISC10 | 1 << ISC01 | 0 << ISC00
	;out _SFR_IO_ADDR(MCUCR), tmp1
	;ldi tmp1, 1 << INT0 | 1 << INT1
	;out _SFR_IO_ADDR(GICR), tmp1
	; init led0
	cbi _SFR_IO_ADDR(PORTB), 3
	sbi _SFR_IO_ADDR(DDRB), 3
	; wait 

	INIT_LCD		
	LCDCLR
	
	WR_DATA 'P'
	WR_DATA 'r'
	WR_DATA 'e'
	WR_DATA 's'
	WR_DATA 's'
	WR_DATA ' '
	WR_DATA 'b'
	WR_DATA 'u'
	WR_DATA 't'
	WR_DATA 't'
	WR_DATA 'o'
	WR_DATA 'n'
	;LCD_COORD 0, 1	

	
; ---------------------------------	
; MAIN LOOP
; --------------------------------
main:
	call survey_button_matrix
	DELAY 100
	rjmp main

survey_button_matrix:
	; pull-up rows, col to 0, read rows
	ldi	tmp1, 1 << ROW1 | 1 << ROW2 | 1 << ROW3 | 1 << ROW4 
	out 	_SFR_IO_ADDR(BTN_PORT), tmp1
	ldi 	tmp2, 0xFF 
	eor 	tmp1, tmp2
	out 	_SFR_IO_ADDR(BTN_DDR), tmp1
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	in 	tmp1, _SFR_IO_ADDR(BTN_PIN)
	andi	tmp1, 1 << ROW1 | 1 << ROW2 | 1 << ROW3 | 1 << ROW4
	push 	tmp1
	; pull-up cols, rows to 0, read columns
	ldi 	tmp1, 1 << COL1 | 1 << COL2 | 1 << COL3
	out 	_SFR_IO_ADDR(BTN_PORT), tmp1
	ldi 	tmp2, 0xFF
	eor	tmp1, tmp2
	out	_SFR_IO_ADDR(BTN_DDR), tmp1
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	in 	tmp1, _SFR_IO_ADDR(BTN_PIN)
	andi	tmp1, 1 << COL1 | 1 << COL2 | 1 << COL3
	pop 	tmp2
	or 	tmp1, tmp2
	mov	tmp3, tmp1
;	rcall	out_tmp1

	out	_SFR_IO_ADDR(BTN_DDR), 0

	subi	tmp1, 0x7F
	brne	_n1_
	ret
_n1_:
	LCDCLR
	; mask buttons:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN1_MSK
	brne	_n2_
	WR_DATA '1'
_n2_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN2_MSK
	brne	_n3_
	WR_DATA '2'
	
_n3_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN3_MSK
	brne	_n4_
	WR_DATA '3'
_n4_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN4_MSK
	brne	_n5_
	WR_DATA '4'
_n5_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN5_MSK
	brne	_n6_
	WR_DATA '5'
_n6_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN6_MSK
	brne	_n7_
	WR_DATA '6'
_n7_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN7_MSK
	brne	_n8_
	WR_DATA '7'
_n8_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN8_MSK
	brne	_n9_
	WR_DATA '8'
_n9_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN9_MSK
	brne	_n10_
	WR_DATA '9'
_n10_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN10_MSK
	brne	_n11_
	WR_DATA 'A'
_n11_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN11_MSK
	brne	_n12_
	WR_DATA 'B'
_n12_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN12_MSK
	brne	_r_
	WR_DATA 'C'
_r_:
	ret	


.section .bss
.lcomm BreakLoop, 2
