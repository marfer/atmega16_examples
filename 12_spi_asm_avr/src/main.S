; ---------------------------------------------
; SPI Library for AVRMega16 and others
; ---------------------------------------------

; ---------------------------------------------
#define DD_MOSI	5
#define DD_SCK 	7
#define DD_SS 	4
#define DDR_SPI DDRB
; ---------------------------------------------

#include <avr/io.h>
#include "macro.S"

.text
.org 0
#include "vectors.S"
#include "spi.S"

.global init
.type init, @function
init:
	INIT
	
	SPI_INIT 4000000 SPI_MODE0 SPI_MSB 0 1
	_SPI_CHANGE_INT SPI_FIXED_SPDR
	sei
	;SPI_SS_SELECT SPI_SS_INVERTED
		
	;call SPI_Master_Transmit_Int 
;	SPI_MASTER_SEND_BYTES to_transmit 5
	;SPI_MASTER_STOP
	;SPI_SS_RELEASE SPI_SS_INVERTED
	; init uart	
wait:
	nop
	rjmp wait


to_transmit:
	.byte 0xDE, 0xAD, 0x00, 0xBE, 0xAF 
