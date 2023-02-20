		output	"MARRONES Y COTORRAS.rom"
		
				include		"BIOS.asm"
		
		org		#4000
			

		;pagina 0 del megarom	
				
		db "AB"
		word pre_INICIO
		word 0,0,0,0,0,0

; ______________________________________________________________________
		
; (((********** COMIENZA PAGINA 0 MEGAROM **********

;	PREPARACION DEL JUEGO
;	MOTOR DE LA PARTIDA

pre_INICIO:

		xor		a
		ld		(salto_historia),a
		ld		(marca_e_idioma),a
		ld		(ya_hemos_visto_petiso),a
		
		ld		a,(RG9SAV)
		and		11111101b												;a 60 hz
		ld		b,a
		ld		c,9
		call	WRTVDP													;lo escribe en el registro 9 del VDP
				
INICIO:
		
		ld      hl,VDP_0												;|Copia los ajustes de los registros del VDP a la matriz VDP.
        ld      de,VDP													;|Después, lee los registros de VDP con LD A, (VDP + r)
        ld      bc,8													;|(esto debe colocarse al comienzo del programa)
        ldir															;|
        ld      hl,VDP_8												;|
        ld      de,VDP+8												;|
        ld      bc,17													;|
        ldir
		              
		di																;desconecta interrupciones, puesto que vamos a andar en la pila y cambiar la disposicion de los slots que ve la CPU

		im 		1														;modo de interrupcion 1 (en caso de interrupcion, la rutina de servicio de interrupcion (ISR) esta en #0038,
		
		ld		a,#C9													;a tiene el valor de ret
		ld		(#FD9F),A												;colocamos ese ret en el gancho H.Timi POR SI EL ORDENADOR TUVIERA ALGO (ALGUN MSX 2 CONTROL DE DISQUETERA)
		ld		(#FD9A),A												;colocamos ese ret en el gancho H.Key POR SI EL ORDENADOR TUVIERA ALGO

		ld 		sp,0xF380												;colocamos la pila en esta posicion, que suele ser donde empieza las zona RAM que usa el S.O. del MSX. Recuerda que la pila
																		;crece hacia abajo, asi que no pisaremos nada que este mas arriba de esta direccion		
SEGUIMOS_MAS:		

		call	search_slotset											;la CPU vera esta ROM en la pagina 2
		
		xor		a
		ld		[#6000],a												;banco 1, pagina 0 del MEGAROM
		ld		a,5
		call	EL_7000

BUSCAMOS_FM_PAC:

		call	RUTINA_BUSQUEDA_FMPAC
		
		
PREPARACION_GRAFICA: 		
		
		ld		a,1														;screen 1
		call	CHGMOD
				
		xor		a														;Color de fondo a negro
		ld		[BDRCLR],a
		ld		[BAKCLR],a
		ld		[FORCLR],a
		call	CHGCOLOR

		xor		a
		ld		[CLICKSW],a												;quitamos el sonido de tecla de cursor

		
		ld		a,5														;screen 5
		call	CHGMOD
		
		ld		hl,BORRA_PANTALLA_0										;Borrando la2 página2 1-3 por si había restos
[4]		call	DoCopy
		
		ld		a,0														;set page 0
		call	setpage
		
		ld      a, 1
		ld      [ACPAGE],a              								;set page x,1
        
VAMOS_A_SELECCION_DE_IDIOMA:
	
		xor		a
		ld		(marca_e_idioma),a
		jp		BANCO_1_PAGINA_7_PARA_IDIOMA

VAMOS_A_SELECCION_DE_MENU:

		ld		a,1
		ld		(marca_e_idioma),a
		di
		ld		a,5
		ld		[#7000],a
				
		jp		BANCO_1_PAGINA_7_PARA_MENU
		
PREPARAMOS_INTERRUPCION_DE_LINEA:

		di
		xor		a														;nos aseguramos que el juego no empieza temblando
		ld		(tiembla_el_decorado_v),a
		
		ld		a,5
		call	EL_7000
		DI																;banco 2, pagina 5 del MEGAROM
					
		LD 		A,120													; Metemos lilnea 90 en el registro 19
		OUT 	(#99),A		
		ld 		A,19+128		
		out 	(#99),a		
		ld		a,1														;especificamos la interrupcion adecuada
		ld		(interrupcion_valida),a

INTERRUPCIONES_DE_LINEA_ABIERTAS:

		LD 		A,(RG0SAV)												; Enable Line Interrupt: Set R#0 bit 4
		OR		00010000B
		LD 		(RG0SAV),a			
		OUT 	(#99),A		
		LD 		A,0+128		
		OUT 	(#99),A		
				
																		; engancha nuestra rutina de servicio al gancho que deja 
																		; preparada la BIOS cuando se termina de pintar la pantalla
																		; (50 o 60 veces por segundo)

GANCHO_DE_INTERRUPCION_GENERAL:
		
		ld		a,#C3													;#c3 es el código binario de jump (jp)
		ld		[H.KEYI],a												;metemos en H.TIMI ese jp
		ld		hl,NUESTRA_ISR											;con el jp anterior, construimos jp NUESTRA_ISR
		ld		[H.KEYI+1],hl											;la ponemos a continuación del jp
		ei
				
						
LANZAMOS_LA_MUSICA:

		call	ENASCR
		xor		a
		ld		(que_musica_0),a
		
		LD		A,16
		call	EL_7000	

		DI
		call	strmus													;iniciamos la música de juego
		EI
		
		jp		EMPEZAMOS_PREPARACION_PANTALLA
		
RESCATAMOS_EL_PERGAMINO:
																	
		ld		A,54
		call	EL_7000	
		
		ld		de,COPIAMOS_PERGAMINO_1
		ld		hl,copia_pergamino_en_pantalla_1						; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
												
		LD		A,11
		call	EL_7000	
		
		ld		de,COPIAMOS_PERGAMINO_2
		ld		hl,copia_pergamino_en_pantalla_2						; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		LD		A,22
		call	EL_7000	
					
		ld		a,(idioma)
		cp		1
		ret		nz
		
		ld		de,PERGA_INGLES
		ld		hl,copia_pergamino_ingles								; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
						
		ret
		
																				
EMPEZAMOS_PREPARACION_PANTALLA:

		LD		A,(pagina_de_idioma)
		call	EL_7000

		ld		a,(cantidad_de_jugadores)
		cp		2
		jp		z,AVISO_DE_DOS

AVISO_DE_UNO:
		
		call	TEXTO_DE_INICIO_UN_JUGADOR								; Damos el texto de inicio a 1 jugador
		
		jp		DAMOS_TURNO_PINTAMOS_INICIO_DE_DATOS

AVISO_DE_DOS:
		
		call	TEXTO_DE_INICIO_DOS_JUGADORES							; Damos el texto de inicio a 2 jugadores
		
DAMOS_TURNO_PINTAMOS_INICIO_DE_DATOS:

		LD		A,16
		call	EL_7000
				
		ld		(paleta_a_usar_en_vblank),a
						
		ld		a,1														; le damos el turno al jugador 1
		ld		(turno),a
		
		call	DIRECTRICES_VALOR_DADO									; pintamos 0 en dado y valor movimiento
		xor		a
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		call	DIRECTRICES_VALOR_MOVIMIENTO_REAL
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		
		ld		a,(codigo_activo)
		or		a
		jp		nz,PERSONAJE_DE_CODIGO_1								; nos saltamos la entrega de variables del prota si venimos de codigo activo

					
		ld		hl,(posicion_en_mapa_1)
		ld		(posicion_en_mapa),hl
		ld		a,(orientacion_del_personaje_1)
		ld		(orientacion_del_personaje),a			

		ld		a,(personaje_1)
		dec		a
		ld		de,VARIABLES_PROTA
		call	lista_de_opciones
		
		ld		a,(incremento_ataque)
		ld		(incremento_ataque_origen1),a
		ld		(incremento_ataque_1),a
		ld		a,(incremento_defensa)
		ld		(incremento_defensa_origen1),a
		ld		(incremento_defensa_1),a
		ld		a,(incremento_velocidad)
		ld		(incremento_velocidad_origen1),a
		ld		(incremento_velocidad_1),a
		
SEGUIMOS_CON_PERSONAJE_1:
		
		ld		a,1
		ld		(mosca_activa),a

		ld		a,(codigo_activo)
		cp		1
		jp		z,SEGUIMOS									
		
		ld		a,(nivel)
		cp		1
		jp		nz,OTROS_VALORES
				
		ld		hl,3
		ld		(bitneda_decenas),hl
		ld		hl,0
		ld		(bitneda_centenas),hl
		ld		bc,11													
		ld		de,bitneda_unidades1
		ld		hl,bitneda_unidades
					
		ldir		
		
		jp		SEGUIMOS

OTROS_VALORES:

		ld		ix,valor_conserv_bitn_vid
		ld		l,(ix+2)
		LD		h,(IX+3)
		ld		(bitneda_decenas),hl
		ld		l,(ix+4)
		LD		h,(IX+5)
		ld		(bitneda_centenas),hl
		ld		l,(ix)
		LD		h,(IX+1)
		LD		(bitneda_unidades),hl
		
		ld		bc,11													
		ld		de,bitneda_unidades1
		ld		hl,bitneda_unidades					
		ldir			

SEGUIMOS:
				
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,SECUENCIA_DEL_TURNO_DEL_JUGADOR

		ld		a,(codigo_activo)
		cp		1
		jp		z,PERSONAJE_DE_CODIGO_2									; nos saltamos la entrega de variables del prota si venimos de codigo activo

			
		ld		a,(personaje_2)
		dec		a
		ld		de,VARIABLES_PROTA
		call	lista_de_opciones

		ld		a,(incremento_ataque)
		ld		(incremento_ataque_origen2),a
		ld		a,(incremento_defensa)
		ld		(incremento_defensa_origen2),a
		ld		a,(incremento_velocidad)
		ld		(incremento_velocidad_origen2),a


		
		ld		bc,11													;cargamos las variables de las cualidades
		ld		de,bitneda_unidades2
		ld		hl,bitneda_unidades
					
		ldir
			
		ld		a,(incremento_velocidad_1)
		ld		(incremento_velocidad),a
		
		jp		SECUENCIA_DEL_TURNO_DEL_JUGADOR
		
VALORES_PROTA_1:
		
		ld		a,1
		ld		(incremento_velocidad),a
		xor		a
		ld		(incremento_defensa),a
		ld		a,2
		ld		(incremento_ataque),a		
		ld		a,4
		ld		(bitneda_unidades),a
		
		ld		a,(nivel)
		cp		1
		ret		nz
		
		ld		a,3
		ld		(vida_decenas),a
		xor		a
		ld		(vida_unidades),a

		ret
		
VALORES_PROTA_2:

		xor		a
		ld		(incremento_velocidad),a
		ld		a,2
		ld		(incremento_defensa),a
		ld		a,1
		ld		(incremento_ataque),a		
		ld		a,8
		ld		(bitneda_unidades),a
		
		ld		a,(nivel)
		cp		1
		ret		nz
		
		ld		a,3
		ld		(vida_decenas),a
		ld		a,5
		ld		(vida_unidades),a
		
		ret
		
VALORES_PROTA_3:

		ld		a,1
		ld		(incremento_velocidad),a
		xor		a
		ld		(incremento_defensa),a	
		ld		a,2
		ld		(incremento_ataque),a				
		ld		a,6
		ld		(bitneda_unidades),a
		
		ld		a,(nivel)
		cp		1
		ret		nz
		
		ld		a,3
		ld		(vida_decenas),a
		ld		a,5
		ld		(vida_unidades),a

		ret
		
VALORES_PROTA_4:

		ld		a,2
		ld		(incremento_velocidad),a
		ld		a,1
		ld		(incremento_defensa),a	
		xor		a
		ld		(incremento_ataque),a				
		ld		a,2
		ld		(bitneda_unidades),a

		ld		a,(nivel)
		cp		1
		ret		nz		
		
		ld		a,3
		ld		(vida_decenas),a
		xor		a
		ld		(vida_unidades),a

		ret

PERSONAJE_DE_CODIGO_1:
									
		ld		a,(incremento_ataque_1)
		ld		(incremento_ataque),a									; pasamos los incrementos1  a incrementos
		ld		a,(incremento_defensa_1)
		ld		(incremento_defensa),a	
		ld		a,(incremento_velocidad_1)
		ld		(incremento_velocidad),a	
		
		jp		SEGUIMOS_CON_PERSONAJE_1

PERSONAJE_DE_CODIGO_2:
									
		ld		a,(incremento_ataque_2)
		ld		(incremento_ataque),a									; pasamos los incrementos1  a incrementos
		ld		a,(incremento_defensa_2)
		ld		(incremento_defensa),a	
		ld		a,(incremento_velocidad_2)
		ld		(incremento_velocidad),a	
		
		jp		SECUENCIA_DEL_TURNO_DEL_JUGADOR
									
SECUENCIA_DEL_TURNO_DEL_JUGADOR:

		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad_1)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de ataque
		ld		a,(incremento_ataque_1)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de defensa
		ld		a,(incremento_defensa_1)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		ld		a,(pagina_de_idioma)
		call	EL_7000	

;		ld		a,(codigo_activo)
;		or		a
;		jp		z,SIN_CODIGO

		ld		a,(bitneda_decenas1)
		ld		(bitneda_decenas),a

		ld		a,(bitneda_centenas1)
		ld		(bitneda_centenas),a
						
;SIN_CODIGO:
		
		ld		a,(bitneda_unidades1)
		ld		(bitneda_unidades),a
		call	PINTA_BITNEDAS
		
		ld		a,(vida_unidades1)
		ld		(vida_unidades),a
		ld		a,(vida_decenas1)
		ld		(vida_decenas),a		
		call	PINTA_VIDA
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,antes_de_preparar_variables
		
		ld		a,2
		ld		(turno),a
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad_2)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de ataque
		ld		a,(incremento_ataque_2)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de defensa
		ld		a,(incremento_defensa_2)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,antes_de_preparar_variables

;		ld		a,(codigo_activo)
;		or		a
;		jp		z,SIN_CODIGO_2

		ld		a,(bitneda_decenas2)
		ld		(bitneda_decenas),a

		ld		a,(bitneda_centenas2)
		ld		(bitneda_centenas),a

;IN_CODIGO_2:
		
		ld		a,(bitneda_unidades2)
		ld		(bitneda_unidades),a
		call	PINTA_BITNEDAS

		ld		a,(vida_unidades2)
		ld		(vida_unidades),a
		ld		a,(vida_decenas2)
		ld		(vida_decenas),a		
		call	PINTA_VIDA
		
antes_de_preparar_variables:

		ld		a,(codigo_activo)
		or		a		
		jp		z,mas_cosas_sin_codigo
		
		ld		ix,codigo_salve
		ld		a,(ix)
		and		00000011b
		ld		(turno),a
		jp		preparamos_las_variables_para_jugador_adecuado

mas_cosas_sin_codigo:
		
		ld		a,1
		ld		(turno),a
		ld		hl,301
		ld		(casilla_del_oponente),hl
		
preparamos_las_variables_para_jugador_adecuado:

		ld		a,(turno)
		cp		2
		jp		z,prepara_jugador_2
		
prepara_jugador_1:
				
		ld		bc,30													; cargamos las variables de los objetos
		ld		de,brujula
		ld		hl,brujula1
					
		ldir

		ld		a,13
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a
																		
		jp		justo_antes_de_pintar_el_mapa

prepara_jugador_2:
		
		ld		bc,30													; cargamos las variables de los objetos
		ld		de,brujula
		ld		hl,brujula2
					
		ldir


		ld		a,237
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a								

justo_antes_de_pintar_el_mapa:

		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		xor		a
		ld		(codigo_activo),a
		
se_pinta_el_mapa:
 
		call	PINTAMOS_LA_BASE_DEL_LABERINTO_EN_PAGE_1
		call	PINTAMOS_EL_LABERINTO_CONDICIONADO_AL_MAPA

se_pinta_punto_cardinal_si_procede:

		ld		a,(brujula)
		cp		1
		jr.		nz,se_borra_punto_cardinal
		
		call	COLOCA_PUNTO_CARDINAL_parte_1
		
se_va_a_tirar_el_dado:
		
		call	se_tira_el_dado
		
se_borra_punto_cardinal:
		
		call	BORRA_PUNTO_CARDINAL									
		
se_tira_el_dado:

		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_activa_jugador_1							; rutina especial de caras para cuando sólo juego un jugador
		call	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		tirando

.pinta_jugador_2:

		ld		iy,copia_cara_activa_jugador_2							; rutina especial de caras para cuando sólo juego un jugador
		call	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
tirando:
		
		call	DIRECTRICES_VALOR_DADO									;pintamos 0 en dado y valor movimiento
		xor		a
		ld		(valor_a_transm_a_dib),a

		ld		a,16
		call	EL_7000

		
		ld		a,0
		ld		c,2
		call	ayFX_INIT
				
		call	DA_VALOR_AL_DADO
		call	PINTA_EL_DADO_QUE_HA_SALIDO_parte_1
		
		ld 		a,(toca_dado)
		cp		0
		jp		nz,se_tira_el_dado

		ld		a,4														;si pulsa M vamos a ver si puede ver el papiro
		call	SNSMAT
		bit		2,a
		call	z,MIRAMOS_EL_PAPIRO
		
		ld		a,6														;si pulsa F3 nos da código de salvado
		call	SNSMAT
		bit		7,a
		call	z,CARGAMOS_CODIGO_DE_SALVADO
		
		ld		a,(turno)
		add		2
		call	GTTRIG
		cp		#FF
		call	z,MIRAMOS_EL_PAPIRO
				
		xor		a
		call	GTTRIG
		cp		255
		
		jp		z,pasamos_el_valor_del_dado_al_contador
		
		ld		a,(turno)
		call	GTTRIG
		CP		255
		
		jr.		nz,se_tira_el_dado

pasamos_el_valor_del_dado_al_contador:


		ld		a,16
		call	EL_7000

		
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA
		
		ld		a,1
		ld		c,1
		call	ayFX_INIT
		
		ld		iy,cuadrado_que_limpia_4
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		bc,187
		ld		(ix+4),c												;x inicio linea

		call	PINTA_DIRECTRICES_DEL_COPY
				
		call	DIRECTRICES_VALOR_DADO
		ld		a,(dado)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
calcula_lo_que_puede_moverse:

		ld		a,(dado)
		ld		b,a
		ld		a,(incremento_velocidad)
		add		a,b
		ld		(desplazamiento_real),a

Pintamos_los_desplazamientos_reales:

		ld		a,16
		call	EL_7000

		
		ld		a,1
		ld		c,0
		call	ayFX_INIT
				
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA

		call	DIRECTRICES_VALOR_MOVIMIENTO_REAL

		ld		a,(desplazamiento_real)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

se_mueve_las_casillas_adecuadas:

		LD		A,(pagina_de_idioma)
		call	EL_7000													;banco 2, pagina 14 del MEGAROM
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_neutra_jugador_1							; rutina especial de caras para cuando sólo juego un jugador
		call	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		movimiento

.pinta_jugador_2:

		ld		iy,copia_cara_neutra_jugador_2							; rutina especial de caras para cuando sólo juego un jugador
		call	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
movimiento:

		ld		a,16
		call	EL_7000
						
		call	MOVIMIENTO_DEL_JUGADOR
		
		ld		a,(brujula)
		cp		1
		jp		nz,se_repinta_de_nuevo_el_mapa
		
		call	COLOCA_PUNTO_CARDINAL_parte_1

se_repinta_de_nuevo_el_mapa:
		
		call	PINTAMOS_LA_BASE_DEL_LABERINTO_EN_PAGE_1
		call	PINTAMOS_EL_LABERINTO_CONDICIONADO_AL_MAPA

se_pinta_mapa_si_procede:

		ld		a,(papel)												; vamos a ver si se dan las condiciones para dibujar el mapa
		cp		0
		jp		z,se_reduce_en_pantalla_el_valor_de_movimiento_y_se_ve_si_termina_ese_movimiento

		ld		a,(pluma)
		cp		0
		jp		z,se_reduce_en_pantalla_el_valor_de_movimiento_y_se_ve_si_termina_ese_movimiento
		
		ld		a,(tinta)
		cp		1
		call	z,DIBUJAMOS_MAPA	
		
se_reduce_en_pantalla_el_valor_de_movimiento_y_se_ve_si_termina_ese_movimiento:

		call	DIRECTRICES_VALOR_MOVIMIENTO_REAL
		ld		a,(desplazamiento_real)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,(desplazamiento_real)		
		cp		0
		jr.		nz,se_mueve_las_casillas_adecuadas

se_comprueba_si_hay_eventos:

		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		ld		ix,eventos_laberinto									;ponemos en ix el valor de evento que hay en la casilla que está el jugador
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		ld		a,(ix)
		ld		de,POINT_EVENTOS
		call	lista_de_opciones										; elegimos el destino

se_comprueba_si_hay_colision_de_personajes:

		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,se_decide_si_se_pasa_al_siguiente_jugador
		
		ld		a,(colision_de_personajes)
		or		a
		jp		z,se_decide_si_se_pasa_al_siguiente_jugador
		
		ld		a,5
		call	EL_7000
		
		call	EL_6000_PARA_37_COLISION	
				
se_decide_si_se_pasa_al_siguiente_jugador:		
		
		ld		a,(turno_sin_tirar)
		cp		0
		jp		nz,un_turno_menos
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jr.		nz,son_dos_jugadores

		ld		bc,33													;salvamos las variables por si se quiere guardar partida
		ld		de,posicion_en_mapa_1
		ld		hl,posicion_en_mapa
					
		ldir
				
		ld		a,13
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a
		jp		se_tira_el_dado

un_turno_menos:

		dec		a
		ld		(turno_sin_tirar),a
		jp		se_tira_el_dado
		
son_dos_jugadores:
				
		ld		a,16
		call	EL_7000

		ld		a,3
		ld		c,1
		call	ayFX_INIT

seleccionamos_turno:
		
		ld		a,(turno)
		cp		1
		jp		z,paso_turno_a_jugador_2
		
		jp		paso_turno_a_jugador_1
				
limpiamos_fondo:

		ld		iy,cuadrado_que_limpia_5
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		a,11010000b
		ld		(ix+14),a
				
		ret

limpiamos_fondo_1:

		ld		iy,cuadrado_que_limpia_5_1
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		a,11010000b
		ld		(ix+14),a
				
		ret
		
paso_turno_a_jugador_1:
		
		ld		hl,(posicion_en_mapa)
		ld		(casilla_del_oponente),hl								; guardamos el valor de la casilla en la que está por si se cruza con el otro jugador
				
		ld		a,(pagina_de_idioma)
		call	EL_7000


		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa_2
		ld		hl,posicion_en_mapa
					
		ldir
		
		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa
		ld		hl,posicion_en_mapa_1
					
		ldir		
										
		ld		a,1
		ld		(turno),a
		
		call	STRIG_DE_CONTINUE_CAMBIO_DE_JUGADOR
		call	limpiamos_fondo_1
		call	limpiamos_fondo

		ld		a,(set_page01)
		cp		1
		jp		nz,a_limpiar_1

		ld		iy,copia_escenario_a_page_1								; Si estamos en page 0. Vamos a clonar la 0 en la 1
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO
		


a_limpiar_1:
				
		
		ld		a,13
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a
		ld		a,1
		ld		(set_page01),a		
		call	ESCRIBIMOS_EL_NOMBRE_DEL_PROTA
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
													
		call	se_pinta_el_mapa

paso_turno_a_jugador_2:
		
		ld		hl,(posicion_en_mapa)
		ld		(casilla_del_oponente),hl								; guardamos el valor de la casilla en la que está por si se cruza con el otro jugador
		
		ld		a,(pagina_de_idioma)
		call	EL_7000

		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa_1
		ld		hl,posicion_en_mapa
					
		ldir
		
		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa
		ld		hl,posicion_en_mapa_2
					
		ldir
						
		ld		a,2
		ld		(turno),a
		
		call	STRIG_DE_CONTINUE_CAMBIO_DE_JUGADOR
		call	limpiamos_fondo
		call	limpiamos_fondo_1

		ld		a,(set_page01)
		cp		1
		jp		nz,a_limpiar_2

		ld		iy,copia_escenario_a_page_1								; Si estamos en page 0. Vamos a clonar la 0 en la 1
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO

		
		ld		a,1
		ld		(set_page01),a
		

a_limpiar_2:
						
		
		ld		a,237
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a
		
		call	ESCRIBIMOS_EL_NOMBRE_DEL_PROTA
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		
		ld		a,50
		ld		(ralentizando),a
		call	RALENTIZA
												
		jp		se_pinta_el_mapa

FIN_DE_LA_SECUENCIA_DE_TURNO:

COLOCA_PUNTO_CARDINAL_parte_1:
		
		ld		iy,copia_punto_cardinal
		call	COPY_A_GUSTO

		call	EL_12_A_0_EL_14_A_1001
		ld		a,1
		ld		(ix+12),a												;color	

		ld		a,(orientacion_del_personaje)
		cp		0
		jr.		z,.NORTE
		cp		1
		jr.		z,.ESTE
		cp		2
		jr.		z,.SUR
		cp		3
		jr.		z,.OESTE

.NORTE
		
		ld		bc,152

		jr.		COLOCA_PUNTO_CARDINAL_parte_2

.SUR
		
		ld		bc,165

		jr.		COLOCA_PUNTO_CARDINAL_parte_2

.ESTE
		
		ld		bc,178

		jr.		COLOCA_PUNTO_CARDINAL_parte_2

.OESTE
		
		ld		bc,191
				
COLOCA_PUNTO_CARDINAL_parte_2:
		
		ld		(ix),c													;x origen
		ld		(ix+1),b														;cómo es el copy	
		
		call	EL_12_A_0_EL_14_A_1001

		
		ld		hl,datos_del_copy
		jp		DoCopy
				
BORRA_PUNTO_CARDINAL:
		
		ld		iy,cuadrado_que_limpia_6
		call	COPY_A_GUSTO
						
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,10000000b
		ld		(ix+14),a												;especificamos la linea
		ld		hl,datos_del_copy
		jp		DoCopy

DIRECTRICES_RECTIFICACION_VELOCIDAD:
		
		ld		ix,datos_del_copy
		ld		bc,12
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


									
DIRECTRICES_VALOR_DADO:
		
		ld		ix,datos_del_copy
		ld		bc,12
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
		
		ld		bc,7
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
		
.ZONA_JUG_2:
		
		ld		bc,216
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
				
		ret

DIRECTRICES_VALOR_MOVIMIENTO_REAL:
		
		ld		ix,datos_del_copy
		ld		bc,12
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		
		ld		a,(turno)
		
		cp		1
		jr.		z,.ZONA_JUG_1
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,37
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
		
.ZONA_JUG_2:
		
		ld		bc,245
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
				
		ret
				
MOVIMIENTO_DEL_JUGADOR:

		xor		a														;si pulsa el boton 1 vamos a ver si puede acabar el turno
		call	GTTRIG
		cp		#FF
		call	z,MIRAMOS_PARADA
		
		ld		a,(turno)
		call	GTTRIG
		cp		#FF
		call	z,MIRAMOS_PARADA
						
		ld		a,4														;si pulsa M vamos a ver si puede ver el papiro
		call	SNSMAT
		bit		2,a
		call	z,MIRAMOS_EL_PAPIRO

		ld		a,6														;si pulsa F3 nos da código de salvado
		call	SNSMAT
		bit		7,a
		call	z,CARGAMOS_CODIGO_DE_SALVADO
		
		ld		a,(turno)
		add		2
		call	GTTRIG													;si pulsa el boton 2 vamos a ver si puede ver el papiro
		cp		#FF
		call	z,MIRAMOS_EL_PAPIRO
				
		xor		a														;comprobamos si toca teclado
		call	GTSTCK
		cp		0
		jp		z,MOVIMIENTO_DEL_JUGADOR_2
		
		jp		MOVIMIENTO_DEL_JUGADOR_3

MOVIMIENTO_DEL_JUGADOR_2:

		ld		a,(turno)														;comprobamos si toca mando
		call	GTSTCK
		cp		0
		jp		z,MOVIMIENTO_DEL_JUGADOR_4
				
MOVIMIENTO_DEL_JUGADOR_3:
		
		ex		af,af'
		ld		a,(anterior_valor)
		cp		0
		jp		nz,MOVIMIENTO_DEL_JUGADOR
		ex		af,af'
		
		ld		(anterior_valor),a
		
		cp		1
		jp		z,DEFINE_AVANCE
		cp		3
		jp		z,GIRO_A_LA_DERECHA
		cp		7
		jp		z,GIRO_A_LA_IZQUIERDA
		
		jp		MOVIMIENTO_DEL_JUGADOR

MOVIMIENTO_DEL_JUGADOR_4:
	
		xor		a
		ld		(anterior_valor),a
		jp		MOVIMIENTO_DEL_JUGADOR
		
DEFINE_AVANCE:
	
		ld		iy,copia_saltito_al_avanzar								;VAMOS A HACER UN ESCALON PARA QUE PAREZCA QUE CUANDO AVANZA CAMINA Y SI LA SIGUIENTE
		call	COPY_A_GUSTO											;IMAGEN ES IGUAL, SE NOTA QUE SE HA AVANZADO
		call	RECTIFICACION_POR_PAGE_1_SOBRE_SI_MISMO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,cuadrado_que_limpia_7								;pintamos un cuadrado del color del suelo en la parte que ha quedado a vista al 
		call	COPY_A_GUSTO											;simular el saltito

		call	RECTIFICACION_POR_PAGE_1_SOBRE_SI_MISMO

		ld		a,14
		ld		(ix+12),a												;color
		ld		a,10000000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,16
		call	EL_7000
		
		ld		a,2
		ld		c,2
		call	ayFX_INIT
				
		ld		ix,mapa_del_laberinto
		ld		bc,(posicion_en_mapa)
		add		ix,bc
		
		ld		a,(contador_piedras_y_ramas)							; rotamos este valo para que las piedras y ramas salgan en orden
		inc		a
		and		00000111B
		ld		(contador_piedras_y_ramas),a
				
		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_DE_AVANCE
		jp		lista_de_opciones
							
AVANCE_NORTE:

		ld		a,(ix)		
		ld 		de,POINT_AVANCE_NORTE
		jp		lista_de_opciones
		
AVANCE_NORTE_DOS:
							
		ld		a,(desplazamiento_real)
		dec		a
		ld		(desplazamiento_real),a
		
		ld		hl,(posicion_en_mapa)
		ld		bc,30
		or		a
		sbc		hl,bc
		ld		(posicion_en_mapa),hl

		ld		a,(y_map)
		sub		5
		ld		(y_map),a
		
		jp		FIN_DE_TURNO

AVANCE_ESTE:
		
		ld		a,(ix)
		ld 		de,POINT_AVANCE_ESTE
		jp		lista_de_opciones
				
AVANCE_ESTE_DOS:
		
		ld		a,(desplazamiento_real)
		dec		a
		ld		(desplazamiento_real),a
		
		ld		hl,(posicion_en_mapa)
		inc		hl
		ld		(posicion_en_mapa),hl
		
		ld		a,(x_map)
		add		5
		ld		(x_map),a
		
		jr.		FIN_DE_TURNO

AVANCE_SUR:
		
		ld		a,(ix)
		ld 		de,POINT_AVANCE_SUR
		jp		lista_de_opciones
				
AVANCE_SUR_DOS:
		
		ld		a,(desplazamiento_real)
		dec		a
		ld		(desplazamiento_real),a
		
		ld		hl,(posicion_en_mapa)
		ld		bc,30
		or		a
		adc		hl,bc
		ld		(posicion_en_mapa),hl
		
		ld		a,(y_map)
		add		5
		ld		(y_map),a
		
		jr.		FIN_DE_TURNO

AVANCE_OESTE:
		
		ld		a,(ix)
		ld 		de,POINT_AVANCE_OESTE
		jp		lista_de_opciones
				
AVANCE_OESTE_DOS:
		
		ld		a,(desplazamiento_real)
		dec		a
		ld		(desplazamiento_real),a
		
		ld		hl,(posicion_en_mapa)
		dec		hl
		ld		(posicion_en_mapa),hl
		
		ld		a,(x_map)
		sub		5
		ld		(x_map),a
		
		jr.		FIN_DE_TURNO

GIRO_A_LA_DERECHA:
		
		ld		a,16
		call	EL_7000
		
		ld		a,4
		ld		c,2
		call	ayFX_INIT
		
		ld		a,1
		ld		(giro_hacia),a
		
		ld		a,(orientacion_del_personaje)
		cp		3
		jr.		z,SALTO_DE_VARIABLE_EN_EL_GIRO_A_LA_DERECHA
		inc		a
		ld		(orientacion_del_personaje),a
		jp		FIN_DE_TURNO

SALTO_DE_VARIABLE_EN_EL_GIRO_A_LA_DERECHA:
	
		xor		a
		ld		(orientacion_del_personaje),a
		jp		FIN_DE_TURNO

GIRO_A_LA_IZQUIERDA:
		
		ld		a,16
		call	EL_7000
		
		ld		a,4
		ld		c,2
		call	ayFX_INIT
		
		ld		a,2
		ld		(giro_hacia),a
		
		ld		a,(orientacion_del_personaje)
		cp		0
		jp		z,SALTO_DE_VARIABLE_EN_EL_GIRO_A_LA_IZQUIERDA
		dec		a
		ld		(orientacion_del_personaje),a
		jp		FIN_DE_TURNO

SALTO_DE_VARIABLE_EN_EL_GIRO_A_LA_IZQUIERDA:
	
		ld		a,3
		ld		(orientacion_del_personaje),a
				
FIN_DE_TURNO:

		ret

FIN_DE_TURNO_PREV:

		; VAMOS A COMPROBAR SI AL TIRAR CONTRA UNA PARED, ESTÁ ENTRANDO EN LA SALIDA, LA ENTRADA O UNA POCHADA
						
		ld		ix,eventos_laberinto									; capturamos el valor de evento de la casilla en la que estamos
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)

		cp		16
		jp		z,INTENTA_SALIR
		cp		17
		jp		z,INTENTA_SALIR_POR_SALIDA
		cp		14
		jp		z,QUIERE_ENTRAR_EN_POCHADA
		cp		30
		jp		z,QUIERE_ENTRAR_EN_POCHADA
		cp		31
		jp		z,QUIERE_ENTRAR_EN_POCHADA
		cp		32
		jp		z,QUIERE_ENTRAR_EN_POCHADA
							
CHOCA_CONTRA_LA_PARED:

		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		ld		a,(vida_unidades)
		dec		a
		ld		(vida_unidades),a
		
		call	AJUSTA_VIDA_HACIA_ABAJO
		call	PINTA_VIDA
		call	GOLPE_EN_LA_PARED
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_pierde_jugador_1							
		call	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		SONIDO_GOLPE

.pinta_jugador_2:

		ld		iy,copia_cara_pierde_jugador_2							
		call	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

SONIDO_GOLPE:		
								
		ld		a,16
		call	EL_7000
		
		ld		a,5
		ld		c,0
		jp		ayFX_INIT

		
DA_VALOR_AL_DADO:

		ld		a,r
		and		00000111b		
		ld		(dado),a
		
		ret

INTENTA_SALIR:

		ld		ix,decorados_laberinto									; capturamos el valor de evento de la casilla en la que estamos
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)
				
		cp		19
		jp		z,.ESTE
		cp		20
		jp		z,.NORTE
		cp		21
		jp		z,.OESTE
		cp		22
		jp		z,.SUR
		
		jp		CHOCA_CONTRA_LA_PARED
		
.ESTE:
		
		ld		a,(orientacion_del_personaje)
		cp		1
		jp		z,NO_PODEMOS_SALIR
		jp		CHOCA_CONTRA_LA_PARED
		
.NORTE:

		ld		a,(orientacion_del_personaje)
		cp		0
		jp		z,NO_PODEMOS_SALIR
		jp		CHOCA_CONTRA_LA_PARED
		
.OESTE:

		ld		a,(orientacion_del_personaje)
		cp		3
		jp		z,NO_PODEMOS_SALIR
		jp		CHOCA_CONTRA_LA_PARED
		
.SUR:

		ld		a,(orientacion_del_personaje)
		cp		2
		jp		z,NO_PODEMOS_SALIR
		jp		CHOCA_CONTRA_LA_PARED

INTENTA_SALIR_POR_SALIDA:

		ld		ix,decorados_laberinto									; capturamos el valor de evento de la casilla en la que estamos
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)

		cp		13
		jp		z,.ESTE
		cp		14
		jp		z,.NORTE
		cp		15
		jp		z,.OESTE
		cp		16
		jp		z,.SUR
		
		jp		CHOCA_CONTRA_LA_PARED
		
.ESTE:
		
		ld		a,(orientacion_del_personaje)
		cp		1
		jp		z,VAMOS_A_VER_SI_TENEMOS_LLAVE
		jp		CHOCA_CONTRA_LA_PARED
		
.NORTE:

		ld		a,(orientacion_del_personaje)
		cp		0
		jp		z,VAMOS_A_VER_SI_TENEMOS_LLAVE
		jp		CHOCA_CONTRA_LA_PARED
		
.OESTE:

		ld		a,(orientacion_del_personaje)
		cp		3
		jp		z,VAMOS_A_VER_SI_TENEMOS_LLAVE
		jp		CHOCA_CONTRA_LA_PARED
		
.SUR:

		ld		a,(orientacion_del_personaje)
		cp		2
		jp		z,VAMOS_A_VER_SI_TENEMOS_LLAVE
		jp		CHOCA_CONTRA_LA_PARED
				
VAMOS_A_VER_SI_TENEMOS_LLAVE:

		ld		a,(llave)
		cp		1
		jp		z,TENEMOS_LLAVE_Y_SALIMOS
															; cambiamos la pagina 2 para poder leer efectos
		ld		a,(pagina_de_idioma)
		call	EL_7000
			
		call	AVISO_DE_NO_SALIDA_EN_LA_SALIDA
		
		ret
		
QUIERE_ENTRAR_EN_POCHADA:

		ld		ix,decorados_laberinto									; capturamos el valor de evento de la casilla en la que estamos
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)

		cp		25
		jp		z,.ESTE
		cp		26
		jp		z,.NORTE
		cp		27
		jp		z,.OESTE
		cp		28
		jp		z,.SUR
		
		jp		CHOCA_CONTRA_LA_PARED
		
.ESTE:
		
		ld		a,(orientacion_del_personaje)
		cp		1
		jp		z,ENTRA_EN_POCHADA
		jp		CHOCA_CONTRA_LA_PARED
		
.NORTE:

		ld		a,(orientacion_del_personaje)
		cp		0
		jp		z,ENTRA_EN_POCHADA
		jp		CHOCA_CONTRA_LA_PARED
		
.OESTE:

		ld		a,(orientacion_del_personaje)
		cp		3
		jp		z,ENTRA_EN_POCHADA
		jp		CHOCA_CONTRA_LA_PARED
		
.SUR:

		ld		a,(orientacion_del_personaje)
		cp		2
		jp		z,ENTRA_EN_POCHADA
		jp		CHOCA_CONTRA_LA_PARED

ENTRA_EN_POCHADA:														

		ld		a,5
		call	EL_7000
		
		jp		EL_6000_PARA_37_POCHADA	

SALE_DE_POCHADA:
		
		ret
		
NO_PODEMOS_SALIR:

																		; cambiamos la pagina 20 para poder leer efectos
		ld		a,(pagina_de_idioma)
		call	EL_7000

				
		call	AVISO_DE_NO_SALIDA


		ld		a,16
		call	EL_7000

		
		ld		a,12
		ld		c,0
		jp		ayFX_INIT

TENEMOS_LLAVE_Y_SALIMOS:												

		pop		af

		jp		VAMOS_A_DECIDIR_QUE_PASA_AL_SALIR
		
PINTA_EL_DADO_QUE_HA_SALIDO_parte_1:

		
		ld		iy,copia_dado											
		call	COPY_A_GUSTO											
		
		call	EL_12_A_0_EL_14_A_1001

		
		ld		a,(dado)
		ld 		de,POINT_DADO
		jp		lista_de_opciones
		
DATOS_1:
		
		ld		bc,142
		ld		(ix),c													;x origen
		ld		a,1
		jr.		PINTA_EL_DADO_QUE_HA_SALIDO_parte_2

DATOS_2:
		
		ld		bc,158
		ld		(ix),c													;x origen
		ld		a,2
		jr.		PINTA_EL_DADO_QUE_HA_SALIDO_parte_2

DATOS_3:
		
		ld		bc,174
		ld		(ix),c													;x origen
		ld		a,3
		jr.		PINTA_EL_DADO_QUE_HA_SALIDO_parte_2

DATOS_4:
		
		ld		bc,190
		ld		(ix),c													;x origen
		ld		a,4
		jr.		PINTA_EL_DADO_QUE_HA_SALIDO_parte_2
		
DATOS_5:
		
		ld		bc,206
		ld		(ix),c													;x origen
		ld		a,5
		jr.		PINTA_EL_DADO_QUE_HA_SALIDO_parte_2
		
DATOS_6:
		
		ld		bc,222
		ld		(ix),c													;x origen
		ld		a,6
		
PINTA_EL_DADO_QUE_HA_SALIDO_parte_2:
		
		ld		(dado),a
		ld		a,(turno)
		
		cp		1
		jr.		z,.ZONA_JUG_1
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,56
		
		jp		PINTA_EL_DADO_QUE_HA_SALIDO_parte_3
		
.ZONA_JUG_2:
		
		ld		bc,187
	
PINTA_EL_DADO_QUE_HA_SALIDO_parte_3:
		
		ld		(ix+4),c												;x destino
		ld		(ix+5),b		

		ld		a,(toca_dado)
		cp		0
		jp		nz,SI_PINTAMOS_DADO
		
		ld		a,1
		ld		(toca_dado),a
				
		ld		bc,140
		ld		(ix+2),c													;x origen

		jp		PINTA_DADO_FINAL

CARGAMOS_CODIGO_DE_SALVADO:

		ld		a,16
		call	EL_7000

		
		ld		a,11
		ld		c,1
		call	ayFX_INIT
		
		ld		a,53
		call	EL_7000

		ld		a,(cantidad_de_jugadores)
		cp		2
		jp		z,ACTUALIZAMOS_VARIABLES_DE_2
		
ACTUALIZAMOS_VARIABLES_DE_1:
		
		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa_1
		ld		hl,posicion_en_mapa
					
		ldir

		jp		DESCIFRAMOS_EL_CODIGO_PARA_GUARDARLO

ACTUALIZAMOS_VARIABLES_DE_2:
		
		ld		a,(turno)
		cp		1
		JP		z,ACTUALIZAMOS_VARIABLES_DE_1
		
		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa_2
		ld		hl,posicion_en_mapa
					
		ldir

DESCIFRAMOS_EL_CODIGO_PARA_GUARDARLO:
						
		call	DESCIFRAMOS_EL_CODIGO
				
		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		ld		hl,AVISO_CODIGO_ESP1
		call	TEXTO_A_ESCRIBIR
		ld		hl,AVISO_CODIGO_ESP2
		call	TEXTO_A_ESCRIBIR
		call	STRIG_DE_CONTINUE
						
		ld		hl,codigo_salve
		call	CODIGO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,AVISO_CODIGO_ESP3
		call	TEXTO_A_ESCRIBIR
		ld		hl,AVISO_CODIGO_ESP4
		call	TEXTO_A_ESCRIBIR
		call	STRIG_DE_CONTINUE

		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
								
		ld		a,16
		call	EL_7000
		
		call	strmus
				
		ld		a,(pagina_de_idioma)
		call	EL_7000
				
		ret
		
SI_PINTAMOS_DADO:

		xor		a
		ld		(toca_dado),a		

		ld		bc,114
		ld		(ix+2),c													;x origen
		
PINTA_DADO_FINAL:

		jp		HL_DATOS_DEL_COPY_CALL_DOCOPY
		
PINTAMOS_EL_LABERINTO_CONDICIONADO_AL_MAPA:

DECIDIMOS_PUNTO_CARDINAL_PARA_CUARTA_FASE:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_FASE_4
		jp		lista_de_opciones

CUARTA_FASE_NORTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)

		ld		bc,90
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc
			
		ld		a,(ix)
		ld 		de,POINT_CUARTA_FASE_NORTE
		jp		lista_de_opciones
					
CUARTA_FASE_ESTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,3
		add		ix,bc

		ld		a,(ix)
		ld 		de,POINT_CUARTA_FASE_ESTE
		jp		lista_de_opciones


CUARTA_FASE_SUR:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,90
		add		ix,bc

		ld		a,(ix)
		ld 		de,POINT_CUARTA_FASE_SUR
		jp		lista_de_opciones
				
CUARTA_FASE_OESTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,3
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc


		ld		a,(ix)
		ld		a,(ix)
		ld 		de,POINT_CUARTA_FASE_OESTE
		jp		lista_de_opciones

RECTIFICACION_POR_PAGE_1_INVERTIDAS:

		ld		a,(set_page01)
		cp		0
		ret		z
		call	LA_RECTIFICACION
		xor		a
		ld		(ix+3),a
		ret
		
RECTIFICACION_POR_PAGE_1_SOBRE_SI_MISMO:

		ld		a,(set_page01)
		cp		0
		ret		z
		call	LA_RECTIFICACION
		ld		L,(ix+2)
		ld		H,(ix+3)
		adc		hl,de				
		ld		(ix+2),l
		ld		(ix+3),h
		ret
		
RECTIFICACION_POR_PAGE_1:

		ld		a,(set_page01)
		cp		1
		ret		z

LA_RECTIFICACION:
		
		or		a
		ld		de,#100
		ld		L,(ix+6)
		ld		H,(ix+7)
		adc		hl,de
		ld		(ix+6),L
		ld		(ix+7),H
		
		ret

RECTIFICACION_POR_PAGE_0:

		ld		a,(set_page01)
		cp		0
		ret		z

		jp		LA_RECTIFICACION
				
CUARTA_FASE_0:

		ld		iy,copia_cuarta_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_abierta
				
		jr.		FIN_CUARTA_FASE
		
CUARTA_FASE_1:

		ld		iy,copia_cuarta_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_abierta
		
		jr.		FIN_CUARTA_FASE
		
CUARTA_FASE_2:

		ld		iy,copia_cuarta_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_abierta
		
		jr.		FIN_CUARTA_FASE

CUARTA_FASE_3:

		ld		iy,copia_cuarta_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_abierta
		
		jr.		FIN_CUARTA_FASE

CUARTA_FASE_4:
		
		ld		iy,copia_cuarta_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_cerrada
		
		jr.		FIN_CUARTA_FASE

CUARTA_FASE_5:
		
		ld		iy,copia_cuarta_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_cerrada
	
		jr.		FIN_CUARTA_FASE

CUARTA_FASE_6:

		ld		iy,copia_cuarta_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_cerrada

		jr.		FIN_CUARTA_FASE

CUARTA_FASE_7:

		ld		iy,copia_cuarta_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_cuarta_fase_izquierda_cerrada

FIN_CUARTA_FASE:

		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		ld		a,11010000B
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		LD		A,24
		call	EL_7000	

		jp		CUARTA_FASE_DECORADOS
				
DECIDIMOS_PUNTO_CARDINAL_PARA_TERCERA_FASE:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_FASE_3
		jp		lista_de_opciones
	
TERCERA_FASE_NORTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,60
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)
		ld 		de,POINT_TERCERA_FASE_NORTE
		jp		lista_de_opciones				

TERCERA_FASE_ESTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,2
		add		ix,bc
		
		ld		a,(ix)
		ld 		de,POINT_TERCERA_FASE_ESTE
		jp		lista_de_opciones

TERCERA_FASE_SUR:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,60
		add		ix,bc

		ld		a,(ix)
		ld 		de,POINT_TERCERA_FASE_SUR
		jp		lista_de_opciones
		
TERCERA_FASE_OESTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,2
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc


		ld		a,(ix)
		ld 		de,POINT_TERCERA_FASE_OESTE
		jp		lista_de_opciones
		
TERCERA_FASE_0:

		ld		iy,copia_tercera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_izquierda_abierta
		
		jr.		FIN_TERCERA_FASE
		
TERCERA_FASE_1:

		ld		iy,copia_tercera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_izquierda_abierta
		
		jr.		FIN_TERCERA_FASE
		
TERCERA_FASE_2:

		ld		iy,copia_tercera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_tercera_fase_izquierda_abierta
		
		jr.		FIN_TERCERA_FASE

TERCERA_FASE_3:

		ld		iy,copia_tercera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_tercera_fase_izquierda_abierta
		
		jr.		FIN_TERCERA_FASE

TERCERA_FASE_4:
		
		ld		iy,copia_tercera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_izquierda_cerrada
		
		jr.		FIN_TERCERA_FASE

TERCERA_FASE_5:

		ld		iy,copia_tercera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_izquierda_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,10011000B
		ld		(ix+14),a
		
.COMPROBAMOS_PIEDRA:
		
		ld		a,(contador_piedras_y_ramas)
		cp		1
		jp		nz,.COMPROBAMOS_RAMA
		
		ld		iy,copia_piedra_3
		jr.		FIN_TERCERA_FASE

.COMPROBAMOS_RAMA:
		
		cp		5
		jp		nz,FIN_TERCERA_FASE
		
		ld		iy,copia_rama_3
		jp		FIN_TERCERA_FASE

TERCERA_FASE_6:

		ld		iy,copia_tercera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_tercera_fase_izquierda_cerrada
		
		jr.		FIN_TERCERA_FASE

TERCERA_FASE_7:

		ld		iy,copia_tercera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_tercera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_tercera_fase_izquierda_cerrada
		
FIN_TERCERA_FASE:
		
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,11010000B
		ld		(ix+14),a
		
		ld		a,24
		call	EL_7000
		
		jp		TERCERA_FASE_DECORADOS
		
DECIDIMOS_PUNTO_CARDINAL_PARA_SEGUNDA_FASE:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_FASE_2
		jp		lista_de_opciones

SEGUNDA_FASE_NORTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,30
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)
		ld 		de,POINT_SEGUNDA_FASE_NORTE
		jp		lista_de_opciones

SEGUNDA_FASE_ESTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,1
		add		ix,bc

		ld		a,(ix)
		ld 		de,POINT_SEGUNDA_FASE_ESTE
		jp		lista_de_opciones

SEGUNDA_FASE_SUR:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,30
		add		ix,bc

		ld		a,(ix)
		ld 		de,POINT_SEGUNDA_FASE_SUR
		jp		lista_de_opciones
		
SEGUNDA_FASE_OESTE:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,1
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc


		ld		a,(ix)
		ld 		de,POINT_SEGUNDA_FASE_OESTE
		jp		lista_de_opciones
		
SEGUNDA_FASE_0:

		ld		iy,copia_segunda_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_izquierda_abierta
		
		jr.		FIN_SEGUNDA_FASE
		
SEGUNDA_FASE_1:

		ld		iy,copia_segunda_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_izquierda_abierta
		
		jr.		FIN_SEGUNDA_FASE
		
SEGUNDA_FASE_2:

		ld		iy,copia_segunda_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_segunda_fase_izquierda_abierta
		
		jr.		FIN_SEGUNDA_FASE

SEGUNDA_FASE_3:


		ld		iy,copia_segunda_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_segunda_fase_izquierda_abierta

		jr.		FIN_SEGUNDA_FASE

SEGUNDA_FASE_4:
		
		ld		iy,copia_segunda_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_izquierda_cerrada
		
		jr.		FIN_SEGUNDA_FASE

SEGUNDA_FASE_5:

		ld		iy,copia_segunda_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_izquierda_cerrada
		
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,10011000B
		ld		(ix+14),a
		
.COMPROBAMOS_PIEDRA:
		
		ld		a,(contador_piedras_y_ramas)
		cp		2
		jp		nz,.COMPROBAMOS_RAMA
		
		ld		iy,copia_piedra_2
		jr.		FIN_SEGUNDA_FASE

.COMPROBAMOS_RAMA:
		
		cp		6
		jp		nz,FIN_SEGUNDA_FASE
		
		ld		iy,copia_rama_2
		jp		FIN_SEGUNDA_FASE

SEGUNDA_FASE_6:

		ld		iy,copia_segunda_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_segunda_fase_izquierda_cerrada
		
		jr.		FIN_SEGUNDA_FASE

SEGUNDA_FASE_7:

		ld		iy,copia_segunda_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_segunda_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_segunda_fase_izquierda_cerrada

FIN_SEGUNDA_FASE:	

		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,11010000B
		ld		(ix+14),a
		
		ld		a,24
		call	EL_7000
		
		jp		SEGUNDA_FASE_DECORADOS
								
DECIDIMOS_PUNTO_CARDINAL_PARA_PRIMERA_FASE:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_FASE_1
		jp		lista_de_opciones
		
PRIMERA_FASE_NORTE:
		
		ld		ix,mapa_del_laberinto
		
		ld		bc,(posicion_en_mapa)
		add		ix,bc

		ld		a,(ix)
		ld 		de,POINT_PRIMERA_FASE_NORTE
		jp		lista_de_opciones

PRIMERA_FASE_ESTE:

		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		
		ld		a,(ix)
		ld 		de,POINT_PRIMERA_FASE_ESTE
		jp		lista_de_opciones

PRIMERA_FASE_SUR:
		
		ld		ix,mapa_del_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc

		ld		a,(ix)
		ld 		de,POINT_PRIMERA_FASE_SUR
		jp		lista_de_opciones
		
PRIMERA_FASE_OESTE:
		
		ld		ix,mapa_del_laberinto
		ld		bc,(posicion_en_mapa)
		add		ix,bc


		ld		a,(ix)
		ld 		de,POINT_PRIMERA_FASE_OESTE
		jp		lista_de_opciones
		
PRIMERA_FASE_0:

		ld		iy,copia_primera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_primera_fase_izquierda_abierta
		
		jr.		FIN_PRIMERA_FASE
		
PRIMERA_FASE_1:

		ld		iy,copia_primera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_primera_fase_izquierda_abierta
		
		jr.		FIN_PRIMERA_FASE
		
PRIMERA_FASE_2:

		ld		iy,copia_primera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_primera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_primera_fase_izquierda_abierta
		
		jr.		FIN_PRIMERA_FASE

PRIMERA_FASE_3:

		ld		iy,copia_primera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_primera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_primera_fase_izquierda_abierta
		
		jr.		FIN_PRIMERA_FASE

PRIMERA_FASE_4:
		
		ld		iy,copia_primera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_primera_fase_izquierda_cerrada
		
		jr.		FIN_PRIMERA_FASE

PRIMERA_FASE_5:

		ld		iy,copia_primera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		iy,copia_primera_fase_izquierda_cerrada
		
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,10011000B
		ld		(ix+14),a
		
.COMPROBAMOS_PIEDRA:
		
		ld		a,(contador_piedras_y_ramas)
		cp		3
		jp		nz,.COMPROBAMOS_RAMA
		
		ld		iy,copia_piedra_1
		jr.		FIN_PRIMERA_FASE

.COMPROBAMOS_RAMA:
		
		cp		7
		jp		nz,FIN_PRIMERA_FASE
		
		ld		iy,copia_rama_1
		jp		FIN_PRIMERA_FASE
		
PRIMERA_FASE_6:

		ld		iy,copia_primera_fase_derecha_abierta
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_primera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_primera_fase_izquierda_cerrada
		
		jr.		FIN_PRIMERA_FASE

PRIMERA_FASE_7:

		ld		iy,copia_primera_fase_derecha_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_primera_fase_fondo_cerrada
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		ld		iy,copia_primera_fase_izquierda_cerrada
		
FIN_PRIMERA_FASE:	

		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,11010000B
		ld		(ix+14),a

		ld		a,(desplazamiento_real)									; si aun no ha tirado el dado, seguimos sin más
		cp		0
		jp		z,.CONTINUAMOS

		ld		a,(no_borra_texto)
		cp		1
		jp		z,.CONTINUAMOS
		
		ld		a,(pagina_de_idioma)													; Borramos cualquier posible texto anterior
		call	EL_7000
		
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR

.CONTINUAMOS:
		
		xor		a
		ld		(no_borra_texto),a
		
		ld		a,24
		call	EL_7000

		jp		PRIMERA_FASE_DECORADOS	

HAY_ALGUIEN_AQUI:

		ld		a,(cantidad_de_jugadores)								; vamos a comprobar si el otro jugador está aquí
		cp		1
		jp		z,EFECTOS_FINALES
		
		ld		a,(casilla_del_oponente)
		ld		b,a
		ld		a,(posicion_en_mapa)
		cp		b
		jp		nz,PRE_EFECTOS_FINALES

		ld		a,1
		ld		(colision_de_personajes),a
		
		ld		a,(set_page01)
		cp		0
		jp		z,.PINTAMOS_EN_1

.PINTAMOS_EN_O:

		ld		hl,copia_sombra_en_vram_0
		
		jp		.COMUN
		
.PINTAMOS_EN_1:
				
		ld		hl,copia_sombra_en_vram_1
		
.COMUN:		
		
		LD		A,2
		call	EL_7000

	

		ld		de,SOMBRA_ENEMIGA
		call	ESPERA_AL_VDP_HMMC

		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		ld		hl,HAY_ALGUIEN_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR

		jp		EFECTOS_FINALES
		
PRE_EFECTOS_FINALES:

		xor		a
		ld		(colision_de_personajes),a
						
EFECTOS_FINALES:
		
		ld		a,(giro_hacia)											
		cp		1														;si ha girado a la derecha se irá a la secuencia de copy especial para ello
		jp		z,EFECTO_DE_GIRO_A_LA_DERECHA
		
		cp		2														;si ha girado a la izquierda se irá a la secuencia de copy especial para ello
		jp		z,EFECTO_DE_GIRO_A_LA_IZQUIERDA
		
		jp		PINTAMOS_EL_RESULTADO_FINAL
		
EFECTO_DE_GIRO_A_LA_DERECHA:

		ld		iy,copia_parte_de_escenario_a_page_1_derecha			;copiamos en la page 1 el trozo izquierdo de page 0
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1_SOBRE_SI_MISMO		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_parte_de_escenario_a_page_0_derecha						;copiamos en la page 0 la mezcla de page 1
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1_INVERTIDAS
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		call	VDP_LISTO
		
		jp		PINTAMOS_EL_RESULTADO_FINAL

EFECTO_DE_GIRO_A_LA_IZQUIERDA:		
		
		ld		iy,copia_parte_de_escenario_a_page_1_izquierda			;copiamos en la page 1 el trozo derecho de page 0
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1_SOBRE_SI_MISMO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		iy,copia_parte_de_escenario_a_page_0_izquierda					;copiamos en la page 0 la mezcla de page 1
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1_INVERTIDAS
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	VDP_LISTO
					
PINTAMOS_EL_RESULTADO_FINAL:		
		
		xor		a
		ld		(giro_hacia),a
		
		ld		a,(set_page01)
		cp		0
		jp		z,.PALETA_A_UNO

.PALETA_A_CERO:

		xor		a
		ld		(set_page01),a
		ret

.PALETA_A_UNO:

		ld		a,1
		ld		(set_page01),a

		ret
			
PINTAMOS_LA_BASE_DEL_LABERINTO_EN_PAGE_1:
		
		ld		iy,copia_cuarta_fase_fondo_abierta	
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a
		CALL	RECTIFICACION_POR_PAGE_1
		jp		HL_DATOS_DEL_COPY_CALL_DOCOPY

TRASLADAMOS_SALIDA_C_F:

		LD		A,17
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_SALIDA_C_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
															
TRASLADAMOS_SALIDA_T_F:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_SALIDA_S_F:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_SALIDA_P_F:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_P_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_SALIDA_T_D:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_T_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_SALIDA_S_D:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_S_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_SALIDA_P_D:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_P_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_SALIDA_T_I:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_T_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_SALIDA_S_I:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_S_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_SALIDA_P_I:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_SALIDA_P_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_GRAFITI_C_F:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		a,(idioma)
		cp		1
		jp		z,.pagina_cambiadaingles
		
		ld		de,COPIAMOS_GRAFITI_C_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

.pagina_cambiadaingles:

		ld		de,COPIAMOS_GRAFITIE_C_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
																	
TRASLADAMOS_GRAFITI_T_F:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	

		ld		a,(idioma)
		cp		1
		jp		z,.pagina_cambiadaingles
				
		ld		de,COPIAMOS_GRAFITI_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

.pagina_cambiadaingles:

		ld		de,COPIAMOS_GRAFITIE_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_GRAFITI_S_F:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	

		ld		a,(idioma)
		cp		1
		jp		z,.pagina_cambiadaingles
						
		ld		de,COPIAMOS_GRAFITI_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

.pagina_cambiadaingles:

		ld		de,COPIAMOS_GRAFITIE_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_GRAFITI_P_F:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	

		ld		a,(idioma)
		cp		1
		jp		z,.pagina_cambiadaingles
				
		ld		de,COPIAMOS_GRAFITI_P_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

.pagina_cambiadaingles:

		ld		de,COPIAMOS_GRAFITIE_P_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_GRAFITI_T_D:

		LD		A,26
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_GRAFITI_T_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_GRAFITI_S_D:

		LD		A,26
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_GRAFITI_S_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_GRAFITI_P_D:

		LD		A,26
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_GRAFITI_P_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_GRAFITI_T_I:

		LD		A,26
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_GRAFITI_T_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_GRAFITI_S_I:

		LD		A,26
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_GRAFITI_S_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_GRAFITI_P_I:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
		
		ld		de,COPIAMOS_GRAFITI_P_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_LLAVE_T_F:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_S_F:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_P_F:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_P_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_T_D:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_T_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_S_D:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_S_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_P_D:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_P_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_T_I:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_T_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_S_I:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_S_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_LLAVE_P_I:

		LD		A,26
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_LLAVE_P_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000
																						
TRASLADAMOS_ESPEJO_C_F:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_C_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESPEJO_T_F:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESPEJO_S_F:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESPEJO_T_D:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_T_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESPEJO_S_D:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_S_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_ESPEJO_P_D:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_P_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESPEJO_T_I:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_T_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000

TRASLADAMOS_ESPEJO_S_I:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_S_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESPEJO_P_I:

		LD		A,25
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ESPEJO_P_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000
												
TRASLADAMOS_ENTRADA_C_F:

		LD		A,17
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_ENTRADA_C_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
															
TRASLADAMOS_ENTRADA_T_F:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ENTRADA_S_F:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ENTRADA_P_F:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_P_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ENTRADA_T_D:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_T_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ENTRADA_S_D:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_S_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ENTRADA_P_D:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_P_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ENTRADA_T_I:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_T_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_ENTRADA_S_I:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_S_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ENTRADA_P_I:

		LD		A,17
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_ENTRADA_P_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		call	EL_7000

TRASLADAMOS_POCHADA_C_F:

		LD		A,18
		call	EL_7000
		
.pagina_cambiada:	
	
		ld		de,COPIAMOS_POCHADA_C_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
															
TRASLADAMOS_POCHADA_T_F:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_POCHADA_S_F:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_POCHADA_P_F:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_P_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_POCHADA_T_D:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_T_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_POCHADA_S_D:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_S_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_POCHADA_P_D:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_P_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_POCHADA_T_I:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_T_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_POCHADA_S_I:

		LD		A,18
		call	EL_7000
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_S_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_POCHADA_P_I:

		LD		A,18
		call	EL_7000
		
.pagina_cambiada:	
		
		ld		de,COPIAMOS_POCHADA_P_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		call	EL_7000
				
TRASLADAMOS_ESCUDO_C_F:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_C_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000		

TRASLADAMOS_ESCUDO_T_F:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_T_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
						
TRASLADAMOS_ESCUDO_S_F:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_S_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESCUDO_P_F:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_P_F
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESCUDO_T_D:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_T_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESCUDO_S_D:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_S_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESCUDO_P_D:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_P_D
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESCUDO_T_I:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_T_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
		
TRASLADAMOS_ESCUDO_S_I:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_S_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	

TRASLADAMOS_ESCUDO_P_I:

		LD		A,14
		call	EL_7000
		
		ld		de,COPIAMOS_ESCUDO_P_I
		call	ESPERA_AL_VDP_HMMC

		LD		A,24
		jp		EL_7000	
																		
TRASLADAMOS_PATRONES_ESPEJO:

		ld		a,(patron_actual_cargado)
		cp		2
		ret		z
		
		ld		a,2
		ld		(patron_actual_cargado),a
		
		ld		hl,copia_espejo_en_vram

		LD		A,25
		call	EL_7000
				
		ld		de,COPIAMOS_LOS_ESPEJOS
		call	ESPERA_AL_VDP_HMMC
		LD		A,24
		jp		EL_7000	

TRASLADAMOS_PATRONES_LLAVES:

		RET
										
DIBUJAMOS_MAPA:
		
		ld		ix,mapa_del_laberinto									; le damos a ix el valor de la casilla en la que está el jugador
		ld		bc,(posicion_en_mapa)
		add		ix,bc	
		
		ld		a,(ix)													; con ese valor, decidimos qué patrón de laberinto pintaremos (valor 1)
		
		push	af
		
		ld		a,(turno)
		cp		2
		jp		z,.jugador_2
		
.jugador_1:
		
		ld		ix,act_mapa_1
		jp		.comun

.jugador_2:

		ld		ix,act_mapa_2
		
.comun:
				
		add		ix,bc
		
		pop		af
		
		ld		(ix),a
		
		ld		iy,eventos_laberinto									
		ld		bc,(posicion_en_mapa)
		add		iy,bc		
		ld		a,(iy)					
		cp		17
		jp		z,MARCAMOS_SALIDA
		cp		16
		jp		z,MARCAMOS_ENTRADA
		cp		14
		jp		z,MARCAMOS_POCHADERO
		cp		30
		jp		z,MARCAMOS_POCHADERO
		cp		31
		jp		z,MARCAMOS_POCHADERO
		cp		32
		jp		z,MARCAMOS_POCHADERO
		cp		15
		jp		z,MARCAMOS_LLAVE	
					
		ld		a,(lupa)
		cp		0
		ret		z
		
		ld		a,(iy)					

		cp		19
		jp		z,MARCAMOS_AGUJERO_NEGRO
		cp		20
		jp		z,MARCAMOS_TRAMPA
		cp		21
		jp		z,MARCAMOS_HATER
		cp		21
		jp		z,MARCAMOS_HATER
		cp		22
		jp		z,MARCAMOS_HATER
		cp		23
		jp		z,MARCAMOS_HATER
		cp		24
		jp		z,MARCAMOS_HATER
		cp		25
		jp		z,MARCAMOS_HATER
		cp		26
		jp		z,MARCAMOS_HATER
		cp		27
		jp		z,MARCAMOS_HATER						

		ret

FIN_DE_SUMAS_DE_EVENTOS:

		ld		b,a
		ld		a,(ix)
		add		b
		ld		(ix),a	
		ret
		
MARCAMOS_SALIDA:														; 15-29	

		ld		a,15
		jp		FIN_DE_SUMAS_DE_EVENTOS

MARCAMOS_ENTRADA:														; 30-44	

		ld		a,30
		jp		FIN_DE_SUMAS_DE_EVENTOS


MARCAMOS_TRAMPA:														; 45-59	

		ld		a,45
		jp		FIN_DE_SUMAS_DE_EVENTOS

		
MARCAMOS_POCHADERO:														; 60-74	

		ld		a,60
		jp		FIN_DE_SUMAS_DE_EVENTOS

		
MARCAMOS_HATER:															; 75-89	

		ld		a,75
		jp		FIN_DE_SUMAS_DE_EVENTOS


MARCAMOS_AGUJERO_NEGRO:													; 90-104	

		ld		a,90
		jp		FIN_DE_SUMAS_DE_EVENTOS


MARCAMOS_LLAVE:														; 105-119	

		ld		a,105
		jp		FIN_DE_SUMAS_DE_EVENTOS

														
MIRAMOS_PARADA:

		xor		a
		call	GTSTCK
		cp		1
		jp		z,.quiere_activar_lupa
		cp		5
		jp		z,.quiere_activar_trampa

		ld		a,(turno)
		call	GTSTCK
		cp		1
		jp		z,.quiere_activar_lupa
		cp		5
		jp		z,.quiere_activar_trampa
		pop		af														; sacamos un valor para que se vaya al call adecuado
		
		JP		MOVIMIENTO_DEL_JUGADOR				

.quiere_activar_lupa:
		
		ld		a,(lupa)
		or		a
		jp		nz,.LUPA
		
		RET		
		
.quiere_activar_trampa:

		ld		a,(trampa)
		or		a
		call	nz,.TRAMPA
		
		ret	
			
.LUPA:
								
		xor		a
		ld		(desplazamiento_real),a
		
		ld		a,(pagina_de_idioma)
		call	EL_7000

		ld		hl,TERMINA_TURNO_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO

		call	TEXTO_A_ESCRIBIR
		call	STRIG_DE_CONTINUE
		pop		af														; sacamos un valor para que se vaya al call adecuado
		jp		FIN_DE_TURNO

.TRAMPA:

		ld		a,(pagina_de_idioma)
		call	EL_7000
		ld		ix,eventos_laberinto									;ponemos en ix el valor de evento que hay en la casilla que está el jugador
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		ld		a,(ix)
		cp		15
		jp		z,.NO_PUEDES_PONER_TRAMPA
		cp		16
		jp		z,.NO_PUEDES_PONER_TRAMPA
		cp		17		
		jp		z,.NO_PUEDES_PONER_TRAMPA
		ld		a,20
		ld		(ix),a
		
		ld		a,(trampa)
		dec		a
		ld		(trampa),a

		ld		a,(trampa)
		cp		0
		jp		z,.NINGUNO
		cp		1
		jp		nz,.VARIAS

.UNA:
	
		ld		iy,copia_trampa_en_objetos								; PINTA OBJETO ENTRE LOS OBJETOS
		jp		.SEGUIMOS_DIBUJANDO

.NINGUNO:

		ld		iy,copia_trampa_en_objetos								; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a	
		jp		.QUE_JUGADOR_ES
		
.VARIAS:

		ld		iy,copia_trampas_en_objetos								; PINTA OBJETO ENTRE LOS OBJETOS

.SEGUIMOS_DIBUJANDO:

		CALL	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

.QUE_JUGADOR_ES:

		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

.COORDENADAS_JUGADOR_DOS:

		ld		a,#d3
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_trampa_en_objetos_1								; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_trampa_en_objetos_2								; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
		ld		a,(pagina_de_idioma)
		call	EL_7000
		ld		hl,TRAMPA_SI_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TRAMPA_SI_2_ESP
		CALL	TEXTO_A_ESCRIBIR		
		jp		STRIG_DE_CONTINUE
		
.NO_PUEDES_PONER_TRAMPA:

		ld		a,(pagina_de_idioma)
		call	EL_7000
		ld		hl,TRAMPA_NO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TRAMPA_NO_2_ESP
		jp		TEXTO_A_ESCRIBIR	
						
MIRAMOS_EL_PAPIRO:

		ld		a,16
		call	EL_7000

		
		ld		a,10
		ld		c,1
		call	ayFX_INIT

		ld		a,(papel)
		or		a
		jp		nz,PUEDE_VERLO

		ld		a,(pagina_de_idioma)
		call	EL_7000

		ld		hl,NO_TIENES_PAPEL_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO

		jp		TEXTO_A_ESCRIBIR
		
PUEDE_VERLO:

		ld		a,(tinta)												; si no tiene también la pluma y el tintero no mostrará el puntero
		cp		0
		jp		z,NO_PUEDE_ESCRIBIR
		
		ld		a,(pluma)
		cp		0
		jp		nz,LO_VEMOS

NO_PUEDE_ESCRIBIR:

		ld		a,(pagina_de_idioma)
		call	EL_7000

		ld		hl,NO_PUEDE_ESCRIBIR_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO

		call	TEXTO_A_ESCRIBIR
		
LO_VEMOS:

		call	DISSCR
		ld		a,(set_page01)
		cp		1
		jp		z,.SOLO_LO_NECESARIO

		ld		iy,copia_escenario_a_page_1_3							; Si estamos en page 0. Vamos a clonar la 0 en la 1 pero completa
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO
		
		jp		.CONTINUAMOS

.SOLO_LO_NECESARIO:

		ld		iy,copia_escenario_a_page_1_4							; Si estamos en page 0. Vamos a clonar la 0 en la 1 pero completa
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO	
	
.CONTINUAMOS:

		ld		iy,cuadrado_que_limpia_una_linea							; Si estamos en page 0. Vamos a clonar la 0 en la 1 pero completa
		CALL	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO
				
		xor		a
		ld		(set_page01),a
		ld		(patron_actual_cargado),a
							
		ld		a,22
		call	EL_7000
		
		jp		MIRAMOS_EL_PAPIRO_SECUENCIA

EFECTO:
		
		ld		b,a
		
		ld		a,16
		call	EL_7000

		
		ld		a,b
		ld		c,1
		call	ayFX_INIT

		ld		a,(pagina_de_idioma)
		JP		EL_7000
		
EFECTO_MAPA:

		ld		a,16
		call	EL_7000
		
		ld		a,10
		ld		c,1
		call	ayFX_INIT

		ld		a,22
		call	EL_7000
		
		ret
										
ENCUENTRA_BRUJULA_2:					
		
		ld		a,20
		ld		(mosca_x_objetivo),a

ENCUENTRA_BRUJULA_2_5:
		
		pop		af														;sacamos un valor de la pila para compensar un call

		ld		a,16
		call	EL_7000

		
		ld		a,9
		ld		c,0
		call	ayFX_INIT
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY							; pasamos el dibujo a pantalla

		ld		a,(pagina_de_idioma)
		call	EL_7000
				
		ret
		
SONIDO_VIEJIGUIA:

		ld		a,16
		call	EL_7000

		
		ld		a,14
		ld		c,0
		call	ayFX_INIT

		ld		a,(pagina_de_idioma)
		jp		EL_7000
				
VAMOS_A_DECIDIR_QUE_PASA_AL_SALIR:

		di
		call	stpmus
		ei
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,LO_CONSIGUE_UN_JUGADOR

LO_CONSIGUE_DOS_JUGADORES:
		
		ld		a,(personaje)
		dec		a
		ld		(pagina_hater),a
		or		a
		jp		z,.natpu
		cp		1
		jp		z,.fergar
		cp		2
		jp		z,.crira
		cp		3
		jp		z,.vicmar
		
.natpu:

		ld		a,52
		call	EL_7000
		ld		de,VICTORIA_N
		jp		.comun
		
.fergar:

		ld		a,49
		call	EL_7000
		ld		de,VICTORIA_F
		jp		.comun
		
.crira:

		ld		a,50
		call	EL_7000
		ld		de,VICTORIA_C
		jp		.comun
		
.vicmar:

		ld		a,51
		call	EL_7000
		ld		de,VICTORIA_V

.comun:
				
		ld		a,(set_page01)
		or		a
		jp		z,.a_page_1

.a_page_0:
		
		ld		hl,copia_victoria								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		xor		a
		ld		(set_page01),a
		jp		.sigue
		
.a_page_1:

		ld		hl,copia_victoria1								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		ld		a,1
		ld		(set_page01),a
		
.sigue:

		ld		a,5
		ld		(que_musica_0),a
		
		ld		a,4
        call	EL_7000
		
		di
		call	strmus
		ei
					
		ld		a,(pagina_de_idioma)
		call	EL_7000

		ld		ix,HAS_GANADO_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		ld		ix,HAS_GANADO_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE
		
		ld		ix,HAS_GANADO_3_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		ld		ix,HAS_GANADO_4_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE
														
		jp		REINICIANDO_EL_JUEGO
																									
LO_CONSIGUE_UN_JUGADOR:

		ld		a,#ff
		ld		(act_mapa_1),a

		ld		de,act_mapa_1_1
		ld		hl,act_mapa_1
		ld		bc,899																		
		ldir

		ld		de,act_mapa_2
		ld		hl,act_mapa_1
		ld		bc,900													
		ldir
				
		call	ENEMIGO_FINAL
		
		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		ld		hl,PASA_MAZMORRA_ESP
		call	TEXTO_A_ESCRIBIR

		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR

		ld		a,4
		ld		(que_musica_0),a
		
		ld		a,2
        call	EL_7000
		
		di
		call	strmus
		ei
		
		ld		a,(pagina_de_idioma)
		call	EL_7000		
		
		call	STRIG_DE_CONTINUE
		
		di
		call	stpmus
		ei
		
		xor		a
		ld		(que_musica_0),a
		
SUBIMOS_DE_NIVEL:

		ld		a,(nivel)
		inc		a
		ld		(nivel),a
		cp		5
		jp		z,FINAL_DEL_JUEGO

		ld		a,0
		ld		(posicion_en_mapa),a

				
		ld		iy,cuadrado_que_limpia_10								; BORRA OBJETOS DE PANTALLA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a				
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos								; BORRA DIBUJO GALLILNA
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		

		ld		iy,cuadrado_que_limpia_11								; BORRA LABERINTOS DE PAGE 2
		call	COPY_A_GUSTO
				
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
	
								
		di
		LD		a,4		
		ld		(en_que_pagina_el_page_2),a					
		ld		[#7000],a												;banco 2, pagina 4 del MEGAROM
		ei

		ld		de,valor_conserv_bitn_vid								;salvamos valores que luego se borrarán
		ld		hl,bitneda_unidades
		ld		bc,8
		ldir		

		xor		a
		ld		(brujula),a
		ld		(brujula1),a

		ld		de,papel
		ld		hl,brujula
		ld		bc,26																		
		ldir

		ld		de,papel1
		ld		hl,brujula1
		ld		bc,26																		
		ldir

		di
		LD		a,53		
		ld		(en_que_pagina_el_page_2),a					
		ld		[#7000],a												;banco 2, pagina 4 del MEGAROM
		ei
        
		call	CARGAMOS_OBJETOS_DE_LA_TIENDA

		di
		LD		a,4		
		ld		(en_que_pagina_el_page_2),a					
		ld		[#7000],a												;banco 2, pagina 4 del MEGAROM
		ei
				
		ld		hl,valor_conserv_bitn_vid								; recuperamos los valores
		ld		de,bitneda_unidades
		ld		bc,8
		ldir	

		ld		hl,valor_conserv_bitn_vid								; recuperamos los valores
		ld		de,bitneda_unidades1
		ld		bc,8
		ldir	
								
		ld		a,(nivel)

		cp		2
		jp		z,A_NIVEL_2
		cp		3
		jp		z,A_NIVEL_3
		cp		4
		jp		z,A_NIVEL_4
		
A_NIVEL_2:

		jp		NIVEL_2_EN_PAGE_4
		
A_NIVEL_3:

		jp		NIVEL_3_EN_PAGE_4

A_NIVEL_4:

		jp		NIVEL_4_EN_PAGE_4


		
ENEMIGO_FINAL:

		ld		a,5
		call	EL_7000
		jp		EL_6000_PARA_37_ENEMIGO_FINAL
						
EL_7000:

		di
		
		ld		(en_que_pagina_el_page_2),a					
		ei		
		ld		[#7000],a	
				
		ret
		
PINTAMOS_PROTA_MUERTO:
		
		LD		A,23													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000
		
		ld		de,COPIAMOS_PROTA_MUERTO

		ld		a,(set_page01)
		or		a
		jp		z,.muerto_en_1

.muerto_en_0:

		ld		hl,copia_prota_muerto_en_pantalla						;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		xor		a
		ld		(set_page01),a
		jp		.final
		
.muerto_en_1:
				
		ld		hl,copia_prota_muerto_en_pantalla_1						;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		ld		a,1
		ld		(set_page01),a
		
.final:
		
		LD		A,(pagina_de_idioma)													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		jp		EL_7000
		
PINTANDO_EL_HATER:
		
		ld		a,r														; Creamos un valor aleatorio entre 4 para escoger hater
		and		00000011b		
		ld		(pagina_hater),a
						
		cp		0
		jp		z,CARGAMOS_HATER_1
		cp		1
		jp		z,CARGAMOS_HATER_2
		cp		2
		jp		z,CARGAMOS_HATER_3
		cp		3
		jp		z,CARGAMOS_HATER_4

CARGAMOS_HATER_1:
								
		LD		A,21													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ld		de,COPIAMOS_HATER1
		ld		hl,copia_hater_en_pantalla								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		LD		A,(pagina_de_idioma)													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ret

CARGAMOS_HATER_2:
								
		LD		A,21													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ld		de,COPIAMOS_HATER2
		ld		hl,copia_hater_en_pantalla								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		LD		A,(pagina_de_idioma)													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ret

CARGAMOS_HATER_3:
								
		LD		A,33													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ld		de,COPIAMOS_HATER3
		ld		hl,copia_hater_en_pantalla								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		LD		A,(pagina_de_idioma)													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ret

CARGAMOS_HATER_4:
								
		LD		A,33													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ld		de,COPIAMOS_HATER4
		ld		hl,copia_hater_en_pantalla								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		LD		A,(pagina_de_idioma)													; CAMBIAMOS A LA PALETA DONDE ESTÁ EL HATER PARA PINTARLO
		call	EL_7000

		ret
						
HATER_CARA_ENFADADO:

		call	DEFINE_DIRECTRICES_DE_CARA_HATER

		call	HATER_CARA_COMUN_1
		
		ld		de,HATER_1_ENFADADO

		jp		HATER_CARA_COMUN_2

HATER_CARA_TRISTE:

		call	DEFINE_DIRECTRICES_DE_CARA_HATER

		call	HATER_CARA_COMUN_1
		
		ld		de,HATER_1_TRISTE

		jp		HATER_CARA_COMUN_2

HATER_CARA_MUERTO:

		call	DEFINE_DIRECTRICES_DE_CARA_HATER

		call	HATER_CARA_COMUN_1
		
		ld		de,HATER_1_MUERTO
		
		jp		HATER_CARA_COMUN_2
						
HATER_CARA_FELIZ:

		call	DEFINE_DIRECTRICES_DE_CARA_HATER

		call	HATER_CARA_COMUN_1
		
		ld		de,HATER_1_FELIZ

HATER_CARA_COMUN_2:	

		push	ix
		pop		hl														;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		ld		a,(pagina_de_idioma)
		call	EL_7000
		
		RET
		
HATER_CARA_COMUN_1:	

		ld		a,29
		ld		b,a
		ld		a,(pagina_hater)										; Pintamos al hater contento		
		add		b
		call	EL_7000		
		ret

CARGA_VIEJI1:
			
		LD		A,27
		call	EL_7000	
		
		ld		a,(set_page01)
		cp		0
		jp		z,.a_la_page1

.a_la_page0:
		
		ld		de,VIEJI1
		
.comun_de_viejis_en_0:
		
		ld		hl,copia_viejiguia_1
		call	ESPERA_AL_VDP_HMMC
		
		xor		a
		jp		.final

.a_la_page1:
		
		ld		de,VIEJI1
		
.comun_de_viejis_en_1:		

		ld		hl,copia_viejiguia_12
		call	ESPERA_AL_VDP_HMMC
		
		ld		a,1
.final:

		ld		(set_page01),a
		
		LD		A,(pagina_de_idioma)
		jp		EL_7000	

CARGA_VIEJI2:
			
		LD		A,27
		call	EL_7000	
		
		ld		a,(set_page01)
		cp		0
		jp		z,.a_la_page1

.a_la_page0:
		
		ld		de,VIEJI2
		jp		CARGA_VIEJI1.comun_de_viejis_en_0

.a_la_page1:
		
		ld		de,VIEJI2
		jp		CARGA_VIEJI1.comun_de_viejis_en_1
		
CARGA_VIEJI3:
			
		LD		A,38
		call	EL_7000	
		
		ld		a,(set_page01)
		cp		0
		jp		z,.a_la_page1

.a_la_page0:
		
		ld		de,VIEJI3
		jp		CARGA_VIEJI1.comun_de_viejis_en_0


.a_la_page1:
		
		ld		de,VIEJI3
		jp		CARGA_VIEJI1.comun_de_viejis_en_1
		
CARGA_VIEJI4:
			
		LD		A,38
		call	EL_7000	
		
		ld		a,(set_page01)
		cp		0
		jp		z,.a_la_page1

.a_la_page0:
		
		ld		de,VIEJI4
		jp		CARGA_VIEJI1.comun_de_viejis_en_0

.a_la_page1:
		
		ld		de,VIEJI4
		jp		CARGA_VIEJI1.comun_de_viejis_en_1

ACTIVA_MUSICA_HATER:

		call	stpmus
		ld		a,2
		ld		(que_musica_0),a
				
		LD		A,22		
		call	EL_7000
				
		di
		call	strmus													;iniciamos la música de tienda
		ei
		
		ld		a,(pagina_de_idioma)
		jp		EL_7000

ACTIVA_MUSICA_HATER_CONVERSACION:

		call	stpmus
		ld		a,8
		ld		(que_musica_0),a
				
		LD		A,81		
		call	EL_7000
				
		di
		call	strmus													;iniciamos la música de tienda
		ei
		
		ld		a,(pagina_de_idioma)
		jp		EL_7000
		
ACTIVA_MUSICA_JUEGO:

		xor		a
		ld		(que_musica_0),a

		LD		A,16		
		call	EL_7000

		DI
		call	strmus													;iniciamos la música de tienda
		EI
				
		ld		a,(pagina_de_idioma)
		jp		EL_7000

ESPERA_PARA_VOLVER_SIN_OBJETOS:

		ld		a,(pagina_de_idioma)
		call	EL_7000
		ld		hl,NO_PUEDE_ESCRIBIR_ESP
		call	TEXTO_A_ESCRIBIR
		ld		a,22
		call	EL_7000
		jp		ESPERA_PARA_VOLVER

MUSICA_HAS_MUERTO:

		LD		A,53		
		call	EL_7000
		
		di
		call	strmus													;iniciamos la música de tienda
		ei

		LD		A,(pagina_de_idioma)	
		jp		EL_7000
				
										
cuadrado_que_limpia_4:							dw		#0000,#0000,#0038,#00B8,#000F,#0010				
cuadrado_que_limpia_5:							dw		#0000,#0000,#0036,#000a,#0094,#006c	; Limpia la pantalla del laberinto en 0
cuadrado_que_limpia_5_1:						dw		#0000,#0000,#0036,#010a,#0094,#006c	; Limpia la pantalla del laberinto en 1	
copia_punto_cardinal:							dw		#0000,#0282,#007c,#00B2,#000C,#0009
cuadrado_que_limpia_6:							dw		#0000,#0000,#007c,#00B2,#000C,#0009
copia_saltito_al_avanzar:						dw		#0036,#0010,#0036,#000C,#0094,#0066	
cuadrado_que_limpia_7:							dw		#0000,#0000,#0036,#0072,#0094,#0004	; Es elcuadradito debajo del dibujo en el saltito
cuadrado_que_limpia_10:							dw		#0000,#0000,#0036,#0080,#004B,#001a ; BORRA ZONA DE OBJETOS PARCIAL
cuadrado_que_limpia_11:							dw		#0000,#0000,#004C,#029C,#00B4,#0064	; borra los mapas de laberinto de los dos jugadores
cuadrado_que_limpia_final_hater:				dw		#0000,#0000,#005c,#001f,#0008,#001a
cuadrado_que_limpia_result_at_def:				dw		#0000,#0000,#0006,#001f,#0008,#001a
cuadrado_que_limpia_final_at_def:				dw		#0000,#0000,#0024,#001f,#0008,#001a
cuadrado_que_limpia_dados_hater:				dw		#0000,#0000,#0036,#0019,#000f,#0024
copia_dado:										dw		#0000,#0272,#0000,#00B8,#0010,#000F		

copia_cuarta_fase_derecha_abierta:				dw		#0056,#02FE,#008A,#0008,#0005,#006e
copia_cuarta_fase_derecha_cerrada:				dw		#0056,#01FE,#008A,#0008,#0005,#006e
copia_cuarta_fase_izquierda_abierta:			dw		#003C,#02FE,#0072,#0008,#0004,#006e
copia_cuarta_fase_izquierda_cerrada:			dw		#003C,#01FE,#0072,#0008,#0004,#006e

copia_cuarta_fase_fondo_cerrada:				dw		#0040,#01FE,#0076,#0008,#0014,#006e
copia_cuarta_fase_fondo_abierta:				dw		#0040,#02FE,#0076,#0008,#0014,#006e

copia_tercera_fase_derecha_abierta:				dw		#005c,#02FE,#008E,#0008,#000A,#006e
copia_tercera_fase_derecha_cerrada:				dw		#005a,#01FE,#008E,#0008,#000A,#006e
copia_tercera_fase_izquierda_abierta:			dw		#0030,#02FE,#0066,#0008,#000c,#006e
copia_tercera_fase_izquierda_cerrada:			dw		#0030,#01FE,#0066,#0008,#000c,#006e

copia_tercera_fase_fondo_cerrada:				dw		#00C6,#0248,#0068,#0036,#0028,#001A

copia_segunda_fase_derecha_abierta:				dw		#0066,#02FE,#0098,#0008,#0014,#006e
copia_segunda_fase_derecha_cerrada:				dw		#0064,#01FE,#0098,#0008,#0014,#006e
copia_segunda_fase_izquierda_abierta:			dw		#001c,#02FE,#0052,#0008,#0016,#006e
copia_segunda_fase_izquierda_cerrada:			dw		#001c,#01FE,#0052,#0008,#0016,#006e

copia_segunda_fase_fondo_cerrada:				dw		#0098,#0248,#0066,#002E,#0034,#0028

copia_primera_fase_derecha_abierta:				dw		#007A,#02FE,#00AC,#0008,#001e,#006e
copia_primera_fase_derecha_cerrada:				dw		#0078,#01FE,#00AC,#0008,#001E,#006e
copia_primera_fase_izquierda_abierta:			dw		#0000,#02FE,#0036,#0008,#001E,#006e
copia_primera_fase_izquierda_cerrada:			dw		#0000,#01FE,#0036,#0008,#001E,#006e

copia_primera_fase_fondo_cerrada:				dw		#0098,#0200,#0052,#0020,#005C,#0047	

copia_escenario_a_page_0:						dw		#0036,#010C,#0036,#000C,#0094,#006A

copia_parte_de_escenario_a_page_1_derecha:		dw		#0094,#000a,#0036,#000a,#0036,#006e
copia_parte_de_escenario_a_page_1_izquierda:	dw		#0036,#000a,#0094,#000a,#0036,#006e
copia_parte_de_escenario_a_page_0_derecha:		dw		#0036,#010A,#006b,#000A,#005e,#006A
copia_parte_de_escenario_a_page_0_izquierda:	dw		#006b,#010A,#0036,#000A,#005e,#006A
											
copia_cuarta_fase_fondo_decorado_grafitie:		dw		#0078,#003B,#0014,#000e
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_grafitie:		dw		#0073,#0038,#001e,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_grafitie:		dw		#0068,#0032,#0030,#0020
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_grafitie:		dw		#0055,#0027,#0054,#0038
												db		#00,#00,#F0

copia_cuarta_fase_fondo_decorado_grafitie1:		dw		#0078,#013B,#0014,#000e
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_grafitie1:	dw		#0073,#0138,#001e,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_grafitie1:	dw		#0068,#0132,#0030,#0020
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_grafitie1:	dw		#0055,#0127,#0054,#0038
												db		#00,#00,#F0
																																				
copia_cuarta_fase_fondo_decorado_llaves:		dw		#0000,#019F,#007A,#003E,#000E,#0009
copia_tercera_fase_fondo_decorado_llaves:		dw		#002E,#018F,#007A,#003C,#0015,#000D
copia_segunda_fase_fondo_decorado_llaves:		dw		#002E,#017A,#0072,#0038,#001F,#0015
copia_primera_fase_fondo_decorado_llaves:		dw		#0000,#017A,#0067,#0031,#002E,#0024

copia_tercera_fase_derecha_decorado_llaves:		dw		#002D,#019E,#0095,#0037,#0006,#0012
copia_segunda_fase_derecha_decorado_llaves:		dw		#001A,#019E,#009f,#002E,#000D,#0020
copia_primera_fase_derecha_decorado_llaves:		dw		#0062,#017A,#00b5,#0022,#0015,#0035

copia_reflejo_prota_1:							dw		#0071,#017c,#0077,#0038,#0011,#0024
copia_reflejo_prota_2:							dw		#0072,#01a0,#0078,#0038,#0011,#0024
copia_reflejo_prota_3:							dw		#0082,#017c,#0077,#0038,#0011,#0024
copia_reflejo_prota_4:							dw		#0083,#01a0,#0078,#0038,#0011,#0024
copia_reflejo_casco:							dw		#0071,#01c4,#0077,#0037,#0012,#0011
copia_reflejo_armadura:							dw		#0084,#01c5,#0079,#0044,#0014,#0012
copia_reflejo_cuchillo:							dw		#0025,#01cc,#007c,#0046,#0009,#0008
copia_reflejo_espada:							dw		#0092,#017a,#0078,#0040,#0011,#000e
																					
copia_viejiguia_1:								dw		#0036,#000C,#0094,#006A
												db		#00,#00,#f0

copia_viejiguia_12:								dw		#0037,#010C,#0094,#006A
												db		#00,#00,#f0
																																		
copia_patron_mapa_standar:						dw		#0000,#0298,#0000,#0000,#0004,#0004
copia_puntero_del_mapa:							dw		#008A,#026D,#0000,#0000,#0001,#0001

copia_hater_0:									dw		#0000,#0290,#004F,#001f,#0008,#0008
copia_hater_1:									dw		#0008,#0290,#004F,#001f,#0008,#0008
copia_hater_2:									dw		#0010,#0290,#004F,#001f,#0008,#0008
copia_hater_3:									dw		#0018,#0290,#004F,#001f,#0008,#0008
copia_hater_4:									dw		#0020,#0290,#004F,#001f,#0008,#0008

copia_piedra_1:									dw		#00c8,#01dc,#0061,#0069,#000a,#0007
copia_piedra_2:									dw		#00d2,#01dc,#006f,#0056,#0006,#0005
copia_piedra_3:									dw		#00d8,#01dc,#007c,#004c,#0003,#0004
copia_rama_1:									dw		#00c9,#01e3,#0095,#006d,#0014,#000a
copia_rama_2:									dw		#00dd,#01e9,#008c,#005c,#0008,#0005
copia_rama_3:									dw		#00dc,#01dc,#0087,#004c,#0006,#0004

copia_escenario_a_page_1_2:						dw		#0036,#000C,#0036,#010C,#0094,#006A
copia_escenario_a_page_1_3:						dw		#0000,#0000,#0000,#0100,#0100,#00d3
copia_escenario_a_page_1_4:						dw		#0000,#0076,#0000,#0176,#0100,#005D
copia_escenario_a_page_1_5:						dw		#0000,#0100,#0000,#0000,#0100,#00d3
cuadrado_que_limpia_una_linea:					dw		#0000,#0000,#0000,#00d2,#0100,#0002

copia_prota_1_en_vram:							dw		#0000,#0374,#00ac,#002a
												db		#00,#00,#F0
copia_prota_2_en_vram:							dw		#0000,#039e,#00ac,#002a
												db		#00,#00,#F0	
												
copia_escudo_en_vram:							dw		#0000,#017A,#0084,#0030
												db		#00,#00,#F0
copia_espejo_en_vram:							dw		#0000,#017A,#00a4,#005d
												db		#00,#00,#F0	
copia_llaves_en_vram:							dw		#0000,#017A,#0078,#0044
												db		#00,#00,#F0													
copia_grafiti_en_vram:							dw		#0000,#017A,#00e2,#0061
												db		#00,#00,#F0																								
copia_puerta_en_vram:							dw		#0000,#017A,#0082,#005D
												db		#00,#00,#F0
copia_sombra_en_vram_0:							dw		#005C,#0035,#004B,#0041
												db		#00,#00,#Bb
copia_sombra_en_vram_1:							dw		#005C,#0135,#004B,#0041
												db		#00,#00,#Bb												
copia_pergamino_en_pantalla_1:					dw		#0000,#0000,#0100,#007E
												db		#00,#00,#F0
copia_pergamino_en_pantalla_2:					dw		#0000,#007E,#0100,#0055
												db		#00,#00,#F0	
copia_pergamino_ingles:							dw		#000C,#0016,#0022,#0029
												db		#00,#00,#F0																							
copia_hater_en_pantalla:						dw		#0036,#000A,#0094,#006D
												db		#00,#00,#F0											
copia_hater_cara:								dw		#0070,#001F,#0032,#003D
												db		#00,#00,#F0
												dw		#006F,#0015,#0032,#003D
												db		#00,#00,#F0
												dw		#006E,#001E,#0032,#003D
												db		#00,#00,#F0
												dw		#0068,#000C,#0032,#003D
												db		#00,#00,#F0
copia_prota_muerto_en_pantalla:					dw		#0036,#000C,#0094,#006A
												db		#00,#00,#f0																																																										
copia_prota_muerto_en_pantalla_1:				dw		#0036,#010C,#0094,#006A
												db		#00,#00,#f0	
																																				
POINT_DE_AVANCE:			dw	AVANCE_NORTE
							dw	AVANCE_ESTE
							dw	AVANCE_SUR
							dw	AVANCE_OESTE

POINT_AVANCE_NORTE:			dw	AVANCE_NORTE_DOS	;0
							dw	AVANCE_NORTE_DOS	;1
							dw	FIN_DE_TURNO_PREV	;2
							dw	FIN_DE_TURNO_PREV	;3
							dw	AVANCE_NORTE_DOS	;4
							dw	AVANCE_NORTE_DOS	;5
							dw	FIN_DE_TURNO_PREV	;6
							dw	FIN_DE_TURNO_PREV	;7
							dw	AVANCE_NORTE_DOS	;8
							dw	AVANCE_NORTE_DOS	;9
							dw	FIN_DE_TURNO_PREV	;10
							dw	FIN_DE_TURNO_PREV	;11
							dw	AVANCE_NORTE_DOS	;12
							dw	AVANCE_NORTE_DOS	;13
							dw	FIN_DE_TURNO_PREV	;14

POINT_AVANCE_ESTE:			dw	AVANCE_ESTE_DOS		;0
							dw	FIN_DE_TURNO_PREV	;1
							dw	AVANCE_ESTE_DOS		;2
							dw	FIN_DE_TURNO_PREV	;3
							dw	AVANCE_ESTE_DOS		;4
							dw	FIN_DE_TURNO_PREV	;5
							dw	AVANCE_ESTE_DOS		;6
							dw	FIN_DE_TURNO_PREV	;7
							dw	AVANCE_ESTE_DOS		;8
							dw	FIN_DE_TURNO_PREV	;9
							dw	AVANCE_ESTE_DOS		;10
							dw	FIN_DE_TURNO_PREV	;11
							dw	AVANCE_ESTE_DOS		;12
							dw	FIN_DE_TURNO_PREV	;13
							dw	AVANCE_ESTE_DOS		;14

POINT_AVANCE_SUR:			dw	AVANCE_SUR_DOS		;0
							dw	AVANCE_SUR_DOS		;1
							dw	AVANCE_SUR_DOS		;2
							dw	AVANCE_SUR_DOS		;3
							dw	AVANCE_SUR_DOS		;4
							dw	AVANCE_SUR_DOS		;5
							dw	AVANCE_SUR_DOS		;6
							dw	AVANCE_SUR_DOS		;7
							dw	FIN_DE_TURNO_PREV	;8
							dw	FIN_DE_TURNO_PREV	;9
							dw	FIN_DE_TURNO_PREV	;10
							dw	FIN_DE_TURNO_PREV	;11
							dw	FIN_DE_TURNO_PREV	;12
							dw	FIN_DE_TURNO_PREV	;13
							dw	FIN_DE_TURNO_PREV	;14

POINT_AVANCE_OESTE:			dw	AVANCE_OESTE_DOS	;0
							dw	AVANCE_OESTE_DOS	;1
							dw	AVANCE_OESTE_DOS	;2
							dw	AVANCE_OESTE_DOS	;3
							dw	FIN_DE_TURNO_PREV	;4
							dw	FIN_DE_TURNO_PREV	;5
							dw	FIN_DE_TURNO_PREV	;6
							dw	FIN_DE_TURNO_PREV	;7
							dw	AVANCE_OESTE_DOS	;8
							dw	AVANCE_OESTE_DOS	;9
							dw	AVANCE_OESTE_DOS	;10
							dw	AVANCE_OESTE_DOS	;11
							dw	FIN_DE_TURNO_PREV		;12
							dw	FIN_DE_TURNO_PREV		;13
							dw	FIN_DE_TURNO_PREV		;14

POINT_DADO:					dw	DATOS_1
							dw	DATOS_1
							dw	DATOS_2
							dw	DATOS_3
							dw	DATOS_4
							dw	DATOS_5
							dw	DATOS_6
							dw	DATOS_6	

POINT_PC_FASE_4:			dw	CUARTA_FASE_NORTE
							dw	CUARTA_FASE_ESTE
							dw	CUARTA_FASE_SUR
							dw	CUARTA_FASE_OESTE
					
POINT_PC_FASE_3:			dw	TERCERA_FASE_NORTE
							dw	TERCERA_FASE_ESTE
							dw	TERCERA_FASE_SUR
							dw	TERCERA_FASE_OESTE
					
POINT_PC_FASE_2:			dw	SEGUNDA_FASE_NORTE
							dw	SEGUNDA_FASE_ESTE
							dw	SEGUNDA_FASE_SUR
							dw	SEGUNDA_FASE_OESTE
					
POINT_PC_FASE_1:			dw	PRIMERA_FASE_NORTE
							dw	PRIMERA_FASE_ESTE
							dw	PRIMERA_FASE_SUR
							dw	PRIMERA_FASE_OESTE

POINT_CUARTA_FASE_NORTE:	dw	CUARTA_FASE_0
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_3
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_5
							dw	CUARTA_FASE_6
							dw	CUARTA_FASE_7
							dw	CUARTA_FASE_0
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_3
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_5
							dw	CUARTA_FASE_6
							
POINT_TERCERA_FASE_NORTE:	dw	TERCERA_FASE_0
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_3
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_5
							dw	TERCERA_FASE_6
							dw	TERCERA_FASE_7
							dw	TERCERA_FASE_0
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_3
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_5
							dw	TERCERA_FASE_6
							
POINT_SEGUNDA_FASE_NORTE:	dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_3
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_5
							dw	SEGUNDA_FASE_6
							dw	SEGUNDA_FASE_7
							dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_3
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_5
							dw	SEGUNDA_FASE_6
							
POINT_PRIMERA_FASE_NORTE:	dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_3
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_5
							dw	PRIMERA_FASE_6
							dw	PRIMERA_FASE_7
							dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_3
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_5
							dw	PRIMERA_FASE_6

POINT_CUARTA_FASE_ESTE:		dw	CUARTA_FASE_0
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_6
							dw	CUARTA_FASE_0
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_6
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_3
							dw	CUARTA_FASE_5
							dw	CUARTA_FASE_7
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_3
							dw	CUARTA_FASE_5

POINT_TERCERA_FASE_ESTE:	dw	TERCERA_FASE_0
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_6
							dw	TERCERA_FASE_0
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_6
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_3
							dw	TERCERA_FASE_5
							dw	TERCERA_FASE_7
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_3
							dw	TERCERA_FASE_5

POINT_SEGUNDA_FASE_ESTE:	dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_6
							dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_6
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_3
							dw	SEGUNDA_FASE_5
							dw	SEGUNDA_FASE_7
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_3
							dw	SEGUNDA_FASE_5

POINT_PRIMERA_FASE_ESTE:	dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_6
							dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_6
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_3
							dw	PRIMERA_FASE_5
							dw	PRIMERA_FASE_7
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_3
							dw	PRIMERA_FASE_5
																					
POINT_CUARTA_FASE_SUR:		dw	CUARTA_FASE_0
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_0
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_5
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_5
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_6
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_6
							dw	CUARTA_FASE_3
							dw	CUARTA_FASE_7
							dw	CUARTA_FASE_3

POINT_TERCERA_FASE_SUR:		dw	TERCERA_FASE_0
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_0
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_5
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_5
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_6
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_6
							dw	TERCERA_FASE_3
							dw	TERCERA_FASE_7
							dw	TERCERA_FASE_3

POINT_SEGUNDA_FASE_SUR:		dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_5
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_5
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_6
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_6
							dw	SEGUNDA_FASE_3
							dw	SEGUNDA_FASE_7
							dw	SEGUNDA_FASE_3

POINT_PRIMERA_FASE_SUR:		dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_5
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_5
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_6
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_6
							dw	PRIMERA_FASE_3
							dw	PRIMERA_FASE_7
							dw	PRIMERA_FASE_3
																					
POINT_CUARTA_FASE_OESTE:	dw	CUARTA_FASE_0
							dw	CUARTA_FASE_0
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_1
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_2
							dw	CUARTA_FASE_3
							dw	CUARTA_FASE_3
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_4
							dw	CUARTA_FASE_5
							dw	CUARTA_FASE_5
							dw	CUARTA_FASE_6
							dw	CUARTA_FASE_6
							dw	CUARTA_FASE_7
							
POINT_TERCERA_FASE_OESTE:	dw	TERCERA_FASE_0
							dw	TERCERA_FASE_0
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_1
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_2
							dw	TERCERA_FASE_3
							dw	TERCERA_FASE_3
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_4
							dw	TERCERA_FASE_5
							dw	TERCERA_FASE_5
							dw	TERCERA_FASE_6
							dw	TERCERA_FASE_6
							dw	TERCERA_FASE_7

POINT_SEGUNDA_FASE_OESTE:	dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_0
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_1
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_2
							dw	SEGUNDA_FASE_3
							dw	SEGUNDA_FASE_3
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_4
							dw	SEGUNDA_FASE_5
							dw	SEGUNDA_FASE_5
							dw	SEGUNDA_FASE_6
							dw	SEGUNDA_FASE_6
							dw	SEGUNDA_FASE_7
							
POINT_PRIMERA_FASE_OESTE:	dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_0
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_1
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_2
							dw	PRIMERA_FASE_3
							dw	PRIMERA_FASE_3
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_4
							dw	PRIMERA_FASE_5
							dw	PRIMERA_FASE_5
							dw	PRIMERA_FASE_6
							dw	PRIMERA_FASE_6
							dw	PRIMERA_FASE_7							
																																																
POINT_PC_DECORADOS_FASE_4:

							dw	CUARTA_FASE_NORTE_DECORADOS
							dw	CUARTA_FASE_ESTE_DECORADOS
							dw	CUARTA_FASE_SUR_DECORADOS
							dw	CUARTA_FASE_OESTE_DECORADOS
							
POINT_PC_DECORADOS_FASE_3:

							dw	TERCERA_FASE_NORTE_DECORADOS
							dw	TERCERA_FASE_ESTE_DECORADOS
							dw	TERCERA_FASE_SUR_DECORADOS
							dw	TERCERA_FASE_OESTE_DECORADOS
														
POINT_PC_DECORADOS_FASE_2:

							dw	SEGUNDA_FASE_NORTE_DECORADOS
							dw	SEGUNDA_FASE_ESTE_DECORADOS
							dw	SEGUNDA_FASE_SUR_DECORADOS
							dw	SEGUNDA_FASE_OESTE_DECORADOS

POINT_PC_DECORADOS_FASE_1:

							dw	PRIMERA_FASE_NORTE_DECORADOS
							dw	PRIMERA_FASE_ESTE_DECORADOS
							dw	PRIMERA_FASE_SUR_DECORADOS
							dw	PRIMERA_FASE_OESTE_DECORADOS
							
POINT_EVENTOS:				dw	NO_PASA_NADA
							dw	ENCUENTRA_BOTAS
							dw	ENCUENTRA_BOTAS_ESP
							dw	ENCUENTRA_CUCHILLO
							dw	ENCUENTRA_ESPADA
							dw	ENCUENTRA_ARMADURA
							dw	ENCUENTRA_CASCO
							dw	ENCUENTRA_BRUJULA
							dw	ENCUENTRA_PAPEL
							dw	ENCUENTRA_PLUMA
							dw	ENCUENTRA_TINTA
							dw	ENCUENTRA_VIEJIGUIA
							dw	ENCUENTRA_LUPA
							dw	ENCUENTRA_BITNEDA
							dw	NO_PASA_NADA 	; POCHADERO 1(SE ENTRA DE OTRA MANERA)14
							dw	ENCUENTRA_LLAVE ; 15
							dw	NO_PASA_NADA	; ENTRADA (NO TIENE EFECTO) 16
							dw	NO_PASA_NADA	; SALIDA (SE CONTROLA DE OTRA MANERA)17
							dw	ENCUENTRA_SUPERBITNEDA;18
							dw	ENCUENTRA_AGUJERO_NEGRO;19
							dw	ENCUENTRA_TRAMPA;20
							dw	ENCUENTRA_HATER_MSX;21
							dw	ENCUENTRA_HATER_ATARI;22
							dw	ENCUENTRA_HATER_AMSTRAD;23
							dw	ENCUENTRA_HATER_COMMODORE;24
							dw	ENCUENTRA_HATER_DRAGON;25
							dw	ENCUENTRA_HATER_SPECTRUM;26
							dw	ENCUENTRA_HATER_ACORN;27
							dw	ENCUENTRA_HATER_ORIC;28
							dw	ENCUENTRA_MANZANA;29
							dw	NO_PASA_NADA 	; POCHADERO 2(SE ENTRA DE OTRA MANERA)30
							dw	NO_PASA_NADA 	; POCHADERO 3(SE ENTRA DE OTRA MANERA)31
							dw	NO_PASA_NADA 	; POCHADERO 4(SE ENTRA DE OTRA MANERA)32
							dw	ENCUENTRA_PERRO;33
							
	
;POINT_PATRON_DE_MAPA:		dw	PATRON_0
;							dw	PATRON_1
;							dw	PATRON_2		
;							dw	PATRON_3		
;							dw	PATRON_4		
;							dw	PATRON_5		
;							dw	PATRON_6		
;							dw	PATRON_7		
;							dw	PATRON_8		
;							dw	PATRON_9		
;							dw	PATRON_10	
;							dw	PATRON_11	
;							dw	PATRON_12	
;							dw	PATRON_13	
;							dw	PATRON_14


VARIABLES_PROTA:			dw	VALORES_PROTA_1
							dw	VALORES_PROTA_2
							dw	VALORES_PROTA_3
							dw	VALORES_PROTA_4
																					
; ********** FIN DE RECURSOS **********

; ********** DATAS **********
		
BORRA_PANTALLA_0:

		DW	#0000,#0000,#0000,#00D4,#0100,#0044
		DB	0,0,#D0
				
BORRA_PANTALLA_1:
	
		DW	#0000,#0000,#0000,#0100,#0100,#0100
		DB	0,0,#D0
		
copia_primera_fase_fondo_decorado_espejo:		dw		#0007,#017e,#0070,#0029,#0021,#0040

		
; ********** FIN DE DATAS **********

	ds			#69c0-$
	
				include		"RECURSOS EXTERNOS.asm"	
				
	ds			#7200-$
	
				include			"LANZADOR FMPACK Y MUSIC MODULE_0.asm"
				include			"LANZADOR EFECTOS PSG_0.ASM"
				
	DS	#8000-$

; ********** FIN PAGINA 0 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 1 DEL MEGAROM **********
	
	; PANTALLA LABERINTO 1-1
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

LABERINTO_1_1:		incbin		"SR5/LABERINTO/LABERINTO 1-1.SR5"
			
		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 1 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 2 DEL MEGAROM **********
	
	; MÚSICA PASA FASE EN 2 JUGADORES
	; PANTALLA LABERINTO 1-2
	; DIBUJO DE RAMA Y DE SOMBRA ENEMIGA
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 		

PASA_FASE:			incbin		"MUSICAS/PASA FASE.MBM"
LABERINTO_1_2:		incbin		"SR5/LABERINTO/LABERINTO 1-2.SR5"
PIEDRAS_RAMAS:		incbin		"SR5/LABERINTO/PIEDRASRAMAS_30x18.DAT"
SOMBRA_ENEMIGA:		incbin		"SR5/PROTAS/SOMBRA DEL CONTRARIO_150x65.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 2 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 3 DEL MEGAROM **********

	; PANTALLA LABERINTO 2-1
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 3)

LABERINTO_2_1:		incbin		"SR5/LABERINTO/LABERINTO 2-1.SR5"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 3 DEL MEGAROM **********)))

; ______________________________________________________________________


; (((********** PAGINA 4 DEL MEGAROM **********

	; MUSICA GANA LA PARTIDA 2 JUGADORES
	; PANTALLA LABERINTO 2-2
	; MAPA LABERINTOS FORMATO DE 1 JUGADOR
	; LA S PARA PRESENTACION CARAMBALAN EN INGLES
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 4)	

GANO_2_JUG:			incbin		"MUSICAS/GANA LA PARTIDA 2 JUGADORES.MBM"

LABERINTO_2_2:		incbin		"SR5/LABERINTO/LABERINTO 2-2.SR5"

NIVEL_1_EN_PAGE_4:

		call	DECORADOS_NIVEL_1_POR_CODIGO
		jp		VARIABLES_NIVEL_1
		
		; CARGAMOS EL LABERINTO
		
DECORADOS_NIVEL_1_POR_CODIGO:
		
		or		a
		ld		bc,990													;cargamos el laberinto en memoria
		ld		de,mapa_del_laberinto
		ld		hl,DATA_LABERINTO_1
					
		ldir	

		ld		bc,990													;cargamos los decorados del laberinto en memoria
		ld		de,decorados_laberinto
		ld		hl,DATA_DECORADOS_LABERINTO_1
					
		ldir


		ld		bc,900													;cargamos los sucesos del laberinto en memoria
		ld		de,eventos_laberinto
		ld		hl,DATA_SUCESOS_LABERINTO_1
					
		ldir

		ld		hl,375
		ld		(casilla_destino_agujero_negro),hl
		ld		a,128	
		ld		(x_map_destino_agujero_negro),a
		ld		a,67	
		ld		(y_map_destino_agujero_negro),a
				
		ret
		
VARIABLES_NIVEL_1:
		
		ld		hl,375
		ld		(casilla_destino_agujero_negro),hl
		ld		a,128	
		ld		(x_map_destino_agujero_negro),a
		ld		a,67	
		ld		(y_map_destino_agujero_negro),a
		
		; definimos salida y orientación
		
		xor		a
		ld		(patron_actual_cargado),a	
		
		call	DA_VALOR_AL_DADO_7										; buscamos un valor aleatorio entre 0 y 7
		inc		a
		ld		de,POSICIONES_1
		jp		lista_de_opciones_7										

POSICION_1_1:

		ld		hl,255													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,128													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,67
		ld		(y_map_1),a
		ld		a,2														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		VOLVEMOS_A_PAGE_0
		
POSICION_1_2:

		ld		hl,319													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,148													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,77
		ld		(y_map_1),a
		ld		a,3														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		VOLVEMOS_A_PAGE_0
		
POSICION_1_3:

		ld		hl,340													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,103													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,82
		ld		(y_map_1),a
		ld		a,1														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		VOLVEMOS_A_PAGE_0
		
POSICION_1_4:

		ld		hl,435													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,128													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,97
		ld		(y_map_1),a
		xor		a														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		VOLVEMOS_A_PAGE_0

NIVEL_2_EN_PAGE_4:

		call	DECORADOS_NIVEL_2_POR_CODIGO
		jp		VARIABLES_NIVEL_2
		
		; CARGAMOS EL LABERINTO
		
DECORADOS_NIVEL_2_POR_CODIGO:
		
		or		a
		ld		bc,990													;cargamos el laberinto en memoria
		ld		de,mapa_del_laberinto
		ld		hl,DATA_LABERINTO_2
					
		ldir	

		ld		bc,990													;cargamos los decorados del laberinto en memoria
		ld		de,decorados_laberinto
		ld		hl,DATA_DECORADOS_LABERINTO_2
					
		ldir


		ld		bc,900													;cargamos los sucesos del laberinto en memoria
		ld		de,eventos_laberinto
		ld		hl,DATA_SUCESOS_LABERINTO_2
					
		ldir

		ld		hl,356;  
		ld		(casilla_destino_agujero_negro),hl
		ld		a,183
		ld		(x_map_destino_agujero_negro),a
		ld		a,82
		ld		(y_map_destino_agujero_negro),a
				
		ret
		
VARIABLES_NIVEL_2:
		
		ld		hl,356;  
		ld		(casilla_destino_agujero_negro),hl
		ld		a,183
		ld		(x_map_destino_agujero_negro),a
		ld		a,82
		ld		(y_map_destino_agujero_negro),a
		
		; definimos salida y orientación

		call	DA_VALOR_AL_DADO										; buscamos un valor aleatorio entre 0 y 7
		ld		de,POSICIONES_2
		jp		lista_de_opciones										; ¡¡¡¡¡¡¡¡PUNTO DE SALTO DEL BUGG IMPREDECIBLE!!!!!! 
		
POSICION_2_1:

		ld		hl,180;													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,53													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,57
		ld		(y_map_1),a
		ld		a,1														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_2_2:

		ld		hl,240													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,53													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,67
		ld		(y_map_1),a
		ld		a,1														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_2_3:

		ld		hl,326													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,183													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,77
		ld		(y_map_1),a
		ld		a,3														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_2_4:

		ld		hl,371													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,108													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,87
		ld		(y_map_1),a
		xor		a														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA

NIVEL_3_EN_PAGE_4:

		call	DECORADOS_NIVEL_3_POR_CODIGO
		jp		VARIABLES_NIVEL_3
		
		; CARGAMOS EL LABERINTO
		
DECORADOS_NIVEL_3_POR_CODIGO:
		
		or		a
		ld		bc,990													;cargamos el laberinto en memoria
		ld		de,mapa_del_laberinto
		ld		hl,DATA_LABERINTO_3
					
		ldir	

		ld		bc,990													;cargamos los decorados del laberinto en memoria
		ld		de,decorados_laberinto
		ld		hl,DATA_DECORADOS_LABERINTO_3
					
		ldir


		ld		bc,900													;cargamos los sucesos del laberinto en memoria
		ld		de,eventos_laberinto
		ld		hl,DATA_SUCESOS_LABERINTO_3
					
		ldir

		ld		hl,315
		ld		(casilla_destino_agujero_negro),hl
		ld		a,128	
		ld		(x_map_destino_agujero_negro),a
		ld		a,77	
		ld		(y_map_destino_agujero_negro),a
				
		ret
		
VARIABLES_NIVEL_3: ;53 Y 27
		
		ld		hl,315
		ld		(casilla_destino_agujero_negro),hl
		ld		a,128	
		ld		(x_map_destino_agujero_negro),a
		ld		a,77	
		ld		(y_map_destino_agujero_negro),a
		
		; definimos salida y orientación
				
		call	DA_VALOR_AL_DADO										; buscamos un valor aleatorio entre 0 y 7
		ld		de,POSICIONES_3
		jp		lista_de_opciones										; ¡¡¡¡¡¡¡¡PUNTO DE SALTO DEL BUGG IMPREDECIBLE!!!!!! 
		
POSICION_3_1:

		ld		hl,36													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,83													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,32
		ld		(y_map_1),a
		ld		a,2														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_3_2:

		ld		hl,45													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,128													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,32
		ld		(y_map_1),a
		ld		a,2														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_3_3:

		ld		hl,157													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,88													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,52
		ld		(y_map_1),a
		xor		a													;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_3_4:

		ld		hl,173													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,168													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,52
		ld		(y_map_1),a
		xor		a														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA

NIVEL_4_EN_PAGE_4:

		call	DECORADOS_NIVEL_4_POR_CODIGO
		jp		VARIABLES_NIVEL_4
		
		; CARGAMOS EL LABERINTO
		
DECORADOS_NIVEL_4_POR_CODIGO:	

		or		a
		ld		bc,990													;cargamos el laberinto en memoria
		ld		de,mapa_del_laberinto
		ld		hl,DATA_LABERINTO_4
					
		ldir	

		ld		bc,990													;cargamos los decorados del laberinto en memoria
		ld		de,decorados_laberinto
		ld		hl,DATA_DECORADOS_LABERINTO_4
					
		ldir


		ld		bc,900													;cargamos los sucesos del laberinto en memoria
		ld		de,eventos_laberinto
		ld		hl,DATA_SUCESOS_LABERINTO_4
					
		ldir

		ld		hl,471
		ld		(casilla_destino_agujero_negro),hl
		ld		a,158	
		ld		(x_map_destino_agujero_negro),a
		ld		a,102	
		ld		(y_map_destino_agujero_negro),a
				
		ret
		
VARIABLES_NIVEL_4: ;53 Y 27
		
		ld		hl,471
		ld		(casilla_destino_agujero_negro),hl
		ld		a,158	
		ld		(x_map_destino_agujero_negro),a
		ld		a,102	
		ld		(y_map_destino_agujero_negro),a
		
		; definimos salida y orientación
				
		call	DA_VALOR_AL_DADO										; buscamos un valor aleatorio entre 0 y 7
		ld		de,POSICIONES_4
		jp		lista_de_opciones										; ¡¡¡¡¡¡¡¡PUNTO DE SALTO DEL BUGG IMPREDECIBLE!!!!!! 
		
POSICION_4_1:

		ld		hl,150													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,53													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,52
		ld		(y_map_1),a
		ld		a,1														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_4_2:

		ld		hl,554													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,123													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,117
		ld		(y_map_1),a
		ld		a,0														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_4_3:

		ld		hl,600													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,53													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,127
		ld		(y_map_1),a
		ld		a,1														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
		
POSICION_4_4:

		ld		hl,689													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		a,198													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,137
		ld		(y_map_1),a
		xor		a,3														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
						
		jp		PREPARAMOS_INTERRUPCION_DE_LINEA
						
DATA_LABERINTO_1:

	include	"LABERINTOS/FASE_1_1_LABERINTO.asm"	

DATA_DECORADOS_LABERINTO_1:

	include	"LABERINTOS/FASE_1_1_DECORADOS.asm"	
										
DATA_SUCESOS_LABERINTO_1:

	include	"LABERINTOS/FASE_1_1_SUCESOS.asm"	

DATA_LABERINTO_2:

	include	"LABERINTOS/FASE_1_2_LABERINTO.asm"	

DATA_DECORADOS_LABERINTO_2:

	include	"LABERINTOS/FASE_1_2_DECORADOS.asm"	
										
DATA_SUCESOS_LABERINTO_2:

	include	"LABERINTOS/FASE_1_2_SUCESOS.asm"	
		
DATA_LABERINTO_3:

	include	"LABERINTOS/FASE_1_3_LABERINTO.asm"	

DATA_DECORADOS_LABERINTO_3:

	include	"LABERINTOS/FASE_1_3_DECORADOS.asm"	
										
DATA_SUCESOS_LABERINTO_3:

	include	"LABERINTOS/FASE_1_3_SUCESOS.asm"	

DATA_LABERINTO_4:

	include	"LABERINTOS/FASE_1_4_LABERINTO.asm"	

DATA_DECORADOS_LABERINTO_4:

	include	"LABERINTOS/FASE_1_4_DECORADOS.asm"	
										
DATA_SUCESOS_LABERINTO_4:

	include	"LABERINTOS/FASE_1_4_SUCESOS.asm"	

LA_S_PARA_INGLES:

	incbin	"SR5/MENU/LA S_24x45.DAT"

copia_s_en_pantalla:			dw		#00a8,#0381,#0018,#002d
								db		#00,#00,#F0	
POSICIONES_2:				dw	POSICION_2_1
							dw	POSICION_2_2
							dw	POSICION_2_3
							dw	POSICION_2_4
							dw	POSICION_2_1
							dw	POSICION_2_2
							dw	POSICION_2_3
							dw	POSICION_2_4
POSICIONES_3:				dw	POSICION_3_1
							dw	POSICION_3_2
							dw	POSICION_3_3
							dw	POSICION_3_4
							dw	POSICION_3_1
							dw	POSICION_3_2
							dw	POSICION_3_3
							dw	POSICION_3_4
POSICIONES_4:				dw	POSICION_4_1
							dw	POSICION_4_2
							dw	POSICION_4_3
							dw	POSICION_4_4
							dw	POSICION_4_1
							dw	POSICION_4_2
							dw	POSICION_4_3
							dw	POSICION_4_4
																														
		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 4 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 5 DEL MEGAROM **********

	; PRIMERA PARTE DEL FONDO DURANTE EL JUEGO
	; PALETA DEL LABERINTO
	; CAMBIOS DEL BANCO 1
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 5)

FONDO_ESTRUCTURA_1:		incbin		"SR5/LABERINTO/FONDO 1.SR5"

VOLVEMOS_DE_LA_TIENDA:
		
		di
		or		a
		xor		a
		ld		[#6000],a												;banco 1, pagina 0 del MEGAROM
		ei
		
		ret

EL_6000_PARA_37_COLISION:
		
		di
		or		a
		ld		a,37
		ld		[#6000],a												;banco 1, pagina 7 del MEGAROM
		ei
		
		jp		COMIENZA_COLISION	
				
EL_6000_PARA_37_POCHADA:
		
		di
		or		a
		ld		a,37
		ld		[#6000],a												;banco 1, pagina 7 del MEGAROM
		ei
		
		jp		COMIENZA_TIENDA	

EL_6000_PARA_37_ENEMIGO_FINAL:
		
		di
		or		a
		ld		a,37
		ld		[#6000],a												;banco 1, pagina 7 del MEGAROM
		ei
		
		jp		COMIENZA_ENEMIGO_FINAL	

RECUPERAMOS_PAGE0_EN_1:
				
		xor		a
		ld     	[#6000],a
		

		ret
								
BANCO_1_PAGINA_7_PARA_IDIOMA:
		
		di
		or		a
		ld		a,7
		ld		[#6000],a												;banco 1, pagina 7 del MEGAROM
		ei
		
		
		jr.		PREPARACION_BANCO_7			

BANCO_1_PAGINA_7_PARA_MENU:
		
		di																; desconectamos las interrupciones
																				
		ld 		a,(RG0SAV)												; leemos allí donde tenemos la copia de los registros de escritura, ya que estos registros en sí no se pueden leer
		and		11101111B												; hacemos que el BIT 4 sea 0
		ld 		(RG0SAV),a												; salvamos ese nuevo valor en la copia
		OUT 	(#99),a													; especificamos el valor en la dirección #99
		ld 		a,0+128													; le damos a a el valor del registro en el que hay que escribir
		OUT 	(#99),a													; especificamos el número de registro en la direccion #99
				
		ld		a,0
		ld		[#6000],a												;banco 1, pagina 7 del MEGAROM
		

		
		jp		INICIO	
		
BANCO_1_PAGINA_0_PARA_JUEGO:
		
		di
		or		a
		xor		a
		ld		[#6000],a												;banco 1, pagina 0 del MEGAROM

		jp		PREPARAMOS_INTERRUPCION_DE_LINEA		

RUTINA_BUSQUEDA_FMPAC:

SRCFMP:  LD    HL,0FCCAh
         XOR   A
         LD    B,4
         
FMLP2:   PUSH  BC
         LD    B,4
         
FMLP1:   PUSH  BC
         PUSH  AF
         PUSH  HL
         SET   7,A
         LD    H,040h
         CALL  024h
         POP   HL
         PUSH  HL
 ;        LD    A,(HL)
 ;        CP    020h
 ;        CALL  Z,FMTEST
		call	FMTEST
         JP    Z,FMFND
         POP   HL
         POP   AF
         ADD   A,4
         AND   0Fh
         INC   HL
         INC   HL
         INC   HL
         INC   HL
         POP   BC
         DJNZ  FMLP1
         ADD   A,1
         AND   03h
         POP   BC
         DJNZ  FMLP2
         JP    SETBAS
         
FMTEST:  LD    HL,0401Ch
         LD    DE,FMTEXT
         LD    B,4
         
FMLP:    LD    A,(DE)
         CP    (HL)
         RET   NZ
         INC   HL
         INC   DE
         DJNZ  FMLP
         CP    A
         RET
         
FMFND:   POP   HL
         POP   AF
         POP   BC
         POP   BC
         LD    A,(chips)
         SET   1,A
         LD    (chips),A
         LD    A,(07FF6h)
         OR    1
         LD    (07FF6h),A
         
SETBAS:  

		call	CAMBIA_SLOT_PAGE_1_A_MI_CARTUCHO
		xor		a
		ld		[#6000],a

        RET
         
FMTEXT:  DB    "OPLL"

CAMBIA_SLOT_PAGE_1_A_MI_CARTUCHO:										; ampliar a espacios 1 y 2 los usados en la ram del ordenador
		
				ld a,(SLOTVAR)
				ld	h,#40												; 00 para page 0, 40 para page 1, 80 para page 2, c0 para page 3
				jp ENASLT												; Hacemos que en esa página, el ordenador mire al cartucho de slotvar
						
		ds		#c000-$													; llenamos de 0 hasta el final del bloque


; ********** FIN PAGINA 5 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 6 DEL MEGAROM **********

	; SEGUNDA PARTE DEL FONDO DURANTE EL JUEGO

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 6)

MUSICA_SELEC:						incbin		"MUSICAS/SELECCION.MBM"

FONDO_ESTRUCTURA_2:		incbin		"SR5/LABERINTO/FONDO 2.SR5"


		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 6 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 7 DEL MEGAROM **********

	; ANIMACIÓN DE LA CASA
	; SELECCION DE IDIOMA
	; PALETAS EN FADE DE IDIOMA
	; RECURSOS EXTERNOS QUE SE REPITEN EN CADA BLOQUE DE BANCO 1

		org		#4000													;esto define dónde se empieza a escribir el bloque (page 7)	

PREPARACION_BANCO_7:
		
		di						
		LD 		a,(RG0SAV)												; disable Line Interrupt: Set R#0 bit 4
		and		11101111B
		LD 		(RG0SAV),a			
		OUT 	(#99),a		
		LD 		a,0+128		
		OUT 	(#99),a	

		ld		a,00000000b
																		; metemos una posicion de adjust centrada
		OUT 	(#99),a		
																		;apuntamos el dato a poner en el registro	
		ld		a,18+128												;cargamos el valor de registro con el bit 8 establecido (+128)
		out		(#99),a	
		ei
		call	ACTIVAMOS_SPRITES
		JP		PREPARACION_EFECTOS_DE_SONIDO
		
ACTIVAMOS_SPRITES:

		di
		
		ld 		a,(RG1SAV)												; activamos sprites
		or		00000010B
		ld 		(RG1SAV),a			
		out 	(#99),a		
		ld 		a,1+128		
		out 	(#99),a														

		ld 		a,(RG8SAV)												; los hacemos de 16*16
		and		11111101B
		ld 		(RG8SAV),a			
		out 	(#99),a		
		ld 		a,8+128		
		out 	(#99),a			

		ld 		a,(RG5SAV)												; colocamos los punteros de sprites en vram
		or		11110111B
		and		11110111b
		ld 		(RG5SAV),a			
		out 	(#99),a		
		ld 		a,5+128		
		out 	(#99),a			

		ld 		a,(RG11SAV)												; colocamos los punteros de sprites en vram
		and		11111100B
		ld 		(RG11SAV),a			
		out 	(#99),a		
		ld 		a,11+128		
		out 	(#99),a		
			
 		LD 		A,(RG6SAV)												
		OR		00001110B
		and		11111110b
		LD 		(RG6SAV),a			
		OUT 	(#99),A		
		LD 		A,6+128		
		OUT 	(#99),A	       
        ei
        
		ret
	
PREPARACION_EFECTOS_DE_SONIDO:
		
		ld		a,16
        call	EL_7000_7
		
		ld		hl,EFECTOS_DE_SONIDO
		call	ayFX_SETUP

PREPARAMOS_LA_INTERRUPCION_ADECUADA:
		
		di
		
		xor		a
		ld		(mosca_activa),a
				
		ld		a,#C3													;#c3 es el código binario de jump (jp)
		ld		[H.TIMI],a												;metemos en H.TIMI ese jp
		ld		hl,INTERRUPCION_SIN_MUSICA								;cargamos nuestra secuencia en hl
		ld		[H.TIMI+1],hl											;la ponemos a continuación del jp
		
		ei	
	
		ld		a,(ya_hemos_visto_petiso)
		cp		37
		jp		z,PREPARACION_DEL_MENU
		
		ld		a,(marca_e_idioma)
		or		a
		jp		nz,PREPARACION_DEL_MENU
						
PREPARACION_MARCA:

		ld		a,37
		ld		(ya_hemos_visto_petiso),a

		call	LIMPIA_PANTALLA_0_A_3_7		
		
		ld		a,0														;set page 0
		call	setpage_7
						
		ld      a, 1
		ld      [ACPAGE],a              								;set page x,1
        
		ld		a,10
        call	EL_7000_7

						
		ld		hl,MARCA_1												;carga caratula marca parte 1
		ld		de,#0000
		ld		bc,16144
		call	LDIRVM
		
		ld		a,11
        call	EL_7000_7


		ld		hl,paleta_marca_1										;Primera paleta de colores
		call	SetPalet_7		

		ld		hl,MARCA_2												;carga caratula marca parte 2
		ld		de,#3F10
		ld		bc,5480
		call	LDIRVM
														
		ld      a,0
		ld      [ACPAGE],a              								;set page x,0
				
		call	ANIMACION_DE_MARCA
		call	FADE_OUT_MARCA
		
PREPARACION_IDIOMA:
		
		call	LIMPIA_PANTALLA_0_A_3_7
		
		ld		a,0														;set page 0
		call	setpage_7
		
		ld      a, 1
		ld      [ACPAGE],a              								;set page x,1
		
		ld		a,8
        call	EL_7000_7
		
		ld		hl,PANTALLA_DE_IDIOMA									;carga gráficos idioma
		ld		de,#0000
		ld		bc,14100
		call	LDIRVM

		xor		a
		ld      [ACPAGE],a              								;set page x,0		

		ld		hl,PALETA_DEL_IDIOMA									;Paleta de colores para el idioma
		call	SetPalet_7			
						
		ld		iy,copia_seleccion_de_idioma
		call	COPY_A_GUSTO_7
	
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_eng
		call	COPY_A_GUSTO_7
		
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_esp
		call	COPY_A_GUSTO_7
		
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_petiso_senala_esp
		call	COPY_A_GUSTO_7
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		
FADE_IN_DEL_IDIOMA:

		ld		hl,IDIOMA_FADE_IN										;colocamos el lector al comienzo de la secuencia de idioma en fade in de la paleta
		call	FADE_7													;lo mandamos a la rutina de esta page para hacer un fade
		push	af														;no sirve de nada, pero luego nos hará falta un pop y esto compensa para no cargar la pila
		
SELECCIONAMOS_CASTELLANO:
		
		ld		a,16
        call	EL_7000_7

		
		ld		a,6
		ld		c,1
		call	ayFX_INIT
								
		pop		af														;venga de la rutina stick de idioma o no, quita un dato de la pila que se ha acumulado
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_petiso_senala_esp
		call	COPY_A_GUSTO_7
		
		ld		hl,datos_del_copy
		call	DoCopy_7
				
		ld		a,2														; Ponemos el idioma en castellano
		ld		(idioma),a
		ld		a,20
		ld		(pagina_de_idioma),a

STICK_DE_IDIOMA:
		
		xor		a
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		ld		a,1
		call	.SUBRUTINA_DE_STICK
		ld		a,2														;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		call	.SUBRUTINA_DE_STICK
		jp		STRIG_DE_IDIOMA

.SUBRUTINA_DE_STICK:
		
		call	GTSTCK
		
		cp		3
		jr.		z,SELECCIONAMOS_CASTELLANO
		
		cp		7
		jr.		z,SELECCIONAMOS_INGLES
		
		RET
			
STRIG_DE_IDIOMA:

		xor		a
		call	.SUBRUTINA_DE_TRIG
		ld		a,1
		call	.SUBRUTINA_DE_TRIG
		ld		a,2
		call	.SUBRUTINA_DE_TRIG		
		jp		STICK_DE_IDIOMA

.SUBRUTINA_DE_TRIG:
		
		CALL	GTTRIG
		
		cp		255
		jr.		z,FADE_OUT_DEL_IDIOMA
		
		ret
		
SELECCIONAMOS_INGLES:
		
		ld		a,16
        call	EL_7000_7
		
		ld		a,6
		ld		c,1
		call	ayFX_INIT	
		
		pop		af														; quita un dato de la pila que se ha acumulado por un call sin ret
		ld		hl,datos_del_copy
		call	DoCopy_7
		ld		iy,copia_petiso_senala_eng
		call	COPY_A_GUSTO_7

		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		a,1														; Ponemos el idioma en inglés
		ld		(idioma),a
		ld		a,82
		ld		(pagina_de_idioma),a
		
		jr.		STICK_DE_IDIOMA

FADE_OUT_DEL_IDIOMA:

		ld		a,16
        call	EL_7000_7
				
		ld		a,7
		ld		c,0
		call	ayFX_INIT
		
		pop		af														; sacamos de la pila el valor metido con un call que no tendrá ret
		ld		hl,IDIOMA_FADE_OUT										; situamos el puntero en los data de fade out paleta idioma
		call	FADE_7													; ejecutamos la secuencia de fade de esta page
				
PREPARACION_DEL_MENU:

		ld		a,(salto_historia)
		cp		0
		jp		nz,FADE_IN_DEL_MENU
				
		xor		a
		ld		(turno_sin_tirar),a
		
		call	DISSCR
		
		xor		a														; definimos variables del menu
		ld		(posicion_del_titulo),a
		ld		(posicion_del_titulo_inicio),a
		ld		(repeticion_posicion_titulo),a

		ld		a,2														;set page 2
		call	setpage_7


		ld		a,0
		ld		(el_menu_baila),a										; DESconecta el movimiento del titulo
		
		call	LIMPIA_PANTALLA_0_A_3_7									; un cuadrado de color 0 en todas las pantallas
		
		ld		hl,TITULO_FADE_IN
		call	SetPalet_7

		call	ENASCR
		
		ld		a,9
        call	EL_7000_7

		ld      a, 1
		ld      [ACPAGE],a              								;set page x,1

		ld		a,(idioma)
		cp		1
		jp		z,PREPARACION_DEL_MENU_DOS
		
		ld		hl,PANTALLA_DE_TITULO									;carga gráficos del título
		ld		de,#0000
		ld		bc,8448
		call	LDIRVM
		jp		PREPARACION_DEL_MENU_TRES
				
PREPARACION_DEL_MENU_DOS:

		ld		a,13
        call	EL_7000_7

		ld		hl,PANTALLA_DE_TITLE									;carga gráficos del título
		ld		de,#0000
		ld		bc,8448
		call	LDIRVM

		ld		a,9
        call	EL_7000_7
	
PREPARACION_DEL_MENU_TRES:

		ld		hl,PULSA_UNA_TECLA										;carga gráficos del texto del título
		ld		de,#2100
		ld		bc,2944
		call	LDIRVM
	
		ld      a, 0
		ld      [ACPAGE],a              								;set page x,0		
		
		ld		iy,copia_titulo_del_menu
		call	COPY_A_GUSTO_7
		
		xor		a
		ld		(ix+13),a												;cómo es el copy	
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7

		call	SPRITES
		jp		DECIDIMOS_IDIOMA
		
SPRITES:

		ld		a,55
        call	EL_7000_7
        
		ld		hl,sprites_pat											; Lo último que hacemos es depositar los sprites en vram	
		ld		de,#7000
		ld		bc,704
		call	LDIRVM
		ld		hl,sprites_col											; COLOR DEL SPRITE	
		ld		de,#7800
		ld		bc,288
		call	LDIRVM

		ld		ix,atributos_sprites_prota								; plano 1 fuera de vista
		ld		de,#7a04
		ld		a,#D8
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		call	LDIRVM
		
		ld		de,#7a08												; plano 2 a posición de invisible todos los de debajo
		ld		a,#d8
		ld		(ix),a		
		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		call	LDIRVM	
		ld		a,9
        call	EL_7000_7
        
		RET	
		
DECIDIMOS_IDIOMA:
					
		ld		a,(idioma)
		cp		1
		jr.		z,TEXTO_EN_INGLES

		
		
TEXTO_EN_CASTELLANO:

		ld		iy,copia_pulsa_una_tecla
		call	COPY_A_GUSTO_7


				
		jr.		FADE_IN_DEL_MENU
		
TEXTO_EN_INGLES:

		ld		iy,copia_push_space_key
		call	COPY_A_GUSTO_7
				
FADE_IN_DEL_MENU:

		ld		a,(salto_historia)
		cp		0
		jp		nz,PREPARAMOS_INTERRUPCION_DE_LINEA_7
		
		ld		a,10010000b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
				
PREPARAMOS_INTERRUPCION_DE_LINEA_7:
		
		LD 		a,90													;Metemos lilnea 90 en el registro 19
		ld		(interrupcion_valida),a
		OUT		(#99),a		
		ld 		a,19+128		
		out 	(#99),a		

INTERRUPCIONES_DE_LINEA_ABIERTAS_7:

		LD 		a,(RG0SAV)												; Enable Line Interrupt: Set R#0 bit 4
		OR		00010000B
		LD 		(RG0SAV),a			
		OUT 	(#99),a		
		LD 		a,0+128		
		OUT 	(#99),a		
				
	;engancha nuestra rutina de servicio al gancho que deja preparada la BIOS cuando se termina de pintar la pantalla (50 o 60 veces por segundo)

GANCHO_DE_INTERRUPCION_GENERAL_7:
		
		di
		
		ld		a,#C3													;#c3 es el código binario de jump (jp)
		ld		[H.KEYI],a												;metemos en H.TIMI ese jp
		ld		hl,NUESTRA_ISR_7										;con el jp anterior, construimos jp NUESTRA_ISR
		ld		[H.KEYI+1],hl											;la ponemos a continuación del jp
		
		ei
				
		

		ld      a, 1
		ld      [ACPAGE],a              								;set page x,1
        
		ld		a,12
        call	EL_7000_7
				
		ld		hl,SELEC_MENU_1											;carga selecciones del menú parte 1
		ld		de,#0000
		ld		bc,16144
		di
		call	LDIRVM
		ei
		
		ld		a,34
        call	EL_7000_7

		ld		hl,SELEC_MENU_2											;carga selecciones del menú parte 2
		ld		de,#3F10
		ld		bc,10608
		di
		call	LDIRVM
		ei

		LD		A,0
		LD		(que_musica_7),a

INICIAMOS_MUSICA:

		ld		a,15
        call	EL_7000_7

		xor		a														;le damos 0 a la posicion de arranque de la música
		ld		(pos),a
		ld		a,1
		ld		(modval),a
		ld		a,7
		ld		(psgvol),a
		
		ld		a,15
        call	EL_7000_7
				
		LD 		A,1 													; 0 MSX AUDIO, 1 MSX MUSIC, 2 ESTEREO
		LD 		(chips),A
		
;		call	SRCFMP
				
		XOR 	A
		LD 		(CLIKSW),A
		LD 		A,0
		LD 		(busply),A
		LD 		A,3
		LD 		(muspge),A

		LD		B,15
		XOR	 	A
		LD 		HL,pos

S1:

		LD 		(HL),A
		INC 	HL
		DJNZ 	S1
		LD 		HL,_modval      										; copia variables por defecto
		LD 		DE,modval
		LD 		BC,einde-_modval
		LDIR
		LD 		D,0             										; pone variables valor de rango 0
		LD 		BC,psgvol-stepbf+1
		LD 		HL,stepbf
	
S2:

		LD		(HL),D
		INC 	HL
		DEC 	BC
		LD 		A,B
		OR 		C
		JR 		NZ,S2
		CALL	MUS1

		ld		a,(salto_historia)
		cp		0
		jp		nz,VAMOS_A_CONOCER_LA_HISTORIA
			
		CALL	strmus
		
CARAMBALAN_STUDIOS_PRESENTA:
		
		ld      a,0
		ld      [ACPAGE],a              								;set page x,0
		
		ld		a,1
		ld		(mosca_activa),a
				
		ld		a,0														;set page 0
		call	setpage_7
		
		ld		a,35
        call	EL_7000_7

		ld		de,CSP
		ld		hl,copia_carambalan_en_pantalla							;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_7
		
		ld		a,(idioma)
		cp		1
		jp		nz,.SIGUE_LA_PRESENTACION

		ld		a,4
        call	EL_7000_7

		ld		de,LA_S_PARA_INGLES
		ld		hl,copia_s_en_pantalla									;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_7
		

		
.SIGUE_LA_PRESENTACION:

		ld		a,36
        call	EL_7000_7

		ld		iy,copia_carambalan_trozo
		call	COPY_A_GUSTO_7
		
		ld		a,10010000b
		ld		(ix+14),a												;especificamos la linea
		
		ld		hl,datos_del_copy
		call	DoCopy_7		
		
		ld		a,(ix)
		add		36
		ld		(ix),a
		ld		(ix+4),a
		
		ld		a,1
		ld		(var_cuentas_paleta_esp),a
		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		a,40
		ld		(mosca_y_objetivo),a		
		ld		hl,CSP1_IN
		call	FADE_7
				
		ld		a,3
		ld		(ix+8),a

		ld		a,2
		ld		(var_cuentas_paleta_esp),a
				
		ld		a,65
		ld		(var_cuentas_paleta_int),a


				
		call	CARAM_1
		call	CARAM_2
		call	LIMPIA_PANTALLA_0_7
		

				
		ld		a,255
		call	RALENTIZA_7_ESP
		
		ld		hl,CSP1_IN												;cOLORES A 0
		call	SetPalet_7	

		ld		iy,copia_carambalan_trozo
		call	COPY_A_GUSTO_7
		
		ld		a,64
		ld		(ix),a
		ld		(ix+4),a
		ld		a,84
		ld		(ix+2),a
		ld		(ix+6),a
								
		ld		a,10010000b
		ld		(ix+14),a												;especificamos la linea
		
		ld		hl,datos_del_copy
		call	DoCopy_7		

		ld		a,(ix)
		add		36
		ld		(ix),a
		ld		(ix+4),a
		
		ld		a,1
		ld		(var_cuentas_paleta_esp),a
		ld		a,62
		ld		(mosca_x_objetivo),a
		ld		a,79
		ld		(mosca_y_objetivo),a		
		ld		hl,CSP1_IN
		call	FADE_7
		
		ld		a,3
		ld		(ix+8),a

		ld		a,2
		ld		(var_cuentas_paleta_esp),a
				
		ld		a,60
		ld		(var_cuentas_paleta_int),a


		
		call	CARAM_1
		call	CARAM_2
		call	LIMPIA_PANTALLA_0_7
		
		ld		a,255
		call	RALENTIZA_7_ESP
				
		ld		hl,CSP1_IN												;cOLORES A 0
		call	SetPalet_7	
		
		ld		iy,copia_carambalan_trozo
		call	COPY_A_GUSTO_7
		
		ld		a,46
		ld		(ix),a
		ld		(ix+4),a
		ld		a,128
		ld		(ix+2),a
		ld		(ix+6),a
								
		ld		a,10010000b
		ld		(ix+14),a												;especificamos la linea
		
		ld		hl,datos_del_copy
		call	DoCopy_7		

		ld		a,(ix)
		add		36
		ld		(ix),a
		ld		(ix+4),a
		
		ld		a,1
		ld		(var_cuentas_paleta_esp),a
		ld		a,40
		ld		(mosca_x_objetivo),a
		ld		a,125
		ld		(mosca_y_objetivo),a		
		ld		hl,CSP1_IN
		call	FADE_7
		
		ld		a,3
		ld		(ix+8),a

		ld		a,2
		ld		(var_cuentas_paleta_esp),a
				
		ld		a,62
		ld		(var_cuentas_paleta_int),a


		
		call	CARAM_1
		call	CARAM_2
		ld		hl,CSP1_IN												;cOLORES A 0
		call	SetPalet_7	
		ld		iy,copia_carambalan_trozo
		call	COPY_A_GUSTO_7

		ld		a,255
		call	RALENTIZA_7_ESP
							
		ld		a,#d0
		ld		(ix+8),a
		ld		a,#86
		ld		(ix+10),a
								
		ld		a,10010000b
		ld		(ix+14),a												;especificamos la linea
		
		push	hl
		ld		hl,datos_del_copy
		call	DoCopy_7		
		pop		hl
				
		call	CARAM_3	
					
CARAM_1:


		
		push	hl
		ld		a,(ix)
		add		3
		ld		(ix),a
		ld		(ix+4),a
		ld		a,10010000b
		ld		(ix+14),a													
		ld		hl,datos_del_copy		

		call	DoCopy_7
		CALL	INTERRUMPE_CSP		
		ld		a,(ix+4)
		sub		45
		ld		(ix+4),a
		ld		a,0
		ld		(ix+12),a		
		ld		a,10000000b
		ld		(ix+14),a

		ld		hl,datos_del_copy		
		call	DoCopy_7
		ld		a,(ix+4)
		add		45
		ld		(ix+4),a				
		pop		hl
				
		call	FADE_7
		
		ld		a,(var_cuentas_paleta_int)
		dec		a
		ld		(var_cuentas_paleta_int),a
		cp		0
		jp		nz,CARAM_1
		ret
				
CARAM_2:

		push	hl
		CALL	INTERRUMPE_CSP
		xor		a
		ld		(var_cuentas_paleta_esp),a	

		call	FADE_7
		
		pop		hl
		ret
		
FINAL_CSP:
		
		pop		af
		ld		hl,CSP1_IN
		xor		a
		ld		(var_cuentas_paleta_esp),a

		jp		PRE_TITULO
																		; ENCONTRAR EL CAMINO HACIA EL TITULO
		
CARAM_3:

		ld		a,121
		ld		(mosca_x_objetivo),a
		ld		a,33
		ld		(mosca_y_objetivo),a						
		call	FADE_7

		xor		2
		ld		(var_cuentas_paleta_esp),a	

[6]		call	FADE_7
										
		xor		a
		ld		(var_cuentas_paleta_esp),a
		
	
			
		ld		a,235
		ld		(ralentizando),a

		call	RALENTIZA_7

PRE_TITULO:
							
		ld		hl,CSP_OUT
		call	FADE_7	
		
		ld		a,9
        call	EL_7000_7

		ld		a,70
		ld		(mosca_x_objetivo),a
		ld		a,168
		ld		(mosca_y_objetivo),a
				
TITULO:
	
		ld		a,2														;set page 2
		call	setpage_7
		
		ld		a,1
		ld		(el_menu_baila),a										; conecta el movimiento del titulo
																		
		ld      a,0
		ld      [ACPAGE],a              								;set page x,0
		ld		(codigo_activo),a
		
		ld		hl,TITULO_FADE_IN
		call	FADE_7						

		ld		h,0
		ld		l,0
		
		ld		(var_cuentas_gra),hl
		xor		a
		ld		(var_cuentas_peq),a
		
STRIG_DE_MENU:
		
		xor		a
		call	.SUBRUTINA_DE_TRIG
		ld		a,1
		call	.SUBRUTINA_DE_TRIG
		ld		a,2
		call	.SUBRUTINA_DE_TRIG	
		ld		a,4														
		call	SNSMAT
		bit		2,a
		jp		z,CODIGO
				
		ld		de,1
		ld		hl,(var_cuentas_gra)
		or		a
		adc		hl,de
		
		ld		(var_cuentas_gra),hl
		ld		a,h
		cp		230
		jp		z,.SEMI_CUENTA
			
		jp		STRIG_DE_MENU

.SEMI_CUENTA:

		ld		h,0
		ld		l,0
		
		ld		(var_cuentas_gra),hl

		ld		a,(var_cuentas_peq)
		inc		a
		ld		(var_cuentas_peq),a
		cp		4
		jp		z,VAMOS_A_CONOCER_LA_HISTORIA
		jp		STRIG_DE_MENU
		
.SUBRUTINA_DE_TRIG:
		
		CALL	GTTRIG
		
		cp		255
		jr.		z,SELECCIONES
		
		ret
		
SELECCIONES:		

		di
		call	stpmus													; paramos la antigua musica
		ei
		
		ld		a,1
		ld		(que_musica_7),a
		
		ld		a,6
        call	EL_7000_7
	
		DI
		call	strmus													;iniciamos la música de juego
		EI
		
		ld		a,16
        call	EL_7000_7

		ld		a,7
		ld		c,1
		call	ayFX_INIT
		
		pop		af														;sacamos de la pila el valor de un call que no tendrá ret

		ld		a,16
		ld		(mosca_x_objetivo),a
		ld		a,135
		ld		(mosca_y_objetivo),a
		ld		a,255
		ld		(var_cuentas_peq),a

SELECCIONES_PRIMER_MOVIMIENTO:

		ld		a,2
		ld		(direccion_scroll_horizontal),a		

		ld		a,(var_cuentas_peq)										;var_cuentas_peq tendrá el control del número a meter en el registro 23 para el scroll

		call	SCROLL_HORIZONTAL_7
			
		call	PARADA_7
								
		ld		a,(var_cuentas_peq)
		cp		195
		jr.		nz,SELECCIONES_PRIMER_MOVIMIENTO
				
		ld		iy,cuadrado_que_limpia_1
		call	COPY_A_GUSTO_7
		
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,10000000b												;ESTRUCTURA DE CUADRADO RELLENO
		ld		(ix+14),a
					
		ld		hl,datos_del_copy
		call	DoCopy_7
		call	VDP_LISTO_7
		
SELECCIONES_PRIMER_MOVIMIENTO_1:

		ld		a,2
		ld		(direccion_scroll_horizontal),a		

		ld		a,(var_cuentas_peq)										;var_cuentas_peq tendrá el control del número a meter en el registro 23 para el scroll

		call	SCROLL_HORIZONTAL_7
			
		call	PARADA_7
								
		ld		a,(var_cuentas_peq)
		cp		185
		jr.		nz,SELECCIONES_PRIMER_MOVIMIENTO_1
		

		
		ld		a,(idioma)
		cp		1
		jr.		z,CANT_JUGADORES_INGLES

CANT_JUGADORES_ESPANOL:

		ld		iy,copia_1_o_2_jugadores
		call	COPY_A_GUSTO_7
		
		jr.		ZOOM_PARA_VER_LA_PRIMERA_PREGUNTA

CANT_JUGADORES_INGLES:

		ld		iy,copia_1_or_2_players
		call	COPY_A_GUSTO_7
		
ZOOM_PARA_VER_LA_PRIMERA_PREGUNTA:
	
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7
				
		ld		a,184
		ld		(var_cuentas_peq),a

SELECCIONES_SEGUNDO_MOVIMIENTO:
		
		ld		a,1
		ld		(direccion_scroll_horizontal),a
		
		ld		a,(var_cuentas_peq)										;var_cuentas_peq tendrá el control del número a meter en el registro 23 para el scroll
			
		call	SCROLL_HORIZONTAL_7		
		call	PARADA_7
		
		ld		iy,cuadrado_que_limpia_2
		call	COPY_A_GUSTO_7
		
		ld		bc,(var_cuentas_gra)
		ld		(ix+6),c												;y inicio linea
		ld		(ix+7),b
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,10000000b
		ld		(ix+14),a												;especificamos la linea

		
		ld		hl,datos_del_copy
		call	PARADA_7
		call	DoCopy_7
		call	VDP_LISTO_7
						
		ld		a,(var_cuentas_peq)
		cp		200
		jr.		nz,SELECCIONES_SEGUNDO_MOVIMIENTO
		
		ld		a,1
		ld		(cantidad_de_jugadores),a
			
STICK_STRIG_DE_CANTIDAD_DE_JUGADORES:
		
		ld		a,1
		ld		(suena_direccion),a
		
		xor		a
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		ld		a,1
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		ld		a,2
		call	.SUBRUTINA_DE_STICK	
		jp		STICK_STRIG_DE_CANTIDAD_DE_JUGADORES

.SUBRUTINA_DE_STICK:
		
		call	GTSTCK				
		cp		7
		jr		z,UN_JUGADOR
		cp		3
		jp		z,DOS_JUGADORES
		
		xor		a
		ld		(suena_direccion),a
				
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		nz,DOS_JUGADORES
		
UN_JUGADOR:

		ld		a,16
		ld		(mosca_x_objetivo),a
				
		ld		a,(suena_direccion)
		cp		1
		call	z,SUENA_DIRECCION
		
		ld		a,1
		ld		(cantidad_de_jugadores),a

SELECCIONA_ESO:
		
		xor		a
		call	GTTRIG
		cp		$FF
		jp		z,SELECCION_DE_ESTANDARTE

		ld		a,1
		call	GTTRIG
		cp		$FF
		jp		z,SELECCION_DE_ESTANDARTE

		ld		a,2
		call	GTTRIG
		cp		$FF
		jp		z,SELECCION_DE_ESTANDARTE
							
		ret
				
DOS_JUGADORES:

		ld		a,124
		ld		(mosca_x_objetivo),a

		ld		a,(suena_direccion)
		cp		1
		call	z,SUENA_DIRECCION
				
		ld		a,2
		ld		(cantidad_de_jugadores),a
		
		jp		SELECCIONA_ESO

SUENA_DIRECCION:

		ld		a,16
        call	EL_7000_7

		ld		a,6
		ld		c,1
		call	ayFX_INIT
		
		RET
		
SELECCION_DE_ESTANDARTE:

		ld		a,10
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a		
		ld		a,16
        call	EL_7000_7

		ld		a,7
		ld		c,0
		call	ayFX_INIT
		
		pop		af														;sacamos el dato acumulado por call anteriormente para que no crezca la pila
		
		ld		a,(idioma)
		cp		1
		jp		z,.ESTANDARTE_EN_INGLES

.ESTANDARTE_EN_CASTELLANO:
		
		ld		iy,copia_estandarte
		jp		.CONTINUA_SELECCION_DE_ESTANDARTE

.ESTANDARTE_EN_INGLES:

		ld		iy,copia_banner

.CONTINUA_SELECCION_DE_ESTANDARTE:
		
		call	COPY_A_GUSTO_7

		ld		a,10010000b
		ld		(ix+14),a
		call	PARADA_7
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_dibujos_estandartes_1
		call	COPY_A_GUSTO_7

		ld		hl,datos_del_copy
		call	DoCopy_7
		
		xor		a														;le damos al estandarte_1 el valor de 0 para que no tenga conflictos curante la selcción
		ld		(estandarte_1),a
		
SELECCION_DE_ESTANDARTE_DOS:		
		
		ld		a,(var_cuentas_peq)										;var_cuentas_peq tendrá el control del número a meter en el registro 23 para el scroll
		
		call	SCROLL_HORIZONTAL_7	
		call	PARADA_7
		
		ld		a,(var_cuentas_peq)
		cp		250
		jp		nz,SELECCION_DE_ESTANDARTE_TRES
		
		ld		iy,copia_dibujos_estandartes_2
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		iy,copia_p1
		call	COPY_A_GUSTO_7		
		ld		a,10010000b
		ld		(ix+14),a		
		ld		hl,datos_del_copy
		call	DoCopy_7
				
SELECCION_DE_ESTANDARTE_TRES:
							
		ld		a,(var_cuentas_peq)
		cp		9
		jp		nz,SELECCION_DE_ESTANDARTE_DOS
		
		ld		a,1
		ld		(estandarte),a
		

		ld		a,1
		ld		(turno),a
		
		call	STICK_STRIG_DE_ESTANDARTE
		ld		a,(estandarte)
		ld		(estandarte_1),a
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,SELECCION_DE_PROTA

		ld		a,2
		ld		(turno),a
		
		ld		a,(estandarte_1)
		ld		de,POINT_ESTANDARTE_ESCOGIDO_plus
		call	lista_de_opciones_7
				
		ld		a,10010001b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
						
		ld		iy,copia_p2
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		a,(estandarte_1)
		cp		1
		jp		z,SELECCION_DE_ESTANDARTE_CUATRO

		ld		a,15
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a
				
		ld		a,1
		ld		(estandarte),a
		jp		SELECCION_DE_ESTANDARTE_CINCO

SELECCION_DE_ESTANDARTE_CUATRO:
				
		ld		a,2
		ld		(estandarte),a
		ld		a,53
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a
				
SELECCION_DE_ESTANDARTE_CINCO:

		ld		a,30
		ld		(ralentizando),a
		call	RALENTIZA_7		
		call	STICK_STRIG_DE_ESTANDARTE

		ld		a,(estandarte)
		ld		de,POINT_ESTANDARTE_ESCOGIDO_plus
		call	lista_de_opciones_7
				
		ld		a,10010001b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
						
		ld		a,(estandarte)
		ld		(estandarte_2),a
		jp		SELECCION_DE_PROTA
		
STICK_STRIG_DE_ESTANDARTE:
		
		call	SELECCION_DE_DOS_CEROS
		ld		a,(anterior_valor)
		cp		1
		jp		z,STICK_STRIG_DE_ESTANDARTE
		
		xor		a
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		ld		a,(turno)
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		jp		STICK_STRIG_DE_ESTANDARTE

.SUBRUTINA_DE_STICK:

		call	GTSTCK

		cp		1
		jp		z,ESTANDARTE_ARRIBA
		cp		5
		jp		Z,ESTANDARTE_ABAJO	
		cp		7
		jp		z,ESTANDARTE_DE_MENOS
		cp		3
		jp		z,ESTANDARTE_DE_MAS

		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI
		
ESTANDARTE_ARRIBA:

		ld		a,(estandarte)
		cp		7
		jp		c,PARPADEO_ESTANDARTE
		sub		a,4
		ld		(estandarte),a
		
		ld		b,a

		call	SUENA_DIRECCION
		
		ld		a,(estandarte_1)
		cp		b
		jp		nz,PARPADEO_ESTANDARTE
		
		ld		a,(estandarte)
		add		4
		ld		(estandarte),a
		
		jp		PARPADEO_ESTANDARTE
		
ESTANDARTE_ABAJO:

		call	SUENA_DIRECCION

		ld		a,(estandarte)
		cp		7
		jp		nc,PARPADEO_ESTANDARTE
		cp		4
		jp		nc,.POSICION_DOS_ABAJO

		ld		a,(estandarte_1)
		cp		7
		jp		z,.POSICION_DOS_ABAJO
		ld		a,7
		jp		.ESTANDARTE_ABAJO_SIGUE

.POSICION_DOS_ABAJO:		

		call	SUENA_DIRECCION

		ld		a,(estandarte_1)
		cp		8
		jp		nz,.ESTANDARTE_ABAJO_PRE_SIGUE
		ld		a,7
		jp		.ESTANDARTE_ABAJO_SIGUE
		
.ESTANDARTE_ABAJO_PRE_SIGUE

		call	SUENA_DIRECCION

		ld		a,8
		
.ESTANDARTE_ABAJO_SIGUE:		

		ld		(estandarte),a
		jp		PARPADEO_ESTANDARTE
		
ESTANDARTE_DE_MENOS:
		
		ld		a,(estandarte_1)
		cp		1
		jp		nz,.ESTANDARTE_DE_MENOS_CERO
		ld		a,(estandarte)
		cp		2
		jp		z,PARPADEO_ESTANDARTE
	
.ESTANDARTE_DE_MENOS_CERO:
	
		call	SUENA_DIRECCION

		ld		a,(estandarte_1)
		cp		7
		jp		nz,.ESTANDARTE_DE_MENOS_UNO
		ld		a,(estandarte)
		cp		8
		jp		z,PARPADEO_ESTANDARTE
		
.ESTANDARTE_DE_MENOS_UNO:
		
		ld		a,(estandarte)
		cp		1
		jp		Z,PARPADEO_ESTANDARTE
		cp		7
		jp		Z,PARPADEO_ESTANDARTE
		dec		a
		ld		b,a
		ld		a,(estandarte_1)
		cp		b
		jp		nz,.ESTANDARTE_DE_MENOS_DOS
		
		ld		a,(estandarte)
		dec		a
		ld		(estandarte),a
		
.ESTANDARTE_DE_MENOS_DOS:

		ld		a,(estandarte)
		dec		a
		ld		(estandarte),a
		
.ESTANDARTE_DE_MENOS_TRES:
		
		jp		PARPADEO_ESTANDARTE
		
ESTANDARTE_DE_MAS:
		
		ld		a,(estandarte_1)
		cp		6
		jp		nz,.ESTANDARTE_DE_MAS_CERO
		
		ld		a,(estandarte)
		cp		5
		jp		z,PARPADEO_ESTANDARTE
	
.ESTANDARTE_DE_MAS_CERO:
	
		call	SUENA_DIRECCION

		ld		a,(estandarte_1)
		cp		8
		jp		nz,.ESTANDARTE_DE_MAS_UNO
		ld		a,(estandarte)
		cp		7
		jp		z,PARPADEO_ESTANDARTE
		
.ESTANDARTE_DE_MAS_UNO:

		ld		a,(estandarte)
		cp		6
		jp		Z,PARPADEO_ESTANDARTE
		cp		8
		jp		Z,PARPADEO_ESTANDARTE
		inc		a
		ld		b,a
		ld		a,(estandarte_1)
		cp		b
		jp		nz,.ESTANDARTE_DE_MAS_DOS
		
		ld		a,(estandarte)
		inc		a
		ld		(estandarte),a
		
.ESTANDARTE_DE_MAS_DOS:

		ld		a,(estandarte)
		inc		a
		ld		(estandarte),a

PARPADEO_ESTANDARTE:

		ld		a,1
		ld		(anterior_valor),a
		ld		a,3
		ld		(ralentizando),a
		call	RALENTIZA_7
		
		ld		a,(estandarte)		
		ld 		de,POINT_DE_ESTANDARTE
		jp		lista_de_opciones_7
		
POINT_MSX:

		ld		a,15
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a
		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI
		
POINT_ATARI:

		ld		a,53
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a

		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI

POINT_AMSTRAD:

		ld		a,97
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a
		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI

POINT_COMMODORE:

		ld		a,136
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a
		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI

POINT_DRAGON:

		ld		a,177
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a
		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI

POINT_SPECTRUM:

		ld		a,219
		ld		(mosca_x_objetivo),a
		ld		a,174
		ld		(mosca_y_objetivo),a	
		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI

POINT_ACORN:

		ld		a,97
		ld		(mosca_x_objetivo),a
		ld		a,198
		ld		(mosca_y_objetivo),a
		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI

POINT_ORIC:

		ld		a,136
		ld		(mosca_x_objetivo),a
		ld		a,198
		ld		(mosca_y_objetivo),a
		jp		TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI

SELECCION_DE_DOS_CEROS:

		xor		a
		call	GTSTCK
		cp		0
		ret		nz
		ld		a,1
		call	GTSTCK
		cp		0
		ret		nz
		ld		a,2
		call	GTSTCK
		cp		0
		ret		nz		
		ld		(anterior_valor),a
		
		ret
		
TODOS_LOS_PARPADEOS_DE_ESTANDARTE_ACABAN_AQUI:
						
		xor		a
		call	GTTRIG
		cp		$FF
		jp		z,FINAL_SELECCION_ESTANDARTE

		ld		a,(turno)
		call	GTTRIG
		cp		$FF
		jp		z,FINAL_SELECCION_ESTANDARTE
									
		ret

FINAL_SELECCION_ESTANDARTE:

		pop		af														;sacamos el dato de la pila acumulado por un call sin ret

		ld		a,16
        call	EL_7000_7
		
		ld		a,7
		ld		c,1
		call	ayFX_INIT


			
		ld		c,170
		ld		b,0
		ld		(ix+6),c
		ld		(ix+7),b		
		ld		a,10010000b
		ld		(ix+14),a
				
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		iy,copia_estandartes_a_salvo							;copia los estandartes en la página 3 para luego utilizarlos
		call	COPY_A_GUSTO_7
		
		ld		a,10010000b
		ld		(ix+14),a
		
		call	PARADA_7
		ld		hl,datos_del_copy
		call	DoCopy_7


		ret
		
SELECCION_DE_PROTA:

		ld		a,49
		ld		(mosca_x_objetivo),a
		ld		a,94
		ld		(mosca_y_objetivo),a
				
		ld		a,50
		ld		(ralentizando),a
		call	RALENTIZA_7
		
		ld		hl,TITULO_FADE_OUT										;colocamos el lector al comienzo de la secuencia de TITULO EN FADE OUT de la paleta
		call	FADE_7
		
		xor		a
		ld		(el_menu_baila),a
				
		di
		
		ld		a,#C3													;#c3 es el código binario de jump (jp)
		ld		[H.KEYI],a												;metemos en H.TIMI ese jp
				
		xor		a														;var_cuentas_peq tendrá el control del número a meter en el registro 23 para el scroll
			
																		;desconectamos las interrupciones
		out		(#99),a													;apuntamos el dato a poner en el registro
		
		inc		a
		ld		(var_cuentas_peq),a
		
		ld		a,23+128												;cargamos el valor de registro con el bit 8 establecido (+128)
		ei																;contectamos las interrupciones que se conectarán después de la siguiente orden
		out		(#99),a													;apuntamos al registro adecuado (en este caso el 23 para el scroll)

		ei
		
		ld		a,0														;set page 0
		call	setpage_7
				
		call	LIMPIA_PANTALLA_0_7
		call	LIMPIA_PANTALLA_2_7
		
		ld		a,10010000b
		ld		(ix+14),a
										
		ld		a,(idioma)
		cp		1
		jp		z,ESCRIBE_HERO

ESCRIBE_HEROE:

		ld		iy,copia_heroe
		jp		SELECCION_DE_PROTA_DOS

ESCRIBE_HERO:

		ld		iy,copia_hero

SELECCION_DE_PROTA_DOS:
				
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_protagonistas
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy
		call	DoCopy_7
				
		ld		hl,PROTAS_FADE_IN										;colocamos el lector al comienzo de la secuencia de TITULO EN FADE IN de la paleta
		call	FADE_7
		
		xor		0
		ld		(personaje_1),a
		ld		a,1
		ld		(personaje),a
				
		ld		iy,copia_p1
		call	COPY_A_GUSTO_7
		
		ld		c,44
		ld		b,0
		ld		(ix+4),c
		ld		(ix+5),b
		
		ld		c,86
		ld		b,0
		ld		(ix+6),c
		ld		(ix+7),b
		
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		a,1
		ld		(turno),a
		call	SELECCIONAMOS_PROTA
		
		ld		a,(personaje)
		ld		(personaje_1),a
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,SELECCION_DE_NIVEL

		ld		a,2
		ld		(turno),a
		
		ld		a,(personaje_1)
		ld		de,POINT_DE_PROTA_plus
		call	lista_de_opciones_7
				
		ld		a,10010011b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
				
		ld		iy,copia_p2
		
		call	COPY_A_GUSTO_7
		
		ld		c,44
		ld		b,0
		ld		(ix+4),c
		ld		(ix+5),b
		
		ld		c,86
		ld		b,0
		ld		(ix+6),c
		ld		(ix+7),b


		ld		a,10010000b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
	

		ld		a,49
		ld		(mosca_x_objetivo),a
				
		ld		a,1
		ld		(personaje),a
		ld		b,a
		ld		a,(personaje_1)
		cp		b
		jp		nz,SELECCION_DE_PROTA_TRES

		ld		a,40
		ld		(ralentizando),a
		call	RALENTIZA_7
				
		ld		a,2
		ld		(personaje),a

		ld		a,90
		ld		(mosca_x_objetivo),a
				
SELECCION_DE_PROTA_TRES:
		
		ld		a,30
		ld		(ralentizando),a
		call	RALENTIZA_7
			
		call	SELECCIONAMOS_PROTA

		ld		a,(personaje)
		ld		de,POINT_DE_PROTA_plus
		call	lista_de_opciones_7
				
		ld		a,10010011b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
				
		ld		a,(personaje)
		ld		(personaje_2),a	
			
		jp		SELECCION_DE_NIVEL

SELECCIONAMOS_PROTA:
		
		ld		a,3
		ld		(ralentizando),a
		call	RALENTIZA_7
		
STICK_STRIG_DE_PROTA:

		call	SELECCION_DE_DOS_CEROS
		ld		a,(anterior_valor)
		cp		1
		jp		z,STICK_STRIG_DE_PROTA
				
		xor		a
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		ld		a,(turno)
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		jp		STICK_STRIG_DE_PROTA

.SUBRUTINA_DE_STICK:

		call	GTSTCK
		cp		7
		jp		z,PROTA_DE_MENOS
		cp		3
		jp		z,PROTA_DE_MAS

		jp		TODOS_LOS_PARPADEOS_DE_PROTA_ACABAN_AQUI
						
PROTA_DE_MENOS:
		
		call	SUENA_DIRECCION

		ld		a,(personaje_1)
		cp		1
		jp		nz,.PROTA_DE_MENOS_UNO
		ld		a,(personaje)
		cp		2
		jp		z,PARPADEO_PROTA
			
.PROTA_DE_MENOS_UNO:
		
		ld		a,(personaje)
		cp		1
		jp		Z,PARPADEO_PROTA
		dec		a
		ld		b,a
		ld		a,(personaje_1)
		cp		b
		jp		nz,.PROTA_DE_MENOS_DOS
		
		ld		a,(personaje)
		dec		a
		ld		(personaje),a
		
.PROTA_DE_MENOS_DOS:

		ld		a,(personaje)
		dec		a
		ld		(personaje),a
				
		jp		PARPADEO_PROTA
		
PROTA_DE_MAS:

		call	SUENA_DIRECCION
		
		ld		a,(personaje_1)
		cp		4
		jp		z,.PROTA_DE_MAS_UNO
		
		ld		a,(personaje)
		cp		4
		jp		z,PARPADEO_PROTA
		
		jp		.PROTA_DE_MAS_UNO_Y_MEDIO
			
.PROTA_DE_MAS_UNO:

		ld		a,(personaje)
		cp		3
		jp		Z,PARPADEO_PROTA

.PROTA_DE_MAS_UNO_Y_MEDIO:
		
		inc		a
		ld		b,a
		ld		a,(personaje_1)
		cp		b
		jp		nz,.PROTA_DE_MAS_DOS
		
		ld		a,(personaje)
		inc		a
		ld		(personaje),a
		
.PROTA_DE_MAS_DOS:

		ld		a,(personaje)
		inc		a
		ld		(personaje),a

PARPADEO_PROTA:

		ld		a,1
		ld		(anterior_valor),a
		ld		a,3
		ld		(ralentizando),a
		call	RALENTIZA_7
		
		ld		a,(personaje)		
		ld 		de,POINT_DE_PROTA
		jp		lista_de_opciones_7
		
POINT_NATPU:

		ld		a,49
		ld		(mosca_x_objetivo),a
		jp		TODOS_LOS_PARPADEOS_DE_PROTA_ACABAN_AQUI
		
POINT_FERGAR:

		ld		a,90
		ld		(mosca_x_objetivo),a

		jp		TODOS_LOS_PARPADEOS_DE_PROTA_ACABAN_AQUI

POINT_CRISRA:

		ld		a,130
		ld		(mosca_x_objetivo),a

		jp		TODOS_LOS_PARPADEOS_DE_PROTA_ACABAN_AQUI

POINT_VICMAR:

		ld		a,173
		ld		(mosca_x_objetivo),a

		jp		TODOS_LOS_PARPADEOS_DE_PROTA_ACABAN_AQUI

POINT_NATPU_plus:

		ld		iy,copia_natpu
		call	COPY_A_GUSTO_7

		ret
		
POINT_FERGAR_plus:

		ld		iy,copia_fergar
		call	COPY_A_GUSTO_7

		ret
		
POINT_CRISRA_plus:

		ld		iy,copia_crisra
		call	COPY_A_GUSTO_7

		ret
		
POINT_VICMAR_plus:
		
		ld		iy,copia_vicmar
		call	COPY_A_GUSTO_7

		ret
		
TODOS_LOS_PARPADEOS_DE_PROTA_ACABAN_AQUI:
										
		xor		a
		call	GTTRIG
		cp		$FF
		jp		z,FINAL_SELECCION_PROTA

		ld		a,(turno)
		call	GTTRIG
		cp		$FF
		jp		z,FINAL_SELECCION_PROTA
					
		ret

FINAL_SELECCION_PROTA:

		pop		af	

		ld		a,16
        call	EL_7000_7
	
		ld		a,7
		ld		c,1
		call	ayFX_INIT
				
		ret

SELECCION_DE_NIVEL:
		
		ld		a,1														; por si la partida es de un jugador le ponemos el nivel 1 de comienzo
		ld		(nivel),a
		ld		(nivel_2),a
		
		ld		hl,PROTAS_FADE_OUT										;colocamos el lector al comienzo de la secuencia de TITULO EN FADE OUT de la paleta
		call	FADE_7
		ld		a,(cantidad_de_jugadores)								; Si es partida de un jugador vamos a la partida
		cp		1
		jp		z,FINAL_DE_SELECCION

		call	LIMPIA_PANTALLA_0_7
			
		ld		a,(idioma)
		cp		2
		jp		z,.CASTELLANO

.INGLES:
			
		ld		iy,copia_level
		
		jp		.COMUN_DE_IDIOMA
								
.CASTELLANO:
		
		ld		iy,copia_nivel
				
.COMUN_DE_IDIOMA:

		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
			
		ld		iy,copia_uno
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_dos
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_tres
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		a,59
		ld		(mosca_y_objetivo),a
		ld		a,77
		ld		(mosca_x_objetivo),a	
		
		ld		hl,MENU_FADE_IN											;colocamos el lector al comienzo de la secuencia de TITULO EN FADE IN de la paleta
		call	FADE_7
		
		ld		a,1
		ld		(nivel_2),a
		
STICK_STRIG_DE_NIVEL:

		call	SELECCION_DE_DOS_CEROS
		ld		a,(anterior_valor)
		cp		1
		jp		z,STICK_STRIG_DE_NIVEL
				
		xor		a
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		ld		a,1
		call	.SUBRUTINA_DE_STICK	
		ld		a,2
		call	.SUBRUTINA_DE_STICK										;esto carga un dato en la pila que si no se usa ret, habrá que sacar manualmente
		jp		STICK_STRIG_DE_NIVEL

.SUBRUTINA_DE_STICK:

		call	GTSTCK
		cp		1
		jp		z,NIVEL_DE_MENOS
		cp		5
		jp		z,NIVEL_DE_MAS

		jp		TODOS_LOS_PARPADEOS_DE_NIVEL_ACABAN_AQUI
						
NIVEL_DE_MENOS:
		
		call	SUENA_DIRECCION

		ld		a,(nivel_2)
		cp		1
		jp		z,TODOS_LOS_PARPADEOS_DE_NIVEL_ACABAN_AQUI
			
.NIVEL_DE_MENOS_UNO:
		
		ld		a,(nivel_2)
		dec		a
		ld		(nivel_2),a
						
		jp		PARPADEO_NIVEL
		
NIVEL_DE_MAS:

		call	SUENA_DIRECCION
		
		ld		a,(nivel_2)
		cp		3
		jp		z,TODOS_LOS_PARPADEOS_DE_NIVEL_ACABAN_AQUI
			
.NIVEL_DE_MAS_UNO:

		ld		a,(nivel_2)
		inc		a
		ld		(nivel_2),a
						
PARPADEO_NIVEL:

		ld		a,1
		ld		(anterior_valor),a
		
		ld		a,(nivel_2)
		ld 		de,POINT_DE_NIVEL
		jp		lista_de_opciones_7
		
POINT_NIVEL_UNO:

		ld		a,77
		ld		(mosca_x_objetivo),a
		ld		a,59
		ld		(mosca_y_objetivo),a
				
		jp		TODOS_LOS_PARPADEOS_DE_NIVEL_ACABAN_AQUI
		
POINT_NIVEL_DOS:

		ld		a,182
		ld		(mosca_x_objetivo),a
		ld		a,101
		ld		(mosca_y_objetivo),a

		jp		TODOS_LOS_PARPADEOS_DE_NIVEL_ACABAN_AQUI

POINT_NIVEL_TRES:

		ld		a,43
		ld		(mosca_x_objetivo),a
		ld		a,137
		ld		(mosca_y_objetivo),a

		jp		TODOS_LOS_PARPADEOS_DE_NIVEL_ACABAN_AQUI
		
TODOS_LOS_PARPADEOS_DE_NIVEL_ACABAN_AQUI:
										
		xor		a
		call	GTTRIG
		cp		$FF
		jp		z,FINAL_SELECCION_NIVEL

		ld		a,1
		call	GTTRIG
		cp		$FF
		jp		z,FINAL_SELECCION_NIVEL

		ld		a,2
		call	GTTRIG
		cp		$FF
		jp		z,FINAL_SELECCION_NIVEL
					
		ret

FINAL_SELECCION_NIVEL:

		pop		af	

		ld		a,16
        call	EL_7000_7
	
		ld		a,7
		ld		c,1
		call	ayFX_INIT

		ld		hl,MENU_FADE_OUT										;colocamos el lector al comienzo de la secuencia de TITULO EN FADE OUT de la paleta
		call	FADE_7
										
FINAL_DE_SELECCION:
										
		ld		a,0
		ld		(mosca_activa),a
		call	LIMPIA_PANTALLA_0_7

		di
		call	stpmus													;paramos la música
		ei
		
CARGAMOS_EL_BANCO_DEL_JUEGO:		
		
		ld      a, 1
		ld      [ACPAGE],a              								;set page x,0
		
		ld		a,5
        call	EL_7000_7

PREPARANDO_IMAGEN_DE_LA_PARTIDA:

		ld      a, 0
		ld      [ACPAGE],a              								;set page x,0	
			
		ld		hl,FONDO_ESTRUCTURA_1									;carga gráficos fondo parte 1
		ld		de,#0000
		ld		bc,16144
		call	LDIRVM
		
		ld		a,6
        call	EL_7000_7
					
		ld		hl,FONDO_ESTRUCTURA_2									;carga gráficos fondo parte 2
		ld		de,#3F10
		ld		bc,10992
		call	LDIRVM
		

		
PINTA_LOS_ESTANDARTES_ADECUADOS:

		ld		iy,copia_todos_estandartes								; los copia a salvo en page 3 fuera de vista
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		a,(estandarte_1)
		ld		de, POINT_ESTANDARTE_ESCOGIDO
		call	lista_de_opciones_7

		ld		a,10010000b
		ld		(ix+14),a

		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,CARGAMOS_EN_VRAM_EL_LABERINTO
		
		ld		a,(estandarte_2)
		ld		de, POINT_ESTANDARTE_ESCOGIDO
		call	lista_de_opciones_7

		ld		c,#cc
		ld		b,#00
		ld		(ix+4),c
		ld		(ix+5),b

		ld		hl,datos_del_copy
		call	DoCopy_7


CARGAMOS_EN_VRAM_EL_LABERINTO:
				
		ld		a,1
        call	EL_7000_7
			
		ld      a, 2
		ld      [ACPAGE],a              								;set page x,2
        				
		ld		hl,LABERINTO_1_1										;carga gráficos laberinto 1 parte 1
		ld		de,#0000
		ld		bc,16144
		call	LDIRVM
						
		ld		a,2
        call	EL_7000_7
				
		ld		hl,LABERINTO_1_2										;carga gráficos laberinto 1 parte 2
		ld		de,#3F10
		ld		bc,6678
		call	LDIRVM

		ld		de,PIEDRAS_RAMAS										; copiamos piedras y ramas
		ld		hl,copia_piedras_en_pantalla							; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_7
									
		ld      a, 3
		ld      [ACPAGE],a              								;set page x,3
		
		ld		a,3
        call	EL_7000_7
		
		ld		hl,LABERINTO_2_1										;carga gráficos laberinto 2 parte 1
		ld		de,#0000
		ld		bc,16144
		call	LDIRVM
		
		ld		a,4
        call	EL_7000_7
			
		ld		hl,LABERINTO_2_2										;carga gráficos laberinto 2 parte 2
		ld		de,#3F10
		ld		bc,257
		call	LDIRVM
				
COPIA_PROTAS_ADECUADOS:		
																		;copiaremos en la page 3 los protas adecuados

		ld		a,(personaje_1)
		ld		de,CARA_DE_PROTA_ESCOGIDA
		call	lista_de_opciones_7
		
		ld		hl,copia_prota_1_en_vram_7								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_7										;copiamos	

		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,MOSTRAMOS_POR_PRIMERA_VEZ_LOS_PROTAS


		ld		a,(personaje_2)
		ld		de,CARA_DE_PROTA_ESCOGIDA
		call	lista_de_opciones_7
		
		ld		hl,copia_prota_2_en_vram_7							;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_7									;copiamos	
		
		ld		a,(personaje_1)
		ld		(personaje),a

		ld      a, 0
		ld      [ACPAGE],a 												;set page x,0
		
		ld		a,(pagina_de_idioma)
        call	EL_7000_7
		
MOSTRAMOS_POR_PRIMERA_VEZ_LOS_PROTAS:
		
		ld		iy,copia_cara_neutra_jugador_1_7
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a
		ld		hl,datos_del_copy		
		call	DoCopy_7
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,CARGAMOS_DATOS_DEL_LABERINTO

		ld		iy,copia_cara_neutra_jugador_2_7
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy		
		call	DoCopy_7
		
		
				
CARGAMOS_DATOS_DEL_LABERINTO:

		ld		a,4
        call	EL_7000_7
								
		ld		hl,0													; ponemos todas las variables de objetos y mapa a 0
		ld		(posicion_en_mapa),hl
						
COMIENZA_EL_REINICIO_DE_VARIABLES:		
		
		ld		a,25
		ld		(var_cuentas_peq),a
		ld		de,posicion_en_mapa
		
REINICIA_VARIABLES:

		ld		hl,posicion_en_mapa

		ld		bc,1													
					
		ldir
		
		dec		a
		cp		0
		jp		nz,REINICIA_VARIABLES
				
		ld		de,posicion_en_mapa_1
		ld		hl,posicion_en_mapa
		ld		bc,19													
		ldir

		ld		de,posicion_en_mapa_2
		ld		hl,posicion_en_mapa
		ld		bc,19													
		ldir

		xor		a
		ld		(perro),a
		ld		(perro_1),a
		ld		(perro_2),a
		
COMIENZA_LIMPIEZA_MAPAS:
		
		ld		a,#ff
		ld		(act_mapa_1),a

		ld		de,act_mapa_1_1
		ld		hl,act_mapa_1
		ld		bc,899																		
		ldir

		ld		de,act_mapa_2
		ld		hl,act_mapa_1
		ld		bc,900													
		ldir
						
		xor		a
		ld		(set_page01),a							

		ld		a,53
        call	EL_7000_7
        
		call	CARGAMOS_OBJETOS_DE_LA_TIENDA
		
		ld		a,(pagina_de_idioma)
        call	EL_7000_7
						
DESCUBRIMOS_MAPA_Y_POSICION_DEPENDIENDO_DE_CANTIDAD_DE_JUGADORES_Y_NIVEL:

		call	DISSCR
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		nz,PREPARAMOS_PARA_2_JUGADORES

PREPARAMOS_PARA_1_JUGADOR:
		
		ld		iy,cuadrado_que_limpia_jugador_dos						;borramos contadores de jugador 2
		call	COPY_A_GUSTO_7
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a

		ld		hl,datos_del_copy		
		call	DoCopy_7
						
		ld		a,4
        call	EL_7000_7
		
NIVEL_1:

		ld		a,(codigo_activo)
		or		a
		jp		z,NIVEL_1_EN_PAGE_4

NIVEL_SEGUN_CODIGO:

		ld		a,(nivel)
		cp		1
		call	z,DECORADOS_NIVEL_1_POR_CODIGO
		cp		2
		call	z,DECORADOS_NIVEL_2_POR_CODIGO
		cp		3
		call	z,DECORADOS_NIVEL_3_POR_CODIGO
		cp		4
		call	z,DECORADOS_NIVEL_4_POR_CODIGO	
			
		ld		a,53
        call	EL_7000_7
										
		call	VARIABLES_DEL_JUGADOR_1_POR_CODIGO
		call	VARIABLES_DEL_JUGADOR_2_POR_CODIGO
		call	OBJETOS_DEL_JUGADOR_1_POR_CODIGO

		ld		bc,32													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa
		ld		hl,posicion_en_mapa_1
					
		ldir
		
		ld		a,(pagina_de_idioma)
        call	EL_7000_7
	
		jp		VOLVEMOS_A_PAGE_0
												
PREPARAMOS_PARA_2_JUGADORES:

		ld		a,(codigo_activo)
		or		a
		jp		z,DEFINIMOS_NIVEL		

		ld		a,53
        call	EL_7000_7
									
		call	VARIABLES_DEL_JUGADOR_1_POR_CODIGO
		call	OBJETOS_DEL_JUGADOR_1_POR_CODIGO
		call	VARIABLES_DEL_JUGADOR_2_POR_CODIGO
		call	OBJETOS_DEL_JUGADOR_2_POR_CODIGO

		ld		a,(turno)
		cp		2
		jp		z,VARIABLES_A_DOS
		
VARIABLES_A_UNO:

		ld		bc,32													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa
		ld		hl,posicion_en_mapa_1
					
		ldir
		
		jp		DEFINIMOS_NIVEL
		
VARIABLES_A_DOS:

		ld		bc,32													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa
		ld		hl,posicion_en_mapa_2
					
		ldir
				
DEFINIMOS_NIVEL:

		ld		a,19
        call	EL_7000_7
					
		ld		a,(nivel_2)
		cp		1
		jp		z,BUSCANDO_NIVEL_1
		cp		2
		jp		z,BUSCANDO_NIVEL_2
		cp		3
		jp		z,BUSCANDO_NIVEL_3
							
CARGA_LABERINTO:


		or		a
		ld		bc,990													;cargamos el laberinto en memoria
		ld		de,mapa_del_laberinto
					
		ldir
		
		ret
		
CARGA_DECORADOS:			
		
		or		a
		ld		bc,990													;cargamos los decorados del laberinto en memoria
		ld		de,decorados_laberinto
					
		ldir

		ret
		
CARGA_SUCESOS:
		
		or		a
		ld		bc,900													;cargamos los sucesos del laberinto en memoria
		ld		de,eventos_laberinto
					
		ldir
		
		ret
		
REGRESO:
				
		ld		a,(pagina_de_idioma)
        call	EL_7000_7
        
	; definimos salida y orientación
		
		xor		a
		ld		(patron_actual_cargado),a								;ponemos a 0 el patron de decorado que está cargado


				
		jp		VOLVEMOS_A_PAGE_0
		
ALEATORIA_DE_0_A_4:

		ld		a,r
		and		00000100b				
		ret
				
ALEATORIA_DE_0_A_5:

		ld		a,r
		and		00000101b				
		ret
				

				
PROTA_1:														

		ld		a,13
        call	EL_7000_7
		
		ld		de,COPIAMOS_CARAS_PROTA_1								;escojemos lo que hay que copiar
	
		ret
		
PROTA_2:														

		ld		a,13
        call	EL_7000_7
	
		ld		de,COPIAMOS_CARAS_PROTA_2								;escojemos lo que hay que copiar
		
		ret
		
PROTA_3:														

		ld		a,14
        call	EL_7000_7
		
		ld		de,COPIAMOS_CARAS_PROTA_3								;escojemos lo que hay que copiar

		ret
		
PROTA_4:														
		
		ld		a,14
        call	EL_7000_7
		
		ld		de,COPIAMOS_CARAS_PROTA_4								;escojemos lo que hay que copiar

		ret
		
POINT_TOCA_MSX:

		ld		iy,copia_msx
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_ATARI:

		ld		iy,copia_atari
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_AMSTRAD:

		ld		iy,copia_amstrad
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_COMODORE:

		ld		iy,copia_comodore
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_DRAGON:

		ld		iy,copia_dragon
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_SINCLAIR:

		ld		iy,copia_spectrum
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_ACORN:

		ld		iy,copia_acorn
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_ORIC:	

		ld		iy,copia_oric
		call	COPY_A_GUSTO_7
		
		ret

POINT_TOCA_MSX_plus:

		ld		iy,copia_msx_plus
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_ATARI_plus:

		ld		iy,copia_atari_plus
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_AMSTRAD_plus:

		ld		iy,copia_amstrad_plus
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_COMODORE_plus:

		ld		iy,copia_comodore_plus
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_DRAGON_plus:

		ld		iy,copia_dragon_plus
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_SINCLAIR_plus:

		ld		iy,copia_spectrum_plus
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_ACORN_plus:

		ld		iy,copia_acorn_plus
		call	COPY_A_GUSTO_7

		ret
		
POINT_TOCA_ORIC_plus:	

		ld		iy,copia_oric_plus
		call	COPY_A_GUSTO_7
		
		ret

POSICIONES_1:				dw	POSICION_1_1
							dw	POSICION_1_2
							dw	POSICION_1_3
							dw	POSICION_1_4
							dw	POSICION_1_1
							dw	POSICION_1_2
							dw	POSICION_1_3
							dw	POSICION_1_4
																											
VOLVEMOS_A_PAGE_0:

		ld		iy,copia_parte_page_1_a_page_2							; copia la page 1 a la page 2 para que no se vean difencias
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld      a, 0
		ld      [ACPAGE],a              								;set page x,1
																									
		ld		a,5
        call	EL_7000_7
					
		jp		BANCO_1_PAGINA_0_PARA_JUEGO


VAMOS_A_CONOCER_LA_HISTORIA:

		ld		hl,TITULO_FADE_OUT										;colocamos el lector al comienzo de la secuencia de TITULO EN FADE OUT de la paleta
		call	FADE_7

REPETIMOS:
		
		ld		a,8														;screen 8
		call	CHGMOD

		di
		call	stpmus													; paramos la antigua musica
		ei
		
;		ld		a,2
;		ld		(que_musica_7),a
			
;		ld		a,36
 ;       call	EL_7000_7
		
;		di
;		call	strmus
;		ei
		
		LD 		A,(RG8SAV)												; DESactivamos sprites
		or		00000010B
		LD 		(RG8SAV),a			
		OUT 	(#99),A		
		LD 		A,8+128		
		OUT 	(#99),A	
		
		ld		iy,cuadrado_que_limpia_2_pantallas_sc8					; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO_7
		ld		a,10000000b
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR_7
						
		xor		a
		ld		(el_menu_baila),a
		ld		(mosca_activa),a
		
		ld		a,(salto_historia)
		cp		1
		jp		z,.carga_final
		cp		2
		jp		z,.carga_creditos
		
.carga_presentacion:	

		ld		a,2
		ld		(que_musica_7),a
			
		ld		a,36
        call	EL_7000_7
		
		di
		call	strmus
		ei
		
		ld		a,(idioma)
		cp		1
		jp		z,.carga_presentacion_ingles
		LD		A,39
		jp		.a_cargar

.carga_presentacion_ingles:


		LD		A,82
		jp		.a_cargar
		
.carga_creditos:

		ld		a,2
		ld		(que_musica_7),a
			
		ld		a,36
        call	EL_7000_7
		
		di
		call	strmus
		ei
		
		LD		A,66
		jp		.a_cargar
		
.carga_final:

		ld		a,9
		ld		(que_musica_7),a
			
		ld		a,19
        call	EL_7000_7
		
		di
		call	strmus
		ei
		
		ld		a,(idioma)
		cp		1
		jp		z,.carga_final_ingles
		ld		a,57
		jp		.a_cargar

.carga_final_ingles:

		LD		A,91

.a_cargar:
		
		ld		(scroll_comic_page),a

		ld		a,44
		ld		(var_cuentas_peq),a										;var_cuentas_peq tendrá el control del número a meter en el registro 23 para el scroll

		ld		a,40
		ld		(var_cuentas_gra),a
		call	SECUENCIA_DE_CAMBIA_PAGE_PARA_SCROLL
		
		di																;desconectamos las interrupciones
		out		(#99),a
		ld		a,23+128												;cargamos el valor de registro con el bit 8 establecido (+128)
		ei																;contectamos las interrupciones que se conectarán después de la siguiente orden
		out		(#99),a
				
		ld		hl,COM_PRES1											;carga gráficos comic presentacion/despedida 1
		ld		de,#00000
		
.scroll_1:
		
		call	SECUENCIA_DE_PINTA_MAS_SCROLL
			
		push	bc
		ld		a,(limite_impresion_comic)
		ld		b,a
		ld		a,(var_cuentas_peq)
		cp		b
		pop		bc
		jp		z,.scroll_2
		jp		.scroll_1
		
.scroll_2:

		call	SECUENCIA_DE_CAMBIA_PAGE_PARA_SCROLL
		ld		hl,COM_PRES1											;carga gráficos comic presentacion 1
		ld		a,(scroll_comic_page)
		cp		49
		jp		z,.scroll_3
		cp		67
		jp		z,.scroll_3
		cp		80
		jp		z,.scroll_3
		cp		92
		jp		z,.scroll_3	
		cp		101
		jp		z,.scroll_3	
		jp		.scroll_1

.scroll_3:

		ld		a,255
		ld		(ralentizando),a
		
		
		call	RALENTIZA_7

		ld		a,9
        call	EL_7000_7
		
.scroll_4:
		
		ld		a,5														;screen 8
		call	CHGMOD

		di
		call	stpmus													; paramos la antigua musica
		ei
			
		call	ACTIVAMOS_SPRITES	
		
		DI
		
		LD 		A,(RG6SAV)												; Enable Line Interrupt: Set R#0 bit 4
		OR		00001110B
		and		11111110b
		LD 		(RG6SAV),a			
		OUT 	(#99),A		
		LD 		A,6+128		
		OUT 	(#99),A	
									
		ei
		
		ld		a,(salto_historia)
		cp		0
		jp		z,PREPARACION_DEL_MENU
		cp		1
		jp		z,PREPARAMOS_CREDITOS
		xor		a
		ld		(salto_historia),a
		jp		PREPARACION_DEL_MENU		

PREPARAMOS_CREDITOS:

		ld		a,2
		ld		(salto_historia),a
		jp		REPETIMOS
		
SECUENCIA_DE_PINTA_MAS_SCROLL:

		PUSH	HL
		PUSH	DE
		
		ld		bc,256
		call	LDIRVM
		
		ld		a,(var_cuentas_peq)
		
		di																;desconectamos las interrupciones
		out		(#99),a
		inc		a
		ld		(var_cuentas_peq),a
		
		ld		a,23+128												;cargamos el valor de registro con el bit 8 establecido (+128)
		ei																;contectamos las interrupciones que se conectarán después de la siguiente orden
		out		(#99),a

		ld		a,(salto_historia)
		cp		2
		jp		z,.MAS_RETARDO
		
		ld		a,3
		ld		(ralentizando),a
		call	RALENTIZA_7

.MAS_RETARDO:
		
		ld		a,8
		ld		(ralentizando),a
		call	RALENTIZA_7
		
		ld		bc,#100
		POP		HL
		ADC		HL,BC
		PUSH	HL
		pop		de
		pop		hl
		ADC		HL,BC
		
		xor		a
		CALL	GTTRIG
		cp		255
		jp		z,.EL_REGRESO											;volvemos al programa general

		ld		a,1
		CALL	GTTRIG
		cp		255
		jp		z,.EL_REGRESO		

		ld		a,2
		CALL	GTTRIG
		cp		255
		jp		z,.EL_REGRESO	
				
		RET
		
.EL_REGRESO:

		pop		af
		jp		REPETIMOS.scroll_4
		
SECUENCIA_DE_CAMBIA_PAGE_PARA_SCROLL:

		ld		a,(scroll_comic_page)
		inc		a
		ld		(scroll_comic_page),a
		
        call	EL_7000_7

		ld		a,(var_cuentas_peq)
		add		64
		ld		(limite_impresion_comic),a
		
		ret
						
CODIGO:

		di
		call	stpmus													; paramos la antigua musica
		ei
		
		ld		a,1
		ld		(que_musica_7),a
		
		ld		a,6
        call	EL_7000_7
		
		di
		call	strmus													;iniciamos la música de juego
		ei
		
		ld		a,16
        call	EL_7000_7
	
		ld		a,7
		ld		c,1
		call	ayFX_INIT
		
		pop		af														;sacamos de la pila el valor de un call que no tendrá ret

		ld		a,#5
		ld		(mosca_x_objetivo),a
		ld		a,#E0
		ld		(mosca_y_objetivo),a
		ld		a,255
		ld		(var_cuentas_peq),a

		ld		a,34
        call	EL_7000_7

		ld		de,LETRAS
		ld		hl,letras_a_page3										;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_7

		ld		iy,cuadrado_que_limpia_letras
		call	COPY_A_GUSTO_7	
		ld		a,8
		ld		(ix+12),a												;color
		ld		a,10000000b												;ESTRUCTURA DE CUADRADO RELLENO
		ld		(ix+14),a
						
		ld		hl,datos_del_copy
		call	DoCopy_7
		xor		a
		ld		(ix+12),a						
		ld		a,(idioma)
		cp		1
		jp		z,.INGLES

.CASTELLANO:
				
		ld		iy,copia_codigo
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a					
		ld		hl,datos_del_copy
		call	DoCopy_7
		call	VDP_LISTO_7
		
		jp		CODIGO_SCROLL_1

.INGLES:

		ld		iy,copia_code
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a							
		ld		hl,datos_del_copy
		call	DoCopy_7

		ld		iy,copia_code_la_e
		call	COPY_A_GUSTO_7
							
		ld		hl,datos_del_copy
		call	DoCopy_7
		call	VDP_LISTO_7
		
CODIGO_SCROLL_1:

		ld		a,2
		ld		(direccion_scroll_horizontal),a		

		ld		a,(var_cuentas_peq)										;var_cuentas_peq tendrá el control del número a meter en el registro 23 para el scroll

		call	SCROLL_HORIZONTAL_7
			
		call	PARADA_7
								
		ld		a,(var_cuentas_peq)
		cp		195
		jp		nz,CODIGO_SCROLL_1
				
				
		ld		a,(pagina_de_idioma)
        call	EL_7000_7
				
		ld		a,1
		ld		(var_cuentas_peq),a
		
		ld		iy,primera_letra_de_codigo
		call	COPY_A_GUSTO_7
		ld		iy,codigo_salve
		
ESCRIBIENDO_EL_TEXTO:

; acceso a las diferentes letras para escribir el código
		
		xor		a
		ld		(retroceso),a
		
		ld		a,2														
		call	SNSMAT
		bit		6,a
		jp		z,la_A

		ld		a,2														
		call	SNSMAT
		bit		7,a
		jp		z,la_B

		ld		a,3														
		call	SNSMAT
		bit		0,a
		jp		z,la_C

		ld		a,3														
		call	SNSMAT
		bit		1,a
		jp		z,la_D

		ld		a,3														
		call	SNSMAT
		bit		2,a
		jp		z,la_E

		ld		a,3														
		call	SNSMAT
		bit		3,a
		jp		z,la_F

		ld		a,3														
		call	SNSMAT
		bit		4,a
		jp		z,la_G

		ld		a,3														
		call	SNSMAT
		bit		5,a
		jp		z,la_H

		ld		a,3														
		call	SNSMAT
		bit		6,a
		jp		z,la_I

		ld		a,3														
		call	SNSMAT
		bit		7,a
		jp		z,la_J

		ld		a,4													
		call	SNSMAT
		bit		0,a
		jp		z,la_K

		ld		a,4														
		call	SNSMAT
		bit		1,a
		jp		z,la_L

		ld		a,4														
		call	SNSMAT
		bit		2,a
		jp		z,la_M

		ld		a,4														
		call	SNSMAT
		bit		3,a
		jp		z,la_N

		ld		a,4														
		call	SNSMAT
		bit		4,a
		jp		z,la_O

		ld		a,4														
		call	SNSMAT
		bit		5,a
		jp		z,la_P

		ld		a,7														
		call	SNSMAT
		bit		5,a
		jp		z,la_bs
						
		jp		ESCRIBIENDO_EL_TEXTO

FIN_LETRA:

		ld		a,(retroceso)
		cp		1
		jp		z,.RETROCESO
		
		ld		c,212
		ld		b,#03
		ld		(ix+2),c												
		ld		(ix+3),b
		
		ld		hl,datos_del_copy
		call	DoCopy_7	
		
		ld		a,16
        call	EL_7000_7
	
		ld		a,15
		ld		c,0
		call	ayFX_INIT
		
		ld		a,(pagina_de_idioma)
        call	EL_7000_7
		
		ld		a,(codiguin)
		ld		b,a
		ld		a,(iy)
		and		11110000b
		add		b
		ld		(iy),a
		
		ld		a,(var_cuentas_peq)
		bit		0,a
		jp		z,.ANTE_FIN_LETRAS
															
		ld		a,(iy)
[4]		rlc		a
		ld		(iy),a
		
		jp		.FIN_LETRAS

.RETROCESO:
		
		ld		a,(mosca_x_objetivo)
		sub		8
		ld		(mosca_x_objetivo),a

		ld		a,(ix+4)
		sub		8
		ld		(ix+4),a
		
		ld		a,16
        call	EL_7000_7
	
		ld		a,22
		ld		c,0
		call	ayFX_INIT
				
		ld		a,(pagina_de_idioma)
        call	EL_7000_7
        		
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a

		cp		26
		jp		z,.CAMBIO_DE_RENGLON_en_menos		
		cp		4
		jp		z,.ANADIDO_en_menos
		cp		8
		jp		z,.ANADIDO_en_menos		
		cp		12
		jp		z,.ANADIDO_en_menos		
		cp		16
		jp		z,.ANADIDO_en_menos
		cp		20
		jp		z,.ANADIDO_en_menos					
		cp		24
		jp		z,.ANADIDO_en_menos		
		cp		30
		jp		z,.ANADIDO_en_menos		
		cp		34
		jp		z,.ANADIDO_en_menos		
		cp		38
		jp		z,.ANADIDO_en_menos		
		cp		42
		jp		z,.ANADIDO_en_menos
		cp		46
		jp		z,.ANADIDO_en_menos
		cp		50
		jp		z,.ANADIDO_en_menos						
		jp		.Y_SI_ESTA_EN_OTRO_BYTE
				
.ANTE_FIN_LETRAS:

		inc		iy
		
.FIN_LETRAS:	
		
		ld		a,(var_cuentas_peq)
		inc		a
		ld		(var_cuentas_peq),a
		
		cp		27
		jp		z,.CAMBIO_DE_RENGLON
		cp		53
		jp		z,.FIN
		
		ld		a,(ix+4)
		add		8
		ld		(ix+4),a
		
		ld		a,(mosca_x_objetivo)
		add		8
		ld		(mosca_x_objetivo),a

		
		ld		a,(var_cuentas_peq)
		cp		5
		jp		z,.ANADIDO
		cp		9
		jp		z,.ANADIDO		
		cp		13
		jp		z,.ANADIDO		
		cp		17
		jp		z,.ANADIDO
		cp		21
		jp		z,.ANADIDO					
		cp		25
		jp		z,.ANADIDO		
		cp		31
		jp		z,.ANADIDO		
		cp		35
		jp		z,.ANADIDO		
		cp		39
		jp		z,.ANADIDO		
		cp		43
		jp		z,.ANADIDO
		cp		47
		jp		z,.ANADIDO
		cp		51
		jp		z,.ANADIDO						
		jp		.REPETIMOS

.ANADIDO_en_menos:

		ld		a,(ix+4)
		sub		8
		ld		(ix+4),a
		
		ld		a,(mosca_x_objetivo)
		sub		8
		ld		(mosca_x_objetivo),a

.Y_SI_ESTA_EN_OTRO_BYTE:

		ld		a,(var_cuentas_peq)
		bit		0,a
		jp		z,.ANTE_FIN_LETRAS_en_menos
		
				
		jp		.REPETIMOS

.ANTE_FIN_LETRAS_en_menos:

		dec		iy
		jp		.REPETIMOS
				
.ANADIDO:

		ld		a,(ix+4)
		add		8
		ld		(ix+4),a
		
		ld		a,(mosca_x_objetivo)
		add		8
		ld		(mosca_x_objetivo),a
		
		jp		.REPETIMOS
			
.CAMBIO_DE_RENGLON:

		ld		a,2
		ld		(ix+4),a
		ld		a,#f4
		ld		(ix+6),a
		
		ld		a,#5
		ld		(mosca_x_objetivo),a
		ld		a,#ef
		ld		(mosca_y_objetivo),a
		jp		.REPETIMOS
		
.CAMBIO_DE_RENGLON_en_menos:

		ld		a,250
		ld		(ix+4),a
		ld		a,#e4
		ld		(ix+6),a
		
		ld		a,#f9
		ld		(mosca_x_objetivo),a
		ld		a,#e0
		ld		(mosca_y_objetivo),a
		jp		.Y_SI_ESTA_EN_OTRO_BYTE
								
.REPETIMOS:		
		
		ld		a,15
		ld		(ralentizando),a
		call	RALENTIZA_7
		
		jp		ESCRIBIENDO_EL_TEXTO

.FIN:
		ld		ix,codigo_salve
		ld		a,(ix)
		or		a
		jp		z,NO_NOS_VAMOS		
		
		ld		ix,codigo_salve

		ld		a,(ix)
		ld		b,a
		ld		a,(ix+1)
		add		b
		ld		b,a
		ld		a,(ix+2)
		add		b
		ld		b,a
		ld		a,(ix+3)
		add		b
		ld		b,a
		ld		a,(ix+4)
		add		b
		ld		b,a
		ld		a,(ix+5)
		add		b
		ld		b,a
		ld		a,(ix+6)
		add		b
		ld		b,a
		ld		a,(ix+7)
		add		b
		ld		b,a
		ld		a,(ix+8)
		add		b
		ld		b,a
		ld		a,(ix+9)
		add		b
		ld		b,a
		ld		a,(ix+10)
		add		b
		ld		b,a
		ld		a,(ix+11)
		add		b
		ld		b,a
		ld		a,(ix+12)
		add		b
		ld		b,a
		ld		a,(ix+13)
		add		b
		ld		b,a
		ld		a,(ix+14)
		add		b
		ld		b,a
		ld		a,(ix+15)
		add		b
		ld		b,a
		ld		a,(ix+16)
		add		b
		ld		b,a
		ld		a,(ix+17)
		add		b
		ld		b,a
		ld		a,(ix+19)
		add		b
		ld		b,a
		ld		a,(ix+20)
		add		b
		ld		b,a
		ld		a,(ix+22)
		add		b
		ld		b,a
		ld		a,(ix+23)
		add		b
		ld		b,a
		ld		a,(ix+24)
		add		b
		ld		b,a
		ld		a,(ix+25)
		add		b
		push	af
		and		00011111b
		ld		b,a
		ld		a,(ix+18)
		and		00011111b
		cp		b
		jp		nz,NO_NOS_VAMOS
		
		pop		af

		and		11100000b
[5]		srl		a
		ld		b,a
		ld		a,(ix+21)
		and		00000111b
		cp		b		
		jp		z,NOS_VAMOS		

NO_NOS_VAMOS:

		ld		a,6
        call	EL_7000_7
	
		di
		call	stpmus
		ei
		
		ld		a,16
        call	EL_7000_7

		ld		a,18													; SONIDO DE GOLPE RECIBIDO CON PRIORIDAD 2
		ld		c,0
		call	ayFX_INIT

		ld		a,#6b
		ld		(mosca_x_objetivo),a
		ld		a,#09
		ld		(mosca_y_objetivo),a
		
		ld		iy,copia_error
		call	COPY_A_GUSTO_7
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		a,100
		ld		(ralentizando),a
		call	RALENTIZA_7

		ld		a,7
        call	EL_7000_7
	
		ld		hl,TITULO_FADE_OUT										;colocamos el lector al comienzo de la secuencia de TITULO EN FADE OUT de la paleta
		call	FADE_7
										

		
		ld		iy,BORRA_PANTALLA_1_7										;Borrando la2 página2 1-3 por si había restos
		call	COPY_A_GUSTO_7
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,10000000b												;ESTRUCTURA DE CUADRADO RELLENO
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
				
		ld		iy,cuadrado_que_limpia_page2_1
		call	COPY_A_GUSTO_7
		

					
		ld		hl,datos_del_copy
		call	DoCopy_7
		ld		iy,cuadrado_que_limpia_page2_2
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		ld		iy,cuadrado_que_limpia_page3_3
		call	COPY_A_GUSTO_7
		ld		hl,datos_del_copy
		call	DoCopy_7
						
		xor		a
		call	SCROLL_HORIZONTAL_7
						
		xor		a
		ld		(el_menu_baila),a
		
		ld		a,15
        call	EL_7000_7
		
		xor		a
		ld		(que_musica_7),a
		call	strmus
		
		jp		CARAMBALAN_STUDIOS_PRESENTA
		

NOS_VAMOS:

		di
		call	stpmus
		ei
		
		ld		a,1
		ld		(codigo_activo),a
		
		ld		a,16
        call	EL_7000_7

		ld		a,14													; SONIDO DE GOLPE RECIBIDO CON PRIORIDAD 2
		ld		c,0
		call	ayFX_INIT
				
		ld		a,100
		ld		(ralentizando),a
		call	RALENTIZA_7

		ld		a,(pagina_de_idioma)
        call	EL_7000_7
		
		ld		hl,TITULO_FADE_OUT										;colocamos el lector al comienzo de la secuencia de TITULO EN FADE OUT de la paleta
		call	FADE_7

		ld		iy,copia_estandartes_a_salvo							; los copia a salvo en page 3 fuera de vista
		call	COPY_A_GUSTO_7
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ld		a,0
		ld		(mosca_activa),a
		call	LIMPIA_PANTALLA_0_7

		xor		a
		ld		(posicion_en_mapa_1),a
		ld		bc,63													;salvamos las variables por si se quiere guardar partida
		ld		de,orientacion_del_personaje_1
		ld		hl,posicion_en_mapa_1
					
		ldir
										
ESCRIBIMOS_LAS_VARIABLES:
		
		ld		ix,codigo_salve
		
		;byte 1
		
		ld		a,(ix)
		and		00000011b
		ld		(turno),a
		ld		a,(ix)
[2]		srl		a		
		and		00000011b
		ld		(cantidad_de_jugadores),a
		ld		a,(ix)
[4]		srl		a		
		and		00000011b
		ld		(nivel_2),a
		ld		a,(ix)
[6]		srl		a		
		and		00000011b
		inc		a
		ld		(nivel),a

[2]		inc		ix
		
		;byte 3

		ld		a,(ix)
[2]		srl		a		
		and		00000011b
		inc		a
		ld		(personaje_1),a	

		inc		ix
		inc		ix
		inc		ix

		;byte 6

		ld		a,(ix)
[2]		srl		a		
		and		00000011b
		inc		a
		ld		(personaje_2),a	
				
		inc		ix
		inc		ix
		inc		ix
		inc		ix
		inc		ix
		inc		ix
		inc		ix
		inc		ix
		inc		ix
		inc		ix

		;byte 16
		
		ld		a,(ix)
[5]		srl		a
		and		00000111b
		inc		a
		ld		(estandarte_1),a

[3]		inc		ix
		
		;byte 19
		
		ld		a,(ix)
[5]		srl		a
		and		00000111b
		inc		a
		ld		(estandarte_2),a
						
		ld		iy,cuadrado_que_limpia_page2							; Borrando un poquito de page 2 que molesta para las letras
		call	COPY_A_GUSTO_7
		ld		a,0
		ld		(ix+12),a												;color
		ld		a,10000000b												;ESTRUCTURA DE CUADRADO RELLENO
		ld		(ix+14),a
		ld		hl,datos_del_copy
		call	DoCopy_7
				
		xor		a
		call	SCROLL_HORIZONTAL_7
																		
		JP		CARGAMOS_EL_BANCO_DEL_JUEGO
		
la_A:

		ld		c,0
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b
		
		ld		a,00000000b
		ld		(codiguin),a
		
		jp		FIN_LETRA
		
la_B:

		ld		c,8
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00000001b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_C:

		ld		c,16
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00000010b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_D:

		ld		c,24
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00000011b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_E:

		ld		c,32
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00000100b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_F:

		ld		c,40
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00000101b
		ld		(codiguin),a
		
		jp		FIN_LETRA

la_G:

		ld		c,48
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b
		
		ld		a,00000110b
		ld		(codiguin),a
		
		jp		FIN_LETRA
		
la_H:

		ld		c,56
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b
		
		ld		a,00000111b
		ld		(codiguin),a		
		jp		FIN_LETRA
		
la_I:

		ld		c,64
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001000b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_J:

		ld		c,72
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001001b
		ld		(codiguin),a
				
		jp		FIN_LETRA

la_K:

		ld		c,82
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001010b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_L:

		ld		c,90
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001011b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_M:

		ld		c,98
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001100b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_N:

		ld		c,106
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001101b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_O:

		ld		c,114
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001110b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
la_P:

		ld		c,122
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		a,00001111b
		ld		(codiguin),a
				
		jp		FIN_LETRA

la_bs:

		ld		a,(var_cuentas_peq)
		cp		1
		jp		z,FIN_LETRA.REPETIMOS

		ld		c,130
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b
		
		ld		a,1
		ld		(retroceso),a
		
		ld		a,00001111b
		ld		(codiguin),a
				
		jp		FIN_LETRA
		
BORRA_PANTALLA_1_7:								dw		#0000,#0000,#0000,#0000,#0100,#00d3
cuadrado_que_limpia_page2:						dw		#0000,#0000,#0046,#02b2,#00ba,#0004
cuadrado_que_limpia_page2_1:					dw		#0000,#0000,#0000,#0200,#0100,#003a
cuadrado_que_limpia_page2_2:					dw		#0000,#0000,#0000,#02d1,#0100,#002e
cuadrado_que_limpia_page3_3:					dw		#0000,#0000,#0000,#03d4,#0100,#001f
			
copia_error:									dw		#00a4,#017f,#006d,#020f,#002f,#000e
cuadrado_que_limpia_2_pantallas_sc8:			dw		#0000,#0000,#0000,#0000,#0100,#0200
primera_letra_de_codigo:						dw		#0000,#0000,#0002,#02E4,#0004,#0008	
copia_codigo:									dw		#00a4,#016e,#0068,#02D2,#002f,#000f	
copia_code:										dw		#00a4,#016f,#006e,#02d2,#001b,#000f
copia_code_la_e:								dw		#00a4,#017f,#0089,#02d2,#0009,#000f
cuadrado_que_limpia_letras:						dw		#0000,#0000,#0000,#03d4,#0002,#0001		
copia_piedras_en_pantalla:						dw		#00c8,#01dc,#001E,#0018
												db		#00,#00,#F0
letras_a_page3:									dw		#0000,#03d4,#007e,#0008
												db		#00,#00,#F0
																																							
; Datas de los copys chumino

copia_todos_estandartes:						dw		#0000,#033b,#0000,#03d4,#00f7,#002c
copia_msx:										dw		#0000,#03d4,#000C,#0084,#002A,#0015
copia_atari:									dw		#0029,#03d4,#000C,#0084,#002A,#0015
copia_amstrad:									dw		#0052,#03d4,#000C,#0084,#002A,#0015
copia_comodore:									dw		#007B,#03d4,#000C,#0084,#002A,#0015
copia_dragon:									dw		#00A4,#03d4,#000C,#0084,#002A,#0015
copia_spectrum:									dw		#00CD,#03d4,#000C,#0084,#002A,#0015
copia_acorn:									dw		#0000,#03e8,#000C,#0084,#002A,#0015
copia_oric:										dw		#0029,#03e8,#000C,#0084,#002A,#0015

copia_msx_plus:									dw		#0000,#03d4,#0004,#02b1,#0029,#0015
copia_atari_plus:								dw		#0029,#03d4,#002d,#02b1,#0029,#0015
copia_amstrad_plus:								dw		#0052,#03d4,#0056,#02b1,#0029,#0015
copia_comodore_plus:							dw		#007B,#03d4,#007f,#02b1,#0029,#0015
copia_dragon_plus:								dw		#00A4,#03d4,#00a8,#02b1,#0029,#0015
copia_spectrum_plus:							dw		#00CD,#03d4,#00d1,#02b1,#0029,#0015
copia_acorn_plus:								dw		#0000,#03e8,#0056,#02c8,#0029,#0015
copia_oric_plus:								dw		#0029,#03e8,#007f,#02c8,#0029,#0015

copia_natpu:									dw		#0002,#0165,#002E,#0061,#0026,#0050
copia_fergar:									dw		#002a,#0165,#0056,#0061,#0026,#0050
copia_crisra:									dw		#0054,#0165,#0080,#0061,#0026,#0050
copia_vicmar:									dw		#007d,#0165,#00a9,#0061,#0026,#0050

copia_level:									dw		#0063,#012d,#006A,#000E,#002c,#000f
copia_nivel:									dw		#0036,#012d,#006C,#000E,#0027,#000f
copia_uno:										dw		#00A5,#0151,#0058,#002D,#004F,#001C
copia_dos:										dw		#0090,#01B8,#0048,#0057,#006F,#0019
copia_tres:										dw		#0005,#01B6,#003B,#007E,#0089,#0016

copia_prota_1_en_vram_7:						dw		#0000,#0374,#00ac,#002a
												db		#00,#00,#F0
copia_prota_2_en_vram_7:						dw		#0000,#039e,#00ac,#002a
												db		#00,#00,#F0	
												
copia_seleccion_de_idioma:						dw		#0000,#0100,#0000,#003C,#0100,#0042
copia_eng:										dw		#0000,#0146,#002F,#0082,#001E,#000C	
copia_esp:										dw		#0020,#0146,#00B6,#0082,#0020,#000C
copia_petiso_senala_esp:						dw		#0000,#0152,#0078,#0064,#0015,#0022
copia_petiso_senala_eng:						dw		#0015,#0152,#0078,#0064,#0015,#0022
copia_titulo_del_menu:							dw		#0000,#0100,#0003,#023C,#00FC,#0042		
copia_pulsa_una_tecla:							dw		#0000,#0142,#0046,#02AA,#0074,#0017
copia_push_space_key:							dw		#0075,#0142,#0041,#02AA,#007D,#0017
cuadrado_que_limpia_1:							dw		#0000,#0000,#0041,#02AA,#007E,#001E
copia_titulo_a_0:								dw		#0000,#0220,#0000,#0020,#0100,#0090
copia_1_o_2_jugadores:							dw		#0000,#0100,#0010,#0288,#00FC,#000E		
copia_1_or_2_players:							dw		#0000,#010F,#0014,#0288,#00FC,#000E
cuadrado_que_limpia_2:							dw		#0000,#0000,#0000,#0200,#0100,#0001	
copia_estandarte:								dw		#0000,#011E,#0052,#029C,#005A,#000E
copia_banner:									dw		#0064,#011E,#006D,#029C,#0036,#000E
copia_dibujos_estandartes_1:					dw		#0000,#013B,#0003,#02B0,#0100,#0015
copia_dibujos_estandartes_2:					dw		#0000,#014F,#0055,#02C7,#0053,#0015
copia_estandartes_a_salvo:						dw		#0000,#013b,#0000,#033b,#0100,#0029
copia_p1:										dw		#0055,#015a,#0003,#02a7,#000b,#000a
copia_p2:										dw		#0060,#015a,#0003,#02a7,#000f,#000a
cuadrado_que_limpia_3:							dw		#0000,#0000,#0003,#00AA,#0009,#0005
copia_titulo_del_menu_2:						dw		#0005,#0100,#0002,#0005,#00FC,#0042		
copia_heroe:									dw		#0000,#012c,#0069,#0049,#0033,#000f	
copia_hero:										dw		#0000,#012d,#006E,#0050,#0023,#000E
copia_protagonistas:							dw		#0000,#0164,#002C,#0060,#00A3,#0050

cuadrado_que_limpia_jugador_dos:				dw		#0000,#0000,#00d4,#0000,#002c,#0074

copia_parte_page_1_a_page_2:					dw		#0000,#0000,#0000,#0100,#0100,#0080

;listas de opciones

CARA_DE_PROTA_ESCOGIDA:		dw	PROTA_1
							dw	PROTA_2	
							dw	PROTA_3																													
							dw	PROTA_4
														
POINT_ESTANDARTE_ESCOGIDO:	dw	POINT_TOCA_MSX
							dw	POINT_TOCA_ATARI
							dw	POINT_TOCA_AMSTRAD
							dw	POINT_TOCA_COMODORE
							dw	POINT_TOCA_DRAGON
							dw	POINT_TOCA_SINCLAIR
							dw	POINT_TOCA_ACORN
							dw	POINT_TOCA_ORIC

POINT_ESTANDARTE_ESCOGIDO_plus:	dw	POINT_TOCA_MSX_plus
							dw	POINT_TOCA_ATARI_plus
							dw	POINT_TOCA_AMSTRAD_plus
							dw	POINT_TOCA_COMODORE_plus
							dw	POINT_TOCA_DRAGON_plus
							dw	POINT_TOCA_SINCLAIR_plus
							dw	POINT_TOCA_ACORN_plus
							dw	POINT_TOCA_ORIC_plus
														
POINT_DE_ESTANDARTE:		dw	POINT_MSX
							dw	POINT_ATARI
							dw	POINT_AMSTRAD
							dw	POINT_COMMODORE
							dw	POINT_DRAGON
							dw	POINT_SPECTRUM
							dw	POINT_ACORN
							dw	POINT_ORIC
							
POINT_DE_PROTA:				dw	POINT_NATPU
							dw	POINT_FERGAR
							dw	POINT_CRISRA
							dw	POINT_VICMAR

POINT_DE_PROTA_plus:		dw	POINT_NATPU_plus
							dw	POINT_FERGAR_plus
							dw	POINT_CRISRA_plus
							dw	POINT_VICMAR_plus
							
POINT_DE_NIVEL:				dw	POINT_NIVEL_UNO							
							dw	POINT_NIVEL_DOS	
							dw	POINT_NIVEL_TRES
															
; Paletas de idioma en fade in y fade out

IDIOMA_FADE_IN:		incbin		"PL5/IDIOMA.FADEIN"
IDIOMA_FADE_OUT:	incbin		"PL5/IDIOMA.FADEOUT"

;paletas de titulo en fade in y fade out

TITULO_FADE_IN:		incbin		"PL5/TITULO FADE IN.PL5"
TITULO_FADE_OUT:	incbin		"PL5/TITULO FADE OUT.PL5"
MENU_FADE_IN:		incbin		"PL5/MENU.FADEIN"
MENU_FADE_OUT:		incbin		"PL5/MENU.FADEOUT"
;paleta de protas en fade in y fade out

PROTAS_FADE_IN:		incbin		"PL5/PROTAS FADE IN.PL5"
PROTAS_FADE_OUT:	incbin		"PL5/PROTAS FADE OUT.PL5"
				
; Recursos externos que se repiten. Aquí se les llama con _7 al final por el número de page

				include			"RECURSOS EXTERNOS_7.asm"
				include			"CODIGO DE MARCA.asm"
				
	ds			#7200-$
	
				include			"LANZADOR FMPACK Y MUSIC MODULE.asm"
				include			"LANZADOR EFECTOS PSG.ASM"

EL_7000_7:

		di
		
		ld		(en_que_pagina_el_page_2),a					
		ld		[#7000],a	
		
		ei
		
		ret
				
einde:

		ds		#8000-$													;llenamos de 0 hasta el final del bloque
	
; ********** FIN PAGINA 7 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 8 DEL MEGAROM **********

	; GRAFICOS DE SELECCION DE IDIOMA
	; PALETA BASE DE SELECCION DE IDIOMA
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 8)

PANTALLA_DE_IDIOMA:		incbin		"SR5/MENU/IDIOMA_256x212.DAT"

PALETA_DEL_IDIOMA:		incbin		"PL5/IDIOMA.PAL"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 8 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 9 DEL MEGAROM **********

	; TITULO DEL MENÚ
	; PULSA UNA TECLA

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 9)

PANTALLA_DE_TITULO:		incbin		"SR5/MENU/TITULO_256x66.DAT"

PULSA_UNA_TECLA:		incbin		"SR5/MENU/PULSA UNA TECLA_256x23.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 9 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 10 DEL MEGAROM **********
	
	; PANTALLA DE MARCA PRIMERA PARTE
	

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

MARCA_1:		incbin		"SR5/MENU/MARCA ANIMACION 1.SR5"
		
		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 10 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 11 DEL MEGAROM **********
	
	; PANTALLA DE MARCA SEGUNDA PARTE
	; DIBUJO DE MAPA PARTE 2
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
MARCA_2:							incbin		"SR5/MENU/MARCA ANIMACION 2.SR5"
COPIAMOS_PERGAMINO_2:				incbin		"SR5/MAPA/PERGAMINO_256X211.DAT2"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 11 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 12 DEL MEGAROM **********
	
	; GRAFICOS DE SELECCIÓN EN MENU PARTE 2
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
SELEC_MENU_1:		incbin		"SR5/MENU/MENU_256X212.DAT1"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 12 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 13 DEL MEGAROM **********
	
	; TITULO EN INGLÉS
	; CARAS DE LOS PROTAS 1 Y 2
	; CARGA EL PERGAMINO
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
PANTALLA_DE_TITLE:					incbin		"SR5/MENU/TITLE_256x66.DAT"
COPIAMOS_CARAS_PROTA_1:				incbin		"SR5/PROTAS/PROTA_1_TODAS_CARAS_172x42.DAT"
COPIAMOS_CARAS_PROTA_2:				incbin		"SR5/PROTAS/PROTA_2_TODAS_CARAS_172x42.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 13 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 14 DEL MEGAROM **********
	
	; CARAS DE LOS PROTAS 3 Y 4
	; DECORADOS 1 (CARAS)
	; DECORADOS 2 (GRIETAS)
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
COPIAMOS_CARAS_PROTA_3:				incbin		"SR5/PROTAS/PROTA_3_TODAS_CARAS_172x42.DAT"
COPIAMOS_CARAS_PROTA_4:				incbin		"SR5/PROTAS/PROTA_4_TODAS_CARAS_172x42.DAT"
COPIAMOS_ESCUDO_C_F:				incbin		"SR5/ESCUDOS/ESCUDO_CUARTA_FRENTE_10x9.DAT"
COPIAMOS_ESCUDO_T_F:				incbin		"SR5/ESCUDOS/ESCUDO_TERCERA_FRENTE_16x16.DAT"
COPIAMOS_ESCUDO_S_F:				incbin		"SR5/ESCUDOS/ESCUDO_SEGUNDA_FRENTE_22x26.DAT"
COPIAMOS_ESCUDO_P_F:				incbin		"SR5/ESCUDOS/ESCUDO_PRIMERA_FRENTE_36x43.DAT"
COPIAMOS_ESCUDO_T_D:				incbin		"SR5/ESCUDOS/ESCUDO_TERCERA_DERECHA_6x17.DAT"
COPIAMOS_ESCUDO_S_D:				incbin		"SR5/ESCUDOS/ESCUDO_SEGUNDA_DERECHA_12x29.DAT"
COPIAMOS_ESCUDO_P_D:				incbin		"SR5/ESCUDOS/ESCUDO_PRIMERA_DERECHA_18x43.DAT"
COPIAMOS_ESCUDO_T_I:				incbin		"SR5/ESCUDOS/ESCUDO_TERCERA_IZQUIERDA_6x17.DAT"
COPIAMOS_ESCUDO_S_I:				incbin		"SR5/ESCUDOS/ESCUDO_SEGUNDA_IZQUIERDA_12x29.DAT"
COPIAMOS_ESCUDO_P_I:				incbin		"SR5/ESCUDOS/ESCUDO_PRIMERA_IZQUIERDA_18x43.DAT"

copia_cuarta_fase_fondo_decorado_escudo:		dw		#007E,#003F,#000A,#0009
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_escudo:		dw		#007B,#003A,#0010,#0010
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_escudo:		dw		#0076,#0034,#0016,#001a
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_escudo:		dw		#006F,#002D,#0024,#002b
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_escudo:		dw		#008f,#003A,#0006,#0011
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_escudo:		dw		#009E,#0034,#000C,#001d
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_escudo:		dw		#00b4,#002C,#0012,#002b
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_escudo:	dw		#006b,#003A,#0006,#0011
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_escudo:	dw		#005a,#0034,#000C,#001d
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_escudo:	dw		#003C,#002C,#0012,#002b
												db		#00,#00,#F0
												
copia_cuarta_fase_fondo_decorado_escudo1:		dw		#007E,#013F,#000A,#0009
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_escudo1:		dw		#007B,#013A,#0010,#0010
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_escudo1:		dw		#0076,#0134,#0016,#001a
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_escudo1:		dw		#006F,#012D,#0024,#002b
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_escudo1:	dw		#008f,#013A,#0006,#0011
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_escudo1:	dw		#009E,#0134,#000C,#001d
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_escudo1:	dw		#00b4,#012C,#0012,#002b
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_escudo1:	dw		#006b,#013A,#0006,#0011 
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_escudo1:	dw		#005a,#0134,#000C,#001d
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_escudo1:	dw		#003C,#012C,#0012,#002b
												db		#00,#00,#F0	
												
		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 14 DEL MEGAROM **********)))		

; ______________________________________________________________________

		
; (((********** PAGINA 15 DEL MEGAROM **********
	
	; MUSICA menu
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
MUSICA:								incbin		"MUSICAS/INTRO.MBM"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 15 DEL MEGAROM **********)))		

; ______________________________________________________________________

		
; (((********** PAGINA 16 DEL MEGAROM **********
	
	; MUSICA del juego
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
MUSICA_DEL_JUEGO:					incbin		"MUSICAS/JUEGO.MBM"
EFECTOS_DE_SONIDO:					incbin		"MUSICAS/EFECTOS_SONIDO.afb"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 16 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 17 DEL MEGAROM **********
	
	; DECORADOS 3 (PUERTAS SALIDA)
	; DECORADOS 4 (PUERTAS ENTRADA)
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
COPIAMOS_SALIDA_C_F:				incbin		"SR5/SALIDAS/SALIDA_CUARTA_FRENTE_8X9.DAT"
COPIAMOS_SALIDA_T_F:				incbin		"SR5/SALIDAS/SALIDA_TERCERA_FRENTE_16x19.DAT"
COPIAMOS_SALIDA_S_F:				incbin		"SR5/SALIDAS/SALIDA_SEGUNDA_FRENTE_36x34.DAT"
COPIAMOS_SALIDA_P_F:				incbin		"SR5/SALIDAS/SALIDA_PRIMERA_FRENTE_56x58.DAT"
COPIAMOS_SALIDA_T_D:				incbin		"SR5/SALIDAS/SALIDA_TERCERA_DERECHA_8x24.DAT"
COPIAMOS_SALIDA_S_D:				incbin		"SR5/SALIDAS/SALIDA_SEGUNDA_DERECHA_14x42.DAT"
COPIAMOS_SALIDA_P_D:				incbin		"SR5/SALIDAS/SALIDA_PRIMERA_DERECHA_22x77.DAT"
COPIAMOS_SALIDA_T_I:				incbin		"SR5/SALIDAS/SALIDA_TERCERA_IZQUIERDA_8x24.DAT"
COPIAMOS_SALIDA_S_I:				incbin		"SR5/SALIDAS/SALIDA_SEGUNDA_IZQUIERDA_14x43.DAT"
COPIAMOS_SALIDA_P_I:				incbin		"SR5/SALIDAS/SALIDA_PRIMERA_IZQUIERDA_22x77.DAT"
COPIAMOS_ENTRADA_C_F:				incbin		"SR5/ENTRADAS/ENTRADA_CUARTA_FRENTE_8x9.DAT"
COPIAMOS_ENTRADA_T_F:				incbin		"SR5/ENTRADAS/ENTRADA_TERCERA_FRENTE_16x19.DAT"
COPIAMOS_ENTRADA_S_F:				incbin		"SR5/ENTRADAS/ENTRADA_SEGUNDA_FRENTE_36x34.DAT"
COPIAMOS_ENTRADA_P_F:				incbin		"SR5/ENTRADAS/ENTRADA_PRIMERA_FRENTE_56x58.DAT"
COPIAMOS_ENTRADA_T_D:				incbin		"SR5/ENTRADAS/ENTRADA_TERCERA_DERECHA_8x24.DAT"
COPIAMOS_ENTRADA_S_D:				incbin		"SR5/ENTRADAS/ENTRADA_SEGUNDA_DERECHA_14x42.DAT"
COPIAMOS_ENTRADA_P_D:				incbin		"SR5/ENTRADAS/ENTRADA_PRIMERA_DERECHA_22x77.DAT"
COPIAMOS_ENTRADA_T_I:				incbin		"SR5/ENTRADAS/ENTRADA_TERCERA_IZQUIERDA_8x24.DAT"
COPIAMOS_ENTRADA_S_I:				incbin		"SR5/ENTRADAS/ENTRADA_SEGUNDA_IZQUIERDA_14x43.DAT"
COPIAMOS_ENTRADA_P_I:				incbin		"SR5/ENTRADAS/ENTRADA_PRIMERA_IZQUIERDA_22x77.DAT"

copia_cuarta_fase_fondo_decorado_puerta:		dw		#007D,#0042,#0009,#000c
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_puerta:		dw		#007C,#003b,#0011,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_puerta:		dw		#006C,#0033,#0025,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_puerta:		dw		#0063,#002d,#0039,#003a
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_puerta:		dw		#008f,#003d,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_puerta:		dw		#009c,#0037,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_puerta:		dw		#00b3,#002b,#0017,#004c
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_puerta:	dw		#006b,#003c,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_puerta:	dw		#005a,#0037,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_puerta:	dw		#0039,#002b,#0017,#004c
												db		#00,#00,#F0
												
copia_cuarta_fase_fondo_decorado_puerta1:		dw		#007D,#0142,#0009,#000c
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_puerta1:		dw		#007C,#013b,#0011,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_puerta1:		dw		#006C,#0133,#0025,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_puerta1:		dw		#0063,#012d,#0039,#003a
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_puerta1:	dw		#008f,#013d,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_puerta1:	dw		#009c,#0137,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_puerta1:	dw		#00b3,#012b,#0017,#004c
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_puerta1:	dw		#006b,#013c,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_puerta1:	dw		#005a,#0137,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_puerta1:	dw		#0039,#012b,#0017,#004c
												db		#00,#00,#F0	

copia_cuarta_fase_fondo_decorado_entrada:		dw		#007D,#0042,#0009,#000c
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_entrada:		dw		#007c,#003c,#0011,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_entrada:		dw		#006C,#0033,#0025,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_entrada:		dw		#0063,#002d,#0039,#003a
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_entrada:	dw		#008f,#003d,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_entrada:	dw		#009c,#0038,#000e,#002a
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_entrada:	dw		#00b3,#002b,#0017,#004c
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_entrada:	dw		#006b,#003c,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_entrada:	dw		#005a,#0037,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_entrada:	dw		#0039,#002b,#0017,#004c
												db		#00,#00,#F0
												
copia_cuarta_fase_fondo_decorado_entrada1:		dw		#007D,#0142,#0009,#000c
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_entrada1:		dw		#007c,#013c,#0011,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_entrada1:		dw		#006C,#0133,#0025,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_entrada1:		dw		#0063,#012d,#0039,#003a
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_entrada1:	dw		#008f,#013d,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_entrada1:	dw		#009c,#0138,#000e,#002a
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_entrada1:	dw		#00b3,#012b,#0017,#004c
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_entrada1:	dw		#006b,#013c,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_entrada1:	dw		#005a,#0137,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_entrada1:	dw		#0039,#012b,#0017,#004c
												db		#00,#00,#F0	
																								
		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 17 DEL MEGAROM **********)))	

; ______________________________________________________________________

		
; (((********** PAGINA 18 DEL MEGAROM **********
	
	; DECORADOS 5 (PUERTAS POCHADA)
	; POCHADERO 1
	
		org		#8000													; esto define dónde se empieza a escribir el bloque (page 2)
		
COPIAMOS_POCHADA_C_F:				incbin		"SR5/POCHADAS/POCHADA_CUARTA_FRENTE_8x9.DAT"
COPIAMOS_POCHADA_T_F:				incbin		"SR5/POCHADAS/POCHADA_TERCERA_FRENTE_16x19.DAT"
COPIAMOS_POCHADA_S_F:				incbin		"SR5/POCHADAS/POCHADA_SEGUNDA_FRENTE_36x34.DAT"
COPIAMOS_POCHADA_P_F:				incbin		"SR5/POCHADAS/POCHADA_PRIMERA_FRENTE_56x58.DAT"
COPIAMOS_POCHADA_T_D:				incbin		"SR5/POCHADAS/POCHADA_TERCERA_DERECHA_8x24.DAT"
COPIAMOS_POCHADA_S_D:				incbin		"SR5/POCHADAS/POCHADA_SEGUNDA_DERECHA_14x42.DAT"
COPIAMOS_POCHADA_P_D:				incbin		"SR5/POCHADAS/POCHADA_PRIMERA_DERECHA_22x77.DAT"
COPIAMOS_POCHADA_T_I:				incbin		"SR5/POCHADAS/POCHADA_TERCERA_IZQUIERDA_8x24.DAT"
COPIAMOS_POCHADA_S_I:				incbin		"SR5/POCHADAS/POCHADA_SEGUNDA_IZQUIERDA_14x43.DAT"
COPIAMOS_POCHADA_P_I:				incbin		"SR5/POCHADAS/POCHADA_PRIMERA_IZQUIERDA_22x77.DAT"
COPIAMOS_POCHADERO1:				incbin		"SR5/POCHADAS/POCHADERO1_112x76.DAT"

copia_cuarta_fase_fondo_decorado_pochada:		dw		#007D,#0042,#0009,#000c
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_pochada:		dw		#007C,#003b,#0011,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_pochada:		dw		#006C,#0033,#0025,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_pochada:		dw		#0063,#002d,#0039,#003a
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_pochada:	dw		#008f,#003d,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_pochada:	dw		#009c,#0037,#000e,#002A
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_pochada:	dw		#00b3,#002b,#0017,#004c
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_pochada:	dw		#006b,#003c,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_pochada:	dw		#005a,#0037,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_pochada:	dw		#0039,#002b,#0017,#004c
												db		#00,#00,#F0
												
copia_cuarta_fase_fondo_decorado_pochada1:		dw		#007D,#0142,#0009,#000c
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_pochada1:		dw		#007C,#013b,#0011,#0015
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_pochada1:		dw		#006C,#0133,#0025,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_pochada1:		dw		#0063,#012d,#0039,#003a
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_pochada1:	dw		#008f,#013d,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_pochada1:	dw		#009c,#0137,#000e,#002A
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_pochada1:	dw		#00b3,#012b,#0017,#004c
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_pochada1:	dw		#006b,#013c,#0009,#0017
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_pochada1:	dw		#005a,#0137,#000e,#002b
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_pochada1:	dw		#0039,#012b,#0017,#004c
												db		#00,#00,#F0		
												
		ds		#c000-$													; llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 18 DEL MEGAROM **********)))	

; ______________________________________________________________________

		
; (((********** PAGINA 19 DEL MEGAROM **********
	
	; LABERINTOS PARA DOS JUGADORES DEL 1 AL 6
	
		org		#8000													; esto define dónde se empieza a escribir el bloque (page 2)

; CALCULAR x_map E y_map
;			y = (((casilla/30)-parte decimal)*5)+27
;			x = ((parte decimal*30)*5)+53
MUSICA_END:			incbin		"MUSICAS/ENDING.MBM"

BUSCANDO_NIVEL_1:

		ld		hl,DATA_LABERINTO_2_1
		call	CARGA_LABERINTO
		ld		hl,DATA_DECORADOS_LABERINTO_2_1
		call	CARGA_DECORADOS
		ld		hl,DATA_SUCESOS_LABERINTO_2_1
		call	CARGA_SUCESOS
		ld		hl,399
		ld		(casilla_destino_agujero_negro),hl		
		ld		a,98
		ld		(x_map_destino_agujero_negro),a
		ld		a,92
		ld		(y_map_destino_agujero_negro),a		
		ld		a,(codigo_activo)
		or		a
		jp		nz,REGRESO
		
		ld		hl,870													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		hl,872
		ld		(posicion_en_mapa_2),hl
		ld		a,53													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,63
		ld		(x_map_2),a
		ld		a,172
		ld		(y_map_1),a
		ld		(y_map_2),a


		
		xor		a
		ld		(orientacion_del_personaje_1),a
		ld		(orientacion_del_personaje_2),a
		
		jp		REGRESO
		
BUSCANDO_NIVEL_2:

		cp		2
		jp		nz,BUSCANDO_NIVEL_3
		
		ld		hl,DATA_LABERINTO_2_2
		call	CARGA_LABERINTO
		ld		hl,DATA_DECORADOS_LABERINTO_2_2
		call	CARGA_DECORADOS
		ld		hl,DATA_SUCESOS_LABERINTO_2_2
		call	CARGA_SUCESOS
		ld		hl,438
		ld		(casilla_destino_agujero_negro),hl		
		ld		a,143
		ld		(x_map_destino_agujero_negro),a
		ld		a,97
		ld		(y_map_destino_agujero_negro),a
		ld		a,(codigo_activo)
		or		a
		jp		nz,REGRESO
		
		ld		hl,873													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		hl,26
		ld		(posicion_en_mapa_2),hl
		ld		a,68													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		a,183
		ld		(x_map_2),a
		ld		a,172
		ld		(y_map_1),a
		ld		a,27
		ld		(y_map_2),a


		
		LD		a,0														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
		ld		a,2
		ld		(orientacion_del_personaje_2),a
		
		jp		REGRESO

BUSCANDO_NIVEL_3:

		ld		hl,DATA_LABERINTO_2_3
		call	CARGA_LABERINTO
		ld		hl,DATA_DECORADOS_LABERINTO_2_3
		call	CARGA_DECORADOS
		ld		hl,DATA_SUCESOS_LABERINTO_2_3
		call	CARGA_SUCESOS
		ld		hl,15
		ld		(casilla_destino_agujero_negro),hl		
		ld		a,128
		ld		(x_map_destino_agujero_negro),a
		ld		a,27
		ld		(y_map_destino_agujero_negro),a
		ld		a,(codigo_activo)
		or		a
		jp		nz,REGRESO
		
		ld		hl,14													;especificamos en qué casilla empieza
		ld		(posicion_en_mapa_1),hl
		ld		hl,884
		ld		(posicion_en_mapa_2),hl
		ld		a,123													;especificamos coordenadas de inicio de mapa
		ld		(x_map_1),a
		ld		(x_map_2),a
		ld		a,27
		ld		(y_map_1),a
		ld		a,172
		ld		(y_map_2),a


		
		LD		a,2														;especificamos su orientación inicial
		ld		(orientacion_del_personaje_1),a
		xor		a
		ld		(orientacion_del_personaje_2),a
					
		jp		REGRESO
				
DATA_LABERINTO_2_1:				

									include		"LABERINTOS/FASE_2_1_LABERINTO.asm"
		
DATA_DECORADOS_LABERINTO_2_1:	

									include		"LABERINTOS/FASE_2_1_DECORADOS.asm"
												
DATA_SUCESOS_LABERINTO_2_1:		

									include		"LABERINTOS/FASE_2_1_SUCESOS.asm"

DATA_LABERINTO_2_2:

									include		"LABERINTOS/FASE_2_2_LABERINTO.asm"

DATA_DECORADOS_LABERINTO_2_2:

									include		"LABERINTOS/FASE_2_2_DECORADOS.asm"
										
DATA_SUCESOS_LABERINTO_2_2:

									include		"LABERINTOS/FASE_2_2_SUCESOS.asm"

DATA_LABERINTO_2_3:				

									include		"LABERINTOS/FASE_2_3_LABERINTO.asm"
		
DATA_DECORADOS_LABERINTO_2_3:				

									include		"LABERINTOS/FASE_2_3_DECORADOS.asm"
									
DATA_SUCESOS_LABERINTO_2_3:				

									include		"LABERINTOS/FASE_2_3_SUCESOS.asm"
		
		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 19 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 20 DEL MEGAROM **********
	
; ESCRIBIR TEXTOS	

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

ESCRIBIMOS_CODIGO:

		CALL	LIMPIEZA
		ld		a,1
		ld		(var_cuentas_peq),a
		
ESCRIBIMOS_CODIGO_2:

		ld		a,(iy)													; Leemos primera letra del bloque de 3 letras que suponen los 2 bytes												
		and		11110000b												; 0XXXXX00 00000000
[4]		srl		a
		ld		de, POINT_CODIGO
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		a,(iy)													; Leemos primera letra del bloque de 3 letras que suponen los 2 bytes												
		and		00001111b
		ld		de, POINT_CODIGO
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		inc		iy
		push	iy
		pop		de
		
		ld		a,(var_cuentas_peq)
		inc		a
		ld		(var_cuentas_peq),a

		cp		3
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		5
		call	z,FINAL_DE_LETRAS_GENERAL
		
		cp		7
		call	z,FINAL_DE_LETRAS_GENERAL
		
		cp		9
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		11
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		13
		call	z,FINAL_DE_LETRAS_GENERAL
						
		cp		14	
		call	z,LIMPIEZA_INTERMEDIA

		cp		16
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		18
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		20
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		22
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		24
		call	z,FINAL_DE_LETRAS_GENERAL
		cp		26
		call	z,FINAL_DE_LETRAS_GENERAL	
					
		cp		27
		ret		z
		
		push	de
		pop		iy
		jp		ESCRIBIMOS_CODIGO_2

LIMPIEZA_INTERMEDIA:

		call	LIMPIEZA

		ld		a,(ix+4)
		sub		2
		add		2
		
		ld		(ix+4),a
		ret
				
ESCRIBIMOS_EL_NOMBRE_DEL_PROTA:

		ld		a,(personaje)
		dec		a
		ld		de, POINT_ESCRIBE_NOMBRE
		call	lista_de_opciones
		
ESCRIBIMOS_EN_GENERAL:

		CALL	LIMPIEZA
		JP		ESCRIBIMOS_EN_GENERAL_2
		
LIMPIEZA:
		
		ld		iy,copia_texto_para_arriba
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		iy,cuadrado_texto_para_arriba
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		a,10
		ld		(ralentizando),a
		call	RALENTIZA
		
		ld		iy,copia_inicio_texto									;copiamos en la page 0 lo construído en la page 1
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a	
		
		ld		iy,secuencia_de_letras
		ld		a,(iy)
		
		RET
		
ESCRIBIMOS_EN_GENERAL_2:

		ld		a,(iy)													; Leemos primera letra del bloque de 3 letras que suponen los 2 bytes												
		and		01111100b												; 0XXXXX00 00000000
[2]		srl		a
		ld		de, POINT_LETRAS
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,(iy)													; Leemos segunda letra, la parte que está en el primer byte
		and		00000011b												; 000000XX 00000000
[3]		rlc		a														; Lo colocamos en posición adecuada 000XX000
		ld		b,a				
		inc		iy
		ld		a,(iy)													; Colocamos segunda letra, la parte que está en el segundo byte
[5]		srl		a														; de XXX00000  a 000000XX	
		add		b														;Le añadimos la parte adecuada del otro byte 000XX000 + 000000XX = 000XXXXX
		ld		de, POINT_LETRAS
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		a,(iy)													; leemos tercera letra, que está en el segundo byte
		and		00011111b												; 000XXXXX
		ld		de, POINT_LETRAS
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		dec		iy
		ld		a,(iy)
		and		10000000b
		rlc		a
		cp		1
		call	z,PASA_CARRO
		
[2]		inc		iy
		
		jp		ESCRIBIMOS_EN_GENERAL_2

cuadrado_texto_para_arriba:						dw		#0000,#0000,#0036,#00a2,#0096,#0009
copia_inicio_texto:								dw		#0000,#0000,#0036,#00a2,#0006,#0009
copia_texto_para_arriba:						dw		#0036,#00a2,#0036,#009a,#0096,#0008
				
ESPACIO:

		ld		c,98
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,144
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

A:

		ld		c,0
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
B:

		ld		c,8
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
C:

		ld		c,16
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
D:

		ld		c,24
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
E:

		ld		c,32
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
F:

		ld		c,40
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

G:

		ld		c,48
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
H:

		ld		c,56
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
I:

		ld		c,64
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
J:

		ld		c,72
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

K:

		ld		c,0
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
L:

		ld		c,8
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
M:

		ld		c,16
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
N:

		ld		c,24
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
O:

		ld		c,32
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
P:

		ld		c,40
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

Q:

		ld		c,48
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
R:

		ld		c,56
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
S:

		ld		c,64
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
T:

		ld		c,72
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
U:

		ld		c,0
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
V:

		ld		c,8
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
W:

		ld		c,16
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
X:

		ld		c,24
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
Y:

		ld		c,32
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
Z:

		ld		c,40
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

DOS_PUNTOS:

		ld		c,48
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
PUNTO:

		ld		c,72
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
					
		jp		FINAL_DE_LETRAS_GENERAL
		
ACENTO:

		ld		c,56
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,172
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		ret
		
RABITO_N:

		ld		c,64
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,172
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		ret
		
PASA_CARRO:

		pop		af														;sacamos de la pila el dato que nos devuelve a continuar escribiendo

		ret
			
STRIG_DE_CONTINUE:	
		
		ld		de,PULSA_ESPACIO
		ld		hl,copia_pulsa_espacio									; dibujamos la flecha de espera
		call	ESPERA_AL_VDP_HMMC

			

.EL_STRIG:

		xor		a
		CALL	GTTRIG
		cp		255
		jp		z,.EL_REGRESO_teclado											;volvemos al programa general

		ld		a,(turno)
		CALL	GTTRIG
		cp		255
		jp		z,.EL_REGRESO_mando											;volvemos al programa general
		
		ld		a,7														
		call	SNSMAT
		bit		7,a
		jp		z,.EL_REGRESO_intro
		
		jp		.EL_STRIG

.EL_REGRESO_teclado:

		xor		a
		call	GTTRIG
		cp		255		
		jp		nz,.EL_REGRESO
		jp		.EL_REGRESO_teclado

.EL_REGRESO_mando:

		ld		a,(turno)
		call	GTTRIG
		cp		255		
		jp		nz,.EL_REGRESO
		jp		.EL_REGRESO_mando
		
.EL_REGRESO_intro:

		ld		a,7														
		call	SNSMAT
		bit		7,a
		jp		nz,.EL_REGRESO
		jp		.EL_REGRESO_intro
				
.EL_REGRESO:

		ld		iy,cuadrado_que_limpia_PULSA_ESPACIO					; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,10010000b
		ld		(ix+14),a							

		ret
		
STRIG_DE_CONTINUE_CAMBIO_DE_JUGADOR:	
		
		ld		de,PULSA_ESPACIO
		ld		hl,copia_pulsa_espacio									; dibujamos la flecha de espera
		call	ESPERA_AL_VDP_HMMC

			

.EL_STRIG:

		xor		a
		CALL	GTTRIG
		cp		255
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa space

		ld		a,(1)
		CALL	GTTRIG
		cp		255
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa boton A mando 1

		ld		a,(2)
		CALL	GTTRIG
		cp		255
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa boton A mando 2
				
		ld		a,7														
		call	SNSMAT
		bit		7,a
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa intro
		
		jp		.EL_STRIG
				

FINAL_DE_LETRAS_GENERAL:

		ld		a,(ix+4)
		add		4
		ld		(ix+4),a
		
		ret
					
HOLA_EN_POCHADA_FINAL:

		ld		ix,HOLA_POCHADA_2_ESP
		jp		COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER

PASAR_LA_NOCHE:

		ld		hl,PASAR_LA_NOCHE_ESP		
		RET

PAGA_30:

		ld		hl,PAGA_30_ESP
		RET

PAGA_60:

		ld		hl,PAGA_60_ESP
		RET
				
PAGA_90:

		ld		hl,PAGA_90_ESP
		RET

SALIR_DE_POSADA:

		ld		hl,SALIR_ESP
		RET

BUENAS_NOCHES:

		ld		ix,BUENAS_NOCHES_ESP
		jp		COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER

BRUJULA_EXPLICADA:

		ld		hl,BRUJULA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,BRUJULA_2_ESP
		RET

PAPIRO_EXPLICADO:

		ld		hl,PAPIRO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PAPIRO_2_ESP
		RET

PLUMA_EXPLICADA:

		ld		hl,PLUMA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PLUMA_2_ESP
		RET

HABLA_DE_POCHADA:

		ld		hl,VIEJIGUIA_POCHADA_ESP
		RET
		
HABLA_DE_SALIDA:

		ld		hl,VIEJIGUIA_SALIDA_ESP
		RET
		
HABLA_DE_LLAVE:

		ld		hl,VIEJIGUIA_LLAVE_ESP
		RET

NORTE:
		
		ld		hl,N_ESP		
		jp		COMUN_VIEJIGUIA
		
NORESTE:

		ld		hl,NE_ESP		
		jp		COMUN_VIEJIGUIA
		
ESTE:

		ld		hl,E_ESP		
		jp		COMUN_VIEJIGUIA
		
SURESTE:

		ld		hl,SE_ESP		
		jp		COMUN_VIEJIGUIA

SUR:

		ld		hl,S_ESP		
		jp		COMUN_VIEJIGUIA
		
SUROESTE:

		ld		hl,SO_ESP		
		jp		COMUN_VIEJIGUIA

OESTE:

		ld		hl,O_ESP		
		jp		COMUN_VIEJIGUIA
		
NOROESTE:		

		ld		hl,NO_ESP		
		jp		COMUN_VIEJIGUIA
				
NATPU:

		ld		hl,NOMBRE_NATPU_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

	
FERGAR:

		ld		hl,NOMBRE_FERGAR_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

	
CRIRA:

		ld		hl,NOMBRE_CRIRA_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

	
VICMAR:

		ld		hl,NOMBRE_VICMAR_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

NO_PASA_NADA:

		ld		a,(cantidad_de_jugadores)
		cp		1
		ret		z
		
		ld		hl,FIN_DE_TURNO_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		jp		TEXTO_A_ESCRIBIR

ENCUENTRA_BRUJULA:

		ld		a,(brujula)												;si ya la tiene, pasa de largo
		or		a
		ret		nz
		
		ld		a,1														;le damos la brújula al jugador
		ld		(brujula),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
				
		ld		iy,copia_brujula_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla


		call	EXPLICACION_BRUJULA
		jp		ENCUENTRA_BRUJULA_CONTINUACION
		
EXPLICACION_BRUJULA:

		call	BRUJULA_EXPLICADA
		jp		TEXTO_A_ESCRIBIR
		
ENCUENTRA_BRUJULA_CONTINUACION:
						
		ld		iy,copia_brujula_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO				
		call	COMPRUEBA_TURNO_EN_OBJETO
		
		ld		c,#C0													;corregimos la posición de la brújula para el jugador 2

ENCUENTRA_BRUJULA_1_5:

		PUSH	af														;empujamos a la pila un valor para compensar el que sacamos despues de un call
		
		ld		b,#00
		ld		(ix+4),c
		ld		(ix+5),b
		
		jp		ENCUENTRA_BRUJULA_2_5
		
ENCUENTRA_PAPEL:

		ld		a,(papel)												;si ya la tiene, pasa de largo
		or		a
		ret		nz
		
		ld		a,1														;le damos la brújula al jugador
		ld		(papel),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a

		ld		iy,copia_papel_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		call	PAPIRO_EXPLICADO

		call	TEXTO_A_ESCRIBIR
				
		ld		iy,copia_papel_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO
		
		call	COMPRUEBA_TURNO_EN_OBJETO_2
	
		ld		c,#b2													;corregimos la posición de la brújula para el jugador 2
		
		jp		ENCUENTRA_BRUJULA_1_5
		
ENCUENTRA_PLUMA:

		ld		a,(pluma)												;si ya la tiene, pasa de largo
		or		a
		ret		nz
		
		ld		a,1														;le damos la brújula al jugador
		ld		(pluma),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a


		ld		iy,copia_pluma_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		call	PLUMA_EXPLICADA

		call	TEXTO_A_ESCRIBIR
						
		ld		iy,copia_pluma_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO
		
		call	COMPRUEBA_TURNO_EN_OBJETO_2
			
		ld		c,#9a													;corregimos la posición de la brújula para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_VIEJIGUIA:
		
		ld		a,r														; decide qué viejiguia va a hablar
		and		00000011b		
		ld		(pagina_hater),a
		
		cp		0
		jp		z,.VIEJI1
		cp		1
		jp		z,.VIEJI2	
		cp		2
		jp		z,.VIEJI3
		cp		3
		jp		z,.VIEJI4
		
.VIEJI1:
			
		call	CARGA_VIEJI1
		jp		.CONTINUAMOS

.VIEJI2:
			
		call	CARGA_VIEJI2
		jp		.CONTINUAMOS
		
.VIEJI3:
			
		call	CARGA_VIEJI3
		jp		.CONTINUAMOS
		
.VIEJI4:
			
		call	CARGA_VIEJI4

.CONTINUAMOS:

SE_PRESENTA:

		ld		ix,SOY_ANDRES_SAMUDIO_ESP_1
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		ix,SOY_ANDRES_SAMUDIO_ESP_2
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
							
		call	STRIG_DE_CONTINUE										; PAUSA
		
DECIDE_DE_LO_QUE_HABLA:

		ld		a,r														; decide sobre qué objeto va a hablar (pochada, llave salida)
		and		00000011b		
		add		14
		cp		16
		jp		nz,.HACE_LOS_CALCULOS_ADECUADOS
		
		inc		a														; si es entrada, lo convertimos en salida
				
.HACE_LOS_CALCULOS_ADECUADOS:
		
		ld		(que_estoy_buscando),a
		
		ld		hl,0
		ld		a,0
		ld		(donde_esta_jugador_posicion),a
		ld		(objeto_manipular),hl
		ld		(objeto_posicion),a
		
		ld		hl,(posicion_en_mapa)									; salva A
		ld		(donde_esta_jugador_manipular),hl
		
.CALCULA_C:																; calcula C el resto a E
	
		ld		de,(donde_esta_jugador_manipular)
		ld		a,d
		cp		0
		jp		nz,.SALTA_PRIMER_BYTE_C
		ld		a,e
		cp		29
		jp		c,.ENCUENTRA_B

.SALTA_PRIMER_BYTE_C:

		push	de														; A-30
		pop		hl
		ld		de,30
		or		a
		sbc		hl,de

		ld		(donde_esta_jugador_manipular),hl				

		ld		a,(donde_esta_jugador_posicion)							; C+1
		inc		a
		ld		(donde_esta_jugador_posicion),a
	
		jp		.CALCULA_C
		
.ENCUENTRA_B:															;encuentra B
		
		ld		a,(que_estoy_buscando)
		ld		b,a

		ld		iy,eventos_laberinto									

.BUSCANDO_1_POR_1:

		ld		a,(iy)	
		
		cp		b
		jp		z,.CALCULA_D
		
		ld		bc,1
		add		iy,bc
		ld		a,(objeto_manipular)
		inc		a
		ld		(objeto_manipular),a

		ld		a,(que_estoy_buscando)
		ld		b,a		
		jp		.BUSCANDO_1_POR_1
				
.CALCULA_D:																;calcula D el resto a F

		ld		de,(objeto_manipular)
		ld		a,d
		cp		0
		jp		nz,.SALTA_PRIMER_BYTE_D
		ld		a,e
		cp		29
		jp		c,.VALOR_NORTE_SUR

.SALTA_PRIMER_BYTE_D:

		push	de														; D-30
		pop		hl
		ld		de,30
		or		a
		sbc		hl,de

		ld		(objeto_manipular),hl				

		ld		a,(objeto_posicion)										; E+1
		inc		a
		ld		(objeto_posicion),a
	
		jp		.CALCULA_D
		
.VALOR_NORTE_SUR:														;calcula valor norte_sur

		ld		a,(objeto_posicion)
		ld		b,a
		ld		a,(donde_esta_jugador_posicion)
		cp		b
		jp		z,.VALOR_ESTE_OESTE
		jp		c,.ESTA_AL_SUR
		jp		nc,.ESTA_AL_NORTE
				
.ESTA_AL_SUR:

		ld		a,6
		ld		(norte_sur),a
		jp		.VALOR_ESTE_OESTE

.ESTA_AL_NORTE:

		ld		a,3
		ld		(norte_sur),a

.VALOR_ESTE_OESTE:														;calcula valor este_oeste

		ld		a,(objeto_manipular)
		ld		b,a
		ld		a,(donde_esta_jugador_manipular)
		cp		b
		jp		z,.MISMA_LINEA
		jp		c,.ESTA_AL_ESTE
		jp		nc,.ESTA_AL_OESTE

.MISMA_LINEA:

		ld		a,4
		ld		(este_oeste),a
		jp		.SUMA_FINAL
						
.ESTA_AL_ESTE:

		ld		a,5
		ld		(este_oeste),a
		jp		.SUMA_FINAL

.ESTA_AL_OESTE:

		ld		a,3
		ld		(este_oeste),a
		
.SUMA_FINAL:															;suma para dar situacion_real

		ld		a,(norte_sur)
		ld		b,a
		ld		a,(este_oeste)
		add		a,b

		ld		(situacion_real),a
		
		ld		a,(que_estoy_buscando)

		cp		14
		jp		z,.DECISION_POCHADA		
		cp		15
		jp		z,.DECISION_LLAVE
		cp		17
		jp		z,.DECISION_SALIDA		

.DECISION_POCHADA:
		
		call	HABLA_DE_POCHADA
		ld		bc,37	
		call	TEXTO_A_ESCRIBIR
		jp		.DECISION_FIN

.DECISION_LLAVE:
		
		call	HABLA_DE_LLAVE
		ld		bc,34	
		call	TEXTO_A_ESCRIBIR
		jp		.DECISION_FIN
		
.DECISION_SALIDA:
		
		call	HABLA_DE_SALIDA
		ld		bc,35	
		call	TEXTO_A_ESCRIBIR
						
.DECISION_FIN:
		
		
		ld		a,(situacion_real)
		sub		3
		and		00001111b														;restamos tres para que coincida con la lista de selección
		ld		de, POINT_DIREC_VIAJIGUIA
		jp		lista_de_opciones
						
COMUN_VIEJIGUIA:

		call	TEXTO_A_ESCRIBIR
		call	SONIDO_VIEJIGUIA

		call	STRIG_DE_CONTINUE
		
		ld		a,(set_page01)
		or		a
		jp		z,.a_uno

.a_0:

		xor		a
		ld		(set_page01),a
		ret

.a_uno:

		ld		a,1
		ld		(set_page01),a
		ret		

ENCUENTRA_HATER_MSX:

		ld		a,1
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_ATARI:

		ld		a,2
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_AMSTRAD:

		ld		a,3
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_COMMODORE:

		ld		a,4
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_DRAGON:

		ld		a,5
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_SPECTRUM:

		ld		a,6
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER
		
ENCUENTRA_HATER_ACORN:

		ld		a,7
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_ORIC:

		ld		a,8
		ld		(estandarte_hater),a
		
ENCUENTRA_HATER:

		di
		call  	stpmus
		ei
		
		CALL	ACTIVA_MUSICA_HATER_CONVERSACION
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_neutra_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		EMPIEZA_CONTROL_DE_PELEA

.pinta_jugador_2:

		ld		iy,copia_cara_neutra_jugador_2						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

EMPIEZA_CONTROL_DE_PELEA:

		ld		a,(set_page01)
		cp		1
		jp		z,.CONTINUAMOS

		ld		iy,copia_escenario_a_page_1								; Si estamos en page 0. Vamos a clonar la 0 en la 1
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO
		
		ld		a,1
		ld		(set_page01),a
		
.CONTINUAMOS:
				
		ld		a,5														; REINICIAMOS LA VIDA AL HATER
		ld		(vida_hater),a
		
		ld		iy,cuadrado_que_limpia_5								; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR
						
		call	PINTANDO_EL_HATER										; PINTA_HATER

		ld		iy,copia_mas_igual										; COPIAMOS + E = DE ATAQUE
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_corazon										; COPIAMOS + E = DE DEFENSA
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	DIRECTRICES_VIDA_HATER									; PINTAMOS EL VALOR DE LA VIDA DEL HATER
		ld		a,(vida_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		call	LIMPIA_VALORES_DE_LUCHA
								
		ld		a,(nivel)												; PINTAMOS EL MODIFICADOR DE ATAQUE Y DEFENSA
		ld		de, POINT_NIVEL_HATER
		jp		lista_de_opciones

NIVEL_HATER_0:
		
		ld		iy,copia_hater_0									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_0		
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER

NIVEL_HATER_1:
		
		ld		iy,copia_hater_1									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_1									
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER

NIVEL_HATER_2:
		
		ld		iy,copia_hater_2									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_2									
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER

NIVEL_HATER_3:
		
		ld		iy,copia_hater_3									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_3									
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER
		
NIVEL_HATER_4:
		
		ld		iy,copia_hater_4									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_4
		call	COPY_A_GUSTO					
		ld		a,#32
		ld		(ix+6),a									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
												
SALUDO_HATER:

		xor		a
		ld		(set_page01),a	
		
		ld		ix,HOLA_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		ix,HOLA_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		
					
		call	STRIG_DE_CONTINUE										; PAUSA

		di
		or		a
		ld		a,7				
		ld		[#6000],a	
		
		ei


				
		ld		a,(estandarte_hater)
		ld		de, POINT_ESTANDARTE_ESCOGIDO
		call	lista_de_opciones_7
		
		di
		or		a
		ld		a,0				
		ld		[#6000],a	
		
		ei
		
		ld		c,#a0
		ld		b,#00
		ld		(ix+4),c
		ld		(ix+5),b
		ld		c,#0c
		ld		b,#00
		ld		(ix+6),c
		ld		(ix+7),b
						
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
		ld		a,(estandarte)											; DECIDE SI LUCHA O NO LUCHA
		ld		b,a
		ld		a,(estandarte_hater)
		cp		b
		jp		NZ,SI_LUCHA

NO_LUCHA:																; NO LUCHA
		
		ld		a,17
		ld		c,0
		call	EFECTO

		ld		a,1														; activamos la mosca_activa
		ld		(mosca_activa),a

		ld		a,(turno)
		cp		1
		jp		nz,NO_LUCHA_2
		
		ld		a,28
		ld		(mosca_x_objetivo),a
		ld		a,62
		ld		(mosca_y_objetivo),a
		jp		NO_LUCHA_3

NO_LUCHA_2:

		ld		a,235
		ld		(mosca_x_objetivo),a
		ld		a,62
		ld		(mosca_y_objetivo),a
		
NO_LUCHA_3:
				
		ld		ix,PREMIO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		ix,PREMIO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		
		call	HATER_CARA_FELIZ
			
		call	STRIG_DE_CONTINUE										; PAUSA
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_activa_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		A_DAR_MONEDAS
		
.pinta_jugador_2:

		ld		iy,copia_cara_activa_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

A_DAR_MONEDAS:		

		ld		a,15
		ld		(var_cuentas_peq),a										; INCLUIR REGALO

.LOOP_MONEDAS:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS	
			
		call	PINTA_BITNEDAS											; pinta el valor de las bitnedas
		
		ld		a,11
		ld		c,0
		call	EFECTO
		
		ld		ix,eventos_laberinto									; DESAPARECE DE LA CASILLA PARA QUE NADIE SE APROVECHE DE ÉL
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		xor		a
		ld		(ix),a

		di
		call  	stpmus
		ei
				
		jp		FINAL_DE_LUCHA											; SALTO A RUTINA DE FINAL

COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER:

		ld		a,(pagina_hater)
		cp		0
		jp		z,SUBE_0
		cp		1
		jp		z,SUBE_26
		cp		2
		jp		z,SUBE_52		

SUBE_78:

[26]	inc		ix

SUBE_52:

[26]	inc		ix

SUBE_26:

[26]	inc		ix

SUBE_0:

		push	ix
		pop		hl
		ret
		
DEFINE_DIRECTRICES_DE_CARA_HATER:

		ld		ix,copia_hater_cara
		ld		a,(pagina_hater)
		cp		0
		jp		z,NO_AUMENTAMOS_IX
		cp		1
		jp		z,IX_MAS_1
		cp		2
		jp		z,IX_MAS_2
		
IX_MAS_3:
		
[11]	inc		ix
		
IX_MAS_2:
		
[11]	inc		ix
				
IX_MAS_1:
		
[11]	inc		ix
		
NO_AUMENTAMOS_IX:
		
		ret
		
SI_LUCHA:	
																		; SI LUCHA
				
		ld		a,1														; activamos la mosca_activa
		ld		(mosca_activa),a
		
		ld		a,18
		ld		c,0
		call	EFECTO
		
		CALL	ACTIVA_MUSICA_HATER	
		
		ld		ix,TE_ATACO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,TE_ATACO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_ENFADADO
			
		call	STRIG_DE_CONTINUE										; PAUSA


ENEMIGO_ATACA:															; ENEMIGO ATACA
		
		ld		a,74
		ld		(mosca_x_objetivo),a
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	LIMPIA_VALORES_DE_LUCHA
	
		call	HATER_CARA_ENFADADO
				
		ld		a,r														; LANZA DADO
		and		00000111b
		
PINTAMOS_EL_DADO:
		
		ld		(valor_ataque_hater),a									; PASAMOS EL RESULTADO DEL DADO A SU VARIABLE
	

		ld		iy,copia_numero_hater									
		call	COPY_A_GUSTO
		
		ld		a,(valor_ataque_hater)
		ld		de, POINT_DADO_ATAQUE_HATER								; PINTA DADO ATAQUE
		jp		lista_de_opciones

ATAQUE_HATER_1:
		
		ld		a,1
		ld		(valor_ataque_hater),a
		ld		a,9
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2
		
ATAQUE_HATER_2:

		ld		a,16
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_3:

		ld		a,24
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_4:

		ld		a,32
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_5:

		ld		a,40
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_6:

		ld		a,6
		ld		(valor_ataque_hater),a
		ld		a,48
		ld		(ix),a

PINTAMOS_EL_DADO_2:

		ld		a,62
		ld		(ix+4),a
		ld		a,31
		ld		(ix+6),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
								
		ld		a,(nivel)												; PINTA RESULTADO FINAL
		ld		b,a
		ld		a,(valor_ataque_hater)
		add		a,b
		ld		(valor_ataque_final_hater),a

		call	DIRECTRICES_ATAQUE_FINAL_HATER							;pintamos el valor de la rectificacion de ataque hater
		ld		a,(valor_ataque_final_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
	
		ld		a,42
		ld		(mosca_y_objetivo),a
				
		ld		hl,LANZA_DEFENDER
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
										
		call	TIRAMOS_EL_DADO_PARA_PELEA								; PERSONAJE TIRA EL DADO PARA LA DEFENSA
			
		ld		a,1
		ld		(estado_pelea),a
		call	pasamos_el_valor_del_dado_de_defensa_al_contador		; SE PINTA RESULTADO DEL DADO Y DEFINITIVO EN DEFENSA
		xor		a
		ld		(estado_pelea),a
						
		ld		a,(defensa_real)										; COMPARA ATAQUE DE HATER CON DEFENSA DE PERSONAJE
		ld		b,a
		ld		a,(valor_ataque_final_hater)
		cp		b
		jp		z,FRACASO_EN_EL_ATAQUE_ENEMIGO
		jp		c,FRACASO_EN_EL_ATAQUE_ENEMIGO
					
EXITO_EN_EL_ATAQUE_ENEMIGO:												; EXITO EN EL ATAQUE
		
		ld		a,18													; SONIDO DE GOLPE RECIBIDO CON PRIORIDAD 2
		ld		c,0
		call	EFECTO
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_pierde_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		RESTA_VIDA_PERSONAJE

.pinta_jugador_2:

		ld		iy,copia_cara_pierde_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
RESTA_VIDA_PERSONAJE:
		
		ld		a,3
		ld		(paleta_a_usar_en_vblank),a
						
		ld		a,(defensa_real)										; RESTA VIDA A PERSONAJE
		ld		b,a
		ld		a,(valor_ataque_final_hater)
		sub		b
		cp		0
		jp		z,COMPROBAMOS_ESTADO_DEL_JUGADOR
		ld		(var_cuentas_peq),a
		
DESCONTAMOS_VIDA:
		
		ld		a,(vida_unidades)
		dec		a
		ld		(vida_unidades),a
		
		call	AJUSTA_VIDA_HACIA_ABAJO
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		or		a
		jp		nz,DESCONTAMOS_VIDA
		
		call	PINTA_VIDA												; PINTA VIDA
			
COMPROBAMOS_ESTADO_DEL_JUGADOR:

		ld		a,(vida_decenas)										; COMPRUEVA ESTADO
		ld		b,a
[2]		add		a,a
		add		b
		add		a
		ld		b,a
		ld		a,(vida_unidades)
		add		b

		cp		6
		jp		c,VIDA_INFERIOR_A_5
		jp		nc,VIDA_SUPERIOR_A_5
										
VIDA_INFERIOR_A_5:														; VIDA=<5


		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
	
		di
		call	stpmus
		ei
		
		ld		iy,copia_cara_pierde_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		MENSAJE_DEL_MALO

.pinta_jugador_2:

		ld		iy,copia_cara_pierde_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

MENSAJE_DEL_MALO:

		di
		call	stpmus
		ei
		
		ld		ix,TE_HIERO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,TE_HIERO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_FELIZ
				
		call	STRIG_DE_CONTINUE										; PAUSA
	
		xor		a														; RESTA DINERO
		ld		(bitneda_centenas),a
		ld		(bitneda_decenas),a
		ld		(bitneda_unidades),a
		
		call	PINTA_BITNEDAS											; PINTA DINERO

		xor		a														; QUITA OBJETOS
		ld		(brujula),a
		ld		a,14
		ld		(var_cuentas_peq),a
		ld		de,papel
		ld		a,0
		ld		(menu_de_lampara_trampa),a
		ld		a,(turno)
		cp		1
		jp		z,ORIGEN_1

ORIGEN_2:
		
		ld		a,(incremento_ataque_origen2)
		ld		(incremento_ataque),a
		ld		a,(incremento_defensa_origen2)
		ld		(incremento_defensa),a
		ld		a,(incremento_velocidad_origen2)
		ld		(incremento_velocidad),a

		jp		PINTA_ORIGENES

ORIGEN_1:

		ld		a,(incremento_ataque_origen1)
		ld		(incremento_ataque),a
		ld		a,(incremento_defensa_origen1)
		ld		(incremento_defensa),a
		ld		a,(incremento_velocidad_origen1)
		ld		(incremento_velocidad),a
				
PINTA_ORIGENES:
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de ataque
		ld		a,(incremento_ataque)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de defensa
		ld		a,(incremento_defensa)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
						
BORRA_OBJETOS:

		ld		bc,13
		ld		de,papel
		ld		hl,brujula
		ldir													
											
		ld		iy,cuadrado_que_limpia_101								; BORRA OBJETOS DE PANTALLA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		
		ld		a,(turno)
		cp		1
		jp		z,BORRA_OBJETOS_JUGADOR_1

BORRA_OBJETOS_JUGADOR_2:


		ld		a,#81
		ld		(ix+4),a
		
BORRA_OBJETOS_JUGADOR_1:		
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
		jp		FINAL_DE_LUCHA											; SALTO A RUTINA DE FINAL
					
VIDA_SUPERIOR_A_5:														; VIDA>5

		ld		ix,TE_HIERO_POCO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,TE_HIERO_POCO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_FELIZ
		
		call	STRIG_DE_CONTINUE										; PAUSA
						
		jp		PERSONAJE_ATACA											; SALTO A RUTINA DE PERSONAJE ATACA
						
FRACASO_EN_EL_ATAQUE_ENEMIGO:											; FRACASO EN EL ATAQUE

		ld		a,17													; SONIDO DE EVITA GOLPE
		ld		c,0
		call	EFECTO

		ld		ix,NO_TE_HIERO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,NO_TE_HIERO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		
		call	STRIG_DE_CONTINUE										; PAUSA
		
		jp		PERSONAJE_ATACA											; SALTO A LA RUTINA DE PERSONAJE ATACA
				
PERSONAJE_ATACA:														; PERSONAJE ATACA

		ld		hl,LANZA_ATACAR
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	HATER_CARA_ENFADADO
						
		call	LIMPIA_VALORES_DE_LUCHA
		ld		a,40
		ld		(ralentizando),a
		call	RALENTIZA
		call	TIRAMOS_EL_DADO_PARA_PELEA								; PERSONAJE TIRA EL DADO PARA EL ATAQUE
			
		ld		a,2
		ld		(estado_pelea),a
		call	pasamos_el_valor_del_dado_de_ataque_al_contador			; SE PINTA RESULTADO DEL DADO Y DEFINITIVO EN ATAQUE
		xor		a
		ld		(estado_pelea),a
		
		call	STRIG_DE_CONTINUE
		
		ld		a,r														; LANZA DADO PARA SU DEFENSA
		and		00000111b
		
PINTAMOS_EL_DADO_DEFENSA:
						
		ld		(valor_defensa_hater),a									; PASAMOS EL RESULTADO DEL DADO A SU VARIABLE
	
		ld		a,74
		ld		(mosca_x_objetivo),a
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		ld		iy,copia_numero_hater									
		call	COPY_A_GUSTO
		
		ld		a,(valor_defensa_hater)
		ld		de, POINT_DADO_DEFENSA_HATER							; PINTA DADO DEFENSA
		jp		lista_de_opciones

DEFENSA_HATER_1:
		
		ld		a,1
		ld		(valor_defensa_hater),a
		ld		a,9
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA
		
DEFENSA_HATER_2:

		ld		a,16
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_3:

		ld		a,24
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_4:

		ld		a,32
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_5:

		ld		a,40
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_6:

		ld		a,6
		ld		(valor_defensa_hater),a
		ld		a,48
		ld		(ix),a

PINTAMOS_EL_DADO_2_DEFENSA:

		ld		a,62
		ld		(ix+4),a
		ld		a,50
		ld		(ix+6),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
								
		ld		a,(nivel)												; PINTA RESULTADO FINAL
		ld		b,a
		ld		a,(valor_defensa_hater)
		add		a,b
		ld		(valor_defensa_final_hater),a

		call	DIRECTRICES_DEFENSA_FINAL_HATER							;pintamos el valor de la rectificacion de defensa hater
		ld		a,(valor_defensa_final_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
						
		ld		a,(ataque_real)											; COMPARA ATAQUE DE PERSONAJE CON DEFENSA DE HATER
		ld		b,a
		ld		a,(valor_defensa_final_hater)
		cp		b
		jp		nc,FRACASO_EN_EL_ATAQUE_PROPIO
					
EXITO_EN_EL_ATAQUE_PROPIO:												; EXITO EN EL ATAQUE

		ld		b,a														; RESTA VIDA A HATER
		ld		a,(ataque_real)
		sub		b
		ld		b,a
		ld		a,(vida_hater)
		sub		b
		cp		30
		jp		c,FIJAMOS_VALOR_VIDA_HATER
		
		xor		a
			
FIJAMOS_VALOR_VIDA_HATER:
		
		ld		(vida_hater),a

		ld		a,18													; SONIDO DE GOLPE CON PREFERENCIA 2
		ld		c,0
		call	EFECTO	
		
		call	DIRECTRICES_VIDA_HATER									; PINTA VIDA DE HATER
		ld		a,(vida_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS		

		ld		a,(vida_hater)											; COTEJA
		or		a
		jp		nz,VIDA_HATER_SUPERIOR_A_0
				
VIDA_HATER_INFERIOR_A_0:
													; VIDA=<0
		DI
		call	stpmus
		ei
				
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2


		
		ld		iy,copia_cara_activa_jugador_1					
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		RESOLUCION

.pinta_jugador_2:

		ld		iy,copia_cara_activa_jugador_2						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
RESOLUCION:
				
		ld		a,19													; SONIDO DE EXITO
		ld		c,0
		call	EFECTO	
								
		ld		ix,MUERO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,MUERO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_MUERTO
		
		ld		a,60
		ld		(var_cuentas_peq),a										; COGE LOS OBJETOS Y DINERO

.LOOP_MONEDAS:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS	
		
		call	PINTA_BITNEDAS											; pinta el valor de las bitnedas

		ld		a,11
		ld		c,0
		call	EFECTO		
						
		ld		ix,eventos_laberinto									; DESAPARECE DE LA CASILLA POR ESTAR MUERTO
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		xor		a
		ld		(ix),a
				
		call	STRIG_DE_CONTINUE										; PAUSA
		jp		FINAL_DE_LUCHA											; VE A FINAL DE LUCHA
						
VIDA_HATER_SUPERIOR_A_0:												; VIDA>0

		ld		ix,ME_HIERES_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,ME_HIERES_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_TRISTE
				
		call	STRIG_DE_CONTINUE										; PAUSA
		
		jp		ENEMIGO_ATACA											; SALTO A RUTINA DE ENEMIGO ATACA
						
FRACASO_EN_EL_ATAQUE_PROPIO:											; FRACASO EN EL ATAQUE

		ld		a,17													; SONIDO DE FALLO
		ld		c,0
		call	EFECTO

		ld		ix,NO_ME_HIERES_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,NO_ME_HIERES_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_FELIZ
				
		call	STRIG_DE_CONTINUE										; PAUSA
				
		jp		ENEMIGO_ATACA											; SALTO A RUTINA DE ENEMIGO ATACA
				
FINAL_DE_LUCHA:															; FINAL
		
		call	LIMPIA_VALORES_DE_LUCHA

		ld		iy,cuadrado_que_limpia_5								; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR
		
		xor		a														; CAMBIA PALETA A LABERINTO
		ld		(paleta_a_usar_en_vblank),a
		

		ld		iy,copia_escenario_a_page_0								; COPIAMOS EL LABERINTO EN PANTALLA OTRA VEZ
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a
						
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY							; REGRESA
		
		call	ACTIVA_MUSICA_JUEGO

pasamos_el_valor_del_dado_de_defensa_al_contador:


		ld		a,1
		ld		c,0
		call	EFECTO
		
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA
				
		ld		iy,cuadrado_que_limpia_4
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		bc,187
		ld		(ix+4),c												;x inicio linea
	
		call	PINTA_DIRECTRICES_DEL_COPY
				
		call	DIRECTRICES_VALOR_DADO
		ld		a,(dado)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
				
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
calcula_lo_que_puede_defenderse:

		ld		a,(dado)
		ld		b,a
		ld		a,(incremento_defensa)
		add		a,b
		ld		(defensa_real),a

Pintamos_la_defensa_real:

		ld		a,1
		ld		c,0
		call	EFECTO
				
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA

		call	DIRECTRICES_VALOR_MOVIMIENTO_REAL

		ld		a,(defensa_real)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
		ret

pasamos_el_valor_del_dado_de_ataque_al_contador:

		ld		a,1
		ld		c,1
		call	EFECTO
		
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA
				
		ld		iy,cuadrado_que_limpia_4
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		bc,187
		ld		(ix+4),c												;x inicio linea
	
		call	PINTA_DIRECTRICES_DEL_COPY
				
		call	DIRECTRICES_VALOR_DADO
		ld		a,(dado)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
				
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
calcula_lo_que_puede_atacar:

		ld		a,(dado)
		ld		b,a
		ld		a,(incremento_ataque)
		add		a,b
		ld		(ataque_real),a

Pintamos_el_ataque_real:

		ld		a,1
		ld		c,0
		call	EFECTO
				
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA

		call	DIRECTRICES_VALOR_MOVIMIENTO_REAL

		ld		a,(ataque_real)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
		ret

DIRECTRICES_VIDA_HATER:

		ld		ix,datos_del_copy
		ld		bc,14
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		bc,92
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
						
DIRECTRICES_ATAQUE_FINAL_HATER:
		
		ld		ix,datos_del_copy
		ld		bc,31
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		bc,92
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret

DIRECTRICES_DEFENSA_FINAL_HATER:
		
		ld		ix,datos_del_copy
		ld		bc,50
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		bc,92
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
		
TIRAMOS_EL_DADO_PARA_PELEA:

		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2

.pinta_jugador_1:		

		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		iy,copia_cara_ataque_jugador_1							; rutina especial de cara enfadado
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		TIRANDO_PARA_PELEA

.pinta_jugador_2:

		ld		a,229
		ld		(mosca_x_objetivo),a
		ld		iy,copia_cara_ataque_jugador_2							; rutina especial de cara enfadado
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
TIRANDO_PARA_PELEA:
		
		xor		a
		ld		c,0		
		call	EFECTO
		
		ld		a,1
		ld		(toca_dado),a
				
		call	DA_VALOR_AL_DADO		
		call	PINTA_EL_DADO_QUE_HA_SALIDO_parte_1
						
		xor		a
		call	GTTRIG
		cp		#FF
		ret		z
		
		ld		a,(turno)
		call	GTTRIG
		cp		#FF
		ret		z

		ld		a,4														
		call	SNSMAT
		bit		2,a
		call	z,QUIERE_ESCAPAR
		
		ld		a,(turno)
		add		2														; si le da al boton 2
		call	GTTRIG
		cp		#FF
		call	z,QUIERE_ESCAPAR
		
		jp		TIRANDO_PARA_PELEA

QUIERE_ESCAPAR:

		ld		a,(gallina)
		or		a
		jp		nz,LO_CONSIGUE

		ld		ix,NO_PUEDES_ESCAPAR_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		jp		STRIG_DE_CONTINUE

		ret

LO_CONSIGUE:
		
		pop		af														; sacamos de la pila el valor del último ret
		pop		af														; sacamos de la pila el valor del anterior
		
		ld		a,(gallina)
		dec		a
		ld		(gallina),a
		or		a
		jp		nz,MIRAMOS_SI_ES_LA_ULTIMA
		
		ld		iy,copia_gallina_en_objetos								; BORRA DIBUJO GALLILNA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos_sigue						; BORRA DIBUJO GALLILNA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		jp		MENSAJE_DE_COBARDE
		
MIRAMOS_SI_ES_LA_ULTIMA:
		
		cp		1
		jp		nz,MENSAJE_DE_COBARDE
		
		ld		iy,copia_gallina_en_objetos								; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		cp		1
		jp		z,.PINTAMOS
		
		ld		a,#e7
		ld		(ix+4),a
		
.PINTAMOS:		
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos_sigue						; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		cp		1
		jp		z,.PINTAMOS_2
		
		ld		a,#e7
		ld		(ix+4),a
		
.PINTAMOS_2:		
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
MENSAJE_DE_COBARDE:		

		ld		ix,COBARDE_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,COBARDE_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_gallina_en_objetos_1								; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos_2								; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
		jp		FINAL_DE_LUCHA
		
LIMPIA_VALORES_DE_LUCHA:

		ld		iy,cuadrado_que_limpia_final_hater						; BORRA RESULTADO FINAL DEFENSA Y ATAQUE HATER
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,cuadrado_que_limpia_result_at_def					; BORRA RESULTADO DEFENSA Y ATAQUE DE JUGADOR
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,cuadrado_que_limpia_final_at_def						; BORRA RESULTADO FINAL DEFENSA Y ATAQUE DE JUGADOR
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,cuadrado_que_limpia_dados_hater						; BORRA DADOS_HATER
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		a,11010000b
		ld		(ix+14),a
		
		ret
					
ENCUENTRA_TINTA:

		ld		a,(tinta)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la brújula al jugador
		ld		(tinta),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a

		ld		iy,copia_tinta_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,TINTA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PLUMA_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_tinta_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO

		
		call	COMPRUEBA_TURNO_EN_OBJETO_2

		
		ld		c,#a5													;corregimos la posición de la brújula para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_LLAVE:

		ld		a,1														;le damos la llave al jugador
		ld		(llave),a

		ld		iy,copia_llave_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla						;no la quitamos de la casilla (otro jugador la puede coger)

		ld		hl,LLAVE_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,LLAVE_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_llave_en_objetos								; pintamos la llave entre los objetos
		CALL	COPY_DE_OBJETO

		
		call	COMPRUEBA_TURNO_EN_OBJETO_2

		
		ld		c,#8d													;corregimos la posición de la llave para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5


ENCUENTRA_LUPA:

		ld		a,(lupa)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la brújula al jugador
		ld		(lupa),a

		ld		iy,copia_lupa_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,LUPA_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,LUPA_2_ESP

		call	TEXTO_A_ESCRIBIR
					
		ld		iy,copia_lupa_en_objetos								; pintamos la lupa entre los objetos
		CALL	COPY_DE_OBJETO

		
		call	COMPRUEBA_TURNO_EN_OBJETO_2

		
		ld		c,#82				 									;corregimos la posición de la lupa para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_BOTAS:

		ld		a,(botas)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(botas_esp)
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la bota al jugador
		ld		(botas),a
		
		ld		a,(incremento_velocidad)
		inc		a
		ld		(incremento_velocidad),a

		ld		iy,copia_botas_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,BOTA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,BOTA_2_ESP

		call	TEXTO_A_ESCRIBIR
							
		ld		iy,copia_botas_en_objetos								; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		ld		a,5
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		c,#C0													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5


ENCUENTRA_BOTAS_ESP:
		
		ld		a,(botas_esp)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(botas)
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la bota especiales al jugador
		ld		(botas_esp),a


		
		ld		a,(incremento_velocidad)
		add		2
		ld		(incremento_velocidad),a

		ld		iy,copia_botas_esp_en_objetos							; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,BOTA_ESP_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,BOTA_2_ESP

		call	TEXTO_A_ESCRIBIR
					
		ld		iy,copia_botas_esp_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		ld		a,5
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
				
		ld		c,#C0													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_PERRO:

		ld		a,(perro)											;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
				
		ld		a,1														;le damos el cuchillo al jugador
		ld		(perro),a
				
		ld		hl,PERRO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PERRO_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,PERRO_3_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PERRO_4_ESP
		call	TEXTO_A_ESCRIBIR

		ld		a,(turno)
		cp		1
		jp		z,.EL_UNO
.EL_DOS:

		ld		de,GRAFICO_PERRO
		ld		hl,copia_perro_2										; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC

		jp		ENCUENTRA_BRUJULA_1_5
		
.EL_UNO:
				
		ld		de,GRAFICO_PERRO
		ld		hl,copia_perro_1										; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		jp		ENCUENTRA_BRUJULA_1_5
		
ENCUENTRA_CUCHILLO:

		ld		a,(cuchillo)											;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(espada)												;si tiene la espada, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos el cuchillo al jugador
		ld		(cuchillo),a
		
		ld		a,(incremento_ataque)
		inc		a
		ld		(incremento_ataque),a

		ld		iy,copia_cuchillo_en_objetos							; pintamos el cuchillo pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de fuerza
		ld		a,(incremento_ataque)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,CUCHILLO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,CUCHILLO_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_cuchillo_en_objetos							; pintamos el cuchillo entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a

		
		ld		c,#b2													;corregimos la posición de el cuchillo para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_ESPADA:

		ld		a,(espada)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(cuchillo)
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la bota especiales al jugador
		ld		(espada),a
		
		ld		a,(incremento_ataque)
		add		2
		ld		(incremento_ataque),a

		ld		iy,copia_espada_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_ataque)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,ESPADA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,CUCHILLO_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_espada_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a

		
		ld		c,#b2													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_ARMADURA:

		ld		a,(armadura)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
				
		ld		a,1														;le damos la bota especiales al jugador
		ld		(armadura),a
		
		ld		a,(incremento_defensa)
		inc		a
		ld		(incremento_defensa),a

		ld		iy,copia_armadura_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_defensa)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,ARMADURA_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,ARMADURA_2_ESP

		call	TEXTO_A_ESCRIBIR
				
		ld		iy,copia_armadura_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a

		
		ld		c,#a5													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_CASCO:

		ld		a,(casco)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
				
		ld		a,1														;le damos la bota especiales al jugador
		ld		(casco),a
		
		ld		a,(incremento_defensa)
		inc		a
		ld		(incremento_defensa),a

		ld		iy,copia_casco_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_defensa)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,CASCO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,ARMADURA_2_ESP

		call	TEXTO_A_ESCRIBIR
					
		ld		iy,copia_casco_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		c,#9a													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_BITNEDA:
		
		ld		a,(bitneda_centenas)
		cp		2
		ret		z
		
		ld		a,(bitneda_unidades)									; le damos una bitneda al jugador
		inc		a
		ld		(bitneda_unidades),a

		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		
		ld		iy,copia_bitneda_en_objetos								; pintamos la bitneda pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,BITNEDA_1_ESP
		call	TEXTO_A_ESCRIBIR
	
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	PINTA_BITNEDAS											; lo mandamos a secuencia de pintar las bitnedas
		
		ld		a,11
		ld		c,0
		jp		EFECTO

ENCUENTRA_MANZANA:
				
		ld		a,(vida_unidades)										; le damos una vida al jugador
		inc		a
		ld		(vida_unidades),a

		call	AJUSTA_VIDA												; controla valor de unidades a DECENAS
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		
		ld		iy,copia_manzana_en_objetos								; pintamos la manzana pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,MANZANA_1_ESP
		call	TEXTO_A_ESCRIBIR

		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	PINTA_VIDA												; lo mandamos a secuencia de pintar las vidas
		
		ld		a,11
		ld		c,0
		jp		EFECTO
		
ENCUENTRA_SUPERBITNEDA:

		ld		a,(bitneda_centenas)
		cp		2
		ret		z
		
		ld		a,5
		ld		(var_cuentas_peq),a

.LOOP_MONEDAS:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		
		ld		iy,copia_bitnedas_en_objetos							; pintamos las 5 bitnedas pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,BITNEDAS_1_ESP
		call	TEXTO_A_ESCRIBIR

		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR				
		call	PINTA_BITNEDAS											; lo mandamos a secuencia de pintar las bitnedas
		
		ld		a,11
		ld		c,0
		jp		EFECTO

ENCUENTRA_TRAMPA:
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		ld		a,30													; creamos un efecto raro de movimiento
		ld		(tiembla_el_decorado_v),a

		ld		iy,copia_trampa_en_pantalla								; pintamos la trampa en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
				
		ld		a,7
		ld		(var_cuentas_peq),a
		
.LOOP_DE_VIDA:
		
		ld		a,(vida_unidades)										; resta 4 puntos de vida al personaje
		dec		a
		ld		(vida_unidades),a
		
		call	AJUSTA_VIDA_HACIA_ABAJO
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_DE_VIDA
		
		call	PINTA_VIDA

		ld		hl,TRAMPA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TRAMPA_2_ESP

		call	TEXTO_A_ESCRIBIR				
		
		ld		a,13
		ld		c,0		
		jp		EFECTO
						
ENCUENTRA_AGUJERO_NEGRO:
		
		ld		hl,(casilla_destino_agujero_negro)						; le damos el valor de la casilla destino
		ld		(posicion_en_mapa),hl
		ld		a,(x_map_destino_agujero_negro)
		ld		(x_map),a
		ld		a,(y_map_destino_agujero_negro)
		ld		(y_map),a
						
		ld		a,4
		ld		(var_cuentas_peq),a
		
		ld		hl,AGUJERO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,AGUJERO_2_ESP		
		call	TEXTO_A_ESCRIBIR
				
		call	STRIG_DE_CONTINUE
				
.LOOP_DE_VIDA:

		ld		a,100
		ld		(tiembla_el_decorado_v),a
				
		ld		a,(vida_unidades)										; resta 4 puntos de vida al personaje
		dec		a
		ld		(vida_unidades),a
			
		call	AJUSTA_VIDA_HACIA_ABAJO
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_DE_VIDA
		
		call	PINTA_VIDA
			
		ld		a,13
		ld		c,0		
		call	EFECTO
		
		pop		af														;extraemos de la pila el valor de regreso de ret
		
		jp		se_pinta_el_mapa
								
SECUENCIA_PINTA_OBJETO_EN_TABLERO:

		CALL	COPY_DE_OBJETO
		
		ld		c,#78													;corregimos la posición de la brújula para pantalla de juego
		ld		b,#00
		ld		(ix+4),c
		ld		(ix+5),b
		ld		c,#60													;corregimos la posición de la brújula para pantalla de juego
		ld		b,#00
		ld		(ix+6),c
		ld		(ix+7),b		
		ld		a,10011000b
		ld		(ix+14),a
		
		call	RECTIFICACION_POR_PAGE_0		
		
		jp		HL_DATOS_DEL_COPY_CALL_DOCOPY
		
COMPRUEBA_TURNO_EN_OBJETO:

		ld		a,(turno)												; comprobamos de quién es el turno
		cp		1
		jp		z,ENCUENTRA_BRUJULA_2
		
		ret

COMPRUEBA_TURNO_EN_OBJETO_2:

		ld		a,(turno)												; comprobamos de quién es el turno
		cp		1
		jp		z,ENCUENTRA_BRUJULA_2_5
		
		ret
				
COPY_DE_OBJETO:

		CALL	COPY_A_GUSTO
		
		ld		a,10010000b												; nos aseguramos que copia mediante LMMM
		ld		(ix+14),a
		
		ret
						
AJUSTA_BITNEDAS:

		ld		a,(bitneda_centenas)
		cp		9
		jp		z,MANTEN_LA_CANTIDAD
		
		ld		a,(bitneda_unidades)									; comprobamos si las unidades pasan de 9
		cp		10
		ret		nz
		
		xor		a														; ponemos las unidades a 0
		ld		(bitneda_unidades),a
		ld		a,(bitneda_decenas)										; aumentamos las decenas
		inc		a
		ld		(bitneda_decenas),a										; comprobamos si las decenas pasan de 9
		cp		10
		ret		nz
		
		xor		a														; ponemos las decenas a 0
		ld		(bitneda_decenas),a	
		ld		a,(bitneda_centenas)									; aumentamos las centenas
		inc		a
		ld		(bitneda_centenas),a

		RET

MANTEN_LA_CANTIDAD:
		
		xor		a
		ld		(bitneda_decenas),a
		ld		(bitneda_unidades),a
		
		ret

AJUSTA_VIDA:

		ld		a,(vida_unidades)									; comprobamos si las unidades pasan de 9
		cp		10
		ret		nz
		
		xor		a														; ponemos las unidades a 0
		ld		(vida_unidades),a
		ld		a,(vida_decenas)										; aumentamos las decenas
		inc		a
		ld		(vida_decenas),a										; comprobamos si las decenas pasan de 9
		cp		10
		ret		nz
		dec		a
		ld		(vida_decenas),a		
		ret
		
AJUSTA_BITNEDAS_HACIA_ABAJO:

		ld		a,(bitneda_unidades)									; comprobamos si las unidades pasan de 0 por abajo
		cp		255
		ret		nz
		
		ld		a,9														; ponemos las unidades a 9
		ld		(bitneda_unidades),a
		ld		a,(bitneda_decenas)										; reducimos las decenas
		dec		a
		ld		(bitneda_decenas),a										; comprobamos si las decenas pasan de 0 por abajo
		cp		255
		ret		nz
		
		ld		a,9														; ponemos las decenas a 9
		ld		(bitneda_decenas),a	
		ld		a,(bitneda_centenas)									; reducimos las centenas
		dec		a
		ld		(bitneda_centenas),a
		
		ret
		
AJUSTA_VIDA_HACIA_ABAJO:

		ld		a,(vida_unidades)										; comprobamos si las unidades inferior a 0
		cp		255
		ret		nz
		
		ld		a,9														; ponemos las unidades a 9
		ld		(vida_unidades),a
		ld		a,(vida_decenas)										; reducimos las decenas
		dec		a
		ld		(vida_decenas),a										
		
		cp		255
		jp		z,MUERTE
		
		ret
		
PINTA_BITNEDAS:

		ld		ix,datos_del_copy
		ld		bc,69
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		xor		a
		ld		(ix+13),a												;cómo es el copy	
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,36
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_BITNEDAS_CONTINUACION
		
.ZONA_JUG_2:
		
		ld		bc,245
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_BITNEDAS_CONTINUACION:
		
		ld		a,(bitneda_unidades)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1

		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,28
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_BITNEDAS_CONTINUACION_2
		
.ZONA_JUG_2:
		
		ld		bc,237
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_BITNEDAS_CONTINUACION_2:
		
		ld		a,(bitneda_decenas)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1

		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,20
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_BITNEDAS_CONTINUACION_3
		
.ZONA_JUG_2:
		
		ld		bc,229
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_BITNEDAS_CONTINUACION_3:
		
		ld		a,(bitneda_centenas)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		jp		COPIA_NUMEROS
						

PINTA_VIDA:

		ld		ix,datos_del_copy
		ld		bc,88
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		xor		a
		ld		(ix+13),a												;cómo es el copy	
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,36
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_VIDA_CONTINUACION
		
.ZONA_JUG_2:
		
		ld		bc,245
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_VIDA_CONTINUACION:
		
		ld		a,(vida_unidades)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1

		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,28
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_VIDA_CONTINUACION_2
		
.ZONA_JUG_2:
		
		ld		bc,237
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_VIDA_CONTINUACION_2:
		
		ld		a,(vida_decenas)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		jp		COPIA_NUMEROS
		
PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE:

		ld		bc,40
		ld		de,secuencia_de_letras
		ldir

		ret	

CODIGO_A_ESCRIBIR:
		
		ld		bc,26
		ld		de,secuencia_de_letras
		ldir

		jp		ESCRIBIMOS_CODIGO
				
TEXTO_A_ESCRIBIR:
		
		ld		bc,40
		ld		de,secuencia_de_letras
		ldir
		
		jp		ESCRIBIMOS_EN_GENERAL

AVISO_DE_NO_SALIDA:

		ld		hl,NO_SALIDA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO		
		call	TEXTO_A_ESCRIBIR
		ld		a,1
		ld		(no_borra_texto),a
		ret
		
AVISO_DE_NO_SALIDA_EN_LA_SALIDA:

		ld		hl,NO_SALIDA_EN_SALIDA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,NO_SALIDA_EN_SALIDA_2_ESP
		call	TEXTO_A_ESCRIBIR
		ld		a,1
		ld		(no_borra_texto),a
		ret
							
MUERTE:
				
		pop		af

		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_pierde_jugador_1							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		CONTINUA_MUERTE

.pinta_jugador_2:

		ld		iy,copia_cara_pierde_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

CONTINUA_MUERTE:
		
		di
		call	stpmus
		ei

		ld		a,3
		ld		(que_musica_0),a
		
		call	MUSICA_HAS_MUERTO
				
		ld		a,(set_page01)
		or		a
		jp		z,.limpia_en_0

.limpia_en_1:

		ld		iy,cuadrado_que_limpia_5_1
		jp		.sigue

.limpia_en_0:
				
		ld		iy,cuadrado_que_limpia_5								; BORRA PANTALLA DE JUEGO

.sigue:

		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR
				
		ld		a,5														;indicamos a la interrupción de vblanck el cambio de paleta
		ld		(paleta_a_usar_en_vblank),a
				
		call	PINTAMOS_PROTA_MUERTO	

		ld		hl,ME_MUERO_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_4_ESP

		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE
		
		ld		hl,ME_MUERO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_2_ESP

		call	TEXTO_A_ESCRIBIR
											
		call	STRIG_DE_CONTINUE

		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z, REINICIANDO_EL_JUEGO
		
		ld		hl,ME_MUERO_5_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_6_ESP

		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,ME_MUERO_7_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_8_ESP

		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE
				
REINICIANDO_EL_JUEGO:

		di
		xor		a
		ld		[#6000],a		
		ei
		
		call	DISSCR

		di
		call	stpmus													;paramos la música
		ei
		
		ld		hl,BORRA_PANTALLA_1										;Borrando la2 página2 1-3 por si había restos
[3]		call	DoCopy
		
		jp		VAMOS_A_SELECCION_DE_MENU												
						
TEXTO_DE_INICIO_UN_JUGADOR:

		ld		hl,COMIENZA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COMIENZA_2_ESP
		call	TEXTO_A_ESCRIBIR
		
		ld		a,1
		ld		(no_borra_texto),a
		ret

TEXTO_DE_INICIO_DOS_JUGADORES:

		ld		hl,COMIENZAN_2_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COMIENZAN_2_2_ESP
		call	TEXTO_A_ESCRIBIR
		
		ld		a,1
		ld		(no_borra_texto),a
		ret

GOLPE_EN_LA_PARED:

		ld		a,3
		ld		(paleta_a_usar_en_vblank),a
		
		ld		hl,GOLPE_CONTRA_PARED_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		ld		a,1
		ld		(no_borra_texto),a
		
		ret

FINAL_DEL_JUEGO:

		di
		xor		a
		ld		[#6000],a		
		ei
		
		call	DISSCR

		di
		call	stpmus													;paramos la música
		ei
		
		ld		hl,BORRA_PANTALLA_1										;Borrando la2 página2 1-3 por si había restos
[3]		call	DoCopy
		
		ld		a,1
		ld		(salto_historia),a
		jp		VAMOS_A_SELECCION_DE_MENU	
							
cuadrado_que_limpia_101:						dw		#0000,#0000,#0036,#0080,#004B,#001a ; BORRA ZONA DE OBJETOS PARCIAL

copia_brujula_en_objetos:						dw		#0001,#0272,#0037,#0080,#000d,#000d
copia_gallina_en_objetos:						dw		#007f,#0280,#001c,#006a,#000d,#000d
copia_gallina_en_objetos_sigue:					dw		#007f,#0280,#011c,#006a,#000d,#000d
copia_gallinas_en_objetos:						dw		#00dd,#0264,#001c,#006a,#000d,#000d
copia_gallina_en_objetos_1:						dw		#001c,#006a,#001c,#016a,#000d,#000d
copia_gallina_en_objetos_2:						dw		#00e7,#006a,#00e7,#016a,#000d,#000d
copia_trampa_en_objetos:						dw		#0071,#0280,#0008,#006a,#000d,#000d
copia_trampas_en_objetos:						dw		#00cf,#0264,#0008,#006a,#000d,#000d
copia_trampa_en_objetos_1:						dw		#0008,#006a,#0008,#016a,#000d,#000d
copia_trampa_en_objetos_2:						dw		#00d3,#006a,#00d3,#016a,#000d,#000d
copia_papel_en_objetos:							dw		#0010,#0272,#0044,#0080,#000c,#000d
copia_tinta_en_objetos:							dw		#002b,#0272,#0050,#0080,#000d,#000d
copia_pluma_en_objetos:							dw		#001e,#0272,#005c,#0080,#000c,#000d
copia_llave_en_objetos:							dw		#0039,#0272,#0068,#0080,#000d,#000d
copia_lupa_en_objetos:							dw		#0048,#0272,#0076,#0080,#000c,#000d
copia_botas_en_objetos:							dw		#0056,#0272,#0037,#008C,#000C,#000d
copia_botas_esp_en_objetos:						dw		#0064,#0272,#0037,#008C,#000C,#000d
copia_cuchillo_en_objetos:						dw		#0071,#0272,#0044,#008C,#000C,#000d
copia_espada_en_objetos:						dw		#007f,#0272,#0044,#008C,#000d,#000d
copia_armadura_en_objetos:						dw		#0001,#0280,#0050,#008C,#000C,#000d
copia_casco_en_objetos:							dw		#0010,#0280,#005c,#008C,#000C,#000d
copia_bitneda_en_objetos:						dw		#001e,#0280,#0050,#008C,#000C,#000d
copia_bitnedas_en_objetos:						dw		#002b,#0280,#005c,#008C,#000C,#000d
copia_trampa_en_pantalla:						dw		#0071,#0280,#005c,#008C,#000C,#000d
copia_manzana_en_objetos:						dw		#0063,#0280,#005c,#008C,#000C,#000d

copia_cara_neutra_jugador_1:					dw		#0000,#0375,#000C,#009D,#002A,#0028
copia_cara_neutra_jugador_2:					dw		#0000,#039e,#00CC,#009D,#002A,#0028
copia_cara_activa_jugador_1:					dw		#002c,#0375,#000C,#009D,#002A,#0028
copia_cara_activa_jugador_2:					dw		#002c,#039e,#00CC,#009D,#002A,#0028
copia_cara_ataque_jugador_1:					dw		#0057,#0375,#000C,#009D,#002A,#0028
copia_cara_ataque_jugador_2:					dw		#0057,#039e,#00CC,#009D,#002A,#0028
copia_cara_pierde_jugador_1:					dw		#0082,#0375,#000C,#009D,#002A,#0028
copia_cara_pierde_jugador_2:					dw		#0082,#039e,#00CC,#009D,#002A,#0028
copia_perro_1:									dw		#0056,#00bc,#0010,#000b
												db		#00,#00,#F0
copia_perro_2:									dw		#009e,#00bc,#0010,#000b
												db		#00,#00,#F0

GRAFICO_PERRO:			incbin		"SR5/LABERINTO/PERRO_16X11.DAT"
															
POINT_DIREC_VIAJIGUIA:		dw	OESTE
							dw	NORTE
							dw	ESTE
							dw	NOROESTE
							dw	NORTE
							dw	NORESTE
							dw	SUROESTE
							dw	SUR
							dw	SURESTE

POINT_DADO_ATAQUE_HATER:	dw	ATAQUE_HATER_1
							dw	ATAQUE_HATER_1
							dw	ATAQUE_HATER_2
							dw	ATAQUE_HATER_3
							dw	ATAQUE_HATER_4
							dw	ATAQUE_HATER_5
							dw	ATAQUE_HATER_6
							dw	ATAQUE_HATER_6

POINT_DADO_DEFENSA_HATER:	dw	DEFENSA_HATER_1
							dw	DEFENSA_HATER_1
							dw	DEFENSA_HATER_2
							dw	DEFENSA_HATER_3
							dw	DEFENSA_HATER_4
							dw	DEFENSA_HATER_5
							dw	DEFENSA_HATER_6
							dw	DEFENSA_HATER_6
														
POINT_LETRAS:				dw	ESPACIO		; 00		00000
							dw	A			; 01		00001
							dw	B			; 02		00010
							dw	C			; 03		00011	
							dw	D			; 04		00100
							dw	E			; 05		00101
							dw	F			; 06		00110
							dw	G			; 07		00111
							dw	H			; 08		01000
							dw	I			; 09		01001
							dw	J			; 10		01010
							dw	K			; 11 		01011
							dw	L			; 12		01100
							dw	M			; 13		01101
							dw	N			; 14 		01110
							dw	O			; 15		01111
							dw	P			; 16		10000
							dw	Q			; 17		10001
							dw	R			; 18		10010
							dw	S			; 19		10011
							dw	T			; 20		10100
							dw	U			; 21		10101
							dw	V			; 22		10110
							dw	W			; 23		10111
							dw	X			; 24		11000
							dw	Y			; 25		11001
							dw	Z			; 26		11010
							dw	DOS_PUNTOS	; 27		11011
							dw	PUNTO		; 28		11100
							dw	ACENTO		; 29		11101
							dw	RABITO_N	; 30		11110
							dw	PASA_CARRO	; 31		11111

POINT_CODIGO:				dw	A
							dw	B			
							dw	C			
							dw	D			
							dw	E			
							dw	F			
							dw	G			
							dw	H			
							dw	I		
							dw	J			
							dw	K		
							dw	L			
							dw	M			
							dw	N		
							dw	O		
							dw	P			
										
POINT_ESCRIBE_NOMBRE:		dw	NATPU									; 1
							dw	FERGAR									; 2
							dw	CRIRA									; 3
							dw	VICMAR									; 4

POINT_NIVEL_HATER:			dw	NIVEL_HATER_0							; 0
							dw	NIVEL_HATER_1							; 1
							dw	NIVEL_HATER_2							; 2
							dw	NIVEL_HATER_3							; 3
							dw	NIVEL_HATER_4							; 4

; ALGUNOS RECURSOS

copia_mas_igual:			dw	#000f,#0017,#0046,#0017,#001B,#0022
copia_corazon:				dw	#0012,#0058,#0052,#000f,#0008,#0006
copia_numero:				dw	#0000,#0090,#0000,#0000,#0008,#0008	
copia_numero_hater:			dw	#0000,#0290,#0000,#00B8,#0008,#0008

copia_escenario_a_page_1:	dw	#0036,#000C,#0036,#010C,#0094,#006A

copia_pulsa_espacio:		dw	#00Ae,#00B6,#0010,#0012
							db	#00,#00,#F0
							
cuadrado_que_limpia_PULSA_ESPACIO:

							dw	#0000,#0000,#00ae,#00B6,#0010,#0012
																			
PULSA_ESPACIO:		incbin		"SR5/MENU/PULSA ESPACIO_16x18.DAT"

; TEXTOS HATERS

HOLA_HATER_1_ESP:			incbin		"TEXTOS/hh1es1.DAT"		; Soy Frinky. Esta es mi zona.
							incbin		"TEXTOS/hh1es2.DAT"		; Soy Phantover. Esta es mi zona.
							incbin		"TEXTOS/hh1es3.DAT"		; Acho tío. Soy Conchi.
							incbin		"TEXTOS/hh1es4.DAT"		; Soy Kutreport. Estos son mis tiles.
HOLA_HATER_2_ESP:			incbin		"TEXTOS/hh2ES1.DAT"		; Déjame ver tu estandarte.		
							incbin		"TEXTOS/hh2ES2.DAT"		; Dime a quién adoras.			
							incbin		"TEXTOS/hh2ES3.DAT"		; Dime tu estandarte.		
							incbin		"TEXTOS/hh2ES4.DAT"		; Qué estandarte veneras.			
PREMIO_HATER_1_ESP:			incbin		"TEXTOS/ph1ES1.DAT"		; Por Nichi. Eres de los míos.
							incbin		"TEXTOS/ph1ES2.DAT"		; Anda. Como yo. Mejor. Ya no	
							incbin		"TEXTOS/ph1ES3.DAT"		; Ah. Comolmío. Pos te
							incbin		"TEXTOS/ph1ES4.DAT"		; Sí señor. Eres un tío de fiar.
PREMIO_HATER_2_ESP:			incbin		"TEXTOS/ph2ES1.DAT"		; acepta este regalo.
							incbin		"TEXTOS/ph2ES2.DAT"		; tengo edad para liarme a tetazos.
							incbin		"TEXTOS/ph2ES3.DAT"		; doy bitnedas.
							incbin		"TEXTOS/ph2ES4.DAT"		; Usa estas bitnedas como quieras.
TE_HIERO_HATER_1_ESP:		incbin		"TEXTOS/thh1ES1.DAT"	; Eres blando como las teclas de
							incbin		"TEXTOS/thh1ES2.DAT"	; Eso por mirarme los pellejos.     
							incbin		"TEXTOS/thh1ES3.DAT"	; Pa que aprendas. coño.
							incbin		"TEXTOS/thh1ES4.DAT"	; Ja ja ja. Y sin usar sprites.
TE_HIERO_HATER_2_ESP:		incbin		"TEXTOS/thh2ES1.DAT"	; un spectrum. Me quedo tus cosas.
							incbin		"TEXTOS/thh2ES2.DAT"	; me quedo con todo lo que tienes.    
							incbin		"TEXTOS/thh2ES3.DAT"	; Y me quedo tus cosas.
							incbin		"TEXTOS/thh2ES4.DAT"	; me quedo tus pertenencias.
NO_TE_HIERO_HATER_1_ESP:	incbin		"TEXTOS/nthh1ES1.DAT"	; Eres más difícil de pillar
							incbin		"TEXTOS/nthh1ES2.DAT"	; No me evites o de un mamellazo
							incbin		"TEXTOS/nthh1ES3.DAT"	; No te apartes que si no me
							incbin		"TEXTOS/nthh1ES4.DAT"	; Eres más rápido que yo. Claro. 
NO_TE_HIERO_HATER_2_ESP:	incbin		"TEXTOS/nthh2ES1.DAT"	; que el assembly estate quieto.
							incbin		"TEXTOS/nthh2ES2.DAT"	; te voy a hundir en la miseria.
							incbin		"TEXTOS/nthh2ES3.DAT"	; Cuesta absorverte con el coño.
							incbin		"TEXTOS/nthh2ES4.DAT"	; como soy un cutreport... 
TE_HIERO_POCO_HATER_1_ESP:	incbin		"TEXTOS/thph1ES1.DAT"	; prepárate porque esto es sólo
							incbin		"TEXTOS/thph1ES2.DAT"	; toma golpe de chumino
							incbin		"TEXTOS/thph1ES3.DAT"	; Ah. Toma. Hahahahahaha.
							incbin		"TEXTOS/thph1ES4.DAT"	; Toma ya. Y sin necesidad de 
TE_HIERO_POCO_HATER_2_ESP:	incbin		"TEXTOS/thph2ES1.DAT"	; el principio de tu sufrimiento.
							incbin		"TEXTOS/thph2ES2.DAT"	; fofo y descolgado.
							incbin		"TEXTOS/thph2ES3.DAT"	; Ahora con la pepitilla.
							incbin		"TEXTOS/thph2ES4.DAT"	; colorinchis estúpidos. 
TE_ATACO_HATER_1_ESP:		incbin		"TEXTOS/tah1ES1.DAT"	; Vaya una mierda veneras.
							incbin		"TEXTOS/tah1ES2.DAT"	; Pero qué mal gusto.
							incbin		"TEXTOS/tah1ES3.DAT"	; Ah. Esa es horrible: No es
							incbin		"TEXTOS/tah1ES4.DAT"	; Vivís de ports del nuestro.
TE_ATACO_HATER_2_ESP:		incbin		"TEXTOS/tah2ES1.DAT"	; Te vas a cagar.	
							incbin		"TEXTOS/tah2ES2.DAT"	; Ni Luís Royo adoraría eso.
							incbin		"TEXTOS/tah2ES3.DAT"	; verde. Ahora te follo.
							incbin		"TEXTOS/tah2ES4.DAT"	; Ahora te voy a dar caña. 
ME_HIERES_HATER_1_ESP:		incbin		"TEXTOS/mhh1ES1.DAT"	; Ostia. Me has dado en la VRAM.
							incbin		"TEXTOS/mhh1ES2.DAT"	; Coño. Qué daño. Ni azpiri
							incbin		"TEXTOS/mhh1ES3.DAT"	; Ah. Mha dolío. Te voy a dar
							incbin		"TEXTOS/mhh1ES4.DAT"	; Qué daño. Se me ha caído un 
ME_HIERES_HATER_2_ESP:		incbin		"TEXTOS/mhh2ES1.DAT"	; prepárate que ahora me toca a mí.
							incbin		"TEXTOS/mhh2ES2.DAT"	; me trataba así. Ahora verás.
							incbin		"TEXTOS/mhh2ES3.DAT"	; Con un kilómetro de coño.
							incbin		"TEXTOS/mhh2ES4.DAT"	; tile de la vram y todo. 
NO_ME_HIERES_HATER_1_ESP:	incbin		"TEXTOS/nmhh1ES1.DAT"	; Tienes menos fuerza que una
							incbin		"TEXTOS/nmhh1ES2.DAT"	; Estás más senil que yo. Ahora te
							incbin		"TEXTOS/nmhh1ES3.DAT"	; Pos si no mhas dao.
							incbin		"TEXTOS/nmhh1ES4.DAT"	; ja ja ja. Mi capacidad para	
NO_ME_HIERES_HATER_2_ESP:	incbin		"TEXTOS/nmhh2ES1.DAT"	; GAME BOY. Prepárate.
							incbin		"TEXTOS/nmhh2ES2.DAT"	; ataco con el bote de sintrom.
							incbin		"TEXTOS/nmhh2ES3.DAT"	; Vaya mierda golpe.
							incbin		"TEXTOS/nmhh2ES4.DAT"	; camuflar mis colores te confunde. 
MUERO_HATER_1_ESP:			incbin		"TEXTOS/mh1ES1.DAT"		; haggg. Mi BIOS. No es posible.
							incbin		"TEXTOS/mh1ES2.DAT"		; No vale. Me he enredado con
							incbin		"TEXTOS/mh1ES3.DAT"		; Ah. Se mha luxao el coño.
							incbin		"TEXTOS/mh1ES4.DAT"		; Nooooo. No volveré a portar un
MUERO_HATER_2_ESP:			incbin		"TEXTOS/mh2ES1.DAT"		; siempre odiaré tu estandarte.
							incbin		"TEXTOS/mh2ES2.DAT"		; el pelo. Dame un peine.
							incbin		"TEXTOS/mh2ES3.DAT"		; Pero volveré.
							incbin		"TEXTOS/mh2ES4.DAT"		; juego y dejarlo sin música.
COBARDE_1_ESP:				incbin		"TEXTOS/c1ES1.DAT"		; No huyas gallina o te meto el
							incbin		"TEXTOS/c1es2.DAT"		; Si te vuelvo a ver te rajo
							incbin		"TEXTOS/c1ES3.DAT"		; Ande vaaaaaaas.
							incbin		"TEXTOS/c1ES4.DAT"		; Cobarde. Luego os quejáis si no
COBARDE_2_ESP:				incbin		"TEXTOS/c2ES1.DAT"		; Estandarte en el puerto del ratón.
							incbin		"TEXTOS/c2ES2.DAT"		; la cara con un pezón.
							incbin		"TEXTOS/c2ES3.DAT"		; Galliiiiiiina.
							incbin		"TEXTOS/c2ES4.DAT"		; hacen juegos para vuestro sistema.
NO_PUEDES_ESCAPAR_ESP:		incbin		"TEXTOS/npeES1.DAT"		; No puedes escapar de mí.
							incbin		"TEXTOS/npeES2.DAT"		; Ni lo intentes o te meto.
							incbin		"TEXTOS/npeES3.DAT"		; Que te lo has creío.
							incbin		"TEXTOS/npeES4.DAT"		; Eso no va a ocurrir.
LANZA_ATACAR:				incbin		"TEXTOS/ldpa.DAT"		; Lanza el dado para atacar.							
LANZA_DEFENDER:				incbin		"TEXTOS/ldpd.DAT"		; Lanza el dado para defenderte.							

; TEXTOS POCHADEROS

HOLA_POCHADA_1_ESP:			incbin		"TEXTOS/hp1neESP.DAT"	; Choy Némechich el pochadero.
							incbin		"TEXTOS/hp1piESP.DAT"	; Choy Pichi la pochadera.
							incbin		"TEXTOS/hp1cuESP.DAT"	; Choy Chumi el pochadero.
							incbin		"TEXTOS/hp1caESP.DAT"	; Choy Chari la pochadera.
HOLA_POCHADA_2_ESP:			incbin		"TEXTOS/hp2neesp.DAT"	; Puedo venderte una nave.
							incbin		"TEXTOS/hp2piesp.DAT"	; Te puedo bailar una polka.
							incbin		"TEXTOS/hp2cuesp.DAT"	; Dime qué puedo hacher por ti.
							incbin		"TEXTOS/hp2caesp.DAT"	; Tengo unoch tapetech muy baratoch.
BUENAS_NOCHES_ESP:			incbin		"TEXTOS/bnneesp.DAT"	; Que chueñech con echtrellach.
							incbin		"TEXTOS/bnpiesp.DAT"	; Te achigno la habitachión rocha.
							incbin		"TEXTOS/bncuesp.DAT"	; Buenach nochech.
							incbin		"TEXTOS/bncaesp.DAT"	; Te he preparado la camita.
NO_PUEDES_COMPRAR_ESP:		incbin		"TEXTOS/npcneesp.DAT"	; Te faltan bitnedach para echo.
							incbin		"TEXTOS/npcpiesp.DAT"	; No puedech pagarlo.
							incbin		"TEXTOS/npccuesp.DAT"	; No tienech fondoch para echo.
							incbin		"TEXTOS/npccaesp.DAT"	; Cariño, no pudech comprar echo.
ADIOS_ESP:					incbin		"TEXTOS/aneesp.DAT"		; Que el echpachio te acompañe.
							incbin		"TEXTOS/apiesp.DAT"		; que te vaya bonito.
							incbin		"TEXTOS/acuesp.DAT"		; hachta otra.
							incbin		"TEXTOS/acaesp.DAT"		; Echpero verte pronto, bonito.
GRACIAS_ESP:				incbin		"TEXTOS/gneesp.DAT"		; De regalo, un pin de konami.
							incbin		"TEXTOS/gpiesp.DAT"		; Tu dinero ech bienvenido.
							incbin		"TEXTOS/gcuesp.DAT"		; Grachiach por tu compra.
							incbin		"TEXTOS/gcaesp.DAT"		; Por comprar te regalo un tapete.
PASAR_LA_NOCHE_ESP:			incbin		"TEXTOS/plnESP.DAT"		; una noche cuechta treinta bitnedach.
PAGA_30_ESP:				incbin		"TEXTOS/p30ESP.DAT"		; echto cuechta treinta bitnedach.
PAGA_60_ESP:				incbin		"TEXTOS/p60ESP.DAT"		; echto cuechta chechenta bitnedach.
PAGA_90_ESP:				incbin		"TEXTOS/p90ESP.DAT"		; echto cuechta noventa bitnedach.
SALIR_ESP:					incbin		"TEXTOS/sESP.DAT"		; echta ech la puerta de chalida.
TRAMPA_COMP_1_ESP:			incbin		"TEXTOS/TC1ESP.DAT"		; Trampa: pulsa space o fire durante				
TRAMPA_COMP_2_ESP:			incbin		"TEXTOS/TC2ESP.DAT"		; un desplazamiento para colocarla.
ESTANTE_VACIO_ESP:			incbin		"TEXTOS/EVESP.DAT"		; Este estante está vacío.

; TEXTOS DEL PERGAMINO

NO_PUEDE_ESCRIBIR_ESP:		incbin		"TEXTOS/npeESP.DAT"		; Busca pluma y tinta para pintar aquí
NO_TIENES_PAPEL_ESP:		incbin		"TEXTOS/ntpESP.DAT"		; Aún no dispones del pergamino
TRAMPA_SI_1_ESP:			incbin		"TEXTOS/TS1ESP.DAT"		; Colocas una trampa en esa zona.
TRAMPA_SI_2_ESP:			incbin		"TEXTOS/TS2ESP.DAT"		; El siguiente visitante sufrirá.				
TRAMPA_NO_1_ESP:			incbin		"TEXTOS/TN1ESP.DAT"		; No es una zona adecuada para
TRAMPA_NO_2_ESP:			incbin		"TEXTOS/TN2ESP.DAT"		; poner trampas. Se ve demasiado.

; TEXTOS SOBRE OBJETOS
							
BRUJULA_1_ESP:				incbin		"TEXTOS/bruju1.DAT"		; has encontrado una brújula:
BRUJULA_2_ESP:				incbin		"TEXTOS/bruju2.DAT"		; ahora puedes localizar el norte			
LLAVE_1_ESP:				incbin		"TEXTOS/llave1.DAT"		; has encontrado la llave:						
LLAVE_2_ESP:				incbin		"TEXTOS/llave2.DAT"		; úsala para salir de la mazmorra				
TINTA_1_ESP:				incbin		"TEXTOS/tinta.DAT"		; has encontrado un tintero:						
PLUMA_1_ESP:				incbin		"TEXTOS/pluma.DAT"		; has encontrado una pluma:						
PLUMA_2_ESP:				incbin		"TEXTOS/tinplu.DAT"		; indispensable para pintar mapas				
PAPIRO_1_ESP:				incbin		"TEXTOS/perga1.DAT"		; has encontrado un pergamino:
PAPIRO_2_ESP:				incbin		"TEXTOS/perga2.DAT"		; consúltalo con: tecla M o botón dos			
ESPADA_1_ESP:				incbin		"TEXTOS/espada.DAT"		; has encontrado una espada:					
CUCHILLO_1_ESP:				incbin		"TEXTOS/daga.DAT"		; has encontrado un cuchillo:					
CUCHILLO_2_ESP:				incbin		"TEXTOS/espadaga.DAT"	; aumenta tu ataque								
BOTA_ESP_1_ESP:				incbin		"TEXTOS/botasra.DAT"	; has encontrado unas botas rápidas:			
BOTA_1_ESP:					incbin		"TEXTOS/botas.DAT"		; has encontrado unas botas:						
BOTA_2_ESP:					incbin		"TEXTOS/botbotra.DAT"	; aumentan tu velocidad		
BITNEDA_1_ESP:				incbin		"TEXTOS/bitneda.DAT"	; has encontrado una bitneda					
BITNEDAS_1_ESP:				incbin		"TEXTOS/bitnedas.DAT"	; has encontrado cinco bitnedas				
CASCO_1_ESP:				incbin		"TEXTOS/casco.DAT"		; has encontrado un casco:					
ARMADURA_1_ESP:				incbin		"TEXTOS/armadura.DAT"	; has encontrado una armadura:				
ARMADURA_2_ESP:				incbin		"TEXTOS/arm2esp.DAT"	; aumenta tu defensa en un punto				
MANZANA_1_ESP:				incbin		"TEXTOS/manzana.DAT"	; una pieza de fruta mejora tu vida
LUPA_1_ESP:					incbin		"TEXTOS/lampara1.DAT"	; has encontrado una lámpara:				
LUPA_2_ESP:					incbin		"TEXTOS/lampara2.DAT"	; acaba turno con space o botón uno
AGUJERO_1_ESP:				incbin		"TEXTOS/aguneg1.DAT"	; has caido en un agujero negro:	
AGUJERO_2_ESP:				incbin		"TEXTOS/aguneg2.DAT"	; apareces en otra zona de la mazmorra		
TRAMPA_1_ESP:				incbin		"TEXTOS/trampa1.DAT"	; has caido en una trampa				
TRAMPA_2_ESP:				incbin		"TEXTOS/trampa2.DAT"	; pierdes bastante vida
GALLINA_ESP:				incbin		"TEXTOS/gallina.DAT"	; Evita una reyerta con M o botón dos
PERRO_1_ESP:				incbin		"TEXTOS/perr1esp.DAT"	; Te haces amigo de un perro
PERRO_2_ESP:				incbin		"TEXTOS/perr2esp.DAT"	; abandonado. Seguro que te ayuda. 
PERRO_3_ESP:				incbin		"TEXTOS/perr3esp.DAT"	; Rastrea jugadores pulsando space 
PERRO_4_ESP:				incbin		"TEXTOS/perr4esp.DAT"	; o botón 1 mientras ves el mapa.
BOTAS_CU:					incbin		"TEXTOS/bmuavesp.DAT"	; Botas. Más uno en velocidad.
BOTAS_ESP_CU:				incbin		"TEXTOS/bemdaesp.DAT"	; Botas especiales. Más dos en velocidad.
CUCHILLO_CU:				incbin		"TEXTOS/cmuaaesp.DAT"	; Cuchillo. Más uno en ataque.
ESPADA_CU:					incbin		"TEXTOS/emdaaesp.DAT"	; Espada. Más dos en ataque.
CASCO_CU:					incbin		"TEXTOS/cmuadesp.DAT"	; Casco. Más uno en defensa acumulable.
ARMADURA_CU:				incbin		"TEXTOS/amuadesp.DAT"	; Armadura. Más uno en defensa acumulable.

; TEXTOS SOBRE LA PARTIDA

COMIENZA_1_ESP:				incbin		"TEXTOS/c1ESP.DAT"		; Comienza la aventura. Encuentra
COMIENZA_2_ESP:				incbin		"TEXTOS/c2ESP.DAT"		; El camino hacia las catacumbas.
COMIENZAN_2_1_ESP:			incbin		"TEXTOS/c21ESP.DAT"		; Comienza el enfrentamiento. Sal
COMIENZAN_2_2_ESP:			incbin		"TEXTOS/c22ESP.DAT"		; el primero de esta mazmorra.
GOLPE_CONTRA_PARED_ESP:		incbin		"TEXTOS/gcpESP.DAT"		; Aunch. Cómo duele.
TERMINA_TURNO_ESP:			incbin		"TEXTOS/ttESP.DAT"		; Has decidido acabar aquí tu turno.
NO_SALIDA_EN_SALIDA_1_ESP:	incbin		"TEXTOS/nses1ESP.DAT"	; La puerta de salida está cerrada
NO_SALIDA_EN_SALIDA_2_ESP:	incbin		"TEXTOS/nses2ESP.DAT"	; y no podrás salir sin la llave.
NO_SALIDA_1_ESP:			incbin		"TEXTOS/ns1ESP.DAT"		; esta puerta está inutilizada.
ME_MUERO_1_ESP:				incbin		"TEXTOS/mm1ESP.DAT"		; Has muerto. 
ME_MUERO_2_ESP:				incbin		"TEXTOS/mm2ESP.DAT"		; Fin de la partida.
ME_MUERO_3_ESP:				incbin		"TEXTOS/mm3ESP.DAT"		; Tu cadáver será encontrado dentro de
ME_MUERO_4_ESP:				incbin		"TEXTOS/mm4ESP.DAT"		; diez años sobre un teclado ochentero.
ME_MUERO_5_ESP:				incbin		"TEXTOS/mm5ESP.DAT"		; tu contrincante tendrá que soportar
ME_MUERO_6_ESP:				incbin		"TEXTOS/mm6ESP.DAT"		; un bochorno terrible.
ME_MUERO_7_ESP:				incbin		"TEXTOS/mm7ESP.DAT"		; El de ganar porque tú has perdido.
ME_MUERO_8_ESP:				incbin		"TEXTOS/mm8ESP.DAT"		; pobre. Qué penita nos da a todos.
TEXTO_EN_BLANCO:			incbin		"TEXTOS/tebESP.DAT"		; (No escribe nada)
HAY_ALGUIEN_ESP:			incbin		"TEXTOS/haesp.DAT"		; Aqui hay alguien.
FIN_DE_TURNO_ESP:			incbin		"TEXTOS/fdtesp.DAT"		; Se acabó el turno.
AVISO_CODIGO_ESP1:			incbin		"TEXTOS/acesp1.DAT"		; coge papel y pluma y
AVISO_CODIGO_ESP2:			incbin		"TEXTOS/acesp2.DAT"		; apunta el siguiente código	
AVISO_CODIGO_ESP3:			incbin		"TEXTOS/acesp3.DAT"		; te servirá para iniciar tu
AVISO_CODIGO_ESP4:			incbin		"TEXTOS/acesp4.DAT"		; aventura desde aquí.
HAS_GANADO_1_ESP:			incbin		"TEXTOS/hg1esp1.DAT"	; La suerte sonríe a Natpu.
							incbin		"TEXTOS/hg1esp2.DAT"	; Fergar es el campeón de la jornada
							incbin		"TEXTOS/hg1esp3.DAT"	; No hay una campeona más completa
							incbin		"TEXTOS/hg1esp4.DAT"	; Vicmar nos complace con su
HAS_GANADO_2_ESP:			incbin		"TEXTOS/hg2esp1.DAT"	; Es el momento de celebrarlo.
							incbin		"TEXTOS/hg2esp2.DAT"	; El gorg debe correr a raudales.
							incbin		"TEXTOS/hg2esp3.DAT"	; que Crira. Es la mejor.
							incbin		"TEXTOS/hg2esp4.DAT"	; triunfo. Es un ganador nato.
HAS_GANADO_3_ESP:			incbin		"TEXTOS/hg3esp1.DAT"	; MIentras Natpu se emborracha
							incbin		"TEXTOS/hg3esp2.DAT"	; Dejémosle emborrachándose mientras
							incbin		"TEXTOS/hg3esp3.DAT"	; Brindemos por su tenacidad y
							incbin		"TEXTOS/hg3esp4.DAT"	; Los 8 bits salven su alma
HAS_GANADO_4_ESP:			incbin		"TEXTOS/hg4esp1.DAT"	; anunciamos el fin de la partida.
							incbin		"TEXTOS/hg4esp2.DAT"	; damos por finalizada la partida.
							incbin		"TEXTOS/hg4esp3.DAT"	; demos por terminado el juego.
							incbin		"TEXTOS/hg4esp4.DAT"	; al terminar este juego.
PASA_MAZMORRA_ESP:			incbin		"TEXTOS/pf1jesp.DAT"	; vamos a la siguiente mazmorra.							

; TEXTOS SOBRE LOS VIEJIGUIAS

SOY_ANDRES_SAMUDIO_ESP_1:	incbin		"TEXTOS/sasesp1.DAT"	; soy ansam. el viejiguía.
SOY_CESAR_ASTUDILLO_ESP_1:	incbin		"TEXTOS/scaesp1.DAT"	; soy ceas. el viejiguía.	
SOY_CAROL_SHAW_ESP_1:		incbin		"TEXTOS/scsesp1.DAT"	; soy casha. la viejiguía.	
SOY_JENNELL_JAQUAYS_ESP_1:	incbin		"TEXTOS/sjjesp1.DAT"	; soy jeja. la viemiguía.	
SOY_ANDRES_SAMUDIO_ESP_2:	incbin		"TEXTOS/sasesp2.DAT"	; señor de las conversacionales.	
SOY_CESAR_ASTUDILLO_ESP_2:	incbin		"TEXTOS/scaesp2.DAT"	; músico insuperable.	
SOY_CAROL_SHAW_ESP_2:		incbin		"TEXTOS/scsesp2.DAT"	; diosa del vuelo entre ríos.	
SOY_JENNELL_JAQUAYS_ESP_2:	incbin		"TEXTOS/sjjesp2.DAT"	; creadora de kong.	
VIEJIGUIA_POCHADA_ESP:		incbin		"TEXTOS/vpesp.DAT"		; encontrarás una bonita pochada				
VIEJIGUIA_LLAVE_ESP:		incbin		"TEXTOS/vlesp.DAT"		; encontrarás la preciada llave
VIEJIGUIA_SALIDA_ESP:		incbin		"TEXTOS/vsesp.DAT"		; encontrarás la ansiada salida				
N_ESP:						incbin		"TEXTOS/norte.DAT"		; si viajas hacia el norte					
NE_ESP:						incbin		"TEXTOS/noreste.DAT"	; si viajas hacia el noreste			
E_ESP:						incbin		"TEXTOS/este.DAT"		; si viajas hacia el este
SE_ESP:						incbin		"TEXTOS/sureste.DAT"	; si viajas hacia el sureste
S_ESP:						incbin		"TEXTOS/sur.DAT"		; si viajas hacia el sur
SO_ESP:						incbin		"TEXTOS/suroeste.DAT"	; si viajas hacia el suroeste
O_ESP:						incbin		"TEXTOS/oeste.DAT"		; si viajas hacia el oeste
NO_ESP:						incbin		"TEXTOS/noroeste.DAT"	; si viajas hacia el noroeste

; TEXTOS SOBRE LA PELEA 

COINCIDE_1_ESP:				incbin		"TEXTOS/co1esp.DAT"		; Te encuentras con otro humano.
COINCIDE_2_ESP:				incbin		"TEXTOS/co2esp.DAT"		; Tus intenciones son...
HOSTIL_AMISTOSO_1_ESP:		incbin		"TEXTOS/ha1esp.DAT"		; espacio o boton 1 : hostiles.
HOSTIL_AMISTOSO_2_ESP:		incbin		"TEXTOS/ha2esp.DAT"		; M o boton 2: amistosas.
RESPUESTA_1_ESP:			incbin		"TEXTOS/r1esp.DAT"		; Ha aparecido alguien amigable.
ATRINCHERA_1_ESP:			incbin		"TEXTOS/atr1esp.DAT"	; Pasáis la noche al raso
ATRINCHERA_2_ESP:			incbin		"TEXTOS/atr2esp.DAT"	; haciendo guardias.
ATRINCHERA_3_ESP:			incbin		"TEXTOS/atr3esp.DAT"	; Recuperáis energías y al
ATRINCHERA_4_ESP:			incbin		"TEXTOS/atr4esp.DAT"	; amanecer seguís vuestro camino.
COMPARA_1_ESP:				incbin		"TEXTOS/com1esp.DAT"	; haceis amistad y acabais
COMPARA_2_ESP:				incbin		"TEXTOS/com2esp.DAT"	; comparando vuestros mapas.
COMPARA_3_ESP:				incbin		"TEXTOS/com3esp.DAT"	; ahora los dos tenéis el mismo
COMPARA_4_ESP:				incbin		"TEXTOS/com4esp.DAT"	; mapa, pero más completo.
DEDUCE_1_ESP:				incbin		"TEXTOS/ded1esp.DAT"	; comparando los mapas os
DEDUCE_2_ESP:				incbin		"TEXTOS/ded2esp.DAT"	; dais cuenta de tres cosas:
DEDUCE_3_ESP:				incbin		"TEXTOS/ded3esp.DAT"	; dónde deben estar las salidas
DEDUCE_4_ESP:				incbin		"TEXTOS/ded4esp.DAT"	; llaves y pochadas. lo apuntáis.
INTERCAMBIAN_1_ESP:			incbin		"TEXTOS/int1esp.DAT"	; Como paisanos del mismo pueblo
INTERCAMBIAN_2_ESP:			incbin		"TEXTOS/int2esp.DAT"	; decidís compartir ganancias.
INTERCAMBIAN_3_ESP:			incbin		"TEXTOS/int3esp.DAT"	; El que más bitnedas tiene
INTERCAMBIAN_4_ESP:			incbin		"TEXTOS/int4esp.DAT"	; ayudará al que menos tiene.
BORRA_1_ESP:				incbin		"TEXTOS/bor1esp.DAT"	; Te acercas amistosamente.
BORRA_2_ESP:				incbin		"TEXTOS/bor2esp.DAT"	; Pero en un descuidos...
BORRA_3_ESP:				incbin		"TEXTOS/bor3esp.DAT"	; Borras su mapa con la mano
BORRA_4_ESP:				incbin		"TEXTOS/bor4esp.DAT"	; mojada y sales corriendo.
QUITA_TURNO_1_ESP:			incbin		"TEXTOS/qtu1esp.DAT"	; Aprovechas un momento de
QUITA_TURNO_2_ESP:			incbin		"TEXTOS/qtu2esp.DAT"	; descuido de tu oponente y...
QUITA_TURNO_3_ESP:			incbin		"TEXTOS/qtu3esp.DAT"	; Le golpeas en la cabeza.
QUITA_TURNO_4_ESP:			incbin		"TEXTOS/qtu4esp.DAT"	; El pobre descansará un turno.
QUITA_1_ESP:				incbin		"TEXTOS/qui1esp.DAT"	; Te acercas sibilinamente
QUITA_2_ESP:				incbin		"TEXTOS/qui2esp.DAT"	; mostrándote amistoso...
QUITA_3_ESP:				incbin		"TEXTOS/qui3esp.DAT"	; En cuanto se confía, tiras
QUITA_4_ESP:				incbin		"TEXTOS/qui4esp.DAT"	; de su zurrón y sales corriendo.

; TEXTOS PELEAS FINALES

TROMAXE_01:					incbin		"TEXTOS/troma01.DAT"	; Soy Tromaxe. Quién eres tú.
TROMAXE_021:				incbin		"TEXTOS/troma021.DAT"	; Soy Fergar.
TROMAXE_022:				incbin		"TEXTOS/troma022.DAT"	; Soy Natpu.
TROMAXE_023:				incbin		"TEXTOS/troma023.DAT"	; Soy Crira.
TROMAXE_024:				incbin		"TEXTOS/troma024.DAT"	; Soy Vicmar.
TROMAXE_03:					incbin		"TEXTOS/troma03.DAT"	; de la ciudad de Viejunos.
TROMAXE_04:					incbin		"TEXTOS/troma04.DAT"	; Y vengo a acabar
TROMAXE_05:					incbin		"TEXTOS/troma05.DAT"	; con todos los cotorras.
TROMAXE_06:					incbin		"TEXTOS/troma06.DAT"	; ja, ja, ja. Qué petulante.
TROMAXE_07:					incbin		"TEXTOS/troma07.DAT"	; Antes tendrás que pasar
TROMAXE_08:					incbin		"TEXTOS/troma08.DAT"	; por encima de mi cadaver.
TROMAXE_09:					incbin		"TEXTOS/troma09.DAT"	; Puta mosca. Sal de aquí.
TROMAXE_10:					incbin		"TEXTOS/troma10.DAT"	; Muere, retroperro!
TROMAXE_11:					incbin		"TEXTOS/troma11.DAT"	; Oh. Me has hecho correr tanto 
TROMAXE_12:					incbin		"TEXTOS/troma12.DAT"	; que he adelgazado. Mil gracias.
TROMAXE_13:					incbin		"TEXTOS/troma13.DAT"	; como recompensa, te dejaré pasar
TROMAXE_14:					incbin		"TEXTOS/troma14.DAT"	; a la siguiente mazmorra.
TROMAXE_15:					incbin		"TEXTOS/troma15.DAT"	; gracias, pero...
TROMAXE_16:					incbin		"TEXTOS/troma16.DAT"	; qué era eso negro que me lanzabas.
TROMAXE_17:					incbin		"TEXTOS/troma17.DAT"	; fundas de ordenadores.
TROMAXE_18:					incbin		"TEXTOS/troma18.DAT"	; las usaba para atacar
TROMAXE_19:					incbin		"TEXTOS/troma19.DAT"	; a los habitantes de viejunos
TROMAXE_20:					incbin		"TEXTOS/troma20.DAT"	; creo que ahora
TROMAXE_21:					incbin		"TEXTOS/troma21.DAT"	; me dedicaré a venderlas.
TROMAXE_22:					incbin		"TEXTOS/troma22.DAT"	; por cierto.
TROMAXE_23:					incbin		"TEXTOS/troma23.DAT"	; el paso a la siguiente mazmorra
TROMAXE_24:					incbin		"TEXTOS/troma24.DAT"	; es muy estrecho.
TROMAXE_25:					incbin		"TEXTOS/troma25.DAT"	; tendrás que dejar todas tus pertenencias.
TROMAXE_26:					incbin		"TEXTOS/troma26.DAT"	; llévate sólo el zurrón con 
TROMAXE_27:					incbin		"TEXTOS/troma27.DAT"	; las bitnedas. Las vas a necesitar.

ONIRIKUS_01:				incbin		"TEXTOS/onir01.DAT"		; Soy Onirikus.
ONIRIKUS_02:				incbin		"TEXTOS/onir02.DAT"		; Yo soy...
ONIRIKUS_03:				incbin		"TEXTOS/onir03.DAT"		; Picha. Me importa una mierda.
ONIRIKUS_04:				incbin		"TEXTOS/onir04.DAT"		; Te voy a joder más que una
ONIRIKUS_05:				incbin		"TEXTOS/onir05.DAT"		; procesión por debajo de tu casa.
ONIRIKUS_06:				incbin		"TEXTOS/onir06.DAT"		; Está bien. Me rindo.
ONIRIKUS_07:				incbin		"TEXTOS/onir07.DAT"		; De dónde sacas tantos niños.
ONIRIKUS_08:				incbin		"TEXTOS/onir08.DAT"		; Son todos míos. Soy muy fecundo.
ONIRIKUS_09:				incbin		"TEXTOS/onir09.DAT"		; Pues nada. A cuidarlos todos.
ONIRIKUS_10:				incbin		"TEXTOS/onir10.DAT"		; No sé de dónde voy a sacar tiempo
ONIRIKUS_11:				incbin		"TEXTOS/onir11.DAT"		; para programar.

SALGUERI_01:				incbin		"TEXTOS/salg01.DAT"		; Soy salueri, el temible.
SALGUERI_021:				incbin		"TEXTOS/salg021.DAT"	; tú debes ser Fergar.
SALGUERI_022:				incbin		"TEXTOS/salg022.DAT"	; tú debes ser Natpu.
SALGUERI_023:				incbin		"TEXTOS/salg023.DAT"	; tú debes ser Crira.
SALGUERI_024:				incbin		"TEXTOS/salg024.DAT"	; tú debes ser Vicmar.
SALGUERI_03:				incbin		"TEXTOS/salg03.DAT"		; no tienes nada que hacer contra mí.
SALGUERI_04:				incbin		"TEXTOS/salg04.DAT"		; muestra tu arma.
SALGUERI_051:				incbin		"TEXTOS/salg051.DAT"	; tengo piedras.
SALGUERI_052:				incbin		"TEXTOS/salg052.DAT"	; tengo este puñal.
SALGUERI_053:				incbin		"TEXTOS/salg053.DAT"	; tengo esta espada.
SALGUERI_06:				incbin		"TEXTOS/salg06.DAT"		; vaya una mierda de arma.
SALGUERI_07:				incbin		"TEXTOS/salg07.DAT"		; me voy a divertir contigo.
SALGUERI_08:				incbin		"TEXTOS/salg08.DAT"		; vaya. con tant ostia lo veo
SALGUERI_09:				incbin		"TEXTOS/salg09.DAT"		; todo diferente.
SALGUERI_10:				incbin		"TEXTOS/salg10.DAT"		; ya no quiero acabar con los sistemas.
SALGUERI_11:				incbin		"TEXTOS/salg11.DAT"		; prefiero hacer juegos como churros.
SALGUERI_12:				incbin		"TEXTOS/salg12.DAT"		; gracias.
SALGUERI_13:				incbin		"TEXTOS/salg13.DAT"		; de nada, pero...
SALGUERI_14:				incbin		"TEXTOS/salg14.DAT"		; qué eran esas cosas
SALGUERI_15:				incbin		"TEXTOS/salg15.DAT"		; cuadradas que me tirabas.
SALGUERI_16:				incbin		"TEXTOS/salg16.DAT"		; cartuchos. alguien dijo que me
SALGUERI_17:				incbin		"TEXTOS/salg17.DAT"		; quedé con todas las existencias.
SALGUERI_18:				incbin		"TEXTOS/salg18.DAT"		; ya que me criticaban igualmente
SALGUERI_19:				incbin		"TEXTOS/salg19.DAT"		; decidí robarlas todas.
SALGUERI_20:				incbin		"TEXTOS/salg20.DAT"		; ahora creo que las llenaré
SALGUERI_21:				incbin		"TEXTOS/salg21.DAT"		; con juegos del pasado.


LUCKYLUKEB_01:				incbin		"TEXTOS/luck01.DAT"		; oy Luckylukeb.
LUCKYLUKEB_02:				incbin		"TEXTOS/luck02.DAT"		; el terrible, el abominable...
LUCKYLUKEB_03:				incbin		"TEXTOS/luck03.DAT"		; el enemigo final, vamos.
LUCKYLUKEB_04:				incbin		"TEXTOS/luck04.DAT"		; en resumen: si me vences
LUCKYLUKEB_05:				incbin		"TEXTOS/luck05.DAT"		; se acaba el juego.
LUCKYLUKEB_061:				incbin		"TEXTOS/luck061.DAT"	; pues no he llegado hasta aquí
LUCKYLUKEB_062:				incbin		"TEXTOS/luck062.DAT"	; para perder.
LUCKYLUKEB_07:				incbin		"TEXTOS/luck07.DAT"		; cañña. ,arocón.
LUCKYLUKEB_08:				incbin		"TEXTOS/luck08.DAT"		; te voy a poner el culo
LUCKYLUKEB_09:				incbin		"TEXTOS/luck09.DAT"		; como la bandera de japón.
LUCKYLUKEB_10:				incbin		"TEXTOS/luck10.DAT"		; ups. He hecho un pareado.
LUCKYLUKEB_11:				incbin		"TEXTOS/luck11.DAT"		; el que nace artista...
LUCKYLUKEB_12:				incbin		"TEXTOS/luck12.DAT"		; para, para, para...
LUCKYLUKEB_13:				incbin		"TEXTOS/luck13.DAT"		; está bien. Me rindo.
LUCKYLUKEB_14:				incbin		"TEXTOS/luck14.DAT"		; no entiendo por qué has hecho
LUCKYLUKEB_15:				incbin		"TEXTOS/luck15.DAT"		; todo esto.
LUCKYLUKEB_16:				incbin		"TEXTOS/luck16.DAT"		; por qué odias al resto de
LUCKYLUKEB_17:				incbin		"TEXTOS/luck17.DAT"		; sistemas.
LUCKYLUKEB_18:				incbin		"TEXTOS/luck18.DAT"		; yo no los odio. pero el juego
LUCKYLUKEB_19:				incbin		"TEXTOS/luck19.DAT"		; está lleno de personajes reales.
LUCKYLUKEB_20:				incbin		"TEXTOS/luck20.DAT"		; no querrás que ponga de enemigo
LUCKYLUKEB_21:				incbin		"TEXTOS/luck21.DAT"		; final a otro y que se acabe enfandando.
LUCKYLUKEB_22:				incbin		"TEXTOS/luck22.DAT"		; ya sabes cómo somos los de msx
LUCKYLUKEB_23:				incbin		"TEXTOS/luck23.DAT"		; bueno. Esperemos que este juego
LUCKYLUKEB_24:				incbin		"TEXTOS/luck24.DAT"		; sirva para hermanar sistemas.
LUCKYLUKEB_25:				incbin		"TEXTOS/luck25.DAT"		; Empecemos por hermanarnos entre
LUCKYLUKEB_26:				incbin		"TEXTOS/luck26.DAT"		; nosotros y ya luego vamos viendo.
LUCKYLUKEB_27:				incbin		"TEXTOS/luck27.DAT"		; Si sales por esta puerta podrás
LUCKYLUKEB_28:				incbin		"TEXTOS/luck28.DAT"		; acceder al final del juego


MUERTE_1:					incbin		"TEXTOS/muer1esp.dat"	; ja, ja, ja. Nunca os libraréis
MUERTE_2:					incbin		"TEXTOS/muer2esp.dat"	; de nosotros los COTORRAS.

; TEXTOS NOBRES PROPIOS

NOMBRE_NATPU_ESP:			incbin		"TEXTOS/nnesp.DAT"		; turno de Natpu
NOMBRE_FERGAR_ESP:			incbin		"TEXTOS/nfesp.DAT"		; turno de Fergar
NOMBRE_CRIRA_ESP:			incbin		"TEXTOS/ncesp.DAT"		; turno de Crira
NOMBRE_VICMAR_ESP:			incbin		"TEXTOS/nvesp.DAT"		; turno de Vicmar

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 20 DEL MEGAROM **********)))

; ______________________________________________________________________

; (((********** PAGINA 21 DEL MEGAROM **********
	
; DIBUJO DE HATER 1 y 2

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

COPIAMOS_HATER1:						incbin		"SR5/HATERS/HATER1CARA_148x106.DAT"		
COPIAMOS_HATER2:						incbin		"SR5/HATERS/HATER2CARA_148x106.DAT"	

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 21 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 22 DEL MEGAROM **********

; MUSICAS HATERS	
; SECUENCIA DE MIRAR MAPA	

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

		
MUSICA_HATER:	incbin	"MUSICAS/HATER.MBM"
		
MIRAMOS_EL_PAPIRO_SECUENCIA:
								
		ld		a,1														;indicamos a la interrupción de vblanck el cambio de paleta
		ld		(paleta_a_usar_en_vblank),a
		
		CALL	RESCATAMOS_EL_PERGAMINO
		
		ld		a,0
		ld		(set_page01),a
		
		call	ENASCR		
		
		ld		a,(tinta)
		or		a
		jp		z,ESPERA_PARA_VOLVER_SIN_OBJETOS

		ld		a,(pluma)
		or		a
		jp		z,ESPERA_PARA_VOLVER_SIN_OBJETOS
								
COMPROBAMOS_JUGADOR_PARA_PINTAR_MAPA:

		ld		a,(turno)
		cp		1
		jp		nz,MAPA_DOS

MAPA_UNO:

		ld		ix,act_mapa_1
		jp		FINAL_COMUN
		
MAPA_DOS:

		ld		ix,act_mapa_2

FINAL_COMUN:

		ld		a,53
		ld		(x_pinta_mapa),a
		ld		a,27
		ld		(y_pinta_mapa),a
		
DESCUBRIMOS_LO_QUE_HAY_EN_LA_CASILLA:		
		
		ld		a,(ix)
		cp		#FF
		jp		z,AUMENTOS
		ld 		de,POINT_CASILLAS_MAPA_A_DIBUJAR
		push	ix
		call	lista_de_opciones
		pop		ix
		
AUMENTOS:
		
		inc		ix
		
		ld		a,(x_pinta_mapa)
		add		5
		ld		(x_pinta_mapa),a		
		cp		203
		jp		z,.SALTO_DE_LINEA
		jp		DESCUBRIMOS_LO_QUE_HAY_EN_LA_CASILLA
		
.SALTO_DE_LINEA:

		ld		a,53
		ld		(x_pinta_mapa),a		
		ld		a,(y_pinta_mapa)
		add		5
		ld		(y_pinta_mapa),a		
		cp		177
		jp		z,ESPERA_PARA_VOLVER
		jp		DESCUBRIMOS_LO_QUE_HAY_EN_LA_CASILLA
			
VACIA_0:

		jp		PINTA_LABERINTO_0
		
VACIA_1:

		jp		PINTA_LABERINTO_1
		
VACIA_2:

		jp		PINTA_LABERINTO_2
		
VACIA_3:

		jp		PINTA_LABERINTO_3
		
VACIA_4:

		jp		PINTA_LABERINTO_4
		
VACIA_5:

		jp		PINTA_LABERINTO_5
		
VACIA_6:

		jp		PINTA_LABERINTO_6
		
VACIA_7:

		jp		PINTA_LABERINTO_7
		
VACIA_8:

		jp		PINTA_LABERINTO_8
		
VACIA_9:

		jp		PINTA_LABERINTO_9
		
VACIA_10:

		jp		PINTA_LABERINTO_10
		
VACIA_11:

		jp		PINTA_LABERINTO_11
		
VACIA_12:

		jp		PINTA_LABERINTO_12
		
VACIA_13:

		jp		PINTA_LABERINTO_13
		
VACIA_14:

		jp		PINTA_LABERINTO_14
		
SALIDA_0:

		call	PINTA_LABERINTO_0
		jp		PINTA_SALIDA
		
SALIDA_1:

		call	PINTA_LABERINTO_1
		jp		PINTA_SALIDA
		
SALIDA_2:

		call	PINTA_LABERINTO_2
		jp		PINTA_SALIDA
		
SALIDA_3:

		call	PINTA_LABERINTO_3
		jp		PINTA_SALIDA
		
SALIDA_4:

		call	PINTA_LABERINTO_4
		jp		PINTA_SALIDA
		
SALIDA_5:

		call	PINTA_LABERINTO_5
		jp		PINTA_SALIDA
		
SALIDA_6:

		call	PINTA_LABERINTO_6
		jp		PINTA_SALIDA
		
SALIDA_7:

		call	PINTA_LABERINTO_7
		jp		PINTA_SALIDA
		
SALIDA_8:

		call	PINTA_LABERINTO_8
		jp		PINTA_SALIDA
		
SALIDA_9:

		call	PINTA_LABERINTO_9
		jp		PINTA_SALIDA
		
SALIDA_10:

		call	PINTA_LABERINTO_10
		jp		PINTA_SALIDA
		
SALIDA_11:

		call	PINTA_LABERINTO_11
		jp		PINTA_SALIDA
		
SALIDA_12:

		call	PINTA_LABERINTO_12
		jp		PINTA_SALIDA
		
SALIDA_13:

		call	PINTA_LABERINTO_13
		jp		PINTA_SALIDA
		
SALIDA_14:

		call	PINTA_LABERINTO_14
		jp		PINTA_SALIDA
		
ENTRADA_0:

		call	PINTA_LABERINTO_0
		jp		PINTA_ENTRADA
		
ENTRADA_1:

		call	PINTA_LABERINTO_1
		jp		PINTA_ENTRADA
		
ENTRADA_2:

		call	PINTA_LABERINTO_2
		jp		PINTA_ENTRADA
		
ENTRADA_3:

		call	PINTA_LABERINTO_3
		jp		PINTA_ENTRADA
		
ENTRADA_4:

		call	PINTA_LABERINTO_4
		jp		PINTA_ENTRADA
		
ENTRADA_5:

		call	PINTA_LABERINTO_5
		jp		PINTA_ENTRADA
		
ENTRADA_6:

		call	PINTA_LABERINTO_6
		jp		PINTA_ENTRADA
		
ENTRADA_7:

		call	PINTA_LABERINTO_7
		jp		PINTA_ENTRADA
		
ENTRADA_8:

		call	PINTA_LABERINTO_8
		jp		PINTA_ENTRADA
		
ENTRADA_9:

		call	PINTA_LABERINTO_9
		jp		PINTA_ENTRADA
		
ENTRADA_10:

		call	PINTA_LABERINTO_10
		jp		PINTA_ENTRADA
		
ENTRADA_11:

		call	PINTA_LABERINTO_11
		jp		PINTA_ENTRADA
		
ENTRADA_12:

		call	PINTA_LABERINTO_12
		jp		PINTA_ENTRADA
		
ENTRADA_13:

		call	PINTA_LABERINTO_13
		jp		PINTA_ENTRADA
		
ENTRADA_14:

		call	PINTA_LABERINTO_14
		jp		PINTA_ENTRADA
		
TRAMPA_0:

		call	PINTA_LABERINTO_0
		jp		PINTA_TRAMPA
		
TRAMPA_1:

		call	PINTA_LABERINTO_1
		jp		PINTA_TRAMPA
		
TRAMPA_2:

		call	PINTA_LABERINTO_2
		jp		PINTA_TRAMPA
		
TRAMPA_3:

		call	PINTA_LABERINTO_3
		jp		PINTA_TRAMPA
		
TRAMPA_4:

		call	PINTA_LABERINTO_4
		jp		PINTA_TRAMPA
		
TRAMPA_5:

		call	PINTA_LABERINTO_5
		jp		PINTA_TRAMPA
		
TRAMPA_6:

		call	PINTA_LABERINTO_6
		jp		PINTA_TRAMPA
		
TRAMPA_7:

		call	PINTA_LABERINTO_7
		jp		PINTA_TRAMPA
		
TRAMPA_8:

		call	PINTA_LABERINTO_8
		jp		PINTA_TRAMPA
		
TRAMPA_9:

		call	PINTA_LABERINTO_9
		jp		PINTA_TRAMPA
		
TRAMPA_10:

		call	PINTA_LABERINTO_10
		jp		PINTA_TRAMPA
		
TRAMPA_11:

		call	PINTA_LABERINTO_11
		jp		PINTA_TRAMPA
		
TRAMPA_12:

		call	PINTA_LABERINTO_12
		jp		PINTA_TRAMPA
		
TRAMPA_13:

		call	PINTA_LABERINTO_13
		jp		PINTA_TRAMPA
		
TRAMPA_14:

		call	PINTA_LABERINTO_14
		jp		PINTA_TRAMPA
		
POCHADERO_0:

		call	PINTA_LABERINTO_0
		jp		PINTA_POCHADERO
		
POCHADERO_1:

		call	PINTA_LABERINTO_1
		jp		PINTA_POCHADERO
		
POCHADERO_2:

		call	PINTA_LABERINTO_2
		jp		PINTA_POCHADERO
		
POCHADERO_3:

		call	PINTA_LABERINTO_3
		jp		PINTA_POCHADERO
		
POCHADERO_4:

		call	PINTA_LABERINTO_4
		jp		PINTA_POCHADERO
		
POCHADERO_5:

		call	PINTA_LABERINTO_5
		jp		PINTA_POCHADERO
		
POCHADERO_6:

		call	PINTA_LABERINTO_6
		jp		PINTA_POCHADERO
		
POCHADERO_7:

		call	PINTA_LABERINTO_7
		jp		PINTA_POCHADERO
		
POCHADERO_8:

		call	PINTA_LABERINTO_8
		jp		PINTA_POCHADERO
		
POCHADERO_9:

		call	PINTA_LABERINTO_9
		jp		PINTA_POCHADERO
		
POCHADERO_10:

		call	PINTA_LABERINTO_10
		jp		PINTA_POCHADERO
		
POCHADERO_11:

		call	PINTA_LABERINTO_11
		jp		PINTA_POCHADERO
		
POCHADERO_12:

		call	PINTA_LABERINTO_12
		jp		PINTA_POCHADERO
		
POCHADERO_13:

		call	PINTA_LABERINTO_13
		jp		PINTA_POCHADERO
		
POCHADERO_14:

		call	PINTA_LABERINTO_14
		jp		PINTA_POCHADERO
		
HATER_0:

		call	PINTA_LABERINTO_0
		jp		PINTA_HATER
		
HATER_1:

		call	PINTA_LABERINTO_1
		jp		PINTA_HATER
		
HATER_2:

		call	PINTA_LABERINTO_2
		jp		PINTA_HATER
		
HATER_3:

		call	PINTA_LABERINTO_3
		jp		PINTA_HATER
		
HATER_4:

		call	PINTA_LABERINTO_4
		jp		PINTA_HATER
		
HATER_5:

		call	PINTA_LABERINTO_5
		jp		PINTA_HATER
		
HATER_6:

		call	PINTA_LABERINTO_6
		jp		PINTA_HATER
		
HATER_7:

		call	PINTA_LABERINTO_7
		jp		PINTA_HATER
		
HATER_8:

		call	PINTA_LABERINTO_8
		jp		PINTA_HATER
		
HATER_9:

		call	PINTA_LABERINTO_9
		jp		PINTA_HATER
		
HATER_10:

		call	PINTA_LABERINTO_10
		jp		PINTA_HATER
		
HATER_11:

		call	PINTA_LABERINTO_11
		jp		PINTA_HATER
		
HATER_12:

		call	PINTA_LABERINTO_12
		jp		PINTA_HATER
		
HATER_13:

		call	PINTA_LABERINTO_13
		jp		PINTA_HATER
		
HATER_14:

		call	PINTA_LABERINTO_14
		jp		PINTA_HATER
		
AGUJERO_0:

		call	PINTA_LABERINTO_0
		jp		PINTA_AGUJERO
		
AGUJERO_1:

		call	PINTA_LABERINTO_1
		jp		PINTA_AGUJERO
		
AGUJERO_2:

		call	PINTA_LABERINTO_2
		jp		PINTA_AGUJERO
		
AGUJERO_3:

		call	PINTA_LABERINTO_3
		jp		PINTA_AGUJERO
		
AGUJERO_4:

		call	PINTA_LABERINTO_4
		jp		PINTA_AGUJERO
		
AGUJERO_5:

		call	PINTA_LABERINTO_5
		jp		PINTA_AGUJERO
		
AGUJERO_6:

		call	PINTA_LABERINTO_6
		jp		PINTA_AGUJERO
		
AGUJERO_7:

		call	PINTA_LABERINTO_7
		jp		PINTA_AGUJERO
		
AGUJERO_8:

		call	PINTA_LABERINTO_8
		jp		PINTA_AGUJERO
		
AGUJERO_9:

		call	PINTA_LABERINTO_9
		jp		PINTA_AGUJERO
		
AGUJERO_10:

		call	PINTA_LABERINTO_10
		jp		PINTA_AGUJERO
		
AGUJERO_11:

		call	PINTA_LABERINTO_11
		jp		PINTA_AGUJERO
		
AGUJERO_12:

		call	PINTA_LABERINTO_12
		jp		PINTA_AGUJERO
		
AGUJERO_13:

		call	PINTA_LABERINTO_13
		jp		PINTA_AGUJERO
		
AGUJERO_14:

		call	PINTA_LABERINTO_14
		jp		PINTA_AGUJERO
		
LLAVE_0:

		call	PINTA_LABERINTO_0
		jp		PINTA_LLAVE
		
LLAVE_1:

		call	PINTA_LABERINTO_1
		jp		PINTA_LLAVE
		
LLAVE_2:

		call	PINTA_LABERINTO_2
		jp		PINTA_LLAVE
		
LLAVE_3:

		call	PINTA_LABERINTO_3
		jp		PINTA_LLAVE
		
LLAVE_4:

		call	PINTA_LABERINTO_4
		jp		PINTA_LLAVE
		
LLAVE_5:

		call	PINTA_LABERINTO_5
		jp		PINTA_LLAVE
		
LLAVE_6:

		call	PINTA_LABERINTO_6
		jp		PINTA_LLAVE
		
LLAVE_7:

		call	PINTA_LABERINTO_7
		jp		PINTA_LLAVE
		
LLAVE_8:

		call	PINTA_LABERINTO_8
		jp		PINTA_LLAVE
		
LLAVE_9:

		call	PINTA_LABERINTO_9
		jp		PINTA_LLAVE
		
LLAVE_10:

		call	PINTA_LABERINTO_10
		jp		PINTA_LLAVE
		
LLAVE_11:

		call	PINTA_LABERINTO_11
		jp		PINTA_LLAVE
		
LLAVE_12:

		call	PINTA_LABERINTO_12
		jp		PINTA_LLAVE
		
LLAVE_13:

		call	PINTA_LABERINTO_13
		jp		PINTA_LLAVE
		
LLAVE_14:

		call	PINTA_LABERINTO_14
		jp		PINTA_LLAVE
		
		
		ret

PINTA_LABERINTO_0:

		ld		de,DIBUJO_MAPA_0
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_1:

		ld		de,DIBUJO_MAPA_1
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_2:

		ld		de,DIBUJO_MAPA_2
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_3:

		ld		de,DIBUJO_MAPA_3
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_4:

		ld		de,DIBUJO_MAPA_4
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_5:

		ld		de,DIBUJO_MAPA_5
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_6:

		ld		de,DIBUJO_MAPA_6
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_7:

		ld		de,DIBUJO_MAPA_7
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_8:

		ld		de,DIBUJO_MAPA_8
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_9:

		ld		de,DIBUJO_MAPA_9
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_10:

		ld		de,DIBUJO_MAPA_10
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_11:

		ld		de,DIBUJO_MAPA_11
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_12:

		ld		de,DIBUJO_MAPA_12
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_13:

		ld		de,DIBUJO_MAPA_13
		jp		COMUN_PINTA_LABERINTO

PINTA_LABERINTO_14:

		ld		de,DIBUJO_MAPA_14
		jp		COMUN_PINTA_LABERINTO

PINTA_SALIDA:

		ld		de,DIBUJO_MAPA_SALIDA
		jp		COMUN_PINTA_LABERINTO

PINTA_ENTRADA:

		ld		de,DIBUJO_MAPA_ENTRADA
		jp		COMUN_PINTA_LABERINTO

PINTA_POCHADERO:

		ld		de,DIBUJO_MAPA_POCHADA
		jp		COMUN_PINTA_LABERINTO

PINTA_HATER:

		ld		de,DIBUJO_MAPA_HATER
		jp		COMUN_PINTA_LABERINTO

PINTA_AGUJERO:

		ld		de,DIBUJO_MAPA_AGUJERO
		jp		COMUN_PINTA_LABERINTO

PINTA_TRAMPA:

		ld		de,DIBUJO_MAPA_TRAMPA
		jp		COMUN_PINTA_LABERINTO

PINTA_LLAVE:

		ld		de,DIBUJO_MAPA_LLAVE
		jp		COMUN_PINTA_LABERINTO
																																													
COMUN_PINTA_LABERINTO:
		
		ld		hl,dibujo_mapa											; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC

		ld		iy,copia_trozo_mapa										; copiamos la parte de laberinto correspondiente
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+5),a
		ld		(ix+7),a		
		ld		a,(x_pinta_mapa)
		ld		(ix+4),a
		ld		a,(y_pinta_mapa)
		ld		(ix+6),a
		call	EL_12_A_0_EL_14_A_1001	
		ld		a,10011000B
		ld		(ix+14),a		
		jp		HL_DATOS_DEL_COPY_CALL_DOCOPY

copia_trozo_mapa:				dw		#005a,#029d,#0000,#0000,#0006,#0006
dibujo_mapa:					dw		#005a,#029d,#0006,#0006
								db		#00,#00,#F0	
																		
ESPERA_PARA_VOLVER:
		
		ld		a,(mosca_x_objetivo)
		push	af			
		ld		a,(x_map)
		ld		(mosca_x_objetivo),a

		ld		a,(mosca_y_objetivo)
		push	af			
		ld		a,(y_map)
		ld		(mosca_y_objetivo),a
												
PULSA_M_O_BOTON_DOS_PARA_VOLVER:
						
		ld		a,4														; si pulsa M termina la secuencia de pergamino
		call	SNSMAT
		bit		2,a
		jp		z,VOLVEMOS

		ld		a,(turno)												; si pulsa boton 2 la secuencia de pergamino termina
		add		2
		call	GTTRIG
		cp		#FF
		jp		z,VOLVEMOS
		
		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,PULSA_M_O_BOTON_DOS_PARA_VOLVER
	
		ld		a,(perro)
		or		a
		jp		z,SEGUIMIENTO
		
		xor		a
		call	GTTRIG
		cp		#FF
		jp		z,EL_CONTRARIO

		ld		a,(turno)
		call	GTTRIG
		cp		#FF
		jp		z,EL_CONTRARIO

SEGUIMIENTO:
		
		ld		a,(x_map)
		ld		(mosca_x_objetivo),a
		ld		a,(y_map)
		ld		(mosca_y_objetivo),a
		
		jp		PULSA_M_O_BOTON_DOS_PARA_VOLVER
		
RECUPERAMOS_VALORES_2:

		ld		a,(x_map_2)
		ld		(mosca_x_objetivo),a
		ld		a,(y_map_2)
		ld		(mosca_y_objetivo),a						
		jp		PULSA_M_O_BOTON_DOS_PARA_VOLVER

RECUPERAMOS_VALORES_1:

		ld		a,(x_map_1)
		ld		(mosca_x_objetivo),a
		ld		a,(y_map_1)
		ld		(mosca_y_objetivo),a	
		jp		PULSA_M_O_BOTON_DOS_PARA_VOLVER

EL_CONTRARIO:

		ld		a,(turno)
		cp		1
		jp		nz,RECUPERAMOS_VALORES_1
		jp		RECUPERAMOS_VALORES_2
		
VOLVEMOS:
		
		pop		af
		ld		(mosca_y_objetivo),a
		pop		af
		ld		(mosca_x_objetivo),a
		
		call	EFECTO_MAPA		

		call	DISSCR
				
		ld		iy,cuadrado_que_limpia_5
		call	COPY_A_GUSTO
		ld		a,1
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
	
		call	VDP_LISTO
	
		xor		a														;indicamos a la interrupción de vblanck el cambio de paleta
		ld		(paleta_a_usar_en_vblank),a						

		ld		iy,copia_escenario_a_page_1_5							; Si estamos en page 0. Vamos a clonar la 0 en la 1 pero completa
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO	
		call	ENASCR
		ret

POINT_CASILLAS_MAPA_A_DIBUJAR:

		dw		VACIA_0
		dw		VACIA_1
		dw		VACIA_2
		dw		VACIA_3
		dw		VACIA_4
		dw		VACIA_5
		dw		VACIA_6
		dw		VACIA_7
		dw		VACIA_8
		dw		VACIA_9
		dw		VACIA_10
		dw		VACIA_11
		dw		VACIA_12
		dw		VACIA_13
		dw		VACIA_14
		dw		SALIDA_0
		dw		SALIDA_1
		dw		SALIDA_2
		dw		SALIDA_3
		dw		SALIDA_4
		dw		SALIDA_5
		dw		SALIDA_6
		dw		SALIDA_7
		dw		SALIDA_8
		dw		SALIDA_9
		dw		SALIDA_10
		dw		SALIDA_11
		dw		SALIDA_12
		dw		SALIDA_13
		dw		SALIDA_14
		dw		ENTRADA_0
		dw		ENTRADA_1
		dw		ENTRADA_2
		dw		ENTRADA_3
		dw		ENTRADA_4
		dw		ENTRADA_5
		dw		ENTRADA_6
		dw		ENTRADA_7
		dw		ENTRADA_8
		dw		ENTRADA_9
		dw		ENTRADA_10
		dw		ENTRADA_11
		dw		ENTRADA_12
		dw		ENTRADA_13
		dw		ENTRADA_14
		dw		TRAMPA_0
		dw		TRAMPA_1
		dw		TRAMPA_2
		dw		TRAMPA_3
		dw		TRAMPA_4
		dw		TRAMPA_5
		dw		TRAMPA_6
		dw		TRAMPA_7
		dw		TRAMPA_8
		dw		TRAMPA_9
		dw		TRAMPA_10
		dw		TRAMPA_11
		dw		TRAMPA_12
		dw		TRAMPA_13
		dw		TRAMPA_14
		dw		POCHADERO_0
		dw		POCHADERO_1
		dw		POCHADERO_2
		dw		POCHADERO_3
		dw		POCHADERO_4
		dw		POCHADERO_5
		dw		POCHADERO_6
		dw		POCHADERO_7
		dw		POCHADERO_8
		dw		POCHADERO_9
		dw		POCHADERO_10
		dw		POCHADERO_11
		dw		POCHADERO_12
		dw		POCHADERO_13
		dw		POCHADERO_14
		dw		HATER_0
		dw		HATER_1
		dw		HATER_2
		dw		HATER_3
		dw		HATER_4
		dw		HATER_5
		dw		HATER_6
		dw		HATER_7
		dw		HATER_8
		dw		HATER_9
		dw		HATER_10
		dw		HATER_11
		dw		HATER_12
		dw		HATER_13
		dw		HATER_14
		dw		AGUJERO_0
		dw		AGUJERO_1
		dw		AGUJERO_2
		dw		AGUJERO_3
		dw		AGUJERO_4
		dw		AGUJERO_5
		dw		AGUJERO_6
		dw		AGUJERO_7
		dw		AGUJERO_8
		dw		AGUJERO_9
		dw		AGUJERO_10
		dw		AGUJERO_11
		dw		AGUJERO_12
		dw		AGUJERO_13
		dw		AGUJERO_14
		dw		LLAVE_0
		dw		LLAVE_1
		dw		LLAVE_2
		dw		LLAVE_3
		dw		LLAVE_4
		dw		LLAVE_5
		dw		LLAVE_6
		dw		LLAVE_7
		dw		LLAVE_8
		dw		LLAVE_9
		dw		LLAVE_10
		dw		LLAVE_11
		dw		LLAVE_12
		dw		LLAVE_13
		dw		LLAVE_14														
		
DIBUJO_MAPA_0:			incbin			"SR5/MAPA/DIBUJO MAPA 0.DAT"
DIBUJO_MAPA_1:			incbin			"SR5/MAPA/DIBUJO MAPA 1.DAT"
DIBUJO_MAPA_2:			incbin			"SR5/MAPA/DIBUJO MAPA 2.DAT"
DIBUJO_MAPA_3:			incbin			"SR5/MAPA/DIBUJO MAPA 3.DAT"
DIBUJO_MAPA_4:			incbin			"SR5/MAPA/DIBUJO MAPA 4.DAT"
DIBUJO_MAPA_5:			incbin			"SR5/MAPA/DIBUJO MAPA 5.DAT"
DIBUJO_MAPA_6:			incbin			"SR5/MAPA/DIBUJO MAPA 6.DAT"
DIBUJO_MAPA_7:			incbin			"SR5/MAPA/DIBUJO MAPA 7.DAT"
DIBUJO_MAPA_8:			incbin			"SR5/MAPA/DIBUJO MAPA 8.DAT"
DIBUJO_MAPA_9:			incbin			"SR5/MAPA/DIBUJO MAPA 9.DAT"
DIBUJO_MAPA_10:			incbin			"SR5/MAPA/DIBUJO MAPA 10.DAT"
DIBUJO_MAPA_11:			incbin			"SR5/MAPA/DIBUJO MAPA 11.DAT"
DIBUJO_MAPA_12:			incbin			"SR5/MAPA/DIBUJO MAPA 12.DAT"
DIBUJO_MAPA_13:			incbin			"SR5/MAPA/DIBUJO MAPA 13.DAT"
DIBUJO_MAPA_14:			incbin			"SR5/MAPA/DIBUJO MAPA 14.DAT"
DIBUJO_MAPA_ENTRADA:	incbin			"SR5/MAPA/DIBUJO MAPA ENTRADA.DAT"
DIBUJO_MAPA_HATER:		incbin			"SR5/MAPA/DIBUJO MAPA HATER.DAT"
DIBUJO_MAPA_POCHADA:	incbin			"SR5/MAPA/DIBUJO MAPA POCHADA.DAT"
DIBUJO_MAPA_SALIDA:		incbin			"SR5/MAPA/DIBUJO MAPA SALIDA.DAT"
DIBUJO_MAPA_AGUJERO:	incbin			"SR5/MAPA/DIBUJO MAPA NEGRO.DAT"
DIBUJO_MAPA_LLAVE:		incbin			"SR5/MAPA/DIBUJO MAPA LLAVE.DAT"
DIBUJO_MAPA_TRAMPA:		incbin			"SR5/MAPA/DIBUJO MAPA TRAMPA.DAT"
PERGA_INGLES:			incbin			"SR5/MAPA/PERGAMINO PARTE INGLES_34x41.DAT"
		
		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 22 DEL MEGAROM **********)))	
														
; ______________________________________________________________________

; (((********** PAGINA 23 DEL MEGAROM **********
	
; DIBUJO PROTA MUERTO	


		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

COPIAMOS_PROTA_MUERTO:				incbin		"SR5/PROTAS/MUERTE_148x106.DAT" 		
		
		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 23 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 24 DEL MEGAROM **********
	
; RUTINA DE DECORADOS


		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

CUARTA_FASE_DECORADOS:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_DECORADOS_FASE_4
		jp		lista_de_opciones
		
CUARTA_FASE_NORTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,90
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)

		ld 		de,POINT_CUARTA_FASE_DECORADOS_NORTE
		jp		lista_de_opciones

CUARTA_FASE_ESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,3
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_CUARTA_FASE_DECORADOS_ESTE
		jp		lista_de_opciones
		
CUARTA_FASE_SUR_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,90
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_CUARTA_FASE_DECORADOS_SUR
		jp		lista_de_opciones

CUARTA_FASE_OESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,3
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_CUARTA_FASE_DECORADOS_OESTE
		jp		lista_de_opciones
					
CUARTA_FASE_DECORADOS_0:

		jp		DECIDIMOS_PUNTO_CARDINAL_PARA_TERCERA_FASE
		
CUARTA_FASE_DECORADOS_GRAFITI_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
		ld		a,(idioma)
		cp		1
		jp		z,.page0ingles		
		ld		hl,copia_cuarta_fase_fondo_decorado_grafiti
		jp		.unido

.page0ingles:

		ld		hl,copia_cuarta_fase_fondo_decorado_grafitie
		jp		.unido
				
.page1:

		ld		a,(idioma)
		cp		1
		jp		z,.page1ingles	
		ld		hl,copia_cuarta_fase_fondo_decorado_grafiti1
		jp		.unido

.page1ingles:

		ld		hl,copia_cuarta_fase_fondo_decorado_grafitie1
		
.unido:
				
		call	TRASLADAMOS_GRAFITI_C_F	
					
		jp		FIN_CUARTA_FASE_DECORADOS
		
CUARTA_FASE_DECORADOS_LLAVE_2:
					
		jp		FIN_CUARTA_FASE_DECORADOS
				
CUARTA_FASE_DECORADOS_ESPEJO_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_cuarta_fase_fondo_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_cuarta_fase_fondo_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_C_F	
					
		jp		FIN_CUARTA_FASE_DECORADOS

CUARTA_FASE_DECORADOS_ENTRADA_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_cuarta_fase_fondo_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_cuarta_fase_fondo_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_C_F	
					
		jp		FIN_CUARTA_FASE_DECORADOS

CUARTA_FASE_DECORADOS_POCHADA_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_cuarta_fase_fondo_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_cuarta_fase_fondo_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_C_F	
					
		jp		FIN_CUARTA_FASE_DECORADOS
				
CUARTA_FASE_DECORADOS_PUERTA_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_cuarta_fase_fondo_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_cuarta_fase_fondo_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_C_F	
					
		jp		FIN_CUARTA_FASE_DECORADOS
				
CUARTA_FASE_DECORADOS_ESCUDO_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_cuarta_fase_fondo_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_cuarta_fase_fondo_decorado_escudo1

.unido:
				
		call	TRASLADAMOS_ESCUDO_C_F	

FIN_CUARTA_FASE_DECORADOS:

		jp		DECIDIMOS_PUNTO_CARDINAL_PARA_TERCERA_FASE

TERCERA_FASE_DECORADOS:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_DECORADOS_FASE_3
		jp		lista_de_opciones
		
TERCERA_FASE_NORTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,60
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)

		ld 		de,POINT_TERCERA_FASE_DECORADOS_NORTE
		jp		lista_de_opciones

TERCERA_FASE_ESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,2
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_TERCERA_FASE_DECORADOS_ESTE
		jp		lista_de_opciones
				
TERCERA_FASE_SUR_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,60
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_TERCERA_FASE_DECORADOS_SUR
		jp		lista_de_opciones
				
TERCERA_FASE_OESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,2
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)

		ld 		de,POINT_TERCERA_FASE_DECORADOS_OESTE
		jp		lista_de_opciones
			
TERCERA_FASE_DECORADOS_0:

		jp		DECIDIMOS_PUNTO_CARDINAL_PARA_SEGUNDA_FASE

TERCERA_FASE_DECORADOS_GRAFITI_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_derecha_decorado_grafiti
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_derecha_decorado_grafiti1

.unido:
				
		call	TRASLADAMOS_GRAFITI_T_D	
					
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_LLAVE_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_derecha_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_derecha_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_T_D	
					
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_ESPEJO_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_derecha_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_derecha_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_T_D	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_GRAFITI_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
		
		ld		a,(idioma)
		cp		1
		jp		z,.page0ingles
				
		ld		hl,copia_tercera_fase_fondo_decorado_grafiti
		jp		.unido

.page0ingles:

		ld		hl,copia_tercera_fase_fondo_decorado_grafitie
		jp		.unido
				
.page1:

		ld		a,(idioma)
		cp		1
		jp		z,.page1ingles
		
		ld		hl,copia_tercera_fase_fondo_decorado_grafiti1
		jp		.unido

.page1ingles:

		ld		hl,copia_tercera_fase_fondo_decorado_grafitie1
		
.unido:
				
		call	TRASLADAMOS_GRAFITI_T_F	
					
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_LLAVE_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_fondo_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_fondo_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_T_F	
					
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_ESPEJO_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_fondo_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_fondo_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_T_F	
					
		jp		FIN_TERCERA_FASE_DECORADOS


TERCERA_FASE_DECORADOS_GRAFITI_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_izquierda_decorado_grafiti
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_izquierda_decorado_grafiti1

.unido:
				
		call	TRASLADAMOS_GRAFITI_T_I	
					
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_LLAVE_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_izquierda_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_izquierda_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_T_I	
					
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_ESPEJO_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_izquierda_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_izquierda_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_T_I	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_GRAFITI_5:

		ret
		
TERCERA_FASE_DECORADOS_LLAVE_5:

		RET
		
TERCERA_FASE_DECORADOS_ESPEJO_5:
		
		ret

TERCERA_FASE_DECORADOS_ENTRADA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_derecha_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_derecha_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_T_D	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_ENTRADA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_fondo_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_fondo_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_T_F	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_ENTRADA_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_izquierda_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_izquierda_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_T_I	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_ENTRADA_5:
		
		ret

TERCERA_FASE_DECORADOS_POCHADA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_derecha_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_derecha_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_T_D	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_POCHADA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_fondo_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_fondo_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_T_F	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_POCHADA_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_izquierda_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_izquierda_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_T_I	
					
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_POCHADA_5:
		
		ret
				
TERCERA_FASE_DECORADOS_PUERTA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_derecha_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_derecha_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_T_D	

		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_PUERTA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_fondo_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_fondo_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_T_F	
		
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_PUERTA_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_izquierda_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_izquierda_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_T_I	
		jp		FIN_TERCERA_FASE_DECORADOS
				
TERCERA_FASE_DECORADOS_PUERTA_5:

		ret
						
TERCERA_FASE_DECORADOS_ESCUDO_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_derecha_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_derecha_decorado_escudo1

.unido:
		
				
		call	TRASLADAMOS_ESCUDO_T_D
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_ESCUDO_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_fondo_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_fondo_decorado_escudo1

.unido:		

		call	TRASLADAMOS_ESCUDO_T_F
		jp		FIN_TERCERA_FASE_DECORADOS

TERCERA_FASE_DECORADOS_ESCUDO_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_tercera_fase_izquierda_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_tercera_fase_izquierda_decorado_escudo1

.unido:

		call	TRASLADAMOS_ESCUDO_T_I
		jp		FIN_TERCERA_FASE_DECORADOS
		
TERCERA_FASE_DECORADOS_ESCUDO_5:
		
FIN_TERCERA_FASE_DECORADOS:	
		
		jp		DECIDIMOS_PUNTO_CARDINAL_PARA_SEGUNDA_FASE

SEGUNDA_FASE_DECORADOS:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_DECORADOS_FASE_2
		jp		lista_de_opciones
		
SEGUNDA_FASE_NORTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,30
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc
		
		ld		a,(ix)

		ld 		de,POINT_SEGUNDA_FASE_DECORADOS_NORTE
		jp		lista_de_opciones

SEGUNDA_FASE_ESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,1
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_SEGUNDA_FASE_DECORADOS_ESTE
		jp		lista_de_opciones
				
SEGUNDA_FASE_SUR_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc
		ld		bc,30
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_SEGUNDA_FASE_DECORADOS_SUR
		jp		lista_de_opciones
				
SEGUNDA_FASE_OESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		bc,1
		or		a
		sbc		hl,bc
		push	hl
		pop		bc
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_SEGUNDA_FASE_DECORADOS_OESTE
		jp		lista_de_opciones
					
SEGUNDA_FASE_DECORADOS_0:

		jp		DECIDIMOS_PUNTO_CARDINAL_PARA_PRIMERA_FASE

SEGUNDA_FASE_DECORADOS_GRAFITI_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_derecha_decorado_grafiti
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_derecha_decorado_grafiti1

.unido:
				
		call	TRASLADAMOS_GRAFITI_S_D	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_LLAVE_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_derecha_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_derecha_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_S_D	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_ESPEJO_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_derecha_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_derecha_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_S_D	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_GRAFITI_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:

		ld		a,(idioma)
		cp		1
		jp		z,.page0ingles
		
		ld		hl,copia_segunda_fase_fondo_decorado_grafiti
		jp		.unido

.page0ingles:

		ld		hl,copia_segunda_fase_fondo_decorado_grafitie
		jp		.unido
				
.page1:

		ld		a,(idioma)
		cp		1
		jp		z,.page1ingles
		
		ld		hl,copia_segunda_fase_fondo_decorado_grafiti1
		jp		.unido
		
.page1ingles:

		ld		hl,copia_segunda_fase_fondo_decorado_grafitie1
			
.unido:
				
		call	TRASLADAMOS_GRAFITI_S_F	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_LLAVE_2:

		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_fondo_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_fondo_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_S_F	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_ESPEJO_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_fondo_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_fondo_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_S_F	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_GRAFITI_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_izquierda_decorado_grafiti
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_izquierda_decorado_grafiti1

.unido:
				
		call	TRASLADAMOS_GRAFITI_S_I	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_LLAVE_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_izquierda_decorado_llave
		jp		.unido
.page1:

		ld		hl,copia_segunda_fase_izquierda_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_S_I	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_ESPEJO_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_izquierda_decorado_espejo
		jp		.unido
.page1:

		ld		hl,copia_segunda_fase_izquierda_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_S_I	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_GRAFITI_5:

		ret
		
SEGUNDA_FASE_DECORADOS_LLAVE_5:

		RET
		
SEGUNDA_FASE_DECORADOS_ESPEJO_5:
		
		ret

SEGUNDA_FASE_DECORADOS_ENTRADA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_derecha_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_derecha_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_S_D	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_ENTRADA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_fondo_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_fondo_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_S_F	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_ENTRADA_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_izquierda_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_izquierda_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_S_I	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_ENTRADA_5:
		
		ret

SEGUNDA_FASE_DECORADOS_POCHADA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_derecha_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_derecha_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_S_D	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_POCHADA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_fondo_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_fondo_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_S_F	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_POCHADA_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_izquierda_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_izquierda_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_S_I	
					
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_POCHADA_5:
		
		ret
				
SEGUNDA_FASE_DECORADOS_PUERTA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_derecha_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_derecha_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_S_D	
		jp		FIN_SEGUNDA_FASE_DECORADOS
		
SEGUNDA_FASE_DECORADOS_PUERTA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_fondo_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_fondo_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_S_F	
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_PUERTA_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_izquierda_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_izquierda_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_S_I	
		jp		FIN_SEGUNDA_FASE_DECORADOS
				
SEGUNDA_FASE_DECORADOS_PUERTA_5:

		ret
						
SEGUNDA_FASE_DECORADOS_ESCUDO_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_derecha_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_derecha_decorado_escudo1

.unido:

		call	TRASLADAMOS_ESCUDO_S_D
		
		jp		FIN_SEGUNDA_FASE_DECORADOS
				
SEGUNDA_FASE_DECORADOS_ESCUDO_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_fondo_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_fondo_decorado_escudo1

.unido:
		
		call	TRASLADAMOS_ESCUDO_S_F
		
		jp		FIN_SEGUNDA_FASE_DECORADOS

SEGUNDA_FASE_DECORADOS_ESCUDO_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_segunda_fase_izquierda_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_segunda_fase_izquierda_decorado_escudo1

.unido:

		call	TRASLADAMOS_ESCUDO_S_I
		
		jp		FIN_SEGUNDA_FASE_DECORADOS
			
SEGUNDA_FASE_DECORADOS_ESCUDO_5:
		
FIN_SEGUNDA_FASE_DECORADOS:	
		
		jp		DECIDIMOS_PUNTO_CARDINAL_PARA_PRIMERA_FASE

PRIMERA_FASE_DECORADOS:

		ld		a,(orientacion_del_personaje)
		ld 		de,POINT_PC_DECORADOS_FASE_1
		jp		lista_de_opciones
		
PRIMERA_FASE_NORTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		bc,(posicion_en_mapa)

		add		ix,bc
		
		ld		a,(ix)

		ld 		de,POINT_PRIMERA_FASE_DECORADOS_NORTE
		jp		lista_de_opciones



PRIMERA_FASE_ESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_PRIMERA_FASE_DECORADOS_ESTE
		jp		lista_de_opciones
				
PRIMERA_FASE_SUR_DECORADOS:

		ld		ix,decorados_laberinto
		ld		hl,(posicion_en_mapa)
		ld		c,l
		ld		b,h
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_PRIMERA_FASE_DECORADOS_SUR
		jp		lista_de_opciones
				
PRIMERA_FASE_OESTE_DECORADOS:

		ld		ix,decorados_laberinto
		ld		bc,(posicion_en_mapa)
		add		ix,bc

		ld		a,(ix)

		ld 		de,POINT_PRIMERA_FASE_DECORADOS_OESTE
		jp		lista_de_opciones
			
PRIMERA_FASE_DECORADOS_0:

		jp		HAY_ALGUIEN_AQUI

PRIMERA_FASE_DECORADOS_GRAFITI_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_derecha_decorado_grafiti
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_derecha_decorado_grafiti1

.unido:
				
		call	TRASLADAMOS_GRAFITI_P_D	
					
		jp		FIN_PRIMERA_FASE_DECORADOS
		
PRIMERA_FASE_DECORADOS_LLAVE_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_derecha_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_derecha_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_P_D	
					
		jp		FIN_PRIMERA_FASE_DECORADOS
				
PRIMERA_FASE_DECORADOS_ESPEJO_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_derecha_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_derecha_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_P_D	
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_GRAFITI_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:

		ld		a,(idioma)
		cp		1
		jp		z,.page0ingles
						
		ld		hl,copia_primera_fase_fondo_decorado_grafiti
		jp		.unido

.page0ingles:

		ld		hl,copia_primera_fase_fondo_decorado_grafitie
		jp		.unido
				
.page1:

		ld		a,(idioma)
		cp		1
		jp		z,.page1ingles
		
		ld		hl,copia_primera_fase_fondo_decorado_grafiti1
		jp		.unido
		
.page1ingles:

		ld		hl,copia_primera_fase_fondo_decorado_grafitie1

.unido:
				
		call	TRASLADAMOS_GRAFITI_P_F	
					
		jp		FIN_PRIMERA_FASE_DECORADOS
				
PRIMERA_FASE_DECORADOS_LLAVE_2:	

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_fondo_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_fondo_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_P_F
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_ESPEJO_2:	
		
		call	TRASLADAMOS_PATRONES_ESPEJO
						
PRIMERA_FASE_DECORADOS_ESPEJO_2_SIGUE:

		ld		iy,copia_primera_fase_fondo_decorado_espejo

		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1
		ld		a,10011000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		a,(personaje)
		cp		1
		jp		z,PINTAMOS_NATPU
		cp		2
		jp		z,PINTAMOS_FERGAR
		cp		3
		jp		z,PINTAMOS_CRISRA
		cp		4
		jp		z,PINTAMOS_VICMAR

PINTAMOS_NATPU:
		
		ld		iy,copia_reflejo_prota_1
		jp		PINTAMOS_REFLEJO_PROTA

PINTAMOS_FERGAR:
		
		ld		iy,copia_reflejo_prota_2
		jp		PINTAMOS_REFLEJO_PROTA

PINTAMOS_CRISRA:
		
		ld		iy,copia_reflejo_prota_3
		jp		PINTAMOS_REFLEJO_PROTA

PINTAMOS_VICMAR:
		
		ld		iy,copia_reflejo_prota_4

PINTAMOS_REFLEJO_PROTA:

		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1		
		ld		a,10011000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
PINTAMOS_REFLEJO_ARMADURA:

		ld		a,(armadura)
		or		a
		jp		z,PINTAMOS_REFLEJO_CASCO

		ld		iy,copia_reflejo_armadura
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1				
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
PINTAMOS_REFLEJO_CASCO:

		ld		a,(casco)
		or		a
		jp		z,PINTAMOS_REFLEJO_CUCHILLO

		ld		iy,copia_reflejo_casco
		call	COPY_A_GUSTO
		call	RECTIFICACION_POR_PAGE_1				
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY



PINTAMOS_REFLEJO_CUCHILLO:

		ld		a,(cuchillo)
		or		a
		jp		z,PINTAMOS_REFLEJO_ESPADA

		ld		iy,copia_reflejo_cuchillo
		call	COPY_A_GUSTO				
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY												
		jp		FIN_PRIMERA_FASE_DECORADOS

PINTAMOS_REFLEJO_ESPADA:

		ld		a,(espada)
		or		a
		jp		z,FIN_PRIMERA_FASE_DECORADOS

		ld		iy,copia_reflejo_espada
		call	COPY_A_GUSTO				
		call	RECTIFICACION_POR_PAGE_1
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY												
		jp		FIN_PRIMERA_FASE_DECORADOS
		
PRIMERA_FASE_DECORADOS_GRAFITI_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_izquierda_decorado_grafiti
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_izquierda_decorado_grafiti1

.unido:
				
		call	TRASLADAMOS_GRAFITI_P_I	
					
		jp		FIN_PRIMERA_FASE_DECORADOS
		
PRIMERA_FASE_DECORADOS_LLAVE_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_izquierda_decorado_llave
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_izquierda_decorado_llave1

.unido:
				
		call	TRASLADAMOS_LLAVE_P_I	
					
		jp		FIN_PRIMERA_FASE_DECORADOS
			
PRIMERA_FASE_DECORADOS_ESPEJO_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_izquierda_decorado_espejo
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_izquierda_decorado_espejo1

.unido:
				
		call	TRASLADAMOS_ESPEJO_P_I	
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_GRAFITI_5:

		jp		FIN_PRIMERA_FASE_DECORADOS

		
PRIMERA_FASE_DECORADOS_LLAVE_5:

		jp		FIN_PRIMERA_FASE_DECORADOS
			
PRIMERA_FASE_DECORADOS_ESPEJO_5:
		
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_ENTRADA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_derecha_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_derecha_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_P_D	
					
		jp		FIN_PRIMERA_FASE_DECORADOS
		
PRIMERA_FASE_DECORADOS_ENTRADA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_fondo_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_fondo_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_P_F	
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_ENTRADA_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_izquierda_decorado_entrada
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_izquierda_decorado_entrada1

.unido:
				
		call	TRASLADAMOS_ENTRADA_P_I	
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_ENTRADA_5:
		
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_POCHADA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_derecha_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_derecha_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_P_D	
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_POCHADA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_fondo_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_fondo_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_P_F	
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_POCHADA_3:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_izquierda_decorado_pochada
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_izquierda_decorado_pochada1

.unido:
				
		call	TRASLADAMOS_POCHADA_P_I	
					
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_POCHADA_5:
		
		jp		FIN_PRIMERA_FASE_DECORADOS
				
PRIMERA_FASE_DECORADOS_PUERTA_1:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_derecha_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_derecha_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_P_D	
		jp		FIN_PRIMERA_FASE_DECORADOS
		
PRIMERA_FASE_DECORADOS_PUERTA_2:
		
		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_fondo_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_fondo_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_P_F	
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_PUERTA_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_izquierda_decorado_puerta
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_izquierda_decorado_puerta1

.unido:
				
		call	TRASLADAMOS_SALIDA_P_I	
		jp		FIN_PRIMERA_FASE_DECORADOS
				
PRIMERA_FASE_DECORADOS_PUERTA_5:

		jp		FIN_PRIMERA_FASE_DECORADOS
										
PRIMERA_FASE_DECORADOS_ESCUDO_1:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_derecha_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_derecha_decorado_escudo1

.unido:
		
		call	TRASLADAMOS_ESCUDO_P_D
		
		jp		FIN_PRIMERA_FASE_DECORADOS
		
PRIMERA_FASE_DECORADOS_ESCUDO_2:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_fondo_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_fondo_decorado_escudo1

.unido:
		
		call	TRASLADAMOS_ESCUDO_P_F
		
		jp		FIN_PRIMERA_FASE_DECORADOS

PRIMERA_FASE_DECORADOS_ESCUDO_3:

		ld		a,(set_page01)
		cp		1
		jp		nz,.page1

.page0:
				
		ld		hl,copia_primera_fase_izquierda_decorado_escudo
		jp		.unido
		
.page1:

		ld		hl,copia_primera_fase_izquierda_decorado_escudo1

.unido:

		call	TRASLADAMOS_ESCUDO_P_I
				
		jp		FIN_PRIMERA_FASE_DECORADOS
				
PRIMERA_FASE_DECORADOS_ESCUDO_5:

FIN_PRIMERA_FASE_DECORADOS:	
		
		jp		HAY_ALGUIEN_AQUI
						
POINT_CUARTA_FASE_DECORADOS_NORTE:
							
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESCUDO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESPEJO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_PUERTA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ENTRADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0	
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_POCHADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_GRAFITI_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_LLAVE_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0	

POINT_CUARTA_FASE_DECORADOS_ESTE:
							
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESCUDO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESPEJO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_PUERTA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0	
							dw	CUARTA_FASE_DECORADOS_ENTRADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_POCHADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_GRAFITI_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_LLAVE_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							
POINT_CUARTA_FASE_DECORADOS_SUR:
							
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESCUDO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESPEJO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_PUERTA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0	
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ENTRADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0	
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_POCHADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0	
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_GRAFITI_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_LLAVE_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							
POINT_CUARTA_FASE_DECORADOS_OESTE:
							
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESCUDO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ESPEJO_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_PUERTA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_ENTRADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_POCHADA_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_GRAFITI_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_LLAVE_2
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0
							dw	CUARTA_FASE_DECORADOS_0	

POINT_TERCERA_FASE_DECORADOS_NORTE:
							
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_1
							dw	TERCERA_FASE_DECORADOS_ESCUDO_2
							dw	TERCERA_FASE_DECORADOS_ESCUDO_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_5
							dw	TERCERA_FASE_DECORADOS_ESPEJO_1
							dw	TERCERA_FASE_DECORADOS_ESPEJO_2
							dw	TERCERA_FASE_DECORADOS_ESPEJO_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESPEJO_5
							dw	TERCERA_FASE_DECORADOS_PUERTA_1
							dw	TERCERA_FASE_DECORADOS_PUERTA_2
							dw	TERCERA_FASE_DECORADOS_PUERTA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_PUERTA_5
							dw	TERCERA_FASE_DECORADOS_ENTRADA_1
							dw	TERCERA_FASE_DECORADOS_ENTRADA_2
							dw	TERCERA_FASE_DECORADOS_ENTRADA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ENTRADA_5
							dw	TERCERA_FASE_DECORADOS_POCHADA_1
							dw	TERCERA_FASE_DECORADOS_POCHADA_2
							dw	TERCERA_FASE_DECORADOS_POCHADA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_POCHADA_5
							dw	TERCERA_FASE_DECORADOS_GRAFITI_1
							dw	TERCERA_FASE_DECORADOS_GRAFITI_2
							dw	TERCERA_FASE_DECORADOS_GRAFITI_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_GRAFITI_5
							dw	TERCERA_FASE_DECORADOS_LLAVE_1
							dw	TERCERA_FASE_DECORADOS_LLAVE_2
							dw	TERCERA_FASE_DECORADOS_LLAVE_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_LLAVE_5
							
POINT_TERCERA_FASE_DECORADOS_ESTE:
							
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_2
							dw	TERCERA_FASE_DECORADOS_ESCUDO_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_1
							dw	TERCERA_FASE_DECORADOS_ESCUDO_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESPEJO_2
							dw	TERCERA_FASE_DECORADOS_ESPEJO_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESPEJO_1
							dw	TERCERA_FASE_DECORADOS_ESPEJO_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_PUERTA_2
							dw	TERCERA_FASE_DECORADOS_PUERTA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_PUERTA_1
							dw	TERCERA_FASE_DECORADOS_PUERTA_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ENTRADA_2
							dw	TERCERA_FASE_DECORADOS_ENTRADA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ENTRADA_1
							dw	TERCERA_FASE_DECORADOS_ENTRADA_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_POCHADA_2
							dw	TERCERA_FASE_DECORADOS_POCHADA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_POCHADA_1
							dw	TERCERA_FASE_DECORADOS_POCHADA_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_GRAFITI_2
							dw	TERCERA_FASE_DECORADOS_GRAFITI_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_GRAFITI_1
							dw	TERCERA_FASE_DECORADOS_GRAFITI_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_LLAVE_2
							dw	TERCERA_FASE_DECORADOS_LLAVE_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_LLAVE_1
							dw	TERCERA_FASE_DECORADOS_LLAVE_5
							dw	TERCERA_FASE_DECORADOS_0
																																										

POINT_TERCERA_FASE_DECORADOS_SUR:
							
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_1
							dw	TERCERA_FASE_DECORADOS_ESCUDO_2
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_5
							dw	TERCERA_FASE_DECORADOS_ESPEJO_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESPEJO_1
							dw	TERCERA_FASE_DECORADOS_ESPEJO_2
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESPEJO_5
							dw	TERCERA_FASE_DECORADOS_PUERTA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_PUERTA_1
							dw	TERCERA_FASE_DECORADOS_PUERTA_2
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_PUERTA_5
							dw	TERCERA_FASE_DECORADOS_ENTRADA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ENTRADA_1
							dw	TERCERA_FASE_DECORADOS_ENTRADA_2
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ENTRADA_5
							dw	TERCERA_FASE_DECORADOS_POCHADA_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_POCHADA_1
							dw	TERCERA_FASE_DECORADOS_POCHADA_2
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_POCHADA_5
							dw	TERCERA_FASE_DECORADOS_GRAFITI_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_GRAFITI_1
							dw	TERCERA_FASE_DECORADOS_GRAFITI_2
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_GRAFITI_5
							dw	TERCERA_FASE_DECORADOS_LLAVE_3
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_LLAVE_1
							dw	TERCERA_FASE_DECORADOS_LLAVE_2
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_LLAVE_5
									
POINT_TERCERA_FASE_DECORADOS_OESTE:
							
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESCUDO_1
							dw	TERCERA_FASE_DECORADOS_ESCUDO_2
							dw	TERCERA_FASE_DECORADOS_ESCUDO_3
							dw	TERCERA_FASE_DECORADOS_ESCUDO_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ESPEJO_1
							dw	TERCERA_FASE_DECORADOS_ESPEJO_2
							dw	TERCERA_FASE_DECORADOS_ESPEJO_3
							dw	TERCERA_FASE_DECORADOS_ESPEJO_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_PUERTA_1
							dw	TERCERA_FASE_DECORADOS_PUERTA_2
							dw	TERCERA_FASE_DECORADOS_PUERTA_3
							dw	TERCERA_FASE_DECORADOS_PUERTA_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_ENTRADA_1
							dw	TERCERA_FASE_DECORADOS_ENTRADA_2
							dw	TERCERA_FASE_DECORADOS_ENTRADA_3
							dw	TERCERA_FASE_DECORADOS_ENTRADA_5
							dw	TERCERA_FASE_DECORADOS_0	
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_POCHADA_1
							dw	TERCERA_FASE_DECORADOS_POCHADA_2
							dw	TERCERA_FASE_DECORADOS_POCHADA_3
							dw	TERCERA_FASE_DECORADOS_POCHADA_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_GRAFITI_1
							dw	TERCERA_FASE_DECORADOS_GRAFITI_2
							dw	TERCERA_FASE_DECORADOS_GRAFITI_3
							dw	TERCERA_FASE_DECORADOS_GRAFITI_5
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_0
							dw	TERCERA_FASE_DECORADOS_LLAVE_1
							dw	TERCERA_FASE_DECORADOS_LLAVE_2
							dw	TERCERA_FASE_DECORADOS_LLAVE_3
							dw	TERCERA_FASE_DECORADOS_LLAVE_5
							dw	TERCERA_FASE_DECORADOS_0
																						
POINT_SEGUNDA_FASE_DECORADOS_NORTE:
							
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_1
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_2
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_5
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_1
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_2
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_5
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_1
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_2
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_5
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_1
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_2
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_5
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_1
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_2
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_5
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_1
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_2
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_5
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_1
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_2
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_5
																												
POINT_PRIMERA_FASE_DECORADOS_NORTE:
							
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_1
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_5
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_1
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_5
							dw	PRIMERA_FASE_DECORADOS_PUERTA_1
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2
							dw	PRIMERA_FASE_DECORADOS_PUERTA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2
							dw	PRIMERA_FASE_DECORADOS_PUERTA_5
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_1
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_5
							dw	PRIMERA_FASE_DECORADOS_POCHADA_1
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_POCHADA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_POCHADA_5
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_1
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_5
							dw	PRIMERA_FASE_DECORADOS_LLAVE_1
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
							dw	PRIMERA_FASE_DECORADOS_LLAVE_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
							dw	PRIMERA_FASE_DECORADOS_LLAVE_5
																																																																																			
POINT_SEGUNDA_FASE_DECORADOS_ESTE:
							
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_2
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_1
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_2
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_1
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_2
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_1
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_2
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_1
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_2
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_1
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_2
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_1
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_2
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_1
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_5
							dw	SEGUNDA_FASE_DECORADOS_0	
																																		
POINT_PRIMERA_FASE_DECORADOS_ESTE:
							
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_1
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_5
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_1
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_5
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2
							dw	PRIMERA_FASE_DECORADOS_PUERTA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_PUERTA_1
							dw	PRIMERA_FASE_DECORADOS_PUERTA_5
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_1
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_5
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_POCHADA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_POCHADA_1
							dw	PRIMERA_FASE_DECORADOS_POCHADA_5
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_1
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_5
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
							dw	PRIMERA_FASE_DECORADOS_LLAVE_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_LLAVE_1
							dw	PRIMERA_FASE_DECORADOS_LLAVE_5
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
																																																																																			
POINT_SEGUNDA_FASE_DECORADOS_SUR:
							
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_1
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_2
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_5
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_1
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_2
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_5
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_1
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_2
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_5	
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_1
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_2
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_5
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_1
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_2
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_5
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_1
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_2
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_5
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_3
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_1
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_2
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_5
																																		
POINT_PRIMERA_FASE_DECORADOS_SUR:
							
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_1
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_5
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_1
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_5
							dw	PRIMERA_FASE_DECORADOS_PUERTA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_PUERTA_1
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2
							dw	PRIMERA_FASE_DECORADOS_PUERTA_5
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_1
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_5
							dw	PRIMERA_FASE_DECORADOS_POCHADA_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_POCHADA_1
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_POCHADA_5
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_1
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_5
							dw	PRIMERA_FASE_DECORADOS_LLAVE_3
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_LLAVE_1
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
							dw	PRIMERA_FASE_DECORADOS_LLAVE_5
																															
POINT_SEGUNDA_FASE_DECORADOS_OESTE:
							
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_1
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_2
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_3
							dw	SEGUNDA_FASE_DECORADOS_ESCUDO_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_1
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_2
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_3
							dw	SEGUNDA_FASE_DECORADOS_ESPEJO_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_1
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_2
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_3
							dw	SEGUNDA_FASE_DECORADOS_PUERTA_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_1
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_2
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_3
							dw	SEGUNDA_FASE_DECORADOS_ENTRADA_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_1
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_2
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_3
							dw	SEGUNDA_FASE_DECORADOS_POCHADA_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_1
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_2
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_3
							dw	SEGUNDA_FASE_DECORADOS_GRAFITI_5
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_0
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_1
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_2
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_3
							dw	SEGUNDA_FASE_DECORADOS_LLAVE_5
							dw	SEGUNDA_FASE_DECORADOS_0
																																			
POINT_PRIMERA_FASE_DECORADOS_OESTE:
							
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_1
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_3
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_5
							dw	PRIMERA_FASE_DECORADOS_ESCUDO_2
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_1
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_3
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_5
							dw	PRIMERA_FASE_DECORADOS_ESPEJO_2
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_PUERTA_1
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2
							dw	PRIMERA_FASE_DECORADOS_PUERTA_3
							dw	PRIMERA_FASE_DECORADOS_PUERTA_5
							dw	PRIMERA_FASE_DECORADOS_PUERTA_2	
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_1
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_3
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_5
							dw	PRIMERA_FASE_DECORADOS_ENTRADA_2	
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_POCHADA_1
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_POCHADA_3
							dw	PRIMERA_FASE_DECORADOS_POCHADA_5
							dw	PRIMERA_FASE_DECORADOS_POCHADA_2
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_1
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_3
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_5
							dw	PRIMERA_FASE_DECORADOS_GRAFITI_2
							dw	PRIMERA_FASE_DECORADOS_0
							dw	PRIMERA_FASE_DECORADOS_LLAVE_1
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
							dw	PRIMERA_FASE_DECORADOS_LLAVE_3
							dw	PRIMERA_FASE_DECORADOS_LLAVE_5
							dw	PRIMERA_FASE_DECORADOS_LLAVE_2
																																																					
		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 24 DEL MEGAROM **********)))	
; ______________________________________________________________________

		
; (((********** PAGINA 25 DEL MEGAROM **********
	
	; DECORADOS 2 (ESPEJO)
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
COPIAMOS_LOS_ESPEJOS:				incbin		"SR5/ESPEJOS/ESPEJO_164x93.DAT"
COPIAMOS_ESPEJO_C_F:				incbin		"SR5/ESPEJOS/ESPEJO_CUARTA_FRENTE_10x14.DAT"
COPIAMOS_ESPEJO_T_F:				incbin		"SR5/ESPEJOS/ESPEJO_TERCERA_FRENTE_16x18.DAT"
COPIAMOS_ESPEJO_S_F:				incbin		"SR5/ESPEJOS/ESPEJO_SEGUNDA_FRENTE_18x28.DAT"
COPIAMOS_ESPEJO_T_D:				incbin		"SR5/ESPEJOS/ESPEJO_TERCERA_DERECHA_6x14.DAT"
COPIAMOS_ESPEJO_S_D:				incbin		"SR5/ESPEJOS/ESPEJO_SEGUNDA_DERECHA_12x29.DAT"
COPIAMOS_ESPEJO_P_D:				incbin		"SR5/ESPEJOS/ESPEJO_PRIMERA_DERECHA_16x54.DAT"
COPIAMOS_ESPEJO_T_I:				incbin		"SR5/ESPEJOS/ESPEJO_TERCERA_IZQUIERDA_6x15.DAT"
COPIAMOS_ESPEJO_S_I:				incbin		"SR5/ESPEJOS/ESPEJO_SEGUNDA_IZQUIERDA_12x29.DAT"
COPIAMOS_ESPEJO_P_I:				incbin		"SR5/ESPEJOS/ESPEJO_PRIMERA_IZQUIERDA_16x55.DAT"

copia_cuarta_fase_fondo_decorado_espejo:		dw		#007d,#003c,#000a,#000e
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_espejo:		dw		#007A,#003B,#0010,#0012
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_espejo:		dw		#0079,#0035,#0012,#001c
												db		#00,#00,#F0								

copia_tercera_fase_derecha_decorado_espejo:		dw		#008f,#003e,#0006,#000e
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_espejo:		dw		#00a2,#0034,#000c,#001d
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_espejo:		dw		#00b7,#0028,#0010,#0036
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_espejo:	dw		#006b,#003e,#0006,#000f
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_espejo:	dw		#0053,#0034,#000c,#001d
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_espejo:	dw		#003a,#0028,#0010,#0037
												db		#00,#00,#F0

copia_cuarta_fase_fondo_decorado_espejo1:		dw		#007d,#013c,#000a,#000e
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_espejo1:		dw		#007A,#013B,#0010,#0012
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_espejo1:		dw		#0079,#0135,#0012,#001c
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_espejo1:		dw		#0007,#017e,#0070,#0029,#0021,#0040

copia_tercera_fase_derecha_decorado_espejo1:	dw		#008f,#013e,#0006,#000e
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_espejo1:	dw		#00a2,#0134,#000c,#001d
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_espejo1:	dw		#00b7,#0128,#0010,#0036
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_espejo1:	dw		#006b,#013e,#0006,#000f
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_espejo1:	dw		#0053,#0134,#000c,#001d
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_espejo1:	dw		#003a,#0128,#0010,#0037
												db		#00,#00,#F0
												
		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 25 DEL MEGAROM **********)))		
; ______________________________________________________________________

		
; (((********** PAGINA 26 DEL MEGAROM **********
	
	; DECORADOS 6 (GRAFITIS CASTELLANO)
	; DECORADOS 8 (LLAVES)
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
COPIAMOS_GRAFITI_C_F:				incbin		"SR5/GRAFITIS/GRAFITIESP_CUARTA_FRENTE_22x15.DAT"
COPIAMOS_GRAFITI_T_F:				incbin		"SR5/GRAFITIS/GRAFITIESP_TERCERA_FRENTE_36x23.DAT"
COPIAMOS_GRAFITI_S_F:				incbin		"SR5/GRAFITIS/GRAFITIESP_SEGUNDA_FRENTE_50x35.DAT"
COPIAMOS_GRAFITI_P_F:				incbin		"SR5/GRAFITIS/GRAFITIESP_PRIMERA_FRENTE_90x59.DAT"
COPIAMOS_GRAFITI_T_D:				incbin		"SR5/GRAFITIS/GRAFITIESP_TERCERA_DERECHA_10x27.DAT"
COPIAMOS_GRAFITI_S_D:				incbin		"SR5/GRAFITIS/GRAFITIESP_SEGUNDA_DERECHA_18x48.DAT"
COPIAMOS_GRAFITI_P_D:				incbin		"SR5/GRAFITIS/GRAFITIESP_PRIMERA_DERECHA_28x77.DAT"
COPIAMOS_GRAFITI_T_I:				incbin		"SR5/GRAFITIS/GRAFITIESP_TERCERA_IZQUIERDA_10x28.DAT"
COPIAMOS_GRAFITI_S_I:				incbin		"SR5/GRAFITIS/GRAFITIESP_SEGUNDA_IZQUIERDA_18x46.DAT"
COPIAMOS_GRAFITI_P_I:				incbin		"SR5/GRAFITIS/GRAFITIESP_PRIMERA_IZQUIERDA_28x79.DAT"

COPIAMOS_GRAFITIE_C_F:				incbin		"SR5/GRAFITIS/GRAFITIING_CUARTA_FRENTE_20x14.DAT"
COPIAMOS_GRAFITIE_T_F:				incbin		"SR5/GRAFITIS/GRAFITIING_TERCERA_FRENTE_30x21.DAT"
COPIAMOS_GRAFITIE_S_F:				incbin		"SR5/GRAFITIS/GRAFITIING_SEGUNDA_FRENTE_48x32.DAT"
COPIAMOS_GRAFITIE_P_F:				incbin		"SR5/GRAFITIS/GRAFITIING_PRIMERA_FRENTE_84x56.DAT"

COPIAMOS_LLAVE_T_F:					incbin		"SR5/LLAVES/LLAVES_TERCERA_FRENTE_8X9.DAT"
COPIAMOS_LLAVE_S_F:					incbin		"SR5/LLAVES/LLAVES_SEGUNDA_FRENTE_16X18.DAT"
COPIAMOS_LLAVE_P_F:					incbin		"SR5/LLAVES/LLAVES_PRIMERA_FRENTE_26X30.DAT"
COPIAMOS_LLAVE_T_D:					incbin		"SR5/LLAVES/LLAVES_TERCERA_DERECHA_8X11.DAT"
COPIAMOS_LLAVE_S_D:					incbin		"SR5/LLAVES/LLAVES_SEGUNDA_DERECHA_10X22.DAT"
COPIAMOS_LLAVE_P_D:					incbin		"SR5/LLAVES/LLAVES_PRIMERA_DERECHA_14X34.DAT"
COPIAMOS_LLAVE_T_I:					incbin		"SR5/LLAVES/LLAVES_TERCERA_IZQUIERDA_8X11.DAT"
COPIAMOS_LLAVE_S_I:					incbin		"SR5/LLAVES/LLAVES_SEGUNDA_IZQUIERDA_10X23.DAT"
COPIAMOS_LLAVE_P_I:					incbin		"SR5/LLAVES/LLAVES_PRIMERA_IZQUIERDA_14X35.DAT"

copia_cuarta_fase_fondo_decorado_grafiti:		dw		#0078,#003B,#0016,#000f
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_grafiti:		dw		#0073,#0037,#0024,#0017
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_grafiti:		dw		#0066,#0032,#0032,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_grafiti:		dw		#0055,#0027,#005A,#003B
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_grafiti:	dw		#0090,#0036,#000A,#001B
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_grafiti:	dw		#009C,#0034,#0012,#0030
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_grafiti:	dw		#00AE,#0027,#001C,#004D
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_grafiti:	dw		#0068,#0036,#000A,#001C
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_grafiti:	dw		#0055,#002f,#0012,#002E
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_grafiti:	dw		#0039,#001F,#001C,#004F
												db		#00,#00,#F0

copia_cuarta_fase_fondo_decorado_grafiti1:		dw		#0078,#013B,#0016,#000f
												db		#00,#00,#F0
copia_tercera_fase_fondo_decorado_grafiti1:		dw		#0073,#0137,#0024,#0017
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_grafiti1:		dw		#0066,#0132,#0032,#0023
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_grafiti1:		dw		#0055,#0127,#005A,#003B
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_grafiti1:	dw		#0090,#0136,#000A,#001B
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_grafiti1:	dw		#009C,#0134,#0012,#0030
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_grafiti1:	dw		#00AE,#0127,#001C,#004D
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_grafiti1:	dw		#0068,#0136,#000A,#001C
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_grafiti1:	dw		#0055,#012f,#0012,#002E
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_grafiti1:	dw		#0039,#011F,#001C,#004F
												db		#00,#00,#F0
												
copia_tercera_fase_fondo_decorado_llave:		dw		#007B,#003A,#0008,#0009
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_llave:		dw		#0076,#0034,#0010,#0012
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_llave:		dw		#0071,#002D,#001A,#001E
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_llave:		dw		#008f,#003A,#0008,#0011
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_llave:		dw		#009E,#0034,#000A,#0016
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_llave:		dw		#00b4,#002C,#000e,#0022
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_llave:	dw		#006b,#003A,#0008,#0011
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_llave:	dw		#005a,#0034,#000A,#0017
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_llave:	dw		#003C,#002C,#000e,#0023
												db		#00,#00,#F0
												
copia_tercera_fase_fondo_decorado_llave1:		dw		#007B,#013A,#0008,#0009
												db		#00,#00,#F0
copia_segunda_fase_fondo_decorado_llave1:		dw		#0076,#0134,#0010,#0012
												db		#00,#00,#F0
copia_primera_fase_fondo_decorado_llave1:		dw		#0071,#012D,#001A,#001E
												db		#00,#00,#F0

copia_tercera_fase_derecha_decorado_llave1:		dw		#008f,#013A,#0008,#0011
												db		#00,#00,#F0
copia_segunda_fase_derecha_decorado_llave1:		dw		#009E,#0134,#000A,#0016
												db		#00,#00,#F0
copia_primera_fase_derecha_decorado_llave1:		dw		#00b4,#012C,#000e,#0022
												db		#00,#00,#F0

copia_tercera_fase_izquierda_decorado_llave1:	dw		#006b,#013A,#0008,#0011 
												db		#00,#00,#F0
copia_segunda_fase_izquierda_decorado_llave1:	dw		#005a,#0134,#000A,#0017
												db		#00,#00,#F0
copia_primera_fase_izquierda_decorado_llave1:	dw		#003C,#012C,#000e,#0023
												db		#00,#00,#F0	
												
		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 26 DEL MEGAROM **********)))	

; (((********** PAGINA 27 DEL MEGAROM **********
	
	; VIEJIGUIAS
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)
		
VIEJI1:								incbin		"SR5/VIEJIGUIAS/VIEJI1_148x106.DAT"
VIEJI2:								incbin		"SR5/VIEJIGUIAS/vieji2_148x106.DAT"
		
		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 27 DEL MEGAROM **********)))

; ______________________________________________________________________

		
; (((********** PAGINA 28 DEL MEGAROM **********
	
	; POCHADEROS 2,3 Y 4
	
		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)

COPIAMOS_POCHADERO2:				incbin		"SR5/POCHADAS/POCHADERO2_112x76.DAT"
COPIAMOS_POCHADERO3:				incbin		"SR5/POCHADAS/POCHADERO3_112x76.DAT"
COPIAMOS_POCHADERO4:				incbin		"SR5/POCHADAS/POCHADERO4_112x76.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque
				
; ********** FIN PAGINA 28 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 29 DEL MEGAROM **********
	
; HATER 1 CARAS


		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)

HATER_1_FELIZ:				incbin		"SR5/HATERS/HATER1FELIZ_50x61.DAT"		
HATER_1_TRISTE:				incbin		"SR5/HATERS/HATER1TRISTE_50x61.DAT"
HATER_1_ENFADADO:			incbin		"SR5/HATERS/HATER1ENFADADO_50x61.DAT"		
HATER_1_MUERTO:				incbin		"SR5/HATERS/HATER1MUERTO_50x61.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 29 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 30 DEL MEGAROM **********
	
; HATER 1 CARAS


		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)

HATER_2_FELIZ:				incbin		"SR5/HATERS/HATER2FELIZ_50x61.DAT"		
HATER_2_TRISTE:				incbin		"SR5/HATERS/HATER2TRISTE_50x61.DAT"
HATER_2_ENFADADO:			incbin		"SR5/HATERS/HATER2ENFADADO_50x61.DAT"		
HATER_2_MUERTO:				incbin		"SR5/HATERS/HATER2MUERTO_50x61.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 30 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 31 DEL MEGAROM **********
	
; HATER 1 CARAS


		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)

HATER_3_FELIZ:				incbin		"SR5/HATERS/HATER3FELIZ_50x61.DAT"		
HATER_3_TRISTE:				incbin		"SR5/HATERS/HATER3TRISTE_50x61.DAT"
HATER_3_ENFADADO:			incbin		"SR5/HATERS/HATER3ENFADADO_50x61.DAT"		
HATER_3_MUERTO:				incbin		"SR5/HATERS/HATER3MUERTO_50x61.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 31 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 32 DEL MEGAROM **********
	
; HATER 1 CARAS


		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)

HATER_4_FELIZ:				incbin		"SR5/HATERS/HATER4FELIZ_50x61.DAT"		
HATER_4_TRISTE:				incbin		"SR5/HATERS/HATER4TRISTE_50x61.DAT"
HATER_4_ENFADADO:			incbin		"SR5/HATERS/HATER4ENFADADO_50x61.DAT"		
HATER_4_MUERTO:				incbin		"SR5/HATERS/HATER4MUERTO_50x61.DAT"

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 32 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 33 DEL MEGAROM **********
	
; DIBUJO DE HATER 3 y 4

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 2)

COPIAMOS_HATER3:			incbin		"SR5/HATERS/HATER3CARA_148x106.DAT"		
COPIAMOS_HATER4:			incbin		"SR5/HATERS/HATER4CARA_148x106.DAT"		

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 33 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 34 DEL MEGAROM **********
	
; MENU PARTE 2

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

SELEC_MENU_2:				incbin		"SR5/MENU/MENU_256X212.DAT2"
LETRAS:						incbin		"sr5/menu/LETRAS_126x8.DAT"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 34 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 35 DEL MEGAROM **********
	
; CARAMBALAN STUDIOS PRESENTA

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)


CSP:						incbin		"SR5/MENU/CSP_208x134.DAT"
copia_carambalan_en_pantalla:	dw		#0018,#0327,#00d0,#0086
								db		#00,#00,#F0	

											
		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 35 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 36 DEL MEGAROM **********
	
; CARAMBALAN STUDIOS PRESENTA JUEGO DE COLORES

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

HISTORIA:					incbin		"MUSICAS/HISTORIA.MBM"

CSP1_IN:					incbin		"PL5/CSP1.FADEIN"
CSP2_IN:					incbin		"PL5/CSP2.FADEIN"
CSP3_IN:					incbin		"PL5/CSP3.FADEIN"
CSP4_IN:					incbin		"PL5/CSP4.FADEIN"
CSP5_IN:					incbin		"PL5/CSP5.FADEIN"
CSP6_IN:					incbin		"PL5/CSP6.FADEIN"
CSP7_IN:					incbin		"PL5/CSP7.FADEIN"
CSP8_IN:					incbin		"PL5/CSP8.FADEIN"
CSP9_IN:					incbin		"PL5/CSP9.FADEIN"
CSP10_IN:					incbin		"PL5/CSP10.FADEIN"
CSP11_IN:					incbin		"PL5/CSP11.FADEIN"
CSP12_IN:					incbin		"PL5/CSP12.FADEIN"
CSP_OUT:					incbin		"PL5/CSP.FADEOUT"

copia_carambalan_trozo:		dw		#0018,#0327,#0018,#0027,#0027,#002d
												
		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 36 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 37 DEL MEGAROM **********

; TIENDA
; ENEMIGOS FINALES

		org		#4000
		
COMIENZA_TIENDA:

		di
		call	stpmus													; paramos la antigua musica
		ei
		
		ld		a,1
		ld		(que_musica_0),a
		
		LD		A,39		
		call	EL_7000_37
		
		di
		call	strmus													;iniciamos la música de tienda
		ei
		
		ld		a,1
		ld		(no_borra_texto),a
		
		LD		A,16
		call	EL_7000_37
	
		ld		a,15
		ld		c,0
		call	ayFX_INIT
		
		LD		A,(pagina_de_idioma)
		call	EL_7000_37
		
		ld		a,(set_page01)
		cp		1
		jp		z,.CONTINUAMOS

		ld		iy,copia_escenario_a_page_1								; Si estamos en page 0. Vamos a clonar la 0 en la 1
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO
		
		ld		a,1
		ld		(set_page01),a
		
.CONTINUAMOS:
				
		ld		iy,copia_objetos_a_salvo								; GUARDA OBJETOS DE LOS DOS JUGADORES DIBUJADOS
		CALL	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		iy,cuadrado_que_limpia_5_del_37							; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,cuadrado_que_limpia_5_1_del_37						; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				

		ld		iy,cuadrado_que_limpia_8								; BORRA ZONA DE OBJETOS
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

COMPROBAMOS_EL_POCHADERO_A_COPIAR:
		
		ld		a,2														; CAMBIA PALETA A POCHADERO 2 O 3
		ld		(paleta_a_usar_en_vblank),a
		
		LD		A,28													; COPIA POCHADERO A VISTA
		call	EL_7000_37
		
		ld		ix,eventos_laberinto									;ponemos en ix el valor de evento que hay en la casilla que está el jugador
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		ld		a,(ix)
		push	af
		
		cp		30
		jp		Z,.POSADERO2
		cp		31
		jp		Z,.POSADERO3
		cp		32
		jp		Z,.POSADERO4

.POSADERO1:
				
		ld		a,6														; CAMBIA PALETA A POCHADERO
		ld		(paleta_a_usar_en_vblank),a

		LD		A,18													; COPIA POCHADERO A VISTA
		call	EL_7000_37

		ld		de,COPIAMOS_POCHADERO1
		jp		COPIA_EL_POCHADERO

.POSADERO2:
				
		ld		de,COPIAMOS_POCHADERO2
		jp		COPIA_EL_POCHADERO

.POSADERO3:
				
		ld		de,COPIAMOS_POCHADERO3
		jp		COPIA_EL_POCHADERO

.POSADERO4:
				
		ld		a,7														; CAMBIA PALETA A POCHADERO
		ld		(paleta_a_usar_en_vblank),a

		ld		de,COPIAMOS_POCHADERO4
								
COPIA_EL_POCHADERO:
		
		ld		hl,copia_pochadero_en_pantalla
		call	ESPERA_AL_VDP_HMMC
		
		ld		iy,copia_dormir_en_lista								; CARGA OPCIONES
		CALL	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		iy,copia_salir_en_lista
		CALL	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,(tienda_objeto_2)
		call	PINTAMOS_EN_TIENDA_OBJETO_ADECUADO
		CALL	COPY_A_GUSTO
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		xor		a
		ld		(set_page01),a
		
		ld		a,(tienda_objeto_3)
		call	PINTAMOS_EN_TIENDA_OBJETO_ADECUADO
		CALL	COPY_A_GUSTO
		ld		a,#72
		ld		(ix+4),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,(tienda_objeto_4)
		call	PINTAMOS_EN_TIENDA_OBJETO_ADECUADO
		CALL	COPY_A_GUSTO		
		ld		a,#89
		ld		(ix+4),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,(tienda_objeto_5)
		cp		0
		jp		z,.PLUMA
		cp		1
		jp		z,.PAPEL
		cp		2
		jp		z,.TINTA
		cp		3
		jp		z,.LUPA
		cp		4
		jp		z,.BRUJULA
		cp		5
		jp		z,.GALLINA
		ld		iy,tapa_objeto_en_tienda
		
		jp		CONTINUAMOS_EN_LA_POCHADA
		
		
.PLUMA:

		ld		iy,copia_pluma_en_lista
		jp		CONTINUAMOS_EN_LA_POCHADA

.PAPEL:

		ld		iy,copia_papel_en_lista
		jp		CONTINUAMOS_EN_LA_POCHADA

.TINTA:

		ld		iy,copia_tinta_en_lista
		jp		CONTINUAMOS_EN_LA_POCHADA

.LUPA:

		ld		iy,copia_lupa_en_lista
		jp		CONTINUAMOS_EN_LA_POCHADA

.BRUJULA:

		ld		iy,copia_brujula_en_lista
		jp		CONTINUAMOS_EN_LA_POCHADA

.GALLINA:

		ld		iy,copia_gallina_en_lista
		jp		CONTINUAMOS_EN_LA_POCHADA
					
CONTINUAMOS_EN_LA_POCHADA:


						
		CALL	COPY_A_GUSTO
		ld		a,#9c
		ld		(ix+4),a			
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
								
		ld		a,(pagina_de_idioma)													; MENSAJE ¿QUÉ PUEDO HACER POR TI?
		call	EL_7000_37
		
		pop		af														; SACAMOS EL VALOR DEL POCHADERO QUE TOCA
		
		cp		30
		jp		z,.POCHADERO2ESP
		cp		31
		jp		z,.POCHADERO3ESP
		cp		32
		jp		z,.POCHADERO4ESP

.POCHADERO1ESP:
		
		xor		a
		ld		(pagina_hater),a										; utilizamos la misma variable para hater y pochadero
		jp		.TERMINA_TEXTO

.POCHADERO2ESP:

		ld		a,1
		ld		(pagina_hater),a										; utilizamos la misma variable para hater y pochadero		
		jp		.TERMINA_TEXTO

.POCHADERO3ESP:

		ld		a,2
		ld		(pagina_hater),a										; utilizamos la misma variable para hater y pochadero			
		jp		.TERMINA_TEXTO

.POCHADERO4ESP:

		ld		a,3
		ld		(pagina_hater),a										; utilizamos la misma variable para hater y pochadero			
					
.TERMINA_TEXTO:
		
		ld		ix,HOLA_POCHADA_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		
		call	HOLA_EN_POCHADA_FINAL
		
		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_mano_en_lista									; PRESENTAMOS LA MANO SELECCIONADORA
		CALL	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		

		ld		a,#46
		ld		(x_tienda),a
		
RUTINA_DE_SELECCION:													; RUTINA STICK/STRIG

		xor		a														; STICK
		call	.SUBRUTINA_DE_STICK
		ld		a,(turno)
		call	.SUBRUTINA_DE_STICK
		jp		STRIG_DE_TIENDA											; STRIG

.SUBRUTINA_DE_STICK:
		
		call	GTSTCK
		
		cp		3
		jr.		z,OBJETO_SIGUIENTE
		
		cp		7
		jr.		z,OBJETO_ANTERIOR
		
		ret
		
OBJETO_SIGUIENTE:
		
		ld		a,(x_tienda)
		cp		#b4
		ret		z
		add		#16
				
		jp		PINTAMOS_LA_MANO
		
OBJETO_ANTERIOR:

		ld		a,(x_tienda)
		cp		#46
		ret		z
		sub		#16


		
PINTAMOS_LA_MANO:

		ld		(x_tienda),a
		
		LD		A,16
		call	EL_7000_37
		
		ld		a,6
		ld		c,2
		call	ayFX_INIT
		
		LD		A,(pagina_de_idioma)
		call	EL_7000_37
		
		ld		iy,cuadrado_que_limpia_9								; BORRA ZONA MANO
		call	COPY_A_GUSTO
											
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		iy,copia_mano_en_lista									; PRESENTAMOS LA MANO SELECCIONADORA
		CALL	COPY_A_GUSTO
		
		ld		a,(x_tienda)
		ld		(ix+4),a
		call	EL_12_A_0_EL_14_A_1001

				
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY	

		ld		a,(x_tienda)
		cp		#46
		jp		z,TEXTO_NOCHE
		cp		#5c
		jp		z,OBJETOS_PRIMER_BLOQUE
		cp		#72
		jp		z,OBJETOS_SEGUNDO_BLOQUE
		cp		#88
		jp		z,OBJETOS_TERCER_BLOQUE
		cp		#9E
		jp		z,OBJETOS_CUARTO_BLOQUE
		cp		#B4
		jp		z,SALIDA_DE_LA_TIENDA

TEXTO_NOCHE:
										

		call	PASAR_LA_NOCHE
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		JP		TEXTO_A_ESCRIBIR		

OBJETOS_PRIMER_BLOQUE:

		ld		a,(tienda_objeto_2)

COMUN_BLOQUES_2_3_4:

		cp		6
		jp		z,AVISO_DE_ESTANTE_VACIO
		cp		7
		ret		z
		cp		1
		jp		z,OBJETO_DE_60
		cp		2
		jp		z,OBJETO_DE_60

		call	PAGA_30		
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		jp		TEXTO_A_ESCRIBIR

AVISO_DE_ESTANTE_VACIO:

		ld		hl,ESTANTE_VACIO_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		jp		TEXTO_A_ESCRIBIR
				
OBJETOS_SEGUNDO_BLOQUE:

		ld		a,(tienda_objeto_3)
		jp		COMUN_BLOQUES_2_3_4

OBJETOS_TERCER_BLOQUE:

		ld		a,(tienda_objeto_4)
		jp		COMUN_BLOQUES_2_3_4

OBJETO_DE_60:

		call	PAGA_60		
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		jp		TEXTO_A_ESCRIBIR

OBJETOS_CUARTO_BLOQUE:

		ld		a,(tienda_objeto_5)
		cp		6
		ret		z

		call	PAGA_90
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		jp		TEXTO_A_ESCRIBIR
		
SALIDA_DE_LA_TIENDA:

		call	SALIR_DE_POSADA
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		jp		TEXTO_A_ESCRIBIR
	
STRIG_DE_TIENDA:

		xor		a
		call	.SUBRUTINA_DE_TRIG
		ld		a,(turno)
		call	.SUBRUTINA_DE_TRIG
		
		ld		a,(turno)
		add		2
		CALL	GTTRIG
		CP		255
		call	Z,VAMOS_A_VER_NUESTROS_OBJETOS

		ld		a,4														
		call	SNSMAT
		bit		2,a
		call	z,VAMOS_A_VER_NUESTROS_OBJETOS
		
		jp		RUTINA_DE_SELECCION
		
.SUBRUTINA_DE_TRIG:
		
		CALL	GTTRIG
		
		cp		255
		jp		z,QUE_ES_LO_QUE_SELECCIONA
		
		ret

QUE_ES_LO_QUE_SELECCIONA:

		LD		A,16
		call	EL_7000_37
		
		ld		a,7
		ld		c,1
		call	ayFX_INIT
		
		LD		A,(pagina_de_idioma)
		call	EL_7000_37
		
		ld		a,(x_tienda)
		cp		#46
		jp		z,COMPRA_NOCHE
		cp		#5c
		jp		z,COMPRA_PRIMER_OBJETO
		cp		#72
		jp		z,COMPRA_SEGUNDO_OBJETO
		cp		#88
		jp		z,COMPRA_TERCER_OBJETO
		cp		#9E
		jp		z,COMPRA_CUARTO_OBJETO
		cp		#B4
		jp		z,SALE_DE_LA_TIENDA
		
COMPRA_NOCHE:															; PASA UNA NOCHE
		
		call	DESCUBRE_CUANTAS_BITNEDAS_TIENE							; ¿PUEDE PAGAR?
		ld		a,30
		call	SON_SUFICIENTES_O_NO
		
		ld		a,30													; RESTA DINERO
		ld		(var_cuentas_peq),a		
		call	RESTAMOS_EL_DINERO_ADECUADO
		call	PINTA_BITNEDAS
				
		xor		a														; PIERDE TURNO
		ld		(desplazamiento_real),a

		ld		a,20													; RECUPERA_VIDA
		ld		(var_cuentas_peq),a		
		call	SUMAMOS_LA_VIDA_ADECUADA
		call	PINTA_VIDA															

		ld		a,81
		ld		(mosca_y_objetivo),a
		
		ld		a,(turno)
		cp		1
		jp		nz,.COORDENADAS_MOSCA_2
		
		ld		a,28
		ld		(mosca_x_objetivo),a
		jp		.COMPRA_NOCHE

.COORDENADAS_MOSCA_2:

		ld		a,235
		ld		(mosca_x_objetivo),a

.COMPRA_NOCHE:
		
		call	BUENAS_NOCHES
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
				
		call	STRIG_DE_CONTINUE
		jp		SALE_DE_LA_TIENDA

COMPRA_PRIMER_OBJETO:													; COMPRA UN OBJETO
		
		ld		a,2
		ld		(objeto_del_que_hablamos),a
										
		ld		a,(tienda_objeto_2)										; DA VALOR A LA SECUENCIA CON EL OBJETO EN EL QUE ESTÁ
		ld		b,a
				   
		ld		a,(cantidad_de_jugadores)
		cp		2
		jp		z,COMUN_DE_TRES_OBJETOS
		
		ld		a,b
		cp		6
		ret		z
		
		call	COMUN_DE_TRES_OBJETOS

		ret
		
COMPRA_SEGUNDO_OBJETO:

		ld		a,3
		ld		(objeto_del_que_hablamos),a
		
		ld		a,(tienda_objeto_3)										; DA VALOR A LA SECUENCIA CON EL OBJETO EN EL QUE ESTÁ
		ld		b,a
				   
		ld		a,(cantidad_de_jugadores)
		cp		2
		jp		z,COMUN_DE_TRES_OBJETOS
		
		ld		a,b
		cp		6
		ret		z
		call	COMUN_DE_TRES_OBJETOS

		ret
		
COMPRA_TERCER_OBJETO:

		ld		a,4
		ld		(objeto_del_que_hablamos),a

		ld		a,(tienda_objeto_4)										; DA VALOR A LA SECUENCIA CON EL OBJETO EN EL QUE ESTÁ
		ld		b,a
				   
		ld		a,(cantidad_de_jugadores)
		cp		2
		jp		z,COMUN_DE_TRES_OBJETOS
		
		ld		a,b
		cp		6
		ret		z
		call	COMUN_DE_TRES_OBJETOS

		ret

MIRAMOS_SI_PONEMOS_BOMBA:
		
		ld		a,(cantidad_de_jugadores)
		cp		2
		ret		nz
		
		call	COMUN_DE_TRES_OBJETOS
		ret
		
COMUN_DE_TRES_OBJETOS:
		
		ld		a,b

		ld		(objeto_en_curso),a
		ld		b,a														; AVERIGUA EL OBJETO QUE ES PARA DARLE UN VALOR
		ld		a,30													
		ld		(valor_decidido),a
		ld		a,b
		cp		1
		call	z,VALOR_CARO
		cp		2
		call	z,VALOR_CARO
				
		call	DESCUBRE_CUANTAS_BITNEDAS_TIENE							; ¿PUEDE PAGAR?
		ld		a,(valor_decidido)
		call	SON_SUFICIENTES_O_NO

		ld		a,(valor_decidido)										; RESTA DINERO
		ld		(var_cuentas_peq),a		
		call	RESTAMOS_EL_DINERO_ADECUADO
		call	PINTA_BITNEDAS
		
		ld		a,(objeto_en_curso)										; AÑADE OBJETO A DIBUJO Y AÑADE CUALIDADES
		ld 		de,POINT_OBJETOS_EN_TIENDA
		jp		lista_de_opciones
										
BOTAS_EN_TIENDA:

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,BOTAS_CU

		call	TEXTO_A_ESCRIBIR
		
		ld		a,(botas)
		or		a
		ret		nz
		
		inc		a
		ld		(botas),a

		ld		iy,copia_botas_en_objetos_tienda						; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		ld		a,(ix+6)
		add		#54
		ld		(ix+6),a												
		call	EL_12_A_0_EL_14_A_1001

		
		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		a,5
		ld		(mosca_y_objetivo),a
				
		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		a,#C0
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		a,(botas_esp)
		or		a
		jp		nz,.RESTA_BOTAS
		
		ld		a,(incremento_velocidad)
		inc		a
		ld		(incremento_velocidad),a

		jp		DIBUJA_COMUN_BOTAS

.RESTA_BOTAS:

		xor		a
		ld		(botas_esp),a
		
		ld		a,(incremento_velocidad)
		dec		a
		ld		(incremento_velocidad),a

DIBUJA_COMUN_BOTAS:
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD_37						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
FINAL_COMUN_OBJETOS_EN_TIENDA:
		
		ld		iy,tapa_objeto_en_tienda								; BORRA ZONA OBJETO COMPRADO
		call	COPY_A_GUSTO
		
		ld		a,(objeto_del_que_hablamos)
		
		cp		2
		jp		z,.TERMINANDO_FINAL_COMUN
		
		cp		3
		jp		nz,.ULTIMA_SELECCION
		ld		a,#72
		ld		(ix+4),a
		jp		.TERMINANDO_FINAL_COMUN
		
.ULTIMA_SELECCION:
		
		cp		4
		jp		nz,.TERMINANDO_FINAL_COMUN
		ld		a,#88
		ld		(ix+4),a		

.TERMINANDO_FINAL_COMUN:
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,SIGUE_OBJETOS_1_2_3
		
		ld		iy,tapa_objeto_en_tienda_con_trampa						; BORRA ZONA OBJETO COMPRADO
		call	COPY_A_GUSTO
		ld		a,(x_tienda)
		ld		(ix+4),a
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
																			
		jp		SIGUE_OBJETOS_1_2_3
		
BOTAS_ESP_EN_TIENDA:

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,BOTAS_ESP_CU

		call	TEXTO_A_ESCRIBIR
		
		ld		a,(botas_esp)
		or		a
		ret		nz
		
		inc		a
		ld		(botas_esp),a

		ld		iy,copia_botas_esp_en_objetos_tienda							; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		ld		a,(ix+6)
		add		#54
		ld		(ix+6),a												
		call	EL_12_A_0_EL_14_A_1001


		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		a,5
		ld		(mosca_y_objetivo),a
		
		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		a,#be
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		a,(botas)
		or		a
		jp		nz,.SUMA_BOTAS
		
		ld		a,(incremento_velocidad)
		add		2
		ld		(incremento_velocidad),a

		jp		DIBUJA_COMUN_BOTAS

.SUMA_BOTAS:

		xor		a
		ld		(botas),a
		
		ld		a,(incremento_velocidad)
		inc		a
		ld		(incremento_velocidad),a
		
		jp		DIBUJA_COMUN_BOTAS
		
ESPADA_EN_TIENDA:

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,ESPADA_CU

		call	TEXTO_A_ESCRIBIR
		
		ld		a,(espada)
		or		a
		ret		nz
		
		inc		a
		ld		(espada),a

		ld		iy,copia_espada_en_objetos_tienda								; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		ld		a,(ix+6)
		add		#54
		ld		(ix+6),a												
		call	EL_12_A_0_EL_14_A_1001


		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		a,#b2
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		a,(cuchillo)
		or		a
		jp		nz,.SUMA_CUCHILLO
		
		ld		a,(incremento_ataque)
		add		2
		ld		(incremento_ataque),a

		jp		DIBUJA_COMUN_CUCHILLO

.SUMA_CUCHILLO:

		xor		a
		ld		(cuchillo),a
		
		ld		a,(incremento_ataque)
		inc		a
		ld		(incremento_ataque),a
		
		jp		DIBUJA_COMUN_CUCHILLO

CUCHILLO_EN_TIENDA:

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,CUCHILLO_CU

		call	TEXTO_A_ESCRIBIR
		
		ld		a,(cuchillo)
		or		a
		ret		nz
		
		inc		a
		ld		(cuchillo),a

		ld		iy,copia_cuchillo_en_objetos_tienda							; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		ld		a,(ix+6)
		add		#54
		ld		(ix+6),a												
		call	EL_12_A_0_EL_14_A_1001


		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a

		ld		a,#b2
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		a,(espada)
		or		a
		jp		nz,.RESTA_CUCHILLO
		
		ld		a,(incremento_ataque)
		inc		a
		ld		(incremento_ataque),a

		jp		DIBUJA_COMUN_CUCHILLO

.RESTA_CUCHILLO:

		xor		a
		ld		(espada),a
		
		ld		a,(incremento_ataque)
		dec		a
		ld		(incremento_ataque),a

DIBUJA_COMUN_CUCHILLO:
		
		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de ataque
		ld		a,(incremento_ataque)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		jp		FINAL_COMUN_OBJETOS_EN_TIENDA
		
CASCO_EN_TIENDA:

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,CASCO_CU
	
		call	TEXTO_A_ESCRIBIR
				
		ld		a,(casco)
		or		a
		jp		nz,.NO_SUMA_MAS
		
		ld		a,(incremento_defensa)
		inc		a
		ld		(incremento_defensa),a
		
.NO_SUMA_MAS:
		
		ld		a,1
		ld		(casco),a

		ld		iy,copia_casco_en_objetos_tienda								; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		ld		a,(ix+6)
		add		#54
		ld		(ix+6),a												
		call	EL_12_A_0_EL_14_A_1001


		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		a,#9a
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
COMUN_CASCO_ARMADURA:

		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de defensa
		ld		a,(incremento_defensa)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
						
		jp		FINAL_COMUN_OBJETOS_EN_TIENDA
		
ARMADURA_EN_TIENDA:

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,ARMADURA_CU

		call	TEXTO_A_ESCRIBIR
		
		ld		a,(armadura)
		or		a
		jp		nz,.NO_SUMA_MAS
		
		ld		a,(incremento_defensa)
		inc		a
		ld		(incremento_defensa),a
		
.NO_SUMA_MAS:
		
		ld		a,1
		ld		(armadura),a

		ld		iy,copia_armadura_en_objetos_tienda							; PINTA OBJETO ENTRE LOS OBJETOS
		CALL	COPY_A_GUSTO
		ld		a,(ix+6)
		add		#54
		ld		(ix+6),a												
		call	EL_12_A_0_EL_14_A_1001


		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		a,#a5
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		jp		COMUN_CASCO_ARMADURA

TRAMPA_EN_TIENDA:

		ld		a,(trampa)
		inc		a
		ld		(trampa),a

		ld		hl,TRAMPA_COMP_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TRAMPA_COMP_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		a,(trampa)
		cp		2
		jp		nc,MAS_DE_UNA_TRAMPA
		
		ld		iy,copia_trampa_en_objetos								; PINTA OBJETO ENTRE LOS OBJETOS

		jp		COMUN_DE_TRAMPAS

MAS_DE_UNA_TRAMPA:

		ld		iy,copia_trampas_en_objetos								; PINTA OBJETO ENTRE LOS OBJETOS

COMUN_DE_TRAMPAS:

		CALL	COPY_A_GUSTO
									
		call	EL_12_A_0_EL_14_A_1001


		ld		a,(turno)
		cp		1
		jp		z,.DIBUJAMOS_OBJETO

		ld		a,#d3
		ld		(ix+4),a
		
.DIBUJAMOS_OBJETO:
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_trampa_en_objetos_1								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_trampa_en_objetos_2								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		FINAL_COMUN_OBJETOS_EN_TIENDA
				
SIGUE_OBJETOS_1_2_3:
		
		
		ld		a,(objeto_del_que_hablamos)
		cp		2
		jp		z,.DOS
		cp		3
		jp		z,.TRES
		cp		4
		jp		z,.CUATRO
		
.DOS:

		ld		a,6
		ld		(tienda_objeto_2),a
		
		ret																; VUELVE

.TRES:

		ld		a,6
		ld		(tienda_objeto_3),a
		
		ret																; VUELVE

.CUATRO:

		ld		a,6
		ld		(tienda_objeto_4),a
		
		ret																; VUELVE
				
VALOR_CARO:

		ld		a,60
		ld		(valor_decidido),a
		
		ret
		
COMPRA_CUARTO_OBJETO:

		ld		a,5
		ld		(objeto_del_que_hablamos),a

		ld		a,(tienda_objeto_5)										; DA VALOR A LA SECUENCIA CON EL OBJETO EN EL QUE ESTÁ
		cp		6
		ret		z

		ld		(objeto_en_curso),a
		ld		a,90													
		ld		(valor_decidido),a
					
		call	DESCUBRE_CUANTAS_BITNEDAS_TIENE							; ¿PUEDE PAGAR?
		ld		a,90
		call	SON_SUFICIENTES_O_NO

		ld		a,90													; RESTA DINERO
		ld		(var_cuentas_peq),a		
		call	RESTAMOS_EL_DINERO_ADECUADO
		call	PINTA_BITNEDAS
			
		ld		a,(objeto_en_curso)										; AÑADE OBJETO A DIBUJO Y AÑADE CUALIDADES
		ld 		de,POINT_OBJETOS_EN_TIENDA_2
		jp		lista_de_opciones		

PLUMA_EN_TIENDA:

		ld		a,1
		ld		(pluma),a

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,PLUMA_2_ESP

		call	TEXTO_A_ESCRIBIR
		ld		iy,copia_pluma_en_objetos_tienda								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		ld		a,(turno)
		cp		1
		jp		z,COMUN_BLOQUE_5

		ld		a,#9A
		ld		(ix+4),a
		
COMUN_BLOQUE_5:

		
		ld		a,(ix+6)
		add		#54
		ld		(ix+6),a												
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos_1							; PINTA OBJETO ENTRE LOS OBJETOS
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,copia_gallina_en_objetos_2							; PINTA OBJETO ENTRE LOS OBJETOS
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		iy,tapa_objeto_en_tienda_con_gallina					; BORRA ZONA OBJETO COMPRADO
		call	COPY_A_GUSTO
		ld		a,#9c
		ld		(ix+4),a
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
			
		ld		a,5
		ld		(tienda_objeto_5),a
		
		ret																; VUELVE

GALLINA_EN_TIENDA:

		ld		a,(gallina)
		inc		a
		ld		(gallina),a

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,GALLINA_ESP

		call	TEXTO_A_ESCRIBIR

		ld		a,(gallina)
		cp		2
		jp		nc,MAS_DE_UNA_GALLINA
		
		ld		iy,copia_gallina_en_objetos								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		ld		a,(ix+6)
		sub		#54
		ld		(ix+6),a
		
		ld		a,(turno)
		cp		1
		jp		z,COMUN_BLOQUE_5

		ld		a,#e7
		ld		(ix+4),a
				
		jp		COMUN_BLOQUE_5

MAS_DE_UNA_GALLINA:

		ld		iy,copia_gallinas_en_objetos							; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO

		ld		a,(ix+6)
		sub		#54
		ld		(ix+6),a
		
				ld		a,(turno)
		cp		1
		jp		z,COMUN_BLOQUE_5

		ld		a,#e7
		ld		(ix+4),a
		

		
		jp		COMUN_BLOQUE_5
										
PAPEL_EN_TIENDA:

		ld		a,1
		ld		(papel),a

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,PAPIRO_2_ESP
	
		call	TEXTO_A_ESCRIBIR
		
		ld		iy,copia_papel_en_objetos_tienda								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		ld		a,(turno)
		cp		1
		jp		z,COMUN_BLOQUE_5

		ld		a,#B2
		ld		(ix+4),a
		
		jp		COMUN_BLOQUE_5
		
TINTA_EN_TIENDA:

		ld		a,1
		ld		(tinta),a

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,PLUMA_2_ESP

		call	TEXTO_A_ESCRIBIR
		
		ld		iy,copia_tinta_en_objetos_tienda								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		ld		a,(turno)
		cp		1
		jp		z,COMUN_BLOQUE_5

		ld		a,#A5
		ld		(ix+4),a
		
		jp		COMUN_BLOQUE_5
		
LAMPARA_EN_TIENDA:

		ld		a,1
		ld		(lupa),a

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,LUPA_2_ESP

		call	TEXTO_A_ESCRIBIR
		
		ld		iy,copia_lupa_en_objetos_tienda								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		ld		a,(turno)
		cp		1
		jp		z,COMUN_BLOQUE_5

		ld		a,#82
		ld		(ix+4),a
		
		jp		COMUN_BLOQUE_5
		
BRUJULA_EN_TIENDA:

		ld		a,1
		ld		(brujula),a

		ld		ix,GRACIAS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		hl,BRUJULA_2_ESP

		call	TEXTO_A_ESCRIBIR
				
		ld		iy,copia_brujula_en_objetos_tienda								; PINTA OBJETO ENTRE LOS OBJETOS

		CALL	COPY_A_GUSTO
		ld		a,(turno)
		cp		1
		jp		z,COMUN_BLOQUE_5

		ld		a,#C0
		ld		(ix+4),a
		
		jp		COMUN_BLOQUE_5
				
SALE_DE_LA_TIENDA:														; SALIDA

		ld		ix,ADIOS_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER	
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		jp		FIN_DE_LA_SECUENCIA_DE_TIENDA

FIN_DE_LA_SECUENCIA_DE_TIENDA:

		di
		call	stpmus													; paramos la antigua musica
		ei
		
		xor		a
		ld		(que_musica_0),a
		
		di
		LD		A,16		
		ld		(en_que_pagina_el_page_2),a
		ld		[#7000],a	
		
		call	strmus													;iniciamos la música de juego

		EI
							
		ld		iy,cuadrado_que_limpia_5_del_37								; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		LD		A,16
		call	EL_7000_37
		
		ld		a,15
		ld		c,0
		call	ayFX_INIT
			
		LD		A,(pagina_de_idioma)
		call	EL_7000_37
				
		ld		iy,cuadrado_que_limpia_8								; BORRA ZONA DE OBJETOS
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		

		ld		iy,copia_objetos_a_su_sitio								; RECOLOCA OBJETOS
		CALL	COPY_A_GUSTO			
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
					
		xor		a														; DEVUELVE PALETA
		ld		(paleta_a_usar_en_vblank),a			
		
		pop		af														; SALIMOS DE LA TIENDA AL LABERINTO

		ld		a,(turno)
		cp		1
		jp		nz,.DOS_JUGADORES
		
.UN_JUGADOR:

		ld		a,13
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a
		
		ld		a,5
		call	EL_7000_37
		
		jp		VOLVEMOS_DE_LA_TIENDA

.DOS_JUGADORES:

		ld		a,237
		ld		(mosca_x_objetivo),a
		ld		a,157
		ld		(mosca_y_objetivo),a
						
		ld		a,5
		call	EL_7000_37
				
		jp		VOLVEMOS_DE_LA_TIENDA
					
PINTAMOS_EN_TIENDA_OBJETO_ADECUADO:

		cp	0
		jp	z,.BOTAS
		cp	1
		jp	z,.BOTAS_ESP
		cp	2
		jp	z,.ESPADA
		cp	3
		jp	z,.CUCHILLO
		cp	4
		jp	z,.CASCO		
		cp	5
		jp	z,.ARMADURA
		cp	6
		jp	z,.TRAMPA
		
		ld		iy,tapa_objeto_en_tienda
		
		ret
		
.BOTAS:

		ld		iy,copia_botas_en_lista
		
		ret

.BOTAS_ESP:

		ld		iy,copia_botas_esp_en_lista

		ret

.ESPADA:

		ld		iy,copia_espada_en_lista		

		ret

.CUCHILLO:

		ld		iy,copia_cuchillo_en_lista

		ret

.CASCO:

		ld		iy,copia_casco_en_lista

		ret

.ARMADURA:

		ld		iy,copia_armadura_en_lista														

		ret
		
.TRAMPA:

		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z,.SIN_OBJETO
		ld		iy,copia_trampa_en_lista
		
		ret

.SIN_OBJETO:

		ld		iy,tapa_objeto_en_tienda
		
		ret
		
DESCUBRE_CUANTAS_BITNEDAS_TIENE:

		ld		hl,0
		
		ld		a,100
		ld		(var_cuentas_peq),a
		ld		de,(bitneda_centenas)
		
.CENTENAS:
		
		or		a
		adc		hl,de
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.CENTENAS

		push	hl
		ld		hl,0
		
		ld		a,10
		ld		(var_cuentas_peq),a
		ld		de,(bitneda_decenas)		

.DECENAS:

		ld		de,(bitneda_decenas)
		or		a		
		adc		hl,de
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.DECENAS

		push	hl		

		ld		hl,(bitneda_unidades)			

		pop		de
		or		a
		adc		hl,de
		pop		de
		or		a
		adc		hl,de
		
		ld		(dinero_real),hl

		ret

SON_SUFICIENTES_O_NO:
		
		ld		b,a
		ld		hl,(dinero_real)
		ld		a,h
		cp		0
		ret		nz
		
		ld		a,(dinero_real)
		cp		a,b
		jp		c,NO_PUEDES_COMPRAR_ESO
		
		ret
		
NO_PUEDES_COMPRAR_ESO:

		LD		A,16
		call	EL_7000_37

		
		ld		a,12
		ld		c,0
		call	ayFX_INIT
		
		LD		A,(pagina_de_idioma)
		call	EL_7000_37

		ld		ix,NO_PUEDES_COMPRAR_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		
		pop		af
		ret

RESTAMOS_EL_DINERO_ADECUADO:		

		ld		a,(bitneda_unidades)
		dec		a
		ld		(bitneda_unidades),a
		
		call	AJUSTA_BITNEDAS_HACIA_ABAJO
		
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		or		a		
		jp		nz,RESTAMOS_EL_DINERO_ADECUADO	

		ret

VAMOS_A_VER_NUESTROS_OBJETOS:

		ld		iy,copia_tienda_a_salvo									; GUARDA OBJETOS DE LA TIENDA
		CALL	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a												
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,40
		ld		(ralentizando),a
		call	RALENTIZA
		
		ld		iy,copia_objetos_a_su_sitio								; GUARDA OBJETOS DE LA TIENDA
		CALL	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

ESPERA_A_QUE_PULSE_BOTON_2:
		
		ld		a,(turno)
		add		2
		CALL	GTTRIG
		CP		255
		jp		Z,VOLVEMOS_A_LA_RUTINA

		ld		a,4														
		call	SNSMAT
		bit		2,a
		jp		z,VOLVEMOS_A_LA_RUTINA
		
		jp		ESPERA_A_QUE_PULSE_BOTON_2
		
VOLVEMOS_A_LA_RUTINA:
		
		ld		iy,copia_tienda_a_su_sitio								; GUARDA OBJETOS DE LA TIENDA
		CALL	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,40
		ld		(ralentizando),a
		jp		RALENTIZA
		
SUMAMOS_LA_VIDA_ADECUADA:		

		ld		a,(vida_unidades)
		inc		a
		ld		(vida_unidades),a
		
		call	AJUSTA_VIDA
		
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		or		a
		jp		nz,SUMAMOS_LA_VIDA_ADECUADA
		
		ret

DIRECTRICES_RECTIFICACION_VELOCIDAD_37:
		
		ld		ix,datos_del_copy
		ld		bc,12
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

EL_7000_37:

		di
		
		ld		(en_que_pagina_el_page_2),a					
		ld		[#7000],a	
		
		ei
		
		ret

COMIENZA_COLISION:

		ld		a,(pagina_de_idioma)													; cargamos en la pagina 3 el bloque 20 para textos
		call	EL_7000_37

EXPLICA_ENCUENTRO:

		ld		hl,COINCIDE_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COINCIDE_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,HOSTIL_AMISTOSO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,HOSTIL_AMISTOSO_2_ESP
		call	TEXTO_A_ESCRIBIR
		
ELIGE_ENTRE_HOSTIL_Y_AMISTOSO:

		xor		a
		CALL	GTTRIG
		cp		255
		jp		z,EL_QUE_LLEGA_ES_HOSTIL

		ld		a,(turno)
		CALL	GTTRIG
		cp		255
		jp		z,EL_QUE_LLEGA_ES_HOSTIL
		
		ld		a,4												
		call	SNSMAT
		bit		2,a
		jp		z,EL_QUE_LLEGA_ES_AMISTOSO
				
		ld		a,(turno)
		add		2
		call	GTTRIG
		cp		#FF
		jp		z,EL_QUE_LLEGA_ES_AMISTOSO
		
		jp		ELIGE_ENTRE_HOSTIL_Y_AMISTOSO

EL_QUE_LLEGA_ES_AMISTOSO:

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE
		
		ld		hl,RESPUESTA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COINCIDE_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,HOSTIL_AMISTOSO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,HOSTIL_AMISTOSO_2_ESP
		call	TEXTO_A_ESCRIBIR

EL_QUE_ESTA_ELIGE_ENTRE_HOSTIL_Y_AMISTOSO:

		xor		a
		CALL	GTTRIG
		cp		255
		jp		z,EL_QUE_ESTA_ES_HOSTIL

		ld		a,(turno)
		CALL	GTTRIG
		cp		255
		jp		z,EL_QUE_ESTA_ES_HOSTIL
		
		ld		a,4												
		call	SNSMAT
		bit		2,a
		jp		z,EL_QUE_ESTA_ES_AMISTOSO
				
		ld		a,(turno)
		add		2
		call	GTTRIG
		cp		#FF
		jp		z,EL_QUE_ESTA_ES_AMISTOSO
		
		jp		EL_QUE_ESTA_ELIGE_ENTRE_HOSTIL_Y_AMISTOSO

EL_QUE_ESTA_ES_AMISTOSO:

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		ld		a,r
		and		00000011b		
		
		or		a
		jp		z,SE_ATRINCHERAN
		cp		1
		jp		z,SE_INTERCAMBIAN
		cp		2
		jp		z,COMPARAN_MAPAS
		cp		3
		jp		z,DEDUCEN_DONDE_HAY_SALIDAS_Y_LLAVES

SE_ATRINCHERAN:

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		ld		hl,ATRINCHERA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ATRINCHERA_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,ATRINCHERA_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ATRINCHERA_4_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		a,20
		ld		(var_cuentas_peq),a		
		call	SUMAMOS_LA_VIDA_ADECUADA
		call	PINTA_VIDA
		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		ld		a,20
		ld		(var_cuentas_peq),a		
		call	SUMAMOS_LA_VIDA_ADECUADA
		call	PINTA_VIDA

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE						
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL
		
SE_INTERCAMBIAN:

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		ld		hl,INTERCAMBIAN_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,INTERCAMBIAN_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,INTERCAMBIAN_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,INTERCAMBIAN_4_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		a,(bitneda_centenas1)
		ld		b,a
[9]		add		b
		ld		b,a
[9]		add		b
		push	af
		ld		a,(bitneda_decenas1)
		ld		b,a		
[9]		add		b
		ld		b,a
		pop		af
		add		b
		ld		b,a
		ld		a,(bitneda_unidades1)
		add		b
		push	af
		ld		a,(bitneda_centenas2)
		ld		b,a
[9]		add		b
		ld		b,a
[9]		add		b
		ld		b,a
		pop		af
		add		b
		push	af
		ld		a,(bitneda_decenas2)
		ld		b,a		
[9]		add		b
		ld		b,a
		pop		af
		add		b
		ld		b,a
		ld		a,(bitneda_unidades2)
		add		b
		srl		a		

		push	af
		ld		(var_cuentas_peq),a										; INCLUIR REGALO

		xor		a
		ld		(bitneda_centenas),a
		ld		(bitneda_decenas),a
		ld		(bitneda_unidades),a
		
.LOOP_MONEDAS1:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS1	
			
		call	PINTA_BITNEDAS			

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		pop		af
		ld		(var_cuentas_peq),a										; INCLUIR REGALO

		xor		a
		ld		(bitneda_centenas),a
		ld		(bitneda_decenas),a
		ld		(bitneda_unidades),a
		
.LOOP_MONEDAS2:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS2	
			
		call	PINTA_BITNEDAS
				
		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE
		
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL
				
COMPARAN_MAPAS:

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		ld		hl,COMPARA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COMPARA_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,COMPARA_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COMPARA_4_ESP
		call	TEXTO_A_ESCRIBIR

		ld		ix,act_mapa_1
		ld		iy,act_mapa_2
		ld		hl,900
		ld		(var_cuentas_gra),hl

.bucle_1:

		ld		a,(ix)
		cp		#ff
		jp		z,.suma_bucle_1
		ld		(iy),a
		jp		.suma_bucle_1

.suma_bucle_1:
		
		inc		ix
		inc		iy
		ld		hl,(var_cuentas_gra)
		dec		hl
		ld		(var_cuentas_gra),hl
		ld		a,l
		or		a
		jp		nz,.bucle_1
		ld		a,h
		or		a
		jp		nz,.bucle_1

		ld		ix,act_mapa_1
		ld		iy,act_mapa_2
		ld		hl,900
		ld		(var_cuentas_gra),hl
		
.bucle_2:

		ld		a,(iy)
		cp		#ff
		jp		z,.suma_bucle_2
		ld		(ix),a
		jp		.suma_bucle_2

.suma_bucle_2:
		
		inc		ix
		inc		iy
		ld		hl,(var_cuentas_gra)
		dec		hl
		ld		(var_cuentas_gra),hl
		ld		a,l
		or		a
		jp		nz,.bucle_2
		ld		a,h
		or		a
		jp		nz,.bucle_2
				
		call	STRIG_DE_CONTINUE

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL
		
DEDUCEN_DONDE_HAY_SALIDAS_Y_LLAVES:

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		ld		hl,DEDUCE_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,DEDUCE_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,DEDUCE_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,DEDUCE_4_ESP
		call	TEXTO_A_ESCRIBIR

		ld		ix,eventos_laberinto
		ld		iy,act_mapa_1
		ld		hl,900
		ld		(var_cuentas_gra),hl

.bucle_1:

		ld		a,(ix)
		cp		14														; POCHADA
		jp		z,.pochada_1
		cp		30														; POCHADA
		jp		z,.pochada_1
		cp		31														; POCHADA
		jp		z,.pochada_1
		cp		32														; POCHADA
		jp		z,.pochada_1		
		cp		15														; LLAVE
		jp		z,.llave_1
		cp		17														; SALIDA
		jp		z,.salida_1
		jp		.suma_bucle_1

.pochada_1:

		ld		(iy),60
		jp		.suma_bucle_1
		
.llave_1:

		ld		(iy),105
		jp		.suma_bucle_1
		
.salida_1:

		ld		(iy),15
		jp		.suma_bucle_1
		

.suma_bucle_1:
		
		inc		ix
		inc		iy
		ld		hl,(var_cuentas_gra)
		dec		hl
		ld		(var_cuentas_gra),hl
		ld		a,l
		or		a
		jp		nz,.bucle_1
		ld		a,h
		or		a
		jp		nz,.bucle_1

		ld		ix,eventos_laberinto
		ld		iy,act_mapa_2
		ld		hl,900
		ld		(var_cuentas_gra),hl

.bucle_2:

		ld		a,(ix)
		cp		14														; POCHADA
		jp		z,.pochada_2
		cp		30														; POCHADA
		jp		z,.pochada_2
		cp		31														; POCHADA
		jp		z,.pochada_2
		cp		32														; POCHADA
		jp		z,.pochada_2	
		cp		15														; LLAVE
		jp		z,.llave_2
		cp		17														; SALIDA
		jp		z,.salida_2
		jp		.suma_bucle_2

.pochada_2:

		ld		(iy),60
		jp		.suma_bucle_2
		
.llave_2:

		ld		(iy),105
		jp		.suma_bucle_2
		
.salida_2:

		ld		(iy),15
		jp		.suma_bucle_2
		

.suma_bucle_2:
		
		inc		ix
		inc		iy
		ld		hl,(var_cuentas_gra)
		dec		hl
		ld		(var_cuentas_gra),hl
		ld		a,l
		or		a
		jp		nz,.bucle_2
		ld		a,h
		or		a
		jp		nz,.bucle_2
				
		call	STRIG_DE_CONTINUE

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL
		
BORRA_MAPA:

		ld		hl,BORRA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,BORRA_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,BORRA_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,BORRA_4_ESP
		call	TEXTO_A_ESCRIBIR
		
		call	STRIG_DE_CONTINUE

		ld		a,(turno)
		cp		1
		jp		z,.borra_a_2

.borra_a_1:

		xor		#ff
		ld		(act_mapa_1),a
		ld		bc,899													
		ld		de,act_mapa_1_1
		ld		hl,act_mapa_1
					
		ldir
		
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL
		
.borra_a_2:

		xor		#ff
		ld		(act_mapa_2),a
		ld		bc,899													
		ld		de,act_mapa_2_1
		ld		hl,act_mapa_2
					
		ldir
		
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL	
							
QUITA_UN_TURNO:


		ld		hl,QUITA_TURNO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,QUITA_TURNO_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,QUITA_TURNO_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,QUITA_TURNO_4_ESP
		call	TEXTO_A_ESCRIBIR
		
		call	STRIG_DE_CONTINUE

		ld		a,1
		ld		(turno_sin_tirar),a
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL
		
PELEA:
		
QUITA_DINERO:


		ld		hl,QUITA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,QUITA_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,QUITA_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,QUITA_4_ESP
		call	TEXTO_A_ESCRIBIR
		
		call	STRIG_DE_CONTINUE

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE

		ld		a,(bitneda_centenas)
		ld		b,a
[9]		add		b
		ld		b,a
[9]		add		b
		push	af
		ld		a,(bitneda_decenas)
		ld		b,a		
[9]		add		b
		ld		b,a
		pop		af
		add		b
		ld		b,a
		ld		a,(bitneda_unidades)
		add		b
		push	af
		xor		a
		ld		(bitneda_centenas),a
		ld		(bitneda_decenas),a
		ld		(bitneda_unidades),a

		CALL	PINTA_BITNEDAS

		call	CAMBIA_EL_TURNO_MOMENTANEAMENTE
		
		pop		af
		ld		(var_cuentas_peq),a										; INCLUIR REGALO
		
.LOOP_MONEDAS:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS	
			
		call	PINTA_BITNEDAS
						
		jp		VOLVEMOS_A_LA_RUTINA_GENERAL
				
EL_QUE_ESTA_ES_HOSTIL:													; misma rutina pero inicia el otro jugador
		
EL_QUE_LLEGA_ES_HOSTIL:

		ld		a,r
		and		00000011b		
		
		or		a
		jp		z,BORRA_MAPA
		cp		1
		jp		z,QUITA_UN_TURNO
		cp		2
		jp		z,PELEA
		cp		3
		jp		z,QUITA_DINERO
						
VOLVEMOS_A_LA_RUTINA_GENERAL:

		ld		a,5
		call	EL_7000_37
		jp		VOLVEMOS_DE_LA_TIENDA

CAMBIA_EL_TURNO_MOMENTANEAMENTE:

		ld		a,(turno)
		cp		1
		jp		z,.A_DOS
		
.A_UNO:

		ld		a,1
		ld		(turno),a
		ld		a,13
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a

		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa_2
		ld		hl,posicion_en_mapa
					
		ldir
		
		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa
		ld		hl,posicion_en_mapa_1
					
		ldir				
		ret
		
.A_DOS:

		ld		a,2
		ld		(turno),a
		ld		a,237
		ld		(mosca_x_objetivo),a
		ld		a,154
		ld		(mosca_y_objetivo),a		

		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa_1
		ld		hl,posicion_en_mapa
					
		ldir
		
		ld		bc,33													;cargamos las variables de los objetos
		ld		de,posicion_en_mapa
		ld		hl,posicion_en_mapa_2
					
		ldir
		ret

COMIENZA_ENEMIGO_FINAL:
		
		ld		a,(pagina_de_idioma)
		call	EL_7000_37

PASAMOS_TODO_A_PAGE_1_PARA_TRABAJAR_EN_PAGE_0:
		
		ld		a,(set_page01)
		cp		1
		jp		z,APAGAMOS_PANTALLA_PARA_PASO_A_ENEMIGO

		ld		iy,copia_escenario_a_page_1_37							; Si estamos en page 0. Vamos a clonar la 0 en la 1
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001_37

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO
		
		ld		a,1
		ld		(set_page01),a
		call	setpage

APAGAMOS_PANTALLA_PARA_PASO_A_ENEMIGO:
		
		call	DISSCR

		di
		LD 		a,(RG0SAV)												; Enable Line Interrupt: Set R#0 bit 4
		and		11101111B
		LD 		(RG0SAV),a			
		OUT 	(#99),a		
		LD 		a,0+128		
		OUT 	(#99),a
		
TRANSFORMAMOS_LA_PANTALLA:
		
		ld		iy,borde_izquierdo_para_izquierda						; ampliamos el espacio de la pantalla
		call	COPY_A_GUSTO_37
		call	EL_12_A_0_EL_14_A_1001_37
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		iy,copia_cadeneta										; copiamos la cadeneta superior
		call	COPY_A_GUSTO_37
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
					
		ld		de,ESTANCIA_PELEA										; copiamos zona de pelea
		ld		hl,copia_zona_pelea_en_pantalla							; preparamos las directrices de copia
		ld		a,56
		call	EL_7000_37
		call	ESPERA_AL_VDP_HMMC_37	

COPIAMOS_LOS_SPRITES_DE_PROTA_ADECUADOS:

		ld		a,55
        call	EL_7000_37
        
		ld		a,(personaje)
		cp		1
		jp		z,.Natpu
		cp		2
		jp		z,.Fergar
		cp		3
		jp		z,.Crira
		cp		4
		jp		z,.Vicmar

.Natpu:

		ld		hl,NATPU_SPRITES
		jp		CARGA_SPRITES_PROTA

.Fergar:

		ld		hl,FERGAR_SPRITES
		jp		CARGA_SPRITES_PROTA

.Crira:

		ld		hl,CRIRA_SPRITES
		jp		CARGA_SPRITES_PROTA

.Vicmar:

		ld		hl,VICMAR_SPRITES
							
CARGA_SPRITES_PROTA:
		
		ld		de,#7040
		ld		bc,640
		
		halt
		di
		call	fast_LDIRVM
		ei
		
		ld		a,(personaje)
		cp		1
		jp		z,.Natpu
		cp		2
		jp		z,.Fergar
		cp		3
		jp		z,.Crira
		cp		4
		jp		z,.Vicmar

.Natpu:

		ld		hl,NATPU_COLORES
		jp		CARGA_COLORES_PROTA

.Fergar:

		ld		hl,FERGAR_COLORES
		jp		CARGA_COLORES_PROTA

.Crira:

		ld		hl,CRIRA_COLORES
		jp		CARGA_COLORES_PROTA

.Vicmar:

		ld		hl,VICMAR_COLORES
		jp		CARGA_COLORES_PROTA	
		
RUTINA_FIJA_DE_SPRITES:

		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	fast_LDIRVM
		ei	
		RET
							
CARGA_COLORES_PROTA:
				
		ld		de,#7820
		ld		bc,320
		
		halt
		di
		call	fast_LDIRVM
		ei
				
		ld		ix,atributos_sprites_prota								; plano 1 fuera de vista
		ld		de,#7a04
		call	RUTINA_FIJA_DE_SPRITES
		
		ld		ix,atributos_sprites_prota								; plano 10 fuera de vista
		ld		de,#7a28
		call	RUTINA_FIJA_DE_SPRITES

		ld		ix,atributos_sprites_prota								; plano 11 fuera de vista
		ld		de,#7a2C
		call	RUTINA_FIJA_DE_SPRITES

		ld		ix,atributos_sprites_prota								; plano 12 fuera de vista
		ld		de,#7a30
		call	RUTINA_FIJA_DE_SPRITES

		ld		ix,atributos_sprites_prota								; plano 13 fuera de vista
		ld		de,#7a34
		call	RUTINA_FIJA_DE_SPRITES
										
		ld		ix,atributos_sprites_prota								; plano 22 fuera de vista
		ld		de,#7a58
		ld		a,#D8
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	fast_LDIRVM
		ei
				
		ld		de,#7a68												; plano 26 a posición de invisible todos los de debajo
		ld		a,#d8
		ld		(ix),a		
		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	fast_LDIRVM
		ei
					
CARGA_SPRITES_ARMA:

		ld		a,(cuchillo)
		cp		1
		jp		z,CARGA_CUCHILLO
		ld		a,(espada)
		cp		1
		JP		z,CARGA_ESPADA
		
CARGA_PIEDRA:

		ld		hl,PIEDRA_COLORES
		push	hl
		ld		hl,PIEDRA_SPRITES
		jp		COPIAMOS_SPRITES_ARMA
		
CARGA_CUCHILLO:

		ld		hl,CUCHILLO_COLORES
		push	hl
		ld		hl,CUCHILLO_SPRITES
		jp		COPIAMOS_SPRITES_ARMA
		
CARGA_ESPADA:

		ld		hl,ESPADA_COLORES
		push	hl
		ld		hl,ESPADA_SPRITES
		
COPIAMOS_SPRITES_ARMA:

		ld		de,#72c0												; copiamos patrones arma
		ld		bc,64
		di
		call	fast_LDIRVM
		ei
		
		pop		hl														;recuperamos la dirección de los colores
		
		ld		de,#78a0
		ld		bc,32
		di
		call	fast_LDIRVM
		ei	

COPIAMOS_SPRITES_COLISION:

		ld		hl,COLISION_SPRITES
		ld		de,#7300												; copiamos patrones arma
		ld		bc,64
		di
		call	fast_LDIRVM
		ei
		
		ld		hl,COLISION_COLORES
		ld		de,#78C0
		ld		bc,32
		di
		call	fast_LDIRVM
		ei
				        	
COPIAMOS_LOS_SPRITES_DE_ENEMIGO_ADECUADOS:
		
		ld		a,(nivel)
		cp		1
		jp		z,CARGA_TROMAX
		cp		2
		jp		z,CARGA_ONIRICUS
		cp		3
		jp		z,CARGA_SALGUERI
		cp		4
		jp		z,CARGA_LUCKYLUKEB

CARGA_TROMAX:

		ld		hl,TROMAXE_SPRITES
		jp		COPIANDO_SPRITES

CARGA_ONIRICUS:

		ld		hl,ONIRIKUS_SPRITES
		jp		COPIANDO_SPRITES
		
CARGA_SALGUERI:

		ld		hl,SALGUERI_SPRITES
		jp		COPIANDO_SPRITES
		
CARGA_LUCKYLUKEB:

		ld		hl,LUCKYLUKEB_SPRITES
				
COPIANDO_SPRITES:
		      
		ld		de,#7340												; copiamos patrones del cotorra
		ld		bc,512
		halt
		di
		call	fast_LDIRVM
		ei
		
COPIANDO_MUNICION_ENEMIGA:

		halt
		
		ld		a,(nivel)
		cp		4
		jp		z,MUNI_LUCKYLUKEB
		cp		3
		jp		z,MUNI_SALGUERI		
		cp		2
		jp		z,MUNI_ONIRIKUS
		
MUNI_TROMAXE:

		LD		hl,TRAPO_COLORES_1
		push	hl
		ld		hl,TRAPO_1      
		jp		SALVAMOS_EL_ARMA

MUNI_ONIRIKUS:

		LD		hl,NINO_COLORES_1
		push	hl
		ld		hl,NINO_1      
		jp		SALVAMOS_EL_ARMA

MUNI_SALGUERI:

		LD		hl,CARTUCHO_COLORES_1
		push	hl
		ld		hl,CARTUCHO_1      
		jp		SALVAMOS_EL_ARMA

MUNI_LUCKYLUKEB:

		LD		hl,MASCARA_COLORES_1
		push	hl
		ld		hl,MASCARA_1      
						
SALVAMOS_EL_ARMA:

		ld		de,#7540												; copiamos patrones del trapo
		ld		bc,128
		halt
		di
		call	fast_LDIRVM
		ei

		pop		hl		
		ld		de,#7960				
		ld		bc,64
		di
		call	fast_LDIRVM
		ei
						
LIMPIANDO_SPRITES_INNECESARIOS:
		
		ld		ix,atributos_sprites_prota								; plano 1 fuera de vista
		ld		de,#7a04
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	fast_LDIRVM
		ei
		
		ld		de,#7a30
		ld		a,#e0
		ld		(ix),a
		ld		(ix+4),a		
		ld		hl,atributos_sprites_prota
		ld		bc,8
		di
		call	fast_LDIRVM
		ei
				
		ld		de,#7a50												; plano 22 a posición de invisible todos los de debajo
		ld		a,#d8
		ld		(ix),a		
		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	fast_LDIRVM	
		ei
		
COPIAMOS_EL_ENEMIGO_ADECUADO_EN_CARAS:
		
		ld		a,57
        call	EL_7000_37
		
		ld		a,(nivel)
		cp		4
		jp		z,.luckylukeb_caras
		cp		3
		jp		z,.salgueri_caras
		cp		2
		jp		z,.onirikus_caras

.tromaxe_caras:
		
		ld		de,TROMAXE_CARAS	
		jp		.seguimos

.onirikus_caras:
		
		ld		de,ONIRIKUS_CARAS	
		jp		.seguimos

.salgueri_caras:
		
		ld		de,SALGUERI_CARAS	
		jp		.seguimos

.luckylukeb_caras:
		
		ld		de,LUCKY_CARAS
								
.seguimos:

		ld		hl,copia_enemigo_1_en_vram								;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_37									;copiamos	

		ld		de,VIDA_CORAZON	
		ld		hl,copia_vida											;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_37									;copiamos

		ld		de,VIDA_CULO	
		ld		hl,copia_culo											;preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC_37									;copiamos
				
		ld		a,(pagina_de_idioma)
        call	EL_7000_37
        												
		ld		a,5														; cambiamos la paleta a la adecuada
		ld		(paleta_a_usar_en_vblank),a

COPIAMOS_CARAS_EN_SU_SITIO:

		ld		iy,copia_cara_neutra_jugador1
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37
		
		ld		iy,copia_cara_neutra_cotorra
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37

		ld		a,8
		ld		(que_musica_0),a
				
		LD		A,81		
		call	EL_7000_37
				
		di
		call	strmus													;iniciamos la música de tienda
		ei
						
MOSTRAMOS_DECORADO_DE_PELEA:
		
		xor		a														; volvemos a page 0
		ld		(set_page01),a
		call	setpage		

		
		ld		ix,atributos_sprites_prota
		ld		a,119-32
		ld		(ix),a
		ld		a,91
		ld		(ix+1),a
		ld		a,8
		ld		(fotograma_que_toca),a			

		ld		iy,atributos_sprites_cotorra
		ld		a,48
		ld		(iy),a
		ld		a,130
		ld		(iy+1),a
		ld		a,26*4
		ld		(iy+2),a

		LD 		a,(RG0SAV)												; Enable Line Interrupt: Set R#0 bit 4
		OR		00010000B
		LD 		(RG0SAV),a			
		OUT 	(#99),a		
		LD 		a,0+128		
		OUT 	(#99),a
		
		call	ENASCR

VARIABLES_DE_INICIO:

		ld		a,60
		ld		(intervalo_de_disparos),a
		xor		a
		ld		(intervalo_feaciente),a
		ld		(vida_cotorra),a
		ld		(cambio_de_cotorra),a
		ld		(prota_saltando),a
		ld		(salto_prota_continuo),a
		ld		(propiedades_disparo),a
		ld		(propiedades_disparo_2),a
		
		call	PINTA_A_PROTA
		call	PINTA_COTORRA		
		jp		TEXTOS_ANTES_DE_PELEA
		
CARAS_COMIENZO_PELEA:

		push	iy
		push	ix
		ld		iy,copia_cara_ataque_jugador1
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37
		
		ld		iy,copia_cara_ataque_cotorra
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37
		pop		ix
		pop		iy
		ret
		
CARAS_BUENO_DA_A_MALO:

		push	iy
		push	ix
		ld		iy,copia_cara_activa_jugador1
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37
		
		ld		iy,copia_cara_pierde_cotorra
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37
		pop		ix
		pop		iy
		ret
		
CARAS_MALO_DA_A_BUENO:

		push	iy
		push	ix
		ld		iy,copia_cara_pierde_jugador1
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37
		
		ld		iy,copia_cara_activa_cotorra
		call	COPY_A_GUSTO_37
		ld		hl,datos_del_copy		
		call	DoCopy_37
		pop		ix
		pop		iy
		ret

SONIDO_PASO_TEXTO:
		
		LD		A,16
		call	EL_7000_37

		ld		a,22
		ld		c,0
		call	ayFX_INIT

		LD		A,(pagina_de_idioma)
		jp		EL_7000_37
						
TEXTOS_ANTES_DE_PELEA:

		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a28
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a2c
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a30
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a34
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei		
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a58
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei				
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a5c
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei	
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a60
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei		
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a64
		ld		a,#e0
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei							
		ld		a,(pagina_de_idioma)													; cargamos página de textos
		call	EL_7000_37
		
		push	ix
		push	iy

		ld		a,(nivel)
		cp		4
		jp		z,presenta_luckylukeb
		cp		3
		jp		z,presenta_salgueri
		cp		2
		jp		z,presenta_onirikus

presenta_tromaxe:

		ld		a,237
		ld		(mosca_x_objetivo),a		
		ld		hl,TROMAXE_01
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO
		
		ld		a,13
		ld		(mosca_x_objetivo),a
		ld		a,(personaje)
		cp		4
		jp		z,.vicmar
		cp		3
		jp		z,.crira
		cp		2
		jp		z,.fergar

.natpu:
				
		ld		hl,TROMAXE_022
		call	TEXTO_A_ESCRIBIR
		jp		.sigue

.fergar:
				
		ld		hl,TROMAXE_021
		call	TEXTO_A_ESCRIBIR
		jp		.sigue

.crira:
				
		ld		hl,TROMAXE_023
		call	TEXTO_A_ESCRIBIR
		jp		.sigue

.vicmar:
				
		ld		hl,TROMAXE_024
		call	TEXTO_A_ESCRIBIR
								
.sigue:		
		ld		HL,TROMAXE_03
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_04
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_05
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,237
		ld		(mosca_x_objetivo),a		
		ld		hl,TROMAXE_06
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_07
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_08
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_09
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,13
		ld		(mosca_x_objetivo),a
		ld		hl,TROMAXE_10
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		jp		PREPARADOS_PARA_PELEA

presenta_onirikus:


		ld		a,237
		ld		(mosca_x_objetivo),a
				
		ld		hl,ONIRIKUS_01
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR				
		call	SONIDO_PASO_TEXTO				
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO				
		
		ld		a,13
		ld		(mosca_x_objetivo),a
				
		ld		hl,ONIRIKUS_02
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR							
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO	
		
		ld		a,237
		ld		(mosca_x_objetivo),a
		ld		hl,ONIRIKUS_03
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR							
		call	STRIG_DE_CONTINUE

		ld		hl,ONIRIKUS_04
		call	TEXTO_A_ESCRIBIR
		ld		HL,ONIRIKUS_05
		call	TEXTO_A_ESCRIBIR							
		call	STRIG_DE_CONTINUE

		ld		a,13
		ld		(mosca_x_objetivo),a
											
		jp		PREPARADOS_PARA_PELEA
		
presenta_salgueri:

		ld		a,237
		ld		(mosca_x_objetivo),a		
		ld		hl,SALGUERI_01
		call	TEXTO_A_ESCRIBIR

		ld		a,(personaje)
		cp		4
		jp		z,.vicmar
		cp		3
		jp		z,.crira
		cp		2
		jp		z,.fergar

.natpu:
				
		ld		hl,SALGUERI_022
		jp		.sigue

.fergar:
				
		ld		hl,SALGUERI_021
		jp		.sigue

.crira:
				
		ld		hl,SALGUERI_023
		jp		.sigue

.vicmar:
				
		ld		hl,SALGUERI_024
								
.sigue:

		call	TEXTO_A_ESCRIBIR		
		call	SONIDO_PASO_TEXTO
		call	STRIG_DE_CONTINUE
		
		ld		hl,SALGUERI_03
		call	TEXTO_A_ESCRIBIR
		ld		hl,SALGUERI_04
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,13
		ld		(mosca_x_objetivo),a		

		ld		a,(espada)
		cp		1
		jp		z,.espada
		ld		a,(cuchillo)
		cp		1
		jp		z,.cuchillo


.nada:
				
		ld		hl,SALGUERI_051
		jp		.sigue_a

.cuchillo:
				
		ld		hl,SALGUERI_052
		jp		.sigue_a

.espada:
				
		ld		hl,SALGUERI_053

								
.sigue_a:

		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR				
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,237
		ld		(mosca_x_objetivo),a		
		ld		hl,SALGUERI_06
		call	TEXTO_A_ESCRIBIR
		ld		hl,SALGUERI_07
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,13
		ld		(mosca_x_objetivo),a		


		jp		PREPARADOS_PARA_PELEA

presenta_luckylukeb:

		ld		a,237
		ld		(mosca_x_objetivo),a
				
		ld		hl,LUCKYLUKEB_01
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR				
		call	SONIDO_PASO_TEXTO				
		call	STRIG_DE_CONTINUE

		ld		hl,LUCKYLUKEB_02
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_03
		call	TEXTO_A_ESCRIBIR								
		call	STRIG_DE_CONTINUE

		ld		hl,LUCKYLUKEB_04
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_05
		call	TEXTO_A_ESCRIBIR								
		call	STRIG_DE_CONTINUE
		
		call	SONIDO_PASO_TEXTO				
		
		ld		a,13
		ld		(mosca_x_objetivo),a

		ld		hl,LUCKYLUKEB_061
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_062
		call	TEXTO_A_ESCRIBIR								
		call	STRIG_DE_CONTINUE

		call	SONIDO_PASO_TEXTO				

		ld		a,237
		ld		(mosca_x_objetivo),a

		ld		hl,LUCKYLUKEB_07
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR								
		call	STRIG_DE_CONTINUE

		ld		hl,LUCKYLUKEB_08
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_09
		call	TEXTO_A_ESCRIBIR								
		call	STRIG_DE_CONTINUE
	
		ld		hl,LUCKYLUKEB_10
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_11
		call	TEXTO_A_ESCRIBIR								
		call	STRIG_DE_CONTINUE
	
						
PREPARADOS_PARA_PELEA:

		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
				
		call	CARAS_COMIENZO_PELEA
		
		call	stpmus
		
		ld		a,7
		ld		(que_musica_0),a
				
		LD		A,80		
		call	EL_7000_37
				
		di
		call	strmus													;iniciamos la música de tienda
		ei
		
		pop		iy
		pop		ix	

		ld		a,1
		ld		(prota_saltando),a

		call	SALTA_PROTA.esta_saltando
		
SECUENCIA_DE_PELEA:
		
		call	MUEVE_PROTA
		call	SALTA_PROTA
		call	DISPARA_PROTA
		call	BORRA_COLISION
		call	COORDENADAS_DISPARO_PROTA
		call	COMPROBAMOS_SPRITES_COTORRA		
		call	A_I_COTORRA
		call	DISPARA_COTORRA	
		call	COORDENADAS_DISPARO_COTORRA

		call	PINTA_A_PROTA
		call	PINTA_COTORRA
		call	PINTA_TRAPOS

		ld		a,(vida_cotorra)
		cp		40
		jp		c,SECUENCIA_DE_PELEA

		call	stpmus
		
		ld		a,5
		ld		(que_musica_0),a
				
		LD		A,4		
		call	EL_7000_37
				
		di
		call	strmus													;iniciamos la música de tienda
		ei
		
		LD		A,(pagina_de_idioma)		
		call	EL_7000_37

LO_LOGRAMOS:

		ld		a,(nivel)
		cp		4
		jp		z,despide_luckylukeb
		cp		3
		jp		z,despide_salgueri
		cp		2
		jp		z,despide_onirikus

despide_tromaxe:

		ld		a,237
		ld		(mosca_x_objetivo),a
						
		ld		hl,TROMAXE_11
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_12
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_13
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_14
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,13
		ld		(mosca_x_objetivo),a
		
		ld		hl,TROMAXE_15
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_16
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,237
		ld		(mosca_x_objetivo),a
		
		ld		hl,TROMAXE_17
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_18
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_19
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_20
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_21
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

despide_comun:

		ld		hl,TROMAXE_22
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_23
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_24
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_25
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,TROMAXE_26
		call	TEXTO_A_ESCRIBIR
		ld		HL,TROMAXE_27
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		
		jp		SALIENDO_DE_LA_PELEA
		
despide_onirikus:

		ld		a,237
		ld		(mosca_x_objetivo),a

		ld		hl,ONIRIKUS_06
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		a,13
		ld		(mosca_x_objetivo),a

		ld		hl,ONIRIKUS_07
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		a,237
		ld		(mosca_x_objetivo),a

		ld		hl,ONIRIKUS_08
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		
		ld		a,13
		ld		(mosca_x_objetivo),a				
		ld		HL,ONIRIKUS_09
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR					
		call	STRIG_DE_CONTINUE

		ld		a,237
		ld		(mosca_x_objetivo),a
								
		ld		hl,ONIRIKUS_10
		call	TEXTO_A_ESCRIBIR
		ld		HL,ONIRIKUS_11
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
												
		jp		despide_comun
	
despide_salgueri:

		ld		a,237
		ld		(mosca_x_objetivo),a

		ld		hl,SALGUERI_08
		call	TEXTO_A_ESCRIBIR
		ld		HL,SALGUERI_09
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
								
		ld		hl,SALGUERI_10
		call	TEXTO_A_ESCRIBIR
		ld		HL,SALGUERI_11
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,SALGUERI_12
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,13
		ld		(mosca_x_objetivo),a
		
		ld		hl,SALGUERI_13
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		hl,SALGUERI_14
		call	TEXTO_A_ESCRIBIR
		ld		HL,SALGUERI_15
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO
		
		ld		a,237
		ld		(mosca_x_objetivo),a
		
		ld		hl,SALGUERI_16
		call	TEXTO_A_ESCRIBIR
		ld		HL,SALGUERI_17
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,SALGUERI_18
		call	TEXTO_A_ESCRIBIR
		ld		HL,SALGUERI_19
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		
		ld		hl,SALGUERI_20
		call	TEXTO_A_ESCRIBIR
		ld		HL,SALGUERI_21
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		
		jp		despide_comun
	
despide_luckylukeb:

		ld		a,237
		ld		(mosca_x_objetivo),a
						
		ld		hl,LUCKYLUKEB_12
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_13
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,13
		ld		(mosca_x_objetivo),a
				
		ld		hl,LUCKYLUKEB_14
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_15
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		
		ld		hl,LUCKYLUKEB_16
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_17
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
				
		call	SONIDO_PASO_TEXTO

		ld		a,237
		ld		(mosca_x_objetivo),a
		
		
		ld		hl,LUCKYLUKEB_18
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_19
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		
		ld		hl,LUCKYLUKEB_20
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_21
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		
		ld		hl,LUCKYLUKEB_22
		call	TEXTO_A_ESCRIBIR
		ld		HL,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
		call	SONIDO_PASO_TEXTO

		ld		a,13
		ld		(mosca_x_objetivo),a
						
		ld		hl,LUCKYLUKEB_23
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_24
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

				
		call	SONIDO_PASO_TEXTO

		ld		a,237
		ld		(mosca_x_objetivo),a
		
		
		ld		hl,LUCKYLUKEB_25
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_26
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE

		ld		hl,LUCKYLUKEB_27
		call	TEXTO_A_ESCRIBIR
		ld		HL,LUCKYLUKEB_28
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
														
SALIENDO_DE_LA_PELEA:
		
		call	stpmus
		
		ld		ix,atributos_sprites_prota								; borramos sprites
		ld		de,#7a08
		ld		a,#d8
		ld		(ix),a		
		ld		hl,atributos_sprites_prota
		ld		bc,1
		di
		call	LDIRVM
		ei
		
		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR_37
		
		ld		iy,copia_page0_a_page1_tras_pelea						; copiamos page1 a page0
		call	COPY_A_GUSTO_37
		call	EL_12_A_0_EL_14_A_1001_37
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY_37
		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR_37

		ld		iy,borra_cara_enemigo									; borramos cara enemigo y su vida
		call	COPY_A_GUSTO_37
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY_37
		
		xor		a
		ld		(paleta_a_usar_en_vblank),a		
		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR_37
										
		ld		a,5
		call	EL_7000_37
		jp		RECUPERAMOS_PAGE0_EN_1
		
COORDENADAS_DISPARO_COTORRA:

		ld		a,(ix+1)
		ld		(x_salvada),a
		
		push	ix														; guardamos ix porque lo vamos a usar

disparo_uno:

		ld		ix,propiedades_disparo									; no hace nada si el disparo no está activo
		ld		a,(ix)
		cp		0
		jp		z,disparo_dos

		LD		A,16
		call	EL_7000_37
		ld		a,21
		ld		c,2
		call	ayFX_INIT
				
		call	control_de_fotograma
		call	control_de_secuencia

disparo_dos:
		
		ld		ix,propiedades_disparo_2
		ld		a,(ix)
		cp		0
		jp		z,saliendo_de_aqui
		LD		A,16
		call	EL_7000_37
		ld		a,21
		ld		c,2
		call	ayFX_INIT
				
		call	control_de_fotograma
		call	control_de_secuencia

saliendo_de_aqui:
		
		pop		ix
		
		ret

control_de_secuencia:

		ld		a,(ix+4)
		cp		2
		jp		z,secuencia2
		cp		1
		jp		z,secuencia1

secuencia0:

		ld		a,(ix+5)
		cp		2
		jp		z,secuencia02
		cp		1
		jp		z,secuencia01

secuencia00:

		ld		a,(ix+1)
		add		2
		ld		(ix+1),a
		cp		185
		ret		c
		ld		a,(ix+5)
		inc		a
		ld		(ix+5),a
		
		ret
		
secuencia01:

		ld		a,(ix+1)
		add		1
		ld		(ix+1),a
		ld		a,(ix+2)
		add		2
		ld		(ix+2),a
		cp		104
		ret		c
		ld		a,(ix+5)
		inc		a
		ld		(ix+5),a
		
		ret

secuencia02:

		ld		a,(ix+1)
		sub		2
		ld		(ix+1),a
		
		ld		b,a
		ld		a,(x_salvada)
		add		10
		cp		b
		jp		c,secuencia021
		sub		25
		cp		b
		jp		nc,secuencia021
		ld		a,(prota_saltando)
		cp		1
		jp		z,secuencia021

		ld		a,20
		ld		(tiembla_el_decorado_v),a
		LD		A,16
		call	EL_7000_37
		ld		a,20
		ld		c,1
		call	ayFX_INIT
				
		ld		(pintamos_sin_colision),a
		
		call	CARAS_MALO_DA_A_BUENO
		
		call	DESCONTAMOS_VIDA_CON_COTORRA

		ld		a,1				
		ld		(pintamos_sin_colision),a
				
		jp		secuencia022
		
secuencia021:
		
		ld		a,(ix+1)
		cp		60
		ret		nc

secuencia022:
		
		ld		a,224
		ld		(ix+2),a
		xor		a
		ld		(ix),a
		ld		(ix+4),a
		ld		(ix+5),a
		
		ret

secuencia1:

		ld		a,(ix+5)
		cp		2
		jp		z,secuencia12
		cp		1
		jp		z,secuencia11

secuencia10:

		ld		a,(ix+1)
		sub		2
		ld		(ix+1),a
		cp		100
		ret		nc
		ld		a,(ix+5)
		inc		a
		ld		(ix+5),a
		
		ret
		
secuencia11:

		ld		a,(ix+1)
		sub		2
		ld		(ix+1),a
		ld		a,(ix+2)
		add		2
		ld		(ix+2),a
		cp		104
		ret		c
		ld		a,(ix+5)
		inc		a
		ld		(ix+5),a
		
		ret

secuencia12:

		ld		a,(ix+1)
		add		2
		ld		(ix+1),a

		ld		b,a
		ld		a,(x_salvada)
		add		10
		cp		b
		jp		c,secuencia121
		sub		25
		cp		b
		jp		nc,secuencia121
		ld		a,(prota_saltando)
		cp		0
		jp		nz,secuencia121

		ld		a,20
		ld		(tiembla_el_decorado_v),a
		
		LD		A,16
		call	EL_7000_37
		ld		a,20
		ld		c,1
		call	ayFX_INIT
		
		call	DESCONTAMOS_VIDA_CON_COTORRA
		ld		a,1				
		ld		(pintamos_sin_colision),a
		
		call	CARAS_MALO_DA_A_BUENO
		
		jp		secuencia122

secuencia121:
		
		ld		a,(ix+1)		
		cp		230
		ret		c

secuencia122:

		ld		a,224
		ld		(ix+2),a
		xor		a
		ld		(ix),a
		ld		(ix+4),a
		ld		(ix+5),a
		
		ret

secuencia2:

		ld		a,(x_salvada)
		ld		b,a
		ld		a,(ix+1)
		cp		b
		jp		nc,.resta_x

.suma_x:

		inc		a
		ld		(ix+1),a
		jp		.seguimos
		
.resta_x:

		dec		a
		ld		(ix+1),a
		
.seguimos:
		
		ld		a,(ix+2)
		add		1
		ld		(ix+2),a
					
		cp		110
		ret		c

		ld		a,(prota_saltando)
		cp		1
		jp		z,secuencia222
				
		ld		a,(ix+1)
		ld		b,a
		ld		a,(x_salvada)
		add		10
		cp		b
		jp		c,secuencia222
		sub		25
		cp		b
		jp		nc,secuencia222

secuencia221:

		ld		a,20
		ld		(tiembla_el_decorado_v),a
		
		LD		A,16
		call	EL_7000_37
		ld		a,20
		ld		c,1
		call	ayFX_INIT
		call	DESCONTAMOS_VIDA_CON_COTORRA
		ld		a,1						
		ld		(pintamos_sin_colision),a
		
		call	CARAS_MALO_DA_A_BUENO
		
secuencia222:

		ld		a,224
		ld		(ix+2),a		
		xor		a
		ld		(ix),a
		ld		(ix+4),a
		ld		(ix+5),a
		
		ret
		
control_de_fotograma:

		ld		a,(ix+3)
		cp		42*4
		jp		z,.a_45

.a_43:

		ld		a,42*4
		ld		(ix+3),a
		ret
		
.a_45
		
		ld		a,44*4
		ld		(ix+3),a
		ret
				
DISPARA_COTORRA:
		
		ld		a,(intervalo_de_disparos)								; vemos si toca hacer algo
		ld		b,a
		ld		a,(intervalo_feaciente)
		inc		a
		ld		(intervalo_feaciente),a
		cp		b
		ret		nz
		
		xor		a
		ld		(intervalo_feaciente),a
		
		call	DA_VALOR_AL_DADO_37
		and		00000011b												; hayamos un valor aleatorio entre 0 y 3
		cp		0
		jp		nz,.dispara

.cambia_de_direccion_en_lugar_de_disparar:
		
		ld		a,(nivel)
		cp		3
		jp		nc,.dispara
		call	DA_VALOR_AL_DADO_37
		and		00000001b
		ld		(direccion_cotorra),a

		ret

.dispara:

		push	ix														; guardamos los datos de ix porque la vamos a usar

		ld		a,(disparo_que_toca)									; elegimos cual de los 2 sprites tocamos 
		inc		a
		and		00000001b												; de los dedicados a disparo
		ld		(disparo_que_toca),a
		cp		1
		jp		z,.activamos_disparo_2

.activamos_disparo_1:

		ld		ix,propiedades_disparo
		jp		.otorgamos_valores

.activamos_disparo_2:

		ld		a,(nivel)
		cp		2
		jp		nc,.prepara_ix
			
		ld		a,(cambio_de_cotorra)
		cp		1
		jp		c,.salimos_de_aqui

.prepara_ix:

		ld		ix,propiedades_disparo_2

.otorgamos_valores:
				
		ld		a,(ix)													; si el disparo está activo, nos saltamos esto
		cp		1
		jp		z,.salimos_de_aqui

		ld		a,1														; activamos el disparo
		ld		(ix),a
		
		ld		a,(iy)													; le damos su y
		add		16
		ld		(ix+2),a
		
		ld		a,(iy+1)												; le damos su x
		add		16
		ld		(ix+1),a
		
		ld		a,(nivel)
		sub		2
		ld		b,a
		cp		2
		jp		z,.ponemos_el_valor_a_secuencia
		call	DA_VALOR_AL_DADO_37										; escogemos la secuencia que realizará
		and		00000011b
		
		ld		b,a
		cp		0
		jp		z,.ponemos_el_valor_a_secuencia
		cp		1
		jp		z,.revisamos_si_esta_en_estado_1
		cp		2
		jp		z,.revisamos_si_esta_en_estado_2
		
		dec		a
		ld		b,a

.revisamos_si_esta_en_estado_2:											; nos aseguramos que puede hacer la secuencia 2


		ld		a,(cambio_de_cotorra)
		cp		2
		jp		nc,.ponemos_el_valor_a_secuencia
		ld		a,b
		dec		a
		ld		b,a
		
.revisamos_si_esta_en_estado_1:											; nos aseguramos que puede hacer la secuencia 1


		ld		a,(cambio_de_cotorra)
		cp		1
		jp		nc,.ponemos_el_valor_a_secuencia
		ld		a,b
		dec		a
		ld		b,a		
		
.ponemos_el_valor_a_secuencia:											; otorgamos la secuencia adecuada
		
		ld		a,b
		ld		(ix+4),a
		
.salimos_de_aqui:														; recuperamos ix y salimos
		
		pop		ix
		
		ret
		
COMPROBAMOS_SPRITES_COTORRA:

		ld		a,55
		call	EL_7000_37
				
		ld		a,(cambio_de_cotorra)									; si ya cambió, no revisamos
		cp		0
		jp		nz,.comprobamos_cambio_2
		
		ld		a,(vida_cotorra)										; si la vida supera 10, primer cambio
		cp		15
		ret		c
		
		ld		a,1
		ld		(cambio_de_cotorra),a

		ld		a,(nivel)												; sólo miramos si estamos hablando de Tromaxe
		cp		1
		ret		nz
				
		halt
		ld		hl,TROMAXE_2_SPRITES_1_2
		ld		de,#7380												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		di
		ld		hl,TROMAXE_2_SPRITES_1_4
		ld		de,#7400												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		di
		ld		hl,TROMAXE_2_SPRITES_2_2
		ld		de,#7480												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		di
		ld		hl,TROMAXE_2_SPRITES_2_4
		ld		de,#7500												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		ei
		
		ret						
.comprobamos_cambio_2:

		cp		1
		ret		nz

		ld		a,(vida_cotorra)										; si la vida supera 10, primer cambio
		cp		30
		ret		c

		ld		a,3
		ld		(cambio_de_cotorra),a

		ld		a,(nivel)												; sólo miramos si estamos hablando de Tromaxe
		cp		1
		ret		nz
						
		halt
		ld		hl,TROMAXE_3_SPRITES_1_2
		ld		de,#7380												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		di
		ld		hl,TROMAXE_3_SPRITES_1_4
		ld		de,#7400												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		di
		ld		hl,TROMAXE_3_SPRITES_2_2
		ld		de,#7480												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		di
		ld		hl,TROMAXE_3_SPRITES_2_4
		ld		de,#7500												; copiamos patrones del cotorra
		ld		bc,64
		di
		call	fast_LDIRVM
		ei
		
		ret	
		
DA_VALOR_AL_DADO_37:

		ld		a,r
		and		00000111b		
		ld		(dado),a
		
		ret
		
BORRA_COLISION:

		ld		a,(tiembla_el_decorado_v)
		cp		0
		ret		nz
		
		ld		a,(pintamos_sin_colision)
		cp		0
		ret		z
		
		ld		a,#E0
		ld		(ix+40),a
		ld		(ix+40+4),a
		
		call	CARAS_COMIENZO_PELEA
		xor		a
		ld		(pintamos_sin_colision),a
		
		ret
		
PINTA_COTORRA:

		HALT
		
		ld		de,#7A38												; Dirección de VRAM del sprte*8 a pintar
		
		ld		a,(iy+2)												; Doy el valor de patrón a cada bloque de atributos
		add		4
		ld		(iy+6),a
		add		4
		ld		(iy+10),a
		add		4
		ld		(iy+14),a	
		add		4
		ld		(iy+18),a			
		add		4
		ld		(iy+22),a			
		add		4
		ld		(iy+26),a			
		add		4
		ld		(iy+30),a			
		
		ld		a,(iy)													; Doy el valor de y a cada bloque de atributos
		ld		(iy+4),a
		ld		(iy+16),a
		ld		(iy+20),a	
		add		16
		ld		(iy+8),a		
		ld		(iy+12),a			
		ld		(iy+24),a			
		ld		(iy+28),a		
		
		ld		a,(iy+1)												; Doy el valor de x a cada bloque de atributos
		ld		(iy+5),a
		ld		(iy+9),a
		ld		(iy+13),a	
		add		16
		ld		(iy+17),a		
		ld		(iy+21),a			
		ld		(iy+25),a			
		ld		(iy+29),a

		ld		hl,atributos_sprites_cotorra							; copia atributos del sprite a VRAM	
		ld		bc,31
		
		di
		call	LDIRVM
		ei
		
		ld		a,(nivel)
		cp		4
		jp		z,.luckylukeb
		cp		3
		jp		z,.salgueri
		cp		2
		jp		z,.onirikus

.tromaxe:
		
		ld		hl,TROMAXE_POSE_1		
		jp		.resto

.onirikus:

		ld		hl,ONIRIKUS_POSE_1		
		jp		.resto

.salgueri:

		ld		hl,SALGUERI_POSE_1		
		jp		.resto		

.luckylukeb:

		ld		hl,LUCKYLUKEB_POSE_1
						
.resto:
		
		ld		de,#78e0		
		
		ld		bc,128
		ld		a,55
		call	EL_7000_37
		di
		call	LDIRVM
		ei
		
		ret

PINTA_TRAPOS:
		
		push	ix
		push	iy
		HALT
		ld		de,#7A58												; Dirección de VRAM del sprte*2 a pintar
		ld		ix,propiedades_disparo
		ld		iy,atributos_disparos
		ld		a,(ix+2)
		ld		(iy),a
		ld		(iy+4),a
		ld		a,(ix+1)
		ld		(iy+1),a
		ld		(iy+1+4),a
		ld		a,(ix+3)
		ld		(iy+2),a
		ADD		4
		ld		(iy+2+4),a
		ld		ix,propiedades_disparo_2
		ld		a,(ix+2)
		ld		(iy+8),a
		ld		(iy+4+8),a
		ld		a,(ix+1)
		ld		(iy+1+8),a
		ld		(iy+1+4+8),a
		ld		a,(ix+3)
		ld		(iy+2+8),a
		ADD		4
		ld		(iy+2+4+8),a		
		ld		hl,atributos_disparos									; copia atributos del sprite a VRAM	
		ld		bc,15
		
		di
		call	LDIRVM
		ei

		pop		iy
		pop		ix
								
		ld		a,(nivel)
		cp		4
		jp		z,.luckylukeb
		cp		3
		jp		z,.salgueri
		cp		2
		jp		z,.onirikus

.tromaxe:
		ld		a,(disparo_que_toca)
		cp		1
		jp		z,.tromaxe_1
.tromaxe_0:		
		ld		hl,TRAPO_COLORES_1		
		jp		.resto
.tromaxe_1:
		ld		hl,TRAPO_COLORES_2		
		jp		.resto

.onirikus:
		ld		a,(disparo_que_toca)
		cp		1
		jp		z,.onirikus_1
.onirikus_0:			
		ld		hl,NINO_COLORES_1	
		jp		.resto
.onirikus_1:
		ld		hl,NINO_COLORES_2		
		jp		.resto
.salgueri:
		ld		a,(disparo_que_toca)
		cp		1
		jp		z,.salgueri_1
.salgueri_0:		
		ld		hl,CARTUCHO_COLORES_1		
		jp		.resto		
.salgueri_1:
		ld		hl,CARTUCHO_COLORES_2
		jp		.resto
.luckylukeb:
		ld		a,(disparo_que_toca)
		cp		1
		jp		z,.luckylukeb_1
.luckylukeb_0:
		ld		hl,MASCARA_COLORES_1
		jp		.resto
.luckylukeb_1:
		
		ld		hl,MASCARA_COLORES_2						
.resto:
		
		ld		de,#79B0		
		
		ld		bc,16
		ld		a,55
		call	EL_7000_37
		di
		call	LDIRVM
		ei
		
		ret
								
A_I_COTORRA:


		
		ld		a,(pie_de_cotorra)
		inc		a
		and		00111111b
		ld		(pie_de_cotorra),a
		cp		32
		jp		c,.pose_dos

.pose_uno:

		ld		a,(nivel)
		cp		4
		jp		z,.luckylukeb1
		cp		3
		jp		z,.salgueri1
		cp		2
		jp		z,.onirikus1

.tromaxe1:
		
		ld		hl,TROMAXE_POSE_1		
		jp		.resto

.onirikus1:

		ld		hl,ONIRIKUS_POSE_1		
		jp		.resto

.salgueri1:

		ld		hl,SALGUERI_POSE_1		
		jp		.resto		

.luckylukeb1:

		ld		hl,LUCKYLUKEB_POSE_1

.resto:
								
		ld		a,26*4
		ld		(iy+2),a
		
		jp		.seguimos

.pose_dos:

		ld		a,(nivel)
		cp		4
		jp		z,.luckylukeb2
		cp		3
		jp		z,.salgueri2
		cp		2
		jp		z,.onirikus2

.tromaxe2:
		
		ld		hl,TROMAXE_POSE_2		
		jp		.resto2

.onirikus2:

		ld		hl,ONIRIKUS_POSE_2		
		jp		.resto2

.salgueri2:

		ld		hl,SALGUERI_POSE_2		
		jp		.resto2		

.luckylukeb2:

		ld		hl,LUCKYLUKEB_POSE_2

.resto2:

		ld		a,34*4
		ld		(iy+2),a
						
.seguimos:

		ld		de,#78e0		
		ld		bc,128
		ld		a,55
		call	EL_7000_37
		di
		call	LDIRVM
		ei

		ld		a,(retraso_cotorra)										; Le damos un retraso de movimiento al cotorra
		inc		a
		and		00000011b
		ld		(retraso_cotorra),a
		cp		0
		ret		nz
		
		ld		a,(direccion_cotorra)
		cp		0
		jp		z,.derecha

.izquierda:

		ld		a,(iy+1)
		cp		108
		jp		c,.cambio_a_derecha
		dec		a
		push	af

		ld		a,(cambio_de_cotorra)
		ld		b,a
		pop		af
		sub		b
		ld		(iy+1),a
		ret
		
.cambio_a_derecha:

		xor		a
		ld		(direccion_cotorra),a
		ret

.derecha:

		ld		a,(iy+1)
		cp		187-28
		jp		nc,.cambio_a_izquierda
		inc		a
		ld		b,a
		ld		a,(cambio_de_cotorra)
		add		b		
		ld		(iy+1),a
		ret
		
.cambio_a_izquierda:

		ld		a,1
		ld		(direccion_cotorra),a
		ret
				
COORDENADAS_DISPARO_PROTA:

		ld		a,(disparo_ya_en_juego)
		cp		0
		ret		z
		
		ld		a,(ix+32)
		cp		56
		jp		c,reiniciamos_proyectil
		
		dec		a
		ld		(ix+32),a
		ld		(ix+32+4),a

CALCULOS_DE_LA_X:

		ld		a,(x_proyectil_salida)
		ld		b,a
		ld		a,(ix+32+1)
		cp		b
		jp		c,.mas_1
		jp		nc,.menos_1
		
		ret
		
.mas_1:

		ld		a,(ix+32+1)
		inc		a
		ld		(ix+32+1),a
		ld		(ix+32+4+1),a
		
		ret

.menos_1:

		ld		a,(ix+32+1)
		dec		a
		ld		(ix+32+1),a
		ld		(ix+32+4+1),a
		
		ret
		
reiniciamos_proyectil:

		ld		a,(ix+32+1)												; calculamos si el proyectil es superior a los ojos del malo
		add		2
		ld		b,a
		ld		a,(iy+1)
		add		2
		cp		b
		jp		nc,.reinicio

		ld		a,(ix+32+1)												; calculamos si el proyectil está en los ojos del malo
		add		12
		ld		b,a
		ld		a,(iy+1)
		add		25
		cp		b
		jp		c,.reinicio

		ld		a,(ix+32)
		ld		(ix+40),a
		ld		(ix+40+4),a

		ld		a,(ix+32+1)
		ld		(ix+40+1),a
		ld		(ix+40+1+4),a
				
		ld		a,24*4													; le damos el patrón a la colisión
		ld		(ix+40+2),a
		ld		a,25*4					
		ld		(ix+40+2+4),a
		
		ld		a,(vida_cotorra)
		inc		a
		push	af
		ld		a,(espada)
		add		a
		ld		b,a
		ld		a,(cuchillo)
		add		b
		inc		a
		ld		b,a
		pop		af
		add		b
		ld		(vida_cotorra),a


		
		push	iy
		push	ix
		push	af
		ld		iy,copia_parte_de_culo									
		CALL	COPY_A_GUSTO
		call	EL_12_A_0_EL_14_A_1001
		
		pop		af														; añadimos la x adecuada a la copia del culo									
		ld		b,a
		ld		a,(ix+8)
		add		b
		ld		(ix+8),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY		
		pop		ix
		pop		iy
		
		call	DA_VALOR_AL_DADO_37
		and		00000001b
		ld		(direccion_cotorra),a	
			
		ld		a,20
		ld		(tiembla_el_decorado_v),a

		LD		A,16
		call	EL_7000_37
		ld		c,1
		call	ayFX_INIT
		
		ld		a,1		
		ld		(pintamos_sin_colision),a
		
		call	CARAS_BUENO_DA_A_MALO
										
.reinicio:
		
		xor		a
		ld		(disparo_ya_en_juego),a
		
		ld		a,224 
 		ld		(ix+32),a
		ld		(ix+32+4),a
		
		ret
		
DISPARA_PROTA:
		
		ld		a,(tiembla_el_decorado_v)								; si está temblando el decorado, no puede disparar
		cp		0
		ret		nz
		
		ld		a,(prota_saltando)										; si está saltando, no puede disparar
		cp		1
		ret		z
		
		ld		a,(disparo_ya_en_juego)
		cp		1
		ret		z

		ld		a,4														;si pulsa M vamos a ver si puede disparar
		call	SNSMAT
		bit		2,a
		jp		z,.seguimos
		ld		a,3
		call	GTTRIG
		CP		#FF		
		ret		nz		
.seguimos:
		ld		a,1														; activamos el disparo
		ld		(disparo_ya_en_juego),a

		ld		a,(ix)													; le damos la y al arma
		add		8
		ld		(ix+32),a
		ld		(ix+32+4),a		
		ld		a,(ix+1)												; le damos la x al arma
		add 	8
		ld		(ix+32+1),a
		ld		(ix+32+1+4),a
		
		ld		b,a														; calculamos el valor de llegada
		push	ix
		ld		ix,objetivos_proyectil_prota
		push	ix
		pop		de
		sub		a,60
		ld		l,a
		xor		a
		ld		h,a
		adc		hl,de
		push	hl
		pop		ix
		ld		a,(ix)	
		ld		(x_proyectil_salida),a
		pop		ix

		LD		A,16
		call	EL_7000_37
		ld		a,24
		ld		c,1
		call	ayFX_INIT
				
		ld		a,22*4													; le damos el patrón al arma
		ld		(ix+32+2),a
		ld		a,23*4					
		ld		(ix+32+2+4),a
		ret
		
PINTA_A_PROTA:
		
		ld		a,(prota_saltando)
		cp		1
		jp		z,PINTA_PROTA_SALTANDO
		
		ld		a,(fotograma_que_toca)
		ld		(ix+2),a

		ld		de,#7A08												; Dirección de VRAM del sprte*8 a pintar

		call	PINTA_SPRITE_DE_8
		
		ld		de,#7820
		call	PATRON_COLORES
		
		ld		a,(var_cuentas_peq)
		inc		a
		and		01111111b
		ld		(var_cuentas_peq),a
		
		cp		64
		jp		c,.dos
.uno:
		
		ld		a,8
		ld		(fotograma_que_toca),a
		RET

.dos:

		ld		a,40
		ld		(fotograma_que_toca),a
		RET
		
PINTA_PROTA_SALTANDO:

		ld		de,#7A08												; Dirección de VRAM del sprte*8 a pintar
	
		ld		a,2*4
		ld		(ix+2),a												; Doy el valor de patrón a cada bloque de atributos
		ld		a,3*4
		ld		(ix+6),a
		ld		a,18*4
		ld		(ix+10),a
		ld		a,19*4
		ld		(ix+14),a	
		
		ld		a,6*4
		ld		(ix+18),a			
		ld		a,7*4
		ld		(ix+22),a			
		ld		a,20*4
		ld		(ix+26),a			
		ld		a,21*4
		ld		(ix+30),a			
		
		ld		a,(ix)													; Doy el valor de y a cada bloque de atributos
		ld		(ix+4),a
		ld		(ix+16),a
		ld		(ix+20),a	
		add		16
		ld		(ix+8),a		
		ld		(ix+12),a			
		ld		(ix+24),a			
		ld		(ix+28),a		
		
		ld		a,(ix+1)												; Doy el valor de x a cada bloque de atributos
		ld		(ix+5),a
		ld		(ix+9),a
		ld		(ix+13),a	
		add		16
		ld		(ix+17),a		
		ld		(ix+21),a			
		ld		(ix+25),a			
		ld		(ix+29),a

		ld		hl,atributos_sprites_prota								; copia atributos del sprite a VRAM	
		ld		bc,47
		halt
		di
		call	LDIRVM
		ei
		
		ld		a,55
		call	EL_7000_37		

		ld		de,#7820
		
		ld		a,(personaje)
		cp		1
		jp		z,.Natpu
		cp		2
		jp		z,.Fergar		
		cp		3
		jp		z,.Crira
		cp		4
		jp		z,.Vicmar

.Natpu:

		ld		bc,8*6
		ld		hl,NATPU_POSE_1
		di
		call	LDIRVM
		ei
		
		LD		de,#7840
		ld		bc,8*4
		ld		hl,NATPU_POSE_31
		di
		call	LDIRVM
		ei
				
		LD		de,#7880
		ld		bc,8*4
		ld		hl,NATPU_POSE_32
		di
		call	LDIRVM
		ei
			
				
		ld		a,(pagina_de_idioma)
		jp		EL_7000_37
		
.Fergar:		
						
		ld		bc,8*6
		ld		hl,FERGAR_POSE_1
		di
		call	LDIRVM
		ei
		
		LD		de,#7840
		ld		bc,8*4
		ld		hl,FERGAR_POSE_31
		di
		call	LDIRVM
		ei
				
		LD		de,#7880
		ld		bc,8*4
		ld		hl,FERGAR_POSE_32
		di
		call	LDIRVM
		ei
				
				
		ld		a,(pagina_de_idioma)
		jp		EL_7000_37

.Crira:

		ld		bc,8*6
		ld		hl,CRIRA_POSE_1
		di
		call	LDIRVM
		ei
		
		LD		de,#7840
		ld		bc,8*4
		ld		hl,CRIRA_POSE_31
		di
		call	LDIRVM
		ei
				
		LD		de,#7880
		ld		bc,8*4
		ld		hl,CRIRA_POSE_32
		di
		call	LDIRVM
		ei
				
				
		ld		a,(pagina_de_idioma)
		jp		EL_7000_37
	
.Vicmar:

		ld		bc,8*6
		ld		hl,VICMAR_POSE_1
		di
		call	LDIRVM
		ei
		
		LD		de,#7840
		ld		bc,8*4
		ld		hl,VICMAR_POSE_31
		di
		call	LDIRVM
		ei
				
		LD		de,#7880
		ld		bc,8*4
		ld		hl,VICMAR_POSE_32
		di
		call	LDIRVM
		ei
				
				
		ld		a,(pagina_de_idioma)
		jp		EL_7000_37
						
MUEVE_PROTA:

		ld		a,(prota_saltando)										; Si está saltando, mantiene la dirección
		cp		1
		jp		z,.mantiene_direccion
		
		xor		a														;comprobamos si toca teclado
		call	GTSTCK
		or		a
		jp		nz,.esta_con_teclado

		ld		a,1
		call	GTSTCK
		
.esta_con_teclado:
		
		ld		(ultimo_stick),a
		jp		.decidimos_que_ha_hecho

.mantiene_direccion:

		ld		a,(ultimo_stick)
		
.decidimos_que_ha_hecho:
		
		cp		3
		jp		z,.derecha
		cp		7
		jp		z,.izquierda

		ret

.derecha

		call	suma_las_botas
		
		ld		a,(ix+1)
		cp		255-42
		ret		nc
		add		b
		ld		(ix+1),a
		ret

.izquierda

		call	suma_las_botas

		ld		a,(ix+1)
		cp		#35
		ret		c
		sub		b
		ld		(ix+1),a
		ret
		
suma_las_botas:

		ld		a,(botas_esp)
		ld		b,a
		ld		a,(botas)
		add		b
		inc		a
		inc		a
		ld		b,a
		
		ret
		
SALTA_PROTA:

		ld		a,(salto_prota_continuo)								; Reducimos el valor de control del salto
		cp		0
		jp		z,.sigue
		dec		a
		ld		(salto_prota_continuo),a
		
		cp		20
		ret		nc
		
		ld		a,119-32												; Devolvemos coordenada y sin salto
		ld		(ix),a		

		xor		a														; Le decimos que el prota ya no está saltando
		ld		(prota_saltando),a
		
		ret
		
.sigue
		
		call	GTTRIG													; Miramos si vuelve a saltar
		cp		#FF		
		jp		z,.esta_saltando

		ld		a,1
		call	GTTRIG
		cp		#FF		
		jp		z,.esta_saltando
				
		ret

.esta_saltando:

		ld		a,116-32												; Le damos coordenada y de salto
		ld		(ix),a
		
		ld		a,1														; Le decimos que está saltando
		ld		(prota_saltando),a
						
		ld		a,(botas_esp)											; Le decimos el tiempo que salta
		cp		0
		jp		z,.terminando
		ld		a,20
		
.terminando
		
		add		40
		ld		(salto_prota_continuo),a

		LD		A,16
		call	EL_7000_37

		ld		a,23
		ld		c,0
		call	ayFX_INIT
				
		ret
		
PATRON_COLORES:

		ld		a,(var_cuentas_peq)
		cp		64
		jp		c,.dos
.uno:
		
		ld		a,(personaje)
		cp		1
		jp		z,.uno_natpu
		cp		2
		jp		z,.uno_fergar		
		cp		3
		jp		z,.uno_crira
		cp		4
		jp		z,.uno_vicmar

.uno_natpu:
						
		ld		hl,NATPU_POSE_1
		jp		.final

.uno_fergar:
						
		ld		hl,FERGAR_POSE_1
		jp		.final

.uno_crira:
						
		ld		hl,CRIRA_POSE_1
		jp		.final

.uno_vicmar:
						
		ld		hl,VICMAR_POSE_1
		jp		.final

.dos:

		ld		a,(personaje)
		cp		1
		jp		z,.dos_natpu
		cp		2
		jp		z,.dos_fergar		
		cp		3
		jp		z,.dos_crira
		cp		4
		jp		z,.dos_vicmar

.dos_natpu:
						
		ld		hl,NATPU_POSE_2
		jp		.final

.dos_fergar:
						
		ld		hl,FERGAR_POSE_2
		jp		.final

.dos_crira:
						
		ld		hl,CRIRA_POSE_2
		jp		.final

.dos_vicmar:
						
		ld		hl,VICMAR_POSE_2
		
.final:				

		ld		bc,128
		ld		a,55
		call	EL_7000_37
		di
		call	LDIRVM
		ei
		
		ld		a,(pagina_de_idioma)
		jp		EL_7000_37
					
PINTA_SPRITE_DE_8:

		halt
		ld		a,(ix+2)												; Doy el valor de patrón a cada bloque de atributos
		add		4
		ld		(ix+6),a
		add		4
		ld		(ix+10),a
		add		4
		ld		(ix+14),a	
		add		4
		ld		(ix+18),a			
		add		4
		ld		(ix+22),a			
		add		4
		ld		(ix+26),a			
		add		4
		ld		(ix+30),a			
		
		ld		a,(ix)													; Doy el valor de y a cada bloque de atributos
		ld		(ix+4),a
		ld		(ix+16),a
		ld		(ix+20),a	
		add		16
		ld		(ix+8),a		
		ld		(ix+12),a			
		ld		(ix+24),a			
		ld		(ix+28),a		
		
		ld		a,(ix+1)												; Doy el valor de x a cada bloque de atributos
		ld		(ix+5),a
		ld		(ix+9),a
		ld		(ix+13),a	
		add		16
		ld		(ix+17),a		
		ld		(ix+21),a			
		ld		(ix+25),a			
		ld		(ix+29),a

		ld		hl,atributos_sprites_prota								; copia atributos del sprite a VRAM	
		ld		bc,47
		di
		call	LDIRVM
		ei
			
		ret

DESCONTAMOS_VIDA_CON_COTORRA:

		ld		a,(armadura)
		ld		b,a
		ld		a,(casco)
		add		b
		ld		b,a
		ld		a,(nivel)
		add		2
		sub		b
		ld		(var_cuentas_peq),a
		
		ld		a,(pagina_de_idioma)
		call	EL_7000_37
		
.varios_descuentos:
		
		ld		a,(vida_unidades)
		dec		a
		ld		(vida_unidades),a
		
		call	AJUSTA_VIDA_HACIA_ABAJO_EN_COTORRA
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		or		a
		jp		nz,.varios_descuentos
		
		push	ix
		push	iy
		call	PINTA_VIDA	
		pop		iy
		pop		ix
		
		ret
AJUSTA_VIDA_HACIA_ABAJO_EN_COTORRA:

		ld		a,(vida_unidades)										; comprobamos si las unidades inferior a 0
		cp		255
		ret		nz
		
		ld		a,9														; ponemos las unidades a 9
		ld		(vida_unidades),a
		ld		a,(vida_decenas)										; reducimos las decenas
		dec		a
		ld		(vida_decenas),a										
		
		cp		255
		jp		z,MUERTE_EN_COTORRA
		
		ret		
		
MUERTE_EN_COTORRA:

		push	af

		call	stpmus
		
		ld		a,3
		ld		(que_musica_0),a
				
		LD		A,53		
		call	EL_7000_37
				
		di
		call	strmus													;iniciamos la música de tienda
		ei
		
		LD		A,(pagina_de_idioma)		
		call	EL_7000_37
				
		ld		hl,MUERTE_1
		call	TEXTO_A_ESCRIBIR
		ld		HL,MUERTE_2
		call	TEXTO_A_ESCRIBIR		
		call	STRIG_DE_CONTINUE
				
		jp		REINICIANDO_EL_JUEGO
		
fast_LDIRVM:

    ex de,hl    ; this is wasteful, but it's to maintain the order of parameters of the original LDIRVM...
                ; For things that require real speed, this function should not be used anyway, but use specialized loops
    push de
    push bc
    call NSTWRT
    pop bc
    pop hl
    ; jp copy_to_VDP

;-----------------------------------------------
; This is like LDIRVM, but faster, and assumes, we have already called "SETWRT" with the right address
; input: 
; - hl: address to copy from
; - bc: amount fo copy
copy_to_VDP:
    ld e,b
    ld a,c
    or a
    jr z,copy_to_VDP_lsb_0
    inc e
copy_to_VDP_lsb_0:
    ld b,c
    ; get the VDP write register:
    ld a,(VDP.DW)
    ld c,a
    ld a,e
copy_to_VDP_loop2:
copy_to_VDP_loop:
    outi
    jp nz,copy_to_VDP_loop
    dec a
    jp nz,copy_to_VDP_loop2
    ret
    
objetivos_proyectil_prota:						db		#6f,#70,#70,#71,#71,#72,#72,#72,#73,#73,#74,#74,#75,#75,#76,#76,#76
												db		#77,#77,#78,#78,#79,#79,#79,#7a,#7a,#7b,#7b,#7c,#7c,#7c,#7d,#7d,#7e,#7e,#7f,#7f,#80,#80,#80
												db		#81,#81,#82,#82,#83,#83,#83,#84,#84,#85,#85,#86,#86,#86,#87,#87,#88,#88,#89,#89,#8a,#8a,#8a
												db		#8b,#8b,#8c,#8c,#8d,#8d,#8d,#8e,#8e,#8f,#8f,#90,#90,#90,#91,#91,#92,#92,#93,#93,#94,#94,#94
												db		#95,#95,#96,#96,#97,#97,#97,#98,#98,#99,#99,#9a,#9a,#9b,#9b,#9b,#9c,#9c,#9d,#9d,#9e,#9e,#9e
												db		#9f,#9f,#a0,#a0,#a1,#a1,#a1,#a2,#a2,#a3,#a3,#a4,#a4,#a5,#a5,#a5,#a6,#a6,#a7,#a7,#a8,#a8,#a8
												db		#a9,#a9,#aa,#aa,#ab,#ab,#ab,#ac,#ac,#ad,#ad,#ae,#ae,#af,#af,#af,#b0,#b0,#b1,#b1,#b2,#b2,#b2
												db		#b3,#b3,#b4,#b4,#b5,#b5,#b5,#b6,#b6,#b7,#b7,#b8,#b8,#b9,#b9,#b9,#ba,#ba,#bb,#bb,#bc,#bc
copia_objetos_a_salvo:							dw		#0036,#0080,#0036,#02e4,#0096,#001a
copia_tienda_a_salvo:							dw		#0036,#0080,#0036,#01D4,#0096,#001a
copia_objetos_a_su_sitio:						dw		#0036,#02e4,#0036,#0080,#0096,#001a
copia_tienda_a_su_sitio:						dw		#0036,#01D4,#0036,#0080,#0096,#001a
cuadrado_que_limpia_5_del_37:					dw		#0000,#0000,#0036,#000a,#0094,#006c	; Limpia la pantalla del laberinto en 0
cuadrado_que_limpia_5_1_del_37:					dw		#0000,#0000,#0036,#010a,#0094,#006c	; Limpia la pantalla del laberinto en 1	
cuadrado_que_limpia_8:							dw		#0000,#0000,#0036,#0080,#0096,#001a ;BORRA ZONA DE OBJETOS GLOBAL
copia_dormir_en_lista:							dw		#0039,#0280,#0046,#0080,#000d,#000d
copia_salir_en_lista:							dw		#0047,#0280,#00b3,#0080,#000d,#000d
copia_brujula_en_lista:							dw		#0001,#0272,#009e,#0080,#000d,#000d
copia_papel_en_lista:							dw		#0010,#0272,#009e,#0080,#000c,#000d
copia_tinta_en_lista:							dw		#002b,#0272,#009e,#0080,#000d,#000d
copia_pluma_en_lista:							dw		#001e,#0272,#009e,#0080,#000c,#000d
copia_lupa_en_lista:							dw		#0048,#0272,#009e,#0080,#000c,#000d
copia_gallina_en_lista:							dw		#007f,#0280,#009e,#0080,#000d,#000d
copia_trampa_en_lista:							dw		#0071,#0280,#005c,#0080,#000d,#000d
copia_botas_en_lista:							dw		#0056,#0272,#005c,#0080,#000C,#000d
copia_botas_esp_en_lista:						dw		#0064,#0272,#005c,#0080,#000C,#000d
copia_cuchillo_en_lista:						dw		#0071,#0272,#005c,#0080,#000b,#000d
copia_espada_en_lista:							dw		#007f,#0272,#005c,#0080,#000d,#000d
copia_armadura_en_lista:						dw		#0001,#0280,#005c,#0080,#000C,#000d
copia_casco_en_lista:							dw		#0010,#0280,#005c,#0080,#000C,#000d
copia_mano_en_lista:							dw		#0056,#0280,#0046,#008d,#000c,#000d
tapa_objeto_en_tienda_con_gallina:				dw		#007f,#0280,#005c,#0080,#000d,#000d
tapa_objeto_en_tienda_con_trampa:				dw		#0071,#0280,#005c,#0080,#000d,#000d
tapa_objeto_en_tienda:							dw		#003a,#000a,#005c,#0080,#000G,#000d
cuadrado_que_limpia_9:							dw		#0000,#0000,#0036,#008d,#0096,#000d
copia_brujula_en_objetos_tienda:				dw		#0001,#0272,#0037,#0291,#000d,#000d
copia_papel_en_objetos_tienda:					dw		#0010,#0272,#0044,#0291,#000c,#000d
copia_tinta_en_objetos_tienda:					dw		#002b,#0272,#0050,#0291,#000d,#000d
copia_pluma_en_objetos_tienda:					dw		#001e,#0272,#005c,#0291,#000c,#000d
copia_llave_en_objetos_tienda:					dw		#0039,#0272,#0068,#0291,#000d,#000d
copia_lupa_en_objetos_tienda:					dw		#0048,#0272,#0076,#0291,#000c,#000d
copia_botas_en_objetos_tienda:					dw		#0056,#0272,#0037,#029d,#000C,#000d
copia_botas_esp_en_objetos_tienda:				dw		#0064,#0272,#0037,#029d,#000C,#000d
copia_cuchillo_en_objetos_tienda:				dw		#0071,#0272,#0044,#029d,#000C,#000d
copia_espada_en_objetos_tienda:					dw		#007f,#0272,#0044,#029d,#000d,#000d
copia_armadura_en_objetos_tienda:				dw		#0001,#0280,#0050,#029d,#000C,#000d
copia_casco_en_objetos_tienda:					dw		#0010,#0280,#005c,#029d,#000C,#000d
copia_pochadero_en_pantalla:					dw		#0048,#001B,#0070,#004c
												db		#00,#00,#F0	

copia_zona_pelea_en_pantalla:					dw		#0034,#000A,#00c2,#006c
												db		#00,#00,#F0
copia_enemigo_1_en_vram:						dw		#0000,#039E,#00ac,#002a
												db		#00,#00,#F0
copia_cara_neutra_jugador1:						dw		#0000,#0375,#000C,#009D,#002A,#0028
copia_cara_neutra_cotorra:						dw		#0000,#039e,#00CC,#009D,#002A,#0028
copia_cara_activa_jugador1:						dw		#002c,#0375,#000C,#009D,#002A,#0028
copia_cara_activa_cotorra:						dw		#002c,#039e,#00CC,#009D,#002A,#0028
copia_cara_ataque_jugador1:						dw		#0057,#0375,#000C,#009D,#002A,#0028
copia_cara_ataque_cotorra:						dw		#0057,#039e,#00CC,#009D,#002A,#0028
copia_cara_pierde_jugador1:						dw		#0082,#0375,#000C,#009D,#002A,#0028
copia_cara_pierde_cotorra:						dw		#0082,#039e,#00CC,#009D,#002A,#0028												
																								
copia_escenario_a_page_1_37:					dw		#0036,#000C,#0036,#010C,#0094,#006A
copia_cadeneta:									dw		#0096,#0000,#00C3,#0000,#002E,#0008
borde_izquierdo_para_izquierda:					DW		#00C2,#0000,#00ED,#0000,#0010,#0078
copia_vida:										dw		#00cd,#0085,#0028,#0013
												db		#00,#00,#F0
copia_culo:										dw		#00cd,#0185,#0028,#0013
												db		#00,#00,#F0
copia_parte_de_culo:							dw		#00cd,#0185,#00cd,#0085,#0001,#0013

copia_page0_a_page1_tras_pelea:					dw		#002e,#0100,#002e,#0000,#00d3,#007e
borra_cara_enemigo:								dw		#0000,#0000,#00cC,#0085,#002A,#0041	
										
POINT_OBJETOS_EN_TIENDA:	dw	BOTAS_EN_TIENDA
							dw	BOTAS_ESP_EN_TIENDA
							dw	ESPADA_EN_TIENDA
							dw	CUCHILLO_EN_TIENDA
							dw	CASCO_EN_TIENDA
							dw	ARMADURA_EN_TIENDA
							dw	TRAMPA_EN_TIENDA

POINT_OBJETOS_EN_TIENDA_2:	dw	PLUMA_EN_TIENDA
							dw	PAPEL_EN_TIENDA
							dw	TINTA_EN_TIENDA
							dw	LAMPARA_EN_TIENDA
							dw	BRUJULA_EN_TIENDA
							dw	GALLINA_EN_TIENDA

; ********** FIN DE DATAS **********

	ds			#69c0-$
	
				include		"RECURSOS EXTERNOS_37.asm"	
				
	ds			#7200-$
	
				include			"LANZADOR FMPACK Y MUSIC MODULE_37.asm"
				include			"LANZADOR EFECTOS PSG_37.ASM"
											
		ds		#8000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 37 DEL MEGAROM **********)))	

; ______________________________________________________________________							

; (((********** PAGINA 38 DEL MEGAROM **********


; VIEJIGUIAS 3 Y 4
		org		#8000
		
VIEJI3:								incbin		"SR5/VIEJIGUIAS/VIEJI3_148x106.DAT"
VIEJI4:								incbin		"SR5/VIEJIGUIAS/VIEJI4_148x106.DAT"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 38 DEL MEGAROM **********)))	

; ______________________________________________________________________							

; (((********** PAGINA 39 DEL MEGAROM **********

; MUSICA DE TIENDA
		org		#8000
		
MUSICA_TIEN:						incbin		"MUSICAS/SHOP.MBM"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 39 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 40 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES1:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT01"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 40 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 41 DEL MEGAROM **********

; COMIC PRESENTACION 2

		org		#8000
		
COM_PRES2:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT02"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 41 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 42 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES3:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT03"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 42 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 43 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES4:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT04"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 43 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 44 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES5:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT05"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 44 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 45 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES6:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT06"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 45 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 46 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES7:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT07"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 46 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 47 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES8:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT08"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 47 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 48 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRES9:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA.DAT09"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 48 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 49 DEL MEGAROM **********

; VICTORIA DE FERGAR

		org		#8000
		
VICTORIA_F:					incbin		"SR5/PROTAS/FERGAR_GANA_150x112.DAT"
copia_victoria_2:							dw		#0034,#0009,#0096,#006f
											db		#00,#00,#f0	
copia_victoria1_2:							dw		#0034,#0109,#0096,#006f
											db		#00,#00,#f0	
		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 49 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 50 DEL MEGAROM **********

; VICTORIA DE CRIRA

		org		#8000
		
VICTORIA_C:					incbin		"SR5/PROTAS/CRIRA_GANA_150x112.DAT"
copia_victoria_3:							dw		#0034,#0009,#0096,#006f
											db		#00,#00,#f0	
copia_victoria1_3:							dw		#0034,#0109,#0096,#006f
											db		#00,#00,#f0	
		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 50 DEL MEGAROM **********)))	

; ______________________________________________________________________	
																		
; (((********** PAGINA 51 DEL MEGAROM **********

; VICTORIA DE VICMAR

		org		#8000
		
VICTORIA_V:					incbin		"SR5/PROTAS/VICMAR_GANA_150x112.DAT"
copia_victoria_4:							dw		#0034,#0009,#0096,#006f
											db		#00,#00,#f0	
copia_victoria1_4:							dw		#0034,#0109,#0096,#006f
											db		#00,#00,#f0	
		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 51 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 52 DEL MEGAROM **********

; VICTORIA DE VICMAR

		org		#8000
		
VICTORIA_N:					incbin		"SR5/PROTAS/NATPU_GANA_150x112.DAT"
copia_victoria:								dw		#0034,#0009,#0096,#006f
											db		#00,#00,#f0	
copia_victoria1:							dw		#0034,#0109,#0096,#006f
											db		#00,#00,#f0	
		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 52 DEL MEGAROM **********)))	

; ______________________________________________________________________																																				

; (((********** PAGINA 53 DEL MEGAROM **********

; VER EL CODIGO DE SALVADO

		org		#8000
MUSICA_MUERT:						incbin		"MUSICAS/MUERTE.mbm"	
DESCIFRAMOS_EL_CODIGO:

	di
	call	stpmus
	ei
	
	ld	ix,codigo_salve
	
BYTE_1:

	ld	a,(nivel)
	dec	a
[6]	sla	a
	ld	b,a
	ld	a,(nivel_2)
[4]	sla	a
	add	b
	ld	b,a
	ld	a,(cantidad_de_jugadores)
[2]	sla	a
	add	b
	ld	b,a
	ld	a,(turno)
	add	b
	ld	(ix),a
		
BYTE_2:

	ld a,(brujula1)
[7]	sla	a	
	ld	b,a
	ld a,(papel1)
[6]	sla	a	
	add	b
	ld	b,a
	ld a,(pluma1)
[5]	sla	a	
	add	b
	ld	b,a
	ld a,(tinta1)
[4]	sla	a	
	add	b
	ld	b,a
	ld a,(llave1)
[3]	sla	a	
	add	b
	ld	b,a
	ld a,(lupa_1)
[2]	sla	a	
	add	b
	ld	b,a
	ld a,(botas1)
	sla	a	
	add	b
	ld	b,a
	ld a,(botas_esp1)
	add	b
	ld	(ix+1),a
	
BYTE_3:


	ld a,(cuchillo1)
[7]	sla	a	
	ld	b,a
	ld a,(espada1)
[6]	sla	a	
	add	b
	ld	b,a
	ld a,(armadura1)
[5]	sla	a	
	add	b
	ld	b,a
	ld a,(casco1)
[4]	sla	a	
	add	b
	ld	b,a
	ld	a,(personaje_1)
	dec	a
[2]	sla	a
	add	b
	ld	b,a
	ld	a,(incremento_velocidad_1)
	and	00000011b	
	add	b
	ld	(ix+2),a
	
BYTE_4:

	ld	a,(incremento_ataque_1)
[6]	sla	a
	and	11000000b
	ld	b,a
	ld	a,(incremento_defensa_1)
[4]	sla	a
	and	00110000b
	add	b
	ld	b,a
	ld	a,(incremento_ataque_origen1)
[2]	sla	a
	add	b
	ld	b,a	
	ld	a,(incremento_defensa_origen1)	
	add	b
	ld	(ix+3),a
			
BYTE_5:

	ld a,(brujula2)
[7]	sla	a	
	ld	b,a
	ld a,(papel2)
[6]	sla	a	
	add	b
	ld	b,a
	ld a,(pluma2)
[5]	sla	a	
	add	b
	ld	b,a
	ld a,(tinta2)
[4]	sla	a	
	add	b
	ld	b,a
	ld a,(llave2)
[3]	sla	a	
	add	b
	ld	b,a
	ld a,(lupa_2)
[2]	sla	a	
	add	b
	ld	b,a
	ld a,(botas2)
	sla	a	
	add	b
	ld	b,a
	ld a,(botas_esp2)
	add	b
	ld	(ix+4),a
	
BYTE_6:

	ld a,(cuchillo2)
[7]	sla	a	
	ld	b,a
	ld a,(espada2)
[6]	sla	a	
	add	b
	ld	b,a
	ld a,(armadura2)
[5]	sla	a	
	add	b
	ld	b,a
	ld a,(casco2)
[4]	sla	a	
	add	b
	ld	b,a
	ld	a,(personaje_2)
	dec	a
[2]	sla	a
	add	b
	ld	b,a
	ld	a,(incremento_velocidad_2)
	and	00000011b	
	add	b
	ld	(ix+5),a
	
BYTE_7:

	ld	a,(incremento_ataque_2)
[6]	sla	a
	and	11000000b
	ld	b,a
	ld	a,(incremento_defensa_2)
[4]	sla	a
	and	00110000b
	add	b
	ld	b,a
	ld	a,(incremento_ataque_origen2)
[2]	sla	a
	add	b
	ld	b,a	
	ld	a,(incremento_defensa_origen2)	
	add	b
	ld	(ix+6),a
	
BYTE_8:

	ld	a,(incremento_velocidad_origen1)
[6]	sla	a
	ld	b,a
	ld	a,(incremento_velocidad_origen2)
[4]	sla	a
	add	b
	ld	(ix+7),a
	
	

BYTE_9_y_10:

	ld	hl,(posicion_en_mapa_1)
	ld	(ix+8),l
	ld	(ix+9),h
	
BYTE_11_y_12:

	ld	hl,(posicion_en_mapa_2)
	ld	(ix+10),l
	ld	(ix+11),h
	
BYTE_13:

	ld	a,(orientacion_del_personaje_1)
[6]	sla	a
	ld	b,a
	ld	a,(orientacion_del_personaje_2)
[4]	sla	a
	add b
	ld	b,a
	ld	a,(bitneda_unidades1)
	add	b
	ld	(ix+12),a
	
BYTE_14:

	ld	a,(bitneda_decenas1)
[4]	sla	a
	ld	b,a
	ld	a,(bitneda_centenas1)
	add	b
	ld	(ix+13),a
	
BYTE_15:

	ld	a,(bitneda_decenas2)
[4]	sla	a
	ld	b,a
	ld	a,(bitneda_centenas2)
	add	b
	ld	(ix+14),a
	
BYTE_16:

	ld	a,(estandarte_1)
	dec	a
[5]	sla	a
	and	11100000b
	ld	b,a
	ld	a,(bitneda_unidades2)
	sla	a	
	and	00011110b
	add	b
	ld	b,a
	ld	a,(incremento_velocidad_1)
[2]	sra	a
	and	00000001b
	add	b
	ld	(ix+15),a
	
BYTE_17:

	ld	a,(vida_unidades1)
[4]	sla	a
	ld	b,a
	ld	a,(vida_decenas1)
	add	b
	ld	(ix+16),a
	
BYTE_18:

	ld	a,(vida_unidades2)
[4]	sla	a
	ld	b,a
	ld	a,(vida_decenas2)
	add	b
	ld	(ix+17),a
	
BYTE_20:

	ld	a,(trampa1)
[4]	sla	a
	ld	b,a
	ld	a,(trampa2)
	add	b
	ld	(ix+19),a
	
BYTE_21:

	ld	a,(gallina1)
[4]	sla	a
	ld	b,a
	ld	a,(gallina2)
	add	b
	ld	(ix+20),a

BYTE_23:

	ld	a,(x_map_1)
	ld	(ix+22),a
	
BYTE_24:

	ld	a,(y_map_1)
	ld	(ix+23),a
	
BYTE_25:

	ld	a,(x_map_2)
	ld	(ix+24),a
	
BYTE_26:

	ld	a,(y_map_2)
	ld	(ix+25),a
				
BYTE_19:

	ld	a,(estandarte_2)
	dec	a
[5]	sla	a

	push	af
	
	call	CONFIGURAMOS_EL_CODIGO

	JP		SEGUIMOS_CON_19
	
CONFIGURAMOS_EL_CODIGO:
	
	ld	a,(ix)
	ld	b,a
	ld	a,(ix+1)
	add	b
	ld	b,a
	ld	a,(ix+2)
	add	b
	ld	b,a
	ld	a,(ix+3)
	add	b
	ld	b,a
	ld	a,(ix+4)
	add	b
	ld	b,a
	ld	a,(ix+5)
	add	b
	ld	b,a
	ld	a,(ix+6)
	add		b
	ld		b,a
	ld		a,(ix+7)
	add		b
	ld		b,a
	ld		a,(ix+8)
	add		b
	ld		b,a
	ld		a,(ix+9)
	add		b
	ld		b,a
	ld		a,(ix+10)
	add		b
	ld		b,a
	ld		a,(ix+11)
	add		b
	ld		b,a
	ld		a,(ix+12)
	add		b
	ld		b,a
	ld		a,(ix+13)
	add		b
	ld		b,a
	ld		a,(ix+14)
	add		b
	ld		b,a
	ld		a,(ix+15)
	add		b
	ld		b,a
	ld		a,(ix+16)
	add		b
	ld		b,a
	ld		a,(ix+17)
	add		b
	ld		b,a
	ld		a,(ix+19)
	add		b
	ld		b,a
	ld		a,(ix+20)
	add		b
	ld		b,a
	ld		a,(ix+22)
	add		b
	ld		b,a
	ld		a,(ix+23)
	add		b
	ld		b,a
	ld		a,(ix+24)
	add		b
	ld		b,a
	ld		a,(ix+25)
	add		b
		
	RET

SEGUIMOS_CON_19:

	and		00011111b
	ld		b,a
	pop		af
	add		b
	ld		(ix+18),a
	
BYTE_22:

	ld		a,(incremento_velocidad_2)
[5]	sla		a
	and		10000000b
	ld		b,a

	ld		a,(incremento_ataque_1)
[4]	sla		a
	and		01000000b
	ld		b,a	

	ld		a,(incremento_defensa_1)
[3]	sla		a
	and		00100000b
	ld		b,a

	ld		a,(incremento_ataque_2)
[2]	sla		a
	and		00010000b
	ld		b,a
	
	ld		a,(incremento_defensa_2)
	sla		a
	and		00001000b
	ld		b,a	

	push	af
	call	CONFIGURAMOS_EL_CODIGO

	and		11100000b
[5]	sra		a
	ld		b,a
	pop		af
	add		b
	ld		(ix+21),a
				
	RET

VARIABLES_DEL_JUGADOR_1_POR_CODIGO:
		
		ld		ix,codigo_salve
		inc		ix
		
		;byte 2
		
		ld		a,(ix)
		and		00000001b
		ld		(botas_esp1),a
		ld		a,(ix)
		srl		a		
		and		00000001b
		ld		(botas1),a
		ld		a,(ix)
[2]		srl		a		
		and		00000001b
		ld		(lupa_1),a
		ld		a,(ix)
[3]		srl		a		
		and		00000001b
		ld		(llave1),a
		ld		a,(ix)
[4]		srl		a		
		and		00000001b
		ld		(tinta1),a
		ld		a,(ix)
[5]		srl		a		
		and		00000001b
		ld		(pluma1),a
		ld		a,(ix)
[6]		srl		a		
		and		00000001b
		ld		(papel1),a
		ld		a,(ix)
[7]		srl		a		
		and		00000001b
		ld		(brujula1),a

		inc		ix
		
		; byte 3
		
		ld		a,(ix)
		and		00000011b
		ld		(incremento_velocidad_1),a
		ld		a,(ix)					
[4]		srl		a		
		and		00000001b
		ld		(casco1),a
		ld		a,(ix)
[5]		srl		a		
		and		00000001b
		ld		(armadura1),a
		ld		a,(ix)
[6]		srl		a		
		and		00000001b
		ld		(espada1),a
				ld		a,(ix)
[7]		srl		a		
		and		00000001b
		ld		(cuchillo1),a

		inc		ix
		
		;byte 4
		
		ld		a,(ix)
		and		00000011b
		ld		(incremento_defensa_origen1),a
		ld		a,(ix)
[2]		srl		a
		and		00000011b
		ld		(incremento_ataque_origen1),a
		ld		a,(ix)
[4]		srl		a
		and		00000011b
		ld		(incremento_defensa_1),a
		ld		a,(ix)
[6]		srl		a
		and		00000011b			
		ld		(incremento_ataque_1),a

[4]		inc		ix
		
		;byte 8
		
		ld		a,(ix)
[6]		srl		a
		and		00000011b
		ld		(incremento_velocidad_origen1),a

		inc		ix
		
		;byte 9 y 10
		
		ld		l,(ix)
		ld		h,(ix+1)
		ld		(posicion_en_mapa_1),hl
		
[4]		inc		ix

		;byte 13
		
		ld		a,(ix)
		and		00001111b
		ld		(bitneda_unidades1),a
		ld		a,(ix)
[6]		srl		a
		and		00000011b
		ld		(orientacion_del_personaje_1),a
		
		inc		ix
		
		;byte 14
		
		ld		a,(ix)
		and		00001111b
		ld		(bitneda_centenas1),a
		ld		a,(ix)		
[4]		srl		a
		and		00001111b
		ld		(bitneda_decenas1),a

[2]		inc		ix

		;byte 16

		ld		a,(ix)
[2]		sll		a
		and		00000100b
		ld		b,a
		ld		a,(incremento_velocidad_1)
		add		b
		ld		(incremento_velocidad_1),a
		
[1]		inc		ix		
		
		;byte 17
		
		ld		a,(ix)
		and		00001111b
		ld		(vida_decenas1),a
		ld		a,(ix)		
[4]		srl		a
		and		00001111b
		ld		(vida_unidades1),a

[3]		inc		ix
		
		;byte 20
		
		ld		a,(ix)
		and		00001111b
		ld		(trampa1),a

		inc		ix
		
		;byte 21
		
		ld		a,(ix)
		and		00001111b
		ld		(gallina1),a

		inc		ix
		
		;byte 22
		
		ld		a,(ix)
[4]		srl		a
		and		00000100b
		ld		b,a
		ld		a,(incremento_ataque_1)
		add		b
		ld		(incremento_ataque_1),a

		ld		a,(ix)
[3]		srl		a
		and		00000100b
		ld		b,a
		ld		a,(incremento_defensa_1)
		add		b
		ld		(incremento_defensa_1),a
		
		inc		ix
		
		;byte	23
		
		ld		a,(ix)
		ld		(x_map_1),a

		inc		ix
		
		;byte	24
		
		ld		a,(ix)
		ld		(y_map_1),a	
									
		ret
		
VARIABLES_DEL_JUGADOR_2_POR_CODIGO:

		
		ld		ix,codigo_salve
						
[4]		inc		ix
				
		;byte 5
		
		ld		a,(ix)
		and		00000001b
		ld		(botas_esp2),a
		ld		a,(ix)
		srl		a		
		and		00000001b
		ld		(botas2),a
		ld		a,(ix)
[2]		srl		a		
		and		00000001b
		ld		(lupa_2),a
		ld		a,(ix)
[3]		srl		a		
		and		00000001b
		ld		(llave2),a
		ld		a,(ix)
[4]		srl		a		
		and		00000001b
		ld		(tinta2),a
		ld		a,(ix)
[5]		srl		a		
		and		00000001b
		ld		(pluma2),a
		ld		a,(ix)
[6]		srl		a		
		and		00000001b
		ld		(papel2),a
		ld		a,(ix)
[7]		srl		a		
		and		00000001b
		ld		(brujula2),a

		inc		ix
		
		;byte 6

		ld		a,(ix)
		and		00000011b
		ld		(incremento_velocidad_2),a
		ld		a,(ix)					
[4]		srl		a		
		and		00000001b
		ld		(casco2),a
		ld		a,(ix)
[5]		srl		a		
		and		00000001b
		ld		(armadura2),a
		ld		a,(ix)
[6]		srl		a		
		and		00000001b
		ld		(espada2),a
				ld		a,(ix)
[7]		srl		a		
		and		00000001b
		ld		(cuchillo2),a

		inc		ix
		
		;byte 7
		
		ld		a,(ix)
		and		00000011b
		ld		(incremento_defensa_origen2),a
		ld		a,(ix)
[2]		srl		a
		and		00000011b
		ld		(incremento_ataque_origen2),a
		ld		a,(ix)
[4]		srl		a
		and		00000011b
		ld		(incremento_defensa_2),a
		ld		a,(ix)
[6]		srl		a
		and		00000011b			
		ld		(incremento_ataque_2),a

		inc		ix
		
		;byte 8
		
		ld		a,(ix)
[4]		srl		a
		and		00000011b
		ld		(incremento_velocidad_origen2),a
		
[3]		inc		ix

		;byte 11 y 12
		
		ld		l,(ix)
		ld		h,(ix+1)
		ld		(posicion_en_mapa_2),hl
		
[2]		inc		ix

		;byte 13
		
		ld		a,(ix)
[4]		srl		a
		and		00000011b
		ld		(orientacion_del_personaje_2),a

[2]		inc		ix
		
		;byte 15
		
		ld		a,(ix)
		and		00001111b
		ld		(bitneda_centenas2),a
		ld		a,(ix)		
[4]		srl		a
		and		00001111b
		ld		(bitneda_decenas2),a

		inc		ix
		
		;byte 16
		
		ld		a,(ix)
		srl		a		
		and		00001111b
		ld		(bitneda_unidades2),a

[2]		inc		ix
		
		;byte 18
		
		ld		a,(ix)
		and		00001111b
		ld		(vida_decenas2),a
		ld		a,(ix)		
[4]		srl		a
		and		00001111b
		ld		(vida_unidades2),a

[2]		inc		ix
		
		;byte 20
		
		ld		a,(ix)		
		and		00001111b
		ld		(trampa2),a

		inc		ix
		
		;byte 21

		ld		a,(ix)		
		and		00001111b
		ld		(gallina2),a

		inc		ix
		
		;byte 22
		
		ld		a,(ix)
[5]		srl		a
		and		00000100b
		ld		b,a
		ld		a,(incremento_velocidad_2)
		add		b
		ld		(incremento_velocidad_2),a

		ld		a,(ix)
[2]		srl		a
		and		00000100b
		ld		b,a
		ld		a,(incremento_ataque_2)
		add		b
		ld		(incremento_ataque_2),a

		ld		a,(ix)
		srl		a
		and		00000100b
		ld		b,a
		ld		a,(incremento_defensa_2)
		add		b
		ld		(incremento_defensa_2),a

[3]		inc		ix
		
		;byte	25
		
		ld		a,(ix)
		ld		(x_map_2),a

		inc		ix
		
		;byte	26
		
		ld		a,(ix)
		ld		(y_map_2),a	
						
		ret
																		
OBJETOS_DEL_JUGADOR_1_POR_CODIGO:

.brujula1:
		
		ld		a,(brujula1)
		or		a
		jp		z,.papel1
		
		ld		iy,copia_brujula_en_objetos1								; pintamos la brújula pero en el decorado
		CALL	COPY_DE_OBJETO_7				

.papel1:
		
		ld		a,(papel1)
		or		a
		jp		z,.pluma1
		
		ld		iy,copia_papel_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.pluma1:

		ld		a,(pluma1)
		or		a
		jp		z,.tinta1		
		ld		iy,copia_pluma_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.tinta1:

		ld		a,(tinta1)
		or		a
		jp		z,.llave1		
		ld		iy,copia_tinta_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.llave1:

		ld		a,(llave1)
		or		a
		jp		z,.lupa_1		
		ld		iy,copia_llave_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.lupa_1:

		ld		a,(lupa_1)
		or		a
		jp		z,.botas1		
		ld		iy,copia_lupa_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.botas1:

		ld		a,(botas1)
		or		a
		jp		z,.botas_esp1		
		ld		iy,copia_botas_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.botas_esp1:

		ld		a,(botas_esp1)
		or		a
		jp		z,.cuchillo1		
		ld		iy,copia_botas_esp_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.cuchillo1:

		ld		a,(cuchillo1)
		or		a
		jp		z,.espada1		
		ld		iy,copia_cuchillo_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.espada1:

		ld		a,(espada1)
		or		a
		jp		z,.armadura1		
		ld		iy,copia_espada_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.armadura1:

		ld		a,(armadura1)
		or		a
		jp		z,.casco1		
		ld		iy,copia_armadura_en_objetos1		
		CALL	COPY_DE_OBJETO_7

.casco1:

		ld		a,(casco1)
		or		a
		ret		z		
		ld		iy,copia_casco_en_objetos1		
		jp		COPY_DE_OBJETO_7	

COPY_DE_OBJETO_7:

		CALL	COPY_A_GUSTO_7
		
		ld		a,10010000b												; nos aseguramos que copia mediante LMMM
		ld		(ix+14),a
		
		ld		hl,datos_del_copy
		call	DoCopy_7
		
		ret

OBJETOS_DEL_JUGADOR_2_POR_CODIGO:


.brujula2:

		ld		a,(brujula2)
		or		a
		jp		z,.papel2
		
		ld		iy,copia_brujula_en_objetos2								; pintamos la brújula pero en el decorado
		CALL	COPY_DE_OBJETO_7				

.papel2:
		
		ld		a,(papel2)
		or		a
		jp		z,.pluma2
		
		ld		iy,copia_papel_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.pluma2:

		ld		a,(pluma2)
		or		a
		jp		z,.tinta2		
		ld		iy,copia_pluma_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.tinta2:

		ld		a,(tinta2)
		or		a
		jp		z,.llave2		
		ld		iy,copia_tinta_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.llave2:

		ld		a,(llave2)
		or		a
		jp		z,.lupa_2		
		ld		iy,copia_llave_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.lupa_2:

		ld		a,(lupa_2)
		or		a
		jp		z,.botas2		
		ld		iy,copia_lupa_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.botas2:

		ld		a,(botas2)
		or		a
		jp		z,.botas_esp2		
		ld		iy,copia_botas_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.botas_esp2:

		ld		a,(botas_esp2)
		or		a
		jp		z,.cuchillo2		
		ld		iy,copia_botas_esp_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.cuchillo2:

		ld		a,(cuchillo2)
		or		a
		jp		z,.espada2	
		ld		iy,copia_cuchillo_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.espada2:

		ld		a,(espada2)
		or		a
		jp		z,.armadura2		
		ld		iy,copia_espada_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.armadura2:

		ld		a,(armadura2)
		or		a
		jp		z,.casco2		
		ld		iy,copia_armadura_en_objetos2		
		CALL	COPY_DE_OBJETO_7

.casco2:

		ld		a,(casco2)
		or		a
		RET		Z
		ld		iy,copia_casco_en_objetos2		
		jp		COPY_DE_OBJETO_7

CARGAMOS_OBJETOS_DE_LA_TIENDA:

		ld		a,r
		and		00000101b
		ld		(tienda_objeto_2),a
		inc		a
		call	BUCLE_DE_CONTROL_DE_COINCIDENCIA
		ld		(tienda_objeto_3),a

		inc		a
		call	BUCLE_DE_CONTROL_DE_COINCIDENCIA
		ld		(tienda_objeto_4),a

		ld		a,r
		and		00000100b	
		ld		(tienda_objeto_5),a
		
		ret

BUCLE_DE_CONTROL_DE_COINCIDENCIA:

		cp		6
		ret		nz
		
		xor		a
		ret		
				
copia_brujula_en_objetos1:						dw		#0001,#0272,#0037,#0080,#000d,#000d
copia_papel_en_objetos1:						dw		#0010,#0272,#0044,#0080,#000c,#000d
copia_tinta_en_objetos1:						dw		#002b,#0272,#0050,#0080,#000d,#000d
copia_pluma_en_objetos1:						dw		#001e,#0272,#005c,#0080,#000c,#000d
copia_llave_en_objetos1:						dw		#0039,#0272,#0068,#0080,#000d,#000d
copia_lupa_en_objetos1:							dw		#0048,#0272,#0076,#0080,#000c,#000d
copia_botas_en_objetos1:						dw		#0056,#0272,#0037,#008C,#000C,#000d
copia_botas_esp_en_objetos1:					dw		#0064,#0272,#0037,#008C,#000C,#000d
copia_cuchillo_en_objetos1:						dw		#0071,#0272,#0044,#008C,#000C,#000d
copia_espada_en_objetos1:						dw		#007f,#0272,#0044,#008C,#000d,#000d
copia_armadura_en_objetos1:						dw		#0001,#0280,#0050,#008C,#000C,#000d
copia_casco_en_objetos1:						dw		#0010,#0280,#005c,#008C,#000C,#000d

copia_brujula_en_objetos2:						dw		#0001,#0272,#00c0,#0080,#000d,#000d
copia_papel_en_objetos2:						dw		#0010,#0272,#00b2,#0080,#000c,#000d
copia_tinta_en_objetos2:						dw		#002b,#0272,#00a5,#0080,#000d,#000d
copia_pluma_en_objetos2:						dw		#001e,#0272,#009a,#0080,#000c,#000d
copia_llave_en_objetos2:						dw		#0039,#0272,#008d,#0080,#000d,#000d
copia_lupa_en_objetos2:							dw		#0048,#0272,#0082,#0080,#000c,#000d
copia_botas_en_objetos2:						dw		#0056,#0272,#00c0,#008C,#000C,#000d
copia_botas_esp_en_objetos2:					dw		#0064,#0272,#00c0,#008C,#000C,#000d
copia_cuchillo_en_objetos2:						dw		#0071,#0272,#00b2,#008C,#000C,#000d
copia_espada_en_objetos2:						dw		#007f,#0272,#00b2,#008C,#000d,#000d
copia_armadura_en_objetos2:						dw		#0001,#0280,#00a5,#008C,#000C,#000d
copia_casco_en_objetos2:						dw		#0010,#0280,#009a,#008C,#000C,#000d	
							
		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 53 DEL MEGAROM **********)))	

; ______________________________________________________________________	
																																				

; (((********** PAGINA 54 DEL MEGAROM **********

; DIBUJO DE MAPA PARTE 1

		org		#8000
		
COPIAMOS_PERGAMINO_1:				incbin		"SR5/MAPA/PERGAMINO_256X211.DAT1"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 54 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 55 DEL MEGAROM **********

; SPRITES

		org		#8000

				include		"SPRITES/SPRITES.asm"					
				include		"SPRITES/COLORES.asm"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 55 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 56 DEL MEGAROM **********

; GRÁFICO ESTANCIA PELEA

		org		#8000

ESTANCIA_PELEA:	incbin		"SR5/LABERINTO/ESTANCIA DE PELEA_194x112.DAT"					

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 56 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 57 DEL MEGAROM **********

; CARAS TROMAXE

		org		#8000

TROMAXE_CARAS:	incbin		"SR5/COTORRAS/tromaxe_172x42.DAT"
ONIRIKUS_CARAS:	incbin		"SR5/COTORRAS/ONIRIKUS_172x42.DAT"
VIDA_CORAZON:	incbin		"SR5/COTORRAS/CORAZON_40x19.DAT"
VIDA_CULO:		incbin		"SR5/COTORRAS/CULO_40x19.DAT"
SALGUERI_CARAS:	incbin		"SR5/COTORRAS/SALGUERI_172x42.DAT"
LUCKY_CARAS:	incbin		"SR5/COTORRAS/LUCKYLUKEB_172x42.DAT"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 57 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 58 DEL MEGAROM **********

; COMIC DESPEDIDA 1

		org		#8000
		
COM_DESP1:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT01"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 58 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 59 DEL MEGAROM **********

; COMIC DESPEDIDA 2

		org		#8000
		
COM_DESP2:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT02"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 59 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 60 DEL MEGAROM **********

; COMIC DESPEDIDA 3

		org		#8000
		
COM_DESP3:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT03"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 60 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 61 DEL MEGAROM **********

; COMIC DESPEDIDA 4

		org		#8000
		
COM_DESP4:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT04"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 61 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 62 DEL MEGAROM **********

; COMIC DESPEDIDA 5

		org		#8000
		
COM_DESP5:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT05"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 62 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 63 DEL MEGAROM **********

; COMIC DESPEDIDA 6

		org		#8000
		
COM_DESP6:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT06"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 63 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 64 DEL MEGAROM **********

; COMIC DESPEDIDA 7

		org		#8000
		
COM_DESP7:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT07"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 64 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 65 DEL MEGAROM **********

; COMIC DESPEDIDA 8

		org		#8000
		
COM_DESP8:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT08"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 65 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 66 DEL MEGAROM **********

; COMIC DESPEDIDA 9

		org		#8000
		
COM_DESP9:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERRE.DAT09"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 66 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 67 DEL MEGAROM **********

; COMIC DESPEDIDA 1

		org		#8000
		
COM_CRE1:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT01"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 67 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 68 DEL MEGAROM **********

; COMIC CREDITOS 2

		org		#8000
		
COM_CRE2:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT02"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 68 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 69 DEL MEGAROM **********

; COMIC CREDITOS 3

		org		#8000
		
COM_CRE3:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT03"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 69 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 70 DEL MEGAROM **********

; COMIC CREDITOS 4

		org		#8000
		
COM_CRE4:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT04"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 70 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 71 DEL MEGAROM **********

; COMIC CREDITOS 5

		org		#8000
		
COM_CRE5:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT05"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 71 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 72 DEL MEGAROM **********

; COMIC CREDITOS 6

		org		#8000
		
COM_CRE6:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT06"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 72 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 73 DEL MEGAROM **********

; COMIC CREDITOS 7

		org		#8000
		
COM_CRE7:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT07"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 73 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 74 DEL MEGAROM **********

; COMIC CREDITOS 8

		org		#8000
		
COM_CRE8:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT08"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 74 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 75 DEL MEGAROM **********

; COMIC CREDITOS 9

		org		#8000
		
COM_CRE9:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT09"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 75 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 76 DEL MEGAROM **********

; COMIC CREDITOS 10

		org		#8000
		
COM_CRE10:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT10"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 76 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 77 DEL MEGAROM **********

; COMIC CREDITOS 11

		org		#8000
		
COM_CRE11:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT11"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 77 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 78 DEL MEGAROM **********

; COMIC CREDITOS 12

		org		#8000
		
COM_CRE12:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT12"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 78 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 79 DEL MEGAROM **********

; COMIC CREDITOS 13

		org		#8000
		
COM_CRE13:							incbin		"SR5/COMICS/CREDITOS/CREDITOS.DAT13"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 79 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 80 DEL MEGAROM **********

; COMIC CREDITOS 13

		org		#8000
		
MUSICA_COTORRA:							incbin		"MUSICAS/LUCHAHUMOR.mbm"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 80 DEL MEGAROM **********)))	

; ______________________________________________________________________
; (((********** PAGINA 81 DEL MEGAROM **********

; COMIC CREDITOS 13

		org		#8000
		
MUSICA_CONVERS:							incbin		"MUSICAS/CONVERSACION.mbm"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 81 DEL MEGAROM **********)))	

; ______________________________________________________________________

; (((********** PAGINA 82 DEL MEGAROM **********
	
; ESCRIBIR TEXTOS	

		org		#8000													;esto define dónde se empieza a escribir el bloque (page 1)

ESCRIBIMOS_CODIGO_81:

		CALL	LIMPIEZA
		ld		a,1
		ld		(var_cuentas_peq),a
		
ESCRIBIMOS_CODIGO_2_81:

		ld		a,(iy)													; Leemos primera letra del bloque de 3 letras que suponen los 2 bytes												
		and		11110000b												; 0XXXXX00 00000000
[4]		srl		a
		ld		de, POINT_CODIGO
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		a,(iy)													; Leemos primera letra del bloque de 3 letras que suponen los 2 bytes												
		and		00001111b
		ld		de, POINT_CODIGO
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		inc		iy
		push	iy
		pop		de
		
		ld		a,(var_cuentas_peq)
		inc		a
		ld		(var_cuentas_peq),a

		cp		3
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		5
		call	z,FINAL_DE_LETRAS_GENERAL
		
		cp		7
		call	z,FINAL_DE_LETRAS_GENERAL
		
		cp		9
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		11
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		13
		call	z,FINAL_DE_LETRAS_GENERAL
						
		cp		14	
		call	z,LIMPIEZA_INTERMEDIA

		cp		16
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		18
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		20
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		22
		call	z,FINAL_DE_LETRAS_GENERAL

		cp		24
		call	z,FINAL_DE_LETRAS_GENERAL
		cp		26
		call	z,FINAL_DE_LETRAS_GENERAL	
					
		cp		27
		ret		z
		
		push	de
		pop		iy
		jp		ESCRIBIMOS_CODIGO_2

LIMPIEZA_INTERMEDIA_81:

		call	LIMPIEZA

		ld		a,(ix+4)
		sub		2
		add		2
		
		ld		(ix+4),a
		ret
				
ESCRIBIMOS_EL_NOMBRE_DEL_PROTA_81:

		ld		a,(personaje)
		dec		a
		ld		de, POINT_ESCRIBE_NOMBRE
		call	lista_de_opciones
		
ESCRIBIMOS_EN_GENERAL_81:

		CALL	LIMPIEZA
		JP		ESCRIBIMOS_EN_GENERAL_2
		
LIMPIEZA_81:
		
		ld		iy,copia_texto_para_arriba
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		iy,cuadrado_texto_para_arriba
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		a,10
		ld		(ralentizando),a
		call	RALENTIZA
		
		ld		iy,copia_inicio_texto									;copiamos en la page 0 lo construído en la page 1
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a	
		
		ld		iy,secuencia_de_letras
		ld		a,(iy)
		
		RET
		
ESCRIBIMOS_EN_GENERAL_2_81:

		ld		a,(iy)													; Leemos primera letra del bloque de 3 letras que suponen los 2 bytes												
		and		01111100b												; 0XXXXX00 00000000
[2]		srl		a
		ld		de, POINT_LETRAS
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,(iy)													; Leemos segunda letra, la parte que está en el primer byte
		and		00000011b												; 000000XX 00000000
[3]		rlc		a														; Lo colocamos en posición adecuada 000XX000
		ld		b,a				
		inc		iy
		ld		a,(iy)													; Colocamos segunda letra, la parte que está en el segundo byte
[5]		srl		a														; de XXX00000  a 000000XX	
		add		b														;Le añadimos la parte adecuada del otro byte 000XX000 + 000000XX = 000XXXXX
		ld		de, POINT_LETRAS
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		a,(iy)													; leemos tercera letra, que está en el segundo byte
		and		00011111b												; 000XXXXX
		ld		de, POINT_LETRAS
		call	lista_de_opciones

		ld		a,10011000b
		ld		(ix+14),a	
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		dec		iy
		ld		a,(iy)
		and		10000000b
		rlc		a
		cp		1
		call	z,PASA_CARRO
		
[2]		inc		iy
		
		jp		ESCRIBIMOS_EN_GENERAL_2

cuadrado_texto_para_arriba_81:						dw		#0000,#0000,#0036,#00a2,#0096,#0009
copia_inicio_texto_81:								dw		#0000,#0000,#0036,#00a2,#0006,#0009
copia_texto_para_arriba_81:						dw		#0036,#00a2,#0036,#009a,#0096,#0008
				
ESPACIO_81:

		ld		c,98
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,144
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

A_81:

		ld		c,0
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
B_81:

		ld		c,8
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
C_81:

		ld		c,16
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
D_81:

		ld		c,24
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
E_81:

		ld		c,32
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
F_81:

		ld		c,40
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

G_81:

		ld		c,48
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
H_81:

		ld		c,56
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
I_81:

		ld		c,64
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
J_81:

		ld		c,72
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,155
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

K_81:

		ld		c,0
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
L_81:

		ld		c,8
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
M_81:

		ld		c,16
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
N_81:

		ld		c,24
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
O_81:

		ld		c,32
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
P_81:

		ld		c,40
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

Q_81:

		ld		c,48
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
R_81:

		ld		c,56
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
S_81:

		ld		c,64
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
T_81:

		ld		c,72
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,163
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
U_81:

		ld		c,0
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
V_81:

		ld		c,8
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
W_81:

		ld		c,16
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
X_81:

		ld		c,24
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
Y_81:

		ld		c,32
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
		
Z_81:

		ld		c,40
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL

DOS_PUNTOS_81:

		ld		c,48
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		jp		FINAL_DE_LETRAS_GENERAL
PUNTO_81:

		ld		c,72
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,171
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
					
		jp		FINAL_DE_LETRAS_GENERAL
		
ACENTO_81:

		ld		c,56
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,172
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		ret
		
RABITO_N_81:

		ld		c,64
		ld		b,0
		ld		(ix),c												
		ld		(ix+1),b

		ld		c,172
		ld		b,#02
		ld		(ix+2),c												
		ld		(ix+3),b
		
		ret
		
PASA_CARRO_81:

		pop		af														;sacamos de la pila el dato que nos devuelve a continuar escribiendo

		ret
			
STRIG_DE_CONTINUE_81:	
		
		ld		de,PULSA_ESPACIO
		ld		hl,copia_pulsa_espacio									; dibujamos la flecha de espera
		call	ESPERA_AL_VDP_HMMC

			

.EL_STRIG:

		xor		a
		CALL	GTTRIG
		cp		255
		jp		z,.EL_REGRESO_teclado											;volvemos al programa general

		ld		a,(turno)
		CALL	GTTRIG
		cp		255
		jp		z,.EL_REGRESO_mando											;volvemos al programa general
		
		ld		a,7														
		call	SNSMAT
		bit		7,a
		jp		z,.EL_REGRESO_intro
		
		jp		.EL_STRIG

.EL_REGRESO_teclado:

		xor		a
		call	GTTRIG
		cp		255		
		jp		nz,.EL_REGRESO
		jp		.EL_REGRESO_teclado

.EL_REGRESO_mando:

		ld		a,(turno)
		call	GTTRIG
		cp		255		
		jp		nz,.EL_REGRESO
		jp		.EL_REGRESO_mando
		
.EL_REGRESO_intro:

		ld		a,7														
		call	SNSMAT
		bit		7,a
		jp		nz,.EL_REGRESO
		jp		.EL_REGRESO_intro
				
.EL_REGRESO:

		ld		iy,cuadrado_que_limpia_PULSA_ESPACIO					; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,10010000b
		ld		(ix+14),a							

		ret
		
STRIG_DE_CONTINUE_CAMBIO_DE_JUGADOR_81:	
		
		ld		de,PULSA_ESPACIO
		ld		hl,copia_pulsa_espacio									; dibujamos la flecha de espera
		call	ESPERA_AL_VDP_HMMC

			

.EL_STRIG:

		xor		a
		CALL	GTTRIG
		cp		255
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa space

		ld		a,(1)
		CALL	GTTRIG
		cp		255
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa boton A mando 1

		ld		a,(2)
		CALL	GTTRIG
		cp		255
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa boton A mando 2
				
		ld		a,7														
		call	SNSMAT
		bit		7,a
		jp		z,STRIG_DE_CONTINUE.EL_REGRESO							;volvemos al programa general si pulsa intro
		
		jp		.EL_STRIG
				

FINAL_DE_LETRAS_GENERAL_81:

		ld		a,(ix+4)
		add		4
		ld		(ix+4),a
		
		ret
					
HOLA_EN_POCHADA_FINAL_81:

		ld		ix,HOLA_POCHADA_2_ESP
		jp		COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER

PASAR_LA_NOCHE_81:

		ld		hl,PASAR_LA_NOCHE_ESP		
		RET

PAGA_30_81:

		ld		hl,PAGA_30_ESP
		RET

PAGA_60_81:

		ld		hl,PAGA_60_ESP
		RET
				
PAGA_90_81:

		ld		hl,PAGA_90_ESP
		RET

SALIR_DE_POSADA_81:

		ld		hl,SALIR_ESP
		RET

BUENAS_NOCHES_81:

		ld		ix,BUENAS_NOCHES_ESP
		jp		COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER

BRUJULA_EXPLICADA_81:

		ld		hl,BRUJULA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,BRUJULA_2_ESP
		RET

PAPIRO_EXPLICADO_81:

		ld		hl,PAPIRO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PAPIRO_2_ESP
		RET

PLUMA_EXPLICADA_81:

		ld		hl,PLUMA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PLUMA_2_ESP
		RET

HABLA_DE_POCHADA_81:

		ld		hl,VIEJIGUIA_POCHADA_ESP
		RET
		
HABLA_DE_SALIDA_81:

		ld		hl,VIEJIGUIA_SALIDA_ESP
		RET
		
HABLA_DE_LLAVE_81:

		ld		hl,VIEJIGUIA_LLAVE_ESP
		RET

NORTE_81:
		
		ld		hl,N_ESP		
		jp		COMUN_VIEJIGUIA
		
NORESTE_81:

		ld		hl,NE_ESP		
		jp		COMUN_VIEJIGUIA
		
ESTE_81:

		ld		hl,E_ESP		
		jp		COMUN_VIEJIGUIA
		
SURESTE_81:

		ld		hl,SE_ESP		
		jp		COMUN_VIEJIGUIA

SUR_81:

		ld		hl,S_ESP		
		jp		COMUN_VIEJIGUIA
		
SUROESTE_81:

		ld		hl,SO_ESP		
		jp		COMUN_VIEJIGUIA

OESTE_81:

		ld		hl,O_ESP		
		jp		COMUN_VIEJIGUIA
		
NOROESTE_81:		

		ld		hl,NO_ESP		
		jp		COMUN_VIEJIGUIA
				
NATPU_81:

		ld		hl,NOMBRE_NATPU_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

	
FERGAR_81:

		ld		hl,NOMBRE_FERGAR_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

	
CRIRA_81:

		ld		hl,NOMBRE_CRIRA_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

	
VICMAR_81:

		ld		hl,NOMBRE_VICMAR_ESP
		jp		PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE

NO_PASA_NADA_81:

		ld		a,(cantidad_de_jugadores)
		cp		1
		ret		z
		
		ld		hl,FIN_DE_TURNO_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		jp		TEXTO_A_ESCRIBIR

ENCUENTRA_BRUJULA_81:

		ld		a,(brujula)												;si ya la tiene, pasa de largo
		or		a
		ret		nz
		
		ld		a,1														;le damos la brújula al jugador
		ld		(brujula),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
				
		ld		iy,copia_brujula_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla


		call	EXPLICACION_BRUJULA
		jp		ENCUENTRA_BRUJULA_CONTINUACION
		
EXPLICACION_BRUJULA_81:

		call	BRUJULA_EXPLICADA
		jp		TEXTO_A_ESCRIBIR
		
ENCUENTRA_BRUJULA_CONTINUACION_81:
						
		ld		iy,copia_brujula_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO				
		call	COMPRUEBA_TURNO_EN_OBJETO
		
		ld		c,#C0													;corregimos la posición de la brújula para el jugador 2

ENCUENTRA_BRUJULA_1_5_81:

		PUSH	af														;empujamos a la pila un valor para compensar el que sacamos despues de un call
		
		ld		b,#00
		ld		(ix+4),c
		ld		(ix+5),b
		
		jp		ENCUENTRA_BRUJULA_2_5
		
ENCUENTRA_PAPEL_81:

		ld		a,(papel)												;si ya la tiene, pasa de largo
		or		a
		ret		nz
		
		ld		a,1														;le damos la brújula al jugador
		ld		(papel),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a

		ld		iy,copia_papel_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		call	PAPIRO_EXPLICADO

		call	TEXTO_A_ESCRIBIR
				
		ld		iy,copia_papel_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO
		
		call	COMPRUEBA_TURNO_EN_OBJETO_2
	
		ld		c,#b2													;corregimos la posición de la brújula para el jugador 2
		
		jp		ENCUENTRA_BRUJULA_1_5
		
ENCUENTRA_PLUMA_81:

		ld		a,(pluma)												;si ya la tiene, pasa de largo
		or		a
		ret		nz
		
		ld		a,1														;le damos la brújula al jugador
		ld		(pluma),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a


		ld		iy,copia_pluma_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		call	PLUMA_EXPLICADA

		call	TEXTO_A_ESCRIBIR
						
		ld		iy,copia_pluma_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO
		
		call	COMPRUEBA_TURNO_EN_OBJETO_2
			
		ld		c,#9a													;corregimos la posición de la brújula para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_VIEJIGUIA_81:
		
		ld		a,r														; decide qué viejiguia va a hablar
		and		00000011b		
		ld		(pagina_hater),a
		
		cp		0
		jp		z,.VIEJI1
		cp		1
		jp		z,.VIEJI2	
		cp		2
		jp		z,.VIEJI3
		cp		3
		jp		z,.VIEJI4
		
.VIEJI1:
			
		call	CARGA_VIEJI1
		jp		.CONTINUAMOS

.VIEJI2:
			
		call	CARGA_VIEJI2
		jp		.CONTINUAMOS
		
.VIEJI3:
			
		call	CARGA_VIEJI3
		jp		.CONTINUAMOS
		
.VIEJI4:
			
		call	CARGA_VIEJI4

.CONTINUAMOS:

SE_PRESENTA_81:

		ld		ix,SOY_ANDRES_SAMUDIO_ESP_1
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		ix,SOY_ANDRES_SAMUDIO_ESP_2
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
							
		call	STRIG_DE_CONTINUE										; PAUSA
		
DECIDE_DE_LO_QUE_HABLA_81:

		ld		a,r														; decide sobre qué objeto va a hablar (pochada, llave salida)
		and		00000011b		
		add		14
		cp		16
		jp		nz,.HACE_LOS_CALCULOS_ADECUADOS
		
		inc		a														; si es entrada, lo convertimos en salida
				
.HACE_LOS_CALCULOS_ADECUADOS:
		
		ld		(que_estoy_buscando),a
		
		ld		hl,0
		ld		a,0
		ld		(donde_esta_jugador_posicion),a
		ld		(objeto_manipular),hl
		ld		(objeto_posicion),a
		
		ld		hl,(posicion_en_mapa)									; salva A
		ld		(donde_esta_jugador_manipular),hl
		
.CALCULA_C:																; calcula C el resto a E
	
		ld		de,(donde_esta_jugador_manipular)
		ld		a,d
		cp		0
		jp		nz,.SALTA_PRIMER_BYTE_C
		ld		a,e
		cp		29
		jp		c,.ENCUENTRA_B

.SALTA_PRIMER_BYTE_C:

		push	de														; A-30
		pop		hl
		ld		de,30
		or		a
		sbc		hl,de

		ld		(donde_esta_jugador_manipular),hl				

		ld		a,(donde_esta_jugador_posicion)							; C+1
		inc		a
		ld		(donde_esta_jugador_posicion),a
	
		jp		.CALCULA_C
		
.ENCUENTRA_B:															;encuentra B
		
		ld		a,(que_estoy_buscando)
		ld		b,a

		ld		iy,eventos_laberinto									

.BUSCANDO_1_POR_1:

		ld		a,(iy)	
		
		cp		b
		jp		z,.CALCULA_D
		
		ld		bc,1
		add		iy,bc
		ld		a,(objeto_manipular)
		inc		a
		ld		(objeto_manipular),a

		ld		a,(que_estoy_buscando)
		ld		b,a		
		jp		.BUSCANDO_1_POR_1
				
.CALCULA_D:																;calcula D el resto a F

		ld		de,(objeto_manipular)
		ld		a,d
		cp		0
		jp		nz,.SALTA_PRIMER_BYTE_D
		ld		a,e
		cp		29
		jp		c,.VALOR_NORTE_SUR

.SALTA_PRIMER_BYTE_D:

		push	de														; D-30
		pop		hl
		ld		de,30
		or		a
		sbc		hl,de

		ld		(objeto_manipular),hl				

		ld		a,(objeto_posicion)										; E+1
		inc		a
		ld		(objeto_posicion),a
	
		jp		.CALCULA_D
		
.VALOR_NORTE_SUR:														;calcula valor norte_sur

		ld		a,(objeto_posicion)
		ld		b,a
		ld		a,(donde_esta_jugador_posicion)
		cp		b
		jp		z,.VALOR_ESTE_OESTE
		jp		c,.ESTA_AL_SUR
		jp		nc,.ESTA_AL_NORTE
				
.ESTA_AL_SUR:

		ld		a,6
		ld		(norte_sur),a
		jp		.VALOR_ESTE_OESTE

.ESTA_AL_NORTE:

		ld		a,3
		ld		(norte_sur),a

.VALOR_ESTE_OESTE:														;calcula valor este_oeste

		ld		a,(objeto_manipular)
		ld		b,a
		ld		a,(donde_esta_jugador_manipular)
		cp		b
		jp		z,.MISMA_LINEA
		jp		c,.ESTA_AL_ESTE
		jp		nc,.ESTA_AL_OESTE

.MISMA_LINEA:

		ld		a,4
		ld		(este_oeste),a
		jp		.SUMA_FINAL
						
.ESTA_AL_ESTE:

		ld		a,5
		ld		(este_oeste),a
		jp		.SUMA_FINAL

.ESTA_AL_OESTE:

		ld		a,3
		ld		(este_oeste),a
		
.SUMA_FINAL:															;suma para dar situacion_real

		ld		a,(norte_sur)
		ld		b,a
		ld		a,(este_oeste)
		add		a,b

		ld		(situacion_real),a
		
		ld		a,(que_estoy_buscando)

		cp		14
		jp		z,.DECISION_POCHADA		
		cp		15
		jp		z,.DECISION_LLAVE
		cp		17
		jp		z,.DECISION_SALIDA		

.DECISION_POCHADA:
		
		call	HABLA_DE_POCHADA
		ld		bc,37	
		call	TEXTO_A_ESCRIBIR
		jp		.DECISION_FIN

.DECISION_LLAVE:
		
		call	HABLA_DE_LLAVE
		ld		bc,34	
		call	TEXTO_A_ESCRIBIR
		jp		.DECISION_FIN
		
.DECISION_SALIDA:
		
		call	HABLA_DE_SALIDA
		ld		bc,35	
		call	TEXTO_A_ESCRIBIR
						
.DECISION_FIN:
		
		
		ld		a,(situacion_real)
		sub		3
		and		00001111b														;restamos tres para que coincida con la lista de selección
		ld		de, POINT_DIREC_VIAJIGUIA
		jp		lista_de_opciones
						
COMUN_VIEJIGUIA_81:

		call	TEXTO_A_ESCRIBIR
		call	SONIDO_VIEJIGUIA

		call	STRIG_DE_CONTINUE
		
		ld		a,(set_page01)
		or		a
		jp		z,.a_uno

.a_0:

		xor		a
		ld		(set_page01),a
		ret

.a_uno:

		ld		a,1
		ld		(set_page01),a
		ret		

ENCUENTRA_HATER_MSX_81:

		ld		a,1
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_ATARI_81:

		ld		a,2
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_AMSTRAD_81:

		ld		a,3
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_COMMODORE_81:

		ld		a,4
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_DRAGON_81:

		ld		a,5
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_SPECTRUM_81:

		ld		a,6
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER
		
ENCUENTRA_HATER_ACORN_81:

		ld		a,7
		ld		(estandarte_hater),a
		jp		ENCUENTRA_HATER

ENCUENTRA_HATER_ORIC_81:

		ld		a,8
		ld		(estandarte_hater),a
		
ENCUENTRA_HATER_81:

		di
		call  	stpmus
		ei
		
		CALL	ACTIVA_MUSICA_HATER_CONVERSACION
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_neutra_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		EMPIEZA_CONTROL_DE_PELEA

.pinta_jugador_2:

		ld		iy,copia_cara_neutra_jugador_2						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

EMPIEZA_CONTROL_DE_PELEA_81:

		ld		a,(set_page01)
		cp		1
		jp		z,.CONTINUAMOS

		ld		iy,copia_escenario_a_page_1								; Si estamos en page 0. Vamos a clonar la 0 en la 1
		CALL	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001

		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		call	VDP_LISTO
		
		ld		a,1
		ld		(set_page01),a
		
.CONTINUAMOS:
				
		ld		a,5														; REINICIAMOS LA VIDA AL HATER
		ld		(vida_hater),a
		
		ld		iy,cuadrado_que_limpia_5								; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR
						
		call	PINTANDO_EL_HATER										; PINTA_HATER

		ld		iy,copia_mas_igual										; COPIAMOS + E = DE ATAQUE
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_corazon										; COPIAMOS + E = DE DEFENSA
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	DIRECTRICES_VIDA_HATER									; PINTAMOS EL VALOR DE LA VIDA DEL HATER
		ld		a,(vida_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		call	LIMPIA_VALORES_DE_LUCHA
								
		ld		a,(nivel)												; PINTAMOS EL MODIFICADOR DE ATAQUE Y DEFENSA
		ld		de, POINT_NIVEL_HATER
		jp		lista_de_opciones

NIVEL_HATER_0_81:
		
		ld		iy,copia_hater_0									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_0		
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER

NIVEL_HATER_1_81:
		
		ld		iy,copia_hater_1									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_1									
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER

NIVEL_HATER_2_81:
		
		ld		iy,copia_hater_2									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_2									
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER

NIVEL_HATER_3_81:
		
		ld		iy,copia_hater_3									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_3									
		call	COPY_A_GUSTO
		ld		a,#32
		ld		(ix+6),a									
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		jp		SALUDO_HATER
		
NIVEL_HATER_4_81:
		
		ld		iy,copia_hater_4									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_hater_4
		call	COPY_A_GUSTO					
		ld		a,#32
		ld		(ix+6),a									
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
												
SALUDO_HATER_81:

		xor		a
		ld		(set_page01),a	
		
		ld		ix,HOLA_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		ix,HOLA_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		
					
		call	STRIG_DE_CONTINUE										; PAUSA

		di
		or		a
		ld		a,7				
		ld		[#6000],a	
		
		ei


				
		ld		a,(estandarte_hater)
		ld		de, POINT_ESTANDARTE_ESCOGIDO
		call	lista_de_opciones_7
		
		di
		or		a
		ld		a,0				
		ld		[#6000],a	
		
		ei
		
		ld		c,#a0
		ld		b,#00
		ld		(ix+4),c
		ld		(ix+5),b
		ld		c,#0c
		ld		b,#00
		ld		(ix+6),c
		ld		(ix+7),b
						
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
		ld		a,(estandarte)											; DECIDE SI LUCHA O NO LUCHA
		ld		b,a
		ld		a,(estandarte_hater)
		cp		b
		jp		NZ,SI_LUCHA

NO_LUCHA_81:																; NO LUCHA
		
		ld		a,17
		ld		c,0
		call	EFECTO

		ld		a,1														; activamos la mosca_activa
		ld		(mosca_activa),a

		ld		a,(turno)
		cp		1
		jp		nz,NO_LUCHA_2
		
		ld		a,28
		ld		(mosca_x_objetivo),a
		ld		a,62
		ld		(mosca_y_objetivo),a
		jp		NO_LUCHA_3

NO_LUCHA_2_81:

		ld		a,235
		ld		(mosca_x_objetivo),a
		ld		a,62
		ld		(mosca_y_objetivo),a
		
NO_LUCHA_3_81:
				
		ld		ix,PREMIO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		ld		ix,PREMIO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		
		call	HATER_CARA_FELIZ
			
		call	STRIG_DE_CONTINUE										; PAUSA
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_activa_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		A_DAR_MONEDAS
		
.pinta_jugador_2:

		ld		iy,copia_cara_activa_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

A_DAR_MONEDAS_81:		

		ld		a,15
		ld		(var_cuentas_peq),a										; INCLUIR REGALO

.LOOP_MONEDAS:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS	
			
		call	PINTA_BITNEDAS											; pinta el valor de las bitnedas
		
		ld		a,11
		ld		c,0
		call	EFECTO
		
		ld		ix,eventos_laberinto									; DESAPARECE DE LA CASILLA PARA QUE NADIE SE APROVECHE DE ÉL
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		xor		a
		ld		(ix),a

		di
		call  	stpmus
		ei
				
		jp		FINAL_DE_LUCHA											; SALTO A RUTINA DE FINAL

COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER_81:

		ld		a,(pagina_hater)
		cp		0
		jp		z,SUBE_0
		cp		1
		jp		z,SUBE_26
		cp		2
		jp		z,SUBE_52		

SUBE_78_81:

[26]	inc		ix

SUBE_52_81:

[26]	inc		ix

SUBE_26_81:

[26]	inc		ix

SUBE_0_81:

		push	ix
		pop		hl
		ret
		
DEFINE_DIRECTRICES_DE_CARA_HATER_81:

		ld		ix,copia_hater_cara
		ld		a,(pagina_hater)
		cp		0
		jp		z,NO_AUMENTAMOS_IX
		cp		1
		jp		z,IX_MAS_1
		cp		2
		jp		z,IX_MAS_2
		
IX_MAS_3_81:
		
[11]	inc		ix
		
IX_MAS_2_81:
		
[11]	inc		ix
				
IX_MAS_1_81:
		
[11]	inc		ix
		
NO_AUMENTAMOS_IX_81:
		
		ret
		
SI_LUCHA_81:	
																		; SI LUCHA
				
		ld		a,1														; activamos la mosca_activa
		ld		(mosca_activa),a
		
		ld		a,18
		ld		c,0
		call	EFECTO
		
		CALL	ACTIVA_MUSICA_HATER	
		
		ld		ix,TE_ATACO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,TE_ATACO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_ENFADADO
			
		call	STRIG_DE_CONTINUE										; PAUSA


ENEMIGO_ATACA_81:															; ENEMIGO ATACA
		
		ld		a,74
		ld		(mosca_x_objetivo),a
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	LIMPIA_VALORES_DE_LUCHA
	
		call	HATER_CARA_ENFADADO
				
		ld		a,r														; LANZA DADO
		and		00000111b
		
PINTAMOS_EL_DADO_81:
		
		ld		(valor_ataque_hater),a									; PASAMOS EL RESULTADO DEL DADO A SU VARIABLE
	

		ld		iy,copia_numero_hater									
		call	COPY_A_GUSTO
		
		ld		a,(valor_ataque_hater)
		ld		de, POINT_DADO_ATAQUE_HATER								; PINTA DADO ATAQUE
		jp		lista_de_opciones

ATAQUE_HATER_1_81:
		
		ld		a,1
		ld		(valor_ataque_hater),a
		ld		a,9
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2
		
ATAQUE_HATER_2_81:

		ld		a,16
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_3_81:

		ld		a,24
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_4_81:

		ld		a,32
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_5_81:

		ld		a,40
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2

ATAQUE_HATER_6_81:

		ld		a,6
		ld		(valor_ataque_hater),a
		ld		a,48
		ld		(ix),a

PINTAMOS_EL_DADO_2_81:

		ld		a,62
		ld		(ix+4),a
		ld		a,31
		ld		(ix+6),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
								
		ld		a,(nivel)												; PINTA RESULTADO FINAL
		ld		b,a
		ld		a,(valor_ataque_hater)
		add		a,b
		ld		(valor_ataque_final_hater),a

		call	DIRECTRICES_ATAQUE_FINAL_HATER							;pintamos el valor de la rectificacion de ataque hater
		ld		a,(valor_ataque_final_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
	
		ld		a,42
		ld		(mosca_y_objetivo),a
				
		ld		hl,LANZA_DEFENDER
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
										
		call	TIRAMOS_EL_DADO_PARA_PELEA								; PERSONAJE TIRA EL DADO PARA LA DEFENSA
			
		ld		a,1
		ld		(estado_pelea),a
		call	pasamos_el_valor_del_dado_de_defensa_al_contador		; SE PINTA RESULTADO DEL DADO Y DEFINITIVO EN DEFENSA
		xor		a
		ld		(estado_pelea),a
						
		ld		a,(defensa_real)										; COMPARA ATAQUE DE HATER CON DEFENSA DE PERSONAJE
		ld		b,a
		ld		a,(valor_ataque_final_hater)
		cp		b
		jp		z,FRACASO_EN_EL_ATAQUE_ENEMIGO
		jp		c,FRACASO_EN_EL_ATAQUE_ENEMIGO
					
EXITO_EN_EL_ATAQUE_ENEMIGO_81:												; EXITO EN EL ATAQUE
		
		ld		a,18													; SONIDO DE GOLPE RECIBIDO CON PRIORIDAD 2
		ld		c,0
		call	EFECTO
		
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_pierde_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		RESTA_VIDA_PERSONAJE

.pinta_jugador_2:

		ld		iy,copia_cara_pierde_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
RESTA_VIDA_PERSONAJE_81:
		
		ld		a,3
		ld		(paleta_a_usar_en_vblank),a
						
		ld		a,(defensa_real)										; RESTA VIDA A PERSONAJE
		ld		b,a
		ld		a,(valor_ataque_final_hater)
		sub		b
		cp		0
		jp		z,COMPROBAMOS_ESTADO_DEL_JUGADOR
		ld		(var_cuentas_peq),a
		
DESCONTAMOS_VIDA_81:
		
		ld		a,(vida_unidades)
		dec		a
		ld		(vida_unidades),a
		
		call	AJUSTA_VIDA_HACIA_ABAJO
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		or		a
		jp		nz,DESCONTAMOS_VIDA
		
		call	PINTA_VIDA												; PINTA VIDA
			
COMPROBAMOS_ESTADO_DEL_JUGADOR_81:

		ld		a,(vida_decenas)										; COMPRUEVA ESTADO
		ld		b,a
[2]		add		a,a
		add		b
		add		a
		ld		b,a
		ld		a,(vida_unidades)
		add		b

		cp		6
		jp		c,VIDA_INFERIOR_A_5
		jp		nc,VIDA_SUPERIOR_A_5
										
VIDA_INFERIOR_A_5_81:														; VIDA=<5


		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
	
		di
		call	stpmus
		ei
		
		ld		iy,copia_cara_pierde_jugador_1						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		MENSAJE_DEL_MALO

.pinta_jugador_2:

		ld		iy,copia_cara_pierde_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

MENSAJE_DEL_MALO_81:

		di
		call	stpmus
		ei
		
		ld		ix,TE_HIERO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,TE_HIERO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_FELIZ
				
		call	STRIG_DE_CONTINUE										; PAUSA
	
		xor		a														; RESTA DINERO
		ld		(bitneda_centenas),a
		ld		(bitneda_decenas),a
		ld		(bitneda_unidades),a
		
		call	PINTA_BITNEDAS											; PINTA DINERO

		xor		a														; QUITA OBJETOS
		ld		(brujula),a
		ld		a,14
		ld		(var_cuentas_peq),a
		ld		de,papel
		ld		a,0
		ld		(menu_de_lampara_trampa),a
		ld		a,(turno)
		cp		1
		jp		z,ORIGEN_1

ORIGEN_2_81:
		
		ld		a,(incremento_ataque_origen2)
		ld		(incremento_ataque),a
		ld		a,(incremento_defensa_origen2)
		ld		(incremento_defensa),a
		ld		a,(incremento_velocidad_origen2)
		ld		(incremento_velocidad),a

		jp		PINTA_ORIGENES

ORIGEN_1_81:

		ld		a,(incremento_ataque_origen1)
		ld		(incremento_ataque),a
		ld		a,(incremento_defensa_origen1)
		ld		(incremento_defensa),a
		ld		a,(incremento_velocidad_origen1)
		ld		(incremento_velocidad),a
				
PINTA_ORIGENES_81:
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de ataque
		ld		a,(incremento_ataque)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de defensa
		ld		a,(incremento_defensa)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS
						
BORRA_OBJETOS_81:

		ld		bc,13
		ld		de,papel
		ld		hl,brujula
		ldir													
											
		ld		iy,cuadrado_que_limpia_101								; BORRA OBJETOS DE PANTALLA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		
		ld		a,(turno)
		cp		1
		jp		z,BORRA_OBJETOS_JUGADOR_1

BORRA_OBJETOS_JUGADOR_2_81:


		ld		a,#81
		ld		(ix+4),a
		
BORRA_OBJETOS_JUGADOR_1_81:		
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
		jp		FINAL_DE_LUCHA											; SALTO A RUTINA DE FINAL
					
VIDA_SUPERIOR_A_5_81:														; VIDA>5

		ld		ix,TE_HIERO_POCO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,TE_HIERO_POCO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_FELIZ
		
		call	STRIG_DE_CONTINUE										; PAUSA
						
		jp		PERSONAJE_ATACA											; SALTO A RUTINA DE PERSONAJE ATACA
						
FRACASO_EN_EL_ATAQUE_ENEMIGO_81:											; FRACASO EN EL ATAQUE

		ld		a,17													; SONIDO DE EVITA GOLPE
		ld		c,0
		call	EFECTO

		ld		ix,NO_TE_HIERO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,NO_TE_HIERO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR
		
		call	STRIG_DE_CONTINUE										; PAUSA
		
		jp		PERSONAJE_ATACA											; SALTO A LA RUTINA DE PERSONAJE ATACA
				
PERSONAJE_ATACA_81:														; PERSONAJE ATACA

		ld		hl,LANZA_ATACAR
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	HATER_CARA_ENFADADO
						
		call	LIMPIA_VALORES_DE_LUCHA
		ld		a,40
		ld		(ralentizando),a
		call	RALENTIZA
		call	TIRAMOS_EL_DADO_PARA_PELEA								; PERSONAJE TIRA EL DADO PARA EL ATAQUE
			
		ld		a,2
		ld		(estado_pelea),a
		call	pasamos_el_valor_del_dado_de_ataque_al_contador			; SE PINTA RESULTADO DEL DADO Y DEFINITIVO EN ATAQUE
		xor		a
		ld		(estado_pelea),a
		
		call	STRIG_DE_CONTINUE
		
		ld		a,r														; LANZA DADO PARA SU DEFENSA
		and		00000111b
		
PINTAMOS_EL_DADO_DEFENSA_81:
						
		ld		(valor_defensa_hater),a									; PASAMOS EL RESULTADO DEL DADO A SU VARIABLE
	
		ld		a,74
		ld		(mosca_x_objetivo),a
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		ld		iy,copia_numero_hater									
		call	COPY_A_GUSTO
		
		ld		a,(valor_defensa_hater)
		ld		de, POINT_DADO_DEFENSA_HATER							; PINTA DADO DEFENSA
		jp		lista_de_opciones

DEFENSA_HATER_1_81:
		
		ld		a,1
		ld		(valor_defensa_hater),a
		ld		a,9
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA
		
DEFENSA_HATER_2_81:

		ld		a,16
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_3_81:

		ld		a,24
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_4_81:

		ld		a,32
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_5_81:

		ld		a,40
		ld		(ix),a
		jp		PINTAMOS_EL_DADO_2_DEFENSA

DEFENSA_HATER_6_81:

		ld		a,6
		ld		(valor_defensa_hater),a
		ld		a,48
		ld		(ix),a

PINTAMOS_EL_DADO_2_DEFENSA_81:

		ld		a,62
		ld		(ix+4),a
		ld		a,50
		ld		(ix+6),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
								
		ld		a,(nivel)												; PINTA RESULTADO FINAL
		ld		b,a
		ld		a,(valor_defensa_hater)
		add		a,b
		ld		(valor_defensa_final_hater),a

		call	DIRECTRICES_DEFENSA_FINAL_HATER							;pintamos el valor de la rectificacion de defensa hater
		ld		a,(valor_defensa_final_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
						
		ld		a,(ataque_real)											; COMPARA ATAQUE DE PERSONAJE CON DEFENSA DE HATER
		ld		b,a
		ld		a,(valor_defensa_final_hater)
		cp		b
		jp		nc,FRACASO_EN_EL_ATAQUE_PROPIO
					
EXITO_EN_EL_ATAQUE_PROPIO_81:												; EXITO EN EL ATAQUE

		ld		b,a														; RESTA VIDA A HATER
		ld		a,(ataque_real)
		sub		b
		ld		b,a
		ld		a,(vida_hater)
		sub		b
		cp		30
		jp		c,FIJAMOS_VALOR_VIDA_HATER
		
		xor		a
			
FIJAMOS_VALOR_VIDA_HATER_81:
		
		ld		(vida_hater),a

		ld		a,18													; SONIDO DE GOLPE CON PREFERENCIA 2
		ld		c,0
		call	EFECTO	
		
		call	DIRECTRICES_VIDA_HATER									; PINTA VIDA DE HATER
		ld		a,(vida_hater)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS		

		ld		a,(vida_hater)											; COTEJA
		or		a
		jp		nz,VIDA_HATER_SUPERIOR_A_0
				
VIDA_HATER_INFERIOR_A_0_81:
													; VIDA=<0
		DI
		call	stpmus
		ei
				
		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2


		
		ld		iy,copia_cara_activa_jugador_1					
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		RESOLUCION

.pinta_jugador_2:

		ld		iy,copia_cara_activa_jugador_2						
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
RESOLUCION_81:
				
		ld		a,19													; SONIDO DE EXITO
		ld		c,0
		call	EFECTO	
								
		ld		ix,MUERO_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,MUERO_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_MUERTO
		
		ld		a,60
		ld		(var_cuentas_peq),a										; COGE LOS OBJETOS Y DINERO

.LOOP_MONEDAS:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS	
		
		call	PINTA_BITNEDAS											; pinta el valor de las bitnedas

		ld		a,11
		ld		c,0
		call	EFECTO		
						
		ld		ix,eventos_laberinto									; DESAPARECE DE LA CASILLA POR ESTAR MUERTO
		ld		hl,(posicion_en_mapa)
		push	hl
		pop		bc
		add		ix,bc
		xor		a
		ld		(ix),a
				
		call	STRIG_DE_CONTINUE										; PAUSA
		jp		FINAL_DE_LUCHA											; VE A FINAL DE LUCHA
						
VIDA_HATER_SUPERIOR_A_0_81:												; VIDA>0

		ld		ix,ME_HIERES_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,ME_HIERES_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_TRISTE
				
		call	STRIG_DE_CONTINUE										; PAUSA
		
		jp		ENEMIGO_ATACA											; SALTO A RUTINA DE ENEMIGO ATACA
						
FRACASO_EN_EL_ATAQUE_PROPIO_81:											; FRACASO EN EL ATAQUE

		ld		a,17													; SONIDO DE FALLO
		ld		c,0
		call	EFECTO

		ld		ix,NO_ME_HIERES_HATER_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,NO_ME_HIERES_HATER_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		call	HATER_CARA_FELIZ
				
		call	STRIG_DE_CONTINUE										; PAUSA
				
		jp		ENEMIGO_ATACA											; SALTO A RUTINA DE ENEMIGO ATACA
				
FINAL_DE_LUCHA_81:															; FINAL
		
		call	LIMPIA_VALORES_DE_LUCHA

		ld		iy,cuadrado_que_limpia_5								; BORRA PANTALLA DE JUEGO
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR
		
		xor		a														; CAMBIA PALETA A LABERINTO
		ld		(paleta_a_usar_en_vblank),a
		

		ld		iy,copia_escenario_a_page_0								; COPIAMOS EL LABERINTO EN PANTALLA OTRA VEZ
		call	COPY_A_GUSTO
		ld		a,11010000b
		ld		(ix+14),a
						
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY							; REGRESA
		
		call	ACTIVA_MUSICA_JUEGO

pasamos_el_valor_del_dado_de_defensa_al_contador_81:


		ld		a,1
		ld		c,0
		call	EFECTO
		
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA
				
		ld		iy,cuadrado_que_limpia_4
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		bc,187
		ld		(ix+4),c												;x inicio linea
	
		call	PINTA_DIRECTRICES_DEL_COPY
				
		call	DIRECTRICES_VALOR_DADO
		ld		a,(dado)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
				
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
calcula_lo_que_puede_defenderse_81:

		ld		a,(dado)
		ld		b,a
		ld		a,(incremento_defensa)
		add		a,b
		ld		(defensa_real),a

Pintamos_la_defensa_real_81:

		ld		a,1
		ld		c,0
		call	EFECTO
				
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA

		call	DIRECTRICES_VALOR_MOVIMIENTO_REAL

		ld		a,(defensa_real)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
		ret

pasamos_el_valor_del_dado_de_ataque_al_contador_81:

		ld		a,1
		ld		c,1
		call	EFECTO
		
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA
				
		ld		iy,cuadrado_que_limpia_4
		call	COPY_A_GUSTO
		ld		a,0
		ld		(ix+12),a												;color	
		ld		a,10000000b
		ld		(ix+14),a
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		
		ld		bc,187
		ld		(ix+4),c												;x inicio linea
	
		call	PINTA_DIRECTRICES_DEL_COPY
				
		call	DIRECTRICES_VALOR_DADO
		ld		a,(dado)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
				
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
calcula_lo_que_puede_atacar_81:

		ld		a,(dado)
		ld		b,a
		ld		a,(incremento_ataque)
		add		a,b
		ld		(ataque_real),a

Pintamos_el_ataque_real_81:

		ld		a,1
		ld		c,0
		call	EFECTO
				
		ld		a,60
		ld		(ralentizando),a
		call	RALENTIZA

		call	DIRECTRICES_VALOR_MOVIMIENTO_REAL

		ld		a,(ataque_real)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		a,16
		ld		c,0
		call	EFECTO
		
		ld		a,40
		LD		(ralentizando),a
		call	RALENTIZA
		
		ret

DIRECTRICES_VIDA_HATER_81:

		ld		ix,datos_del_copy
		ld		bc,14
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		bc,92
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
						
DIRECTRICES_ATAQUE_FINAL_HATER_81:
		
		ld		ix,datos_del_copy
		ld		bc,31
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		bc,92
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret

DIRECTRICES_DEFENSA_FINAL_HATER_81:
		
		ld		ix,datos_del_copy
		ld		bc,50
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		ld		bc,92
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		ret
		
TIRAMOS_EL_DADO_PARA_PELEA_81:

		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2

.pinta_jugador_1:		

		ld		a,20
		ld		(mosca_x_objetivo),a
		ld		iy,copia_cara_ataque_jugador_1							; rutina especial de cara enfadado
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		TIRANDO_PARA_PELEA

.pinta_jugador_2:

		ld		a,229
		ld		(mosca_x_objetivo),a
		ld		iy,copia_cara_ataque_jugador_2							; rutina especial de cara enfadado
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
TIRANDO_PARA_PELEA_81:
		
		xor		a
		ld		c,0		
		call	EFECTO
		
		ld		a,1
		ld		(toca_dado),a
				
		call	DA_VALOR_AL_DADO		
		call	PINTA_EL_DADO_QUE_HA_SALIDO_parte_1
						
		xor		a
		call	GTTRIG
		cp		#FF
		ret		z
		
		ld		a,(turno)
		call	GTTRIG
		cp		#FF
		ret		z

		ld		a,4														
		call	SNSMAT
		bit		2,a
		call	z,QUIERE_ESCAPAR
		
		ld		a,(turno)
		add		2														; si le da al boton 2
		call	GTTRIG
		cp		#FF
		call	z,QUIERE_ESCAPAR
		
		jp		TIRANDO_PARA_PELEA

QUIERE_ESCAPAR_81:

		ld		a,(gallina)
		or		a
		jp		nz,LO_CONSIGUE

		ld		ix,NO_PUEDES_ESCAPAR_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		jp		STRIG_DE_CONTINUE

		ret

LO_CONSIGUE_81:
		
		pop		af														; sacamos de la pila el valor del último ret
		pop		af														; sacamos de la pila el valor del anterior
		
		ld		a,(gallina)
		dec		a
		ld		(gallina),a
		or		a
		jp		nz,MIRAMOS_SI_ES_LA_ULTIMA
		
		ld		iy,copia_gallina_en_objetos								; BORRA DIBUJO GALLILNA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos_sigue						; BORRA DIBUJO GALLILNA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		jp		MENSAJE_DE_COBARDE
		
MIRAMOS_SI_ES_LA_ULTIMA_81:
		
		cp		1
		jp		nz,MENSAJE_DE_COBARDE
		
		ld		iy,copia_gallina_en_objetos								; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		cp		1
		jp		z,.PINTAMOS
		
		ld		a,#e7
		ld		(ix+4),a
		
.PINTAMOS:		
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos_sigue						; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		cp		1
		jp		z,.PINTAMOS_2
		
		ld		a,#e7
		ld		(ix+4),a
		
.PINTAMOS_2:		
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
MENSAJE_DE_COBARDE_81:		

		ld		ix,COBARDE_1_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER		
		call	TEXTO_A_ESCRIBIR
		ld		ix,COBARDE_2_ESP
		call	COLOCA_PUNTERO_IX_EN_FRASE_CORRECTA_HATER
		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_gallina_en_objetos_1								; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		
		call	EL_12_A_0_EL_14_A_1001
		
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,copia_gallina_en_objetos_2								; CAMBIA DIBUJO POR UNA SOLA GALLINA
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
						
		jp		FINAL_DE_LUCHA
		
LIMPIA_VALORES_DE_LUCHA_81:

		ld		iy,cuadrado_que_limpia_final_hater						; BORRA RESULTADO FINAL DEFENSA Y ATAQUE HATER
		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		ld		iy,cuadrado_que_limpia_result_at_def					; BORRA RESULTADO DEFENSA Y ATAQUE DE JUGADOR
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,cuadrado_que_limpia_final_at_def						; BORRA RESULTADO FINAL DEFENSA Y ATAQUE DE JUGADOR
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
		ld		iy,cuadrado_que_limpia_dados_hater						; BORRA DADOS_HATER
		call	COPY_A_GUSTO
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY
				
		ld		a,11010000b
		ld		(ix+14),a
		
		ret
					
ENCUENTRA_TINTA_81:

		ld		a,(tinta)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la brújula al jugador
		ld		(tinta),a

		ld		a,0														;la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a

		ld		iy,copia_tinta_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,TINTA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PLUMA_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_tinta_en_objetos								; pintamos la brújula entre los objetos
		CALL	COPY_DE_OBJETO

		
		call	COMPRUEBA_TURNO_EN_OBJETO_2

		
		ld		c,#a5													;corregimos la posición de la brújula para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_LLAVE_81:

		ld		a,1														;le damos la llave al jugador
		ld		(llave),a

		ld		iy,copia_llave_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla						;no la quitamos de la casilla (otro jugador la puede coger)

		ld		hl,LLAVE_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,LLAVE_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_llave_en_objetos								; pintamos la llave entre los objetos
		CALL	COPY_DE_OBJETO

		
		call	COMPRUEBA_TURNO_EN_OBJETO_2

		
		ld		c,#8d													;corregimos la posición de la llave para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5


ENCUENTRA_LUPA_81:

		ld		a,(lupa)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la brújula al jugador
		ld		(lupa),a

		ld		iy,copia_lupa_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,LUPA_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,LUPA_2_ESP

		call	TEXTO_A_ESCRIBIR
					
		ld		iy,copia_lupa_en_objetos								; pintamos la lupa entre los objetos
		CALL	COPY_DE_OBJETO

		
		call	COMPRUEBA_TURNO_EN_OBJETO_2

		
		ld		c,#82				 									;corregimos la posición de la lupa para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_BOTAS_81:

		ld		a,(botas)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(botas_esp)
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la bota al jugador
		ld		(botas),a
		
		ld		a,(incremento_velocidad)
		inc		a
		ld		(incremento_velocidad),a

		ld		iy,copia_botas_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,BOTA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,BOTA_2_ESP

		call	TEXTO_A_ESCRIBIR
							
		ld		iy,copia_botas_en_objetos								; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		ld		a,5
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		c,#C0													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5


ENCUENTRA_BOTAS_ESP_81:
		
		ld		a,(botas_esp)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(botas)
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la bota especiales al jugador
		ld		(botas_esp),a


		
		ld		a,(incremento_velocidad)
		add		2
		ld		(incremento_velocidad),a

		ld		iy,copia_botas_esp_en_objetos							; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_VELOCIDAD						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_velocidad)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,BOTA_ESP_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,BOTA_2_ESP

		call	TEXTO_A_ESCRIBIR
					
		ld		iy,copia_botas_esp_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		ld		a,5
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
				
		ld		c,#C0													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

ENCUENTRA_PERRO_81:

		ld		a,(perro)											;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
				
		ld		a,1														;le damos el cuchillo al jugador
		ld		(perro),a
				
		ld		hl,PERRO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PERRO_2_ESP
		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,PERRO_3_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,PERRO_4_ESP
		call	TEXTO_A_ESCRIBIR

		ld		a,(turno)
		cp		1
		jp		z,.EL_UNO
.EL_DOS:

		ld		de,GRAFICO_PERRO
		ld		hl,copia_perro_2										; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC

		jp		ENCUENTRA_BRUJULA_1_5
		
.EL_UNO:
				
		ld		de,GRAFICO_PERRO
		ld		hl,copia_perro_1										; preparamos las directrices de copia
		call	ESPERA_AL_VDP_HMMC
		
		jp		ENCUENTRA_BRUJULA_1_5
		
ENCUENTRA_CUCHILLO_81:

		ld		a,(cuchillo)											;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(espada)												;si tiene la espada, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos el cuchillo al jugador
		ld		(cuchillo),a
		
		ld		a,(incremento_ataque)
		inc		a
		ld		(incremento_ataque),a

		ld		iy,copia_cuchillo_en_objetos							; pintamos el cuchillo pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de fuerza
		ld		a,(incremento_ataque)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,CUCHILLO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,CUCHILLO_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_cuchillo_en_objetos							; pintamos el cuchillo entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a

		
		ld		c,#b2													;corregimos la posición de el cuchillo para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_ESPADA_81:

		ld		a,(espada)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,(cuchillo)
		or		a
		jp		nz,NO_PASA_NADA
		
		ld		a,1														;le damos la bota especiales al jugador
		ld		(espada),a
		
		ld		a,(incremento_ataque)
		add		2
		ld		(incremento_ataque),a

		ld		iy,copia_espada_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_ATAQUE						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_ataque)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,ESPADA_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,CUCHILLO_2_ESP

		call	TEXTO_A_ESCRIBIR

		ld		iy,copia_espada_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,24
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a

		
		ld		c,#b2													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_ARMADURA_81:

		ld		a,(armadura)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
				
		ld		a,1														;le damos la bota especiales al jugador
		ld		(armadura),a
		
		ld		a,(incremento_defensa)
		inc		a
		ld		(incremento_defensa),a

		ld		iy,copia_armadura_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_defensa)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,ARMADURA_1_ESP
		call	TEXTO_A_ESCRIBIR	
		ld		hl,ARMADURA_2_ESP

		call	TEXTO_A_ESCRIBIR
				
		ld		iy,copia_armadura_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a

		
		ld		c,#a5													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_CASCO_81:

		ld		a,(casco)												;si ya la tiene, pasa de largo
		or		a
		jp		nz,NO_PASA_NADA
				
		ld		a,1														;le damos la bota especiales al jugador
		ld		(casco),a
		
		ld		a,(incremento_defensa)
		inc		a
		ld		(incremento_defensa),a

		ld		iy,copia_casco_en_objetos								; pintamos la brújula pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
		
		call	DIRECTRICES_RECTIFICACION_DEFENSA						;pintamos el valor de la rectificacion de velocidad
		ld		a,(incremento_defensa)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		call	COPIA_NUMEROS

		ld		hl,CASCO_1_ESP
		call	TEXTO_A_ESCRIBIR		
		ld		hl,ARMADURA_2_ESP

		call	TEXTO_A_ESCRIBIR
					
		ld		iy,copia_casco_en_objetos							; pintamos la bota entre los objetos
		CALL	COPY_DE_OBJETO

		
		ld		a,42
		ld		(mosca_y_objetivo),a
		
		call	COMPRUEBA_TURNO_EN_OBJETO

		ld		a,229
		ld		(mosca_x_objetivo),a
		
		ld		c,#9a													;corregimos la posición de la bota para el jugador 2
		jp		ENCUENTRA_BRUJULA_1_5

		
ENCUENTRA_BITNEDA_81:
		
		ld		a,(bitneda_centenas)
		cp		2
		ret		z
		
		ld		a,(bitneda_unidades)									; le damos una bitneda al jugador
		inc		a
		ld		(bitneda_unidades),a

		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		
		ld		iy,copia_bitneda_en_objetos								; pintamos la bitneda pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,BITNEDA_1_ESP
		call	TEXTO_A_ESCRIBIR
	
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	PINTA_BITNEDAS											; lo mandamos a secuencia de pintar las bitnedas
		
		ld		a,11
		ld		c,0
		jp		EFECTO

ENCUENTRA_MANZANA_81:
				
		ld		a,(vida_unidades)										; le damos una vida al jugador
		inc		a
		ld		(vida_unidades),a

		call	AJUSTA_VIDA												; controla valor de unidades a DECENAS
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		
		ld		iy,copia_manzana_en_objetos								; pintamos la manzana pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,MANZANA_1_ESP
		call	TEXTO_A_ESCRIBIR

		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR		
		call	PINTA_VIDA												; lo mandamos a secuencia de pintar las vidas
		
		ld		a,11
		ld		c,0
		jp		EFECTO
		
ENCUENTRA_SUPERBITNEDA_81:

		ld		a,(bitneda_centenas)
		cp		2
		ret		z
		
		ld		a,5
		ld		(var_cuentas_peq),a

.LOOP_MONEDAS:
		
		ld		a,(bitneda_unidades)									; le damos cinco bitnedas al jugador
		add		1
		ld		(bitneda_unidades),a
		call	AJUSTA_BITNEDAS											; controla valor de unidades a centenas

		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_MONEDAS
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		
		ld		iy,copia_bitnedas_en_objetos							; pintamos las 5 bitnedas pero en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla

		ld		hl,BITNEDAS_1_ESP
		call	TEXTO_A_ESCRIBIR

		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR				
		call	PINTA_BITNEDAS											; lo mandamos a secuencia de pintar las bitnedas
		
		ld		a,11
		ld		c,0
		jp		EFECTO

ENCUENTRA_TRAMPA_81:
		
		ld		a,0														; la quitamos de la casilla (ya nadie la puede coger)
		ld		(ix),a
		ld		a,30													; creamos un efecto raro de movimiento
		ld		(tiembla_el_decorado_v),a

		ld		iy,copia_trampa_en_pantalla								; pintamos la trampa en el decorado
		call	SECUENCIA_PINTA_OBJETO_EN_TABLERO						; pasamos el dibujo a pantalla
				
		ld		a,7
		ld		(var_cuentas_peq),a
		
.LOOP_DE_VIDA:
		
		ld		a,(vida_unidades)										; resta 4 puntos de vida al personaje
		dec		a
		ld		(vida_unidades),a
		
		call	AJUSTA_VIDA_HACIA_ABAJO
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_DE_VIDA
		
		call	PINTA_VIDA

		ld		hl,TRAMPA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TRAMPA_2_ESP

		call	TEXTO_A_ESCRIBIR				
		
		ld		a,13
		ld		c,0		
		jp		EFECTO
						
ENCUENTRA_AGUJERO_NEGRO_81:
		
		ld		hl,(casilla_destino_agujero_negro)						; le damos el valor de la casilla destino
		ld		(posicion_en_mapa),hl
		ld		a,(x_map_destino_agujero_negro)
		ld		(x_map),a
		ld		a,(y_map_destino_agujero_negro)
		ld		(y_map),a
						
		ld		a,4
		ld		(var_cuentas_peq),a
		
		ld		hl,AGUJERO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,AGUJERO_2_ESP		
		call	TEXTO_A_ESCRIBIR
				
		call	STRIG_DE_CONTINUE
				
.LOOP_DE_VIDA:

		ld		a,100
		ld		(tiembla_el_decorado_v),a
				
		ld		a,(vida_unidades)										; resta 4 puntos de vida al personaje
		dec		a
		ld		(vida_unidades),a
			
		call	AJUSTA_VIDA_HACIA_ABAJO
		ld		a,(var_cuentas_peq)
		dec		a
		ld		(var_cuentas_peq),a
		cp		0
		jp		nz,.LOOP_DE_VIDA
		
		call	PINTA_VIDA
			
		ld		a,13
		ld		c,0		
		call	EFECTO
		
		pop		af														;extraemos de la pila el valor de regreso de ret
		
		jp		se_pinta_el_mapa
								
SECUENCIA_PINTA_OBJETO_EN_TABLERO_81:

		CALL	COPY_DE_OBJETO
		
		ld		c,#78													;corregimos la posición de la brújula para pantalla de juego
		ld		b,#00
		ld		(ix+4),c
		ld		(ix+5),b
		ld		c,#60													;corregimos la posición de la brújula para pantalla de juego
		ld		b,#00
		ld		(ix+6),c
		ld		(ix+7),b		
		ld		a,10011000b
		ld		(ix+14),a
		
		call	RECTIFICACION_POR_PAGE_0		
		
		jp		HL_DATOS_DEL_COPY_CALL_DOCOPY
		
COMPRUEBA_TURNO_EN_OBJETO_81:

		ld		a,(turno)												; comprobamos de quién es el turno
		cp		1
		jp		z,ENCUENTRA_BRUJULA_2
		
		ret

COMPRUEBA_TURNO_EN_OBJETO_2_81:

		ld		a,(turno)												; comprobamos de quién es el turno
		cp		1
		jp		z,ENCUENTRA_BRUJULA_2_5
		
		ret
				
COPY_DE_OBJETO_81:

		CALL	COPY_A_GUSTO
		
		ld		a,10010000b												; nos aseguramos que copia mediante LMMM
		ld		(ix+14),a
		
		ret
						
AJUSTA_BITNEDAS_81:

		ld		a,(bitneda_centenas)
		cp		9
		jp		z,MANTEN_LA_CANTIDAD
		
		ld		a,(bitneda_unidades)									; comprobamos si las unidades pasan de 9
		cp		10
		ret		nz
		
		xor		a														; ponemos las unidades a 0
		ld		(bitneda_unidades),a
		ld		a,(bitneda_decenas)										; aumentamos las decenas
		inc		a
		ld		(bitneda_decenas),a										; comprobamos si las decenas pasan de 9
		cp		10
		ret		nz
		
		xor		a														; ponemos las decenas a 0
		ld		(bitneda_decenas),a	
		ld		a,(bitneda_centenas)									; aumentamos las centenas
		inc		a
		ld		(bitneda_centenas),a

		RET

MANTEN_LA_CANTIDAD_81:
		
		xor		a
		ld		(bitneda_decenas),a
		ld		(bitneda_unidades),a
		
		ret

AJUSTA_VIDA_81:

		ld		a,(vida_unidades)									; comprobamos si las unidades pasan de 9
		cp		10
		ret		nz
		
		xor		a														; ponemos las unidades a 0
		ld		(vida_unidades),a
		ld		a,(vida_decenas)										; aumentamos las decenas
		inc		a
		ld		(vida_decenas),a										; comprobamos si las decenas pasan de 9
		cp		10
		ret		nz
		dec		a
		ld		(vida_decenas),a		
		ret
		
AJUSTA_BITNEDAS_HACIA_ABAJO_81:

		ld		a,(bitneda_unidades)									; comprobamos si las unidades pasan de 0 por abajo
		cp		255
		ret		nz
		
		ld		a,9														; ponemos las unidades a 9
		ld		(bitneda_unidades),a
		ld		a,(bitneda_decenas)										; reducimos las decenas
		dec		a
		ld		(bitneda_decenas),a										; comprobamos si las decenas pasan de 0 por abajo
		cp		255
		ret		nz
		
		ld		a,9														; ponemos las decenas a 9
		ld		(bitneda_decenas),a	
		ld		a,(bitneda_centenas)									; reducimos las centenas
		dec		a
		ld		(bitneda_centenas),a
		
		ret
		
AJUSTA_VIDA_HACIA_ABAJO_81:

		ld		a,(vida_unidades)										; comprobamos si las unidades inferior a 0
		cp		255
		ret		nz
		
		ld		a,9														; ponemos las unidades a 9
		ld		(vida_unidades),a
		ld		a,(vida_decenas)										; reducimos las decenas
		dec		a
		ld		(vida_decenas),a										
		
		cp		255
		jp		z,MUERTE
		
		ret
		
PINTA_BITNEDAS_81:

		ld		ix,datos_del_copy
		ld		bc,69
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		xor		a
		ld		(ix+13),a												;cómo es el copy	
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,36
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_BITNEDAS_CONTINUACION
		
.ZONA_JUG_2:
		
		ld		bc,245
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_BITNEDAS_CONTINUACION_81:
		
		ld		a,(bitneda_unidades)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1

		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,28
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_BITNEDAS_CONTINUACION_2
		
.ZONA_JUG_2:
		
		ld		bc,237
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_BITNEDAS_CONTINUACION_2_81:
		
		ld		a,(bitneda_decenas)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1

		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,20
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_BITNEDAS_CONTINUACION_3
		
.ZONA_JUG_2:
		
		ld		bc,229
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_BITNEDAS_CONTINUACION_3_81:
		
		ld		a,(bitneda_centenas)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		jp		COPIA_NUMEROS
						

PINTA_VIDA_81:

		ld		ix,datos_del_copy
		ld		bc,88
		ld		(ix+6),c												;y destino
		ld		(ix+7),b
		xor		a
		ld		(ix+13),a												;cómo es el copy	
		ld		a,10010000b
		ld		(ix+14),a
		
		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,36
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_VIDA_CONTINUACION
		
.ZONA_JUG_2:
		
		ld		bc,245
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_VIDA_CONTINUACION_81:
		
		ld		a,(vida_unidades)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1

		ld		a,(turno)
		
		cp		2
		jr.		z,.ZONA_JUG_2

.ZONA_JUG_1:
		
		ld		bc,28
		ld		(ix+4),c												;x destino
		ld		(ix+5),b
		
		jp		PINTA_VIDA_CONTINUACION_2
		
.ZONA_JUG_2:
		
		ld		bc,237
		ld		(ix+4),c												;x destino
		ld		(ix+5),b

PINTA_VIDA_CONTINUACION_2_81:
		
		ld		a,(vida_decenas)
		ld		(valor_a_transm_a_dib),a
		call	DIBUJA_NUMERO_parte_1
		jp		COPIA_NUMEROS
		
PASAMOS_A_SECUENCIA_DE_LETRAS_LA_SECUENCIA_ADECUADA_DESDE_NOMBRE_81:

		ld		bc,40
		ld		de,secuencia_de_letras
		ldir

		ret	

CODIGO_A_ESCRIBIR_81:
		
		ld		bc,26
		ld		de,secuencia_de_letras
		ldir

		jp		ESCRIBIMOS_CODIGO
				
TEXTO_A_ESCRIBIR_81:
		
		ld		bc,40
		ld		de,secuencia_de_letras
		ldir
		
		jp		ESCRIBIMOS_EN_GENERAL

AVISO_DE_NO_SALIDA_81:

		ld		hl,NO_SALIDA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO		
		call	TEXTO_A_ESCRIBIR
		ld		a,1
		ld		(no_borra_texto),a
		ret
		
AVISO_DE_NO_SALIDA_EN_LA_SALIDA_81:

		ld		hl,NO_SALIDA_EN_SALIDA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,NO_SALIDA_EN_SALIDA_2_ESP
		call	TEXTO_A_ESCRIBIR
		ld		a,1
		ld		(no_borra_texto),a
		ret
							
MUERTE_81:
				
		pop		af

		ld		a,(turno)
		cp		1
		jp		nz,.pinta_jugador_2
		
		ld		iy,copia_cara_pierde_jugador_1							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		jp		CONTINUA_MUERTE

.pinta_jugador_2:

		ld		iy,copia_cara_pierde_jugador_2							
		call	COPY_A_GUSTO
		ld		a,10010000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

CONTINUA_MUERTE_81:
		
		di
		call	stpmus
		ei

		ld		a,3
		ld		(que_musica_0),a
		
		call	MUSICA_HAS_MUERTO
				
		ld		a,(set_page01)
		or		a
		jp		z,.limpia_en_0

.limpia_en_1:

		ld		iy,cuadrado_que_limpia_5_1
		jp		.sigue

.limpia_en_0:
				
		ld		iy,cuadrado_que_limpia_5								; BORRA PANTALLA DE JUEGO

.sigue:

		call	COPY_A_GUSTO
		xor		a
		ld		(ix+12),a
		ld		a,10000000b
		ld		(ix+14),a
		call	HL_DATOS_DEL_COPY_CALL_DOCOPY

		call	ESPERA_A_QUE_TERMINE_LO_ANTERIOR
				
		ld		a,5														;indicamos a la interrupción de vblanck el cambio de paleta
		ld		(paleta_a_usar_en_vblank),a
				
		call	PINTAMOS_PROTA_MUERTO	

		ld		hl,ME_MUERO_3_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_4_ESP

		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE
		
		ld		hl,ME_MUERO_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_2_ESP

		call	TEXTO_A_ESCRIBIR
											
		call	STRIG_DE_CONTINUE

		ld		a,(cantidad_de_jugadores)
		cp		1
		jp		z, REINICIANDO_EL_JUEGO
		
		ld		hl,ME_MUERO_5_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_6_ESP

		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE

		ld		hl,ME_MUERO_7_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,ME_MUERO_8_ESP

		call	TEXTO_A_ESCRIBIR

		call	STRIG_DE_CONTINUE
				
REINICIANDO_EL_JUEGO_81:

		di
		xor		a
		ld		[#6000],a		
		ei
		
		call	DISSCR

		di
		call	stpmus													;paramos la música
		ei
		
		ld		hl,BORRA_PANTALLA_1										;Borrando la2 página2 1-3 por si había restos
[3]		call	DoCopy
		
		jp		VAMOS_A_SELECCION_DE_MENU												
						
TEXTO_DE_INICIO_UN_JUGADOR_81:

		ld		hl,COMIENZA_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COMIENZA_2_ESP
		call	TEXTO_A_ESCRIBIR
		
		ld		a,1
		ld		(no_borra_texto),a
		ret

TEXTO_DE_INICIO_DOS_JUGADORES_81:

		ld		hl,COMIENZAN_2_1_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,COMIENZAN_2_2_ESP
		call	TEXTO_A_ESCRIBIR
		
		ld		a,1
		ld		(no_borra_texto),a
		ret

GOLPE_EN_LA_PARED_81:

		ld		a,3
		ld		(paleta_a_usar_en_vblank),a
		
		ld		hl,GOLPE_CONTRA_PARED_ESP
		call	TEXTO_A_ESCRIBIR
		ld		hl,TEXTO_EN_BLANCO
		call	TEXTO_A_ESCRIBIR
		ld		a,1
		ld		(no_borra_texto),a
		
		ret

FINAL_DEL_JUEGO_81:

		di
		xor		a
		ld		[#6000],a		
		ei
		
		call	DISSCR

		di
		call	stpmus													;paramos la música
		ei
		
		ld		hl,BORRA_PANTALLA_1										;Borrando la2 página2 1-3 por si había restos
[3]		call	DoCopy
		
		ld		a,1
		ld		(salto_historia),a
		jp		VAMOS_A_SELECCION_DE_MENU	
							
cuadrado_que_limpia_101_81:						dw		#0000,#0000,#0036,#0080,#004B,#001a ; BORRA ZONA DE OBJETOS PARCIAL

copia_brujula_en_objetos_81:						dw		#0001,#0272,#0037,#0080,#000d,#000d
copia_gallina_en_objetos_81:						dw		#007f,#0280,#001c,#006a,#000d,#000d
copia_gallina_en_objetos_sigue_81					dw		#007f,#0280,#011c,#006a,#000d,#000d
copia_gallinas_en_objetos_81:						dw		#00dd,#0264,#001c,#006a,#000d,#000d
copia_gallina_en_objetos_1_81:						dw		#001c,#006a,#001c,#016a,#000d,#000d
copia_gallina_en_objetos_2_81:						dw		#00e7,#006a,#00e7,#016a,#000d,#000d
copia_trampa_en_objetos_81:							dw		#0071,#0280,#0008,#006a,#000d,#000d
copia_trampas_en_objetos_81:						dw		#00cf,#0264,#0008,#006a,#000d,#000d
copia_trampa_en_objetos_1_81:						dw		#0008,#006a,#0008,#016a,#000d,#000d
copia_trampa_en_objetos_2_81:						dw		#00d3,#006a,#00d3,#016a,#000d,#000d
copia_papel_en_objetos_81:							dw		#0010,#0272,#0044,#0080,#000c,#000d
copia_tinta_en_objetos_81:							dw		#002b,#0272,#0050,#0080,#000d,#000d
copia_pluma_en_objetos_81:							dw		#001e,#0272,#005c,#0080,#000c,#000d
copia_llave_en_objetos_81:							dw		#0039,#0272,#0068,#0080,#000d,#000d
copia_lupa_en_objetos_81:							dw		#0048,#0272,#0076,#0080,#000c,#000d
copia_botas_en_objetos_81:							dw		#0056,#0272,#0037,#008C,#000C,#000d
copia_botas_esp_en_objetos_81:						dw		#0064,#0272,#0037,#008C,#000C,#000d
copia_cuchillo_en_objetos_81:						dw		#0071,#0272,#0044,#008C,#000C,#000d
copia_espada_en_objetos_81:							dw		#007f,#0272,#0044,#008C,#000d,#000d
copia_armadura_en_objetos_81:						dw		#0001,#0280,#0050,#008C,#000C,#000d
copia_casco_en_objetos_81:							dw		#0010,#0280,#005c,#008C,#000C,#000d
copia_bitneda_en_objetos_81:						dw		#001e,#0280,#0050,#008C,#000C,#000d
copia_bitnedas_en_objetos_81:						dw		#002b,#0280,#005c,#008C,#000C,#000d
copia_trampa_en_pantalla_81:						dw		#0071,#0280,#005c,#008C,#000C,#000d
copia_manzana_en_objetos_81:						dw		#0063,#0280,#005c,#008C,#000C,#000d

copia_cara_neutra_jugador_1_81:						dw		#0000,#0375,#000C,#009D,#002A,#0028
copia_cara_neutra_jugador_2_81:						dw		#0000,#039e,#00CC,#009D,#002A,#0028
copia_cara_activa_jugador_1_81:						dw		#002c,#0375,#000C,#009D,#002A,#0028
copia_cara_activa_jugador_2_81:						dw		#002c,#039e,#00CC,#009D,#002A,#0028
copia_cara_ataque_jugador_1_81:						dw		#0057,#0375,#000C,#009D,#002A,#0028
copia_cara_ataque_jugador_2_81:						dw		#0057,#039e,#00CC,#009D,#002A,#0028
copia_cara_pierde_jugador_1_81:						dw		#0082,#0375,#000C,#009D,#002A,#0028
copia_cara_pierde_jugador_2_81:						dw		#0082,#039e,#00CC,#009D,#002A,#0028
copia_perro_1_81:									dw		#0056,#00bc,#0010,#000b
													db		#00,#00,#F0
copia_perro_2_81:									dw		#009e,#00bc,#0010,#000b
													db		#00,#00,#F0

GRAFICO_PERRO_81:			incbin		"SR5/LABERINTO/PERRO_16X11.DAT"
															
POINT_DIREC_VIAJIGUIA_81:		dw	OESTE
							dw	NORTE
							dw	ESTE
							dw	NOROESTE
							dw	NORTE
							dw	NORESTE
							dw	SUROESTE
							dw	SUR
							dw	SURESTE

POINT_DADO_ATAQUE_HATER_81:	dw	ATAQUE_HATER_1
							dw	ATAQUE_HATER_1
							dw	ATAQUE_HATER_2
							dw	ATAQUE_HATER_3
							dw	ATAQUE_HATER_4
							dw	ATAQUE_HATER_5
							dw	ATAQUE_HATER_6
							dw	ATAQUE_HATER_6

POINT_DADO_DEFENSA_HATER_81:	dw	DEFENSA_HATER_1
							dw	DEFENSA_HATER_1
							dw	DEFENSA_HATER_2
							dw	DEFENSA_HATER_3
							dw	DEFENSA_HATER_4
							dw	DEFENSA_HATER_5
							dw	DEFENSA_HATER_6
							dw	DEFENSA_HATER_6
														
POINT_LETRAS_81:				dw	ESPACIO		; 00		00000
							dw	A			; 01		00001
							dw	B			; 02		00010
							dw	C			; 03		00011	
							dw	D			; 04		00100
							dw	E			; 05		00101
							dw	F			; 06		00110
							dw	G			; 07		00111
							dw	H			; 08		01000
							dw	I			; 09		01001
							dw	J			; 10		01010
							dw	K			; 11 		01011
							dw	L			; 12		01100
							dw	M			; 13		01101
							dw	N			; 14 		01110
							dw	O			; 15		01111
							dw	P			; 16		10000
							dw	Q			; 17		10001
							dw	R			; 18		10010
							dw	S			; 19		10011
							dw	T			; 20		10100
							dw	U			; 21		10101
							dw	V			; 22		10110
							dw	W			; 23		10111
							dw	X			; 24		11000
							dw	Y			; 25		11001
							dw	Z			; 26		11010
							dw	DOS_PUNTOS	; 27		11011
							dw	PUNTO		; 28		11100
							dw	ACENTO		; 29		11101
							dw	RABITO_N	; 30		11110
							dw	PASA_CARRO	; 31		11111

POINT_CODIGO_81:				dw	A
							dw	B			
							dw	C			
							dw	D			
							dw	E			
							dw	F			
							dw	G			
							dw	H			
							dw	I		
							dw	J			
							dw	K		
							dw	L			
							dw	M			
							dw	N		
							dw	O		
							dw	P			
										
POINT_ESCRIBE_NOMBRE_81:	dw	NATPU									; 1
							dw	FERGAR									; 2
							dw	CRIRA									; 3
							dw	VICMAR									; 4

POINT_NIVEL_HATER_81:		dw	NIVEL_HATER_0							; 0
							dw	NIVEL_HATER_1							; 1
							dw	NIVEL_HATER_2							; 2
							dw	NIVEL_HATER_3							; 3
							dw	NIVEL_HATER_4							; 4

; ALGUNOS RECURSOS

copia_mas_igual_81:				dw	#000f,#0017,#0046,#0017,#001B,#0022
copia_corazon_81:				dw	#0012,#0058,#0052,#000f,#0008,#0006
copia_numero_81:				dw	#0000,#0090,#0000,#0000,#0008,#0008	
copia_numero_hater_81:			dw	#0000,#0290,#0000,#00B8,#0008,#0008

copia_escenario_a_page_1_81:	dw	#0036,#000C,#0036,#010C,#0094,#006A

copia_pulsa_espacio_81:			dw	#00Ae,#00B6,#0010,#0012
								db	#00,#00,#F0
							
cuadrado_que_limpia_PULSA_ESPACIO_81:

								dw	#0000,#0000,#00ae,#00B6,#0010,#0012
																			
PULSA_ESPACIO_81:		incbin		"SR5/MENU/PULSA ESPACIO_16x18.DAT"

; TEXTOS HATERS (367 frases de texto * 2 idiomas = 734)

HOLA_HATER_1_ESP_81:			incbin		"TEXTOS/ING/hh1es1.DAT"		; Soy Frinky. Esta es mi zona.
								incbin		"TEXTOS/ING/hh1es2.DAT"		; Soy Phantover. Esta es mi zona.
								incbin		"TEXTOS/ING/hh1es3.DAT"		; Acho tío. Soy Conchi.
								incbin		"TEXTOS/ING/hh1es4.DAT"		; Soy Kutreport. Estos son mis tiles.
HOLA_HATER_2_ESP_81				incbin		"TEXTOS/ING/hh2ES1.DAT"		; Déjame ver tu estandarte.		
								incbin		"TEXTOS/ING/hh2ES2.DAT"		; Dime a quién adoras.			
								incbin		"TEXTOS/ING/hh2ES3.DAT"		; Dime tu estandarte.		
								incbin		"TEXTOS/ING/hh2ES4.DAT"		; Qué estandarte veneras.	
PREMIO_HATER_1_ESP_81:			incbin		"TEXTOS/ING/ph1ES1.DAT"		; Por Nichi. Eres de los míos.
								incbin		"TEXTOS/ING/ph1ES2.DAT"		; Anda. Como yo. Mejor. Ya no	
								incbin		"TEXTOS/ING/ph1ES3.DAT"		; Ah. Comolmío. Pos te 
								incbin		"TEXTOS/ING/ph1ES4.DAT"		; Sí señor. Eres un tío de fiar.
PREMIO_HATER_2_ESP_81:			incbin		"TEXTOS/ING/ph2ES1.DAT"		; acepta este regalo.
								incbin		"TEXTOS/ING/ph2ES2.DAT"		; tengo edad para liarme a tetazos.
								incbin		"TEXTOS/ING/ph2ES3.DAT"		; doy bitnedas.
								incbin		"TEXTOS/ING/ph2ES4.DAT"		; Usa estas bitnedas como quieras.
TE_HIERO_HATER_1_ESP_81:		incbin		"TEXTOS/ING/thh1ES1.DAT"	; Eres blando como las teclas de
								incbin		"TEXTOS/ING/thh1ES2.DAT"	; Eso por mirarme los pellejos.     
								incbin		"TEXTOS/ING/thh1ES3.DAT"	; Pa que aprendas. coño.
								incbin		"TEXTOS/ING/thh1ES4.DAT"	; Ja ja ja. Y sin usar sprites.
TE_HIERO_HATER_2_ESP_81:		incbin		"TEXTOS/ING/thh2ES1.DAT"	; un spectrum. Me quedo tus cosas.
								incbin		"TEXTOS/ING/thh2ES2.DAT"	; me quedo con todo lo que tienes.    
								incbin		"TEXTOS/ING/thh2ES3.DAT"	; Y me quedo tus cosas.
								incbin		"TEXTOS/ING/thh2ES4.DAT"	; me quedo tus pertenencias.
NO_TE_HIERO_HATER_1_ESP_81:		incbin		"TEXTOS/ING/nthh1ES1.DAT"	; Eres más difícil de pillar
								incbin		"TEXTOS/ING/nthh1ES2.DAT"	; No me evites o de un mamellazo
								incbin		"TEXTOS/ING/nthh1ES3.DAT"	; No te apartes que si no me
								incbin		"TEXTOS/ING/nthh1ES4.DAT"	; Eres más rápido que yo. Claro. 
NO_TE_HIERO_HATER_2_ESP_81:		incbin		"TEXTOS/ING/nthh2ES1.DAT"	; que el assembly estate quieto.
								incbin		"TEXTOS/ING/nthh2ES2.DAT"	; te voy a hundir en la miseria.
								incbin		"TEXTOS/ING/nthh2ES3.DAT"	; Cuesta absorberte con el coño.
								incbin		"TEXTOS/ING/nthh2ES4.DAT"	; como soy un cutreport... 
TE_HIERO_POCO_HATER_1_ESP_81:	incbin		"TEXTOS/ING/thph1ES1.DAT"	; prepárate porque esto es sólo
								incbin		"TEXTOS/ING/thph1ES2.DAT"	; toma golpe de chumino
								incbin		"TEXTOS/ING/thph1ES3.DAT"	; Ah. Toma. Hahahahahaha.
								incbin		"TEXTOS/ING/thph1ES4.DAT"	; Toma ya. Y sin necesidad de 
TE_HIERO_POCO_HATER_2_ESP_81:	incbin		"TEXTOS/ING/thph2ES1.DAT"	; el principio de tu sufrimiento.
								incbin		"TEXTOS/ING/thph2ES2.DAT"	; fofo y descolgado.
								incbin		"TEXTOS/ING/thph2ES3.DAT"	; Ahora con la pepitilla.
								incbin		"TEXTOS/ING/thph2ES4.DAT"	; colorinchis estúpidos. 
TE_ATACO_HATER_1_ESP_81:		incbin		"TEXTOS/ING/tah1ES1.DAT"	; Vaya una mierda veneras.
								incbin		"TEXTOS/ING/tah1ES2.DAT"	; Pero qué mal gusto.
								incbin		"TEXTOS/ING/tah1ES3.DAT"	; Ah. Esa es horrible_81: No es
								incbin		"TEXTOS/ING/tah1ES4.DAT"	; Vivís de ports del nuestro.
TE_ATACO_HATER_2_ESP_81:		incbin		"TEXTOS/ING/tah2ES1.DAT"	; Te vas a cagar.	
								incbin		"TEXTOS/ING/tah2ES2.DAT"	; Ni Luís Royo adoraría eso.
								incbin		"TEXTOS/ING/tah2ES3.DAT"	; verde. Ahora te follo.
								incbin		"TEXTOS/ING/tah2ES4.DAT"	; Ahora te voy a dar caña. 
ME_HIERES_HATER_1_ESP_81:		incbin		"TEXTOS/ING/mhh1ES1.DAT"	; Ostia. Me has dado en la VRAM.
								incbin		"TEXTOS/ING/mhh1ES2.DAT"	; Coño. Qué daño. Ni azpiri
								incbin		"TEXTOS/ING/mhh1ES3.DAT"	; Ah. Mha dolío. Te voy a dar
								incbin		"TEXTOS/ING/mhh1ES4.DAT"	; Qué daño. Se me ha caído un 
ME_HIERES_HATER_2_ESP_81:		incbin		"TEXTOS/ING/mhh2ES1.DAT"	; prepárate que ahora me toca a mí.
								incbin		"TEXTOS/ING/mhh2ES2.DAT"	; me trataba así. Ahora verás.
								incbin		"TEXTOS/ING/mhh2ES3.DAT"	; Con un kilómetro de coño.
								incbin		"TEXTOS/ING/mhh2ES4.DAT"	; tile de la vram y todo. 
NO_ME_HIERES_HATER_1_ESP_81:	incbin		"TEXTOS/ING/nmhh1ES1.DAT"	; Tienes menos fuerza que una
								incbin		"TEXTOS/ING/nmhh1ES2.DAT"	; Estás más senil que yo. Ahora te
								incbin		"TEXTOS/ING/nmhh1ES3.DAT"	; Pos si no mhas dao.
								incbin		"TEXTOS/ING/nmhh1ES4.DAT"	; ja ja ja. Mi capacidad para	
NO_ME_HIERES_HATER_2_ESP_81:	incbin		"TEXTOS/ING/nmhh2ES1.DAT"	; GAME BOY. Prepárate.
								incbin		"TEXTOS/ING/nmhh2ES2.DAT"	; ataco con el bote de sintrom.
								incbin		"TEXTOS/ING/nmhh2ES3.DAT"	; Vaya mierda golpe.
								incbin		"TEXTOS/ING/nmhh2ES4.DAT"	; camuflar mis colores te confunde. 
MUERO_HATER_1_ESP_81:			incbin		"TEXTOS/ING/mh1ES1.DAT"		; haggg. Mi BIOS. No es posible.
								incbin		"TEXTOS/ING/mh1ES2.DAT"		; No vale. Me he enredado con
								incbin		"TEXTOS/ING/mh1ES3.DAT"		; Ah. Se mha luxao el coño.
								incbin		"TEXTOS/ING/mh1ES4.DAT"		; Nooooo. No volveré a portar un
MUERO_HATER_2_ESP_81:			incbin		"TEXTOS/ING/mh2ES1.DAT"		; siempre odiaré tu estandarte.
								incbin		"TEXTOS/ING/mh2ES2.DAT"		; el pelo. Dame un peine.
								incbin		"TEXTOS/ING/mh2ES3.DAT"		; Pero volveré.
								incbin		"TEXTOS/ING/mh2ES4.DAT"		; juego y dejarlo sin música.
COBARDE_1_ESP_81:				incbin		"TEXTOS/ING/c1ES1.DAT"		; No huyas gallina o te meto el
								incbin		"TEXTOS/ING/c1es2.DAT"		; Si te vuelvo a ver te rajo
								incbin		"TEXTOS/ING/c1ES3.DAT"		; Ande vaaaaaaas.
								incbin		"TEXTOS/ING/c1ES4.DAT"		; Cobarde. Luego os quejáis si no
COBARDE_2_ESP_81:				incbin		"TEXTOS/ING/c2ES1.DAT"		; Estandarte en el puerto del ratón.
								incbin		"TEXTOS/ING/c2ES2.DAT"		; la cara con un pezón.
								incbin		"TEXTOS/ING/c2ES3.DAT"		; Galliiiiiiina.
								incbin		"TEXTOS/ING/c2ES4.DAT"		; hacen juegos para vuestro sistema.
NO_PUEDES_ESCAPAR_ESP_81:		incbin		"TEXTOS/ING/npeES1.DAT"		; No puedes escapar de mí.
								incbin		"TEXTOS/ING/npeES2.DAT"		; Ni lo intentes o te meto.
								incbin		"TEXTOS/ING/npeES3.DAT"		; Que te lo has creío.
								incbin		"TEXTOS/ING/npeES4.DAT"		; Eso no va a ocurrir.
LANZA_ATACAR_81:				incbin		"TEXTOS/ING/ldpa.DAT"		; Lanza el dado para atacar.							
LANZA_DEFENDER_81:				incbin		"TEXTOS/ING/ldpd.DAT"		; Lanza el dado para defenderte.							

; TEXTOS POCHADEROS

HOLA_POCHADA_1_ESP_81:			incbin		"TEXTOS/ING/hp1neESP.DAT"	; Choy Némechich el pochadero.
								incbin		"TEXTOS/ING/hp1piESP.DAT"	; Choy Pichi la pochadera.
								incbin		"TEXTOS/ING/hp1cuESP.DAT"	; Choy Chumi el pochadero.
								incbin		"TEXTOS/ING/hp1caESP.DAT"	; Choy Chari la pochadera.
HOLA_POCHADA_2_ESP_81:			incbin		"TEXTOS/ING/hp2neesp.DAT"	; Puedo venderte una nave.
								incbin		"TEXTOS/ING/hp2piesp.DAT"	; Te puedo bailar una polka.
								incbin		"TEXTOS/ING/hp2cuesp.DAT"	; Dime qué puedo hacher por ti.
								incbin		"TEXTOS/ING/hp2caesp.DAT"	; Tengo unoch tapetech muy baratoch.
BUENAS_NOCHES_ESP_81:			incbin		"TEXTOS/ING/bnneesp.DAT"	; Que chueñech con echtrellach.
								incbin		"TEXTOS/ING/bnpiesp.DAT"	; Te achigno la habitachión rocha.
								incbin		"TEXTOS/ING/bncuesp.DAT"	; Buenach nochech.
								incbin		"TEXTOS/ING/bncaesp.DAT"	; Te he preparado la camita.
NO_PUEDES_COMPRAR_ESP_81:		incbin		"TEXTOS/ING/npcneesp.DAT"	; Te faltan bitnedach para echo.
								incbin		"TEXTOS/ING/npcpiesp.DAT"	; No puedech pagarlo.
								incbin		"TEXTOS/ING/npccuesp.DAT"	; No tienech fondoch para echo.
								incbin		"TEXTOS/ING/npccaesp.DAT"	; Cariño, no pudech comprar echo.
ADIOS_ESP_81:					incbin		"TEXTOS/ING/aneesp.DAT"		; Que el echpachio te acompañe.
								incbin		"TEXTOS/ING/apiesp.DAT"		; que te vaya bonito.
								incbin		"TEXTOS/ING/acuesp.DAT"		; hachta otra.
								incbin		"TEXTOS/ING/acaesp.DAT"		; Echpero verte pronto, bonito.
GRACIAS_ESP_81:					incbin		"TEXTOS/ING/gneesp.DAT"		; De regalo, un pin de konami.
								incbin		"TEXTOS/ING/gpiesp.DAT"		; Tu dinero ech bienvenido.
								incbin		"TEXTOS/ING/gcuesp.DAT"		; Grachiach por tu compra.
								incbin		"TEXTOS/ING/gcaesp.DAT"		; Por comprar te regalo un tapete.
PASAR_LA_NOCHE_ESP_81:			incbin		"TEXTOS/ING/plnESP.DAT"		; una noche cuechta treinta bitnedach.
PAGA_30_ESP_81:					incbin		"TEXTOS/ING/p30ESP.DAT"		; echto cuechta treinta bitnedach.
PAGA_60_ESP_81:					incbin		"TEXTOS/ING/p60ESP.DAT"		; echto cuechta chechenta bitnedach.
PAGA_90_ESP_81:					incbin		"TEXTOS/ING/p90ESP.DAT"		; echto cuechta noventa bitnedach.
SALIR_ESP_81:					incbin		"TEXTOS/ING/sESP.DAT"		; echta ech la puerta de chalida.
TRAMPA_COMP_1_ESP_81:			incbin		"TEXTOS/ING/TC1ESP.DAT"		; Trampa: pulsa space o fire durante				
TRAMPA_COMP_2_ESP_81:			incbin		"TEXTOS/ING/TC2ESP.DAT"		; un desplazamiento para colocarla.
ESTANTE_VACIO_ESP_81:			incbin		"TEXTOS/ING/EVESP.DAT"		; Este estante está vacío.

; TEXTOS DEL PERGAMINO

NO_PUEDE_ESCRIBIR_ESP_81:		incbin		"TEXTOS/ING/npeESP.DAT"		; Busca pluma y tinta para pintar aquí
NO_TIENES_PAPEL_ESP_81:			incbin		"TEXTOS/ING/ntpESP.DAT"		; Aún no dispones del pergamino
TRAMPA_SI_1_ESP_81:				incbin		"TEXTOS/ING/TS1ESP.DAT"		; Colocas una trampa en esa zona.
TRAMPA_SI_2_ESP_81:				incbin		"TEXTOS/ING/TS2ESP.DAT"		; El siguiente visitante sufrirá.				
TRAMPA_NO_1_ESP_81:				incbin		"TEXTOS/ING/TN1ESP.DAT"		; No es una zona adecuada para
TRAMPA_NO_2_ESP_81:				incbin		"TEXTOS/ING/TN2ESP.DAT"		; poner trampas. Se ve demasiado.

; TEXTOS SOBRE OBJETOS
							
BRUJULA_1_ESP_81:				incbin		"TEXTOS/ING/bruju1.DAT"		; has encontrado una brújula:
BRUJULA_2_ESP_81:				incbin		"TEXTOS/ING/bruju2.DAT"		; ahora puedes localizar el norte			
LLAVE_1_ESP_81:					incbin		"TEXTOS/ING/llave1.DAT"		; has encontrado la llave:						
LLAVE_2_ESP_81:					incbin		"TEXTOS/ING/llave2.DAT"		; úsala para salir de la mazmorra				
TINTA_1_ESP_81:					incbin		"TEXTOS/ING/tinta.DAT"		; has encontrado un tintero:						
PLUMA_1_ESP_81:					incbin		"TEXTOS/ING/pluma.DAT"		; has encontrado una pluma:						
PLUMA_2_ESP_81:					incbin		"TEXTOS/ING/tinplu.DAT"		; indispensable para pintar mapas				
PAPIRO_1_ESP_81:				incbin		"TEXTOS/ING/perga1.DAT"		; has encontrado un pergamino:
PAPIRO_2_ESP_81:				incbin		"TEXTOS/ING/perga2.DAT"		; consúltalo con: tecla M o botón dos			
ESPADA_1_ESP_81:				incbin		"TEXTOS/ING/espada.DAT"		; has encontrado una espada:					
CUCHILLO_1_ESP_81:				incbin		"TEXTOS/ING/daga.DAT"		; has encontrado un cuchillo:					
CUCHILLO_2_ESP_81:				incbin		"TEXTOS/ING/espadaga.DAT"	; aumenta tu ataque								
BOTA_ESP_1_ESP_81:				incbin		"TEXTOS/ING/botasra.DAT"	; has encontrado unas botas rápidas:			
BOTA_1_ESP_81:					incbin		"TEXTOS/ING/botas.DAT"		; has encontrado unas botas:						
BOTA_2_ESP_81:					incbin		"TEXTOS/ING/botbotra.DAT"	; aumentan tu velocidad		
BITNEDA_1_ESP_81:				incbin		"TEXTOS/ING/bitneda.DAT"	; has encontrado una bitneda					
BITNEDAS_1_ESP_81:				incbin		"TEXTOS/ING/bitnedas.DAT"	; has encontrado cinco bitnedas				
CASCO_1_ESP_81:					incbin		"TEXTOS/ING/casco.DAT"		; has encontrado un casco:					
ARMADURA_1_ESP_81:				incbin		"TEXTOS/ING/armadura.DAT"	; has encontrado una armadura:				
ARMADURA_2_ESP_81:				incbin		"TEXTOS/ING/arm2esp.DAT"	; aumenta tu defensa en un punto				
MANZANA_1_ESP_81:				incbin		"TEXTOS/ING/manzana.DAT"	; una pieza de fruta mejora tu vida
LUPA_1_ESP_81:					incbin		"TEXTOS/ING/lampara1.DAT"	; has encontrado una lámpara:				
LUPA_2_ESP_81:					incbin		"TEXTOS/ING/lampara2.DAT"	; acaba turno con space o botón uno
AGUJERO_1_ESP_81:				incbin		"TEXTOS/ING/aguneg1.DAT"	; has caido en un agujero negro:	
AGUJERO_2_ESP_81:				incbin		"TEXTOS/ING/aguneg2.DAT"	; apareces en otra zona de la mazmorra		
TRAMPA_1_ESP_81:				incbin		"TEXTOS/ING/trampa1.DAT"	; has caido en una trampa				
TRAMPA_2_ESP_81:				incbin		"TEXTOS/ING/trampa2.DAT"	; pierdes bastante vida
GALLINA_ESP_81:					incbin		"TEXTOS/ING/gallina.DAT"	; Evita una reyerta con M o botón dos
PERRO_1_ESP_81:					incbin		"TEXTOS/ING/perr1esp.DAT"	; Te haces amigo de un perro
PERRO_2_ESP_81:					incbin		"TEXTOS/ING/perr2esp.DAT"	; abandonado. Seguro que te ayuda. 
PERRO_3_ESP_81:					incbin		"TEXTOS/ING/perr3esp.DAT"	; Rastrea jugadores pulsando space 
PERRO_4_ESP_81:					incbin		"TEXTOS/ING/perr4esp.DAT"	; o botón 1 mientras ves el mapa.
BOTAS_CU_81:					incbin		"TEXTOS/ING/bmuavesp.DAT"	; Botas. Más uno en velocidad.
BOTAS_ESP_CU_81:				incbin		"TEXTOS/ING/bemdaesp.DAT"	; Botas especiales. Más dos en velocidad.
CUCHILLO_CU_81:					incbin		"TEXTOS/ING/cmuaaesp.DAT"	; Cuchillo. Más uno en ataque.
ESPADA_CU_81:					incbin		"TEXTOS/ING/emdaaesp.DAT"	; Espada. Más dos en ataque.
CASCO_CU_81:					incbin		"TEXTOS/ING/cmuadesp.DAT"	; Casco. Más uno en defensa acumulable.
ARMADURA_CU_81:					incbin		"TEXTOS/ING/amuadesp.DAT"	; Armadura. Más uno en defensa acumulable.

; TEXTOS SOBRE LA PARTIDA

COMIENZA_1_ESP_81:				incbin		"TEXTOS/ING/c1ESP.DAT"		; Comienza la aventura. Encuentra
COMIENZA_2_ESP_81:				incbin		"TEXTOS/ING/c2ESP.DAT"		; El camino hacia las catacumbas.
COMIENZAN_2_1_ESP_81:			incbin		"TEXTOS/ING/c21ESP.DAT"		; Comienza el enfrentamiento. Sal
COMIENZAN_2_2_ESP_81:			incbin		"TEXTOS/ING/c22ESP.DAT"		; el primero de esta mazmorra.
GOLPE_CONTRA_PARED_ESP_81:		incbin		"TEXTOS/ING/gcpESP.DAT"		; Aunch. Cómo duele.
TERMINA_TURNO_ESP_81:			incbin		"TEXTOS/ING/ttESP.DAT"		; Has decidido acabar aquí tu turno.
NO_SALIDA_EN_SALIDA_1_ESP_81:	incbin		"TEXTOS/ING/nses1ESP.DAT"	; La puerta de salida está cerrada
NO_SALIDA_EN_SALIDA_2_ESP_81:	incbin		"TEXTOS/ING/nses2ESP.DAT"	; y no podrás salir sin la llave.
NO_SALIDA_1_ESP_81:				incbin		"TEXTOS/ING/ns1ESP.DAT"		; esta puerta está inutilizada.
ME_MUERO_1_ESP_81:				incbin		"TEXTOS/ING/mm1ESP.DAT"		; Has muerto. 
ME_MUERO_2_ESP_81:				incbin		"TEXTOS/ING/mm2ESP.DAT"		; Fin de la partida.
ME_MUERO_3_ESP_81:				incbin		"TEXTOS/ING/mm3ESP.DAT"		; Tu cadáver será encontrado dentro de
ME_MUERO_4_ESP_81:				incbin		"TEXTOS/ING/mm4ESP.DAT"		; diez años sobre un teclado ochentero.
ME_MUERO_5_ESP_81:				incbin		"TEXTOS/ING/mm5ESP.DAT"		; tu contrincante tendrá que soportar
ME_MUERO_6_ESP_81:				incbin		"TEXTOS/ING/mm6ESP.DAT"		; un bochorno terrible.
ME_MUERO_7_ESP_81:				incbin		"TEXTOS/ING/mm7ESP.DAT"		; El de ganar porque tú has perdido.
ME_MUERO_8_ESP_81:				incbin		"TEXTOS/ING/mm8ESP.DAT"		; pobre. Qué penita nos da a todos.
TEXTO_EN_BLANCO_81:				incbin		"TEXTOS/tebESP.DAT"			; (No escribe nada)
HAY_ALGUIEN_ESP_81:				incbin		"TEXTOS/ING/haesp.DAT"		; Aqui hay alguien.
FIN_DE_TURNO_ESP_81:			incbin		"TEXTOS/ING/fdtesp.DAT"		; Se acabó el turno.
AVISO_CODIGO_ESP1_81:			incbin		"TEXTOS/ING/acesp1.DAT"		; coge papel y pluma y
AVISO_CODIGO_ESP2_81:			incbin		"TEXTOS/ING/acesp2.DAT"		; apunta el siguiente código	
AVISO_CODIGO_ESP3_81:			incbin		"TEXTOS/ING/acesp3.DAT"		; te servirá para iniciar tu
AVISO_CODIGO_ESP4_81:			incbin		"TEXTOS/ING/acesp4.DAT"		; aventura desde aquí.
HAS_GANADO_1_ESP_81:			incbin		"TEXTOS/ING/hg1esp1.DAT"	; La suerte sonríe a Natpu.
								incbin		"TEXTOS/ING/hg1esp2.DAT"	; Fergar es el campeón de la jornada
								incbin		"TEXTOS/ING/hg1esp3.DAT"	; No hay una campeona más completa
								incbin		"TEXTOS/ING/hg1esp4.DAT"	; Vicmar nos complace con su
HAS_GANADO_2_ESP_81:			incbin		"TEXTOS/ING/hg2esp1.DAT"	; Es el momento de celebrarlo.
								incbin		"TEXTOS/ING/hg2esp2.DAT"	; El gorg debe correr a raudales.
								incbin		"TEXTOS/ING/hg2esp3.DAT"	; que Crira. Es la mejor.
								incbin		"TEXTOS/ING/hg2esp4.DAT"	; triunfo. Es un ganador nato.
HAS_GANADO_3_ESP_81:			incbin		"TEXTOS/ING/hg3esp1.DAT"	; MIentras Natpu se emborracha
								incbin		"TEXTOS/ING/hg3esp2.DAT"	; Dejémosle emborrachándose mientras
								incbin		"TEXTOS/ING/hg3esp3.DAT"	; Brindemos por su tenacidad y
								incbin		"TEXTOS/ING/hg3esp4.DAT"	; Los 8 bits salven su alma
HAS_GANADO_4_ESP_81:			incbin		"TEXTOS/ING/hg4esp1.DAT"	; anunciamos el fin de la partida.
								incbin		"TEXTOS/ING/hg4esp2.DAT"	; damos por finalizada la partida.
								incbin		"TEXTOS/ING/hg4esp3.DAT"	; demos por terminado el juego.
								incbin		"TEXTOS/ING/hg4esp4.DAT"	; al terminar este juego.
PASA_MAZMORRA_ESP_81:			incbin		"TEXTOS/ING/pf1jesp.DAT"	; vamos a la siguiente mazmorra.							

; TEXTOS SOBRE LOS VIEJIGUIAS

SOY_ANDRES_SAMUDIO_ESP_1_81:	incbin		"TEXTOS/ING/sasesp1.DAT"	; soy ansam. el viejiguía.
SOY_CESAR_ASTUDILLO_ESP_1_81:	incbin		"TEXTOS/ING/scaesp1.DAT"	; soy ceas. el viejiguía.	
SOY_CAROL_SHAW_ESP_1_81:		incbin		"TEXTOS/ING/scsesp1.DAT"	; soy casha. la viejiguía.	
SOY_JENNELL_JAQUAYS_ESP_1_81:	incbin		"TEXTOS/ING/sjjesp1.DAT"	; soy jeja. la viemiguía.	
SOY_ANDRES_SAMUDIO_ESP_2_81:	incbin		"TEXTOS/ING/sasesp2.DAT"	; señor de las conversacionales.	
SOY_CESAR_ASTUDILLO_ESP_2_81:	incbin		"TEXTOS/ING/scaesp2.DAT"	; músico insuperable.	
SOY_CAROL_SHAW_ESP_2_81:		incbin		"TEXTOS/ING/scsesp2.DAT"	; diosa del vuelo entre ríos.	
SOY_JENNELL_JAQUAYS_ESP_2_81:	incbin		"TEXTOS/ING/sjjesp2.DAT"	; creadora de kong.	
VIEJIGUIA_POCHADA_ESP_81:		incbin		"TEXTOS/ING/vpesp.DAT"		; encontrarás una bonita pochada				
VIEJIGUIA_LLAVE_ESP_81:			incbin		"TEXTOS/ING/vlesp.DAT"		; encontrarás la preciada llave
VIEJIGUIA_SALIDA_ESP_81:		incbin		"TEXTOS/ING/vsesp.DAT"		; encontrarás la ansiada salida				
N_ESP_81:						incbin		"TEXTOS/ING/norte.DAT"		; si viajas hacia el norte					
NE_ESP_81:						incbin		"TEXTOS/ING/noreste.DAT"	; si viajas hacia el noreste			
E_ESP_81:						incbin		"TEXTOS/ING/este.DAT"		; si viajas hacia el este
SE_ESP_81:						incbin		"TEXTOS/ING/sureste.DAT"	; si viajas hacia el sureste
S_ESP_81:						incbin		"TEXTOS/ING/sur.DAT"		; si viajas hacia el sur
SO_ESP_81:						incbin		"TEXTOS/ING/suroeste.DAT"	; si viajas hacia el suroeste
O_ESP_81:						incbin		"TEXTOS/ING/oeste.DAT"		; si viajas hacia el oeste
NO_ESP_81:						incbin		"TEXTOS/ING/noroeste.DAT"	; si viajas hacia el noroeste

; TEXTOS SOBRE LA PELEA 

COINCIDE_1_ESP_81:				incbin		"TEXTOS/ING/co1esp.DAT"		; Te encuentras con otro humano.
COINCIDE_2_ESP_81:				incbin		"TEXTOS/ING/co2esp.DAT"		; Tus intenciones son...
HOSTIL_AMISTOSO_1_ESP_81:		incbin		"TEXTOS/ING/ha1esp.DAT"		; espacio o boton 1 _81: hostiles.
HOSTIL_AMISTOSO_2_ESP_81:		incbin		"TEXTOS/ING/ha2esp.DAT"		; M o boton 2_81: amistosas.
RESPUESTA_1_ESP_81:				incbin		"TEXTOS/ING/r1esp.DAT"		; Ha aparecido alguien amigable.
ATRINCHERA_1_ESP_81:			incbin		"TEXTOS/ING/atr1esp.DAT"	; Pasáis la noche al raso
ATRINCHERA_2_ESP_81:			incbin		"TEXTOS/ING/atr2esp.DAT"	; haciendo guardias.
ATRINCHERA_3_ESP_81:			incbin		"TEXTOS/ING/atr3esp.DAT"	; Recuperáis energías y al
ATRINCHERA_4_ESP_81:			incbin		"TEXTOS/ING/atr4esp.DAT"	; amanecer seguís vuestro camino.
COMPARA_1_ESP_81:				incbin		"TEXTOS/ING/com1esp.DAT"	; haceis amistad y acabais
COMPARA_2_ESP_81:				incbin		"TEXTOS/ING/com2esp.DAT"	; comparando vuestros mapas.
COMPARA_3_ESP_81:				incbin		"TEXTOS/ING/com3esp.DAT"	; ahora los dos tenéis el mismo
COMPARA_4_ESP_81:				incbin		"TEXTOS/ING/com4esp.DAT"	; mapa, pero más completo.
DEDUCE_1_ESP_81:				incbin		"TEXTOS/ING/ded1esp.DAT"	; comparando los mapas os
DEDUCE_2_ESP_81:				incbin		"TEXTOS/ING/ded2esp.DAT"	; dais cuenta de tres cosas_81:
DEDUCE_3_ESP_81:				incbin		"TEXTOS/ING/ded3esp.DAT"	; dónde deben estar las salidas
DEDUCE_4_ESP_81:				incbin		"TEXTOS/ING/ded4esp.DAT"	; llaves y pochadas. lo apuntáis.
INTERCAMBIAN_1_ESP_81:			incbin		"TEXTOS/ING/int1esp.DAT"	; Como paisanos del mismo pueblo
INTERCAMBIAN_2_ESP_81:			incbin		"TEXTOS/ING/int2esp.DAT"	; decidís compartir ganancias.
INTERCAMBIAN_3_ESP_81:			incbin		"TEXTOS/ING/int3esp.DAT"	; El que más bitnedas tiene
INTERCAMBIAN_4_ESP_81:			incbin		"TEXTOS/ING/int4esp.DAT"	; ayudará al que menos tiene.
BORRA_1_ESP_81:					incbin		"TEXTOS/ING/bor1esp.DAT"	; Te acercas amistosamente.
BORRA_2_ESP_81:					incbin		"TEXTOS/ING/bor2esp.DAT"	; Pero en un descuidos...
BORRA_3_ESP_81:					incbin		"TEXTOS/ING/bor3esp.DAT"	; Borras su mapa con la mano
BORRA_4_ESP_81:					incbin		"TEXTOS/ING/bor4esp.DAT"	; mojada y sales corriendo.
QUITA_TURNO_1_ESP_81:			incbin		"TEXTOS/ING/qtu1esp.DAT"	; Aprovechas un momento de
QUITA_TURNO_2_ESP_81:			incbin		"TEXTOS/ING/qtu2esp.DAT"	; descuido de tu oponente y...
QUITA_TURNO_3_ESP_81:			incbin		"TEXTOS/ING/qtu3esp.DAT"	; Le golpeas en la cabeza.
QUITA_TURNO_4_ESP_81:			incbin		"TEXTOS/ING/qtu4esp.DAT"	; El pobre descansará un turno.
QUITA_1_ESP_81:					incbin		"TEXTOS/ING/qui1esp.DAT"	; Te acercas sibilinamente
QUITA_2_ESP_81:					incbin		"TEXTOS/ING/qui2esp.DAT"	; mostrándote amistoso...
QUITA_3_ESP_81:					incbin		"TEXTOS/ING/qui3esp.DAT"	; En cuanto se confía, tiras
QUITA_4_ESP_81:					incbin		"TEXTOS/ING/qui4esp.DAT"	; de su zurrón y sales corriendo.

; TEXTOS PELEAS FINALES

TROMAXE_01_81:					incbin		"TEXTOS/ING/troma01.DAT"	; Soy Tromaxe. Quién eres tú.
TROMAXE_021_81:					incbin		"TEXTOS/ING/troma021.DAT"	; Soy Fergar.
TROMAXE_022_81:					incbin		"TEXTOS/ING/troma022.DAT"	; Soy Natpu.
TROMAXE_023_81:					incbin		"TEXTOS/ING/troma023.DAT"	; Soy Crira.
TROMAXE_024_81:					incbin		"TEXTOS/ING/troma024.DAT"	; Soy Vicmar.
TROMAXE_03_81:					incbin		"TEXTOS/ING/troma03.DAT"	; de la ciudad de Viejunos.
TROMAXE_04_81:					incbin		"TEXTOS/ING/troma04.DAT"	; Y vengo a acabar
TROMAXE_05_81:					incbin		"TEXTOS/ING/troma05.DAT"	; con todos los cotorras.
TROMAXE_06_81:					incbin		"TEXTOS/ING/troma06.DAT"	; ja, ja, ja. Qué petulante.
TROMAXE_07_81:					incbin		"TEXTOS/ING/troma07.DAT"	; Antes tendrás que pasar
TROMAXE_08_81:					incbin		"TEXTOS/ING/troma08.DAT"	; por encima de mi cadaver.
TROMAXE_09_81:					incbin		"TEXTOS/ING/troma09.DAT"	; Puta mosca. Sal de aquí.
TROMAXE_10_81:					incbin		"TEXTOS/ING/troma10.DAT"	; Muere, retroperro!
TROMAXE_11_81:					incbin		"TEXTOS/ING/troma11.DAT"	; Oh. Me has hecho correr tanto
TROMAXE_12_81:					incbin		"TEXTOS/ING/troma12.DAT"	; que he adelgazado. Mil gracias.
TROMAXE_13_81:					incbin		"TEXTOS/ING/troma13.DAT"	; como recompensa, te dejaré pasar
TROMAXE_14_81:					incbin		"TEXTOS/ING/troma14.DAT"	; a la siguiente mazmorra.
TROMAXE_15_81:					incbin		"TEXTOS/ING/troma15.DAT"	; gracias, pero...
TROMAXE_16_81:					incbin		"TEXTOS/ING/troma16.DAT"	; qué era eso negro que me lanzabas.
TROMAXE_17_81:					incbin		"TEXTOS/ING/troma17.DAT"	; fundas de ordenadores.
TROMAXE_18_81:					incbin		"TEXTOS/ING/troma18.DAT"	; las usaba para atacar
TROMAXE_19_81:					incbin		"TEXTOS/ING/troma19.DAT"	; a los habitantes de viejunos
TROMAXE_20_81:					incbin		"TEXTOS/ING/troma20.DAT"	; creo que ahora
TROMAXE_21_81:					incbin		"TEXTOS/ING/troma21.DAT"	; me dedicaré a venderlas.
TROMAXE_22_81:					incbin		"TEXTOS/ING/troma22.DAT"	; por cierto.
TROMAXE_23_81:					incbin		"TEXTOS/ING/troma23.DAT"	; el paso a la siguiente mazmorra
TROMAXE_24_81:					incbin		"TEXTOS/ING/troma24.DAT"	; es muy estrecho.
TROMAXE_25_81:					incbin		"TEXTOS/ING/troma25.DAT"	; tendrás que dejar todas tus pertenencias.
TROMAXE_26_81:					incbin		"TEXTOS/ING/troma26.DAT"	; llévate sólo el zurrón con 
TROMAXE_27_81:					incbin		"TEXTOS/ING/troma27.DAT"	; las bitnedas. Las vas a necesitar.

ONIRIKUS_01_81:					incbin		"TEXTOS/ING/onir01.DAT"		; Soy Onirikus.
ONIRIKUS_02_81:					incbin		"TEXTOS/ING/onir02.DAT"		; Yo soy...
ONIRIKUS_03_81:					incbin		"TEXTOS/ING/onir03.DAT"		; Picha. Me importa una mierda.
ONIRIKUS_04_81:					incbin		"TEXTOS/ING/onir04.DAT"		; Te voy a joder más que una
ONIRIKUS_05_81:					incbin		"TEXTOS/ING/onir05.DAT"		; procesión por debajo de tu casa.
ONIRIKUS_06_81:					incbin		"TEXTOS/ING/onir06.DAT"		; Está bien. Me rindo.
ONIRIKUS_07_81:					incbin		"TEXTOS/ING/onir07.DAT"		; De dónde sacas tantos niños.
ONIRIKUS_08_81:					incbin		"TEXTOS/ING/onir08.DAT"		; Son todos míos. Soy muy fecundo.
ONIRIKUS_09_81:					incbin		"TEXTOS/ING/onir09.DAT"		; Pues nada. A cuidarlos todos.
ONIRIKUS_10_81:					incbin		"TEXTOS/ING/onir10.DAT"		; No sé de dónde voy a sacar tiempo
ONIRIKUS_11_81:					incbin		"TEXTOS/ING/onir11.DAT"		; para programar.

SALGUERI_01_81:					incbin		"TEXTOS/ING/salg01.DAT"		; Soy salueri, el temible.
SALGUERI_021_81:				incbin		"TEXTOS/ING/salg021.DAT"	; tú debes ser Fergar.
SALGUERI_022_81:				incbin		"TEXTOS/ING/salg022.DAT"	; tú debes ser Natpu.
SALGUERI_023_81:				incbin		"TEXTOS/ING/salg023.DAT"	; tú debes ser Crira.
SALGUERI_024_81:				incbin		"TEXTOS/ING/salg024.DAT"	; tú debes ser Vicmar.
SALGUERI_03_81:					incbin		"TEXTOS/ING/salg03.DAT"		; no tienes nada que hacer contra mí.
SALGUERI_04_81:					incbin		"TEXTOS/ING/salg04.DAT"		; muestra tu arma.
SALGUERI_051_81:				incbin		"TEXTOS/ING/salg051.DAT"	; tengo piedras.
SALGUERI_052_81:				incbin		"TEXTOS/ING/salg052.DAT"	; tengo este puñal.
SALGUERI_053_81:				incbin		"TEXTOS/ING/salg053.DAT"	; tengo esta espada.
SALGUERI_06_81:					incbin		"TEXTOS/ING/salg06.DAT"		; vaya una mierda de arma.
SALGUERI_07_81:					incbin		"TEXTOS/ING/salg07.DAT"		; me voy a divertir contigo.
SALGUERI_08_81:					incbin		"TEXTOS/ING/salg08.DAT"		; vaya. con tant ostia lo veo
SALGUERI_09_81:					incbin		"TEXTOS/ING/salg09.DAT"		; todo diferente.
SALGUERI_10_81:					incbin		"TEXTOS/ING/salg10.DAT"		; ya no quiero acabar con los sistemas.
SALGUERI_11_81:					incbin		"TEXTOS/ING/salg11.DAT"		; prefiero hacer juegos como churros.
SALGUERI_12_81:					incbin		"TEXTOS/ING/salg12.DAT"		; gracias.
SALGUERI_13_81:					incbin		"TEXTOS/ING/salg13.DAT"		; de nada, pero...
SALGUERI_14_81:					incbin		"TEXTOS/ING/salg14.DAT"		; qué eran esas cosas
SALGUERI_15_81:					incbin		"TEXTOS/ING/salg15.DAT"		; cuadradas que me tirabas.
SALGUERI_16_81:					incbin		"TEXTOS/ING/salg16.DAT"		; cartuchos. alguien dijo que me
SALGUERI_17_81:					incbin		"TEXTOS/ING/salg17.DAT"		; quedé con todas las existencias.
SALGUERI_18_81:					incbin		"TEXTOS/ING/salg18.DAT"		; ya que me criticaban igualmente
SALGUERI_19_81:					incbin		"TEXTOS/ING/salg19.DAT"		; decidí robarlas todas.
SALGUERI_20_81:					incbin		"TEXTOS/ING/salg20.DAT"		; ahora creo que las llenaré
SALGUERI_21_81:					incbin		"TEXTOS/ING/salg21.DAT"		; con juegos del pasado.


LUCKYLUKEB_01_81:				incbin		"TEXTOS/ING/luck01.DAT"		; oy Luckylukeb.
LUCKYLUKEB_02_81:				incbin		"TEXTOS/ING/luck02.DAT"		; el terrible, el abominable...
LUCKYLUKEB_03_81:				incbin		"TEXTOS/ING/luck03.DAT"		; el enemigo final, vamos.
LUCKYLUKEB_04_81:				incbin		"TEXTOS/ING/luck04.DAT"		; en resumen_81: si me vences
LUCKYLUKEB_05_81:				incbin		"TEXTOS/ING/luck05.DAT"		; se acaba el juego.
LUCKYLUKEB_061_81:				incbin		"TEXTOS/ING/luck061.DAT"	; pues no he llegado hasta aquí
LUCKYLUKEB_062_81:				incbin		"TEXTOS/ING/luck062.DAT"	; para perder.
LUCKYLUKEB_07_81:				incbin		"TEXTOS/ING/luck07.DAT"		; cañña. ,arocón.
LUCKYLUKEB_08_81:				incbin		"TEXTOS/ING/luck08.DAT"		; te voy a poner el culo
LUCKYLUKEB_09_81:				incbin		"TEXTOS/ING/luck09.DAT"		; como la bandera de japón.
LUCKYLUKEB_10_81:				incbin		"TEXTOS/ING/luck10.DAT"		; ups. He hecho un pareado.
LUCKYLUKEB_11_81:				incbin		"TEXTOS/ING/luck11.DAT"		; el que nace artista...
LUCKYLUKEB_12_81:				incbin		"TEXTOS/ING/luck12.DAT"		; para, para, para...
LUCKYLUKEB_13_81:				incbin		"TEXTOS/ING/luck13.DAT"		; está bien. Me rindo.
LUCKYLUKEB_14_81:				incbin		"TEXTOS/ING/luck14.DAT"		; no entiendo por qué has hecho
LUCKYLUKEB_15_81:				incbin		"TEXTOS/ING/luck15.DAT"		; todo esto.
LUCKYLUKEB_16_81:				incbin		"TEXTOS/ING/luck16.DAT"		; por qué odias al resto de
LUCKYLUKEB_17_81:				incbin		"TEXTOS/ING/luck17.DAT"		; sistemas.
LUCKYLUKEB_18_81:				incbin		"TEXTOS/ING/luck18.DAT"		; yo no los odio. pero el juego
LUCKYLUKEB_19_81:				incbin		"TEXTOS/ING/luck19.DAT"		; está lleno de personajes reales.
LUCKYLUKEB_20_81:				incbin		"TEXTOS/ING/luck20.DAT"		; no querrás que ponga de enemigo
LUCKYLUKEB_21_81:				incbin		"TEXTOS/ING/luck21.DAT"		; final a otro y que se acabe enfandando.
LUCKYLUKEB_22_81:				incbin		"TEXTOS/ING/luck22.DAT"		; ya sabes cómo somos los de msx
LUCKYLUKEB_23_81:				incbin		"TEXTOS/ING/luck23.DAT"		; bueno. Esperemos que este juego
LUCKYLUKEB_24_81:				incbin		"TEXTOS/ING/luck24.DAT"		; sirva para hermanar sistemas.
LUCKYLUKEB_25_81:				incbin		"TEXTOS/ING/luck25.DAT"		; Empecemos por hermanarnos entre
LUCKYLUKEB_26_81:				incbin		"TEXTOS/ING/luck26.DAT"		; nosotros y ya luego vamos viendo.
LUCKYLUKEB_27_81:				incbin		"TEXTOS/ING/luck27.DAT"		; Si sales por esta puerta podrás
LUCKYLUKEB_28_81:				incbin		"TEXTOS/ING/luck28.DAT"		; acceder al final del juego


MUERTE_1_81:					incbin		"TEXTOS/ING/muer1esp.dat"	; ja, ja, ja. Nunca os libraréis
MUERTE_2_81:					incbin		"TEXTOS/ING/muer2esp.dat"	; de nosotros los COTORRAS.

; TEXTOS NOBRES PROPIOS

NOMBRE_NATPU_ESP_81:			incbin		"TEXTOS/ING/nnesp.DAT"		; turno de Natpu
NOMBRE_FERGAR_ESP_81:			incbin		"TEXTOS/ING/nfesp.DAT"		; turno de Fergar
NOMBRE_CRIRA_ESP_81:			incbin		"TEXTOS/ING/ncesp.DAT"		; turno de Crira
NOMBRE_VICMAR_ESP_81:			incbin		"TEXTOS/ING/nvesp.DAT"		; turno de Vicmar

		ds		#c000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 82 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 83 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI1:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT01"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 83 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 84 DEL MEGAROM **********

; COMIC PRESENTACION 2

		org		#8000
		
COM_PRESI2:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT02"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 84 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 85 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI3:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT03"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 85 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 86 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI4:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT04"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 86 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 87 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI5:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT05"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 87 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 88 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI6:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT06"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 88 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 89 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI7:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT07"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 89 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 90 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI8:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT08"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 90 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 91 DEL MEGAROM **********

; COMIC PRESENTACION 1

		org		#8000
		
COM_PRESI9:							incbin		"SR5/COMICS/PRESENTACION/COMIC_APERTURA_I.DAT09"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 91 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 92 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI1:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT01"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 92 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 93 DEL MEGAROM **********

; COMIC CIERRE INGLES 2

		org		#8000
		
COM_CIERI2:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT02"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 93 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 94 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI3:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT03"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 94 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 95 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI4:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT04"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 95 DEL MEGAROM **********)))	

; ______________________________________________________________________
	
; (((********** PAGINA 96 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI5:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT05"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 96 DEL MEGAROM **********)))	

; ______________________________________________________________________	

; (((********** PAGINA 97 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI6:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT06"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 97 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 98 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI7:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT07"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 98 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 99 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI8:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT08"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 99 DEL MEGAROM **********)))	

; ______________________________________________________________________	
; (((********** PAGINA 100 DEL MEGAROM **********

; COMIC CIERRE INGLES 1

		org		#8000
		
COM_CIERI9:							incbin		"SR5/COMICS/DESPEDIDA/COMIC_CIERREI.DAT09"

		ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 100 DEL MEGAROM **********)))	

; ______________________________________________________________________																																																																	
;variables en RAM
		
				include		"DEFINIENDO VARIABLES.asm"
				
