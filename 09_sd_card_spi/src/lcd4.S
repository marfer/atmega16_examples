;=========================================================================================
; Rewrite for GAS of LCD lib by DI HALT (www.easyelectronics.com)
;=========== LCD Define ==================================================================

#define DATA_PORT  	PORTA	
#define DATA_PIN  	PINA
#define DATA_DDR 	DDRA
#define DATA_PORT_MASK	0x0F
#define DATA_INV_MASK	0xF0
#define CMD_PORT  	PORTB
#define CMD_PIN	  	PINB
#define CMD_DDR 	DDRB
#define PIN_E  		2
#define PIN_RW 		1
#define PIN_RS  	0
; 14 for XTAL=16MHz,  10 for XTAL=8MHz,  6 for XTAL=4MHz,  5 for XTAL<4MHz
#define SPEED	  	14


;=========================================================================================
; Initialize Hardware
;=========================================================================================
lcd_init:
	
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_RS	; Выставляем нужные уровни на управляющих выводах
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_RW	; Порты на выход
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; И сразу же выставляются на 1
	sbi	_SFR_IO_ADDR(CMD_DDR), PIN_RS
	sbi	_SFR_IO_ADDR(CMD_DDR), PIN_RW
	sbi	_SFR_IO_ADDR(CMD_DDR), PIN_E
	rcall	_switch_port_in_		; Порт данных на вход
	ret

;=========================================================================================
; Ожидание флага занятости контроллера дисплея
;=========================================================================================
lcd_busy_wait:	
	ldi	tmp1, 0xFF			; Поставили таймер обрыва ожидания
	sts	BreakLoop, tmp1	
	rcall	_switch_port_in_		; Порты на вход
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_RS	; Идет Команда!
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_RW	; Чтение!
_busy_loop_:
	dec	tmp1				; Вычитаем из числа счетчиков цикла число
	sts	BreakLoop, tmp1			; Сохраним обратно
	breq	_busy_ret_			; Если ноль - выходим. Надоело. 
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Поднять строб
	rcall	lcd_delay			; Подождать	
	in	tmp1, _SFR_IO_ADDR(DATA_PIN)	; Считать байт
	swap	tmp1
	push	tmp1				; Сохранить его в стек. Дело в том,  что у нас tmp1 убивается в lcd_delay
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Бросить строб - первый цикл (старший полубайт)
	rcall	lcd_delay			; Подождем маленько	
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Поднимем строб
	in	tmp1, _SFR_IO_ADDR(DATA_PIN)	; Считать байт
	;out _SFR_IO_ADDR(UDR), tmp1		; send byte to uart
	rcall	lcd_delay			; Подождем 
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Опустим строб	- нужно для пропуска второго полубайта
	rcall	lcd_delay			; Задержка снова	
	pop	tmp1				; А теперь достаем сныканый байт - в нем наш флаг. Может быть.
	andi	tmp1, 0x80			; Продавливаем по маске. Есть флаг?
	brne	_busy_loop_			; Если нет,  то переход
_busy_ret_:		
	cbi _SFR_IO_ADDR(PORTB), 3
	ret

;=========================================================================================
; Запись команды в дисплей. Код команды в tmp2
;=========================================================================================
lcd_send_cmd:
	cli					; Запрет прерываний
	rcall	lcd_busy_wait			; Ждем готовности
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_RS	; Идет команда!
	rjmp	_wr_				; Переход на запись

;=========================================================================================
; Запись данных в дисплей. Код данных в tmp2
;=========================================================================================
lcd_send_data:
	cli					; Запрет прерываний
	rcall	lcd_busy_wait			; Ждем готовности
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_RS	; Идут данные!
_wr_:	
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_RW	; Запись!
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Поднять строб
	rcall	_switch_port_out_		; Порт настроить на выход!
	push	tmp2				; Сохраним данные которые будем выводить в стеке
	andi	tmp2, 0xF0			; Отдавим по маске данным младшую тетраду.	
	in	tmp1, _SFR_IO_ADDR(DATA_PORT)	; Возьмем из порта данных старое значение
	andi	tmp1, 0xF0			; Отдавим ему старшую тетраду
	push	tmp1				; Сохраним результа в стеке. Пригодится
	swap	tmp2
	or	tmp1, tmp2			; Склеим младшую тетраду из порта со старшей тетрадой данных 
	out	_SFR_IO_ADDR(DATA_PORT), tmp1	; Выдадим этого мутанта в порт.
	rcall	lcd_delay			; Подождем	
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Бросим строб вниз - данные ушли в индикатор
	rcall	lcd_delay			; Подождем	 
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Поднимем строб
	pop	tmp1				; Достанем из стека младшую тетраду из порта
	pop	tmp2				; И данные которые мы выводим
	andi	tmp2, 0x0F			; Отдавим младшую тетраду
	or	tmp1, tmp2			; Склеим младшую тетраду из порта с старшей тетрадой данных (бывшая младшая)
	out	_SFR_IO_ADDR(DATA_PORT), tmp1	; Выдадим в порт
	rcall	lcd_delay			; Подождем	
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Бросим строб
	rcall	lcd_delay			; Подождем	
	rcall	_switch_port_in_		; Порт вернем в прежнее состояние - на вход
	sei					; Разрешим прерывания
	rcall	lcd_busy_wait			; Ждем готовности
	ret					; Возврат

;=========================================================================================
; Чтение команды из дисплея. Результат в tmp2
;=========================================================================================
lcd_read_cmd:
	cli					; Запрет прерываний
	rcall	lcd_busy_wait			; Ждем контроллер
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_RS	; Команда!
	rjmp	_rd_				; Идем на чтение

;=========================================================================================
; Чтение команды из дисплея. Результат в tmp2
;=========================================================================================
lcd_read_data:	
	cli					; Запрет прерываний
	rcall	lcd_busy_wait			; Ждем контроллер
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_RS	; Данные!
_rd_:		
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_RW	; Чтение!
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Поднимаем строб
	rcall	lcd_delay			; Ждем
	in	tmp2, _SFR_IO_ADDR(DATA_PIN)	; Читаем из порта байт 
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Бросем строб вниз
	swap	tmp2
	andi	tmp2, 0xF0			; Отдавливаем ему младшую тетраду
	rcall	lcd_delay			; Ждем
	sbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Поднимаем строб
	mov	tmp1, tmp2			; Прячем старшую тетраду в tmp1
	in	tmp2, _SFR_IO_ADDR(DATA_PIN)	; Берем еще один байт
	cbi	_SFR_IO_ADDR(CMD_PORT), PIN_E	; Бросаем строб
	andi	tmp2, 0x0F			; Отдавливаем младшую тетраду
	or	tmp2, tmp1			; Склеиваем результат с старшим байтом
	sei					; разрешаем прерывания
	ret					; Возврат.

;=========================================================================================
; Switch port direction for read
;=========================================================================================
_switch_port_in_:
	in	tmp1, _SFR_IO_ADDR(DATA_DDR)	; Данные из DDR в регистр
	andi	tmp1, DATA_INV_MASK		; Отдавливаем старшую тетраду - нам нужно сохранить младшую и обнулить старшую
	out	_SFR_IO_ADDR(DATA_DDR), tmp1	; Выдаем результат в порт.

	in	tmp1, _SFR_IO_ADDR(DATA_PORT)	; Берем данные из порта 
	ori	tmp1, DATA_PORT_MASK		; Выставляем все биты старшей тетрады,  не трогая младшую
	out	_SFR_IO_ADDR(DATA_PORT), tmp1	; Выдаем в порт
	ret		

;=========================================================================================	
; Switch port direction for write
;=========================================================================================
_switch_port_out_:		
	in	tmp1,  _SFR_IO_ADDR(DATA_DDR)	; Данные из ДДР в регистр
	ori	tmp1,  DATA_PORT_MASK		; Выставляем все биты старшей тетрады,  не трогая младшую
	out	_SFR_IO_ADDR(DATA_DDR),  tmp1	; Выдаем данные в порт
	ret		

;=========================================================================================	
; Busy delay
;=========================================================================================
lcd_delay:
	ldi	tmp1, SPEED
_loop_:
	dec	tmp1				; Успевал обрабатывать данные
	brne	_loop_
	ret
