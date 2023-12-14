  ; hbs: Horizontal Blank Start
  ; hrs: Horizontal Retrace Start
  ; hre: Horizontal Retrace End
  ; hbe: Horizontal Blank End
  ; ht : Horizontal Total
  ; vrs: Vertical Retrace Start
  ; vrs: Vertical Retrace End

  ;              hbs hrs rsz bsz  ht
  HSetup      DB  63, 66,  7, 19,101 ;  320
              DB  42, 47,  4, 12, 57 ; w320
              DB  63, 66,  7, 19,101 ;  400
              DB  47, 50,  4, 11, 57 ; w400
              DB  77, 82,  8, 22,113 ;  512
              DB  84, 90,  8, 22,113 ;  640
              DB  84, 95,  8, 22,113 ;  720
              DB 143,149, 17, 43,226 ;  768 ; > 768 lines (e.g.768x1024)
              DB  95,100,  8, 22,113 ;  800 ; also <=768 lines
              DB 159,165, 17, 43,226 ;  960
              DB 159,162, 17, 43,226 ; 1024
              DB 140,145, 13, 35,179 ; 1056
              DB 166,170, 17, 43,226 ; 1152
              DB 172,178, 17, 43,226 ; 1280
              DB 193,199, 17, 43,226 ; 1600

  ;            lines vrs
  VSetup      DW 175,234 ; 350
              DW 192,242 ; 384/768
              DW 200,246 ; 400
              DW 216,253 ; 432/864
              DW 240,266 ; 480/960
              DW 256,274 ; 512/1024
              DW 270,282 ; 540/1080
              DW 288,291 ; 288/576/1152
              DW 300,296 ; 300/600/1200
              DW 320,296 ; 640/1280

  max_lines DW 320
  max_total DW 313
  standard  DB PAL
  chipset   DB 255
  _model    DW generic
  shiftX    DB 0
  shiftY    DW 0
  htlim     DB 3
  one4even  DW 0 ; this value will be added to the number of retrace lines,
                 ; to make sure we have an even number of vertical retrace
                 ; lines
  polarity  DB 00110011b ; Positive
  interlace DB 1 ; interlaced mode, by default
  fullFrame DB 0 ; 0:Field line numbers, 1=Frame line numbers

  hrsz      DB 0 ; Horizontal Retrace Size
  hbsz      DB 0 ; Horizontal Blank Size
  hde       DB 0 ; Horizontal Display End
  ht        DB 0 ; Horizontal Total
  CRTC      DW 0

  genOrg     DB 0 ;
  genNew     DB 0 ; Miscellaneous Output, 3CCh/3C2h
  seqReg     DB 6 DUP (?)  ; 3C4h/3C5h
  seqIdx     DB 0
  CRTReg     DB 60 DUP (?) ; 3D4h/3D5h
  CRTIdx     DB 0
  ext1Reg    DB 3 DUP (?)  ; Oak=3DEh/3DFh
  ext1Idx    DB 0
  charHeight DB 0
  charDef    DW 0

;****************************************************************************;

modinx PROC NEAR ; Adapted from VGADOC 4b

;****************************************************************************;

  out dx, al
  inc dx
  in al, dx
  not ah
  and al, ah
  not ah
  and bl, ah
  add al, bl
  out dx, al
  dec dx
  ret

modinx ENDP

;****************************************************************************;

StuffReg PROC NEAR ; Actually outputs AL into port DX. Updates the undo table
                   ; IN  : AL, DX, SI, DI
                   ; OUT : None
                   ; Changes : SI

;****************************************************************************;

  PUSH CX
  PUSH AX
  DEC DX    ; Decrement DX to point to the base register port
  IN AL,DX  ; Read the currently selected register
  INC DX    ; Restore DX to point to the data port
  XOR CX,CX

NEXTREG:
  CMP CL,[DI]
  JNE CHKREG
    MOV CL,AL
    IN AL,DX
    MOV CH,AL
    MOV [SI],CX
    INC BYTE PTR [DI]
    JMP FOUNDREG

CHKREG:
  CMP BYTE PTR [SI],AL
  JE FOUNDREG
    INC SI
    INC SI
    INC SI
    INC CL
    JMP NEXTREG

FOUNDREG:
  POP AX
  INC SI
  INC SI
  MOV [SI],AL
  POP CX
  OUT DX,AL
  RET

StuffReg ENDP

;****************************************************************************;

SwapRegs PROC NEAR ; Swaps the old<->new register values and updates the
                   ; VGA controller specified by DX. Works most of the time...
                   ; IN  : DX, SI, DI
                   ; OUT : None
                   ; Changes : AX, BL, CX, DX, SI

;****************************************************************************;

  XOR CX,CX

REGIDX:
  CMP CL,[DI]
  JE ENDSWAP
    MOV AL,[SI]
    CMP DX,3C4h  ; Sequencer Registers
    JNE NOTCLK
      CMP AL,1   ; Clocking Mode
      JNE NOTCLK
        XCHG CH,AL
        OUT DX,AL
        INC DX
        OUT DX,AL
        DEC DX
        MOV AL,CH

  NOTCLK:
    OUT DX,AL
    INC SI
    MOV BL,[SI]
    CMP DX,[CRTC] ; CRTC Registers
    JNE NOTLOCK
      CMP AL,11h  ; Vertical Retrace End
      JNE NOTLOCK
        AND BL,01111111b ; CRTC #0..#7 Protection:off

  NOTLOCK:
    INC DX
    MOV AL,BL
    OUT DX,AL
    DEC DX
    INC SI
    XCHG AL,[SI]
    DEC SI
    MOV [SI],AL
    CMP CH,1
    JNE NORESET
      XOR CH,CH
      XOR AL,AL
      OUT DX,AL
      MOV AL,DH ; DX=3C4h, DH=03h
      INC DX
      OUT DX,AL

  NORESET:
    INC SI
    INC SI
    INC CL
    JMP REGIDX

ENDSWAP:
  RET

SwapRegs ENDP

;****************************************************************************;

OutSeq PROC NEAR ; Outputs a byte into the Sequencer. Updates the undo table.
                 ; IN  : AL, DX
                 ; OUT : None
                 ; Changes : None

;****************************************************************************;

  PUSH SI
  PUSH DI
  MOV SI,OFFSET seqReg
  MOV DI,OFFSET seqIdx
  CALL StuffReg
  POP DI
  POP SI
  RET

OutSeq ENDP

;****************************************************************************;

OutCRTC PROC NEAR ; Outputs a byte to the CRT Controller; updates the undo tbl
                  ; IN  : AL, DX
                  ; OUT : None
                  ; Changes : None

;****************************************************************************;

  PUSH SI
  PUSH DI
  MOV SI,OFFSET CRTReg
  MOV DI,OFFSET CRTIdx
  CALL STUFFREG
  POP DI
  POP SI
  RET

OutCRTC ENDP

;****************************************************************************;

OutExt1 PROC NEAR ; Outputs a byte to DX. Updates the undo table
                  ; IN  : AL, DX
                  ; OUT : None
                  ; Changes : None

;****************************************************************************;

  PUSH SI
  PUSH DI
  MOV SI,OFFSET ext1Reg
  MOV DI,OFFSET ext1Idx
  CALL STUFFREG
  POP DI
  POP SI
  RET

OutExt1 ENDP

;****************************************************************************;

unprotect PROC NEAR ; Used to unprotect the register set
                    ; called just once, candidate for insertion (macro?) (MANTY)

;****************************************************************************;

  MOV AL, 11h       ; Vertical Retrace End
  CALL readCRTC
  AND AL, 01111111b ; CRTC #0..#7 Protection:off
  CALL OutCRTC

  CMP [chipset], s3
  JNE unpTRIDENT
    MOV DX, 3C4h
    MOV AX, 0608h
    OUT DX, AX
    MOV DX, [CRTC]
    MOV AX, 4838h
    OUT DX, AX
    MOV AX, 0A539h
    OUT DX, AX
    RET

unpTRIDENT:
  CMP [chipset], Trident
  JNE unpNVIDIA
    mov dx, 3C4h
    cmp [_model], Trident3D
    jne genTrident
      mov ax, 9211h ; Protection, Unlock all registers
      out dx, ax

  genTrident:
    MOV AL, 0Bh
    OUT DX, AL
    INC DX
    XOR AL, AL
    OUT DX, AL ; Force registers into old mode
    IN AL, DX  ; But after this read, they're in new mode again [not 8800BR]
    RET

unpNVIDIA:
  CMP [chipset], NVIDIA
  JNE unpIntel
    mov dx, [CRTC]
    mov ax, 571Fh ; Idx 1Fh: 57h
    out dx, ax
    ret

unpIntel:
  cmp [chipset], Intel
  jne unpCirrus
    mov dx, [CRTC]
    mov al, 80h ; [CR80] I/O Control
    out dx, al
    inc dx
    in al, dx
    or al, 11b  ; Enable Attribute/CRT Controler Extensions
    out dx, al
    ret

unpCirrus:
  cmp [chipset], Cirrus
  jne unpUMC
    mov dx, 3C4h
    mov ax, 1206h ; Value, RegIdx
    out dx, ax
    ret

unpUMC:
  cmp [chipset], UMC
  jne unpParadise
    mov dx, 3BFh
    mov al, 0ACh
    out dx, al
    ret

unpParadise:
  cmp [chipset], Paradise
  jne unpTseng
    mov dx, 3CEh
    mov ax, 170Fh
    mov bl, 5
    call modinx
    mov dx, [CRTC]
    mov ax, 8F29h
    mov bl, 85h
    call modinx
    ret

unpTseng:
  cmp [chipset], Tseng
  jne unpEnd
    mov al, 3
    mov dx, 3BFh
    out dx, al
    mov al, 0A0h
    mov dx, [CRTC]
    add dx, 4
    out dx, al
    ret

unpEND:
  ret

unprotect ENDP

;****************************************************************************;

getCRTC PROC NEAR ; Determines the base CRTC address

;****************************************************************************;

  MOV [CRTC], 3D4h
  MOV DX, 3CCh          ; Miscellaneous Output
  IN AL, DX
  AND AL, 00000001b
  JNZ COLOR
    MOV [CRTC], 3B4h

COLOR:
    RET

getCRTC ENDP

;****************************************************************************;

setCRTC PROC NEAR               ; IN: AH=index, AL=value
                                ; Changed: DX=[CRTC], AL<=>AH

;****************************************************************************;

  MOV DX, [CRTC]
  XCHG AL, AH
  OUT DX, AL
  INC DX
  XCHG AL,AH
  CALL OutCRTC
  XCHG AL,AH
  DEC DX
  RET

setCRTC ENDP

;****************************************************************************;

readCRTC PROC NEAR              ; IN : AL=index
                                ; OUT: AL=value

;****************************************************************************;

  MOV DX, [CRTC]
  OUT DX, AL
  INC DX
  IN AL, DX
  RET

readCRTC ENDP

;****************************************************************************;

setH_Blank PROC NEAR ; Set horizontal blank

;****************************************************************************;

  MOV AH, [ht]
  MOV CL, BL
  MOV DL, AH
  SUB DL, [hbsz]
  ADD BL, [hbsz]
  JC OVRFLOW
    CMP BL, AH
    JB OVER ; Blank

OVRFLOW:
    SUB BL, AH
    CMP AH, 200
    JB OVER
      CMP CL, DL
      JB OVER
        MOV BL, AH
        CMP CL, 193
        JB OVER
          SUB CL, 193
          MOV BL, CL
OVER:
  ADD BH, [hrsz]
  CMP BH, AH
  JB OVER3 ; Retrace
    SUB BH, AH

OVER3:
  MOV CX, BX
  MOV AL, 03h
  CALL readCRTC     ; End Horizontal Blank
  AND CL, 00011111b
  AND AL, 11100000b
  OR AL, CL
  CALL OutCRTC
  MOV CL, BL
  AND CL, 00100000b
  SHL CL, 1
  SHL CL, 1
  MOV AL, 05h
  CALL readCRTC     ; End Horizontal Retrace
  AND AL, 01100000b
  OR AL, CL
  AND CH, 00011111b
  OR AL, CH
  CALL OutCRTC

  cmp [chipset], s3
  jne SHBExit
    mov al, 5Dh
    call readCRTC
    and al, 11000000b ; was 10000000b
    call outCRTC

SHBExit:
  RET

setH_Blank ENDP

;****************************************************************************;

text_mode PROC NEAR ; Tests to see if we're in text or graphics mode

;****************************************************************************;

  MOV DX, 3CEh
  MOV AL, 06h        ; Miscellaneous
  OUT DX, AL
  INC DX
  IN AL, DX
  TEST AL, 00000001b ; Text/Graphics Mode
  RET

text_mode ENDP

;****************************************************************************;

HSync PROC NEAR ; Configures the horizontal timings

;****************************************************************************;

  MOV AL, 5
  MUL AH
  LEA SI, HSetup
  ADD SI, AX
  MOV AL, [SI+4]
  SUB AL, 5
  MOV [ht], AL
  MOV CH, [htlim]
  ADD [ht], CH
  XOR AH, AH    ; Horizontal Total
  CALL setCRTC
  cmp [chipset], s3
  jne Cont1
    mov al, ah
    sub al, 5
    mov ah, 3Bh
    call setCRTC

Cont1:
  XOR CH,CH
  CALL text_mode
  JNZ GRAPH
    MOV CH, 1

GRAPH:
  MOV AL, [SI+1]
  MOV BH, AL
  SUB AL, [shiftX]
  AND AL, AL
  JZ OOPS
    CMP AL, [ht]
    JB SET_SHR

OOPS:
  MOV AL, BH
  MOV [shiftX], 0

SET_SHR:
  ADD AL, CH
  MOV BH, AL
  MOV AH, 04h   ; Start Horizontal Retrace
  CALL setCRTC
  MOV AL, 01h
  CALL readCRTC ; Horizontal Display End
  AND AL, AL
  JZ SHB
    ADD AL, 4
    CMP BH, AL
    JA SHB
      MOV AL, BH
      SUB AL, 4    ; in case of 800 pixel wide modes will make room for
      CALL OutCRTC ; retrace. 4 chars=~2.831us (PAL)

SHB:
  MOV AL, [SI]
  SUB AL, [shiftX]
  CMP AL, [ht]
  JB SET_SHB
    MOV [shiftX], 0
    JMP GRAPH

SET_SHB:
  MOV BL, AL
  MOV AH, 02h    ; Start Horizontal Blanking
  CALL setCRTC
  MOV AX, [SI+2]
  MOV [hrsz], AL
  MOV [hbsz], AH
  CALL setH_Blank
  RET

HSync ENDP

;****************************************************************************;

AlternateClockBy2 PROC NEAR ; Use proprietary Clock/2 instead of standard one
                            ; when using certain chipsets
                            ; Changes : BX

;****************************************************************************;

  MOV BX, 0109h ; 14.161 Mhz
  ;cmp [fullFrame], 1
  ;jne Oak7Mhz
  ;  mov bx, 0101h ; 28.322 Mhz
  ;  ret ; No need to divide the clock by 2

Oak7Mhz:
  cmp [chipset], oak
  jne _trident7Mhz
    cmp [_model], oak037
    jne unable
      jmp capable

_trident7Mhz:
  cmp [chipset], trident
  je capable

  cmp [chipset], realtek
  jne _s37Mhz
    cmp [_model], rtek3103
    je unable
      jmp capable

_s37Mhz:
  cmp [chipset], s3
  jne _intel7Mhz
    cmp [_model], Trio3D
    je capable
      cmp [_model], Trio64
      je capable
        cmp [_model], Trio32
        je capable
          cmp [_model], ViRGE
          je capable
            ret
            ;cmp [_model], Vision964P
            ;ja unable
            ;  cmp [_model], Vision864
            ;  jb unable

_intel7Mhz:
  cmp [chipset], Intel
  jne _cirrus7Mhz
    jmp unable ; for now. It *can* do down to 6Mhz.

_cirrus7Mhz:
  cmp [chipset], Cirrus
  jne _umc7Mhz
    jmp capable

_umc7Mhz:
  cmp [chipset], UMC
  jne _wd7Mhz
    jmp capable

_wd7Mhz:
  cmp [chipset], Paradise
  jne _Tseng7Mhz
    jmp unable

_Tseng7Mhz:
  cmp [chipset], Tseng
  jne unable
    jmp capable

capable:
  mov bx, 0111h ; 14.161Mhz, Clock/2=0

unable:
  ret

AlternateClockBy2 ENDP
;****************************************************************************;

Is7MhzCapable PROC NEAR ; Inquires over the possibility if this chipset
                        ; being configured for a 7Mhz dot clock
                        ; IN  : AH
                        ; OUT : AH+0 (unable), +1 (capable)
                        ; Changes : AH, BX

;****************************************************************************;

  call AlternateClockBy2
  cmp bx, 0101h
  jne not28Mhz
    mov bx, 0109h ; Field mode: use standard 14 Mhz instead of 7Mhz.
    call HSync
    ret

not28Mhz:
  cmp bx, 0109h
  je notCapable
    inc ah
    call HSync
    mov bx, 0119h ; 7.0805mhz
    ret

notCapable:
  call HSync
  MOV BX, 0009h ; 12.587 Mhz
  ret

Is7MhzCapable ENDP
;****************************************************************************;

H_Setup PROC NEAR ; Sets up the horizontal portion of the mode, and the clock
                  ; called just once, candidate for insertion (macro?) (MANTY)

;****************************************************************************;

  ; BH :0=25.175Mhz, 1=28.322Mhz
  ; BLH:1=Clock/2 (7Mhz)
  ; BLL:Bit 0:0=9 bits/char, 1=8 bits/char
  ;     Bit 3:0=Clock/1 ,1=Clock/2

  MOV AL, 01h   ; Horizontal Display End
  CALL readCRTC
  INC AL
  MOV [hde], AL
  xor ah, ah
  CMP AL, 40  ; 320 pixels
  JNE _50COLS
    call Is7MhzCapable
    jmp SetClk

_50COLS:
  mov ah, 2
  CMP AL, 50  ; 400 pixels
  JNE _64COLS
    call Is7MhzCapable
    jmp SetClk

_64COLS:
  mov ah, 4
  CMP AL, 64  ; 512 pixels
  JNE _80COLS
    CALL HSync
    call AlternateClockBy2
    jmp SetClk

_80COLS:
  INC AH
  CMP AL, 80  ; 640 pixels
  JNE _90COLS
    CALL HSync
    MOV BX, 0109h ; 14.161 Mhz
    CALL text_mode
    JNZ FIX37
      JMP SetClk
    FIX37:
      call AlternateClockBy2
      jmp SetClk

_90COLS:
  INC AH
  CMP AL, 90  ; 720 pixels
  JNE _96COLS
    CALL HSync
    call AlternateClockBy2
    jmp SetClk

_96COLS:
  INC AH
  CMP AL, 96  ; 768 pixels
  JNE _100COLS
    push ax
    call GetVSize
    pop ax
    mov al, 100
    cmp cx, 768
    jna _100Cols
      CALL HSync
      MOV BX, 0101h ; 28.322 Mhz
      jmp SetClk

_100COLS:
  INC AH
  CMP AL, 100 ; 800 pixels
  JNE _120COLS
    CALL HSync
    call AlternateClockBy2
    jmp SetClk

_120COLS:
  INC AH
  CMP AL, 120 ; 960 pixels
  JNE _128COLS
    CALL HSync
    MOV BX, 0101h ; 28.322 Mhz
    JMP SETCLK

_128COLS:
  INC AH
  CMP AL, 128 ; 1024 pixels
  JNE _132COLS
    CALL HSync
    MOV BX, 0101h ; 28.322 Mhz
    JMP SETCLK

_132COLS:
  INC AH
  CMP AL, 132 ; 132 columns/1056 pixels
  JNE _144COLS
    CALL HSync
    MOV DX, [CRTC]
    ADD DX, 6
    IN AL, DX ; Dummy read: flip-flop reset
    MOV DX, 3C0h ; Attribute Controller
    MOV AL, 30h  ; Mode Control
    OUT DX, AL
    INC DX
    IN AL, DX
    AND AL, 11111011b
    OR AL, 00000100b ; ELB set
    DEC DX
    OUT DX, AL
    XOR BX, BX ; 25.175 Mhz
    JMP SETCLK

_144COLS:
  INC AH
  CMP AL, 144 ; 1152 pixels
  JNE _160COLS
    CALL HSync
    MOV BX, 0101h ; 28.322 Mhz
    JMP SETCLK

_160COLS:
  INC AH
  CMP AL,160 ; 1280 pixels
  JNE _200COLS
    CALL HSync
    MOV BX,0101h ; 28.322 Mhz
    JMP SETCLK

_200COLS:
  INC AH
  CMP AL,200 ; 1600 pixels
  JE FIX01
    RET ; sorry, this mode isn't supported yet
  FIX01: ; *
    CALL HSync
    MOV BX,0101h ; 28.322 Mhz

SETCLK: ; Tries to reset the clock to a known state first
  MOV DX, 3C4h
  XOR AX, AX
  OUT DX, AX ; Reset

  CMP [chipset],oak
  JNE TRIDENTVGA
    MOV DX,3DEh
    MOV AL,0Dh       ; Oak Miscellaneous
    OUT DX,AL
    INC DX
    IN AL,DX
    AND AL,11011111b ; Clock Select Bit 2
    CALL OutExt1
    JMP CLOCK

TRIDENTVGA:
  CMP [chipset],trident
  JE Fix18
    jmp S3Clk ; *

  Fix18:
    MOV DX,[CRTC]
    MOV AL,38h
    OUT DX,AL
    INC DX
    IN AL,DX
    AND AL,1100b
    JZ _8Bit ; at least 15/16 bits color mode
      MOV BH,2 ; External Clock Select
      MOV AH,AL
      MOV DX,3C4h
      MOV AL,0Eh
      OUT DX,AL
      INC DX
      IN AL,DX
      OR AL,10000000b
      OUT DX,AL
      TEST AH,1000b
      JNZ CLK3
        MOV AX, 0000101011010011b ; 56.649Mhz
        JMP SETTRIDCLK
      CLK3:
      TEST AH,100b
      JNZ CLK4
        CMP BH,1 ; 24 bits
        JNB Fix03
          jmp Clock ; Should be 25Mhz

        Fix03:
          MOV AX,0000011101010111b ; 85.013Mhz
          JMP SETTRIDCLK

      CLK4:      ; 32 bits
        MOV AX,0000010011001111b ; 113.242Mhz

  SETTRIDCLK:
    test bl, 1000b
    jz StoreClk
        or ax, 0001000000000000b
        and bl, 11110111b

  StoreClk:
    MOV DX,43C8h
    out dx, al
    mov al, ah
    inc dx
    out dx, al

  _8BIT:
    MOV DX,3C4h
    MOV AL,0Dh       ; New Mode Control 2
    OUT DX,AL
    INC DX
    IN AL,DX
    cmp [_model], tri8800BR
    JNE GENERICTVGA
      AND AL,11111000b ; Emulation mode=VGA
      CALL OutSeq
      JMP CLOCK
    GENERICTVGA:
    AND AL,10111000b ; Clock Select Bit 3-2[7,0], Divide Pixel Clock by 1[2-1]
    CALL OutSeq
    MOV DX, 3C4h
    MOV AL, 0Bh
    OUT DX, AL
    INC DX
    XOR AL, AL
    call OutSeq ; Force registers into old mode
    mov dx, 3C4h
    mov al, 0Eh
    out dx, al
    inc dx
    in al, dx
    and al, 11101111b ; Clock Select bit 3=0
    out dx, al
    dec dx
    mov al, 0Bh
    out dx, al
    inc dx
    in al, dx ; Force registers into new mode again
    JMP CLOCK

S3Clk:
  cmp [chipset], s3
  jne UMCClk
    mov al, 67h
    call readCRTC
    and al, 11110000b
    cmp [_model], Trio32
    je TrioClk
      cmp [_model], Trio64
      je TrioClk
        cmp [_model], Trio3D
        je TrioClk
          cmp [_model], ViRGE
          je TrioClk
            cmp [_model], Vision964P
            ja S3ClkExit
              cmp [_model], Vision864
              jb S3ClkExit
                cmp al, 1010000b
                ja S3ClkExit
                  cmp al, 110000b
                  jb S3ClkExit
                    mov bx, 0109h ; 14.161Mhz (Clock/2=1)
                    jmp Clock

  TrioClk:
    cmp al,   110000b
    je halveS3Clk
      cmp al, 1010000b
      jne S3ClkExit

    halveS3Clk:
      cmp bx, 0119h ; 7.08Mhz
      je S3ClkExit
        cmp bx, 0101h ; 28.322Mhz
        jne Is25Mhz
          mov bx, 0111h ; 14.161Mhz (Clock/2=0)
          jmp Clock

      Is25Mhz:
        and bx, bx
        jne IsLess
          mov bx, 0011h ; 12.587Mhz (Clock/2=0)
          jmp Clock

      IsLess:
        cmp bx, 0119h ; 7.08Mhz
        jne Fix19
          jmp Clock

        Fix19:
          cmp bx, 0009h ; 12.175Mhz
          jne Is14
            mov bx, 0019h ; 6.29Mhz
            jmp Clock

        Is14:
          mov bx, 0119h

  S3ClkExit:
    jmp Clock

UMCClk:
  cmp [chipset], UMC
  jne WDClock
    mov al, 07h
    mov dx, 3C4h
    out dx, al
    inc dx
    in al, dx
    and al, 11111110b
    out dx, al
    dec dx
    mov al, 09h
    out dx, al
    inc dx
    in al, dx
    and al, 01111111b
    out dx, al
    jmp Clock

WDClock:
  cmp [chipset], Paradise
  jne TsengClock
    ;mov dx, 3C4h
    ;mov al, 12h ; PR32 Miscellaneous Control #4
    ;out dx, al
    ;inc dx
    ;in al, dx
    ;and al, 11111011b
    ;out dx, al
    mov al, 2Eh ; PR15 Miscellaneous Control #1
    call readCRTC
    and al, 11101111b ; 0=VCLK <> MCLK
    or al, 1b         ; 1=Enable borders
    call outCRTC
    mov dx, 3CEh
    mov al, 0Ch ; PR2 Video Configuration
    out dx, al
    inc dx
    in al, dx
    and al, 11111101b
    cmp [_model], WD90C30
    jb SetPR2
      or al, 10b

  SetPR2:
    out dx, al
    jmp Clock

TsengClock:
  cmp [chipset], Tseng
  jne Clock
    cmp [_model], ET4000
    jne Clock
      mov al, 07h ; TS Auxiliary Mode
      mov dx, 3C4h
      out dx, al
      inc dx
      in al, dx
      or al, 01000000b
      and al,11111110b
      out dx, al
      mov al, 31h ; General Purpose
      call readCRTC
      and al, 10011111b ; Clock Select bits 3-4
      call outCRTC
      mov al, 34h ; 6845 Compatibility Control Register
      call readCRTC
      and al, 01111100b
      call outCRTC
      jmp Clock

CLOCK:
    MOV DX, 3CCh ; Miscellaneous Output
    IN AL, DX
    MOV [genOrg],AL
    SHL BH, 1
    SHL BH, 1
    OR AL, 11000000b ; Christian K”nig
    AND AL, [polarity]
    OR AL, BH
    MOV DX, 3C2h
    OUT DX, AL
    MOV [genNew],AL
    MOV DX, 3C4h
    XOR AX, AX
    OUT DX, AX  ; Reset
    MOV AL, 01h ; Clocking Mode
    OUT DX, AL
    INC DX
    IN AL, DX
    AND AL, 11110110b
    MOV AH, BL
    AND AH, 00001111b
    OR AL, AH
    CALL OutSeq
    DEC DX
    MOV AX, 0300h
    OUT DX, AX
    SHR BL, 1
    SHR BL, 1
    SHR BL, 1
    SHR BL, 1
    AND BL, BL
    jnz Fix12
      jmp hstEXIT ; 7.08 Mhz setups follow. Also works for 14.161Mhz that can't
                  ; be set using Clock/2 bit on the Clocking Mode register of
                  ; the Sequencer (Trident, Realtek, S3, ...)
    Fix12:
      CMP [chipset], oak
      JNE TRIDENT7MHZ
        mov al, [genNew]
        and al, 11110011b
        mov [genNew], al
        mov dx, 3C2h
        out dx, al
        MOV DX, 3DEh
        MOV AL, 0Dh      ; Oak Miscellaneous
        OUT DX, AL
        INC DX
        IN AL, DX
        OR AL, 00100000b ; Clock Select Bit 2
        CALL OutExt1
        RET

    TRIDENT7MHZ:
      CMP [chipset], trident
      JNE REALTEK7MHZ
        cmp [_model], TRI9000i
        jae DivideBy2
          mov dx, 3CEh
          mov al, 0Fh
          out dx, al
          inc dx
          in al, dx
          test al, 1000b
          jz DivideBy2
            ret

        DivideBy2:
          MOV DX, 3C4h
          MOV AL, 0Dh ; New Mode Control 2
          OUT DX, AL
          INC DX
          IN AL, DX
          OR AL, 00000010b ; Divide pixel clock by 2
          CALL OutSeq
          RET

    REALTEK7MHZ:
      CMP [chipset], realtek
      JNE S37MHZ
        MOV DX, [CRTC]
        MOV AL, 1Ah
        OUT DX, AL
        INC DX
        IN AL, DX
        OR AL, 10h
        CALL outCRTC
        MOV DX, 3CEh
        MOV AL, 0Bh
        OUT DX, AL
        INC DX
        IN AL, DX
        OR AL, 1 ; Divide pixel clock by 2
        CALL OutExt1
        RET

    S37MHZ:
      CMP [chipset], s3
      jne Cirrus7Mhz
        cmp [_model], Vision864
        jb NotVision
          cmp [_model], Vision964P
          ja NotVision
            ret ; On the 864/964(?) its possible to set a 7/14Mhz clock,
                ; but there are problems. Until I know how to set the RAMDAC
                ; chip correctly, this is the only code there is...

      NotVision:
        mov dx, 3C4h
        mov al, 15h
        out dx, al
        inc dx
        in al, dx
        or al, 10000b
        out dx, al
        ret

    Cirrus7Mhz:
      cmp [chipset], cirrus
      jne UMC7Mhz
        mov dx, 3C4h
        mov al, 07h ; Extended Sequencer Mode
        out dx, al
        inc dx
        in al, dx
        xor bl, bl
        and al, 110b
        cmp al, 010b   ; 16bit/pixel
        jne Fix17
          ret  ; * Clock/2 already

        Fix17:
          cmp al, 100b ; 24bit/pixel
          je cl24Bit
            cmp al, 1000b ; 32bit/pixel
            je cl32Bit
              mov bl, [genNew]
              shr bl, 1
              shr bl, 1
              and bl, 11b
              mov al, 0Bh ; VCLK 0 Numerator
              add al, bl
              mov bh, al
              dec dx ; 3C4h
              out dx, al
              inc dx
              in al, dx
              shr al, 1
              mov ah, al
              dec dx
              mov al, bh
              add al, 10h
              out dx, al
              inc dx
              in al, dx
              mov bl, al
              dec dx
              mov al, 0Eh ; VCLK 3 Numerator
              out dx, al
              inc dx
              mov al, ah
              call outSeq
              dec dx
              mov al, 1Eh
              out dx, al
              inc dx
              mov al, bl
              call outSeq
              jmp clExtClk

          cl24Bit:
            mov dx, 3C4h
            mov ax, 0E71h
            out dx, ax
            mov ax, 1E27h
            out dx, ax
            jmp clExtClk

          cl32Bit:
            mov dx, 3C4h
            mov ax, 0E5Fh
            out dx, ax
            mov ax, 1E19h
            out dx, ax

          clExtClk:
            mov al, [genNew]
            or al, 1100b
            mov [genNew], al
            mov dx, 3C2h
            out dx, al
            ret

    UMC7Mhz:
      cmp [chipset], UMC
      jne Tseng7Mhz
        mov dx, 3C4h
        mov al, 09h
        out dx, al
        inc dx
        in al, dx
        or al, 10000000b
        call outSeq
        ret

    Tseng7Mhz:
      cmp [chipset], Tseng
      jne hstExit
        mov dx, 3C4h
        mov al, 07h
        out dx, al
        inc dx
        in al, dx
        cmp [_model], ET4000
        je _4K7Mhz
          or al, 01000000b
          call outSeq
          ret

      _4K7Mhz:
        and al, 10111111b
        or al, 00000001b
        call outSeq
        ret

hstExit:
  RET

H_Setup ENDP

;****************************************************************************;

GetVSize PROC NEAR ; Returns the number of horizontal lines across the screen
                   ; OUT : CX=number of lines

;****************************************************************************;

  MOV AL, 12h   ; Vertical Display End
  CALL readCRTC
  MOV CL, AL
  MOV AL, 07h   ; Overflow
  CALL readCRTC
  SHR AL, 1
  MOV CH, AL
  AND CH, 00000001b
  SHR AL, 1
  SHR AL, 1
  SHR AL, 1
  SHR AL, 1
  AND AL, 00000010b
  OR CH, AL
  INC CX
  MOV AL, 17h   ; Mode Control
  CALL readCRTC
  MOV AH, AL
  AND AH, 00000100b   ; Horizontal Retrace Select
  JZ HRS
    SHL CX, 1         ; double number of lines
    AND AL, 11111011b ; normal
    CALL OutCRTC

HRS:
  ret

GetVSize ENDP

;****************************************************************************;

DeInterlace PROC NEAR ; Turns off interlace in case of buggy BIOSes...

;****************************************************************************;

  cmp [chipset], Tseng
  jne Uninterlaced
    mov al, 35h ; Overflow High
    cmp [_model], ET4000
    je niET4000
      mov al, 25h ; Overflow High

    niET4000:
      call readCRTC
      and al, 01111111b
      call outCRTC

Uninterlaced:
  ret

DeInterlace ENDP

;****************************************************************************;

V_Setup PROC NEAR ; called just once, candidate for insertion (macro?) (MANTY)

;****************************************************************************;

  call GetVSize
  MOV DI, CX
  MOV AL, 13h        ; Offset
  CALL readCRTC
  MOV CL, AL
  XOR CH, CH
  CMP [chipset], trident
  JNE OfsS3
    MOV AL,29h
    CALL readCRTC
    AND AL,110000b
    SHR AL,1
    SHR AL,1
    SHR AL,1
    SHR AL,1
    MOV CH,AL
    JMP ChkTxt

OfsS3:
  cmp [chipset], s3
  jne OfsIntel
    mov al, 51h     ; Extended System Control 2
    call readCRTC
    and al, 110000b
    shr al, 1
    shr al, 1
    shr al, 1
    shr al, 1
    mov ch, al
    and al, al
    jnz ChkTxt
      mov al, 43h   ; Extended Mode
      call readCRTC
      and al, 100b
      shr al, 1
      shr al, 1
      mov ch, al
      jmp ChkTxt

OfsIntel:
  cmp [chipset], Intel
  jne ChkTxt
    mov al, 41h ; [CR41] Extended Offset Register
    call readCRTC
    mov ch, al

CHKTXT:
  CALL text_mode
  JNZ vstGRAPH
    mov dx, [CRTC]
    add dx, 6
    in al, dx
    mov dx, 3C0h
    mov al, 33h ; Horizontal Pixel Panning + Palette Access
    out dx, al
    xor ax, ax
    out dx, al
    XOR BX,BX
    MOV ES,BX
    MOV AL,BYTE PTR ES:[484h]
    INC AL
    MOV BL, 8
    MUL BL
    MOV DI, AX
    MOV AL,01000111b
    MOV AH, 09h      ; Maximum Scan Line
    CALL setCRTC
    CMP DI, 270
    JNA FIX02
      mov di, 270

  FIX02:
    call DeInterlace
    JMP LINE_SETUP

vstGRAPH:
  MOV AL, 09h        ; Maximum Scan Line
  CALL readCRTC
  AND AL, 11011111b
  CALL OutCRTC
  TEST AL, 10000000b ; 200 to 400
  JZ MSL
    AND AL, 01111111b
    JMP SETMSL

MSL:
  TEST AL, 00000001b ; Maximum Scan Line
  JZ HALVE
    AND AL,11111110b

SETMSL:
  CALL OutCRTC ; Maximum Scan Line
  SHR CX, 1
  mov ax, di
  shr ax, 1
  cmp ax, max_lines
  ja halve
    call DeInterlace
    jmp Squeeze

HALVE:
  CMP [chipset], ibm
  JNE FIX04
    JMP SQUEEZE ; *
  FIX04:
  mov al, [ht]
  SHR AL, 1 ; Interlace End = Horizontal Total/2
  SUB AL, [shiftX]
  JNC SH2
    MOV BH, [ht]
    ADD AL, BH
    CMP AL, BH
    JNA SH2
      SUB AL, BH

SH2:
  MOV BH, AL
  CMP [interlace],1
  JE FIX36
    JMP SQUEEZE ; *

  FIX36:
  CMP [chipset], oak ; Oak Technology Inc.
  JNE _S3
    CMP [_model], oak037
    JNE FIX31
      JMP SQUEEZE ; *
    FIX31:
      MOV DX, 3DEh
      MOV AL, 14h ; Overflow
      OUT DX, AL
      INC DX
      IN AL, DX
      TEST AL, 10000000b
      JZ FIX34
        JMP SQUEEZE ; *
      FIX34:
        SHR DI, 1
        OR AL, 10000000b ; Interlace:On
        CALL OutExt1
        DEC DX
        MOV AL, 15H ; HSYNC/2
        OUT DX, AL
        INC DX
        MOV AL, BH
        CALL OutExt1
        JMP SQUEEZE

_S3:
  CMP [chipset], s3 ; S3, Inc.
  JNE _CIRRUS
    MOV AL, 42h ; CR42 Mode Control
    CALL readCRTC
    TEST AL, 00100000b
    JZ FIX35
     JMP SQUEEZE ; *
    FIX35:
      SHR DI, 1
      OR AL, 00100000b ; Interlace mode
      CALL OutCRTC
      MOV AH, 3Ch ; CR3C Interlaced Mode Start/End
      MOV AL, BH
      CALL setCRTC
      JMP SQUEEZE

_CIRRUS:
  CMP [chipset], cirrus ; Cirrus Logic
  JNE _TSENG
    MOV AL, 1Ah ; Miscellaneous Control
    CALL readCRTC
    TEST AL, 00000001b
    jz Fix13
      jmp SQUEEZE ; *
    Fix13:
      SHR DI, 1
      OR AL, 00000001b ; Interlace mode
      CALL OutCRTC
      MOV AH, 19h ; Interlace End
      MOV AL, BH
      CALL setCRTC
      JMP SQUEEZE

_Tseng:
  cmp [chipset], Tseng
  jne _Trident2
    mov al, 25h ; Overflow High
    cmp [_model], ET3000
    je iET3000
      mov al, 35h ; Overflow High
      mov [fullFrame], 1 ; Frame mode in interlaced mode

    iET3000:
      call readCRTC
      test al, 10000000b
      jz Fix16
        shr di, 1
        and al,11110000b
        call outCRTC
        jmp Squeeze ; *

      Fix16:
        shr di, 1
        or al, 10000000b
        and al,11110000b
        call outCRTC
        jmp Squeeze

_TRIDENT2:
  CMP [chipset], trident ; Trident VGA
  JNE _NVIDIA
    MOV AL, 1Eh ; Module Testing
    CALL readCRTC
    TEST AL, 00000100b
    JZ Fix11
      jmp SQUEEZE ; *
    Fix11:
      SHL CX,1
      SHR DI, 1
      OR AL, 00000100b ; Interlace mode
      CALL OutCRTC
      JMP SQUEEZE

_NVIDIA:
  CMP [chipset], NVIDIA
  JNE _REALTEK
    mov [fullFrame], 1 ; Frame mode in interlaced mode?
    MOV AL, 33h ;
    CALL readCRTC
    TEST AL,10000000b
    jz Fix14
      jmp Squeeze ; *
    Fix14:
      OR AL,10000000b ; Interlace mode
      CALL OutCRTC
      JMP SQUEEZE

_REALTEK:
  CMP [chipset], realtek; Realtek
  JNE _ATI
    MOV AL, 19h ;
    CALL readCRTC
    TEST AL,00000001b
    jz Fix15
      jmp Squeeze ; *
    Fix15:
      SHL CX,1
      SHR DI,1
      OR AL,00000001b ; Interlace mode
      CALL OutCRTC
      JMP SQUEEZE

_ATI:
  CMP [chipset], ATI
  JNE _Intel
    mov al, 0BEh ; ATI Register E
    mov dx, 1CEh
    in al, dx
    TEST AL,00000010b
    JNZ SQUEEZE
      SHL CX,1
      SHR DI,1
      OR AL,00000010b ; Interlace mode
      out dx, al
      JMP SQUEEZE

_Intel:
  cmp [chipset], Intel
  jne _UMC
    mov [fullFrame], 1 ; Frame mode in interlaced mode
    mov al, 70h ; [CR70] Interlace Control Register
    call readCRTC
    test al, 10000000b
    jnz SQUEEZE
      shl cx, 1
      shr di, 1
      or al, 10000000b ; Interlace Enable
      or al, bh        ; CRT Half-Line Value
      call outCRTC
      jmp SQUEEZE

_UMC:
  cmp [chipset], UMC
  jne _Paradise
    mov al, 2Fh
    call readCRTC
    test al, 1b
    jnz SQUEEZE
      shl cx, 1
      shr di, 1
      or al, 1 ; Interlaced Mode
      call outCRTC
      jmp SQUEEZE

_Paradise:
  cmp [chipset], Paradise
  jne Squeeze
    mov al, 2Dh   ; PR14 Interlace H/2 End
    call readCRTC
    test al, 100000b
    jnz Squeeze
      shr di, 1
      or al, 100000b ; Interlaced Mode
      dec bh
      or al, bh
      call outCRTC
      inc bh
      mov ah, 2Ch ; PR13 Interlace H/2 Start
      mov al, bh
      call setCRTC
      jmp Squeeze

Squeeze:
  CMP DI, max_lines
  JNA LINE_SETUP
    SHR DI, 1
    SHL CX, 1

LINE_SETUP:
  LEA SI,VSetup

FINDLINES:
  MOV AX,[SI]
  CMP DI,AX
  JE VSYNC
    add si, 4
    CMP AX,max_lines
    JNE FINDLINES
      RET

VSYNC:
  INC SI
  INC SI
  CMP DI, [SI]
  JNA _OFFSET
    MOV DI, [SI]
    DEC DI

_OFFSET:
  CMP [chipset], s3
  JNE OFS_CIRRUS
    mov al, 51h       ; Extended System Control 2
    call readCRTC
    and al, 11001111b
    mov ah, ch
    shl ah, 1
    shl ah, 1
    shl ah, 1
    shl ah, 1
    or al, ah
    call outCRTC
    mov al, 43h       ; Extended Mode
    call readCRTC
    and al, 11111011b
    shr ah, 1
    shr ah, 1
    and ah, 100b
    or al, ah
    call outCRTC
    jmp ofs_std

OFS_CIRRUS:
  CMP [chipset], Cirrus
  JNE OFS_TRID
    MOV AL,1Bh
    CALL readCRTC
    AND CH,1
    SHL CH,1
    SHL CH,1
    SHL CH,1
    SHL CH,1
    OR AL,CH
    CALL OutCRTC
    JMP OFS_STD

OFS_TRID:
  CMP [chipset], trident
  JNE Intel_OFS
    mov dx, 3C4h
    MOV AL,0Eh ; New Mode Control 1
    OUT DX,AL
    INC DX
    IN AL,DX
    OR AL,10000000b ; Unlock
    CALL OutSeq
    MOV AL,29h
    CALL readCRTC
    AND AL,11001111b
    AND CH,11b
    SHL CH,1
    SHL CH,1
    SHL CH,1
    SHL CH,1
    OR AL,CH
    CALL OutCRTC
    MOV DX,3C4h
    MOV AL,0Eh ; New Mode Control 1
    OUT DX,AL
    INC DX
    IN AL,DX
    AND AL,01111111b ; Lock
    CALL OutSeq
    jmp OFS_STD

Intel_OFS:
  cmp [chipset], Intel
  jne Tseng_Ofs
    mov ah, 41h ; [CR41] Extended Offset Register
    mov al, ch
    call setCRTC
    jmp OFS_STD

Tseng_Ofs:
  cmp [chipset], Tseng
  jne Ofs_Std
    mov al, 3Fh
    call readCRTC
    and al, 01111111b
    and ch, ch ; Offset > 255 ?
    jz TOfs
      or al, 10000000b

  TOfs:
    call outCRTC
    jmp Ofs_Std

OFS_STD:
  MOV AH, 13h  ; Offset
  MOV AL, CL
  CALL setCRTC
  MOV CX, DI
  cmp [fullFrame], 1
  jne FieldBased1
    shl cx, 1

FieldBased1:
  DEC CX
  MOV AL, CL
  MOV AH, 12h  ; Vertical Display End
  CALL setCRTC
  MOV CL, CH
  and cl, 1b
  shl cl, 1
  and ch, 10b
  shl ch, 1
  shl ch, 1
  shl ch, 1
  shl ch, 1
  shl ch, 1
  or cl, ch
  MOV AX, [SI]
  SUB AX, [shiftY]
  mov bx, 3
  cmp [fullFrame], 1
  jne FieldBased2
    shl ax, 1
    mov bx, 6

FieldBased2:
  MOV DI, AX
  sub ax, bx
  mov bl, ah
  and ah, 1b
  SHL AH, 1
  SHL AH, 1
  SHL AH, 1
  OR CL, AH
  MOV AH, 15h  ; Start Vertical Blank
  CALL setCRTC
  mov al, 09h  ; Maximum Scan Line
  call readCRTC
  and bl, 10b
  shl bl, 1
  shl bl, 1
  shl bl, 1
  shl bl, 1
  or al, bl
  call OutCRTC
  MOV AX, DI
  mov bl, ah
  and bl, 10b
  shl bl, 1
  shl bl, 1
  shl bl, 1
  shl bl, 1
  shl bl, 1
  shl bl, 1
  or cl, bl
  and ah, 1b
  SHL AH, 1
  SHL AH, 1
  OR CL, AH
  MOV AH, 10h  ; Vertical Retrace Start
  CALL setCRTC
  MOV AL, 11h  ; Vertical Retrace End
  CALL readCRTC
  MOV BL, AL
  AND BL, 11110000b
  MOV AX, [SI]
  cmp [fullFrame], 1
  jne FieldBased3
    shl ax, 1
    add ax, 4

FieldBased3:
  add ax, 4
  SUB AX, [one4even] ; Subtract one or zero from this value. Depending on how
  SUB AX, [shiftY]   ; the board works, we HAVE to get an even number of
  MOV DI, AX         ; retrace lines
  AND AL, 01001111b  ; 5 refresh cycles
  OR AL, BL
  CALL OutCRTC
  CMP [chipset], s3
  JNE RFRSH_TRID
    MOV AL, 3Ah       ; Miscellaneous 1
    CALL readCRTC
    AND AL, 11111011b ; Enable Alternate Refresh Count Control
    CALL OutCRTC
    JMP CONT

RFRSH_TRID:
  AND AL,10111111b ; 3 refresh cycles
  CALL OutCRTC

CONT:
  mov ax, 18  ; 25 line blank:PAL
  CMP [standard], NTSC
  JNE END_BLANK
    SUB AX,4 ; 21 line blank:NTSC

END_BLANK:
  cmp [fullFrame], 1
  jne FieldBased4
    shl ax, 1

FieldBased4:
  add ax, di
  MOV DI,[max_total]
  cmp [fullFrame], 1
  jne FieldBased5
    shl di, 1
    dec di    ; 313->625, 263->525

FieldBased5:
  SUB DI,2
  CMP DI,AX
  JA BLANK
    SUB AX,DI

BLANK:
  MOV AH,16h  ; End Vertical Blank
  CALL setCRTC
  MOV AX,DI
  mov bl, ah
  and ah, 1b
  OR CL,AH
  and bl, 10b
  shl bl, 1
  shl bl, 1
  shl bl, 1
  shl bl, 1
  or cl, bl
  MOV AH,06h  ; Vertical Total
  CALL setCRTC
  MOV AL,CL
  OR AL,00010000b
  MOV AH,07h  ; Overflow
  CALL setCRTC
  mov [fullFrame], 0
  ret

V_Setup ENDP

;****************************************************************************;

TXTSetup PROC NEAR ; Sets up a text mode for TV output
                   ; called just once, candidate for insertion (macro?) (MANTY)

;****************************************************************************;

  CALL text_mode
  JNZ txtEXIT
    XOR BX,BX
    MOV ES,BX
    MOV AL,BYTE PTR ES:[485h]
    MOV [charHeight],AL
    MOV AH,03
    PUSHF
    CALL DWORD PTR [oldINT10h]
    MOV [charDef],CX
    MOV AX,1102h ; ROM 8x8, without Reset
    XOR BX,BX
    PUSHF
    CALL DWORD PTR [oldINT10h]
    MOV AH,01h   ; Set Cursor Size
    MOV CX,0706h
    PUSHF
    CALL DWORD PTR [oldINT10h]
    MOV BYTE PTR ES:[485h],08h

txtEXIT:
  RET

TXTSetup ENDP

;****************************************************************************;

VGAsetup PROC NEAR ; Main setup function

;****************************************************************************;

  MOV [seqIdx],0
  MOV [CRTIdx],0
  MOV [ext1Idx],0
  CMP [TV],1
  JNE vgaExit
    CALL getCRTC
    CALL TXTSetup
    CALL unprotect
    CALL H_Setup
    CALL V_Setup

vgaExit:
  RET

VGAsetup ENDP

;****************************************************************************;

VideoISR PROC NEAR ; As the name implies, this is the main ISR for INT 10h

;****************************************************************************;

  PUSH AX
  PUSHF
  INC WORD PTR CS:[nestLevel]

  DB 9Ah         ; call original handler
oldINT10h LABEL DWORD
oldINT10h_OFS DW 0
oldINT10h_SEG DW 0

  STI
  DEC WORD PTR CS:[nestLevel]
  CMP WORD PTR CS:[nestLevel],0
  JA isrEXIT
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH DS
    PUSH ES

    PUSH CS
    POP DS
    MOV BX,SP
    MOV AX,SS:[BX+14]
    AND AH,AH
    JZ TVMODE
      CMP AX,4F02h ; VESA: Set Video Mode
      JE TVMODE
        CMP BYTE PTR [TV],1
        JNE isrOUT
          CMP AH,11H
          JNE isrOUT
            CALL V_Setup

  TVMODE:
    CALL VGAsetup

  isrOUT:
    POP ES
    POP DS
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX

isrEXIT:
  INC SP
  INC SP
  IRET

nestLevel DW 0
TV        DB 1

VideoISR ENDP

;****************************************************************************;

keybISR PROC NEAR ; Keyboard Interrupt Service Routine

;****************************************************************************;

; Need to change this whole routine, for now I'll protect the registers, but
; needs to be erased and written again! (MANTY)

  PUSHF

  DB 9Ah                ; call original handler
oldkeybISR LABEL DWORD
oldkeybISR_OFS DW 0
oldkeybISR_SEG DW 0

  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI
  PUSH DS
  PUSH ES
  PUSH CS
  POP DS
  MOV AH, 11h
  INT 16h
  JNZ FIX05
    JMP kbEND ; *
  FIX05:
    CLI
    XOR BX, BX
    MOV ES, BX
    MOV BL, ES:[417h]
    AND BL, 00000100b
    JNZ FIX06
      JMP kbEND     ; Ctrl is NOT pressed
    FIX06:
        CMP AX, 9B00h ; Alt+Left
        JE FIX25
          JMP RIGHT
        FIX25:
          MOV AH, 10h
          INT 16h
          MOV AL, 11h       ; Vertical Retrace End
          CALL readCRTC
          AND AL, 01111111b ; CRTC #0..#7 Protection:off
          CALL OutCRTC
          MOV AH, [ht]      ; Horizontal Total
          MOV AL, 04h
          CALL readCRTC     ; Start Horizontal Retrace
          INC AL
          CMP AL, AH
          JNE FIX07
            JMP kbEND ; *
          FIX07:
            DEC [shiftX]
            CALL OutCRTC
            MOV BH,AL
            SUB AL,5
            JC OVER0
              CMP AL,[hde]
              JNB OVER0
                MOV CX,AX
                MOV AH,01h
                CALL setCRTC
                MOV AX,CX
            OVER0:
            MOV AL,02h
            CALL readCRTC   ; Start Horizontal Blanking
            INC AL
            CMP AL,AH
            JNA R1
              XOR AL,AL
            R1:
            MOV BL,AL
            CALL OutCRTC
            CALL setH_Blank
            CMP [chipset], oak
            JNE CL1
              MOV DX,3DEh
              MOV AL,15h
              OUT DX,AL
              INC DX
              IN AL,DX
              INC AL
              CMP AL,AH    ; Horizontal Total
              JNA I1
                MOV AL,1
              I1:
              CALL OutExt1
              JMP kbEND

          CL1:
            CMP [chipset],cirrus
            JE FIX08
              JMP kbEND ; *
            FIX08:
              MOV AL,19h   ; Interlace End
              CALL readCRTC
              INC AL
              CMP AL,AH    ; Horizontal Total
              JNA I2
                XOR AL,AL
              I2:
              CALL OutCRTC
              JMP kbEND

      RIGHT:
        CMP AX, 9D00h ; Alt+Right
        JE FIX32
          JMP UP ; *
        FIX32:
          MOV AH, 10h
          INT 16h
          MOV AL, 11h       ; Vertical Retrace End
          CALL readCRTC
          AND AL, 01111111b ; CRTC #0..#7 Protection:off
          CALL OutCRTC
          MOV AL, 04h
          CALL readCRTC     ; Start Horizontal Retrace
          DEC AL
          JNZ FIX09
            JMP kbEND ; *
          FIX09:
            INC [shiftX]
            CALL OutCRTC
            MOV BH, AL
            MOV AL, 01h
            CALL readCRTC   ; Horizontal Display End
            AND AL,AL
            JZ OVER4
              ADD AL,4
              CMP BH,AL
              JA OVER4
                MOV AL,BH
                SUB AL,5
                CALL OutCRTC
            OVER4:
            MOV AH,[ht]    ; Horizontal Total
            MOV AL,02h
            CALL readCRTC   ; Start Horizontal Blanking
            DEC AL
            CMP AL,255
            JNE R2
              MOV AL,AH
            R2:
            MOV BL,AL
            CALL OutCRTC
            CALL setH_Blank
            CMP [chipset], oak
            JNE CL2
              MOV DX,3DEh
              MOV AL,15h
              OUT DX,AL
              INC DX
              IN AL,DX
              DEC AL
              JNZ I3
                MOV AL,AH  ; Horizontal Total
              I3:
              CALL OutExt1
              JMP kbEND
            CL2:
            CMP [chipset],cirrus
            JE FIX10
              JMP kbEND ; *
            FIX10:
              MOV AL,19h   ; Interlace End
              CALL readCRTC
              DEC AL
              CMP AL,255
              JNE I4
                MOV AL,AH  ; Horizontal Total
              I4:
              CALL OutCRTC
              JMP kbEND

      UP:
        CMP AX, 9800h ; Alt+Up
        JNE DOWN
          MOV AH, 10h
          INT 16h
          DEC [shiftY]
          MOV AL, 10h       ; Vertical Retrace Start
          CALL readCRTC
          INC AL
          CALL OutCRTC
          MOV AL, 11h       ; Vertical Retrace End
          CALL readCRTC
          MOV BL, AL
          AND BL, 00001111b
          INC BL
          AND AL, 11110000b
          OR AL, BL
          CALL OutCRTC
          MOV AL, 15h       ; Start Vertical Blank
          CALL readCRTC
          INC AL
          CALL OutCRTC
          MOV AL, 16h       ; End Vertical Blank
          CALL readCRTC
          INC AL
          CALL OutCRTC
          JMP kbEND

      DOWN:
        CMP AX, 0A000h ; Alt+Down
        JNE SWITCH
          MOV AH, 10h
          INT 16h
          INC [shiftY]
          MOV AL, 10h       ; Vertical Retrace Start
          CALL readCRTC
          DEC AL
          CALL OutCRTC
          MOV AL, 11h       ; Vertical Retrace End
          CALL readCRTC
          MOV BL, AL
          AND BL, 00001111b
          DEC BL
          AND AL, 11110000b
          OR AL, BL
          CALL OutCRTC
          MOV AL,15h       ; Start Vertical Blank
          CALL readCRTC
          DEC AL
          CALL OutCRTC
          MOV AL,16h       ; End Vertical Blank
          CALL readCRTC
          DEC AL
          CALL OutCRTC
          JMP kbEND

      SWITCH:
        CMP AX,1F00h ; Alt+S
        JE FIX33
          JMP kbRESET ; *
        FIX33:
          MOV AH,10h
          INT 16h
          XOR [TV],1
          CMP [CRTIdx],0
          JE NOTDEF
            MOV AL,[genNew]
            XCHG AL,[genOrg]
            MOV DX,3C2h
            OUT DX,AL
            MOV SI,OFFSET seqReg
            MOV DI,OFFSET seqIdx
            MOV DX,3C4h
            CALL SwapRegs
            MOV SI,OFFSET CRTReg
            MOV DI,OFFSET CRTIdx
            MOV DX,[CRTC]
            CALL SwapRegs
            MOV SI,OFFSET ext1Reg
            MOV DI,OFFSET ext1Idx
            MOV DX,3DEh
            CALL SwapRegs

            MOV AL,BYTE PTR ES:[485h]
            PUSH AX
            MOV AH,03
            PUSHF
            CALL DWORD PTR [oldINT10h]
            PUSH CX
            MOV AH,[charHeight]
            MOV BYTE PTR ES:[485h],AH
            MOV AL,4
            CMP AH,16
            JNE B08
              JMP SETFONT

          B08:
            SHR AL,1
            CMP AH,08
            JNE B14
              JMP SETFONT

          B14:
            SHR AL,1

          SETFONT:
            MOV AH,11h
            XOR BX,BX
            PUSHF
            CALL DWORD PTR [oldINT10h]
            MOV AH,01h
            MOV CX,[charDef]
            PUSHF
            CALL DWORD PTR [oldINT10h]
            POP CX
            MOV [charDef],CX
            POP AX
            MOV [charHeight],AL
            JMP kbEND

        NOTDEF:
          CALL VGAsetup
          JMP kbEND

      kbRESET:
        CMP AX,1300h ; Alt+R
        JNE kbEND
          MOV AH,10h
          INT 16h
          ;mov al, 39h     ; Interlace Start
          ;call readCRTC
          ;inc al
          ;call outCRTC
          jmp kbEND
          MOV [shiftX], 0
          MOV [shiftY], 0
          CALL VGAsetup
          JMP kbEND

kbEND:
  POP ES
  POP DS
  POP DI
  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  IRET

keybISR ENDP
