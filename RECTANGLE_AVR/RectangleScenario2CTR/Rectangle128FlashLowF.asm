
.EQU    COUNTER_BYTE = 8
.EQU    COUNT_NUM_BYTE = (8)
.EQU    PTEXT_NUM_BYTE = (8*2)

#define ENCRYPT

; Registers declarations
.def s0 =r0
.def s1 =r1
.def s2 =r2
.def s3 =r3
.def s4 =r4
.def s5 =r5
.def s6 =r6
.def s7 =r7

.def s10 =r8
.def s11 =r9
.def s12 =r10
.def s13 =r11
.def s14 =r12
.def s15 =r13
.def s16 =r14
.def s17 =r15

.def t0 =r16
.def t1 =r17
.def t2 =r18
.def t3 =r19

.def rrn   =r20
.def rcnt  =r21
.def rzero =r22

.def kt0 =r24
.def kt1 =r25


.def YL =r28
.def YH =r29
.def ZL =r30
.def ZH =r31

;;;****************************************************************************
;;;
;;; store_output
;;; 
.MACRO store_output
	ld  t0, Y
	eor s0, t0
	st  Y+, s0

	ld  t0, Y
	eor s1, t0
	st  Y+, s1

	ld  t0, Y
	eor s2, t0
	st  Y+, s2

	ld  t0, Y
	eor s3, t0
	st  Y+, s3

	ld  t0, Y
	eor s4, t0
	st  Y+, s4

	ld  t0, Y
	eor s5, t0
	st  Y+, s5

	ld  t0, Y
	eor s6, t0
	st  Y+, s6

	ld  t0, Y
	eor s7, t0
	st  Y+, s7
.ENDMACRO

;;;****************************************************************************
.MACRO keyxor
	eor s3, kt0

	eor s7, kt1

	lpm  t0, Z+
	eor s0, t0

	lpm  t0, Z+
	eor s2, t0

	lpm  t0, Z+
	eor s4, t0

	lpm  t0, Z+
	eor s6, t0

	lpm  kt0, Z+
	eor s5, kt0

	lpm  kt1, Z+
	eor s1, kt1
.ENDMACRO


;;;****************************************************************************
.MACRO forward_round
    keyxor

    ;forward_sbox block0
	movw t0, s4

	eor  s4, s2
	eor  s5, s3

	com  s2
	com  s3

	movw t2, s0

	and  s0, s2
	and  s1, s3

	or   s2, s6
	or   s3, s7

	eor  s6, t0
	eor  s7, t1

	eor  s0, s6
	eor  s1, s7

	eor  s2, t2
	eor  s3, t3

	and  s6, s2
	and  s7, s3

	eor  s6, s4
	eor  s7, s5

	or   s4, s0
	or   s5, s1

	eor  s4, s2
	eor  s5, s3

	eor  s2, t0
	eor  s3, t1

    ;forward_permutation block0
    ;rotate16_left_row1 <<< 1
	lsl s2     
    rol s3     
    adc s2, rzero 
	
	;rotate16_left_row2 <<< 12 = >>> 4
	swap s4
	swap s5
	movw t0, s4
	eor  t1, t0
	andi t1, 0xf0
	eor  s4, t1
	eor  s5, t1
	
	;rotate16_left_row3 <<< 13 = >>> 3 = ((>>>4)<<<1)
	swap s6
	swap s7
	movw t0, s6
	eor  t1, t0
	andi t1, 0xf0
	eor  s6, t1
	eor  s7, t1

	lsl  s6     
    rol  s7     
    adc  s6, rzero 
.ENDMACRO

.MACRO forward_last_round
    keyxor
.ENDMACRO

#ifdef ENCRYPT
encrypt:
	clr rzero
	ldi XH, high(SRAM_COUNT)
	ldi XL, low(SRAM_COUNT)
	ld s0, X+
	ld s1, X+
	ld s2, X+
	ld s3, X+
	ld s4, X+
	ld s5, X+
	ld s6, X+
	ld s7, X+
	movw s10, s0
	movw s12, s2
	movw s14, s4
	movw s16, s6
	inc s17

	ldi YH, high(SRAM_PTEXT) ;SRAM_PTEXT
    ldi YL, low(SRAM_PTEXT) ;SRAM_PTEXT
	ldi rrn, 1
blocks:
	ldi rcnt, 25
	ldi ZH, high(RK<<1)
    ldi ZL, low(RK<<1)
	lpm kt0, Z+
	lpm kt1, Z+
encrypt_start:
    forward_round
	dec rcnt
	cpse rcnt, rzero
	rjmp encrypt_start
    forward_last_round
    store_output
	dec rrn
	cpse rrn, rzero
	rjmp encrypt_end
	movw s0, s10
	movw s2, s12
	movw s4, s14
	movw s6, s16
	rjmp blocks
encrypt_end:
ret

; master key is: 10 0f 0e 0d 0c 0b 0a 09 08 07 06 05 04 03 02 01
; reordered: 0 1 2 3 4 5 6 7 => 3 7 0 2 4 6 5 1 and then remove the duplicated 3 7 inter-round
RK:
.db 0x0b, 0x03, 0x10, 0x0c, 0x08, 0x04, 0x07, 0x0f
.db 0xe3, 0xfb, 0x06, 0x1c, 0x06, 0x17
.db 0xfc, 0x00, 0x1e, 0x1a, 0x09, 0x1d
.db 0x19, 0xfd, 0x10, 0xf8, 0x1c, 0xfe
.db 0xed, 0x0e, 0xf5, 0xe8, 0x13, 0xe1
.db 0x1c, 0xeb, 0xf0, 0xfc, 0xe2, 0xe0
.db 0xeb, 0xfb, 0x14, 0x18, 0xe5, 0x0b
.db 0xed, 0x18, 0xe0, 0x0c, 0xed, 0xee
.db 0x0f, 0xfb, 0xf9, 0x09, 0x10, 0xec
.db 0xfe, 0xf4, 0x06, 0xf4, 0x06, 0x19
.db 0xe0, 0xfb, 0x02, 0xf8, 0x07, 0xe8
.db 0x08, 0xe7, 0xff, 0xfa, 0x16, 0xfc
.db 0xfc, 0xef, 0x12, 0x0d, 0x11, 0x0a
.db 0xeb, 0x1e, 0x0e, 0x0f, 0xef, 0x19
.db 0x0e, 0xf4, 0x16, 0xe0, 0xed, 0xf1
.db 0xfe, 0x1b, 0x10, 0xfc, 0xe1, 0x13
.db 0x02, 0x09, 0x10, 0x08, 0x07, 0xe5
.db 0xfb, 0xe7, 0xe3, 0x1a, 0xe1, 0xfb
.db 0xe0, 0x04, 0xf5, 0xe1, 0xee, 0xe6
.db 0xe1, 0xee, 0xe0, 0xf4, 0x15, 0x15
.db 0xe0, 0x0b, 0x0a, 0x15, 0xfb, 0xfb
.db 0x0a, 0xea, 0x06, 0xff, 0x0c, 0xea
.db 0xe1, 0x08, 0x01, 0xf9, 0x12, 0x02
.db 0xfa, 0x07, 0x0d, 0x19, 0xfe, 0x15
.db 0x11, 0xed, 0xe6, 0xec, 0x19, 0xfe
.db 0x1e, 0xf4, 0x14, 0x1a, 0x19, 0xe4
#endif
