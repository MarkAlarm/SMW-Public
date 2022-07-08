!berrySprite = $04
!berryFree = $18CC
!trailNum = $1510				; what number the strawberry is on the trail.

db $37

JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH
JMP Cape : JMP Fireball
JMP MarioCorner : JMP MarioBody : JMP MarioHead
JMP WallFeet : JMP WallBody

MarioBelow:
MarioAbove:
MarioSide:
	BRA WallBody
SpriteV:
SpriteH:
Cape:
Fireball:
	RTL
MarioCorner:
MarioBody:
MarioHead:
WallFeet:
WallBody:
	LDA #!berrySprite
	SEC
	%spawn_sprite()
	BCS +
	
	INC !berryFree
	LDA !berryFree
	STA !trailNum,x
	
	PHY
	PHX
	JSR GetMap16
	PLX
	PLY

	STA $7FAB40,x
	STA $62

	PHY					; \ erase the current block.
	LDA #$02			; |
	STA $9C				; |
	JSL $00BEB0			; |
	PLY					; /
	
	+

RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Important routine, do not touch.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetBlock - SA-1 Hybrid version
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
	LDX $1933
	BEQ Layer1
	LSR A
Layer1:	
	STA $0A
	LSR A
	BCC Horz
	LDA $9B
	LDY $99
	STY $9B
	STA $99
Horz:
if !EXLEVEL
	REP #$20
	LDA $98
	CMP $13D7
	SEP #$20
else
	LDA #$99
	CMP #$02
endif
	BCC NoEnd
	PLB
	PLP
	PLX
	LDA #$FF
	RTS
	
NoEnd:
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
	BEQ NoAdd
	ORA #$10		; 001l yx00
NoAdd:	
	TSB $06			; $06 : 001l yxYY
	LDA $9A			; X LowByte
	AND #$F0		; XXXX 0000
	LSR #3			; 000X XXX0
	TSB $07			; $07 : YY0X XXX0
	LSR A
	TSB $08

	LDA $1925
	ASL A
	REP #$31
	ADC $00BEA8,x
	TAX
	TYA

    ADC $00,x
    TAX
    LDA $08
    ADC $00,x

	TAX
	SEP #$20

	LDA $7F0000,x
	XBA
	LDA $7E0000,x

	SEP #$30
	XBA
	TAY
	XBA

	PLB
	PLP
	PLX
	RTS

print "Celeste strawberry. This is the tile that will spawn a berry, which will trail behind mario."

