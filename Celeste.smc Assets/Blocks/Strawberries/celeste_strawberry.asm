;######################;
;# Celeste Strawberry #;
;######################;

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
	
	!xRecall = $7FBA00
	!yRecall = $7FBB00
	
	!berryFree = $18CC
	
	!strawberrySpriteNum = $04		; sprite number for the strawberry in list.txt

	!trailNum = $1510				; what number the strawberry is on the trail.
	!groundTimer = $1528			; timer to count how long the player has been on the ground.
	!groundFrames = $09				; number of consecutive frames to be on the ground. once hit, the berry will be collected.
	
	!berryTile = $C2
	!berryProps = %00110010

	!collectedValue = $01			; value to say yeah i collected the berry.
	
	; extra byte 1 determines the berry number.
	; first number is the chapter (1x, 2x, etc), second number is the berry within chapter (x1, x2, etc).
	; number 1, 1 through A is valid.
	; number 2, 1 through F is valid.

;#####################;
;# Begin Actual Code #;
;#####################;

print "INIT ",pc
	STZ !groundTimer,x
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
	
	LDA $71
	CMP #$05
	BEQ +
	CMP #$06
	BEQ +
	
	BRA ++
	
	+
	LDA $88
	BEQ ++
	
	JSR Collect
	RTS
	
	++
	LDA $14C8,x		; \
	CMP #$08		; | if the sprite is dead or not in it's normal state, return.
	BNE ReturnSC	; /
	LDA $9D			; \
	BNE ReturnSC	; / if sprites are locked, return.

	JSR UpdatePosition
	
	LDA !trailNum,x
	DEC
	BNE ReturnSC
	
	JSR CollectCheck
	
	ReturnSC:
	RTS
		
	UpdatePosition:
		LDA $14
		AND #$01
		BEQ +
		RTS
		+
		
		LDA !trailNum,x
		DEC
		ASL #3
		STA $00
		
		LDA #$E0
		SEC : SBC $00
		
		STA $00
		INC
		STA $01

		PHX
		LDX $00
		LDA !xRecall,x
		PLX
		STA $E4,x
		PHX
		LDX $01
		LDA !xRecall,x
		PLX
		STA $14E0,x

		PHX
		LDX $00
		LDA !yRecall,x
		PLX
		STA $D8,x
		PHX
		LDX $01
		LDA !yRecall,x
		PLX
		STA $14D4,x
		
		RTS
		
	CollectCheck:
		LDA !groundTimer,x
		CMP #!groundFrames
		BEQ Collect
		
		LDA $13EF					; not just blocked status, but on actual ground. platforms and other solid sprites won't work.
		BEQ ResetGroundTimer
		INC !groundTimer,x
		RTS
		
		Collect:
		
		LDA #$05
		STA $1DFC
		
		STZ $00
		STZ $01
		LDA #$09
		STA $02
		LDA #$05
		%SpawnSmoke()
		
		JSR SaveBerry
		
		LDA #$00
		STA $14C8,x
		
		DEC !berryFree
		
		PHX
		LDX #$0C
		-
		LDA $7FAB9E,x
		CMP #!strawberrySpriteNum
		BNE +
		DEC !trailNum,x
		STZ !groundTimer,x
		+
		DEX
		CPX #$FF
		BNE -
		PLX

		RTS
		
		ResetGroundTimer:
			STZ !groundTimer,x
			RTS
		
		SaveBerry:
			PHX
			
			LDA !extra_byte_1,x
			BEQ +
			
			STA $00
			JSR GetSRAMIndex
			
			REP #$10
			LDX $0C
			
			LDA #!collectedValue
			STA $700500,x
			
			SEP #$10
			
			+
			PLX
		
			RTS
	
	
	
	
	Graphics:
		%GetDrawInfo()
		
		LDA $00
		STA $0300,y
		LDA $01
		STA $0301,y

		LDA #!berryTile
		STA $0302,y
		LDA #!berryProps
		STA $0303,y

		LDX $15E9
		LDY #$02
		LDA #$00
		JSL $01B7B3			; finish the write to OAM
		RTS



fileHighOffsetSRAM:
	db $00,$01,$02
	
GetSRAMIndex:					; this routine can be used for anything in this game that uses SRAM.
	PHX
	STZ $01						; clear this out.
	LDX $010A
	LDA.L fileHighOffsetSRAM,x
	XBA							; high byte is set
	LDA #$00					; and use #$00 for the low byte.

	REP #$20
	CLC : ADC $00				; add in any additional offset.
	STA $0C						; $0C is now 16 bit and contains the index to $700500.
	SEP #$20
	PLX
	RTS


