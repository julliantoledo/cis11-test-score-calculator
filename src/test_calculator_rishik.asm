.ORIG x3000

   LD R6, STACK_BASE       ;Initialize stack pointer
  
   LEA R1, SCORES          ;R1 points to first score
   AND R5, R5, #0
   ADD R5, R5, #5          ;R5 = 5 scores to process

INPUT_LOOP
   LEA R0, PROMPT          ;Load input prompt
   TRAP x22                ;Print prompt
  
   JSR READ_INPUT          ;Read multi-digit number into R0
  
   JSR VALIDATE_SCORE      ;Validate score range 0-100
   ADD R2, R2, #0          ;Check validation flag
   BRp INPUT_LOOP          ;If invalid, re-prompt
  
   STR R0, R1, #0          ;Store score in memory
   ADD R1, R1, #1          ;Move to next memory location
   ADD R5, R5, #-1         ;Decrement counter
   BRp INPUT_LOOP

   LEA R1, SCORES          ;Reset pointer to start
   LDR R0, R1, #0          ;Load score1
   ST R0, MIN              ;min = score1
   ST R0, MAX              ;max = score1
   AND R6, R6, #0          ;Clear R6
   ST R0, SUM              ;sum = score1

   AND R5, R5, #0
   ADD R5, R5, #4          ;Loop for remaining 4 scores
  
LOOP
   ADD R1, R1, #1          ;Move to next score
   LDR R0, R1, #0          ;Load current score
   JSR UPDATE_MIN          ;Check and update minimum
   JSR UPDATE_MAX          ;Check and update maximum
   JSR UPDATE_SUM          ;Add to running sum
   ADD R5, R5, #-1         ;Decrement loop counter
   BRp LOOP

   JSR CALC_AVERAGE        ;Calculate average

   LEA R0, TXT_MIN
   TRAP x22                ;Print "Minimum Score: "
   LD R0, MIN
   JSR PRINT_NUM           ;Print min value

   LEA R0, TXT_MAX
   TRAP x22                ;Print "Maximum Score: "
   LD R0, MAX
   JSR PRINT_NUM           ;Print max value

   LEA R0, TXT_AVG
   TRAP x22                ;Print "Average Score: "
   LD R0, AVG
   JSR PRINT_NUM           ;Print average value

   LEA R0, TXT_GRD
   TRAP x22                ;Print "Letter Grade: "
   JSR FIND_GRADE          ;Determine and print letter grade

   TRAP x25                ;HALT

; === READ_INPUT ===
; Reads multi-digit ASCII input, returns integer in R0
READ_INPUT
   ADD R6, R6, #-1         ;Push R7 to stack
   STR R7, R6, #0
   ADD R6, R6, #-1         ;Push R1 to stack
   STR R1, R6, #0
  
   AND R1, R1, #0          ;R1 = accumulated value

RI_LOOP
   TRAP x20                ;GETC: read character
   LD R2, NEG_ENTER        ;Check for Enter key
   ADD R2, R0, R2
   BRz RI_DONE             ;If Enter, done reading
  
   TRAP x21                ;Echo character to screen
  
   LD R2, NEG_ASCII
   ADD R2, R0, R2          ;Convert ASCII to digit

   ADD R3, R1, #0          ;R3 = R1
   ADD R1, R1, R1          ;x2
   ADD R1, R1, R1          ;x4
   ADD R1, R1, R3          ;x5
   ADD R1, R1, R1          ;x10

   ADD R1, R1, R2          ;Add new digit
   BR RI_LOOP

RI_DONE
   LEA R0, NEWLINE
   TRAP x22                ;Print newline
   ADD R0, R1, #0          ;Move result to R0

   LDR R1, R6, #0          ;Pop R1
   ADD R6, R6, #1
   LDR R7, R6, #0          ;Pop R7
   ADD R6, R6, #1
   RET

; === VALIDATE_SCORE ===
; Checks 0 <= R0 <= 100, sets R2=1 if invalid
VALIDATE_SCORE
   ADD R6, R6, #-1         ;Push R7 to stack
   STR R7, R6, #0
  
   AND R2, R2, #0          ;R2 = 0 (valid)
   ADD R0, R0, #0
   BRn INVALID             ;If negative, invalid
  
   LD R3, NEGHUNDRED
   ADD R3, R0, R3          ;score - 100
   BRp INVALID             ;If > 100, invalid
   BR VS_DONE
  
INVALID
   LEA R0, ERRMSG
   TRAP x22                ;Print error message
   ADD R2, R2, #1          ;Set invalid flag

VS_DONE
   LDR R7, R6, #0          ;Pop R7
   ADD R6, R6, #1
   RET

; === UPDATE_MIN ===
; If score < MIN, update MIN
UPDATE_MIN
   LD R2, MIN              ;Load current min
   NOT R2, R2
   ADD R2, R2, #1          ;Negate min
   ADD R2, R0, R2          ;score - MIN
   BRzp UM_DONE            ;If score >= MIN, skip
   ST R0, MIN              ;Update MIN = score
UM_DONE
   RET

; === UPDATE_MAX ===
; If score > MAX, update MAX
UPDATE_MAX
   LD R2, MAX              ;Load current max
   NOT R2, R2
   ADD R2, R2, #1          ;Negate max
   ADD R2, R0, R2          ;score - MAX
   BRnz UX_DONE            ;If score <= MAX, skip
   ST R0, MAX              ;Update MAX = score
UX_DONE
   RET

; === UPDATE_SUM ===
; Add current score to running sum
UPDATE_SUM
   LD R2, SUM              ;Load current sum
   ADD R2, R2, R0          ;sum = sum + score
   ST R2, SUM              ;Store updated sum
   RET

; === CALC_AVERAGE ===
; Divide SUM by 5 using repeated subtraction
CALC_AVERAGE
   LD R2, SUM              ;Load sum
   AND R3, R3, #0          ;R3 = quotient
CA_LOOP
   ADD R2, R2, #-5         ;Subtract 5 from sum
   BRn CA_DONE             ;If negative, done
   ADD R3, R3, #1          ;Increment quotient
   BR CA_LOOP
CA_DONE
   ST R3, AVG              ;Store average
   RET

; === PRINT_NUM ===
; Prints integer in R0 as ASCII digits
PRINT_NUM
   ADD R6, R6, #-1         ;Push R7 to stack
   STR R7, R6, #0
  
   LD R3, NEGHUNDRED
   ADD R3, R0, R3          ;Check if score = 100
   BRnz PN_LESS
   LEA R0, STR_HUNDRED
   TRAP x22                ;Print "100"
   BR PN_DONE

PN_LESS
   AND R2, R2, #0          ;R2 = tens counter
PN_TENS
   ADD R0, R0, #-10        ;Subtract 10
   BRn PN_ONES             ;If negative, done with tens
   ADD R2, R2, #1          ;Increment tens counter
   BR PN_TENS

PN_ONES
   ADD R1, R0, #10         ;R1 = ones digit
   LD R3, ASCII_BASE

   ADD R2, R2, #0          ;Check tens digit
   BRz PN_PRINT_ONES       ;If 0, skip tens
   ADD R0, R2, R3          ;Convert tens to ASCII
   TRAP x21                ;Print tens digit

PN_PRINT_ONES
   ADD R0, R1, R3          ;Convert ones to ASCII
   TRAP x21                ;Print ones digit
   LEA R0, NEWLINE
   TRAP x22                ;Print newline

PN_DONE
   LDR R7, R6, #0          ;Pop R7
   ADD R6, R6, #1
   RET

; === FIND_GRADE ===
; Compare average to grade boundaries, print letter
FIND_GRADE
   ADD R6, R6, #-1         ;Push R7 to stack
   STR R7, R6, #0
  
   LD R0, AVG              ;Load average
   LD R2, NEGNINETY
   ADD R2, R0, R2          ;average - 90
   BRzp GRADE_A
   LD R2, NEGEIGHTY
   ADD R2, R0, R2          ;average - 80
   BRzp GRADE_B
   LD R2, NEGSEVENTY
   ADD R2, R0, R2          ;average - 70
   BRzp GRADE_C
   LD R2, NEGSIXTY
   ADD R2, R0, R2          ;average - 60
   BRzp GRADE_D
   BR GRADE_F
GRADE_A
   LEA R0, LETTER_A
   BR FG_DISPLAY
GRADE_B
   LEA R0, LETTER_B
   BR FG_DISPLAY
GRADE_C
   LEA R0, LETTER_C
   BR FG_DISPLAY
GRADE_D
   LEA R0, LETTER_D
   BR FG_DISPLAY
GRADE_F
   LEA R0, LETTER_F
FG_DISPLAY
   TRAP x22                ;Print grade
   LDR R7, R6, #0          ;Pop R7
   ADD R6, R6, #1
   RET

; === MEMORY LAYOUT ===
STACK_BASE  .FILL x4000     ;Stack pointer starting address
SCORES      .BLKW #5
MIN         .BLKW #1
MAX         .BLKW #1
SUM         .BLKW #1
AVG         .BLKW #1

; === CONSTANTS ===
NEGHUNDRED  .FILL #-100
NEGNINETY   .FILL #-90
NEGEIGHTY   .FILL #-80
NEGSEVENTY  .FILL #-70
NEGSIXTY    .FILL #-60
NEG_ENTER   .FILL #-10     ;Enter key (x0A)
NEG_ASCII   .FILL #-48     ;ASCII '0' offset
ASCII_BASE  .FILL #48      ;ASCII '0' base

; === STRINGS ===
PROMPT      .STRINGZ "Enter Test Score (0-100): "
ERRMSG      .STRINGZ "Invalid input bounds. Retry.\n"
TXT_MIN     .STRINGZ "Minimum Score: "
TXT_MAX     .STRINGZ "Maximum Score: "
TXT_AVG     .STRINGZ "Average Score: "
TXT_GRD     .STRINGZ "Letter Grade: "
STR_HUNDRED .STRINGZ "100\n"
NEWLINE     .STRINGZ "\n"
LETTER_A    .STRINGZ "A\n"
LETTER_B    .STRINGZ "B\n"
LETTER_C    .STRINGZ "C\n"
LETTER_D    .STRINGZ "D\n"
LETTER_F    .STRINGZ "F\n"

.END
