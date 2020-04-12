; Random number generator
; Based on LCG algorithm
; https://en.wikipedia.org/wiki/Linear_congruential_generator
;
;
#define RND r5


init_rnd:
	ldi r18, 17
	mov RND, r18
	ret

; ------------------------------
; get random value
; ------------------------------
random:
	mov tmp1, RND
	lsl tmp1 ; x2
	lsl tmp1 ; x4
	lsl tmp1 ; x8
	lsl tmp1 ; x16
	add tmp1, RND ; x17
	
	subi tmp1, -53 ; 17x+53 % 256
	mov RND, tmp1
	ret



