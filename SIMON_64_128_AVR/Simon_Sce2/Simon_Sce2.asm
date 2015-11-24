/*
 * Simon_Sce2.asm
 *
 * Encrypt 128 bits of data in CTR mode.
 * 1.No nonce.
 * 2.Counter and data are not stored in flash. There are just initialized in RAM with the same function of the paper.
 * 
 * Data In RAM:   sendData: the data needs to be encrypted 
 *                count:    the counter in CTR mode
 * Data In Flash: keys:     the round keys.( No master key and key schedule is required)
 *
 *  Created: 2015/8/28 18:03:51
 *   Author: LuoPeng
 */ 

 .EQU	PTEXT_NUM_BYTE = 16;
 .EQU	COUNT_NUM_BYTE = 8;
 .EQU	ENC_ROUNDS = 44;

 #define ENCRYPT

 .def temp = r22
 .def zero = r23;;
 .def currentRound = r24;
 .def currentBlock = r25;


	/*
	 * Subroutine: encryption
	 * Function:   
	 * Regester:   
	 * 
	 */
 #ifdef ENCRYPT
 encrypt:
	; load the counter
	ldi r26, low(SRAM_COUNT);
	ldi r27, high(SRAM_COUNT);
	ld r7, x+ ; the highest byte
	ld r6, x+ ;
	ld r5, x+ ;
	ld r4, x+ ;
	ld r3, x+ ;
	ld r2, x+ ;
	ld r1, x+ ;
	ld r0, x+ ; the lowest byte

	; store counter
	movw r16, r0;
	movw r18, r2;
	movw r20, r4;
	movw r22, r6;
	; counter increase
	inc r16;
/*	adc r17, zero;
	adc r18, zero;
	adc r19, zero;
	adc r20, zero;
	adc r21, zero;
	adc r22, zero;
	adc r23, zero;*/
	clr currentBlock;
	clr zero;
	; load the plain text
	ldi r26, low(SRAM_PTEXT);
	ldi r27, high(SRAM_PTEXT);
blocks:
	; encrypt (nonce eor counter) X = [r7, r6, r5, r4], Y = [r3, r2, r1, r0]
	ldi r30, low(keys<<1);
	ldi r31, high(keys<<1);
	clr currentRound;
encStart:
	; store the 4 bytes of sub key to K = [r11, r10, r9, r8]
	lpm r8, z+;  the lowest byte
 	lpm r9, z+;
	lpm r10, z+;
	lpm r11, z+; the highest byte
	; k = k eor y
	eor r8, r0;
	eor r9, r1;
	eor r10, r2;
	eor r11, r3 ;
	; move x to y 
	movw r0, r4; the index must be even ( R1:R0 = R5:R4)
	movw r2, r6; ( R3:R2 : R7:R6 )
	; rotate x by left with 1 bit
	lsl r4; logical shift left: bit 0 is cleared, bit 7 is loaded into the C flag of the SREG
	rol r5; rotate left through carry: the C flag in shifted into bit 0, bit 7 is shifted into the C flag
	rol r6;
	rol r7;
	adc r4, zero;
	; move x to t, t stands for [r15, r14, r13, r12]
	movw r12, r4;
	movw r14, r6;
	; t & S8(y)
	and r12, r3;
	and r13, r0;
	and r14, r1;
	and r15, r2;
	; x = S2(x)
	lsl r4;
	rol r5;
	rol r6;
	rol r7;
	adc r4, zero;
	; x = x eor t
	eor r4, r12;
	eor r5, r13;
	eor r6, r14;
	eor r7, r15;
	; x = x eor k
	eor r4, r8;
	eor r5, r9;
	eor r6, r10;
	eor r7, r11;
	inc currentRound;
	cpi currentRound, ENC_ROUNDS;
	brne encStart;
	ld r15, x+; the highest byte
	ld r14, x+;
	ld r13, x+;
	ld r12, x+;
	ld r11, x+;
	ld r10, x+;
	ld r9, x+;
	ld r8, x+;
	; eor
	eor r7, r15;
	eor r6, r14;
	eor r5, r13;
	eor r4, r12;
	eor r3, r11;
	eor r2, r10;
	eor r1, r9;
	eor r0, r8;
	; store the cipher text
	st -x, r0;
	st -x, r1;
	st -x, r2;
	st -x, r3;
	st -x, r4;
	st -x, r5;
	st -x, r6;
	st -x, r7;

	inc currentBlock;
	cpi currentBlock, 2;
	breq encEnd;
	adiw r26, 8;
	; load counter
	movw r0, r16;
	movw r2, r18;
	movw r4, r20;
	movw r6, r22;
	rjmp blocks;
encEnd:
	ret;
#endif

keys: 
.db $00, $01, $02, $03, $08, $09, $0a, $0b, $10, $11, $12, $13, $18, $19, $1a, $1b 
.db $c3, $11, $a0, $70, $49, $ec, $70, $b7, $35, $e8, $e3, $57, $42, $bc, $97, $d3 
.db $1f, $f8, $dc, $94, $18, $5f, $4b, $bf, $b9, $ab, $5d, $8e, $63, $a8, $f4, $db 
.db $fc, $28, $0c, $cd, $11, $99, $b6, $5c, $a5, $12, $f1, $79, $63, $58, $20, $77
.db $12, $0c, $88, $99, $58, $7c, $e9, $1c, $45, $21, $ed, $c8, $b8, $db, $00, $b8
.db $56, $27, $6a, $e8, $dd, $d4, $06, $7c, $0a, $df, $52, $ab, $a8, $66, $7f, $24
.db $a6, $7c, $58, $53, $f1, $13, $5c, $d2, $4b, $b6, $83, $45, $0d, $96, $9c, $7d
.db $f3, $c2, $bf, $ef, $13, $85, $ed, $89, $4e, $fc, $8d, $30, $36, $2a, $1a, $bf
.db $70, $9d, $49, $e1, $ff, $d2, $e4, $4c, $ef, $eb, $b7, $32, $c1, $05, $75, $c4
.db $e8, $29, $e9, $d0, $b9, $84, $e4, $8f, $ee, $4b, $05, $42, $e2, $ba, $77, $af
.db $02, $9c, $19, $18, $1c, $3f, $9e, $71, $93, $f7, $1c, $0c, $96, $46, $df, $15