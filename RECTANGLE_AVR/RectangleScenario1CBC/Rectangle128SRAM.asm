;
; Constants
;
.EQU    INITV_NUM_BYTE = 8
.EQU    PTEXT_NUM_BYTE = (8*16)
.EQU    KEY_NUM_BYTE = 16
.EQU	KEYEXTENT_NUM_BYTE = (8 + 25*6)

#define KEYSCHEDULE
#define ENCRYPT
#define DECRYPT

; Registers declarations
.def k0 =r0
.def k1 =r1
.def k2 =r2
.def k3 =r3
.def k4 =r4
.def k5 =r5
.def k6 =r6
.def k7 =r7
.def k8 =r8
.def k9 =r9
.def k10=r10
.def k11=r11
.def k12=r12
.def k13=r13
.def k14=r14
.def k15=r15

.def s0 =r8
.def s1 =r9
.def s2 =r10
.def s3 =r11
.def s4 =r12
.def s5 =r13
.def s6 =r14
.def s7 =r15

.def t0 =r16
.def t1 =r17
.def t2 =r18
.def t3 =r19

.def kt0 =r0
.def kt1 =r1

.def dcnt  =r21
.def rcnt  =r22
.def rzero =r23

.def XL =r26
.def XH =r27

.def YL =r28
.def YH =r29

.def ZL =r30
.def ZH =r31

;*****************************************************************************
;;; load_key
;;; 
;;; load master key to:
;;; r3:r2:r1:r0
;;; r7:r6:r5:r4
;;; r11:r10:r9:r8
;;; r15:r14:r13:r12

.MACRO load_key
	ld  k0,  Y+
	ld  k1,  Y+
	ld  k2,  Y+
	ld  k3,  Y+
	ld  k4,  Y+
	ld  k5,  Y+
	ld  k6,  Y+
	ld  k7,  Y+
	ld  k8,  Y+
	ld  k9,  Y+
	ld  k10, Y+
	ld  k11, Y+
	ld  k12, Y+
	ld  k13, Y+
	ld  k14, Y+
	ld  k15, Y
.ENDMACRO

;;;****************************************************************************
;;;
;;; store_subkey_first
;;; 
.MACRO store_subkey_first
	st  Y+, k5	
	st  Y+, k13
	st  Y+, k0	
	st  Y+, k4	
	st  Y+, k8	
	st  Y+, k12
	st  Y+, k9	
	st  Y+, k1	
.ENDMACRO

;;;****************************************************************************
;;;
;;; store_subkey
;;; 
.MACRO store_subkey
	st  Y+, k0	
	st  Y+, k4	
	st  Y+, k8	
	st  Y+, k12
	st  Y+, k9	
	st  Y+, k1	
.ENDMACRO

;;;****************************************************************************
;;;
;;; load_init
;;;
.MACRO loadInitv
	ld  s0, X+
	ld  s1, X+
	ld  s2, X+
	ld  s3, X+
	ld  s4, X+
	ld  s5, X+
	ld  s6, X+
	ld  s7, X+
.ENDMACRO

;;;****************************************************************************
;;;
;;; load_input
;;;
.MACRO loadPlain
	ld  t0, X+
	eor s0, t0

	ld  t0, X+
	eor s1, t0

	ld  t0, X+
	eor s2, t0

	ld  t0, X+
	eor s3, t0

	ld  t0, X+
	eor s4, t0

	ld  t0, X+
	eor s5, t0

	ld  t0, X+
	eor s6, t0

	ld  t0, X+
	eor s7, t0
.ENDMACRO

;;;****************************************************************************
;;;
;;; store_output
;;; 
.MACRO storeCipher
	st  Y+, s0
	st  Y+, s1
	st  Y+, s2
	st  Y+, s3
	st  Y+, s4
	st  Y+, s5
	st  Y+, s6
	st  Y+, s7
.ENDMACRO

.MACRO loadCipher
	ld  s0, Y+
	ld  s1, Y+
	ld  s2, Y+
	ld  s3, Y+
	ld  s4, Y+
	ld  s5, Y+
	ld  s6, Y+
	ld  s7, Y+
.ENDMACRO

.MACRO storePlain
	ld t0, X
	eor s0, t0
	st X+, s0

	ld t0, X
	eor s1, t0
	st X+, s1

	ld t0, X
	eor s2, t0
	st X+, s2

	ld t0, X
	eor s3, t0
	st X+, s3

	ld t0, X
	eor s4, t0
	st X+, s4

	ld t0, X
	eor s5, t0
	st X+, s5

	ld t0, X
	eor s6, t0
	st X+, s6

	ld t0, X
	eor s7, t0
	st X+, s7
.ENDMACRO

;;;****************************************************************************
;;;
.MACRO forward_key_update
	;forward_key_sbox
	;k0, k4, k8, k12
	mov  t0, k8
	eor  k8, k4
	com  k4
	mov  t1, k0
	and  k0, k4
	or   k4, k12
	eor  k4, t1
	eor  k12, t0
	eor  k0, k12
	and  k12, k4
	eor  k12, k8
	or   k8, k0
	eor  k8, k4
	eor  k4, t0

	;w0: k3:k2:k1:k0
	;w1: k7:k6:k5:k4
	;w2: k11:k10:k9:k8
	;w3: k15:k14:k13:k12

	;t3:t2:t1:t0  <- w3: k15:k14:k13:k12
	movw t0, k12
	movw t2, k14
	
	;w3: k15:k14:k13:k12 <- w0: k3:k2:k1:k0
	movw  k12, k0
	movw  k14, k2

	;w0: k3:k2:k1:k0 <- w1: k7:k6:k5:k4
	movw  k0, k4
	movw  k2, k6

	;w1: k7:k6:k5:k4 <- w2: k11:k10:k9:k8
	movw  k4, k8
	movw  k6, k10

	;w2: k11:k10:k9:k8 <- t3:t2:t1:t0
	movw  k8, t0
	movw  k10, t2

	;w0: k3:k2:k1:k0 ^= w3<<<a k14:k13:k12:k15
	eor k0, k15
	eor k1, k12
	eor k2, k13
	eor k3, k14

	;w2: k11:k10:k9:k8 ^= w1<<<b w1: k5:k4:k7:k6
	eor k8, k6
	eor k9, k7
	eor k10, k4
	eor k11, k5

	;key_addRC
	lpm t0, Z+				; 1 ins, 3 clocks
	eor k0, t0				; 1 ins, 1 clock
.ENDMACRO

;;;****************************************************************************
;;;
;;; substitute sbox
;input/output state s1:s0: a
;input/output state s3:s2: b
;input/output state s5:s4: c
;input/output state s7:s6: d

; temporary register t1:t0
; temporary register t3:t2

.MACRO forward_sbox
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
.ENDMACRO

;;;****************************************************************************
;;;
;;; substitute inverse sbox
;input/output state s1:s0: a
;input/output state s3:s2: b
;input/output state s5:s4: c
;input/output state s7:s6: d

; temporary register t1:t0
; temporary register t3:t2

.MACRO invert_sbox
	movw  t0, s0

	and   s0, s4
	and   s1, s5

	eor   s0, s6
	eor   s1, s7

	or    s6, t0
	or    s7, t1

	eor   s6, s4
	eor   s7, s5

	eor   s2, s6
	eor   s3, s7

	movw  s4, s2

	eor   s2, t0
	eor   s3, t1

	eor   s2, s0
	eor   s3, s1

	com   s6
	com   s7

	movw  t0, s6

	or    s6, s2
	or    s7, s3

	eor   s6, s0
	eor   s7, s1

	and   s0, s2
	and   s1, s3

	eor   s0, t0
	eor   s1, t1
.ENDMACRO

.MACRO rotate16_left_row1
	lsl s2     
    rol s3     
    adc s2, rzero 
.ENDMACRO

.MACRO rotate16_left_row2
	swap s4
	swap s5
	movw t0, s4
	eor  t1, t0
	andi t1, 0xf0
	eor  s4, t1
	eor  s5, t1
.ENDMACRO

.MACRO rotate16_left_row3
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

.MACRO rotate16_right_row1
	bst s2, 0
    ror s3   
    ror s2    
    bld s3, 7
.ENDMACRO

.MACRO rotate16_right_row2
	swap s4
	swap s5
	movw t0, s4
	eor  t1, t0
	andi t1, 0x0f
	eor  s4, t1
	eor  s5, t1
.ENDMACRO

.MACRO rotate16_right_row3
	lsl s6     
    rol s7     
    adc s6, rzero 
	lsl s6     
    rol s7     
    adc s6, rzero 
	lsl s6     
    rol s7     
    adc s6, rzero 
.ENDMACRO

.MACRO forward_permutation
    rotate16_left_row1
    rotate16_left_row2
    rotate16_left_row3
.ENDMACRO

.MACRO invert_permutation
    rotate16_right_row1
    rotate16_right_row2
    rotate16_right_row3
.ENDMACRO

.MACRO keyxor
	eor s3, kt0
	eor s7, kt1
	ld  t0, Z+
	eor s0, t0
	ld  t0, Z+
	eor s2, t0
	ld  t0, Z+
	eor s4, t0
	ld  t0, Z+
	eor s6, t0
	ld  kt0, Z+
	eor s5, kt0
	ld  kt1, Z+
	eor s1, kt1
.ENDMACRO

.MACRO ikeyxor
	eor s1, kt1
	eor s5, kt0
	ld  t0, -Z
	eor s6, t0
	ld  t0, -Z
	eor s4, t0
	ld  t0, -Z
	eor s2, t0
	ld  t0, -Z
	eor s0, t0
	ld  kt1, -Z
	eor s7, kt1
	ld  kt0, -Z
	eor s3, kt0
.ENDMACRO

.MACRO forward_round
    keyxor
    forward_sbox
    forward_permutation
.ENDMACRO

.MACRO forward_last_round
    keyxor
.ENDMACRO

.MACRO invert_round
    ikeyxor
    invert_permutation
    invert_sbox
.ENDMACRO

.MACRO invert_last_round
    ikeyxor
.ENDMACRO

#if defined(KEYSCHEDULE)
keyschedule:
    ldi YH, high(SRAM_KEY)
    ldi YL, low(SRAM_KEY)
    load_key
	ldi YH, high(SRAM_SUBKEY)
    ldi YL, low(SRAM_SUBKEY)
	store_subkey_first
	ldi rcnt, 25
	clr rzero
	ldi ZH, high(RC<<1)
    ldi ZL, low(RC<<1)
keyschedule_start:
    forward_key_update
	store_subkey
	dec rcnt
	cpse rcnt, rzero
	rjmp keyschedule_start
keyschedule_last:
ret
#endif

#ifdef ENCRYPT
encrypt:
	clr rzero
	ldi dcnt,16
	ldi XH, high(SRAM_INITV)
	ldi XL, low(SRAM_INITV)
	loadInitv
	ldi YH, high(SRAM_PTEXT)
	ldi YL, low(SRAM_PTEXT)
CBC16_encrypt_start:
	ldi ZH, high(SRAM_SUBKEY)
	ldi ZL, low(SRAM_SUBKEY)
	ldi rcnt,25
    loadPlain
	ld kt0, Z+
	ld kt1, Z+
encrypt_start:
    forward_round
	dec rcnt
	cpse rcnt, rzero
	rjmp encrypt_start
    forward_last_round
    storeCipher
	dec dcnt
	cpse dcnt, rzero
	rjmp CBC16_encrypt_start
ret
#endif

#ifdef DECRYPT
decrypt:
    clr rzero
	ldi dcnt,16
	ldi XH, high(SRAM_INITV)
	ldi XL, low(SRAM_INITV)
    ldi YH, high(SRAM_PTEXT)
    ldi YL, low(SRAM_PTEXT)
CBC16_decrypt_start:
	ldi ZH, high(SRAM_SUBKEY + KEYEXTENT_NUM_BYTE)
    ldi ZL, low(SRAM_SUBKEY + KEYEXTENT_NUM_BYTE)
	ldi rcnt,25
    loadCipher
	ld kt1, -Z
	ld kt0, -Z
decrypt_start:
    invert_round
	dec rcnt
	cpse rcnt, rzero
	rjmp decrypt_start
    invert_last_round
    storePlain

	dec dcnt
	cpse dcnt, rzero
	rjmp CBC16_decrypt_start
ret
#endif

#if defined(KEYSCHEDULE)
RC:
.DB 0x01, 0x02, 0x04, 0x09, 0x12, 0x05, 0x0b, 0x16, 0x0c, 0x19, 0x13, 0x07, 0x0f, 0x1f, 0x1e, 0x1c, 0x18, 0x11, 0x03, 0x06, 0x0d, 0x1b, 0x17, 0x0e, 0x1d 
#endif
