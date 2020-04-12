; ---------------------------------------------
; 
; Useful macros used across all projects
;
; ---------------------------------------------
#define tmp1 r16
#define tmp2 r17
#define tmp3 r18
#define tmp4 r19

#define ZERO r0

; ---------------------------------------------
; INIT - initialize stack pointer and ZERO register
; ---------------------------------------------
.macro INIT
	clr	ZERO
	; Init stack pointer
	OUTI 	_SFR_IO_ADDR(SPH), hi8(RAMEND)
	OUTI 	_SFR_IO_ADDR(SPL), lo8(RAMEND)
.endm

; ---------------------------------------------
; OUTI - output immediate to IO register
; ---------------------------------------------
.macro OUTI reg, val
	ldi tmp1, \val
	out \reg, tmp1
.endm

; ---------------------------------------------
; LDY - load immediate word to Y register
; ---------------------------------------------
.macro LDY k
	ldi YH, hi8(\k)
	ldi YL, lo8(\k)
.endm 

; ---------------------------------------------
; LDX - load immediate word to X register
; ---------------------------------------------
.macro LDX k
	ldi XH, hi8(\k)
	ldi XL, lo8(\k)
.endm 

; ---------------------------------------------
; LDZ - load immediate word to Z register
; ---------------------------------------------
.macro LDZ k
	ldi ZH, hi8(\k)
	ldi ZL, lo8(\k)
.endm 
