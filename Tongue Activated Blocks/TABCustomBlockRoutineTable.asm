;###############################;
;# Tongued Block Routine Table #;
;###############################;

tongueBlockRoutines:
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0000-$000F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0010-$001F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0020-$002F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0030-$003F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0040-$004F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0050-$005F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0060-$006F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0070-$007F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0080-$008F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0090-$009F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $00A0-$00AF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $00B0-$00BF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $00C0-$00CF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $00D0-$00DF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $00E0-$00EF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $00F0-$00FF
	
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0100-$010F
	dw None,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk													; map16 tiles $0110-$011F
	dw InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,InterBlk,None,None,InterBlk,InterBlk,None,None																; map16 tiles $0120-$012F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0130-$013F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0140-$014F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0150-$015F
	dw None,None,None,None,None,None,None,None,None,None,InterBlk,InterBlk,None,None,None,None																										; map16 tiles $0160-$016F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0170-$017F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0180-$018F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $0190-$019F
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $01A0-$01AF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $01B0-$01BF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $01C0-$01CF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $01D0-$01DF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $01E0-$01EF
	dw None,None,None,None,None,None,None,None,None,None,None,None,None,None,None,None																												; map16 tiles $01F0-$01FF

	; and so on, add more rows at your leisure. note that this takes a ton of space and you'll probably run out if you get too far into map16
