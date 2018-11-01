;----------------------------------------------------------------------------------
;  Main SVC Table Handler
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 9 March 2017
;
;  This file handles selecting a sub-table to handle the SVC call.
;  SVC handling is done like so:
;
;  24 bit field is split up into a two digit table selector and a two digit instruction selector.
;  Bits 6-7 are Opcode, Bits 4-5 are ignored (for cleanliness of SVC calls, could easily be expanded to use this for additional tables/instructions)
;  Bits 2-3 are the table selector, each table being a loosely defined 'type' of svc: lcd instructions, timer instructions, etc.
;  Bits 0-1 select the instruction within this table., i.e instruction 00 of the LCD table resets the LCD, etc.
;
;  Could I get some feedback as to whether this is a good or terrible idea? I'm unsure reguarding the readability to efficiency tradeoff.
;  I understand it's probably overkill right now, but I was thinking of this as a code base to use moving forward for future labs.
;
;  Known Bugs: None.
;
;  Register usage:
;  R0 = SVC instruction getter, then masked to just bits 0-1 (Sub-table instruction selector).
;  R1 = Table selector.
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
;  Selects the instruction table
;----------------------------------------------------------------------------------
svc_handler
        PUSH {R0 - R6, LR}
        LDR R0, [LR, #-4] ;LR is the instruction before the one we're linking back to, load it so we can parse the data.
        BIC R0, R0, #&FF000000 ;Mask off Opcode

        AND R1, R0, #&0000FF00 ;Mask off all but table selector
        AND R0, R0, #&000000FF ;Mask off all but instruction selector

        CMP R1, #&0000  ;Standard system stuff
        BEQ core_svcs

        CMP R1, #&0100   ;LCD Stuff
        BEQ lcd_svcs

        CMP R1, #&0200   ;Timer Stuff
        BEQ timer_svcs

        CMP R1, #&0300   ;Button Stuff
        BEQ button_svcs

;----------------------------------------------------------------------------------
;  Called by all SVC instructions to pop registers and return to the program.
;----------------------------------------------------------------------------------
svc_return
        ;Change from supervisor mode to user mode.
        POP {R0 - R6, LR}
        MOVS PC, LR  ;Return to the user program.


;SVC handler files.
include svcs/core_svcs.s
include svcs/lcd_svcs.s
include svcs/timer_svcs.s
include svcs/button_svcs.s
