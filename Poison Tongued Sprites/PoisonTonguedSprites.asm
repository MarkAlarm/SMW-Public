;##############################;
;# Poison Tongued Sprites     #;
;# By MarkAlarm               #;
;# Please give credit if used #;
;##############################;

;###########;
;# Options #;
;###########;

; note that the poison effect remains for as long as the sprite is in yoshis mouth
; though for hurt/kill, the player must be riding yoshi for the effect to take place

; $00 = not poisoned, eat freely
; $01 = yoshi runs away if eaten
; $02 = yoshi dies if eaten (poofs away)
; $03 = yoshi shrinks into baby yoshi
; $04 = hurt the player if eaten
; $05 = kill the player if eaten

vanillaPoisonSprites:														; just check LM for the sprite number you need, then locate it in this table
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $00-$0F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $10-$1F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $20-$2F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $30-$3F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $40-$4F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $50-$5F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $60-$6F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $70-$7F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $80-$8F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $90-$9F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $A0-$AF
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; vanilla sprites $B0-$BF
	db $00,$00,$00,$00,$00,$00,$00,$00										; vanilla sprites $C0-$C8
	
customPoisonSprites:														; this is based on your pixi's list.txt file
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $00-$0F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $10-$1F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $20-$2F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $30-$3F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $40-$4F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $50-$5F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $60-$6F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $70-$7F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $80-$8F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $90-$9F
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		; custom sprites $A0-$AF
	
LoseYoshiXSpeeds:															; \ x speed to give yoshi when he runs away. uses the vanilla values
	db $E8,$18																; / left, right
	
poisonSubroutines:
	dw NoEffect																; $00
	dw YoshiRuns															; $01
	dw YoshiDies															; $02
	dw YoshiShrinks															; $03
	dw HurtPlayer															; $04
	dw KillPlayer															; $05
	; theoretically you could add your own custom routines down here, assuming you know what you're doing

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
	STX $00
	
	LDY !160E,x								; \ check if there's a sprite in yoshi's mouth
	BMI ++									; / if not, finish
	
	PHB : PHK : PLB							; bank wrapper for tables
	
	TYX										; \ check if the tongued sprite is custom
	LDA !extra_bits,x						; |
	AND #$08								; |
	BEQ +									; / if not, skip ahead
	
	LDA !new_sprite_num,x					; \ get custom sprite number
	TAX										; |
	LDA customPoisonSprites,x				; | use it to index the poison subroutine table
	ASL										; |
	TAX										; |
	JSR (poisonSubroutines,x)				; / run corresponding subroutine
	
	PLB
	RTL
	
	+
	LDA !sprite_num,x						; \ get vanilla sprite number
	TAX										; |
	LDA vanillaPoisonSprites,x				; | use it to index the poison subroutine table
	ASL										; |
	TAX										; |
	JSR (poisonSubroutines,x)				; / run corresponding subroutine
	
	PLB
	++
	RTL
	
;######################;
;# Poison Subroutines #;
;######################;
	
NoEffect:
	RTS
	
YoshiRuns:
	LDX $00									; this code is just taken from the yoshi disassembly
	
	LDA #$03								; \ play sound effect
	STA $1DFA|!addr							; /
	LDA #$13								; \ play sound effect
	STA $1DFC|!addr							; /
	LDA #$02								; \ set yoshi state to running
	STA !C2,x								; /
	STZ $187A|!addr							; clear riding yoshi flag
	
	LDA #$F0								; \ set player y speed
	STA $7D									; /
	STZ $7B									; clear player x speed
	JSR SubHorzPos							; thanks pixi
	LDA LoseYoshiXSpeeds,y					; \ make yoshi run away
	STA !sprite_speed_x,x					; /
	RTS
	
YoshiDies:
	LDX $00
	
	STZ !sprite_status,x					; kill self
	LDA #$FF								; \ no sprite in mouth
	STA !160E,x								; /
	
	LDA #$08								; \ play sound effect
	STA $1DF9|!addr							; /
	
	LDY #$03								; \ loop to find a free smoke slot
	-										; |
	LDA $17C0|!addr,y						; |
	BEQ +									; |
	DEY										; |
	BPL -									; |
	BRA ++									; / skip ahead if none found
	
	+
	LDA #$01								; \ set smoke type
	STA $17C0|!addr,y						; |
	LDA !sprite_y_low,x						; | set smoke y position with offset
	CLC : ADC #$10							; |
	STA $17C4|!addr,y						; |
	LDA !sprite_x_low,x						; | set smoke x position
	STA $17C8|!addr,y						; |
	LDA #$1B								; | set smoke timer
	STA $17CC|!addr,y						; /
	
	++
	JSL $07FC3B
	
	RTS
	
YoshiShrinks:
	LDX $00
	LDA #$2D								; \ become baby yoshi
	STA !sprite_num,x						; |
	JSL $07F7D2								; /
	
	LDA #$09								; \ set to be carriable
	STA !sprite_status,x					; /
	
	RTS
	
HurtPlayer:
	LDX $00
	LDA !C2,x								; \ only hurt if riding yoshi
	CMP #$01								; |
	BNE +									; /
	JSL $00F5B7								; hurt
	+
	RTS
	
KillPlayer:
	LDX $00
	LDA !C2,x								; \ only hurt if riding yoshi
	CMP #$01								; |
	BNE +									; /
	JSL $00F606								; kill
	+
	RTS
	
SubHorzPos:									; pixi lol
	LDY #$00
	LDA $94
	SEC
	SBC !E4,x
	STA $0E
	LDA $95
	SBC !14E0,x
	STA $0F
	BPL +
	INY
	+
	RTS
