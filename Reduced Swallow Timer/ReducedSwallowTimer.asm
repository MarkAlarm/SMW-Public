;#######################################;
;# Reduced Yoshi Swallow Timer         #;
;# By MarkAlarm                        #;
;# Credit unnecessary, but appreciated #;
;#######################################;

;###########;
;# Options #;
;###########;

!reducedSwallowTime = $26					; number of frames (x4) before yoshi swallows his sprite

;########;
;# Code #;
;########;

main:
	LDA #!reducedSwallowTime				; \ get reduced timer length
	CMP $18AC|!addr							; | compare to the current swallow timer
	BCS	+									; | if the reduced time is greater, return
	STA $18AC|!addr							; / set reduced timer
	
	+
	RTL
