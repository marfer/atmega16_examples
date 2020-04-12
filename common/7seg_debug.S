; digit position pins:
#define tmp5 r22
#define tmp6 r23

#define DIG1 4
#define DIG2 2
#define DIG3 1
#define DIG4 0
; segment out pin port:
#define DIG_SEG_P PORTA
; segment out pin direction register
#define DIG_SEG_D DDRA
; digit position pin direction register
#define DIG_CNTR_D DDRB
; digit position control port
#define DIG_CNTR_P PORTB

; --------------------
;#define DHI 1 << DIG1 | 1 << DIG2
;#define DLO 1 << DIG3 | 1 << DIG4

#define DHI 1
#define DLO 0
; --------------------
; digit codes
; port : seg
; 0 | A
; 1 | B
; 2 | C
; 3 | D
; 4 | E
; 5 | F
; 6 | G
; 7 | DOT
D_Lookup_Table:
	.byte 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71


;--------------------
; Y - delay cycles
D_Delay:
	clr YH
	ldi YL, 0xFF
	;ldi YH, 0xFF
BDD1:
	sbiw Y, 1
	brne BDD1
	ret

; -------------------
; Initialize
D_Init:
	OUTI _SFR_IO_ADDR(DIG_SEG_D), 0xFF
	OUTI _SFR_IO_ADDR(DIG_CNTR_D), 1 << DIG1 | 1 << DIG2 | 1 << DIG3 | 1 << DIG4
	ret
;--------------------
; Show digit
; XH - digit position (DIG1/DIG2/DIG3/DIG4)
; XL - digit code
D_Show_Digit:
	out _SFR_IO_ADDR(DIG_CNTR_P), XH
	out _SFR_IO_ADDR(DIG_SEG_P), XL
	call D_Delay
	clr r20
	out _SFR_IO_ADDR(DIG_CNTR_P), r20
	out _SFR_IO_ADDR(DIG_SEG_P), r20
	call D_Delay
	ret

.macro D_OUT_DIG code, pos
	mov XL, \code
	ldi XH, 1 << \pos
	call D_Show_Digit
.endm

;-------------------
; out byte
; XH - digit position (DHI/DLO)
; XL - byte
D_Show_Byte:
	push ZH
	push ZL
	push XL
	push XH

	; offset
	ldi tmp2, 0x0F
	ldi tmp3, 0x0F
	and tmp2, XL
	swap XL
	and tmp3, XL
	; sig code
	ldi	ZH, hi8(D_Lookup_Table)
	ldi ZL, lo8(D_Lookup_Table)
	add ZL, tmp2
	lpm tmp2, Z
	ldi ZL, lo8(D_Lookup_Table)
	add ZL, tmp3
	lpm tmp3, Z

	cpi XH, DHI
	breq DSBHI1

DSBLO1:
	D_OUT_DIG tmp3, DIG3
	D_OUT_DIG tmp2, DIG4
	rjmp DSBEND1

DSBHI1:
	D_OUT_DIG tmp3, DIG1
	D_OUT_DIG tmp2, DIG2

DSBEND1:
	pop XH
	pop XL
	pop ZL
	pop ZH
	ret

; ------------------------
; reg - IO register to show
; pos - DHI/DLO pair in 4 seg display
.macro D_SHOW_IO reg, pos
	in XL, _SFR_IO_ADDR(\reg)
	ldi XH, \pos
	call D_Show_Byte
.endm
; -------------------------
; show sram content
; DHI = addr
; DLO = content at (addr)
.macro D_SHOW_SRAM addr
	push ZH
	push ZL
	push XH
	push XL

	ldi	ZH, hi8(\addr)
	ldi ZL, lo8(\addr)
	ld XL, Z
	ldi XH, DLO
	call D_Show_Byte
	ldi XL, \addr
	ldi XH, DHI
	call D_Show_Byte

	pop XL
	pop XH
	pop ZL
	pop ZH
.endm
; -------------------------
; show flash content
; DHI = addr
; DLO = content at (addr)
.macro D_SHOW_FLASH addr
	push ZH
	push ZL
	push XH
	push XL

	ldi	ZH, hi8(\addr)
	ldi ZL, lo8(\addr)
	lpm XL, Z
	ldi XH, DLO
	call D_Show_Byte
	ldi XL, lo8(\addr)
	ldi XH, DHI
	call D_Show_Byte

	pop XL
	pop XH
	pop ZL
	pop ZH
.endm


; -------------------------
; show register value
; DLO = value of (reg)
.macro D_SHOW_REG reg, pos

	mov XL, \reg
	ldi XH, \pos
	call D_Show_Byte

.endm

; -------------------------
; show constant value
; value
; pos - DHI/DLO
.macro D_SHOW_VALUE value, pos
	push ZH
	push ZL
	push XH
	push XL

	ldi XL, \value
	ldi XH, \pos
	call D_Show_Byte

	pop XL
	pop XH
	pop ZL
	pop ZH
.endm

