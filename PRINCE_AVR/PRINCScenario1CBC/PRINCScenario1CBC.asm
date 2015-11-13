;
; Constants
;
.EQU    INITV_NUM_BYTE = 8
.EQU    PTEXT_NUM_BYTE = (8*16)
.EQU    KEY0_NUM_BYTE = 8
.EQU    KEY1_NUM_BYTE = 8
.EQU    KEYR_NUM_BYTE = (8*12)

#define KEYSCHEDULE
#define ENCRYPT
#define iKEYSCHEDULE
#define DECRYPT

; Original State:
;303, 302, 301, 300 : 203, 202, 201, 200 : 103, 102, 101, 100 : 003, 002, 001, 000
;313, 312, 311, 310 : 213, 212, 211, 210 : 113, 112, 111, 110 : 013, 012, 011, 010
;323, 322, 321, 320 : 223, 222, 221, 220 : 123, 122, 121, 120 : 023, 022, 021, 020
;333, 332, 331, 330 : 233, 232, 231, 230 : 133, 132, 131, 130 : 033, 032, 031, 030
;the 0-bit in the nibbles
;s200: 320 220 120 020 : 300 200 100 000
;s310: 330 230 130 030 : 310 210 110 010
;the 1-bit in the nibbles
;s201: 321 221 121 021 : 301 201 101 001
;s311: 331 231 131 031 : 311 211 111 011
;the 2-bit in the nibbles
;s202: 322 222 122 022 : 302 202 102 002
;s312: 332 232 132 032 : 312 212 112 012
;the 3-bit in the nibbles
;s203: 323 223 123 023 : 303 203 103 003
;s313: 333 233 133 033 : 313 213 113 013
.def s200 =r0
.def s310 =r1
.def s201 =r2
.def s311 =r3
.def s202 =r4
.def s312 =r5
.def s203 =r6
.def s313 =r7

.def t0 =r8
.def t1 =r9
.def t2 =r10
.def t3 =r11
.def t4 =r12
.def t5 =r13
.def t6 =r14
.def t7 =r15

.def m66 =r16 ; ldi m66, 0b01100110
.def m99 =r17 ; ldi m99, 0b10011001
.def mf0 =r18 ; ldi mf0, 0b11110000
.def m0f =r19 ; ldi m0f, 0b00001111

.def p0 =r20
.def p1 =r21

.def k0 =r8
.def k1 =r9
.def k2 =r10
.def k3 =r11
.def k4 =r12
.def k5 =r13
.def k6 =r14
.def k7 =r15

.def kt0 =r20
.def kt1 =r21

.def bn    =r22
.def bcnt  =r23

.def rrn   =r24
.def rcnt  =r25

.def XL =r26
.def XH =r27
.def YL =r28
.def YH =r29
.def ZL =r30
.def ZH =r31

;;;****************************************************************************
;;;
;;; load_init
;;;
.MACRO loadInitv
	ld  t0, X+
	ld  t1, X+
	ld  t2, X+
	ld  t3, X+
	ld  t4, X+
	ld  t5, X+
	ld  t6, X+
	ld  t7, X+
.ENDMACRO

;;;****************************************************************************
;;;
.MACRO loadPlain
	ld  kt0, X+
	eor t0, kt0

	ld  kt0, X+
	eor t1, kt0

	ld  kt0, X+
	eor t2, kt0

	ld  kt0, X+
	eor t3, kt0

	ld  kt0, X+
	eor t4, kt0

	ld  kt0, X+
	eor t5, kt0

	ld  kt0, X+
	eor t6, kt0

	ld  kt0, X+
	eor t7, kt0
.ENDMACRO

.MACRO storeCipher
	st  Y+, t0
	st  Y+, t1
	st  Y+, t2
	st  Y+, t3
	st  Y+, t4
	st  Y+, t5
	st  Y+, t6
	st  Y+, t7
.ENDMACRO

.MACRO loadCipher
	ld  t0, Y+
	ld  t1, Y+
	ld  t2, Y+
	ld  t3, Y+
	ld  t4, Y+
	ld  t5, Y+
	ld  t6, Y+
	ld  t7, Y+
.ENDMACRO

.MACRO storePlain
	ld kt0, X
	eor t0, kt0
	st X+, t0

	ld kt0, X
	eor t1, kt0
	st X+, t1

	ld kt0, X
	eor t2, kt0
	st X+, t2

	ld kt0, X
	eor t3, kt0
	st X+, t3

	ld kt0, X
	eor t4, kt0
	st X+, t4

	ld kt0, X
	eor t5, kt0
	st X+, t5

	ld kt0, X
	eor t6, kt0
	st X+, t6

	ld kt0, X
	eor t7, kt0
	st X+, t7
.ENDMACRO

.MACRO Reorder1Byte
	ror @0
	ror @1
	ror @0
	ror @2
	ror @0
	ror @3
	ror @0
	ror @4
.ENDMACRO

.MACRO Reorder1ByteOutput
	ror @1
	ror @0
	ror @2
	ror @0
	ror @3
	ror @0
	ror @4
	ror @0
.ENDMACRO

#if defined(ENCRYPT) || defined(DECRYPT)
ReorderInput:
	Reorder1Byte t1, s310, s311, s312, s313
	Reorder1Byte t1, s200, s201, s202, s203
	Reorder1Byte t3, s310, s311, s312, s313
	Reorder1Byte t3, s200, s201, s202, s203
	Reorder1Byte t5, s310, s311, s312, s313
	Reorder1Byte t5, s200, s201, s202, s203
	Reorder1Byte t7, s310, s311, s312, s313
	Reorder1Byte t7, s200, s201, s202, s203

	Reorder1Byte t0, s310, s311, s312, s313
	Reorder1Byte t0, s200, s201, s202, s203
	Reorder1Byte t2, s310, s311, s312, s313
	Reorder1Byte t2, s200, s201, s202, s203
	Reorder1Byte t4, s310, s311, s312, s313
	Reorder1Byte t4, s200, s201, s202, s203
	Reorder1Byte t6, s310, s311, s312, s313
	Reorder1Byte t6, s200, s201, s202, s203
ret
#endif

.MACRO ReorderOutput
	Reorder1ByteOutput t1, s310, s311, s312, s313
	Reorder1ByteOutput t1, s200, s201, s202, s203
	Reorder1ByteOutput t3, s310, s311, s312, s313
	Reorder1ByteOutput t3, s200, s201, s202, s203
	Reorder1ByteOutput t5, s310, s311, s312, s313
	Reorder1ByteOutput t5, s200, s201, s202, s203
	Reorder1ByteOutput t7, s310, s311, s312, s313
	Reorder1ByteOutput t7, s200, s201, s202, s203

	Reorder1ByteOutput t0, s310, s311, s312, s313
	Reorder1ByteOutput t0, s200, s201, s202, s203
	Reorder1ByteOutput t2, s310, s311, s312, s313
	Reorder1ByteOutput t2, s200, s201, s202, s203
	Reorder1ByteOutput t4, s310, s311, s312, s313
	Reorder1ByteOutput t4, s200, s201, s202, s203
	Reorder1ByteOutput t6, s310, s311, s312, s313
	Reorder1ByteOutput t6, s200, s201, s202, s203
.ENDMACRO

#if defined(KEYSCHEDULE) || defined(iKEYSCHEDULE)
loadYTok:
	ld k0,Y+
	ld k1,Y+
	ld k2,Y+
	ld k3,Y+
	ld k4,Y+
	ld k5,Y+
	ld k6,Y+
	ld k7,Y+
ret

storesToX:
	st X+, s200
	st X+, s310
	st X+, s201
	st X+, s311
	st X+, s202
	st X+, s312
	st X+, s203
	st X+, s313
ret
#endif

.MACRO istoresToX
	sbiw X, 8
	rcall storesToX
.ENDMACRO

.MACRO key_pre
	ldi YH, high(SRAM_KTEXT1)
	ldi YL, low(SRAM_KTEXT1)
	rcall loadYTok
	rcall ReorderInput
	rcall storesToX
.ENDMACRO

.MACRO key_rc
	lpm kt0, Z+				; 1 ins, 3 clocks
	eor @0, kt0
	st X+, @0
.ENDMACRO

#if defined(KEYSCHEDULE) || defined(iKEYSCHEDULE)
key_rc_oneRound:
	ldi YH, high(SRAM_KTEXTR)
	ldi YL, low(SRAM_KTEXTR)
	rcall loadYTok
	key_rc k0
	key_rc k1
	key_rc k2
	key_rc k3
	key_rc k4
	key_rc k5
	key_rc k6
	key_rc k7
ret
#endif

.MACRO key_01
	ld  kt0, Y+
	eor @0, kt0
.ENDMACRO

.MACRO key_rc_01
	ld  kt0, Y+
	eor @0, kt0
	lpm kt0, Z+
	eor @0, kt0
.ENDMACRO

.MACRO key_rc_01_Post
	ldi YH, high(SRAM_KTEXT0)
	ldi YL, low(SRAM_KTEXT0)
	rcall loadYTok

	bst k0, 0
	ror k7
	ror k6
	ror k5
	ror k4
	ror k3
	ror k2
	ror k1
	ror k0
	bld k7, 7

	eor kt0, kt0
	bst k7, 6
	bld kt0, 0
	eor k0, kt0

	rcall ReorderInput
	ldi YH, high(SRAM_KTEXTR)
	ldi YL, low(SRAM_KTEXTR)
	key_rc_01 s200
	key_rc_01 s310
	key_rc_01 s201
	key_rc_01 s311
	key_rc_01 s202
	key_rc_01 s312
	key_rc_01 s203
	key_rc_01 s313
	rcall storesToX

	ldi YH, high(SRAM_KTEXT0)
	ldi YL, low(SRAM_KTEXT0)
	rcall loadYTok
	rcall ReorderInput
	ldi YH, high(SRAM_KTEXTR)
	ldi YL, low(SRAM_KTEXTR)
	key_01 s200
	key_01 s310
	key_01 s201
	key_01 s311
	key_01 s202
	key_01 s312
	key_01 s203
	key_01 s313
	ldi XH, high(SRAM_KTEXTR)
	ldi XL, low(SRAM_KTEXTR)
	rcall storesToX
.ENDMACRO

#ifdef KEYSCHEDULE
keySchedule:
	ldi XH, high(SRAM_KTEXTR)
	ldi XL, low(SRAM_KTEXTR)
	key_pre
	ldi ZH, high(RC<<1)
	ldi ZL, low(RC<<1)
	rcall key_rc_oneRound ; 1
	rcall key_rc_oneRound ; 2
	rcall key_rc_oneRound ; 3
	rcall key_rc_oneRound ; 4
	rcall key_rc_oneRound ; 5
	rcall key_rc_oneRound ; 6
	rcall key_rc_oneRound ; 7
	rcall key_rc_oneRound ; 8
	rcall key_rc_oneRound ; 9
	rcall key_rc_oneRound ; 10
	key_rc_01_Post  ; 11
ret
#endif

.MACRO ikey_rc_oneRound
	sbiw X, 16
	rcall key_rc_oneRound
.ENDMACRO

.MACRO ikey_rc_01_Post
	ldi YH, high(SRAM_KTEXT0)
	ldi YL, low(SRAM_KTEXT0)
	rcall loadYTok
	rcall ReorderInput
	ldi YH, high(SRAM_KTEXTR)
	ldi YL, low(SRAM_KTEXTR)
	key_01 s200
	key_01 s310
	key_01 s201
	key_01 s311
	key_01 s202
	key_01 s312
	key_01 s203
	key_01 s313
	ldi XH, high(SRAM_KTEXTR+KEYR_NUM_BYTE-8)
	ldi XL, low(SRAM_KTEXTR+KEYR_NUM_BYTE-8)
	rcall storesToX

	ldi YH, high(SRAM_KTEXT0)
	ldi YL, low(SRAM_KTEXT0)
	rcall loadYTok

	bst k0, 0
	ror k7
	ror k6
	ror k5
	ror k4
	ror k3
	ror k2
	ror k1
	ror k0
	bld k7, 7

	eor kt0, kt0
	bst k7, 6
	bld kt0, 0
	eor k0, kt0

	rcall ReorderInput
	ldi YH, high(SRAM_KTEXTR)
	ldi YL, low(SRAM_KTEXTR)
	key_rc_01 s200
	key_rc_01 s310
	key_rc_01 s201
	key_rc_01 s311
	key_rc_01 s202
	key_rc_01 s312
	key_rc_01 s203
	key_rc_01 s313
	ldi XH, high(SRAM_KTEXTR)
	ldi XL, low(SRAM_KTEXTR)
	rcall storesToX
.ENDMACRO


#ifdef iKEYSCHEDULE
ikeySchedule:
	ldi XH, high(SRAM_KTEXTR)
	ldi XL, low(SRAM_KTEXTR)
	key_pre
	ldi XH, high(SRAM_KTEXTR+KEYR_NUM_BYTE)
	ldi XL, low(SRAM_KTEXTR+KEYR_NUM_BYTE)
	ldi ZH, high(RC<<1)
	ldi ZL, low(RC<<1)
	ikey_rc_oneRound ; 1
	ikey_rc_oneRound ; 2
	ikey_rc_oneRound ; 3
	ikey_rc_oneRound ; 4
	ikey_rc_oneRound ; 5
	ikey_rc_oneRound ; 6
	ikey_rc_oneRound ; 7
	ikey_rc_oneRound ; 8
	ikey_rc_oneRound ; 9
	ikey_rc_oneRound ; 10
	ikey_rc_01_Post
ret
#endif


.MACRO KeyXor
	ld   t0, Z+
	ld   t1, Z+
	eor  s200, t0
	eor  s310, t1
	ld   t0, Z+
	ld   t1, Z+
	eor  s201, t0
	eor  s311, t1
	ld   t0, Z+
	ld   t1, Z+
	eor  s202, t0
	eor  s312, t1
	ld   t0, Z+
	ld   t1, Z+
	eor  s203, t0
	eor  s313, t1
.ENDMACRO

.MACRO Sbox
	; a = s310:s200 = r1:r0
	; b = s311:s201 = r3:r2
	; c = s312:s202 = r5:r4
	; d = s313:s203 = r7:r6
	com  s201
	com  s311
	movw  t0, s201
	and  s201, s200
	and  s311, s310
	movw  t2, s202
	or   s202,  t0
	or   s312,  t1
	movw  t4, s202
	and  s202, s203
	and  s312, s313
	movw  t6, s202
	or   s202, s201
	or   s312, s311
	com   t6
	com   t7
	eor   t2,  t6
	eor   t3,  t7
	eor  s203,  t2
	eor  s313,  t3
	eor  s201,  t0
	eor  s311,  t1
	or   s201, s203
	or   s311, s313
	eor  s200, s202
	eor  s310, s312
	or   s203, s200
	or   s313, s310
	eor  s200,  t0
	eor  s310,  t1
	eor  s203,  t4
	eor  s313,  t5
	and   t6, s203
	and   t7, s313
	eor  s200,  t6
	eor  s310,  t7
	eor  s203,  t2
	eor  s313,  t3
.ENDMACRO

.MACRO iSbox
	; a = s310:s200 = r1:r0
	; b = s311:s201 = r3:r2
	; c = s312:s202 = r5:r4
	; d = s313:s203 = r7:r6
	movw t0, s200
	and  s200, s201
	and  s310, s311
	or   s200, s203
	or   s310, s313
	eor  s200, s202
	eor  s310, s312
	movw t2, s200
	com  s200
	com  s310
	or   t2, s201
	or   t3, s311
	eor  t2, s203
	eor  t3, s313
	or   s203, s200
	or   s313, s310
	movw t4, t2
	or   t2, t0
	or   t3, t1
	eor  t0, s203
	eor  t1, s313
	eor  s201, t2
	eor  s311, t3
	movw s202, s201
	eor  s201, t0
	eor  s311, t1
	movw s203, s201
	or   s203, s200
	or   s313, s310
	and  t0, s203
	and  t1, s313
	eor  t0, t4
	eor  t1, t5
	movw s203, t0
	and  t0, s202
	and  t1, s312
	eor  s200, t0
	eor  s310, t1
.ENDMACRO

;;;****************************************************************************
;;; M_XOR
.MACRO M_Bits0
	mov  p0, s200
	eor  p0, s310
	mov  p1, p0
	swap p1
	eor  p0, p1
	eor  s200, p0
	eor  s310, p0

	;s200: 320 220 120 020 : 300 200 100 000
	;s310: 330 230 130 030 : 310 210 110 010
	; |
	;s200: 310 200 100 010 : 330 220 120 030
	;s310: 300 230 130 000 : 320 210 110 020
	swap s200              ; s200 = 300 200 100 000 : 320 220 120 020
	movw t0, s200          ;   t1 = 330 230 130 030 : 310 210 110 010; t0 = 300 200 100 000 : 320 220 120 020
	and  s200, m66         ; s200 = xxx 200 100 xxx : xxx 220 120 xxx
	and  s310, m66         ; s310 = xxx 230 130 xxx : xxx 210 110 xxx
	swap t1                ;   t1 = 310 210 110 010 : 330 230 130 030
	and  t1, m99           ;   t1 = 310 xxx xxx 010 : 330 xxx xxx 030
	and  t0, m99           ;   t0 = 300 xxx xxx 000 : 320 xxx xxx 020
	eor  s200, t1          ; s200 = 310 200 100 010 : 330 220 120 030
	eor  s310, t0          ; s310 = 300 230 130 000 : 320 210 110 020
.ENDMACRO

.MACRO M_Bits1
	mov  p0, s201
	eor  p0, s311
	mov  p1, p0
	swap p1
	eor  p0, p1
	eor  s201, p0
	eor  s311, p0

	;s201: 321 221 121 021 : 301 201 101 001
	;s311: 331 231 131 031 : 311 211 111 011
	; |
	;s201: 301 231 131 001 : 321 211 111 021
	;s311: 331 221 121 031 : 311 201 101 011
	movw t0, s201          ;   t1 = 331 231 131 031 : 311 211 111 011; t0 = 321 221 121 021 : 301 201 101 001
	and  s201, m99         ; s201 = 321 xxx xxx 021 : 301 xxx xxx 001
	and  s311, m99         ; s311 = 331 xxx xxx 031 : 311 xxx xxx 011
	swap s201              ; s201 = 301 xxx xxx 001 : 321 xxx xxx 021
	and  t0, m66           ;   t0 = xxx 221 121 xxx : xxx 201 101 xxx
	and  t1, m66           ;   t1 = xxx 231 131 xxx : xxx 211 111 xxx
	eor  s201, t1          ; s201 = 301 231 131 001 : 321 211 111 021
	eor  s311, t0          ; s311 = 331 221 121 031 : 311 201 101 011
.ENDMACRO

.MACRO M_Bits2
	mov  p0, s202
	eor  p0, s312
	mov  p1, p0
	swap p1
	eor  p0, p1
	eor  s202, p0
	eor  s312, p0

	;s202: 322 222 122 022 : 302 202 102 002
	;s312: 332 232 132 032 : 312 212 112 012
	; |
	;s202: 332 222 122 032 : 312 202 102 012
	;s312: 322 212 112 022 : 302 232 132 002
	movw t0, s202          ;   t1 = 332 232 132 032 : 312 212 112 012; t0 = 322 222 122 022 : 302 202 102 002
	and  s202, m66         ; s202 = xxx 222 122 xxx : xxx 202 102 xxx
	and  s312, m66         ; s312 = xxx 232 132 xxx : xxx 212 112 xxx
	swap s312              ; s312 = xxx 212 112 xxx : xxx 232 132 xxx
	and  t0, m99           ;   t0 = 322 xxx xxx 022 : 302 xxx xxx 002
	and  t1, m99           ;   t1 = 332 xxx xxx 032 : 312 xxx xxx 012
	eor  s202, t1          ; s202 = 332 222 122 032 : 312 202 102 012
	eor  s312, t0          ; s312 = 322 212 112 022 : 302 232 132 002
.ENDMACRO

.MACRO M_Bits3
	mov  p0, s203
	eor  p0, s313
	mov  p1, p0
	swap p1
	eor  p0, p1
	eor  s203, p0
	eor  s313, p0

	;s203: 323 223 123 023 : 303 203 103 003
	;s313: 333 233 133 033 : 313 213 113 013
	; |
	;s203: 323 213 113 023 : 303 233 133 003
	;s313: 313 203 103 013 : 333 223 123 033
	swap s313              ; s313 = 313 213 113 013 : 333 233 133 033
	movw t0, s203          ;   t1 = 313 213 113 013 : 333 233 133 033; t0 = 323 223 123 023 : 303 203 103 003
	and  s203, m99         ; s203 = 323 xxx xxx 023 : 303 xxx xxx 003
	and  s313, m99         ; s313 = 313 xxx xxx 013 : 333 xxx xxx 033
	swap t0                ;   t0 = 303 203 103 003 : 323 223 123 023
	and  t1, m66           ;   t1 = xxx 213 113 xxx : xxx 233 133 xxx
	and  t0, m66           ;   t0 = xxx 203 103 xxx : xxx 223 123 xxx
	eor  s203, t1          ; s203 = 323 213 113 023 : 303 233 133 003
	eor  s313, t0          ; s313 = 313 203 103 013 : 333 223 123 033
.ENDMACRO

.MACRO M_XOR
	M_Bits0
	M_Bits1
	M_Bits2
	M_Bits3
.ENDMACRO

.MACRO SR_1bits
	movw t0, @0 ;320 220 120 020 300 200 100 000

	lsl  t0     ;120 020 300 200 100 000 xxx xxx
	lsl  t0
	bst  @0, 6  ;220
	bld  t0, 4  ;120 020 300 220 100 000 xxx xxx
	bst  @0, 7  ;320
	bld  t0, 5  ;120 020 320 220 100 000 xxx xxx
	and  @0, m0f;xxx xxx xxx xxx 300 200 100 000
	and  t0, mf0;120 020 320 220 xxx xxx xxx xxx
	eor  @0, t0 ;120 020 320 220 300 200 100 000

	lsl  @1     ;230 130 030 310 210 110 010 xxx
	bst  @1, 4  ;310
	bld  @1, 0  ;230 130 030 310 210 110 010 310
	lsr  t1     ;xxx 330 230 130 030 310 210 110
	bst  t1, 3  ;030
	bld  t1, 7  ;030 330 230 130 030 310 210 110
	and  @1, m0f;xxx xxx xxx xxx 210 110 010 310
	and  t1, mf0;030 330 230 130 xxx xxx xxx xxx
	eor  @1, t1 ;030 330 230 130 210 110 010 310
.ENDMACRO

.MACRO SR
	SR_1bits s200, s310
	SR_1bits s201, s311
	SR_1bits s202, s312
	SR_1bits s203, s313
.ENDMACRO

.MACRO iSR_1bits
	movw t0, @0

	lsl  t0
	lsl  t0
	bst  @0, 6
	bld  t0, 4
	bst  @0, 7
	bld  t0, 5
	and  @0, m0f
	and  t0, mf0
	eor  @0, t0

	bst  @1, 0
	lsr  @1
	bld  @1, 3
	bst  t1, 7
	lsl  t1
	bld  t1, 4
	and  @1, m0f
	and  t1, mf0
	eor  @1, t1
.ENDMACRO

.MACRO iSR
	iSR_1bits s200, s310
	iSR_1bits s201, s311
	iSR_1bits s202, s312
	iSR_1bits s203, s313
.ENDMACRO

.MACRO forward_round
	KeyXor
	Sbox
	M_XOR
	SR
.ENDMACRO

.MACRO middle_round
	KeyXor
	Sbox
	M_XOR
	iSbox
	KeyXor
.ENDMACRO

.MACRO invert_round
	iSR
	M_XOR
	iSbox
	KeyXor
.ENDMACRO

#if defined(ENCRYPT) || defined(DECRYPT)
crypt:
	rcall ReorderInput
forword_start:
	forward_round
	inc rcnt
	cpse rcnt, rrn
	rjmp forword_start
middle_start:
	middle_round
	ldi rrn, 5
	clr rcnt
invert_start:
	invert_round
	inc rcnt
	cpse rcnt, rrn
	rjmp invert_start
	ReorderOutput
ret
#endif

#ifdef ENCRYPT
encrypt:
	ldi m66, 0b01100110
	ldi m99, 0b10011001
	ldi mf0, 0b11110000
	ldi m0f, 0b00001111
	ldi bn, 16
	clr bcnt
	ldi XH, high(SRAM_INITV)
	ldi XL, low(SRAM_INITV)
	loadInitv
	ldi YH, high(SRAM_PTEXT)
	ldi YL, low(SRAM_PTEXT)
CBC16_encrypt_start:
    ldi rrn, 5
	ldi ZH, high(SRAM_KTEXTR)
	ldi ZL, low(SRAM_KTEXTR)
	clr rcnt
	loadPlain
	rcall crypt
	storeCipher
	inc bcnt
	cpse bcnt, bn
	rjmp CBC16_encrypt_start
CBC16_encrypt_end:
ret
#endif

#ifdef DECRYPT
decrypt:
	ldi m66, 0b01100110
	ldi m99, 0b10011001
	ldi mf0, 0b11110000
	ldi m0f, 0b00001111
	ldi bn, 16
	clr bcnt
	ldi XH, high(SRAM_INITV)
	ldi XL, low(SRAM_INITV)
	ldi YH, high(SRAM_PTEXT)
	ldi YL, low(SRAM_PTEXT)
CBC16_decrypt_start:
    ldi rrn, 5
	ldi ZH, high(SRAM_KTEXTR)
	ldi ZL, low(SRAM_KTEXTR)
	clr rcnt
	loadCipher
	rcall crypt
	storePlain
	inc bcnt
	cpse bcnt, bn
	rjmp CBC16_decrypt_start
CBC16_decrypt_end:
ret
#endif

#if defined(KEYSCHEDULE) || defined(iKEYSCHEDULE)
RC:
; Rearranged
.db $a9,  $8b,  $61,  $4f,  $31,  $50,  $04,  $c4
.db $35,  $a3,  $4f,  $60,  $10,  $28,  $38,  $a6
.db $44,  $10,  $87,  $a4,  $27,  $a3,  $56,  $ff
.db $33,  $1d,  $d6,  $51,  $78,  $58,  $60,  $82
.db $8a,  $60,  $3e,  $4c,  $f4,  $df,  $68,  $79
.db $fb,  $36,  $da,  $0c,  $cf,  $2f,  $b2,  $cf
.db $42,  $4b,  $32,  $11,  $43,  $a8,  $ba,  $34
.db $35,  $46,  $63,  $e4,  $1c,  $53,  $8c,  $49
.db $44,  $f5,  $ab,  $20,  $2b,  $d8,  $e2,  $10
.db $d8,  $dd,  $85,  $0f,  $0a,  $a0,  $de,  $72
.db $71,  $56,  $e4,  $40,  $3b,  $f0,  $da,  $b6
#endif
; Original arrangement
;.db $44, $73, $70, $03, $2E, $8A, $19, $13
;.db $D0, $31, $9F, $29, $22, $38, $09, $A4
;.db $89, $6C, $4E, $EC, $98, $FA, $2E, $08
;.db $77, $13, $D0, $38, $E6, $21, $28, $45
;.db $6C, $0C, $E9, $34, $CF, $66, $54, $BE
;.db $B1, $5C, $95, $FD, $78, $4F, $F8, $7E
;.db $AA, $43, $AC, $F1, $51, $08, $84, $85
;.db $54, $3C, $32, $25, $2F, $D3, $82, $C8
;.db $0D, $61, $E3, $E0, $95, $11, $A5, $64
;.db $99, $23, $0C, $CA, $99, $A3, $B5, $D3
;.db $DD, $50, $7C, $C9, $B7, $29, $AC, $C0


; ;******** R1
; k1 + k0 + RC0
; |
; S
; |
; M
; |
; SR
; 
; ;******** R2
; k1+RC1
; |
; S
; |
; M
; |
; SR
; .
; .
; .
; ;******** R5
; k1+RC4
; |
; S
; |
; M
; |
; SR
; 
; ;******** Rmiddle
; k1+RC5
; |
; S
; |
; M
; |
; iS
; |
; k1+RC6
; 
; 
; ;******** iR1
; iSR
; |
; M
; |
; iS
; |
; k1+RC7
; 
; 
; ;******** iR2
; iSR
; |
; M
; |
; iS
; |
; k1+RC8
; 
; ;******** iR3
; iSR
; |
; M
; |
; iS
; |
; k1+RC9
; 
; ;******** iR4
; iSR
; |
; M
; |
; iS
; |
; k1+RC10
; 
; ;******** iR5
; iSR
; |
; M
; |
; iS
; |
; k1+RC11+k0'
