		; --- ayFX REPLAYER v2.0M ---

		; --- v2.0T  New ayFX replayer routine. T -> Triple FX replayer

ayFX_SETUP0:	; ---          ayFX replayer setup          ---
		; --- INPUT: HL -> pointer to the ayFX bank ---
		ld	[ayFX_BANK],hl			; Current ayFX bank
ayFX_STOP0:	ld	a,255				; Lowest ayFX priority
		ld	[ayFX_C1],a			; First channel minimum priority
		ld	[ayFX_C2],a			; First channel minimum priority
		ld	[ayFX_C3],a			; First channel minimum priority
		ret					; Return
ayFX_END0:	; --- End of an ayFX stream ---
		ld	[IX],255			; Priority saved (not playing ayFX stream)
		ret					; Return

ayFX_INIT0:	; ---     INIT A NEW ayFX STREAM     ---
		; --- INPUT: A -> sound to be played ---
		; ---        C -> sound priority     ---
		; --- Checks the priorities of playing ayFX streams to place ---
		; --- the new one on the channel with lowest priority        ---
		push	bc				; Store bc in stack
		push	de				; Store de in stack
		push	hl				; Store hl in stack
		push	IX				; Store IX in stack
		; --- Check if the index is in the bank ---
		ld	b,a				; b:=a (new ayFX stream index)
		ld	hl,[ayFX_BANK]			; Current ayFX BANK
		ld	a,[hl]				; Number of samples in the bank
		or	a				; If zero (means 256 samples)...
		jp	z,.CHECK_PRI			; ...goto .CHECK_PRI
		; The bank has less than 256 samples
		ld	a,b				; a:=b (new ayFX stream index)
		cp	[hl]				; If new index is not in the bank...
		ld	a,2				; a:=2 (error 2: Sample not in the bank)
		jp	nc,.INIT_END			; ...we can't init it
.CHECK_PRI:	; --- Places the data on the correct channel                  ---
		; ---   Remember: 0 = highest priority, 15 = lowest priority  ---
		; --- Checks channel 1 ---
		ld	a,[ayFX_C1]			; Priority of ayFX Stream being played on channel 1
		cp	255				; If there's no Stream being played...
		jr	z,.TOC1			; ...place the new Stream on channel 1
		ld	e,a				; Minimum priority of Streams being played
		ld	d,1				; On channel 1
		; --- Checks channel 2 ---
		ld	a,[ayFX_C2]			; Priority of ayFX Stream being played on channel 2
		cp	255				; If there's no Stream being played...
		jr	z,.TOC2				; ...place the new Stream on channel 2
		cp	e				; Compare priority with minimum one
		jr	nc,.CHECKC3			; If P(C2) > min, go to .CHECKC3
		ld	e,a				; Minimum priority of Streams being played
		ld	d,2				; On channel 2
.CHECKC3:	; --- Checks channel 3 ---
		ld	a,[ayFX_C3]			; Priority of ayFX Stream being played on channel 3
		cp	255				; If there's no stream being played
		jr	z,.TOC3			; ...place the new Stream on channel 3
		cp	e				; Compare priority with minimum one
		jr	nc,.CHECKMIN			; If P(C3) > min, go to .CHECKMIN
		ld	e,a				; Minimum priority of Streams being played
		ld	d,3				; On channel 3
.CHECKMIN:	; --- Checks if minimum priority is lower than priority of the new Stream ---
		ld	a,c				; Priority of the new Stream
		cp	e				; Minimum priority of Streams being played
		ld	a,1				; a:=1 (error 1: A sample with higher priority is being played)
		jp	nc,.INIT_END			; ...we can't play the new ayFX Stream
		; --- The new stream substitues the minimum priority Stream being played ---
		ld	a,d				; Channel of minimum priority
		cp	1				; If it's 1...
		jr	z,.TOC1			; ...send Stream to channel 1
		cp	2				; If it's 2...
		jr	z,.TOC2			; ...send Stream to channel 2
.TOC3:		; --- Stream will be played on channel 3
		ld	IX,ayFX_C3			; Pointer to the chanel data
		jr	.SETDATA			; Go to .SETDATA
.TOC2:		; --- Stream will be played on channel 2
		ld	IX,ayFX_C2			; Pointer to the channel data
		jr	.SETDATA			; Go to .SETDATA
.TOC1:		; --- Stream will be played on channel 1
		ld	IX,ayFX_C1			; Pointer to the chanel data
.SETDATA:	; --- Set data on the correct channel ---
		ld	a,c				; a:=New priority
		and	$0F				; We mask the priority
		ld	[IX],a				; new ayFX stream priority saved in RAM
		; --- Calculate the pointer to the new ayFX stream ---
		ld	de,[ayFX_BANK]			; de:=Current ayFX bank
		inc	de				; de points to the increments table of the bank
		ld	l,b				; l:=b (new ayFX stream index)
		ld	h,0				; hl:=b (new ayFX stream index)
		add	hl,hl				; hl:=hl*2
		add	hl,de				; hl:=hl+de (hl points to the correct increment)
		ld	e,[hl]				; e:=lower byte of the increment
		inc	hl				; hl points to the higher byte of the correct increment
		ld	d,[hl]				; de:=increment
		add	hl,de				; hl:=hl+de (hl points to the new ayFX stream)
		ld	[IX+1],l			; Pointer lower byte saved in RAM
		ld	[IX+2],h			; Pointer higher byte saved in RAM
		xor	a				; a:=0 (no errors)
.INIT_END:	pop	IX				; Retrieve IX from stack
		pop	hl				; Retrieve hl from stack
		pop	de				; Retrieve de from stack
		pop	bc				; Retrieve bc from stack
		ret					; Return

ayFX_PLAY0:																; --- Plays next frame of each ayFX Stream ---
			
		ld	hl,0														; hl:=0
		ld	[ayFX_REGS+7],hl											; Clears mixer and volume of channel A
		ld	[ayFX_REGS+9],hl											; Clears volume of channels B and C
		ld	IX,ayFX_C1													; Channel 1
		ld	a,1															; a:=1
		call	.ayFX_PlayChannel										; Play Channel 1
		ld	IX,ayFX_C2													; Channel 2
		ld	a,2															; a:=2
		call	.ayFX_PlayChannel										; Play Channel 2
		ld	IX,ayFX_C3													; Channel 3
		ld	a,3															; a:=3
.ayFX_PlayChannel:														; --- Plays a channel stream ---
		ld	[ayFX_CHANNEL],a											; Sets current channel
		ld	a,[IX]														; a:=Current ayFX stream priority
		or	a															; If priority has bit 7 on...
		ret	m															; ...return
		; --- Extract control byte from stream ---
		ld	l,[IX+1]			; Pointer to the current ayFX stream (lower byte)
		ld	h,[IX+2]			; Pointer to the current ayFX stream (higher byte)
		ld	c,[hl]				; c:=Control byte
		inc	hl				; Increment pointer
		; --- Check if there's new tone on stream ---
		bit	5,c				; If bit 5 c is off...
		jp	z,.CHECK_NN			; ...jump to .CHECK_NN (no new tone)
		; --- Extract new tone from stream ---
		ld	e,[hl]				; e:=lower byte of new tone
		inc	hl				; Increment pointer
		ld	d,[hl]				; d:=higher byte of new tone
		inc	hl				; Increment pointer
		ld	[ayFX_TONE],de			; ayFX tone updated
.CHECK_NN:	; --- Check if there's new noise on stream ---
		bit	6,c				; if bit 6 c is off...
		jp	z,.SETPOINTER			; ...jump to .SETPOINTER (no new noise)
		; --- Extract new noise from stream ---
		ld	a,[hl]				; a:=New noise
		inc	hl				; Increment pointer
		cp	$20				; If it's an illegal value of noise (used to mark end of stream)...
		jp	z,ayFX_END			; ...jump to ayFX_END
		ld	[ayFX_NOISE],a			; ayFX noise updated
.SETPOINTER:	; --- Update ayFX pointer ---
		ld	[IX+1],l			; Pointer lower byte saved in RAM
		ld	[IX+2],h			; Pointer higher byte saved in RAM
		; --- Extract volume ---
		ld	a,c				; a:=Control byte
		and	$0F				; lower nibble
		ld	[ayFX_VOLUME],a			; ayFX volume updated
		ret	z				; Return if volume is zero (don't copy ayFX values in to ayFX_REGS)
		; -------------------------------------
		; --- COPY ayFX VALUES IN TO ayFX_REGS ---
		; -------------------------------------
		; --- Set noise channel ---
		bit	7,c				; If noise is off...
		jp	nz,.SETMASKS			; ...jump to .SETMASKS
		ld	a,[ayFX_NOISE]			; ayFX noise value
		ld	[ayFX_REGS+6],a			; copied in to ayFX_REGS (noise channel)
.SETMASKS:	; --- Set mixer masks ---
		ld	a,c				; a:=Control byte
		and	$90				; Only bits 7 and 4 (noise and tone mask for psg reg 7)
		cp	$90				; If no noise and no tone...
		ret	z				; ...return (don't copy ayFX values in to ayFX_REGS)
		; --- Copy ayFX values in to ayFX_REGS ---
		rrc	a				; Rotate a to the right (1 TIME)
		rrc	a				; Rotate a to the right (2 TIMES) (OR mask)
		ld	d,$DB				; d:=Mask for psg mixer (AND mask)
		ld	hl,ayFX_CHANNEL			; ayFX playing channel
		ld	b,[hl]				; Channel counter
.CHK1:		; --- Check if playing channel was 1 ---
		djnz	.CHK2				; Decrement and jump if channel was not 1
.PLAY_C:	; --- Play ayFX stream on channel C ---
		call	.SETMIXER			; Set PSG mixer value (a:=ayFX volume)
		ld	[ayFX_REGS+10],a		; Volume copied in to ayFX_REGS (channel C volume)
		bit	2,c				; If tone is off...
		ret	nz				; ...return
		ld	hl,[ayFX_TONE]			; ayFX tone value
		ld	[ayFX_REGS+4],hl		; copied in to ayFX_REGS (channel C tone)
		ret					; Return
.CHK2:		; --- Check if playing channel was 2 ---
		rrc	d				; Rotate right AND mask
		rrc	a				; Rotate right OR mask
		djnz	.CHK3				; Decrement and jump if channel was not 2
.PLAY_B:	; --- Play ayFX stream on channel B ---
		call	.SETMIXER			; Set PSG mixer value (a:=ayFX volume)
		ld	[ayFX_REGS+9],a			; Volume copied in to ayFX_REGS (channel B volume)
		bit	1,c				; If tone is off...
		ret	nz				; ...return
		ld	hl,[ayFX_TONE]			; ayFX tone value
		ld	[ayFX_REGS+2],hl			; copied in to ayFX_REGS (channel B tone)
		ret					; Return
.CHK3:		; --- Check if playing channel was 3 ---
		rrc	d				; Rotate right AND mask
		rrc	a				; Rotate right OR mask
.PLAY_A:	; --- Play ayFX stream on channel A ---
		call	.SETMIXER			; Set PSG mixer value (a:=ayFX volume)
		ld	[ayFX_REGS+8],a			; Volume copied in to ayFX_REGS (channel A volume)
		bit	0,c				; If tone is off...
		ret	nz				; ...return
		ld	hl,[ayFX_TONE]			; ayFX tone value
		ld	[ayFX_REGS+0],hl			; copied in to ayFX_REGS (channel A tone)
		ret					; Return
.SETMIXER:	; --- Set PSG mixer value ---
		ld	c,a				; c:=OR mask
		ld	a,[ayFX_REGS+7]			; a:=PSG mixer value
		and	d				; AND mask
		or	c				; OR mask
		ld	[ayFX_REGS+7],a			; PSG mixer value updated
		ld	a,[ayFX_VOLUME]			; a:=ayFX volume value
		ret					; Return

AYfx_ROUT0:	

		XOR A
	
ROUT_A00:																; --- FIXES BITS 6 AND 7 OF MIXER ---
				
		LD	HL,ayFX_REGS+AR_Mixer
		set	7,[hl]
		res	6,[hl]

		LD C,$A0
		LD HL,ayFX_REGS

.LOUT:	

		OUT [C],A
		INC C
		OUTI 
		DEC C
		INC A
		CP 13
		JR NZ,.LOUT
		OUT [C],A
		LD A,[HL]
	
		AND A
		RET M
		INC C
		OUT [C],A
		RET
