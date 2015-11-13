/*
 * Simon_Sce1_EncDecWithKeySch.asm
 *
 *  Created: 2015/8/24 10:27:28
 *   Author: LuoPeng
 */ 

.EQU    INITV_NUM_BYTE = 8
.EQU    PTEXT_NUM_BYTE = 128
.EQU	MASTER_KEY_NUM_BYTE = 16
.EQU    KEYS_NUM_BYTE = 160; 176-16
.EQU	KEY_SCHEDULE_ROUNDS = 40
.EQU	ENC_DEC_ROUNDS = 44
.EQU	BLOCK_SIZE = 16

#define KEYSCHEDULE
#define ENCRYPT
#define DECRYPT

.def temp = r17;
.def remain8 = r18;      currentRound % 8
.def currentZ = r19;     the current byte value of z, the 62 bits of z is stored in 8 bytes

.def constC0 = r20;      the lowest byte const value c
.def constC1 = r21;
.def constC2 = r22;
.def constC3 = r23;      the highest byte const value c

.def currentRound = r24;
.def currentBlock = r25; in CBC model, the blocks of plain text is 16(128 bytes).

setConstC:
	; the const value of c
	ldi constC0, 0xfc;
	ldi constC1, 0xff;
	ldi constC2, 0xff;
	ldi constC3, 0xff;
	ret;

	/*
	 * Subroutine: keyschedule
	 * Function:   compute the sub keys.
	 * Register:   [r2, r13] store data during the compute
	 *             [r18, r25] ramain8, currentZ, constC, currentRound, currentBlock
	 *             X stores the address of keys
	 *             Z stores the address of constZ
	 */
#if defined(KEYSCHEDULE)
keyschedule:
	; load master key
/*	ldi r26, low(SRAM_KEYS);
	ldi r27, high(SRAM_KEYS);
	ldi r28, low(SRAM_MASTER_KEY);
	ldi r29, high(SRAM_MASTER_KEY);
	clr currentRound;
loadMasterKey:
	ld temp, y+;
	st x+, temp;
	inc currentRound;
	cpi currentRound, MASTER_KEY_NUM_BYTE
	brne loadMasterKey;*/
	
	; prepare for the key schedule
	ldi r26, low(SRAM_MASTER_KEY);
	ldi r27, high(SRAM_MASTER_KEY);
/*	ldi r26, low(SRAM_KEYS);
	ldi r27, high(SRAM_KEYS);*/
	ldi r30, low(constZ<<1);
	ldi r31, high(constZ<<1);
	lpm currentZ, z+;
	clr remain8;
	clr currentRound; the current round number
keysExtend:
	; load k(i)
	ld r2, x+;
	ld r3, x+;
	ld r4, x+;
	ld r5, x+;
	; load k(i+1)
	ld r10, x+;
	ld r11, x+;
	ld r12, x+;
	ld r13, x+;
	; S(-3)k(i+3)
	adiw r26, 4; adiw rd, K ==== rd+1:rd <- rd+1:rd + K
	ld r6, x+;
	ld r7, x+;
	ld r8, x+;
	ld r9, x+;
	lsr r9;
	ror r8;
	ror r7;
	bst r6, 0;
	ror r6;
	bld r9, 7;
	lsr r9;
	ror r8;
	ror r7;
	bst r6, 0;
	ror r6;
	bld r9, 7;
	lsr r9;
	ror r8;
	ror r7;
	bst r6, 0;
	ror r6;
	bld r9, 7;
	;k(i+1) eor S(-3)k(i+3)
	eor r6, r10;
	eor r7, r11;
	eor r8, r12;
	eor r9, r13;
	; k(i) eor [k(i+1) eor S(-3)k(i+3)]
	eor r2, r6;
	eor r3, r7;
	eor r4, r8;
	eor r5, r9;
	; S(-1)[k(i+1) eor S(-3)k(i+3)]
	lsr r9;
	ror r8;
	ror r7;
	bst r6, 0;
	ror r6;
	bld r9, 7;
	; k(i) eor [k(i+1) eor S(-3)k(i+3)] eor S(-1)[k(i+1) eor S(-3)k(i+3)]
	eor r2, r6;
	eor r3, r7;
	eor r4, r8;
	eor r5, r9;
	; k(i) eor [k(i+1) eor S(-3)k(i+3)] eor S(-1)[k(i+1) eor S(-3)k(i+3)] eor c eor z(i)
	; the lowest bit of const c is 0, so the result of "c eor z(i)" is setting the lowest bit of const c to z(i).
	;bld currentZ, 7;
	;bst constC0, 0;
	bst currentZ, 7;
	bld constC0, 0;
	lsl currentZ;
	eor r2, constC0;
	eor r3, constC1;
	eor r4, constC2;
	eor r5, constC3;
	;k(i+4), is just [r3,r2,r1,r0]
	st x+, r2;
	st x+, r3;
	st x+, r4;
	st x+, r5;
	; set x to the position of k(i+1),should sub 16(from k(i+5) to k(i+1)) not 12
	sbiw r26, 16; sbiw rd, K ==== rd+1:rd <- rd+1:rd - K
	;have finished?
	inc currentRound;
	inc remain8;
	cpi remain8, 8;
	breq nextByteZ; if remain8 = 8, the next byte of constZ should be load
	rjmp keysExtend;
nextByteZ:
	clr remain8; start with 0 again
	lpm currentZ, z+;
	cpi currentRound, KEY_SCHEDULE_ROUNDS;
	breq scheEnd;
	rjmp keysExtend;
scheEnd:
	ret;
#endif

	/*
	 * Subroutine: encrypt
	 * Function:   encyrpt the 128 bytes of data
	 * RAM:        sendData
	 *             keys
	 *             vector
	 * Register:   [r0, r7] plain text 
	 *             [r8, r11] round key
	 *             [r12, r15] for temp use during the encryption
	 *             [r16, r23] the vector or cipher text of last round  
	 *             r24, currentRound
	 *             r25, currentBlock
	 *             X the address of data
	 *             Y the address of keys
	 *             r30 store 0
	 */
#ifdef ENCRYPT
encrypt:
	; load the vector to [r23-r16]
	ldi r26, low(SRAM_INITV);
	ldi r27, high(SRAM_INITV);
	ld r16, x+;
	ld r17, x+;
	ld r18, x+;
	ld r19, x+;
	ld r20, x+;
	ld r21, x+;
	ld r22, x+;
	ld r23, x+;

	; start encyrption
	clr currentBlock;
	ldi r26, low(SRAM_PTEXT); x stores the current address of data
	ldi r27, high(SRAM_PTEXT);
encAnotherBlock:
	clr currentRound; reset
	ldi r28, low(SRAM_KEYS); stores the start address of keys
	ldi r29, high(SRAM_KEYS);
	; load the plaintext from RAM to registers [r7,...,r0], X = [r7, r6, r5, r4], Y = [r3, r2, r1, r0]
	ld r7, x+ ;
	ld r6, x+ ;
	ld r5, x+ ;
	ld r4, x+ ;
	ld r3, x+ ;
	ld r2, x+ ;
	ld r1, x+ ;
	ld r0, x+ ;
	; eor with the init vector or the cipher text of last block
	eor r0, r16
	eor r1, r17
	eor r2, r18
	eor r3, r19
	eor r4, r20
	eor r5, r21
	eor r6, r22
	eor r7, r23

	clr r30;
encLoop:
	; store the 4 bytes of sub key to K = [r11, r10, r9, r8]
	ld r8, y+;  r8 is the lowes byte
 	ld r9, y+;
	ld r10, y+;
	ld r11, y+; r11 is the highest byte
	; k = k eor y
	eor r8, r0;
	eor r9, r1;
	eor r10, r2;
	eor r11, r3 ;
	; move x to y 
	movw r0, r4; the index must be even ( R1:R0 = R5:R4)
	movw r2, r6; ( R3:R2 = R7:R6 )
	; rotate x by left with 1 bit
	lsl r4;      logical shift left: bit 0 is cleared, bit 7 is loaded into the C flag of the SREG
	rol r5;      rotate left through carry: the C flag in shifted into bit 0, bit 7 is shifted into the C flag
	rol r6;
	rol r7;
	adc r4, r30;
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
	adc r4, r30;
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
	cpi currentRound, ENC_DEC_ROUNDS;
	brne encLoop;
	; one block has been encrypted. move cipher text to tempCipher
	movw r16, r0;
	movw r18, r2;
	movw r20, r4;
	movw r22, r6;
	; move cipher text back to plain text
	st -x, r0;
	st -x, r1;
	st -x, r2;
	st -x, r3;
	st -x, r4;
	st -x, r5;
	st -x, r6;
	st -x, r7;
	; x = x + 8, let x point the start address of next block
	adiw r26, 8; adiw rd, K ==== rd+1:rd <- rd+1:rd + K
	inc currentBlock;
	cpi currentBlock, BLOCK_SIZE;
	breq encAllEnd;
	rjmp encAnotherBlock;
encAllEnd:
	ret;
#endif

	/*
	 * Subroutine: decrypt
	 * Function:   decyrpt the 128 bytes of data
	 * RAM:        sendData
	 *             keys
	 *             vector
	 *             tempCipher. The cipher text will be overwritten during decryption. But he next round will use it.
	 *                         Therefore, the cipher text must be stored before decryption.
	 * Register:   [r0, r7] cipher text. From low byte to high.
	 *             [r8, r11] round key. From low byte to high.
	 *             [r12, r15] for temp use during the decryption. From low byte to high.
	 *             [r16, r23] the vector or cipher text of last round. From low byte to high.
	 *             r24, currentRound
	 *             r25, currentBlock
	 *             X the address of data
	 *             Y the address of keys
	 *             Z the address of tempCipher, and r30 is also used to store 0
	 */
#ifdef	DECRYPT
decrypt:
	; load the vector to register[r16-r23]
	ldi r26, low(SRAM_INITV);
	ldi r27, high(SRAM_INITV);
	ld r16, x+;
	ld r17, x+;
	ld r18, x+;
	ld r19, x+;
	ld r20, x+;
	ld r21, x+;
	ld r22, x+;
	ld r23, x+;

	; start decyrption
	clr currentBlock;
	ldi r26, low(SRAM_PTEXT); x stores the current address of data
	ldi r27, high(SRAM_PTEXT);
decAnotherBlock:
	clr currentRound; reset
	; load the ciphertext from RAM to registers [r7,...,r0], X = [r7, r6, r5, r4], Y = [r3, r2, r1, r0]
	ld r7, x+ ;
	ld r6, x+ ;
	ld r5, x+ ;
	ld r4, x+ ;
	ld r3, x+ ;
	ld r2, x+ ;
	ld r1, x+ ;
	ld r0, x+ ;
	; store the ciphertext of last round
	ldi r30, low(SRAM_TempCipher); x stores the current address of data
	ldi r31, high(SRAM_TempCipher);
	st z+, r0;
	st z+, r1;
	st z+, r2;
	st z+, r3;
	st z+, r4;
	st z+, r5;
	st z+, r6;
	st z+, r7;

	ldi r28, low(SRAM_KEYS+KEYS_NUM_BYTE); the address of keys
	ldi r29, high(SRAM_KEYS+KEYS_NUM_BYTE);
	;sbiw r28, 1; y is just the start address of keys + 176. So it does not need sub 1.

	clr r30; r30 is useless this time
decLoop:
	; get the sub key k
	ld r11, -y ; store the 4 bytes of sub key to K = [r11, r10, r9, r8]
 	ld r10, -y ;
	ld r9, -y ;
	ld r8, -y ;
	; k = k eor x
	eor r8, r4;
	eor r9, r5;
	eor r10, r6;
	eor r11, r7;
	; move y to x
	movw r4, r0;
	movw r6, r2;
	; rotate y by left with 1 bit
	lsl r0; logical shift left: bit 0 is cleared, bit 7 is loaded into the C flag of the SREG
	rol r1; rotate left through carry: the C flag in shifted into bit 0, bit 7 is shifted into the C flag
	rol r2;
	rol r3;
	adc r0, r30;
	; move y to t, t stands for [r15, r14, r13, r12]
	movw r12, r0;
	movw r14, r2;
	; t & S8(y)
	and r12, r7;
	and r13, r4;
	and r14, r5;
	and r15, r6;
	; y = S2(y)
	lsl r0;
	rol r1;
	rol r2;
	rol r3;
	adc r0, r30;
	; y = y eor t
	eor r0, r12;
	eor r1, r13;
	eor r2, r14;
	eor r3, r15;
	; y = y eor k
	eor r0, r8;
	eor r1, r9;
	eor r2, r10;
	eor r3, r11;

	inc currentRound;
	cpi currentRound, ENC_DEC_ROUNDS;
	brne decLoop;
	
	; eor with the init vector or the cipher text of last block
	eor r0, r16
	eor r1, r17
	eor r2, r18
	eor r3, r19
	eor r4, r20
	eor r5, r21
	eor r6, r22
	eor r7, r23
	; move cipher text back to plain text
	st -x, r0;
	st -x, r1;
	st -x, r2;
	st -x, r3;
	st -x, r4;
	st -x, r5;
	st -x, r6;
	st -x, r7;
	; x = x + 8, let x point the start address of next block
	adiw r26, 8;K adiw rd, K ==== rd+1:rd <- rd+1:rd + K
	; reset vector: move from tempCipher to vector
	ldi r30, low(SRAM_TempCipher);
	ldi r31, high(SRAM_TempCipher);
	ld r16, z+;
	ld r17, z+;
	ld r18, z+;
	ld r19, z+;
	ld r20, z+;
	ld r21, z+;
	ld r22, z+;
	ld r23, z+;
	inc currentBlock;
	cpi currentBlock, BLOCK_SIZE;
	breq decAllEnd;
	rjmp decAnotherBlock;
decAllEnd:
	ret; the end point is here or not makes much difference.
#endif

; 1101 1011, 1010 1100, 0110 0101, 1110 0000, 0100 1000, 1010 0111, 0011 0100, 0011 1100
constZ:
.db 0xdb, 0xac, 0x65, 0xe0, 0x48, 0xa7, 0x34, 0x3c ; 