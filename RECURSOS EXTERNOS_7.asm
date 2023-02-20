setpage_7:     															;cambiar la página en screen 5 	
	
				add     a,a        			      									;x32
				add     a,a
				add     a,a
				add     a,a
				add     a,a
				add     a,31
				ld      (VDP+2),a
				di
				out     (#99),a
				ld      a,2+128
				ei
				out     (#99),a
				
				ret	

setvdp_write_7: 														;poder escribir en paginas 2 y 3

				rlc     h
				rla
				rlc     h
				rla
				srl     h
				srl     h
				di
				out     (#99),a       									;set bits 15-17
				ld      a,14+128
				out     (#99),a
				ld      a,l           									;set bits 0-7
				nop
				out     (#99),a
				ld      a,h          									;set bits 8-14
				or      64           									; + write access
				ei
				out     (#99),a       
				
				ret	
    
SetPalet_7:		

				LD 		a,(RG0SAV)												;vemos si las interrupciones de linea estan activas
				bit		4,a
				call	nz,PARADA_7 
		
[4]				halt													;crea un retardo entre set palets que da el efecto de fade
				xor			a             								;Set p#pointer to zero.
				di
				out			(#99),a
				ld			a,16+128
				out			(#99),a
				ld			c,#9A
[32]			outi
				ei
				ret

DoCopy_7:

				ld	a,32
				di
				out	(#99),a
				ld	a,17+128
				out	(#99),a
				ld	c,#9B
				
VDPready_7:
	
				ld	a,2
				di
				out	(#99),a												;select s#2
				ld	a,15+128
				out	(#99),a
				in	a,(#99)
				rra
				ld 	a,0													;back to s#0, enable ints
				out	(#99),a
				ld	a,15+128
				ei
				out	(#99),a												;loop if vdp not ready (CE)
				jp	c,VDPready_7
				DW	#A3ED,#A3ED,#A3ED,#A3ED	  							;15x OUTI
				DW	#A3ED,#A3ED,#A3ED,#A3ED	  							;(faster than OTIR)
				DW	#A3ED,#A3ED,#A3ED,#A3ED
				DW	#A3ED,#A3ED,#A3ED
				
				ret

RALENTIZA_7_ESP:


																		;para ralentizar una secuencia. En RALENTIZADO daremos un valor entre 
		
		push	af	
																		;0 y 255 cuanto más alto, más lenta irá la secuencia
		LD 		a,(RG0SAV)												;vemos si las interrupciones de linea estan activas
		bit		4,a
		call	nz,PARADA_7 
		
		pop		af
		
		call	INTERRUMPE_CSP	
		
		halt
		ld		a,(ralentizando)
		dec		a
		ld		(ralentizando),a
		cp		0
		jr.		nz,RALENTIZA_7_ESP
		
		ret


RALENTIZA_7:																;para ralentizar una secuencia. En RALENTIZADO daremos un valor entre 
		
		push	af	
																		;0 y 255 cuanto más alto, más lenta irá la secuencia
		LD 		a,(RG0SAV)												;vemos si las interrupciones de linea estan activas
		bit		4,a
		call	nz,PARADA_7 
		
		pop		af
		
		halt
		ld		a,(ralentizando)
		dec		a
		ld		(ralentizando),a
		cp		0
		jr.		nz,RALENTIZA_7
		
		ret
		
VDP_LISTO_7:

		push	hl														;esperamos a que el fotograma se haya copiado correctamente ya
		call	VDPready_7												;que la VDP trabaja de forma independiente del Z80 y se pueden chocar
		pop		hl														;algunas ordenes (pero a veces se puede aprovechar)

		ret

FADE_7:																	;pasa por una secuencia de 7 palete para crear un fade (0 a 100 o 100 a 0)
		
		LD 		a,(RG0SAV)												;vemos si las interrupciones de linea estan activas
		bit		4,a
		call	nz,PARADA_7
		
		halt
		ld		a,(var_cuentas_paleta_esp)
		cp		1
		jp		z,FADE_7_DE_15
		cp		2
		jp		z,FADE_7_DE_1				

FADE_7_DE_8:

		ld		a,8
		ld		(var_cuentas_paleta),a
		jp		FADE_7_SENTENCIA
		
FADE_7_DE_15:

		ld		a,15
		ld		(var_cuentas_paleta),a
		jp		FADE_7_SENTENCIA

FADE_7_DE_1:

		ld		a,1
		ld		(var_cuentas_paleta),a
						
FADE_7_SENTENCIA:
		
		call	SetPalet_7

		ld		a,(var_cuentas_paleta)
		dec		a
		ld		(var_cuentas_paleta),a
		cp		0

		ret		z

		ld		a,60
					
FADE_7_RETARDO:
		
		PUSH	AF
		
		LD 		a,(RG0SAV)												;vemos si las interrupciones de linea estan activas
		bit		4,a
		call	nz,PARADA_7 
		
		POP		AF
		
		dec		a
		cp		0
		jr.		z,FADE_7_RETARDO
		
		
	
		jr.		FADE_7_SENTENCIA
		
LIMPIA_PANTALLA_0_7:													;un recuadro en la pantalla 0 de color 0 tapandolo todo_va_bien
		
		ld		ix,datos_del_copy
		
		ld		bc,0
		ld		(ix+4),c												;x inicio linea
		ld		(ix+5),b
		ld		bc,0
		ld		(ix+6),c												;y inicio linea
		ld		(ix+7),b
		ld		bc,256
		ld		(ix+8),c												;largo x
		ld		(ix+9),b
		ld		bc,211
		ld		(ix+10),c												;largo y
		ld		(ix+11),b
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,0
		ld		(ix+13),a												;estructura	
		ld		a,10000000b
		ld		(ix+14),a												;especificamos la linea
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		call	VDP_LISTO_7

		ret

LIMPIA_PANTALLA_2_7:													;un recuadro en la pantalla 0 de color 0 tapandolo todo_va_bien
		
		ld		ix,datos_del_copy
		
		ld		bc,0
		ld		(ix+4),c												;x inicio linea
		ld		(ix+5),b
		ld		bc,511
		ld		(ix+6),c												;y inicio linea
		ld		(ix+7),b
		ld		bc,256
		ld		(ix+8),c												;largo x
		ld		(ix+9),b
		ld		(ix+10),c												;largo y
		ld		(ix+11),b
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,0
		ld		(ix+13),a												;estructura	
		ld		a,10000000b
		ld		(ix+14),a												;especificamos la linea
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		call	VDP_LISTO_7

		ret
		
LIMPIA_PANTALLA_0_A_3_7:												;un recuadro en la pantalla 0 de color 0 tapandolo todo_va_bien
		
		ld		ix,datos_del_copy
		
		ld		bc,0
		ld		(ix+4),c												;x inicio linea
		ld		(ix+5),b
		ld		bc,0
		ld		(ix+6),c												;y inicio linea
		ld		(ix+7),b
		ld		bc,256
		ld		(ix+8),c												;largo x
		ld		(ix+9),b
		ld		bc,1024
		ld		(ix+10),c												;largo y
		ld		(ix+11),b
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,0
		ld		(ix+13),a												;estructura	
		ld		a,10000000b
		ld		(ix+14),a												;especificamos la linea
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		call	VDP_LISTO_7

		call	ENASCR
		
		ret

SCROLL_HORIZONTAL_7:

		di																;desconectamos las interrupciones
		out		(#99),a													;apuntamos el dato a poner en el registro
		
		push	af
		
		ld		a,(direccion_scroll_horizontal)
		cp		1
		jp		nz,.PARA_ABAJO

.PARA_ARRIBA
		
		pop		af
		inc		a
		jp		SCROLL_HORIZONTAL_SIGUE_7

.PARA_ABAJO		
		
		pop		af
		dec		a

SCROLL_HORIZONTAL_SIGUE_7:
		
		ld		(var_cuentas_peq),a
		
		ld		a,23+128												;cargamos el valor de registro con el bit 8 establecido (+128)
		ei																;contectamos las interrupciones que se conectarán después de la siguiente orden
		out		(#99),a													;apuntamos al registro adecuado (en este caso el 23 para el scroll)
		
		ret

COPY_A_GUSTO_7:

		ld		ix,datos_del_copy

		ld		c,(iy)
		ld		b,(iy+1)
		ld		(ix),c													;x origen
		ld		(ix+1),b
		ld		c,(iy+2)
		ld		b,(iy+3)
		ld		(ix+2),c												;y origen
		ld		(ix+3),b
		ld		c,(iy+4)
		ld		b,(iy+5)
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		ld		c,(iy+6)
		ld		b,(iy+7)
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		c,(iy+8)
		ld		b,(iy+9)
		ld		(ix+8),c												;pixels en x
		ld		(ix+9),b
		ld		c,(iy+10)
		ld		b,(iy+11)
		ld		(ix+10),c												;pixels en y
		ld		(ix+11),b
		xor		a
		ld		(ix+13),a												;cómo es el copy
		
		ret

lista_de_opciones_7:
		

		dec		a

		ld 		h,0
		ld 		l,a
		add 	hl,hl

		add 	hl,de													;hl ya esta apunTando a la posicion correcta de la tabla
		
		ld 		e,(hl)													;extraemos la direccion de la etiqueta
		inc 	hl
		ld 		d,(hl)													;hl ya tiene la direccion de salto!
		ex 		de,hl
		jp 		(hl)

NUESTRA_ISR_7:


	DI
	ex	af,af'
	ld	a,1																; ponemos registro de estado 1 
	out (099h),a
	ld a,128+15
	out (099h),a
	
	
	in	a,(099h)														;Leemos registro de estado 1 (HBLANK or VBLANK)
	rrca
	
	
VEMOS_SI_HAY_INTERRUPCION_DE_LINEA_7:

	jp		c,LINEA_DE_INTERRUPCION_7									;si hay carry->linea de interrupcion!!
	
	xor		a 																;ponemos registro de estado 0 
	out 	(099h),a														;antes de salir o se puede colgar!!
	ld 		a,128+15
	out 	(099h),a

	in		a,(099h)													;es un VBLANK o otro tipo de interrupcion????
	rlca
	jp	c,INTERRUPCION_DE_VBLANK_7
	
	ret																	;si no VBLANK, nos volvemos

LINEA_DE_INTERRUPCION_7:
	
	ld		a,(el_menu_baila)
	cp		0
	ret		z
	
;Aquí esta la comprobacion de si ha terminado de pintar la linea.... 

	ld		a,2   ; 													;ponemos registro de estado 2 
	out 	(#99),a
	ld 		a,128+15
	out 	(#99),a

	
	
;Vale.. estas son las esperas... depende un poco del juego y demas, verás que tienes que hacer
;una espera o dos... eso ya es cuestion de probar.. sin más...
;Normalmente hay que poner un numero de linea anterior... osea, si quieres que salte en la 32, hay
;que poner en el registro 19 la 30 ó 31.. porque a lo que hacemos la comprobacion el VDP ya está pintando
;la siguiente linea.. sin mas...


CICLO_1_7:

	in		a,(099h)														;wait until start of HBLANK
	and		%00100000
	jr		nz,CICLO_1_7
	
CICLO_2_7: 

	in		a,(099h)														;wait until end of HBLANK
	and		%00100000
	jr		z,CICLO_2_7

;Aqui ya hemos esperado a que termine de pintar la linea...	
	
	xor		a 																;ponemos registro de estado 0 
	out 	(099h),a														;antes de salir o se puede colgar!!
	ld 		a,128+15
	out 	(099h),a
	
	in		a,(099h)														;lo leemos para evitar cuelgues...
		
INTERRUPCION_DE_LINEA_7:
	
	ld		a,(interrupcion_valida)
	cp		51
	jp		nc,CONTINUA_INTERRUPCION_1_7

	ld		a,(posicion_del_titulo_inicio)
	ld		(posicion_del_titulo),a
		
CONTINUA_INTERRUPCION_1_7:
	
	ld		a,(interrupcion_valida)
	add		6
	ld		(interrupcion_valida),a
		
	cp		125
	jp		nc,REINICIA_INTERRUPCIONES_DE_LINEA_7

																		; Metemos el siguiente valor de linea de interrupcion
	OUT 	(#99),a		
	ld 		a,19+128		
	out 	(#99),a	
	
	ld		a,(posicion_del_titulo)		
		
	cp		0
	jp		z,POSICION_1_7
	cp		1
	jp		z,POSICION_2_7
	cp		2
	jp		z,POSICION_3_7
	cp		3
	jp		z,POSICION_4_7
	cp		4
	jp		z,POSICION_5_7
	cp		5
	jp		z,POSICION_4_7
	cp		6
	jp		z,POSICION_3_7
	cp		7
	jp		z,POSICION_2_7
	cp		8
	jp		z,POSICION_1_7
	
POSICION_1_7:	
	
	ld		a,00000101b
	jp		FINAL_DE_INTERRUPCION_7

POSICION_2_7:	
	
	ld		a,00000011b
	jp		FINAL_DE_INTERRUPCION_7

POSICION_3_7:	
	
	ld		a,00000000b
	jp		FINAL_DE_INTERRUPCION_7

POSICION_4_7:	
	
	ld		a,00001110b
	jp		FINAL_DE_INTERRUPCION_7
	
POSICION_5_7:	
	
	ld		a,00001101b
		
FINAL_DE_INTERRUPCION_7:
																		; Metemos la posicion de set adjust adecuada
	OUT 	(#99),a		
																		;apuntamos el dato a poner en el registro	
	ld		a,18+128													;cargamos el valor de registro con el bit 8 establecido (+128)
	out		(#99),a	

	ld		a,(posicion_del_titulo)
	inc		a
	ld		(posicion_del_titulo),a
	
	EI
	
	cp		9
	ret		nz
	
	xor		a
	ld		(posicion_del_titulo),a
	
ULTIMO_FINAL:
	
	ret
	
REINICIA_INTERRUPCIONES_DE_LINEA_7:
		
	ld		a,(posicion_del_titulo_inicio)
	ld		(posicion_del_titulo),a
	
	ld		a,00000000b
																		; metemos una posicion de adjust centrada
	OUT 	(#99),a		
																		;apuntamos el dato a poner en el registro	
	ld		a,18+128													;cargamos el valor de registro con el bit 8 establecido (+128)
	out		(#99),a	
	
	ld		a,50
	ld		(interrupcion_valida),a

	OUT 	(#99),a		
	ld 		a,19+128		
	out 	(#99),a	
	
	EI

	ret

INTERRUPCION_DE_VBLANK_7:

	call	MOSCA_7
	
	ei
	
	ld		a,1
	ld		(vblank_real),a
	

	
	ld		a,(repeticion_posicion_titulo)
	inc		a
	ld		(repeticion_posicion_titulo),a
	cp		6
	
	
	jp		nz,FINAL_INTERRUPCION_VBLANK_7
	
	xor		a
	ld		(repeticion_posicion_titulo),a
	ld		a,(posicion_del_titulo_inicio)
	inc		a
	ld		(posicion_del_titulo_inicio),a
	cp		9
	jp		nz,FINAL_INTERRUPCION_VBLANK_7
	xor		a
	ld		(posicion_del_titulo_inicio),a

FINAL_INTERRUPCION_VBLANK_7:
	
	ld 		a,(que_musica_7)
	cp		0
	jp		z,.intro
	CP		1
	jp		z,.seleccion
	CP		2
	jp		z,.historia
	cp		9
	jp		z,.terminando
	
.intro:
	
	ld		a,15														;ponemos la página de la música para que pueda leerla
	jp		.final

.terminando:

	ld		a,19
	jp		.final
	
.seleccion:

	ld		a,6
	jp		.final

.historia:

	ld		a,36
	
.final:
	
	ld		[#7000],a	

FINAL_INTERRUPCION_VBLANK_7_CONTINUACION:

	call	musint
	
INTERRUPCION_SIN_MUSICA:
	
	ld		a,16													;ponemos la página de la música para que pueda leerla
	ld		[#7000],a	
	
	call	AYfx_ROUT
	call	ayFX_PLAY
		
	ld		a,(en_que_pagina_el_page_2)									;devolvemos la página en la que estaba
	ld		[#7000],a	
	
	RET
	
INTERRUMPE_CSP:
	
	CALL	GTTRIG
	cp		255
	jr.		z,FINAL_CSP
	ld		a,1
	CALL	GTTRIG
	cp		255
	jr.		z,FINAL_CSP
	ld		a,2
	CALL	GTTRIG
	cp		255
	jr.		z,FINAL_CSP	
					
	ret
		
PARADA_7:																;HACE DE HALT PERO SOLO TENIENDO EN CUENTA LAS INTERRUPCIONES DE VBLANK
		
	ld		a,(vblank_real)
	or		a
	jp		z,PARADA_7
		
	XOR		a
	ld		(vblank_real),a

	ret

ESPERA_AL_VDP_HMMC_7: 													;en hl metemos los datos para los registros hmmc
		
																		;en de metemos la dirección de los bits a copiar LA DIRECCION DE MEMORIA

		ld a,2
		call LEE_REGISTRO_PARA_HMMC_7
		and 1
		jr nz,ESPERA_AL_VDP_HMMC_7 										;Si el VDP no está libre, no sigue con la acción

		xor a
		call LEE_REGISTRO_PARA_HMMC_7 									; "resetea" los registros de lectura del VDP

		push	hl
		pop		ix														;Pasamos el material de hl a ix

		ld 		a,[de]													;Nos centramos en los 4 bits bajos de la primera dirección de de
		inc		de														;incrementamos de para luego ya tenerlo apuntando a donde interesa

;		ld [ix+8],a 													;introducimos el primer pixel (ESO SE ME COLÓ DE MÁS Y ESTABA DANDO PROBLEMAS)
		ld a,36 														;cargamos el primer registro a escribir

		di
		
		out ($99),a
		ld a,17+128 													;sistema automático de autoincremento
		out ($99),a
		ld c,$9B
		  
		REPEAT 11
		outi 															;ejecutamos 11 outi uno por cada registro
		ENDREPEAT
		
		ld a,44+128
		out ($99),a
		ld a,17+128 													;establece el registro para escribir datos y establece el autoincrement
		out ($99),a

		ei
		
		ex de,hl 														;intercambiamos de con hl y ahora hl apunta al gráfico

ESPERA_A_QUE_TERMINE_LO_ANTERIOR_7: 

		ld a,2															;vamos a fijarnos en el registro 2
		call LEE_REGISTRO_PARA_HMMC_7 									;lee el registro 2

		bit 0,a															;pone en a el valor del bit 0 del registro 2, aquí indica si ha terminado la acción
		jp z,FIN_SENTENCIA_VDP_7											;si el bit está  a 0 es que ya ha terminado y va a salir del tema
		bit 7,a															;nos fijamos ahora en el bit 7, aquí nos dice si ha terminado de realizar la parte concreta dentro de toda la acción
		jp z,ESPERA_A_QUE_TERMINE_LO_ANTERIOR_7 							;si es 1, no ha terminado, por lo que vuelve a atrás a esperar.

		ld	a,[hl]														;cargamos en a el valor de los 4 bits de hl (el siguiente pixel a pintar
		
		out	[#9b],a														;transferimos el byte al registro 9 para que sepa lo que debe pintar después
		inc	hl															;incrementamos hl para la siguiente lectura


		jp ESPERA_A_QUE_TERMINE_LO_ANTERIOR_7 							;loop ya que no ha terminado de pintarlo todo

FIN_SENTENCIA_VDP_7: 

		xor a
		call LEE_REGISTRO_PARA_HMMC_7 									;Limpia el VDP
		
		ret

LEE_REGISTRO_PARA_HMMC_7: 
		
		di
		
		out ($99),a														;Name : ReadReg
		ld a,15+128														;Description : Reads VDP
		out ($99),a														;Input : A=n (VDP register)
		in a,($99)														;Output : A=S#n
		
		ei
		
		ret

SetPalet_sin_retardo_7:
		
	xor			a														;Set p#pointer to zero.
	out			(#99),a
	ld			a,16+128
	out			(#99),a
	ld			c,#9A
	ld			b,16*2
	otir				
	
	ret

MOSCA_7:

		ld		a,(mosca_activa)										; Si no está activa la mosca tomará un valor fuera de escena
		cp		0
		ret		z

MIRAMOS_X_7:

		ld		a,(mosca_x_objetivo)									; Comparamos si objetivo de x es mayor que real de x
		ld		b,a
		ld		a,(mosca_x_real)
		cp		b
		jp		c,AUMENTA_X_REAL_7

DISMINUYE_X_REAL_7:

		ld		a,(mosca_suma_o_resta_x)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		nz,RESTA_A_MOSCA_X_ESTA_RESTANDO_7

RESTA_A_MOSCA_X_ESTA_SUMANDO_7:

		ld		a,(suma_a_mosca_x)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		cp		200
		call	nc,A_A_0
		ld		(suma_a_mosca_x),a
		jp		SUMA_REAL_X_7
		
.LO_ES:
		
		
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000111b
		ld		(suma_a_mosca_x),a
		ld		a,1
		ld		(mosca_suma_o_resta_x),a
		jp		RESTA_REAL_X_7
		
RESTA_A_MOSCA_X_ESTA_RESTANDO_7:

		ld		a,(suma_a_mosca_x)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000111b
		ld		(suma_a_mosca_x),a
		
RESTA_REAL_X_7:			

		ld		a,(suma_a_mosca_x)
		ld		b,a
		ld		a,(mosca_x_real)
		sub		b
		ld		(mosca_x_real),a
		
		jp		MIRAMOS_Y_7
		
AUMENTA_X_REAL_7:

		ld		a,(mosca_suma_o_resta_x)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		z,SUMA_A_MOSCA_X_ESTA_SUMANDO_7

SUMA_A_MOSCA_X_ESTA_RESTANDO_7:

		ld		a,(suma_a_mosca_x)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		cp		200
		call	nc,A_A_0
		ld		(suma_a_mosca_x),a
		jp		RESTA_REAL_X_7
		
.LO_ES:
				
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000111b
		ld		(suma_a_mosca_x),a
		ld		a,0
		ld		(mosca_suma_o_resta_x),a
		jp		SUMA_REAL_X_7
		
SUMA_A_MOSCA_X_ESTA_SUMANDO_7:

		ld		a,(suma_a_mosca_x)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000111b
		ld		(suma_a_mosca_x),a

SUMA_REAL_X_7:			

		ld		a,(suma_a_mosca_x)
		ld		b,a
		ld		a,(mosca_x_real)
		add		b
		ld		(mosca_x_real),a
				
MIRAMOS_Y_7:

		ld		a,(mosca_y_objetivo)									; Comparamos si objetivo de x es mayor que real de x
		ld		b,a
		ld		a,(mosca_y_real)
		cp		b
		jp		c,AUMENTA_Y_REAL_7

DISMINUYE_Y_REAL_7:

		ld		a,(mosca_suma_o_resta_y)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		nz,RESTA_A_MOSCA_Y_ESTA_RESTANDO_7

RESTA_A_MOSCA_Y_ESTA_SUMANDO_7:

		ld		a,(suma_a_mosca_y)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		cp		200
		call	nc,A_A_0
		ld		(suma_a_mosca_y),a
		jp		SUMA_REAL_Y_7
		
.LO_ES:
		
		
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000111b
		ld		(suma_a_mosca_y),a
		ld		a,1
		ld		(mosca_suma_o_resta_y),a
		jp		RESTA_REAL_Y_7
		
RESTA_A_MOSCA_Y_ESTA_RESTANDO_7:

		ld		a,(suma_a_mosca_y)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000111b
		ld		(suma_a_mosca_y),a
		
RESTA_REAL_Y_7:			

		ld		a,(suma_a_mosca_y)
		ld		b,a
		ld		a,(mosca_y_real)
		sub		b
		ld		(mosca_y_real),a
		
		jp		PINTAMOS_SPRITE_7
		
AUMENTA_Y_REAL_7:

		ld		a,(mosca_suma_o_resta_y)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		z,SUMA_A_MOSCA_Y_ESTA_SUMANDO_7

SUMA_A_MOSCA_Y_ESTA_RESTANDO_7:

		ld		a,(suma_a_mosca_y)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		cp		200
		call	nc,A_A_0
		ld		(suma_a_mosca_y),a
		jp		RESTA_REAL_Y_7
		
.LO_ES:
				
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000111b
		ld		(suma_a_mosca_y),a
		ld		a,0
		ld		(mosca_suma_o_resta_y),a
		jp		SUMA_REAL_Y_7
		
SUMA_A_MOSCA_Y_ESTA_SUMANDO_7:

		ld		a,(suma_a_mosca_y)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000111b
		ld		(suma_a_mosca_y),a

SUMA_REAL_Y_7:			

		ld		a,(suma_a_mosca_y)
		ld		b,a
		ld		a,(mosca_y_real)
		add		b
		ld		(mosca_y_real),a
		
PINTAMOS_SPRITE_7:

		ld		(mosca_y_real),a
		
		push	ix
		
		ld		ix,mosca_atributos
		ld		a,(mosca_y_real)
		ld		(ix),a
		ld		a,(mosca_x_real)
		ld		(ix+1),a			
		ld		a,(mosca_fotograma)
		ld		(ix+2),a
		push	hl		
		ld		hl,mosca_atributos										; atributos del sprite	
		ld		de,#7A00
		ld		bc,3
		call	LDIRVM
		pop		hl
		pop		ix
		
		ld		a,(mosca_fotograma)		
		inc		a
		and		00000111b
		ld		(mosca_fotograma),a
		ret
		
A_A_0:

		xor		a
		ret

DA_VALOR_AL_DADO_7:

		ld		a,r
		and		00000111b		
		ld		(dado),a
		
		ret
		
copia_cara_neutra_jugador_1_7:					dw		#0001,#0375,#000C,#009D,#002A,#0028
copia_cara_neutra_jugador_2_7:					dw		#0001,#039e,#00CC,#009D,#002A,#0028
