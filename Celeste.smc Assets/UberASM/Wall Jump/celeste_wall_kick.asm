;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wall Kick by MarioE
; UberASM version by KevinM (v1.1 edited)
;
; Various fixes by Kaizoman (Thomas), dtothefourth, and MiniMawile303.
;
; Allows Mario to perform a wall kick by sliding along a wall and pressing the
; B button.
; This is essentially the same code as the "Wall Kick" patch (with some improvements),
; but it must be inserted with UberASMTool, so you can have it only on certain levels
; (if you insert it as level ASM).
;
; It uses $0DC3, $0DC4 and $0DC5 as free ram.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!require_powerup	= !false	; Whether or not wall jumping requires a powerup.
!AllowSpinJump 		= $01  		; Allow spinjumping off walls $00 - No, $01 - Yes
!AllowWhileSpinning	= !true		; If true, Mario can slide on a wall and wall jump even when he's spin jumping
!AllowFromSameDirection = !true	; False = as the original patch.
								; True = after kicking a wall, Mario can kick again from the same wall/another wall facing the same direction.
								
!AllowDucking		= !true		; Allow walljumping while Mario is ducking. Default is false.

!no_back_time		= $0D		; The time to disable moving back after a wall kick. The smaller the value, the higher the control of the player over Mario's movement while wall jumping, but it also makes it harder to do big wall jumps.
!kick_x_speed		= $20		; The wall kick X speed.
!kick_y_speed		= $B8		; The wall kick Y speed.
!slide_accel		= $04		; The sliding acceleration.
!slide_speed		= $24		; The sliding speed.

!SpinJumpSFX 		= $04	; Spin jump sound effect. 1DFC
!SpinJumpSFXPort	= $1DFC
!JumpSFX 			= $35	; Regular jump sound effect. 1DFA
!JumpSFXPort		= $1DFC
!WallSFX			= $01	; Sound effect to make when jumping off of a wall. 1DF9
!WallSFXPort		= $1DF9

; Change these if there's a free ram conflict with another patch.
!flags			= $0DC3|!addr	; The wallkick flags. (RAM)
!no_back_timer	= $0DC4|!addr	; The timer for not moving back. (RAM)
!temp_y_spd		= $0DC5|!addr	; The temporary Y speed. (RAM)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!false	= 0	; Don't change these.
!true	= 1

main:
		STZ $1888|!addr
		STZ $1889|!addr
		
		LDA $77
		AND #$04
		BEQ .in_air
		
		STZ !flags
		RTL
		
	.in_air:			; not on the ground
		LDA !flags		; branch if already sliding
		AND #$03
		BNE .slide
		
		LDA !no_back_timer
		BEQ +
		
		DEC !no_back_timer
		LDA !flags
		LSR
		LSR
		TRB $15
		TRB $16
		
	+	;LDA $7D			; return if moving upwards
		;BMI .return		; commenting out both of these for legacy. holy SHIT why was this a thing... it works so much nicer without this check.
		
	if !require_powerup
		LDA $19
		BEQ .return
	endif	
	
		LDA $71
		
	if !AllowDucking == !false
		ORA $73
	endif
	
		ORA $74
		ORA $75
		ORA $1407|!addr
		
	if !AllowWhileSpinning == !false
		ORA $140D|!addr
	endif

		ORA $1470|!addr
		ORA $1493|!addr
		ORA $187A|!addr
		BNE .return		; return if: hurt, ducking, climbing, in water, flying, carrying something, riding yoshi, or ending the level
		LDA $7E
		CMP #$0B
		BCC .return
		CMP #$E6
		BCS .return		; return if touching the sides of the screen
		LDA !flags
		LSR
		LSR
	if !AllowFromSameDirection == !false
		AND $77
		BNE .return
	endif
		LDA $15
		AND #$03
		CMP #$03
		BEQ .return		; return if both left/right held
		LDA $15
		AND $77
		BEQ .return		; return if blocked in the direction being moved in
		;JSR CheckTile
		;BCC .stop
		;LDA $76 : INC : EOR #$03
	;.okay:
		STA !flags
		LDA $7D
		STA !temp_y_spd
	.return	RTL

	.stop:
		STZ !flags
		RTL


	.slide:					; sticking to a wall
		LDA $71
		ORA $75
		ORA $1470|!addr
		ORA $187A|!addr		; if hurt, on yoshi, carrying something, or in water, stop sliding
		BNE .stop
		
		LDY #$00
		LDA $7B
		CLC
		ADC #$07
		CMP #$0F
		BCS .stop			; if mario's speed goes > 8, stop sliding
		LDA $15
		AND #$03
		CMP #$03
		BEQ .stop			; if L+R is pressed, stop sliding
		;LDA $15
		;AND !flags
		;BEQ .stop			; if L/R are no longer pressed in the appropriate direction, stop
		
		LDA #$40
		TRB $15
		TRB $16
		
		LDA !flags
		DEC
		STA $76

		JSR CheckTile		; if no longer against a wall, fall off
		BCC .stop
		
		LDA $16
		BMI .kick
    if !AllowSpinJump	
        LDA $18
        BMI .spinjump
    endif
		
		LDA $14
		AND #$07
		BNE ++
		
		LDX $76
		LDY #$03
	-	LDA $17C0|!addr,y
		BNE +
		
		LDA #$03
		STA $17C0|!addr,y
		LDA $94
		CLC
		ADC.l smoke_x_offsets,x
		STA $17C8|!addr,y
		LDA $96
		CLC
		ADC #$10
		STA $17C4|!addr,y
		LDA #$13
		STA $17CC|!addr,y
		BRA ++
		
	+	DEY
		BPL -

	++	LDA #$0D
		STA $13E0|!addr
		
		LDA !temp_y_spd
		CLC
		ADC #!slide_accel
		STA $7D
		STA !temp_y_spd
		BMI .return2
		CMP #!slide_speed
		BCC .return2
		LDA #!slide_speed
		STA $7D
		STA !temp_y_spd
	.return2
		RTL
  if !AllowSpinJump	
    .spinjump
	  LDA #$01
      STA $140D|!addr
      LDA #!SpinJumpSFX
      STA !SpinJumpSFXPort|!addr
      BRA +++
  endif
 
	.kick
		STZ $140D|!addr
		LDA #!JumpSFX
		STA !JumpSFXPort|!addr
		
	+++
		INC $1406|!addr
	    LDA #!WallSFX
		STA !WallSFXPort|!addr
		
		
		LDA #$0B
		STA $72
		LDA #!kick_y_speed
		STA $7D
		
		LDX $76
		LDA.l wall_kick_x_speeds,x
		STA $7B
		
		LDA !flags
		TRB $15
		TRB $16
		ASL
		ASL
		STA !flags
		
		LDA #!no_back_time
		STA !no_back_timer
		
		LDY #$03
	-	LDA $17C0|!addr,y
		BNE +
		
		INC
		STA $17C0|!addr,y
		LDA $94
		STA $17C8|!addr,y
		LDA $96
		CLC
		ADC #$10
		STA $17C4|!addr,y
		LDA #$10
		STA $17CC|!addr,y
		RTL
		
	+	DEY
		BPL -
		RTL

smoke_x_offsets:
		db $0C,$FE

wall_kick_x_speeds:
		db $100-!kick_x_speed,!kick_x_speed


CheckTile:	; man, smw's a pain in the ass
	LDA $81
	BNE +
	
	LDA $80
	CMP #$D0		; originally C0
	BCS .retNo
	+

	LDA $76
	AND #$01
	ASL
	TAX
  
	REP #$20
	LDA $94	; xpos
	CLC : ADC.l .xOffs,x
	STA $9A
	LDA $96
	CLC : ADC #$001A
	STA $98
	SEP #$20
	STZ $1933
	
	REP #$20				; \ allow one way walls to be jumped off of.
	JSL GetMap16
	
	CMP #$FFFF
	BEQ .noLookup
	
	CMP #$0C03				; |
	BEQ .retYes
	CMP #$0C13
	BEQ .retYes
	CMP #$0C23
	BEQ .retYes
	CMP #$0C04
	BEQ .retYes
	CMP #$0C14
	BEQ .retYes
	CMP #$0C24
	BEQ .retYes				; |
	
	
	SEP #$20				; /
	
	;REP #$20		; fuck this why is this here i literally hate everything this is so sad can we get an F in chat like tbh
	;CMP #$FFFF		; original value here was #$01FF
	;SEP #$20		;
	;BCC .noLookup	; removed so you can use any map16 tile you want.
	STA $1693		; run a map16 lookup to get the acts-like
	TYA
	PHK
  - PEA.w (-)+9
	PEA $F563-1
	JML $06F608
  .noLookup:
	SEP #$20
  
	CPY #$00		; at this point, good enough for me...
	BEQ .retNo
	LDA $1693
	CMP #$11
	BCC .retNo
	CMP #$6E
	BCS .retNo
	
	CMP #$2F
	BEQ .retNo		; dont allow walljumping on munchers.
  .retYes:
	SEP #$20
	SEC
	RTS
  .retNo:
    LDA $1925
	CMP #$02
	BEQ +
	CLC
    RTS
	+
  
	JSR CheckTileLayer2
	RTS
	
  .xOffs:
	dw $000E,$FFFE

CheckTileLayer2:
	LDA #$01
	STA $1933
	
	REP #$20				; \ allow one way walls to be jumped off of.
	JSL GetMap16
	
	CMP #$FFFF
	BEQ .noLookup
	
	CMP #$0C03				; |
	BEQ .retYes
	CMP #$0C13
	BEQ .retYes
	CMP #$0C23
	BEQ .retYes
	CMP #$0C04
	BEQ .retYes
	CMP #$0C14
	BEQ .retYes
	CMP #$0C24
	BEQ .retYes				; |
	SEP #$20				; /
	
	;REP #$20		; fuck this why is this here i literally hate everything this is so sad can we get an F in chat like tbh
	;CMP #$FFFF		; original value here was #$01FF
	;SEP #$20		;
	;BCC .noLookup	; removed so you can use any map16 tile you want.
	STA $1693		; run a map16 lookup to get the acts-like
	TYA
	PHK
  - PEA.w (-)+9
	PEA $F563-1
	JML $06F608
  .noLookup:
	SEP #$20
  
	CPY #$00		; at this point, good enough for me...
	BEQ .retNo
	LDA $1693
	CMP #$11
	BCC .retNo
	CMP #$6E
	BCS .retNo
	
	CMP #$2F
	BEQ .retNo		; dont allow walljumping on munchers.
  .retYes:
	SEP #$20
	SEC
	RTS
  .retNo:
	CLC
	RTS
	
  .xOffs:
	dw $000E,$FFFE
		
	
	
	
	
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