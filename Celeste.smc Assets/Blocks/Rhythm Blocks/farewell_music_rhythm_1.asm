
!stillFrames = $28

!BlackHoleDMAchannel = 3					; value from 0 to 7, will do DMA on the specified channel.
!BlackHoleDMAchannelbin = %00001000			; 7/6/5/4/3/2/1/0

; starting address would be $9800 in VRAM, 2BPP

!VRAM = $9800/2

!animationRate = $05

!holeframes = 24

BlackHoleFrames:
	dw BlackHolePt1+$0000,BlackHolePt1+$0600		; part 1 contains the frames that range from 0 degrees to 105 degrees of rotation (inclusive)
	dw BlackHolePt1+$0C00,BlackHolePt1+$1200
	dw BlackHolePt1+$1800,BlackHolePt1+$1E00
	dw BlackHolePt1+$2400,BlackHolePt1+$2A00
	
	dw BlackHolePt2+$0000,BlackHolePt2+$0600		; part 2 contains the frames that range from 120 degrees to 225 degrees of rotation (inclusive)
	dw BlackHolePt2+$0C00,BlackHolePt2+$1200
	dw BlackHolePt2+$1800,BlackHolePt2+$1E00
	dw BlackHolePt2+$2400,BlackHolePt2+$2A00
	
	dw BlackHolePt3+$0000,BlackHolePt3+$0600		; part 3 contains the frames that range from 240 degrees to 345 degrees of rotation (inclusive)
	dw BlackHolePt3+$0C00,BlackHolePt3+$1200
	dw BlackHolePt3+$1800,BlackHolePt3+$1E00
	dw BlackHolePt3+$2400,BlackHolePt3+$2A00
	
!free = $18CC
!nextFrameTimer = $0DDB
	

; beat block below

!beats = $0060
!frames = $04

!songPositionLow = $7FB004
!songPositionHigh = $7FB005
!nextPosition = $1923		; $1926 for other

init:
	; black hole below
	
	STZ !free
	LDA #!animationRate
	STA !nextFrameTimer
	
	; beat block below
	
	REP #$20
	
	-
	LDA $2140
	CMP $2140
	BNE -

	-
	LDA !nextPosition
	SEC : SBC $2140
	CMP #!beats
	BCC .dontChangeYet
	
	LDA !nextPosition
	CLC : ADC #!beats
	STA !nextPosition
	BRA -
	
	.dontChangeYet
	SEP #$20
	
	LDA #!frames
	STA $7FC070
	
	RTL


main:
	; beat block below
	REP #$20

	LDA !nextPosition
	SEC : SBC !songPositionLow
	CMP #!beats
	BCC .dontChangeYet

	LDA !nextPosition
	CLC : ADC #!beats
	STA !nextPosition

	SEP #$20

	LDA $7FC070
	INC
	CMP #!frames
	BCC +
	LDA #$00
	+
	STA $7FC070
	
	RTL

.dontChangeYet
	SEP #$20
	RTL
	

nmi:
	; black hole below
	
	LDA $9D
	ORA $13D4
	BEQ +
	RTL
	
	+
	
	LDA !nextFrameTimer
	DEC
	STA !nextFrameTimer
	BEQ +

	RTL
	
	+
	
	PHB
	PHK
	PLB
	
	LDA #!animationRate
	STA !nextFrameTimer
	
	LDA !free
	INC
	CMP #!holeframes
	BNE +
	LDA #$00
	+
	STA !free

	LDA !free
	ASL
	TAX
	
	JSR GetBank

	REP #$20
	
	LDA #$1801
	STA $43!{BlackHoleDMAchannel}0
	
	LDA BlackHoleFrames,x
	STA $43!{BlackHoleDMAchannel}2

	;LDY.b #BlackHolePt1>>16			; we already got Y from the bank get routine, so we good
	STY $43!{BlackHoleDMAchannel}4
	
	LDA #$0600
	STA $43!{BlackHoleDMAchannel}5
	
	LDY #$80
	STY $2115
	
	LDA #!VRAM
	STA $2116
	
	LDY #!BlackHoleDMAchannelbin
	STY $420B
	
	SEP #$20

	PLB
	RTL
	
GetBank:
	LDA !free
	LSR #3
	AND #$03
	BEQ Part1
	CMP #$01
	BEQ Part2
	CMP #$02
	BEQ Part3
	RTS
	
	
	Part1:
	LDY.b #BlackHolePt1>>16
	RTS
	
	Part2:
	LDY.b #BlackHolePt2>>16
	RTS
	
	Part3:
	LDY.b #BlackHolePt3>>16
	RTS
