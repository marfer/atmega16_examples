; My attempt to create FIFO buffer routines


; Structure of 16 bit addressed buffer:
; 0 - 2 bytes of buffer end pointer
; 2 - 2 bytes of read pointer
; 4 - 2 bytes of write pointer
; 6 - 1 byte of buffer flags
; 7 - X bytes of buffer data
#define BUFFER_HEADER_LENGTH 7
#define B_EP_OFFSET_H 	0x00
#define B_EP_OFFSET_L 	0x01
#define B_RP_OFFSET_H 	0x02
#define B_RP_OFFSET_L 	0x03
#define B_WP_OFFSET_H 	0x04
#define B_WP_OFFSET_L 	0x05
#define B_FLAGS_OFFSET 	0x06
#define B_DATA_OFFSET 	0x07

; if we go through the whole buffer to the start
#define B_FLAG_NEXT_ROUND 7


; ---------------------------------------
; Initialize 16 bit addressed buffer
; tmp2:tmp1 <- buffer length
; Y <- buffer ptr
init_buffer:
	subi tmp1, lo8(-B_DATA_OFFSET) 	; add header offset +1
	sbci tmp2, hi8(-B_DATA_OFFSET)
	add tmp1, YL
	adc tmp2, YH
	std Y+B_EP_OFFSET_H, tmp2
	std Y+B_EP_OFFSET_L, tmp1	; buffer end + 1
	mov tmp1, YH
	mov tmp2, YL
	subi tmp2, lo8(-B_DATA_OFFSET)
	sbci tmp1, hi8(-B_DATA_OFFSET)				; tmp1:tmp2 - start of data 
	std Y+B_RP_OFFSET_H, tmp1
	std Y+B_RP_OFFSET_L, tmp2 	; read pointer
	std Y+B_WP_OFFSET_H, tmp1
	std Y+B_WP_OFFSET_L, tmp2	; write pointer
	std Y+B_FLAGS_OFFSET, ZERO	; flags
	ldd tmp2, Y+B_EP_OFFSET_H
	ldd tmp1, Y+B_EP_OFFSET_L
	adiw Y, B_DATA_OFFSET
b_clear_data:
	st Y+, ZERO		; buffer data
	cp YH, tmp2
	brne b_clear_data
	cp YL, tmp1
	brne b_clear_data
	ret

; ---------------------------------------
; Push byte into buffer
; tmp1 <- byte to push
; Y <- buffer ptr
; tmp1 -> error if not zero
push_buffer:
	push tmp4
	push tmp3
	push tmp2
	push tmp1
	; check if buffer is full:
	ldd  tmp2, Y+B_FLAGS_OFFSET 	; tmp2 <- flags
	sbrs tmp2, B_FLAG_NEXT_ROUND 	
	rjmp pb_write 	
	; if next round flag:
	ldd tmp1, Y+B_RP_OFFSET_H 		; tmp1 = read_pointer_h
	ldd tmp2, Y+B_RP_OFFSET_L		; tmp2 = read_pointer_l
	ldd tmp3, Y+B_WP_OFFSET_H		; tmp3 = write_pointer_h
	ldd tmp4, Y+B_WP_OFFSET_L		; tmp4 = write_pointer_l
	cp tmp1, tmp3
	brne pb_write
	cp tmp2, tmp4
	brne pb_write
	; we go full round and now at read pointer - skip, buffer is full
	pop tmp1
	pop tmp2
	pop tmp3
	pop tmp4
	ret

pb_write:
	mov tmp3, YH	; tmp3:tmp4 - bufer_start
	mov tmp4, YL

	ldd tmp1, Y+B_WP_OFFSET_H	; tmp1 - w_ptr_h
	ldd tmp2, Y+B_WP_OFFSET_L	; tmp2 - w_ptr_l
	mov YH, tmp1
	mov YL, tmp2
	pop tmp1
	st Y+, tmp1		; Y = w_ptr+1
	push YH
	push YL

	mov YH, tmp3
	mov YL, tmp4
	ldd tmp3, Y+B_EP_OFFSET_H
	ldd tmp4, Y+B_EP_OFFSET_L	; tmp3:tmp4 = buffer_max_addr

	pop tmp2
	pop tmp1		; tmp1:tmp2 -> w_ptr+1 addr
	cp tmp3, tmp1
	brne pb_save
	cp tmp4, tmp2
	brne pb_save
	
	ldd tmp3, Y+B_FLAGS_OFFSET
	sbr tmp3, 1 << B_FLAG_NEXT_ROUND
	std Y+B_FLAGS_OFFSET, tmp3	; mark next round flag
	
	mov tmp1, YH				; reset w pointer for new round
	mov tmp2, YL
	subi tmp2, lo8(-B_DATA_OFFSET)
	sbci tmp1, hi8(-B_DATA_OFFSET)
	
pb_save:
	std Y+B_WP_OFFSET_H, tmp1
	std Y+B_WP_OFFSET_L, tmp2
	pop tmp2
	pop tmp3
	pop tmp4		
	clr tmp1
	ret

; ---------------------------------------
; Pop byte from buffer
; Y <- buffer ptr
; tmp1 -> byte readed
; tmp2 -> error if not zero
pop_buffer:
	push tmp3
	push tmp4

	; check if rp = wp
	ldd tmp4, Y+B_RP_OFFSET_H 		; tmp4 = read_pointer_h
	ldd tmp3, Y+B_RP_OFFSET_L		; tmp3 = read_pointer_l
	ldd tmp2, Y+B_WP_OFFSET_H		; tmp2 = write_pointer_h
	ldd tmp1, Y+B_WP_OFFSET_L		; tmp1 = write_pointer_l

	cp tmp4, tmp2
	brne pb_read_byte
	cp tmp3, tmp1
	brne pb_read_byte

	; check next round :
	ldd  tmp1, Y+B_FLAGS_OFFSET 	; tmp2 <- flags
	sbrc tmp1, B_FLAG_NEXT_ROUND 	
	rjmp pb_read_byte
	; nothing to read:
	pop tmp4
	pop tmp3
	ser tmp2
	clr tmp1
	ret
pb_read_byte:
	push YH
	push YL
	mov YH, tmp4
	mov YL, tmp3
	ld tmp1, Y+			; tmp1 = read byte
	mov tmp4, YH
	mov tmp3, YL		; tmp4:tmp3 -> r_ptr+1
	pop YL
	pop YH
	push tmp1
	ldd tmp1, Y+B_EP_OFFSET_H
	ldd tmp2, Y+B_EP_OFFSET_L	; tmp1:tmp2 = buffer_max_addr
	cp tmp1, tmp4
	brne pb_read_ok
	cp tmp2, tmp3
	brne pb_read_ok

	ldd tmp2, Y+B_FLAGS_OFFSET
	cbr tmp2, 1 << B_FLAG_NEXT_ROUND
	std Y+B_FLAGS_OFFSET, tmp2	; clear next round flag
	
	mov tmp4, YH				; reset r pointer for new round
	mov tmp3, YL
	subi tmp3, lo8(-B_DATA_OFFSET)
	sbci tmp4, hi8(-B_DATA_OFFSET)
pb_read_ok:
	std Y+B_RP_OFFSET_H, tmp4
	std Y+B_RP_OFFSET_L, tmp3

	pop tmp1
	clr tmp2
	pop tmp4
	pop tmp3
	ret

; ---------------------------------------
; copy null terminated string
; Z <- string pointer
; Y <- buffer
; tmp1 -> copied bytes
; ---------------------------------------
copy_to_buff:
	push tmp2
	clr tmp2
ctb_next:
	lpm tmp1, Z+
	tst tmp1
	breq ctb_done	; null str reached
	inc tmp2
	call push_buffer ; tmp1 -> error if not zero	
	cp tmp1, ZERO
	breq ctb_next
ctb_done:
	mov tmp1, tmp2
	pop tmp2
	ret

; ---------------------------------------
; move data from one buffer to another
; Z <- from
; Y <- to
; ---------------------------------------
move_buff:
	push tmp1
	push tmp2
	push tmp3
	push tmp4
	mov tmp3, YH
	mov tmp4, YL
mb_next:
	mov YH, ZH
	mov YL, ZL
	call pop_buffer
	tst tmp2
	brne mb_done
	mov YH, tmp3
	mov YL, tmp4
	call push_buffer
	tst tmp1
	brne mb_done
	rjmp mb_next
mb_done:
	pop tmp4
	pop tmp3
	pop tmp2
	pop tmp1
	ret

; ---------------------------------------
; Init buffer
; addr <- buffer address
; size <- buffer size
.macro INIT_BUFFER addr, size
	ldi tmp2, hi8(\size)
	ldi tmp1, lo8(\size)
	ldi YH, hi8(\addr)
	ldi YL, lo8(\addr)
	call init_buffer
.endm

; ---------------------------------------
; Push register into buffer
; buf <- buffer address
; reg <- register to push
; tmp1 -> error if not zero
.macro PUSH_BUFFER buf, reg
	mov tmp1, \reg
	ldi YH, hi8(\buf)
	ldi YL, lo8(\buf)
	call push_buffer
.endm

; ---------------------------------------
; Pop byte to tmp1
; buf <- buffer address
; tmp1 -> byte readed
; tmp2 -> error if not zero
.macro POP_BUFFER buf
	ldi YH, hi8(\buf)
	ldi YL, lo8(\buf)
	call pop_buffer
.endm

; ---------------------------------------
; copy null terminated string
; X <- string pointer
; Y <- buffer
; tmp1 -> copied bytes
.macro BUFFER_COPY_NSTR buff, str
	LDY \buff
	LDZ \str
	call copy_to_buff
.endm

; ---------------------------------------
; move data from one buffer to another 
.macro BUFFER_MOVE from to
	LDZ \from
	LDY \to
	call move_buff
.endm
