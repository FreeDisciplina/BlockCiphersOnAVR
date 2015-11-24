/*
 * Speck_Sce1_EncDecWithKeySch.asm
 *
 *  Created: 2015/8/29 0:02:04
 *   Author: LuoPeng
 */ 

.EQU    INITV_NUM_BYTE = 8
.EQU    PTEXT_NUM_BYTE = 128
.EQU	MASTER_KEY_NUM_BYTE = 16
.EQU    KEYS_NUM_BYTE = 108
.EQU	KEY_SCHEDULE_ROUNDS = 26
.EQU	ENC_DEC_ROUNDS = 27
.EQU	BLOCK_SIZE = 16

#define KEYSCHEDULE
#define ENCRYPT
#define DECRYPT

.def temp = r22;
.def transferL = r23;
.def currentRound = r24;
.def currentBlock = r25;

	/*
	 * Subroutine: keyschedule
	 * Function:   compute the sub keys.
	 * RAM:        lRAM
	 *             keys
	 * Register:   [r0, r7] key schedule
	 *             r22 temp
	 *             r23 transferL
	 *             r24 currentRound
     *             r25 currentBlock
	 *             X the address of keys
	 *             Y the address of lRAM
	 *             Z the address of lRAM
	 */
#ifdef KEYSCHEDULE
keyschedule:
	; load k[0]
	ldi r26, low(SRAM_KEYS);
	ldi r27, high(SRAM_KEYS);
	ldi r28, low(SRAM_MASTER_KEY);
	ldi r29, high(SRAM_MASTER_KEY);
	ld temp, y+;
	st x+, temp;
	ld temp, y+;
	st x+, temp;
	ld temp, y+;
	st x+, temp;
	ld temp, y+;
	st x+, temp;
	ldi r26, low(SRAM_L);
	ldi r27, high(SRAM_L);
	clr currentRound;
loadL:
	ld temp, y+;
	st x+, temp;
	inc currentRound;
	cpi currentRound, 12;
	brne loadL

	; prepare for key schedule
	clr currentRound;
	clr r21; store the value of zero
	ldi r26, low(SRAM_KEYS);
	ldi r27, high(SRAM_KEYS);
subkey:	
	ldi r28, low(SRAM_L);
	ldi r29, high(SRAM_L);
	;[r3,r2,r1,r0] to store ki
	ld r0, x+;
	ld r1, x+;
	ld r2, x+;
	ld r3, x+;
	;[r7,r6,r5,r4] to store li
	ld r4, y+;
	ld r5, y+;
	ld r6, y+;
	ld r7, y+;
	; k(i)+S(-8)l(i)
	add r5, r0;
	adc r6, r1;
	adc r7, r2;
	adc r4, r3;
	; eor i
	eor r5, currentRound;
	; S3(ki)
	lsl r0;
	rol r1;
	rol r2;
	rol r3;
	adc r0, r21;
	lsl r0;
	rol r1;
	rol r2;
	rol r3;
	adc r0, r21;
	lsl r0;
	rol r1;
	rol r2;
	rol r3;
	adc r0, r21;
	; k(i+1)
	eor r0, r5;
	eor r1, r6;
	eor r2, r7;
	eor r3, r4;
	; store k(i+1)
	st x+, r0;
	st x+, r1;
	st x+, r2;
	st x+, r3;
	sbiw r26, 4;

	; update the lRAM, l[i] is useless.
	ldi r30, low(SRAM_L);
	ldi r31, high(SRAM_L);
	clr transferL;
L:
	ld temp, y+;
	st z+, temp;
	inc transferL;
	cpi transferL, 8;
	brne L;
	st z+, r5;
	st z+, r6;
	st z+, r7;
	st z+, r4;

	; loop control
	inc currentRound;
	cpi currentRound, KEY_SCHEDULE_ROUNDS; 27 may be wrong
	brne subkey;
	ret;
#endif

	/*
	 * Subroutine: encryption
	 * Function:   encyrpt the 128 bytes of data
	 * RAM:        sendData
	 *             keys
	 *             vector
	 * Register:   [r0, r7] plain text 
	 *             [r12, r15] round key
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
	; load k: [r15, r14, r13, r12], r12 is the lowest byte
	ld r12, y+;
	ld r13, y+;
	ld r14, y+;
	ld r15, y+;
	; x = S(8)( S(-8)(x) + y)
	add r5, r0; x1 = x1 + y0
	adc r6, r1; x2 = x2 + y1
	adc r7, r2; x3 = x3 + y2
	adc r4, r3; x0 = x0 + y3;
	; k = ( S(-8)(x) + y ) eor k
	eor r12, r5;
	eor r13, r6;
	eor r14, r7;
	eor r15, r4;
	; y = s(3)y
	lsl r0; loop 1
	rol r1;
	rol r2;
	rol r3;
	adc r0, r30;
	lsl r0; loop 2
	rol r1;
	rol r2;
	rol r3;
	adc r0, r30;
	lsl r0; loop 3
	rol r1;
	rol r2;
	rol r3;
	adc r0, r30;
	; y = S(3)(y) eor ( S(-8)(x) + y ) eor k
	eor r0, r12;
	eor r1, r13;
	eor r2, r14;
	eor r3, r15;
	; x = ( S(-8)(x) + y ) eor k
	movw r4, r12; r5:r4 = r13:r12
	movw r6, r14; r7:r6 = r15:r14
	
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
	jmp encAnotherBlock;
encAllEnd:
	ret;
#endif

	/*
	 * Subroutine: decryption
	 * Function:   decyrpt the 128 bytes of data
	 * RAM:        sendData
	 *             keys
	 *             vector
	 *             tempCipher. The cipher text will be overwritten during decryption. But he next round will use it.
	 *                         Therefore, the cipher text must be stored before decryption.
	 * Register:   [r0, r7] cipher text. From low byte to high.
	 *             [r8, r11] round key. From low byte to high.
	 *             [r16, r23] the vector or cipher text of last round. From low byte to high.
	 *             r24, currentRound
	 *             r25, currentBlock
	 *             X the address of data
	 *             Y the address of keys
	 *             Z the address of tempCipher
	 */
#ifdef DECRYPT
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

	; SRAM_INITV must be next and near to SRAM_KEYS in RAM
	ldi r28, low(SRAM_KEYS+KEYS_NUM_BYTE); the address of (the last byte keys + 1)
	ldi r29, high(SRAM_KEYS+KEYS_NUM_BYTE);
	;sbiw r28, 1; y is just the start address of keys + 108. So it does not need sub 1.
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
	; x = x eor y
	eor r4, r0;
	eor r5, r1;
	eor r6, r2;
	eor r7, r3;
	; x = S(-3)x
	lsr r7;
	ror r6;
	ror r5;
	bst r4, 0;
	ror r4;
	bld r7, 7;
	lsr r7;
	ror r6;
	ror r5;
	bst r4, 0;
	ror r4;
	bld r7, 7;
	lsr r7;
	ror r6;
	ror r5;
	bst r4, 0;
	ror r4;
	bld r7, 7;
	; y = x
	movw r0, r4;
	movw r2, r6;
	; x = k - x;
	sub r8, r4;
	sbc r9, r5;
	sbc r10, r6;
	sbc r11, r7;
	; x = S(8)k
	mov r4, r11;
	mov r5, r8;
	mov r6, r9;
	mov r7, r10;

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
	jmp decAnotherBlock;
decAllEnd:
	ret;
#endif
