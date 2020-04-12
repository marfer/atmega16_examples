; Soft implementation of I2C Master module
; master -> slave comunication with EEPROM
; ------------------------------
#define OUT_BUFFER_LENGTH 250
#define DEVICE_ADDR 0xAE
#define I2C_READ 0x01
#define I2C_WRITE 0x00

; ------------------------------

#include <avr/io.h>
#include "macro.S"
.text
.org 0
#include "vectors.S"
#include "i2c_master.S"

init:
	INIT	
	rcall i2c_minit
	rcall i2c_mstart
	ldi tmp1, 0xAE
	rcall i2c_msend
	ldi tmp1, 0x00
	rcall i2c_msend
	ldi tmp1, 0x02
	rcall i2c_msend
	rcall i2c_mrestart

	ldi tmp1, 0xAF
	rcall i2c_msend
	; set ack responce
	sbr I2C_STATUS, 1 << ACK_NACK
	rcall i2c_mread
	cpi I2C_TEMP, 0xDE
	breq _match_1_
_next_m_:
	cbr I2C_STATUS, 1 << ACK_NACK
	rcall i2c_mread
	cpi I2C_TEMP, 0xAD
	breq _match_2_
	rjmp _anyway_
_match_1_:
	sbi _SFR_IO_ADDR(DDRB), PB3
	sbi _SFR_IO_ADDR(PORTB), PB3
	rjmp _next_m_
_match_2_:
	sbi _SFR_IO_ADDR(DDRD), PD4
	sbi _SFR_IO_ADDR(PORTD), PD4
_anyway_:	
	rcall i2c_mstop
; ---------------------------------	
; MAIN LOOP
; --------------------------------
main:
	nop
	rjmp main


