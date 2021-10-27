;##############################;
;# Jump Trigger Switch        #;
;# By MarkAlarm               #;
;# Please give credit if used #;
;##############################;

;###########;
;# Options #;
;###########;

!switch = $14AF|!addr			; switch to trigger upon jumping. default is the on/off flag, could be used with exanimation as well

!inputBufferA = $0F42|!addr		; 3 bytes of freeram, used to compensate for pressing A at most 2 frames early
!inputBufferB = $0F45|!addr		; 3 bytes of freeram, used to compensate for pressing A at most 2 frames early

;#########;
;# Notes #;
;#########;

; the reason this frame buffer exists is to compensate for
; both SMW's input delay and any delay that may occur by using UberASM.
; this also means a frame perfect or buffered jump off the ground
; will still trigger the switch, which should be nice for kaizo hack leniency.

;########;
;# Code #;
;########;

init:
	STZ !inputBufferA			; \ clear out the A/B input buffer
	STZ !inputBufferA+1			; |
	STZ !inputBufferA+2			; |
	STZ !inputBufferB			; |
	STZ !inputBufferB+1			; |
	STZ !inputBufferB+2			; /
	
	RTL

main:
	LDA $77						; \ check if on the ground
	AND #$04					; |
	BEQ +						; / if not, skip ahead
	
	LDA $7D						; \ check if falling
	BPL +						; / if so, skip ahead
	
	LDA !inputBufferA			; \ get all of the inputs from within the last 2 frames
	ORA !inputBufferA+1			; |
	ORA !inputBufferA+2			; |
	ORA !inputBufferB			; |
	ORA !inputBufferB+1			; |
	ORA !inputBufferB+2			; /
	
	AND #$80					; \ check only if A/B are pressed within the last 2 frames
	BEQ +						; /
	
	LDA !switch					; \ change the switch state
	EOR #$01					; |
	STA !switch					; /
	
	+
	LDA !inputBufferA+1			; \ cycle in the newest A input, trash the oldest
	STA !inputBufferA			; |
	LDA !inputBufferA+2			; |
	STA !inputBufferA+1			; |
	LDA $18						; |
	STA !inputBufferA+2			; /
	
	LDA !inputBufferB+1			; \ cycle in the newest B input, trash the oldest
	STA !inputBufferB			; |
	LDA !inputBufferB+2			; |
	STA !inputBufferB+1			; |
	LDA $16						; |
	STA !inputBufferB+2			; /
	
	RTL
