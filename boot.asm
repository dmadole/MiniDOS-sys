; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

; The following is from fsgen.asm in Mike Riley's disttools package.
; For original source see https://github.com/rileym65/Elf-Elfos-disttools

; ************************************
; *** Define disk boot sector      ***
; *** This runs at 100h            ***
; *** Expects to be called with R0 ***
; ************************************

bootold:   ghi     r0                  ; get current page
           phi     r3                  ; place into r3
           ldi     low bootst          ; boot start code
           plo     r3
           sep     r3                  ; transfer control

bootst:    ldi     high call           ; setup call vector
           phi     r4
           ldi     low call
           plo     r4

           ldi     high ret            ; setup return vector
           phi     r5
           ldi     low ret
           plo     r5

           ldi     0                   ; setup an initial stack
           phi     r2
           ldi     0f0h
           plo     r2

           ldi     1                   ; setup sector address
           plo     r7
           ldi     3                   ; starting page for kernel
           phi     rf                  ; place into read pointer
           ldi     0
           plo     rf

           sex     r2                  ; set stack pointer

bootrd:    glo     r7                  ; save R7
           str     r2
           out     4
           dec     r2

           stxd

           ldi     0                   ; prepare other registers
           phi     r7
           plo     r8

           ldi     0e0h
           phi     r8

           sep     scall               ; call bios to read sector
           dw      f_ideread

           irx                         ; recover R7
           ldxa
           plo     r7

           inc     r7                  ; point to next sector
           glo     r7                  ; get count
           smi     15                  ; was last sector (16) read?
           bnz     bootrd              ; jump if not

           ldi     3                   ; setup jump to os
           phi     r0
           ldi     0
           plo     r0
           sep     r0                  ; jump to os

lastold: ; end of boot loader
