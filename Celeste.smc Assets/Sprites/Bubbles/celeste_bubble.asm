;####################################;
;# Celeste Bubble by MiniMawile303 #;
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

	xDisplacement:
		db $00,$10,$00,$10
		
	yDisplacement:
		db $00,$00,$10,$10
		
	tiles:
		db $00,$02,$20,$22
		db $04,$06,$24,$26
		
	yxppccct:
		db %00111011,%00111001
		
	!stateTable = $C2			; sprite table for the bubble state.
	!movingTimer = $1540		; sprite table that acts as a delay between entry and moving, as well as how long the green bubble moves for.
	!launchDirectionStore = $1528

	!originXLow = $1504
	!originXHigh = $1510
	!originYLow = $1594
	!originYHigh = $1FD6
	
	!xSpeed = $40
	!ySpeed = $40
	
	xSpeeds:						; X speed table.
		db $00,!xSpeed,$100-!xSpeed,$00

	ySpeeds:						; Y speed table.
		db $00,!ySpeed,$100-!ySpeed,$00
	
	states:
		dw Idle
		dw AboutToMove
		dw Moving
		dw GoBack

;#####################;
;# Begin Actual Code #;
;#####################;

print "INIT ",pc
	LDX $15E9
	STZ !stateTable,x
	
	LDA $D8,x
	STA !originYLow,x
	LDA $E4,x
	STA !originXLow,x
	LDA $14D4,x
	STA !originYHigh,x
	LDA $14E0,x
	STA !originXHigh,x
	RTL

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR SpriteCode
	PLB
	RTL

	SpriteCode:
		JSR Graphics
		%SubOffScreen()
		
		LDA $14C8,x		; \
		CMP #$08		; | if the sprite is dead or not it it's normal state, return.
		BNE ReturnSC	; /

		LDA $9D			; \
		BNE ReturnSC	; / if game is paused, return.

		LDA !stateTable,x
		ASL
		TAX
		JSR (states,x)

		ReturnSC:
		RTS
		
	Idle:
		LDX $15E9
		JSL $01A7DC
		BCC ReturnIdle
		
		STZ !dashTimer
		LDA !dashSettings
		AND #$80
		BNE +
		LDA !dashSettings
		AND #$03
		STA !dashCount
		+
		
		LDA #$20
		STA !movingTimer,x
		
		LDA #$01
		STA !stateTable,x
		
		ReturnIdle:
			RTS
			
	AboutToMove:
		LDX $15E9
		
		LDA #$40
		STA $13E0
		
		; horizontal shift

		LDA $14E0,x
		XBA
		LDA $E4,x
		
		REP #$20
		CLC : ADC #$0008
		STA $94
		SEP #$20

		LDA $14D4,x
		XBA
		LDA $D8,x
		
		REP #$20
		SEC : SBC #$0008
		STA $96
		SEP #$20
		
		STZ $7B
		STZ $7D
		
		LDA $AA,x
		STA $7D
		LDA $B6,x
		STA $7B
		
		LDA !dashTimer
		BNE ElapsedATM
		
		LDA !movingTimer,x
		BNE ReturnATM
		
		ElapsedATM:
			LDA #$02
			STA !stateTable,x
			
			LDA #$1E
			STA !movingTimer,x
			
			LDA $15
			AND #$0F
			BNE SkipNoDir
				LDA #$02
				STA !launchDirectionStore,x
				LDY $76
				CPY #$00
				BEQ SkipNoDir
				LDA #$01
			
			SkipNoDir:
			STA !launchDirectionStore,x
			
			STZ !dashTimer
			LDA !dashSettings
			AND #$80
			BNE +
			LDA !dashSettings
			AND #$03
			STA !dashCount
			+

		ReturnATM:
			RTS
		
	Moving:
		LDX $15E9
		
		LDA #$40
		STA $13E0

		LDA $14E0,x
		XBA
		LDA $E4,x
		
		REP #$20
		CLC : ADC #$0008
		STA $94
		SEP #$20
		
		LDA $14D4,x
		XBA
		LDA $D8,x
		
		REP #$20
		CLC : ADC #$FFF8
		STA $96
		SEP #$20

		PHX
		LDA !launchDirectionStore,x
		AND #$03
		TAX
		LDA.L xSpeeds,x
		PLX
		STA $B6,x

		PHX
		LDA !launchDirectionStore,x
		LSR #2
		AND #$03
		TAX
		LDA.L ySpeeds,x
		PLX
		STA $AA,x
		
		LDA $AA,x
		STA $7D
		LDA $B6,x
		STA $7B
		
		JSL $01801A
		JSL $018022
		
		LDA !dashTimer
		BNE ElapsedMoving
		
		LDA $7FAB10,x
		AND #$04
		BNE RedNoTimer
			LDA !movingTimer,x
			BEQ ElapsedMoving
			
		RedNoTimer:
		
		JSL $019138
		
		LDA $1588,x
		BEQ ReturnMoving
		
		ElapsedMoving:
			LDA #$03
			STA !stateTable,x
			
			LDA #$3C
			STA $154C,x
			
			LDA !originYLow,x
			STA $D8,x
			LDA !originXLow,x
			STA $E4,x
			LDA !originYHigh,x
			STA $14D4,x
			LDA !originXHigh,x
			STA $14E0,x
			
			LDA #$08
			STA $00
			STA $01
			
			LDA #$0F
			STA $02
			
			LDA #$01
			%SpawnSmoke()
		
		ReturnMoving:
			RTS
	
	GoBack:
		LDX $15E9
		
		LDA $154C,x
		BNE ReturnGB
			STZ !stateTable,x
			
			LDA #$08
			STA $00
			STA $01
			
			LDA #$0F
			STA $02
			
			LDA #$01
			%SpawnSmoke()
		
		ReturnGB:
			RTS
		
	Graphics:
		STZ $07
		STZ $08
		LDX $15E9
		LDA $7FAB10,x
		AND #$04
		BEQ Green
			INC $08
		Green:
		
		LDA !stateTable,x
		CMP #$03
		BNE NoOutline
			LDA $07
			CLC : ADC #$04
			STA $07
		
		NoOutline:
	
		%GetDrawInfo()
		LDX #$03
		
		GFXLoop:
			LDA $00
			CLC
			ADC xDisplacement,x
			STA $0300,y
			
			LDA $01
			CLC
			ADC yDisplacement,x
			STA $0301,y
			
			PHX

			TXA
			CLC : ADC $07
			TAX
			
			LDA tiles,x
			STA $0302,y

			LDX $08
			LDA yxppccct,x
			STA $0303,y
			
			PLX
			
			INY #$04
			DEX
			BPL GFXLoop
			
			LDX $15E9
			LDY #$02
			LDA #$03
			JSL $01B7B3			; finish the write to OAM
			RTS
		
