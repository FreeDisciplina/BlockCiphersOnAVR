.EQU    KEY1_NUM_BYTE = 8
.EQU    KEY2_NUM_BYTE = 8
.EQU    KEY1E_NUM_BYTE = 16 // Expanded key1
.EQU    KEY2E_NUM_BYTE = 16 // Expanded key2
.EQU    KEYR_NUM_BYTE = 48 // Round constant
.EQU    INITV_NUM_BYTE = 8
.EQU    PTEXT_NUM_BYTE = (8*16)

#define KEYSCHEDULE
#define ENCRYPT
#define DECRYPT

; Registers declarations
;303, 302, 301, 300 : 203, 202, 201, 200 : 103, 102, 101, 100 : 003, 002, 001, 000
;313, 312, 311, 310 : 213, 212, 211, 210 : 113, 112, 111, 110 : 013, 012, 011, 010
;323, 322, 321, 320 : 223, 222, 221, 220 : 123, 122, 121, 120 : 023, 022, 021, 020
;333, 332, 331, 330 : 233, 232, 231, 230 : 133, 132, 131, 130 : 033, 032, 031, 030
;
;the 0-bit in the nibbles
;s00: 300 200 100 000 : xxx xxx xxx xxx
;s10: 310 210 110 010 : xxx xxx xxx xxx
;s20: 320 220 120 020 : xxx xxx xxx xxx
;s30: 330 230 130 030 : xxx xxx xxx xxx
;the 1-bit in the nibbles
;s01: 301 201 101 001 : xxx xxx xxx xxx
;s11: 311 211 111 011 : xxx xxx xxx xxx
;s21: 321 221 121 021 : xxx xxx xxx xxx
;s31: 331 231 131 031 : xxx xxx xxx xxx
;the 2-bit in the nibbles
;s02: 302 202 102 002 : xxx xxx xxx xxx
;s12: 312 212 112 012 : xxx xxx xxx xxx
;s22: 322 222 122 022 : xxx xxx xxx xxx
;s32: 332 232 132 032 : xxx xxx xxx xxx
;the 3-bit in the nibbles
;s03: 303 203 103 003 : xxx xxx xxx xxx
;s13: 313 213 113 013 : xxx xxx xxx xxx
;s23: 323 223 123 023 : xxx xxx xxx xxx
;s33: 333 233 133 033 : xxx xxx xxx xxx
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

.def m40 =r24 ; ldi m40, 0b01000000
.def m80 =r25 ; ldi m80, 0b10000000

.def rrn =r22
.def rcnt=r23

.def bn   =r26
.def bcnt =r27

.def YL =r28
.def YH =r29
.def ZL =r30
.def ZH =r31

.def tmp =r0

;;;****************************************************************************
;;; Load input and Store output
;;;****************************************************************************
;;;
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
	rol @4
	rol @0
	rol @3
	rol @0
	rol @2
	rol @0
	rol @1
	rol @0
.ENDMACRO

#if defined(ENCRYPT) || defined(DECRYPT)
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
	Reorder1ByteOutput t0, s02, s03, s00, s01
	Reorder1ByteOutput t0, s02, s03, s00, s01
	Reorder1ByteOutput t1, s02, s03, s00, s01
	Reorder1ByteOutput t1, s02, s03, s00, s01

	Reorder1ByteOutput t2, s12, s13, s10, s11
	Reorder1ByteOutput t2, s12, s13, s10, s11
	Reorder1ByteOutput t3, s12, s13, s10, s11
	Reorder1ByteOutput t3, s12, s13, s10, s11

	Reorder1ByteOutput t4, s22, s23, s20, s21
	Reorder1ByteOutput t4, s22, s23, s20, s21
	Reorder1ByteOutput t5, s22, s23, s20, s21
	Reorder1ByteOutput t5, s22, s23, s20, s21

	Reorder1ByteOutput t6, s32, s33, s30, s31
	Reorder1ByteOutput t6, s32, s33, s30, s31
	Reorder1ByteOutput t7, s32, s33, s30, s31
	Reorder1ByteOutput t7, s32, s33, s30, s31
ret
#endif

.MACRO loadRC
	ldi ZH, high(RC<<1)
	ldi ZL, low(RC<<1)
	ldi XH, high(SRAM_KTEXTR)
	ldi XL, low(SRAM_KTEXTR)
	ldi r18, KEYR_NUM_BYTE
loadRCloop:
	lpm r16, Z+
	st  X+,r16
	dec r18
	brbc 1, loadRCloop
.ENDMACRO

.MACRO iloadRC
	ldi ZH, high(RC<<1)
	ldi ZL, low(RC<<1)
	ldi XH, high(SRAM_KTEXTR+KEYR_NUM_BYTE)
	ldi XL, low(SRAM_KTEXTR+KEYR_NUM_BYTE)
	ldi r18, KEYR_NUM_BYTE
iloadRCloop:
	lpm r16, Z+
	st  -X,r16
	dec r18
	brbc 1, iloadRCloop
.ENDMACRO


.MACRO loadInit
	ld t0, Y+
	ld t1, Y+
	ld t2, Y+
	ld t3, Y+
	ld t4, Y+
	ld t5, Y+
	ld t6, Y+
	ld t7, Y+
.ENDMACRO

.MACRO loadReorderInputSwitch
	ld  tmp, Y+
	eor  t0, tmp
	ld  tmp, Y+
	eor  t1, tmp
	ld  tmp, Y+
	eor  t2, tmp
	ld  tmp, Y+
	eor  t3, tmp
	ld  tmp, Y+
	eor  t4, tmp
	ld  tmp, Y+
	eor  t5, tmp
	ld  tmp, Y+
	eor  t6, tmp
	ld  tmp, Y+
	eor  t7, tmp
	rcall ReorderInputSwitch
.ENDMACRO

.MACRO storeReorderOutputSwitch
	rcall ReorderOutputSwitch
	sbiw YH:YL, 8
	st Y+, t0
	st Y+, t1
	st Y+, t2
	st Y+, t3
	st Y+, t4
	st Y+, t5
	st Y+, t6
	st Y+, t7
.ENDMACRO

.MACRO loadReorderInputSwitchDec
	ldd  t0, Y+8
	ldd  t1, Y+9
	ldd  t2, Y+10
	ldd  t3, Y+11
	ldd  t4, Y+12
	ldd  t5, Y+13
	ldd  t6, Y+14
	ldd  t7, Y+15
	rcall ReorderInputSwitch
.ENDMACRO

.MACRO storeReorderOutputSwitchDec
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
.ENDMACRO

;;;****************************************************************************
;;; KeySchedule
;;;****************************************************************************
;;;
#if defined(KEYSCHEDULE)
keySchedule:
	ldi YH, high(SRAM_KTEXT1E)
	ldi YL,  low(SRAM_KTEXT1E)

	ldi ZH, high(SRAM_KTEXT1)
	ldi ZL, low(SRAM_KTEXT1)
	ld t0, Z+
	ld t1, Z+
	ld t2, Z+
	ld t3, Z+
	ld t4, Z+
	ld t5, Z+
	ld t6, Z+
	ld t7, Z+
	rcall ReorderInputSwitch
	st Y+, s00
	st Y+, s10
	st Y+, s20
	st Y+, s30
	st Y+, s01
	st Y+, s11
	st Y+, s21
	st Y+, s31
	st Y+, s02
	st Y+, s12
	st Y+, s22
	st Y+, s32
	st Y+, s03
	st Y+, s13
	st Y+, s23
	st Y+, s33
	ld t0, Z+
	ld t1, Z+
	ld t2, Z+
	ld t3, Z+
	ld t4, Z+
	ld t5, Z+
	ld t6, Z+
	ld t7, Z+
	rcall ReorderInputSwitch
	st Y+, s00
	st Y+, s10
	st Y+, s20
	st Y+, s30
	st Y+, s01
	st Y+, s11
	st Y+, s21
	st Y+, s31
	st Y+, s02
	st Y+, s12
	st Y+, s22
	st Y+, s32
	st Y+, s03
	st Y+, s13
	st Y+, s23
	st Y+, s33
ret
#endif

;;;****************************************************************************
;;; Components
;;;****************************************************************************
;;;
;.MACRO Sbox
;	; a = s10:s00 = r1:r0
;	; b = s11:s01 = r5:r4
;	; c = s12:s02 = r9:r8
;	; d = s13:s03 = r13:r12
;	eor  s01, s02
;	eor  s11, s12
;	movw t0, s02
;	and  t0, s01
;	and  t1, s11
;	eor  s03, t0
;	eor  s13, t1
;	movw t0, s03
;	and  s03, s01
;	and  s13, s11
;	eor  s03, s02
;	eor  s13, s12
;	movw t2, s03
;	eor  s03, s00
;	eor  s13, s10
;	com  s03
;	com  s13
;	movw s02, s03
;	or   t2, s00
;	or   t3, s10
;	eor  s00, t0
;	eor  s10, t1
;	eor  s01, s00
;	eor  s11, s10
;	or   s02, s01
;	or   s12, s11
;	eor  s02, t0
;	eor  s12, t1
;	eor  s01, t2
;	eor  s11, t3
;	eor  s03, s01
;	eor  s13, s11
;
;	; a = s30:s20 = r1:r0
;	; b = s31:s21 = r5:r4
;	; c = s32:s22 = r9:r8
;	; d = s33:s23 = r13:r12
;	eor  s21, s22
;	eor  s31, s32
;	movw t0, s22
;	and  t0, s21
;	and  t1, s31
;	eor  s23, t0
;	eor  s33, t1
;	movw t0, s23
;	and  s23, s21
;	and  s33, s31
;	eor  s23, s22
;	eor  s33, s32
;	movw t2, s23
;	eor  s23, s20
;	eor  s33, s30
;	com  s23
;	com  s33
;	movw s22, s23
;	or   t2, s20
;	or   t3, s30
;	eor  s20, t0
;	eor  s30, t1
;	eor  s21, s20
;	eor  s31, s30
;	or   s22, s21
;	or   s32, s31
;	eor  s22, t0
;	eor  s32, t1
;	eor  s21, t2
;	eor  s31, t3
;	eor  s23, s21
;	eor  s33, s31
;.ENDMACRO

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

.MACRO iSboxSwitch
	; a = s10:s00 = r1:r0
	; b = s11:s01 = r5:r4
	; c = s12:s02 = r9:r8
	; d = s13:s03 = r13:r12
	movw  t0, s01
	eor   t0, s03
	eor   t1, s13
	and  s03, s01
	and  s13, s11
	eor  s02, s03
	eor  s12, s13
	movw  t2, s02
	eor  s02, s00
	eor  s12, s10
	com  s02
	com  s12
	eor  s00, t0
	eor  s10, t1
	movw s03, s00
	and   t0, s02
	and   t1, s12
	eor  s01,  t0
	eor  s11,  t1
	movw  t0, s03
	eor  s00, s01
	eor  s10, s11
	and  s00,  t2
	and  s10,  t3
	eor  s03, s00
	eor  s13, s10
	eor  s00, s01
	eor  s10, s11
	com  s00
	com  s10
	or   s01,  t0
	or   s11,  t1
	eor  s01,  t2
	eor  s11,  t3

	; a = s32:s22 = r1:r0
	; b = s33:s23 = r5:r4
	; c = s30:s20 = r9:r8
	; d = s31:s21 = r13:r12
	movw  t0, s21
	eor   t0, s23
	eor   t1, s33
	and  s23, s21
	and  s33, s31
	eor  s22, s23
	eor  s32, s33
	movw  t2, s22
	eor  s22, s20
	eor  s32, s30
	com  s22
	com  s32
	eor  s20, t0
	eor  s30, t1
	movw s23, s20
	and   t0, s22
	and   t1, s32
	eor  s21,  t0
	eor  s31,  t1
	movw  t0, s23
	eor  s20, s21
	eor  s30, s31
	and  s20,  t2
	and  s30,  t3
	eor  s23, s20
	eor  s33, s30
	eor  s20, s21
	eor  s30, s31
	com  s20
	com  s30
	or   s21,  t0
	or   s31,  t1
	eor  s21,  t2
	eor  s31,  t3
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

.MACRO iMixColumn
	// A4
	eor  s33, s21
	eor  s33, s11

	eor  s32, s21
	eor  s33, s22
	eor  s30, s23
	eor  s31, s20

	eor  s32, s11
	eor  s33, s12
	eor  s30, s13
	eor  s31, s10

	eor  s32, s02
	eor  s33, s03
	eor  s30, s00
	eor  s31, s01

	eor  s33, s32
	eor  s30, s33

	// A3
	eor  s23, s11
	eor  s23, s01

	eor  s22, s11
	eor  s23, s12
	eor  s20, s13
	eor  s21, s10

	eor  s22, s01
	eor  s23, s02
	eor  s20, s03
	eor  s21, s00

	eor  s22, s30
	eor  s23, s31
	eor  s20, s32
	eor  s21, s33

	eor  s23, s22
	eor  s20, s23

	// A2
	eor  s13, s01
	eor  s13, s33

	eor  s12, s01
	eor  s13, s02
	eor  s10, s03
	eor  s11, s00

	eor  s12, s33
	eor  s13, s30
	eor  s10, s31
	eor  s11, s32

	eor  s12, s20
	eor  s13, s21
	eor  s10, s22
	eor  s11, s23

	eor  s13, s12
	eor  s10, s13

	// A1
	eor  s03, s33
	eor  s03, s23

	eor  s02, s33
	eor  s03, s30
	eor  s00, s31
	eor  s01, s32

	eor  s02, s23
	eor  s03, s20
	eor  s00, s21
	eor  s01, s22

	eor  s02, s10
	eor  s03, s11
	eor  s00, s12
	eor  s01, s13

	eor  s03, s02
	eor  s00, s03

.ENDMACRO

.MACRO KeyXorSwitch
	lds k0, @0 +  0;
	eor s00, k0
	lds k0, @0 +  1;
	eor s10, k0
	lds k0, @0 +  2;
	eor s20, k0
	lds k0, @0 +  3;
	eor s30, k0
	lds k0, @0 +  4;
	eor s01, k0
	lds k0, @0 +  5;
	eor s11, k0
	lds k0, @0 +  6;
	eor s21, k0
	lds k0, @0 +  7;
	eor s31, k0
	lds k0, @0 +  8;
	eor s02, k0
	lds k0, @0 +  9;
	eor s12, k0
	lds k0, @0 + 10;
	eor s22, k0
	lds k0, @0 + 11;
	eor s32, k0
	lds k0, @0 + 12;
	eor s03, k0
	lds k0, @0 + 13;
	eor s13, k0
	lds k0, @0 + 14;
	eor s23, k0
	lds k0, @0 + 15;
	eor s33, k0
.ENDMACRO


.MACRO Key1XorSwitch
	KeyXorSwitch SRAM_KTEXT1E
.ENDMACRO

.MACRO Key2XorSwitch
	KeyXorSwitch SRAM_KTEXT2E
.ENDMACRO


.MACRO RCXorSwitch
	ld  k0, Z+

	bst  k0, 5
	brtc rc5
	eor  s00, m40 ; 01000000
	eor  s20, m40 ; 01000000
rc5:
	bst  k0, 4
	brtc rc4
	eor  s03, m40 ; 01000000
	eor  s23, m40 ; 01000000
rc4:
	eor  s01, m80 ; 10000000
	eor  s23, m80 ; 10000000

	bst  k0, 3
	brtc rc3
	eor  s02, m40 ; 01000000
	eor  s22, m40 ; 01000000
rc3:
	bst  k0, 2
	brtc rc2
	eor  s10, m40 ; 01000000
	eor  s30, m40 ; 01000000
rc2:
	bst  k0, 1
	brtc rc1
	eor  s13, m40 ; 01000000
	eor  s33, m40 ; 01000000
rc1:
	eor  s11, m80 ; 10000000
	eor  s33, m80 ; 10000000

	bst  k0, 0
	brtc rc0
	eor  s12, m40 ; 01000000
	eor  s32, m40 ; 01000000
rc0:
	eor  s12, m80 ; 10000000
	eor  s32, m80 ; 10000000
.ENDMACRO


.MACRO SR_1bits
	bst  @1, 7
	lsl  @1
	bld  @1, 4

	bst  @2, 7
	lsl  @2
	bld  @2, 4
	bst  @2, 7
	lsl  @2
	bld  @2, 4

	bst  @3, 4
	lsr  @3
	bld  @3, 7
.ENDMACRO

.MACRO SR
	SR_1bits s00, s10, s20, s30
	SR_1bits s01, s11, s21, s31
	SR_1bits s02, s12, s22, s32
	SR_1bits s03, s13, s23, s33
.ENDMACRO

.MACRO iSR_1bits
	bst  @1, 4
	lsr  @1
	bld  @1, 7

	bst  @2, 4
	lsr  @2
	bld  @2, 7
	bst  @2, 4
	lsr  @2
	bld  @2, 7

	bst  @3, 7
	lsl  @3
	bld  @3, 4
.ENDMACRO

.MACRO iSR
	iSR_1bits s00, s10, s20, s30
	iSR_1bits s01, s11, s21, s31
	iSR_1bits s02, s12, s22, s32
	iSR_1bits s03, s13, s23, s33
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
	loadRC
	ldi m40, 0b01000000
	ldi m80, 0b10000000
	ldi YH, high(SRAM_INITV)
	ldi YL, low(SRAM_INITV)
	ldi bn, 16
	clr bcnt
	loadInit
CBC16_encrypt_start:
	loadReorderInputSwitch

	ldi ZH, high(SRAM_KTEXTR)
	ldi ZL, low(SRAM_KTEXTR)
	ldi rrn, 6
	clr rcnt
loop_start_encrypt:

	Step1
	Step2

	inc rcnt
	cpse rcnt, rrn
	rjmp loop_start_encrypt

	Key1XorSwitch
	storeReorderOutputSwitch

	inc bcnt
	cpse bcnt, bn
	rjmp CBC16_encrypt_start
CBC16_encrypt_end:
ret
#endif

#if defined(DECRYPT)
iRoundFunction:
	iMixColumn
	iSR
	iSboxSwitch
	RCXorSwitch
ret

.MACRO iStep1
	Key1XorSwitch
	rcall iRoundFunction
	rcall iRoundFunction
	rcall iRoundFunction
	rcall iRoundFunction
.ENDMACRO

.MACRO iStep2
	Key2XorSwitch
	rcall iRoundFunction
	rcall iRoundFunction
	rcall iRoundFunction
	rcall iRoundFunction
.ENDMACRO

decrypt:
	iloadRC
	ldi m40, 0b01000000
	ldi m80, 0b10000000
	ldi YH, high(SRAM_INITV)
	ldi YL, low(SRAM_INITV)
	ldi bn, 16
	clr bcnt
CBC16_decrypt_start:
	loadReorderInputSwitchDec

	ldi ZH, high(SRAM_KTEXTR)
	ldi ZL, low(SRAM_KTEXTR)

	ldi rrn, 6
	clr rcnt
loop_start_decrypt:

	iStep1
	iStep2

	inc rcnt
	cpse rcnt, rrn
	rjmp loop_start_decrypt

	Key1XorSwitch
	storeReorderOutputSwitchDec

	inc bcnt
	cpse bcnt, bn
	rjmp CBC16_decrypt_start
CBC16_decrypt_end:
ret
#endif


RC:
; 1-24
.db 0x01,0x03,0x07,0x0F,0x1F,0x3E,0x3D,0x3B,0x37,0x2F,0x1E,0x3C,0x39,0x33,0x27,0x0E,0x1D,0x3A,0x35,0x2B,0x16,0x2C,0x18,0x30
; 25-48
.db 0x21,0x02,0x05,0x0B,0x17,0x2E,0x1C,0x38,0x31,0x23,0x06,0x0D,0x1B,0x36,0x2D,0x1A,0x34,0x29,0x12,0x24,0x08,0x11,0x22,0x04

; RoundFunction:
; RCXorSwitch
; |
; SboxSwitch
; |
; SR
; |
; M

; Step:
; |
; RoundFunction
; |
; RoundFunction
; |
; RoundFunction
; |
; RoundFunction


; loadReorderInputSwitch
; |                                            {
; |                                             i = 1
; Key1XorSwitch
; |
; Step
; |
; Key2XorSwitch
; |
; Step
; |                                             i = 2
; Key1XorSwitch
; |
; Step
; |
; Key2XorSwitch
; |
; Step
; |                                             i = 3
; Key1XorSwitch
; |
; Step
; |
; Key2XorSwitch
; |
; Step
; |                                             i = 4
; Key1XorSwitch
; |
; Step
; |
; Key2XorSwitch
; |
; Step
; |                                             i = 5
; Key1XorSwitch
; |
; Step
; |
; Key2XorSwitch
; |
; Step
; |                                             i = 6
; Key1XorSwitch
; |
; Step
; |
; Key2XorSwitch
; |
; Step
; |                                             }
; Key1XorSwitch
; |
; storeReorderOutputSwitch
