; LCD initialization
; ------------------------------

#define BAUD_DIVIDER F_CPU/(16*BAUD_RATE)-1
; ------------------------------
#define DD_MOSI	5
#define DD_SCK 	7
#define DD_SS 	4
#define DDR_SPI DDRB
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


.macro LCD_STR str
	ldi	ZH, hi8(\str)
	ldi	ZL, lo8(\str)
	call lcd_str
.endm


.macro SD_SEND b1, b2, b3, b4, b5, b6
	push	tmp1
	ldi 	ZH, hi8(spi_out_buffer)
	ldi	ZL, lo8(spi_out_buffer)
	ldi	tmp1, \b1
	st	Z+, tmp1
	ldi	tmp1, \b2
	st	Z+, tmp1
	ldi	tmp1, \b3
	st	Z+, tmp1
	ldi	tmp1, \b4
	st	Z+, tmp1
	ldi	tmp1, \b5
	st	Z+, tmp1
	ldi	tmp1, \b6
	st	Z+, tmp1
	call	sd_send_cmd
	pop	tmp1
.endm

.macro LCD_SHOW_MEM mem, count
	push	tmp1
	push	tmp2
	push	tmp3
	
	ldi	tmp3, \count
	ldi	YH, hi8(\mem)
	ldi	YL, lo8(\mem)
	call 	lcd_show_mem
	
	pop	tmp3
	pop	tmp2
	pop	tmp1 
.endm

.text
.org 0
#include "vectors.S"
#include "lcd4.S"


init:
	INIT
	; init led0
	cbi _SFR_IO_ADDR(PORTB), 3
	sbi _SFR_IO_ADDR(DDRB), 3
	; init uart	
	OUTI 	_SFR_IO_ADDR(UBRRH), hi8(BAUD_DIVIDER)
	OUTI 	_SFR_IO_ADDR(UBRRL), lo8(BAUD_DIVIDER)
	OUTI 	_SFR_IO_ADDR(UCSRC), 1 << URSEL | 1 << UCSZ1 | 1 << UCSZ0 ; 8-N-1
	OUTI 	_SFR_IO_ADDR(UCSRA), 0
	OUTI 	_SFR_IO_ADDR(UCSRB), 1 << TXEN
	

	INIT_LCD		
	LCDCLR
	
	;;LCD_STR str_init_l2
	call SPI_MasterInit
	SD_SEND 0x40, 0x00, 0x00, 0x00, 0x00, 0x95
	SD_SEND 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	; CMD8
	SD_SEND 0x48, 0x00, 0x00, 0x01, 0xAA, 0x87
	SD_SEND 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
_w_sd_init:
	; CMD55: application command follows, should returen 0x01
	SD_SEND 0x77, 0x00, 0x00, 0x00, 0x00, 0x64
	;;LCD_SHOW_MEM spi_out_buffer, 6
	SD_SEND 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	; ACMD41: initialize the card, should return 0x00 when ready
	SD_SEND 0x69, 0x40, 0x00, 0x00, 0x00, 0x00
	SD_SEND 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	LCD_COORD 0, 1
	LCD_SHOW_MEM spi_in_buffer, 6
	ldi YH, hi8(spi_in_buffer)
	ldi YL, lo8(spi_in_buffer)
	ldd tmp1, Y+1
	;call lcd_out_hex
	cpi tmp1, 0x01
	brne 	_w_ne
	jmp	_w_sd_init
_w_ne:
	brlo	_w_init
	LCDCLR
	LCD_STR	str_error
	rjmp	main ; error??
_w_init:
	LCDCLR
	LCD_STR str_ready
	
	
	
; ---------------------------------	
; MAIN LOOP
; --------------------------------
main:
	;call survey_button_matrix
	ldi tmp1, 0xFF
	ldi tmp2, 0xFF
_busy_wait_:
	dec 	tmp1
	call	m_wait
	brne	_busy_wait_
	ldi	tmp1, 0xFF
	dec 	tmp2
	breq 	main
	rjmp 	_busy_wait_

survey_button_matrix:
	; pull-up rows, col to 0, read rows
	ldi	tmp1, 1 << ROW1 | 1 << ROW2 | 1 << ROW3 | 1 << ROW4 
	out 	_SFR_IO_ADDR(BTN_PORT), tmp1
	ldi 	tmp2, 0xFF 
	eor 	tmp1, tmp2
	out 	_SFR_IO_ADDR(BTN_DDR), tmp1
	call	m_wait
	in 	tmp1, _SFR_IO_ADDR(BTN_PIN)
	andi	tmp1, 1 << ROW1 | 1 << ROW2 | 1 << ROW3 | 1 << ROW4
	push 	tmp1
	; pull-up cols, rows to 0, read columns
	ldi 	tmp1, 1 << COL1 | 1 << COL2 | 1 << COL3
	out 	_SFR_IO_ADDR(BTN_PORT), tmp1
	ldi 	tmp2, 0xFF
	eor	tmp1, tmp2
	out	_SFR_IO_ADDR(BTN_DDR), tmp1
	call	m_wait
	in 	tmp1, _SFR_IO_ADDR(BTN_PIN)
	andi	tmp1, 1 << COL1 | 1 << COL2 | 1 << COL3
	pop 	tmp2
	or 	tmp1, tmp2
	mov	tmp3, tmp1

	out	_SFR_IO_ADDR(BTN_DDR), 0

	
	subi	tmp1, 0x7F
	brne	_n1_
	ret
_n1_:
;	mov tmp1, tmp3
;	rcall	out_tmp1
;	LCDCLR
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
	;WR_DATA 'A'
	SHIFT	SCR_R
_n11_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN11_MSK
	brne	_n12_
	WR_DATA 'B'
_n12_:
	mov 	tmp1, tmp3
	andi 	tmp1, BTN12_MSK
	brne	_r_
	;WR_DATA 'C'
	SHIFT	SCR_L
_r_:
	ret	

;out_tmp1:
	; init uart
;	out 	_SFR_IO_ADDR(UDR), tmp1
;wait:
;	sbis _SFR_IO_ADDR(UCSRA), UDRE 
;	rjmp wait
;	ret

; ----------------------------------------------------------------
; ----------------------------------------------------------------
; output string from flash memory
; ----------------------------------------------------------------
; ----------------------------------------------------------------
lcd_str:
	lpm	tmp2, Z+
	tst	tmp2
	breq	_lcd_str_r_
	mov	tmp1, tmp2
;	rcall 	out_tmp1
	rcall	lcd_send_data
	rjmp	lcd_str
_lcd_str_r_:
;	ldi tmp1, 0x0A
;	call out_tmp1
;	ldi tmp1, 0x0D
;	call out_tmp1
	ret
; ----------------------------------------------------------------
m_wait:
	ldi	tmp1, 0xff
_m_w_:
	dec 	tmp1
	breq 	_m_r_
	rjmp 	_m_w_
_m_r_:
	ret

SPI_MasterInit:
	; Set MOSI and SCK output, all others input
	sbi	_SFR_IO_ADDR(DDR_SPI), DD_MOSI
	sbi	_SFR_IO_ADDR(DDR_SPI), DD_SCK
	sbi	_SFR_IO_ADDR(DDR_SPI), DD_SS
	; Enable SPI, Master, set clock rate fck/16
	ldi	tmp1, 1<<SPE | 1<<MSTR | 1<<SPR0
	out	_SFR_IO_ADDR(SPCR), tmp1
	ret

SPI_MasterTransmit:
	; Start transmission of data (r16)
	out 	_SFR_IO_ADDR(SPDR), tmp1
Wait_Transmit:
	; Wait for transmission complete
	sbis	_SFR_IO_ADDR(SPSR),SPIF
	rjmp	Wait_Transmit
	in	tmp1, _SFR_IO_ADDR(SPDR)
	ret

;SPI_MasterRead:
	

SPI_End:
	cbi	_SFR_IO_ADDR(DDR_SPI), DD_SS
	ret

;-----------------------------------------------
; HEX TO ASCII
;-----------------------------------------------
;I think, this was the smallest (only 10 words). 

;input: R16 = 8 bit value 0 ... 255 
;output: R18, R17, R16 = digits 
;bytes: 20
;Hex2Ascii:
;	ldi 	r18,-1+'0'
;_bcd1:
;	inc 	r18
;	subi 	r16,100 
;	brcc	_bcd1 
;	ldi	r17,10+'0' 
;_bcd2:
;	dec 	r17 
;	subi 	r16,-10 
;	brcs	_bcd2 
;	sbci	r16,-'0' 
;	ret

; tmp1 - byte to output
lcd_out_hex:
	push	tmp2
	push	tmp1
	push	tmp1
	swap 	tmp1
	andi 	tmp1, 0x0F
	ldi	ZH, hi8(lcd_out_table)
	ldi 	ZL, lo8(lcd_out_table)
	add	ZL, tmp1
	adc	ZH, 0
	lpm	tmp1, Z
	mov	tmp2, tmp1
	rcall	lcd_send_data
	pop	tmp1
	andi	tmp1, 0x0F
	ldi	ZH, hi8(lcd_out_table)
	ldi 	ZL, lo8(lcd_out_table)
	add	ZL, tmp1
	adc	ZH, 0
	lpm	tmp1, Z
	mov	tmp2, tmp1
	rcall	lcd_send_data
	pop	tmp1
	pop	tmp2
	ret
	
lcd_out_table:
	.byte	0x30, 0x31, 0x32, 0x33
	.byte	0x34, 0x35, 0x36, 0x37
	.byte	0x38, 0x39, 0x41, 0x42
	.byte	0x43, 0x44, 0x45, 0x46

lcd_show_mem:
	ld	tmp1, Y+
	call	lcd_out_hex
	dec 	tmp3
	brne 	lcd_show_mem
	ret

sd_send_cmd:
	ldi 	ZH, hi8(spi_out_buffer)
	ldi	ZL, lo8(spi_out_buffer)
	ldi	YH, hi8(spi_in_buffer)
	ldi	YL, lo8(spi_in_buffer)
	ldi	tmp3, 0x06
_cmd_byte_:
	ld	tmp1, Z+
	call	SPI_MasterTransmit
	st	Y+, tmp1
	dec	tmp3
	brne	_cmd_byte_
	ret
		
	
	
	

 
str_init:
	.asciz "Initialization"
str_init_l2:
	.asciz "96%"
str_ready:
	.asciz "Ready...."
str_error:
	.asciz "Error!"

.section .bss
.lcomm BreakLoop, 2
.lcomm	spi_out_buffer, 6
.lcomm	spi_in_buffer, 6
