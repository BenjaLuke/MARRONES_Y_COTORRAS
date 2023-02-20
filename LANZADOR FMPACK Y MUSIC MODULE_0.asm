MUS1_0:			LD 			HL,MUSICA
				LD 			(musadr),HL
 
				RET

strmus_0:			di

				ld			a,(busply)
				or			a
				ret			nz
				ld			hl,0
				ld			(status),hl
				ld			(status+1),hl
				xor			a
				ld			(spdcnt),a
				ld			(trbpsg),a
				dec			a
				ld			(pos),a
				ld			(busply),a
				in			a,(0feh)
				push		af
				ld			a,(muspge)
				out			(0feh),a
				ld			hl,(musadr)
				ld			de,xleng
				ld			bc,207
				ldir
				ld			c,41
				add			hl,bc
				ld			c,128
				ldir
				ld			(xpos),hl
				ld			a,(xleng)
				inc			a
				ld			e,a
				ld			d,0
				add			hl,de
				ld			(patadr),hl

				ld			hl,pc2out
				ld			de,mm2out
				ld			bc,pc3out
				ld			ix,mm3out
				ld			a,(02dh)
				cp			3
				jr			c,strms2
				ld			a,03dh
				ld			(trbpsg),a
				ld			(trbpsg+1),a
				call		0183h
				or			a
				jr			z,strms2
				ld			hl,parout
				ld			de,mmrout
				ld			bc,parout
				ld			ix,mmrout
				
strms2_0:			ld			(pacout+1),hl
				ld			(fpcout+1),bc
				ld			(mmout+1),de
				ld			(fmmout+1),ix
				ld			hl,chnwc1
				ld			de,chnwc1+1
				ld			bc,9
				ld			(hl),0
				ldir
				ld			a,(chips)
				or			a
				call		z,setaud
				dec			a
				call		z,setmus
				dec			a
				call		z,setste

				ld			b,9
				ld			iy,xbegvm+8
				ld			ix,xrever
				ld			hl,laspl1+176+6
				ld			de,-27
					
mrlus_0:			ld			(hl),0
				inc			hl
				inc			hl
				inc			hl
				ld			a,(ix+0)
				ld			(hl),a
				inc			hl
				ld			a,(iy+0)
				ld			(hl),a
				inc			hl
				ld			a,(iy+9)
				ld			(hl),a
				inc			ix
				dec			iy
				add			hl,de
				djnz		mrlus
	
				call		sinsmm
				call		sinspa
				ld			a,(xtempo)
				ld			(speed),a
				ld			a,15
				ld			(step),a
				ld			a,48
				ld			(tpval),a
				pop			af
				out			(0feh),a

strms3_0:			di

				ld			hl,0fd9fh
				ld			de,oldint
				ld			bc,5
				ldir
				ld			a,0c3h
				ld			(0fd9fh),a
				ld			hl,musint
				ld			(0fda0h),hl
				ei

				ret

;--- inicia instrumentos de msx-audio

sinsmm_0:			ld			de,mmrgad
				ld			hl,xbegvm
				ld			iy,laspl1+20

				ld			b,9

sinsm4_0:			push		bc
				push		hl
				push		de
				ld			b,(hl)
				ld			hl,xmmvoc-9
				ld			de,9

sinsm3_0:			add			hl,de
				djnz		sinsm3
				pop			de
	
				push		hl
				inc			hl
				inc			hl
				ld			a,(hl)
				ld			(iy+0),a
				pop			hl

				ld			b,9

sinsm2_0:			ld			a,(de)
				ld			c,a
				ld			a,(hl)
				inc			de
				inc			hl
				call		mmout
				djnz		sinsm2
				pop			hl
				inc			hl
				ld			bc,22
				add			iy,bc
				pop			bc
				djnz		sinsm4

				ld			b,4
				ld			hl,strreg

sinsm5_0:			ld			c,(hl)
				inc			hl
				ld			a,(hl)
				inc			hl
				call		fmmout
				djnz		sinsm5
				ld			a,(xsust)
				and			011000000b
				ld			c,0bdh
				jp			fmmout

;--- inicia instrumentos de msx-music

sinspa_0:			di

				ld			hl,xbegvp
				ld			iy,laspl1+21
				ld			b,6
				ld			a,(xsust)
				bit			5,a
				push		af
				jr			nz,sinsp2
				ld			b,9

sinsp2_0:			ld			c,30h

sinspi_0:			push		bc
				push		hl
				ld			a,(hl)
				ld			hl,xpasti-2
				add			a,a
				ld			c,a
				ld			b,0
				add			hl,bc
				ld			a,(hl)
				cp			16
				call		nc,sinspo
				rlca
				rlca
				rlca
				rlca
				inc			hl
				ld			b,(hl)
				add			a,b
				ld			bc,22
				add			iy,bc
				pop			hl
				pop			bc
				call		pacout
				inc			hl
				inc			c
				djnz		sinspi
				xor			a
				ld			c,0eh
				call		fpcout
				pop			af
				ret			z

				ld			de,xdrvol
				ld			hl,drmreg
				ld			b,9

setdrm_0:			ld			c,(hl)
				ld			a,(de)
				call		pacout
				inc			hl
				inc			de
				djnz		setdrm

				ret

sinspo_0:			push		hl
				sub			15
				ld			b,a
				ld			hl,xorgp1-8
				ld			de,8

sinpo2_0:			add			hl,de
				djnz		sinpo2
				push		hl
				inc			hl
				inc			hl
				ld			a,(hl)
				ld			(iy+0),a
				pop			hl
				ld			bc,0800h

sinpo3_0:			ld			a,(hl)
				call		pacout
				inc			c
				inc			hl
				djnz		sinpo3
				pop			hl
				xor			a
				ret


setmus_0:			push		af
				ld			a,(xsust)
				and			0100000b
				ld			a,2
				jr			z,setau2
				ld			hl,chnwc1
				ld			de,chnwc1+1
				ld			bc,5
				ld			(hl),a
				ldir
				ld			(chnwc1+9),a
				pop			af
				
				ret
				
setaud_0:			push		af
				inc			a

setau2_0:			ld			hl,chnwc1
				ld			de,chnwc1+1
				ld			bc,9
				ld			(hl),a
				ldir
				pop			af
				
				ret
				
setste_0:			ld			hl,xstpr
				ld			de,chnwc1
				ld			bc,10
				ldir
				
				ret

;--- continua la música ---

cntmus_0:			ld			a,(busply)
				or			a
				ret			nz
				dec			a
				ld			(busply),a
				jp			strms3

;--- rutina de interrupción de música ---

musint_0:			di

				push		af
				ld			a,(busply)
				or			a
				jp			z,stpms3
				in			a,(0feh)
				push		af
				ld			a,(muspge)
				out			(0feh),a

				call		dopsg
				call		dopit
				ld			a,(speed)
				ld			hl,spdcnt
				inc			(hl)
				cp			(hl)
				jp			nz,secint
				ld			(hl),0

				ld			iy,laspl1
				ld			hl,stepbf
				ld			b,9
				ld			de,chnwc1
	
intl1_0:			push		bc
				ld			a,(hl)
				or			a
				jp			z,intl3
				push		de
				push		hl
				cp			97
				jp			c,onevn
				jp			z,offevt
				cp			114
				jp			c,chgins
				cp			177
				jp			c,chgvol
				cp			180
				jp			c,chgste
				cp			199
				jp			c,lnkevn
				cp			218
				jp			c,chgpit
				cp			224
				jp			c,chgbr1
				cp			231
				jp			c,chgrev
				cp			237
				jp			c,chgbr2
				cp			238
				jp			c,susevt
				jp			chgmod

intl2_0:			pop			hl
				pop			de

intl3_0:			ld			bc,22
				add			iy,bc
				inc			de
				inc			hl
				pop			bc
				djnz		intl1
				call		mmdrum
				ld			a,(de)
				bit			1,a
				call		nz,pacdrm
				inc			hl
				ld			a,(hl)
				or			a
				jr			z,cmdint
				cp			24
				jp			c,chgtmp
				jp			z,endop2
				cp			28
				jp			c,chgdrs
				cp			31
				jp			c,chgsta
				call		chgtrs
				
cmdint_0:

endint_0:			pop			af
				out			(0feh),a
				pop			af

oldint_0:			ret
				ret
				ret
				ret
				ret


secint_0:			dec			a
				cp			(hl)
				jr			nz,endint
				ld			a,(step)
				inc			a
				and			01111b
				ld			(step),a
				ld			hl,(patpnt)
				call		z,posri3
				ld			de,stepbf
				ld			c,13
				
dcrstp_0:			ld			a,(hl)
				cp			243
				jr			nc,crcdat
				ld			(de),a
				inc			de
				dec			c
					
crcdt2_0:			inc			hl
				ld			a,c
				or			a
				jr			nz,dcrstp
				ld			(patpnt),hl
				jp			secin2
				
crcdat_0:			sub			242
				ld			b,a
				xor			a
	
crclus_0:			ld			(de),a
				inc			de
				dec			c
				djnz		crclus
				jr			crcdt2

secin2_0:			ld			iy,laspl1
				ld			hl,stepbf
				ld			b,9
				ld			de,chnwc1
	
intl4_0:			push		bc
				ld			a,(hl)
				or			a
				jr			z,intl5
				cp			97
				jr			nc,intl5
				push		hl
				ld			(iy+6),0
				ld			c,a
				push		de
				push		bc
				ld			a,(de)
				push		af
				and			010b
				call		nz,pacple
				pop			af
				pop			bc
				and			01b
				call		nz,mmple
				pop			de
				pop			hl
	
intl5_0:			ld			bc,22
				add			iy,bc
				inc			de
				inc			hl
				pop			bc
				djnz		intl4
				jp			endint

mmple_0:			ld			a,(tpval)
				add			a,c
				cp			96+48+1
				jr			c,mmpl4
				sub			96
				jr			mmpl3
	
mmpl4_0:			cp			1+48
				jr			nc,mmpl3
				add			a,96
	
mmpl3_0:			sub			48
				ld			(iy+0),a
				ld			hl,pafreq-1
				add			a,a
				add			a,l
				ld			l,a
				jr			nc,mmpl2
				inc			h
	
mmpl2_0:			ld			d,(hl)
				dec			hl
				ld			e,(hl)
				ex			de,hl
				add			hl,hl
				ld			a,l
				ld			e,(iy+9)
				add			a,e
				add			a,e
				ld			l,a
				dec			hl
				ld			(iy+16),h
				ld			(iy+17),l
				
				ret

pacple_0:			ld			a,(tpval)
				add			a,c
				cp			96+48+1
				jr			c,pacpl4
				sub			96
				jr			pacpl3
	
pacpl4_0:			cp			1+48
				jr			nc,pacpl3
				add			a,96
				
pacpl3_0:			sub			48
				ld			(iy+5),a
				ld			hl,pafreq-1
				add			a,a
				add			a,l
				ld			l,a
				jr			nc,pacpl2
				inc			h
	
pacpl2_0:			ld			a,(hl)
				ld			(iy+18),a
				dec			hl
				ld			a,(hl)
				add			a,(iy+9)
				ld			(iy+19),a
				
				ret

onevn_0:			ld			a,(de)
				push		af
				and			010b
				call		nz,pacpl
				pop			af
				and			01b
				call		nz,mmpl
				jp			intl2

offevt_0:			ld			(iy+6),0
				ld			a,(de)
				push		af
				and			010b
				call		nz,offpap
	
offet2_0:			pop			af
				and			01b
				call		nz,offmmp
				jp			intl2

susevt_0:			ld			(iy+6),0
				ld			a,(de)
				push		af
				and			010b
				call		nz,suspap
				jr			offet2

chgins_0:			push		de
				ld			(iy+6),0
				sub			97
				ld			c,a
				ld			a,(de)
				push		af
				push		bc
				and			010b
				call		nz,chpaci
				pop			bc
				pop			af
				and			01b
				call		nz,chmodi
				pop			de
				jp			intl2

chgvol_0:			push		de
				sub			114
				ld			c,a
				ld			a,(de)
				push		af
				push		bc
				and			010b
				call		nz,chpacv
				pop			bc
				pop			af
				and			01b
				call		nz,chmodv
				pop			de
				jp			intl2

chgste_0:			ld			c,a
				ld			a,(chips)
				cp			2
				jp			nz,intl2
				call		chstdp
				jp			intl2

lnkevn_0:			sub			189
				ld			c,a
				push		bc
				ld			a,(de)
				push		af
				and			010b
				call		nz,chlkpa
				pop			af
				pop			bc
				and			01b
				call		nz,chlkmm
				jp			intl2

chgpit_0:			sub			208
				ld			(iy+6),1
				ld			(iy+14),a
				rlca
				jr			c,chgpi2
				ld			(iy+15),0
				jp			intl2
				
chgpi2_0:			ld			(iy+15),0ffh
				ld			a,(de)
				push		af
				and			010b
				call		nz,chpidp
				pop			af
				and			01b
				call		nz,chpidm
				jp			intl2

chgbr1_0:			sub			224
				jr			chgbr3
	
chgbr2_0:			sub			230

chgbr3_0:			push		de
				ld			c,a
				ld			a,(de)
				push		af
				push		bc
				and			010b
				call		nz,chpcbr
				pop			bc
				pop			af
				and			01b
				call		nz,chmmbr
				pop			de
                jp  	  	intl2

chgrev_0:			sub			227
				ld			(iy+9),a
				jp			intl2
			
chgmod_0:			ld			(iy+6),2
				jp			intl2

posri3_0:			ld			a,(xleng)
				ld			b,a
				ld			a,(pos)
				cp			b
				jr			nz,posri5
				ld			a,(xloop)
				cp			255
				jr			z,posri4
				dec			a
				
posri5_0:			inc			a
				ld			(pos),a
				ld			c,a
				ld			b,0
				ld			hl,(xpos)
				add			hl,bc
				ld			a,(hl)
				dec			a
				add			a,a
				ld			c,a
				ld			hl,(patadr)
				add			hl,bc
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				ex			de,hl
				ld			de,(musadr)
				add			hl,de
				
				ret
				
posri4_0:			xor			a
				ld			(busply),a
				dec			a
				jr			posri5

;----- rotinas del music module -----


;-- speel noot af -- no usa af?

mmpl_0:			ld			a,(iy+17)
				ld			c,(iy+7)
				call		fmmout

				ld  		(iy+1),a
				set			4,c
				ld			a,(iy+16)
				call		fmmout
				set			5,a
				ld			(iy+2),a
				jp			fmmout

;-- apagar la nota --

offmmp_0:			ld			c,(iy+7)
				ld			a,(iy+1)
				call		fmmout
				ld			a,(iy+2)
				set			4,c
				and			011011111b
				ld			(iy+2),a
				jp			fmmout

;-- cambio de instrumento --

chmodi_0:			ld			a,c
				push		bc
				ld			(iy+10),a
				ld			b,a
				ld			hl,xmmvoc-9
				ld			de,9
				
chmoi2_0:			add			hl,de
				djnz		chmoi2
				pop			bc
				push		hl

				inc			hl											;mover el brillo
				inc			hl
				ld			a,(hl)
                ld    		(iy+20),a

				ld			a,10
				sub			b
				ld			b,a
				ld			hl,mmrgad-9
				ld			de,9
				
chmoi3_0:			add			hl,de
				djnz		chmoi3
				pop			de
				ld			b,9
				
chmoi4_0:			ld			c,(hl)
				ld			a,(de)
				call		fmmout
				inc			hl
				inc			de
				djnz		chmoi4
				
				ret


;-- cambio de volumen --

chmodv_0:			ld			a,c
				ex			af,af'
				ld			b,(iy+10)
				ld			hl,xmmvoc-6
				ld			de,9
				
chmov2_0:			add			hl,de
				djnz		chmov2
				ld			a,(hl)
				and			11000000b
				ld			c,(iy+13)
				ex			af,af'
				add			a,b
				jp			fmmout

;-- cambio del ajuste de stereo --

chstdp_0:			ld			(iy+6),0
				ld			a,c
				sub			176
				ld			(de),a
				push		af
				and			1
				call		z,moduit
				pop			af
				and			010b
				call		z,msxuit
				
				ret

;-- uniendo notas --

chlkmm_0:			ld			a,(iy+0)
				add			a,c
				ld			(iy+0),a
				ld			hl,pafreq-1
				add			a,a
				add			a,l
				ld			l,a
				jr			nc,chlkm2
				inc			h

chlkm2_0:			push		de
				ld			d,(hl)
				dec			hl
				ld			e,(hl)
				ex			de,hl
				add			hl,hl
				dec			hl
				pop			de
				ld			a,h
				ld			(mmfrqs),a
				ld			a,l
				ld			h,(iy+9)
				add			a,h
				add			a,h
				ld			(iy+1),a
				ld			c,(iy+7)
				call		fmmout

				set			4,c
				ld			a,(mmfrqs)
				or			0100000b
				ld			(iy+2),a
				ld			(iy+6),0
				jp			fmmout

;-- cambiar el brillo --

chmmbr_0:			ld			a,(iy+20)
				and			11000000b
				ld			e,a
				ld			a,(iy+20)
				and			00111111b
				ld			b,a
				ld			a,c
				add			a,b
				add			a,e
				ld			(iy+20),a
				ld			c,(iy+13)
				dec			c
				dec			c
				dec			c
				jp			fmmout

;-- cambiar la inclinación del tono --

chpidm_0:			ld			h,(iy+2)
				bit			1,h
				ret			nz
				ld			a,h
				and			11111100b
				sub			4
				ld			l,(iy+1)
				res			5,h
				add			hl,hl
				ld			(iy+1),l
				ex			af,af'
				ld			a,h
				and			00000011b
				ld			h,a
				ex			af,af'
				or			h
				ld			(iy+2),a
				
				ret

;--- samples de percusión ---

mmdrum_0:			ld			a,(de)
				rrca
				jr			nc,nommdr
				ld			a,(hl)
				or			a
				jp			z,mmdru2
				exx
				ld			hl,mmpdt1-2
				add			a,a
				ld			c,a
				ld			b,0
				rl			b
				add			hl,bc
				ld			a,(hl)
				ld			c,11h
				call		fmmout
				inc			hl
				ld			a,(hl)
				dec			c
				call		fmmout
				exx

mmdru2_0:			inc			hl
				ld			a,(hl)
				or			a
				jp			z,mmdru3
				scf
				rla
				ld			c,012h
				call		fmmout

mmdru3_0:			inc			hl
				ld			a,(hl)
				and			011110000b
				or			a
				ret			z
				srl			a
				srl			a
				srl			a
				srl			a
				exx
				call		mdrblk
				exx
				ld			c,7
				ld			a,1
				call		fmmout
				ld			a,0a0h
				jp			fmmout

nommdr_0:			inc			hl
				inc			hl

				ret

mdrblk_0:			add			a,a
				add			a,a
				ld			hl,smpadr-4
				ld			c,a
				ld			b,0
				add			hl,bc
				ld			c,9
				ld			a,(hl)
				call		fmmout
				inc			hl
				ld			a,(hl)
				inc			c
				call		fmmout
				inc			hl
				ld			a,(hl)
				inc			c
				call		fmmout
				inc			hl
				ld			a,(hl)
				inc			c
				jp			fmmout

;----- rutinas del fm-pac -----

pacpl_0:

;-- notas de actividad --

				ld			a,(iy+19)
				ld			c,(iy+8)
				call		fpcout
				ld			(iy+3),a
				ld			a,c
				add			a,010h
				ld			c,a
				ld			a,(iy+18)
				call		fpcout
				set			4,a
				ld			(iy+4),a
				jp			fpcout

;--- apagar nota de manera sostenida ---

suspap_0:			ld			l,0100000b
				jr			offpa2

;--- zet noot uit ---

offpap_0:			ld			l,0

offpa2_0:			ld			c,(iy+8)
				ld			a,(iy+3)
				call		fpcout
				ld			a,c
				add			a,010h
				ld			c,a
				ld			a,(iy+4)
				and			011101111b
				or			l
				ld			(iy+4),a
				jp			fpcout

;-- cambio de instrumento --

chpaci_0:			ld			a,c
				ld			(iy+11),a
				dec			a
				add			a,a
				ld			c,a
				ld			b,0
				ld			hl,xpasti
				add			hl,bc
				ld			a,(hl)
				cp			16
				jp			nc,chpaco
				rlca
				rlca
				rlca
				rlca
				
chpai2_0:			inc			hl
				ld			c,(hl)
				add			a,c
				ld			c,(iy+12)
				jp			fpcout

chpaco_0:			exx
				sub			15
				rlca
				rlca
				rlca
				ld			b,0
				ld			c,a
				ld			hl,xorgp1-8
				add			hl,bc

				push		hl											;cambia el brillo
				inc			hl
				inc			hl
				ld			a,(hl)
				ld			(iy+21),a
				pop  		hl

				ld			bc,0800h
				
chpao3_0:			ld			a,(hl)
				call		fpcout
				inc			c
				inc			hl
				djnz		chpao3
				exx
				xor			a
				jp			chpai2

;-- cambia el volumen --

chpacv_0:			ld			a,c
				srl			a
				srl			a
				ex			af,af'
				ld			hl,xbegvp
				ld			a,(iy+11)
				ld			b,0
				add			a,a
				ld			c,a
				ld			hl,xpasti-2
				add			hl,bc
				ld			a,(hl)
				cp			16
				jr			c,chpcv2
				xor			a
				
chpcv2_0:			rlca
				rlca
				rlca
				rlca
				ld			b,a
				ld			c,(iy+12)
				ex			af,af'
				xor			b
				jp			fpcout

;-- uniendo notas --

chlkpa_0:			ld			a,(iy+5)
				add			a,c
				ld			(iy+5),a
				ld			hl,pafreq-1
				add			a,a
				add			a,l
				ld			l,a
				jr			nc,chlkp2
				inc			h
				
chlkp2_0:			ld			a,(hl)
				ld			(mmfrqs),a
				dec			hl
				ld			a,(hl)
				add			a,(iy+9)
				ld			(iy+3),a
				ld			c,(iy+8)
				call		fpcout
				ld			a,c
				add			a,010h
				ld			c,a
				ld			a,(mmfrqs)
				or			010000b
				ld			(iy+4),a
				ld			(iy+6),0
				jp			fpcout

;--- cambiando el brillo ---

chpcbr_0:			ld			a,(iy+11)
				dec			a
				add			a,a
				ld			e,a
				ld			d,0
				ld			hl,xpasti
				add			hl,de
				ld			a,(hl)
				cp			16
				ret			c
				ld			a,(iy+21)
				and			11000000b
				ld			e,a
				ld			a,(iy+21)
				and			00111111b
				ld			b,a
				ld			a,c
				add			a,b
				add			a,e
				ld			(iy+21),a
				ld			c,2
				jp			fpcout

;-- cambiando la inclinación del tono --

chpidp_0:			ld			a,(iy+4)
				bit			0,a
				ret			nz
				dec			a
				ld			(iy+4),a
				ld			a,(iy+3)
				add			a,a
				ld			(iy+3),a
				
				ret

;-- percusión fm-pac --

pacdrm_0:			ld			a,(hl)
				and			01111b
				or			a
				ret			z
				ld			e,a
				ld			d,0
				push		hl
				ld			hl,xdrblk-1
				add			hl,de
				ld			a,(hl)
				cp			0100000b
				ld			c,a
				call		nc,psgdrm
				pop			hl
				ld			a,(xsust)
				and			0100000b
				ret			z
				ld			a,c
				and			011111b
				ld			c,0eh
				call		fpcout
				set			5,a
				jp			fpcout

psgdrm_0:			rlca
				rlca
				rlca
				and			0111b
				add			a,a
				ld			e,a
				ld			hl,psgadr-2
				add			hl,de
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				ex			de,hl
				ld			a,(hl)
				ld			(psgcnt),a
				inc			hl
				ld			b,(hl)
				inc			hl
				
psgl1_0:			ld			a,(hl)
				out			(0a0h),a
				inc			hl
				ld			a,(hl)
				out			(0a1h),a
				inc			hl
				djnz		psgl1
				ld			a,(hl)
				ld			(psgvol),a
				jp			dopsg2

;---- rutinas de comandos ----

chgtmp_0:			ld			b,a
				ld			a,25
				sub			b
				ld			(speed),a
				jp			cmdint

endop2_0:			ld			a,15
				ld			(step),a
				jp			cmdint

chgdrs_0:			sub			25
				add			a,a
				ld			b,a
				add			a,a
				add			a,b
				ld			e,a
				ld			d,0
				ld			hl,xdrfrq
				add			hl,de
				ex			de,hl
				ld			hl,drmreg+3
				ld			b,6
				
chgdrl_0:			ld			c,(hl)
				ld			a,(de)
				call		fpcout
				inc			hl
				inc			de
				djnz		chgdrl
				jp			cmdint

;--- bytes de estado ---

chgsta_0:			ld			c,a
				ld			b,0
				ld			hl,status-28
				add			hl,bc
				ld			(hl),255
				jp			cmdint

;--- cambio de transposición ---

chgtrs_0:			sub			55-48
				ld			(tpval),a
				
                ret

;--- rutinas por interrupción ----

dopsg_0:			ld			a,(psgcnt)
				or			a
				ret			z
				dec			a
				ld			(psgcnt),a
				jr			z,endpsg
	
dopsg2_0:			ld			a,8
				out			(0a0h),a
				ld			a,(psgvol)
				sub			2
				ld			(psgvol),a
	
trbpsg_0:			nop
				nop
				out			(0a1h),a
				
				ret
	
endpsg_0:			ld			a,7
				out			(0a0h),a
				ld			a,0bfh
				out			(0a1h),a
				ld			a,8
				out			(0a0h),a
				xor			a
				out			(0a1h),a
	
				ret

;----- flexión del tono -----

dopit_0:			ld			iy,laspl1
				ld			de,chnwc1
				exx
				ld			b,9
				ld			de,22
				
dopitl_0:			exx
				ld			a,(iy+6)
				ld			h,a
				or			a
				jp			z,dopit2
				ld			a,(de)
				and			01b
				call		nz,pitmm
				ld			a,(de)
				and			010b
				call		nz,pitpa
	
dopit2_0:			inc			de
				exx
				add			iy,de
				djnz		dopitl
				ret


;--- pitch bend module ---

pitmm_0:			push		hl
				dec			h
				jr			nz,modmm
				ld			l,(iy+14)
				ld			h,(iy+15)
				ld			c,(iy+1)
				ld			b,(iy+2)
				bit			7,h
				jr			nz,pitmm2
				add			hl,hl
				add			hl,bc
				ld			a,b
				and			00000010b
				ld			b,a
				
pitmm4_0:			ld			(iy+1),l
				ld			c,(iy+7)
				ld			a,l
				call		fmmout
				ld			a,h
				or			b
				ld			(iy+2),a
				set			4,c
				pop			hl
				jp			fmmout

pitmm2_0:			add			hl,hl
				add			hl,bc
				bit			1,h
				jr			nz,pitmm3
				dec			h
				dec			h
				
pitmm3_0:			ld			b,0
				jp			pitmm4

;--- pitch bend fm-pac ---

pitpa_0:			dec			h
				jr			nz,modpa
				ld			l,(iy+14)
				ld			h,(iy+15)
				ld			c,(iy+3)
				ld			b,(iy+4)
				bit			7,h
				jr			nz,pitpa2
				add			hl,bc
				ld			a,b
				and			00000001b
				ld			b,a
				
pitpa4_0:			ld			(iy+3),l
				ld			c,(iy+8)
				ld			a,l
				call		fpcout
				ld			a,c
				add			a,010h
				ld			c,a
				ld			a,h
				or			b
				ld			(iy+4),a
				jp			fpcout

pitpa2_0:			add			hl,bc
				bit			0,h
				jr			nz,pitpa3
				dec			h
				
pitpa3_0:			ld			b,0
				jp			pitpa4

;---- modulatie module ----

modmm_0:			ld			a,h
				add			a,2
				cp			12
				jr			nz,modmm3
				ld			a,2
				
modmm3_0:			ld			(iy+6),a
				ld			a,h
				add			a,a
				ld			c,a
				ld			b,0
				ld			hl,modval-2
				add			hl,bc
				ld			c,(hl)
				sla			c
				inc			hl
				ld			b,(hl)
				ld			l,(iy+1)
				ld			h,(iy+2)
				add			hl,bc
				ld			b,0
				jp			pitmm4

;---- modulatie pac ----

modpa_0:			ld			a,(de)
				cp			2
				jr			nz,modpa2
				ld			a,h
				add			a,2
				cp			12
				jr			nz,modpa3
				ld			a,2
				
modpa3_0:			ld	(iy+6),a

modpa2_0:			ld			a,h
				add			a,a
				ld			c,a
				ld			b,0
				ld			hl,modval-2
				add			hl,bc
				ld			c,(hl)
				inc			hl
				ld			b,(hl)
				ld			l,(iy+3)
				ld			h,(iy+4)
				add			hl,bc
				ld			b,0
				jp			pitpa4

;saliendo de las rutinas

mmout_0:			jp			mm2out

fmmout_0:			jp			mm3out

pacout_0:			jp			pc2out

fpcout_0:			jp			pc3out

mm2out_0:			ex			af,af'
				ld			a,c
				out			(0c0h),a
				ex			af,af'
				out			(0c1h),a
				ex			(sp),hl
				ex			(sp),hl
				
				ret
				
pc2out_0:			ex			af,af'
				ld			a,c
				out			(7ch),a
				ex			af,af'
				out			(7dh),a
				ex			(sp),hl
				ex			(sp),hl
				
				ret
	
mm3out_0:			ex			af,af'
				ld			a,c
				out			(0c0h),a
				ex			af,af'
				out			(0c1h),a
				
				ret
	
pc3out_0:			ex			af,af'
				ld			a,c
				out			(7ch),a
				ex			af,af'
				out			(7dh),a
				
				ret
	
mmrout_0:			ex			af,af'
				call		trbwt
				ld			a,c
				out			(0c0h),a
				in			a,(0e6h)
				ld			(rtel),a
				ex			af,af'
				out			(0c1h),a
				
				ret
	
parout_0:			ex			af,af'
				call		trbwt
				ld			a,c
				out			(7ch),a
				in			a,(0e6h)
				ld			(rtel),a
				ex			af,af'
				out			(7dh),a
				
				ret
	
trbwt_0:			push		bc
				ld			a,(rtel)
				ld			b,a
	
trbwl_0:			in			a,(0e6h)
				sub			b
				cp			7
				jr			c,trbwl
				pop			bc
				
				ret




;------ para la música ------

stpms3_0:			call		stpms2
				pop			af
				
				ret
				
stpmus_0:

hltmus_0:			ld			a,(busply)
				or			a
				ret			z
				
stpms2_0:			di

				ld			hl,oldint
				ld			de,0fd9fh
				ld			bc,5
				ldir
	
hltms2_0:			ld			de,22
				ld			iy,laspl1
				ld			b,9
	
hltmsl_0:			call		msxuit
				call		moduit
				add			iy,de
				djnz		hltmsl
				xor			a
				ld			(busply),a
				ei
				jp			endpsg
	
msxuit_0:			ld			a,(xsust)
				bit			5,a
				jr			z,msxui2
				ld			a,b
				cp			4
				ret			c
	
msxui2_0:			ld			c,(iy+8)
				xor			a
				call		pacout
				ld			a,c
				add			a,10h
				ld			c,a
				xor			a
				jp			fpcout
	
moduit_0:			ld			c,(iy+7)
				xor			a
				call		mmout
				set			4,c
				jp			fmmout

;--- psg percusion data ---

pbddat_0:			db			5,3,0,179,1,6,7,0beh,17
ps1dat_0:			db			6,2,6,013h,7,0b7h,15
ps2dat_0:			db			6,2,6,009h,7,0b7h,15
pb1dat_0:			db			4,3,0,173,1,1,7,0beh,15
pb2dat_0:			db			4,3,0,72,1,0,7,0beh,15
ph1dat_0:			db			5,2,6,006h,7,0b7h,15
ph2dat_0:			db			5,2,6,001h,7,0b7h,14
psgadr_0:			dw			pbddat,ps1dat,ps2dat,pb1dat,pb2dat,ph1dat,ph2dat
;psgcnt:		db			0
;psgvol:		db			0

;--- msx-audio data ---

mmpdt1_0: 		db    		005h,022h,005h,06ah,005h,0bah,006h,012h,006h,073h,006h,0d3h
				db   		007h,03bh,007h,0abh,008h,01bh,008h,09ch,009h,024h,009h,0ach
				db  		00ah,03dh,00ah,0d5h,00bh,07dh,00ch,02dh,00ch,0e6h,00dh,0a6h
				db  		00eh,07fh,00fh,057h,010h,03fh,011h,038h,012h,040h,013h,051h
				db  		014h,07ah,015h,0aah,016h,0fbh,018h,05bh,019h,0c4h,01bh,04dh
				db  		01ch,0feh,01eh,0b6h,020h,077h,022h,070h,024h,081h,026h,0aah
				db  		028h,0fch,02bh,05dh,02dh,0f6h,030h,0afh,033h,089h,036h,0a2h
				db  		039h,0f4h,03dh,066h,040h,0f7h,044h,0e1h,049h,00bh,04dh,04dh
				db  		051h,0f0h,056h,0b2h,05bh,0ech,061h,05fh,067h,01ah,06dh,045h
				db  		073h,0e8h,07ah,0cbh,081h,0f0h,089h,0c4h,092h,018h,09ah,0a4h
				
mmrgad_0:			db    		20h,23h,40h,43h,60h,63h,80h,83h,0c0h ;k1
				db    		21h,24h,41h,44h,61h,64h,81h,84h,0c1h ;k2
				db    		22h,25h,42h,45h,62h,65h,82h,85h,0c2h ;k3
				db    		28h,2bh,48h,4bh,68h,6bh,88h,8bh,0c3h ;k4
				db    		29h,2ch,49h,4ch,69h,6ch,89h,8ch,0c4h ;k5
				db    		2ah,2dh,4ah,4dh,6ah,6dh,8ah,8dh,0c5h ;k6
				db   	 	30h,33h,50h,53h,70h,73h,90h,93h,0c6h ;k7
				db    		31h,34h,51h,54h,71h,74h,91h,94h,0c7h ;k8
				db    		32h,35h,52h,55h,72h,75h,92h,95h,0c8h ;k9
				
smpadr_0: 		dw    		0000h,03ffh,0400h,07ffh,0800h,0bffh,0c00h,0fffh
				dw    		1000h,13ffh,1400h,17ffh,1800h,1bffh,1c00h,1fffh
				dw    		0000h,07ffh,0800h,0fffh,1000h,17ffh,1800h,1fffh
				dw    		0000h,0fffh,1000h,1fffh
				
strreg_0: 		db    		16,0f0h,17,051h,18,255,018h,0

;--- msx-music data ---

pafreq_0:			db    		0adh,000h,0b7h,000h,0c2h,000h,0cdh,000h,0d9h,000h,0e6h,000h
				db    		0f4h,000h,003h,001h,012h,001h,022h,001h,034h,001h,046h,001h
				db    		0adh,002h,0b7h,002h,0c2h,002h,0cdh,002h,0d9h,002h,0e6h,002h
				db    		0f4h,002h,003h,003h,012h,003h,022h,003h,034h,003h,046h,003h
				db    		0adh,004h,0b7h,004h,0c2h,004h,0cdh,004h,0d9h,004h,0e6h,004h
				db    		0f4h,004h,003h,005h,012h,005h,022h,005h,034h,005h,046h,005h
				db    		0adh,006h,0b7h,006h,0c2h,006h,0cdh,006h,0d9h,006h,0e6h,006h
				db    		0f4h,006h,003h,007h,012h,007h,022h,007h,034h,007h,046h,007h
				db    		0adh,008h,0b7h,008h,0c2h,008h,0cdh,008h,0d9h,008h,0e6h,008h
				db    		0f4h,008h,003h,009h,012h,009h,022h,009h,034h,009h,046h,009h
				db    		0adh,00ah,0b7h,00ah,0c2h,00ah,0cdh,00ah,0d9h,00ah,0e6h,00ah
				db    		0f4h,00ah,003h,00bh,012h,00bh,022h,00bh,034h,00bh,046h,00bh
				db    		0adh,00ch,0b7h,00ch,0c2h,00ch,0cdh,00ch,0d9h,00ch,0e6h,00ch
				db    		0f4h,00ch,003h,00dh,012h,00dh,022h,00dh,034h,00dh,046h,00dh
				db    		0adh,00eh,0b7h,00eh,0c2h,00eh,0cdh,00eh,0d9h,00eh,0e6h,00eh
				db    		0f4h,00eh,003h,00fh,012h,00fh,022h,00fh,034h,00fh,046h,00fh
				
drmreg_0: 		db    		36h,37h,38h,16h,26h,17h,27h,18h,28h

;--- algemene data ---

_chnwc1_0: 		dw    		0,0,0,0,0

_modval_0: 		dw     		1,2,2,-2,-2,-1,-2,-2,2,2
_mmfrqs_0: 		db    		0
_speed_0: 		db    		0
_spdcnt_0: 		db    		0
_rtel_0:   		db    		0
_patadr_0: 		dw    		0
_patpnt_0: 		dw    		0
_tpval_0:  		db    		0
_xpos_0:   		dw    		0
_laspl1_0: 		db    		0,0,0,0,0,0,0,0a0h,10h,0,0,0,030h,043h,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a1h,11h,0,0,0,031h,044h,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a2h,12h,0,0,0,032h,045h,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a3h,13h,0,0,0,033h,04bh,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a4h,14h,0,0,0,034h,04ch,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a5h,15h,0,0,0,035h,04dh,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a6h,16h,0,0,0,036h,053h,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a7h,17h,0,0,0,037h,054h,0,0,0,0,0,0,0,0
				db    		0,0,0,0,0,0,0,0a8h,18h,0,0,0,038h,055h,0,0,0,0,0,0,0,0
