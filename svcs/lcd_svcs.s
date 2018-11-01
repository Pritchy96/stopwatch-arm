;----------------------------------------------------------------------------------
;  LCD SVC Table Handler
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 9 March 2017
;
;  Handles all button related SVC instructions.
;  Checks bits 0-1 of R0 in order to get the instruction code for this subset.
;
;  Known Bugs: None. Honestly, this section is a bit of a mess. It needs a rewrite.
;
;  Register usage for instruction selection (functions may be different)
;  R0 = Sub table SVC selector.
;  R1 = Port area for offsetting.
;  R2 = Value to push to lcd to switch LCD backlight on.
;  R11 = SVC Parameter.
;
;
;  Register usage for printing methods
;  R0 = Port Area
;  R1 = R11 Stoarge for print_hex_4
;  R2 = General Purpose port register for print_char.
;  R3 = Port A reading (waiting for idle)
;  R11 = SVC Parameter.
;----------------------------------------------------------------------------------

;Offsets kept within sub-tables in order to aid modularity.
lcd_port_a  EQU   &0
lcd_port_b  EQU   &4

;Port A Values
idle_bit    EQU   &80 ;Bit to check whether lcd is idle.

;Port B Values.
lcd_rs       EQU  &2   ;register select, 0 = control, 1 = data
lcd_rw       EQU  &4   ;r not w, 1 = r, 0 = w
lcd_e        EQU  &1   ;Enable signal
lcd_light    EQU  &20  ;Enable backlight.


;----------------------------------------------------------------------------------
;  Selects the instruction specific to this table
;----------------------------------------------------------------------------------
lcd_svcs
        CMP R0, #&00  ;Send control signal to LCD.
        BLEQ write_control_signal
        CMP R0, #&01   ;LCD Backlight enable.
        BLEQ lcd_backlight
        CMP R0, #&02   ;Print ascii Char.
        BLEQ print_char
        CMP R0, #&03
        BLEQ print_hex_word
        CMP R0, #&04
        BLEQ print_hex_byte
        CMP R0, #&05   ;Print hex Char.
        BLEQ print_hex_digit

        ;If no valid code found, should probably error.
        B svc_return    ;End of SVC call, return to user program.

;----------------------------------------------------------------------------------
;  Enables the LCD backlight by sending 1 one on bit 5 of port B.
;----------------------------------------------------------------------------------
lcd_backlight
        MOV   R1, #port_area  ;For accessing IO
        LDRB  R2, [R1, #lcd_port_b] ;Load backlight values first so we don't overwrite stuff.
        ORR  R2, R2, #lcd_light   ;Switch on LCD Backlight
        STRB  R2, [R1, #lcd_port_b]
        MOV PC, LR  ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Prints an entire Hex word
;----------------------------------------------------------------------------------
print_hex_word
        PUSH {LR} ;Store the old LR value in the stack so we can BL again.
        MOV R11, R11, ROR #24
        BL print_hex_byte
        MOV R11, R11, ROR #24
        BL print_hex_byte
        MOV R11, R11, ROR #24
        BL print_hex_byte
        MOV R11, R11, ROR #24
        BL print_hex_byte
        POP {LR} ;Pop the old LR value back to the LR.
        MOV PC, LR  ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Prints two Hex Digits
;----------------------------------------------------------------------------------
print_hex_byte
        PUSH {LR} ;Store the old LR value in the stack so we can BL again.
        MOV R11, R11, ROR #4
        BL print_hex_digit
        MOV R11, R11, ROR #28
        BL print_hex_digit
        POP {LR} ;Pop the old LR value back to the LR.
        MOV PC, LR  ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Prints a signel Hex Digit
;----------------------------------------------------------------------------------
print_hex_digit
        MOV R1, R11
        AND R1, R1, #&F ;Mask off Opcode

        CMP R1, #9
        BGT convert_to_hex_letter ;If it's > 9
        B convert_to_hex_digit  ;Otherwise conver to ascii digit (from hex).

;----------------------------------------------------------------------------------
;  Converts a hex value to ASCII A-F
;----------------------------------------------------------------------------------
convert_to_hex_letter
        ADD R1, R1, #55 ;value + A
        PUSH {LR, R11} ;Store the old LR value in the stack so we can BL again.
        MOV R11, R1
        BL print_char
        POP {LR, R11} ;Pop the old LR, R11 value back to the LR.
        MOV PC, LR  ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Converts a hex value to ASCII 0-9
;----------------------------------------------------------------------------------
convert_to_hex_digit
        ADD R1, R1, #48 ;Value + '0'
        PUSH {LR, R11} ;Store the old LR value in the stack so we can BL again.
        MOV R11, R1
        BL print_char
        POP {LR, R11} ;Pop the old LR, R11 value back to the LR.
        MOV PC, LR  ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Prints a single ASCII Char
;----------------------------------------------------------------------------------
print_char
        MOV   R0, #port_area  ;For accessing IO

        PUSH {LR} ;Store the old LR value in the stack so we can BL again.
        BL  wait_for_lcd_idle
        POP {LR} ;Pop the old LR value back to the LR.

        LDRB R2, [R0, #lcd_port_b]  ;Load old b, only modify certain bits, leave the rest.
        BIC  R2, R2, #lcd_rw ;set rw to 0, write.
        ORR  R2, R2, #lcd_rs ;select data on reg select
        STRB R2, [R0, #lcd_port_b]  ;Store B

        STRB R11, [R0, #lcd_port_a]  ;Store char in A.
        ;ADD  R5, R5, #1 ;Get the next address Byte of the string.

        ORR  R2, R2, #lcd_e  ;Set bus enable high.
        STRB R2, [R0, #lcd_port_b]  ;Store B

        BIC  R2, R2, #lcd_e  ;Bit clear bus enable; set it low.
        STRB R2, [R0, #lcd_port_b]  ;Store B

        MOV PC, LR  ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Waits for the LCD to become idle before returning.
;----------------------------------------------------------------------------------
wait_for_lcd_idle
        MOV   R4, #idle_bit   ;for comparison in wait_for_idle

        LDRB R2, [R0, #lcd_port_b]  ;Load old b, only modify certain bits, leave the rest.
        ORR  R2, R2, #lcd_rw ;set rw to 1, read.
        AND  R2, R2, #(&FF - lcd_rs - lcd_e)

        ORR  R2, R2, #lcd_e  ;Set bus enable high.
        STRB R2, [R0, #lcd_port_b]  ;Store B

        LDRB R3, [R0, #lcd_port_a] ;load a

        AND  R3, R3, R4  ;Anding with 1000000 means we zero everything but bit 7, getting either 00000000 or 10000000
        CMP  R3, R4  ;If R1 = 10000000 then lcd is not idle, wait more
        BEQ  wait_for_lcd_idle
        MOV PC, LR  ;Otherwise move back to write char, after the branch.

;----------------------------------------------------------------------------------
;  Sends R3 over the control bus.
;----------------------------------------------------------------------------------
write_control_signal  ;TODO: This should be used by other functions.
        MOV   R0, #port_area  ;For accessing IO

        PUSH {LR} ;Store the old LR value in the stack so we can BL again.
        BL  wait_for_lcd_idle
        POP {LR} ;Pop the old LR value back to the LR.

        LDRB R2, [R0, #lcd_port_b]  ;Load old b, only modify certain bits, leave the rest.
        BIC  R2, R2, #(lcd_rw OR lcd_rs) ;set rw to 0, write.
        ;BIC  R2, R2, # ;select control on reg select
        STRB R2, [R0, #lcd_port_b]  ;Store B

        LDRB R3, [R0, #lcd_port_a]  ;Load old A, only modify certain bits, leave the rest.
        BIC  R3, R3, R11
        ORR  R3, R3, R11
        STRB R11, [R0, #lcd_port_a]  ;Store signal in A.

        ORR  R2, R2, #lcd_e  ;Set bus enable high.
        STRB R2, [R0, #lcd_port_b]  ;Store B

        BIC  R2, R2, #lcd_e  ;Bit clear bus enable; set it low.
        STRB R2, [R0, #lcd_port_b]  ;Store B

        MOV PC, LR  ;Move back to sending method.
