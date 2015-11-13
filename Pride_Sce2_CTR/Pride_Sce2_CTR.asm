/*
 * Pride_Sce2_CTR.asm
 *
 *  Created: 2015/9/15 14:12:38
 *   Author: LuoPeng
 *
 * Time : 2015.9.25
 */ 
.EQU    PTEXT_NUM_BYTE = 16			; 128 bits is 16 bytes
.EQU	WHITEN_KEY0_NUM_BYTE = 8	; whiten key0 is 8 bytes
.EQU    KEYS_NUM_BYTE = 80			; round keys
.EQU	ENC_DEC_ROUNDS = 19
.EQU	COUNT_SIZE_BYTE = 8

#define ENCRYPT

#ifdef ENCRYPT
.def s0 = r0
.def s1 = r1
.def s2 = r2
.def s3 = r3
.def s4 = r4
.def s5 = r5
.def s6 = r6
.def s7 = r7

.def rk0 = r8
.def rk2 = r9
.def rk4 = r10
.def rk6 = r11
.def rk1 = r12
.def rk3 = r13
.def rk5 = r14
.def rk7 = r15

.def t0 = r12;
.def t1 = r13;
.def t2 = r14;
.def t3 = r15;

.def count0 = r16;
.def count1 = r17;
.def count2 = r18;
.def count3 = r19;
.def count4 = r20;
.def count5 = r21;
.def count6 = r22;
.def count7 = r23;

.def currentRound = r24;
.def currentBlock = r25;
#endif

	/*
	 * Subroutine: encrypt
	 * Function:   encyrpt the 128 bits of data
	 */
#ifdef ENCRYPT
encrypt:
	; start encyrption
	ldi r26, low(SRAM_COUNT);
	ldi r27, high(SRAM_COUNT);
	ld s0, x+ ;
	ld s1, x+ ;
	ld s2, x+ ;
	ld s3, x+ ;
	ld s4, x+ ;
	ld s5, x+ ;
	ld s6, x+ ;
	ld s7, x+ ;
	; store count+1 to SRAM_TEMP_COUNT
	movw count0, s0;
	movw count2, s2;
	movw count4, s4;
	movw count6, s6;
	inc count7;
/*	st x+, count0;
	st x+, count1;
	st x+, count2;
	st x+, count3;
	st x+, count4;
	st x+, count5;
	st x+, count6;
	st x+, count7;*/

	ldi currentBlock, 0;
	ldi r28, low(SRAM_PTEXT);
	ldi r29, high(SRAM_PTEXT);
blockAgain:
	; whitening key0
	ldi r30, low(whitenKeys<<1);
	ldi r31, high(whitenKeys<<1);
	lpm rk0, z+;
	lpm rk1, z+;
	lpm rk2, z+;
	lpm rk3, z+;
	lpm rk4, z+;
	lpm rk5, z+;
	lpm rk6, z+;
	lpm rk7, z+;
	; eor k0
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;
	
	clr currentRound; reset
	ldi r30, low(fixedKey<<1); stores the start address of keys
	ldi r31, high(fixedKey<<1);
	lpm rk0, z+;
	lpm rk2, z+;
	lpm rk4, z+;
	lpm rk6, z+;
	ldi r30, low(roundKeys<<1); stores the start address of keys
	ldi r31, high(roundKeys<<1);
encLoop:
	lpm rk1, z+;
	lpm rk3, z+;
	lpm rk5, z+;
	lpm rk7, z+;
	; eor round keys
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;
	; Substitution Layer
	movw t0, s0
	movw t2, s2
	and s0, s2
	eor s0, s4
	and s2, s4
	eor s2, s6
	and s1, s3
	eor s1, s5
	and s3, s5
	eor s3, s7
	movw s4, s0
	movw s6, s2
	and s4, s6
	eor s4, t0
	and s6, s4
	eor s6, t2
	and s5, s7
	eor s5, t1
	and s7, s5
	eor s7, t3

	cpi currentRound, ENC_DEC_ROUNDS;
	breq enclastRound;

	; State s0, s1, s2, s3, s4, s5, s6, s7
	; Temporary registers t0, t1, t2, t3
	; Linear Layer and Inverse Linear Layer: L0
	movw t0, s0 ; t1:t0 = s1:s0
	swap s0
	swap s1
	eor s0, s1
	eor t0, s0
	mov s1, t0
	eor s0, t1
	; Linear Layer: L1
	swap s3
	movw t0, s2 ; t1:t0 = s3:s2
	movw t2, s2 ; t3:t2 = s3:s2
	lsl t0
	rol t2
	lsr t1
	ror t3
	eor s2, t3
	mov t0, s2
	eor s2, t2
	eor s3, t0
	; Linear Layer: L2
	swap s4
	movw t0, s4 ; t1:t0 = s5:s4
	movw t2, s4 ; t3:t2 = s5:s4
	lsl t0
	rol t2
	lsr t1
	ror t3
	eor s4, t3
	mov t0, s4
	eor s4, t2
	eor s5, t0
	; Linear Layer and Inverse Linear Layer: L3
	movw t0, s6 ; t1:t0 = s7:s6
	swap s6
	swap s7
	eor s6, s7
	eor t1, s6
	mov s7, t1
	eor s6, t0

	inc currentRound;
	rjmp encLoop;
enclastRound:
	; whitening key2
	ldi r30, low(whitenKeys<<1);
	ldi r31, high(whitenKeys<<1);
	lpm rk0, z+;
	lpm rk1, z+;
	lpm rk2, z+;
	lpm rk3, z+;
	lpm rk4, z+;
	lpm rk5, z+;
	lpm rk6, z+;
	lpm rk7, z+;
	; eor k0
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;
	; load plain text
	ld rk0, y+;
	ld rk1, y+;
	ld rk2, y+;
	ld rk3, y+;
	ld rk4, y+;
	ld rk5, y+;
	ld rk6, y+;
	ld rk7, y+;
	; eor plain text
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;
	; move cipher text back to plain text
	st -y, s7;
	st -y, s6;
	st -y, s5;
	st -y, s4;
	st -y, s3;
	st -y, s2;
	st -y, s1;
	st -y, s0;
	adiw y, 8;
	; load count for the next round
	movw s0, count0;
	movw s2, count2;
	movw s4, count4;
	movw s6, count6;
/*	ldi r26, low(SRAM_TEMP_COUNT);
	ldi r27, high(SRAM_TEMP_COUNT);
	ld s0, x+ ;
	ld s1, x+ ;
	ld s2, x+ ;
	ld s3, x+ ;
	ld s4, x+ ;
	ld s5, x+ ;
	ld s6, x+ ;
	ld s7, x+ ;*/

	inc currentBlock
	cpi currentBlock, 2
	breq prideCTREnd;
	rjmp blockAgain;
prideCTREnd:
	ret;
#endif

; result of master key [0000000000000000 fedcba9876543210]
whitenKeys: .db $00, $00, $00, $00, $00, $00, $00, $00 ; whiten key0 and whiten key2
roundKeys: 
.db $9d, $3d, $a5, $d5, $5e, $e2, $f6, $9a
.db $1f, $87, $47, $5f, $e0, $2c, $98, $24
.db $a1, $d1, $e9, $e9, $62, $76, $3a, $ae
.db $23, $1b, $8b, $73, $e4, $c0, $dc, $38
.db $a5, $65, $2d, $fd, $66, $0a, $7e, $c2
.db $27, $af, $cf, $87, $e8, $54, $20, $4c
.db $a9, $f9, $71, $11, $6a, $9e, $c2, $d6
.db $2b, $43, $13, $9b, $ec, $e8, $64, $60
.db $ad, $8d, $b5, $25, $6e, $32, $06, $ea
.db $2f, $d7, $57, $af, $f0, $7c, $a8, $74 
fixedKey: .db $fe, $ba, $76, $32