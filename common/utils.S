; some utility methdos

; ------------------------------------
; byte -> ascii dec
; tmp1 <- byte
; Y <- FIFO BUFFER
; ------------------------------------
; From http://www.piclist.com/techref/language/ccpp/convertbase.htm
;         unsigned char d4, d3, d2, d1, d0, q;
;
;        if (n < 0) {
;            putchar( '-' );
;            n = -n;
;        }
;
;        d1 = (n>>4)  & 0xF;
;        d2 = (n>>8)  & 0xF;
;        d3 = (n>>12) & 0xF;
;
;        d0 = 6*(d3 + d2 + d1) + (n & 0xF);
;        q = (d0 * 0xCD) >> 11;
;        d0 = d0 - 10*q;
;
;        d1 = q + 9*d3 + 5*d2 + d1;
;        q = (d1 * 0xCD) >> 11;
;        d1 = d1 - 10*q;
;
;        d2 = q + 2*d2; 
;        q = (d2 * 0x1A) >> 8;
;        d2 = d2 - 10*q;
;
;        d3 = q + 4*d3;
;        d4 = (d3 * 0x1A) >> 8;
;        d3 = d3 - 10*d4;
;
;        putchar( d4 + '0' );
;        putchar( d3 + '0' );
;        putchar( d2 + '0' );
;        putchar( d1 + '0' );
;        putchar( d0 + '0' );
#define d0 r18
#define d1 r19
#define d2 r20
#define d3 r21
#define d4 r22
; X <- word to convert
word_to_ascii_int:
	push d0
	push d1
	push d2
	push d3
	push d4
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5

	
;        d1 = (n>>4)  & 0xF;
	mov d1, XL
	swap d1
	andi d1, 0xF
;        d2 = (n>>8)  & 0xF;
	mov d2, XH
	andi d2, 0xF
;        d3 = (n>>12) & 0xF;
	mov d3, XH
	swap d3
	andi d3, 0xF
;        d0 = 6*(d3 + d2 + d1) + (n & 0xF);
	mov d0, d1
	add d0, d2
	add d0, d3
	ldi d4, 6
	mul d0, d4
	clr d4
	mov d0, XL
	andi d0, 0xF
	add r0, d0
	adc r1, d4
	push r0
	push r1
;        q = (d0 * 0xCD) >> 11;
	ldi d4, 0xCD
	clr r2
	mov r5, r1
	mov r4, r0
	mul r4, d4 ; AL*0xCD
	mov r4, r0
	mov r3, r1
	mul r5, d4 ; AH*0xCD
	add r3, r0
	adc r2, r1
; >> 11
	lsr r2
	ror r3	
	lsr r2
	ror r3	
	lsr r2
	ror r3	
	lsr r2
	ror r3	
	lsr r2
	ror r3	
;        d0 = d0 - 10*q;
	mov r4, r2
	mov r5, r3
	lsl r3
	rol r2	;x2
	lsl r3
	rol r2 	;x4
	add r3, r5
	adc r2, r4	;x5
	lsl r3
	rol r2		;x10
	pop r4		; r4 <- d0H
	pop r5		; r5 <- d0L
	sub r5, r3
	sbc r4, r2
	
;        d1 = q + 9*d3 + 5*d2 + d1;
	




#define    a0 r16
#define    a1 r17
#define    a2 r18
#define    a3 r19
#define    a4 r20
;************************************************************************
;*                                                                      *
;*                      binary to ASCII decimal conversion              *
;*                                                                      *
;************************************************************************
;input: a1, a0 = 16 bit value 0 ... 65535
;output: a4, a3, a2, a1, a0 = digits
;cycle: 27 .. 183
;bytes: 42
;
binbcd:
        ldi     a4, -1 + '0'
_bib1:  inc     a4
        subi    a0, lo8(10000)
        sbci    a1, hi8(10000)
        brcc    _bib1

        ldi     a3, 10 + '0'
_bib2:  dec     a3
        subi    a0, lo8(-1000)
        sbci    a1, hi8(-1000)
        brcs    _bib2

        ldi     a2, -1 + '0'
_bib3:  inc     a2
        subi    a0, lo8(100)
        sbci    a1, hi8(100)
        brcc    _bib3

        ldi     a1, 10 + '0'
_bib4:  dec     a1
        subi    a0, -10
        brcs    _bib4

        subi    a0, -'0'
        ret
;------------------------------------------------------------------------


; -----------------------------------------------------------------------
; hexToAscii
; -----------------------------------------------------------------------
; tmp1 - hex
; tmp2:tmp3 - ascii symbols for given hex
hex_to_ascii:
	push	ZH
	push	ZL
	push	tmp1
	swap 	tmp1
	andi 	tmp1, 0x0F
	LDZ	table_hex_to_ascii
	add	ZL, tmp1
	adc	ZH, 0
	lpm	tmp1, Z
	mov	tmp2, tmp1
	pop	tmp1
	andi	tmp1, 0x0F
	LDZ	table_hex_to_ascii
	add	ZL, tmp1
	adc	ZH, 0
	lpm	tmp1, Z
	mov	tmp3, tmp1
	pop	ZL
	pop	ZH
	ret
table_hex_to_ascii:
	.byte	0x30, 0x31, 0x32, 0x33
	.byte	0x34, 0x35, 0x36, 0x37
	.byte	0x38, 0x39, 0x41, 0x42
	.byte	0x43, 0x44, 0x45, 0x46

; ------------------------------------------------------------------------
; DELAY 
; ------------------------------------------------------------------------
.macro DELAY ms
	push 	tmp1
	push 	tmp2
	push 	tmp3
	ldi	tmp1, (\ms*F_CPU/1000 >> 16) & 0xFF
	ldi	tmp2, (\ms*F_CPU/1000 >> 8) & 0xFF
	ldi	tmp3, (\ms*F_CPU/1000) & 0xFF
	call	utils_delay
	pop	tmp3
	pop 	tmp2
	pop	tmp1
.endm
utils_delay:
	subi 	tmp1, 1
	sbci 	tmp2, 0
	sbci 	tmp3, 0
	
	cpi	tmp3, 0
	brne	utils_delay
	cpi	tmp2, 0
	brne	utils_delay
	cpi	tmp1, 0
	brne	utils_delay
	ret
