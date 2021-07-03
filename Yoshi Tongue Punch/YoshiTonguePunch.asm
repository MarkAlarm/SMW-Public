;#######################################;
;# Yoshi Tongue Punch                  #;
;# By MarkAlarm                        #;
;# Punch graphic by MegaScott          #;
;# Credit unnecessary, but appreciated #;
;#######################################;

;###########;
;# Options #;
;###########;

!punchMoreThings = 1						; if 0, this won't punch things that yoshi's tongue doesn't normally interact with. if 1, it makes basically everything punchable
; if this is set, the only sprites that won't get punched are ones that either set their speed every frame OR don't run the speed routine(s) at all
; expect some strange results with things like solid, line guided, and platform sprites

punchXSpeeds:
	db $30,$D0

!punchYSpeed = $C0

;########;
;# Code #;
;########;

main:
	if !punchMoreThings
		LDX #!sprite_slots-1				; \ attempts to make all sprites punchable to some extent
		-									; | invalid sprites are ones that either set their speed every frame OR don't run the speed routine(s) at all
		LDA !sprite_tweaker_1686,x			; |
		AND #$FC							; |
		ORA #$02							; |
		STA !sprite_tweaker_1686,x			; |
		DEX									; |
		BPL -								; /
	endif
	
	LDX #!sprite_slots-1					; \ loop to find which slot yoshi is in
	-										; |
	LDA !sprite_num,x						; |
	CMP #$35								; |
	BEQ +									; |
	DEX										; |
	BPL -									; |
	RTL										; /

	+
	LDY !160E,x								; \ check if sprite in mouth
	BMI ++									; / if not, return
	
	PHB	: PHK : PLB							; bank wrapper for tables
	
	LDA #$FF								; \ set sprite in mouth index to have nothing
	STA !160E,x								; /
	LDA #$02								; \ set tongue subroutine
	STA !1594,x								; /
	LDA #$0A								; \ set tongue timer
	STA !1558,x								; /
	
	LDA !157C,x								; \ keep yoshi's direction as an index for later
	STA $00									; /
	
	STZ $01									; $01 just determines if a sprite should be explicitly *kicked* rather than just thrown away
	
	PHX
	TYX
	
	LDA !sprite_num,x						; \ load punched sprite number
	CMP #$0D								; | check if koopa
	BCS +									; | if not, skip ahead
	CMP #$04								; | check if naked koopa
	BCC +									; | if so, skip ahead
	INC $01									; | kick it
	+										; |
	CMP #$11								; | check if buzzy beetle
	BNE +									; | if not, skip ahead
	INC $01									; |
	+										; |
	CMP #$53								; | check if throw block
	BNE +									; | if not, skip ahead
	INC $01									; | kick it
	+										; /
	
	LDY $00									; \ use horizontal direction as index
	LDA punchXSpeeds,y						; | set punched sprite's x speed
	STA !sprite_speed_x,x					; /
	LDA #!punchYSpeed						; \ set punched sprite's y speed
	STA !sprite_speed_y,x					; /
	TYA										; \ set punched sprite's horizontal direction
	STA !157C,x								; /
	
	LDA $01									; \ check if the sprite should be kicked
	BEQ +									; |
	LDA #$0A								; | set sprite status to be kicked
	STA !sprite_status,x					; |
	+										; /
	
	PLX
	
	PLB
	
	++
	RTL
