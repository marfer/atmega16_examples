# Master make file
# APPLICATION LINKS
#

CC       = avr-gcc
ASM	 = avr-as
OBJCOPY  = avr-objcopy
DUDE     = avrdude

# DEFAULT VARIABLES
ifndef MCU
  MCU	= atmega16a
endif

ifndef CPU_F
  CPU_F	= 8000000
endif

ifndef DUDE_MCU
  DUDE_MCU	= m16
endif

ifndef DUDE_BAUDRATE
  DUDE_BAUDRATE	= 115200
endif

ifndef PROGR
  PROGR		= jtagmkI
endif

ifndef PORT
  PORT		= /dev/ttyUSB1
endif

ifndef BAUD_RATE
  BAUD_RATE	= 19200
endif


ifndef HFUSE
#	Fuse 	Bit	Description 		Default Value
#	OCDEN	7 	Enable OCD 		1 (unprogrammed, OCD disabled)
#	JTAGEN  6 	Enable JTAG 		0 (programmed, JTAG enabled)
#	SPIEN  	5 	SPI Program		0 (programmed, SPI prog. enabled)
#	CKOPT 	4 	Oscillator opt		1 (unprogrammed)
#	EESAVE 	3 	EEPROM memory is 
#			preservedthrough the 
#			Chip Erase 		1 (unprogrammed, EEPROM not preserved)
#	BOOTSZ1 2 	Select Boot Size 	0 (programmed)
#	BOOTSZ0 1 	Select Boot Size 	0 (programmed)
#	BOOTRST 0 	Select reset vector 	1 (unprogrammed)
#	
	# 1001 1011
	HFUSE	=	0x9B
endif

ifndef LFUSE
#	Fuse	Bit	Description 		Default Value
#	BODLEVEL 7 	Brown-out Detector 
#			trigger level 		1 (unprogrammed)
#	BODEN	6	Brown-out Detector 
#			enable 			1 (unprogrammed, BOD disabled)
#	SUT1 	5 	Select start-up time 	1 (unprogrammed)
#	SUT0 	4 	Select start-up time 	0 (programmed)
#	CKSEL3 	3 	Select Clock source 	0 (programmed)
#	CKSEL2 	2	Select Clock source 	0 (programmed)
#	CKSEL1 	1 	Select Clock source 	0 (programmed)
#	CKSEL0 	0 	Select Clock source 	1 (unprogrammed)
 	# 1101 0100
	LFUSE	=	0xD4
endif

ifndef CFLAGS
CFLAGS=-mno-interrupts -nostartfiles
endif


ifndef INCLUDES
INCLUDES=../common
endif

ifndef X_LANG
X_LANG=assembler-with-cpp
endif

ifndef ASFLAGS
ASFLAGS=-DF_CPU=$(CPU_F) -DBAUD_RATE=$(BAUD_RATE) -I $(INCLUDES) -Wall -x ${X_LANG}
endif

PFLAGS   = -b $(DUDE_BAUDRATE)

#---------------- Linker Options ----------------
#  -Wl,...:     tell GCC to pass this to linker.
#    -Map:      create map file
#    --cref:    add cross reference to  map file
LDFLAGS  = -Wl,-Map=$(TARGET).map,--cref
LDFLAGS += -Wl,--section-start=.text=$(BOOT_START)
LDFLAGS += -Wl,--relax
LDFLAGS += -Wl,--gc-sections
LDFLAGS += $(EXTMEMOPTS)
LDFLAGS += $(patsubst %,-L%,$(EXTRALIBDIRS))
LDFLAGS += $(PRINTF_LIB) $(SCANF_LIB) $(MATH_LIB)
#LDFLAGS += -T linker_script.x

SRCDIR   = src
BINDIR   = bin


ifndef SRCS
SRCS=main.S
endif

ifndef OBJ
OBJ=$(SRCS:.S=.o)
endif

prj0	= 00_uart_simple
prj1	= 01_uart_int
prj2	= 02_uart_buffer
prj3	= 03_uart_game
prj4 	= 04_soft_uart
prj5	= 05_encoder_simple
prj6	= 06_i2c_simple
prj7	= 07_i2c_soft
prj8	= 08_lcd_hd_44780
prj9	= 09_sd_card_spi
prj10   = 10_c_arduino_uart
prj11   = 11_c_arduino_spi
prj12   = 12_spi_asm_avr

projects = $(prj0) $(prj1) $(prj2) $(prj3) $(prj4) $(prj5) $(prj6) $(prj7) $(prj8) $(prj9) $(prj10) $(prj11) $(prj12)

# Project specific variables

PROJECT_NAME_HEX = $(BINDIR)/$(PROJECT_NAME).hex

.PHONY: build
build: $(BINDIR)/$(PROJECT_NAME).hex

$(BINDIR)/$(PROJECT_NAME).hex: $(BINDIR)/$(PROJECT_NAME).elf $(MAKEFILE_LIST)
	$(OBJCOPY) -j .text -j .data -j .bss -O ihex $< $@

$(BINDIR)/$(PROJECT_NAME).elf: $(BINDIR)/$(OBJ) 
	$(CC) -mmcu=$(MCU) $(CFLAGS) $< -o $@
	
$(BINDIR)/$(OBJ): $(SRCDIR)/$(SRCS) | $(BINDIR)
	$(CC) -mmcu=$(MCU) $(ASFLAGS) -c $< -o $@

$(BINDIR): 
	mkdir $@


.PHONY: all $(projects)
all: $(projects)

$(projects):
	$(MAKE) -C $@


#.PHONY: clean $(projects)
clean-all: $(projects) 
	for dir in $(projects); do \
		make clean -C $$dir; \
	done


.PHONY: flash
flash: $(PROJECT_NAME_HEX)
	$(DUDE) -c $(PROGR) -p $(DUDE_MCU) -P $(PORT) $(PFLAGS) -U flash:w:$<


.PHONY: fuse
fuse: 
	$(DUDE) -c $(PROGR) -p $(DUDE_MCU) -P $(PORT) $(PFLAGS) -U lfuse:w:$(LFUSE):m -U hfuse:w:$(HFUSE):m -V


.PHONY: clean
clean:
	rm -rf $(BINDIR)

.PHONY: comm
comm:
	minicom -D /dev/ttyUSB0 -b $(BAUD_RATE)


# Link: create ELF output file from object files.
.SECONDARY : $(TARGET).elf
.PRECIOUS : $(OBJ)
elf: $(OBJ)
	@echo
	@echo Linking... $@
	$(CC) $(ALL_CFLAGS) $^ --output $@ $(LDFLAGS)

