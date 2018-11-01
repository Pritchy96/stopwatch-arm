;----------------------------------------------------------------------------------
;  Timer SVC Table Handler
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
;  R12 = SVC return value (timer value)
;----------------------------------------------------------------------------------

;Offsets kept within sub-tables in order to aid modularity.
timer_port  EQU   &8

;----------------------------------------------------------------------------------
;  Selects the instruction specific to this table
;----------------------------------------------------------------------------------
timer_svcs
        CMP R0, #&00  ;Get timer
        BLEQ get_timer

        ;If no valid code found, should probably error.
        B svc_return    ;End of SVC call, return to user program.

get_timer
        MOV   R1, #port_area  ;For accessing IO
        LDRB  R12, [R1, #timer_port]
        MOV PC, LR  ;Move back to sending method.
