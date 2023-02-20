ANIMACION_DE_MARCA:
		
		ld		hl,COPY_MARCA
		ld		a,21
		ld		(fotogramas_animaciones),a
		ld		a,0
		ld		(que_page),a
	
		ld		ix,datos_del_copy
		
		ld		bc,#00a8
		ld		(ix),c													;x origen
		ld		(ix+1),b
		ld		bc,#0100
		ld		(ix+2),c												;y origen
		ld		(ix+3),b
		xor		a
		ld		(ix+4),a												;x destino
		ld		(ix+5),a
		ld		bc,#0040
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		bc,#0006
		ld		(ix+8),c												;pixels en x
		ld		(ix+9),b
		ld		bc,#0054	
		ld		(ix+10),c												;pixels en y
		ld		(ix+11),b
														
		xor		a
		ld		(ix+13),a												;cómo es el copy	
		ld		a,#d0
		ld		(ix+14),a
		
		xor		a
		ld		(fotograma_de_dos),a	
			
.SECUENCIA_1:

		ld		a,5
		ld		(ralentizando),a
		
		call	RALENTIZA_7
						
		ld		hl,datos_del_copy
		
	
				
		call	DoCopy_7													;mandamos copiar el fotograma adecuado
		
		ld		l,(ix)													;hacemos las variaciones adecuadas de cara al siguiente copy
		ld		h,(ix+1)
		ld		de,#0008
		or		a
		sbc		hl,de
		ld		(ix),l
		ld		(ix+1),h
				
		ld		l,(ix+8)
		ld		h,(ix+9)
		ld		de,#0008
		adc		hl,de
		ld		(ix+8),l
		ld		(ix+9),h
		
		ld		a,(fotograma_de_dos)									;dependiendo del fotograma (0 o 1) cogerá y copiará en un sitio diferente
		cp		0
		jp		z,.SECUENCIA_1_FOTOGRAMA_2

.SECUENCIA_1_FOTOGRAMA_1:
		
		ld		hl,#0100
			
		jp		.SECUENCIA_1_FINAL_FOTOGRAMA_ORIGEN
	
	

.SECUENCIA_1_FOTOGRAMA_2:
		
		ld		hl,#0156
				
.SECUENCIA_1_FINAL_FOTOGRAMA_ORIGEN:

		ld		(ix+2),l
		ld		(ix+3),h
		
		ld		a,(fotograma_de_dos)
		cp		0
		jp		z,.SECUENCIA_1_FOTOGRAMA_DESTINO_2

.SECUENCIA_1_FOTOGRAMA_DESTINO_1:
		
		xor		a														;Una vez ya se han pasado todas las variables que dependen del número de fotograma
		ld		(fotograma_de_dos),a									;cambiamos el fotograma de cara al siguiente copy
		ld		hl,#0040
		
		jp		.SECUENCIA_1_FINAL_FOTOGRAMA_DESTINO
		
.SECUENCIA_1_FOTOGRAMA_DESTINO_2:

		call	VDP_LISTO_7
		inc		a														;Una vez ya se han pasado todas las variables que dependen del número de fotograma
		ld		(fotograma_de_dos),a									;cambiamos el fotograma de cara al siguiente copy
		
		ld		hl,#0240
		
.SECUENCIA_1_FINAL_FOTOGRAMA_DESTINO:

		ld		(ix+6),l
		ld		(ix+7),h
								
		call	.COMUN_EN_SECUENCIAS
		jp		nz,.SECUENCIA_1

		ld		hl,COPY_MARCA											;Al haber entre 2  3 copys cada vez, lo hago por DATAS a partir de aquí
		
		ld		a,7
		ld		(fotogramas_animaciones),a
		
.SECUENCIA_2:

		ld		a,5
		ld		(ralentizando),a

		call	RALENTIZA_7
[2]		call	DoCopy_7												;mandamos copiar el fotograma adecuado
		CALL	VDP_LISTO_7
		call	.COMUN_EN_SECUENCIAS
		jp		nz,.SECUENCIA_2
				
		ld		a,55
		ld		(ralentizando),a
					
.SECUENCIA_3:
		
		
[3]		call	DoCopy_7
		call	RALENTIZA_7
[3]		call	DoCopy_7
		call	.COMUN_EN_SECUENCIAS

		di
		ld		a,16
		ld		(en_que_pagina_el_page_2),a
		ld		[#7000],a
		ei
		
		ld		a,8
		ld		c,0
		call	ayFX_INIT
		
		ld		a,125
		ld		(ralentizando),a

		call	RALENTIZA_7

		ret		

.COMUN_EN_SECUENCIAS:
		
		di
		ld		a,16
		ld		(en_que_pagina_el_page_2),a
		ld		[#7000],a
		ei

		ld		a,2
		ld		c,0
		call	ayFX_INIT
						
		ld		a,(que_page)
		cp		0
		jp		z,.PAGE_0
		
		call	VDP_LISTO_7
		
		ld		a,2
		call	setpage_7
		xor		a
		ld		(que_page),a
		
		jp		.FINAL_COMUN_EN_SECUENCIAS
		
.PAGE_0:

		call	VDP_LISTO_7
		
		xor		a
		call	setpage_7
		ld		a,2
		ld		(que_page),a
		
.FINAL_COMUN_EN_SECUENCIAS:
		
		
		ld		a,(fotogramas_animaciones)
		dec		a
		ld		(fotogramas_animaciones),a
		cp		0
				
		ret

FADE_OUT_MARCA:
		
		ld		hl,paleta_marca_2
		xor		a
		ld		(var_cuentas_paleta),a
		
.LOOP:	
	
		call	SetPalet_7												;cargamos la paleta de colores haciendo un fade out
		ld		a,(var_cuentas_paleta)
		inc		a
		ld		(var_cuentas_paleta),a
		cp		7
		jp		nz,.LOOP
		
		ret
						
COPY_MARCA:
	
	; Cartel entero desplazándose al centro
	; Trozo en negro para borrar lo que se va dejando atrás
	
	DW	#0000,#0156,#0000,#0240,#00ae,#0054
	DB	0,0,#D0
		DW	#0000,#01b4,#0000,#0240,#0002,#0054
		DB	0,0,#D0
	DW	#0000,#0100,#0008,#0040,#00ae,#0054
	DB	0,0,#D0
		DW	#0000,#01b4,#0000,#0040,#0009,#0054
		DB	0,0,#D0
	DW	#0000,#0156,#0010,#0240,#00ae,#0054
	DB	0,0,#D0
		DW	#0000,#01b4,#0000,#0240,#0011,#0054
		DB	0,0,#D0
	DW	#0000,#0100,#0018,#0040,#00ae,#0054
	DB	0,0,#D0
		DW	#0000,#01b4,#0000,#0040,#0019,#0054
		DB	0,0,#D0
	DW	#0000,#0156,#0020,#0240,#00ae,#0054
	DB	0,0,#D0
		DW	#0000,#01b4,#0000,#0240,#0021,#0054
		DB	0,0,#D0
	DW	#0000,#0100,#0028,#0040,#00ae,#0054
	DB	0,0,#D0
		DW	#0000,#01b4,#0000,#0040,#0029,#0054
		DB	0,0,#D0
	DW	#0000,#0156,#0030,#0240,#00ae,#0054
	DB	0,0,#D0
		DW	#0000,#01b4,#0000,#0240,#0031,#0054
		DB	0,0,#D0
			
	; Dos últimos fotogramas de la secuencia
	
	DW	#0000,#0156,#0030,#0240,#00ae,#0054
	DB	0,0,10010000b
		DW	#0000,#01b4,#0000,#0240,#0031,#0054
		DB	0,0,10010000b
	DW	#00aE,#0100,#00a3,#0240,#004C,#0055
	DB	0,0,10010000b
	DW	#0000,#0156,#0030,#0040,#00ae,#0054
	DB	0,0,10010000b
		DW	#0000,#01b4,#0000,#0040,#0031,#0054
		DB	0,0,10010000b
	DW	#00aE,#0154,#00a3,#003e,#004C,#0055
	DB	0,0,10010000b	
	
	; Color de la primera paleta
	
paleta_marca_1:	

	db	#00,#00,#56,#05,#22,#02,#02,#02,#10,#01,#34,#04,#44,#05,#32,#03,#30,#02,#42,#04,#66,#06,#02,#00,#63,#06,#26,#05,#24,#04,#77,#07

paleta_marca_2:	

	db	#00,#00,#45,#04,#11,#01,#01,#01,#00,#00,#23,#03,#33,#04,#21,#02,#20,#01,#31,#03,#55,#05,#01,#00,#52,#05,#15,#04,#13,#03,#66,#06	
	db	#00,#00,#34,#03,#00,#00,#00,#00,#00,#00,#12,#02,#22,#03,#10,#01,#10,#00,#20,#02,#44,#04,#00,#00,#41,#04,#04,#03,#02,#02,#55,#05
	db	#00,#00,#23,#02,#00,#00,#00,#00,#00,#00,#01,#01,#11,#02,#00,#00,#00,#00,#10,#01,#33,#03,#00,#00,#30,#03,#03,#02,#01,#01,#44,#04	
	db	#00,#00,#12,#01,#00,#00,#00,#00,#00,#00,#00,#00,#00,#01,#00,#00,#00,#00,#00,#00,#22,#02,#00,#00,#20,#02,#02,#01,#00,#00,#33,#03	
	db	#00,#00,#01,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#11,#01,#00,#00,#10,#01,#01,#00,#00,#00,#22,#02	
	db	#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#11,#01	
	db	#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00	
			                           

