;#######################################;
;# Celeste Based Dash by MiniMawile303 #;
;#######################################;

;##########################;
;# Global Celeste Defines #;
;##########################;

	!dashCount = $18C5				; freeram address that acts as the counter for how many dashes the player has left.
	!dashTimer = $18C6				; freeram address that counts down to maintain dash speed. also acts as a flag for if the player is dashing.
	!directionStore = $18C7			; freeram address that stores what direction was held down.
	
	!dashSettings = $18CA			; freeram address that stores individual level settings for dash code.
	
	!paletteFree = $7FB200			; freeram address to check whether or not to do the palette change.
	!palettePointer = $7FB201
	
	!dashFrames = $0A				; number of frames that you'll maintain speed when you dash. there should be no reason to change this.

;#################################;
;# Variable and Table Initiation #;
;#################################;

	!SFX = $27						; \ sound effect to play.
	!channel = $1DFC				; / channel to use. make sure the sound effect and channel work together.

	!buttons = %0000000000110000	; format: byetUDLRaxlr----. these are the buttons (OR'd) that the will be checked for your dash. L and R are set by default.

	!xSpeed = $3F					; \ speed variables. if xSpeed is more than $3F, mario will not be able to jump from a dash.
	!ySpeed = $3F					; / again, not much reason to change these.

	xSpeeds:						; X speed table.
		db $00,!xSpeed,$100-!xSpeed,$00

	ySpeeds:						; Y speed table.
		db $00,!ySpeed,$100-!ySpeed,$00

	!defaultDashSettings = $01		; format: c-----dd, where c is if ground (or other things) should be checked to restore dash, d is the number of dashes.
	
	!numberOfSpecialLevels = $0E	; number of levels that don't use the default setting.
		
	specialLevels:					; level numbers that are special.
		dw $0007,$0017,$0027,$0037,$0047,$0057,$0067,$0077,$0008,$0018,$0028,$0038,$00C5,$01C5
	
	specialSettings:				; setting values to use for those levels. format is c-----dd.
		db $02,$02,$02,$02,$02,$02,$02,$03,$82,$82,$82,$02,$00,$00
		
	!false = 0						; \ don't change these.
	!true = 1						; /
	
	ColorPointers:
	dw $F9F5,$B2C8,$FF93,$FFA7

;#####################;
;# Begin Actual Code #;
;#####################;

init:
	LDA #$01					; \ allows the custom palette to be drawn.
	STA !paletteFree			; /

	LDA #!numberOfSpecialLevels
	TAX

	REP #$20
	
	.specialLoop:
	DEX
	CPX #$FF
	BEQ .notSpecial
	
	PHX
	
	TXA
	ASL
	TAX

	LDA.L specialLevels,x
	PLX
	
	CMP $010B
	BNE .specialLoop

	SEP #$20

	LDA.L specialSettings,x
	STA !dashSettings
	AND #$03
	STA !dashCount
	RTL
	
	.notSpecial:
	SEP #$20
	
	LDA #!defaultDashSettings
	STA !dashSettings
	AND #$03
	STA !dashCount
	RTL

main:
	LDA #$01					; \ allows the custom palette to be drawn.
	STA !paletteFree			; /


	LDA $9D				; \ if sprites locked...
	ORA $13D4			; | or paused...
	ORA $1493			; | or goal tape sequence is happening...
	BNE .return			; / don't run.

	LDA !dashTimer		; \ if the timer isn't 0 then the player is dashing, so just go to the dash code.
	BEQ .dashTimerZero	; /
		BRL .preDash
	.dashTimerZero:
	
	STZ $0B
	LDA !dashSettings
	AND #$80
	BNE .noGround
		LDA $77			; \ if standing on something solid...
		STA $0B
	.noGround:
	
	LDA $0B			; \ if standing on something solid...
	AND #$04		; /
	ORA $74			; or if climbing...
	ORA $75			; or if in the water...
	
	BNE .restore
	BRA .checks

	.restore:
		LDA !dashSettings
		AND #$03
		CMP !dashCount
		BMI .checks
	
		LDA !dashSettings				; \ resets dash counter...
		AND #$03						; |
		STA !dashCount					; /

		STZ !dashTimer				; and dash timer.

	.checks:
		LDA !dashCount				; \ if you can't dash anymore, don't dash.
		BEQ .return					; /
		
		; LDA $77						; \ if getting blocked by the screen, do
		; AND #$80					; |
		; BNE .return					; /
		
		LDA $15
		STA $0C

		LDA $0C 					; \ if no directional input is held, use whatever direction mario was facing.
		AND #$0F					; |
		BEQ .faceDirSet				; /

		CMP #$03					; \ or if L/R are both held.
		BEQ .return					; /
		CMP #$0C					; \ or if U/D are both held.
		BEQ .return					; /
		
		.afterFaceSet:
		
		LDA $16
		XBA
		LDA $18

		REP #$30
		
		AND.W #!buttons
		BNE .hit
		
		SEP #$30
		
		.return:
			RTL
			
		.faceDirSet:
			LDA #$02
			STA $0C
			LDA $76
			BEQ .afterFaceSet
				DEC $0C
				BRA .afterFaceSet
		
		.hit:
			SEP #$30

			LDA #$00				; \ sets jump status to normal jump.
			STA $140D				; /
			
			STZ $0DC3				; clear walljump flags

			LDA #!SFX				; \ plays the sound effect to the given channel.
			STA !channel			; /

			LDA $0C
			AND #$0F
			STA !directionStore

			LDA #!dashFrames		; \ loads the amount of frames into the timer so the dash can be executed.
			STA !dashTimer			; /
			
			DEC !dashCount

			LDY #$00
			JSR .smoke
			
			LDA #$70				; \ set p-meter to full.
			STA $13E4				; /

			RTL

	.preDash:
		LDA $77						; \ if mario is standing on something solid...
		AND #$04					; |
		BEQ .continueDash			; /

		LDA $16						; \ or if mario trys to jump...
		ORA $18						; | either kind...
		AND #$80					; |
		BEQ .continueDash			; / then stop dashing.

		STZ !dashTimer				; stop dashing.
		RTL
		
		.continueDash:
		
		LDA $77						; \ if mario is standing on something solid...
		AND #$04					; |
		BEQ .noReverse				; /

		LDA #!dashFrames			; \ 3 frames to do a ground turnaround
		SEC : SBC #$03				; |
		STA $00						; /
		
		LDA !dashTimer
		CMP $00
		BMI .noReverse
		
			LDA !directionStore
			AND #$03				; if not going left or right, no Reverse
			BEQ .noReverse
			CMP #$01
			BEQ .checkRightReverse
				
				LDA $16
				AND #$01
				BNE .doReverse
				BRA .noReverse

			.checkRightReverse:
				LDA $16
				AND #$02
				BNE .doReverse
				BRA .noReverse
				
			.doReverse:
				LDA !directionStore
				AND #$03
				EOR #$03
				STA !directionStore
				LDA #$01
				STA !dashTimer
			
		.noReverse:
		
		LDA !directionStore		; reloads controller input, handles L/R
		AND #$03
		TAX							; \ stores into mario's x speed
		LDA.L xSpeeds,x				; |
		STA $7B						; /

		LDA !directionStore		; reloads controller input, handles U/D
		LSR #2
		AND #$03
		TAX							; \ stores into mario's y speed
		LDA.L ySpeeds,x				; |
		STA $7D						; /

		DEC !dashTimer

		RTL
		
	.smoke:
		LDA $17C0,y			; \ draw smoke if there's a free slot.
		BEQ .actuallyDraw	; /
		
		INY
		CPY #$04
		BMI .smoke
		
		RTS					; return if there isn't.
		
		.actuallyDraw:
			LDA #$02
			STA $17C0,y
			
			LDA #!dashFrames
			STA $17CC,y
			
			LDA $96
			CLC
			ADC #$10
			STA $17C4,y
			
			LDA $94
			STA $17C8,y
			
			RTS

nmi:
	LDA $1493		; \ don't run NMI code during course clear, otherwise a seizure inducing screen flash happens.
	BEQ +			; /

	LDA !dashSettings
	AND #$03
	STA !dashCount
	
	STZ !dashTimer
	
	RTL

	+
	LDA !dashCount
	ASL
	TAX
	REP #$20
	LDA.L ColorPointers,x
	STA $0D82
	SEP #$20
	
	RTL
	
pushpc	
org $00F9F5
BluePal:
	dw $635F,$581D,$2800,$7DE8
	dw $44C4,$4E08,$6770,$59A5
	dw $35DF,$03FF

org $00FF93
GreenPal:
	dw $635F,$581D,$0140,$23EE
	dw $44C4,$4E08,$6770,$16CC
	dw $35DF,$03FF
	
org $00FFA7
WhitePal:
	dw $635F,$581D,$3182,$6F7B
	dw $44C4,$4E08,$6770,$56B5
	dw $35DF,$03FF
pullpc
