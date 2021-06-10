;#####################################################;
;# Scale Platform Disassembly                        #;
;# By MiniMawile303                                  #;
;# This version behaves just like the original did   #;
;# Check the other version for customization options #;
;#####################################################;

;#####################;
;# Defines and Stuff #;
;#####################;

	platformWidth:					; width between scale platforms (X&1)
		db $80,$40					; long, short (vanilla widths)
	
	!tile = $80						; tile number to use when drawing the platform

;##########################;
;# Init and Main Wrappers #;
;##########################;

print "INIT ",pc
	PHB : PHK : PLB					; this isn't included in the original code, but is necessary to correctly load widths without bank stuff going wrong

	LDA !sprite_y_low,x				; \ save second platform y position for later
	STA !1534,x						; |
	LDA !sprite_y_high,x			; |
	STA !151C,x						; /
	
	LDA !sprite_x_low,x				; \ get initial x position tile
	AND #$10						; |
	LSR #4							; |
	TAY								; |
	LDA !sprite_x_low,x				; |
	CLC								; |
	ADC platformWidth,y				; | use it to get the other platform position
	STA !C2,x						; /
	
	LDA !sprite_x_high,x			; \ save second platform x position for later
	ADC #$00						; |
	STA !1602,x						; /

	PLB								; part of the wrapper, not in original code either
	
	RTL

print "MAIN ",pc
	LDA !15EA,x						; \ preserve OAM index
	PHA								; /
	
	PHB : PHK : PLB					; \ main wrapper
	JSR SpriteCode					; |
	PLB								; /
	
	PLA								; \ restore OAM index
	STA !15EA,x						; /
	
	RTL

;################;
;# Main Routine #;
;################;

SpriteCode:
	LDA #$05						; \ using #$05 since it acts closest to the original's weird offscreen routine
	%SubOffScreen()					; /
	
	STZ $185E|!addr					; cleared out so it can be checked later for platform position updating
	
	LDA !sprite_x_low,x				; \ preserve first platform's x and y location
	PHA								; |
	LDA !sprite_x_high,x			; |
	PHA								; |
	LDA !sprite_y_low,x				; |
	PHA								; |
	LDA !sprite_y_high,x			; |
	PHA								; /
	
	LDA !151C,x						; \ get the second platform's x and y location
	STA !sprite_y_high,x			; |
	LDA !1534,x						; |
	STA !sprite_y_low,x				; |
	LDA !C2,x						; |
	STA !sprite_x_low,x				; |
	LDA !1602,x						; |
	STA !sprite_x_high,x			; /
	
	LDY #$02						; \ run code for second platform
	JSR PlatformCode				; /
	
	PLA								; \ restore first platform's x and y location
	STA !sprite_y_high,x			; |
	PLA								; |
	STA !sprite_y_low,x				; |
	PLA								; |
	STA !sprite_x_high,x			; |
	PLA								; |
	STA !sprite_x_low,x				; /
	
	BCC +							; carry would be set from solid block routine. if clear, not on platform
	
	INC $185E|!addr					; \ 
	LDA #$F8						; | set speed for rising platform (when on platform)
	JSR SetPosition					; / 
	
	+
	LDA !15EA,x						; \ offset OAM index so the other platform can be drawn later on
	CLC								; |
	ADC #$08						; |
	STA !15EA,x						; /
	
	LDY #$00						; \ run code for first platform
	JSR PlatformCode				; /
	
	BCC +							; if clear, not on platform
	
	INC $185E|!addr					; \ 
	LDA #$08						; | set speed for descending platform (when on platform)
	JSR SetPosition					; /
	
	+
	LDA $185E|!addr					; \ basically if we were on either platform, return. otherwise, the platforms need to return to their original position
	BNE Return						; /
	
	LDY #$02						; \ set speed for descending platform (when it's returning)
	LDA !sprite_y_low,x				; |
	CMP !1534,x						; | if platforms are at same y position,
	BEQ Return						; / don't continue
	
	LDA !sprite_y_high,x			; \
	SBC !151C,x						; |
	BMI +							; |
	LDY #$FE						; / set speed for rising platform (when it's returning)

	+
	TYA								; since SetPosition uses A for the speed, we need to put Y in there first since A was messed with earlier.
	JSR SetPosition					; set platform position

Return:
	RTS
	
mushroomScaleTiles:					; tiles to generate using $00BEB0
	db $02,$07,$07,$02

PlatformCode:						; this routine generates the stem, draws the GFX, and makes the platform solid
	LDA !sprite_y_low,x				; \ if platform is not on an exact tile position,
	AND #$0F						; |
	BNE .noBlockGen					; | don't generate
	LDA !sprite_speed_y,x			; | or if it's stationary,
	BEQ .noBlockGen					; / don't generate
	
	LDA !sprite_speed_y,x			; \ descending platform will place air instead of a stem
	BPL +							; |
	INY								; /
	
	+
	LDA mushroomScaleTiles,y		; \ pick tile to write using SMW's built in routine
	STA $9C							; /
	
	LDA !sprite_x_low,x				; \ take platform position, generate tile where it is
	STA $9A							; |
	LDA !sprite_x_high,x			; |
	STA $9B							; |
	LDA !sprite_y_low,x				; |
	STA $98							; |
	LDA !sprite_y_high,x			; |
	STA $99							; /
	
	JSL $00BEB0						; change tile routine
	
.noBlockGen
	JSR Graphics					; draw the mushroom platform
	STZ !1528,x						; never used anywhere else in this sprite, used in the solid block routine?
	JSL $01B44F						; solid block routine
	
	RTS
	
SetPosition:
	LDY $9D							; \ if sprites locked,
	BNE .locked						; / don't move
	
	PHA
	JSL $01801A						; update y position without gravity
	PLA
	STA !sprite_speed_y,x			; update sprite speed
	
	LDY #$00						; \
	LDA $1491|!addr					; | get the number of pixels moved
	EOR #$FF						; | but inversed so that the other platform moves in the opposite direction
	INC								; |
	BPL +							; |
	DEY								; /
	
	+
	CLC								; \ update other platform's position
	ADC !1534,x						; |
	STA !1534,x						; |
	TYA								; |
	ADC !151C,x						; |
	STA !151C,x						; /
	
.locked
	RTS
	
Graphics:							; pretty generic graphics routine, draws each platform individually. no sense in commenting it
	%GetDrawInfo()
	
	LDA $00
	SEC
	SBC #$08
	STA $0300|!addr,y
	CLC
	ADC #$10
	STA $0304|!addr,y
	
	LDA $01
	DEC
	STA $0301|!addr,y
	STA $0305|!addr,y
	
	LDA #!tile
	STA $0302|!addr,y
	STA $0306|!addr,y
	
	LDA !15F6,x
	ORA $64
	STA $0303|!addr,y
	ORA #$40
	STA $0307|!addr,y
	
	LDA #$01
	LDY #$02
	JSL $01B7B3
	
	RTS
