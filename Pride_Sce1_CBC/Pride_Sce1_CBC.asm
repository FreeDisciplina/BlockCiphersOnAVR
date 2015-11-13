/*
 * Pride_Sce1_CBC.asm
 *
 *  Created: 2015/9/15 9:46:19
 *   Author: LuoPeng
 *
 * Time : 2015.9.25
 *		  1. Use 16 bytes to store master keys because they can not be changed even after the key schedule.
 */ 
.EQU	ONE_BLOCK_BYTE = 8			; one block has 8 bytes
.EQU    PTEXT_NUM_BYTE = 128		; CBC mode has 128 bytes of plain text
.EQU	MASTER_KEY_NUM_BYTE = 16	; master key is 16 bytes
.EQU	KEY0_NUM_BYTE = 8			; whiten key0 and key2 are 8 bytes
.EQU	FIXED_KEYS_NUM_BYTE = 4		; in round keys, there are 4 bytes that are fixed
.EQU    KEYS_NUM_BYTE = 80			; for each round keys, 4 bytes is different, so only 80 bytes is needed for 20 rounds
.EQU	KEY_SCHEDULE_ROUNDS = 21	; round number begin with 1 not 0, so the loop control value should be 21 not 20
.EQU	ENC_DEC_ROUNDS = 19			; 20 rounds in total, the last round is different
.EQU	BLOCK_SIZE = 16				; 128 bytes is 16 block

#define KEYSCHEDULE
#define ENCRYPT
#define DECRYPT

#ifdef KEYSCHEDULE
.def k1_1 = r4;
.def k1_3 = r5;
.def k1_5 = r6;
.def k1_7 = r7;
; const values, only used in key schedule
.def const193 = r16;
.def const165 = r17;
.def const81  = r18;
.def const197 = r19;

.def temp = r20;
#endif

#if defined(ENCRYPT) || defined(DECRYPT)
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

.def t0 = r12
.def t1 = r13
.def t2 = r14
.def t3 = r15

.def initv0 = r16		; initv  is only used before encryption (store init value) and after encryption(store cipher text for next round)
.def initv1 = r17		; but t0-t3 is only used in encryption, so register have no conflict.
.def initv2 = r18
.def initv3 = r19
.def initv4 = r20
.def initv5 = r21
.def initv6 = r22
.def initv7 = r23
#endif

.def currentRound = r24;
.def currentBlock = r25;

	/*
	 * Subroutine:	keyschedule
	 * Function:	compute the sub keys.
	 * Register:	[r0-r1] store the result of mul
	 *				[r4-r7] store k1_1(index 1 byte), k1_3(index 3 byte), k1_5(index 5 byte), k1_7(index 7 byte) of master key k1.
	 *				[r16-r19] const values
	 *				r20 temp use
	 *				r24 currentRound
	 *				r25 currentBlock
	 *				X
	 *				Y
	 */
#if defined(KEYSCHEDULE)
keyschedule:
	; set the fixed four bytes
	ldi r26, low(SRAM_MASTER_KEYS);
	ldi r27, high(SRAM_MASTER_KEYS);
	adiw r26, 8;
	ldi r28, low(SRAM_KEYS_FIXED_FOUR);
	ldi r29, high(SRAM_KEYS_FIXED_FOUR);
	clr currentRound;
fixedBytes:
	ld temp, x+;
	adiw x, 1;
	st y+, temp;
	inc currentRound;
	cpi currentRound, FIXED_KEYS_NUM_BYTE;
	brne fixedBytes;
	; set the unfixed four bytes
	sbiw r26, 8;
	ldi r28, low(SRAM_KEYS);
	ldi r29, high(SRAM_KEYS);
	clr currentRound;
unFixedBytes:
	adiw x, 1;
	ld temp, x+;
	st y+, temp;
	inc currentRound;
	cpi currentRound, FIXED_KEYS_NUM_BYTE;
	brne unFixedBytes;
	
	; compute round keys
	ldi const193, 193;
	ldi const165, 165;
	ldi const81, 81;
	ldi const197, 197;
	ldi r26, low(SRAM_KEYS);
	ldi r27, high(SRAM_KEYS);
	ld k1_1, x+;
	ld k1_3, x+;
	ld k1_5, x+;
	ld k1_7, x+;
	sbiw x, 4;
	ldi currentRound, 1;
keysExtend:
	mul const193, currentRound;
	add r0, k1_1;
	st x+, r0;
	mul const165, currentRound;
	add r0, k1_3;
	st x+, r0;
	mul const81, currentRound;
	add r0, k1_5;
	st x+, r0;
	mul const197, currentRound;
	add r0, k1_7;
	st x+, r0;
	inc currentRound;
	cpi currentRound, KEY_SCHEDULE_ROUNDS;
	brne keysExtend;
	ret;
#endif

	/*
	 * Subroutine:	encrypt
	 * Function:	encyrpt the 128 bytes of data
	 * Register:	[r0-r7]:	used as [s0-s7] (store plain text)
	 *				[r8-r15]:	used as [rk0-rk7](store whiten key0, round keys and whiten key2)
	 *				[r16-r23]:	used as [initv0-initv7] (store initv), as [t0-t3] (temp use in encryption)
	 *				r24 currentRound
	 *				r25 currentBlock
	 *				X
	 *				Y
	 */
#ifdef ENCRYPT
encrypt:
	; load initv
	ldi r26, low(SRAM_INITV);
	ldi r27, high(SRAM_INITV);
	ld initv0, x+;
	ld initv1, x+;
	ld initv2, x+;
	ld initv3, x+;
	ld initv4, x+;
	ld initv5, x+;
	ld initv6, x+;
	ld initv7, x+;
	; encrypt every block
	clr currentBlock;
	ldi r26, low(SRAM_PTEXT);
	ldi r27, high(SRAM_PTEXT);
encAnotherBlock:
	ld s0, x+ ;
	ld s1, x+ ;
	ld s2, x+ ;
	ld s3, x+ ;
	ld s4, x+ ;
	ld s5, x+ ;
	ld s6, x+ ;
	ld s7, x+ ;
	; eor initv16
	eor s0, initv0;
	eor s1, initv1;
	eor s2, initv2;
	eor s3, initv3;
	eor s4, initv4;
	eor s5, initv5;
	eor s6, initv6;
	eor s7, initv7;
	; whitening key0
	ldi r28, low(SRAM_MASTER_KEYS); x stores the current address of data
	ldi r29, high(SRAM_MASTER_KEYS);
	ld rk0, y+;
	ld rk1, y+;
	ld rk2, y+;
	ld rk3, y+;
	ld rk4, y+;
	ld rk5, y+;
	ld rk6, y+;
	ld rk7, y+;
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
	ldi r28, low(SRAM_KEYS_FIXED_FOUR);
	ldi r29, high(SRAM_KEYS_FIXED_FOUR);
	ld rk0, y+;
	ld rk2, y+;
	ld rk4, y+;
	ld rk6, y+;
	ldi r28, low(SRAM_KEYS);
	ldi r29, high(SRAM_KEYS);
encLoop:
	ld rk1, y+;
	ld rk3, y+;
	ld rk5, y+;
	ld rk7, y+;
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
	;cpi currentRound, ENC_DEC_ROUNDS;
	;breq enclastRound;
	rjmp encLoop;
enclastRound:
	/*ld rk1, y+;
	ld rk3, y+;
	ld rk5, y+;
	ld rk7, y+;
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
	eor s7, t3*/
	; whitening key2
	ldi r28, low(SRAM_MASTER_KEYS);
	ldi r29, high(SRAM_MASTER_KEYS);
	ld rk0, y+;
	ld rk1, y+;
	ld rk2, y+;
	ld rk3, y+;
	ld rk4, y+;
	ld rk5, y+;
	ld rk6, y+;
	ld rk7, y+;
	; eor k0
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;
	; move cipher to initv
	movw initv0, s0;
	movw initv2, s2;
	movw initv4, s4;
	movw initv6, s6;
	; move cipher text back to plain text
	st -x, s7;
	st -x, s6;
	st -x, s5;
	st -x, s4;
	st -x, s3;
	st -x, s2;
	st -x, s1;
	st -x, s0;
	; block control
	adiw r26, 8;
	inc currentBlock;
	cpi currentBlock, BLOCK_SIZE;
	breq encAllEnd;
	rjmp encAnotherBlock;
encAllEnd:
	ret;
#endif

	/*
	 * Subroutine:	decrypt
	 * Function:	decrypt 128 bytes of cipher text
	 * Register:	[r0-r7]:	used as [s0-s7] (store cipher text)
	 *				[r8-r15]:	used as [rk0-rk7](store whiten key0, round keys and whiten key2)
	 *				[r16-r23]:	used as [initv0-initv7] (store initv), as [t0-t3] (temp use in decryption)
	 *				r24 currentRound
	 *				r25 currentBlock
	 *				X
	 *				Y
	 */
#ifdef DECRYPT
decrypt:
	; load initv
	ldi r26, low(SRAM_INITV);
	ldi r27, high(SRAM_INITV);
	ld initv0, x+;
	ld initv1, x+;
	ld initv2, x+;
	ld initv3, x+;
	ld initv4, x+;
	ld initv5, x+;
	ld initv6, x+;
	ld initv7, x+;
	; store initv to ONE_BLOCK_BYTE
/*	st x+, initv0;
	st x+, initv1;
	st x+, initv2;
	st x+, initv3;
	st x+, initv4;
	st x+, initv5;
	st x+, initv6;
	st x+, initv7;*/

	clr currentBlock;
	ldi r26, low(SRAM_PTEXT);
	ldi r27, high(SRAM_PTEXT);
decAnotherBlock:
	ld s0, x+ ;
	ld s1, x+ ;
	ld s2, x+ ;
	ld s3, x+ ;
	ld s4, x+ ;
	ld s5, x+ ;
	ld s6, x+ ;
	ld s7, x+ ;
	; store the ciphertext of last round
	ldi r30, low(SRAM_TEMP_CIPHE);
	ldi r31, high(SRAM_TEMP_CIPHE);
	st z+, s0;
	st z+, s1;
	st z+, s2;
	st z+, s3;
	st z+, s4;
	st z+, s5;
	st z+, s6;
	st z+, s7;
	; whitening key2
	ldi r28, low(SRAM_MASTER_KEYS);
	ldi r29, high(SRAM_MASTER_KEYS);
	ld rk0, y+;
	ld rk1, y+;
	ld rk2, y+;
	ld rk3, y+;
	ld rk4, y+;
	ld rk5, y+;
	ld rk6, y+;
	ld rk7, y+;
	; eor k0
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;

	;the first round in decryption
	; Substitution Layer
/*	movw t0, s0
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
	eor s7, t3*/
	
	ldi r28, low(SRAM_KEYS_FIXED_FOUR); stores the start address of keys
	ldi r29, high(SRAM_KEYS_FIXED_FOUR);
	ld rk0, y+;
	ld rk2, y+;
	ld rk4, y+;
	ld rk6, y+;
	ldi r28, low(SRAM_KEYS + KEYS_NUM_BYTE); stores the start address of keys
	ldi r29, high(SRAM_KEYS + KEYS_NUM_BYTE);
/*	ld rk7, -y;
	ld rk5, -y;
	ld rk3, -y;
	ld rk1, -y;
	; eor round keys
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;*/

	clr currentRound;
decLoop:
	;the first round in decryption
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
	; eor k
	ld rk7, -y;
	ld rk5, -y;
	ld rk3, -y;
	ld rk1, -y;
	; eor round keys
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;

	cpi currentRound, ENC_DEC_ROUNDS;
	breq declastRound;

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
	; Inverse Linear Layer: L1
	movw t0, s2 ; t1:t0 = s3:s2
	movw t2, s2 ; t3:t2 = s3:s2
	lsr t0
	ror t2
	lsr t1
	ror t3
	eor t3, t2
	eor s3, t3
	swap s3
	mov s2, t3
	lsr t3
	ror s2
	eor s2, t2
	; Inverse Linear Layer: L2
	movw t0, s4 ; t1:t0 = s5:s4
	movw t2, s4 ; t3:t2 = s5:s4
	lsr t0
	ror t2
	lsr t1
	ror t3
	eor t3, t2
	eor s5, t3
	mov s4, t3
	lsr t3
	ror s4
	eor s4, t2
	swap s4
	; Linear Layer and Inverse Linear Layer: L3
	movw t0, s6 ; t1:t0 = s7:s6
	swap s6
	swap s7
	eor s6, s7
	eor t1, s6
	mov s7, t1
	eor s6, t0
	; Substitution Layer
/*	movw t0, s0
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
	; eor k
	ld rk7, -y;
	ld rk5, -y;
	ld rk3, -y;
	ld rk1, -y;
	; eor round keys
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;*/

	inc currentRound;
	/*cpi currentRound, ENC_DEC_ROUNDS;
	breq declastRound;*/
	rjmp decLoop;
declastRound:
	; whitening key0
	ldi r28, low(SRAM_MASTER_KEYS); x stores the current address of data
	ldi r29, high(SRAM_MASTER_KEYS);
	ld rk0, y+;
	ld rk1, y+;
	ld rk2, y+;
	ld rk3, y+;
	ld rk4, y+;
	ld rk5, y+;
	ld rk6, y+;
	ld rk7, y+;
	; eor k0
	eor s0, rk0;
	eor s1, rk1;
	eor s2, rk2;
	eor s3, rk3;
	eor s4, rk4;
	eor s5, rk5;
	eor s6, rk6;
	eor s7, rk7;
	; eor initv
/*	ldi r28, low(SRAM_TEMP_INITV);
	ldi r29, high(SRAM_TEMP_INITV);
	ld initv0, y+;
	ld initv1, y+;
	ld initv2, y+;
	ld initv3, y+;
	ld initv4, y+;
	ld initv5, y+;
	ld initv6, y+;
	ld initv7, y+;*/
	eor s0, initv0;
	eor s1, initv1;
	eor s2, initv2;
	eor s3, initv3;
	eor s4, initv4;
	eor s5, initv5;
	eor s6, initv6;
	eor s7, initv7;
	; move cipher text back to plain text
	st -x, s7;
	st -x, s6;
	st -x, s5;
	st -x, s4;
	st -x, s3;
	st -x, s2;
	st -x, s1;
	st -x, s0;
	adiw x, 8;
	; fresh initv
	ldi r30, low(SRAM_TEMP_CIPHE);
	ldi r31, high(SRAM_TEMP_CIPHE);
	ld initv0, z+;
	ld initv1, z+;
	ld initv2, z+;
	ld initv3, z+;
	ld initv4, z+;
	ld initv5, z+;
	ld initv6, z+;
	ld initv7, z+;
/*	st -y, initv7;
	st -y, initv6;
	st -y, initv5;
	st -y, initv4;
	st -y, initv3;
	st -y, initv2;
	st -y, initv1;
	st -y, initv0;*/
	; block control
	inc currentBlock;
	cpi currentBlock, BLOCK_SIZE;
	breq decAllEnd;
	rjmp decAnotherBlock;
decAllEnd:
	ret;
#endif
