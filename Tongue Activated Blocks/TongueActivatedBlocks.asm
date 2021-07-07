;##############################;
;# Tongue Activated Blocks    #;
;# By MarkAlarm               #;
;# Please give credit if used #;
;##############################;

;###########;
;# Options #;
;###########;

!advancedBlockInteraction = !false			; default is false
; if false, the simple interaction just activates blocks as if as shell was thrown at them. on/offs, turn blocks, question mark blocks, etc
; if true, you can write custom interaction routines for any map16 tile. would only recommend if you know what you're doing

; note that this will not work with layer 2 blocks. compatibility with this may be added in the future
; none of the options beyond here should be edited (except the custom block routines, but only if you know what you're doing

!false = 0
!true = 1

tongueBlockOffsets:							; \ offsets for the tongue to properly interact with blocks
	dw $001E,$FFF2							; / right, left
	
if !advancedBlockInteraction
	incsrc "TABCustomBlockRoutineTable.asm"
endif

;########;
;# Code #;
;########;

main:
	LDX #!sprite_slots-1					; \ loop to find which slot yoshi is in
	-										; |
	LDA !sprite_num,x						; |
	CMP #$35								; |
	BEQ +									; |
	DEX										; |
	BPL -									; |
	RTL										; /
	
	+
	LDA !1594,x
	DEC
	BEQ +
	DEC
	BEQ +
	RTL
	
	+
	PHB : PHK : PLB							; bank wrapper for tables
	
	LDY !157C,x								; \ check direction
	CPY #$01								; |
	BNE +									; / add if facing right
	
	LDA !sprite_x_low,x						; \ subtract yoshi x position with tongue distance
	SEC : SBC !151C,x						; |
	STA $00									; | store it to scratch for later
	LDA !sprite_x_high,x					; |
	SBC #$00								; |
	STA $01									; /
	BRA ++	
	
	+
	LDA !sprite_x_low,x						; \ add yoshi x position with tongue distance
	CLC : ADC !151C,x						; |
	STA $00									; | store it to scratch for later
	LDA !sprite_x_high,x					; |
	ADC #$00								; |
	STA $01									; /
	
	++
	LDA !157C,x								; \ use direction as index
	ASL										; |
	TAY										; /
	
	LDA $00									; \ get an x offset based on direction in order to properly calculate the tile we're on
	CLC : ADC tongueBlockOffsets,y			; |
	STA $9A									; |
	INY										; |
	LDA $01									; |
	ADC tongueBlockOffsets,y				; |
	STA $9B									; /
	
	STZ $00
	LDA $77									; \ check if on ground
	AND #$04								; |
	BEQ +									; | if not, skip ahead
	LDA $15									; | check if holding up
	AND #$08								; |
	BNE +									; / if not, skip ahead
	
	LDA #$10								; \ set a vertical offset since yoshi's tongue is low to the ground
	STA $00									; /
	
	+
	LDA !sprite_y_low,x						; \ set the vertical offset
	CLC : ADC $00							; |
	STA $98									; |
	LDA !sprite_y_high,x					; |
	ADC #$00								; |
	STA $99									; /

	STZ $1933|!addr							; only work with layer 1
	
	REP #$20
	JSL GetMap16
	STA $00									; store tile for later
	
	if !advancedBlockInteraction
		PHX
		BMI +								; if an invalid tile, finish up
		ASL
		REP #$10
		TAX
		JSR (tongueBlockRoutines,x)
		SEP #$10
		PLX
		+
	else
		BMI +								; if an invalid tile, finish up
		SEC : SBC #$0111					; \ check if in range of interactable tiles
		CMP #$001D							; |
		BCC +								; | if so, continue
		LDA $00								; |
		SEC : SBC #$016A					; | check for the switch palace blocks
		CMP #$0002							; |
		BCS ++								; / if not those, skip ahead
		
		+
		SEP #$20

		LDY #$00							; \ interact with the block
		LDA $00								; |
		JSL $00F160							; /
		
		LDA !1594,x
		DEC
		BNE ++
		LDA #$08							; \ set tongue timer
		STA !1558,x							; /
		INC !1594,x							; set tongue subroutine
		
		++
	endif

	SEP #$20
	PLB
	RTL
	
;#################################;
;# Custom Tongued Block Routines #;
;#################################;

if !advancedBlockInteraction
	incsrc "TABCustomBlockRoutines.asm"
endif
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetBlock - SA-1 Hybrid version (ripped from pixi)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this routine will get Map16 value
; If position is invalid range, will return 0xFFFF.
;
; input:
; $98-$99 block position Y
; $9A-$9B block position X
; $1933   layer
;
; output:
; A Map16 lowbyte (or all 16bits in 16bit mode)
; Y Map16 highbyte
;
; by Akaginite
;
; It used to return FF but it also fucked with N and Z lol, that's fixed now
; Slightly modified by Tattletale
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro assert_lm_version(version, define)
	!lm_version #= ((read1($0FF0B4)-'0')*100)+((read1($0FF0B6)-'0')*10)+(read1($0FF0B7)-'0')
	if !lm_version >= <version>
		!<define> = 1
	else
		!<define> = 0
	endif
endmacro

%assert_lm_version(257, "EXLEVEL")

GetMap16:
	PHX
	PHP
	REP #$10
	PHB
	LDY $98
	STY $0E
	LDY $9A
	STY $0C
	SEP #$30
	LDA $5B
	LDX $1933|!addr
	BEQ .layer1
	LSR A
.layer1
	STA $0A
	LSR A
	BCC .horz
	LDA $9B
	LDY $99
	STY $9B
	STA $99
.horz
if !EXLEVEL
	BCS .verticalCheck
	REP #$20
	LDA $98
	CMP $13D7|!addr
	SEP #$20
	BRA .check
endif
.verticalCheck
	LDA $99
	CMP #$02
.check
	BCC .noEnd
	PLB
	PLP
	PLX
	LDA #$FFFF
	RTL
	
.noEnd
	LDA $9B
	STA $0B
	ASL A
	ADC $0B
	TAY
	REP #$20
	LDA $98
	AND.w #$FFF0
	STA $08
	AND.w #$00F0
	ASL #2			; 0000 00YY YY00 0000
	XBA			; YY00 0000 0000 00YY
	STA $06
	TXA
	SEP #$20
	ASL A
	TAX
	
	LDA $0D
	LSR A
	LDA $0F
	AND #$01		; 0000 000y
	ROL A			; 0000 00yx
	ASL #2			; 0000 yx00
	ORA #$20		; 0010 yx00
	CPX #$00
	BEQ .noAdd
	ORA #$10		; 001l yx00
.noAdd
	TSB $06			; $06 : 001l yxYY
	LDA $9A			; X LowByte
	AND #$F0		; XXXX 0000
	LSR #3			; 000X XXX0
	TSB $07			; $07 : YY0X XXX0
	LSR A
	TSB $08

	LDA $1925|!addr
	ASL A
	REP #$31
	ADC $00BEA8|!bank,x
	TAX
	TYA
if !sa1
    ADC.l $00,x
    TAX
    LDA $08
    ADC.l $00,x
else
    ADC $00,x
    TAX
    LDA $08
    ADC $00,x
endif
	TAX
	SEP #$20
if !sa1
	LDA $410000,x
	XBA
	LDA $400000,x
else
	LDA $7F0000,x
	XBA
	LDA $7E0000,x
endif
	SEP #$30
	XBA
	TAY
	XBA

	PLB
	PLP
	PLX
	RTL