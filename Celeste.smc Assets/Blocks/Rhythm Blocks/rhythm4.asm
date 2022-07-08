!exanimationStart = $7FC070
!manualSlot = $00
!solidFrame = $03

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
MarioCorner:
MarioBody:
MarioHead:
WallFeet:
WallBody:

	LDY #$01
	LDA #$30
	STA $1693

	LDA !exanimationStart+!manualSlot
	CMP #!solidFrame
	BEQ +
	
	LDY #$00
	LDA #$25
	STA $1693

	+
	RTL




print "Farewell rhythm block using manual trigger !manualSlot"