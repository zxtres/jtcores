;   THIS FILE IS PART OF JTCORES.
;   JTCORES PROGRAM IS FREE SOFTWARE: YOU CAN REDISTRIBUTE IT AND/OR MODIFY
;   IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY
;   THE FREE SOFTWARE FOUNDATION, EITHER VERSION 3 OF THE LICENSE, OR
;   (AT YOUR OPTION) ANY LATER VERSION.
;
;   JTCORES PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL,
;   BUT WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
;   MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  SEE THE
;   GNU GENERAL PUBLIC LICENSE FOR MORE DETAILS.
;
;   YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE
;   ALONG WITH JTCORES.  IF NOT, SEE <HTTP://WWW.GNU.ORG/LICENSES/>.
;
;   AUTHOR: JOSE TEJADA GOMEZ. TWITTER: @TOPAPATE
;   VERSION: 1.0
;   DATE: 24-4-2023
;
;   FIRMWARE COMPATIBLE WITH ARKANOID 2

	RELAXED ON

CMD	EQU	R4
RDSEL  	EQU	R5
OLDCOIN	EQU	R6
CREDITS	EQU	R7

TOMAIN  MACRO   VAL
	MOV A,#VAL
	MOV STS,A	; Upper 4 bits can be read in the upper memory address
	MOV A,#VAL	; by the Z80
	OUT DBB,A
LOOP:   JOBF LOOP
	ENDM

WAITFF	MACRO		; wait for about 1ms
	MOV R1,#$FF
LOOP:	DJNZ R1,LOOP
	ENDM

READDB	MACRO
LOOP:	JNIBF LOOP
	IN A,DBB
	ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG 0
	; ABSOLUTE ADDRESSING UPTO ADDRESS 7 = Timer interrupt
	JMP START
	NOP
	RETR    ; ADDRESS 3 = IRQ service
	NOP
	NOP
	RETR
START:      ; ADDRESS 7
	MOV A,#0
	MOV PSW,A
	DIS I
	DIS TCNTI
	STOP TCNT
	CLR F0
	CLR F1


	TOMAIN $55
	; Clear the memory
	MOV R0,#$20
	MOV R1,#$60
	MOV A,#0
$$LOOP:	MOV @R0,A
	INC R0
	DJNZ R1,$$LOOP

	TOMAIN $AA

	; Get 4 values for the coin settings
	MOV R0,#$30
	MOV R1,#4
COINAGE:
	READDB
	CLR F1
	MOV @R0,A
	INC R0
	DJNZ R1,COINAGE

	; Prepare counter
	MOV A,#211
	MOV T,A
	STRT T
	TOMAIN $5A	; final initialization signal

L:  	JNIBF CKCMD
	IN A,DBB
	JF1 A1WR
	; check if command is 41
	; then add the data received
	MOV R0,A	; keep the data
	MOV A,CMD
	ADD A,#$BF	; -$41
	JNZ CKCMD	; it wasn't $41, ignore
	MOV A,CREDITS
	ADD A,R0
	MOV CREDITS,A
	JMP CKCMD	; continue
A1WR:
	CLR F1
	MOV CMD,A
	; If CMD=C1, set the read port selection to zero
	ADD A,#$3F	; -$C1
	JNZ CK15
	MOV RDSEL,#0
	JMP CKCMD
CK15:	; if CMD=15, decrement the credits by 1
	MOV A,CMD
	ADD A,#$EB	; -$15
	JNZ CKCMD
	MOV A,CREDITS
	JZ CKCMD
	DEC CREDITS
CKCMD:	CALL RDCOINS	; Update STS with coin information
	JOBF L		; do not output new data
	; if cmd is 41, return the number of credits
	MOV A,CMD
	ADD A,#$BF
	JNZ RDDATA
	MOV A,CREDITS
	OUT DBB,A
	JMP L
RDDATA:	MOV A,RDSEL
	JNZ RDBUT
	INC RDSEL
	MOV A,CREDITS
	OUT DBB,A
	JMP L
RDBUT:	; output buttons, all zero for now
	MOV A,#$00
	OUT DBB,A
	JMP L

RDCOINS:
	MOV A,T
	JZ UPDATE
	RET
UPDATE:
	MOV A,#0
	JNT0 T0C
	ORL A,#0x10
T0C:	JNT1 T1C
	ORL A,#0x20
T1C:	MOV R1,A	; save the new coins
	JZ NOCOINS
	XRL A,OLDCOIN
	JZ NOCOINS
	MOV A,CREDITS
	ADD A,#$F7
	JC NOCOINS	; Do not pass 9 credits
	INC CREDITS
	MOV A,R1
	MOV STS,A
	MOV OLDCOIN,A
	RET
NOCOINS:
	MOV A,R1
	MOV OLDCOIN,A
	MOV A,#0
	MOV STS,A	; No activity to report
	RET