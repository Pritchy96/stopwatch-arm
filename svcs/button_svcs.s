;----------------------------------------------------------------------------------
;  Button SVC Table Handler
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 9 March 2017
;
;  Handles all button related SVC instructions.
;  Checks bits 0-1 of R0 in order to get the instruction code for this subset.
;
;  Known Bugs: None.
;
;  Register usage.
;  R0 = Sub table SVC selector.
;  R1 = Port area for offsetting.
;  R12 = SVC return value (button state)
;----------------------------------------------------------------------------------

;Offsets kept within sub-tables in order to aid modularity.
button_port EQU &4

;----------------------------------------------------------------------------------
;  Selects the instruction specific to this table
;----------------------------------------------------------------------------------
button_svcs
        CMP R0, #&00  ;get button states.
        BLEQ get_buttons_state

        ;If no valid code found, should probably error.
        B svc_return    ;End of SVC call, return to user program.

;----------------------------------------------------------------------------------
;  Returns the button state, masking off other values.
;----------------------------------------------------------------------------------
get_buttons_state
        MOV   R1, #port_area  ;For accessing IO
        LDRB  R12, [R1, #button_port]  ;Load in the button (and lcd) data to R12, the return register.
        AND R12, R12, #&C0 ;Mask other data, we don't care about it.
        MOV PC, LR  ;Move back to sending method.
