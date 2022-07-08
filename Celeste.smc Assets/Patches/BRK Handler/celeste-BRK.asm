
table table.txt

reset bytes



!RAM_HUD          = $7F0000

!preservedStart   = $0F5E

!preservedA       = !preservedStart+$00		; 2 bytes
!preservedX       = !preservedStart+$02		; 2 bytes
!preservedY       = !preservedStart+$04		; 2 bytes
!preservedD       = !preservedStart+$06		; 2 bytes
!preservedP       = !preservedStart+$08		; 1 byte
!preservedPC      = !preservedStart+$09		; 3 bytes
!preservedStack   = !preservedStart+$0C		; 2 bytes
!preservedBRK     = !preservedStart+$0E		; 1 byte

!defaultTile      = $FC
!defaultProps     = %00111000

org $00FFE6
	dw BRKPointer

org $00FFE0
	BRKPointer:
		autoclean JML HandleBRK
	
freecode

InfoText:
	db "       - Software Break -       "
	db "                                "
	db "     The game reached a BRK     "
	db "  instruction. You will need to "
	db "       reset your console.      "
	
!infoRows = 5
!infoStartingRow = 1

RegistersText:
	db " ROM: $pcpcpc       SP: $spsp   "
	db " A: $aaaa  X: $xxxx  Y: $yyyy   "
	db " D: $dpdp  P: --------          "
	db "                                "
	db " BRK Parameter: $bk             "
	
!registersRows = 5
!registersStartingRow = 7

PlayerText:
	db " Player X: $xpxp $xs            "
	db " Player Y: $ypyp $ys            "
	
!playerRows = 2
!playerStartingRow = 13

MiscText:
	db " Level Number: $llll            "
	db " Current Sprite Index: $ii      "
	
!miscRows = 2
!miscStartingRow = 16

StackText:
	db " Attempting Stack Dump At $spsp "
	db "                                "	; \ up to 16 bytes of stack data can be printed here without issue
	db "                                "	; /
	
!stackRows = 3
!stackStartingRow = 19

ControllerText:
	db " Held:                 Pressed: "
	db "  - -- -                - -- -  "
	db " - -  - -              - -  - - "
	db "  - -- -                - -- -  "
	
!controllerRows = 4
!controllerStartingRow = 23
	


HandleBRK:
	REP #$30					; 16 bit A/X/Y
	
	STA !preservedA				; preserve A
	STX !preservedX				; preserve X
	STY !preservedY				; preserve Y
	
	TDC							; \ preserve direct page
	STA !preservedD				; /
	TSC							; \ preserve stack pointer
	STA !preservedStack			; /
	
	SEP #$30					; 8 bit A/X/Y
	
	LDA #$80					; \ disable NMI
	TRB $4200					; /
	
	PLA							; \ preserve processor flags
	STA !preservedP				; /
	
	PLA							; \ preserve PC location
	STA !preservedPC			; |
	STA $00						; |
	PLA							; |
	STA !preservedPC+1			; |
	STA $01						; |
	PLA							; |
	STA !preservedPC+2			; |
	DEC							; | decrement bank location so the FFFF index wraps itself back to the original PC location, minus 1 (which would be the BRK parameter)
	STA $02						; /
	
	REP #$10					; \ preserve the BRK parameter
	LDY #$FFFF					; |
	LDA [$00],y					; |
	STA !preservedBRK			; |
	SEP #$10					; /
	
	LDA #$8F					; \ turn off screen, full brightness
	STA $2100					; /
	
	JSR ClearLayer3HUD			; clear out the HUD
	JSR UpdateBreakData			; actually get all the break data and store it to necessary RAM mirror
	JSR UpdateLayer3			; write data to the screen
	
	LDA #%00000100				; \ enable layer 3 only, mainscreen
	STA $212C					; /
	LDA #%00000010				; \ enable layer 2 only, subscreen
	STA $212D					; /
	
	LDA #$0F					; \ turn on screen, full brightness
	STA $2100					; /
	
	
	
	; past this point is code that would attempt to restore the game state. it didn't work, so i added an infinite loop
	BRA $FE
	
	REP #$10
	
	LDY #$0020
	LDX #$0000
	-
	DEX
	BNE -
	DEY
	BNE -

	LDX #$01FF
	TXS
	
	SEP #$10
	
	LDA #$8F					; \ turn off screen, full brightness
	STA $2100					; /
	
	JSR ClearLayer3HUD			; clear out the HUD
	JSR UpdateLayer3			; write data to the screen
	
	LDA #%00011111				; \ enable layers, mainscreen
	STA $212C					; /
	LDA #%00011111				; \ enable layers, subscreen
	STA $212D					; /
	
	LDA #$0F					; \ turn on screen, full brightness
	STA $2100					; /
	
	STZ $10
	
	LDA #$00
	PHA
	PLB
	
	LDA #$80
	TSB $4200
	
	JML $90BC7C
	
ClearLayer3HUD:
	REP #$10

	LDX #$07FF
	
	-
	LDA #!defaultProps
	STA !RAM_HUD,x
	DEX
	
	LDA #!defaultTile
	STA !RAM_HUD,x
	DEX
	BPL -
	
	SEP #$10
	
	RTS
		
LoadTiles:
	REP #$20
	
	LDY #$80
	STY $2115
	LDA #$4000
	STA $2116
	
	LDA #$1801
	STA $4320
	LDA #.tiles
	STA $4322
	LDY.b #.tiles>>16
	STY $4324
	LDA #$1000
	STA $4325
	
	LDY #$04
	STY $420B

	SEP #$20
	
	RTS
	
	.tiles
		incbin tiles.bin

UpdateBreakData:
	PHB
	PHK
	PLB

	JSR DisplayInfoText
	JSR DisplayRegisters
	JSR DisplayPlayerInfo
	JSR DisplayMisc
	JSR DisplayStack
	JSR DisplayControllerData
	JSR DisplayValues
	
	PLB
	RTS
	
	DisplayInfoText:
		REP #$10
		LDY #(!infoRows*$0020)-1
		LDX #(!infoStartingRow*$0040)+(!infoRows*$0040)-1
		
		-
		LDA #$38
		STA !RAM_HUD,x
		DEX
		
		LDA InfoText,y
		STA !RAM_HUD,x
		
		DEY
		DEX
		CPX #(!infoStartingRow*$0040)
		BPL -
		
		SEP #$10
		RTS
	
	DisplayRegisters:
		REP #$10
		LDY #(!registersRows*$0020)-1
		LDX #(!registersStartingRow*$0040)+(!registersRows*$0040)-1
		
		-
		LDA #$38
		STA !RAM_HUD,x
		DEX
		
		LDA RegistersText,y
		STA !RAM_HUD,x
		
		DEY
		DEX
		CPX #(!registersStartingRow*$0040)
		BPL -
		
		SEP #$10
		RTS
		
	DisplayPlayerInfo:
		REP #$10
		LDY #(!playerRows*$0020)-1
		LDX #(!playerStartingRow*$0040)+(!playerRows*$0040)-1
		
		-
		LDA #$38
		STA !RAM_HUD,x
		DEX
		
		LDA PlayerText,y
		STA !RAM_HUD,x
		
		DEY
		DEX
		CPX #(!playerStartingRow*$0040)
		BPL -
		
		SEP #$10
		RTS
		
	DisplayMisc:
		REP #$10
		LDY #(!miscRows*$0020)-1
		LDX #(!miscStartingRow*$0040)+(!miscRows*$0040)-1
		
		-
		LDA #$38
		STA !RAM_HUD,x
		DEX
		
		LDA MiscText,y
		STA !RAM_HUD,x
		
		DEY
		DEX
		CPX #(!miscStartingRow*$0040)
		BPL -
		
		SEP #$10
		RTS
		
	DisplayStack:
		REP #$10
		LDY #(!stackRows*$0020)-1
		LDX #(!stackStartingRow*$0040)+(!stackRows*$0040)-1
		
		-
		LDA #$38
		STA !RAM_HUD,x
		DEX
		
		LDA StackText,y
		STA !RAM_HUD,x
		
		DEY
		DEX
		CPX #(!stackStartingRow*$0040)
		BPL -
		
		SEP #$10
		RTS
		
	DisplayControllerData:
		REP #$10
		LDY #(!controllerRows*$0020)-1
		LDX #(!controllerStartingRow*$0040)+(!controllerRows*$0040)-1
		
		-
		LDA #$38
		STA !RAM_HUD,x
		DEX
		
		LDA ControllerText,y
		STA !RAM_HUD,x
		
		DEY
		DEX
		CPX #(!controllerStartingRow*$0040)
		BPL -
		
		SEP #$10
		
		LDY #$16
		-
		LDA #$27
		STA $00
		LDA #$38
		STA $01

		LDA .partOfController,y
		TAX
		LDA $0DA2,x

		AND .buttonChecks,y
		BEQ +
		LDA .buttonTiles,y
		STA $00
		LDA .buttonProps,y
		STA $01

		+
		PHY
		
		TYA
		ASL
		TAY
		
		REP #$20
		LDA .indexToHUD,y
		CLC : ADC #((!controllerStartingRow+1)*$0040)
		REP #$10
		TAX
		
		LDA $00
		STA !RAM_HUD,x
		SEP #$30
		
		PLY
		
		DEY
		BPL -
		
		RTS
			
		.partOfController				; first controller = held, second controller = pressed
			db $00,$02,$02,$02			; \   ^   L R   X
			db $00,$00,$00,$02			; | <   >     Y   A
			db $00,$00,$00,$00			; /   v   E T   B
			
			db $01,$03,$03,$03			; \   ^   L R   X
			db $01,$01,$01,$03			; | <   >     Y   A
			db $01,$01,$01,$01			; /   v   E T   B
			
		.buttonChecks
			db $08,$20,$10,$40			; \   ^   L R   X
			db $02,$01,$40,$80			; | <   >     Y   A
			db $04,$20,$10,$80			; /   v   E T   B
			
			db $08,$20,$10,$40			; \   ^   L R   X
			db $02,$01,$40,$80			; | <   >     Y   A
			db $04,$20,$10,$80			; /   v   E T   B
			
		.buttonTiles
			db $35,$15,$1B,$21			; \   ^   L R   X
			db $45,$45,$22,$0A			; | <   >     Y   A
			db $35,$0E,$1D,$0B			; /   v   E T   B
			
			db $35,$15,$1B,$21			; \   ^   L R   X
			db $45,$45,$22,$0A			; | <   >     Y   A
			db $35,$0E,$1D,$0B			; /   v   E T   B
			
		.buttonProps
			db $38,$38,$38,$38			; \   ^   L R   X
			db $38,$78,$38,$38			; | <   >     Y   A
			db $B8,$38,$38,$38			; /   v   E T   B
			
			db $38,$38,$38,$38			; \   ^   L R   X
			db $38,$78,$38,$38			; | <   >     Y   A
			db $B8,$38,$38,$38			; /   v   E T   B
			
		.indexToHUD
			dw $0004,$0008,$000A,$000E	; \   ^   L R   X
			dw $0042,$0046,$004C,$0050	; | <   >     Y   A
			dw $0084,$0088,$008A,$008E	; /   v   E T   B
			
			dw $0030,$0034,$0036,$003A	; \   ^   L R   X
			dw $006E,$0072,$0078,$007C	; | <   >     Y   A
			dw $00B0,$00B4,$00B6,$00BA	; /   v   E T   B
		
	DisplayValues:
		REP #$10
		
		LDX #((!registersStartingRow+0)*$0040)+$000E
		LDA !preservedPC+2
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedPC+2
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA !preservedPC+1
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedPC+1
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA !preservedPC
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedPC
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!registersStartingRow+0)*$0040)+$0032
		LDA !preservedStack+1
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedStack+1
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA !preservedStack
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedStack
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!registersStartingRow+1)*$0040)+$000A
		LDA !preservedA+1
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedA+1
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA !preservedA
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedA
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!registersStartingRow+1)*$0040)+$001E
		LDA !preservedX+1
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedX+1
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA !preservedX
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedX
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!registersStartingRow+1)*$0040)+$0032
		LDA !preservedY+1
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedY+1
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA !preservedY
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedY
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!registersStartingRow+2)*$0040)+$000A
		LDA !preservedD+1
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedD+1
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA !preservedD
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedD
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!registersStartingRow+2)*$0040)+$001C
		LDA !preservedP
		AND #$80
		BEQ +
		LDA #$17
		STA !RAM_HUD,x
		+
		INX #2
		LDA !preservedP
		AND #$40
		BEQ +
		LDA #$1F
		STA !RAM_HUD,x
		+
		INX #2
		LDA !preservedP
		AND #$20
		BEQ +
		LDA #$16
		STA !RAM_HUD,x
		+
		INX #2
		LDA !preservedP
		AND #$10
		BEQ +
		LDA #$21
		STA !RAM_HUD,x
		+
		INX #2
		LDA !preservedP
		AND #$08
		BEQ +
		LDA #$0D
		STA !RAM_HUD,x
		+
		INX #2
		LDA !preservedP
		AND #$04
		BEQ +
		LDA #$12
		STA !RAM_HUD,x
		+
		INX #2
		LDA !preservedP
		AND #$02
		BEQ +
		LDA #$23
		STA !RAM_HUD,x
		+
		INX #2
		LDA !preservedP
		AND #$01
		BEQ +
		LDA #$0C
		STA !RAM_HUD,x
		+
		
		LDX #((!registersStartingRow+4)*$0040)+$0022
		LDA !preservedBRK
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA !preservedBRK
		AND #$0F
		STA !RAM_HUD,x
		
		
		
		LDX #((!playerStartingRow+0)*$0040)+$0018
		LDA $95
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $95
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA $94
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $94
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!playerStartingRow+0)*$0040)+$0024
		LDA $7B
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $7B
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!playerStartingRow+1)*$0040)+$0018
		LDA $97
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $97
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA $96
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $96
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!playerStartingRow+1)*$0040)+$0024
		LDA $7D
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $7D
		AND #$0F
		STA !RAM_HUD,x
		
		
		
		LDX #((!miscStartingRow+0)*$0040)+$0020
		LDA $010C
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $010C
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		LDA $010B
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $010B
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!miscStartingRow+1)*$0040)+$0030
		LDA $15E9
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		LDA $15E9
		AND #$0F
		STA !RAM_HUD,x
		
		
		
		LDX #(!stackStartingRow*$0040)+$0036
		
		LDA !preservedStack+1
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		
		LDA !preservedStack+1
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		
		LDA !preservedStack
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		
		LDA !preservedStack
		AND #$0F
		STA !RAM_HUD,x
		
		LDX #((!stackStartingRow+1)*$0040)
		LDY #$01FF

		-
		LDA #$3C
		STA !RAM_HUD,x
		INX #2

		LDA $0000,y
		AND #$F0
		LSR #4
		STA !RAM_HUD,x
		INX #2
		
		LDA $0000,y
		AND #$0F
		STA !RAM_HUD,x
		INX #2
		
		LDA #$FC
		STA !RAM_HUD,x
		INX #2
		
		DEY
		CPY !preservedStack
		BPL -
		
		SEP #$10
		RTS
		
		
	;DisplayTemplate:
	;	REP #$10
	;	LDY #(!templateRows*$0020)-1
	;	LDX #(!templateStartingRow*$0040)+(!templateRows*$0040)-1
	;	
	;	-
	;	LDA #$38
	;	STA !RAM_HUD,x
	;	DEX
	;	
	;	LDA TemplateText,y
	;	STA !RAM_HUD,x
	;	
	;	DEY
	;	DEX
	;	CPX #(!templateStartingRow*$0040)
	;	BPL -
	;	
	;	SEP #$10
	;	RTS
		
	
UpdateLayer3:
	REP #$20
	
	LDY #$80
	STY $2115
	LDA #$5000
	STA $2116
	
	LDA #$1801
	STA $4320
	
	LDA #!RAM_HUD
	STA $4322
	LDY #$7F
	STY $4324
	LDA #$1000
	STA $4325
	
	LDY #$04
	STY $420B
	
	SEP #$20
	
	RTS
	
print "Inserted ", bytes, " bytes."
