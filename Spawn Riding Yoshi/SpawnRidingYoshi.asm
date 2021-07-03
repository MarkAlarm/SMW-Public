;#######################################;
;# Spawn Riding Yoshi                  #;
;# By MarkAlarm                        #;
;# Credit unnecessary, but appreciated #;
;#######################################;

;###########;
;# Options #;
;###########;

; note: do NOT place a yoshi in the level in Lunar Magic, this will spawn it for you

!spawnColor = !green					; yellow, blue, red, and green all work as you expect

!spawnWithSprite = !true				; if true, yoshi will spawn in with the specified sprite
!mouthSprite = $2D						; $04,$05,$06,$07 = colored shells, everything else is what Lunar Magic says
!switchColor = $00						; $00 = blue, $01 = silver. only use with pswitches or weird things happen
!discoShell = $00						; $00 = not disco, $01 = disco. only use with shells or weird things happen
!swallowTimer = $FF						; number of frames before yoshi swallows the sprite spawned with

; none of the options beyond here should be edited

!false = 0
!true = 1

!beige = $00
!grey = $02
!yellow = $04
!blue = $06
!red = $08
!green = $0A
!colorE = $0C
!colorF = $0E

;########;
;# Code #;
;########;

init:
	LDX #!sprite_slots-1				; \ loop to find a slot for yoshi
	-									; |
	LDA !sprite_status,x				; | if there's a free slot, use it
	BEQ +								; |
	DEX									; |
	BPL -								; |
	RTL									; /
	
	+
	LDA #$35							; \ spawn yoshi
	STA !sprite_num,x					; |
	JSL $07F7D2							; |
	LDA #$08							; |
	STA !sprite_status,x				; /
	
	LDA $94								; \ position yoshi right where the player is
	STA !sprite_x_low,x					; |
	LDA $95								; |
	STA !sprite_x_high,x				; |
	LDA $96								; |
	STA !sprite_y_low,x					; |
	LDA $97								; |
	STA !sprite_y_high,x				; /
	
	DEC $96								; shift the player slightly so that they actually mount yoshi
	
	LDA !sprite_oam_properties,x		; \ set yoshi's color based on the option picked
	AND #$F1							; |
	ORA #!spawnColor					; |
	STA !sprite_oam_properties,x		; /
	
	if !spawnWithSprite
		TXY								; \ loop to find a slot for the mouth sprite
		-								; |
		LDA !sprite_status,y			; | if there's a free slot, use it
		BEQ +							; |
		DEY								; |
		BPL -							; |
		RTL								; /
		
		+
		TYA								; \ set sprite in mouth index
		STA !160E,x						; /
		
		TYX
		
		LDA #!mouthSprite				; \ spawn desired item in mouth
		STA !sprite_num,x				; |
		LDA #$07						; |
		STA !sprite_status,x			; |
		JSL $07F7D2						; /
		
		if !discoShell
			LDA #$01					; \ set disco shell flag
			STA !187B,x					; /
		endif
		
		if !mouthSprite == $3E
			LDA #!switchColor					; \ set pswitch color
			STA !151C,x							; |
			LDA.b #read1($018466+!switchColor)	; | and its palette data
			STA !sprite_oam_properties,x		; /
		endif
		
		if !mouthSprite == $80
			LDA #$01					; \ set key in mouth flag
			STA $191C|!addr				; /
		endif
		
		LDA #!swallowTimer				; \ set swallow timer
		STA $18AC|!addr					; /
	endif
	
	RTL
