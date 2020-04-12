; Interrupts vector table

	jmp		init			; (RESET) External Pin, Power-on Reset, Brown-out Reset, Watchdog Reset and JTAG AVR Reset
	jmp		__bad_intterupt 	; (INT0) External Interrupt Request 0
	jmp		__bad_intterupt		; (INT1) External Interrupt Request 1
	jmp		__bad_intterupt  	; (TIMER2 COMP) Timer/Counter2 Compare Match
	jmp		__bad_intterupt		; (TIMER2 OVF) Timer/Counter2 Overflow
	jmp		__bad_intterupt		; (TIMER1 CAPT) Timer/Counter1 Capture Event
	jmp		__bad_intterupt		; (TIMER1 COMPA) Timer/Counter1 Compare Match A
	jmp		__bad_intterupt		; (TIMER1 COMPB) Timer/Counter1 Compare Match B
	jmp		__bad_intterupt		; (TIMER1 OVF) Timer/Counter1 Overflow
	jmp		__bad_intterupt		; (TIMER0 OVF) Timer/Counter0 Overflow
	jmp		__bad_intterupt		; (SPI,STC) Serial Transfer Complete
	jmp		__bad_intterupt		; (USART,RXC) USART, Rx Complete
	jmp		__bad_intterupt		; (USART,UDRE) USART Data Register Empty
	jmp		__bad_intterupt		; (USART,TXC) USART, Tx Complete
	jmp		__bad_intterupt		; (ADC) ADC Conversion Complete
	jmp		__bad_intterupt		; (EE_RDY) EEPROM Ready
	jmp		__bad_intterupt		; (ANA_COMP) Analog Comparator
	jmp		__bad_intterupt		; (TWI) 2-wire Serial Interface
	jmp		__bad_intterupt		; (INT2) External Interrupt Request 2
	jmp		__bad_intterupt		; (TIMER0 COMP) Timer/Counter0 Compare Match
	jmp		__bad_intterupt		; (SPM_RDY) Store Program Memory Ready


__bad_intterupt:
	reti
