;
; Constants
;
.EQU    COUNTER_BYTE = 8
.EQU    COUNT_NUM_BYTE = (8)
.EQU    PTEXT_NUM_BYTE = (8*2)

#define ENCRYPT
#define Fixorder
;#define Reorder

; Original State:
;303, 302, 301, 300 : 203, 202, 201, 200 : 103, 102, 101, 100 : 003, 002, 001, 000
;313, 312, 311, 310 : 213, 212, 211, 210 : 113, 112, 111, 110 : 013, 012, 011, 010
;323, 322, 321, 320 : 223, 222, 221, 220 : 123, 122, 121, 120 : 023, 022, 021, 020
;333, 332, 331, 330 : 233, 232, 231, 230 : 133, 132, 131, 130 : 033, 032, 031, 030
;the 0-bit in the nibbles
;s00: 300 200 100 000 : 300 200 100 000
;s10: 310 210 110 010 : 310 210 110 010
;s20: 320 220 120 020 : 320 220 120 020
;s30: 330 230 130 030 : 330 230 130 030
;the 1-bit in the nibbles
;s01: 301 201 101 001 : 301 201 101 001
;s11: 311 211 111 011 : 311 211 111 011
;s21: 321 221 121 021 : 321 221 121 021
;s31: 331 231 131 031 : 331 231 131 031
;the 2-bit in the nibbles
;s02: 302 202 102 002 : 302 202 102 002
;s12: 312 212 112 012 : 312 212 112 012
;s22: 322 222 122 022 : 322 222 122 022
;s32: 332 232 132 032 : 332 232 132 032
;the 3-bit in the nibbles
;s03: 303 203 103 003 : 303 203 103 003
;s13: 313 213 113 013 : 313 213 113 013
;s23: 323 223 123 023 : 323 223 123 023
;s33: 333 233 133 033 : 333 233 133 033
.def s00 =r0
.def s10 =r1
.def s20 =r2
.def s30 =r3
.def s01 =r4
.def s11 =r5
.def s21 =r6
.def s31 =r7
.def s02 =r8
.def s12 =r9
.def s22 =r10
.def s32 =r11
.def s03 =r12
.def s13 =r13
.def s23 =r14
.def s33 =r15

.def t0 =r16
.def t1 =r17
.def t2 =r18
.def t3 =r19
.def t4 =r20
.def t5 =r21
.def t6 =r22
.def t7 =r23

.def k0 =r16
.def k1 =r17
.def k2 =r18
.def k3 =r19
.def k4 =r20
.def k5 =r21
.def k6 =r22
.def k7 =r23

.def m0f =r24 ; ldi m0f, 0b00001111
.def mf0 =r25 ; ldi mf0, 0b11110000

.def kt0 =r0
.def kt1 =r1

.def m66 =r24 ; ldi m66, 0b01100110
.def m99 =r25 ; ldi m99, 0b10011001

.def rrn  =r22
.def rcnt =r26

.def XL =r26
.def XH =r27
.def YL =r28
.def YH =r29
.def ZL =r30
.def ZH =r31

.def tmp =r30

;;;****************************************************************************
;;;

#ifdef Reorder
.MACRO loadReorderInput
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  t0, Y+
	ld  t1, Y+
	ld  t2, Y+
	ld  t3, Y+
	ld  t4, Y+
	ld  t5, Y+
	ld  t6, Y+
	ld  t7, Y+
	rcall ReorderInput
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  t0, Y+
	ld  t1, Y+
	ld  t2, Y+
	ld  t3, Y+
	ld  t4, Y+
	ld  t5, Y+
	ld  t6, Y+
	ld  t7, Y+
	inc t7
	rcall ReorderInput
.ENDMACRO

.MACRO storeReorderOutput
	ldi YH, high(SRAM_PTEXT)
	ldi YL, low(SRAM_PTEXT)

	rcall ReorderOutput
	ld tmp, Y
	eor t0, tmp
	st Y+, t0

	ld tmp, Y
	eor t1, tmp
	st Y+, t1

	ld tmp, Y
	eor t2, tmp
	st Y+, t2

	ld tmp, Y
	eor t3, tmp
	st Y+, t3

	ld tmp, Y
	eor t4, tmp
	st Y+, t4

	ld tmp, Y
	eor t5, tmp
	st Y+, t5

	ld tmp, Y
	eor t6, tmp
	st Y+, t6

	ld tmp, Y
	eor t7, tmp
	st Y+, t7

	rcall ReorderOutput
	ld tmp, Y
	eor t0, tmp
	st Y+, t0

	ld tmp, Y
	eor t1, tmp
	st Y+, t1

	ld tmp, Y
	eor t2, tmp
	st Y+, t2

	ld tmp, Y
	eor t3, tmp
	st Y+, t3

	ld tmp, Y
	eor t4, tmp
	st Y+, t4

	ld tmp, Y
	eor t5, tmp
	st Y+, t5

	ld tmp, Y
	eor t6, tmp
	st Y+, t6

	ld tmp, Y
	eor t7, tmp
	st Y+, t7
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

#ifdef ENCRYPT
ReorderInput:
	Reorder1Byte t1, s10, s11, s12, s13
	Reorder1Byte t3, s10, s11, s12, s13
	Reorder1Byte t5, s10, s11, s12, s13
	Reorder1Byte t7, s10, s11, s12, s13

	Reorder1Byte t1, s00, s01, s02, s03
	Reorder1Byte t3, s00, s01, s02, s03
	Reorder1Byte t5, s00, s01, s02, s03
	Reorder1Byte t7, s00, s01, s02, s03

	Reorder1Byte t0, s30, s31, s32, s33
	Reorder1Byte t2, s30, s31, s32, s33
	Reorder1Byte t4, s30, s31, s32, s33
	Reorder1Byte t6, s30, s31, s32, s33

	Reorder1Byte t0, s20, s21, s22, s23
	Reorder1Byte t2, s20, s21, s22, s23
	Reorder1Byte t4, s20, s21, s22, s23
	Reorder1Byte t6, s20, s21, s22, s23
ret

ReorderOutput:
	Reorder1ByteOutput t1, s10, s11, s12, s13
	Reorder1ByteOutput t3, s10, s11, s12, s13
	Reorder1ByteOutput t5, s10, s11, s12, s13
	Reorder1ByteOutput t7, s10, s11, s12, s13

	Reorder1ByteOutput t1, s00, s01, s02, s03
	Reorder1ByteOutput t3, s00, s01, s02, s03
	Reorder1ByteOutput t5, s00, s01, s02, s03
	Reorder1ByteOutput t7, s00, s01, s02, s03

	Reorder1ByteOutput t0, s30, s31, s32, s33
	Reorder1ByteOutput t2, s30, s31, s32, s33
	Reorder1ByteOutput t4, s30, s31, s32, s33
	Reorder1ByteOutput t6, s30, s31, s32, s33

	Reorder1ByteOutput t0, s20, s21, s22, s23
	Reorder1ByteOutput t2, s20, s21, s22, s23
	Reorder1ByteOutput t4, s20, s21, s22, s23
	Reorder1ByteOutput t6, s20, s21, s22, s23
ret
#endif
#endif

#ifdef Fixorder
.MACRO loadInput
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  s00, Y+
	ld  s10, Y+
	ld  s20, Y+
	ld  s30, Y+
	ld  s01, Y+
	ld  s11, Y+
	ld  s21, Y+
	ld  s31, Y+
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  s02, Y+
	ld  s12, Y+
	ld  s22, Y+
	ld  s32, Y+
	ld  s03, Y+
	ld  s13, Y+
	ld  s23, Y+
	ld  s33, Y+
	inc s33
.ENDMACRO

.MACRO storeOutput
	ldi YH, high(SRAM_PTEXT)
	ldi YL, low(SRAM_PTEXT)

	ld  tmp, Y
	eor s00, tmp
	st  Y+, s00

	ld  tmp, Y
	eor s10, tmp
	st  Y+, s10

	ld  tmp, Y
	eor s20, tmp
	st  Y+, s20

	ld  tmp, Y
	eor s30, tmp
	st  Y+, s30

	ld  tmp, Y
	eor s01, tmp
	st  Y+, s01

	ld  tmp, Y
	eor s11, tmp
	st  Y+, s11

	ld  tmp, Y
	eor s21, tmp
	st  Y+, s21

	ld  tmp, Y
	eor s31, tmp
	st  Y+, s31

	ld  tmp, Y
	eor s02, tmp
	st  Y+, s02

	ld  tmp, Y
	eor s12, tmp
	st  Y+, s12

	ld  tmp, Y
	eor s22, tmp
	st  Y+, s22

	ld  tmp, Y
	eor s32, tmp
	st  Y+, s32

	ld  tmp, Y
	eor s03, tmp
	st  Y+, s03

	ld  tmp, Y
	eor s13, tmp
	st  Y+, s13

	ld  tmp, Y
	eor s23, tmp
	st  Y+, s23

	ld  tmp, Y
	eor s33, tmp
	st  Y+, s33
.ENDMACRO
#endif

.MACRO KeyXor
	lpm    k0, Z+
	eor  s00, k0
	lpm    k0, Z+
	eor  s10, k0
	lpm    k0, Z+
	eor  s20, k0
	lpm    k0, Z+
	eor  s30, k0
	lpm    k0, Z+
	eor  s01, k0
	lpm    k0, Z+
	eor  s11, k0
	lpm    k0, Z+
	eor  s21, k0
	lpm    k0, Z+
	eor  s31, k0
	lpm    k0, Z+
	eor  s02, k0
	lpm    k0, Z+
	eor  s12, k0
	lpm    k0, Z+
	eor  s22, k0
	lpm    k0, Z+
	eor  s32, k0
	lpm    k0, Z+
	eor  s03, k0
	lpm    k0, Z+
	eor  s13, k0
	lpm    k0, Z+
	eor  s23, k0
	lpm    k0, Z+
	eor  s33, k0
.ENDMACRO

.MACRO Sbox
	; a = s10:s00 = r1:r0
	; b = s11:s01 = r5:r4
	; c = s12:s02 = r9:r8
	; d = s13:s03 = r13:r12
	com  s01
	com  s11
	movw  t0, s01
	and  s01, s00
	and  s11, s10
	movw  t2, s02
	or   s02,  t0
	or   s12,  t1
	movw  t4, s02
	and  s02, s03
	and  s12, s13
	movw  t6, s02
	or   s02, s01
	or   s12, s11
	com   t6
	com   t7
	eor   t2,  t6
	eor   t3,  t7
	eor  s03,  t2
	eor  s13,  t3
	eor  s01,  t0
	eor  s11,  t1
	or   s01, s03
	or   s11, s13
	eor  s00, s02
	eor  s10, s12
	or   s03, s00
	or   s13, s10
	eor  s00,  t0
	eor  s10,  t1
	eor  s03,  t4
	eor  s13,  t5
	and   t6, s03
	and   t7, s13
	eor  s00,  t6
	eor  s10,  t7
	eor  s03,  t2
	eor  s13,  t3

	; a = s30:s20 = r3:r2
	; b = s31:s21 = r7:r6
	; c = s32:s22 = r11:r10
	; d = s33:s23 = r15:r14
	com  s21
	com  s31
	movw  t0, s21
	and  s21, s20
	and  s31, s30
	movw  t2, s22
	or   s22,  t0
	or   s32,  t1
	movw  t4, s22
	and  s22, s23
	and  s32, s33
	movw  t6, s22
	or   s22, s21
	or   s32, s31
	com   t6
	com   t7
	eor   t2,  t6
	eor   t3,  t7
	eor  s23,  t2
	eor  s33,  t3
	eor  s21,  t0
	eor  s31,  t1
	or   s21, s23
	or   s31, s33
	eor  s20, s22
	eor  s30, s32
	or   s23, s20
	or   s33, s30
	eor  s20,  t0
	eor  s30,  t1
	eor  s23,  t4
	eor  s33,  t5
	and   t6, s23
	and   t7, s33
	eor  s20,  t6
	eor  s30,  t7
	eor  s23,  t2
	eor  s33,  t3
.ENDMACRO

.MACRO iSbox
	; a = s10:s00 = r1:r0
	; b = s11:s01 = r5:r4
	; c = s12:s02 = r9:r8
	; d = s13:s03 = r13:r12
	movw t0, s00
	and  s00, s01
	and  s10, s11
	or   s00, s03
	or   s10, s13
	eor  s00, s02
	eor  s10, s12
	movw t2, s00
	com  s00
	com  s10
	or   t2, s01
	or   t3, s11
	eor  t2, s03
	eor  t3, s13
	or   s03, s00
	or   s13, s10
	movw t4, t2
	or   t2, t0
	or   t3, t1
	eor  t0, s03
	eor  t1, s13
	eor  s01, t2
	eor  s11, t3
	movw s02, s01
	eor  s01, t0
	eor  s11, t1
	movw s03, s01
	or   s03, s00
	or   s13, s10
	and  t0, s03
	and  t1, s13
	eor  t0, t4
	eor  t1, t5
	movw s03, t0
	and  t0, s02
	and  t1, s12
	eor  s00, t0
	eor  s10, t1

	; a = s30:s20 = r3:r2
	; b = s31:s21 = r7:r6
	; c = s32:s22 = r11:r10
	; d = s33:s23 = r15:r14
	movw t0, s20
	and  s20, s21
	and  s30, s31
	or   s20, s23
	or   s30, s33
	eor  s20, s22
	eor  s30, s32
	movw t2, s20
	com  s20
	com  s30
	or   t2, s21
	or   t3, s31
	eor  t2, s23
	eor  t3, s33
	or   s23, s20
	or   s33, s30
	movw t4, t2
	or   t2, t0
	or   t3, t1
	eor  t0, s23
	eor  t1, s33
	eor  s21, t2
	eor  s31, t3
	movw s22, s21
	eor  s21, t0
	eor  s31, t1
	movw s23, s21
	or   s23, s20
	or   s33, s30
	and  t0, s23
	and  t1, s33
	eor  t0, t4
	eor  t1, t5
	movw s23, t0
	and  t0, s22
	and  t1, s32
	eor  s20, t0
	eor  s30, t1
.ENDMACRO

;;;****************************************************************************
;;; M_XOR
.MACRO M_Bits0
	mov  t0, s00
	eor  t0, s10
	eor  t0, s20
	eor  t0, s30
	eor  s00, t0
	eor  s10, t0
	eor  s20, t0
	eor  s30, t0

	;s00: 300 200 100 000 : 300 200 100 000
	;s10: 310 210 110 010 : 310 210 110 010
	;s20: 320 220 120 020 : 320 220 120 020
	;s30: 330 230 130 030 : 330 230 130 030
	; |
	;s00: 330 220 120 030 : 330 220 120 030
	;s10: 320 210 110 020 : 320 210 110 020
	;s20: 310 200 100 010 : 310 200 100 010
	;s30: 300 230 130 000 : 300 230 130 000

	movw t0, s00
	movw t2, s20

	mov  s00, t2
	mov  s20, t0

	and  s00, m66   ; xxx 220 120 xxx : xxx 220 120 xxx
	and  s10, m66   ; xxx 210 110 xxx : xxx 210 110 xxx
	and  s20, m66   ; xxx 200 100 xxx : xxx 200 100 xxx
	and  s30, m66   ; xxx 230 130 xxx : xxx 230 130 xxx
	and   t3, m99   ; 330 xxx xxx 030 : 330 xxx xxx 030
	and   t2, m99   ; 320 xxx xxx 020 : 320 xxx xxx 020
	and   t1, m99   ; 310 xxx xxx 010 : 310 xxx xxx 010
	and   t0, m99   ; 300 xxx xxx 000 : 300 xxx xxx 000

	eor  s00, t3    ; 330 220 120 030 : 330 220 120 030
	eor  s10, t2    ; 320 210 110 020 : 320 210 110 020
	eor  s20, t1    ; 310 200 100 010 : 310 200 100 010
	eor  s30, t0    ; 300 230 130 000 : 300 230 130 000
.ENDMACRO

.MACRO M_Bits1
	mov  t0, s01
	eor  t0, s11
	eor  t0, s21
	eor  t0, s31
	eor  s01, t0
	eor  s11, t0
	eor  s21, t0
	eor  s31, t0

	;s01: 301 201 101 001 : 301 201 101 001
	;s11: 311 211 111 011 : 311 211 111 011
	;s21: 321 221 121 021 : 321 221 121 021
	;s31: 331 231 131 031 : 331 231 131 031
	; |
	;s01: 321 211 111 021 : 321 211 111 021
	;s11: 311 201 101 011 : 311 201 101 011
	;s21: 301 231 131 001 : 301 231 131 001
	;s31: 331 221 121 031 : 331 221 121 031

	movw t0, s01    ; 301 201 101 001 : 301 201 101 001
				    ; 311 211 111 011 : 311 211 111 011
	movw t2, s21    ; 321 221 121 021 : 321 221 121 021
				    ; 331 231 131 031 : 331 231 131 031

	mov  s01, t2    ; 321 221 121 021 : 321 221 121 021
	mov  s21, t0    ; 301 231 131 001 : 301 231 131 001

	and  s01, m99   ; 321 xxx xxx 021 : 321 xxx xxx 021
	and  s11, m99   ; 311 xxx xxx 011 : 311 xxx xxx 011
	and  s21, m99   ; 301 xxx xxx 001 : 301 xxx xxx 001
	and  s31, m99   ; 331 xxx xxx 031 : 331 xxx xxx 031

	and   t1, m66   ; xxx 211 111 xxx : xxx 211 111 xxx
	and   t0, m66   ; xxx 201 101 xxx : xxx 201 101 xxx
	and   t3, m66   ; xxx 231 131 xxx : xxx 231 131 xxx
	and   t2, m66   ; xxx 221 121 xxx : xxx 221 121 xxx

	eor  s01,  t1   ; 321 211 111 021 : 321 211 111 021
	eor  s11,  t0   ; 311 201 101 011 : 311 201 101 011
	eor  s21,  t3   ; 301 231 131 001 : 301 231 131 001
	eor  s31,  t2   ; 331 221 121 031 : 331 221 121 031
.ENDMACRO

.MACRO M_Bits2
	mov  t0, s02
	eor  t0, s12
	eor  t0, s22
	eor  t0, s32
	eor  s02, t0
	eor  s12, t0
	eor  s22, t0
	eor  s32, t0

	;s02: 302 202 102 002 : 302 202 102 002
	;s12: 312 212 112 012 : 312 212 112 012
	;s22: 322 222 122 022 : 322 222 122 022
	;s32: 332 232 132 032 : 332 232 132 032
	; |
	;s02: 312 202 102 012 : 312 202 102 012
	;s12: 302 232 132 002 : 302 232 132 002
	;s22: 332 222 122 032 : 332 222 122 032
	;s32: 322 212 112 022 : 322 212 112 022

	movw t0, s02    ; 302 202 102 002 : 302 202 102 002
				    ; 312 212 112 012 : 312 212 112 012
	movw t2, s22    ; 322 222 122 022 : 322 222 122 022
				    ; 332 232 132 032 : 332 232 132 032

	mov  s12, t3    ; 332 232 132 032 : 332 232 132 032
	mov  s32, t1    ; 312 212 112 012 : 312 212 112 012

	and  s02, m66   ; xxx 202 102 xxx : xxx 202 102 xxx
	and  s12, m66   ; xxx 232 132 xxx : xxx 232 132 xxx
	and  s22, m66   ; xxx 222 122 xxx : xxx 222 122 xxx
	and  s32, m66   ; xxx 212 112 xxx : xxx 212 112 xxx
	and   t1, m99   ; 312 xxx xxx 012 : 312 xxx xxx 012
	and   t0, m99   ; 302 xxx xxx 002 : 302 xxx xxx 002
	and   t3, m99   ; 332 xxx xxx 032 : 332 xxx xxx 032
	and   t2, m99   ; 322 xxx xxx 022 : 322 xxx xxx 022

	eor  s02, t1    ; 312 202 102 012 : 312 202 102 012
	eor  s12, t0    ; 302 232 132 002 : 302 232 132 002
	eor  s22, t3    ; 332 222 122 032 : 332 222 122 032
	eor  s32, t2    ; 322 212 112 022 : 322 212 112 022
.ENDMACRO

.MACRO M_Bits3
	mov  t0, s03
	eor  t0, s13
	eor  t0, s23
	eor  t0, s33
	eor  s03, t0
	eor  s13, t0
	eor  s23, t0
	eor  s33, t0

	;s03: 303 203 103 003 : 303 203 103 003
	;s13: 313 213 113 013 : 313 213 113 013
	;s23: 323 223 123 023 : 323 223 123 023
	;s33: 333 233 133 033 : 333 233 133 033
	; |
	;s03: 303 233 133 003 : 303 233 133 003
	;s13: 333 223 123 033 : 333 223 123 033
	;s23: 323 213 113 023 : 323 213 113 023
	;s33: 313 203 103 013 : 313 203 103 013

	movw t0, s03    ; 303 203 103 003 : 303 203 103 003
				    ; 313 213 113 013 : 313 213 113 013
	movw t2, s23    ; 323 223 123 023 : 323 223 123 023
				    ; 333 233 133 033 : 333 233 133 033

	mov  s13, t3    ; 333 233 133 033 : 333 233 133 033
	mov  s33, t1    ; 313 213 113 013 : 313 213 113 013

	and  s03, m99   ; 303 xxx xxx 003 : 303 xxx xxx 003
	and  s13, m99   ; 333 xxx xxx 033 : 333 xxx xxx 033
	and  s23, m99   ; 323 xxx xxx 023 : 323 xxx xxx 023
	and  s33, m99   ; 313 xxx xxx 013 : 313 xxx xxx 013
	and   t3, m66   ; xxx 233 133 xxx : xxx 233 133 xxx
	and   t2, m66   ; xxx 223 123 xxx : xxx 223 123 xxx
	and   t1, m66   ; xxx 213 113 xxx : xxx 213 113 xxx
	and   t0, m66   ; xxx 203 103 xxx : xxx 203 103 xxx

	eor  s03, t3    ; 303 233 133 003 : 303 233 133 003
	eor  s13, t2    ; 333 223 123 033 : 333 223 123 033
	eor  s23, t1    ; 323 213 113 023 : 323 213 113 023
	eor  s33, t0    ; 313 203 103 013 : 313 203 103 013
.ENDMACRO

.MACRO M_XOR
	M_Bits0
	M_Bits1
	M_Bits2
	M_Bits3
.ENDMACRO

.MACRO SR_1bits
	mov  t1, @1
	movw t2, @2

	lsl  @1
	bst  t1, 3
	bld  @1, 0
	bst  t1, 7
	bld  @1, 4

	and @2, t4
	and t2, t5
	lsl  @2
	lsl  @2
	lsr  t2
	lsr  t2
	eor  @2, t2

	lsr  @3
	bst  t3, 0
	bld  @3, 3
	bst  t3, 4
	bld  @3, 7
.ENDMACRO

.MACRO SR
	ldi  t4, 0b00110011
	ldi  t5, 0b11001100
	SR_1bits s00, s10, s20, s30
	SR_1bits s01, s11, s21, s31
	SR_1bits s02, s12, s22, s32
	SR_1bits s03, s13, s23, s33
.ENDMACRO

.MACRO iSR_1bits
	mov  t1, @1
	movw t2, @2

	lsl  @3
	bst  t3, 3
	bld  @3, 0
	bst  t3, 7
	bld  @3, 4

	and @2, t4
	and t2, t5
	lsl  @2
	lsl  @2
	lsr  t2
	lsr  t2
	eor  @2, t2

	lsr  @1
	bst  t1, 0
	bld  @1, 3
	bst  t1, 4
	bld  @1, 7
.ENDMACRO

.MACRO iSR
	ldi  t4, 0b00110011
	ldi  t5, 0b11001100
	iSR_1bits s00, s10, s20, s30
	iSR_1bits s01, s11, s21, s31
	iSR_1bits s02, s12, s22, s32
	iSR_1bits s03, s13, s23, s33
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

#ifdef ENCRYPT
Encrypt:
	ldi m66, 0b01100110
	ldi m99, 0b10011001
	ldi ZH, high(key<<1)
	ldi ZL, low(key<<1)
#ifdef Reorder
	loadReorderInput
#endif
#ifdef Fixorder
	loadInput
#endif
	clr rcnt
forword_start:
	forward_round
	inc rcnt
	ldi rrn, 5
	cpse rcnt, rrn
	rjmp forword_start
middle_start:
	middle_round
	clr rcnt
invert_start:
	invert_round
	inc rcnt
	ldi rrn, 5
	cpse rcnt, rrn
	rjmp invert_start
#ifdef Reorder
	storeReorderOutput
#endif
#ifdef Fixorder
	storeOutput
#endif
ret
#endif


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
