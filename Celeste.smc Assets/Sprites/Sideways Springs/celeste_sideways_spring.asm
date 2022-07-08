;###################################;
;# Celeste Spring by MiniMawile303 #;
;###################################;

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

	xDisplacement:
		db $00,$00,$08,$08,$00,$00		; for these graphics tables, first row is right, second row is left.
		db $08,$08,$00,$00,$08,$08		; first values 2 are retracted, last 4 are full.
		
	yDisplacement:
		db $00,$08,$00,$08,$00,$08
		db $00,$08,$00,$08,$00,$08
		
	tiles:
		db $81,$81,$81,$81,$91,$91
		db $81,$81,$81,$81,$91,$91
		
	yxppccct:
		db %01110000,%11110000,%01110000,%11110000,%01110000,%11110000
		db %00110000,%10110000,%00110000,%10110000,%00110000,%10110000
	
	marioLaunchX:
		db $50,$B0		; for these launch tables, first is right, second is left.
		
	spriteLaunchX:
		db $40,$C0
		
	!marioLaunchY = $B0		; Y speed to launch mario with.
	!spriteLaunchY = $C0	; Y speed to launch sprites with.
	!thwompLaunchY = $E0	; Y speed to launch thwomps with.
		

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
	
		LDA $14C8,x			; \
		CMP #$08			; | if the sprite is dead or not it it's normal state, return.
		BNE SkipToGFX		; /

		LDA $9D				; \
		BNE SkipToGFX		; / if game is paused, return.
		
		JSR MarioInteraction
		JSR SpriteInteraction
		LDX $15E9
		
		SkipToGFX:
		
		JSR Graphics
		%SubOffScreen()
		
		RTS

	Graphics:
		%GetDrawInfo()
		
		LDX $15E9

		LDA $1540,x
		BEQ retractedSetup
		BNE fullSetup
		
		retractedSetup:
			LDX #$01
			PHX
			
			LDA #$01				; only have to draw 2 tiles if it's retracted.
			STA $04					; using $04 as a counter for the number of tiles drawn.
			
			LDA #$00
			STA $05					; using $05 as a comparison for the graphics loop.
			
			BRA nowDoDirection
			
		fullSetup:
			LDX #$05
			PHX
			
			LDA #$03				; 4 tiles for the full spring.
			STA $04
			
			LDA #$02
			STA $05					; using $05 as a comparison for the graphics loop.
			
			BRA nowDoDirection

		nowDoDirection:
		
		LDX $15E9
		
		LDA $7FAB10,x
		AND #$04
		BEQ rightSetup
		BNE leftSetup
		
		rightSetup:
			PLX
			; nothing extra really needs to be done, it's default setup to look right.
			BRA GFXloop

		leftSetup:
			PLX
			INX #$06					; increase by 6 to use the second row.
			
			LDA $05						; comparison too.
			CLC
			ADC #$06
			STA $05
			
			BRA GFXloop

		GFXloop:
			LDA $00						; $00 = base X position
			CLC
			ADC xDisplacement,x
			STA $0300,y

			LDA $01
			CLC
			ADC yDisplacement,x
			STA $0301,y

			LDA tiles,x
			STA $0302,y

			LDA yxppccct,x
			STA $0303,y

			INY #$04				; \ add 4 to the OAM index
			DEX						; | and decrement the tile counter
			CPX $05					; | compared here, so it either uses the first or second row.
			BPL GFXloop				; / if positive, there are more tiles to draw

			LDX $15E9
			LDY #$00
			LDA $04				; knows the number of tiles drawn
			JSL $01B7B3			; finish the write to OAM
			RTS
			
	MarioInteraction:
		JSL $01A7DC
		BCC ReturnMI
		
		LDA #$1E				; 60 decimal frames to hold sprung animation.
		STA $1540,x				; "stun timer" table because it auto-decrements.
		
		LDA #$1E				; 60 decimal frames to not interact with player.
		STA $154C,x
		STA $1564,x				; or other sprites
		
		PHY
		
		LDY #$00		
		LDA $7FAB10,x
		AND #$04
		BEQ MarioRight
			LDY #$01			; loads this if the extra bit is 3, so mario gets launched leftward.
		
		MarioRight:
			LDA marioLaunchX,y
			STA $7B
			
			LDA #!marioLaunchY
			STA $7D
		
		PLY	
		LDA !dashSettings		; \ reset dash counter.
		AND #$80
		BNE +

		LDA !dashSettings
		AND #$03
		CMP !dashCount
		BMI +

		STA !dashCount
		
		+
		
		LDA #$00
		STA !dashTimer
		
		LDA #$08
		STA $1DFC
			
		RTS
		
		ReturnMI:
			RTS
			
	SpriteInteraction:
		JSL	$03B69F
		
		LDX #$0C
		
		SpriteCheckingLoop:
		DEX
		CPX #$FF
		BEQ ReturnSI
		
		CPX $15E9
		BEQ SpriteCheckingLoop
		
		LDA $14C8,x
		CMP #$08
		BMI SpriteCheckingLoop
		
		LDA $9E,x
		CMP #$C4
		BEQ SpriteCheckingLoop
		
		JSL $03B6E5				; get clipping B.
		
		JSL $03B72B				; check contact.
		BCC SpriteCheckingLoop	; if not in contact, keep checking.
		
		BRA SpriteSpeedStoring
		
		ReturnSI:
			RTS

		
		SpriteSpeedStoring:
		
		TXY
		LDX $15E9
		
		LDA #$1E				; 60 decimal frames to hold sprung animation.
		STA $1540,x				; "stun timer" table because it auto-decrements.
		
		LDA #$1E				; 60 decimal frames to not interact with player.
		STA $154C,x
		STA $1564,x				; or other sprites.
		
		PHY
		
		LDY #$00		
		LDA $7FAB10,x
		AND #$04
		BEQ SpriteRight
			LDY #$01			; loads this if the extra bit is 3, so mario gets launched leftward.
		
		SpriteRight:
			LDA spriteLaunchX,y
			PLY
			STA $B6,y
			; store x speed
			
			LDA #!spriteLaunchY
			STA $AA,y
			
			LDA $9E,y
			CMP #$26
			BNE +
			LDA #!thwompLaunchY
			STA $AA,y
			+
			
			LDA $14C8,y
			CMP #$09
			BNE ++
			
			LDA $9E,y
			CMP #$04
			BEQ +
			CMP #$05
			BEQ +
			CMP #$06
			BEQ +
			CMP #$07
			BEQ +
			BRA ++
			
			+
			LDA #$0A
			STA $14C8,y
			
		++
		LDA #$08
		STA $1DFC
		
		RTS

		
		