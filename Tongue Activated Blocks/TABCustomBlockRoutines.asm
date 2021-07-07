;#################################;
;# Custom Tongued Block Routines #;
;#################################;

; this is only 

; make sure your routine ends in RTS
; also you'll probably want to SEP #$30 in here before using indices
	
None:
	RTS
	
InterBlk:
	SEP #$30
	LDY #$00
	LDA $00
	JSL $00F160
	
	LDA !1594,x
	DEC
	BNE +
	LDA #$08								; \ set tongue timer
	STA !1558,x								; /
	INC !1594,x								; set tongue subroutine
	
	+
	RTS
	
Solid:
	SEP #$30
	
	LDA !1594,x
	DEC
	BNE +
	LDA #$08								; \ set tongue timer
	STA !1558,x								; /
	INC !1594,x								; set tongue subroutine
	
	+
	RTS
	
Template:
	SEP #$30
	; run code
	RTS
