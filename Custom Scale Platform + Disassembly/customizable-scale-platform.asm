;########################################################;
;# Customizable Scale Platform                          #;
;# By MiniMawile303                                     #;
;# This version has some code changes from the original #;
;# Check the other version for the original code        #;
;########################################################;

;#######################################################################################;
;# Extra Byte/Bit Information                                                          #;
;#                                                                                     #;
;# Extra Bit                - Unused (may add additional features in a future update)  #;
;#                                                                                     #;
;# Extra Byte 1             - Width, how far apart the two platforms will be           #;
;#                            $40: vanilla's short width                               #;
;#                            $80: vanilla's long width                                #;
;#                                                                                     #;
;# Extra Byte 2             - Speed, how quickly the platform falls when on it         #;
;#                            $08: vanilla's on platform speed                         #;
;#                            Using negative speed will make the platform rise instead #;
;#                                                                                     #;
;# Extra Byte 3             - Return speed, how quickly the platform returns           #;
;#                            $02: vanilla's platform return speed                     #;
;#                            Keep this speed positive, regardless of the other value  #;
;#                                                                                     #;
;#######################################################################################;

;#####################;
;# Defines and Stuff #;
;#####################;

	!air = $0025					; map16 tile used when the platform erases (typically air)
	!stem = $00A2					; map16 tile used when the platform places (typically stem)
	
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
	CLC								; |
	ADC !extra_byte_1,x				; | use first extra byte to get the other platform position
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
	LDA !extra_byte_2,x				; | set speed for rising platform (when on platform)
	EOR #$FF						; | inverse the speed
	INC								; |
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
	LDA !extra_byte_2,x				; | set speed for descending platform (when on platform)
	JSR SetPosition					; /
	
	+
	LDA $185E|!addr					; \ basically if we were on either platform, return. otherwise, the platforms need to return to their original position
	BNE Return						; /
	
	LDA !extra_byte_3,x				; \ set speed for descending platform (when it's returning)
	AND #$7F						; | negative return speeds makes this super weird, so let's not even deal with it
	TAY								; |
	LDA !sprite_y_low,x				; |
	CMP !1534,x						; | if platforms are at same y position,
	BEQ Return						; / don't continue
	
	LDA !sprite_y_high,x			; \ 
	SBC !151C,x						; |
	BMI +							; |
	TYA								; |
	EOR #$FF						; | inverse the speed
	INC								; |
	TAY								; / set speed for rising platform (when it's returning)

	+
	TYA								; since SetPosition uses A for the speed, we need to put Y in there first since A was messed with earlier.
	JSR SetPosition					; set platform position

Return:
	RTS
	
mushroomScaleTiles:					; tiles to generate
	dw !air,!stem,!stem,!air
	
generateYOffsets:					; y offsets for the tile generation to make it look correct
	db $00,$10,$10,$00

PlatformCode:						; this routine generates the stem, draws the GFX, and makes the platform solid
	LDA !sprite_speed_y,x			; \ if platform is stationary,
	BEQ .noBlockGen					; / don't generate
	
	LDA !sprite_speed_y,x			; \ descending platform will place air instead of a stem
	BPL +							; |
	INY								; /
	
	+
	LDA !sprite_x_low,x				; \ take platform position, generate tile where it is
	STA $9A							; |
	LDA !sprite_x_high,x			; |
	STA $9B							; |
	LDA !sprite_y_low,x				; |
	CLC : ADC generateYOffsets,y	; | but offset it a bit so it looks correct when generated
	STA $98							; |
	LDA !sprite_y_high,x			; |
	ADC #$00						; |
	STA $99							; /
	
	TYA								; \ double the index so it's used for map16 tiles, not the $00BEB0 format
	ASL								; |
	TAY								; /
	
	REP #$20						; \ change tile routine
	LDA mushroomScaleTiles,y		; |
	%ChangeMap16()					; |
	SEP #$20						; /
	
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
