;####################################;
;# Celeste Feather by MiniMawile303 #;
;####################################;

;##########################;
;# Global Celeste Defines #;
;##########################;

	!dashCount = $18C5
	!dashTimer = $18C6
	!directionStore = $18C7

	!dashSettings = $18CA

;#################################;
;# Variable and Table Initiation #;
;#################################;

fishTiles:
	db $04,$06,$08
	
!fishProps = %00111101

outlineXDisps:
	db $20,$20,$10,$00
	db $E0,$E0,$F0,$00
	
outlineYDisps:
	db $00,$10,$20,$20		; y disps and tiles are duplicated to save processing cost. its only 8 extra bytes here lol.
	db $00,$10,$20,$20
	
outlineTiles:
	db $48,$4A,$68,$6A
	db $48,$4A,$68,$6A
	
outlineProps:
	db %01111101,%01111101,%01111101,%01111101
	db %00111101,%00111101,%00111101,%00111101
	
outlineStarts:
	db $03,$07
	
outlineEnds:
	db $00,$04
	
!stateTable = $C2

!ySpeed = $40

!bounceSFX = $0E
!bounceChannel = $1DF9

launchXSpeeds:
	db $60,$A0
	
xSpeedCompares:
	db $20,$E0


;#####################;
;# Begin Actual Code #;
;#####################;

print "INIT ",pc
	RTL

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR SpriteCode
	PLB
	RTL

	SpriteCode:
		LDX $15E9
		
		JSR Graphics
		LDA #$01
		%SubOffScreen()
		
		LDA $14C8,x		; \
		CMP #$08		; | if the sprite is dead or not it it's normal state, return.
		BMI ReturnSC	; /

		LDA $9D			; \
		BNE ReturnSC	; / if game is paused, return.
		
		JSR FloatyX
		JSR LowGravity
		JSR SpeedPhysics
		JSR MarioInteraction
		
		ReturnSC:
		RTS
		
	FloatyX:
		LDA $B6,x
		BEQ ReturnFX
		BPL Right
			INC $B6,x
			RTS
			
		Right:
			DEC $B6,x

		ReturnFX:
		RTS
		
	LowGravity:
		LDA $AA,x
		BEQ +
		CMP #$80
		BPL +
		DEC $AA,x
		DEC $AA,x
		RTS
		
		+
		RTS
		
	SpeedPhysics:
		LDA $AA,x
		CMP #$80
		BPL +
		JSL $01801A
		JSL $018022
		RTS
		
		+
		JSL $01802A
		RTS
		
	ReturnMI:
		RTS
		
	MarioInteraction:
		JSL $03B69F						; \ get all the sprite clipping info, loads in a custom hitbox.
		LDA #$2C						; |
		STA $07
		
		LDA $0A
		XBA
		LDA $04
		REP #$20
		CLC : ADC #$FFE4
		SEP #$20
		STA $04
		XBA
		STA $0A
		
		LDA #$48						; |
		STA $06							; /
		
		JSL $03B664						; get player hitbox info.

		JSL $03B72B						; \ check if colliding. if not, return.
		BCC ReturnMI					; /
		
		%SubVertPos()
		LDA $0F							; \ 
		CMP #$F0						; |
		BPL ExplodeFish					; /
		
		; bounce off the pufferfish head normally.
		
			%SubHorzPos()
			LDA $0E
			CMP #$F2
			BMI ExplodeFish
			CMP #$0E
			BPL ExplodeFish
			
			STZ $00
			STZ $01
			LDA #$0A
			STA $02
			LDA #$01
			%SpawnSmoke()
			
			LDA $7D
			BMI ReturnMI
			
			JSL $01AA33
			
			LDA #!ySpeed
			STA $AA,x
			
			LDA !dashSettings		; \ reset dash counter.
			AND #$80
			BNE +

			LDA !dashSettings
			AND #$03
			CMP !dashCount
			BMI +

			STA !dashCount
			
			+
			
			LDA #!bounceSFX
			STA !bounceChannel
			
			RTS
			
		; pufferfish explodes lol
		
		ExplodeFish:
			%SubHorzPos()
			PHX
			TYX
			
			LDA #$00
			STA !dashTimer
			
			LDA #$0A
			STA $02
			LDA #$02
			%SpawnSmoke()
			CPY #$FF
			BEQ +
			LDA $94
			STA $17C8,y
			LDA $96
			CLC : ADC #$08
			STA $17C4,y
			
			
			+
			LDA launchXSpeeds,x
			STA $7B
			LDA #$C0
			STA $7D
			
			LDA !dashSettings
			AND #$80
			BNE +
			LDA !dashSettings
			AND #$03
			STA !dashCount		
			+
			PLX
			
			LDA #$0D                ; Turn sprite into a Bob-omb
			STA $9E,x
			LDA #$08                ; Sprite is alive
			STA $14C8,x
			JSL $07F7D2			    ; Reload sprite tables
			LDA #$01                ; Explode immediately
			STA $1534,x
			LDA #$40
			STA $1540,x
			LDA #$09                ; Play explosion SFX
			STA $1DFC

			RTS
		
	Graphics:
		%GetDrawInfo()

		LDA $00
		STA $0300,y
		LDA $01
		STA $0301,y
		
		;;;;;;;;;;;;;;; get needed fish tile here
		
		LDA #$06
		STA $0302,y
		
		;;;;;;;;;;;;;;
		
		LDA #!fishProps
		STA $0303,y
		
		INY #4
		
		STY $06

		%SubHorzPos()
		TYX
		LDA outlineEnds,x
		STA $07
		LDA outlineStarts,x
		TAX
		
		LDY $06
		OutlineLoop:
		
		LDA $00
		CLC : ADC outlineXDisps,x
		STA $0300,y
		LDA $01
		CLC : ADC outlineYDisps,x
		STA $0301,y

		LDA outlineTiles,x
		STA $0302,y
		LDA outlineProps,x
		STA $0303,y
		
		INY #4
		DEX
		CPX $07
		BPL OutlineLoop
		
		LDX $15E9
		LDY #$02
		LDA #$04
		JSL $01B7B3		
		
		RTS
		
		
		
		
		
		
		
		
		
		
