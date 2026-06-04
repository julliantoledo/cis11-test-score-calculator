.ORIG x3000

LEA R1, SCORES				;R1 points to the first score
AND R5, R5, #0
ADD R5, R5, #5				;R5 = 5 scores to process

INPUT_LOOP
	JSR READ_SCORE
	STR R0, R1, #0			;Store score in memory
	ADD R1, R1, #1			;Move to next memory location
	ADD R5, R5, #-1			;Decrement counter
	BRp INPUT_LOOP

LEA R1, SCORES				;Reset pointer to start
LDR R0, R1, #0				;Load score1
ST R0, MIN					;min = score1
ST R0, MAX					;max = score1
AND R6, R6, #0				;R6 = running sum, clear it
ST R6, SUM

AND R5, R5, #0
ADD R5, R5, #5				;Reset counter to 5

LOOP
	LDR R0, R1, #0			;Load current score
	JSR UPDATE_MIN			;Check and update minimum
	JSR UPDATE_MAX			;Check and update maximum
	JSR UPDATE_SUM			;Add to running sum
	ADD R1, R1, #1			;Move to next memory location
	ADD R5, R5, #-1			;Decrement loop counter
	BRp LOOP

JSR CALC_AVERAGE			;Calculate average after loop
JSR FIND_GRADE				;Determine letter grade
TRAP x25					;HALT

READ_SCORE
   ST R7, RS_RETURN
   ST R1, RS_R1
   ST R2, RS_R2
   ST R3, RS_R3
   ST R4, RS_R4
   AND R4, R4, #0

RS_LOOP
   TRAP x23
   LD R3, SENTINEL         ;SENTINEL = -44
   ADD R2, R0, R3       
   BRz RS_DONE             ;If user input = sentinel, branch.
   JSR VALIDATE_SCORE
   LD R3, ASCII_ZERO    
   ADD R0, R0, R3          ;ASCII conversion 

;Tenths place right
   ADD R3, R4, R4          ;R3 = 2R4
   ADD R3, R3, R3          ;R3 = 4R4
   ADD R3, R3, R3          ;R3 = 8R4
   ADD R4, R4, R4          ;R4 = 2R4
   ADD R4, R3, R4          ;R4 = 10R4

   ADD R4, R4, R0          ;R4 = R4 + new digit
   BR RS_LOOP

RS_DONE
   ADD R0, R4, #0
   LD R7, RS_RETURN
   LD R4, RS_R4
   LD R3, RS_R3
   LD R2, RS_R2
   LD R1, RS_R1
   RET
SENTINEL	.FILL #-44
ASCII_ZERO	.FILL #-48
RS_RETURN   .BLKW #1
RS_R1	.BLKW #1
RS_R2	.BLKW #1
RS_R3	.BLKW #1
RS_R4	.BLKW #1


;VALIDATE_SCORE subroutine checks if R0 has numbers (0-9) or sentinel character ","
VALIDATE_SCORE
   ST R7, VS_RETURN
   ST R0, VS_R0
   ST R1, VS_R1
   ST R2, VS_R2
   LD R1, ASCII_ZERO       ;R1 = -48
   ADD R2, R0, R1          ;Subtract ASCII_ZERO to check if input is less than 0 
   BRn INVALID
   LD R1, ASCII_NINE
   ADD R2, R0, R1          ;Subtract ASCII_NINE to check if input is greater than 9
   BRp INVALID
   LD R7, VS_RETURN
   LD R0, VS_R0
   LD R1, VS_R1
   LD R2, VS_R2
   RET
ASCII_NINE  .FILL #-57
VS_RETURN   .BLKW #1
VS_R0	.BLKW #1
VS_R1	.BLKW #1
VS_R2	.BLKW #1

INVALID
	LEA R0, ERRMSG
	TRAP x22
	BR RS_LOOP

UPDATE_MIN
	ST R7, UM_RET			;Save return address
	ST R1, UM_R1			;Save R1
	ST R2, UM_R2			;Save R2
	LD R2, MIN				;Load current min
	NOT R2, R2
	ADD R2, R2, #1			;Negate min (R2 = -MIN)
	ADD R2, R0, R2			;R2 = score - MIN
	BRzp UM_DONE			;If score >= MIN, no update
	ST R0, MIN				;Update MIN = score
UM_DONE
	LD R1, UM_R1			;Restore R1
	LD R2, UM_R2			;Restore R2
	LD R7, UM_RET			;Restore return address
	RET
UM_RET	.BLKW #1
UM_R1	.BLKW #1
UM_R2	.BLKW #1

UPDATE_MAX
	ST R7, UX_RET			;Save return address
	ST R1, UX_R1			;Save R1
	ST R2, UX_R2			;Save R2
	LD R2, MAX				;Load current max
	NOT R2, R2
	ADD R2, R2, #1			;Negate max (R2 = -MAX)
	ADD R2, R0, R2			;R2 = score - MAX
	BRnz UX_DONE			;If score <= MAX, no update
	ST R0, MAX				;Update MAX = score
UX_DONE
	LD R1, UX_R1			;Restore R1
	LD R2, UX_R2			;Restore R2
	LD R7, UX_RET			;Restore return address
	RET
UX_RET	.BLKW #1
UX_R1	.BLKW #1
UX_R2	.BLKW #1

UPDATE_SUM
	ST R7, US_RET			;Save return address
	ST R2, US_R2			;Save R2
	LD R2, SUM				;Load current sum
	ADD R2, R2, R0			;sum = sum + score
	ST R2, SUM				;Store updated sum
	LD R2, US_R2			;Restore R2
	LD R7, US_RET			;Restore return address
	RET
US_RET	.BLKW #1
US_R2	.BLKW #1

CALC_AVERAGE
	ST R7, CA_RET			;Save return address
	ST R2, CA_R2			;Save R2
	ST R3, CA_R3			;Save R3
	LD R2, SUM				;Load sum
	AND R3, R3, #0			;R3 = quotient (average)
CA_LOOP
	ADD R2, R2, #-5			;Subtract 5 from sum
	BRn CA_DONE				;If negative, done
	ADD R3, R3, #1			;Increment quotient
	BR CA_LOOP
CA_DONE
	ST R3, AVG				;Store average
	LD R2, CA_R2			;Restore R2
	LD R3, CA_R3			;Restore R3
	LD R7, CA_RET			;Restore return address
	RET
CA_RET	.BLKW #1
CA_R2	.BLKW #1
CA_R3	.BLKW #1

FIND_GRADE
	ST R7, FG_RET			;Save return address
	ST R2, FG_R2			;Save R2
	LD R0, AVG				;Load average
	LD R2, NEG90
	ADD R2, R0, R2			;average - 90
	BRzp GRADE_A
	LD R2, NEG80
	ADD R2, R0, R2			;average - 80
	BRzp GRADE_B
	LD R2, NEG70
	ADD R2, R0, R2			;average - 70
	BRzp GRADE_C
	LD R2, NEG60
	ADD R2, R0, R2			;average - 60
	BRzp GRADE_D
	BR GRADE_F
GRADE_A
	LEA R0, LETTER_A
	TRAP x22				;Print “A”
	BR FG_DONE
GRADE_B
	LEA R0, LETTER_B
	TRAP x22				;Print “B”
	BR FG_DONE
GRADE_C
	LEA R0, LETTER_C
	TRAP x22				;Print “C”
	BR FG_DONE
GRADE_D
	LEA R0, LETTER_D
	TRAP x22				;Print “D”
	BR FG_DONE
GRADE_F
	LEA R0, LETTER_F
	TRAP x22				;Print “F”
FG_DONE
	LD R2, FG_R2			;Restore R2
	LD R7, FG_RET			;Restore return address
	RET
FG_RET	.BLKW #1
FG_R2	.BLKW #1

SCORES   .BLKW #5
MIN      .BLKW #1
MAX      .BLKW #1
SUM      .BLKW #1
AVG      .BLKW #1
NEG100	 .FILL #-100
NEG90	 .FILL #-90
NEG80 	 .FILL #-80
NEG70 	 .FILL #-70
NEG60 	 .FILL #-60

; === STRINGS ===
ERRMSG	.STRINGZ "\nInvalid score. Enter 0-100: \n"
LETTER_A	.STRINGZ "\nGrade: A\n"
LETTER_B	.STRINGZ "\nGrade: B\n"
LETTER_C	.STRINGZ "\nGrade: C\n"
LETTER_D	.STRINGZ "\nGrade: D\n"
LETTER_F	.STRINGZ "\nGrade: F\n"

.END