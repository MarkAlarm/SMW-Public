;############################;
;# Celeste Strawberry Stuff #;
;############################;

;##########################;
;# Global Celeste Defines #;
;##########################;

	!dashCount = $18C5				; freeram address that acts as the counter for how many dashes the player has left.
	!dashTimer = $18C6				; freeram address that counts down to maintain dash speed. also acts as a flag for if the player is dashing.
	!directionStore = $18C7			; freeram address that stores what direction was held down.
	!paletteFree = $18C9			; freeram address to check whether or not to do the palette change.
	!dashSettings = $18CA			; freeram address that stores individual level settings for dash code.
	
	!dashFrames = $0A				; number of frames that you'll maintain speed when you dash. there should be no reason to change this.

;#################################;
;# Variable and Table Initiation #;
;#################################;

	!xRecall = $7FBA00
	!yRecall = $7FBB00



;#####################;
;# Begin Actual Code #;
;#####################;

main:
	JSR PositionBuffer
	
	
	

	RTL



	PositionBuffer:
		LDA $14
		AND #$01
		BEQ +
		RTS
		+

		REP #$20
		
		LDX #$02
		-	
		LDA !xRecall,x
		DEX #2
		STA !xRecall,x
		INX #2
		LDA !yRecall,x
		DEX #2
		STA !yRecall,x
		INX #4
		CPX #$F2
		BNE -
		
		LDX #$F0
		LDA $94
		STA !xRecall,x

		LDA $96
		STA !yRecall,x

		SEP #$20
		RTS