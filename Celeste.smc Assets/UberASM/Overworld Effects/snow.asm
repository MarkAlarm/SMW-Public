;############################################;
;# 128 Bullet Sprite System                 #;
;# By MarkAlarm                             #;
;# Credit if used, do not claim as your own #;
;############################################;

;#####################;
;# Defines and Stuff #;
;#####################;

	!max = 64										; max number of bullets. default is 64, max is 128
	!startRAM = $7FA200								; requires (!max * 15) bytes ($7FA200)
	
	!bulletIndex = $13C8|!addr						; 1 byte of freeram
	!oamIndex = $13E6|!addr							; 2 bytes of freeram

	; do not edit anything past this point, unless you know what you're doing

	!bullet_state = !startRAM+(!max*$00)
	!bullet_x_low = !startRAM+(!max*$01)
	!bullet_x_high = !startRAM+(!max*$02)
	!bullet_y_low = !startRAM+(!max*$03)
	!bullet_y_high = !startRAM+(!max*$04)
	!bullet_speed_x = !startRAM+(!max*$05)
	!bullet_speed_y = !startRAM+(!max*$06)
	!bullet_speed_x_frac = !startRAM+(!max*$07)
	!bullet_speed_y_frac = !startRAM+(!max*$08)
	!bullet_misc_1 = !startRAM+(!max*$09)
	!bullet_misc_2 = !startRAM+(!max*$0A)
	!bullet_misc_3 = !startRAM+(!max*$0B)
	!bullet_misc_4 = !startRAM+(!max*$0C)
	!bullet_misc_5 = !startRAM+(!max*$0D)
	!bullet_misc_6 = !startRAM+(!max*$0E)

init:
	LDX #!max-1
	
	LDA #$00
	STA !bulletIndex
	STA !oamIndex
	STA !oamIndex+1
	
	-
	STA !bullet_state,x
	STA !bullet_x_low,x
	STA !bullet_x_high,x
	STA !bullet_y_low,x
	STA !bullet_speed_x,x
	STA !bullet_speed_y,x
	STA !bullet_speed_x_frac,x
	STA !bullet_speed_y_frac,x
	STA !bullet_misc_1,x
	STA !bullet_misc_2,x
	STA !bullet_misc_3,x
	STA !bullet_misc_4,x
	STA !bullet_misc_5,x
	STA !bullet_misc_6,x
	
	DEX
	BPL -
	
	RTL

main:
	LDA $1B87
	BEQ +
	RTL
	+
	
	PHB : PHK : PLB
	
	JSR AdvancedRNG
	
	LDA $14
	AND #$07
	BNE ++
	
	LDX #!max-1
	-
	LDA !bullet_state,x
	BEQ +
	DEX
	BPL -
	BRA ++
	
	+
	LDA #$01
	STA !bullet_state,x
	
	JSL $01ACF9
	
	LDA $148D
	STA !bullet_x_low,x
	LDA #$00
	STA !bullet_x_high,x
	LDA #$20
	STA !bullet_y_low,x
	LDA #$00
	STA !bullet_y_high,x
	
	JSL $01ACF9
	LDA $148D
	AND #$07
	SEC : SBC #$04
	STA !bullet_speed_x,x
	
	LDA $148E
	AND #$03
	CLC : ADC #$04
	STA !bullet_speed_y,x
	
	JSL $01ACF9
	LDY #$E2
	LDA $148D
	AND #$01
	BEQ +
	LDY #$F2
	+
	TYA
	STA !bullet_misc_1,x
	
	LDA $148E
	AND #$03
	ASL #6
	STA !bullet_misc_2,x
	
	++
	LDX #!max-1
	
	LDA #$FC
	STA !oamIndex
	LDA #$01
	STA !oamIndex+1
	STZ $08
	
	-
	LDA !bullet_state,x
	BEQ +
	
	
	STX !bulletIndex
	JSR RunBullet
	
	+
	DEX
	BPL -
	
	
	PLB
	RTL
	
Offscreen:
	SEP #$30
	LDA #$00
	STA !bullet_state,x
	RTS
	
RunBullet:
	; offscreen and position handling
	LDA !bullet_x_low,x
	STA $00
	LDA !bullet_x_high,x
	STA $01
	LDA !bullet_y_low,x
	STA $02
	LDA !bullet_y_high,x
	STA $03

	REP #$20

	LDA $00							; \ handle the sprite going offscreen, x based
	CMP #$FFE8						; |
	BCS +							; |
	CMP #$0118						; |
	BCS Offscreen					; |
	+								; /
	
	LDA $02							; \ handle the sprite going offscreen, y based
	CMP #$FFF8						; |
	BCS +							; |
	CMP #$00F0						; |
	BCS Offscreen					; |
	+								; /

	SEP #$20
	
	; graphics routine
	REP #$10
	
	LDA #$F0
	LDY !oamIndex
	
	--
	CMP $0201|!addr,y
	BEQ +
	
	-
	DEY #4
	BPL --
	
	BRA Offscreen
	
	+
	CPY #$0108
	BCC +
	CPY #$0124
	BCS +
	LDY #$0108
	BRA -
	
	+
	LDA $00
	STA $0200|!addr,y
	LDA $02
	STA $0201|!addr,y
	LDA !bullet_misc_1,x
	STA $0202|!addr,y
	LDA #%00110010
	ORA !bullet_misc_2,x
	STA $0203|!addr,y
	
	DEY #4
	STY !oamIndex
	
	REP #$20
	TYA
	LSR #2
	INC
	TAY
	SEP #$20

	LDA $01
	AND #$01
	STA $0420|!addr,y
	
	SEP #$10
	


	; speed routine adapted from the original game's code ($02FF98 and $02FFA3)
	LDA !bullet_speed_y,x
	ASL #4
	CLC : ADC !bullet_speed_y_frac,x
	STA !bullet_speed_y_frac,x
	PHP
	LDA !bullet_speed_y,x
	LSR #4
	CMP #$08
	LDY #$00
	BCC +
	ORA #$F0
	DEY
	
	+
	PLP
	ADC !bullet_y_low,x
	STA !bullet_y_low,x
	TYA
	ADC !bullet_y_high,x
	STA !bullet_y_high,x
	
	LDA !bullet_speed_x,x
	ASL #4
	CLC : ADC !bullet_speed_x_frac,x
	STA !bullet_speed_x_frac,x
	PHP
	LDA !bullet_speed_x,x
	LSR #4
	CMP #$08
	LDY #$00
	BCC +
	ORA #$F0
	DEY
	
	+
	PLP
	ADC !bullet_x_low,x
	STA !bullet_x_low,x
	TYA
	ADC !bullet_x_high,x
	STA !bullet_x_high,x
	
	RTS
	
AdvancedRNG:
	JSL $01ACF9
	
	LDA $13
	AND #$01
	BEQ +
	JSL $01ACF9
	
	+
	
	RTS
	
