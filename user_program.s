;----------------------------------------------------------------------------------
;  Stopwatch Program
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 9 March 2017
;
;  A simple stopwatch program. The lower button starts the count, and the upper
;  button causes it to pause. Holding the upper button for for > 1 second causes
;  it to reset.
;
;  I'm not entirely happy about using 4 different registers for each digit,
;  Maybe I could use one register with bit manipulation?
;
;  Known Bugs: On some boards, there is an issue where the last digit is occasionally,
;  and somewhat erratically, duplicated. This is simply not present whatsoever on some other boards .
;
;  Register usage.
;  R1 = Last timer value.
;  R2 = Timer
;  R3 = Top Button Timer.
;  R4 = Pause bit.
;  R5 = Used in timer calculations, value of seconds/minutes.
;  R6 = Tens of Minutes
;  R7 = Single Minutes
;  R8 = Tens of Seconds
;  R9 = Single Seconds
;  R11 = Svc parameter.
;  R12 = Svc return.
;----------------------------------------------------------------------------------

tens_seconds	DEFW	10000
single_minute 	DEFW	60000
tens_minutes	DEFW	600000
ALIGN

;----------------------------------------------------------------------------------
;  Initialises Backlight then branches into the main program loop.
;----------------------------------------------------------------------------------
begin_user_program
        SVC &0101 ;Enable backlight.
        ADD R11, R11, #1
        SVC &0100 ;Reset LCD
        B main_loop

;----------------------------------------------------------------------------------
;  Loads the timer value, adds it to the main counter, accounting for overflow,
;  then converts the value to the format mm: ss and prints it. Fnally, it gets and
;  handles button input.
;----------------------------------------------------------------------------------
main_loop
        SVC &0200 ;Put current timer value into R12.
        SUBS R5, R12, R1 ;Subtract old value of timer from new value (get difference), and set flags.

        ;If the subtraction resulted in a negative value, then we have 'ticked over'
        ;The sub will therefore result in a negative value, we need to add 255 (max value before ticking over)
        ;plus 1 (256) To account for the extra in addition to the full cycle of 255.
        ;Does not account for multiple full cycles. In this program this should not happen.
        ADDMI R5, R5, #256 ;Add if minus (NE is taken, Not equal)

        CMP R4, #0 ;Check pause bit is not set.
        ADDEQ R2, R2, R5 ;Update actual counter (if not paused).

        MOV R1, R12  ;Store the now old value of R12 into R1 for the next loop.

        SVC &0300 ;Get button input.

        CMP R12, #&40  ;Stop button
        ADDEQ R3, R3, R5

        CMP R12, #&80  ;bottom button
        MOVEQ R4, #0 ;Pause the timer.

        CMP R12, #&00 ;No button pressed
        BLEQ buttons_not_held

        PUSH {LR}
        BL convert_to_decimal
        POP {LR}

        MOV R11, R6
        SVC &0105 ;Print tens of minutes.
        MOV R11, R7
        SVC &0105 ;Print minutes.
        MOV R11, #58
        SVC &0102 ;Print colon.
        MOV R11, #32
        SVC &0102 ;Print space.
        MOV R11, R8
        SVC &0105 ;Print tens of seconds.
        MOV R11, R9
        SVC &0105 ;Print seconds.

        MOV R11, #&2 ;Reset LCD counter cursor.
        SVC &0100

        B main_loop

;----------------------------------------------------------------------------------
;  Checks to see if the upper button has been held down. If so,
;  it either resets the counter or pauses it.
;----------------------------------------------------------------------------------
buttons_not_held  ;This only handles upper button, lower button is handled as soon as it is pressed.
        CMP R3, #1000  ;Reset program if upper button has been held for long enough.
        BGT reset_program

        CMP R3, #0  ;If the time upper button has been pressed is > 0, but not > reset time, we want to start the count.
        MOVGT R4, #1

        MOV R3, #0 ;Zero the reset timer.
        MOV PC, LR  ;Return

;----------------------------------------------------------------------------------
;  Uses the below methods to convert the milisecond hex value in the timer
;  to a MM:SS format.
;----------------------------------------------------------------------------------
convert_to_decimal
        MOV R6, #0
        MOV R7, #0
        MOV R8, #0
        MOV R9, #0
        PUSH {R2, LR}
        BL handle_tens_minutes
        POP {R2, LR} ;Restore counter value.
        MOV PC, LR ;Return to calling method.

handle_tens_minutes
        LDR R5, tens_minutes
        CMP R2, R5
        BLT handle_single_minutes ;If less than ten seconds, move to single second counter.
        SUB R2, R2, R5 ;Remove 10 mins from the main counter.
        ADD R6, R6, #1 ;Add one to the second counter.
        B handle_tens_minutes

handle_single_minutes
        LDR R5, single_minute
        CMP R2, R5
        BLT handle_tens_seconds ;If less than ten seconds, move to single second counter.
        SUB R2, R2, R5 ;Remove 1 min from the main counter.
        ADD R7, R7, #1 ;Add one to the second counter.
        B handle_single_minutes

handle_tens_seconds
        LDR R5, tens_seconds
        CMP R2, R5
        BLT handle_single_seconds ;If less than ten seconds, move to single second counter.
        SUB R2, R2, R5 ;Remove ten seconds from the main counter.
        ADD R8, R8, #1 ;Add one to the second counter.
        B handle_tens_seconds

handle_single_seconds
        CMP R2, #1000
        MOVLT PC, LR  ;If less than one second, just return to sending method.
        SUB R2, R2, #1000 ;Remove one second from the main counter.
        ADD R9, R9, #1 ;Add one to the second counter.
        B handle_single_seconds

;----------------------------------------------------------------------------------
;  Reset program timer and pause it.
;----------------------------------------------------------------------------------
reset_program
        MOV R2, #0
        MOV R4, #1
        MOV R3, #0 ;Zero the reset timer.
        B main_loop
