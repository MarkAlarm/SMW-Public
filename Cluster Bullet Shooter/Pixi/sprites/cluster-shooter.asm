;############################################;
;# Cluster Bullet Shooter v1.11             #;
;# By MarkAlarm                             #;
;# Credit if used, do not claim as your own #;
;############################################;

;##################################;
;# Extra Byte/Bit Information     #;
;#                                #;
;# Refer to the included document #;
;##################################;

;#####################;
;# Defines and Stuff #;
;#####################;

	!readme               = 0					; hopefully you read the readme. set this to 1.

	!bulletAmount         = 20					; maximum number of cluster bullets to have on screen, do not set higher than 20 or I will be sad
	!bulletSpriteNum      = $10					; cluster sprite number as defined in list.txt

	!shootSFX             = $27					; if $00, it won't play a sound effect
	!shootChannel         = $1DFC|!addr			; should either be $1DF9 or $1DFC. check out https://www.smwcentral.net/?p=viewthread&t=6665 for a detailed list of sound effecta
	
	; do not edit anything past this point, unless you know what you're doing

	!cluster_type         = $0F4A|!addr
	!cluster_setting_1    = $0F72|!addr
	!cluster_setting_2    = $0F86|!addr
	
	!cluster_speed_y      = $1E52|!addr
	!cluster_speed_x      = $1E66|!addr
	!cluster_speed_y_frac = $1E7A|!addr
	!cluster_speed_x_frac = $1E8E|!addr
	
	!cluster_expire_timer = $0F5E|!addr
	!cluster_misc_table   = $0F9A|!addr
	
	!shooterTypeTable     = !C2
	!shootRateTable       = !1510
	!bulletSpeedTable     = !151C
	!bulletAngleTable     = !1528
	!timerOffsetTable     = !1534
	!parameterTable       = !1570
	!bulletTimerTable     = !157C
	!shotCapTable         = !1594
	!attachNumTable       = !15DC
	!attachOffsetsTable   = !15F6
	!setting1Table        = !1602
	!setting2Table        = !1632
	
	!angleTableCopy       = !1504
	!attachedSpriteIndex  = !1FD6
	
	assert !readme, "You didn't read the readme, did you? Nothing was inserted."

;######################;
;# Parameter Pointers #;
;######################;

parameterPointers:
	dw NoParameter					; $00
	
	dw OnOff_isON					; $01
	dw OnOff_isOFF					; $02
	dw BlueP_isACTIVE				; $03
	dw BlueP_isNOTACTIVE			; $04
	dw SilverP_isACTIVE				; $05
	dw SilverP_isNOTACTIVE			; $06
	
	dw RNG1_isPOSITIVE				; $07
	dw RNG1_isNEGATIVE				; $08
	dw RNG2_isPOSITIVE				; $09
	dw RNG2_isNEGATIVE				; $0A
	
	dw Player_onRIGHT				; $0B
	dw Player_onLEFT				; $0C
	dw Player_isBELOW				; $0D
	dw Player_isABOVE				; $0E
	dw Player_facingRIGHT			; $0F
	dw Player_facingLEFT			; $10
	
	dw DragonCoins_areNOTCOLLECTED	; $11
	dw DragonCoins_areCOLLECTED		; $12
	dw Invis1Up_isNOTCOLLECTED		; $13
	dw Invis1Up_isCOLLECTED			; $14
	dw Moon_isNOTCOLLECTED			; $15
	dw Moon_isCOLLECTED				; $16

	dw ReservedParameter_17			; $17
	dw ReservedParameter_18			; $18
	dw ReservedParameter_19			; $19
	dw ReservedParameter_1A			; $1A
	dw ReservedParameter_1B			; $1B
	dw ReservedParameter_1C			; $1C
	dw ReservedParameter_1D			; $1D
	dw ReservedParameter_1E			; $1E
	dw ReservedParameter_1F			; $1F
	
	; if you wanted to write your own custom parameter checks, you would write the pointer here.
	; then where all these pointers are, you'd add the code under everything else.
	
;#################################;
;# Shooter Modification Pointers #;
;#################################;

shooterModificationPointers:
	dw StandardShooter			; $00
	dw CircularShooter			; $01
	dw BackForthShooter			; $02
	dw SpeedUpShooter			; $03
	dw SineWaveShooter			; $04
	dw CosineWaveShooter		; $05
	dw TargetShooter			; $06
	dw ReAimShooter				; $07
	
	dw ReservedShooter_08		; $08
	dw ReservedShooter_09		; $09
	dw ReservedShooter_0A		; $0A
	dw ReservedShooter_0B		; $0B
	dw ReservedShooter_0C		; $0C
	dw ReservedShooter_0D		; $0D
	dw ReservedShooter_0E		; $0E
	dw ReservedShooter_0F		; $0F
	dw ReservedShooter_10		; $10
	dw ReservedShooter_11		; $11
	dw ReservedShooter_12		; $12
	dw ReservedShooter_13		; $13
	dw ReservedShooter_14		; $14
	dw ReservedShooter_15		; $15
	dw ReservedShooter_16		; $16
	dw ReservedShooter_17		; $17
	dw ReservedShooter_18		; $18
	dw ReservedShooter_19		; $19
	dw ReservedShooter_1A		; $1A
	dw ReservedShooter_1B		; $1B
	dw ReservedShooter_1C		; $1C
	dw ReservedShooter_1D		; $1D
	dw ReservedShooter_1E		; $1E
	dw ReservedShooter_1F		; $1F

;##########################;
;# Init and Main Wrappers #;
;##########################;

print "INIT ",pc
	LDA #$FF
	STA !attachedSpriteIndex,x

	LDA !extra_byte_1,x				; \ set up the 12 extra bytes
	STA $0A							; |
	LDA !extra_byte_2,x				; |
	STA $0B							; |
	LDA !extra_byte_3,x				; |
	STA $0C							; /
	
	LDY #$00						; \ store the 12 extra bytes into sprite tables so they can be modified and accessed faster
	LDA [$0A],y						; |
	STA !shooterTypeTable,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !shootRateTable,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !bulletSpeedTable,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !bulletAngleTable,x			; |
	STA !angleTableCopy,x			; | we need to keep a copy of the starting angle so the back/forth shooter works properly
	INY								; |
	LDA [$0A],y						; |
	STA !timerOffsetTable,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !parameterTable,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !bulletTimerTable,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !shotCapTable,x				; |
	INY								; |
	LDA [$0A],y						; |
	STA !attachNumTable,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !attachOffsetsTable,x		; |
	INY								; |
	LDA [$0A],y						; |
	STA !setting1Table,x			; |
	INY								; |
	LDA [$0A],y						; |
	STA !setting2Table,x			; /	
	
	JSR AttachToSprite

	RTL

print "MAIN ",pc
	PHB : PHK : PLB
	JSR SpriteCode
	PLB
	RTL

;################;
;# Main Routine #;
;################;

SpriteCode:
	LDA #$00
	%SubOffScreen()					; don't try shooting when offscreen
	
	LDA $9D							; \ if sprites are locked, don't do things
	BNE .done						; /
	
	LDA #$01						; \ run cluster sprite code
	STA $18B8|!addr					; /
	
	LDA !sprite_status,x			; \ if not normal status, don't run
	CMP #$08						; |
	BNE .done						; /
	
	JSR AttachToSprite
	
	LDA !timerOffsetTable,x			; \ store timer offset into scratch
	STA $00							; /

	LDA !shootRateTable,x			; \ store fire rate into scratch
	STA $01							; /
	
	LDA $14							; \ load the global timer
	SEC : SBC $00					; | add in the offset
	AND $01							; | AND it with how often you want to shoot for
	BNE .done						; / if not zero, don't shoot
	
	LDA !parameterTable,x			; load parameter index
	
	CLC								; \ clear carry, it will be set if the parameter is met. if not met, then the bullet won't shoot
	AND #$7F						; |
	ASL								; | 
	TAX								; | 
	JSR (parameterPointers,x)		; / jump to parameter check routine
	
	BCC .done						; \ if carry is clear, don't shoot a bullet
	JSR GenerateBullet				; / shoot the bullet
	
	.done
	RTS
	
GenerateBullet:
	LDY #!bulletAmount-1			; \ load the highest possible slot index
	-								; | 
	LDA !cluster_num,y				; | load the cluster sprite number
	BEQ +							; | if zero, then a bullet can be spawned
	DEY								; | if not found, try another slot
	BPL -							; | if no more slots
	RTS								; / just return
	
	+
	LDA !shotCapTable,x				; \ load the shot counter
	BEQ +							; | if it's 0 then we don't care and we don't bother counting
	DEC !shotCapTable,x				; | decrement number of shots left
	BNE +							; | if not 0 then it can keep shooting
	LDA #$00						; | if it's 0,
	STA !sprite_status,x			; | then we kill the shooter
	+								; /
	
	LDA #!shootSFX					; \ play sound effect when shot
	BEQ +							; |
	STA !shootChannel				; |
	+								; /
	
	LDA.b #!bulletSpriteNum+!ClusterOffset		; \ store bullet number
	STA !cluster_num,y							; /
	
	LDA !shooterTypeTable,x			; \ store a copy of the shooter's type and parameters into the bullet
	STA !cluster_type,y				; | mainly done so that the bullet can modify itself after being shot
	LDA !setting1Table,x			; |
	STA !cluster_setting_1,y		; |
	LDA !setting2Table,x			; |
	STA !cluster_setting_2,y		; /
	
	LDA !sprite_x_low,x				; \ have cluster sprite spawn at the shooter's x position
	STA !cluster_x_low,y			; |
	LDA !sprite_x_high,x			; |
	STA !cluster_x_high,y			; /
	
	LDA !sprite_y_low,x				; \ have cluster sprite spawn at the shooter's y position
	STA !cluster_y_low,y			; |
	LDA !sprite_y_high,x			; |
	STA !cluster_y_high,y			; /

	LDA !bulletTimerTable,x			; \ store the bullet expiration timer into the cluster sprite table
	STA !cluster_expire_timer,y		; /

	STZ $05							; \ clear high angle byte
	LDA !bulletAngleTable,x			; | get the actual angle we want
	ASL								; | shift due to how CircleX and CircleY work
	STA $04							; | store angle into scratch
	BCC +							; |
	INC $05							; | increment high byte if we're in the $80-$FF range
	+								; /
	
	LDA !bulletSpeedTable,x			; \ store bullet speed into scratch
	STA $06							; /
	
	LDA !shooterTypeTable,x					; \ load shooter type
	ASL										; |
	TAX										; |
	JSR (shooterModificationPointers,x)		; / jump to the shooter modification routine
	
	BCS ++							; if carry set, we set the bullet speed in one of the modifier routines
	
	LDA !extra_bits,x				; \ shoot at specified angle if extra bit is clear
	AND #$04						; |
	BNE Aim							; / aim at the player if extra bit is set
	
	SetAngle:
		%CircleX()
		%CircleY()

		LDA $07
		STA !cluster_speed_x,y
		LDA $09
		STA !cluster_speed_y,y

		++
		RTS
	
	Aim:
		LDA !sprite_x_low,x			; \ store sprite position into scratch RAM
		STA $00						; |
		LDA !sprite_x_high,x		; |
		STA $01						; |
		LDA !sprite_y_low,x			; |
		STA $02						; |
		LDA !sprite_y_high,x		; |
		STA $03						; /
		
		LDA $00						; \ subtract sprite x position with player x position
		SEC : SBC $94				; |
		STA $00						; |
		LDA $01						; |
		SBC $95						; |
		STA $01						; /
		
		REP #$20					; \ subtract sprite y position with player y position (and a constant so it aims a bit lower)
		LDA $02						; |
		SEC : SBC $96				; |
		SBC #$0010					; |
		STA $02						; |
		SEP #$20					; /
		
		LDA $06						; load speed
		
		%Aiming()					; aim at the player
		LDA $00						; \ store x and y speeds
		STA !cluster_speed_x,y		; |
		LDA $02						; |
		STA !cluster_speed_y,y		; /
		
		RTS
		
AttachToSprite:
	LDA !attachNumTable,x			; \ if wanted sprite = $00, don't attach
	BNE +							; /
	RTS	
	+
	STA $09							; store wanted sprite into scratch

	LDA !attachedSpriteIndex,x		; \ load attached sprite index
	TAY								; |
	BPL +++							; /	if one is already set, dont't search for a sprite to attach to

	LDY #!SprSize					; \ load max sprite count
	-								; |
	SEP #$20						; |
	DEY								; |
	BMI .noAvailableAttach			; / if we checked all sprites and couldn't attach, return

	LDA !sprite_num,y				; \ check vanilla sprite number against the value we want
	CMP $09							; |
	BEQ +							; / if there's a match, check if we can actually attach to it
	TYX
	LDA !new_sprite_num,x			; \ check custom sprite number against the value we want
	LDX $15E9|!addr					; |
	CMP $09							; |
	BEQ +							; / if there's a match, check if we can actually attach to it
	
	BRA -
	
	+
	LDA !sprite_status,y			; \ check if the sprite is either in init or main
	CMP #$01						; |
	BEQ ++							; | if so, we can make another check
	CMP #$08						; |
	BMI -							; / if not, look for another potential sprite
	
	++
	LDA !sprite_x_low,x				; \ get x position difference between the potential sprite and the shooter
	SEC : SBC !sprite_x_low,y		; |
	STA $00							; |
	LDA !sprite_x_high,x			; |
	SBC !sprite_x_high,y			; |
	STA $01							; /
	
	REP #$20
	LDA $00							; \ inverse value if necessary, since it's absolute distance
	BPL +							; /
	EOR #$FFFF
	INC
	+
	
	SEC : SBC #$001F				; \ check if the two sprites are within ~2 tiles of each other
	BCS -							; / if not, then keep searching. this basically lets you put the shooter on the same tile ±1 in Lunar Magic
	
	SEP #$20
	TYA								; \ put the valid sprite's index into a sprite table so all this checking can be skipped next time
	STA !attachedSpriteIndex,x		; /

	+++
	LDA !sprite_status,y			; \ check sprite status so it's either in init or main
	CMP #$01						; |
	BEQ +							; | if so, attach with the given offset
	CMP #$08						; |
	BMI .killShooter				; / if not, something happened to the host sprite so we kill the shooter as well
	
	+
	JSR AttachmentOffset
	
	.noAvailableAttach
	RTS
	
	.killShooter
	LDA #$00						; \ kill the shooter
	STA !sprite_status,x			; /
	RTS
	
AttachmentOffset:
	LDA !attachOffsetsTable,x		; \ load in the offset
	STA $04							; / $02 will contain the whole offset, both y and x unmodified. now we get to make sense of the 4 bits each
	
	; please excuse the garbage code below. it effectively sets up the offsets in terms of 8 pixel increments, positive or negative.
	
	AND #$08
	BNE +
	LDA $04
	AND #$0F
	ASL #3
	STA $00
	STZ $01
	BRA ++

	+
	LDA $04
	EOR #$FF
	INC
	AND #$0F
	ASL #3
	EOR #$FF
	STA $00
	LDA #$FF
	STA $01
	
	++
	LDA $04
	LSR #4
	AND #$08
	BNE +
	LDA $04
	LSR #4
	AND #$0F
	ASL #3
	STA $02
	STZ $03
	BRA ++

	+
	LDA $04
	LSR #4
	EOR #$FF
	INC
	AND #$0F
	ASL #3
	EOR #$FF
	STA $02
	LDA #$FF
	STA $03
	
	++
	LDA !attachedSpriteIndex,x
	TAY
	
	; ok end the garbage code here
	
	LDA !sprite_x_low,y				; \ store the host sprite's x position into the shooter's
	CLC : ADC $00					; |
	STA !sprite_x_low,x				; |
	LDA !sprite_x_high,y			; |
	ADC $01							; |
	STA !sprite_x_high,x			; /
	
	LDA !sprite_y_low,y				; \ store the host sprite's y position into the shooter's
	CLC : ADC $02					; |
	STA !sprite_y_low,x				; |
	LDA !sprite_y_high,y			; |
	ADC $03							; |
	STA !sprite_y_high,x			; /
	
	RTS
	
;#################################;
;# Shooter Modification Routines #;
;#################################;

StandardShooter:					; note for all of these: clear the carry flag so that the speed is set by the general routine
	LDX $15E9|!addr					; if the carry flag is set, the speed was set by one of these custom modifiers
	CLC
	RTS
	
CircularShooter:					; TO-DO: make this actually work (IE fix the math routine or something)
	LDX $15E9|!addr
	
	LDA !bulletAngleTable,x			; \ increment the bullet shot angle by the specified amount
	CLC : ADC !setting1Table,x		; |
	STA !bulletAngleTable,x			; /
	
	CLC
	RTS
	
BackForthShooter:
	LDX $15E9|!addr
	
	LDA !bulletAngleTable,x
	CLC : ADC !setting1Table,x
	STA !bulletAngleTable,x
	
	CMP !setting2Table,x
	BEQ +
	CMP !angleTableCopy,x
	BEQ +
	
	CLC
	RTS
	
	+
	LDA !setting1Table,x
	EOR #$FF
	INC
	STA !setting1Table,x

	CLC
	RTS
	
SpeedUpShooter:
	LDX $15E9|!addr
	
	LDA !bulletSpeedTable,x			; \ if bullet speed is maxed out, don't continue increasing it
	CMP !setting2Table,x			; |
	BEQ +							; /
	
	CLC : ADC !setting1Table,x		; \ increment bullet speed by specified amount
	STA !bulletSpeedTable,x			; /
	
	+
	CLC
	RTS

SineWaveShooter:
	LDX $15E9|!addr
	
	LDA !bulletAngleTable,x			; \ misc table will hold the shooting direction
	LSR #6							; | 0 = right, 1 = down, 2 = left, 3 = up
	STA !cluster_misc_table,y		; /
	
	AND #$01
	BNE .vertical
	
	%CircleX()
	
	LDA $07							; \ set x speed
	STA !cluster_speed_x,y			; /
	
	LDA !setting1Table,x			; \ set y speed
	STA !cluster_speed_y,y			; /
	
	BRA +
		
	.vertical
	%CircleY()
	
	LDA $09							; \ set y speed
	STA !cluster_speed_y,y			; /
	
	LDA !setting1Table,x			; \ set x speed
	STA !cluster_speed_x,y			; /
	
	+
	LDA !cluster_setting_1,y		; \ inverse speed to approach
	EOR #$FF						; |
	INC								; |
	STA !cluster_setting_1,y		; /
	
	LDA !cluster_setting_2,y		; \ inverse acceleration
	EOR #$FF						; |
	INC								; |
	STA !cluster_setting_2,y		; /
	
	SEC
	RTS
	
CosineWaveShooter:
	LDX $15E9|!addr
	
	LDA !bulletAngleTable,x			; \ misc table will hold the shooting direction
	LSR #6							; | 0 = right, 1 = down, 2 = left, 3 = up
	STA !cluster_misc_table,y		; /
	
	AND #$01
	BNE .vertical
	
	%CircleX()
	
	LDA $07							; \ set x speed
	STA !cluster_speed_x,y			; /
	
	LDA #$00						; \ set y speed
	STA !cluster_speed_y,y			; /
	
	BRA +
		
	.vertical
	%CircleY()
	
	LDA $09							; \ set y speed
	STA !cluster_speed_y,y			; /
	
	LDA #$00						; \ set x speed
	STA !cluster_speed_x,y			; /
	
	+
	LDA !cluster_setting_1,y		; \ inverse speed to approach
	EOR #$FF						; |
	INC								; |
	STA !cluster_setting_1,y		; /
	
	LDA !cluster_setting_2,y		; \ inverse acceleration
	EOR #$FF						; |
	INC								; |
	STA !cluster_setting_2,y		; /
	
	SEC
	RTS
	
TargetShooter:
	LDX $15E9|!addr

	LDA !sprite_x_low,x			; \ store sprite position into scratch RAM
	STA $00						; |
	LDA !sprite_x_high,x		; |
	STA $01						; |
	LDA !sprite_y_low,x			; |
	STA $02						; |
	LDA !sprite_y_high,x		; |
	STA $03						; /
	
	REP #$20					; \ store target position into scratch RAM
	LDA !setting1Table,x		; |
	AND #$00FF					; |
	ASL #4						; |
	STA $08						; |
	LDA !setting2Table,x		; |
	AND #$00FF					; |
	ASL #4						; |
	STA $0A						; |
	SEP #$20					; /
	
	LDA $00						; \ subtract sprite x position with target x position
	SEC : SBC $08				; |
	STA $00						; |
	LDA $01						; |
	SBC $09						; |
	STA $01						; /
	
	LDA $02						; \ subtract sprite y position with target y position
	SEC : SBC $0A				; |
	STA $02						; |
	LDA $03						; |
	SBC $0B						; |
	STA $03						; /	
	
	LDA $06						; load speed
	
	%Aiming()					; aim at the player
	LDA $00						; \ store x and y speeds
	STA !cluster_speed_x,y		; |
	LDA $02						; |
	STA !cluster_speed_y,y		; /

	SEC
	RTS
	
ReAimShooter:
	LDX $15E9|!addr
	
	LDA !bulletSpeedTable,x			; \ keep the raw speed into the misc table so the re-aim works well
	STA !cluster_misc_table,y		; /
	
	LDA !setting1Table,x			; \ use cluster setting 2 as the frame counter, based on the setting 1 table
	AND #$F0						; |
	LSR #4							; |
	STA !cluster_setting_2,y		; /
	
	CLC
	RTS
	
ReservedShooter_08:
ReservedShooter_09:
ReservedShooter_0A:
ReservedShooter_0B:
ReservedShooter_0C:
ReservedShooter_0D:
ReservedShooter_0E:
ReservedShooter_0F:
ReservedShooter_10:
ReservedShooter_11:
ReservedShooter_12:
ReservedShooter_13:
ReservedShooter_14:
ReservedShooter_15:
ReservedShooter_16:
ReservedShooter_17:
ReservedShooter_18:
ReservedShooter_19:
ReservedShooter_1A:
ReservedShooter_1B:
ReservedShooter_1C:
ReservedShooter_1D:
ReservedShooter_1E:
ReservedShooter_1F:
	LDX $15E9|!addr
	CLC
	RTS
	
; add more shooter types below here if you so desire
	
;############################;
;# Parameter Check Routines #;
;############################;

NoParameter:
	LDX $15E9|!addr					; basically the code for all of these is load some RAM and if it fits the parameter wanted,
	SEC								; then set the carry flag. if it doesn't fit the parameter, it stays clear
	RTS
	
OnOff_isON:
	LDX $15E9|!addr
	LDA $14AF|!addr
	BNE +
	SEC	
	+
	RTS

OnOff_isOFF:
	LDX $15E9|!addr
	LDA $14AF|!addr
	BEQ +
	SEC	
	+
	RTS

BlueP_isACTIVE:
	LDX $15E9|!addr
	LDA $14AD|!addr
	BEQ +
	SEC	
	+
	RTS

BlueP_isNOTACTIVE:
	LDX $15E9|!addr
	LDA $14AD|!addr
	BNE +
	SEC	
	+
	RTS

SilverP_isACTIVE:
	LDX $15E9|!addr
	LDA $14AE|!addr
	BEQ +
	SEC	
	+
	RTS

SilverP_isNOTACTIVE:
	LDX $15E9|!addr
	LDA $14AE|!addr
	BNE +
	SEC	
	+
	RTS

RNG1_isPOSITIVE:
	LDX $15E9|!addr
	LDA $148D|!addr
	BPL +
	SEC
	+
	RTS
	
RNG1_isNEGATIVE:
	LDX $15E9|!addr
	LDA $148D|!addr
	BMI +
	SEC
	+
	RTS
	
RNG2_isPOSITIVE:
	LDX $15E9|!addr
	LDA $148E|!addr
	BPL +
	SEC
	+
	RTS

RNG2_isNEGATIVE:
	LDX $15E9|!addr
	LDA $148D|!addr
	BMI +
	SEC
	+
	RTS
	
Player_onRIGHT:
	LDX $15E9|!addr
	%SubHorzPos()
	CPY #$00
	CLC
	BNE +
	SEC
	+
	RTS

Player_onLEFT:
	LDX $15E9|!addr
	%SubHorzPos()
	CPY #$00
	CLC
	BEQ +
	SEC
	+
	RTS

Player_isBELOW:
	LDX $15E9|!addr
	%SubVertPos()
	CPY #$00
	CLC
	BNE +
	SEC
	+
	RTS

Player_isABOVE:
	LDX $15E9|!addr
	%SubVertPos()
	CPY #$00
	CLC
	BEQ +
	SEC
	+
	RTS
	
Player_facingRIGHT:
	LDX $15E9|!addr
	LDA $76
	BEQ +
	SEC
	+
	RTS
	
Player_facingLEFT:
	LDX $15E9|!addr
	LDA $76
	BNE +
	SEC
	+
	RTS

DragonCoins_areNOTCOLLECTED:
	LDA $13BF|!addr
	LSR #3
	TAX
	LDA $1F2F|!addr,x
	PHA
	LDA $13BF|!addr
	AND #$07
	TAX
	PLA
	AND $05B35B,x
	CLC
	BNE +
	SEC
	+
	LDX $15E9|!addr
	RTS
	
DragonCoins_areCOLLECTED:
	LDA $13BF|!addr
	LSR #3
	TAX
	LDA $1F2F|!addr,x
	PHA
	LDA $13BF|!addr
	AND #$07
	TAX
	PLA
	AND $05B35B,x
	CLC
	BEQ +
	SEC
	+
	LDX $15E9|!addr
	RTS
	
Invis1Up_isNOTCOLLECTED:
	LDA $13BF|!addr
	LSR #3
	TAX
	LDA $1F3C|!addr,x
	PHA
	LDA $13BF|!addr
	AND #$07
	TAX
	PLA
	AND $05B35B,x
	CLC
	BNE +
	SEC
	+
	LDX $15E9|!addr
	RTS
	
Invis1Up_isCOLLECTED:
	LDA $13BF|!addr
	LSR #3
	TAX
	LDA $1F3C|!addr,x
	PHA
	LDA $13BF|!addr
	AND #$07
	TAX
	PLA
	AND $05B35B,x
	CLC
	BEQ +
	SEC
	+
	LDX $15E9|!addr
	RTS
	
Moon_isNOTCOLLECTED:
	LDA $13BF|!addr
	LSR #3
	TAX
	LDA $1FEE|!addr,x
	PHA
	LDA $13BF|!addr
	AND #$07
	TAX
	PLA
	AND $05B35B,x
	CLC
	BNE +
	SEC
	+
	LDX $15E9|!addr
	RTS
	
Moon_isCOLLECTED:
	LDA $13BF|!addr
	LSR #3
	TAX
	LDA $1FEE|!addr,x
	PHA
	LDA $13BF|!addr
	AND #$07
	TAX
	PLA
	AND $05B35B,x
	CLC
	BEQ +
	SEC
	+
	LDX $15E9|!addr
	RTS

ReservedParameter_17:
ReservedParameter_18:
ReservedParameter_19:
ReservedParameter_1A:
ReservedParameter_1B:
ReservedParameter_1C:
ReservedParameter_1D:
ReservedParameter_1E:
ReservedParameter_1F:
	LDX $15E9|!addr
	SEC
	RTS
	
; add more parameter checks below here if you so desire
