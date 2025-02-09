****************************************************************************
* Demons Are Forever - Doctor Mabuse Orgasm Cracking (D.O.C)
*
* Coding:   Unknown
* Music:    Frog
* Graphics: Esteban
*           Future Light
*           Zoci Joe
* Text:     Dr. Mabuse
*
* Disassembly: MnemoTroN/Spreadpoint in Feb 2025
*
* Fixes: Self-modifying code removed
*        Use scanline wait for music DMA
*        Limit Copper wait for scroller to line 319
*        Fully relocatable exe
*        Uses BSS hunk for bitplanes
****************************************************************************

	opt	o+

	section	main,code

;Include modern startup code by StingRay.
;Calls MAIN. Will return to the OS for us.

	INCLUDE	"startup.i"

; Original location of the code was $3B000
;	ORG $3B000

MAIN:

;MTN: Added this for dynamic bitplane setup
	bsr	init_pointers

	lea	lbW000EE8,a0
	move.w	#19,d0
lbC000040:
	cmp.w	#8,(a0)
	beq.s	lbC000050
	move.w	#$555,(a0)+
	move.w	#$888,(a0)+
	bra.s	lbC000058

lbC000050:
	move.w	#$888,(a0)+
	move.w	#$555,(a0)+
lbC000058:
	dbra	d0,lbC000040

;Copy the background to the visible bitplanes
	lea	background,a0
	lea	lbL025000,a1
	move.w	#(44*220*4)/4-1,d0
copy_bg:
	move.l	(a0)+,(a1)+
	dbra	d0,copy_bg

	lea	scr_bitplane,a0
	move.w	#(clear_size/4)-1,d0
	moveq	#0,d1
scroll_clr:
	move.l	d1,(a0)+
	dbra	d0,scroll_clr

	lea	bob_pal,a0
	lea	lbW000FBE,a1
	move.w	#14,d0
lbC000092:
	move.w	(a0)+,(a1)
	addq.l	#4,a1
	dbra	d0,lbC000092

	lea	cop_scope,a0
	move.w	#24,d0
	move.l	#$2109FFFE,d1
lbC0000AA:
	move.l	d1,(a0)+
	move.l	#$1800000,(a0)+
	move.l	d1,(a0)+
	move.l	#$1800000,(a0)+
	move.l	#$1800000,(a0)+
	add.l	#$1000000,d1
	dbra	d0,lbC0000AA

	lea	lbL000E02,a0
	lea	lbL000E2A,a1
	move.w	#9,d0
	move.l	#$3FE,d1
	move.l	#$11A,d2
lbC0000E6:
	move.l	d1,(a0)+
	move.l	d2,(a1)+
	dbra	d0,lbC0000E6

;MTN: Moved to here after the copper list has been fully set up
	move.l	#copperlist,$DFF080
	move.w	d0,$DFF088
	move.w	#4,$DFF104

	jsr	mt_init

mainloop:
	cmp.b	#$F1,$DFF006
	bne.s	mainloop

	btst	#6,$bfe001
	beq.s	quit

	move.b	#'C',bob_blitmode	;clear?
	bsr	blit_bobs
	bsr	lbC00047A
	move.b	#'S',bob_blitmode	;set?
	bsr	blit_bobs
	jsr	mt_music
	bsr	draw_shadows

	tst.b	lbB000DF6
	bne.s	lbC00013C
	move.w	scroll_speed,d3
lbC000130:
	bsr	scroll_scroller
	sub.b	#1,d3
	bne.s	lbC000130
	bra.s	lbC000144

lbC00013C:
	sub.b	#1,lbB000DF6
lbC000144:
	bsr	draw_scope
	bsr	scope_new_notes
	bsr	zoom_floor
	move.b	lbB000153,d3
lbC000154:
	bsr	scr_dobounce
	subq.b	#1,d3
	bne.s	lbC000154
	bsr	show_numbers
	bsr	handle_bobpos
	bsr	bo_bob_move_params
	bsr	kb_control
	bra	mainloop
quit:
	rts

; MTN: Added for setting pointers dynamically
init_pointers:
	lea	menuspr0,a0
	lea	cop_spr0ptr,a1
	bsr.s	set_copptr
	add.w	#menusprsize,a0
	bsr.s	set_copptr
	add.w	#menusprsize,a0
	bsr.s	set_copptr
	add.w	#menusprsize,a0
	bsr.s	set_copptr
	add.w	#menusprsize,a0
	bsr.s	set_copptr
	
	lea	nullspr,a0
	bsr.s	set_copptr
	bsr.s	set_copptr
	bsr.s	set_copptr

	lea	lbL025000,a0
	lea	cop_bpl0ptr,a1
	bsr.s	set_copptr
	add.w	#44,a0			;width of bitplanes in bytes
	bsr.s	set_copptr
	add.w	#44,a0
	bsr.s	set_copptr
	add.w	#44,a0
	bsr.s	set_copptr

	lea	shadow_bitpl,a0
	lea	cop_bpl5ptr,a1
	bsr.s	set_copptr
	add.w	#44,a0
	bsr.s	set_copptr

;scroll bitplane
	lea	scr_bitplane,a0
	lea	cop_bpl0ptr_scr,a1
	bsr.s	set_copptr
	add.w	#20*48,a0		;20 lines * 48 bytes
	bsr.s	set_copptr
	rts

; MTN: Added for setting pointers dynamically
set_copptr:
	move.l	a0,d0
	swap	d0
	move.w	d0,(a1)		;HI
	move.w	a0,4(a1)	;LO
	addq.w	#8,a1		;standard offset to next ptr pair in Copper list
	rts

show_numbers:
	move.l	#lbB0212C9,lbW0001E0
	move.l	#lbB0213B5,lbC0001F4
	move.l	#lbB0213B4,lbC000206
	lea	lbL000DDC,a5
	move.w	#3,d5
lbC000198:
	move.l	(a5)+,d0
	bsr.s	lbC0001C0
	add.l	#$1C,lbW0001E0
	add.l	#$1C,lbC0001F4
	add.l	#$1C,lbC000206
	dbra	d5,lbC000198
	rts

lbC0001C0:
	cmp.w	#3,d5
	bne.s	lbC0001C8
	asr.w	#1,d0
lbC0001C8:
	cmp.w	#1,d5
	bne.s	lbC0001D0
	asr.w	#1,d0
lbC0001D0:
	and.w	#$1FF,d0
	move.w	d0,d1
	divu	#$100,d1
	mulu	#6,d1
	move.l	lbW0001E0,a1
	bsr.s	lbC00020A

	clr.l	d1
	move.b	d0,d1
	and.b	#15,d1
	mulu	#6,d1
	move.l	lbC0001F4,a1
	bsr.s	lbC00020A

	clr.l	d1
	move.b	d0,d1
	asr.l	#4,d1
	mulu	#6,d1
	move.l	lbC000206,a1

lbC00020A:
	lea	spr_digits,a0
	add.w	d1,a0
	move.w	#4,d4
lbC000216:
	move.b	(a0)+,(a1)
	addq.l	#4,a1
	dbra	d4,lbC000216
	rts

bo_bob_move_params:
	tst.b	kb_menu_flag
	beq.s	set_move_data
	rts

set_move_data:
	tst.w	move_frame_count
	beq.s	next_move
	subq.w	#1,move_frame_count
	rts

next_move:
	move.l	moves_ptr,a0
	add.l	#20,moves_ptr
	cmp.l	#'ende',(a0)
	beq.s	lbC000274
	lea	lbL000DDC,a1
	move.l	(a0)+,(a1)+	;copy parameters
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)
	move.b	(a1),d4
	tst.b	d4
	beq	lbC000272
	move.b	#1,lbB000DED
lbC000272:
	rts

lbC000274:
	move.l	#moves_table,moves_ptr
	bra.s	set_move_data

kb_control:
	tst.b	control_disable
	beq.s	lbC00028A
	rts

lbC00028A:
	bsr	get_key
	tst.b	kb_menu_flag
	beq	lbC0003E8
	cmp.b	#$46,d0			;Del
	bne.s	lbC0002B8
	eor.w	#$20,bplcon2_ctrl
	not.w	cop_color17
	not.w	cop_color21
	not.w	cop_color25
lbC0002B8:
	cmp.b	#$50,d0			;F1
	bne.s	lbC0002C4
	addq.l	#2,lbL000DE4
lbC0002C4:
	cmp.b	#$51,d0			;F2
	bne.s	lbC0002D0
	subq.l	#2,lbL000DE4
lbC0002D0:
	cmp.b	#$52,d0			;F3
	bne.s	lbC0002DC
	addq.l	#1,lbL000DE8
lbC0002DC:
	cmp.b	#$53,d0			;F4
	bne.s	lbC0002E8
	subq.l	#1,lbL000DE8
lbC0002E8:
	cmp.b	#$54,d0			;F5
	bne.s	lbC0002FA
	addq.l	#2,lbL000DE4
	addq.l	#1,lbL000DE8
lbC0002FA:
	cmp.b	#$55,d0			;F6
	bne.s	lbC00030C
	subq.l	#2,lbL000DE4
	subq.l	#1,lbL000DE8
lbC00030C:
	cmp.b	#$56,d0			;F7
	bne.s	lbC00031E
	addq.l	#2,lbL000DDC
	addq.l	#1,lbL000DE0
lbC00031E:
	cmp.b	#$57,d0			;F8
	bne.s	lbC000330
	subq.l	#2,lbL000DDC
	subq.l	#1,lbL000DE0
lbC000330:
	cmp.b	#1,lbB000DED
	beq.s	lbC000360
	cmp.b	#$58,d0			;F9
	bne.s	lbC000348
	move.b	#3,lbB000DED
lbC000348:
	cmp.b	#1,lbB000DED
	beq.s	lbC000360
	cmp.b	#$59,d0			;F10
	bne.s	lbC000360
	move.b	#2,lbB000DED
lbC000360:
	cmp.b	#$20,d0			;A
	bne.s	lbC000376
	move.b	#1,lbB000DED
	move.b	#1,lbB000DF0
lbC000376:
	cmp.b	#$35,d0			;B
	bne.s	lbC00038C
	move.b	#1,lbB000DED
	move.b	#2,lbB000DF0
lbC00038C:
	cmp.b	#$33,d0			;C
	bne.s	lbC0003A2
	move.b	#1,lbB000DED
	move.b	#3,lbB000DF0
lbC0003A2:
	cmp.b	#$22,d0			;D
	bne.s	lbC0003B8
	move.b	#1,lbB000DED
	move.b	#4,lbB000DF0
lbC0003B8:
	cmp.b	#$4C,d0			;Up
	bne.s	lbC0003C4
	subq.l	#1,lbL000DE0
lbC0003C4:
	cmp.b	#$4D,d0			;Down
	bne.s	lbC0003D0
	addq.l	#1,lbL000DE0
lbC0003D0:
	cmp.b	#$4F,d0			;Left
	bne.s	lbC0003DC
	subq.l	#2,lbL000DDC
lbC0003DC:
	cmp.b	#$4E,d0			;Right
	bne.s	lbC0003E8
	addq.l	#2,lbL000DDC
lbC0003E8:
	cmp.b	#$43,d0			;Enter
	bne.s	lbC000418
	bchg	#0,kb_menu_flag
	beq.s	lbC00041A
	move.w	#4,bplcon2_ctrl
	move.w	#$F000,cop_color17
	move.w	#$F000,cop_color21
	move.w	#$F000,cop_color25
lbC000418:
	rts

lbC00041A:
	move.w	#$24,bplcon2_ctrl
	move.w	#$FFF,cop_color17
	move.w	#$FFF,cop_color21
	move.w	#$FFF,cop_color25
	move.b	#2,lbB000DED
	rts

get_key:
	move.b	$BFED01,d0
	btst	#3,d0
	beq.s	lbC000460
	move.b	$BFEC01,d0
	not.b	d0
	btst	#0,d0
	bne.s	lbC000460
	lsr.b	#1,d0
lbC000460:
	bset	#6,$BFEE01

;	move.w	#$80,d1
;.delay:
;	dbra	d1,.delay

;MTN: Use raster line wait for faster processors
	MOVEQ	#2,D2
.waitlines:
	MOVE.B	$DFF006,D1
.sameline:
	CMP.B	$DFF006,D1
	BEQ.S	.sameline
	DBRA	D2,.waitlines

	bclr	#6,$BFEE01
	rts

lbC00047A:
	tst.b	lbB000DEC
	beq.s	lbC0004B0
	tst.b	lbB000DED
	bne	lbC00053C
	move.b	#2,lbB000DED
	clr.l	d0
	move.b	lbB000DEC,d0
	clr.b	lbB000DEC
	clr.l	lbL000E02
	clr.l	lbL000E2A
	bra.s	lbC00050E

lbC0004B0:
	tst.b	lbB000DF0
	beq	lbC00053C
	tst.b	lbB000DED
	bne	lbC00053C

	move.b	#2,lbB000DED
	clr.l	lbL000E02
	clr.l	lbL000E2A
	move.l	#4,lbL000DDC
	move.l	#2,lbL000DE0
	move.l	#$66,lbL000DE4
	move.l	#$33,lbL000DE8

	clr.l	d0
	move.b	lbB000DF0,d0
	clr.b	lbB000DF0
lbC00050E:
	sub.b	#1,d0
	mulu	#$600,d0

	lea	lbW021500,a0
	add.l	d0,a0
	move.l	a0,lbL0005A8
	move.l	a0,lbL00070C
	add.l	#$400,a0
	move.l	a0,lbL0005B4
	move.l	a0,lbL000718

lbC00053C:
	lea	lbL000E02,a0
	lea	lbL000E2A,a1
	move.w	#8,d0
	move.l	lbL000DDC,d1
	move.l	lbL000DE0,d2
	add.l	d1,(a0)
	add.l	d2,(a1)
	and.l	#$3FF,(a0)
	and.l	#$1FF,(a1)
	move.l	lbL000DE4,d3
	move.l	lbL000DE8,d4
	move.l	(a0)+,d5
	move.l	(a1)+,d6
lbC000578:
	add.l	d3,d5
	move.l	d5,(a0)
	add.l	d4,d6
	move.l	d6,(a1)
	and.l	#$3FF,(a0)+
	and.l	#$1FF,(a1)+
	dbra	d0,lbC000578
	rts

blit_bobs:
	lea	lbL000E02,a0
	lea	lbL000E2A,a1
	move.w	#9,d4
lbC0005A2:
	move.l	(a0)+,d2
	move.l	(a1)+,d3
	move.l	lbL0005A8,a2
	add.l	d2,a2
	clr.l	d2
	move.w	(a2),d2
	move.l	lbL0005B4,a2
	add.l	d3,a2
	clr.l	d3
	move.b	(a2),d3
	bsr.s	bobaddr_from_xy
	cmp.b	#'C',bob_blitmode
	beq.s	lbC0005CE
	bsr.s	bob_blit
	bra.s	lbC0005D2

lbC0005CE:
	bsr	bob_restore
lbC0005D2:
	dbra	d4,lbC0005A2
	rts

; d2=x, d3=y
bobaddr_from_xy:
	lea	lbL025000,a2
	addq.l	#2,d2
	mulu	#176,d3		;4*44
	add.l	d3,a2
	divu	#16,d2
	move.l	d2,d0
	lsl.w	#1,d2
	and.l	#$FFFF,d2
	add.l	d2,a2
	swap	d0
	lsl.b	#4,d0
	and.l	#$F0,d0
	and.l	#$FFF0000,bob_bplcon0
	or.b	d0,bob_bplcon0
	or.b	d0,bob_bplcon0+2
	rts

bob_blit:
	btst.b	#6,$DFF002
	bne.s	bob_blit
	move.l	bob_bplcon0,$DFF040	;BPLCON0
	move.l	#$FFFF0000,$DFF044
	move.l	bob_data,$DFF04C
	move.l	bob_mask,$DFF050
	move.l	a2,$DFF048
	move.l	a2,$DFF054
	move.l	#$26FFFE,$DFF060
	move.l	#$FFFE0026,$DFF064
	move.w	#100<<6+3,$DFF058	;$1903 (25*4 bitpl = 100)
	rts

bob_restore:
	btst.b	#6,$DFF002
	bne.s	bob_restore
	move.l	#$9F00000,$DFF040
	move.l	#$FFFFFFFF,$DFF044
	move.l	a2,$DFF054
;	add.l	#$10000,a2		;specific offset to background image in original memory layout
	sub.l	#lbL025000,a2		;MTN: sub address of work background
	add.l	#background,a2		;MTN: add base of background
	move.l	a2,$DFF050
	move.l	#$260026,$DFF064
	move.w	#100<<6+3,$DFF058	;$1903 (25*4 bitpl = 100)
	rts

draw_shadows:

	btst.b	#6,$DFF002
	bne.s	draw_shadows

;Clear shadow bitplane
	move.l	#$9F00000,$DFF040
	clr.l	$DFF044			;BLTAFWM/BLTALWM
	clr.l	$DFF064			;BLTAMOD/BLTDMOD
	move.l	#shadow_bitpl,$DFF050	;$6A7D0
	move.l	#shadow_bitpl2,$DFF054	;$6B2FC; $2F7D0 + $B2C (=2860 bytes = 65 * 44 bytes)
	move.w	#33<<6+44,$DFF058	;$86C (33 lines * 88 bytes = 66 lines * 44 bytes)

	lea	lbL000E02,a0
	lea	lbL000E2A,a1
	move.w	#9,d4
shadow_loop:
	clr.l	d2
	clr.l	d3
	move.l	(a0)+,d5
	move.l	lbL00070C,a2
	add.l	d5,a2
	move.w	(a2),d2
	move.l	(a1)+,d5
	move.l	lbL000718,a2
	add.l	d5,a2
	move.b	(a2),d3
	sub.l	#12,d3
	divu	#15,d3
	bsr	bobaddr_from_xy
;	add.l	#$B2FC,a2
	sub.l	#lbL025000,a2			;MTN: sub base of display bitplanes
	add.l	#shadow_bitpl2,a2		;MTN: add base of shadow bitplane
	and.l	#$FFF0000,shadow_bplcon0
	or.b	d0,shadow_bplcon0
	or.b	d0,shadow_bplcon0+2

lbC00074A:
	btst.b	#6,$DFF002
	bne.s	lbC00074A

	move.l	shadow_bplcon0,$DFF040
	move.l	#$FFFF0000,$DFF044
	move.l	bob_mask,$DFF04C
	move.l	bob_mask,$DFF050
	move.l	a2,$DFF048
	move.l	a2,$DFF054
	move.l	#$AA003A,$DFF060
	move.l	#$3A00AA,$DFF064
	move.w	#7<<6+3,$DFF058		;$1C3
	dbra	d4,shadow_loop
	rts

scroll_scroller:
	tst.w	cop_bplcon1
	beq.s	lbC0007BC
	sub.w	#$11,cop_bplcon1
	rts

lbC0007BC:
	btst.b	#6,$DFF002
	bne.s	lbC0007BC
	move.l	#$89F00000,$DFF040
	move.l	#$FFFFFFFF,$DFF044
	move.l	#scr_bitplane+2,$DFF050
	move.l	#scr_bitplane,$DFF054
	clr.l	$DFF064
	move.w	#40<<6+24,$DFF058
	move.w	#$77,cop_bplcon1
	bchg	#0,lbB000DD3
	beq.s	do_scrolltext
	rts

do_scrolltext:
	move.l	scrollptr,a0
	add.l	#1,scrollptr
	move.b	(a0),d0
	cmp.b	#$FF,d0
	bne.s	scroll_notend
	move.l	#scrolltext,scrollptr
	bra.s	do_scrolltext

scroll_notend:
	cmp.b	#'S',d0
	bne.s	scr_notspeed
	move.l	scrollptr,a0
	add.l	#1,scrollptr
	move.b	(a0),d0
	sub.b	#$30,d0
	ext.w	d0
	move.w	d0,scroll_speed
	bra.s	do_scrolltext

scr_notspeed:
	cmp.b	#'U',d0
	bne.s	lbC000884
	move.b	#1,lbB000DF4
	move.l	scrollptr,a0
	add.l	#1,scrollptr
	move.b	(a0),d0
	sub.b	#$30,d0
	move.b	d0,lbB000153
	bra.s	do_scrolltext

lbC000884:
	cmp.b	#'K',d0
	bne.s	scr_not_enable_ctrl
	clr.b	control_disable
	bra	do_scrolltext

scr_not_enable_ctrl:
	cmp.b	#'N',d0
	bne.s	scr_not_bounce
	move.b	#1,scr_bouncing
	clr.b	lbB000DF4
	bra	do_scrolltext

scr_not_bounce:
	cmp.b	#'W',d0
	bne.s	lbC0008CC
	move.l	scrollptr,a0
	add.l	#1,scrollptr
	move.b	(a0),d0
	move.b	d0,lbB000DF6
	rts

lbC0008CC:
	lea	chartab,a0
	clr.l	d1
char_loop:
	cmp.b	(a0)+,d0
	beq.s	char_found
	add.b	#1,d1
	cmp.b	#46,d1
	bne.s	char_loop
	move.b	#$30,d1
char_found:
	asl.b	#1,d1
	lea	scrollfont,a0
	add.l	d1,a0
lbC0008F0:
	btst.b	#6,$DFF002
	bne.s	lbC0008F0
	move.l	#$9F00000,$DFF040
	move.l	#$FFFFFFFF,$DFF044
	move.l	a0,$DFF050
	move.l	#scr_bitplane+$2e,$DFF054
	move.l	#$62002E,$DFF064
	move.w	#40<<6+1,$DFF058	;$A01
	rts

scr_dobounce:
	tst.b	scr_bouncing
	bne.s	lbC00096A
	tst.b	lbB000DF4
	beq.s	lbC000968
	bsr.s	scr_rotbouncetab
;	move.b	scr_bouncetab,cop_scrollw1
;	add.b	#25,cop_scrollw1
;	move.b	cop_scrollw1,cop_scrollw2
;	add.b	#20,cop_scrollw2

	move.b	scr_bouncetab,d0
	add.b	#25,d0
	move.b	d0,cop_scrollw1
	add.b	#20,d0
	cmp.b	#56,d0			;limit wait to scanline 312 (-256 = 56)
	ble.s	.yok
	move.b	#56,d0
.yok:
	move.b	d0,cop_scrollw2
lbC000968:
	rts

lbC00096A:
	bsr.s	scr_rotbouncetab
;	move.b	scr_bouncetab,cop_scrollw1
;	add.b	#25,cop_scrollw1
;	move.b	cop_scrollw1,cop_scrollw2
;	add.b	#20,cop_scrollw2

	move.b	scr_bouncetab,d0
	add.b	#25,d0
	move.b	d0,cop_scrollw1
	add.b	#20,d0
	cmp.b	#56,d0
	ble.s	.yok
	move.b	#56,d0
.yok:
	move.b	d0,cop_scrollw2

	tst.b	scr_bouncetab
	bne.s	lbC00099E
	clr.b	scr_bouncing
lbC00099E:
	rts

; rotate the y bounce table
scr_rotbouncetab:
	lea	scr_bouncetab,a0
	move.w	#59,d0
	move.b	(a0),d1
lbC0009AC:
	move.b	1(a0),(a0)+
	dbra	d0,lbC0009AC
	move.b	d1,-(a0)
	rts

handle_bobpos:
	cmp.b	#1,lbB000DED
	beq.s	lbC0009DA
	cmp.b	#2,lbB000DED
	beq.s	lbC000A26
	cmp.b	#3,lbB000DED
	beq	lbC000A8A
	rts

lbC0009DA:
	tst.b	anim_delay
	beq.s	lbC0009EC
	sub.b	#1,anim_delay
	rts

lbC0009EC:
	move.b	#4,anim_delay
	cmp.l	#lbL000ADC,bob_ptr
	beq.s	lbC000A1E
	sub.l	#8,bob_ptr
	move.l	bob_ptr,a0
	move.l	(a0)+,bob_data
	move.l	(a0),bob_mask
	rts

lbC000A1E:
	clr.b	lbB000DED
	rts

lbC000A26:
	tst.b	anim_delay
	beq.s	lbC000A38
	sub.b	#1,anim_delay
	rts

lbC000A38:
	move.b	#4,anim_delay
	cmp.l	#lbL000B34,bob_ptr
	beq.s	lbC000A1E
	bcs.s	lbC000A6C
	sub.l	#8,bob_ptr
	move.l	bob_ptr,a0
	move.l	(a0)+,bob_data
	move.l	(a0),bob_mask
	rts

lbC000A6C:
	add.l	#8,bob_ptr
	move.l	bob_ptr,a0
	move.l	(a0)+,bob_data
	move.l	(a0),bob_mask
	rts

lbC000A8A:
	tst.b	anim_delay
	beq.s	lbC000A9C
	sub.b	#1,anim_delay
	rts

lbC000A9C:
	move.b	#4,anim_delay
	cmp.l	#lbL000BCC,bob_ptr
	bne.s	lbC000ABA
	move.l	#lbL000B7C,bob_ptr
lbC000ABA:
	add.l	#8,bob_ptr
	move.l	bob_ptr,a0
	move.l	(a0)+,bob_data
	move.l	(a0),bob_mask
	rts

bob_ptr:
	dc.l	lbL000ADC

; tuples of image + mask addr
lbL000ADC:
	dc.l	lbW022D00,lbW023E30
	dc.l	lbW022D00+$190,lbW023E30+$190
	dc.l	lbW022D00+$190*2,lbW023E30+$190*2
	dc.l	lbW022D00+$190*3,lbW023E30+$190*3
	dc.l	lbW022D00+$190*4,lbW023E30+$190*4
	dc.l	lbW022D00+$190*5,lbW023E30+$190*5
	dc.l	lbW022D00+$190*6,lbW023E30+$190*6
	dc.l	lbW022D00+$190*7,lbW023E30+$190*7
	dc.l	lbW022D00+$190*8,lbW023E30+$190*8
	dc.l	lbW022D00+$190*9,lbW023E30+$190*9
	dc.l	lbW022D00+$190*10,lbW023E30+$190*10

lbL000B34:
	dc.l	lbW040000,lbW041900
	dc.l	lbW040000+$190,lbW041900+$190
	dc.l	lbW040000+$190*2,lbW041900+$190*2
	dc.l	lbW040000+$190*3,lbW041900+$190*3
	dc.l	lbW040000+$190*4,lbW041900+$190*4
	dc.l	lbW040000+$190*5,lbW041900+$190*5
	dc.l	lbW040000+$190*6,lbW041900+$190*6
	dc.l	lbW040000+$190*7,lbW041900+$190*7
	dc.l	lbW040000+$190*8,lbW041900+$190*8
lbL000B7C:
	dc.l	lbW040000+$190*9,lbW041900+$190*9
	dc.l	lbW040000+$190*10,lbW041900+$190*10
	dc.l	lbW040000+$190*11,lbW041900+$190*11
	dc.l	lbW040000+$190*12,lbW041900+$190*12
	dc.l	lbW040000+$190*13,lbW041900+$190*13
	dc.l	lbW040000+$190*14,lbW041900+$190*14
	dc.l	lbW040000+$190*15,lbW041900+$190*15
	dc.l	lbW040000+$190*14,lbW041900+$190*14
	dc.l	lbW040000+$190*13,lbW041900+$190*13
	dc.l	lbW040000+$190*12,lbW041900+$190*12
lbL000BCC:
	dc.l	lbW040000+$190*11,lbW041900+$190*11

zoom_floor:
	lea	lbW000EE8,a0
	move.w	#19,d0
	move.w	(a0),d1
	move.w	2(a0),d2
lbC000BE4:
	move.w	4(a0),(a0)
	move.w	6(a0),2(a0)
	addq.l	#4,a0
	dbra	d0,lbC000BE4
	move.w	d1,-4(a0)
	move.w	d2,-2(a0)

	lea	lbW000EE8,a0
	lea	lbW001408,a1
	move.w	#$13,d0
lbC000C0C:
	move.w	(a0)+,6(a1)
	move.w	(a0)+,10(a1)
	add.l	#12,a1
	dbra	d0,lbC000C0C

	lea	lbW001408,a0
	move.w	#4,d0
	move.w	#5,d1
	move.w	#$550,d2
lbC000C30:
	add.w	d1,6(a0)
	add.w	d1,10(a0)
	sub.w	d2,6(a0)
	sub.w	d2,10(a0)
	add.l	#12,a0
	sub.w	#1,d1
	sub.w	#$110,d2
	dbra	d0,lbC000C30
	rts

scope_new_notes:
	lea	mt_aud1temp,a0
	lea	lbB000DCE,a1
	lea	lbW000DD4,a3
	move.w	#3,d0
lbC000C6A:
	bsr.s	lbC000C7E
	move.w	(a0),(a3)+
	add.l	#$1A,a0
	addq.l	#1,a1
	addq.l	#2,a3
	dbra	d0,lbC000C6A
	rts

lbC000C7E:
	tst.w	(a0)
	beq.s	lbC000C8E
	move.w	(a3),d3
	cmp.w	(a0),d3
	beq.s	lbC000C8E
	move.b	#217,(a1)	;set to max x
	rts

lbC000C8E:
	cmp.b	#65,(a1)	;min pos?
	beq.s	lbC000C98
	sub.b	#4,(a1)	;decr pos
lbC000C98:
	rts

draw_scope:
	lea	lbB000E8E,a0
	move.w	#3,d2
lbC000CA4:
	bsr	lbC000D30
	addq.l	#1,a0
	dbra	d2,lbC000CA4

	lea	cop_scope+6,a0
	move.w	#24,d0
lbC000CB8:
	clr.w	(a0)
	clr.w	8(a0)
	clr.w	12(a0)
	add.l	#20,a0
	dbra	d0,lbC000CB8

	bsr	lbC000D42
	move.w	#3,d0
	lea	lbB000DCA,a4
	lea	lbB000E8E,a3
lbC000CE0:
	lea	cop_scope+6,a5
	clr.l	d1
	move.b	(a3),d1
	mulu	#20,d1
	add.l	d1,a5
	bsr.s	lbC000CFE
	add.l	#15,a3
	dbra	d0,lbC000CE0
	rts

lbC000CFE:
	lea	equ_left_pal,a0
	lea	equ_max_pal,a1
	lea	equ_bg_pal,a2
	move.w	#6,d2
	move.b	(a4)+,d6
lbC000D16:
	move.b	d6,3(a5)
	move.w	(a0)+,(a5)
	move.w	(a1)+,8(a5)
	move.w	(a2)+,12(a5)
	add.l	#$14,a5
	dbra	d2,lbC000D16
	rts

lbC000D30:
	move.w	#14,d0
	move.b	(a0),d1
lbC000D36:
	move.b	1(a0),(a0)+
	dbra	d0,lbC000D36
	move.b	d1,-(a0)
	rts

lbC000D42:
	cmp.b	#18,lbB000E8E
	beq.s	lbC000D4E
	bra.s	lbC000D66

lbC000D4E:
	addq.b	#1,lbB000DD2
	cmp.b	#5,lbB000DD2
	bne.s	lbC000D66
	move.b	#1,lbB000DD2
lbC000D66:
	move.b	lbB000DD2,d0
	move.l	lbB000DCE,lbB000DCA
lbC000D76:
	lea	lbB000DCA,a0
	move.w	#3,d2
	move.b	3(a0),d1
lbC000D84:
	move.b	2(a0),3(a0)
	sub.l	#1,a0
	dbra	d2,lbC000D84
	move.b	d1,4(a0)
	sub.b	#1,d0
	bne.s	lbC000D76
	rts

equ_left_pal:
	dc.w	$444
	dc.w	$888
	dc.w	$CCC
	dc.w	$FFF
	dc.w	$CCC
	dc.w	$888
	dc.w	$444
equ_max_pal:
	dc.w	$400
	dc.w	$800
	dc.w	$C00
	dc.w	$F00
	dc.w	$C00
	dc.w	$800
	dc.w	$400
equ_bg_pal:
	dc.w	4
	dc.w	8
	dc.w	12
	dc.w	15
	dc.w	12
	dc.w	8
	dc.w	4
lbB000DCA:
	dc.b	$41
	dc.b	$51
	dc.b	$61
	dc.b	$71
lbB000DCE:
	dc.b	$41
	dc.b	$51
	dc.b	$61
	dc.b	$71
lbB000DD2:
	dc.b	1
lbB000DD3:
	dc.b	0
lbW000DD4:
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
lbL000DDC:
	dc.l	0
lbL000DE0:
	dc.l	0
lbL000DE4:
	dc.l	0
lbL000DE8:
	dc.l	0
lbB000DEC:
	dc.b	0
lbB000DED:
	dc.b	3
move_frame_count:
	dc.w	1160
lbB000DF0:
	dc.b	0
kb_menu_flag:
	dc.b	0
control_disable:
	dc.b	1
bob_blitmode:
	dc.b	'C'
lbB000DF4:
	dc.b	1
scr_bouncing:
	dc.b	0
scroll_speed:
	dc.w	1
lbB000153:
	dc.b	1
lbB000DF6:
	dc.b	0
anim_delay:
	dc.b	4
	dc.b	3

	even
lbW0001E0:	dc.l	0
lbC0001F4:	dc.l	0
lbC000206:	dc.l	0
lbL0005A8:	dc.l	lbW021500
lbL00070C:	dc.l	lbW021500
lbL0005B4:	dc.l	lbW021500+$400
lbL000718:	dc.l	lbW021500+$400
bob_bplcon0:	dc.l	$FCA0000
shadow_bplcon0:	dc.l	$FCA0000

bob_data:	dc.l	lbW022D00
bob_mask:	dc.l	lbW023E30

lbL000E02:
	dc.l	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1

lbL000E2A:
	dc.l	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1

scr_bouncetab:
	dc.b	18,17,17,17,17,16,16,15,15,14
	dc.b	13,12,11,10,9,9,8,7,6,5
	dc.b	4,3,2,2,1,1,0,0,0,0
	dc.b	0,0,0,0,0,1,1,2,2,3
	dc.b	4,5,6,7,8,8,9,10,11,12
	dc.b	13,14,15,15,16,16,17,17,17,17

lbB000E8E:
	dc.b	18,17,17,17,17,16,16,15,15,14
	dc.b	13,12,11,10,9,9,8,7,6,5
	dc.b	4,3,2,2,1,1,0,0,0,0
	dc.b	0,0,0,0,0,1,1,2,2,3
	dc.b	4,5,6,7,8,8,9,10,11,12
	dc.b	13,14,15,15,16,16,17,17,17,17

; Bob palette, COLOR01 to 15
bob_pal:
	dc.w	$666,$333,$742,$FCA,$AAA,0,$F55
	dc.w	$F00,$D00,$C00,$A00,$900,$700,$600,$400

lbW000EE8:
	dc.w	6,8,6,8,6,8,6,8,6,8
	dc.w	8,6,8,6,8,6,8,6,8,6
	dc.w	6,8,6,8,6,8,6,8,6,8
	dc.w	8,6,8,6,8,6,8,6,8,6

moves_ptr:
	dc.l	moves_table

moves_table:
	dc.l	8
	dc.l	4
	dc.l	$66
	dc.l	$33
	dc.b	1
	dc.b	3
	dc.w	$200

	dc.l	8
	dc.l	$FFFFFFFC
	dc.l	$66
	dc.l	$33
	dc.b	0
	dc.b	2
	dc.w	$FF

	dc.l	8
	dc.l	$FFFFFFFC
	dc.l	$66
	dc.l	$33
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	8
	dc.l	4
	dc.l	$66
	dc.l	$10
	dc.b	0
	dc.b	2
	dc.w	$180

	dc.l	8
	dc.l	4
	dc.l	$66
	dc.l	$10
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	8
	dc.l	4
	dc.l	$20
	dc.l	$33
	dc.b	0
	dc.b	2
	dc.w	$180

	dc.l	8
	dc.l	4
	dc.l	$20
	dc.l	$33
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	$18
	dc.l	9
	dc.l	$28
	dc.l	$14
	dc.b	0
	dc.b	2
	dc.w	$180

	dc.l	$18
	dc.l	9
	dc.l	$28
	dc.l	$14
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	$3F2
	dc.l	9
	dc.l	$100
	dc.l	$80
	dc.b	0
	dc.b	2
	dc.w	$200

	dc.l	$3F2
	dc.l	9
	dc.l	$100
	dc.l	$80
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	2
	dc.l	1
	dc.l	$66
	dc.l	$33
	dc.b	2
	dc.b	0
	dc.w	$200

	dc.l	4
	dc.l	2
	dc.l	$66
	dc.l	$33
	dc.b	0
	dc.b	3
	dc.w	$200

	dc.l	4
	dc.l	2
	dc.l	$66
	dc.l	$33
	dc.b	0
	dc.b	1
	dc.w	$80

	dc.l	4
	dc.l	$FE
	dc.l	$66
	dc.l	$33
	dc.b	3
	dc.b	2
	dc.w	$200

	dc.l	4
	dc.l	$FE
	dc.l	$66
	dc.l	$33
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	12
	dc.l	7
	dc.l	$4A
	dc.l	$33
	dc.b	4
	dc.b	2
	dc.w	$200

	dc.l	12
	dc.l	7
	dc.l	$4A
	dc.l	$33
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	14
	dc.l	0
	dc.l	$66
	dc.l	$33
	dc.b	3
	dc.b	2
	dc.w	$200

	dc.l	14
	dc.l	0
	dc.l	$66
	dc.l	$33
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	$3F2
	dc.l	$FF
	dc.l	$16
	dc.l	3
	dc.b	1
	dc.b	2
	dc.w	$200

	dc.l	$3F2
	dc.l	$FF
	dc.l	$16
	dc.l	3
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	14
	dc.l	5
	dc.l	$66
	dc.l	$16
	dc.b	4
	dc.b	2
	dc.w	$200

	dc.l	14
	dc.l	5
	dc.l	$66
	dc.l	$16
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	8
	dc.l	4
	dc.l	$42
	dc.l	9
	dc.b	3
	dc.b	3
	dc.w	$200

	dc.l	8
	dc.l	4
	dc.l	$42
	dc.l	9
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	8
	dc.l	8
	dc.l	$3E2
	dc.l	$15
	dc.b	4
	dc.b	2
	dc.w	$200

	dc.l	8
	dc.l	8
	dc.l	$3E2
	dc.l	$15
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	6
	dc.l	3
	dc.l	$CE
	dc.l	$67
	dc.b	2
	dc.b	2
	dc.w	$200

	dc.l	6
	dc.l	3
	dc.l	$CE
	dc.l	$67
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	14
	dc.l	$1FC
	dc.l	$66
	dc.l	$16
	dc.b	4
	dc.b	2
	dc.w	$200

	dc.l	14
	dc.l	$1FC
	dc.l	$66
	dc.l	$16
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.l	12
	dc.l	6
	dc.l	$2C
	dc.l	$16
	dc.b	2
	dc.b	2
	dc.w	$200

	dc.l	12
	dc.l	6
	dc.l	$2C
	dc.l	$16
	dc.b	0
	dc.b	1
	dc.w	$40

	dc.b	'ende'

chartab:
	dc.b	'abcdefghijklmnopqrstuvwxyz'
	dc.b	'0123456789.!-,C?/()'': BC'
	even

scrollptr:
	dc.l	scrolltext

scrolltext:
	dc.b	'N      S5    ignition!                 kick '
	dc.b	'down!             let''s do it!             '
	dc.b	'        S3d.o.c (doctor mabuse orgasm cracki'
	dc.b	'ngs) strikes forward !!!                   S'
	dc.b	'5   welcome to one of the most succesful and'
	dc.b	' powerful amiga demos !!!                   '
	dc.b	' S6to maintain the high performance and reli'
	dc.b	'ability of this demo, avoid using or storing'
	dc.b	' it in the following conditions...          '
	dc.b	' U1dusty places             U2near heat sour'
	dc.b	'ces such as hell, etc.             in high h'
	dc.b	'umidity areas such as the swimming pool     '
	dc.b	'              U1places exposed to direct sun'
	dc.b	'light especially in a closed car            '
	dc.b	'        U2extremely cold places             '
	dc.b	'           N and don''t forget            U1'
	dc.b	'keep the volume set to a comfortable listeni'
	dc.b	'ng level, as excess volumes could damage you'
	dc.b	'r hearing  !!!                   for traffic'
	dc.b	' safety, it is recommended that the amiga no'
	dc.b	't be used while operating a motor vehicle.  '
	dc.b	'            S4 Nyou wait for the greetings ?'
	dc.b	'?           we hope you have got some time n'
	dc.b	'ow...        otherwise you will not be able '
	dc.b	'to watch the greetings flickering through th'
	dc.b	'is bloody S5scroll....              at first'
	dc.b	' some credits to this wonderful             '
	dc.b	'  S3d.o.c demo      Wz             S4  this '
	dc.b	'fascinating demonstration  coded by      S3 '
	dc.b	'U1 ! unknown !      Wz        S4  N soundtra'
	dc.b	'ck composed by      S3  U1  ! frog !       W'
	dc.b	'z             S4 Nall graphics above the scr'
	dc.b	'oll pixeled by      S3  U1  ! esteban !     '
	dc.b	' Wz           S4 Nthis amazing (?) (welcher '
	dc.b	'idiot hat das fragezeichen da hingesetzt ??)'
	dc.b	' scrolltext written by             S3 U1  ! '
	dc.b	'doctor mabuse !   Wz          S4 N          '
	dc.b	' swiss representation by        S3 U1      t'
	dc.b	'he impotent freak   Wz N             charset'
	dc.b	' by     S3 U1      future light      Wz N an'
	dc.b	'd another d.o.c member is     S3 U1   ! zoci'
	dc.b	' joe !     Wz N    S4most probably (?) relea'
	dc.b	'sed on 21.5.88 at dns''s and rage''s copy pa'
	dc.b	'rty - our fascinating magazine on disk -    '
	dc.b	' S3 U2  ! p.e.n.i.s !     Wz N    S4we need '
	dc.b	'some good arcticle writer !!!        if you '
	dc.b	'are interested contact us - now !!!!        '
	dc.b	'    so it is - and here it is - our contact '
	dc.b	'address - write the following on your letter'
	dc.b	' (write only (when i say only - i mean only '
	dc.b	'!!) the following three lines - no!! name - '
	dc.b	'neither wolfgang amadeus nor r.mueller or su'
	dc.b	'ch a shit!)   write :      S3 U1 plk 089114 '
	dc.b	'c     Wy        -           2300 kiel 1     '
	dc.b	' Wz      -     S3 U1 west-germany      Wy !!'
	dc.b	'!!        N S4pay attention  !!!       in a '
	dc.b	'moment you are able to create your own ball '
	dc.b	'animations.....        keep on...       neve'
	dc.b	'r press reset in a d.o.c demo until you have'
	dc.b	' read the whole scrolltext...       maybe yo'
	dc.b	'u should lay down ?        but don''t fall a'
	dc.b	'sleep !!!         '
* Racist "joke" removed.
*	dc.b	'was macht ein neger, wenn '
*	dc.b	'er schlaeft ??        ein niggerchen !!!!   '
	dc.b	'           und nun wieder die aktuelle durch'
	dc.b	'saege -aeh- sage des wetter-tarzans  -   tag'
	dc.b	'sueber ist es meist tag, wobei es nachts auc'
	dc.b	'h dunkel sein kann.  der wind dreht geschwin'
	dc.b	'd aus schwachsinnigen richtungen, wobei eine'
	dc.b	' windstaerke von 5 bis pi quadrat erreicht w'
	dc.b	'erden kann.  das war wieder wetter-tarzan.  '
	dc.b	' yoladrihuu!.     ok, for the non-german - t'
	dc.b	'hat was our weather tarzan !!    yeah, man !'
	dc.b	'!    for the guys, who are just travelling b'
	dc.b	'y car -  here it comes the updatest message '
	dc.b	'from the german ''verkehrs-tarzan'' -  auf d'
	dc.b	'er achterbahn ist es streckenweise kneblig, '
	dc.b	'achten sie auf den geisterfahrer im vw cabri'
	dc.b	'o kaefer...   wir wuenschen ihnen weiterhin '
	dc.b	'eine tube fahrt.     biiiiiiiiip.           '
	dc.b	'  and now...        now some messages...    '
	dc.b	'            S4 hey silicion league (this mes'
	dc.b	'sage for the ram hunter)        1. i (dr.m) '
	dc.b	'think it''s not my milk-bottle-holder  -  it'
	dc.b	'''s my beer, whiskey, pernod, amaretto, kuest'
	dc.b	'ennebel, gin, bacardi, elephants holder !   '
	dc.b	'2. who''s running out of words ?  3. who ask'
	dc.b	'ed the question number two ?   4. who is goi'
	dc.b	'ng to ask question number five ?    5. can y'
	dc.b	'ou tell me ?!?      6. geht das los oder geh'
	dc.b	't das los ?       7. jaja heisst klei mi an'''
	dc.b	' mors !     8. running out of words !?!     '
	dc.b	'           hey atoemchen / champs !   oh mei'
	dc.b	'n geld ! oh mein geld !  try throwing 5 dm c'
	dc.b	'oins in the phone box instead of ten pfennig'
	dc.b	' coins...     don''t forget to remove daily '
	dc.b	'the dust from the disks...      hey all looo'
	dc.b	'oooosers !    don''t contact us for swapping'
	dc.b	'...          hey megaforce france !    i sen'
	dc.b	't a package to the address you gave me, but '
	dc.b	'it came back...   the postman couldn''t find'
	dc.b	' your house...    or do you live in the unde'
	dc.b	'rground...           hey oks import division'
	dc.b	' !     congratulations zum rausschmiss diese'
	dc.b	'r kieler schwuchtel named alex...        hey'
	dc.b	' bullen !!!   fuck yourself...              '
	dc.b	'jetzt wird''s ernst, leute !!!       only a '
	dc.b	'few lines more bullshit...        and after '
	dc.b	'''em...     the unremovable greetings...     '
	dc.b	'ahhhhhhhh!!!     good morning.         hey a'
	dc.b	'll guys there...   thanx for all those lette'
	dc.b	'rs...     but we think it''s impossible to a'
	dc.b	'nswer all of ''em...     we get average eigh'
	dc.b	't letters a day and so it''s nearly impossib'
	dc.b	'le to send them back...     1. we have not s'
	dc.b	'o much time to answer each of ''em !    2. w'
	dc.b	'e would answer your letters if you enclosed '
	dc.b	'the return postage !   3. answering all your'
	dc.b	' letters would cost about 70 deutschmark the'
	dc.b	' week - that means we would have to pay abou'
	dc.b	't 280! marks a month...   and that''s imposs'
	dc.b	'ible...         okay, so loooooooooosers do '
	dc.b	'not contact us anymore...      winners are w'
	dc.b	'elcome of course !!             if you think'
	dc.b	' what i think it''s time for the greetings..'
	dc.b	'.         and here they go !!!           all'
	dc.b	' members of dr. mabuse orgasm crackings send'
	dc.b	' hand-shakes to the following solos and grou'
	dc.b	'ps...       again alphabetical order and som'
	dc.b	'e messages !?   S4 N      hip hop hippel di '
	dc.b	'hops to          alpha flight (we''ll have a'
	dc.b	' hard competition fight with our p.e.n.i.s a'
	dc.b	'nd your cracker journal)     -       antitra'
	dc.b	'x 2010        -         amiga i.c.e (the goo'
	dc.b	'nies)     -     bamiga sector one (thanx for'
	dc.b	' contacting us) and the kent team (thanx, to'
	dc.b	'o)     -     bfbs (nice from you to name the'
	dc.b	' painter of your intro pic...  it was drawn '
	dc.b	'by d.o.c member esteban for you - have you f'
	dc.b	'orgotten it ???)        -     bitstoppers   '
	dc.b	'  -     blizzard     -      cbc       -     '
	dc.b	'  champs (atoemchen / oh mein geld ! oh mein'
	dc.b	' geld ! you''re funny...)       -    c.h.h ('
	dc.b	'what''s with the vi-deos ?)       -        c'
	dc.b	'ommando frontier     -        cool       -  '
	dc.b	'     danish gold     -     def jam     -    '
	dc.b	' dominators     -     dynamic systems and ra'
	dc.b	'ge (see you on may the 21st !)       -      '
	dc.b	'federation against copyright    -      fairl'
	dc.b	'ight     -     fun and function       -     '
	dc.b	'  gigaflops 2112     -     garfield / bfbs ('
	dc.b	'oder wo soll ich dich einordnen ?)     -    '
	dc.b	' at this place ...  gaehn....    x.... we kn'
	dc.b	'ow you would like to see your group-name her'
	dc.b	'e...    but we can''t greet you...   because'
	dc.b	' one of you''ve stolen letters from d.o.c at'
	dc.b	' the post office...    and here''s the last '
	dc.b	'warning...    you know we''ve much much much'
	dc.b	' better connections to the post and if you g'
	dc.b	'o on stealing letters and disks from us - or'
	dc.b	' if you continue talking bullshit - it could'
	dc.b	' happen that you won''t receive anymore lett'
	dc.b	'ers....     -      hagar / the connection   '
	dc.b	'    -      heavy bits italian bad boys / esg'
	dc.b	'       -     jungle command (thanx for your '
	dc.b	'letter)     -     kongoman     -     movers '
	dc.b	'(hey markus... sorry about the video...)    '
	dc.b	' -     mr. ram and executer (see you in aach'
	dc.b	'en ?)     -     motley crue team  (or is you'
	dc.b	'r name already alcatraz ? - if so - of cours'
	dc.b	'e greetings to alcatraz !)      -     nato  '
	dc.b	'     -       north star      -       norther'
	dc.b	'n lights        -       oks import division '
	dc.b	'      -       pulle flens     -     quadlite'
	dc.b	' (zeronine! on the waescheline)     -    rad'
	dc.b	'war ent.     -      red sector (hey dirk ! s'
	dc.b	'orry for the late reply, but we had to decod'
	dc.b	'e your phonenumber !?!)      -      red / pr'
	dc.b	'ofessionals (still waiting for your articles'
	dc.b	'...)       -       sinners / powerstation   '
	dc.b	'  -     silicon league ! (messages gab es sc'
	dc.b	'hon... alles kann ich nur sagen - hau die hu'
	dc.b	'ehner und hock di hi !!)       -          sk'
	dc.b	'ywalker     -     sodan / magician 42     - '
	dc.b	'    steelpulse (esp. to the amiga power (nic'
	dc.b	'e, that you liked our scroll concepts...))  '
	dc.b	'   -     syndicate dk      -      swatch    '
	dc.b	'  -     taurus one     -      the commodore '
	dc.b	'guys (ftf)     -     tgm crew      -     the'
	dc.b	' light circle (hey duke! du banane hast es d'
	dc.b	'och tatsaechlich vergessen...  )      -     '
	dc.b	' the light force      -     the unknown five'
	dc.b	'     -       the young ones     -     the ne'
	dc.b	'w dimension     -     the new masters      -'
	dc.b	'       the sofkiller crew     -      the squ'
	dc.b	'ad      -      jon / t.u.i (new york)      -'
	dc.b	'       w.c.s     and to all other junkies !!'
	dc.b	'!       okay !!!   K    from now on you are '
	dc.b	'able to create your own ball animations !!! '
	dc.b	'      here is a quick clarification to it...'
	dc.b	'.          S2 N   1. press ''enter'' (not re'
	dc.b	'turn!) to quit the demo mode !!   2. press '''
	dc.b	'f1'' to increase the x-value   3. press ''f2'
	dc.b	''' to decrease the x-value   4. press ''f3'' '
	dc.b	'to increase the y-value   5. press ''f4'' to'
	dc.b	' decrease the y-value    6. press ''f5'' to '
	dc.b	'increase both values    7. press ''f6'' to d'
	dc.b	'ecrease both values   8. press ''f7'' to inc'
	dc.b	'rease the x - and the y - speed   9. press '''
	dc.b	'f8'' to decrease the x - and the y - speed  '
	dc.b	' 10. press ''f9'' for mutation ball / demon '
	dc.b	'  11. press ''f10'' for mutation demon / bal'
	dc.b	'l   13. use the cursor keys left / right for'
	dc.b	'  x - speed de-and increasing  14. use the c'
	dc.b	'ursor keys up / down for y - speed de- and i'
	dc.b	'ncreasing   15. press delete to remove the t'
	dc.b	'hing at the top left corner   16. press ''en'
	dc.b	'ter'' to reactivate the demo mode   17. pres'
	dc.b	's ''a'' to ''d'' for different animations   '
	dc.b	'S3 let''s have fun sonst bist du dran !!!   '
	dc.b	'         end of transmission                '
	dc.b	'            '
	dc.b	-1
	even

**********************************************************
* Classic Soundtracker replay routine
* Raster line wait added to accommodate faster processors
**********************************************************

; $3EF00
mt_init:
	move.l	#sample1,mt_sample1
	move.l	#sample2,mt_sample2
	move.l	#sample3,mt_sample3
	move.l	#sample4,mt_sample4
	move.l	#sample5,mt_sample5
	move.l	#sample6,mt_sample6
	move.l	#sample7,mt_sample7
	move.l	#sample8,mt_sample8
	move.l	#sample9,mt_sample9
	move.l	#sample10,mt_sample10
	move.l	#sample11,mt_sample11
	move.l	#sample12,mt_sample12
	move.l	#sample13,mt_sample13
	move.l	#sample14,mt_sample14
	move.l	#sample15,mt_sample15

	move.l	#mt_sample1,a0
	clr.l	d0
mt_clear:
	move.l	(a0,d0.l),a1
	clr.l	(a1)			;BUG - would clear long after last sample, if less than 15
	addq.w	#4,d0
	cmp.l	#15*4,d0
	bne.s	mt_clear
	move.w	#0,$DFF0A8
	move.w	#0,$DFF0B8
	move.w	#0,$DFF0C8
	move.w	#0,$DFF0D8
	clr.l	mt_partnrplay
	clr.l	mt_partnote
	clr.l	mt_partpoint
	move.b	mt_song+$1d6,mt_maxpart+1
	move.b	mt_song+$1d7,mt_kn1+1
	rts

mt_music:
	addq.l	#1,mt_counter
mt_cool:
	move.l	mt_speed,d0
	cmp.l	mt_counter,d0
	bne.s	mt_notsix
	clr.l	mt_counter
	bra	mt_rout2

mt_notsix:
	lea	mt_aud1temp,a6
	tst.b	3(a6)
	beq.s	mt_arp1
	move.l	#$DFF0A0,a5
	bsr.s	mt_arprout
mt_arp1:
	lea	mt_aud2temp,a6
	tst.b	3(a6)
	beq.s	mt_arp2
	move.l	#$DFF0B0,a5
	bsr.s	mt_arprout
mt_arp2:
	lea	mt_aud3temp,a6
	tst.b	3(a6)
	beq.s	mt_arp3
	move.l	#$DFF0C0,a5
	bsr.s	mt_arprout
mt_arp3:
	lea	mt_aud4temp,a6
	tst.b	3(a6)
	beq.s	mt_arp4
	move.l	#$DFF0D0,a5
	bra.s	mt_arprout

mt_arp4:
	rts

mt_arprout:
	tst.w	24(a6)
	beq.s	mt_noslide
	clr.w	d0
	move.b	25(a6),d0
	lsr.b	#4,d0
	tst.b	d0
	beq.s	mt_voldwn2
	bsr	mt_pushvol1
	bra.s	mt_noslide

mt_voldwn2:
	clr.w	d0
	move.b	25(a6),d0
	bsr	mt_pushvol2
mt_noslide:
	move.b	2(a6),d0
	and.b	#15,d0
	tst.b	d0
	beq	mt_arpegrt
	cmp.b	#3,d0
	beq	mt_arpegrt
	cmp.b	#4,d0
	beq	mt_arpegrt
	cmp.b	#5,d0
	beq	mt_arpegrt
	cmp.b	#1,d0
	beq.s	mt_portup
	cmp.b	#6,d0
	beq.s	mt_portup
	cmp.b	#7,d0
	beq.s	mt_portup
	cmp.b	#8,d0
	beq.s	mt_portup
	cmp.b	#2,d0
	beq.s	mt_portdwn
	cmp.b	#9,d0
	beq.s	mt_portdwn
	cmp.b	#10,d0
	beq.s	mt_portdwn
	cmp.b	#11,d0
	beq.s	mt_portdwn
	cmp.b	#13,d0
	beq.s	mt_volup
	rts

mt_portup:
	clr.w	d0
	move.b	3(a6),d0
	sub.w	d0,$16(a6)
	cmp.w	#$71,$16(a6)
	bpl.s	lbC0040FC
	move.w	#$71,$16(a6)
lbC0040FC:
	move.w	$16(a6),6(a5)
	rts

mt_portdwn:
	clr.w	d0
	move.b	3(a6),d0
	add.w	d0,$16(a6)
	cmp.w	#$358,$16(a6)
	bmi.s	lbC00411C
	move.w	#$358,$16(a6)
lbC00411C:
	move.w	$16(a6),6(a5)
	rts

mt_volup:
	clr.w	d0
	move.b	3(a6),d0
	lsr.b	#4,d0
	tst.b	d0
	beq.s	lbC00414A
mt_pushvol1:
	add.w	d0,$12(a6)
	cmp.w	#$40,$12(a6)
	bmi.s	lbC004142
	move.w	#$40,$12(a6)
lbC004142:
	move.w	$12(a6),8(a5)
	rts

lbC00414A:
	clr.w	d0
	move.b	3(a6),d0
mt_pushvol2:
	and.b	#15,d0
	sub.w	d0,$12(a6)
	bpl.s	lbC00415E
	clr.w	$12(a6)
lbC00415E:
	move.w	$12(a6),8(a5)
	rts

mt_arpegrt:
	cmp.l	#1,mt_counter
	beq.s	lbC0041A4
	cmp.l	#2,mt_counter
	beq.s	lbC0041AE
	cmp.l	#3,mt_counter
	beq.s	lbC0041BA
	cmp.l	#4,mt_counter
	beq.s	lbC0041A4
	cmp.l	#5,mt_counter
	beq.s	lbC0041AE
	rts

lbC0041A4:
	clr.l	d0
	move.b	3(a6),d0
	lsr.b	#4,d0
	bra.s	lbC0041C0

lbC0041AE:
	clr.l	d0
	move.b	3(a6),d0
	and.b	#15,d0
	bra.s	lbC0041C0

lbC0041BA:
	move.w	$10(a6),d2
	bra.s	lbC0041DA

lbC0041C0:
	lsl.w	#1,d0
	clr.l	d1
	move.w	$10(a6),d1
	lea	mt_period,a0
lbC0041CE:
	move.w	(a0,d0.l),d2
	cmp.w	(a0),d1
	beq.s	lbC0041DA
	addq.l	#2,a0
	bra.s	lbC0041CE

lbC0041DA:
	move.w	d2,6(a5)
	rts

mt_rout2:
	lea	mt_song,a0
	move.l	a0,a3
	add.l	#12,a3
	move.l	a0,a2
	add.l	#$1D8,a2
	add.l	#$258,a0
	move.l	mt_partnrplay,d0
	clr.l	d1
	move.b	(a2,d0.l),d1
	mulu	#$400,d1
	add.l	mt_partnote,d1
	move.l	d1,mt_partpoint
	clr.w	mt_dmacon
	move.l	#$DFF0A0,a5
	lea	mt_aud1temp,a6
	bsr	mt_playit
	move.l	#$DFF0B0,a5
	lea	mt_aud2temp,a6
	bsr	mt_playit
	move.l	#$DFF0C0,a5
	lea	mt_aud3temp,a6
	bsr	mt_playit
	move.l	#$DFF0D0,a5
	lea	mt_aud4temp,a6
	bsr	mt_playit

;	move.l	#500,d0			;mt_speed
;mt_rls:
;	dbra	d0,mt_rls

;MTN: Use scan line wait for faster processors
	MOVEQ	#5,D0
mt_waitlines:
	MOVE.B	$DFF006,D1
mt_sameline:
	CMP.B	$DFF006,D1
	BEQ.S	mt_sameline
	DBRA	D0,mt_waitlines

	move.l	#$8000,d0
	add.w	mt_dmacon,d0
	move.w	d0,$DFF096
	move.l	#mt_aud4temp,a6
	cmp.w	#1,14(a6)
	bne.s	mt_voice3
	move.l	10(a6),$DFF0D0
	move.w	#1,$DFF0D4
mt_voice3:
	move.l	#mt_aud3temp,a6
	cmp.w	#1,14(a6)
	bne.s	mt_voice2
	move.l	10(a6),$DFF0C0
	move.w	#1,$DFF0C4
mt_voice2:
	move.l	#mt_aud2temp,a6
	cmp.w	#1,14(a6)
	bne.s	mt_voice1
	move.l	10(a6),$DFF0B0
	move.w	#1,$DFF0B4
mt_voice1:
	move.l	#mt_aud1temp,a6
	cmp.w	#1,14(a6)
	bne.s	mt_voice0
	move.l	10(a6),$DFF0A0
	move.w	#1,$DFF0A4
mt_voice0:
	move.l	mt_partnote,d0
	add.l	#$10,d0
	move.l	d0,mt_partnote
	cmp.l	#$400,d0
	bne.s	mt_stop
	clr.l	mt_partnote
	addq.l	#1,mt_partnrplay
	clr.l	d0
	move.w	mt_maxpart,d0
	move.l	mt_partnrplay,d1
	cmp.l	d0,d1
	bne.s	mt_stop
	clr.l	mt_partnrplay
mt_stop:
	rts

mt_playit:
	move.l	(a0,d1.l),(a6)
	addq.l	#4,d1
	clr.l	d2
	move.b	2(a6),d2
	and.b	#$F0,d2
	lsr.b	#4,d2
	tst.b	d2
	beq.s	mt_nosamplechange
	clr.l	d3
	lea	mt_samples,a1
	move.l	d2,d4
	mulu	#4,d2
	mulu	#$1E,d4
	move.l	(a1,d2.l),4(a6)
	move.w	(a3,d4.l),8(a6)
	move.w	2(a3,d4.l),$12(a6)
	move.w	4(a3,d4.l),d3
	tst.w	d3
	beq.s	mt_displace
	move.l	4(a6),d2
	add.l	d3,d2
	move.l	d2,4(a6)
	move.l	d2,10(a6)
	move.w	6(a3,d4.l),8(a6)
	move.w	6(a3,d4.l),14(a6)
	move.w	$12(a6),8(a5)
	bra.s	mt_nosamplechange

mt_displace:
	move.l	4(a6),d2
	add.l	d3,d2
	move.l	d2,10(a6)
	move.w	6(a3,d4.l),14(a6)
	move.w	$12(a6),8(a5)
mt_nosamplechange:
	tst.w	(a6)
	beq.s	mt_retrout
	move.w	(a6),$10(a6)
	move.w	$14(a6),$DFF096
	move.l	4(a6),(a5)
	move.w	8(a6),4(a5)
	move.w	(a6),6(a5)
	move.w	20(a6),d0
	or.w	d0,mt_dmacon
mt_retrout:
	move.w	20(a6),d0
	lsl.w	#4,d0
	add.w	20(a6),d0
	move.w	d0,$DFF09E
	tst.w	(a6)
	beq.s	mt_nonewper
	move.w	(a6),$16(a6)
mt_nonewper:
	move.b	2(a6),d0
	and.b	#15,d0
	cmp.b	#14,d0
	bne.s	mt_noset
	move.w	2(a6),$18(a6)
	rts

mt_noset:
	tst.b	3(a6)
	bne.s	mt_noclr
	clr.w	24(a6)
mt_noclr:
	cmp.b	#3,d0
	beq.s	mt_modvol
	cmp.b	#6,d0
	beq.s	mt_modvol
	cmp.b	#9,d0
	beq.s	mt_modvol
	cmp.b	#4,d0
	beq.s	mt_modper
	cmp.b	#7,d0
	beq.s	mt_modper
	cmp.b	#10,d0
	beq.s	mt_modper
	cmp.b	#5,d0
	beq.s	mt_modvolper
	cmp.b	#8,d0
	beq.s	mt_modvolper
	cmp.b	#11,d0
	beq.s	mt_modvolper
	cmp.b	#15,d0
	beq.s	mt_chgspeed
	cmp.b	#12,d0
	bne.s	mt_nochnge
	move.b	3(a6),8(a5)
mt_nochnge:
	rts

mt_chgspeed:
	moveq	#0,d0
	move.b	3(a6),d0
	and.b	#15,d0
	beq.s	mt_nochnge
	clr.l	mt_counter
	move.b	d0,mt_speed
	rts

mt_modvol:
	move.w	20(a6),d0
	bra.s	mt_push

mt_modper:
	move.w	20(a6),d0
	lsl.w	#4,d0
	bra.s	mt_push

mt_modvolper:
	move.w	20(a6),d0
	lsl.w	#4,d0
	add.w	20(a6),d0
mt_push:
	add.w	#$8000,d0
	move.w	d0,$DFF09E
	rts

mt_aud1temp:
	dc.l	0,0,0,0,0
	dc.w	1,0,0
mt_aud2temp:
	dc.l	0,0,0,0,0
	dc.w	2,0,0
mt_aud3temp:
	dc.l	0,0,0,0,0
	dc.w	4,0,0
mt_aud4temp:
	dc.l	0,0,0,0,0
	dc.w	8,0,0

mt_partnote:
	dc.l	0
mt_partnrplay:
	dc.l	0
mt_counter:
	dc.l	0
mt_speed:
	dc.l	6
mt_partpoint:
	dc.l	0
mt_samples:
	dc.l	0
mt_sample1:
	dc.l	0
mt_sample2:
	dc.l	0
mt_sample3:
	dc.l	0
mt_sample4:
	dc.l	0
mt_sample5:
	dc.l	0
mt_sample6:
	dc.l	0
mt_sample7:
	dc.l	0
mt_sample8:
	dc.l	0
mt_sample9:
	dc.l	0
mt_sample10:
	dc.l	0
mt_sample11:
	dc.l	0
mt_sample12:
	dc.l	0
mt_sample13:
	dc.l	0
mt_sample14:
	dc.l	0
mt_sample15:
	dc.l	0
mt_maxpart:
	dc.b	0
lbB00454B:
	dc.b	0
mt_kn1:
	dc.b	0
lbB00454D:
	dc.b	0
mt_dmacon:
	dc.w	0
mt_period:
	dc.w	$358,$328,$2FA,$2D0,$2A6
	dc.w	$280,$25C,$23A,$21A,$1FC
	dc.w	$1E0,$1C5,$1AC,$194,$17D
	dc.w	$168,$153,$140,$12E,$11D
	dc.w	$10D,$FE,$F0,$E2,$D6
	dc.w	$CA,$BE,$B4,$AA,$A0
	dc.w	$97,$8F,$87,$7F,$78
	dc.w	$71,0,0,0

mt_song:	incbin	"data/demons.sng"

spr_digits:
	dc.b	%00011110
	dc.b	%00110011
	dc.b	%00110011
	dc.b	%00110011
	dc.b	%00011110
	dc.b	%00000000
	dc.b	%00001100
	dc.b	%00011100
	dc.b	%00001100
	dc.b	%00001100
	dc.b	%00111111
	dc.b	%00000000
	dc.b	%00011110
	dc.b	%00110011
	dc.b	%00000110
	dc.b	%00011000
	dc.b	%00111111
	dc.b	%00000000
	dc.b	%00111110
	dc.b	%00000011
	dc.b	%00001110
	dc.b	%00000011
	dc.b	%00111110
	dc.b	%00000000
	dc.b	%00001110
	dc.b	%00011110
	dc.b	%00110110
	dc.b	%00111111
	dc.b	%00000110
	dc.b	%00000000
	dc.b	%00111111
	dc.b	%00110000
	dc.b	%00111110
	dc.b	%00000011
	dc.b	%00111110
	dc.b	%00000000
	dc.b	%00011111
	dc.b	%00110000
	dc.b	%00111110
	dc.b	%00110011
	dc.b	%00011110
	dc.b	%00000000
	dc.b	%00111111
	dc.b	%00000011
	dc.b	%00000110
	dc.b	%00001100
	dc.b	%00001100
	dc.b	%00000000
	dc.b	%00011110
	dc.b	%00110011
	dc.b	%00011110
	dc.b	%00110011
	dc.b	%00011110
	dc.b	%00000000
	dc.b	%00011110
	dc.b	%00110011
	dc.b	%00011111
	dc.b	%00000011
	dc.b	%00111110
	dc.b	%00000000
	dc.b	%00011110
	dc.b	%00110011
	dc.b	%00111111
	dc.b	%00110011
	dc.b	%00110011
	dc.b	%00000000
	dc.b	%00111110
	dc.b	%00110011
	dc.b	%00111110
	dc.b	%00110011
	dc.b	%00111110
	dc.b	%00000000
	dc.b	%00011111
	dc.b	%00110000
	dc.b	%00110000
	dc.b	%00110000
	dc.b	%00011111
	dc.b	%00000000
	dc.b	%00111110
	dc.b	%00110011
	dc.b	%00110011
	dc.b	%00110011
	dc.b	%00111110
	dc.b	%00000000
	dc.b	%00111111
	dc.b	%00110000
	dc.b	%00111100
	dc.b	%00110000
	dc.b	%00111111
	dc.b	%00000000
	dc.b	%00111111
	dc.b	%00110000
	dc.b	%00111100
	dc.b	%00110000
	dc.b	%00110000
	dc.b	%00000000
	dc.b	%00000001
	dc.b	%11110011
	dc.b	%11100111
	dc.b	%11000000

lbW021500:
	dc.w	$A0,$A0,$A1,$A2,$A3,$A4,$A5,$A6
	dc.w	$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE
	dc.w	$AF,$AF,$B0,$B1,$B2,$B3,$B4,$B5
	dc.w	$B6,$B7,$B8,$B9,$B9,$BA,$BB,$BC
	dc.w	$BD,$BE,$BF,$C0,$C0,$C1,$C2,$C3
	dc.w	$C4,$C5,$C5,$C6,$C7,$C8,$C9,$C9
	dc.w	$CA,$CB,$CC,$CD,$CD,$CE,$CF,$D0
	dc.w	$D0,$D1,$D2,$D3,$D3,$D4,$D5,$D5
	dc.w	$D6,$D7,$D7,$D8,$D9,$D9,$DA,$DA
	dc.w	$DB,$DC,$DC,$DD,$DD,$DE,$DE,$DF
	dc.w	$E0,$E0,$E1,$E1,$E2,$E2,$E2,$E3
	dc.w	$E3,$E4,$E4,$E5,$E5,$E6,$E6,$E6
	dc.w	$E7,$E7,$E7,$E8,$E8,$E8,$E9,$E9
	dc.w	$E9,$E9,$EA,$EA,$EA,$EA,$EB,$EB
	dc.w	$EB,$EB,$EB,$EC,$EC,$EC,$EC,$EC
	dc.w	$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC
	dc.w	$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC
	dc.w	$EC,$EC,$EC,$EC,$EC,$EC,$EB,$EB
	dc.w	$EB,$EB,$EB,$EA,$EA,$EA,$EA,$E9
	dc.w	$E9,$E9,$E9,$E8,$E8,$E8,$E7,$E7
	dc.w	$E7,$E6,$E6,$E6,$E5,$E5,$E4,$E4
	dc.w	$E3,$E3,$E2,$E2,$E2,$E1,$E1,$E0
	dc.w	$E0,$DF,$DE,$DE,$DD,$DD,$DC,$DC
	dc.w	$DB,$DA,$DA,$D9,$D9,$D8,$D7,$D7
	dc.w	$D6,$D5,$D5,$D4,$D3,$D3,$D2,$D1
	dc.w	$D0,$D0,$CF,$CE,$CD,$CD,$CC,$CB
	dc.w	$CA,$C9,$C9,$C8,$C7,$C6,$C5,$C5
	dc.w	$C4,$C3,$C2,$C1,$C0,$C0,$BF,$BE
	dc.w	$BD,$BC,$BB,$BA,$B9,$B9,$B8,$B7
	dc.w	$B6,$B5,$B4,$B3,$B2,$B1,$B0,$AF
	dc.w	$AF,$AE,$AD,$AC,$AB,$AA,$A9,$A8
	dc.w	$A7,$A6,$A5,$A4,$A3,$A2,$A1,$A0
	dc.w	$9F,$9F,$9E,$9D,$9C,$9B,$9A,$99
	dc.w	$98,$97,$96,$95,$94,$93,$92,$91
	dc.w	$90,$90,$8F,$8E,$8D,$8C,$8B,$8A
	dc.w	$89,$88,$87,$86,$86,$85,$84,$83
	dc.w	$82,$81,$80,$7F,$7F,$7E,$7D,$7C
	dc.w	$7B,$7A,$7A,$79,$78,$77,$76,$76
	dc.w	$75,$74,$73,$72,$72,$71,$70,$6F
	dc.w	$6F,$6E,$6D,$6C,$6C,$6B,$6A,$6A
	dc.w	$69,$68,$68,$67,$66,$66,$65,$65
	dc.w	$64,$63,$63,$62,$62,$61,$61,$60
	dc.w	$5F,$5F,$5E,$5E,$5D,$5D,$5D,$5C
	dc.w	$5C,$5B,$5B,$5A,$5A,$59,$59,$59
	dc.w	$58,$58,$58,$57,$57,$57,$56,$56
	dc.w	$56,$56,$55,$55,$55,$55,$54,$54
	dc.w	$54,$54,$54,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$54,$54
	dc.w	$54,$54,$54,$55,$55,$55,$55,$56
	dc.w	$56,$56,$56,$57,$57,$57,$58,$58
	dc.w	$58,$59,$59,$59,$5A,$5A,$5B,$5B
	dc.w	$5C,$5C,$5D,$5D,$5D,$5E,$5E,$5F
	dc.w	$5F,$60,$61,$61,$62,$62,$63,$63
	dc.w	$64,$65,$65,$66,$66,$67,$68,$68
	dc.w	$69,$6A,$6A,$6B,$6C,$6C,$6D,$6E
	dc.w	$6F,$6F,$70,$71,$72,$72,$73,$74
	dc.w	$75,$76,$76,$77,$78,$79,$7A,$7A
	dc.w	$7B,$7C,$7D,$7E,$7F,$7F,$80,$81
	dc.w	$82,$83,$84,$85,$86,$86,$87,$88
	dc.w	$89,$8A,$8B,$8C,$8D,$8E,$8F,$90
	dc.w	$90,$91,$92,$93,$94,$95,$96,$97
	dc.w	$98,$99,$9A,$9B,$9C,$9D,$9E,$9F

lbB021900:
	dc.b	$A6,$A6,$A6,$A6,$A6,$A6,$A6,$A6
	dc.b	$A6,$A6,$A6,$A6,$A6,$A6,$A5,$A5
	dc.b	$A5,$A5,$A5,$A4,$A4,$A4,$A4,$A3
	dc.b	$A3,$A3,$A3,$A2,$A2,$A2,$A1,$A1
	dc.b	$A1,$A0,$A0,$A0,$9F,$9F,$9E,$9E
	dc.b	$9D,$9D,$9C,$9C,$9C,$9B,$9B,$9A
	dc.b	$9A,$99,$98,$98,$97,$97,$96,$96
	dc.b	$95,$94,$94,$93,$93,$92,$91,$91
	dc.b	$90,$8F,$8F,$8E,$8D,$8D,$8C,$8B
	dc.b	$8A,$8A,$89,$88,$87,$87,$86,$85
	dc.b	$84,$83,$83,$82,$81,$80,$7F,$7F
	dc.b	$7E,$7D,$7C,$7B,$7A,$7A,$79,$78
	dc.b	$77,$76,$75,$74,$73,$73,$72,$71
	dc.b	$70,$6F,$6E,$6D,$6C,$6B,$6A,$69
	dc.b	$69,$68,$67,$66,$65,$64,$63,$62
	dc.b	$61,$60,$5F,$5E,$5D,$5C,$5B,$5A
	dc.b	$59,$59,$58,$57,$56,$55,$54,$53
	dc.b	$52,$51,$50,$4F,$4E,$4D,$4C,$4B
	dc.b	$4A,$4A,$49,$48,$47,$46,$45,$44
	dc.b	$43,$42,$41,$40,$40,$3F,$3E,$3D
	dc.b	$3C,$3B,$3A,$39,$39,$38,$37,$36
	dc.b	$35,$34,$34,$33,$32,$31,$30,$30
	dc.b	$2F,$2E,$2D,$2C,$2C,$2B,$2A,$29
	dc.b	$29,$28,$27,$26,$26,$25,$24,$24
	dc.b	$23,$22,$22,$21,$20,$20,$1F,$1F
	dc.b	$1E,$1D,$1D,$1C,$1C,$1B,$1B,$1A
	dc.b	$19,$19,$18,$18,$17,$17,$17,$16
	dc.b	$16,$15,$15,$14,$14,$13,$13,$13
	dc.b	$12,$12,$12,$11,$11,$11,$10,$10
	dc.b	$10,$10,15,15,15,15,14,14
	dc.b	14,14,14,13,13,13,13,13
	dc.b	13,13,13,13,13,13,13,13
	dc.b	13,13,13,13,13,13,13,13
	dc.b	13,13,13,13,13,13,14,14
	dc.b	14,14,14,15,15,15,15,$10
	dc.b	$10,$10,$10,$11,$11,$11,$12,$12
	dc.b	$12,$13,$13,$13,$14,$14,$15,$15
	dc.b	$16,$16,$17,$17,$17,$18,$18,$19
	dc.b	$19,$1A,$1B,$1B,$1C,$1C,$1D,$1D
	dc.b	$1E,$1F,$1F,$20,$20,$21,$22,$22
	dc.b	$23,$24,$24,$25,$26,$26,$27,$28
	dc.b	$29,$29,$2A,$2B,$2C,$2C,$2D,$2E
	dc.b	$2F,$30,$30,$31,$32,$33,$34,$34
	dc.b	$35,$36,$37,$38,$39,$39,$3A,$3B
	dc.b	$3C,$3D,$3E,$3F,$40,$40,$41,$42
	dc.b	$43,$44,$45,$46,$47,$48,$49,$4A
	dc.b	$4A,$4B,$4C,$4D,$4E,$4F,$50,$51
	dc.b	$52,$53,$54,$55,$56,$57,$58,$59
	dc.b	$5A,$5A,$5B,$5C,$5D,$5E,$5F,$60
	dc.b	$61,$62,$63,$64,$65,$66,$67,$68
	dc.b	$69,$69,$6A,$6B,$6C,$6D,$6E,$6F
	dc.b	$70,$71,$72,$73,$73,$74,$75,$76
	dc.b	$77,$78,$79,$7A,$7A,$7B,$7C,$7D
	dc.b	$7E,$7F,$7F,$80,$81,$82,$83,$83
	dc.b	$84,$85,$86,$87,$87,$88,$89,$8A
	dc.b	$8A,$8B,$8C,$8D,$8D,$8E,$8F,$8F
	dc.b	$90,$91,$91,$92,$93,$93,$94,$94
	dc.b	$95,$96,$96,$97,$97,$98,$98,$99
	dc.b	$9A,$9A,$9B,$9B,$9C,$9C,$9C,$9D
	dc.b	$9D,$9E,$9E,$9F,$9F,$A0,$A0,$A0
	dc.b	$A1,$A1,$A1,$A2,$A2,$A2,$A3,$A3
	dc.b	$A3,$A3,$A4,$A4,$A4,$A4,$A5,$A5
	dc.b	$A5,$A5,$A5,$A6,$A6,$A6,$A6,$A6
	dc.b	$A6,$A6,$A6,$A6,$A6,$A6,$A6,$A6
	dc.w	$71,$72,$74,$75,$76,$77,$78,$7A
	dc.w	$7B,$7C,$7D,$7F,$80,$81,$82,$83
	dc.w	$85,$86,$87,$88,$89,$8B,$8C,$8D
	dc.w	$8E,$90,$91,$92,$93,$94,$96,$97
	dc.w	$98,$99,$9A,$9C,$9D,$9E,$9F,$A1
	dc.w	$A2,$A3,$A4,$A5,$A7,$A8,$A9,$AA
	dc.w	$AB,$AD,$AE,$AF,$B0,$B2,$B3,$B4
	dc.w	$B5,$B6,$B8,$B9,$BA,$BB,$BC,$BE
	dc.w	$BF,$C0,$C1,$C3,$C4,$C5,$C6,$C7
	dc.w	$C9,$CA,$CB,$CC,$CD,$CF,$D0,$D1
	dc.w	$D2,$D4,$D5,$D6,$D7,$D8,$DA,$DB
	dc.w	$DC,$DD,$DE,$E0,$E1,$E2,$E3,$E5
	dc.w	$E6,$E7,$E8,$E9,$EB,$EC,$ED,$EB
	dc.w	$EA,$E8,$E7,$E5,$E4,$E2,$E1,$DF
	dc.w	$DE,$DC,$DB,$D9,$D8,$D6,$D5,$D3
	dc.w	$D2,$D0,$CF,$CD,$CC,$CA,$C9,$C7
	dc.w	$C6,$C4,$C3,$C1,$C0,$BE,$BD,$BB
	dc.w	$BA,$B8,$B7,$B5,$B4,$B2,$B1,$AF
	dc.w	$AE,$AC,$AB,$A9,$A8,$A6,$A5,$A3
	dc.w	$A2,$A0,$9E,$9D,$9B,$9A,$98,$97
	dc.w	$95,$94,$92,$91,$8F,$8E,$8C,$8B
	dc.w	$89,$88,$86,$85,$83,$82,$80,$7F
	dc.w	$7D,$7C,$7A,$79,$77,$76,$74,$73
	dc.w	$71,$70,$6E,$6D,$6B,$6A,$68,$67
	dc.w	$65,$64,$62,$61,$5F,$5E,$5C,$5B
	dc.w	$59,$58,$56,$55,$53,$54,$55,$57
	dc.w	$58,$59,$5A,$5B,$5D,$5E,$5F,$60
	dc.w	$61,$63,$64,$65,$66,$67,$69,$6A
	dc.w	$6B,$6C,$6D,$6F,$70,$71,$72,$74
	dc.w	$75,$76,$77,$78,$7A,$7B,$7C,$7D
	dc.w	$7E,$80,$81,$82,$83,$84,$86,$87
	dc.w	$88,$89,$8A,$8C,$8D,$8E,$8F,$90
	dc.w	$92,$93,$94,$95,$96,$98,$99,$9A
	dc.w	$9B,$9C,$9E,$9F,$A0,$A1,$A2,$A4
	dc.w	$A5,$A6,$A7,$A8,$AA,$AB,$AC,$AD
	dc.w	$AE,$B0,$B1,$B2,$B3,$B5,$B6,$B7
	dc.w	$B8,$B9,$BB,$BC,$BD,$BE,$BF,$C1
	dc.w	$C2,$C3,$C4,$C5,$C7,$C8,$C9,$CA
	dc.w	$CB,$CD,$CE,$CF,$CF,$CE,$CE,$CD
	dc.w	$CD,$CC,$CC,$CB,$CB,$CA,$CA,$C9
	dc.w	$C9,$C9,$C8,$C8,$C7,$C7,$C6,$C6
	dc.w	$C5,$C5,$C4,$C4,$C3,$C3,$C3,$C2
	dc.w	$C2,$C1,$C1,$C0,$C0,$BF,$BF,$BE
	dc.w	$BE,$BD,$BD,$BD,$BC,$BC,$BB,$BB
	dc.w	$BA,$BA,$B9,$B9,$B8,$B8,$B7,$B7
	dc.w	$B7,$B6,$B6,$B5,$B5,$B4,$B4,$B3
	dc.w	$B3,$B2,$B2,$B2,$B1,$B1,$B0,$B0
	dc.w	$AF,$AF,$AE,$AE,$AD,$AD,$AC,$AC
	dc.w	$AC,$AB,$AB,$AA,$AA,$A9,$A9,$A8
	dc.w	$A8,$A7,$A7,$A6,$A6,$A6,$A5,$A5
	dc.w	$A4,$A4,$A3,$A3,$A2,$A2,$A1,$A1
	dc.w	$A0,$A0,$A0,$9F,$9F,$9E,$9E,$9D
	dc.w	$9D,$9C,$9C,$9B,$9B,$9A,$9A,$99
	dc.w	$99,$98,$98,$98,$97,$97,$96,$96
	dc.w	$95,$95,$94,$94,$93,$93,$92,$92
	dc.w	$91,$91,$90,$90,$90,$8F,$8F,$8E
	dc.w	$8E,$8D,$8D,$8C,$8C,$8B,$8B,$8A
	dc.w	$8A,$89,$89,$88,$88,$88,$87,$87
	dc.w	$86,$86,$85,$85,$84,$84,$83,$83
	dc.w	$82,$82,$81,$81,$80,$80,$80,$7F
	dc.w	$7F,$7E,$7E,$7D,$7D,$7C,$7C,$7B
	dc.w	$7B,$7A,$7A,$79,$79,$78,$78,$78
	dc.w	$77,$77,$76,$76,$75,$75,$74,$74
	dc.w	$73,$73,$72,$72,$71,$71,$70,$70
	dc.b	$A4,$A3,$A2,$A2,$A1,$A0,$9F,$9E
	dc.b	$9D,$9C,$9B,$9B,$9A,$99,$98,$97
	dc.b	$96,$95,$94,$94,$93,$92,$91,$90
	dc.b	$8F,$8E,$8D,$8D,$8C,$8B,$8A,$89
	dc.b	$88,$87,$86,$86,$85,$84,$83,$82
	dc.b	$81,$80,$7F,$7F,$7E,$7D,$7C,$7B
	dc.b	$7A,$79,$78,$78,$77,$76,$75,$74
	dc.b	$73,$72,$71,$71,$70,$6F,$6E,$6D
	dc.b	$6C,$6B,$6A,$6A,$69,$68,$67,$66
	dc.b	$65,$64,$63,$63,$62,$61,$60,$5F
	dc.b	$5E,$5D,$5C,$5C,$5B,$5A,$59,$58
	dc.b	$57,$56,$55,$55,$54,$53,$52,$51
	dc.b	$50,$4F,$4E,$4E,$4D,$4C,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4B,$4B,$4B
	dc.b	$4B,$4B,$4B,$4B,$4B,$4C,$4D,$4E
	dc.b	$4E,$4F,$50,$51,$52,$53,$54,$55
	dc.b	$55,$56,$57,$58,$59,$5A,$5B,$5C
	dc.b	$5C,$5D,$5E,$5F,$60,$61,$62,$63
	dc.b	$63,$64,$65,$66,$67,$68,$69,$6A
	dc.b	$6A,$6B,$6C,$6D,$6E,$6F,$70,$71
	dc.b	$71,$72,$73,$74,$75,$76,$77,$78
	dc.b	$78,$79,$7A,$7B,$7C,$7D,$7E,$7F
	dc.b	$7F,$80,$81,$82,$83,$84,$85,$86
	dc.b	$86,$87,$88,$89,$8A,$8B,$8C,$8D
	dc.b	$8D,$8E,$8F,$90,$91,$92,$93,$94
	dc.b	$94,$95,$96,$97,$98,$99,$9A,$9B
	dc.b	$9B,$9C,$9D,$9E,$9F,$A0,$A1,$A2
	dc.b	$A2,$A3,$A4,$A5,$A4,$A2,$A1,$9F
	dc.b	$9E,$9C,$9B,$9A,$98,$97,$95,$94
	dc.b	$92,$91,$90,$8E,$8D,$8B,$8A,$88
	dc.b	$87,$86,$84,$83,$81,$80,$7E,$7D
	dc.b	$7B,$7A,$79,$77,$76,$74,$73,$71
	dc.b	$70,$6F,$6D,$6C,$6A,$69,$67,$66
	dc.b	$65,$63,$62,$60,$5F,$5D,$5C,$5B
	dc.b	$59,$58,$56,$55,$53,$52,$51,$4F
	dc.b	$4E,$4C,$4B,$49,$48,$47,$45,$44
	dc.b	$42,$41,$3F,$3E,$3D,$3B,$3A,$38
	dc.b	$37,$35,$34,$32,$31,$30,$2E,$2D
	dc.b	$2B,$2A,$28,$27,$26,$24,$23,$21
	dc.b	$20,$1E,$1D,$1C,$1A,$19,$17,$16
	dc.b	$14,$13,$14,$16,$17,$19,$1A,$1C
	dc.b	$1D,$1E,$20,$21,$23,$24,$26,$27
	dc.b	$28,$2A,$2B,$2D,$2E,$30,$31,$32
	dc.b	$34,$35,$37,$38,$3A,$3B,$3D,$3E
	dc.b	$3F,$41,$42,$44,$45,$47,$48,$49
	dc.b	$4B,$4C,$4E,$4F,$51,$52,$53,$55
	dc.b	$56,$58,$59,$5B,$5C,$5D,$5F,$60
	dc.b	$62,$63,$65,$66,$67,$69,$6A,$6C
	dc.b	$6D,$6F,$70,$71,$73,$74,$76,$77
	dc.b	$79,$7A,$7B,$7D,$7E,$80,$81,$83
	dc.b	$84,$86,$87,$88,$8A,$8B,$8D,$8E
	dc.b	$90,$91,$92,$94,$95,$97,$98,$9A
	dc.b	$9B,$9C,$9E,$9F,$A1,$A2,$A4,$A5
	dc.w	$54,$55,$57,$58,$59,$5A,$5B,$5D
	dc.w	$5E,$5F,$60,$61,$63,$64,$65,$66
	dc.w	$67,$69,$6A,$6B,$6C,$6D,$6F,$70
	dc.w	$71,$72,$73,$75,$76,$77,$78,$7A
	dc.w	$7B,$7C,$7D,$7E,$80,$81,$82,$83
	dc.w	$84,$86,$87,$88,$89,$8A,$8C,$8D
	dc.w	$8E,$8F,$90,$92,$93,$94,$95,$96
	dc.w	$98,$99,$9A,$9B,$9C,$9E,$9F,$A0
	dc.w	$A1,$A2,$A4,$A5,$A6,$A7,$A8,$AA
	dc.w	$AB,$AC,$AD,$AE,$B0,$B1,$B2,$B3
	dc.w	$B4,$B6,$B7,$B8,$B9,$BA,$BC,$BD
	dc.w	$BE,$BF,$C0,$C2,$C3,$C4,$C5,$C6
	dc.w	$C8,$C9,$CA,$CB,$CD,$CE,$CF,$D0
	dc.w	$D1,$D3,$D4,$D5,$D6,$D7,$D9,$DA
	dc.w	$DB,$DC,$DD,$DF,$E0,$E1,$E2,$E3
	dc.w	$E5,$E6,$E7,$E8,$E9,$EB,$EC,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
	dc.w	$EC,$EB,$E9,$E8,$E7,$E6,$E5,$E3
	dc.w	$E2,$E1,$E0,$DF,$DD,$DC,$DB,$DA
	dc.w	$D9,$D7,$D6,$D5,$D4,$D3,$D1,$D0
	dc.w	$CF,$CE,$CD,$CB,$CA,$C9,$C8,$C6
	dc.w	$C5,$C4,$C3,$C2,$C0,$BF,$BE,$BD
	dc.w	$BC,$BA,$B9,$B8,$B7,$B6,$B4,$B3
	dc.w	$B2,$B1,$B0,$AE,$AD,$AC,$AB,$AA
	dc.w	$A8,$A7,$A6,$A5,$A4,$A2,$A1,$A0
	dc.w	$9F,$9E,$9C,$9B,$9A,$99,$98,$96
	dc.w	$95,$94,$93,$92,$90,$8F,$8E,$8D
	dc.w	$8C,$8A,$89,$88,$87,$86,$84,$83
	dc.w	$82,$81,$80,$7E,$7D,$7C,$7B,$7A
	dc.w	$78,$77,$76,$75,$73,$72,$71,$70
	dc.w	$6F,$6D,$6C,$6B,$6A,$69,$67,$66
	dc.w	$65,$64,$63,$61,$60,$5F,$5E,$5D
	dc.w	$5B,$5A,$59,$58,$57,$55,$54,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A4,$A3,$A2,$A0,$9F,$9E,$9D,$9C
	dc.b	$9B,$9A,$98,$97,$96,$95,$94,$93
	dc.b	$92,$90,$8F,$8E,$8D,$8C,$8B,$8A
	dc.b	$88,$87,$86,$85,$84,$83,$82,$80
	dc.b	$7F,$7E,$7D,$7C,$7B,$7A,$79,$77
	dc.b	$76,$75,$74,$73,$72,$71,$6F,$6E
	dc.b	$6D,$6C,$6B,$6A,$69,$67,$66,$65
	dc.b	$64,$63,$62,$61,$5F,$5E,$5D,$5C
	dc.b	$5B,$5A,$59,$57,$56,$55,$54,$53
	dc.b	$52,$51,$4F,$4E,$4D,$4C,$4B,$4A
	dc.b	$49,$47,$46,$45,$44,$43,$42,$41
	dc.b	$3F,$3E,$3D,$3C,$3B,$3A,$39,$38
	dc.b	$36,$35,$34,$33,$32,$31,$30,$2E
	dc.b	$2D,$2C,$2B,$2A,$29,$28,$26,$25
	dc.b	$24,$23,$22,$21,$20,$1E,$1D,$1C
	dc.b	$1B,$1A,$19,$18,$16,$15,$14,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$13,$13,$13,$13,$13,$13,$13,$13
	dc.b	$14,$15,$16,$18,$19,$1A,$1B,$1C
	dc.b	$1D,$1E,$20,$21,$22,$23,$24,$25
	dc.b	$26,$28,$29,$2A,$2B,$2C,$2D,$2E
	dc.b	$30,$31,$32,$33,$34,$35,$36,$38
	dc.b	$39,$3A,$3B,$3C,$3D,$3E,$3F,$41
	dc.b	$42,$43,$44,$45,$46,$47,$49,$4A
	dc.b	$4B,$4C,$4D,$4E,$4F,$51,$52,$53
	dc.b	$54,$55,$56,$57,$59,$5A,$5B,$5C
	dc.b	$5D,$5E,$5F,$61,$62,$63,$64,$65
	dc.b	$66,$67,$69,$6A,$6B,$6C,$6D,$6E
	dc.b	$6F,$71,$72,$73,$74,$75,$76,$77
	dc.b	$79,$7A,$7B,$7C,$7D,$7E,$7F,$80
	dc.b	$82,$83,$84,$85,$86,$87,$88,$8A
	dc.b	$8B,$8C,$8D,$8E,$8F,$90,$92,$93
	dc.b	$94,$95,$96,$97,$98,$9A,$9B,$9C
	dc.b	$9D,$9E,$9F,$A0,$A2,$A3,$A4,$A5
	dc.w	$A0,$A0,$A1,$A2,$A3,$A4,$A5,$A6
	dc.w	$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE
	dc.w	$AF,$AF,$B0,$B1,$B2,$B3,$B4,$B5
	dc.w	$B6,$B7,$B8,$B9,$B9,$BA,$BB,$BC
	dc.w	$BD,$BE,$BF,$C0,$C0,$C1,$C2,$C3
	dc.w	$C4,$C5,$C5,$C6,$C7,$C8,$C9,$C9
	dc.w	$CA,$CB,$CC,$CD,$CD,$CE,$CF,$D0
	dc.w	$D0,$D1,$D2,$D3,$D3,$D4,$D5,$D5
	dc.w	$D6,$D7,$D7,$D8,$D9,$D9,$DA,$DA
	dc.w	$DB,$DC,$DC,$DD,$DD,$DE,$DE,$DF
	dc.w	$E0,$E0,$E1,$E1,$E2,$E2,$E2,$E3
	dc.w	$E3,$E4,$E4,$E5,$E5,$E6,$E6,$E6
	dc.w	$E7,$E7,$E7,$E8,$E8,$E8,$E9,$E9
	dc.w	$E9,$E9,$EA,$EA,$EA,$EA,$EB,$EB
	dc.w	$EB,$EB,$EB,$EC,$EC,$EC,$EC,$EC
	dc.w	$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC
	dc.w	$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC
	dc.w	$EC,$EC,$EC,$EC,$EC,$EC,$EB,$EB
	dc.w	$EB,$EB,$EB,$EA,$EA,$EA,$EA,$E9
	dc.w	$E9,$E9,$E9,$E8,$E8,$E8,$E7,$E7
	dc.w	$E7,$E6,$E6,$E6,$E5,$E5,$E4,$E4
	dc.w	$E3,$E3,$E2,$E2,$E2,$E1,$E1,$E0
	dc.w	$E0,$DF,$DE,$DE,$DD,$DD,$DC,$DC
	dc.w	$DB,$DA,$DA,$D9,$D9,$D8,$D7,$D7
	dc.w	$D6,$D5,$D5,$D4,$D3,$D3,$D2,$D1
	dc.w	$D0,$D0,$CF,$CE,$CD,$CD,$CC,$CB
	dc.w	$CA,$C9,$C9,$C8,$C7,$C6,$C5,$C5
	dc.w	$C4,$C3,$C2,$C1,$C0,$C0,$BF,$BE
	dc.w	$BD,$BC,$BB,$BA,$B9,$B9,$B8,$B7
	dc.w	$B6,$B5,$B4,$B3,$B2,$B1,$B0,$AF
	dc.w	$AF,$AE,$AD,$AC,$AB,$AA,$A9,$A8
	dc.w	$A7,$A6,$A5,$A4,$A3,$A2,$A1,$A0
	dc.w	$9F,$9F,$9E,$9D,$9C,$9B,$9A,$99
	dc.w	$98,$97,$96,$95,$94,$93,$92,$91
	dc.w	$90,$90,$8F,$8E,$8D,$8C,$8B,$8A
	dc.w	$89,$88,$87,$86,$86,$85,$84,$83
	dc.w	$82,$81,$80,$7F,$7F,$7E,$7D,$7C
	dc.w	$7B,$7A,$7A,$79,$78,$77,$76,$76
	dc.w	$75,$74,$73,$72,$72,$71,$70,$6F
	dc.w	$6F,$6E,$6D,$6C,$6C,$6B,$6A,$6A
	dc.w	$69,$68,$68,$67,$66,$66,$65,$65
	dc.w	$64,$63,$63,$62,$62,$61,$61,$60
	dc.w	$5F,$5F,$5E,$5E,$5D,$5D,$5D,$5C
	dc.w	$5C,$5B,$5B,$5A,$5A,$59,$59,$59
	dc.w	$58,$58,$58,$57,$57,$57,$56,$56
	dc.w	$56,$56,$55,$55,$55,$55,$54,$54
	dc.w	$54,$54,$54,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$53,$53
	dc.w	$53,$53,$53,$53,$53,$53,$54,$54
	dc.w	$54,$54,$54,$55,$55,$55,$55,$56
	dc.w	$56,$56,$56,$57,$57,$57,$58,$58
	dc.w	$58,$59,$59,$59,$5A,$5A,$5B,$5B
	dc.w	$5C,$5C,$5D,$5D,$5D,$5E,$5E,$5F
	dc.w	$5F,$60,$61,$61,$62,$62,$63,$63
	dc.w	$64,$65,$65,$66,$66,$67,$68,$68
	dc.w	$69,$6A,$6A,$6B,$6C,$6C,$6D,$6E
	dc.w	$6F,$6F,$70,$71,$72,$72,$73,$74
	dc.w	$75,$76,$76,$77,$78,$79,$7A,$7A
	dc.w	$7B,$7C,$7D,$7E,$7F,$7F,$80,$81
	dc.w	$82,$83,$84,$85,$86,$86,$87,$88
	dc.w	$89,$8A,$8B,$8C,$8D,$8E,$8F,$90
	dc.w	$90,$91,$92,$93,$94,$95,$96,$97
	dc.w	$98,$99,$9A,$9B,$9C,$9D,$9E,$9F
	dc.b	12,12,12,12,12,12,12,12
	dc.b	12,12,12,12,12,12,12,12
	dc.b	12,12,12,13,13,13,13,13
	dc.b	13,13,13,14,14,14,14,14
	dc.b	14,15,15,15,15,$10,$10,$10
	dc.b	$10,$10,$11,$11,$11,$11,$12,$12
	dc.b	$12,$12,$13,$13,$13,$14,$14,$14
	dc.b	$15,$15,$15,$16,$16,$16,$17,$17
	dc.b	$17,$18,$18,$18,$19,$19,$1A,$1A
	dc.b	$1A,$1B,$1B,$1C,$1C,$1D,$1D,$1D
	dc.b	$1E,$1E,$1F,$1F,$20,$20,$21,$21
	dc.b	$22,$22,$23,$23,$24,$24,$25,$25
	dc.b	$26,$26,$27,$27,$28,$29,$29,$2A
	dc.b	$2A,$2B,$2B,$2C,$2D,$2D,$2E,$2E
	dc.b	$2F,$30,$30,$31,$31,$32,$33,$33
	dc.b	$34,$35,$35,$36,$37,$37,$38,$39
	dc.b	$39,$3A,$3B,$3B,$3C,$3D,$3D,$3E
	dc.b	$3F,$3F,$40,$41,$42,$42,$43,$44
	dc.b	$45,$45,$46,$47,$48,$48,$49,$4A
	dc.b	$4B,$4B,$4C,$4D,$4E,$4E,$4F,$50
	dc.b	$51,$52,$52,$53,$54,$55,$56,$56
	dc.b	$57,$58,$59,$5A,$5B,$5B,$5C,$5D
	dc.b	$5E,$5F,$60,$61,$61,$62,$63,$64
	dc.b	$65,$66,$67,$67,$68,$69,$6A,$6B
	dc.b	$6C,$6D,$6E,$6E,$6F,$70,$71,$72
	dc.b	$73,$74,$75,$76,$77,$77,$78,$79
	dc.b	$7A,$7B,$7C,$7D,$7E,$7F,$80,$81
	dc.b	$82,$83,$83,$84,$85,$86,$87,$88
	dc.b	$89,$8A,$8B,$8C,$8D,$8E,$8F,$90
	dc.b	$91,$92,$93,$93,$94,$95,$96,$97
	dc.b	$98,$99,$9A,$9B,$9C,$9D,$9E,$9F
	dc.b	$A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
	dc.b	$A7,$A6,$A5,$A4,$A3,$A2,$A1,$A0
	dc.b	$9F,$9E,$9D,$9C,$9B,$9A,$99,$98
	dc.b	$97,$96,$95,$94,$93,$93,$92,$91
	dc.b	$90,$8F,$8E,$8D,$8C,$8B,$8A,$89
	dc.b	$88,$87,$86,$85,$84,$83,$83,$82
	dc.b	$81,$80,$7F,$7E,$7D,$7C,$7B,$7A
	dc.b	$79,$78,$77,$77,$76,$75,$74,$73
	dc.b	$72,$71,$70,$6F,$6E,$6E,$6D,$6C
	dc.b	$6B,$6A,$69,$68,$67,$67,$66,$65
	dc.b	$64,$63,$62,$61,$61,$60,$5F,$5E
	dc.b	$5D,$5C,$5B,$5B,$5A,$59,$58,$57
	dc.b	$56,$56,$55,$54,$53,$52,$52,$51
	dc.b	$50,$4F,$4E,$4E,$4D,$4C,$4B,$4B
	dc.b	$4A,$49,$48,$48,$47,$46,$45,$45
	dc.b	$44,$43,$42,$42,$41,$40,$3F,$3F
	dc.b	$3E,$3D,$3D,$3C,$3B,$3B,$3A,$39
	dc.b	$39,$38,$37,$37,$36,$35,$35,$34
	dc.b	$33,$33,$32,$31,$31,$30,$30,$2F
	dc.b	$2E,$2E,$2D,$2D,$2C,$2B,$2B,$2A
	dc.b	$2A,$29,$29,$28,$27,$27,$26,$26
	dc.b	$25,$25,$24,$24,$23,$23,$22,$22
	dc.b	$21,$21,$20,$20,$1F,$1F,$1E,$1E
	dc.b	$1D,$1D,$1D,$1C,$1C,$1B,$1B,$1A
	dc.b	$1A,$1A,$19,$19,$18,$18,$18,$17
	dc.b	$17,$17,$16,$16,$16,$15,$15,$15
	dc.b	$14,$14,$14,$13,$13,$13,$12,$12
	dc.b	$12,$12,$11,$11,$11,$11,$10,$10
	dc.b	$10,$10,$10,15,15,15,15,14
	dc.b	14,14,14,14,14,13,13,13
	dc.b	13,13,13,13,13,12,12,12
	dc.b	12,12,12,12,12,12,12,12
	dc.b	12,12,12,12,12,12,12,12

	section	chipdata,data_c

copperlist:
	dc.w	$120
cop_spr0ptr:
	dc.w	0
	dc.w	$122,0

	dc.w	$124,0
	dc.w	$126,0

	dc.w	$128,0
	dc.w	$12A,0

	dc.w	$12C,0
	dc.w	$12E,0

	dc.w	$130,0
	dc.w	$132,0

	dc.w	$134,0
	dc.w	$136,0

	dc.w	$138,0
	dc.w	$13A,0

	dc.w	$13C,0
	dc.w	$13E,0

;	dc.w	$8E,$3B00		;original
	dc.w	$8E,$2181		;corrected value (MTN)
;	dc.w	$90,$40FF		;original
	dc.w	$90,$38C1		;corrected value (MTN)
	dc.w	$92,$30
	dc.w	$94,$D8

	dc.w	$E0			;$60000
cop_bpl0ptr:
	dc.w	0
	dc.w	$E2,0

	dc.w	$E4,0			;$6002C
	dc.w	$E6,0

	dc.w	$E8,0			;$60058
	dc.w	$EA,0

	dc.w	$EC,0			;$60084
	dc.w	$EE,0

	dc.w	$102,0
	dc.w	$104
bplcon2_ctrl:
	dc.w	4
	dc.w	$108,$84
	dc.w	$10A,$84

	dc.w	$180,0
	dc.w	$182
lbW000FBE:
	dc.w	0
	dc.w	$184,$000
	dc.w	$186,$000
	dc.w	$188,$000
	dc.w	$18A,$000
	dc.w	$18C,$000
	dc.w	$18E,$000
	dc.w	$190,$000
	dc.w	$192,$000
	dc.w	$194,$000
	dc.w	$196,$000
	dc.w	$198,$000
	dc.w	$19A,$000
	dc.w	$19C,$000
	dc.w	$19E,$000

	dc.w	$1A2
cop_color17:
	dc.w	0
	dc.w	$1AA
cop_color21:
	dc.w	0
	dc.w	$1B2
cop_color25:
	dc.w	0
cop_scope:
	ds.l	25*5

	dc.w	$3A09,$FFFE
	dc.w	$180,$FFF

	dc.w	$3B09,$FFFE
	dc.w	$100,$4200		;BPLCON0 = 4 bitplanes;COLOR
	dc.w	$180,$000

	dc.w	$7A09,$FFFE
	dc.w	$180,$001
	dc.w	$7B09,$FFFE
	dc.w	$180,$000
	dc.w	$7C09,$FFFE
	dc.w	$180,$001
	dc.w	$8C09,$FFFE
	dc.w	$180,$002
	dc.w	$8D09,$FFFE
	dc.w	$180,$001
	dc.w	$8E09,$FFFE
	dc.w	$180,$002
	dc.w	$9E09,$FFFE
	dc.w	$180,$003
	dc.w	$9F09,$FFFE
	dc.w	$180,$002
	dc.w	$A009,$FFFE
	dc.w	$180,$003
	dc.w	$B201,$FFFE
	dc.w	$180,$004
	dc.w	$B301,$FFFE
	dc.w	$180,$003
	dc.w	$B401,$FFFE
	dc.w	$180,$004
	dc.w	$C109,$FFFE
	dc.w	$180,$005
	dc.w	$C209,$FFFE
	dc.w	$180,$006
	dc.w	$C309,$FFFE
	dc.w	$180,$007
	dc.w	$C409,$FFFE
	dc.w	$180,$008
	dc.w	$C509,$FFFE
	dc.w	$180,$009
	dc.w	$C609,$FFFE
	dc.w	$180,$00A
	dc.w	$C709,$FFFE
	dc.w	$180,$00B
	dc.w	$C809,$FFFE
	dc.w	$180,$00C
	dc.w	$182,$620
	dc.w	$184,$420
	dc.w	$C909,$FFFE
	dc.w	$180,$00D
	dc.w	$CA09,$FFFE
	dc.w	$180,$00E
	dc.w	$CB09,$FFFE
	dc.w	$180,$00F
	dc.w	$CC09,$FFFE
	dc.w	$180,$11F
	dc.w	$CD09,$FFFE
	dc.w	$180,$22F
	dc.w	$CE09,$FFFE
	dc.w	$180,$33F
	dc.w	$CF09,$FFFE
	dc.w	$180,$44F
	dc.w	$D009,$FFFE
	dc.w	$180,$55F
	dc.w	$D109,$FFFE
	dc.w	$180,$66F
	dc.w	$D209,$FFFE
	dc.w	$180,$77F
	dc.w	$D309,$FFFE
	dc.w	$180,$88C
	dc.w	$D409,$FFFE
	dc.w	$180,$99A
	dc.w	$D509,$FFFE
	dc.w	$180,$AA8
	dc.w	$D609,$FFFE
	dc.w	$180,$BB6
	dc.w	$D709,$FFFE
	dc.w	$180,$CC5
	dc.w	$D809,$FFFE
	dc.w	$180,$DD3
	dc.w	$D909,$FFFE
	dc.w	$180,$EE1
	dc.w	$DA09,$FFFE
	dc.w	$180,$FF0
	dc.w	$DB09,$FFFE
	dc.w	$180,$FE0
	dc.w	$DC09,$FFFE
	dc.w	$180,$FD0
	dc.w	$DD09,$FFFE
	dc.w	$180,$FC0
	dc.w	$DE09,$FFFE
	dc.w	$180,$FB0
	dc.w	$DF09,$FFFE
	dc.w	$180,$FA0
	dc.w	$E009,$FFFE
	dc.w	$180,$F90
	dc.w	$E109,$FFFE
	dc.w	$180,$F80
	dc.w	$E209,$FFFE
	dc.w	$180,$F70
	dc.w	$E309,$FFFE
	dc.w	$180,$F60
	dc.w	$E409,$FFFE
	dc.w	$180,$F50
	dc.w	$E509,$FFFE
	dc.w	$180,$F40
	dc.w	$E609,$FFFE
	dc.w	$180,$F30
	dc.w	$E709,$FFFE
	dc.w	$180,$F20
	dc.w	$E809,$FFFE
	dc.w	$180,$F10
	dc.w	$E909,$FFFE
	dc.w	$180,$F00
	dc.w	$EB09,$FFFE
	dc.w	$182,$624
	dc.w	$184,$424
	dc.w	$EC09,$FFFE
	dc.w	$182,$628
	dc.w	$184,$428
	dc.w	$ED09,$FFFE
	dc.w	$182,$408
	dc.w	$EE09,$FFFE
	dc.w	$182,$20A
	dc.w	$EF09,$FFFE
	dc.w	$182,$30C
	dc.w	$F009,$FFFE
	dc.w	$182,$11D

	dc.w	$F101,$FFFE
	dc.w	$100,$6200		;BPLCON0 = 6 bitplanes

	dc.w	$F0			;$6A7D0
cop_bpl5ptr:
	dc.w	0
	dc.w	$F2,0

	dc.w	$F4,0			;$6A7FC
;This label is needed for 6 bytes later
lbW001408:
	dc.w	$F6,0

	dc.w	$182,$000
	dc.w	$184,$000
	dc.w	$F209,$FFFE
	dc.w	$182,$000
	dc.w	$184,$000
	dc.w	$F309,$FFFE
	dc.w	$182,$000
	dc.w	$184,$000
	dc.w	$F409,$FFFE
	dc.w	$182,$000
	dc.w	$184,$000
	dc.w	$F509,$FFFE
	dc.w	$182,$000
	dc.w	$184,$000
	dc.w	$F609,$FFFE
	dc.w	$182,$000
	dc.w	$184,$000
	dc.w	$F709,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$F809,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$F909,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$FB09,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$FD09,$FFFE
	dc.w	$182,$632
	dc.w	$184,$854
	dc.w	$FE09,$FFFE
	dc.w	$182,$632
	dc.w	$184,$854
	dc.w	$FFDF,$FFFE
	dc.w	$182,$632
	dc.w	$184,$854
	dc.w	$0309,$FFFE
	dc.w	$182,$632
	dc.w	$184,$854
	dc.w	$509,$FFFE
	dc.w	$182,$632
	dc.w	$184,$854
	dc.w	$809,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$C09,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$1009,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$1509,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632
	dc.w	$1709,$FFFE
	dc.w	$182,$854
	dc.w	$184,$632

	dc.w	$1709,$FFFE
	dc.w	$180,$FFF
	dc.w	$100,$200		;BPLCON0 = 0 bitplanes
	dc.w	$182,$A00
	dc.w	$184,$C00
	dc.w	$186,$F00

;Scroller part
	dc.w	$92,$28
	dc.w	$94,$E0

	dc.w	$108,2			;BPL1MOD
	dc.w	$10A,2			;BPL2MOD

	dc.w	$E0
cop_bpl0ptr_scr:
	dc.w	0
	dc.w	$E2
	dc.w	0

	dc.w	$E4
	dc.w	0
	dc.w	$E6
	dc.w	0

	dc.w	$1809,$FFFE
	dc.w	$180,$000
	dc.w	$102
cop_bplcon1:
	dc.w	0
cop_scrollw1:
	dc.w	$1901,$FFFE
	dc.w	$100,$2200		;BPLCON0 = 2 bitplanes;COLOR
cop_scrollw2:
	dc.w	$2D09,$FFFE
	dc.w	$100,$200		;BPLCON0 = 0 bitplanes;COLOR
	dc.w	$FFFF,$FFFE

;empty sprite definition
nullspr:	dc.l	0

; $5C000
menuspr0:
	dc.w	$3C40
	dc.w	$7500
	dc.w	%1100110000000111
	dc.w	%0000000000000000
	dc.w	%1100110000001100
	dc.w	%0000000000000000
	dc.w	%0111100111100111
	dc.w	%0000000000000000
	dc.w	%1100110000000000
	dc.w	%0000000000000000
	dc.w	%1100110000001111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1100110000000111
	dc.w	%0000000000000000
	dc.w	%1100110000001100
	dc.w	%0000000000000000
	dc.w	%0111100111100111
	dc.w	%0000000000000000
	dc.w	%0011000000000000
	dc.w	%0000000000000000
	dc.w	%0011000000001111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1100110111111011
	dc.w	%0000000000000000
	dc.w	%1110110110000011
	dc.w	%0000000000000000
	dc.w	%1111110111100001
	dc.w	%0000000000000000
	dc.w	%1101110110000011
	dc.w	%0000000000000000
	dc.w	%1100110111111011
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1100110111111011
	dc.w	%0000000000000000
	dc.w	%1110110110000011
	dc.w	%0000000000000000
	dc.w	%1111110111100001
	dc.w	%0000000000000000
	dc.w	%1101110110000011
	dc.w	%0000000000000000
	dc.w	%1100110111111011
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1111111111111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000001111
	dc.w	%0000000000000000
	dc.w	%0000000000011000
	dc.w	%0000000000000000
	dc.w	%0000000000011000
	dc.w	%0000000000000000
	dc.w	%0000000000011000
	dc.w	%0000000000000000
	dc.w	%0000000000001111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000001
	dc.w	%0000000000000000
	dc.w	%0000000000000001
	dc.w	%0000000000000000
	dc.w	%0000000000000001
	dc.w	%0000000000000000
	dc.w	%0000000000000001
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000011
	dc.w	%0000000000000000
	dc.w	%0000000000000011
	dc.w	%0000000000000000
	dc.w	%0000000000000011
	dc.w	%0000000000000000
	dc.w	%0000000000000011
	dc.w	%0000000000000000
	dc.w	%0000000000000011
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
menusprsize equ *-menuspr0

	dc.w	$3C48
	dc.w	$7500
	dc.w	%1101111100111111
	dc.w	%0000000000000000
	dc.w	%0001100110110000
	dc.w	%0000000000000000
	dc.w	%1001111100111100
	dc.w	%0000000000000000
	dc.w	%1101100000110000
	dc.w	%0000000000000000
	dc.w	%1001100000111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1101111100111111
	dc.w	%0000000000000000
	dc.w	%0001100110110000
	dc.w	%0000000000000000
	dc.w	%1001111100111100
	dc.w	%0000000000000000
	dc.w	%1101100000110000
	dc.w	%0000000000000000
	dc.w	%1001100000111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0011011111100000
	dc.w	%0000000000000000
	dc.w	%0011000110000000
	dc.w	%0000000000000000
	dc.w	%1110000110001111
	dc.w	%0000000000000000
	dc.w	%0011000110000000
	dc.w	%0000000000000000
	dc.w	%0011000110000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0011011111100000
	dc.w	%0000000000000000
	dc.w	%0011000110000000
	dc.w	%0000000000000000
	dc.w	%1110000110001111
	dc.w	%0000000000000000
	dc.w	%0011000110000000
	dc.w	%0000000000000000
	dc.w	%0011000110000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1111111111111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1001111001111100
	dc.w	%0000000000000000
	dc.w	%0011001101100110
	dc.w	%0000000000000000
	dc.w	%0011001101100110
	dc.w	%0000000000000000
	dc.w	%0011001101100110
	dc.w	%0000000000000000
	dc.w	%1001111001111100
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1001101100110110
	dc.w	%0000000000000000
	dc.w	%1001101110110110
	dc.w	%0000000000000000
	dc.w	%1001101111110111
	dc.w	%0000000000000000
	dc.w	%1001101101110110
	dc.w	%0000000000000000
	dc.w	%1111001100110110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1111111100000000
	dc.w	%0000000000000000
	dc.w	%1100001111000000
	dc.w	%0000000000000000
	dc.w	%1100001111000000
	dc.w	%0000000000000000
	dc.w	%1100001111001111
	dc.w	%0000000000000000
	dc.w	%1111111100001111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000

	dc.w	$3C50
	dc.w	$7500
	dc.w	%0111111011111000
	dc.w	%0000000000000000
	dc.w	%0110000011001100
	dc.w	%0000000000000000
	dc.w	%0111100011001100
	dc.w	%0000000000000000
	dc.w	%0110000011001100
	dc.w	%0000000000000000
	dc.w	%0111111011111000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0111111011111000
	dc.w	%0000000000000000
	dc.w	%0110000011001100
	dc.w	%0000000000000000
	dc.w	%0111100011001100
	dc.w	%0000000000000000
	dc.w	%0110000011001100
	dc.w	%0000000000000000
	dc.w	%0111111011111000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0110011000000000
	dc.w	%0000000000000000
	dc.w	%0110011000000000
	dc.w	%0000000000000000
	dc.w	%0011110000000000
	dc.w	%0000000000000000
	dc.w	%0110011000000000
	dc.w	%0000000000000000
	dc.w	%0110011000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0110011000000000
	dc.w	%0000000000000000
	dc.w	%0110011000000000
	dc.w	%0000000000000000
	dc.w	%0011110000000000
	dc.w	%0000000000000000
	dc.w	%0001100000000000
	dc.w	%0000000000000000
	dc.w	%0001100000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1111111111111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1111011001100111
	dc.w	%0000000000000000
	dc.w	%0110011101101100
	dc.w	%0000000000000000
	dc.w	%0110011111101101
	dc.w	%0000000000000000
	dc.w	%0110011011101100
	dc.w	%0000000000000000
	dc.w	%1111011001100111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0110110011001111
	dc.w	%0000000000000000
	dc.w	%1100111011011001
	dc.w	%0000000000000000
	dc.w	%1000111111011001
	dc.w	%0000000000000000
	dc.w	%1100110111011001
	dc.w	%0000000000000000
	dc.w	%0110110011001111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0011110011111100
	dc.w	%0000000000000000
	dc.w	%0110011011000000
	dc.w	%0000000000000000
	dc.w	%0110011011110000
	dc.w	%0000000000000000
	dc.w	%0110011011000000
	dc.w	%0000000000000000
	dc.w	%0011110011000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000111111110000
	dc.w	%0000000000000000
	dc.w	%0011110000111100
	dc.w	%0000000000000000
	dc.w	%0011110000111100
	dc.w	%0000000000000000
	dc.w	%0011110000111100
	dc.w	%0000000000000000
	dc.w	%0000111111110000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000

	dc.w	$3C58
	dc.w	$7500
	dc.b	%00000000
lbB0212C9:
	dc.b	%00001100
	dc.w	%0000000000000000
	dc.w	%0001100000011100
	dc.w	%0000000000000000
	dc.w	%0000000000001100
	dc.w	%0000000000000000
	dc.w	%0001100000001100
	dc.w	%0000000000000000
	dc.w	%0000000000111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000011110
	dc.w	%0000000000000000
	dc.w	%0001100000110011
	dc.w	%0000000000000000
	dc.w	%0000000000110011
	dc.w	%0000000000000000
	dc.w	%0001100000110011
	dc.w	%0000000000000000
	dc.w	%0000000000011110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000011110
	dc.w	%0000000000000000
	dc.w	%0001100000110011
	dc.w	%0000000000000000
	dc.w	%0000000000110011
	dc.w	%0000000000000000
	dc.w	%0001100000110011
	dc.w	%0000000000000000
	dc.w	%0000000000011110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000011110
	dc.w	%0000000000000000
	dc.w	%0001100000110011
	dc.w	%0000000000000000
	dc.w	%0000000000110011
	dc.w	%0000000000000000
	dc.w	%0001100000110011
	dc.w	%0000000000000000
	dc.w	%0000000000011110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1111111111111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1100000111110011
	dc.w	%0000000000000000
	dc.w	%0000000110011011
	dc.w	%0000000000000000
	dc.w	%1100000111110001
	dc.w	%0000000000000000
	dc.w	%1100000110011000
	dc.w	%0000000000000000
	dc.w	%1000000111110000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0011000110110011
	dc.w	%0000000000000000
	dc.w	%1011010110111011
	dc.w	%0000000000000000
	dc.w	%1011111110111111
	dc.w	%0000000000000000
	dc.w	%1011101110110111
	dc.w	%0000000000000000
	dc.w	%0011000110110011
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000011111111
	dc.w	%0000000000000000
	dc.w	%0000001111000000
	dc.w	%0000000000000000
	dc.w	%0000001111000000
	dc.w	%0000000000000000
	dc.w	%1111001111000000
	dc.w	%0000000000000000
	dc.w	%1111000011111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000

	dc.w	$3C60
	dc.w	$7500
lbB0213B4:
	dc.b	$3F
lbB0213B5:
	dc.b	$3E
	dc.w	%0000000000000000
	dc.w	%0011000000110011
	dc.w	%0000000000000000
	dc.w	%0011110000110011
	dc.w	%0000000000000000
	dc.w	%0011000000110011
	dc.w	%0000000000000000
	dc.w	%0011000000111110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0001111000011110
	dc.w	%0000000000000000
	dc.w	%0011001100110011
	dc.w	%0000000000000000
	dc.w	%0011001100011110
	dc.w	%0000000000000000
	dc.w	%0011001100110011
	dc.w	%0000000000000000
	dc.w	%0001111000011110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0001111100111110
	dc.w	%0000000000000000
	dc.w	%0011000000000011
	dc.w	%0000000000000000
	dc.w	%0011111000001110
	dc.w	%0000000000000000
	dc.w	%0011001100000011
	dc.w	%0000000000000000
	dc.w	%0001111000111110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0001111000011111
	dc.w	%0000000000000000
	dc.w	%0011001100110000
	dc.w	%0000000000000000
	dc.w	%0001111000111110
	dc.w	%0000000000000000
	dc.w	%0011001100110011
	dc.w	%0000000000000000
	dc.w	%0001111000011110
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1111111111111111
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0011000000000000
	dc.w	%0000000000000000
	dc.w	%0011000000000000
	dc.w	%0000000000000000
	dc.w	%1110000000000000
	dc.w	%0000000000000000
	dc.w	%1100000000000000
	dc.w	%0000000000000000
	dc.w	%1100000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1100000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%1100000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000
	dc.w	%0000000000000000

; Ball transition
;$5DD00
lbW022D00:
	incbin	"data/balls.lo4"

; Ball transition, Blitter masks
;$5EE30
lbW023E30:
	incbin	"data/balls_mask.lo4"

; $70000
background:
	incbin	"data/demons_bg.lo4"

; $79740
scrollfont:
	incbin	"data/scrollfont.lo2"

; Ball to demon morph
lbW040000:
	incbin	"data/demon_bobs.lo4"

; Ball to demon morph, Blitter 
lbW041900:
	incbin	"data/demon_bobs_mask.lo4"

sample1:	incbin	"data/instr1"
sample2:	incbin	"data/instr2"
sample3:	incbin	"data/instr3"
sample4:	incbin	"data/instr4"
sample5:	incbin	"data/instr5"
sample6:	incbin	"data/instr6"
sample7:	incbin	"data/instr7"
sample8:	incbin	"data/instr8"
sample9:	incbin	"data/instr9"
sample10:	incbin	"data/instr10"
sample11:	incbin	"data/instr11"
sample12:	incbin	"data/instr12"
sample13:	incbin	"data/instr13"
sample14:	incbin	"data/instr14"
sample15:	incbin	"data/instr15"

; For safety
	dc.l	0

	section	chipbss,bss_c

; $60000 Main work bitplanes, 220 lines, 4 bitplanes
lbL025000:
	ds.b	44*220*4

; $6A000 Scroll bitplane
; 48 bytes, 20 lines, 2 bitplanes
scr_bitplane:
	ds.b	48*20*2

;44 bytes * 25 lines, 2 bitplanes
;$6A7D0
shadow_bitpl:
	ds.b	65*44

;$6B2FC
shadow_bitpl2:
	ds.b	66*44*2

clear_size	equ	*-scr_bitplane
	end
