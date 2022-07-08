!flags			= $0DC3		; wall jump flags
!switch			= $14AF		; on/off flag

db $37

JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH
JMP Cape : JMP Fireball
JMP MarioCorner : JMP MarioBody : JMP MarioHead
JMP WallFeet : JMP WallBody

MarioBelow:
MarioAbove:
MarioSide:
SpriteV:
SpriteH:
Cape:
Fireball:
	RTL

MarioCorner:
MarioBody:
MarioHead:
	STZ !flags
	
	LDA !switch
	BEQ +
	RTL
	+

	LDA $9A
	AND #$F0
	SEC : SBC #$03
	CMP $94
	BEQ +
	BPL +
	RTL
	
	+
	LDA $15
	AND #$40
	BEQ WallBody
	
	LDA #$20
	STA $13E0
	
	LDA #$00
	STA $140D
	
	STZ $7B
	STZ $7D

	REP #$20
	LDA $96
	SEC
	SBC #$0002
	STA $96
	SEP #$20
	
	LDA $16
	ORA $18
	AND #$80
	BEQ +
	LDA #$06
	STA $1DFC
	LDA #$40
	STA $7B
	LDA #$C0
	STA $7D
	LDA #$01
	STA $76
	
	+
	
	RTL

WallFeet:
WallBody:
	RTL




print "Core conveyor wall, which you can grab onto and jump off of. This one goes on the right side of an already existing wall."