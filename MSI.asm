#include <p18f452.inc>
LIST P=PIC18F452, F=INHX32, N=0, ST=OFF, R=HEX
config OSC=HS, OSCS=OFF, WDT=OFF, BORV=45, PWRT=ON, BOR=ON, DEBUG=OFF, LVP=OFF, STVR=OFF

ORG 0x00 ; Origin - start of the program

; Configure ports for LCD control
BCF TRISB, RB0 ; RB0 as input for button
BCF TRISB, RB1 ; RB1 as input for button
BCF TRISC, RC0 ; RC0 as output for RS (Register Select)
BCF TRISC, RC1 ; RC1 as output for RW (Read/Write)
BCF TRISC, RC2 ; RC2 as output for E (Enable)
CLRF TRISD     

; Initialize LCD
RCALL LONGDELAY ; Initial delay for LCD power-up
BCF PORTC, RC1 ; Set RW to write
BCF PORTC, RC0 ; Set RS to instruction mode

MOVLW 0x38    ; Function set: 8-bit mode, 2 lines, 5x7 dots
RCALL SendingInstruction 

MOVLW 0x0C    ; Display on, cursor off, blink off
RCALL SendingInstruction 

MOVLW 0x01    ; Clear display
RCALL SendingInstruction 

MOVLW 0x06    ; Entry mode set: increment cursor, no display shift
RCALL SendingInstruction 

; Define initial time values in ASCII
MOVLW '0'     
MOVWF HOURS_TENS 
MOVWF HOURS_UNITS 
MOVWF MINUTES_TENS 
MOVWF MINUTES_UNITS 
MOVWF SECONDS_TENS 
MOVWF SECONDS_UNITS 

; Display "TIME " label
BCF PORTC, RC0 ; Set RS to instruction mode
MOVLW 0x80 ; Set DDRAM address to 0 (first line)
RCALL SendingInstruction

BSF PORTC, RC0 ; Set RS to data mode
MOVLW 'T' 
RCALL SendingData 
MOVLW 'I' 
RCALL SendingData 
MOVLW 'M' 
RCALL SendingData 
MOVLW 'E' 
RCALL SendingData 
MOVLW ' ' 
RCALL SendingData 

; Display "Day " label on second line
BCF PORTC, RC0 ; Set RS to instruction mode
MOVLW 0xC0 ; Set DDRAM address to 0x40 (second line)
RCALL SendingInstruction

BSF PORTC, RC0 ; Set RS to data mode
MOVLW 'D' 
RCALL SendingData 
MOVLW 'A' 
RCALL SendingData 
MOVLW 'Y' 
RCALL SendingData 
MOVLW ' ' 
RCALL SendingData ; 

MAIN_LOOP:
    MOVLW 0x85 ; Set cursor to position after "TIME "
    BCF PORTC, RC0 ; Set RS to instruction mode
    RCALL SendingInstruction
    BSF PORTC, RC0 ; Set RS to data mode

    MOVF HOURS_TENS, W 
    RCALL SendingData 
    MOVF HOURS_UNITS, W 
    RCALL SendingData 
    MOVLW ':' 
    RCALL SendingData 
    MOVF MINUTES_TENS, W 
    RCALL SendingData 
    MOVF MINUTES_UNITS, W 
    RCALL SendingData 
    MOVLW ':' 
    RCALL SendingData 
    MOVF SECONDS_TENS, W 
    RCALL SendingData 
    MOVF SECONDS_UNITS, W 
    RCALL SendingData 

    ; Check RB0 button press to increment hours
    BTFSC PORTB, RB0 
    CALL IncrementHour 

    ; Check RB1 button press to increment minutes
    BTFSC PORTB, RB1 
    CALL IncrementMinute 

    ; Display "MONDAY" on second line after "Day "
    MOVLW 0xC4 ; Set DDRAM address to 0x44 (second line after "Day ")
    BCF PORTC, RC0 ; Set RS to instruction mode
    RCALL SendingInstruction
    BSF PORTC, RC0 ; Set RS to data mode

    MOVLW 'M' 
    RCALL SendingData 
    MOVLW 'O' 
    RCALL SendingData 
    MOVLW 'N' 
    RCALL SendingData 
    MOVLW 'D' 
    RCALL SendingData 
    MOVLW 'A' 
    RCALL SendingData
    MOVLW 'Y' 
    RCALL SendingData 

    ; Increment SECONDS_UNITS
    INCF SECONDS_UNITS, F
    MOVLW '9' + 1 
    SUBWF SECONDS_UNITS, W
    BTFSS STATUS, Z
    GOTO MAIN_LOOP

    ; If SECONDS_UNITS reached '10', reset to '0' and increment SECONDS_TENS
    MOVLW '0'
    MOVWF SECONDS_UNITS
    INCF SECONDS_TENS, F
    MOVLW '5' + 1 
    SUBWF SECONDS_TENS, W
    BTFSS STATUS, Z
    GOTO MAIN_LOOP

    ; If SECONDS_TENS reached '6', reset to '0' and increment MINUTES_UNITS
    MOVLW '0'
    MOVWF SECONDS_TENS
    INCF MINUTES_UNITS, F
    MOVLW '9' + 1 
    SUBWF MINUTES_UNITS, W
    BTFSS STATUS, Z
    GOTO MAIN_LOOP

    ; If MINUTES_UNITS reached '10', reset to '0' and increment MINUTES_TENS
    MOVLW '0'
    MOVWF MINUTES_UNITS
    INCF MINUTES_TENS, F
    MOVLW '5' + 1 
    SUBWF MINUTES_TENS, W
    BTFSS STATUS, Z
    GOTO MAIN_LOOP

    ; If MINUTES_TENS reached '6', reset to '0' and increment HOURS_UNITS
    MOVLW '0'
    MOVWF MINUTES_TENS
    INCF HOURS_UNITS, F
    MOVLW '9' + 1 
    SUBWF HOURS_UNITS, W
    BTFSS STATUS, Z
    GOTO MAIN_LOOP

    ; If HOURS_UNITS reached '10', reset to '0' and increment HOURS_TENS
    MOVLW '0'
    MOVWF HOURS_UNITS
    INCF HOURS_TENS, F
    MOVLW '2' ; 
    SUBWF HOURS_TENS, W
    BTFSS STATUS, Z
    GOTO MAIN_LOOP

    ; If HOURS_TENS reached '2' and HOURS_UNITS reached '4', reset to '00:00:00'
    MOVLW '0'
    MOVWF HOURS_TENS
    MOVF HOURS_UNITS, W
    SUBLW '4'
    BTFSC STATUS, Z
    CLRF HOURS_UNITS
    GOTO MAIN_LOOP 

; Subroutine to send instruction to LCD
SendingInstruction:
    MOVWF PORTD ;  (send data to LCD)
    RCALL HtoL_pulse ; Generate high-to-low pulse on E pin
    RCALL SHORTDELAY  
    RETURN  

; Subroutine to send data to LCD
SendingData:
    MOVWF PORTD ;  (send data to LCD)
    RCALL HtoL_pulse ; Generate high-to-low pulse on E pin
    RCALL SHORTDELAY 
    RETURN  

; Short delay subroutine
SHORTDELAY:
    MOVLW b'00001000'  
    MOVWF T0CON  
    MOVLW 0x10 ; Load 16 into W
    MOVWF TMR0H  
    MOVWF TMR0L  
    BCF INTCON, TMR0IF  
    BSF T0CON, TMR0ON 
AGAIN:
    BTFSS INTCON, TMR0IF  
    BRA AGAIN ; L
    BCF T0CON, TMR0ON ; S
    RETURN  

; Long delay subroutine (approx. 1 second)
LONGDELAY:
    MOVLW b'00000100' ; Load 4 into W
    MOVWF T0CON  
    MOVLW 0x00  
    MOVWF TMR0H  
    MOVWF TMR0L  
    BCF INTCON, TMR0IF  
    BSF T0CON, TMR0ON 
A2:
    BTFSS INTCON, TMR0IF 
    BRA A2 
    BCF T0CON, TMR0ON  
    RETURN 

; Subroutine to increment hour
IncrementHour:
    INCF HOURS_UNITS, F  
    MOVLW '9' + 1 
    SUBWF HOURS_UNITS, W
    BTFSS STATUS, Z
    RETURN ; Return if not overflowed

    ; Reset units and increment tens if needed
    MOVLW '0'
    MOVWF HOURS_UNITS
    INCF HOURS_TENS, F 
    MOVLW '2' 
    SUBWF HOURS_TENS, W
    BTFSS STATUS, Z
    RETURN 

; Subroutine to increment minute
IncrementMinute:
    INCF MINUTES_UNITS, F
    MOVLW '9' + 1 
    SUBWF MINUTES_UNITS, W
    BTFSS STATUS, Z
    RETURN

    ; Reset units and increment tens if needed
    MOVLW '0'
    MOVWF MINUTES_UNITS
    INCF MINUTES_TENS, F
    MOVLW '5' + 1 
    SUBWF MINUTES_TENS, W
    BTFSS STATUS, Z
    RETURN

; Generate high-to-low pulse on E pin
HtoL_pulse:
    BSF PORTC, RC2 ; Set E high
    NOP ; No operation (small delay)
    BCF PORTC, RC2 ; Set E low
    RETURN 


CBLOCK 0x20 ; Starting address for variable definitions
    HOURS_TENS     
    HOURS_UNITS    
    MINUTES_TENS   
    MINUTES_UNITS  
    SECONDS_TENS   
    SECONDS_UNITS  
ENDC

END

