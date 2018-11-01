;----------------------------------------------------------------------------------
;  Interrupt Handler
;  T. Pritchard
;  Created: March 2017
;  Last Updated: 9 March 2017
;
;
;  Known Bugs: None.
;
;  Register usage:
;  R0-R6: Pushed and used for handling stuff.
;----------------------------------------------------------------------------------


fiq_handler     ;This is never actually branched to, but eh, formatting
        PUSH {R0 - R6, LR}

        b interrupt_return


irq_handler
        PUSH {R0 - R6, LR}


        b interrupt_return


;----------------------------------------------------------------------------------
;  Called by all SVC instructions to pop registers and return to the program.
;----------------------------------------------------------------------------------
interrupt_return
        POP {R0 - R6, LR}

        SUBS PC, LR, #4  ;Return to the user program.
