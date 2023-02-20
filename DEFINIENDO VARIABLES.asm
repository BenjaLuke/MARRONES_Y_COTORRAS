	MAP 0xc001
	
mapa_del_laberinto:				#990									; 900 casillas más 90 para evitar problemas en la lectura de profundidad
decorados_laberinto:			#990									; 900 casillas con diferentes decorados mas 90 para evitar problemas en la lectura de profundidad
eventos_laberinto:				#900									; 900 casillas con diferentes eventos
act_mapa_1:						#1										; 900 para ver si se activa la casilla en el mapa_del_laberinto
act_mapa_1_1:					#899									;				0 - no
																		;				1 - si
act_mapa_2:						#1										; 900 para ver si se activa la casilla en el mapa_del_laberinto
act_mapa_2_1:					#899									;				0 - no
																		;				1 - si
x_pinta_mapa:					#1										; controla la x a la hora de pintar el mapa																																				
y_pinta_mapa:					#1										; controla la y a la hora de pintar el mapa																																				
codigo_salve:					#26										; código de salvado de partida
codiguin:						#1										; los cuatro bits que representan una letra del código
codigo_activo:					#1										; el juego leerá los datos ya metidos según este byte
																		; 				0- no
																		;				1- si
turno_sin_tirar:				#1										; turnos sin tirar																		
VDP:         					#28										; control de VDP para el cambio de page	
ya_hemos_visto_petiso:			#1										; controla si ya hemos pasado por el inicio
																		;				diferente a 37		no
																		;				37					si
var_cuentas_peq:				#1										; para cuentas pequeñitas
fotogramas_animaciones:			#1										; para contar los fotogramas que lleva una animación
ralentizando:					#1										; para hacer perder tiempo
que_page:						#1										; page que se debe poner
datos_del_copy:					#15										; reune los datos para hacer un copy por in & outs
																		;				0-1		x salida
																		;				2-3		y salida
																		;				4-5		x destino
																		;				6-7		y destino
																		;				8-9		pixeles de x
																		;				10-11	pixeles de y
																		;				12		registro a 0 por no usarse
																		;				13		definición del tipo de copy (derecha a izquierda, arriba a abajo, etc...)
																		;				14		definición de clase de copy en asm (esta estructura es para HMMM)
fotograma_de_dos:				#1										; controla en que fotograma está de entre 2
var_cuentas_gra:				#2										; para cuentas más grandes (hasta 65000)
anterior_valor:					#1										; Retiene el valor anterior de stick para controlar que no se repita
en_que_pagina_el_page_2:		#1										; nos dice en qué página está en ese momento la página 2 del ordenador
marca_e_idioma:					#1										; decide si al volver a empezar, sale cabecera o directamente menu
																		; 				0		cabecera
																		;				1		menu
pagina_hater:					#1										; qué hater va a luchar
																		;				29		el 1
																		;				30		el 2
																		;				31		el 3
																		;				32		el 4
mosca_x_objetivo:				#1										; la x a la que la mosca debe ir
mosca_y_objetivo:				#1										; la y a la que la mosca debe ir
mosca_x_real:					#1										; la x en la que la mosca está
mosca_y_real:					#1										; la y en la que la mosca está
suma_a_mosca_x:					#1										; lo que suma o resta a x para llegar a objetivo
suma_a_mosca_y:					#1										; lo que suma o resta a y para llegar a objetivo
mosca_suma_o_resta_x:			#1										; indica si está sumando o restando en su x
																		;				0		suma
																		;				1		resta
mosca_suma_o_resta_y:			#1										; indica si está sumando o restando en su y
																		;				0		suma
																		;				1		resta																		
mosca_activa:					#1										; nos dice si la mosca se debe ver o no
																		;				0		no
																		;				1		si
mosca_fotograma:				#1										; fotograma en el que está de cinco (0-4)
mosca_atributos:				#7										; los atributos del sprite de mosca	
mosca_y_objetivo_res:			#1										; guardamos el valor que tenía y en mosca para devolverlo
tecla_pulsada:					#1										; para evitar la repetición de teclas pulsadas
																		;				0		no está pulsada
																		;				1		si lo está
tecla_pulsada_MOSCA:			#1										; Lo mismo pero especial para asustar o atraer a la mosca																		
set_page01:						#1										; controla el doble buffer
																		;				0		muestra page 0
																		;				1		muestra page 1
que_musica_7:					#1										; nos indica qué música hay que reproducir antes de empezar el juego
																		;				0		intro
																		;				1		selecciones
que_musica_0:					#1										; nos indica qué música hay que reproducir antes de empezar el juego
																		;				0		juego misterio
																		;				1		tienda
scroll_comic_page:				#1										; paginas consecutivas de scroll de sc8
limite_impresion_comic:			#1										; el límite de lineas a imprimir antes de terminar el bloque de 16 k
salto_historia:					#1										; nos indica si ver el final o la presentacion en el comic																		
																		
;	Variables sobre la partida

nivel:							#1										; nivel en el que estamos (en el modo un jugador) del 1 al 4
nivel_2:						#1										; nivel de dificultad en el modo 2 jugadores del 1 al 3
dado:							#1										; resultado del dado
desplazamiento_real:			#1										; el movimiento real del personaje
ataque_real:					#1										; el ataque real del personaje
defensa_real:					#1										; la defensa real del personaje
cantidad_de_jugadores:			#1										; 1 o 2 jugadores
turno:							#1										; 1 o 2 dependiendo del jugador
valor_a_transm_a_dib:			#1										; cuando se quiere pintar un número, esta variable guarda el valor a pintar
secuencia_de_letras:			#40										; la secuencia de letras a escribir
valor_ataque_hater:				#1										; valor del dado que tira el hater al atacar (entre 1-6)
valor_ataque_final_hater:		#1										; sumada la rectificación
valor_defensa_hater:			#1										; valor del dado que tira el hater al defender (entre 1-6)
valor_defensa_final_hater:		#1										; sumada la rectificación
vida_hater:						#1										; vida del hater al que se enfrenta
estandarte_hater:				#1										; decide el estandarte del hater en cuestión
																		;				1		MSX
																		;				2 		ATARI
																		;				3 		AMSTRAD
																		;				4 		COMODORE
																		;				5 		DRAGON
																		;				6 		SPECTRUM
																		;				7 		ACORN
																		;				8 		ORIC

casilla_destino_agujero_negro:	#2										; número de casilla del laberinto a la que se va cuando se cae en un agujero negro.
x_map_destino_agujero_negro:	#1
y_map_destino_agujero_negro:	#1
tiembla_el_decorado_v:			#1										; si es mayor que 0, sigue temblando
dinero_real:					#2										; la suma de centenas, decenas y unidades en curso para poder calcular en la tienda.
estado_pelea:					#2										; para saber donde pintar los numeros
																		;				0		no está en pelea (velocidad)
																		;				1		defensa
																		;				2		ataque
menu_de_lampara_trampa:			#1										; controla si tenemos lámpara o tramapa o las dos cosas para poder hacer un menú al respecto
																		;				0		no tiene nada
																		;				1		tiene lupa
																		;				2		tiene trampa o trampas
																		;				3		tiene las dos cosas
contador_piedras_y_ramas:		#1										; para dibujar en el suelo cosas que nos den la sensación de avance
no_borra_texto:					#1										; para evitar que se borre un texto que ha salido un instante
																		
;VARIABLES PARA LOS VIEJIGUIAS

donde_esta_jugador_manipular:	#2										; valor de la casilla en la que se está para poder hacer cálculos
donde_esta_jugador_posicion:	#1										; valor sobre el que calculamos la altura

que_estoy_buscando:				#1										; el objeto que se busca

objeto_manipular:				#2										; valor de la casilla en la que se estará el objeto a buscar
objeto_posicion:				#1										; valor sobre el que calculamos la altura

norte_sur:						#1										; el resultado de la operación norte sur
																		;				0		están en la misma linea
																		;				3		el objeto está más al norte que la casilla del jugador
																		;				6		el objeto está más al sur que la casilla del jugador
este_oeste:						#1										; el resultado de la operación oeste este
																		;				3		el objeto está más al oeste que la casilla del jugador
																		;				4		están en la misma linea
																		;				5		el objeto está más al este que la casilla del jugador
situacion_real:					#1										; suma de norte_sur y oeste_este
																		; 				3		oeste
																		;				4		combinación imposible
																		;				5		este
																		;				6		noroeste
																		;				7		norte
																		;				8		noreste
																		;				9		suroeste
																		;				10		sur
																		;				11		sureste
																		
incremento_ataque_origen1:		#1										; guardamos para los dos jugadores los origenes de los valores de modificacion
incremento_defensa_origen1:		#1
incremento_velocidad_origen1:	#1
incremento_ataque_origen2:		#1
incremento_defensa_origen2:		#1
incremento_velocidad_origen2:	#1

;VARIABLES JUGADOR JUGANDO

posicion_en_mapa:				#2										; casilla en la que está el jugador en curso
orientacion_del_personaje:		#1										; orientacion cardinal dentro del laberinto del jugador en curso	
																		;				0		Norte
																		;				1		Este	
																		;				2		Sur
																		;				3		Oeste
brujula:						#1										; valor de brujula para pasar a la brujula que esté en juego
																		;				0 		no la tiene
																		;				1 		la tiene
papel:							#1										; valor de papel para pasar a la brujula que esté en juego
pluma:							#1										; valor de pluma para pasar a la brujula que esté en juego
tinta:							#1										; valor de tinta para pasar a la brujula que esté en juego
llave:							#1										; valor de llave pasar a la llave que esté en juego
lupa:							#1										; para poder ver los eventos por donde pasamos
botas:							#1										; mas uno en velocidad, anula las botas esp
botas_esp:						#1										; mas dos en velocidad, anula las botas
cuchillo:						#1										; mas uno en ataque, anula la espada
espada:							#1										; mas dos en ataque, anula elcuchillo
armadura:						#1										; mas uno en defensa, acumulable
casco:							#1										; mas uno en defensa, acumulable
																		;				0 		no la tiene
																		;				1 		la tiene
trampa:							#1										; para putear al contrario
																		;				el número es la cantidad
gallina:						#1										; te permite huir de las peleas
																		; 				el numero es la cantidad
x_map:							#1										; controla la coordenada x a la hora de pintar el mapa global
y_map:							#1										; controla la coordenada y a la hora de pintar el mapa global
bitneda_unidades:				#2										; control de moneda
bitneda_decenas:				#2										; control de moneda
bitneda_centenas:				#2										; control de moneda
vida_unidades:					#1										; control de vida
vida_decenas:					#1										; control de vida
incremento_velocidad:			#1										; valor a añadir al movimiento del jugador
incremento_ataque:				#1										; valor a añadir al ataque del jugador
incremento_defensa:				#1										; valor a añadir a la defensa del jugador
estandarte:						#1										; esta decide y pasa el valor a las otras
																		;				1		MSX
																		;				2 		ATARI
																		;				3 		AMSTRAD
																		;				4 		COMODORE
																		;				5 		DRAGON
																		;				6 		SPECTRUM
																		;				7 		ACORN
																		;				8 		ORIC
personaje:						#1										; el personaje que está jugando	
																		;				1 		NATALIA
																		;				2 		FERNANDO
																		;				3 		CRISTINA
																		;				4 		VICTOR
perro:							#1										; el perro del que está jugando
																		;				0		no lo tiene
																		;				1		lo tiene
tienda_objeto_2:				#1										; el número de objeto escogido para este artículo de la tienda
tienda_objeto_3:				#1										; el número de objeto escogido para este artículo de la tienda
tienda_objeto_4:				#1										; el número de objeto escogido para este artículo de la tienda
																		; 				0		BOTAS
																		;				1		BOTAS ESPECIALES
																		;				2		ARMADURA
																		;				3		CASCO
																		;				4		ESPADA
																		;				5		PUÑAL
tienda_objeto_5:				#1										; el número de objeto escogido para este artículo de la tienda
																		;				0		PLUMA
																		;				1		PAPEL
																		;				2		TINTA
																		;				3		LÁMPARA
																		;				4		BRÚJULA
control_coincidencia_tienda:	#1										; para controlar si hay que cotejar más de una vez los objetos en la tienda
																		;				0		NO
																		;				1		SI
x_tienda:						#1										; posición para la mano seleccionadora de la tienda en coordenada x
valor_decidido:					#1										; valor según el objeto que haya en la tienda para objetos 2, 3 y 4
objeto_en_curso:				#1										; el objeto que se ha seleccionado para comprar, para diferentes análisis dentro de la tienda
objeto_del_que_hablamos:		#1										; posición del objeto del que estamos hablando
casilla_del_oponente:			#2										; es la estancia en la que está el jugdor contrario, para poder dibujarlo si hay un cruce de dos personajes

; VARIABLES JUGADOR 1

posicion_en_mapa_1:				#2										; casilla en la que está el jugador 1
orientacion_del_personaje_1:	#1										; orientación cardinal dentro del laberinto del jugador 1
brujula1:						#1										; posesion de brujula jugador 1
papel1:							#1										; posesion de papel jugador 1
pluma1:							#1										; posesion de pluma jugador 1
tinta1:							#1										; posesion de tinta jugador 1
llave1:							#1										; posesion de llave jugador 1
lupa_1:							#1										; para poder ver los eventos por donde pasamos
botas1:							#1										; mas uno en velocidad, anula las botas esp
botas_esp1:						#1										; mas dos en velocidad, anula las botas
cuchillo1:						#1										; mas uno en ataque, anula la espada
espada1:						#1										; mas dos en ataque, anula elcuchillo
armadura1:						#1										; mas uno en defensa, acumulable
casco1:							#1										; mas uno en defensa, acumulable
trampa1:						#1										; para putear al contrario
																		;				el número es la cantidad
gallina1:						#1										; te permite huir de las peleas
																		; 				el numero es la cantidad

x_map_1:						#1										; controla la coordenada x a la hora de pintar el mapa jugador 1
y_map_1:						#1										; controla la coordenada y a la hora de pintar el mapa jugador 1
bitneda_unidades1:				#2										; control de moneda
bitneda_decenas1:				#2										; control de moneda
bitneda_centenas1:				#2										; control de moneda
vida_unidades1:					#1										; control de vida
vida_decenas1:					#1										; control de vida
incremento_velocidad_1:			#1										; valor a añadir al movimiento del jugador 1
incremento_ataque_1:			#1										; valor a añadir al ataque del jugador 1
incremento_defensa_1:			#1										; valor a añadir a la defensa del jugador 1
estandarte_1:					#1										; el del jugador 1
personaje_1:					#1										; el personaje del jugador 1
perro_1:						#1										; el perro del personaje 1

; VARIABLES JUGADOR 2

posicion_en_mapa_2:				#2										; casilla en la que está el jugador 2
orientacion_del_personaje_2:	#1										; orientación cardinal dentro del laberinto del jugador 2
brujula2:						#1										; posesion de brujula jugador 2
papel2:							#1										; posesion de papel jugador 2
pluma2:							#1										; posesion de pluma jugador 2
tinta2:							#1										; posesion de tinta jugador 2
llave2:							#1										; posesion de llave jugador 2
lupa_2:							#1										; para poder ver los eventos por donde pasamos
botas2:							#1										; mas uno en velocidad, anula las botas esp
botas_esp2:						#1										; mas dos en velocidad, anula las botas
cuchillo2:						#1										; mas uno en ataque, anula la espada
espada2:						#1										; mas dos en ataque, anula elcuchillo
armadura2:						#1										; mas uno en defensa, acumulable
casco2:							#1										; mas uno en defensa, acumulable
trampa2:						#1										; para putear al contrario
																		;				el número es la cantidad
gallina2:						#1										; te permite huir de las peleas
																		; 				el numero es la cantidad
x_map_2:						#1										; controla la coordenada x a la hora de pintar el mapa jugador 2
y_map_2:						#1										; controla la coordenada y a la hora de pintar el mapa jugador 2
bitneda_unidades2:				#2										; control de moneda
bitneda_decenas2:				#2										; control de moneda
bitneda_centenas2:				#2										; control de moneda
vida_unidades2:					#1										; control de vida
vida_decenas2:					#1										; control de vida
incremento_velocidad_2:			#1										; valor a añadir al movimiento del jugador 2
incremento_ataque_2:			#1										; valor a añadir al movimiento del jugador 2
incremento_defensa_2:			#1										; valor a añadir al ataque del jugador 2
estandarte_2:					#1										; el del jugador 2
personaje_2:					#1										; el personaje del jugador 2
perro_2:						#1										; el perro del personaje 2

colision_de_personajes:			#1										; controla si los dos personajes estan en la misma casilla para acciones posteriores
																		;				0		no
																		;				1		si	
idioma:							#1										; idioma en el que se desarrolla el juego
																		;				1 		Inglés
																		;				2 		Castellano
pagina_de_idioma:				#1										; indica la pagina que hay que cargar dependiendo del idioma
																		;				20		castellano
																		;				81		inglés
suena_direccion:				#1										; seleccionar cantidad de jugadores control de si le hemos dado para que se mueva
direccion_scroll_horizontal:	#1										; controla la dirección de un scroll 
																		;				1 		hacia arriba
																		;				2 		hacia abajo
interrupcion_valida:			#1										; indica el tipo de interrupcion que se está realizando (de linea)	
																		;				1 		interrupcion primera para estandartes y objetos
																		;				2 		interrupcion segunda para personajes  y textos
giro_hacia:						#1										; define si ha girado en lugar de avanzar
																		;				0		avanza
																		;				1		derecha
																		;				2		izquierda
posicion_del_titulo:			#1										; controla la posicion del baile del titulo
repeticion_posicion_titulo:		#1										; cuantas interrupciones se repite cada pose
posicion_del_titulo_inicio:		#1										; punto del que parte la animación
vblank_real						#1										; sube en uno cada vez que la interrupción es de vblanck
																		; sirve para sustituir al HALT cuando hay más interrupciones que la de vblanck
patron_actual_cargado:			#1										; controla el patrón que se cargó de decorados
paleta_a_usar_en_vblank:		#1										; decide la paleta a usar en la parte superior
																		;				0 		standard de mazmorra
																		;				1 		pergamino
																		;				2		pochadero
																		;				3		hater
var_cuentas_paleta:				#1										; para los fades
var_cuentas_paleta_esp:			#1										; indica si hay una cuenta diferente a 8
																		;				0		no
																		;				1		15
																		;				2		1
var_cuentas_paleta_int:			#1										; para bucles con las paletas
el_menu_baila:					#1										; para controlar si hay mov. de titulo o no																		
toca_dado:						#1										; controla si muestra un número de dado o el dado girando
																		;				0		girando
																		;				1		plano
largo_frase:					#1;										cantidad de carácteres que tiene esa frase

; VARIABLES EXTRAS PARA JUGADOR 1
valor_conserv_bitn_vid:			#8										; salva de una fase a otra el valor de bitnedas y vida del jugador 1
																		;				1		bitnedas unidades
																		;				2		bitnedas decenas
																		;				3		bitnedas centenas
																		;				4		vida unidades
																		;				5		vida decenas

atributos_sprites_prota:		#48										; Atributos para dibujar los sprites prota (4*2*4) arma (2*4) colision (2*4)
																		;				0		y
																		;				1		x
																		;				2		número de patrón
fotograma_que_toca:				#1										; Nos dice el fotograma que se debe pintar de 2*8
atributos_sprites_cotorra:		#47
prota_saltando:					#1										; Activa el salto
salto_prota_continuo:			#1										; Cuánto tiempo activa el salto
ultimo_stick:					#1										; Guarda lo último que se pulsó para mantenerlo durante el salto
disparo_ya_en_juego:			#1										; controla si ya hay un disparo en juego
x_proyectil_salida:				#1										; nos indica el punto x de salida del proyectil del prota
direccion_cotorra:				#1										; nos indica la dirección hacia la que va el cotorra
																		;				0		izquierda
																		;				1		derecha
retraso_cotorra:				#1										; Los ciclos de espera entre desplazamiento y desplazamiento
pie_de_cotorra:					#1										; qué pose del cotorra vemos
vida_cotorra:					#1										; vida del enemigo cotorra
cambio_de_cotorra:				#1										; mientras sea 0 estará comprobando para cambiar a 1 y lo mismo de 1 a 3 (es para los sprites) 
intervalo_de_disparos:			#1										; cada cuanto decide disparar el cotorra
intervalo_feaciente:			#1										; control para ver si coincide con el momento de disparar el cotorra
disparo_que_toca:				#1										; hay dos posibilidades 0 y 1 relacionado con 2 juegos de sprites diferentes
propiedades_disparo:			#6										; propiedades del disparo del cotorra:
propiedades_disparo_2:			#6
																		;				0 - 6	inactivo/activo 0/1
																		;				1 - 7	x
																		;				2 - 8	y
																		;				3 - 9	fotograma que mostramos de los dos 0/1
																		;				4 - 10	secuencia de ataque escogida 0/1/2
																		;				5 - 11	fase de la secuencia en la que está
atributos_disparos:				#15										; los datos de los disparos que pasaremos a vram
pintamos_sin_colision:			#1										; Si ha habido colisión está en 1. al limpiar todo se pone a 0	
x_salvada:						#1										; salva el valor de x del prota para trabajar con el mientras la ix está siendo usada en otra cosa																	
retroceso:						#1										; nos indica que se ha pedido corregir una letra del código
	
; --- ayFX REPLAYER v2.0M ---
; --- THIS FILE MUST BE COMPILED IN RAM ---

ayFX_BANK:						#2										; Current ayFX Bank
ayFX_C1:						#3										; Priority & Pointer to the ayFX being played on channel 1
ayFX_C2:						#3										; Priority & Pointer to the ayFX being played on channel 2
ayFX_C3:						#3										; Priority & Pointer to the ayFX being played on channel 3

ayFX_TONE:						#2										; Current tone of the ayFX stream
ayFX_NOISE:						#1										; Current noise of the ayFX stream
ayFX_VOLUME:					#1										; Current volume of the ayFX stream
ayFX_CHANNEL:					#1										; PSG channel to play the ayFX stream

ayFX_REGS:						#14										; Ram copy of PSG registers
												
;struc	AR

AR_TonA		equ 0														;RESW 1
AR_TonB		equ 2														;RESW 1
AR_TonC		equ 4														;RESW 1
AR_Noise	equ 6														;RESB 1
AR_Mixer	equ 7														;RESB 1
AR_AmplA	equ 8														;RESB 1
AR_AmplB	equ 9														;RESB 1
AR_AmplC	equ 10														;RESB 1
AR_Env		equ 11														;RESW 1
AR_EnvTp	equ 13														;RESB 1

;endstruc

; fmpac y music module

CLIKSW:	#2	
chips:	#1 																;db  0 			;soundchip: 	0 = 	msx-audio
																		;							   	1 = 	msx-music
																		;	   							2 = 	stereo
busply:	#1 																;db  0 			;status:  		0 = 	no se reproduce
																		;       						255 = 	se reproduce
muspge:	#1 																;db  3 			;banco mapeador con datos de música
musadr:	#2 																;dw  08000h		;dirección de los datos de música
pos:	#1 																;db  0 			;Contador de posición actual
step:	#1 																;db  0 			;Paso actual
status:	#3 																;db  0,0,0	;3 	;Statusbytes

chnwc1: #10  															;dw  0,0,0,0,0
modval: #20 															;dw  1,2,2,-2,-2,-1,-2,-2,2,2
mmfrqs: #1  															;db  0
speed:  #1  															;db  0
spdcnt: #1  															;db  0
rtel:   #1 																;db  0
patadr: #2  															;dw  0
patpnt: #2  															;dw  0
tpval:  #1  															;db  0
xpos:   #2  															;dw  0
laspl1: #22*9 															;db  0,0,0,0,0,0,0,0a0h,10h,0,0,0,030h,043h,0,0,0,0,0,0,0,0
																		;db  0,0,0,0,0,0,0,0a1h,11h,0,0,0,031h,044h,0,0,0,0,0,0,0,0
																		;db  0,0,0,0,0,0,0,0a2h,12h,0,0,0,032h,045h,0,0,0,0,0,0,0,0
																		;db  0,0,0,0,0,0,0,0a4h,14h,0,0,0,034h,04ch,0,0,0,0,0,0,0,0
																		;db  0,0,0,0,0,0,0,0a5h,15h,0,0,0,035h,04dh,0,0,0,0,0,0,0,0
																		;db  0,0,0,0,0,0,0,0a6h,16h,0,0,0,036h,053h,0,0,0,0,0,0,0,0
																		;db  0,0,0,0,0,0,0,0a7h,17h,0,0,0,037h,054h,0,0,0,0,0,0,0,0
																		;db  0,0,0,0,0,0,0,0a8h,18h,0,0,0,038h,055h,0,0,0,0,0,0,0,0

stepbf:	#13  															;ds  13			;datos de paso en SIGUIENTE interrupción
																		;				;se ejecuta (o ya ha sido ejecutado antes)
xleng   #3     															;ds  3
xmmvoc  #16*9 															;ds  16*9
xmmsti  #16   	 														;ds  16
xpasti  #32    															;ds  32
xstpr   #10    															;ds  10
xtempo  #1     															;ds  1
xsust   #1     															;ds  1
xbegvm  #9    															;ds  9
xbegvp  #9     															;ds  9
xorgp1  #6*8   															;ds  6*8
xorgnr  #6     															;ds  6
xsmpkt  #8     															;ds  8
xdrblk  #15    															;ds  15
xdrvol  #3     															;ds  3
xdrfrq  #20    															;ds  20
xrever  #9     															;ds  9
xloop   #1     															;ds  1
psgcnt:	#1    	 														;db	 0
psgvol:	#1     															;db	 0																		
