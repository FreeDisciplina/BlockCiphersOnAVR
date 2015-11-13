
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


    .include "./Simon_Sce1_EncDecWithKeySch.asm"

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
	ldi XH, high(SRAM_INITV)
	ldi XL, low(SRAM_INITV)
	ldi r18, INITV_NUM_BYTE
INITV_LOOP:
	st X+, r18
	dec r18
	brbc 1, INITV_LOOP

	ldi 	XH, high(SRAM_PTEXT)
	ldi 	XL, low(SRAM_PTEXT)
	ldi		r18, PTEXT_NUM_BYTE
PTEXT_LOOP:
	st X+, r18
	dec r18
	brbc 1, PTEXT_LOOP

	ldi 	XH, high(SRAM_MASTER_KEY)
	ldi 	XL, low(SRAM_MASTER_KEY)
	ldi		r18, MASTER_KEY_NUM_BYTE
KEY_LOOP:
	st X+, r18
	dec r18
	brbc 1, KEY_LOOP

	sbi		PORTB,1		; portA,0 = high (trigger on port A0)
	nop
	nop
	nop
	nop
 	cbi		PORTB,1		; portA,0 = low

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

#ifdef KEYSCHEDULE
	rcall setConstC
	rcall keyschedule 
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
#ifdef ENCRYPT	
	rcall	encrypt		; encryption routine
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

#ifdef DECRYPT
	rcall   decrypt      ; encryption routine
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
	rcall	wait2
	rcall	wait2
	rcall	wait2


.DSEG
  SRAM_PTEXT: .BYTE PTEXT_NUM_BYTE				; the 16 blocks(each block has 8 bytes) of plaintext. For each block, the byte is from high to low.
  SRAM_MASTER_KEY: .BYTE MASTER_KEY_NUM_BYTE	; master keys
  SRAM_KEYS: .BYTE KEYS_NUM_BYTE				; the 44*4 bytes of round keys
  SRAM_INITV: .BYTE INITV_NUM_BYTE				; an initialization vector that is used in the first block(encryption and decryption)
  SRAM_TempCipher: .byte 8						; store the cipher text of last round. only used in decrtypion.
;******************** MAIN (END) *********************************