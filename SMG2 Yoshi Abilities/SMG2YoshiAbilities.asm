;########################################;
;# Super Mario Galaxy 2 Yoshi Abilities #;
;# By MarkAlarm                         #;
;# Please give credit if used           #;
;########################################;

;###########;
;# Options #;
;###########;

!simultaneousAbilities = !false				; if true, enable simultaneous yoshi abilities. default is false (and enabling this will definitely cause weird stuff to happen, but try it if you want lol)
!resetBerryCounters = !true					; if true, this will reset the red and pink berry counters. it will NOT revert the 20 second bonus from green berries, however. default is true
!warningSFX = $24							; sound effect to use when yoshi's ability is about to run out. default is $24
!warningChannel = $1DFC|!addr				; channel to use. default is $1DFC

!dashFree = $0F3A|!addr						; 2 bytes of freeram for the dash timer
!dashTime = $0258							; number of frames for the dash to last. default is $0258 (10 seconds)
!dashWarn = $0078							; number of frames left to give warning to the player. default is $0078 (2 seconds left)
!dashColor = !red							; color to make yoshi while in dash mode. default is red
!dashEnableSmokeTrail = !true				; if true, yoshi will leave a smoke trail effect while running. default is true
!dashBreakBlocks = !true					; if true, yoshi will break turn blocks akin to a chuck. default is true
!dashOffYoshiXSpeed = $30					; x speed to give yoshi while not riding him. speeds higher than $3F prevent the player from jumping on a vanilla rom. default is $30
!dashOnYoshiXSpeed = $3F					; x speed to give yoshi while riding him. speeds higher than $3F prevent the player from jumping on a vanilla rom. default is $3F

!blimpFree = $0F3C|!addr					; 2 bytes of freeram for the blimp timer
!blimpTime = $0258							; number of frames for the blimp to last. default is $0258 (10 seconds)
!blimpWarn = $0078							; number of frames left to give warning to the player. default is $0078 (2 seconds left)
!blimpColor = !blue							; color to make yoshi while in blimp mode. default is blue
!blimpEnableSmokeTrail = !true				; if true, yoshi will leave a smoke trail effect while going up. default is true
!blimpEnableSFX = !true						; if true, a sound effect will play when rising quickly. default is true
!blimpSlowRiseSpeed = $FC					; y speed to give when yoshi is rising slowly (pressing A/B). default is $FC
!blimpFastRiseSpeed = $F0					; y speed to give when yoshi is rising quickly (not pressing A/B). default is $F0
!blimpFallSpeed = $08						; y speed to give when the player is off yoshi. default is $08

!bulbFree = $0F3E|!addr						; 2 bytes of freeram for the blub timer
!bulbTime = $0258							; number of frames for the bulb to last. default is $0258 (10 seconds)
!bulbWarn = $0078							; number of frames left to give warning to the player. default is $0078 (2 seconds left)
!bulbColor = !yellow						; color to make yoshi while in blub mode. default is yellow
!bulbEnableSparkles	= !true					; if true, sparkle effects will appear while riding yoshi. default is true
!bulbDynamicExanimation = !true				; if true, the bulb berry timer will work directly with the exanimation slot, allowing for gradual changes in animation. default is true
!bulbManualTrigger = $00					; manual exanimation trigger to activate when the bulb berry is grabbed. default is $00
!bulbExanimationExtender = 5				; multiplier for how long the bulb timer will last. every increment of this is another double, so 0 = 1x, 1 = 2x, 2 = 4x, 3 = 8x, and so on
; if you use the dynamic exanimation, make sure the frames count in LM * (2^n) where n = !bulbExanimationExtender, is MORE than !bulbTime. LM * (2^n) > !bulbTime

; note to anyone experienced with ASM: the dash, blimp, and bulb sections can all be edited to add your own custom mechanics!
; just make sure your custom routine ends in an RTS

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

if !dashBreakBlocks
	dashBlockXOffsets:						; \ offset to interact with blocks in dash state
		dw $0012,$FFEE						; / right, left
endif

if !blimpEnableSmokeTrail
	blimpSmokeTimes:						; \ blimp smoke times
		db $0F,$1B							; / short, long
endif

;########;
;# Code #;
;########;

init:
	STZ !dashFree							; \ clear timers
	STZ !dashFree+1							; |
	STZ !blimpFree							; |
	STZ !blimpFree+1						; |
	STZ !bulbFree							; |
	STZ !bulbFree+1							; /

	RTL

main:
	LDX #!sprite_slots-1					; \ loop to find which slot yoshi is in
	-										; |
	LDA !sprite_num,x						; |
	CMP #$35								; |
	BEQ +									; |
	DEX										; |
	BPL -									; |
	RTL										; /

	+
	PHB : PHK : PLB							; bank wrapper for tables
	JSR CheckEatenBerry						; check berry type

	REP #$20
	LDA !dashFree							; \ run dash code
	BEQ +									; |
	JSR Dash								; /
	REP #$20

	+
	LDA !blimpFree							; \ run blimp code
	BEQ +									; |
	JSR Blimp								; /
	REP #$20

	+
	LDA !bulbFree							; \ run bulb code
	BEQ +									; |
	JSR Bulb								; /

	+
	SEP #$20

	PLB
	RTL

;#######################;
;# Check Eaten Berries #;
;#######################;

CheckEatenBerry:
	LDA $18D6|!addr							; \ load berry eaten type
	CMP #$01								; | check if red
	BEQ .dash								; | if so, get dash ability
	CMP #$02								; | check if pink
	BEQ .blimp								; | if so, get blimp ability
	CMP #$03								; | check if green
	BEQ .bulb								; / if so, get bulb ability
	RTS

	.dash
	LDA !sprite_oam_properties,x			; \ set yoshi's color based on the option picked
	AND #$F1								; |
	ORA #!dashColor							; |
	STA !sprite_oam_properties,x			; /

	REP #$20
	LDA #!dashTime							; \ set dash timer
	STA !dashFree							; /
	
	if !resetBerryCounters
		STZ $18D4|!addr						; reset red berry counter
	endif

	if !simultaneousAbilities == !false
		LDA #$0000							; \ clear other timers if we don't want simultaneous abilities
		STA !blimpFree						; |
		STA !bulbFree						; /
		SEP #$20
		LDA #$00							; \ reset exanimation trigger
		STA $7FC070+!bulbManualTrigger		; /
	endif

	SEP #$20
	RTS

	.blimp
	LDA !sprite_oam_properties,x			; \ set yoshi's color based on the option picked
	AND #$F1								; |
	ORA #!blimpColor						; |
	STA !sprite_oam_properties,x			; /

	REP #$20
	LDA #!blimpTime							; \ set blimp timer
	STA !blimpFree							; /
	
	if !resetBerryCounters
		STZ $18D5|!addr						; reset pink berry counter
	endif

	if !simultaneousAbilities == !false
		LDA #$0000							; \ clear other timers if we don't want simultaneous abilities
		STA !dashFree						; |
		STA !bulbFree						; /
		SEP #$20
		LDA #$00							; \ reset exanimation trigger
		STA $7FC070+!bulbManualTrigger		; /
	endif

	SEP #$20
	RTS

	.bulb
	LDA !sprite_oam_properties,x			; \ set yoshi's color based on the option picked
	AND #$F1								; |
	ORA #!bulbColor							; |
	STA !sprite_oam_properties,x			; /

	REP #$20
	LDA #!bulbTime							; \ set bulb timer
	STA !bulbFree							; /

	if !simultaneousAbilities == !false
		LDA #$0000							; \ clear other timers if we don't want simultaneous abilities
		STA !dashFree						; |
		STA !blimpFree						; /
	endif

	SEP #$20
	RTS

;########;
;# Dash #;
;########;

Dash:
	CMP #$0001								; \ check if we should finish
	BNE +									; | if not, continue
	JMP .done								; |
	+										; |
	CMP #!dashWarn							; | check if we should warn the player
	BNE +									; | if not, skip ahead
	LDY #!warningSFX						; | warn player with sfx
	STY !warningChannel						; /
	
	+
	DEC !dashFree							; decrement the timer
	SEP #$20
	
	if !dashBreakBlocks						; \ break blocks if enabled
		JSR DashBreakBlocks					; |
	endif									; /
	
	if !dashEnableSmokeTrail
		LDA !dashFree						; \ check if we should display a new smoke tile
		AND #$03							; |
		BNE ++								; / if not, skip ahead
		
		LDY #$03							; \ loop to find a free smoke slot
		-									; |
		LDA $17C0|!addr,y					; |
		BEQ +								; |
		DEY									; |
		BPL -								; |
		BRA ++								; / skip ahead if none found
		
		+
		LDA #$01							; \ set smoke type
		STA $17C0|!addr,y					; |
		LDA !sprite_y_low,x					; | set smoke y position with offset
		CLC : ADC #$08						; |
		STA $17C4|!addr,y					; |
		LDA !sprite_x_low,x					; | set smoke x position
		STA $17C8|!addr,y					; |
		LDA #$0F							; | set smoke timer
		STA $17CC|!addr,y					; /
		
		++
	endif

	LDA !C2,x								; \ check if the player is riding yoshi
	CMP #$01								; |
	BEQ .riding								; / if so, skip ahead
	LDA #$02								; \ set yoshi to run
	STA !C2,x								; /

	LDA #!dashOffYoshiXSpeed				; \ load speed we want yoshi to run at
	LDY !157C,x								; | check direction
	BEQ +									; | flip value if necessary
	EOR #$FF								; |
	INC										; |
	+										; |
	STA !sprite_speed_x,x					; / set x speed
	RTS

	.riding
	LDA $77									; \ check blocked status
	AND #$03								; | walls only
	BNE ++									; / if blocked, clear x speed
	
	LDA #!dashOnYoshiXSpeed					; \ load speed we want the player to run at
	LDY !157C,x								; | check direction
	BEQ +									; | flip value if necessary
	EOR #$FF								; |
	INC										; |
	+										; |
	STA $7B									; / set x speed
	RTS
	
	++
	STZ $7B									; clear x speed
	RTS

	.done
	SEP #$20
	LDA !sprite_oam_properties,x			; \ return yoshi's color to the normal green
	AND #$F1								; |
	ORA #!green								; |
	STA !sprite_oam_properties,x			; /

	RTS

	if !dashBreakBlocks
	DashBreakBlocks:
		LDA !157C,x							; \ use direction as index
		ASL									; |
		TAY									; /

		LDA !sprite_x_low,x					; \ set block x position
		CLC : ADC dashBlockXOffsets,y		; |
		STA $9A								; |
		INY									; |
		LDA !sprite_x_high,x				; |
		ADC dashBlockXOffsets,y				; |
		STA $9B								; /
		
		LDA !sprite_y_low,x					; \ set block y position
		STA $98								; |
		LDA !sprite_y_high,x				; |
		STA $99								; /
		
		STZ $1933|!addr						; layer 1 only
		
		REP #$20
		JSL GetMap16						; \ get map16 tile
		BMI ++								; | if $FFFF, skip ahead
		CMP #$011E							; | check if turn block
		BEQ +								; | if so, continue
		CMP #$012E							; | check if throw block
		BNE ++								; / if not, skip ahead
		
		+
		SEP #$20
		
		LDA #$02							; \ generate tile
		STA $9C								; |
		JSL $00BEB0							; /
		
		PHB									; \ bank wrapper stuff for the shatter block routine
		LDA #$02							; |
		PHA									; |
		PLB									; /
		LDA #$00							; \ shatter block
		JSL $028663							; /
		
		LDA $98								; \ also get the block below
		CLC : ADC #$10						; |
		STA $98								; |
		LDA $99								; |
		ADC #$00							; |
		STA $99								; /
		
		JSL $00BEB0							; generate tile
		
		LDA #$00							; \ shatter block
		JSL $028663							; /
		
		PLB
		
		++
		SEP #$20
		RTS
	endif

;#########;
;# Blimp #;
;#########;

Blimp:
	CMP #$0001								; \ check if we should finish
	BNE +									; | if not, continue
	JMP .done								; |
	+										; |
	CMP #!blimpWarn							; | check if we should warn the player
	BNE +									; | if not, skip ahead
	LDY #!warningSFX						; | warn player with sfx
	STY !warningChannel						; /
	
	+
	DEC !blimpFree							; decrement the timer
	SEP #$20
	
	LDA !C2,x
	CMP #$01
	BNE .notRiding
	
	LDA #$80								; \ scroll camera
	STA $1406|!addr							; /
	
	STZ $00
	LDA #!blimpSlowRiseSpeed
	BIT $15									; \ check if A/B held
	BMI ++									; / if so, skip ahead
	
	if !blimpEnableSFX
		LDA !blimpFree						; \ play a sound effect every so often
		AND #$07							; |
		BNE +								; |
		LDA #$21							; |
		STA $1DFC|!addr						; |
		+									; /
	endif
	
	INC $00
	LDA #!blimpFastRiseSpeed
	
	++
	STA $7D
	
	if !blimpEnableSmokeTrail
		LDA !blimpFree						; \ check if we should display a new smoke tile
		AND #$07							; |
		BNE ++								; / if not, skip ahead
		
		LDY #$03							; \ loop to find a free smoke slot
		-									; |
		LDA $17C0|!addr,y					; |
		BEQ +								; |
		DEY									; |
		BPL -								; |
		BRA ++								; / skip ahead if none found
		
		+
		LDA #$01							; \ set smoke type
		STA $17C0|!addr,y					; |
		LDA !sprite_y_low,x					; | set smoke y position
		STA $17C4|!addr,y					; |
		LDA !sprite_x_low,x					; | set smoke x position
		STA $17C8|!addr,y					; |
		PHY									; |
		LDY $00								; |
		LDA blimpSmokeTimes,y				; | set smoke timer
		PLY									; |
		STA $17CC|!addr,y					; /
		
		++
	endif
	
	RTS
	
	.notRiding
	LDA #!blimpFallSpeed
	STA !sprite_speed_y,x
	
	RTS

	.done
	SEP #$20
	LDA !sprite_oam_properties,x			; \ return yoshi's color to the normal green
	AND #$F1								; |
	ORA #!green								; |
	STA !sprite_oam_properties,x			; /

	RTS

;########;
;# Bulb #;
;########;

Bulb:
	CMP #$0001								; \ check if we should finish
	BNE +									; | if not, continue
	JMP .done								; |
	+										; |
	CMP #!bulbWarn							; | check if we should warn the player
	BNE +									; | if not, skip ahead
	LDY #!warningSFX						; | warn player with sfx
	STY !warningChannel						; /
	
	+
	DEC !bulbFree							; decrement the timer
	SEP #$20
	
	if !bulbEnableSparkles
		LDA !C2,x							; \ check if riding yoshi
		CMP #$01							; |
		BNE +								; | if not, skip ahead
		JSL $02858F							; | add sparkle effect
		+									; /
	endif
	
	if !bulbDynamicExanimation
		REP #$20							; \ set exanimation trigger based on the timer left
		LDA !bulbFree						; |
		LSR #!bulbExanimationExtender		; |
		AND #$00FF							; |
		SEP #$20							; |
		STA $7FC070+!bulbManualTrigger		; /
	else
		LDA #$01							; \ set exanimation trigger to just be on
		STA $7FC070+!bulbManualTrigger		; /
	endif

	RTS

	.done
	SEP #$20
	LDA #$00								; \ reset exanimation trigger
	STA $7FC070+!bulbManualTrigger			; /
	
	LDA !sprite_oam_properties,x			; \ return yoshi's color to the normal green
	AND #$F1								; |
	ORA #!green								; |
	STA !sprite_oam_properties,x			; /

	RTS
	
;##################;
;# Other Routines #;
;##################;

if !dashBreakBlocks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetBlock - SA-1 Hybrid version (ripped from pixi)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this routine will get Map16 value
; If position is invalid range, will return 0xFFFF.
;
; input:
; $98-$99 block position Y
; $9A-$9B block position X
; $1933   layer
;
; output:
; A Map16 lowbyte (or all 16bits in 16bit mode)
; Y Map16 highbyte
;
; by Akaginite
;
; It used to return FF but it also fucked with N and Z lol, that's fixed now
; Slightly modified by Tattletale
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro assert_lm_version(version, define)
	!lm_version #= ((read1($0FF0B4)-'0')*100)+((read1($0FF0B6)-'0')*10)+(read1($0FF0B7)-'0')
	if !lm_version >= <version>
		!<define> = 1
	else
		!<define> = 0
	endif
endmacro

%assert_lm_version(257, "EXLEVEL")

GetMap16:
	PHX
	PHP
	REP #$10
	PHB
	LDY $98
	STY $0E
	LDY $9A
	STY $0C
	SEP #$30
	LDA $5B
	LDX $1933|!addr
	BEQ .layer1
	LSR A
.layer1
	STA $0A
	LSR A
	BCC .horz
	LDA $9B
	LDY $99
	STY $9B
	STA $99
.horz
if !EXLEVEL
	BCS .verticalCheck
	REP #$20
	LDA $98
	CMP $13D7|!addr
	SEP #$20
	BRA .check
endif
.verticalCheck
	LDA $99
	CMP #$02
.check
	BCC .noEnd
	PLB
	PLP
	PLX
	LDA #$FFFF
	RTL
	
.noEnd
	LDA $9B
	STA $0B
	ASL A
	ADC $0B
	TAY
	REP #$20
	LDA $98
	AND.w #$FFF0
	STA $08
	AND.w #$00F0
	ASL #2			; 0000 00YY YY00 0000
	XBA			; YY00 0000 0000 00YY
	STA $06
	TXA
	SEP #$20
	ASL A
	TAX
	
	LDA $0D
	LSR A
	LDA $0F
	AND #$01		; 0000 000y
	ROL A			; 0000 00yx
	ASL #2			; 0000 yx00
	ORA #$20		; 0010 yx00
	CPX #$00
	BEQ .noAdd
	ORA #$10		; 001l yx00
.noAdd
	TSB $06			; $06 : 001l yxYY
	LDA $9A			; X LowByte
	AND #$F0		; XXXX 0000
	LSR #3			; 000X XXX0
	TSB $07			; $07 : YY0X XXX0
	LSR A
	TSB $08

	LDA $1925|!addr
	ASL A
	REP #$31
	ADC $00BEA8|!bank,x
	TAX
	TYA
if !sa1
    ADC.l $00,x
    TAX
    LDA $08
    ADC.l $00,x
else
    ADC $00,x
    TAX
    LDA $08
    ADC $00,x
endif
	TAX
	SEP #$20
if !sa1
	LDA $410000,x
	XBA
	LDA $400000,x
else
	LDA $7F0000,x
	XBA
	LDA $7E0000,x
endif
	SEP #$30
	XBA
	TAY
	XBA

	PLB
	PLP
	PLX
	RTL
endif
