;############################################;
;# On/Off Toggleable Ice/Water              #;
;# By MarkAlarm                             #;
;# Credit unnecessary, but appreciated      #;
;############################################;

!switch = $14AF|!addr	; ram address to use for toggling between ice and water. default is on/off flag
!option = BEQ			; set to BEQ for on = ice, off = water. set to BNE for on = water, off = ice

main:
	LDA !switch			; \ load the flag we want to check
	!option +			; / branch depending on what we want
	LDA #$01			; \ set water flag
	STA $85				; /
	STZ $86				; clear ice flag
	RTL
	
	+
	STZ $85				; clear water flag
	LDA #$80			; \ set ice flag
	STA $86				; /
	RTL
