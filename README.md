# AVR Tutorials 

Example programs for ATMega16A AVR microcontroller generally written in assembly language

 - 00_uart_simple 
	Simple UART echo program. Implemented with existing USART module on microcontroller.
 - 01_uart_int
	Echo UART implemented with existing USART module and driven by interrupts.
 - 02_uart_buffer
	UART with buffer for holding request message. Implemented with USART module on microcontroller.
 - 03_uart_game
	Guess number from 1 until 100, UART transmission.
 - 04_soft_uart
	UART transmission protocol implemented in assembly language.
 - 05_encoder_simple
	Assembly program for impulse encoder to find out rotation direction. Information displayed on 7 segment display.
 - 06_i2c_simple
	Sample program that communicates via I2C protocol with EEPROM chip. Implemented without error handling and interrupts.
 - 07_i2c_soft
	Soft implementation of I2C Master mode protocol.
 - 08_lcd_hd_44780
	Assembly program to show text on LCD (HD-44780) and continuously pull states of buttons matrix. In case button pressed it LCD shows the button number.
 - 09_sd_card_spi
	Initialize SD Card via SPI protocol, show bytes of the card on LCD
 - 10_c_arduino_uart
	Example to show how the arduino library can be adjusted to run on ATMega16a microcontroller. UART communication written on C.
 - 11_c_arduino_spi
	Example to show how to use adjusted arduino library to implement SPI master -> slave communication with RFC module. Sends info about RFC tag to the UART over SPI.
 - 12_spi_asm_avr
	SPI protocol implemented on assembly.	


## Installation
Build scripts configured for [PinBoard II](http://shop.easyelectronics.ru/index.php?productID=151) dev board and are using on-board FT2232D chip as programmator. You probably need to adjust root *Makefile* in case you have different pinouts.

To build programs you need to install [gcc-avr](http://avr-eclipse.sourceforge.net/wiki/index.php/The_AVR_GCC_Toolchain) and [avrdude](http://www.nongnu.org/avrdude/).
#### Build and flash
To flash desired program to microcontroller:
```shell
cd [project] && make && make flash
```
#### Clean 
```shell
make clean
```
or in parent directory:
```shell
make clean-all
```
