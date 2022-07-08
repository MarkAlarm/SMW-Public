;##########################;
;# Celeste Ridge Platform #;
;##########################;

;#################################;
;# Variable and Table Initiation #;
;#################################;
	
	xDisplacements:
		db $00,$10,$20
		db $00,$10
	
	tiles:
		db $60,$61,$62
		db $60,$62
		
	platStart:				; starting index
		db $02,$04
		
	platEnd:
		db $00,$03
		
	platWidth:				; sprite clipping hitbox
		db $04,$1D
		
	!props = %00110001
	
	
	!state = $C2

	!timer = $1540
	
	!pauseFrames = $0F		; number of frames to pause while not moving before starting up again
	
	; extra bit clear = big (3 wide), set = small (2 wide)
	; extra byte 1 = starting direction.
	; 00 = right
	; 01 = left
	; 02 = down
	; 03 = up
	; extra byte 2 = timer to maintain max speed for
	
	states:
		dw Idle
		dw Accelerating
		dw Moving
		dw Decelerating
		
	acceleration:
		db $01,$FF
		
	maxSpeeds:
		db $20,$E0

;#####################;
;# Begin Actual Code #;
;#####################;

print "INIT ",pc
	PHB
	PHK
	PLB
	
	STZ $157C,x

	LDA $7FAB10,x
	AND #$04
	LSR #2
	TAY

	LDA platWidth,y
	STA $1662,x

	LDA #!pauseFrames
	STA !timer,x

	STZ !state,x
	
	LDA !extra_byte_1,x
	AND #$01
	BEQ +
	INC $157C,x
	
	+
	PLB

	RTL

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR SpriteCode
	PLB
	RTL
	
	
;#############;
;# Main Shit #;
;#############;
	
SpriteCode:
	JSR Graphics

	LDA $14C8,x		; \
	CMP #$08		; | if the sprite is dead or not in it's normal state, return.
	BNE ReturnSC	; /
	LDA $9D			; \
	BNE ReturnSC	; / if sprites are locked, return.
	
	LDA #$01
	%SubOffScreen()
	
	
	
	JSL $018022				; update x
	STA $1528,x
	
	JSL $01801A				; update y
	
	JSL $01B44F				; solid
	
	LDA !state,x
	ASL
	TAY
	
	LDA $15E9		; get the sprite index and keep it in $02 for offset purposes
	STA $02			; 

	LDA !extra_byte_1,x
	AND #$02
	LSR
	BNE +
	LDA $02				; offset to the x speeds instead of y speeds
	CLC : ADC #$0C		; 
	STA $02				; 
	
	+	
	REP #$20
	LDA states,y
	STA $00
	SEP #$20
	
	JMP ($0000)	

	ReturnSC:
		RTS
	
	Graphics:
		LDA $7FAB10,x
		AND #$04
		LSR #2
		STA $02				; $02 will be 0 if extra bit clear, 1 if extra bit set.
	
		%GetDrawInfo()
		
		LDX $02
		
		LDA platEnd,x
		STA $03
		
		LDA platStart,x
		TAX
		
		STZ $04
		DEC $04
		
		GFXLoop:
			INC $04
		
			LDA $00
			CLC : ADC xDisplacements,x
			STA $0300,y
			
			LDA $01
			STA $0301,y
			
			LDA tiles,x
			STA $0302,y
			
			LDA #!props
			STA $0303,y
			
			INY #4
			DEX
			CPX $03
			BPL GFXLoop

			LDX $15E9
			LDY #$02
			LDA $04
			
			JSL $01B7B3
			
			RTS
			
	Idle:
		LDA !timer,x
		BNE +
		
		INC !state,x
		
		+
		RTS
	
	Accelerating:
		LDA $157C,x
		TAY
		
		LDX $02
		
		LDA $AA,x
		CLC : ADC acceleration,y
		CMP maxSpeeds,y
		BNE +
		
		LDX $15E9
		
		INC !state,x
		
		LDA !extra_byte_2,x
		STA !timer,x
		
		LDX $02
		
		LDA maxSpeeds,y
		
		+
		STA $AA,x
		LDX $15E9
		RTS
	
	Moving:
		LDA !timer,x
		BNE +
		
		INC !state,x
		
		+
		RTS
	
	Decelerating:
		LDA $157C,x
		TAY
		
		LDX $02
		
		LDA $AA,x
		SEC : SBC acceleration,y
		BNE +
		
		LDX $15E9
		
		STZ !state,x
		
		LDA #!pauseFrames
		STA !timer,x
		
		LDA $157C,x
		EOR #$01
		STA $157C,x
		
		LDX $02
		
		LDA #$00
		
		+
		STA $AA,x
		LDX $15E9
		RTS
		
		
		