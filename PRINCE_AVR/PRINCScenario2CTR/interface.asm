
.ORG 0x0000
; global interrupt disable
	cli
; initialize stack
	ldi		r31,HIGH(RAMEND)
	out		SPH,r31
	ldi		r31,LOW(RAMEND)
	out		SPL,r31

; initialize trigger B1
  	ldi		r16, 0b11	; portB,1 = output (triggers)
  	out		DDRB, r16

	rjmp	main


;******************* INCLUDE FILES *******************************
; include encryption algorithm
    .include "./PRINCScenario2CTR.asm"

.CSEG

;******************** Q ELEC FUNCTIONS (START) *********************
; wait : ret + 0xFF * (5*nop + 1*dec + 1*brbc)
wait:
	ldi		r16, 0xFF	;r16=FF
w_loop:
	nop
	nop
	nop
	nop
	nop
	dec		r16			; r16=r16-1
	brbc	1,w_loop	; branch sur loop si Z=0, c¨¤s si r16 != 0
	ret					; return from subroutine


; wait2 : r17 * wait (to be set inside) + some instructions
wait2:
	ldi		r17, 0xFF	;
w_loop2:
	rcall	wait
	dec		r17			; r17=r17-1
	brbc	1,w_loop2	; branch sur loop2 si Z=0, c¨¤s si r17 != 0
	ret					; return from subroutine
;******************** Q ELEC FUNCTIONS (END) *********************


;******************** MAIN (START) *******************************
main:
	ldi XH, high(SRAM_COUNT)
	ldi XL, low(SRAM_COUNT)
	ldi r18, COUNTER_BYTE
COUNTER_LOOP:
	st X+, r18
	dec r18
	brbc 1, COUNTER_LOOP
	
	ldi 	XH, high(SRAM_PTEXT)
	ldi 	XL, low(SRAM_PTEXT)
	ldi		r18, PTEXT_NUM_BYTE
PTEXT_LOOP:
	st X+, r18
	dec r18
	brbc 1, PTEXT_LOOP

	sbi		PORTB,1		; portA,0 = high (trigger on port A0)
	nop
	nop
	nop
	nop
 	cbi		PORTB,1		; portA,0 = low
	nop
	nop
	nop

#ifdef ENCRYPT
	rcall	Encrypt		; encryption routine
#endif
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	sbi		PORTB,0		; portA,0 = high (trigger on port A0)
	nop
	nop
	nop
	nop
 	cbi		PORTB,0		; portA,0 = low

	;make a pause
	rcall	wait2
	rcall	wait2
;	rcall	wait2
;	rcall	wait2
;	rcall	wait2

; All zero master key XOR reordered round constant
key:
.db $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00
.db $99,  $bb,  $aa,  $88,  $11,  $ff,  $66,  $44,  $11,  $00,  $33,  $55,  $44,  $44,  $00,  $cc
.db $55,  $33,  $33,  $aa,  $ff,  $00,  $44,  $66,  $00,  $88,  $11,  $22,  $88,  $66,  $33,  $aa
.db $44,  $00,  $44,  $11,  $77,  $44,  $88,  $aa,  $77,  $33,  $22,  $aa,  $66,  $ff,  $55,  $ff
.db $33,  $dd,  $33,  $11,  $66,  $11,  $dd,  $55,  $88,  $88,  $77,  $55,  $00,  $22,  $66,  $88
.db $aa,  $00,  $88,  $66,  $ee,  $cc,  $33,  $44,  $44,  $ff,  $ff,  $dd,  $88,  $99,  $66,  $77
.db $bb,  $66,  $ff,  $33,  $aa,  $cc,  $dd,  $00,  $ff,  $ff,  $cc,  $22,  $22,  $ff,  $bb,  $cc
.db $22,  $bb,  $44,  $44,  $22,  $11,  $33,  $11,  $33,  $88,  $44,  $aa,  $aa,  $44,  $bb,  $33
.db $55,  $66,  $33,  $44,  $33,  $44,  $66,  $ee,  $cc,  $33,  $11,  $55,  $cc,  $99,  $88,  $44
.db $44,  $55,  $44,  $ff,  $bb,  $00,  $aa,  $22,  $bb,  $88,  $22,  $dd,  $22,  $00,  $ee,  $11
.db $88,  $dd,  $dd,  $dd,  $55,  $ff,  $88,  $00,  $aa,  $00,  $00,  $aa,  $ee,  $22,  $dd,  $77
.db $11,  $66,  $77,  $55,  $44,  $00,  $ee,  $44,  $bb,  $00,  $33,  $ff,  $aa,  $66,  $dd,  $bb

.DSEG
  SRAM_COUNT: .BYTE COUNT_NUM_BYTE
  SRAM_PTEXT: .BYTE PTEXT_NUM_BYTE

;******************** MAIN (END) *********************************


