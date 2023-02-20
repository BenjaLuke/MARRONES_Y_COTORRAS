search_slotset_37:															;ampliar a espacios 1 y 2 los usados en la ram del ordenador
		
				call search_slot
				jp ENASLT

search_slot_37:

				call RSLREG
				rrca
				rrca
				and 3
				ld c,a
				ld b,0
				ld hl,0FCC1h
				add hl,bc
				ld a,(hl)
				and 080h
				or c
				ld c,a
				inc hl
				inc hl
				inc hl
				inc hl
				ld a,(hl)
				and 0Ch
				or c
				ld h,080h
				ld (SLOTVAR),a
				
				ret		
		
setpage_37:     															;cambiar la página en screen 5 	
	
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

setvdp_write_37: 															;poder escribir en paginas 2 y 3

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
    
SetPalet_37:		

[4]				halt

				xor			a             								;Set p#pointer to zero.
				di
				out			(#99),a
				ld			a,16+128
				ei
				out			(#99),a
				ld			c,#9A
[32]			outi

				ret

EL_12_A_0_EL_14_A_1001_37:

		xor		a
		ld		(ix+13),a
		ld		(ix+12),a												
		ld		a,10010000b												
		ld		(ix+14),a
		ret
		
DoCopy_37:	
				ld	a,32
				di
				out	(#99),a
				ld	a,17+128
				out	(#99),a
				ld	c,#9B
				
VDPready_37:
	
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
				jp	c,VDPready
				
				DW	#A3ED,#A3ED,#A3ED,#A3ED	  							;15x OUTI
				DW	#A3ED,#A3ED,#A3ED,#A3ED	  							;(faster than OTIR)
				DW	#A3ED,#A3ED,#A3ED,#A3ED
				DW	#A3ED,#A3ED,#A3ED
				
				ret
	
RALENTIZA_37:																;para ralentizar una secuencia. En RALENTIZADO daremos un valor entre 
																		;0 y 255 cuanto más alto, más lenta irá la secuencia
		halt
		ld		a,(ralentizando)
		dec		a
		ld		(ralentizando),a
		cp		0
		jp		nz,RALENTIZA
		
		ret
		
VDP_LISTO_37:

		push	hl														;esperamos a que el fotograma se haya copiado correctamente ya
		call	VDPready												;que la VDP trabaja de forma independiente del Z80 y se pueden chocar
		pop		hl														;algunas ordenes (pero a veces se puede aprovechar)

		ret


NUESTRA_ISR_37:
	
	ld	a,1																; ponemos registro de estado 1 
	out (099h),a
	ld a,128+15
	out (099h),a
	
	
	in	a,(099h)														;Leemos registro de estado 1 (HBLANK or VBLANK)
	rrca
	
VEMOS_SI_HAY_INTERRUPCION_DE_LINEA_37:

	jp	c,LINEA_DE_INTERRUPCION											;si hay carry->linea de interrupcion!!
	
	xor	a 																;ponemos registro de estado 0 
	out (099h),a														;antes de salir o se puede colgar!!
	ld a,128+15
	out (099h),a

	in	a,(099h)														;es un VBLANK o otro tipo de interrupcion????
	rlca
	jp	c,INTERRUPCION_DE_VBLANK
	
	ret																	;si no VBLANK, nos volvemos

LINEA_DE_INTERRUPCION_37:

;Aquí esta la comprobacion de si ha terminado de pintar la linea.... 
	
	ld	a,2   ; 														;ponemos registro de estado 2 
	out (#99),a
	ld a,128+15
	out (#99),a

	
	
;Vale.. estas son las esperas... depende un poco del juego y demas, verás que tienes que hacer
;una espera o dos... eso ya es cuestion de probar.. sin más...
;Normalmente hay que poner un numero de linea anterior... osea, si quieres que salte en la 32, hay
;que poner en el registro 19 la 30 ó 31.. porque a lo que hacemos la comprobacion el VDP ya está pintando
;la siguiente linea.. sin mas...


CICLO_1_37:

	in	a,(099h)														;wait until start of HBLANK
	and	%00100000
	jr	nz,CICLO_1
	
CICLO_2_37: 

	in	a,(099h)														;wait until end of HBLANK
	and	%00100000
	jr	z,CICLO_2

;Aqui ya hemos esperado a que termine de pintar la linea...	
	
	xor	a 																;ponemos registro de estado 0 
	out (099h),a														;antes de salir o se puede colgar!!
	ld a,128+15
	out (099h),a
	
	in	a,(099h)														;lo leemos para evitar cuelgues...
	
	ld	a,(interrupcion_valida)
	cp	2
	jp	z,INTERRUPCION_DE_LINEA_2
	
INTERRUPCION_DE_LINEA_37:

		ld		a,0														;set page 0
		call	setpage
		
		xor	a
		di																;desconectamos las interrupciones
		out		(#99),a													;apuntamos el dato a poner en el registro
		
		ld		a,18+128												;cargamos el valor de registro con el bit 8 establecido (+128)
		ei																;contectamos las interrupciones que se conectarán después de la siguiente orden
		out		(#99),a	
			
		LD A,147														; Metemos linea 148 en el registro 19
		OUT (#99),A		
		ld A,19+128		
		out (#99),a		
		ld	a,2															;especificamos la interrupcion adecuada
		ld	(interrupcion_valida),a

	ld		a,(paleta_a_usar_en_vblank)
	cp		1
	ret		z
						
	ld		hl,PALETA_DEL_LABERINTO_2									;Paleta de colores para el laberinto	
	jp		SetPalet_sin_retardo

INTERRUPCION_DE_LINEA_2_37:
	
		LD A,114															; Metemos lilnea 90 en el registro 19
		OUT (#99),A		
		ld A,19+128		
		out (#99),a		
		ld	a,1															;especificamos la interrupcion adecuada
		ld	(interrupcion_valida),a

	ld		a,(paleta_a_usar_en_vblank)
	cp		1
	ret		z
						
	ld		hl,PALETA_DEL_LABERINTO_3									;Paleta de colores para el laberinto	
	jp		SetPalet_sin_retardo



INTERRUPCION_DE_VBLANK_37:
	
	ld	a,(set_page01)
	cp	0
	jp	z,CAMBIAMOS_COLOR
	
	ld		a,1															;set page 0
	call	setpage

CAMBIAMOS_COLOR_37:
																		;cambiamos color
	ld		a,(paleta_a_usar_en_vblank)
	cp		1
	jp		z,INTERRUPCION_DE_VBLANK_2
	cp		2
	jp		z,INTERRUPCION_DE_VBLANK_3
	cp		3
	jp		z,INTERRUPCION_DE_VBLANK_4
	cp		4
	jp		z,INTERRUPCION_DE_VBLANK_5		
	cp		5
	jp		z,INTERRUPCION_DE_VBLANK_6
	cp		6
	jp		z,INTERRUPCION_DE_VBLANK_8
	cp		7
	jp		z,INTERRUPCION_DE_VBLANK_9

	LD		a,(vida_decenas)
	cp		0
	jp		nz,INTERRUPCION_VBLANK_CONTINUA
	ld		hl,PALETA_DEL_LABERINTO_1_D									;Paleta de colores para el laberinto
	call	SetPalet_sin_retardo	
	jp 		INTERRUPCION_VBLANK_CONTINUA_2
	
INTERRUPCION_VBLANK_CONTINUA_37:
					
	ld		hl,PALETA_DEL_LABERINTO_1									;Paleta de colores para el laberinto
	call	SetPalet_sin_retardo

INTERRUPCION_VBLANK_CONTINUA_2_37:

	ld		a,(tiembla_el_decorado_v)
	cp		0
	call	nz,TIEMBLA_EL_DECORADO
	
	jp		COMUN_VBLANK

TIEMBLA_EL_DECORADO_37:

	dec		a
	ld		(tiembla_el_decorado_v),a
	call	DA_VALOR_AL_DADO_37
	
		di																;desconectamos las interrupciones
		out		(#99),a													;apuntamos el dato a poner en el registro
		
		ld		a,18+128												;cargamos el valor de registro con el bit 8 establecido (+128)
		ei																;contectamos las interrupciones que se conectarán después de la siguiente orden
		out		(#99),a													;apuntamos al registro adecuado (en este caso el 23 para el scroll)

		ret
		
INTERRUPCION_DE_VBLANK_2_37:
		
	ld		hl,PALETA_DEL_PERGAMINO
	call	SetPalet_sin_retardo
	
	jp		COMUN_VBLANK
		
INTERRUPCION_DE_VBLANK_3_37:
		
	ld		hl,PALETA_DEL_POCHADERO
	call	SetPalet_sin_retardo

	jp		COMUN_VBLANK

INTERRUPCION_DE_VBLANK_4_37:
		
	ld		hl,PALETA_DE_MENOS_VIDA
	call	SetPalet_sin_retardo
	ld		a,(paleta_a_usar_en_vblank)
	xor		a
	ld		(paleta_a_usar_en_vblank),a
	jp		COMUN_VBLANK
		
INTERRUPCION_DE_VBLANK_8_37:
		
	ld		hl,PALETA_DEL_POCHADERO1
	call	SetPalet_sin_retardo
	
	jp		COMUN_VBLANK

INTERRUPCION_DE_VBLANK_9_37:
		
	ld		hl,PALETA_DEL_POCHADERO4
	call	SetPalet_sin_retardo
	
	jp		COMUN_VBLANK
			
INTERRUPCION_DE_VBLANK_6_37:
		
	ld		hl,PALETA_DEL_PROTA_MUERTO
	call	SetPalet_sin_retardo

INTERRUPCION_DE_VBLANK_5_37:
		
	ld		hl,PALETA_DE_ENEMIGO_1
	call	SetPalet_sin_retardo
	jp		INTERRUPCION_VBLANK_CONTINUA_2
			
COMUN_VBLANK_37:
	
	ld		a,(que_musica_0)
	cp		1
	jp		z,.shop
	CP		2
	jp		z,.hater
	cp		3
	jp		z,.muerto
	cp		4
	jp		z,.pasa_fase
	cp		5
	jp		z,.gana_juego_2
	CP		6
	jp		z,.historia_final
	CP		7
	jp		z,.pelea_cotorra
	CP		8
	jp		z,.conversacion_cotorra
				
.juego:	

	ld		a,16
	jp		.sigue

.pelea_cotorra:

	ld		a,80
	jp		.sigue
	
.conversacion_cotorra

	ld		a,81
	jp		.sigue
	
.shop:

	ld		a,39														;ponemos la página de la música para que pueda leerla
	jp		.sigue

.muerto:

	ld		a,53
	jp		.sigue

.pasa_fase:

	ld		a,2
	jp		.sigue
	
.gana_juego_2:

	ld		a,4
	jp		.sigue

.historia_final:

	ld		a,36
	jp		.sigue
	
.hater:

	ld		a,22
		
.sigue:
														;ponemos la página de la música para que pueda leerla
	ld		[#7000],a	
	
	call	musint	

	ld		a,16
	ld		[#7000],a	
		
	call	AYfx_ROUT
	call	ayFX_PLAY
		
	ld		a,(en_que_pagina_el_page_2)									;devolvemos la página en la que estaba
	ld		[#7000],a	
	call	MOSCA														; vamos a revisar la mosca cojonera


	
	ld		a,6														
	call	SNSMAT
	bit		6,a
	call	z,CAMBIO_EN_MOSCA
	
	ld		a,(tecla_pulsada_MOSCA)
	cp		0
	ret		z
	dec		a
	ld		(tecla_pulsada_MOSCA),a
	ret
	
CAMBIO_EN_MOSCA_37:

	ld		a,(tecla_pulsada_MOSCA)

	cp		0
	ret		nz
	
	ld		a,60
	ld		(tecla_pulsada_MOSCA),a

	ld		a,(mosca_activa)
	cp		0
	jp		z,.A_UNO

.A_CERO:

	xor		a
	ld		(mosca_activa),a
	ld		a,(mosca_y_objetivo)
	ld		(mosca_y_objetivo_res),a	
	ret
	
.A_UNO:

	xor		1
	ld		(mosca_activa),a
	ld		a,(mosca_y_objetivo_res)
	ld		(mosca_y_objetivo),a
			
	ret
		
SetPalet_sin_retardo_37:
		
	xor			a														;Set p#pointer to zero.
	out			(#99),a
	ld			a,16+128
	out			(#99),a
	ld			c,#9A
	ld			b,16*2
	otir				
	
	ret

COPY_A_GUSTO_37:

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

HL_DATOS_DEL_COPY_CALL_DOCOPY_37:

		ld		hl,datos_del_copy
		jp		DoCopy

lista_de_opciones_37:
		
		ld 		h,0
		ld 		l,a
		add 	hl,hl

		add 	hl,de													;hl ya esta apuntando a la posicion correcta de la tabla
		
		ld 		e,(hl)													;extraemos la direccion de la etiqueta
		inc 	hl
		ld 		d,(hl)													;hl ya tiene la direccion de salto!
		ex 		de,hl
		jp 		(hl)

LIMPIA_PANTALLA_0_A_3_37:												;un recuadro en la pantalla 0 de color 0 tapandolo todo_va_bien
		
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
		call	DoCopy
		call	VDP_LISTO

		ret
		

ESPERA_AL_VDP_HMMC_37: 													;en hl metemos los datos para los registros hmmc
		
																		;en de metemos la dirección de los bits a copiar LA DIRECCION DE MEMORIA

		ld a,2
		call LEE_REGISTRO_PARA_HMMC
		and 1
		jr nz,ESPERA_AL_VDP_HMMC 										;Si el VDP no está libre, no sigue con la acción

		xor a
		call LEE_REGISTRO_PARA_HMMC 									; "resetea" los registros de lectura del VDP

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

ESPERA_A_QUE_TERMINE_LO_ANTERIOR_37: 

		ld a,2															;vamos a fijarnos en el registro 2
		call LEE_REGISTRO_PARA_HMMC 									;lee el registro 2

		bit 0,a															;pone en a el valor del bit 0 del registro 2, aquí indica si ha terminado la acción
		jp z,FIN_SENTENCIA_VDP											;si el bit está  a 0 es que ya ha terminado y va a salir del tema
		bit 7,a															;nos fijamos ahora en el bit 7, aquí nos dice si ha terminado de realizar la parte concreta dentro de toda la acción
		jp z,ESPERA_A_QUE_TERMINE_LO_ANTERIOR 							;si es 1, no ha terminado, por lo que vuelve a atrás a esperar.

		ld	a,[hl]														;cargamos en a el valor de los 4 bits de hl (el siguiente pixel a pintar
		
		di
		out	[#9b],a														;transferimos el byte al registro 9 para que sepa lo que debe pintar después
		ei
		inc	hl															;incrementamos hl para la siguiente lectura


		jp ESPERA_A_QUE_TERMINE_LO_ANTERIOR 							;loop ya que no ha terminado de pintarlo todo

FIN_SENTENCIA_VDP_37: 

		xor a
		call LEE_REGISTRO_PARA_HMMC 									;Limpia el VDP
		
		ret

LEE_REGISTRO_PARA_HMMC_37: 
		
		di
		
		out ($99),a														;Name _37: ReadReg
		ld a,15+128														;Description _37: Reads VDP
		out ($99),a														;Input _37: A=n (VDP register)
		in a,($99)														;Output _37: A=S#n
		
		ei
		
		ret

MOSCA_37:

		ld		a,(mosca_activa)										; Si no está activa la mosca tomará un valor fuera de escena
		cp		0
		call	z,MOSCA_OUT

MIRAMOS_X_37:

		ld		a,(mosca_x_objetivo)									; Comparamos si objetivo de x es mayor que real de x
		ld		b,a
		ld		a,(mosca_x_real)
		cp		b
		jp		c,AUMENTA_X_REAL

DISMINUYE_X_REAL_37:

		ld		a,(mosca_suma_o_resta_x)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		nz,RESTA_A_MOSCA_X_ESTA_RESTANDO

RESTA_A_MOSCA_X_ESTA_SUMANDO_37:

		ld		a,(suma_a_mosca_x)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		ld		(suma_a_mosca_x),a
		jp		SUMA_REAL_X
		
.LO_ES:
		
		
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000011b
		ld		(suma_a_mosca_x),a
		ld		a,1
		ld		(mosca_suma_o_resta_x),a
		jp		RESTA_REAL_X
		
RESTA_A_MOSCA_X_ESTA_RESTANDO_37:

		ld		a,(suma_a_mosca_x)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000011b
		ld		(suma_a_mosca_x),a
		
RESTA_REAL_X_37:			

		ld		a,(suma_a_mosca_x)
		ld		b,a
		ld		a,(mosca_x_real)
		sub		b
		ld		(mosca_x_real),a
		
		jp		MIRAMOS_Y
		
AUMENTA_X_REAL_37:

		ld		a,(mosca_suma_o_resta_x)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		z,SUMA_A_MOSCA_X_ESTA_SUMANDO

SUMA_A_MOSCA_X_ESTA_RESTANDO_37:

		ld		a,(suma_a_mosca_x)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		ld		(suma_a_mosca_x),a
		jp		RESTA_REAL_X
		
.LO_ES:
				
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000011b
		ld		(suma_a_mosca_x),a
		ld		a,0
		ld		(mosca_suma_o_resta_x),a
		jp		SUMA_REAL_X
		
SUMA_A_MOSCA_X_ESTA_SUMANDO_37:

		ld		a,(suma_a_mosca_x)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000011b
		ld		(suma_a_mosca_x),a

SUMA_REAL_X_37:			

		ld		a,(suma_a_mosca_x)
		ld		b,a
		ld		a,(mosca_x_real)
		add		b
		ld		(mosca_x_real),a
				
MIRAMOS_Y_37:

		ld		a,(mosca_y_objetivo)									; Comparamos si objetivo de x es mayor que real de x
		ld		b,a
		ld		a,(mosca_y_real)
		cp		b
		jp		c,AUMENTA_Y_REAL

DISMINUYE_Y_REAL_37:

		ld		a,(mosca_suma_o_resta_y)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		nz,RESTA_A_MOSCA_Y_ESTA_RESTANDO

RESTA_A_MOSCA_Y_ESTA_SUMANDO_37:

		ld		a,(suma_a_mosca_y)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		ld		(suma_a_mosca_y),a
		jp		SUMA_REAL_Y
		
.LO_ES:
		
		
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000111b
		ld		(suma_a_mosca_y),a
		ld		a,1
		ld		(mosca_suma_o_resta_y),a
		jp		RESTA_REAL_Y
		
RESTA_A_MOSCA_Y_ESTA_RESTANDO_37:

		ld		a,(suma_a_mosca_y)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000111b
		ld		(suma_a_mosca_y),a
		
RESTA_REAL_Y_37:			

		ld		a,(suma_a_mosca_y)
		ld		b,a
		ld		a,(mosca_y_real)
		sub		b
		ld		(mosca_y_real),a
		
		jp		PINTAMOS_SPRITE
		
AUMENTA_Y_REAL_37:

		ld		a,(mosca_suma_o_resta_y)								; Miramos si mosca_suma_o_resta_x está sumando o restando
		cp		0
		jp		z,SUMA_A_MOSCA_Y_ESTA_SUMANDO

SUMA_A_MOSCA_Y_ESTA_RESTANDO_37:

		ld		a,(suma_a_mosca_y)										; comprobamos si su acumulado es 0
		cp		0
		jp		z,.LO_ES
		
.NO_LO_ES:

[2]		dec		a														; disminuimos el sumando y vamos a la suma real
		ld		(suma_a_mosca_y),a
		jp		RESTA_REAL_Y
		
.LO_ES:
				
		inc		a														; aumentamos el sumando , ponemos el acumulado a 1 y vamos a la resta real
		and		00000111b
		ld		(suma_a_mosca_y),a
		ld		a,0
		ld		(mosca_suma_o_resta_y),a
		jp		SUMA_REAL_Y
		
SUMA_A_MOSCA_Y_ESTA_SUMANDO_37:

		ld		a,(suma_a_mosca_y)										; aumentamos el sumando y vamos a la resta real
		inc		a
		and		00000111b
		ld		(suma_a_mosca_y),a

SUMA_REAL_Y_37:			

		ld		a,(suma_a_mosca_y)
		ld		b,a
		ld		a,(mosca_y_real)
		add		b
		ld		(mosca_y_real),a
		
PINTAMOS_SPRITE_37:

		ld		(mosca_y_real),a
		
		push	ix
		
		ld		ix,mosca_atributos
		ld		a,(mosca_y_real)
		ld		(ix),a
		ld		a,(mosca_x_real)
		ld		(ix+1),a			
		ld		a,(mosca_fotograma)
		ld		(ix+2),a
		ld		a,224
		ld		(ix+4),a
		ld		hl,mosca_atributos										; atributos del sprite	
		ld		de,#7A00
		ld		bc,7
		call	LDIRVM
		
		pop		ix

		ld		a,(mosca_fotograma)		
		inc		a
		and		00000111b
		ld		(mosca_fotograma),a
		ret
		
MOSCA_OUT_37:

		ld		a,215
		ld		(mosca_y_objetivo),a
		ret

DIBUJA_NUMERO_parte_1_37:
		
		ld		ix,datos_del_copy
		ld		bc,656													;y origen
		ld		(ix+2),c
		ld		(ix+3),b
		
		ld		a,11													;pintamos un borrón para llamar la atención
		ld 		de,POINT_DE_NUMERO
		call	lista_de_opciones
		
		ld		a,10
		ld		(ralentizando),a
		call	RALENTIZA
				
		ld		a,(valor_a_transm_a_dib)								;pintamos el número
		ld 		de,POINT_DE_NUMERO
		jp		lista_de_opciones
		
PINTA_0_37:

		ld		bc,0													;x origen

		jp		DIBUJA_NUMERO_parte_2

PINTA_1_37:

		ld		bc,8													;x origen

		jp		DIBUJA_NUMERO_parte_2
		
PINTA_2_37:

		ld		bc,16													;x origen

		jp		DIBUJA_NUMERO_parte_2

PINTA_3_37:

		ld		bc,24													;x origen

		jp		DIBUJA_NUMERO_parte_2

PINTA_4_37:

		ld		bc,32													;x origen

		jp		DIBUJA_NUMERO_parte_2
		
PINTA_5_37:

		ld		bc,40													;x origen

		jp		DIBUJA_NUMERO_parte_2			

PINTA_6_37:

		ld		bc,48													;x origen

		jp		DIBUJA_NUMERO_parte_2

PINTA_7_37:

		ld		bc,56													;x origen

		jp		DIBUJA_NUMERO_parte_2
		
PINTA_8_37:

		ld		bc,64													;x origen

		jp		DIBUJA_NUMERO_parte_2	

PINTA_9_37:

		ld		bc,72													;x origen

		jp		DIBUJA_NUMERO_parte_2	

PINTA_10_37:

		ld		bc,80													;x origen

		jp		DIBUJA_NUMERO_parte_2	

PINTA_BORRON_37:

		ld		bc,88													;x origen

DIBUJA_NUMERO_parte_2_37:

		ld		(ix),c
		ld		(ix+1),b
		
		ld		a,(estado_pelea)
		cp		2
		jp		z,ATAQUE
		cp		1
		jp		z,DEFENSA

VELOCIDAD_37:
				
		jp		DIBUJA_NUMERO_CONT

ATAQUE_37:

		ld		bc,31
		ld		(ix+6),c												;pixels en x
		ld		(ix+7),b

		jp		DIBUJA_NUMERO_CONT
		
DEFENSA_37:

		ld		bc,50
		ld		(ix+6),c												;pixels en x
		ld		(ix+7),b
		
DIBUJA_NUMERO_CONT_37:
		
		ld		bc,8
		ld		(ix+8),c												;pixels en x
		ld		(ix+9),b
		ld		bc,7	
		ld		(ix+10),c												;pixels en y
		ld		(ix+11),b
														
		xor		a
		ld		(ix+13),a												;cómo es el copy	
		ld		a,#d0
		ld		(ix+14),a
		
		jr.		PINTA_DIRECTRICES_DEL_COPY		
		
PINTA_DIRECTRICES_DEL_COPY_37:
		
		jp		HL_DATOS_DEL_COPY_CALL_DOCOPY		

DIRECTRICES_RECTIFICACION_ATAQUE_37:
		
		ld		ix,datos_del_copy
		ld		bc,31
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
											;cómo es el copy	
		call	EL_12_A_0_EL_14_A_1001

		
		ld		a,(turno)
		
		cp		1
		jr.		z,.ZONA_JUG_1
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,23
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
		
.ZONA_JUG_2:
		
		ld		bc,231
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
				
		ret

DIRECTRICES_RECTIFICACION_DEFENSA_37:
		
		ld		ix,datos_del_copy
		ld		bc,50
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
												;cómo es el copy	
		call	EL_12_A_0_EL_14_A_1001

		
		ld		a,(turno)
		
		cp		1
		jr.		z,.ZONA_JUG_1
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,23
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
		
.ZONA_JUG_2:
		
		ld		bc,231
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
				
		ret

COPIA_NUMEROS_37:

		ld		iy,copia_numeros_1_a_page_2					
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		a,(cantidad_de_jugadores)
		cp		1
		ret		z		
		ld		iy,copia_numeros_2_a_page_2					
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ret
		
copia_numeros_1_a_page_2_37:	dw	#0000,#0008,#0000,#0108,#002d,#005f
copia_numeros_2_a_page_2_37:	dw	#00d6,#0008,#00d6,#0108,#002d,#005f
		
POINT_DE_NUMERO_37:			dw	PINTA_0
							dw	PINTA_1
							dw	PINTA_2
							dw	PINTA_3
							dw	PINTA_4
							dw	PINTA_5
							dw	PINTA_6
							dw	PINTA_7
							dw	PINTA_8
							dw	PINTA_9
							dw	PINTA_10
							dw	PINTA_BORRON

; ********** RECURSOS **********
		


PALETA_DEL_PERGAMINO_37:		incbin		"PL5/PERGAMINO.PAL"
PALETA_DEL_LABERINTO_1_37:		incbin		"PL5/FONDO 1.PL5"
PALETA_DEL_LABERINTO_1_D_37:	incbin		"PL5/FONDO 1 DOBLADA.PL5"
PALETA_DEL_LABERINTO_2_37:		incbin		"PL5/FONDO 2.PL5"
PALETA_DEL_LABERINTO_3_37:		incbin		"PL5/FONDO 3.PL5"
PALETA_DEL_POCHADERO_37:		incbin		"PL5/POCHADERO.PAL"
PALETA_DEL_POCHADERO1_37:		incbin		"PL5/POCHADERO1.PAL"
PALETA_DEL_POCHADERO4_37:		incbin		"PL5/POCHADERO4.PAL"
PALETA_DEL_PROTA_MUERTO_37:		incbin		"PL5/PROTA MUERTO.PAL"
PALETA_DE_MENOS_VIDA_37:		incbin		"PL5/MENOSVIDA.PAL"
PALETA_DE_ENEMIGO_1_37:			incbin		"PL5/SPRITES 1.PAL"
