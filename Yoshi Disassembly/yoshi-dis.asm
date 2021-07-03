;###################################################;
;# Yoshi Disassembly                               #;
;# By MarkAlarm                                    #;
;# This version behaves just like the original did #;
;# Credit unnecessary, but appreciated             #;
;###################################################;

;#####################;
;# Defines and Stuff #;
;#####################;

LoseYoshiXSpeeds:
	db $E8,$18

GroundedDismountXSpeeds:
	db $10,$F0

GrowingAniSequence:
	db $0C,$0B,$0C,$0B,$0A,$0B,$0A,$0B

EggLayXSpeeds:
	db $F0,$10

EggLayXOffsetsLow:
	db $FA,$06

EggLayXOffsetsHigh:
	db $FF,$00

PlayerMountYOffsets:
	db $04,$10

YoshiWalkFrames:
	db $02,$01,$00

YoshiPositionX:
	db $02,$FE

YoshiHeadTiles:
	db $00,$01,$02,$03,$02,$10,$04,$05
	db $00,$00,$FF,$FF,$00

YoshiBodyTiles:
	db $06,$07,$08,$09,$0A,$0B,$06,$0C
	db $0A,$0D,$0E,$0F,$0C

YoshiHeadDispXLow:
	db $0A,$09,$0A,$06,$0A,$0A,$0A,$10
	db $0A,$0A,$00,$00,$0A,$F6,$F7,$F6
	db $FA,$F6,$F6,$F6,$F0,$F6,$F6,$00
	db $00,$F6

YoshiHeadDispXHigh:
	db $00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$FF,$FF,$FF
	db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
	db $00,$FF

YoshiPositionY:
	db $00,$01,$01,$00,$04,$00,$00,$04
	db $03,$03,$00,$00,$04

YoshiHeadDispY:
	db $00,$00,$01,$00,$00,$00,$00,$08
	db $00,$00,$00,$00,$05

YoshiShellAbility:
	db $00,$00,$01,$02,$00,$00,$01,$02
	db $01,$01,$01,$03,$02,$02

YoshiAbilityIndex:
	db $03,$02,$02,$03,$01,$00

FireballXSpeeds:
	db $28,$24,$24

FireballYSpeeds:
	db $00,$F8,$08

SpitXSpeeds:
	db $30,$D0,$10,$F0

SpitXOffsetsLow:
	db $10,$F0

SpitXOffsetsHigh:
	db $00,$FF

YoshiDuckPoses:
	db $00,$04

DATA_01F60A:
	db $F5,$F5,$F5,$F5,$F5,$F5,$F5,$F0
	db $13,$13,$13,$13,$13,$13,$13,$18

TongueYOffsets:
	db $08,$08,$08,$08,$08,$08,$08,$13

DATA_03C176:
	db $0C,$0C,$0C,$0C,$0C,$0C,$0D,$0D
	db $0D,$0D,$FC,$FC,$FC,$FC,$FC,$FC
	db $FB,$FB,$FB,$FB,$0C,$0C,$0C,$0C
	db $0C,$0C,$0D,$0D,$0D,$0D,$FC,$FC
	db $FC,$FC,$FC,$FC,$FB,$FB,$FB,$FB

DATA_03C19E:
	db $0E,$0E,$0E,$0D,$0D,$0D,$0C,$0C
	db $0B,$0B,$0E,$0E,$0E,$0D,$0D,$0D
	db $0C,$0C,$0B,$0B,$12,$12,$12,$11
	db $11,$11,$10,$10,$0F,$0F,$12,$12
	db $12,$11,$11,$11,$10,$10,$0F,$0F

SpriteToSpawn:
	db $00,$01,$02,$03,$04,$05,$06,$07
	db $04,$04,$05,$05,$07,$00,$00,$0F
	db $0F,$0F,$0D

ChangingItemSprite:
	db $74,$75,$77,$76

;##################;
;# State Wrappers #;
;##################;

print "INIT ",pc
	DEC !160E,x								; set sprite in mouth index to have nothing
	INC !157C,x								; set horizontal direction

	LDA $0DC1|!addr							; \ load yoshi between levels flag
	BEQ +									; / if no yoshi, continue
	STZ !sprite_status,x					; if there is, yoshi already exists so we kill the newly spawned one

	+
	RTL

print "MAIN ",pc
	PHB : PHK : PLB							; \ main wrapper
	JSR YoshiMain							; |
	PLB										; /

	RTL

;################;
;# Main Routine #;
;################;

YoshiMain:
	STZ $13FB|!addr							; clear player locked flag
	LDA $141E|!addr							; \ load yoshi wings flag
	STA $1410|!addr							; / store it to a mirror, used for ???
	STZ $141E|!addr							; clear yoshi wings flag
	STZ $18E7|!addr							; clear yoshi stomp flag
	STZ $191B|!addr							; clear a byte of freeram (unused)

	LDA !sprite_status,x					; \ check if sprite status is in main (which we always should be...?)
	CMP #$08								; |
	BEQ +									; / if so, skip ahead

	; this seems to be unreachable?
	STZ $0DC1|!addr							; clear yoshi between levels flag
	JMP HandleOffYoshi

	+
	TXA										; \ store current slot (+1) to yoshi slot RAM
	INC										; |
	STA $18DF|!addr							; /
	LDA $187A|!addr							; \ load riding yoshi flag
	BNE ++									; / if riding, skip ahead
	%SubOffScreen()							; sub off screen
	LDA !sprite_status,x					; \ load sprite status
	BNE ++									; / if not free, skip ahead
	LDA $1B95|!addr							; \ load wings above screen animation flag
	BNE +									; / if set, return
	STZ $0DC1|!addr							; clear yoshi between levels flag

	+
	RTS

	++
	LDA $187A|!addr							; \ load riding yoshi flag
	BEQ +									; / if clear, skip ahead
	LDA $1419|!addr							; \ load yoshi in pipe pose
	BNE +++									; / if in pipe, skip ahead

	+
	LDA $18DE|!addr							; \ load egg delay timer
	BNE +++									; / if delaying, skip ahead
	LDA $18E8|!addr							; \ load grow animation timer
	BEQ ++									; / if clear, skip ahead
	DEC $18E8|!addr							; decrement grow animation timer
	STA $9D									; set sprites locked flag
	STA $13FB|!addr							; set player locked flag
	CMP #$01								; \ check if grow timer is basically done
	BNE +									; / if not, skip ahead
	STZ $9D									; clear sprites locked flag
	STZ $13FB|!addr							; clear player locked flag
	LDY $0DB3|!addr							; \ load current player ($00 = Mario, $01 = Luigi)
	LDA $1F11|!addr,y						; | load current submap based on player
	DEC										; | decrement it (looking for the Yoshi's Island submap)
	ORA $0EF8|!addr							; | or if yoshi has already been saved
	ORA $0109|!addr							; | or if overworld
	BNE +									; / if any of these are not right, skip ahead
	INC $0EF8|!addr							; set yoshi saved flag
	LDA #$03								; \ trigger yoshi thanks message
	STA $1426|!addr							; /

	+
	DEC
	LSR #3
	TAY
	LDA GrowingAniSequence,y				; \ set animation index
	STA !1602,x								; /
	RTS

	++
	LDA $9D									; \ load sprites locked flag
	BEQ +++									; / if clear, skip ahead

CODE_01EC50:
	LDY $187A|!addr							; \ load riding yoshi flag
	BEQ +									; / if clear, return
	LDY #$06								; \ set player image relative y position
	STY $188B|!addr							; /

	+
	RTS

	+++
	LDA $72									; \ load player in air state
	BNE YoshiStateTrampoline				; / if in air, skip ahead
	LDA $18DE|!addr							; \ load egg delay timer
	BNE +									; / if delaying, skip ahead

YoshiStateTrampoline:
	JMP HandleYoshiState

	+
	DEC $18DE|!addr							; decrement egg delay timer
	CMP #$01								; \ check if timer elapsed
	BNE +									; / if not, skip ahead
	STZ $9D									; clear sprites locked flag
	BRA YoshiStateTrampoline

	+
	INC $13FB|!addr							; set player locked flag
	JSR CODE_01EC50
	STY $9D									; set sprites locked flag
	CMP #$02
	BNE +
	JSL $02A9E4								; \ search for free sprite slot
	BPL FoundEggSlot						; / if found, skip ahead

	+
	RTS

FoundEggSlot:
	LDA #$09								; \ set spawned sprite status to stationary/carriable
	STA !sprite_status,y					; /
	LDA #$2C								; \ set spawned sprite number to egg
	STA !sprite_num,y						; /

	PHY										; \ set spawned sprite x position
	PHY										; |
	LDY !157C,x								; |
	STY $0F									; |
	LDA !sprite_x_low,x						; |
	CLC										; |
	ADC EggLayXOffsetsLow,y					; |
	PLY										; |
	STA !sprite_x_low,y						; |
	LDY !157C,x								; |
	LDA !sprite_x_high,x					; |
	ADC EggLayXOffsetsHigh,y				; |
	PLY										; |
	STA !sprite_x_high,y					; /

	LDA !sprite_y_low,x						; \ set spawned sprite y position
	CLC										; |
	ADC #$08								; |
	STA !sprite_y_low,y						; |
	LDA !sprite_y_high,x					; |
	ADC #$00								; |
	STA !sprite_y_high,y					; /

	PHX
	TYX
	JSL $07F7D2								; reset most sprite tables
	LDY $0F									; \ set spawned sprite x speed
	LDA EggLayXSpeeds,y						; |
	STA !sprite_speed_x,x					; /
	LDA #$F0								; \ set spawned sprite y speed
	STA !sprite_speed_y,x					; /
	LDA #$10								; \ set spawned sprite hatch timer
	STA !154C,x								; /
	LDA $18DA|!addr							; \ set spawned sprite to come out of egg
	STA !151C,x								; /
	PLX
	RTS

HandleYoshiState:
	LDA !C2,x								; \ load yoshi state
	CMP #$01								; | check if mounted
	BNE +									; / if not, skip ahead
	JMP HandleMounted						; handle mounted state

	+
	JSL $01802A								; update sprite x/y position with gravity
	JSR IsOnGround							; \ check if on ground
	BEQ +									; / if not, skip ahead
	JSR SetSomeYSpeed
	LDA !C2,x								; \ load yoshi state
	CMP #$02								; | check if running
	BCS +									; / if so, skip ahead
	STZ !sprite_speed_x,x					; clear x speed
	LDA #$F0								; \ set y speed
	STA !sprite_speed_y,x					; /

	+
	JSR UpdateDirection
	JSR IsTouchingObjSide					; \ if not touching a wall, don't flip speed and direction
	BEQ +									; |
	JSR InvertSpeedAndDirection				; /

	+
	LDA #$04								; \ get yoshi clipping
	CLC										; |
	ADC !sprite_x_low,x						; |
	STA $04									; |
	LDA !sprite_x_high,x					; |
	ADC #$00								; |
	STA $0A									; |
	LDA #$13								; |
	CLC										; |
	ADC !sprite_y_low,x						; |
	STA $05									; |
	LDA !sprite_y_high,x					; |
	ADC #$00								; |
	STA $0B									; |
	LDA #$08								; |
	STA $07									; |
	STA $06									; /

	JSL $03B664								; get player clipping
	JSL $03B72B								; \ check for interaction
	BCC HandleMounted						; / if no interaction, skip ahead
	LDA $72									; \ load player in air state
	BEQ HandleMounted						; / if on ground, skip ahead
	LDA $1470|!addr							; \ load carry flag
	ORA $187A|!addr							; | as well as the riding yoshi flag
	BNE HandleMounted						; / if either set, skip ahead
	LDA $7D									; \ load player y speed
	BMI HandleMounted						; / if ascending, skip ahead

SetOnYoshi:
	LDY #$01
	JSR MountPlayerLarge
	STZ $7B									; clear player x speed
	STZ $7D									; clear player y speed
	LDA #$0C								; \ set yoshi squat timer
	STA $18AF|!addr							; /
	LDA #$01								; \ set yoshi state to mounted
	STA !C2,x								; /
	LDA #$02								; \ play sound effect
	STA $1DFA|!addr							; /
	LDA #$1F								; \ play sound effect
	STA $1DFC|!addr							; /
	JSL $028BB0								; originally supposed to display smoke particles when mounted, but it ended up going unused
	LDA #$20								; \ disable sprite interaction
	STA !163E,x								; /
	INC $1697|!addr

HandleMounted:
	LDA !C2,x								; \ load yoshi state
	CMP #$01								; | check if mounted
	BNE ++									; / if not, return
	JSR CODE_01F622
	LDA $15									; \ load byetUDLR held controller data
	AND #$03								; | check bits 1/0 (L/R)
	BEQ +									; / if neither held, skip ahead
	DEC										; \ makes right = 0, left = 1
	CMP !157C,x								; | check against horizontal direction
	BEQ +									; / if already matching, skip ahead
	LDA !15AC,x								; \ load turnaround timer
	ORA !151C,x								; | include tongue distance
	ORA $18DC|!addr							; | include ducking on yoshi flag
	BNE +									; / if any are set, skip ahead
	LDA #$10								; \ set turnaround timer
	STA !15AC,x								; /

	+
	LDA $13F3|!addr							; \ if inflated by the pballoon, skip ahead
	BNE +									; /
	BIT $18									; \ check against axlr---- pressed controller data
	BPL ++									; / if bit 7 (a) isn't pressed, return

	+
	LDA #$02								; \ disable water splashes
	STA !1FE2,x								; /
	STZ !C2,x								; set yoshi state to idle
	LDA #$03								; \ play sound effect
	STA $1DFA|!addr							; /
	STZ $0DC1|!addr							; clear yoshi between levels flag
	LDA $7B									; \ load player x speed
	STA !sprite_speed_x,x					; / store it to yoshi x speed
	LDA #$A0
	LDY $72									; \ load player in air flag
	BNE +									; / if in air, skip ahead
	%SubHorzPos()
	LDA GroundedDismountXSpeeds,y			; \ set player x speed
	STA $7B									; /
	LDA #$C0

	+
	STA $7D									; set player y speed
	STZ $187A|!addr							; clear riding yoshi flag
	STZ !sprite_speed_y,x					; clear sprite y speed
	JSR MountPlayerSmall

	++
	RTS

MountPlayerSmall:
	LDY #$00

MountPlayerLarge:
	LDA !sprite_y_low,x						; \ set player position to be where yoshi is
	SEC										; |
	SBC PlayerMountYOffsets,y				; | but raised up a bit
	STA $96									; |
	STA $D3									; |
	LDA !sprite_y_high,x					; |
	SBC #$00								; |
	STA $97									; |
	STA $D4									; /
	RTS

HandleOffYoshi:
	LDA !1602,x								; load animation index
	PHA
	LDY !15AC,x								; \ check if turnaround timer is $08
	CPY #$08								; | if not, skip ahead
	BNE +									; /
	LDA $1419|!addr							; \ load yoshi in pipe pose
	ORA $9D									; | include sprites locked flag
	BNE +									; / if either set, skip ahead
	LDA !157C,x								; \ set player direction with current horizontal direction
	STA $76									; |
	EOR #$01								; | flip value
	STA !157C,x								; / store to horizontal direction

	+
	LDA $1419|!addr							; \ load yoshi in pipe pose
	BMI +									; | if set to not change the image, skip ahead
	CMP #$02								; | if set to face the screen, skip ahead
	BNE +									; /
	INC
	STA !1602,x								; set animation index

	+
	JSR Graphics							; do part of the graphics routine
	LDY $0E									; \ get the head OAM index
	LDA $0302|!addr,y						; |
	STA $00									; | set DMA reference low byte (tile num)
	STZ $01									; / clear high byte
	LDA #$06								; \ set head tile
	STA $0302|!addr,y						; /

	LDY !sprite_oam_index,x					; \ get the body OAM index
	LDA $0302|!addr,y						; |
	STA $02									; | set DMA reference low byte (tile num)
	STZ $03									; / clear high byte
	LDA #$08								; \ set body tile
	STA $0302|!addr,y						; /

	REP #$20
	LDA $00									; \ take the tile number
	ASL #5									; | do some math
	CLC										; |
	ADC #$8500								; |
	STA $0D8B|!addr							; | set yoshi's head top 8x16 row
	CLC										; |
	ADC #$0200|!addr						; | offset it by an 8 pixel wide row
	STA $0D95|!addr							; / set yoshi's head bottom 8x16 row

	LDA $02									; \ take the tile number
	ASL #5									; | do some math
	CLC										; |
	ADC #$8500								; |
	STA $0D8D|!addr							; | set yoshi's body top 8x16 row
	CLC										; |
	ADC #$0200|!addr						; | offset it by an 8 pixel wide row
	STA $0D97|!addr							; / set yoshi's body bottom 8x16 row
	SEP #$20

	PLA
	STA !1602,x								; set animation index
	JSR CODE_01F0A2
	LDA $1410|!addr							; \ load yoshi wings flag mirror
	CMP #$02								; |
	BCC +++									; / if it doesn't have wings, return
	LDA $187A|!addr							; \ load riding yoshi flag
	BEQ DrawYoshiWings						; / if clear, skip ahead
	LDA $72									; \ load player in air flag
	BNE ++									; / if in air, skip ahead
	LDA $7B									; \ load player x speed
	BPL +									; / if positive, skip ahead
	EOR #$FF								; \ flip value
	INC										; /

	+
	CMP #$28								; \ check if going $28 speed or faster
	LDA #$01								; | use #$01 as a wing index offset, assuming the player is moving fast enough
	BCS DrawYoshiWings						; | if so, skip ahead
	LDA #$00								; | if not, use #$00 since the player is too slow
	BRA DrawYoshiWings						; / skip ahead

	++
	LDA $14									; load effective frame counter
	LSR #2									; animate slower
	LDY $7D									; \ load player y speed
	BMI +									; / if ascending, skip ahead
	LSR #2									; animate even slower

	+
	AND #$01
	BNE DrawYoshiWings
	LDY #$21								; \ play sound effect
	STY $1DFC|!addr							; /

DrawYoshiWings:
	JSL $02BB23								; draw and animate yoshi's wings based on the given index in A

	+++
	RTS

Graphics:
	LDY !1602,x								; \ save animation index for later
	STY $185E|!addr							; /
	LDA YoshiHeadTiles,y					; \ set animation index
	STA !1602,x								; |
	STA $0F									; / and save it for later

	LDA !sprite_y_low,x						; \ offset yoshi's head y position
	PHA										; | save the body's y low position for later
	CLC										; |
	ADC YoshiPositionY,y					; |
	STA !sprite_y_low,x						; |
	LDA !sprite_y_high,x					; |
	PHA										; | save the body's y high position for later
	ADC #$00								; |
	STA !sprite_y_high,x					; /

	TYA
	LDY !157C,x
	BEQ +
	CLC
	ADC #$0D

	+
	TAY
	LDA !sprite_x_low,x						; \ offset yoshi's head x position
	PHA										; | save the body's x low position for later
	CLC										; |
	ADC YoshiHeadDispXLow,y					; |
	STA !sprite_x_low,x						; |
	LDA !sprite_x_high,x					; |
	PHA										; | save the body's x high position for later
	ADC YoshiHeadDispXHigh,y				; |
	STA !sprite_x_high,x					; /

	LDA !sprite_oam_index,x					; \ save oam index for later
	PHA										; /
	LDA !15AC,x								; \ load turnaround timer
	ORA $1419|!addr							; | include yoshi in pipe pose
	BEQ +									; / if either set, skip ahead
	LDA #$04								; \ set oam index for now
	STA !sprite_oam_index,x					; /

	+
	LDA !sprite_oam_index,x					; \ save oam index for later
	STA $0E									; /

	JSL $0190B2								; SubSprGfx2Entry1

	PHX										; save sprite index
	LDY !sprite_oam_index,x
	LDX $185E|!addr							; use animation index from earlier
	LDA $0301|!addr,y						; \ offset head's y position
	CLC										; |
	ADC YoshiHeadDispY,x					; |
	STA $0301|!addr,y						; /
	PLX										; get the old sprite index
	PLA										; \ get the old oam index
	CLC										; |
	ADC #$04								; | get next oam slot
	STA !sprite_oam_index,x					; / save it

	PLA										; \ restore body's x position
	STA !sprite_x_high,x					; |
	PLA										; |
	STA !sprite_x_low,x						; /
	LDY $185E|!addr
	LDA YoshiBodyTiles,y					; \ animation index
	STA !1602,x								; /

	LDA !sprite_y_low,x						; \ offset yoshi's y position
	CLC										; |
	ADC #$10								; |
	STA !sprite_y_low,x						; /
	BCC +									; \ offset high byte if necessary
	INC !sprite_y_high,x					; /

	+
	JSL $0190B2								; SubSprGfx2Entry1

	PLA										; \
	STA !sprite_y_high,x					; |
	PLA										; |
	STA !sprite_y_low,x						; /

	LDY $0E									; get OAM index back
	LDA $0F									; get animation index
	BPL +									; if valid (?), skip ahead
	LDA #$F0								; \ set OAM tile to be offscreen
	STA $0301|!addr,y						; /

	+
	LDA !C2,x								; \ load yoshi state
	BNE +									; / if not idle, skip ahead
	LDA $14									; \ load effective frame counter
	AND #$30								; | check bits 5/4
	BNE CODE_01EFDB							; / if either bit set, skip ahead
	LDA #$2A
	BRA CODE_01EFFA

	+
	CMP #$02
	BNE CODE_01EFDB
	LDA !151C,x								; \ load tongue distance
	ORA $13C6|!addr							; | include cutscene value?
	BNE CODE_01EFDB							; / if either set, skip ahead
	LDA $14									; \ load effective frame counter
	AND #$10								; | check bit 4
	BEQ CODE_01EFFD							; / if not set, skip ahead
	BRA CODE_01EFF8							; skip further ahead

Return01EFDA:
	RTS

CODE_01EFDB:
	LDA !1594,x								; \ check tongue subroutine
	CMP #$03								; |
	BEQ CODE_01EFEE							; / if spit, skip ahead
	LDA !151C,x								; \ load tongue distance
	BEQ CODE_01EFF3							; / if in mouth, skip ahead
	LDA $0302|!addr,y						; ok I can't anymore with this graphics routine, I'll continue commenting and labelling this sometime in the future when I make a customizable yoshi sprite
	CMP #$24
	BEQ CODE_01EFF3

CODE_01EFEE:
	LDA #$2A
	STA $0302|!addr,y

CODE_01EFF3:
	LDA $18AE|!addr							; \ load yoshi tongue delay
	BEQ CODE_01EFFD							; / if clear, skip ahead

CODE_01EFF8:
	LDA #$0C

CODE_01EFFA:
	STA $0302|!addr,y

CODE_01EFFD:
	LDA !1564,x
	LDY $18AC|!addr
	BEQ CODE_01F00F
	CPY #$26
	BCS CODE_01F038
	LDA $14									; \ load effective frame counter
	AND #$18								; | check bits 4/3
	BNE CODE_01F038							; / if either bit set, skip ahead

CODE_01F00F:
	LDA !1564,x
	CMP #$00
	BEQ Return01EFDA
	LDY #$00
	CMP #$0F
	BCC CODE_01F03A
	CMP #$1C
	BCC CODE_01F038
	BNE CODE_01F02F
	LDA $0E
	PHA
	JSL $02D1F3								; SetTreeTile (probably used for the berry eating?)
	JSR HandleEatingBerries
	PLA
	STA $0E

CODE_01F02F:
	INC $13FB|!addr							; set player locked flag
	LDA #$00
	LDY #$2A
	BRA CODE_01F03A

CODE_01F038:
	LDY #$04

CODE_01F03A:
	PHA
	TYA
	LDY $0E
	STA $0302|!addr,y
	PLA
	CMP #$0F
	BCS FinishGraphics
	CMP #$05
	BCC FinishGraphics
	SBC #$05
	LDY !157C,x								; \ check horizontal direction
	BEQ +
	CLC
	ADC #$0A

	+
	LDY !1602,x
	CPY #$0A
	BNE +
	CLC
	ADC #$14

	+
	STA $02									; / save for later

	JSR IsSprOffScreen
	BNE FinishGraphics
	LDA !sprite_x_low,x
	SEC
	SBC $1A
	STA $00
	LDA !sprite_y_low,x
	SEC
	SBC $1C
	STA $01
	PHX
	LDX $02
	LDA $00
	CLC
	ADC DATA_03C176,x
	STA $0300|!addr
	LDA $01
	CLC
	ADC DATA_03C19E,x
	STA $0301|!addr
	LDA #$3F
	STA $0302|!addr
	PLX
	LDY !sprite_oam_index,x
	LDA $0303|!addr,y
	ORA #$01
	STA $0303|!addr
	LDA #$00
	STA $0460|!addr

FinishGraphics:								; thank god we're done
	RTS

Return01F0A1:								; extra return here for some reason ???
	RTS

CODE_01F0A2:
	LDA !C2,x								; \ load yoshi state
	CMP #$01								; | check if mounted
	BNE +									; / if not, skip ahead
	JSL $02D0D4								; ???

	+
	LDA $1410|!addr							; \ load yoshi wings flag mirror
	CMP #$01								; | check if able to shoot fireballs while riding (unused)
	BEQ Return01F0A1						; / if so, return
	LDA $14A3|!addr							; \ load yoshi tongue stretch timer
	CMP #$10								; |
	BNE RunTongueCode						; / if not #$10, skip ahead
	LDA $18AE|!addr							; \ load yoshi tongue delay
	BNE RunTongueCode						; / if delaying, skip ahead
	LDA #$06								; \ set yoshi tongue delay
	STA $18AE|!addr							; /

RunTongueCode:
	LDA !1594,x								; \ run tongue subroutine
	JSL $0086DF								; /

TonguePointers:								; \ tongue subroutines
	dw TongueInactive						; | when yoshi isn't doing anything special
	dw TongueGoingOut						; | when yoshi gets punched
	dw TongueComingIn						; | when yoshi doesn't get anything OR tongued something to eat
	dw TongueSpit							; / when yoshi spits something out

HandleEatingBerries:
	LDA #$06								; \ play sound effect
	STA $1DF9|!addr							; /
	JSL $05B34A								; give player a single coin
	LDA $18D6|!addr							; \ load berry eaten type
	BEQ ReturnFromBerries					; / if coin, return
	STZ $18D6|!addr							; clear berry eaten type
	CMP #$01								; \ see if berry type is red
	BNE BerryNotRed							; / if not, skip ahead
	INC $18D4|!addr							; increment red berries counter
	LDA $18D4|!addr							; \ load red berries counter
	CMP #$0A								; | check if 10 eaten
	BNE ReturnFromBerries					; / if not, return
	STZ $18D4|!addr							; clear red berries counter
	LDA #$74								; load mushroom
	BRA ++

BerryNotRed:
	CMP #$03								; \ see if berry type is green
	BNE BerryNotGreen						; / if not, skip ahead
	LDA #$29								; \ play sound effect
	STA $1DFC|!addr							; /
	LDA $0F32|!addr							; \ load tens timer
	CLC										; |
	ADC #$02								; | add 2 (20 in game seconds)
	CMP #$0A								; | check if less than 10
	BCC +									; | if so, skip ahead
	SBC #$0A								; | subtract 10
	INC $0F31|!addr							; | increment the hundreds timer
	+										; |
	STA $0F32|!addr							; / store to tens timer
	BRA ReturnFromBerries					; branch to a return for some reason ???

BerryNotGreen:
	INC $18D5|!addr							; increment pink berries counter
	LDA $18D5|!addr							; \ load pink berries counter
	CMP #$02								; | check if 2 eaten
	BNE ReturnFromBerries					; / if not, return
	STZ $18D5|!addr							; clear pink berries counter
	LDA #$6A								; load coin game cloud

	++
	STA $18DA|!addr							; store to sprite number in egg
	LDY #$20								; \ set egg delay timer
	STY $18DE|!addr							; /

ReturnFromBerries:
	RTS

TongueSpit:
	LDA !1558,x								; \ load tongue timer
	BNE +									; / if not done, return
	STZ !1594,x								; set tongue subroutine

	+
	RTS

TongueInactive:
	LDA $1B95|!addr							; \ load wings above screen animation flag
	BEQ +									; / if clear, skip ahead
	LDA #$02								; \ set yoshi wings flag
	STA $141E|!addr							; /

	+
	LDA $18AC|!addr							; \ load swallow timer
	BEQ SkipYoshiAbility					; /
	LDY !160E,x								; load sprite in mouth index
	LDA !sprite_num,y						; \ load sprite in mouth number
	CMP #$80								; | check if key
	BNE +									; / if not, skip ahead
	INC $191C|!addr							; set key in mouth flag

	+
	CMP #$0D								; \ check if within the koopa sprite range
	BCS SkipYoshiAbility					; / if not, skip giving yoshi an ability
	PHY
	LDA !187B,y								; \ load disco shell flag
	CMP #$01								; |
	LDA #$03								; |
	BCS +									; / if set, skip ahead and set all abilities

	LDA !sprite_oam_properties,x			; \ load yoshi's color
	LSR										; |
	AND #$07								; |
	TAY										; | use as index
	LDA YoshiAbilityIndex,y					; |
	ASL #2									; |
	STA $00									; / store usable abilities to scratch
	PLY
	PHY
	LDA !sprite_oam_properties,y			; \ load sprite in mouth's color
	LSR										; |
	AND #$07								; |
	TAY										; | use as index
	LDA YoshiAbilityIndex,y					; |
	ORA $00									; | include yoshi color's existing abilities
	TAY										; | use as index
	LDA YoshiShellAbility,y					; /

	+
	PHA										; \ save all valid abilities
	AND #$02								; | bit 1 determines wings flag
	STA $141E|!addr							; / store to yoshi wings flag
	PLA										; \ get back valid abilities
	AND #$01								; | bit 0 determines stomp flag
	STA $18E7|!addr							; / set yoshi stomp flag
	PLY

SkipYoshiAbility:
	LDA $14									; \ load effective frame counter
	AND #$03								; | check bits 1/0
	BNE +									; / if either bit set, skip ahead
	LDA $18AC|!addr							; \ check swallow timer
	BEQ +									; | skip ahead if done
	DEC $18AC|!addr							; | decrement it
	BNE +									; / skip ahead if done (second edition)

	LDY !160E,x								; load sprite in mouth index
	LDA #$00								; \ kill sprite in mouth
	STA !sprite_status,y					; /
	DEC										; \ set sprite in mouth index to have nothing
	STA !160E,x								; /
	LDA #$1B								; \ set swallow animation timer
	STA !1564,x								; /
	JMP HandleEatingBerries

	+
	LDA $18AE|!addr							; \ load yoshi tongue delay
	BEQ +									; / if clear, skip ahead
	DEC $18AE|!addr							; \ decrement yoshi tongue delay
	BNE Return01F1DE						; / if still set, return
	INC !1594,x
	STZ !151C,x								; clear tongue distance
	LDA #$FF								; \ set sprite in mouth index to have nothing
	STA !160E,x								; /
	STZ !1564,x

Return01F1DE:
	RTS

	+
	LDA !C2,x								; \ load yoshi state
	CMP #$01								; | check if mounted
	BNE Return01F1DE						; / if not, return
	BIT $16									; \ check against byetUDLR pressed controller data
	BVC Return01F1DE						; / if bit 6 (y) isn't pressed, return
	LDA $18AC|!addr							; \ check swallow timer
	BNE +									; / skip ahead if still going
	JMP ExtendYoshiTongue

	+
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

	LDA #$00								; \ clear some stuff
	STA !C2,y								; |
	STA !sprite_being_eaten,y				; |
	STA !1626,y								; /

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
	STA !sprite_speed_x,y					; |
	LDA #$00								; | and the y speeds
	STA !sprite_speed_y,y					; |
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
	RTS

ShootFireball:
	JSR FindExtendedSpriteSlot				; find free extended sprite slot for the yoshi fireball

	LDA #$11								; \ set extended number to yoshi fireball
	STA !extended_num,y						; /
	LDA !sprite_x_low,x						; \ set fireball position to be where yoshi is
	STA !extended_x_low,y					; |
	LDA !sprite_x_high,x					; |
	STA !extended_x_high,y					; |
	LDA !sprite_y_low,x						; |
	STA !extended_y_low,y					; |
	LDA !sprite_y_high,x					; |
	STA !extended_y_high,y					; /
	LDA #$00								; \ set fireballs to be in front of layers
	STA !extended_behind,y					; /
	PHX
	LDA !157C,x								; load horizontal direction
	LSR
	LDX $00									; load fireball speeds index
	LDA FireballXSpeeds,x					; \ load fireball x speeds
	BCC +									; /
	EOR #$FF								; \ flip value
	INC										; /

	+
	STA !extended_x_speed,y					; set fireball x speed
	LDA FireballYSpeeds,x					; \ set fireball y speed
	STA !extended_y_speed,y					; /
	LDA #$A0								; \ set extended timer
	STA !extended_timer,y					; /
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
	LDX !sprite_num,y						; \ spawn a new sprite
	LDA SpriteToSpawn,x						; |
	PLX										; |
	STA !sprite_num,y						; /
	PHX
	TYX
	JSL $07F7A0								; initialize the six tweaker bytes
	PLX

	+
	RTS

ExtendYoshiTongue:
	LDA #$12								; \ set yoshi tongue stretch timer
	STA $14A3|!addr							; /
	LDA #$21								; \ play sound effect
	STA $1DFC|!addr							; /
	RTS

TongueGoingOut:
	LDA !151C,x								; \ increment tongue distance
	CLC										; |
	ADC #$03								; |
	STA !151C,x								; /
	CMP #$20
	BCS +

CODE_01F321:
	JSR CODE_01F3FE
	JSR CODE_01F4B2
	RTS

	+
	LDA #$08								; \ set tongue timer
	STA !1558,x								; /
	INC !1594,x								; set tongue subroutine
	BRA CODE_01F321

TongueComingIn:
	LDA !1558,x								; \ load tongue timer
	BNE CODE_01F321							; / if not done, skip ahead
	LDA !151C,x								; \ decrement tongue distance
	SEC										; |
	SBC #$04								; |
	BMI +									; | if it finishes, skip ahead
	STA !151C,x								; /
	BRA CODE_01F321

	+
	STZ !151C,x								; clear tongue distance
	STZ !1594,x								; clear tongue subroutine
	LDY !160E,x								; \ load sprite in mouth index
	BMI +									; / if no sprite in mouth, skip ahead
	
	LDA !sprite_tweaker_1686,y
	AND #$02
	BEQ ++
	LDA #$07								; \ set sprite in mouth to be... in mouth
	STA !sprite_status,y					; /
	LDA #$FF
	STA $18AC|!addr
	LDA !sprite_num,y						; \ load sprite in mouth number
	CMP #$0D								; | check if greater than or equal to #$0D
	BCS +									; / if so, skip ahead
	PHX
	TAX
	LDA SpriteToSpawn,x						; \ set ???
	STA !sprite_num,y						; /
	PLX

	+
	JMP CODE_01F3FA

	++
	LDA #$00								; \ set ???
	STA !sprite_status,y					; /
	LDA #$1B
	STA !1564,x
	LDA #$FF								; \ set sprite in mouth index to have nothing
	STA !160E,x								; /
	STY $00
	LDA !sprite_num,y						; \ load sprite in mouth number
	CMP #$9D								; | check if bubble
	BNE CODE_01F39F							; / if not, skip ahead
	LDA !C2,y								; \ load sprite in bubble number
	CMP #$03								; | check if mushroom
	BNE CODE_01F39F							; / if not, skip ahead
	LDA #$74								; \ set sprite in mouth to be a mushroom
	STA !sprite_num,y						; /
	LDA !sprite_tweaker_167a,y
	ORA #$40
	STA !sprite_tweaker_167a,y

CODE_01F39F:
	LDA !sprite_num,y						; \ load sprite in mouth number
	CMP #$81								; | check if changing item from roulette box
	BNE CODE_01F3BA							; / if not, skip ahead
	LDA !187B,y
	LSR #6
	AND #$03
	TAY
	LDA ChangingItemSprite,y
	LDY $00									; \ set ???
	STA !sprite_num,y						; /

CODE_01F3BA:
	PHA
	LDY $00
	LDA !sprite_tweaker_167a,y
	ASL #2
	PLA
	BCC CODE_01F3DB
	PHX
	TYX
	STZ !C2,x								; set yoshi state to idle

	PHK										; \ JSL2RTS $01C4BF
	PEA.w (+)-1								; |
	PEA.w $0180CA-1							; |
	JML $01C4BF								; |
	+										; /

	PLX
	LDY $18DC|!addr							; \ load ducking on yoshi flag as index
	LDA YoshiDuckPoses,y					; | set ducking (or not) pose
	STA !1602,x								; /
	JMP CODE_01F321

CODE_01F3DB:
	CMP #$7E
	BNE CODE_01F3F7
	LDA !C2,y
	BEQ CODE_01F3F7
	CMP #$02
	BNE ADDR_01F3F1
	LDA #$08								; \ set pose to shooting into the sky
	STA $71									; /
	LDA #$03								; \ play sound effect
	STA $1DFC|!addr							; /

ADDR_01F3F1:
	JSR CODE_01F6CD
	JMP CODE_01F321

CODE_01F3F7:
	JSR HandleEatingBerries

CODE_01F3FA:
	JMP CODE_01F321

Return01F3FD:
	RTS

CODE_01F3FE:
	LDA !sprite_off_screen_horz,x			; \ check horizontal offscreen flag
	ORA !sprite_off_screen_vert,x			; | and the vertical offscreen flag
	ORA $1419|!addr							; | and the yoshi in pipe pose
	BNE Return01F3FD						; / if any set, return
	
	LDY !1602,x								; \ get animation index
	LDA TongueYOffsets,y						; | use to get the tongue y postion offset
	STA $185E|!addr							; / save it for later
	CLC
	ADC !sprite_y_low,x
	SEC
	SBC $1C
	STA $01
	LDA !157C,x
	BNE +
	TYA										; \ offset index by $08
	CLC										; |
	ADC #$08								; |
	TAY										; /

	+
	LDA DATA_01F60A,y
	STA $0D
	LDA !sprite_x_low,x
	SEC
	SBC $1A
	CLC
	ADC $0D
	STA $00
	LDA !157C,x
	BNE CODE_01F43C
	BCS Return01F3FD
	BRA CODE_01F43E

CODE_01F43C:
	BCC Return01F3FD

CODE_01F43E:
	if !SA1
		LDA #$01
		STA $2250
		LDA !151C,x							; load tongue distance
		STA $2252
		STZ $2251
		LDA #$04
		STA $2253
		LDA !157C,x
		STA $07
		LSR
		LDA $2307
	else
		LDA !151C,x							; load tongue distance
		STA $4205
		STZ $4204
		LDA #$04
		STA $4206
		NOP #8
		LDA !157C,x
		STA $07
		LSR
		LDA $4215
	endif
	
	BCC CODE_01F462
	EOR #$FF								; \ flip value
	INC										; /

CODE_01F462:
	STA $05
	LDA #$04
	STA $06
	LDY #$0C

CODE_01F46A:
	LDA $00
	STA $0200|!addr,y
	CLC
	ADC $05
	STA $00
	LDA $05
	BPL CODE_01F47C
	BCC Return01F4B1
	BRA CODE_01F47E

CODE_01F47C:
	BCS Return01F4B1

CODE_01F47E:
	LDA $01
	STA $0201|!addr,y
	LDA $06
	CMP #$01
	LDA #$76
	BCS CODE_01F48D
	LDA #$66

CODE_01F48D:
	STA $0202|!addr,y
	LDA $07
	LSR
	LDA #$09
	BCS CODE_01F499
	ORA #$40

CODE_01F499:
	ORA $64
	STA $0203|!addr,y
	PHY
	TYA
	LSR #2
	TAY
	LDA #$00
	STA $0420|!addr,y
	PLY
	INY #4
	DEC $06
	BPL CODE_01F46A

Return01F4B1:
	RTS

CODE_01F4B2:
	LDA !160E,x								; \ load sprite in mouth index
	BMI CODE_01F524							; / if no sprite in mouth, skip ahead
	LDY #$00
	LDA $0D
	BMI CODE_01F4C3
	CLC
	ADC !151C,x
	BRA CODE_01F4CC

CODE_01F4C3:
	LDA !151C,x								; load tongue distance
	EOR #$FF								; \ flip value
	INC										; /
	CLC
	ADC $0D

CODE_01F4CC:
	SEC
	SBC #$04
	BPL CODE_01F4D2
	DEY

CODE_01F4D2:
	PHY
	CLC
	ADC !sprite_x_low,x
	LDY !160E,x								; load sprite in mouth index
	STA !sprite_x_low,y
	PLY
	TYA
	ADC !sprite_x_high,x
	LDY !160E,x								; load sprite in mouth index
	STA !sprite_x_high,y
	LDA #$FC
	STA $00
	LDA !sprite_tweaker_1662,y
	AND #$40
	BNE CODE_01F4FD
	LDA !sprite_tweaker_190f,y
	AND #$20
	BEQ CODE_01F4FD
	LDA #$F8
	STA $00

CODE_01F4FD:
	STZ $01
	LDA $00
	CLC
	ADC $185E|!addr
	BPL CODE_01F509
	DEC $01

CODE_01F509:
	CLC
	ADC !sprite_y_low,x
	STA !sprite_y_low,y
	LDA !sprite_y_high,x
	ADC $01
	STA !sprite_y_high,y
	LDA #$00
	STA !sprite_speed_y,y
	STA !sprite_speed_x,y
	INC
	STA !sprite_being_eaten,y
	RTS

CODE_01F524:
	PHY
	LDY #$00
	LDA $0D
	BMI CODE_01F531
	CLC
	ADC !151C,x
	BRA CODE_01F53A

CODE_01F531:
	LDA !151C,x								; load tongue distance
	EOR #$FF								; \ flip value
	INC										; /
	CLC
	ADC $0D

CODE_01F53A:
	CLC
	ADC #$00
	BPL CODE_01F540
	DEY

CODE_01F540:
	CLC
	ADC !sprite_x_low,x
	STA $00
	TYA
	ADC !sprite_x_high,x
	STA $08
	PLY
	LDA $185E|!addr
	CLC
	ADC #$02
	CLC
	ADC !sprite_y_low,x
	STA $01
	LDA !sprite_y_high,x
	ADC #$00
	STA $09
	LDA #$08
	STA $02
	LDA #$04
	STA $03
	LDY #!SprSize-1

CODE_01F568:
	STY $1695|!addr
	CPY $15E9|!addr
	BEQ CODE_01F586
	LDA !160E,x								; \ load sprite in mouth index
	BPL CODE_01F586							; / if sprite in mouth, skip ahead
	LDA !sprite_status,y
	CMP #$08
	BCC CODE_01F586
	LDA !sprite_behind_scenery,y
	BNE CODE_01F586
	PHY
	JSR TryEatSprite
	PLY

CODE_01F586:
	DEY
	BPL CODE_01F568
	JSL $02B9FA								; ???
	RTS

TryEatSprite:
	PHX
	TYX
	JSL $03B69F								; get sprite clipping A
	PLX
	JSL $03B72B								; \ check for interaction
	BCC Return01F609						; / if no interaction, return
	LDA !sprite_tweaker_1686,y
	LSR
	BCC EatSprite
	LDA #$01								; \ play sound effect
	STA $1DF9|!addr							; /
	RTS

EatSprite:
	LDA !sprite_num,y						; \ load sprite in mouth number
	CMP #$70								; | check if pokey
	BNE CODE_01F5FB							; / if not, skip ahead

SpltPokeyInto2Sprs:
	STY $185E|!addr
	LDA $01
	SEC
	SBC !sprite_y_low,y
	CLC
	ADC #$00
	PHX
	TYX
	JSL $02B81C								; remove pokey segment
	PLX
	JSL $02A9E4								; \ search for free sprite slot
	BMI Return01F609						; / if not found, skip ahead
	LDA #$08								; \ set spawned sprite status to main
	STA !sprite_status,y					; /
	LDA #$70								; \ set spawned sprite number to pokey
	STA !sprite_num,y						; /
	LDA $00
	STA !sprite_x_low,y
	LDA $08
	STA !sprite_x_high,y
	LDA $01
	STA !sprite_y_low,y
	LDA $09
	STA !sprite_y_high,y
	PHX
	TYX
	JSL $07F7D2								; reset most sprite tables
	LDX $185E|!addr
	LDA !C2,x
	AND $0D
	STA !C2,y
	LDA #$01
	STA !1534,y
	PLX

CODE_01F5FB:
	TYA
	STA !160E,x
	LDA #$02
	STA !1594,x
	LDA #$0A
	STA !1558,x

Return01F609:
	RTS

CODE_01F622:
	LDA !163E,x
	ORA $9D									; | include sprites locked flag
	BNE Return01F667
	LDY #!SprSize-1

CODE_01F62B:
	STY $1695|!addr
	TYA
	EOR $13									; | flip with the true frame counter
	AND #$01
	BNE CODE_01F661
	TYA
	CMP !160E,x
	BEQ CODE_01F661
	CPY $15E9|!addr
	BEQ CODE_01F661
	LDA !sprite_status,y
	CMP #$08
	BCC CODE_01F661
	LDA !sprite_num,y						; load ???
	LDA !sprite_status,y					; just kidding actually load ???
	CMP #$09
	BEQ CODE_01F661
	LDA !sprite_tweaker_167a,y
	AND #$02
	ORA !sprite_being_eaten,y
	ORA !sprite_behind_scenery,y
	BNE CODE_01F661
	JSR CODE_01F668

CODE_01F661:
	LDY $1695|!addr
	DEY
	BPL CODE_01F62B

Return01F667:
	RTS

CODE_01F668:
	PHX
	TYX
	JSL $03B6E5								; get sprite clipping B
	PLX
	JSL $03B69F								; get sprite clipping A
	JSL $03B72B								; \ check for interaction
	BCC Return01F667						; / if no interaction, return
	LDA !sprite_num,y						; \ load ???
	CMP #$9D								; | check if bubble
	BEQ Return01F667						; | if so, return
	CMP #$15								; | check if horizontal fish
	BEQ CODE_01F69E							; | if so, skip ahead
	CMP #$16								; | check if vertical fish
	BEQ CODE_01F69E							; | if so, skip ahead
	CMP #$04								; | check if greater than or equal to #$04
	BCS CODE_01F6A3							; | if so, skip ahead
	CMP #$02								; | check if blue koopa, no shell
	BEQ CODE_01F6A3							; / if so, skip ahead
	LDA !163E,y
	BPL CODE_01F6A3

CODE_01F695:
	PHY
	PHX
	TYX

	PHK										; \ JSL2RTS CODE_01B12A
	PEA.w (+)-1								; |
	PEA.w $0180CA-1							; |
	JML $01B12A								; |
	+										; /

	PLX
	PLY
	RTS

CODE_01F69E:
	LDA !sprite_in_water,y
	BEQ CODE_01F695

CODE_01F6A3:
	LDA !sprite_num,y						; \ load ???
	CMP #$BF								; | check if mega mole
	BNE CODE_01F6B4							; / if not, skip ahead
	LDA $96
	SEC
	SBC !sprite_y_low,y
	CMP #$E8
	BMI Return01F6DC

CODE_01F6B4:
	LDA !sprite_num,y						; \ load ???
	CMP #$7E								; | check if flying red coin
	BNE CODE_01F6DD							; / if not, skip ahead
	LDA !C2,y
	BEQ Return01F6DC
	CMP #$02
	BNE CODE_01F6CD
	LDA #$08								; \ set pose to shooting into the sky
	STA $71									; /
	LDA #$03								; \ play sound effect
	STA $1DFC|!addr							; /

CODE_01F6CD:
	LDA #$40
	STA $14AA|!addr
	LDA #$02								; \ set yoshi wings flag
	STA $141E|!addr							; /
	LDA #$00								; \ set ???
	STA !sprite_status,y					; /

Return01F6DC:
	RTS

CODE_01F6DD:
	CMP #$4E
	BEQ CODE_01F6E5
	CMP #$4D
	BNE CODE_01F6EC

CODE_01F6E5:
	LDA !C2,y
	CMP #$02
	BCC Return01F6DC

CODE_01F6EC:
	LDA $05
	CLC
	ADC #$0D
	CMP $01
	BMI Return01F74B
	LDA !sprite_status,y
	CMP #$0A
	BNE CODE_01F70E
	PHX
	TYX
	%SubHorzPos()
	STY $00
	LDA !sprite_speed_x,x
	PLX
	ASL
	ROL
	AND #$01
	CMP $00
	BNE Return01F74B

CODE_01F70E:
	LDA $1490|!addr							; \ load star timer
	BNE Return01F74B						; / if set, return
	LDA #$10
	STA !163E,x
	LDA #$03								; \ play sound effect
	STA $1DFA|!addr							; /
	LDA #$13								; \ play sound effect
	STA $1DFC|!addr							; /
	LDA #$02								; \ set yoshi state to running
	STA !C2,x								; /
	STZ $187A|!addr							; clear riding yoshi flag
	LDA #$C0								; \ set player y speed
	STA $7D									; /
	STZ $7B									; clear player x speed
	%SubHorzPos()
	LDA LoseYoshiXSpeeds,y
	STA !sprite_speed_x,x
	STZ !1594,x
	STZ !151C,x								; clear tongue distance
	STZ $18AE|!addr							; clear yoshi tongue delay
	STZ $0DC1|!addr							; clear yoshi between levels flag
	LDA #$30								; \ set flashing invulnerability timer
	STA $1497|!addr							; /
	JSR MountPlayerSmall

Return01F74B:
	RTS

CODE_01F74C:
	LDA #$08								; \ set ???
	STA !sprite_status,x					; /
	LDA #$20
	STA !1540,x
	LDA #$0A								; \ play sound effect
	STA $1DFC|!addr							; /
	RTS

;##########################;
;# SMW's Suboutines (JSR) #;
;##########################;

FindExtendedSpriteSlot:
	LDY #$07

	-
	LDA !extended_num,y
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

IsOnGround:
	LDA !sprite_blocked_status,x			; \ check if touching the ground
	AND #$04								; /
	RTS

IsSprOffScreen:
	LDA !sprite_off_screen_horz,x			; \ load horizontal offscreen flag
	ORA !sprite_off_screen_vert,x			; / include vertical offscreen flag
	RTS

IsTouchingObjSide:
	LDA !sprite_blocked_status,x			; \ check if touching sides
	AND #$03								; /
	RTS

InvertSpeedAndDirection:
	LDA !sprite_speed_x,x					; \ flip sprite x speed
	EOR #$FF								; |
	INC										; |
	STA !sprite_speed_x,x					; /
	LDA !157C,x								; \ flip horizontal direction
	EOR #$01								; |
	STA !157C,x								; /
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
	LDY !sprite_speed_x,x
	BEQ ++
	BPL +
	INC
	+
	STA !157C,x
	++
	RTS
