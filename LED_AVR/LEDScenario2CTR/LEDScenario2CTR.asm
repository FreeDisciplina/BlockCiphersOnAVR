.EQU    COUNTER_BYTE = 8
.EQU    COUNT_NUM_BYTE = (8)
.EQU    PTEXT_NUM_BYTE = (8*2)

#define ENCRYPT
;#define Reorder
#define Fixorder

; Registers declarations
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
;
;s03:s02:s01:s00
;s13:s12:s11:s10
;s23:s22:s21:s20
;s33:s32:s31:s30
;
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

.def m44 =r24 ; ldi m44, 0b01000100
.def m88 =r25 ; ldi m88, 0b10001000

.def rrn =r22
.def rcnt=r23

.def YL =r28
.def YH =r29
.def ZL =r30
.def ZH =r31

.def tmp =r26

;;;****************************************************************************
;;; Load input and Store output
;;;****************************************************************************
;;;
#ifdef Reorder
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

ReorderInputSwitch:
	Reorder1Byte t1, s02, s03, s00, s01
	Reorder1Byte t1, s02, s03, s00, s01
	Reorder1Byte t0, s02, s03, s00, s01
	Reorder1Byte t0, s02, s03, s00, s01

	Reorder1Byte t3, s12, s13, s10, s11
	Reorder1Byte t3, s12, s13, s10, s11
	Reorder1Byte t2, s12, s13, s10, s11
	Reorder1Byte t2, s12, s13, s10, s11

	Reorder1Byte t5, s22, s23, s20, s21
	Reorder1Byte t5, s22, s23, s20, s21
	Reorder1Byte t4, s22, s23, s20, s21
	Reorder1Byte t4, s22, s23, s20, s21

	Reorder1Byte t7, s32, s33, s30, s31
	Reorder1Byte t7, s32, s33, s30, s31
	Reorder1Byte t6, s32, s33, s30, s31
	Reorder1Byte t6, s32, s33, s30, s31
ret

ReorderOutputSwitch:
	Reorder1ByteOutput t1, s02, s03, s00, s01
	Reorder1ByteOutput t1, s02, s03, s00, s01
	Reorder1ByteOutput t0, s02, s03, s00, s01
	Reorder1ByteOutput t0, s02, s03, s00, s01

	Reorder1ByteOutput t3, s12, s13, s10, s11
	Reorder1ByteOutput t3, s12, s13, s10, s11
	Reorder1ByteOutput t2, s12, s13, s10, s11
	Reorder1ByteOutput t2, s12, s13, s10, s11

	Reorder1ByteOutput t5, s22, s23, s20, s21
	Reorder1ByteOutput t5, s22, s23, s20, s21
	Reorder1ByteOutput t4, s22, s23, s20, s21
	Reorder1ByteOutput t4, s22, s23, s20, s21

	Reorder1ByteOutput t7, s32, s33, s30, s31
	Reorder1ByteOutput t7, s32, s33, s30, s31
	Reorder1ByteOutput t6, s32, s33, s30, s31
	Reorder1ByteOutput t6, s32, s33, s30, s31
ret

.MACRO loadReorderInputSwitch
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  t0, Y+
	ld  t1, Y+
	ld  t2, Y+
	ld  t3, Y+
	ld  t4, Y+
	ld  t5, Y+
	ld  t6, Y+
	ld  t7, Y
	rcall ReorderInputSwitch
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  t0, Y+
	ld  t1, Y+
	ld  t2, Y+
	ld  t3, Y+
	ld  t4, Y+
	ld  t5, Y+
	ld  t6, Y+
	ld  t7, Y
	inc t7
	rcall ReorderInputSwitch
.ENDMACRO


.MACRO storeReorderOutputSwitch
	ldi YH, high(SRAM_PTEXT)
	ldi YL, low(SRAM_PTEXT)

	rcall ReorderOutputSwitch

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

	rcall ReorderOutputSwitch
	ld tmp, Y
	eor t0, tmp
	st  Y+, t0

	ld tmp, Y
	eor t1, tmp
	st  Y+, t1

	ld tmp, Y
	eor t2, tmp
	st  Y+, t2

	ld tmp, Y
	eor t3, tmp
	st  Y+, t3

	ld tmp, Y
	eor t4, tmp
	st  Y+, t4

	ld tmp, Y
	eor t5, tmp
	st  Y+, t5

	ld tmp, Y
	eor t6, tmp
	st  Y+, t6

	ld tmp, Y
	eor t7, tmp
	st  Y, t7
.ENDMACRO
#endif

#ifdef Fixorder
.MACRO loadInputSwitch
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  s20, Y+
	ld  s30, Y+
	ld  s00, Y+
	ld  s10, Y+
	ld  s21, Y+
	ld  s31, Y+
	ld  s01, Y+
	ld  s11, Y
	ldi YH, high(SRAM_COUNT)
	ldi YL, low(SRAM_COUNT)
	ld  s22, Y+
	ld  s32, Y+
	ld  s02, Y+
	ld  s12, Y+
	ld  s23, Y+
	ld  s33, Y+
	ld  s03, Y+
	ld  s13, Y
	inc s13
.ENDMACRO

.MACRO storeOutputSwitch
	ldi YH, high(SRAM_PTEXT)
	ldi YL, low(SRAM_PTEXT)

	ld  tmp, Y
	eor s20, tmp
	st  Y+, s20

	ld  tmp, Y
	eor s30, tmp
	st  Y+, s30

	ld  tmp, Y
	eor s00, tmp
	st  Y+, s00

	ld  tmp, Y
	eor s10, tmp
	st  Y+, s10

	ld  tmp, Y
	eor s21, tmp
	st  Y+, s21

	ld  tmp, Y
	eor s31, tmp
	st  Y+, s31

	ld  tmp, Y
	eor s01, tmp
	st  Y+, s01

	ld  tmp, Y
	eor s11, tmp
	st  Y+, s11

	ld  tmp, Y
	eor s22, tmp
	st  Y+, s22

	ld  tmp, Y
	eor s32, tmp
	st  Y+, s32

	ld  tmp, Y
	eor s02, tmp
	st  Y+, s02

	ld  tmp, Y
	eor s12, tmp
	st  Y+, s12

	ld  tmp, Y
	eor s23, tmp
	st  Y+, s23

	ld  tmp, Y
	eor s33, tmp
	st  Y+, s33

	ld  tmp, Y
	eor s03, tmp
	st  Y+, s03

	ld  tmp, Y
	eor s13, tmp
	st  Y, s13

.ENDMACRO
#endif

;;;****************************************************************************
;;; Components
;;;****************************************************************************
;;;
.MACRO SboxSwitch
	; a = s10:s00 = r1:r0
	; b = s11:s01 = r5:r4
	; c = s12:s02 = r9:r8
	; d = s13:s03 = r13:r12
	eor  s03, s00
	eor  s13, s10
	movw t0, s02
	movw s02, s03
	and  s03, s00
	and  s13, s10
	eor  s03, s01
	eor  s13, s11
	movw t2, s03
	and  s03, s02
	and  s13, s12
	eor  s03, s00
	eor  s13, s10
	movw s01, s03
	or   s01, t0
	or   s11, t1
	movw s00, t2
	eor  s00, t0
	eor  s10, t1
	eor  s02, s00
	eor  s12, s10
	eor  s01, s02
	eor  s11, s12
	com  t0
	com  t1
	eor  s03, t0
	eor  s13, t1
	or   s02, s03
	or   s12, s13
	eor  s02, t2
	eor  s12, t3
	eor  s03, s01
	eor  s13, s11

	; a = s30:s20 = r1:r0
	; b = s31:s21 = r5:r4
	; c = s32:s22 = r9:r8
	; d = s33:s23 = r13:r12
	eor  s23, s20
	eor  s33, s30
	movw t0, s22
	movw s22, s23
	and  s23, s20
	and  s33, s30
	eor  s23, s21
	eor  s33, s31
	movw t2, s23
	and  s23, s22
	and  s33, s32
	eor  s23, s20
	eor  s33, s30
	movw s21, s23
	or   s21, t0
	or   s31, t1
	movw s20, t2
	eor  s20, t0
	eor  s30, t1
	eor  s22, s20
	eor  s32, s30
	eor  s21, s22
	eor  s31, s32
	com  t0
	com  t1
	eor  s23, t0
	eor  s33, t1
	or   s22, s23
	or   s32, s33
	eor  s22, t2
	eor  s32, t3
	eor  s23, s21
	eor  s33, s31
.ENDMACRO

;;;****************************************************************************
;;; MixColumn
.MACRO MixColumn
	// A1
	eor  s00, s03
	eor  s03, s02

	eor  s01, s13
	eor  s00, s12
	eor  s03, s11
	eor  s02, s10

	eor  s01, s22
	eor  s00, s21
	eor  s03, s20
	eor  s02, s23

	eor  s01, s32
	eor  s00, s31
	eor  s03, s30
	eor  s02, s33

	eor  s03, s23
	eor  s03, s33

	// A2
	eor  s10, s13
	eor  s13, s12

	eor  s11, s23
	eor  s10, s22
	eor  s13, s21
	eor  s12, s20

	eor  s11, s32
	eor  s10, s31
	eor  s13, s30
	eor  s12, s33

	eor  s11, s00
	eor  s10, s03
	eor  s13, s02
	eor  s12, s01

	eor  s13, s33
	eor  s13, s01

	// A3
	eor  s20, s23
	eor  s23, s22

	eor  s21, s33
	eor  s20, s32
	eor  s23, s31
	eor  s22, s30

	eor  s21, s00
	eor  s20, s03
	eor  s23, s02
	eor  s22, s01

	eor  s21, s10
	eor  s20, s13
	eor  s23, s12
	eor  s22, s11

	eor  s23, s01
	eor  s23, s11

	// A4
	eor  s30, s33
	eor  s33, s32

	eor  s31, s01
	eor  s30, s00
	eor  s33, s03
	eor  s32, s02

	eor  s31, s10
	eor  s30, s13
	eor  s33, s12
	eor  s32, s11

	eor  s31, s20
	eor  s30, s23
	eor  s33, s22
	eor  s32, s21

	eor  s33, s11
	eor  s33, s21
.ENDMACRO

.MACRO Key1XorSwitch
	movw YL, ZL
	ldi ZH, high(key<<1)
	ldi ZL, low(key<<1)
	lpm k0, Z+;
	eor s00, k0
	lpm k0, Z+;
	eor s10, k0
	lpm k0, Z+;
	eor s20, k0
	lpm k0, Z+;
	eor s30, k0
	lpm k0, Z+;
	eor s01, k0
	lpm k0, Z+;
	eor s11, k0
	lpm k0, Z+;
	eor s21, k0
	lpm k0, Z+;
	eor s31, k0
	lpm k0, Z+;
	eor s02, k0
	lpm k0, Z+;
	eor s12, k0
	lpm k0, Z+;
	eor s22, k0
	lpm k0, Z+;
	eor s32, k0
	lpm k0, Z+;
	eor s03, k0
	lpm k0, Z+;
	eor s13, k0
	lpm k0, Z+;
	eor s23, k0
	lpm k0, Z;
	eor s33, k0
	movw ZL, YL
.ENDMACRO

.MACRO Key2XorSwitch
	movw YL, ZL
	ldi ZH, high((key<<1) + 16)
	ldi ZL, low((key<<1) + 16)
	lpm k0, Z+;
	eor s00, k0
	lpm k0, Z+;
	eor s10, k0
	lpm k0, Z+;
	eor s20, k0
	lpm k0, Z+;
	eor s30, k0
	lpm k0, Z+;
	eor s01, k0
	lpm k0, Z+;
	eor s11, k0
	lpm k0, Z+;
	eor s21, k0
	lpm k0, Z+;
	eor s31, k0
	lpm k0, Z+;
	eor s02, k0
	lpm k0, Z+;
	eor s12, k0
	lpm k0, Z+;
	eor s22, k0
	lpm k0, Z+;
	eor s32, k0
	lpm k0, Z+;
	eor s03, k0
	lpm k0, Z+;
	eor s13, k0
	lpm k0, Z+;
	eor s23, k0
	lpm k0, Z;
	eor s33, k0
	movw ZL, YL
.ENDMACRO

.MACRO RCXor
	lpm  k0, Z+

	bst  k0, 5
	brtc rc5
	eor  s02, m44 ; 01000100
	eor  s22, m44 ; 01000100
rc5:
	bst  k0, 4
	brtc rc4
	eor  s01, m44 ; 01000100
	eor  s21, m44 ; 01000100
rc4:
	eor  s03, m88 ; 10001000
	eor  s21, m88 ; 10001000

	bst  k0, 3
	brtc rc3
	eor  s00, m44 ; 01000100
	eor  s20, m44 ; 01000100
rc3:
	bst  k0, 2
	brtc rc2
	eor  s12, m44 ; 01000100
	eor  s32, m44 ; 01000100
rc2:
	bst  k0, 1
	brtc rc1
	eor  s11, m44 ; 01000100
	eor  s31, m44 ; 01000100
rc1:
	eor  s13, m88 ; 10001000
	eor  s31, m88 ; 10001000

	bst  k0, 0
	brtc rc0
	eor  s10, m44 ; 01000100
	eor  s30, m44 ; 01000100
rc0:
	eor  s10, m88 ; 10001000
	eor  s30, m88 ; 10001000
.ENDMACRO


.MACRO RCXorSwitch
	lpm  k0, Z+

	bst  k0, 5
	brtc rc5
	eor  s00, m44 ; 01000100
	eor  s20, m44 ; 01000100
rc5:
	bst  k0, 4
	brtc rc4
	eor  s03, m44 ; 01000100
	eor  s23, m44 ; 01000100
rc4:
	eor  s01, m88 ; 10001000
	eor  s23, m88 ; 10001000

	bst  k0, 3
	brtc rc3
	eor  s02, m44 ; 01000100
	eor  s22, m44 ; 01000100
rc3:
	bst  k0, 2
	brtc rc2
	eor  s10, m44 ; 01000100
	eor  s30, m44 ; 01000100
rc2:
	bst  k0, 1
	brtc rc1
	eor  s13, m44 ; 01000100
	eor  s33, m44 ; 01000100
rc1:
	eor  s11, m88 ; 10001000
	eor  s33, m88 ; 10001000

	bst  k0, 0
	brtc rc0
	eor  s12, m44 ; 01000100
	eor  s32, m44 ; 01000100
rc0:
	eor  s12, m88 ; 10001000
	eor  s32, m88 ; 10001000
.ENDMACRO

.MACRO SR_1bits
	mov  t1, @1
	movw t2, @2

	lsr  @3
	bst  t3, 0
	bld  @3, 3
	bst  t3, 4
	bld  @3, 7

	and @2, t4
	and t2, t5
	lsl  @2
	lsl  @2
	lsr  t2
	lsr  t2
	eor  @2, t2

	lsl  @1
	bst  t1, 3
	bld  @1, 0
	bst  t1, 7
	bld  @1, 4
.ENDMACRO

.MACRO SR
	SR_1bits s00, s10, s20, s30
	SR_1bits s01, s11, s21, s31
	SR_1bits s02, s12, s22, s32
	SR_1bits s03, s13, s23, s33
.ENDMACRO


#if defined(ENCRYPT)
RoundFunction:
	RCXorSwitch
	SboxSwitch
	SR
	MixColumn
ret

.MACRO Step1
	Key1XorSwitch
	rcall RoundFunction
	rcall RoundFunction
	rcall RoundFunction
	rcall RoundFunction
.ENDMACRO

.MACRO Step2
	Key2XorSwitch
	rcall RoundFunction
	rcall RoundFunction
	rcall RoundFunction
	rcall RoundFunction
.ENDMACRO

encrypt:
	ldi m44, 0b01000100
	ldi m88, 0b10001000
#ifdef Reorder
	loadReorderInputSwitch
#endif
#ifdef Fixorder
	loadInputSwitch
#endif
	ldi ZH, high(RC<<1)
	ldi ZL, low(RC<<1)

	ldi  t4, 0b00110011
	ldi  t5, 0b11001100

	ldi rrn, 6
	clr rcnt
loop_start:

	Step1
	Step2

	inc rcnt
	cpse rcnt, rrn
	rjmp loop_start

	Key1XorSwitch
#ifdef Reorder
	storeReorderOutputSwitch
#endif
#ifdef Fixorder
	storeOutputSwitch
#endif
ret
#endif

RC:
; 1-24
.db 0x01,0x03,0x07,0x0F,0x1F,0x3E,0x3D,0x3B,0x37,0x2F,0x1E,0x3C,0x39,0x33,0x27,0x0E,0x1D,0x3A,0x35,0x2B,0x16,0x2C,0x18,0x30
; 25-48
.db 0x21,0x02,0x05,0x0B,0x17,0x2E,0x1C,0x38,0x31,0x23,0x06,0x0D,0x1B,0x36,0x2D,0x1A,0x34,0x29,0x12,0x24,0x08,0x11,0x22,0x04

; iRoundFunction:
; iM
; |
; iSR
; |
; iSboxSwitch
; |
; RCXor

; iStep:
; |
; iRoundFunction
; |
; iRoundFunction
; |
; iRoundFunction
; |
; iRoundFunction


; loadReorderInputSwitch
; |                                            {
; |                                             i = 1
; Key1XorSwitch
; |
; iStep
; |
; Key2XorSwitch
; |
; iStep
; |                                             i = 2
; Key1XorSwitch
; |
; iStep
; |
; Key2XorSwitch
; |
; iStep
; |                                             i = 3
; Key1XorSwitch
; |
; iStep
; |
; Key2XorSwitch
; |
; iStep
; |                                             i = 4
; Key1XorSwitch
; |
; iStep
; |
; Key2XorSwitch
; |
; iStep
; |                                             i = 5
; Key1XorSwitch
; |
; iStep
; |
; Key2XorSwitch
; |
; iStepSwitch
; |                                             i = 6
; Key1XorSwitch
; |
; iStep
; |
; Key2XorSwitch
; |
; iStep
; |                                             }
; Key1XorSwitch
; |
; storeReorderOutputSwitch
