;
; CLONETRO
;

; Code and graphics by TMR
; Music by Odie


; A written-from-scratch mashup of various C64 crack intros from
; Jewels, Yeti Factories, Ikari and the Dynamic Duo. Coded for
; C64CrapDebunk.Wordpress.com and the 2016 iteration of Laxity's
; CSDb Intro Competition.

; Notes: this source is formatted for the ACME cross assembler from
; http://sourceforge.net/projects/acme-crossass/
; Compression is handled with Exomizer 2 which can be downloaded at
; http://hem.bredband.net/magli143/exo/

; build.bat will call both to create an assembled file and then the
; crunched release version.


; Memory Map
; $0800 - $0dff		character graphics
; $0e00 - $0fff		sprites
; $1000 - $1bff		music
; $1c00 - $1fff		precalcuated grid data
; $2000 - $23ff		scroll character set
; $2400 - $27ff		screen RAM
; $2800 - $3fff		program code/data


; Select an output filename
		!to "clonetro.prg",cbm


; Pull in the binary data
		* = $0800
		!binary "binary\graphics.chr"

		* = $0e00
		!binary "binary\sprites.spr"

		* = $1000
music		!binary "binary\cosine_intro_v2.prg",,2

		* = $1c00
grid_data	!binary "binary\grids.raw"

		* = $2000
		!binary "binary\plain_font_16x8.chr"

		* = $2400
screen_data	!binary "binary\screen.raw"


; Raster split positions
raster_1_pos	= $00
raster_2_pos	= $49
raster_3_pos	= $89
raster_4_pos	= $9c

; Label assignments
raster_num	= $50

colour_timer	= $51		; two bytes used
colour_read_1	= $52		; two bytes used
colour_read_2	= $54		; two bytes used
logo_wash_count	= $56

scrl_wash_count	= $57
scroll_pos	= $58		; two bytes used
scroll_x	= $5a
scroll_count	= $5b

grid_read_1	= $5c		; two bytes used
grid_read_2	= $5e		; two bytes used
grid_x1		= $60
grid_y1		= $61
grid_x2		= $62
grid_y2		= $63

grid_dir	= $64
grid_timer_x1	= $65
grid_timer_y1	= $66
grid_timer_x2	= $67
grid_timer_y2	= $68

sine_at_1	= $69
sine_at_2	= $6a
sine_at_3	= $6b
sine_speed_1	= $6c
sine_speed_2	= $6d
sine_speed_3	= $6e

anim_timer	= $6f


scroll_line	= $25e0
scroll_col_line	= scroll_line+$b400

grid_work_lf	= $0de0
grid_work_rt	= $0df0


; Entry point for the code
		* = $2800

; Stop interrupts, disable the ROMS and set up NMI and IRQ interrupt pointers
code_start	sei

		lda #$35
		sta $01

		lda #<nmi_int
		sta $fffa
		lda #>nmi_int
		sta $fffb

		lda #<irq_int
		sta $fffe
		lda #>irq_int
		sta $ffff

; Set the VIC-II up for a raster IRQ interrupt
		lda #$7f
		sta $dc0d
		sta $dd0d

		lda $dc0d
		lda $dd0d

		lda #raster_1_pos
		sta $d012

		lda #$1b
		sta $d011
		lda #$01
		sta $d019
		sta $d01a

; Draw the grid area into what will become the screen RAM
		ldx #$00
grid_draw	lda #$bc
		sta screen_data+$259,x
		sta screen_data+$2a9,x
		sta screen_data+$2f9,x
		sta screen_data+$349,x
		sta screen_data+$399,x
		clc
		adc #$01
		sta screen_data+$281,x
		sta screen_data+$2d1,x
		sta screen_data+$321,x
		sta screen_data+$371,x
		inx

		clc
		adc #$01
		sta screen_data+$259,x
		sta screen_data+$2a9,x
		sta screen_data+$2f9,x
		sta screen_data+$349,x
		sta screen_data+$399,x
		clc
		adc #$01
		sta screen_data+$281,x
		sta screen_data+$2d1,x
		sta screen_data+$321,x
		sta screen_data+$371,x
		inx
		cpx #$24
		bne grid_draw

; Set the colour for the screen at $2400
		ldx #$00
colour_set	ldy screen_data+$000,x
		lda colour_decode,y
		sta $d800,x
		ldy screen_data+$100,x
		lda colour_decode,y
		sta $d900,x
		ldy screen_data+$200,x
		lda colour_decode,y
		sta $da00,x
		ldy screen_data+$2e8,x
		lda colour_decode,y
		sta $dae8,x
		inx
		bne colour_set

; Colour in the logo
		ldx #$00
		lda #$08
logo_col_set	sta $d87c,x
		sta $d8a4,x
		sta $d8cc,x
		sta $d8f4,x
		sta $d91c,x
		inx
		cpx #$1e
		bne logo_col_set

; Set up the line for the scroller
		ldx #$00
scroll_col_set	lda #$06
		sta $d9b8,x
		sta $da08,x
		lda #$00
		sta $d9e0,x
		inx
		cpx #$28
		bne scroll_col_set

; Add some colour for the grid
		ldx #$00
		lda #$0b
grid_col_draw	sta $da59,x
		sta $da81,x
		sta $daa9,x
		sta $dad1,x
		sta $daf9,x
		sta $db21,x
		sta $db49,x
		sta $db71,x
		sta $db99,x
		inx
		cpx #$24
		bne grid_col_draw

; Set up the music driver
		ldx #$00
		txa
		tay
		jsr music+$00

; Initialise our own labels
		ldx #$00
		lda #$00
clear_zp	sta raster_num,x
		inx
		cpx #$20
		bne clear_zp

		lda #$01
		sta raster_num

		lda #<split_cols_1
		sta colour_read_1+$00
		lda #>split_cols_1
		sta colour_read_1+$01

		lda #<split_cols_2
		sta colour_read_2+$00
		lda #>split_cols_2
		sta colour_read_2+$01

		lda #$20
		sta logo_wash_count

		lda #$6a
		sta grid_dir

		lda #$00
		sta sine_at_1
		sta sine_at_2
		sta sine_at_3

		lda #$03
		sta sine_speed_1
		lda #$01
		sta sine_speed_2
		lda #$02
		sta sine_speed_3

; Reset the scroller
		jsr scroll_reset
		lda #$e0
		sta scroll_count

; Restart the interrupts
		cli


; Infinite loop to check for space being pressed
space_loop	lda $dc01
		cmp #$ef
		bne space_loop

; Stop the interrupts, switch off the screen and zero the volume
		sei
		lda #$0b
		sta $d011
		lda #$00
		sta $d020
		sta $d418

; Bank in the ROMs and reset the C64
		lda #$37
		sta $01
		jmp $fce2


; IRQ interrupt handler
irq_int		pha
		txa
		pha
		tya
		pha

		lda $d019
		and #$01
		sta $d019
		bne int_go
		jmp irq_exit

; An interrupt has triggered
int_go		lda raster_num
		cmp #$02
		bne *+$05
		jmp irq_rout2

		cmp #$03
		bne *+$05
		jmp irq_rout3

		cmp #$04
		bne *+$05
		jmp irq_rout4


; Raster split 1
irq_rout1	lda #$06
		sta $d020
		lda #$0e
		sta $d021
		lda #$03
		sta $d022
		lda #$0d
		sta $d023

		lda #$17
		sta $d016
		lda #$92
		sta $d018

; Set up the hardware sprites as an underlay for the scroller
		lda #$ff
		sta $d015
		sta $d01b
		sta $d01c
		sta $d01d

		ldx #$00
		lda underlay_x
set_sprite_x1	sta $d000,x
		clc
		adc #$30
		inx
		inx
		cpx #$0e
		bne set_sprite_x1

		lda #$40
		ldy $d00a
		cpy #$80
		bcs *+$04
		lda #$60
		sta $d010

		ldx #$00
		lda #$8c
set_sprite_y1	sta $d001,x
		inx
		inx
		cpx #$0e
		bne set_sprite_y1

		ldx #$00
		lda #$80
set_sprite_dp1	lda underlay_dp
		sta $27f8,x
		lda #$0f
		sta $d027,x
		inx
		cpx #$07
		bne set_sprite_dp1

		lda #$0c
		sta $d025
		lda #$01
		sta $d026

; Update the colour for the C64CD logo
		ldx #$00
logo_wash	lda $d87d,x
		sta $d87c,x
		sta $d8a4,x
		sta $d8cc,x
		sta $d8f4,x
		sta $d91c,x
		inx
		cpx #$1d
		bne logo_wash

		inc logo_wash_count
		ldx logo_wash_count
		cpx #$20
		bcc *+$04
		ldx #$1f

		lda wash_colours,x
		ora #$08
		sta $d899
		sta $d8c1
		sta $d8e9
		sta $d911
		sta $d939

; Move the scroller's colour RAM to the right
		ldx #$26
scroll_col_wash	lda scroll_col_line+$00,x
		sta scroll_col_line+$01,x
		dex
		cpx #$ff
		bne scroll_col_wash

		ldx scrl_wash_count
		inx
		cpx #$59
		bcc *+$04
		ldx #$00
		stx scrl_wash_count

		cpx #$20
		bcc *+$04
		ldx #$00
		lda scroll_wash_col,x
		sta scroll_col_line

; Set interrupt handler for split 2
		lda #$02
		sta raster_num
		lda #raster_2_pos
		sta $d012

; Exit IRQ interrupt
		jmp irq_exit


; Skip to the next page boundary so the timing doesn't get mangled!
		* = ((*/$100)+1)*$100

; Raster split 2
irq_rout2	ldx #$0e
		dex
		bne *-$01

; Colour splitter for the C64CD logo
		ldy #$00
splitter_1	lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny

		lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny
		ldx #$08
		dex
		bne *-$01
		nop

		lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny
		ldx #$08
		dex
		bne *-$01
		nop

		lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny
		ldx #$08
		dex
		bne *-$01
		nop

		lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny
		ldx #$08
		dex
		bne *-$01
		nop

		lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny
		ldx #$08
		dex
		bne *-$01
		nop

		lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny
		ldx #$08
		dex
		bne *-$01
		nop

		lda (colour_read_1),y
		sta $d022
		lda (colour_read_2),y
		sta $d023
		iny
		ldx #$07
		dex
		bne *-$01

		cpy #$28
		beq *+$05
		jmp splitter_1

		lda #$03
		sta $d022
		lda #$0d
		sta $d023


; Update the colour positions
		lda colour_timer
		eor #$01
		and #$01
		sta colour_timer

		beq colour_update_2

colour_update_1	ldx colour_read_1
		inx
		cpx #$40
		bne *+$04
		ldx #$00
		stx colour_read_1
		jmp colour_upd_out

colour_update_2	ldx colour_read_2
		dex
		cpx #$7f
		bne *+$04
		ldx #$8f
		stx colour_read_2

; Update the underlay sprites
colour_upd_out	ldx underlay_x
		dex
		cpx #$ff
		bne ux_xb

		lda underlay_dp
		eor #$01
		sta underlay_dp

		ldx #$17
ux_xb		stx underlay_x

; Set interrupt handler for split 3
		lda #$03
		sta raster_num
		lda #raster_3_pos
		sta $d012

		jmp irq_exit


; Raster split 3
irq_rout3	ldx #$0e
		dex
		bne *-$01

		lda scroll_x
		and #$03
		eor #$03
		asl
		sta $d016

		lda #$98
		sta $d018

		lda #$0b
		sta $d021

; Set interrupt handler for split 4
		lda #$04
		sta raster_num
		lda #raster_4_pos
		sta $d012

		jmp irq_exit


; Raster split 4
irq_rout4	ldx #$03
		dex
		bne *-$01

		lda #$0b
		sta $d022
		lda #$0e
		sta $d023
		lda #$0d
		sta $d021

		lda #$17
		sta $d016
		lda #$92
		sta $d018

; Relocate the sprites for the lower box
		ldx #$00
		ldy #$00
set_sprites	lda sprite_x,x
		clc
		adc #$6c
		sta $d000,y
		lda sprite_y,x
		clc
		adc #$aa
		sta $d001,y
		lda sprite_cols,x
		sta $d027,x
		lda sprite_dps,x
		sta $27f8,x
		iny
		iny
		inx
		cpx #$08
		bne set_sprites

		lda #$09
		sta $d025
		lda #$01
		sta $d026

		lda #$00
		sta $d010
		sta $d01d

; Wait until the upper edge of the frame for a colour change
		lda #$a9
col_wait_1	cmp $d012
		bne *-$05
		lda #$00
		sta $d021

; Move scrolling message
		ldx scroll_x
		inx
		cpx #$04
		bne scr_xb

; Move the text line
		ldx #$00
scroll_mover	lda scroll_line+$01,x
		sta scroll_line+$00,x
		inx
		cpx #$27
		bne scroll_mover

		ldx scroll_count
		inx
		cpx #$02
		bne sc_skip

; Copy a new character to the scroller
		ldy #$00
scroll_mread	lda (scroll_pos),y
		bne scroll_okay
		jsr scroll_reset
		jmp scroll_mread

scroll_okay	asl
		sta scroll_line+$26
		clc
		adc #$01
		sta scroll_line+$27

; Nudge the scroller onto the next character
		inc scroll_pos+$00
		bne *+$04
		inc scroll_pos+$01

		ldx #$00
sc_skip		stx scroll_count

		ldx #$00
scr_xb		stx scroll_x

; Work out the sprite positions for the next frame
		lda sine_at_1
		clc
		adc sine_speed_1
		sta sine_at_1

		lda sine_at_2
		clc
		adc sine_speed_2
		sta sine_at_2

		lda sine_at_3
		clc
		adc sine_speed_3
		sta sine_at_3

		ldx #$00
		ldy sine_at_1
sine_x_gen_1	lda sprite_x_sinus,y
		sta sprite_x,x
		tya
		clc
		adc #$25
		tay
		inx
		cpx #$08
		bne sine_x_gen_1

		ldx #$00
		ldy sine_at_2
sine_x_gen_2	lda sprite_x_sinus,y
		clc
		adc sprite_x,x
		sta sprite_x,x
		tya
		clc
		adc #$1b
		tay
		inx
		cpx #$08
		bne sine_x_gen_2

		ldx #$00
		ldy sine_at_3
sine_y_gen_1	lda sprite_y_sinus,y
		sta sprite_y,x
		tya
		clc
		adc #$1d
		tay
		inx
		cpx #$08
		bne sine_y_gen_1

; Play the music
		jsr music+$03

; Wait until the lower edge of the frame for colour changes
		lda #$f3
		cmp $d012
		bne *-$05
		lda #$0d
		sta $d021

		ldx #$20
		dex
		bne *-$01
		lda #$00
		sta $d021

; Check to see if the grids need to change direction
		ldx #$00
grid_upd_loop	lda grid_timer_x1,x
		clc
		adc #$01
		cmp grid_max_vals,x
		bne gtx1_xb

		lda grid_dir
		eor grid_joy_masks,x
		sta grid_dir

		lda #$00
gtx1_xb		sta grid_timer_x1,x
		inx
		cpx #$04
		bne grid_upd_loop

; Update the grid positions
		lda grid_dir
grid_1_up	lsr
		bcc *+$04
		dec grid_y1
grid_1_down	lsr
		bcc *+$04
		inc grid_y1
grid_1_left	lsr
		bcc *+$04
		dec grid_x1
grid_1_right	lsr
		bcc *+$04
		inc grid_x1

grid_2_up	lsr
		bcc *+$04
		dec grid_y2
grid_2_down	lsr
		bcc *+$04
		inc grid_y2
grid_2_left	lsr
		bcc *+$04
		dec grid_x2
grid_2_right	lsr
		bcc *+$04
		inc grid_x2

; Render the lower grid
		lda grid_x1
		lsr
		and #$07
		sta grid_read_1+$00
		lda #$00
		asl grid_read_1+$00
		rol
		asl grid_read_1+$00
		rol
		asl grid_read_1+$00
		rol
		asl grid_read_1+$00
		rol
		clc
		adc #>grid_data+$00
		sta grid_read_1+$01

		lda grid_y1
		and #$0f
		tax
		ldy #$00
grid_copy_l1	lda (grid_read_1),y
		sta grid_work_lf,x
		inx
		cpx #$10
		bne *+$04
		ldx #$00
		iny
		cpy #$10
		bne grid_copy_l1

		lda grid_y1
		and #$0f
		tax
		ldy #$80
grid_copy_r1	lda (grid_read_1),y
		sta grid_work_rt,x
		inx
		cpx #$10
		bne *+$04
		ldx #$00
		iny
		cpy #$90
		bne grid_copy_r1

; Render the upper grid
		lda grid_x2
		lsr
		and #$07
		sta grid_read_1+$00
		lda #$00
		asl grid_read_1+$00
		rol
		asl grid_read_1+$00
		rol
		asl grid_read_1+$00
		rol
		asl grid_read_1+$00
		rol
		clc
		adc #>(grid_data+$100)
		sta grid_read_1+$01
		clc
		adc #$01
		sta grid_read_2+$01
		lda grid_read_1+$00
		sta grid_read_2+$00

		lda grid_y2
		and #$0f
		tax
		ldy #$00
grid_copy_l2	lda grid_work_lf,x
		and (grid_read_2),y
		ora (grid_read_1),y
		sta grid_work_lf,x
		inx
		cpx #$10
		bne *+$04
		ldx #$00
		iny
		cpy #$10
		bne grid_copy_l2

		lda grid_y2
		and #$0f
		tax
		ldy #$80
grid_copy_r2	lda grid_work_rt,x
		and (grid_read_2),y
		ora (grid_read_1),y
		sta grid_work_rt,x
		inx
		cpx #$10
		bne *+$04
		ldx #$00
		iny
		cpy #$90
		bne grid_copy_r2

; Update the sprite animations if need be
		ldx anim_timer
		inx
		cpx #$03
		bne at_xb

		ldx #$00
anim_update	lda sprite_dps,x
		clc
		adc #$01
		cmp #$3e
		bne *+$04
		lda #$38
		sta sprite_dps,x
		inx
		cpx #$08
		bne anim_update

		ldx #$00
at_xb		stx anim_timer

; Set interrupt handler for split 1
		lda #$01
		sta raster_num
		lda #raster_1_pos
		sta $d012

; Restore registers and exit IRQ interrupt
irq_exit	pla
		tay
		pla
		tax
		pla
nmi_int		rti


; Subroutine to reset the scrolling message
scroll_reset	lda #<scroll_text
		sta scroll_pos+$00
		lda #>scroll_text
		sta scroll_pos+$01
		rts


; Colour data for the screen (each character has a fixed colour)
colour_decode	!byte $0e,$0c,$0e,$0e,$0e,$0e,$0e,$0c
		!byte $0e,$0e,$0e,$0e,$0e,$0e,$0c,$0c
		!byte $0e,$0e,$0e,$0e,$0c,$0e,$0e,$0e
		!byte $0c,$0c,$0c,$0c,$0c,$0e,$0c,$0c
		!byte $0c,$0b,$0c,$01,$0c,$0c,$0c,$0c
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
		!byte $0c,$0b,$0c,$0c,$0c,$0c,$0c,$0c
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c

		!byte $0c,$0c,$0c,$0c,$0c,$0e,$0c,$0c
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
		!byte $0c,$0c,$0c,$0e,$0b,$0b,$0c,$0c
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
		!byte $0c,$0c,$0c,$0c,$0c,$0b,$0c,$0c
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0b
		!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0e

		!byte $0e,$0e,$0c,$0b,$0b,$0b,$0b,$0b
		!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
		!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
		!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b


; Raster colour tables for the C64CD logo
		* = ((*/$100)+1)*$100
split_cols_1	!byte $09,$09,$02,$09,$02,$02,$08,$02
		!byte $08,$08,$0c,$08,$0c,$0c,$0a,$0c
		!byte $0a,$0a,$0f,$0a,$0f,$0f,$07,$0f
		!byte $07,$07,$01,$07,$01,$01,$07,$01
		!byte $07,$07,$0f,$07,$0f,$0f,$0a,$0f
		!byte $0a,$0a,$0c,$0a,$0c,$0c,$08,$0c
		!byte $08,$08,$02,$08,$02,$02,$09,$02
		!byte $09,$09,$09,$09,$09,$09,$09,$09

		!byte $09,$09,$02,$09,$02,$02,$08,$02
		!byte $08,$08,$0c,$08,$0c,$0c,$0a,$0c
		!byte $0a,$0a,$0f,$0a,$0f,$0f,$07,$0f
		!byte $07,$07,$01,$07,$01,$01,$07,$01
		!byte $07,$07,$0f,$07,$0f,$0f,$0a,$0f
		!byte $0a,$0a,$0c,$0a,$0c,$0c,$08,$0c
		!byte $08,$08,$02,$08,$02,$02,$09,$02
		!byte $09,$09,$09,$09,$09,$09,$09,$09

split_cols_2	!byte $06,$0b,$04,$0e,$05,$03,$0d,$01
		!byte $0d,$03,$05,$0e,$04,$0b,$06,$00
		!byte $06,$0b,$04,$0e,$05,$03,$0d,$01
		!byte $0d,$03,$05,$0e,$04,$0b,$06,$00
		!byte $06,$0b,$04,$0e,$05,$03,$0d,$01
		!byte $0d,$03,$05,$0e,$04,$0b,$06,$00
		!byte $06,$0b,$04,$0e,$05,$03,$0d,$01
		!byte $0d,$03,$05,$0e,$04,$0b,$06,$00


; Colour data for the logo wash effect
wash_colours	!byte $01,$01,$07,$01,$07,$07,$03,$07
		!byte $03,$03,$05,$03,$05,$05,$04,$05
		!byte $04,$04,$02,$04,$02,$02,$06,$02
		!byte $06,$06,$00,$06,$00,$00,$00,$00

; Colour data for the scroll wash effect
scroll_wash_col	!byte $00,$00,$09,$09,$02,$02,$08,$08
		!byte $0a,$0a,$0f,$0f,$07,$07,$01,$01
		!byte $07,$07,$0f,$0f,$0a,$0a,$08,$08
		!byte $02,$02,$09,$09,$00,$00,$00,$00


; Movement control data for the grids
grid_max_vals	!byte $c2,$97,$b0,$d1
grid_joy_masks	!byte $03,$0c,$30,$c0


; Sprite position and colour data for the scroll underlay
underlay_x	!byte $00
underlay_dp	!byte $3e

; Sprite position and colour data for the sinus sprites
sprite_x	!byte $00,$00,$00,$00,$00,$00,$00,$00
sprite_y	!byte $34,$20,$20,$20,$20,$20,$20,$20
sprite_cols	!byte $0a,$08,$05,$04,$0a,$08,$05,$04
sprite_dps	!byte $3d,$3c,$3b,$3a,$39,$38,$3d,$3c


; Sine table for the sprite X movement
sprite_x_sinus	!byte $20,$20,$21,$22,$23,$24,$24,$25
		!byte $26,$27,$27,$28,$29,$2a,$2a,$2b
		!byte $2c,$2d,$2d,$2e,$2f,$2f,$30,$31
		!byte $31,$32,$33,$33,$34,$35,$35,$36
		!byte $36,$37,$37,$38,$38,$39,$39,$3a
		!byte $3a,$3b,$3b,$3b,$3c,$3c,$3d,$3d
		!byte $3d,$3d,$3e,$3e,$3e,$3e,$3f,$3f
		!byte $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f

		!byte $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
		!byte $3f,$3f,$3f,$3e,$3e,$3e,$3e,$3d
		!byte $3d,$3d,$3c,$3c,$3c,$3b,$3b,$3b
		!byte $3a,$3a,$39,$39,$38,$38,$37,$37
		!byte $36,$36,$35,$34,$34,$33,$33,$32
		!byte $31,$31,$30,$2f,$2f,$2e,$2d,$2c
		!byte $2c,$2b,$2a,$29,$29,$28,$27,$26
		!byte $26,$25,$24,$23,$23,$22,$21,$20

		!byte $1f,$1f,$1e,$1d,$1c,$1c,$1b,$1a
		!byte $19,$18,$18,$17,$16,$15,$15,$14
		!byte $13,$12,$12,$11,$10,$10,$0f,$0e
		!byte $0e,$0d,$0c,$0c,$0b,$0b,$0a,$09
		!byte $09,$08,$08,$07,$07,$06,$06,$05
		!byte $05,$04,$04,$04,$03,$03,$03,$02
		!byte $02,$02,$01,$01,$01,$01,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$01,$01,$01,$01,$02
		!byte $02,$02,$03,$03,$03,$04,$04,$05
		!byte $05,$05,$06,$06,$07,$07,$08,$08
		!byte $09,$0a,$0a,$0b,$0b,$0c,$0d,$0d
		!byte $0e,$0f,$0f,$10,$11,$11,$12,$13
		!byte $13,$14,$15,$16,$16,$17,$18,$19
		!byte $19,$1a,$1b,$1c,$1d,$1d,$1e,$1f

; Sine table for the sprite Y movement
sprite_y_sinus	!byte $34,$34,$34,$34,$34,$34,$34,$34
		!byte $34,$34,$34,$34,$33,$33,$33,$33
		!byte $32,$32,$32,$32,$31,$31,$31,$30
		!byte $30,$30,$2f,$2f,$2e,$2e,$2e,$2d
		!byte $2d,$2c,$2c,$2b,$2b,$2a,$2a,$29
		!byte $29,$28,$28,$27,$26,$26,$25,$25
		!byte $24,$24,$23,$22,$22,$21,$20,$20
		!byte $1f,$1e,$1e,$1d,$1d,$1c,$1b,$1b

		!byte $1a,$19,$19,$18,$17,$17,$16,$15
		!byte $15,$14,$14,$13,$12,$12,$11,$10
		!byte $10,$0f,$0f,$0e,$0d,$0d,$0c,$0c
		!byte $0b,$0b,$0a,$0a,$09,$09,$08,$08
		!byte $07,$07,$06,$06,$05,$05,$05,$04
		!byte $04,$04,$03,$03,$03,$02,$02,$02
		!byte $01,$01,$01,$01,$01,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$01,$01,$01,$01
		!byte $02,$02,$02,$02,$03,$03,$03,$04
		!byte $04,$04,$05,$05,$06,$06,$06,$07
		!byte $07,$08,$08,$09,$09,$0a,$0a,$0b
		!byte $0b,$0c,$0c,$0d,$0e,$0e,$0f,$0f
		!byte $10,$11,$11,$12,$12,$13,$14,$14
		!byte $15,$16,$16,$17,$18,$18,$19,$19

		!byte $1a,$1b,$1b,$1c,$1d,$1d,$1e,$1f
		!byte $1f,$20,$21,$21,$22,$22,$23,$24
		!byte $24,$25,$25,$26,$27,$27,$28,$28
		!byte $29,$29,$2a,$2a,$2b,$2b,$2c,$2c
		!byte $2d,$2d,$2e,$2e,$2f,$2f,$2f,$30
		!byte $30,$30,$31,$31,$31,$32,$32,$32
		!byte $33,$33,$33,$33,$33,$34,$34,$34
		!byte $34,$34,$34,$34,$34,$34,$34,$34


; Text for the scrolling message
scroll_text	!scr "welcome to a new intro that, in the ",$22,"grand",$22,$20
		!scr "c64cd naming tradition, has been titled..."
		!scr "      "
		!scr "--- clonetro ---"
		!scr "      "

		!scr "coding and graphics are as usual by t.m.r, this time "
		!scr "accompanied on the sid chip by odie and inspired by a "
		!scr "range of crack intros from jewels, yeti factories, "
		!scr "ikari and the dynamic duo."
		!scr "      "

		!scr "this is my first entry into the 2016 iteration of "
		!scr "didi's intro competition; my mind is blank as regards "
		!scr "ideas for intros right now (some would say it's always "
		!scr "like that) but i'd like to put at least one more "
		!scr "together before the deadline..."
		!scr "      "

		!scr "the blog post about this at the c64cd website - "
		!scr "http://c64crapdebunk.wordpress.com/ - has some notes "
		!scr "about where inspiration for the various elements on "
		!scr "screen came from and some linkage to the source code "
		!scr "over at github."
		!scr "      "

		!scr "so...  that's the website plugged, a nod to the people "
		!scr "who influenced the design of this thing and there's only "
		!scr "the hellos to get out of the way before i can wrap this "
		!scr "up and see about getting it ready for release!  "
		!scr "alpha-sorted greetings radiate out from c64cd towards:  "

		!scr "1001 crew - "
		!scr "ash and dave - "
		!scr "black bag - "
		!scr "borderzone dezign team - "
		!scr "dynamic duo - "
		!scr "four horsemen of the apocalypse - "
		!scr "happy demomaker - "
		!scr "harlow cracking service - "
		!scr "ikari - "
		!scr "jewels - "
		!scr "laxity - "
		!scr "mean team - "
		!scr "paul, shandor and matt - "
		!scr "pulse productions - "
		!scr "reset 86 - "
		!scr "rob hubbard - "
		!scr "scoop - "
		!scr "slipstream - "
		!scr "stoat and tim - "
		!scr "tangent - "
		!scr "thalamus - "
		!scr "the commandos - "
		!scr "the gps - "
		!scr "the six pack - "
		!scr "we music - "
		!scr "xess - "
		!scr "yak - "
		!scr "yeti factories...  "
		!scr "and the now traditional anti-greeting to c64hater!"
		!scr "      "

		!scr "and we're done...  so this has been t.m.r "
		!scr "broadcasting live for c64cd on the 22nd of november "
		!scr "2016.... ... .. .  .   ."
		!scr "            "

		!byte $00		; end of text marker
