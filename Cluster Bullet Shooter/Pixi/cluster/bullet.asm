;############################################;
;# Cluster Bullet v1.11                     #;
;# By MarkAlarm                             #;
;# Credit if used, do not claim as your own #;
;############################################;

;#####################;
;# Defines and Stuff #;
;#####################;

	!cluster_tile = $C2				; 16x16 tile to use
	!palette = $08					; respective palette number. please keep this between $08 and $0F
	!page = $01						; $00 for SP1/SP2, $01 for SP3/SP4
	
	; do not edit anything past this point, unless you know what you're doing
	!cluster_props = $30|(!palette-$08)<<1|!page
	
	!cluster_type         = $0F4A|!addr
	!cluster_setting_1    = $0F72|!addr
	!cluster_setting_2    = $0F86|!addr
	
	!cluster_speed_y      = $1E52|!addr
	!cluster_speed_x      = $1E66|!addr
	!cluster_speed_y_frac = $1E7A|!addr
	!cluster_speed_x_frac = $1E8E|!addr
	
	!cluster_expire_timer = $0F5E|!addr
	!cluster_misc_table   = $0F9A|!addr
	
;################################;
;# Bullet Modification Pointers #;
;################################;

bulletModificationPointers:
	dw StandardBullet				; $00
	dw CircularBullet				; $01
	dw BackForthBullet				; $02
	dw SpeedUpBullet				; $03
	dw SineWaveBullet				; $04
	dw CosineWaveBullet				; $05
	dw TargetBullet					; $06
	dw ReAimBullet					; $07

;################;
;# Main Wrapper #;
;################;

print "MAIN ",pc
	PHB : PHK : PLB
	JSR SpriteCode
	PLB
	RTL

;################;
;# Main Routine #;
;################;

Offscreen:
	SEP #$20						; \ kill bullet sprite
	LDA #$00						; |
	STA !cluster_num,y				; |
	RTS								; /

SpriteCode:
	LDA !cluster_x_low,y			; \ store bullet position into scratch RAM
	STA $00							; |
	LDA !cluster_x_high,y			; |
	STA $01							; |
	LDA !cluster_y_low,y			; |
	STA $02							; |
	LDA !cluster_y_high,y			; |
	STA $03							; /
	
	REP #$20

	LDA $00							; \ handle the sprite going offscreen, x based
	SEC : SBC $1A					; |
	STA $00							; |
	CMP #$FFE0						; |
	BCS +							; |
	CMP #$0120						; |
	BCC +							; |
	BRA Offscreen					; |
	+								; /
	
	LDA $02							; \ handle the sprite going offscreen, y based
	SEC : SBC $1C					; |
	STA $02							; |
	CMP #$FFF0						; |
	BCS +							; |
	CMP #$00F0						; |
	BCC +							; |
	BRA Offscreen					; |
	+								; /

	SEP #$20

	JSR Graphics
	
	LDY $15E9|!addr

	LDA $9D							; \ if sprites are locked, don't do things
	BNE .done						; /
	
	LDA !cluster_type,y						; \ load bullet type
	ASL										; |
	TAX										; |
	JSR (bulletModificationPointers,x)		; / jump to the bullet modification routine
	
	JSR Interaction					; \ process interaction
	BCS +							; | if carry set, then the player isn't touching the bullet
	PHY								; |
	JSL $00F5B7						; | hurt player
	PLY								; |
	+								; /
	
	JSR Speed

	LDA !cluster_expire_timer,y		; \ load the bullet expiration timer
	BEQ .done						; | if it's 0 then we don't care, just skip all this stuff
	DEC								; | decrement it
	STA !cluster_expire_timer,y		; | store it back
	BNE .done						; | and if it's not 0 then we're not ready to kill the bullet yet
	LDA #$00						; | if it's 0,
	STA !cluster_num,y				; / then kill the bullet

	.done
	RTS
	
;##################################;
;# Interaction and Speed Routines #;
;##################################;

Interaction:						; interaction routine adapted from the original game's code ($02FE71)
	LDA !cluster_x_low,y
	STA $00
	LDA !cluster_x_high,y
	STA $01

	REP #$20
	LDA $94
	SEC : SBC $00
	CLC : ADC #$000A
	SEP #$20

	CMP #$14
	BCS .noContact

	LDA #$14

	LDX $73
	BNE .notBig
	LDX $19
	BEQ .notBig

	LDA #$20
	
	.notBig
	
	STA $00
	
	LDA $96
	SEC : SBC !cluster_y_low,y
	CLC : ADC #$1C
	CMP $00	

	.noContact
	RTS
	
Speed:								; speed routine adapted from the original game's code ($02FF98 and $02FFA3)
	LDA !cluster_speed_y,y
	ASL #4
	CLC : ADC !cluster_speed_y_frac,y
	STA !cluster_speed_y_frac,y
	PHP
	LDA !cluster_speed_y,y
	LSR #4
	CMP #$08
	LDX #$00
	BCC +
	ORA #$F0
	DEX
	
	+
	PLP
	ADC !cluster_y_low,y
	STA !cluster_y_low,y
	TXA
	ADC !cluster_y_high,y
	STA !cluster_y_high,y
	
	LDA !cluster_speed_x,y
	ASL #4
	CLC : ADC !cluster_speed_x_frac,y
	STA !cluster_speed_x_frac,y
	PHP
	LDA !cluster_speed_x,y
	LSR #4
	CMP #$08
	LDX #$00
	BCC +
	ORA #$F0
	DEX
	
	+
	PLP
	ADC !cluster_x_low,y
	STA !cluster_x_low,y
	TXA
	ADC !cluster_x_high,y
	STA !cluster_x_high,y
	
	RTS
	
;################################;
;# Bullet Modification Routines #;
;################################;

StandardBullet:
CircularBullet:
BackForthBullet:
SpeedUpBullet:
	RTS

SineWaveBullet:
CosineWaveBullet:
	LDA !cluster_misc_table,y	; 0 = right, 1 = down, 2 = left, 3 = up
	AND #$01
	BNE .vertical

		LDA !cluster_speed_y,y
		CMP !cluster_setting_1,y
		BEQ +
		
		CLC : ADC !cluster_setting_2,y
		STA !cluster_speed_y,y
		RTS
		
		+
		LDA !cluster_setting_1,y		; \ inverse speed to approach
		EOR #$FF						; |
		INC								; |
		STA !cluster_setting_1,y		; /
		
		LDA !cluster_setting_2,y		; \ inverse acceleration
		EOR #$FF						; |
		INC								; |
		STA !cluster_setting_2,y		; /
		
		RTS
		
	.vertical
		LDA !cluster_speed_x,y
		CMP !cluster_setting_1,y
		BEQ +
		
		CLC : ADC !cluster_setting_2,y
		STA !cluster_speed_x,y
		RTS
		
		+
		LDA !cluster_setting_1,y		; \ inverse speed to approach
		EOR #$FF						; |
		INC								; |
		STA !cluster_setting_1,y		; /
		
		LDA !cluster_setting_2,y		; \ inverse acceleration
		EOR #$FF						; |
		INC								; |
		STA !cluster_setting_2,y		; /
		
		RTS

TargetBullet:
	RTS

ReAimBullet:
	LDA !cluster_setting_1,y	; \ if the bullet re-aimed the number of times specified, don't do it again
	AND #$0F					; |
	BEQ ++						; /
	
	LDA !cluster_setting_2,y
	BEQ +
	DEC
	STA !cluster_setting_2,y
	BNE ++
	
	+
	LDA !cluster_setting_1,y
	DEC
	STA !cluster_setting_1,y

	AND #$F0
	LSR #4
	STA !cluster_setting_2,y
	
	LDA !cluster_x_low,y		; \ store bullet position into scratch RAM
	STA $00						; |
	LDA !cluster_x_high,y		; |
	STA $01						; |
	LDA !cluster_y_low,y		; |
	STA $02						; |
	LDA !cluster_y_high,y		; |
	STA $03						; /
	
	LDA $00						; \ subtract bullet x position with player x position
	SEC : SBC $94				; |
	STA $00						; |
	LDA $01						; |
	SBC $95						; |
	STA $01						; /
	
	REP #$20					; \ subtract bullet y position with player y position (and a constant so it aims a bit lower)
	LDA $02						; |
	SEC : SBC $96				; |
	SBC #$0010					; |
	STA $02						; |
	SEP #$20					; /
	
	LDA !cluster_misc_table,y	; load raw speed
	
	%Aiming()					; aim at the player
	LDA $00						; \ store x and y speeds
	STA !cluster_speed_x,y		; |
	LDA $02						; |
	STA !cluster_speed_y,y		; /

	++
	RTS

;####################;
;# Graphics Routine #;
;####################;

Graphics:
	LDY #$00
	JSR FindOAM							; rather than loading a fixed OAM slot based on sprite index, let's just find a free one
	BCC +								; if carry clear, no slot is available so we just return
	
	LDA $00								; \ load screen position so the sprite can be drawn in the right spot
	STA $0200|!addr,y					; |
	LDA $02								; |
	STA $0201|!addr,y					; /
	
	LDA #!cluster_tile					; \ set tile
	STA $0202|!addr,y					; /
	
	LDA #!cluster_props					; \ set props
	STA $0203|!addr,y					; /
	
	TYA									; \ set OAM index but for size
	LSR #2								; |
	TAY									; /
	
	LDA $01								; \ set 9th x position bit
	AND #$01							; |
	ORA #$02							; | and size
	STA $0420|!addr,y					; /
	
	+
	RTS
	
FindOAM:
	LDA $0201|!addr,y					; \ load in OAM Y position
	CMP #$F0							; | if it's offscreen (empty)
	BEQ +								; | then we can use this as our index
	INY #4								; |
	BNE FindOAM							; | if we didn't loop from the entire $0200-$02FF area of OAM, then we can keep searching for empty slots
	LDY $15E9|!addr						; | restore cluster sprite index
	LDA #$00							; | since there's no available OAM slot (for some reason),
	STA !cluster_num,y					; | kill the sprite
	CLC									; | and clear carry so that nothing is rendered
	RTS									; /
	
	+
	SEC									; \ set carry so the GFX routine knows that it's fine to write to OAM
	RTS									; /