;############################################;
;# Disable grabbing in water                #;
;# By MarkAlarm                             #;
;# Credit unnecessary, but appreciated      #;
;############################################;

main:
	LDA $75			; \ check if in water
	BEQ +			; / if not, return
	LDA #$40		; \ disable Y/X (which in turn, disables grabbing items)
	TRB $15			; |
	TRB $16			; |
	TRB $17			; |
	TRB $18			; /
	+
	RTL
