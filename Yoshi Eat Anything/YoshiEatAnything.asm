;#######################################;
;# Yoshi Eat Anything                  #;
;# By MarkAlarm                        #;
;# Credit unnecessary, but appreciated #;
;#######################################;

;###########;
;# Options #;
;###########;

!beatLevel = 1							; if 1, eating sprites that are necessary to beat the level (orb, goal tape, bosses, etc) will beat the level
!bossMusicTrack = $03					; song to use for eating a boss
!orbMusicTrack = $03					; song to use for eating an orb
!goalMusicTrack = $04					; song to use for eating a goal tape

!messageBox = 1							; if 1, eating the message box will display a corresponding message
!messageToRead = $01					; $01 for the first message, $02 for the second message, $03 for yoshi's thanks message. other values probably break this
!messageReadTable = !1504				; unused sprite table in the message box so that it doesn't display multiple times during the eat. this should not need to be changed

; note that eating chucks will result in variable behavior due to their "gives powerup" flag not working in a normal sense. might be nice to use for glitch heavy levels though!

;########;
;# Code #;
;########;

main:
	LDA #$FF							; \ set invalid sprite in mouth index
	STA $00								; /
	
	LDX #!sprite_slots-1				; \ attempts to make all sprites edible
	-									; | invalid sprites are ones that don't call the speed routines at all
	LDA !sprite_num,x					; | check if current sprite is yoshi
	CMP #$35							; |
	BNE +								; | if not, skip ahead
	STX $00								; / preserve yoshi's index
	+

	LDA !sprite_tweaker_1686,x			; \ clear inedible and stay in yoshi mouth flags
	AND #$FC							; |
	STA !sprite_tweaker_1686,x			; /
	DEX
	BPL -

	if !beatLevel || !messageBox
		LDX $00							; \ check potential yoshi index
		BMI .return						; / if nonexistent, return
		
		LDA !160E,x						; \ if no sprite in mouth, return
		TAX								; |
		BMI .return						; /

		if !beatLevel
			LDA !sprite_num,x			; \ load sprite in mouth number
			CMP #$29					; | check if koopa kid
			BEQ .boss					; | if so, beat level (boss)
			CMP #$4A					; | check if orb
			BEQ .orb					; | if so, beat level (orb)
			CMP #$7B					; | check if goal tape
			BEQ .goal					; | if so, beat level (goal)
			CMP #$A0					; | check if bowser (don't know how this would get triggered in the first place but this probably breaks lol)
			BEQ .boss					; / if so, beat level (boss)
			CMP #$C5					; | check if boo boss
			BNE + 						; / if not, skip ahead (boss)
			
			.boss
			STZ $00						; set exit type
			LDA #!bossMusicTrack		; \ set music track
			STA $01						; /
			LDA #$FF					; \ set end sequence
			STA $02						; /
			BRA .triggerEnd
			
			.orb
			STZ $00						; set exit type
			LDA #!orbMusicTrack			; \ set music track
			STA $01						; /
			LDA #$FF					; \ set end sequence
			STA $02						; /
			BRA .triggerEnd
			
			.goal
			LDA !extra_bits,x			; \ set exit type based on goal type (normal, secret 1, secret 2, secret 3)
			AND #$0F					; |
			LSR #2						; |
			STA $00						; /
			LDA #!goalMusicTrack		; \ set music track
			STA $01						; /
			STZ $02						; set end sequence
			JSL $00FA80					; trigger goal tape routine
			
			.triggerEnd
			LDA #$FF					; \ set walking animation
			STA $1493|!addr				; /
			LDA $00						; \ set exit type
			STA $141C|!addr				; /
			LDA $01						; \ set music track
			STA $1DFB|!addr				; /
			LDA $02						; \ set end sequence
			STA $13C6|!addr				; /
			
			+
		endif
		
		if !messageBox
			LDA !sprite_num,x			; \ load sprite in mouth number
			CMP #$B9					; | check if message box
			BNE +						; / if not, skip ahead
			
			LDA !messageReadTable,x		; \ if we already read the message, skip ahead
			BNE +						; /
			
			LDA #!messageToRead			; \ display the message
			STA $1426|!addr				; /
			STA !messageReadTable,x		; set the read flag so we don't see it again
		
			+
		endif
		
		.return
	endif
	
	RTL
