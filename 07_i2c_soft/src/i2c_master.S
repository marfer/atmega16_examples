;
; I2C_PORT, I2C_PIN, I2C_DDR - pin
; SCL SDA pin must be defined!
;
#define I2C_PORT PORTD
#define I2C_PIN PIND
#define I2C_DDR DDRD
#define SCL 7
#define SDA 5
#define I2C_STATUS r22
#define I2C_TEMP r23
; ------------------
#define ACK_NACK 7  ; 1- ACK 0 - NACK
;
.macro SET_DOWN line
	sbi _SFR_IO_ADDR(I2C_DDR), \line
	cbi _SFR_IO_ADDR(I2C_PORT), \line
.endm

; in order to set line to one, make it as Hi-z input, external resistor should pull it up
; if there are no slowpoke devices
.macro SET_UP line
	cbi _SFR_IO_ADDR(I2C_DDR), \line
	cbi _SFR_IO_ADDR(I2C_PORT), \line
.endm

.macro WAIT_UP line
_wait_\@:
	sbis _SFR_IO_ADDR(I2C_PIN), \line
	rjmp _wait_\@
.endm


.macro CLICK
	SET_UP SCL
	WAIT_UP SCL
	SET_DOWN SCL
.endm


; ------------------------------------------
; init
; ------------------------------------------
i2c_minit:
	clr I2C_STATUS
	clr I2C_TEMP
	ret

; ------------------------------------------
; send stop
; ------------------------------------------
i2c_mstop:
	SET_UP SCL
	WAIT_UP SCL
	SET_UP SDA
	ret

; ------------------------------------------
; send start
; ------------------------------------------
i2c_mstart:
	WAIT_UP SCL
	SET_DOWN SDA
	SET_DOWN SCL
	ret

; ------------------------------------------
; send start
; ------------------------------------------
i2c_mrestart:
	SET_UP SCL
	WAIT_UP SCL
	SET_DOWN SDA
	SET_DOWN SCL
	SET_UP SDA
	ret

; ------------------------------------------
; send_byte
; ------------------------------------------
i2c_msend:
	mov I2C_TEMP, tmp1 			; save to i2c temp register
	cbr I2C_STATUS, 1 << ACK_NACK		; set noack by default
	ldi tmp1, 0x08				; counter to 8
_n1_:
	sbrs I2C_TEMP, 7
	rjmp _s0_				; send 0
	SET_UP SDA
	rjmp _cm0_				; go to click/monitor				
_s0_:
	SET_DOWN SDA
_cm0_:						; click/monitor
	CLICK
	lsl I2C_TEMP				; next bit
	dec tmp1
	brne _n1_				; goto next
	; read ack/nack
	SET_UP SDA				; give line to other device
	SET_UP SCL
	sbis _SFR_IO_ADDR(I2C_PORT), SDA	; if line is up, we have nack, do nothing
	sbr I2C_STATUS, 1 << ACK_NACK		; mark we have ACK
	WAIT_UP SCL
	SET_DOWN SCL
	ret

; ------------------------------------------
; read byte
; ------------------------------------------
i2c_mread:
	clr I2C_TEMP
	ldi tmp1, 0x08
	SET_UP SDA				; give line to other device
_rn1_:
	lsl I2C_TEMP
	SET_UP SCL
	sbis _SFR_IO_ADDR(I2C_PIN), SDA		; read bit
	rjmp _r0_				; read 0
	sbr I2C_TEMP, 1				; read 1
_r0_:
	WAIT_UP SCL
	SET_DOWN SCL
	dec tmp1
	brne _rn1_
	; send ack/nack
	sbrs I2C_STATUS, ACK_NACK
	rjmp _cl1_
	SET_DOWN SDA
_cl1_:	
	CLICK
	SET_DOWN SDA
	ret


