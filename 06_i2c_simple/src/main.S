; Simple I2C transiver
; master -> slave comunication with EEPROM
; without error handling and i2c interupts 
; based on AVR TWI module
; ------------------------------
#define OUT_BUFFER_LENGTH 400
#define DEVICE_ADDR 0xAE
#define I2C_READ 0x01
#define I2C_WRITE 0x00

#define F_SCL 400000
#define TWPS_V 1
#define TWBR_V (F_CPU-16*F_SCL)/(2*(4^TWPS_V)*F_SCL)
#if TWBR_V > 255
  #error 'Please change TWPS prescaler value to fit TWBR in byte'
#endif
; ------------------------------

#include <avr/io.h>
#include "macro.S"

#define _UART_OUT_BUFFER out_buffer

.text
.org 0
#include "vectors.S"
#include "uart-buffer.S"

ud_ok:
	UART_OUT_INT 
	reti

twi_int:
	reti

init:
	INIT
	UART_OUT_INIT OUT_BUFFER_LENGTH
	OUTI _SFR_IO_ADDR(TWBR), TWBR_V 

	; INIT TWI
	sei
	UART_OUT_STRING str_start
	; Send start condition
	; clear int flag, set start condition, enable twi, disable twi interupt
	UART_OUT_STRING str_init_i2c

_read_:
	
	UART_OUT_STRING str_read_i2c
	rcall i2c_start
	; send device address
	UART_OUT_STRING str_i2c_read_send_addr
	UART_OUT_BYTE DEVICE_ADDR | I2C_WRITE ; 1010 1110
	UART_OUT_NL
	ldi tmp1, DEVICE_ADDR | I2C_WRITE ; 1010 1110
	rcall i2c_send
	; send memory address H
	UART_OUT_STRING str_send_addr
	ldi tmp1, 0x00
	UART_OUT_TMP1
	UART_OUT_NL
	;ldi tmp1, 0x00
	rcall i2c_send
	; send memory address L
	UART_OUT_STRING str_send_addr
	ldi tmp1, 0x02 
	UART_OUT_TMP1
	UART_OUT_NL
	;ldi tmp1, 0x02 
	rcall i2c_send
	; restart in read mode
	UART_OUT_STRING str_restart_i2c
	rcall i2c_start	
	; send device address
	UART_OUT_STRING str_i2c_read_send_addr
	ldi 	tmp1, DEVICE_ADDR | I2C_READ
	UART_OUT_TMP1
	UART_OUT_NL
	;ldi 	tmp1, DEVICE_ADDR | I2C_READ
	rcall i2c_send
	; Read byte with ACK responce
	UART_OUT_STRING str_read_with_ack
	rcall i2c_read_ack
	in tmp1, _SFR_IO_ADDR(TWDR)
	UART_OUT_TMP1
	UART_OUT_NL
	; read byte with NACK responce
	UART_OUT_STRING str_read_with_nack
	rcall i2c_read_nack
	in tmp1, _SFR_IO_ADDR(TWDR)
	UART_OUT_TMP1
	UART_OUT_NL
	; stop uart
	UART_OUT_STRING str_i2c_stop
	rcall i2c_stop
	
	rjmp main
_write:
	rcall i2c_start
	ldi tmp1, DEVICE_ADDR | I2C_WRITE ; 1010 1110
	rcall i2c_send	; send device address

	ldi tmp1, 0x00 ; second address
	rcall i2c_send
	ldi tmp1, 0x02 ; second address
	rcall i2c_send
	ldi tmp1, 0xDE
	rcall i2c_send
	ldi tmp1, 0xAD
	rcall i2c_send
	rcall i2c_stop
	

; ---------------------------------	
; MAIN LOOP
; --------------------------------
main:
	nop
	rjmp main



i2c_start:
	OUTI _SFR_IO_ADDR(TWCR), 1 << TWINT | 1 << TWSTA | 1 << TWEN | 0 << TWIE
_i2c_wait1:
	in tmp1, _SFR_IO_ADDR(TWCR)
	ANDI tmp1, 1 << TWINT
	breq _i2c_wait1
	ret
		
i2c_send:
	out _SFR_IO_ADDR(TWDR), tmp1
	OUTI _SFR_IO_ADDR(TWCR), 1 << TWINT | 1 << TWEN | 0 << TWIE
_i2c_wait2:
	in tmp1, _SFR_IO_ADDR(TWCR)
	andi tmp1, 1 << TWINT
	breq _i2c_wait2
	ret
	
i2c_read_ack:
	OUTI _SFR_IO_ADDR(TWCR), 1 << TWINT | 1 << TWEN | 1 << TWEA | 0 << TWIE
_i2c_wait3:
	in tmp1, _SFR_IO_ADDR(TWCR)
	andi tmp1, 1 << TWINT
	breq _i2c_wait3
	ret

i2c_read_nack:
	OUTI _SFR_IO_ADDR(TWCR), 1 << TWINT | 1 << TWEN | 0 << TWEA | 0 << TWIE
_i2c_wait4:
	in tmp1, _SFR_IO_ADDR(TWCR)
	andi tmp1, 1 << TWINT
	breq _i2c_wait4
	ret

i2c_stop:
	OUTI _SFR_IO_ADDR(TWCR), 1 << TWINT | 1 << TWEN | 1 << TWSTO | 0 << TWIE
_i2c_wait5:
	in tmp1, _SFR_IO_ADDR(TWCR)
	andi tmp1, 1 << TWSTO
	breq _i2c_wait5
	ret


str_start:
	.asciz "Basic Initialization done...\n\r"
str_init_i2c:
	.asciz "Init I2C...\n\r"
str_read_i2c:
	.asciz "Read I2C EEPROM...\n\r"
str_i2c_read_send_addr:
	.asciz "Send device address over TWI..."
str_send_addr:
	.asciz "Send memory address..."
str_restart_i2c:
	.asciz "Restart I2C in read mode...\n\r"
str_return_ack:
	.asciz "Return ACK...\n\r"
str_read_with_ack:
	.asciz "Read byte wth ACK responce..."
str_read_with_nack:
	.asciz "Read byte with NACK responce..."
str_i2c_stop:
	.asciz "Stop I2C"

.section .bss
; UART buffer
.lcomm out_buffer, OUT_BUFFER_LENGTH+FIFO_BUFFER_HEADER_LENGTH ; buffer_end_pointer(2)+read_pointer(2)+write_pointer(2)+flags(1)



