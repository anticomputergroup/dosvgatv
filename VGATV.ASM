; FAQ : MANTY = Santiago "Manty" Mantinan (manty@geocities.com)
;       (hope this clears it up... :-)

; * : Some relative jumps were too big. Had to "fix" them. Borland did it
;     silently with Borland Pascal...
; Last fix: FIX42, but 19..24 are also free.

; This are the parameters I use for my tasm:
; tasm /m5 /w2 /z /la /zi
; (MANTY)

; Note on the procedures, procedures on the TSR part should tell in a comment
; on the header which registers it uses as input and which as output, also, the
; ones that it overwrites, so that previous calling procedures know which
; registers they need to protect. On the other hand on the non TSR part,
; procedures must also specify the input and outputs but no other register
; must be touch, so the procedure must protect them so we can code in a sure
; way without the need to be always checking things, as we don't care much
; about the used space on this part we don't mind about a couple of extra
; pushes and pops (MANTY)

; Changes:

; from 067 to 081
; on the TSR part, removed the table offset variables (we now have only one),
; changed the htlim handling, now on the non TSR part -> less mem & more speed
; on the non TSR changes to allow to change one4even, polarity, monitor/TV,
; shiftX, shiftY, standard and chipset without having to unload, also it
; loads the chipset and standard values from the TSR part to tell the user
; how it is working.

GENERIC    EQU 0
IBM        EQU 1
REALTEK    EQU 2
 RTEK3103   EQU 6
OAK        EQU 20
 OAK037     EQU 0
 OAK077     EQU 5
 OAK083     EQU 83
S3         EQU 3
 Trio32     EQU 10h
 Trio64     EQU 11h
 Trio3D     EQU 13h
 ViRGE      EQU 31h
 Vision864  EQU 0C0h
 Vision964P EQU 0D1h
CIRRUS     EQU 4
TSENG      EQU 5
 ET3000     EQU 3000
 ET4000     EQU 4000
TRIDENT    EQU 60
 TRI8800BR  EQU 1
 TRI9000i   EQU 43h
 Trident3D  EQU 0F3h
NVIDIA     EQU 7
ATI        EQU 8
Intel      EQU 9
SiS        EQU 10
Matrox     EQU 11
UMC        EQU 12
Paradise   EQU 13
 WD90C30    EQU 3330h

PAL        EQU 99
NTSC       EQU 100

TamPila    EQU 4096

PROGRAM SEGMENT
        ASSUME CS:PROGRAM, DS:PROGRAM, ES:PROGRAM, SS:PILA
        ORG 0

iniTSR EQU $
.8086

include vgatvtsr.asm

endTSR EQU $

  ; Moved all stuff I think is not needed on the TSR here (MANTY)

  VYEAR EQU 2001
  VDATE EQU 0604

  VY1   EQU VYEAR/1000
  VY2   EQU VYEAR/100-10*VY1
  VY3   EQU VYEAR/10-100*VY1-10*VY2
  VY4   EQU VYEAR-1000*VY1-100*VY2-10*VY3

  VD1   EQU VDATE/1000
  VD2   EQU VDATE/100-100*VD1
  VD3   EQU VDATE/10-100*VD1-10*VD2
  VD4   EQU VDATE-1000*VD1-100*VD2-10*VD3

  name_  DB 'VGA to TV driver Ver. 2001.',VD1+'0',VD2+'0',VD3+'0', VD4+'0', 13, 10, '$'
  author DB 'Paulo S‚rgio Coelho, 1997-',VY1+'0',VY2+'0',VY3+'0',VY4+'0', 13, 10, 13, 10, '$'
  webURL DB 'URL: www.radiolink.net/psergio, MAIL: psergio@radiolink.net', 13, 10, '$'
  warez  DB 'This program is cardware! Thanks for your support!', 13, 10, 13, 10, '$'

  ; hbs: Horizontal Blank Start
  ; hrs: Horizontal Retrace Start
  ; hre: Horizontal Retrace End
  ; hbe: Horizontal Blank End
  ; ht : Horizontal Total
  ; vrs: Vertical Retrace Start
  ; vrs: Vertical Retrace End

  ;              hbs hrs rsz bsz  ht
  HSetup_NTSC DB  59, 65,  7, 20,100 ;  320
              DB  41, 46,  4, 12, 56 ; w320 o
              DB  59, 65,  7, 20,100 ;  400
              DB  46, 49,  4, 11, 56 ; w400 o
              DB  75, 82,  8, 22,112 ;  512 o
              DB  82, 90,  8, 22,112 ;  640 o
              DB  82, 94,  8, 22,112 ;  720 o
              DB 141,147, 17, 43,224 ;  768
              DB  94,100,  8, 22,112 ;  800 o
              DB 157,163, 17, 43,224 ;  960
              DB 157,161, 17, 43,224 ; 1024 o
              DB 138,143, 13, 35,177 ; 1188 o
              DB 164,169, 17, 43,224 ; 1152 o
              DB 171,177, 17, 43,224 ; 1280 o
              DB 191,197, 17, 43,224 ; 1600 o

  ;            lines vrs
  VSetup_NTSC DW 175,207 ; 350          o
              DW 192,218 ; 384/768      o
              DW 200,222 ; 400          o
              DW 216,231 ; 432/864      o
              DW 240,242 ; 480/960      o
              DW 256,250 ; 512/1024     o
              DW 270,250 ; 540/1080
              DW 288,261 ; 288/576/1152 o
              DW 300,261 ; 300/600/1200 o
              DW 320,261 ; 640/1280

TABLELENGTH EQU $ - HSetup_NTSC

  ; helpstr must be the first! Used to compute the size of the tables above.

  helpstr DB 'H/? '
  polstr  DB   'I/ISP '
  monitor DB   'M/M '
  oddeven DB   'O/OE '
  stdstr1 DB   'P/PAL '
  stdstr2 DB   'N/NTSC '
  ntrlace DB   'T/NOINTR '
  panx    DB   'X/X: '
  pany    DB   'Y/Y: '
  setIBM  DB 1, '/IBM '
  setRTK  DB 2, '/REALTEK '
  setOAK  DB 20,'/OAK '
  setS3   DB 3, '/S3 '
  skipDet DB   'S/S: '
  setCIR  DB 4, '/CIRRUS '
  setTSG  DB 5, '/TSENG '
  setTRI  DB 60,'/TRIDENT '
  setUMC  DB 12,'/UMC '
  setWD   DB 13,'/WD '
  uninst  DB   'U/U '
  lastprm DB '#'

  skipVGA      DB 0

  envstr DB 'VGATV='
             ;          1         2         3         4         5         6         7         8         9
             ;0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
  LINE1   DB 'Allows the use of a VGA equipped PC, with a common TV as a monitor.',13,10,'$'
  LINE2   DB 'Provides support to all standard VGA modes and most existing VESA modes.',13,10,13,10,'$'
  LINE3   DB 'VGATV [/<chipset>] [/NTSC|PAL] [/X:<shift>] [/Y:<shift>] [<switches>] [/?]',13,10,13,10,'$'
  LINE4   DB '  <chipset>: VGA''s chipset.',13,10,'$'
  LINE5   DB '             Supported chipsets: Standard IBM VGA, Oak, S3, Cirrus, Trident,',13,10,'$'
  LINE5A  DB '             Realtek, Intel i81x, UMC, WD, Tseng Labs.',13,10,'$'
  LINE5B  DB '             Note that some chipsets, namely PCI/AGP cards, cannot be forced.',13,10,'$'
  LINE6   DB '  /NTSC|PAL: chooses NTSC or PAL frequencies (default).',13,10,'$'
  LINE7   DB '  /X or /Y : tells how many lines or characters to pan or shift the image.',13,10,'$'
  LINE8   DB '             Used to center the output on the screen. Parameters can be of',13,10,'$'
  LINE9   DB '             the form /X:<n>, /Y:-<n> or /Y:+<n>, where <n> represents a value.',13,10,'$'
  LINE10  DB '  /ISP     : Inverts sync polarity. Default is negative.',13,10,'$'
  LINE11  DB '  /OE      : If you''re getting black and white screens, try this!',13,10,'$'
  LINE12  DB '  /M       : Switches between monitor and TV modes.',13,10,'$'
  LINE13  DB '  /U       : Uninstall (remove the program from memory).',13,10,'$'
  LINE14  DB '  /NOINTR  : Non interlaced video modes, even if supported.',13,10,'$'
  LINE14A DB '  /S:<n>   : skips n detected cards. When you have more than one VGA card', 13, 10, '$'
  LINE14B DB '             installed and VGATV won''t use what you want. PCI/AGP detection!', 13, 10, '$'
  LINE15  DB '  /?       : this help screen.',13,10,13,10,'$'
  LINE16  DB 'Shortcut keys available :',13,10,'$'
  LINE17  DB '  Ctrl+Alt+R : resets video mode.',13,10,'$'
  LINE18  DB '  Ctrl+Alt+S : switches between VGA and TV mode.',13,10,'$'
  LINE19  DB '  Ctrl+Alt+Arrows : screen-position keys. Used to centre the screen on the',13,10,'$'
  LINE20  DB '     TV. Can be used with the /X and /Y switches.',13,10,10,'$$'

  CHIPSET_STR  DB 'Chipset: $'
  IBM_STR      DB 1, 'Standard IBM VGA',      13, 10, '$'
  REALTEK_STR  DB 2, 'Realtek',               13, 10, '$'
  OAK_STR      DB 20,'Oak Technologies',      13, 10, '$'
  S3_STR       DB 3, 'S3',                    13, 10, '$'
  CIRRUS_STR   DB 4, 'Cirrus Logic CL-GD54xx',13, 10, '$'
  TSENG_STR    DB 5, 'Tseng Labs',            13, 10, '$'
  TRIDENT_STR  DB 60,'Trident',               13, 10, '$'
  NVIDIA_STR   DB 7, 'NVidia (not working)',  13, 10, '$'
  ATI_STR      DB 8, 'ATI (not working)',     13, 10, '$'
  INTEL_STR    DB 9, 'Intel i810/i815',       13, 10, '$'
  SIS_STR      DB 10,'SiS 6326/620/530 (N/W)',13, 10, '$'
  UMC_STR      DB 12,'UMC UM85c4x8',          13, 10, '$'
  PARADISE_STR DB 13,'Western Digital/Paradise',13,10,'$'

  STANDARD_STR DB 13,10,'TV Standard:$'
  PAL_STR      DB 'PAL',13,10,10,'$'
  NTSC_STR     DB 'NTSC',13,10,10,'$'

  PSP     DW 0

  SEG_MCB      DW 0
  LINKS        DB 0
  ESTRAT       DW 0
  VARMEM       DW 2 ; Needs to be initialized (MANTY)
  choose       DB 0 ; idem
  INMEM        DB 0 ; idem
  UNLOADABLE   DB 0 ; idem, 1 means we want to unload, 2 means we want and
                    ; we can, 0 means we don't want to unload.

CHOOSEchipset   EQU 1
CHOOSEstandard  EQU 2
CHOOSEone4even  EQU 4
CHOOSEpolarity  EQU 8
CHOOSEshiftX    EQU 16
CHOOSEshiftY    EQU 32
CHOOSEmonitor   EQU 64
CHOOSEinterlace EQU 128

  FIRMAINS     DB 'INSVGATV'

  FIRMA   DB 'VGATV'                ; THIS IS SOMETHING LIKE A RECORD
          DB 0                      ; IT MUST BE 8 BYTES LONG AND IS USED TO
  VERNUM  DW (VYEAR-1998)*512+VDATE ; RECOGNIZE US IN RAM (MANTY)

  MSG_WRONGDOS     DB 'This version of the program needs at least DOS version 4.0 to run.',10,13,7,'$'
  MSG_RESIDENT     DB 'The program is now resident.',10,13,'$'
  MSG_NOT_RESIDENT DB 'The program could not remain resident (not enough memory?).',10,13,7,'$'
  MSG_OTHER        DB 'Another version of the program is resident.',10,13,7,'$'
  MSG_NOTUNL       DB 'The program cannot be unloaded, other TSRs are sitting on top of it.',10,13,7,'$'
  MSG_YARES        DB 'The program was already resident.',10,13,'$'
  MSG_UNLOAD       DB 'The program has been unloaded.',10,13,'$'
  MSG_NOT_UNLOAD   DB 'The program is not loaded, so it cannot be unloaded.',10,13,7,'$'

;****************************************************************************;

begin PROC NEAR ; Main entry point of the program

;****************************************************************************;

  PUSH CS
  POP DS
  MOV AX,ES     ; The PSP address is already on ES ;-) (MANTY)
  MOV [PSP], AX
  MOV AX, ES:[2Ch]
  XOR BX, BX
  MOV ES, AX
  XOR DI, DI
  MOV SI, OFFSET envstr     ; 'VGATV=' in-code

FINDENV:
  CMPSB
  JE NEXT2
    MOV SI, OFFSET envstr
    CMP BYTE PTR ES:[DI], 0 ; end of env string?
    JNE FINDENV
    CMP BYTE PTR ES:[DI+1], 0
    JNE NEXT2
      JMP COMMAND ; *       ; no environment string VGATV= found

  NEXT2:
    CMP BYTE PTR [SI-1], '='
  JNE FINDENV

  MOV SI, DI
  XOR AX, AX
  MOV CX, 80
  REPNE SCASB
  DEC DI
  MOV CX, DI ; CX=paramstr end
  MOV DI, SI ; DI=paramstr org address
  DEC DI

STRCMP:
  INC DI
  CMP DI, CX
  JB FIX26
    JMP COMMAND ; *
  FIX26:
    CMP BYTE PTR ES:[DI], '/'
  JNE STRCMP

  MOV SI, OFFSET helpstr+1 ; parameter table
  MOV DX, SI               ; param address
  MOV AX, DI               ; AX=beginning of parameter in cmdline

COMP:
  MOV BL, ES:[DI]
  CMP BL, 'a'
  JB OK
    CMP BL, 'z'
    JA OK
      SUB BL, 32
      MOV ES:[DI], BL

OK:
  CMP BYTE PTR [SI], ' ' ; param end
  JE FOUND
  CMP BYTE PTR [SI], ':' ; more values
  JNE FIX27
    JMP GETPARMS ; *
  FIX27:
  CMPSB
  JE COMP
    NEXT:                ; get next parameter in table
      INC SI
      CMP BYTE PTR [SI], '#' ; end of parameter table
      JE NEXT_PARM
        CMP BYTE PTR [SI-1], '/'
        JNE NEXT

    MOV DI, AX
    DEC SI
    MOV DX, SI           ; param address
    JMP COMP

    NEXT_PARM:           ; parameter not found, skip to next one
      INC DI
      CMP DI, CX
      JB FIX28
        JMP COMMAND ; *  ; no more parameters to check
      FIX28:
        CMP BYTE PTR ES:[DI], ' '
        JNE NEXT_PARM
          JMP STRCMP

FOUND:
  MOV SI, DX
  DEC SI
  MOV BL, [SI]
  CMP BL, 'H'
  JNE IS_SYNC
    CALL copyright
    MOV DX, OFFSET LINE1
    MOV AH,09h ; Print String
    HELP:
      INT 21H
      CALL nextstr
      CMP BYTE PTR [DI], '$'
    JNE HELP
    MOV AX, 4C00h ; Terminate Process
    INT 21h

IS_SYNC:
  CMP BL, 'I'
  JNE IS_ODDEVEN
    XOR [polarity], 11000000b
    OR [choose],CHOOSEpolarity
    JMP STRCMP

IS_ODDEVEN:
  CMP BL, 'O'
  JNE IS_UNINSTALL
    XOR [one4even], 1 ; This is normally 0, but may need to be one
    OR [choose],CHOOSEone4even
    JMP STRCMP

IS_UNINSTALL:
  CMP BL, 'U'
  JNE IS_MONITOR
    INC UNLOADABLE
    JMP STRCMP

IS_MONITOR:
  CMP BL, 'M'
  JNE IS_INTERLACE
    XOR [TV], 1
    OR [choose],CHOOSEmonitor
    JMP STRCMP

IS_INTERLACE:
  CMP BL, 'T'
  JNE IS_PAL
    XOR [interlace], 1
    OR [choose],CHOOSEinterlace
    JMP STRCMP

IS_PAL:
  CMP BL, 'P'
  JNE IS_NTSC
    MOV [standard], PAL
    OR [choose],CHOOSEstandard
    MOV [max_total], 313
    JMP STRCMP

IS_NTSC:
  CMP BL, 'N'
  JNE SET_CHIPSET
    MOV [standard], NTSC
    OR [choose],CHOOSEstandard
    MOV [max_total], 263
    JMP STRCMP

SET_CHIPSET:
  OR [choose], CHOOSEchipset
  MOV [chipset], BL
  JMP STRCMP

GETPARMS:
  INC DI
  CMP BYTE PTR ES:[DI], ' '
  JE GETPARMS

  parmEND:
    INC DI
    CMP BYTE PTR ES:[DI], ' '
    JA parmEND
      DEC DI
      PUSH BX
      PUSH CX
      XOR CX, CX
      MOV BL, 1

    GETVALUE:
      MOV AL, ES:[DI]
      CMP AL, '-'
      JNE PLUS
        NEG CX
        JMP SETSHIFT

    PLUS:
      CMP AL, '+'
      JE SETSHIFT
      CMP AL, ':'
      JE SETSHIFT
      SUB AL, 48
      MUL BL
      ADD CL, AL
      DEC DI
      XCHG AL, BL
      MOV BH, 10
      MUL BH
      XCHG AL, BL ; BL=BL*10
      JMP GETVALUE

    SETSHIFT:
      MOV SI, DX
      DEC SI
      MOV BL, [SI]
      CMP BL, 'X'
      JNE _SHIFTY
        MOV [shiftX], CL
        OR [choose], CHOOSEshiftX
        POP CX
        POP BX
        JMP STRCMP

    _SHIFTY:
      cmp bl, 'Y'
      jne _SkipCards
        MOV [shiftY], CX
        OR [choose], CHOOSEshiftY
        POP CX
        POP BX
        JMP STRCMP

    _SkipCards:
      mov [skipVGA], CL
      pop cx
      pop bx
      jmp strcmp

COMMAND:
  INC BH
  CMP BH, 1
  JA INT_SETUP
    MOV ES, [PSP]
    MOV DI, 80h ; parameter string
    XOR CX, CX
    MOV CL, ES:[DI]
    ADD CX, DI
    INC CX
    JMP STRCMP

INT_SETUP:
  CMP [standard],NTSC
  JNE GETINTs
    LEA SI,HSetup_NTSC
    LEA DI,HSetup
    PUSH DS
    POP ES
    MOV CX,TABLELENGTH
    REP MOVSB

GETINTs:
  MOV AH,35h
  MOV AL,09h
  INT 21h
  MOV [oldkeybISR_OFS],BX
  MOV [oldkeybISR_SEG],ES
  MOV AH,35h
  MOV AL,10h
  INT 21h
  MOV [oldINT10h_OFS],BX
  MOV [oldINT10h_SEG],ES
  CALL getCRTC

  CMP [chipset], realtek
  JNE FIX42
    JMP __REALTEK

  FIX42:
    CMP [chipset],oak
    je _Oak
      CMP [chipset], 255
      JE FIX29
        JMP _CONT ; * ; no further tests performed on given chipset

  FIX29:
    xor ch, ch    ; Commence PCI bus type detection
    mov dx, 0CF8h ; Based on Finn Thoegersen's WHATVGA
    xor ax, ax
    out dx, al
    inc dx
    inc dx
    out dx, al
    dec dx
    dec dx
    in al, dx
    and al, al
    jnz TryType1
      inc dx
      inc dx
      in al, dx
      and al, al
      jnz TryType1
        mov ch, 2 ; Type 2 PCI bus found!
        call DetectPCIVGAChipsets
        mov dx, 0CF8h
        xor al, al
        out dx, al
        cmp [chipset], 255
        je NoPCI2 ; No known PCI VGA found
          jmp _CONT

.386
  TryType1:
    mov dx, 0CF8h
    in eax, dx    ; PCI bus only appear on 386+ machines, so no problem...I think :-)
    mov ebx, eax
    mov cl, 16
    mov eax, 80000000h
    out dx, eax
    in eax, dx
    cmp eax, 80000000h
    jne NoPCI     ; No PCI bus around
      inc ch
      call DetectPCIVGAChipsets
      cmp [chipset], 255
      je NoPCI
        jmp _CONT ; PCI VGA found

  NoPCI:
    mov eax, ebx
    out dx, eax

.8086
  NoPCI2:
    MOV DX,3DEh  ; We're gonna try to detect the chipset
    MOV AX,380Dh ; mask,index
    CALL testinx2
    AND AL,AL
    JZ TEST_TRIDENT
      MOV [chipset], oak ; Oak here!

    _OAK:
      MOV DX,3DEh
      MOV AX,1F23h ; mask,index
      CALL testinx2
      AND AL,AL
      JZ OLD
        MOV [_model], oak083 ; Oak 083/087
        JMP _CONT

    OLD:
      MOV DX,3DEh
      xor ax, ax
      IN AL,DX
      SHR AL,1
      SHR AL,1
      SHR AL,1
      SHR AL,1
      SHR AL,1
      mov [_model], ax
      jmp _CONT

  TEST_TRIDENT:
    MOV DX, 3C4h
    MOV AL, 0Bh
    OUT DX, AL
    INC DX
    XOR AL, AL
    OUT DX, AL ; Force registers into old mode
    IN AL, DX  ; But after this read, they're in new mode again [not 8800BR]
    MOV CL, AL ; chip
    DEC DX
    MOV AL, 0Eh
    OUT DX, AL
    INC DX
    IN AL, DX
    MOV CH, AL ; old
    XOR AL, AL
    OUT DX, AL
    IN AL, DX
    AND AL, 0Fh
    MOV BL, AL ; value
    MOV AL, CH
    OUT DX, AL
    CMP BL, 2
    JNE T8800BR
      MOV [chipset], trident
      xor ax, ax
      mov al, cl
      mov [_model], ax
      XOR CH, 2
      MOV AL, CH
      OUT DX, AL
      JMP _CONT

    T8800BR:
      CMP CL, 1
      JNE TEST_CIRRUS
        MOV DX, 3C4h
        MOV AX, 060Eh ; mask,index
        CALL testinx2
        AND AL, AL
        JZ TEST_CIRRUS
          MOV [chipset], Trident
          MOV [_model], TRI8800BR ; Trident TVGA 8800BR
          JMP _CONT

  TEST_CIRRUS:
    MOV DX, 3C4h
    MOV AL, 06h
    OUT DX, AL
    INC DX
    IN AL, DX
    MOV CL, AL ; old
    XOR AL, AL
    OUT DX, AL
    IN AL, DX
    CMP AL, 0Fh
    JNE NOT_CIRRUS
      MOV AL, 12h
      OUT DX, AL
      IN AL, DX
      and al, 111b
      CMP AL, 010b ; ...or it won't detect Acumos AVGA/GD5402
      JE FIX39
        JMP NOT_CIRRUS
      FIX39:
        DEC DX
        MOV AX, 3F1Eh
        CALL testinx2 ; mask,index
        AND AL, AL
        JNZ FIX41
          JMP NOT_CIRRUS
        FIX41:
          MOV AL, 27h
          CALL readCRTC
          MOV CL, AL  ; SubVers
          mov [chipset], cirrus
          mov [htlim], 2
          jmp _Cont

          ;MOV DX, 3CEh   ; Detecting GD542x, 543x
          ;MOV AX, 0FF09h ; testinx( 3CEh, 09h )
          ;CALL testinx2
          ;AND AL, AL

    NOT_CIRRUS:
      MOV AL, CL
      OUT DX, AL

  TEST_S3:
    MOV DX, [CRTC]
    MOV AX, 0038h
    OUT DX, AX
    MOV AX, 0F35h
    CALL testinx2 ; mask, index
    AND AL, AL
    JNZ TEST_UMC ; Not S3
      MOV AX, 4838h
      OUT DX, AX
      MOV AX, 0F35h
      CALL testinx2
      AND AL, AL
      JZ TEST_UMC ; Not S3
        MOV [chipset], s3
        mov al, 30h
        call readCRTC
        cmp al, 0E0h
        je Trio
          cmp al, 0E1h
          je Trio
            xor ah, ah
            mov [_model], ax
            jmp _cont

      Trio:
        mov al, 2Eh
        call readCRTC
        xor ah, ah
        mov [_model], ax
        JMP _CONT

  TEST_UMC:
    mov dx, 3BFh
    in al, dx
    mov bl, al ; old
    mov al, 3
    out dx, al
    mov dx, 3C4h
    mov ax, 0FF06h
    call testinx2
    and al, al
    jnz NotUMC
      mov dx, 3BFh
      mov al, 0ACh
      out dx, al
      mov dx, 3C4h
      mov ax, 0FF06h
      call testinx2
      and al, al
      jz NotUMC
        mov [chipset], UMC
        jmp _CONT

    NotUMC:
      mov dx, 3BFh
      mov al, bl
      out dx, al

  TestWestDigital:
    mov dx, 3CEh
    mov al, 0Fh
    out dx, al
    inc dx
    in al, dx  ; rdinx
    mov ch, al ; old
    or al, 17h
    out dx, al
    dec dx
    mov ax, 7F09h
    call testinx2; mask, index
    and al, al
    jnz NotParadise ; really? :-)
      mov ax, 170Fh
      mov bl, 101b
      call modinx
      mov ax, 7F09h
      call testinx2; mask, index
      and al, al
      jz NotParadise
        mov [chipset], Paradise
        mov al, 36h
        mov dx, [CRTC]
        out dx, al
        inc dx
        in al, dx
        mov bl, al
        dec dx
        mov al, 37h
        out dx, al
        inc dx
        in al, dx
        mov ah, bl
        mov [_model], ax

    NotParadise:
      mov dx, 3CEh
      mov al, 0Fh
      mov ah, ch
      out dx, ax
      cmp [chipset], Paradise
      jne TestTsengLabs
        jmp _Cont

  TestTsengLabs:
    mov dx, 3BFh
    mov al, 3
    out dx, al
    mov dx, [CRTC]
    add dx, 4
    mov al, 0A0h
    out dx, al
    mov ah, 3Fh
    mov dx, 3CDh
    call tstrg ; port, mask
    and al, al
    jz TestRealtek
      mov [chipset], Tseng
      mov [_model], ET3000
      mov dx, [CRTC]
      mov ax, 0F33h
      call testinx2; mask, index
      and al, al
      jz TestRealtek
        mov [_model], ET4000
        jmp _Cont

  TestRealtek:
    MOV DX, [CRTC]
    MOV AX, 3F1Fh
    CALL testinx2; mask, index
    AND AL, AL
    JNZ _CONT
      mov ah, 0Fh
      MOV DX, 3D6h
      CALL tstrg; port, mask
      AND AL, AL
      JNZ _CONT ; Not Realtek
        mov ah, 0Fh
        MOV DX, 3D7h
        CALL tstrg; port, mask
        AND AL, AL
          JNZ _CONT ; Not Realtek
            MOV [chipset], realtek

         __REALTEK:
            MOV DX, [CRTC]
            MOV AL, 1Ah
            OUT DX, AL
            INC DX
            IN AL,DX
            AND AL,AL
            JNZ _CONT
              MOV [_model], rtek3103
              JMP _CONT

; testinx2(port,index,mask) = MOV AX,mask/index
;                             CALL testinx2
;                             AND AL,AL
;                             JZ BAD
;                               OK:
;                             BAD:
; wrinx(port,index,value) = MOV AX,value/index
;                           MOV DX,port
;                           OUT DX,AX
; tstrg( port, mask ) = MOV DX,port
;                       mov ah,mask
;                       CALL tstrg
;                       AND AL,AL
;                       JZ BAD
;                         OK:
;                       BAD:

_CONT:
  MOV AX,3000h
  INT 21h
  CMP AL,4
  LEA DX,MSG_WRONGDOS
  JC EXITING_
  CALL GUARDA_Y_MODIFICA_LINKS_Y_ESTRATEGIAS
  CALL BUSCA_EN_MCBS
  CMP INMEM,0
  JNE RESIDENT

  LEA DX, MSG_NOT_UNLOAD
  CMP UNLOADABLE,0
  JNE EXITING_
  CALL DEJALO_RESIDENTE
  LEA DX, MSG_RESIDENT
  JNC EXITING_
  LEA DX, MSG_NOT_RESIDENT
EXITING_:
  JMP EXITING

RESIDENT:
  LEA DX, MSG_OTHER
  CMP INMEM,1
  JNE EXITING_            ; Another version is resident
    PUSH ES
    MOV AX,SEG_MCB
    INC AX
    MOV ES,AX
    TEST [choose],CHOOSEchipset ; If the user has chosen a chipset we upgrade
    JZ CHIPNOTCHOSEN            ; the TSR with it
      MOV AL,[chipset]
      MOV ES:[chipset],AL
      mov ax, [_model]
      mov es:[_model], ax
      MOV AL,[htlim]
      MOV ES:[htlim],AL
      JMP CHOOSESTD

CHIPNOTCHOSEN:            ; if not, we get the old TSR values to inform about
  MOV AL,ES:[chipset]     ; about the working values
  MOV [chipset],AL

CHOOSESTD:                ; same as before but with the TV standard
  TEST [choose],CHOOSEstandard
  JZ STDNOTCHOSEN
    MOV AX,[max_total]
    MOV ES:[max_total],AX
    MOV AL,[standard]
    MOV ES:[standard],AL
    LEA SI,HSetup
    CMP AL,NTSC
    JNE PALCHOSEN
      LEA SI,HSetup_NTSC

PALCHOSEN:
  LEA DI,HSetup
  MOV CX,TABLELENGTH
  REP MOVSB
  JMP ONE4EVENCHOSEN

STDNOTCHOSEN:
  MOV AL,ES:[standard]
  MOV [standard],AL

ONE4EVENCHOSEN:
  TEST [choose],CHOOSEone4even
  JZ one4evenNOTCHOSEN
    XOR ES:[one4even],1

one4evenNOTCHOSEN:
  TEST [choose],CHOOSEpolarity
  JZ polarityNOTCHOSEN
    XOR ES:[polarity],11000000b

polarityNOTCHOSEN:
  TEST [choose],CHOOSEmonitor
  JZ monitorNOTCHOSEN
    XOR ES:[TV],1

monitorNOTCHOSEN:
  TEST [choose],CHOOSEinterlace
  JZ interlaceNOTCHOSEN
    MOV AL,[interlace]
    MOV ES:[interlace],AL

interlaceNOTCHOSEN:
  TEST [choose],CHOOSEshiftX
  JZ shiftXNOTCHOSEN
    MOV AL,[shiftX]
    MOV ES:[shiftX],AL

shiftXNOTCHOSEN:
  TEST [choose],CHOOSEshiftY
  JZ shiftYNOTCHOSEN
    MOV AX,[shiftY]
    MOV ES:[shiftY],AX

shiftYNOTCHOSEN:
  POP ES
  LEA DX, MSG_NOTUNL
  CMP [UNLOADABLE],1      ; can it be unloaded?
  JE EXITING
    LEA DX, MSG_YARES
    JB EXITING
      CALL DESCARGA
      LEA DX, MSG_UNLOAD

EXITING:
  PUSH DX
  MOV AX, 03h
  INT 10h
  CALL copyright
  MOV DX, OFFSET CHIPSET_STR
  MOV AH, 09h
  INT 21h
  MOV AH, [chipset]
  CMP AH, 255
  JNE _CHIPSET
    INC AH
    INC AH

_CHIPSET:
  CALL nextstr
  CMP AH, [DI]
  JNE _CHIPSET
    INC DX

  MOV AH, 09h
  INT 21h
  MOV DX, OFFSET STANDARD_STR
  INT 21h
  MOV DX, OFFSET PAL_STR
  CMP [standard], NTSC
  JNE TV_STR
    MOV DX, OFFSET NTSC_STR

TV_STR:
  INT 21h
  POP DX
  INT 21h

  CALL REPONELINKS
  MOV AX, 4C00h ; Terminate Process
  INT 21h

begin ENDP
;****************************************************************************;


;****************************************************************************;

DEJALO_RESIDENTE PROC NEAR
                                        ; entrada: ds,es, prog no residente
                                        ; salida:  si cf -> error

;****************************************************************************;

        PUSH AX
        PUSH BX
        PUSH CX
        PUSH SI
        PUSH DI
        PUSH ES

        MOV AX,PSP
        MOV ES,AX
        MOV BX, (256+endPROG-iniTSR+TamPila)/16+1 ; FREE EVERYTHING BUT OUR SIZE
        MOV AH,4Ah
        INT 21h
        CLI
TRYAGAIN:
        MOV AX,5801h            ; SETS STARTEGY: BEST FIT FOR UMB
        MOV BX,VARMEM           ;                OR LAST FIT FOR LOW MEM
        INT 21h
        CLI

        MOV BX, (endTSR - iniTSR) / 16 + 1
        MOV AH,48h              ; GET MEM
        INT 21h
        CLI
        JNC MEM
        CMP VARMEM,41h
        JNE NOMEM
        MOV VARMEM,2
        JMP TRYAGAIN

NOMEM:
        STC
        JMP FIN_DEJALO_RESIDENTE

MEM:
        PUSH DX
        PUSH DS
        MOV ES,AX
        XOR DI,DI               ; COPIA AL
        LEA SI,iniTSR           ; NUEVO
        MOV CX,endTSR-iniTSR    ; BLOQUE LAS
        REP MOVSB               ; RUTINAS
        DEC AX                  ; ES
        MOV ES,AX               ; DESTRUIDO
        INC AX

        MOV WORD PTR ES:[1],AX  ; CAMBIA PROPIERARIO
        MOV DI,8                ; CAMBIA
        LEA SI,FIRMA
        MOV CX,8
        REP MOVSB               ; FIRMA

        MOV DS,AX               ; PONE DS PARA DEJAR RESIDENTE
        LEA DX,keybISR
        MOV AX,2509h
        INT 21h
        LEA DX,videoISR
        MOV AX,2510h
        INT 21h
        POP DS
        POP DX
        CLC

FIN_DEJALO_RESIDENTE:
        POP ES
        POP DI
        POP SI
        POP CX
        POP BX
        POP AX
        RET

DEJALO_RESIDENTE ENDP

;****************************************************************************;

GUARDA_Y_MODIFICA_LINKS_Y_ESTRATEGIAS PROC NEAR
                                        ; salida: Activa si es posible los
                                        ;         al UMB y guarda su estado.
;****************************************************************************;

        PUSH AX
        PUSH BX
        MOV AX,5802h            ; GUARDA EL ESTADO DE LOS LINKS AL UMB
        INT 21h
        CLI
        JC PIDEEST
        MOV LINKS,AL
        MOV AX,5803h            ; HACE EL LINK AL UMB
        MOV BX,1
        INT 21h
        CLI
        JC PIDEEST
        MOV VARMEM,41h          ; VARMEM ESTA INICIALIZADA A 2,SI HAY SUP->BEST
                                ; (41) SINO SE CARGA ARRIBA (LAST=2)
PIDEEST:
        MOV AX,5800h            ; GUARDA ESTRATEGIA ANTERIOR
        INT 21h
        CLI
        MOV ESTRAT,AX
        POP BX
        POP AX
        RET

GUARDA_Y_MODIFICA_LINKS_Y_ESTRATEGIAS ENDP

;****************************************************************************;

REPONELINKS PROC NEAR
                                        ; entrada: ds
;****************************************************************************;

        PUSH AX
        PUSH BX
        MOV AX,5803h            ; PONE EL ESTADO DE LOS LINKS BIEN
        XOR BH,BH
        MOV BL,LINKS
        INT 21h
        CLI
        MOV AX,5801h            ; PONE COMO ESTRATEGIA LA QUE ESTABA
        MOV BX,ESTRAT
        INT 21h
        CLI
        POP BX
        POP AX
        RET

REPONELINKS ENDP

;****************************************************************************;

BUSCA_EN_MCBS PROC NEAR
                                        ; entrada: ds
;****************************************************************************;

        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DI
        PUSH SI
        PUSH ES

        MOV AX,PSP              ; We change our name on the MCBs so we don't
        DEC AX                  ; find ourselves
        MOV ES,AX
        MOV DI,8
        LEA SI,FIRMAINS
        MOV CX,8
        REP MOVSB

        MOV AX,5200h             ; Obtengo direcci¢n del primer MCB
        INT 21h
        CLI
        CMP BX,2
        JAE COGEDIR
        MOV AX,ES
        DEC AX
        MOV ES,AX
        ADD BX,16
COGEDIR:
        DEC BX
        DEC BX
        MOV AX,WORD PTR ES:[BX] ; Pongo en AX la direccion del 1er MCB
OTROMCB:                        ; recorro la lista de MCBS
        MOV ES,AX
        INC AX
        LEA SI,FIRMA            ; comprueba si la firma es VGATV
        MOV CX,6
        MOV DI,8
        REPE CMPSB
        JE VALIDA

TODAVIANADA:
        ADD AX,WORD PTR ES:[3]
        CMP BYTE PTR ES:[0],'M'
        JE OTROMCB
        JMP FIN_BUSCA_EN_MCBS

VALIDA:
        CMP WORD PTR ES:[1],AX
        JNE TODAVIANADA
YARES:
        MOV CX,WORD PTR ES:[14]
        CMP CX,VERNUM
        JNE OTRA_VER
          MOV INMEM,1                             ; THIS VERSION
          MOV SEG_MCB,ES
          CMP oldkeybISR_SEG,AX
          JNE FIN_BUSCA_EN_MCBS
            CMP oldINT10h_SEG,AX
            JNE FIN_BUSCA_EN_MCBS
              CMP oldkeybISR_OFS,OFFSET keybISR
              JNE FIN_BUSCA_EN_MCBS
                CMP oldINT10h_OFS, OFFSET videoISR
                JNE FIN_BUSCA_EN_MCBS
                  CMP UNLOADABLE,1
                  JNE FIN_BUSCA_EN_MCBS
                    INC UNLOADABLE
                    JMP FIN_BUSCA_EN_MCBS
OTRA_VER:
        MOV INMEM,2                             ; ANOTHER VERSION
FIN_BUSCA_EN_MCBS:
        POP ES
        POP SI
        POP DI
        POP CX
        POP BX
        POP AX
        RET

BUSCA_EN_MCBS ENDP

;****************************************************************************;

DESCARGA PROC NEAR
                                        ; entrada: ds es y programa residente
                                        ; salida:  si cf -> error -> DX=direc

;****************************************************************************;

  PUSH AX
  PUSH CX
  PUSH ES
  PUSH DS
  PUSH DX
  MOV CX,PSP
  MOV AX,SEG_MCB
  PUSH AX
  INC AX
  MOV ES,AX
  LDS DX,ES:oldINT10h
  MOV AX,2510h
  INT 21h
  CLI
  LDS DX,ES:oldkeybISR
  MOV AX,2509h
  INT 21h
  CLI
  POP ES
  MOV WORD PTR ES:[1],CX
  POP DX
  POP DS
  POP ES
  POP CX
  POP AX

  RET

DESCARGA ENDP

;****************************************************************************;

testinx2 PROC NEAR ; Adapted from VGADOC 4b

;****************************************************************************;

  OUT DX, AL
  INC DX
  IN AL, DX
  MOV CL, AL ; old
  MOV BH, AH ; mask
  NOT AH
  AND AL, AH
  OUT DX, AL
  IN AL, DX
  AND AL, BH
  MOV CH, AL ; nw1
  MOV AL, CL
  OR AL, BH
  OUT DX, AL
  IN AL, DX
  AND AL, BH
  MOV AH, AL ; nw2
  MOV AL, CL
  OUT DX, AL
  dec dx
  XOR AL, AL
  AND CH, CH
  JNZ inxEND
    CMP AH, BH
    JNE inxEND
      INC AL

inxEND:
  RET

testinx2 ENDP

;****************************************************************************;

tstrg PROC NEAR ; Adapted from VGADOC 4b

;****************************************************************************;

  IN AL, DX
  MOV CL, AL ; old
  MOV BH, AH ; mask
  NOT AH
  AND AL, AH
  OUT DX, AL
  IN AL, DX
  AND AL, BH
  MOV CH, AL ; nw1
  MOV AL, CL
  OR AL, BH
  OUT DX, AL
  IN AL, DX
  AND AL, BH
  MOV AH, AL ; nw2
  MOV AL, CL
  OUT DX, AL
  XOR AL, AL
  AND CH, CH
  JNZ tstregEND
    CMP AH, BH
    JNE tstregEND
      INC AL

tstregEND:
  RET

tstrg ENDP

;****************************************************************************;

nextstr PROC NEAR

;****************************************************************************;

  MOV BX, DS
  MOV ES, BX
  MOV AL, '$'
  MOV DI, DX
  MOV CX, 99
  REPNE SCASB
  MOV DX, DI
  RET

nextstr ENDP

;****************************************************************************;

copyright PROC NEAR

;****************************************************************************;

  MOV DX, OFFSET name_
  MOV AH, 09h ; Print String
  INT 21h
  MOV DX, OFFSET author
  MOV AH, 09h ; Print String
  INT 21h
  MOV DX, OFFSET webURL
  MOV AH, 09h ; Print String
  INT 21h
  MOV DX, OFFSET warez
  MOV AH, 09h ; Print String
  INT 21h
  RET

copyright ENDP

;****************************************************************************;

TestPCIVGAChipset PROC NEAR
.386
;****************************************************************************;

  mov dx, ax
  shr eax, 16
  cmp dx, 1002h ; ATI
  je ATIFound
    cmp dx, 10DEh ; NVidia
    je NVidiaFound
      cmp dx, 8086h ; Intel on-board
      jne NextID
        cmp ax, 1102h ; i815
        je IntelFound
          cmp ax, 1112h ; i815
          je IntelFound
            cmp ax, 1132h ; i815, Solano
            je IntelFound
              cmp ax, 7800h ; i740
              je IntelFound

    NextID:
        ret ; Some other device

ATIFound:
  mov [chipset], ATI
  mov [_model], ax
  jmp ChipsetFound

NVidiaFound:
  mov [chipset], NVIDIA
  mov [_model], ax
  jmp ChipsetFound

IntelFound:
  mov [chipset], Intel
  mov [_model], ax

ChipsetFound:
  pop ax           ; returns to the main routine if
  cmp [skipVGA], 0 ; no more VGA chipsets to ignore
  je NextID        ; go get the next one
    push ax        ; still not done. Replace the previous return address
    dec [skipVGA]  ; one down, more to go
    mov [chipset], 255
    ret

TestPCIVGAChipset ENDP
.8086
;****************************************************************************;

DetectPCIVGAChipsets PROC NEAR
.386
;****************************************************************************;

  cmp ch, 1
  jne PCIType2
    mov ecx, 512
    mov ebx, 80000000h
    ScanPCI1Bus:
      dec ecx
      jc DetectEnd
        mov eax, ecx
        shl eax, 11
        add eax, ebx
        mov dx, 0CF8h
        out dx, eax
        mov dx, 0CFCh
        in eax, dx
        cmp eax, 0FFFFFFFFh
        je ScanPCI1Bus
          call TestPCIVGAChipset
          jmp ScanPCI1Bus

PCIType2:
  mov ax, 0080h
  mov dx, 0CF8h
  out dx, al
  inc dx
  inc dx
  mov al, ah
  out dx, al
  mov cx, 16
  mov bx, 0C000h
  ScanPCI2Bus:
    dec cx
    jc DetectEnd
      mov dx, cx
      shl dx, 8
      add dx, bx
      in eax, dx
      cmp eax, 0FFFFFFFFh
      je ScanPCI2Bus
        call TestPCIVGAChipset
        jmp ScanPCI2Bus

DetectEnd:
  ret

DetectPCIVGAChipsets ENDP
.8086
;****************************************************************************;
endPROG EQU $

PROGRAM ENDS

PILA          SEGMENT STACK 'STACK'
               DB    TamPila DUP (?) ; stack for the non TSR part
PILA          ENDS

END begin
