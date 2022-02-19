;#######################################;
;# Ghost Shell                         #;
;# By MarkAlarm                        #;
;# Credit unnecessary, but appreciated #;
;#######################################;

;######################################################################################;
;# Extra Byte/Bit Information                                                         #;
;#                                                                                    #;
;# Extra Bit                - Unused (may add additional features in a future update) #;
;#                                                                                    #;
;# Extra Byte 1             - Palette number, what palette row to use for the shell   #;
;#                            Use values between $08 and $0F                          #;
;#                                                                                    #;
;# Extra Byte 2             - Kick speed, how fast the shell will be kicked on spawn  #;
;#                            $00: spawn stunned without any speed                    #;
;#                            $2E: vanilla's base kicked speed                        #;
;#                            $01-$20: spawn stunned with speed (not kicked yet)      #;
;#                            $21-$7F: spawn kicked with speed                        #;
;#                                                                                    #;
;######################################################################################;

;##################;
;# State Wrappers #;
;##################;

print "INIT ",pc
	LDA #$04							; \ set to be a normal koopa (but we're messing with it)
	STA !sprite_num,x					; /
	JSL $07F7D2							; set up tweaker bytes
	
	%SubHorzPos()						; \ set facing direction
	TYA									; |
	STA !157C,x							; /
	
	LDA !sprite_tweaker_1686,x			; \ set "don't interact with other sprites" flag
	ORA #$08							; |
	STA !sprite_tweaker_1686,x			; /
	
	LDA !extra_byte_1,x					; \ do math on the first extra byte so that the number picked represents its palette number
	SEC : SBC #$08						; |
	ASL									; |
	STA $00								; /
	
	LDA !sprite_oam_properties,x		; \ set shell color based on the first extra byte
	AND #$F1							; |
	ORA $00								; |
	STA !sprite_oam_properties,x		; /
	
	LDA #$09							; \ set to be stunned
	STA !sprite_status,x				; /
	
	LDA !extra_byte_2,x					; \ check kick speed
	BEQ ++								; / if empty, don't be kicked
	
	INC !sprite_status,x				; now set to be kicked

	LDY !157C,x							; \ check direction
	BEQ +								; |
	EOR #$FF							; | flip value if needed
	INC									; |
	+									; |
	STA !sprite_speed_x,x				; / set x speed
	
	++
	RTL
