#include <avr/io.h>
#include <avr/interrupt.h>
#include "HardwareSerial.h"
#include "Arduino.h"
#include "pins_arduino.h"


#include "Wire.h"
#define R_BUFFER 16
#define TWI_FREQ 400000

bool stop = false;

void setup(){
	Serial.begin(115200);
	Serial.println("Starting I2C transmission");
	Wire.begin();
	Wire.setClock(TWI_FREQ);
	Serial.println("Reading memory...");
    	unsigned char buffer[R_BUFFER];
	char i = 0;
	for(int base=0; base < 256; base +=16){
		Wire.requestFrom(0xAE >> 1, R_BUFFER, base, 2, true);

		while(Wire.available()){
			buffer[i++] = Wire.read();	
		}
		if (i != 16){
			Serial.println("Incorrect responce!");
			Serial.println(i, DEC);
			Serial.flush();
			return ;
		}

		char ret[R_BUFFER*3];
		sprintf(ret, "%04x: %02x %02x %02x %02x %02x %02x %02x %02x        %02x %02x %02x %02x %02x %02x %02x %02x", base,
				buffer[0], buffer[1], buffer[2], buffer[3],  
				buffer[4], buffer[5], buffer[6], buffer[7],  
				buffer[8], buffer[9], buffer[10], buffer[11],  
				buffer[12], buffer[13], buffer[14], buffer[15]);  
		Serial.println(ret);
		Serial.flush();
		i = 0;
	}

	

}

void loop(){
	
}

