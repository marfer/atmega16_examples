
; LCD Init
.equ 	LCD_CLR          	, 0     	 ; DB0: clear display
.equ 	LCD_HOME         	, 1     	 ; DB1: return to home position

.equ  	LCD_ENTRY_MODE   	, 2     	 ; DB2: set entry mode
.equ 	LCD_ENTRY_INC    	, 1     	 ; DB1: increment
.equ 	LCD_ENTRY_SHIFT  	, 0     	 ; DB2: shift

.equ 	LCD_ON		      	, 3     	 ; DB3: turn lcd/cursor on
.equ  	LCD_ON_DISPLAY   	, 2     	 ; DB2: turn display on
.equ  	LCD_ON_CURSOR     	, 1     	 ; DB1: turn cursor on
.equ  	LCD_ON_BLINK      	, 0     	 ; DB0: blinking cursor

.equ  	LCD_MOVE          	, 4     	 ; DB4: move cursor/display
.equ 	LCD_MOVE_DISP		, 3     	 ; DB3: move display 0-> move cursor
.equ  	LCD_MOVE_RIGHT		, 2     	 ; DB2: move right 0-> left

.equ  	LCD_F		        , 5     	 ; DB5: function set
.equ 	LCD_F_8B	  	, 4     	 ; DB4: set 8BIT mode 0->4BIT mode
.equ  	LCD_F_2L		, 3     	 ; DB3: two lines 0->one line
.equ  	LCD_F_10D		, 2     	 ; DB2: 5x10 font 0->5x7 font
.equ  	LCD_CGRAM           	, 6     	 ; DB6: set CG RAM address
.equ  	LCD_DDRAM           	, 7     	 ; DB7: set DD RAM address

.equ	SCR_L			, 0b00011000	 ; shift screen left command
.equ	SCR_R			, 0b00011100	 ; shift screen right command

.equ	CUR_L			, 0b00010000	 ; shift cursor left command
.equ	CUR_R			, 0b00010100	 ; shift cursor right command
.equ	DWIDTH			, 16

; Init Config
.macro	INIT_LCD						
	rcall	lcd_init					; Init port direction
	rcall	lcd_delay					; Wait for screen
	WR_CMD	1 << LCD_F | 0 << LCD_F_8B			; 4 bit mode
	WR_CMD	1 << LCD_F | 0 << LCD_F_8B | 1  <<  LCD_F_2L 	; send again 4 bit mode + 2 lines
	WR_CMD	1 << LCD_ENTRY_MODE | 1 << LCD_ENTRY_INC 
	WR_CMD	1 << LCD_ON | 1 << LCD_ON_DISPLAY | 0 << LCD_ON_CURSOR | 1 << LCD_ON_BLINK	
	WR_CMD	1 << LCD_HOME
.endm

;===============================================================================================
;Write Data
.macro	WR_DATA data
	ldi	tmp2, \data
	rcall	lcd_send_data
.endm
;===============================================================================================
;Write CMD
.macro	WR_CMD cmd
	ldi	tmp2, \cmd
	rcall	lcd_send_cmd
.endm
;===============================================================================================
; Read Data
.macro	RD_DATA
	rcall	lcd_read_data
.endm
;===============================================================================================
; Read CMD
.macro	RD_CMD
	rcall	lcd_read_cmd
.endm

;===============================================================================================
;Set COORD
;Syntax LCD_COORD X,Y
.macro LCD_COORD x, y
	ldi	tmp2, 1 << LCD_DDRAM | \x+40*\y
	rcall	lcd_send_cmd
.endm
;===============================================================================================
;Shift SCREEN/CURSOR
.macro	SHIFT x
	ldi	tmp2, \x
	rcall	lcd_send_cmd
.endm

;===============================================================================================
;LCD Clear

.macro	LCDCLR
	ldi 	tmp2, 1 << LCD_CLR
	rcall	lcd_send_cmd
.endm

;===============================================================================================
;Write CGRAM
.macro WR_CGADR b
	ldi	tmp2, 1 << LCD_CGRAM | \b
	rcall	lcd_send_cmd
.endm

;Write DDRAM
.macro WR_DDADR b
	ldi	tmp2, 1 << LCD_DDRAM | \b
	rcall	lcd_send_cmd
.endm

