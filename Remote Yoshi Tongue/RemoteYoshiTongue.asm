;#######################################;
;# Remote Yoshi Tongue                 #;
;# By MarkAlarm                        #;
;# Credit unnecessary, but appreciated #;
;#######################################;

;###########;
;# Options #;
;###########;

!buttonRAM = $18							; use $16 for byetudlr, $18 for axlr----
!buttons = %00110000						; 1 means that the associated button activates the tongue

; if multiple are selected, either of them work to activate it

; these tables all use vanilla values, so they shouldn't *need* to be changed but they can be

FireballXSpeeds:							; \ x speeds of the fireballs that are spit out
	db $28,$24,$24							; / middle, top, bottom

FireballYSpeeds:							; \ y speeds of the fireballs that are spit out
	db $00,$F8,$08							; / middle, top, bottom

SpitXSpeeds:								; \ x speeds for sprites that are spit out
	db $30,$D0,$10,$F0						; / first two are fast, second two are slow

SpitXOffsetsLow:							; \ position offsets for the sprite that's spit out
	db $10,$F0								; |
SpitXOffsetsHigh:							; |
	db $00,$FF								; /
	
SpriteToSpawn:
	db $00,$01,$02,$03,$04,$05,$06,$07		; \ sprites to spawn when spitting out sprites $00-$12
	db $04,$04,$05,$05,$07,$00,$00,$0F		; |
	db $0F,$0F,$0D							; /
	
;########;
;# Code #;
;########;

; a lot of the code is pulled from the yoshi disassembly, hence lack of optimization

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
	PHB	: PHK : PLB							; bank wrapper for tables
	
	LDA !buttonRAM							; \ check if the desired buttons are pressed
	AND #!buttons							; |
	BEQ +									; / if not, return
	
	LDA !1594,x								; \ check if yoshi's tongue is idle
	BNE +									; / if not, return
	
	LDA !160E,x								; \ check the sprite in mouth index
	INC										; |
	BNE .goingOut							; / if not $FF, there's a sprite that needs to be spit out
	
	LDA #$01								; \ set tongue subroutine
	STA !1594,x								; /
	LDA #$21								; \ play sound effect
	STA $1DFC|!addr							; /
	STZ !151C,x								; clear tongue timer
	LDA #$FF								; \ set sprite in mouth index to have nothing
	STA !160E,x								; /
	STZ !1564,x
	
	+
	PLB
	RTL
	
.goingOut
	STZ $18AC|!addr							; clear swallow timer
	LDY !160E,x								; load sprite in mouth index
	PHY
	PHY
	
	LDY !157C,x								; \ set the spit sprite's x position
	LDA !sprite_x_low,x						; |
	CLC										; |
	ADC SpitXOffsetsLow,y					; | with some offset based on yoshi's horizontal direction
	PLY										; |
	STA !sprite_x_low,y						; |
	LDY !157C,x								; |
	LDA !sprite_x_high,x					; |
	ADC SpitXOffsetsHigh,y					; |
	PLY										; |
	STA !sprite_x_high,y					; /
	
	LDA !sprite_y_low,x						; \ set the spit sprite's y position
	STA !sprite_y_low,y						; |
	LDA !sprite_y_high,x					; |
	STA !sprite_y_high,y					; /
	
	PHX
	TYX
	LDA #$00								; \ clear some stuff
	STA !C2,x								; |
	STA !sprite_being_eaten,x				; |
	STA !1626,x								; /
	PLX
	
	LDA $18DC|!addr							; \ load ducking on yoshi flag
	CMP #$01								; |
	LDA #$0A								; | set to be kicked if not ducking
	BCC +									; |
	LDA #$09								; | otherwise, set to be carriable/stunned
	+										; |
	STA !sprite_status,y					; / set the spit sprite's status
	
	PHX
	LDA !157C,x								; \ set spit sprite's horizontal direction
	STA !157C,y								; /
	TAX										; \ if not ducking, use the fast spit speeds
	BCC +									; |
	INX #2									; | use slow spit speeds
	+										; |
	LDA SpitXSpeeds,x						; | set the spit sprite's x speeds
	TYX										; |
	STA !sprite_speed_x,x					; |
	LDA #$00								; | and the y speeds
	STA !sprite_speed_y,x					; |
	PLX										; /
	
	LDA #$10								; \ set tongue timer
	STA !1558,x								; /
	LDA #$03								; \ set tongue subroutine
	STA !1594,x								; /
	LDA #$FF								; \ set sprite in mouth index to have nothing
	STA !160E,x								; /
	LDA !sprite_num,y						; \ load sprite in mouth number
	CMP #$0D								; | check if greater than or equal to #$0D
	BCS DontShootFireballs					; / if so, skip ahead
	
	LDA !187B,y								; \ check disco shell flag
	BNE PrepareFireballs					; / if set, shoot fireballs
	LDA !sprite_oam_properties,y			; \ check to see if the sprite in mouth is a red shell
	AND #$0E								; |
	CMP #$08								; |
	BEQ PrepareFireballs					; / if so, shoot fireballs
	LDA !sprite_oam_properties,x			; \ check to see if yoshi is red
	AND #$0E								; |
	CMP #$08								; |
	BNE DontShootFireballs					; / if not, don't shoot fireballs

PrepareFireballs:
	PHX
	TYX
	STZ !sprite_status,x					; kill sprite in mouth
	LDA #$02								; \ set fireball speeds index
	STA $00									; /
	JSR ShootFireball						; shoot fireball
	JSR ShootFireball						; shoot another fireball
	JSR ShootFireball						; shoot another fireball again
	PLX
	LDA #$17								; \ play sound effect
	STA $1DFC|!addr							; /
	
	PLB
	RTL

ShootFireball:
	JSR FindExtendedSpriteSlot				; find free extended sprite slot for the yoshi fireball
	
	LDA #$11								; \ set extended number to yoshi fireball
	STA $170B|!addr,y						; /
	STA $170B|!addr,y						; /
	LDA !sprite_x_low,x						; \ set fireball position to be where yoshi is
	STA $171F|!addr,y						; |
	LDA !sprite_x_high,x					; |
	STA $1733|!addr,y						; |
	LDA !sprite_y_low,x						; |
	STA $1715|!addr,y						; |
	LDA !sprite_y_high,x					; |
	STA $1729|!addr,y						; /
	LDA #$00								; \ set fireballs to be in front of layers
	STA $1779|!addr,y						; /
	PHX
	LDA !157C,x								; load horizontal direction
	LSR
	LDX $00									; load fireball speeds index
	LDA FireballXSpeeds,x					; \ load fireball x speeds
	BCC +									; /
	EOR #$FF								; \ flip value
	INC										; /

	+
	STA $1747|!addr,y						; set fireball x speed
	LDA FireballYSpeeds,x					; \ set fireball y speed
	STA $173D|!addr,y						; /
	LDA #$A0								; \ set extended timer
	STA $176F|!addr,y						; /
	PLX
	DEC $00									; decrement fireball speeds index
	RTS

DontShootFireballs:
	LDA #$20								; \ play sound effect
	STA $1DF9|!addr							; /
	LDA !sprite_tweaker_1686,y				; \ check "spawns a new sprite" bit
	AND #$40								; |
	BEQ +									; / if clear, return
	PHX
	LDX !sprite_num,y						; \ spawn a sprite (typically powerups)
	LDA SpriteToSpawn,x						; |
	PLX										; |
	STA !sprite_num,y						; /
	PHX
	TYX
	JSL $07F7A0								; initialize the six tweaker bytes
	PLX

	+
	PLB
	RTL
	
FindExtendedSpriteSlot:
	LDY #$07

	-
	LDA $170B|!addr,y
	BEQ .found
	DEY
	BPL -

	DEC $18FC|!addr
	BPL +
	LDA #$07
	STA $18FC|!addr
	
	+
	LDY $18FC|!addr
	
.return
	RTS

.found
	LDA !sprite_off_screen_horz,x
	BNE .return
	RTS
