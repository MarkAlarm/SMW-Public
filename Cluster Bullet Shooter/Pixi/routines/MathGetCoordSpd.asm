; 8bit M
; input:
;	$04: speed factor, 16bit, signed
;	$06: angle, 8bit
; output:
;	$00: speed_x, 16bit(rounded/16), signed
;	$02: speed_y, 16bit(rounded/16), signed
;
; GetCoordSpd routine created by worldpeace, used from his math.asm file that can be found (somewhere in his filebin?)
; converted to SA-1 hybrid by MarkAlarm

GetCoordSpd:
	PHB
	PHK
	PLB
	
	PHX
	LDA #$40
	SEC
	SBC $06
	JSR .cos	; sin, rep #$20
	STA $00
	LDA $04
	STA $02
	JSR .multiply
	LDA $00
	PHA
	SEP #$20

	LDA $06
	JSR .cos	; cos, rep #$20
	STA $00
	LDA $04
	STA $02
	JSR .multiply
	PLA
	STA $02

	SEP #$20
	PLX
	
	PLB
	RTL
.cos
	CMP #$80
	BEQ ?++
	BCC ?+
	DEC
	EOR #$FF
?+
	ASL
	TAX
	REP #$20
	LDA .costable,x
	RTS
?++
	REP #$20
	LDA #$F000
	RTS
.costable
	dw $1000,$0FFF,$0FFB,$0FF5,$0FEC,$0FE1,$0FD4,$0FC4,$0FB1,$0F9C,$0F85,$0F6C,$0F50,$0F31,$0F11,$0EEE
	dw $0EC8,$0EA1,$0E77,$0E4B,$0E1C,$0DEC,$0DB9,$0D85,$0D4E,$0D15,$0CDA,$0C9D,$0C5E,$0C1E,$0BDB,$0B97
	dw $0B50,$0B08,$0ABF,$0A73,$0A26,$09D8,$0988,$0937,$08E4,$088F,$083A,$07E3,$078B,$0732,$06D7,$067C
	dw $061F,$05C2,$0564,$0505,$04A5,$0444,$03E3,$0381,$031F,$02BC,$0259,$01F5,$0191,$012D,$00C9,$0065
	dw $0000,$FF9B,$FF37,$FED3,$FE6F,$FE0B,$FDA7,$FD44,$FCE1,$FC7F,$FC1D,$FBBC,$FB5B,$FAFB,$FA9C,$FA3E
	dw $F9E1,$F984,$F929,$F8CE,$F875,$F81D,$F7C6,$F771,$F71C,$F6C9,$F678,$F628,$F5DA,$F58D,$F541,$F4F8
	dw $F4B0,$F469,$F425,$F3E2,$F3A2,$F363,$F326,$F2EB,$F2B2,$F27B,$F247,$F214,$F1E4,$F1B5,$F189,$F15F
	dw $F138,$F112,$F0EF,$F0CF,$F0B0,$F094,$F07B,$F064,$F04F,$F03C,$F02C,$F01F,$F014,$F00B,$F005,$F001
; 16bit M
; input:
;	$00: a, 8bit + 8bit under floating pt, signed
;	$02: b, 8bit + 8bit under floating pt, signed
; output:
;	$00: a*b, 16bit, rounded, signed
.multiply
	LDA $04
	PHA
	LDA $06
	PHA
	SEP #$20
	LDA $01
	EOR $03
	PHA		; sign of a*b
	REP #$20
	LDA $00
	BPL ?+
	DEC
	EOR #$FFFF	; negate (not preserve original values)
	STA $00
?+
	LDA $02
	BPL ?+
	DEC
	EOR #$FFFF
	STA $02
?+

	if !SA1 == 0
		SEP #$20
		LDA $00
		STA $4202
		LDA $02
		STA $4203
		NOP
		NOP
		NOP
		NOP
		REP #$20
		LDA $4216
		STA $04
		SEP #$20

		LDA $01
		STA $4202
		LDA $03
		STA $4203
		NOP
		NOP
		NOP
		NOP
		REP #$20
		LDA $4216
		STA $06
		SEP #$20
	
	else
		STZ $2250
		
		LDA $00
		STA $2251
		LDA $02
		STA $2253
		NOP

		LDA $2306
		STA $04

		LDA $01
		STA $2251
		LDA $03
		STA $2253
		NOP

		LDA $2306
		STA $06
		SEP #$20
	endif

	if !SA1 == 0
		LDA $00
		STA $4202
		LDA $03
		STA $4203
		NOP
		NOP
		NOP
		NOP
		REP #$20
		LDA $4216
	else
		LDA $00
		STA $2251
		LDA $03
		STA $2253
		NOP
		
		LDA $2306
	endif
	SEP #$20
	CLC
	ADC $05
	STA $05
	SEP #$20
	LDA $07
	ADC #$00
	STA $07
	
	if !SA1 == 0
		LDA $01
		STA $4202
		LDA $02
		STA $4203
		NOP
		NOP
		NOP
		NOP
		REP #$20
		LDA $4216
	else
		REP #$20
		LDA $01
		STA $2251
		LDA $02
		STA $2253
		NOP
		LDA $2306
	endif
	CLC
	ADC $05
	STA $05
	SEP #$20
	LDA $07
	ADC #$00
	STA $07

	LDA $05
	BPL ?+
	REP #$20
	INC $06		; round up
	SEP #$20
?+
	PLA
	BPL ?+
	REP #$20
	LDA $06
	DEC
	EOR #$FFFF
	BRA ?++
?+
	REP #$20
	LDA $06
?++
	STA $00
	PLA
	STA $06
	PLA
	STA $04
	RTS		
