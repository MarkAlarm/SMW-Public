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

	xDisplacement:
		db $F8,$08
		
	tiles:
		db $00,$02,$00,$02,$00,$02,$00,$02
	
	!props = %00111001
	
	xSpeedCompares:
		db $18,$E8

;#####################;
;# Begin Actual Code #;
;#####################;

print "INIT ",pc
	LDA #$09
	STA $14C8,x
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
		%SubOffScreen()
		
		LDA $14C8,x		; \
		CMP #$08		; | if the sprite is dead or not it it's normal state, return.
		BCC ReturnSC	; /

		LDA $9D			; \
		BNE ReturnSC	; / if game is paused, return.
		
		LDA $154C,x
		BNE ReturnSC
		
		JSR AttemptCarry
		JSR BeingCarried
		JSR FloatyX
		JSR LowGravity
		JSR CheckThrown
		
		ReturnSC:
		RTS
		
	AttemptCarry:
		LDA $15
		AND #$40
		BEQ ReturnAC
		
		LDA $1470
		ORA $187A
		BNE ReturnAC
		
		JSL $01A7DC
		BCC ReturnAC
		
		LDA #$0B
		STA $14C8,x
		
		LDA !dashTimer
		BEQ ReturnAC
		
		LDA !directionStore
		AND #$08
		BEQ ReturnAC
		
		LDA #$B0
		STA $7D

		ReturnAC:
		RTS
		
	BeingCarried:
		LDA $14C8,x
		CMP #$0B
		BNE ReturnBC

		LDA $15
		AND #$80
		BEQ ReturnBC
		
		DEC $7D
		
		LDA $7D
		CMP #$10
		BMI ReturnBC
		CMP #$80
		BPL ReturnBC
		
		LDA #$10
		STA $7D
		
		ReturnBC:
		RTS
		
	FloatyX:
		LDA $14C8,x
		CMP #$09
		BNE ReturnFX
		
		LDY #$00

		LDA $B6,x
		BPL Right
			INY

			LDA $B6,x
			CMP xSpeedCompares,y
			BPL ContinueFloatX
			LDA xSpeedCompares,y
			STA $B6,x
			BRA ContinueFloatX
			
		Right:
			LDA $B6,x
			CMP xSpeedCompares,y
			BMI ContinueFloatX
			LDA xSpeedCompares,y
			STA $B6,x
		
		ContinueFloatX:
		
		ReturnFX:
		RTS
		
	LowGravity:
		LDA $14C8,x
		CMP #$09
		BNE ReturnLG
		
		INC $AA,x
		
		LDA $AA,x
		CMP #$10
		BMI ReturnLG
		CMP #$80
		BPL ReturnLG
		
		LDA #$10
		STA $AA,x
		
		ReturnLG:
		RTS
		
	CheckThrown:
		LDA $14C8,x
		CMP #$0A
		BNE ReturnCT
		
		LDA #$10
		STA $154C,x
		
		ReturnCT:
		RTS
		
	Graphics:	
		%GetDrawInfo()
		LDX #$01
		
		GFXLoop:
			LDA $00
			CLC
			ADC xDisplacement,x
			STA $0300,y
			
			LDA $01
			STA $0301,y
			
			LDA tiles,x
			STA $0302,y
			
			LDA #!props
			STA $0303,y
			
			INY #4
			DEX
			BPL GFXLoop
			
			LDX $15E9
			LDY #$02
			LDA #$01
			JSL $01B7B3			; finish the write to OAM
		
			RTS
		