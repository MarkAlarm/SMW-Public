;########################################################;
;# Customizable Buzzy Beetle                            #;
;# By MarkAlarm                                         #;
;# This version has some code changes from the original #;
;# Check the other version for the original code        #;
;# Credit unnecessary, but appreciated                  #;
;########################################################;

;######################################################################################;
;# Extra Byte/Bit Information                                                         #;
;#                                                                                    #;
;# Extra Bit                - Unused (may add additional features in a future update) #;
;#                                                                                    #;
;# Extra Byte 1             - Walk speed, how fast the beetle will walk on the ground #;
;#                            $08: vanilla's default speed                            #;
;#                            $0C: vanilla's "fast" speed                             #;
;#                            Use values between $00 and $7F                          #;
;#                                                                                    #;
;# Extra Byte 2             - Kick speed, how fast the beetle will be kicked          #;
;#                            $2E: vanilla's base speed                               #;
;#                            $34: yoshi's spit speed (?)                             #;
;#                            Use values between $00 and $7F                          #;
;#                                                                                    #;
;# Extra Byte 3             - Miscellaneous properties                                #;
;#                            Format: aw--jfls                                        #;
;#                            a = animate faster in the air (leave as 0)              #;
;#                            w = draw wings like a parakoopa (leave as 0)            #;
;#                            - = unused (?)                                          #;
;#                            j = jump over shells                                    #;
;#                            f = follow/turn around to face mario                    #;
;#                            l = stay on ledges                                      #;
;#                            s = use faster walk speeds (unused)                     #;
;#                            $00: vanilla's default properties                       #;
;#                                                                                    #;
;# Extra Byte 4             - Initial state, how the beetle should spawn in           #;
;#                            $08: main/normal                                        #;
;#                            $09: carriable/stunned                                  #;
;#                            $0A: kicked                                             #;
;#                            Other values will probably crash the game               #;
;#                                                                                    #;
;######################################################################################;

;######################;
;# Defines and Tables #;
;######################;

BounceYSpeeds:
	db $00,$00,$00,$F8,$F8,$F8,$F8,$F8
	db $F8,$F7,$F6,$F5,$F4,$F3,$F2,$E8
	db $E8,$E8,$E8,$00,$00,$00,$00,$FE
	db $FC,$F8,$EC,$EC,$EC,$E8,$E4,$E0
	db $DC,$D8,$D4,$D0,$CC,$C8

ShellAniTiles:
	db $06,$07,$08,$07

ShellGfxProp:
	db $00,$00,$00,$40

; all of these DATA values are used in the stunned/kicked/carried states
; used by the vanilla game, so there's no reason to change these unless you know what you're doing
	
DATA_019F99:
	db $FC,$04
DATA_019F67:
	db $F3,$0D
DATA_019F69:
	db $FF,$00
DATA_019F5B:
	db $0B,$F5,$04,$FC,$04,$00
DATA_019F61:
	db $00,$FF,$00,$FF,$00,$00

;##################;
;# State Wrappers #;
;##################;

print "INIT ",pc
	JSL $01ACF9						; \ get random number for the sprite's initial pose
	STA !1570,x						; /
	%SubHorzPos()					; \ face player
	TYA								; |
	STA !157C,x						; /
	
	LDA !extra_byte_4,x
	STA !sprite_status,x
	
	CMP #$09
	BEQ .stunned
	CMP #$0A
	BEQ .kicked
	
	RTL
	
.stunned
	LDA #$FF
	STA !1540,x
	RTL
	
.kicked
	LDA !extra_byte_2,x
	STA $00
	
	LDA !157C,x
	BEQ +
	LDA $00
	EOR #$FF
	INC
	STA $00
	+
	
	LDA $00
	STA !sprite_speed_x,x
	RTL

; a note about the buzzy beetle sprite: it uses a shared sprite handler for sprites 00-13
; this includes segments of code that would lookup a table indexed by the sprite number in order to get data
; those are changed in favor of direct loads of the necessary values, since this is only meant to act as a buzzy beetle
; also any code that gets skipped due to this has been removed/commented out as well
; wow there's a ton unused in this thing lol

print "MAIN ",pc
	PHB : PHK : PLB					; \ main wrapper
	JSR BuzzyBeetleMain				; |
	PLB								; /
	RTL

print "CARRIABLE ",pc
	JSR BuzzyBeetleStunned
	RTL

print "KICKED ", pc
	JSR BuzzyBeetleKicked
	RTL

print "CARRIED ", pc
	JSR BuzzyBeetleCarried
	RTL

;################;
;# Main Routine #;
;################;

BuzzyBeetleMain:
	LDA $9D							; \ if sprites aren't locked, continue
	BEQ +							; /
	JSL $01A7DC						; sprite and player interaction
	JSL $018032						; block interaction
	JSR MainGFX						; graphics
	RTS

	+
	JSR IsOnGround					; \ check if the beetle is on the ground
	BEQ ++							; / if not, skip ahead
	
	LDA !extra_byte_1,x
	STA $00

	LDA !157C,x						; \ load base walking speed based on horizontal direction
	BEQ +							; |
	LDA $00
	EOR #$FF
	INC
	STA $00
	+								; |
	LDA $00							; /
	EOR !sprite_slope,x				; \ handle walking on slopes
	ASL								; |
	LDA $00							; |
	BCC +							; |
	CLC								; |
	ADC !sprite_slope,x				; |
	+								; /
	STA !sprite_speed_x,x			; set x speed

	++
	LDY !157C,x						; \ not sure when this ever gets triggered, it always seems to branch 
	TYA								; |
	INC								; |
	AND !sprite_blocked_status,x	; |
	AND #$03						; |
	BEQ +							; /
	STZ !sprite_speed_x,x			; clear x speed

	+
	JSR IsTouchingCeiling			; \ check if the beetle is touching the ceiling
	BEQ +							; / if not, skip ahead
	STZ !sprite_speed_y,x			; clear y speed

	+
	LDA #$00
	%SubOffScreen()
	JSL $01802A						; update sprite x/y position with gravity
	JSR SetAnimationFrame
	JSR IsOnGround
	BEQ SpriteInAir

SpriteOnGround:
	JSR SetSomeYSpeed
	STZ !151C,x
	LDA !extra_byte_3,x
	PHA
	AND #$04
	BEQ DontFollowMario
	LDA !1570,x
	AND #$7F
	BNE DontFollowMario
	LDA !157C,x
	PHA
	JSR FaceMario
	PLA
	CMP !157C,x
	BEQ DontFollowMario
	LDA #$08
	STA !15AC,x

DontFollowMario:
	PLA
	AND #$08
	BEQ +
	JSR JumpOverShells

	+
	BRA +++

SpriteInAir:
	LDA !extra_byte_3,x
	BPL +
	JSR SetAnimationFrame
	BRA ++

	+
	STZ !1570,x

	++
	LDA !extra_byte_3,x
	BEQ +++
	LDA !151C,x
	ORA !1558,x
	ORA !1528,x
	ORA !1534,x
	BNE +++
	JSR FlipSpriteDir
	LDA #$01
	STA !151C,x

	+++
	LDA !1528,x
	BEQ +
	JSR UnusedKickKill				; unused subroutine?
	BRA ++

	+
	JSL $01A7DC						; sprite and player interaction

	++
	JSL $018032						; block interaction
	JSR FlipIfTouchingObj

MainGFX:
	LDA !157C,x
	PHA
	LDY !15AC,x
	BEQ ++
	LDA #$02						; \ set pose
	STA !1602,x						; /
	LDA #$00
	CPY #$05
	BCC +
	INC

	+
	EOR !157C,x						; \ flip horizontal direction
	STA !157C,x						; /

	++
	LDA !extra_byte_3,x
	AND #$40
	BNE +
	JSL $0190B2						; generic sprite graphics routine two (?)
	BRA DoneWithSprite				; done

	+
	LDA !1602,x
	LSR
	LDA !sprite_y_low,x
	PHA
	SBC #$0F
	STA !sprite_y_low,x
	LDA !sprite_y_high,x
	PHA
	SBC #$00
	STA !sprite_y_high,x
	JSL $019D5F
	PLA
	STA !sprite_y_high,x
	PLA
	STA !sprite_y_low,x
	LDA !sprite_num,x
	CMP #$08
	BCC DoneWithSprite
	JSR KoopaWingGfxRt

DoneWithSprite:
	PLA
	STA !157C,x
	RTS
	
; all this stuff goes unused, but i'm including it anyway.

DATA_01B023:						; unused data as well
	db $F0,$10

UnusedKickKill:
	; LDA !sprite_num,x
	; CMP #$02
	; BNE +
	; JSL $01A7DC
	; BRA ++

	; +
	ASL !sprite_tweaker_167a,x		; \ disable regular interaction with the player
	SEC								; |
	ROR !sprite_tweaker_167a,x		; /
	JSL $01A7DC
	BCC +
	JSR CODE_01B12A

	+
	ASL !sprite_tweaker_167a,x		; \ use regular interaction again
	LSR !sprite_tweaker_167a,x		; /

	++
	RTS

CODE_01B12A:
	LDA #$10
	STA $149A|!addr
	LDA #$03
	STA $1DF9|!addr
	%SubHorzPos()
	LDA DATA_01B023,y
	STA !sprite_speed_x,x
	LDA #$E0
	STA !sprite_speed_y,x
	LDA #$02
	STA !sprite_status,x
	STY $76
	LDA #$01						; \ give points
	JSL $02ACE5						; /
	RTS

;#############################;
;# Carriable/Stunned Routine #;
;#############################;

; the stunned, kicked, and carried routines are all pulled from SMW's general handler
; these routines are adapted slightly to get rid of useless or redundant code,
; such as checking if a the current sprite is a goomba (a buzzy beetle is not a goomba)
; not commented as all.log documents it already
; nothing past this point should need modification anyways

BuzzyBeetleStunned:
	LDA $9D
	BEQ +
	JMP .skip

	+
	JSR HandleStunned
	JSL $01802A
	JSR IsOnGround
	BEQ +
	JSR BounceOnGround

	+
	JSR IsTouchingCeiling
	BEQ +
	LDA #$10
	STA !sprite_speed_y,x
	JSR IsTouchingObjSide
	BNE +
	LDA !sprite_x_low,x
	CLC
	ADC #$08
	STA $9A
	LDA !sprite_x_high,x
	ADC #$00
	STA $9B
	LDA !sprite_y_low,x
	AND #$F0
	STA $98
	LDA !sprite_y_high,x
	STA $99
	LDA !sprite_blocked_status,x
	AND #$20
	ASL #3
	ROL
	AND #$01
	STA $1933|!addr
	LDY #$00
	LDA $1868|!addr
	JSL $00F160
	LDA #$08
	STA !sprite_cape_disable_time,x

	+
	JSR IsTouchingObjSide
	BEQ +

	LDA !sprite_speed_x,x
	ASL
	PHP
	ROR !sprite_speed_x,x
	PLP
	ROR !sprite_speed_x,x

	+
	JSL $01803A

.skip
	JSR StunnedGFX
	LDA #$00
	%SubOffScreen()
	RTS

HandleStunned:
	LDA !1540,x
	ORA !1558,x
	STA !C2,x
	LDA !1558,x
	BEQ ++
	CMP #$01
	BNE ++
	LDY !1594,x
	LDA !sprite_being_eaten,y
	BNE ++
	JSL $07F78B
	JSR FaceMario
	ASL !sprite_oam_properties,x
	LSR !sprite_oam_properties,x
	LDY !160E,x
	LDA #$08
	CPY #$03
	BNE +
	INC !187B,x
	LDA !sprite_tweaker_166e,x
	ORA #$30
	STA !sprite_tweaker_166e,x
	LDA #$0A

	+
	STA !sprite_status,x
	RTS

	++
	LDA !1540,x
	BEQ +
	CMP #$03
	BEQ UnstunSprite
	CMP #$01
	BNE IncrementStunTimer

UnstunSprite:
	LDA #$08
	STA !sprite_status,x
	ASL !sprite_oam_properties,x
	LSR !sprite_oam_properties,x
	RTS

IncrementStunTimer:
	LDA $13
	AND #$01
	BNE +
	INC !1540,x
	+
	RTS

BounceOnGround:
	LDA !sprite_speed_x,x
	PHP
	BPL +
	EOR #$FF
	INC

	+
	LSR
	PLP
	BPL +
	EOR #$FF
	INC

	+
	STA !sprite_speed_x,x
	LDA !sprite_speed_y,x
	PHA
	JSR SetSomeYSpeed
	PLA
	LSR #2
	TAY

	LDA BounceYSpeeds,y
	LDY !sprite_blocked_status,x
	BMI +
	STA !sprite_speed_y,x

	+
	RTS

StunnedGFX:
	LDA #$06
	LDY !sprite_oam_index,x
	BNE CODE_01980F
	LDA #$08

CODE_01980F:
	STA !1602,x
	LDA !sprite_oam_index,x
	PHA
	BEQ +
	CLC
	ADC #$08

	+
	STA !sprite_oam_index,x
	JSL $0190B2
	PLA
	STA !sprite_oam_index,x
	LDA $1EEB|!addr
	BMI +
	LDA !1602,x
	CMP #$06
	BNE +
	LDY !sprite_oam_index,x
	LDA !1558,x
	BNE +
	LDA !1540,x
	BEQ +
	CMP #$30
	BCS +

	LSR
	LDA $0308|!addr,y
	ADC #$00
	BCS +
	STA $0308|!addr,y

	+
	RTS

;##################;
;# Kicked Routine #;
;##################;

BuzzyBeetleKicked:
	LDA !1528,x
	BNE +
	LDA !sprite_speed_x,x
	CLC
	ADC #$20
	CMP #$40
	BCS +
	JSR CODE_01AA0B

	+
	STZ !1528,x
	LDA $9D
	ORA !163E,x
	BEQ +
	JMP CODE_01998F

	+
	JSR UpdateDirection
	LDA !15B8,x
	PHA
	JSL $01802A
	PLA
	BEQ +
	STA $00
	LDY !164A,x
	BNE +
	CMP !15B8,x
	BEQ +
	EOR !sprite_speed_x,x
	BMI +
	LDA #$F8
	STA !sprite_speed_y,x
	BRA ++

	+
	JSR IsOnGround
	BEQ +++
	JSR SetSomeYSpeed
	LDA #$10
	STA !sprite_speed_y,x

	++
	LDA $1860|!addr
	CMP #$B5
	BEQ ++
	CMP #$B4
	BNE +++

	++
	LDA #$B8
	STA !sprite_speed_y,X

	+++
	JSR IsTouchingObjSide
	BEQ +
	JSR CODE_01999E

	+
	JSL $01803A

CODE_01998F:
	LDA #$00
	%SubOffScreen()
	JMP KickedGFX

CODE_01999E:
	LDA #$01
	STA $1DF9|!addr
	JSR InvertSpeedAndDirection
	LDA !sprite_off_screen_horz,x
	BNE +
	LDA !sprite_x_low,x
	SEC
	SBC $1A
	CLC
	ADC #$14
	CMP #$1C
	BCC +
	LDA !sprite_blocked_status,x
	AND #$40
	ASL #2
	ROL
	AND #$01
	STA $1933|!addr
	LDY #$00
	LDA $18A7|!addr
	JSL $00F160
	LDA #$05
	STA !sprite_cape_disable_time,x

	+
	RTS

CODE_01AA0B:
	LDA !C2,x
	BNE SetStunnedTimer
	STZ !1540,x
	BRA SetAsStunned

SetStunnedTimer:
	LDA #$FF
	STA !1540,x

SetAsStunned:
	LDA #$09
	STA !sprite_status,x
	RTS

KickedGFX:
	LDA !C2,x
	STA !1558,x
	LDA $14
	LSR #2
	AND #$03
	TAY
	PHY
	LDA ShellAniTiles,y
	JSR CODE_01980F
	STZ !1558,x
	PLY
	LDA ShellGfxProp,y
	LDY !sprite_oam_index,x
	EOR $030B|!addr,y
	STA $030B|!addr,y
	RTS

;###################;
;# Carried Routine #;
;###################;

BuzzyBeetleCarried:
	JSR HandleCarried
	LDA $13DD|!addr
	BNE +
	LDA $1419|!addr
	BNE +
	LDA $1499|!addr
	BEQ ++

	+
	STZ !sprite_oam_index,x

	++
	LDA $64
	PHA
	LDA $1419|!addr
	BEQ +
	LDA #$10
	STA $64

	+
	JSR StunnedGFX
	PLA
	STA $64
	RTS

HandleCarried:
	JSL $019138
	LDA $71
	CMP #$01
	BCC +
	LDA $1419|!addr
	BNE +
	
	LDA #$09
	STA !sprite_status,x
	RTS

	+
	LDA !sprite_status,x
	CMP #$08
	BEQ +++
	LDA $9D
	BEQ +
	JMP CODE_01A0B1

	+
	JSR HandleStunned
	JSL $018032
	LDA $1419|!addr
	BNE ++
	BIT $15
	BVC ReleaseSprCarried

	++
	JSR CODE_01A0B1

	+++
	RTS

ReleaseSprCarried:
	STZ !1626,x
	STZ !sprite_speed_y,x

	LDA #$09
	STA !sprite_status,X

	LDA $15
	AND #$08
	BNE TossUpSprCarried

	LDA $15
	AND #$03
	BNE KickSprCarried

	LDY $76
	LDA $D1
	CLC
	ADC DATA_019F67,y
	STA !sprite_x_low,x
	LDA $D2
	ADC DATA_019F69,y
	STA !sprite_x_high,x
	
	%SubHorzPos()
	LDA.W DATA_019F99,y
	CLC
	ADC $7B
	STA !sprite_speed_x,x
	STZ !sprite_speed_y,x
	BRA StartKickPose

TossUpSprCarried:
	JSL $01AB6F
	LDA #$90
	STA !sprite_speed_y,x
	LDA $7B
	STA !sprite_speed_x,x
	ASL
	ROR !sprite_speed_x,x
	BRA StartKickPose

KickSprCarried:
	JSL $01AB6F
	LDA !1540,x
	STA !C2,x
	LDA #$0A
	STA !sprite_status,x
	
	LDA !extra_byte_2,x
	STA $02
	
	LDA $76
	BNE +
	LDA $02
	EOR #$FF
	INC
	STA $02
	+
	
	LDA $02
	STA !sprite_speed_x,x			; / store the shell kick speed
	EOR $7B
	BMI StartKickPose
	LDA $7B
	STA $00
	ASL $00
	ROR
	CLC
	ADC $02
	STA !sprite_speed_x,x

StartKickPose:
	LDA #$10
	STA !154C,x
	LDA #$0C
	STA $149A|!addr
	RTS


CODE_01A0B1:
	LDY #$00
	LDA $76
	BNE +
	INY

	+
	LDA $1499|!addr
	BEQ +
	INY #2
	CMP #$05
	BCC +
	INY

	+
	LDA $1419|!addr
	BEQ +
	CMP #$02
	BEQ ++

	+
	LDA $13DD|!addr
	ORA $74
	BEQ +++

	++
	LDY #$05

	+++
	PHY
	LDY #$00
	LDA $1471|!addr
	CMP #$03
	BEQ +
	LDY #$3D

	+
	LDA $94,y
	STA $00
	LDA $95,y
	STA $01
	LDA $96,y
	STA $02
	LDA $97,y
	STA $03
	PLY
	LDA $00
	CLC
	ADC DATA_019F5B,y
	STA !sprite_x_low,x
	LDA $01
	ADC DATA_019F61,y
	STA !sprite_x_high,x
	
	LDA #$0D
	LDY $73
	BNE +
	LDY $19
	BNE ++

	+
	LDA #$0F

	++
	LDY $1498|!addr
	BEQ +
	LDA #$0F

	+
	CLC
	ADC $02
	STA !sprite_y_low,x
	LDA $03
	ADC #$00
	STA !sprite_y_high,x
	LDA #$01
	STA $148F|!addr
	STA $1470|!addr
	RTS

;##########################;
;# SMW's Suboutines (JSR) #;
;##########################;

FaceMario:
	%SubHorzPos()
	TYA
	STA !157C,x
	RTS

FlipIfTouchingObj:
	LDA !157C,x
	INC
	AND !sprite_blocked_status,x
	AND #$03
	BEQ +
	JSR FlipSpriteDir
	+
	RTS

FlipSpriteDir:
	LDA.W !15AC,x
	BNE +
	LDA #$08
	STA !15AC,x

InvertSpeedAndDirection:
	LDA !sprite_speed_x,x
	EOR #$FF
	INC
	STA !sprite_speed_x,x
	LDA !157C,x
	EOR #$01
	STA !157C,x
	+
	RTS

IsOnGround:
	LDA !sprite_blocked_status,x
	AND #$04
	RTS

IsTouchingCeiling:
	LDA !sprite_blocked_status,x
	AND #$08
	RTS

IsTouchingObjSide:
	LDA !sprite_blocked_status,x
	AND #$03
	RTS

JumpOverShells:
	TXA
	EOR $13
	AND #$03
	BNE +
	LDY #!SprSize-1
	--
	LDA !sprite_status,y
	CMP #$0A
	BEQ HandleJumpOver
	-
	DEY
	BPL --
	+
	RTS

HandleJumpOver:
	LDA !sprite_x_low,y
	SEC
	SBC #$1A
	STA $00
	LDA !sprite_x_high,y
	SBC #$00
	STA $08
	LDA #$44
	STA $02
	LDA !sprite_y_low,y
	STA $01
	LDA !sprite_y_high,y
	STA $09
	LDA.B #$10
	STA $03
	JSL $03B69F
	JSL $03B72B
	BCC -
	JSR IsOnGround
	BEQ -
	LDA !157C,y
	CMP !157C,x
	BEQ +
	LDA #$C0
	STA !sprite_speed_y,x
	STZ !163E,x
	+
	RTS

KoopaWingDispXLo:
	db $FF,$F7,$09,$09
KoopaWingDispXHi:
	db $FF,$FF,$00,$00
KoopaWingDispY:
	db $FC,$F4,$FC,$F4
KoopaWingTiles:
	db $5D,$C6,$5D,$C6
KoopaWingGfxProp:
	db $46,$46,$06,$06
KoopaWingTileSize:
	db $00,$02,$00,$02

KoopaWingGfxRt:
	LDY #$00
	JSR IsOnGround
	BNE +
	LDA !1602,x
	AND #$01
	TAY
	+
	STY $02
	LDA !sprite_off_screen_vert,x
	BNE ++
	LDA !sprite_x_low,x
	STA $00
	LDA !sprite_x_high,x
	STA $04
	LDA !sprite_y_low,x
	STA $01
	LDY !sprite_oam_index,x
	PHX
	LDA !157C,x
	ASL
	ADC $02
	TAX
	LDA $00
	CLC
	ADC KoopaWingDispXLo,x
	STA $00
	LDA $04
	ADC KoopaWingDispXHi,x
	PHA
	LDA $00
	SEC
	SBC $1A
	STA $0300|!addr,y
	PLA
	SBC $1B
	BNE +
	LDA $01
	SEC
	SBC $1C
	CLC
	ADC KoopaWingDispY,x
	STA $0301|!addr,y
	LDA KoopaWingTiles,x
	STA $0302|!addr,y
	LDA $64
	ORA KoopaWingGfxProp,x
	STA $0303|!addr,y
	TYA
	LSR #2
	TAY
	LDA KoopaWingTileSize,x
	STA $0460|!addr,y
	+
	PLX
	++
	RTS

SetAnimationFrame:
	INC !1570,x
	LDA !1570,x
	LSR #3
	AND #$01
	STA !1602,x
	RTS

SetSomeYSpeed:
	LDA !sprite_blocked_status,x
	BMI +
	LDA #$00
	LDY !sprite_slope,x
	BEQ ++
	+
	LDA #$18
	++
	STA !sprite_speed_y,x
	RTS

UpdateDirection:
	LDA #$00
	LDY !sprite_speed_x
	BEQ ++
	BPL +
	INC
	+
	STA !157C,x
	++
	RTS
