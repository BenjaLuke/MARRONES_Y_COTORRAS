CHGMOD		equ		#005F												; elige el modo gráfico
CHGCLR		equ		#0062												;da color a la pantalla
ENASLT		equ		#0024												;para ampliar la rom
RSLREG  	equ		#0138												;lee el registro del slot primario
LDIRVM		equ		#005C												;graba en vram una parte de ram
CHGCOLOR	equ		#0062												;da color a la pantalla
FORCLR		equ		#F3E9												;define el color de letras para CHGCLR
BAKCLR		equ		#F3EA												;define el color de fondo para CHGCLR
BDRCLR		equ		#F3EB												;defeine el color de bordes para CHGCLR
SLOTVAR		equ		#c000		
ACPAGE		equ		#faf6												;pones en a la page en la que quieres trabajar
WRTVDP		equ		#0047												;escribe registros del VDP
VDP_0		equ		#F3DF												;para direccionarse a los registros (entre 0 y 7) hay que sumarle el número de registro
VDP_8		equ		#FFDF												;para direccionarse a los registros (entre 8 y 23) hay que sumarle el número de registro	
VDP_25		equ		#FFE1												;para direccionarse a los registros (entre 25 y 27) hay que sumarle el número de registro
CLS			equ		#00C3												;limpia la pantalla
GTTRIG		equ		#00D8												;controla los botones del joystick o la barra espaciadora
																		;En a metes 	0 para controlar barra espaciadora
																		;				1 para controlar boton 1 puerto 1
																		;				2 para controlar boton 1 puerto 2
																		;				3 para controlar boton 2 puerto 1
																		;				4 para controlar boton 2 puerto 2
																		; El resultado es #00 si no está pulsado y #FF si sí está pulsado
DISSCR		equ		#0041												; desconecta la pantalla_en_blanco
ENASCR		equ		#0044												; conecta la pantalla
POSIT		equ		#00C6												; coloca el cursor en una rectrices h,l
CHPUT		equ		#00A2												; escribe un caracter en pantalla
GTSTCK		equ		#00D5												; controla los cursores o direcciones del joistick
																		; En a metes		0 para controlar cursores
																		;				1 para controlar puerto 1
																		;				2 para controlar puerto 2
																		; en a sale		0 Norte
																		;				1 Noreste
																		;				...
																		;				7 Noroeste
CLICKSW		equ		#f3DB												;quita el sonido del toque de teclas
H.TIMI		equ		#FD9F												;lugar al que se va cada vez que hay una interrupción de video (60 veces por segundo)
H.KEYI		equ		#FD9A												;lugar al que se va cada vez que hay una interrupción de cualquier tipo

RG0SAV		equ		#F3DF													;COPIA DE vdp DEL REGISTRO 0 (BASIC:VDP(0))
RG1SAV		equ		#F3E0													;COPIA DE vdp DEL REGISTRO 1 (BASIC:VDP(1))
RG2SAV		equ		#F3E1													;COPIA DE vdp DEL REGISTRO 2 (BASIC:VDP(2))
RG3SAV		equ		#F3E2													;COPIA DE vdp DEL REGISTRO 3 (BASIC:VDP(3))
RG4SAV		equ		#F3E3													;COPIA DE vdp DEL REGISTRO 4 (BASIC:VDP(4))
RG5SAV		equ		#F3E4													;COPIA DE vdp DEL REGISTRO 5 (BASIC:VDP(5))
RG6SAV		equ		#F3E5													;COPIA DE vdp DEL REGISTRO 6 (BASIC:VDP(6))
RG7SAV		equ		#F3E6													;COPIA DE vdp DEL REGISTRO 7 (BASIC:VDP(7))
RG8SAV		equ		#FfE7
RG9SAV		equ		#FfE8	
RG11SAV		equ		#FFEA
SNSMAT		equ		#0141	;INKEY$											;controla si se ha pulsado una tecla

VDP.DW		equ		#0007
NSTWRT		EQU		#0171
