; Encoder investigation
; ------------------------------

#include <avr/io.h>
.text
.org 0x0000
#include "vectors.S"
#include "macro.S"

#include "7seg_debug.S"

#define ONES r5
#define COUNTER r6
#define DISPLAY r7
init:
	INIT
	call D_Init
	ldi tmp1, 0xFF
	mov ONES, tmp1
	clr tmp1
	clr DISPLAY
	clr COUNTER
	clr tmp1
	clr tmp2
	;sts encoder_state, tmp1
	
;	init input on PC0 & PC1
;	OUTI _SFR_IO_ADDR(DDRC), 0xFC		; C0 & C1 - input mode
	OUTI _SFR_IO_ADDR(PORTC), 0x03		; pull up for C0 & C1
	
; ---------------------------------------------
; MAIN
; ---------------------------------------------
; encoder cycle:
; A: 1 0 0 1 1 0 ...
; B: 1 1 0 0 1 1 ...
; states:
; A B A'B' Forward Backward
; 0 0 0 0	0	0
; 0 0 0	1	0	1
; 0 0 1	0	1	0
; 0 0 1 1	~	~ not allowed
; 0 1 0	0	1	0
; 0 1 0 1	0	0	
; 0 1 1 0	~	~ not allowed
; 0 1 1 1	0	1
; 1 0 0 0	0	1
; 1 0 0 1	~	~ 
; 1 0 1 0	0	0
; 1 0 1 1	1	0
; 1 1 0 0	~	~
; 1 1 0 1	1	0
; 1 1 1 0	0	1
; 1 1 1 1	0	0
; DNF logical form:
; FORWARD: (!A & !B & A' & !B') | (!A & B & !A' & !B') | (A & !B & A' & B') | (A & B & !A' & B')
; ======== (!A & !B') & (!B & A' | B & !A') | (A & B') & (!B & A' | B & !A')
; ======== (!A & !B') & (B XOR A')  | (A & B') & (B XOR A')
; ======== (B XOR A') & ( !A & !B' | A & B')
; ======== (B XOR A') & !(A XOR B')
; BACKWARD: same logic as for forward: (A XOR B') & !(B XOR A')
main:
	;lds tmp1, encoder_state			; tmp1 = A'
	;lds tmp2, encoder_state+1		; tmp2 = B'
	; read data
	in tmp3, _SFR_IO_ADDR(PINC)
	andi tmp3, 0x03				; tmp2 = AB
	bst tmp3, 1
	clr tmp4
	bld tmp4, 0				; tmp4 = A
	;cbr tmp3, 1				; tmp3 = B
	andi tmp3, 0x01
	mov tmp5, tmp3				; tmp5 = B
	mov tmp6, tmp4				; tmp6 = A

	
	
; ======== (B XOR A') & !(A XOR B')
	eor tmp3, tmp1				; B XOR A'
	eor tmp4, tmp2				; A XOR B'
	eor tmp4, ONES				; !(A XOR B')
	and tmp3, tmp4
	brne _main_forward

; BACKWARD: (A XOR B') & !(B XOR A')
	mov tmp3, tmp5				; tmp3 = B
	mov tmp4, tmp6				; tmp4 = A
	eor tmp4, tmp2				; A XOR B'
	eor tmp3, tmp1				; B XOR A'
	eor tmp3, ONES				; !(A XOR B')
	and tmp3, tmp4
	brne _main_backward
	
	rjmp _show_counter	
		
_main_forward:
	inc COUNTER
	mov tmp1, COUNTER
	cpi tmp1, 0x04
	brne _show_counter
	clr COUNTER
	inc DISPLAY	
	rjmp _show_counter	
_main_backward:	
	inc COUNTER
	mov tmp1, COUNTER
	cpi tmp1, 0x04
	brne _show_counter
	clr COUNTER
	dec DISPLAY	

_show_counter:	
;	D_SHOW_REG tmp5, DLO
;	D_SHOW_REG tmp6, DHI
		
	D_SHOW_REG DISPLAY
	;sts encoder_state, tmp6 
	;sts encoder_state+1, tmp5 
	call D_Delay
	mov tmp1, tmp6
	mov tmp2, tmp5
	rjmp main




.section .bss
.lcomm encoder_state, 2
