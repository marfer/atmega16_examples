; ---------------------------------------------
; SPI Library for AVRMega16 and others
; ---------------------------------------------

; ---------------------------------------------
#define SPI_SS_PIN 	4
#define SPI_MOSI_PIN	5
#define SPI_MISO_PIN	6
#define SPI_SCK_PIN 	7
#define SPI_PORT_DDR DDRB
#define SPI_PORT PORTB
; ---------------------------------------------

#include <avr/io.h>

; ---------------------------------------------
; AVR ATMega16 Specific stuff here:
; ---------------------------------------------

#define SPI_MODE0 0x00
#define SPI_MODE1 0x04
#define SPI_MODE2 0x08
#define SPI_MODE3 0x0C
#define SPI_MODE_MASK 0x0C
#define SPI_MSB 0 << 5
#define SPI_LSB 1 << 5
#define SPI_SS_INVERTED 1

.macro fn name
.global \name
.type \name, @function
\name:
.endm

fn spi_int
	push ZH
	push ZL
	lds ZL, spi_int_addr
	lds ZH, spi_int_addr+1
	icall
	pop ZL
	pop ZH
	reti

spi_int_default:
	ret

.data 
.type spi_int_addr, @object
spi_int_addr:
	.word spi_int_default
	.lcomm __spi_buffer_counter, 1
	.lcomm __spi_buffer_data, 64
.text

; ---------------------------------------------
; Select SS Pin - just a wrapper macro for easy reading
; ss_inversed if set to 0, then active is high, else low
; ss_pin pin that is uses for slave select, default is SPI_SS_PIN
; ss_port port for slave select, default is SPI_PORT
; ss_ddr DDR port for slave select, default is SPI_PORT_DDR
; ---------------------------------------------
.macro SPI_SS_SELECT ss_inversed=0, ss_pin=SPI_SS_PIN, ss_port=SPI_PORT, ss_ddr=SPI_PORT_DDR
	sbi _SFR_IO_ADDR(\ss_ddr), \ss_pin	
	.if \ss_inversed == 0 
	sbi _SFR_IO_ADDR(\ss_port), \ss_pin
	.else
	cbi _SFR_IO_ADDR(\ss_port), \ss_pin
	.endif	
.endm

; ---------------------------------------------
; Release SS Pin - just a wrapper macro for easy reading
; ss_inversed if set to 0, then active is high, else low
; ss_pin pin that is uses for slave select, default is SPI_SS_PIN
; ss_port port for slave select, default is SPI_PORT
; ss_ddr DDR port for slave select, default is SPI_PORT_DDR
; ---------------------------------------------
.macro SPI_SS_RELEASE ss_inversed=0, ss_pin=SPI_SS_PIN, ss_port=SPI_PORT, ss_ddr=SPI_PORT_DDR
	; assume we already set pin as output:
	.if \ss_inversed == 0 
	cbi _SFR_IO_ADDR(\ss_port), \ss_pin
	.else
	sbi _SFR_IO_ADDR(\ss_port), \ss_pin
	.endif
.endm

; Initialize SPI
; freq - desired SCK speed, default to 1Mhz
; mode - CPOL and CPHA mode, default is CPOL=0 & CPHA=0
; dord - Data order, default is MSB first
; mstr - initialize in master mode, default true
; int  - set SPI interupt enabled, default false
.macro SPI_INIT freq=1000000, mode=SPI_MODE0, dord=SPI_MSB, mstr=1, int=0
	push r25
	.if \mstr == 1
	; MOSI output, MISO input, SCK output
	sbi _SFR_IO_ADDR(SPI_PORT_DDR), SPI_MOSI_PIN
	cbi _SFR_IO_ADDR(SPI_PORT_DDR), SPI_MISO_PIN
	sbi _SFR_IO_ADDR(SPI_PORT_DDR), SPI_SCK_PIN
	.else
	;MISO output, everything else configured by hardware as input
	sbi _SFR_IO_ADDR(SPI_PORT_DDR), SPI_MISO_PIN
	.endif

	.if \freq >= F_CPU/2
	; F_CPU/2 => SPI2X = 1, SPR1 = 0, SPR0 = 0
	ldi r25, 1 << SPI2X 
	out _SFR_IO_ADDR(SPSR), r25
	ldi r25, 0 << SPR0 | 0 << SPR1 | \mode | \dord | 1 << SPE | \mstr << MSTR | \int << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	.elseif \freq >= F_CPU/4
	; F_CPU/4 => SPI2X = 0, SPR1 = 0, SPR0 = 0
	ldi r25, \mode | \dord | 1 << SPE | \mstr << MSTR | \int << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	.elseif \freq >= F_CPU/8
	; F_CPU/8 => SPI2X = 1, SPR1 = 0, SPR0 = 1
	ldi r25, 1 << SPI2X 
	out _SFR_IO_ADDR(SPSR), r25
	ldi r25, 1 << SPR0 | 0 << SPR1 | \mode | \dord | 1 << SPE | \mstr << MSTR | \int << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	.elseif \freq >= F_CPU/16
	; F_CPU/16 => SPI2X = 0, SPR1 = 0, SPR0 = 1
	ldi r25, 1 << SPR0 | 0 << SPR1 | \mode | \dord | 1 << SPE | \mstr << MSTR | \int << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	.elseif \freq >= F_CPU/32
	; F_CPU/32 => SPI2X = 1, SPR1 = 1, SPR0 = 0
	ldi r25, 1 << SPI2X 
	out _SFR_IO_ADDR(SPSR), r25
	ldi r25, 0 << SPR0 | 1 << SPR1 | \mode | \dord | 1 << SPE | \mstr << MSTR | \int << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	.elseif \freq >= F_CPU/64
	; F_CPU/64 => SPI2X = 0, SPR1 = 1, SPR0 = 0
	ldi r25, 0 << SPR0 | 1 << SPR1 | \mode | \dord | 1 << SPE | \mstr << MSTR | \int << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	.else
	; F_CPU/128 => SPI2x = 0, SPR1 = 1, SPR0 = 1
	ldi r25, 1 << SPR0 | 1 << SPR1 | \mode | \dord | 1 << SPE | \mstr << MSTR | \int << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	.endif

	pop r25
.endm

; ---------------------------------------------
; Send/Receive Byte without using interupts
; IN:	 r25 -> byte to send
; OUT:	 r25 <- byte that come
; ---------------------------------------------
fn spi_send_byte_blocking
	out 	_SFR_IO_ADDR(SPDR), r25
	// Borrowed from Arduino SPI
    	/*
    	 * The following NOP introduces a small delay that can prevent the wait
    	 * loop form iterating when running at the maximum speed. This gives
    	 * about 10% more speed, even if it seems counter-intuitive. At lower
    	 * speeds it is unnoticed.
    	 */
	nop
__spi_wait_0__:
	; Wait for transmission complete
	sbis	_SFR_IO_ADDR(SPSR), SPIF
	rjmp	__spi_wait_0__
	in	r25, _SFR_IO_ADDR(SPDR)
	ret

	

; ---------------------------------------------
; Send count(r25:r24) bytes pointed by Y 
; r23:r22 -> count
; Y - byte pointer
; ---------------------------------------------
SPI_Master_Transmit_Bytes:
	lpm r25, Z+
	call spi_send_byte_blocking 
	;st Y+, r25
	subi r22, 1
	sbci r23, 0
	breq __spi_ret_0__
	rjmp SPI_Master_Transmit_Bytes
__spi_ret_0__:
	ret
	
.macro SPI_MASTER_SEND_BYTES label:req, count:req
	ldi ZH, hi8(\label)
	ldi ZL, lo8(\label)
	ldi r23, hi8(\count)
	ldi r22, lo8(\count)
	call SPI_Master_Transmit_Bytes
.endm

.macro SPI_MASTER_SEND_NO_INT byte:req
	ldi r25, \byte
	call spi_send_byte_blocking
.endm



SPI_Master_INT:
	sbi _SFR_IO_ADDR(PORTB), 3
	sbi _SFR_IO_ADDR(DDRB), 3
	ret


SPI_FIXED_SPDR:
	ldi r25, 0xAD
	out _SFR_IO_ADDR(SPDR), r25
	ret

.macro _SPI_CHANGE_INT addr
	ldi r25, pm_hi8(\addr)
	sts spi_int_addr+1, r25
	ldi r25, pm_lo8(\addr)
	sts spi_int_addr, r25
.endm
	

SPI_Master_Transmit_Int:
	_SPI_CHANGE_INT SPI_Master_INT
	sei

;	ldi YH, hi8(spi_int_addr)
;	ldi YL, lo8(spi_int_addr)
;	ld ZL, Y+
;	ld ZH, Y
	
	;lds ZL, spi_int_addr
	;lds ZH, spi_int_addr+1
	
	in r25, _SFR_IO_ADDR(SPCR)
	ori r25, 1 << SPIE
	out _SFR_IO_ADDR(SPCR), r25
	ldi r25, 0xDE
	out 	_SFR_IO_ADDR(SPDR), r25
	ret

	
.macro SPI_MASTER_STOP 
	push r25
	_SPI_CHANGE_INT spi_int_default
	ldi r25, 0 
	out _SFR_IO_ADDR(SPCR), r25
	pop r25
.endm


