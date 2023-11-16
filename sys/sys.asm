
;  Copyright 2023, David S. Madole <david@madole.net>
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <https://www.gnu.org/licenses/>.


          ; Definition files

          #include include/bios.inc
          #include include/kernel.inc


          ; Unpublished kernel vector points

d_ideread:  equ   0447h
d_idewrite: equ   044ah


          ; Executable header block

            org   1ffah
            dw    begin
            dw    end-begin
            dw    begin
 
begin:      br    start

            db    7+80h
            db    29
            dw    2023
            dw    1

            db    'See github/dmadole/Elfos-sys for more information',0


start:      ldi   0                     ; presume only one argument
            plo   r9

skplead:    lda   ra                    ; skip any leading spaces
            lbz   dousage
            sdi   ' '
            lbdf  skplead

            ghi   ra                    ; leave ra at start of filename
            phi   rf
            glo   ra
            plo   rf
            dec   ra

skpfile:    lda   rf                    ; skip over filename
            lbz   drvonly
            sdi   ' '
            lbnf  skpfile

            ldi   0                     ; zero-terminate filename
            dec   rf
            str   rf
            inc   rf

skpspac:    lda   rf                    ; skip intervening spaces
            lbz   drvonly
            sdi   ' '
            lbdf  skpspac

            inc   r9

            dec   rf
            lbr   getdriv

drvonly:    ghi   ra
            phi   rf
            glo   ra
            plo   rf

getdriv:    lda   rf
            smi   '/'                   ; next must be a slash
            lbnz  dousage

            lda   rf                    ; followed by another slash
            smi   '/'
            lbnz  dousage

            sep   scall                 ; then drive number
            dw    f_atoi
            lbdf  dousage

            ghi   rd
            lbnz  dousage

            glo   rd                    ; save drive number
            smi   32
            lbdf  dousage

            ori   0e0h
            phi   r9

skptail:    lda   rf                    ; absorb trailing spaces
            lbz   gotargs
            sdi   ' '
            lbdf  skptail

dousage:    sep   scall                 ; otherwise display usage message
            dw    o_inmsg
            db    'USAGE: sys [filename] //drive',13,10,0
            sep   sret                  ; and return to os



gotargs:    glo   r9
            lbz   readsec

            ghi   ra                    ; get file name
            phi   rf
            glo   ra
            plo   rf

            ldi   fildes.1              ; get file descriptor
            phi   rd
            ldi   fildes.0
            plo   rd

            ldi   0                     ; plain open, no flags
            plo   r7

            sep   scall                 ; open file
            dw    o_open
            lbnf  checklen

            sep   scall
            dw    o_inmsg
            db    'ERROR: kernel file cannot be opened',13,10,0
            sep   sret





checklen:   ldi   0
            plo   r7
            phi   r7
            plo   r8
            phi   r8

            ldi   2
            plo   rc

            sep   scall
            dw    o_seek

            ghi   r8
            lbnz  toolong
            glo   r8
            lbnz  toolong

            glo   r7
            sdi   8192.0
            ghi   r7
            sdbi  8192.1
            lbdf  seekzer

toolong:    sep   scall
            dw    o_inmsg
            db    'ERROR: Kernel is too long (>8192 bytes).',13,10,0

            sep   sret





seekzer:    ldi   0
            plo   r7
            phi   r7
            plo   r8
            phi   r8

            ldi   0
            plo   rc

            sep   scall
            dw    o_seek




readsec:    ldi   0                     ; sector zero for boot code
            plo   r7
            phi   r7
            plo   r8

            ghi   r9                    ; drive selector
            phi   r8

            ldi   buffer.1              ; pointer to buffer
            phi   rf
            ldi   buffer.0
            plo   rf

            sep   scall                 ; read sector zero
            dw    d_ideread
            lbnf  gotboot

            sep   scall
            dw    o_inmsg
            db    'ERROR: could not read boot sector.',13,10,0

            sep   sret

gotboot:    ldi   buffer.1              ; pointer back to beginning
            phi   rf
            ldi   buffer.0
            plo   rf



            ldi   bootnew.1
            phi   rb
            ldi   bootnew.0
            plo   rb

            ldi   lastnew.0
            plo   rc

            glo   r9
            lbz   cpyboot

            ldi   bootold.1            ; pointer to boot code
            phi   rb
            ldi   bootold.0
            plo   rb

            ldi   lastold.0             ; size of boot code to copy
            plo   rc




cpyboot:    lda   rb                    ; copy boot code into buffer
            str   rf
            inc   rf

            dec   rc                    ; loop until complete
            glo   rc
            lbnz  cpyboot

            glo   rb
            lbz   checksum

zerboot:    ldi   0
            str   rf
            inc   rf

            inc   rb
            glo   rb
            lbnz  zerboot




checksum:   ldi   (buffer+38h).1        ; start of block to checksum over
            phi   rb
            ldi   (buffer+38h).0
            plo   rb

            ldi   8                     ; number of bytes to checksum
            plo   re

calcsum:    lda   rb                    ; add each byte then rotate left
            add
            shl
            str   r2

            dec   re                    ; repeat for all bytes in block
            glo   re
            lbnz  calcsum

            ldi   30h                   ; calculate the needed last byte
            sm
            str   rb







            ldi   buffer.1              ; reset pointer to beginning
            phi   rf
            ldi   buffer.0
            plo   rf

            sep   scall                 ; write back to disk
            dw    d_idewrite
            lbnf  cpykern



            sep   scall                 ; indicate error
            dw    o_inmsg
            db    'ERROR: could not write boot sector',13,10,0

            sep   sret                  ; return to OS









cpykern:    glo   r9
            lbnz  cpyloop

            sep   scall                 ; display completion message
            dw    o_inmsg
            db    'File-based boot loader installed.',13,10
            db    'Make sure there is a kernel at /os/kernel.',13,10,0

            sep   sret




cpyloop:    ldi   buffer.1              ; reset pointer to buffer
            phi   rf
            ldi   buffer.0
            plo   rf

            ldi   512.1                 ; one sectors worth of bytes
            phi   rc
            ldi   512.0
            plo   rc

            sep   scall                 ; read the sector
            dw    o_read
            lbnf  checkeof

            sep   scall
            dw    o_inmsg
            db    'ERROR: could not read kernel file.',13,10,0

            sep   sret

checkeof:   ghi   rc                    ; if end of file then stop
            lbnz  writsec
            glo   rc
            lbz   cpydone

writsec:    ldi   buffer.1              ; reset buffer pointer
            phi   rf
            ldi   buffer.0
            plo   rf

            inc   r7                    ; advance to next sector address

            sep   scall                 ; write sector to kernel area
            dw    d_idewrite

            ghi   rc                    ; if not a short read, continue
            smi   2
            lbdf  cpyloop

cpydone:    sep   scall                 ; display completion message
            dw    o_inmsg
            db    'Classic boot loader installed.',13,10
            db    'Kernel copied to reserved kernel area.',13,10,0

            sep   sret




          ; For historical reasons, I suppose, the boot sector effectively has
          ; two entry points depending on whether the PC is R0 or R3. As far
          ; as I know, only the R3 one is still used, but I'll provide both.

            org   ($+0ffh)&0ff00h       ; start at new page

offset:     equ   $-100h                ; delta of where assembled and run


          ; Entry point for when the PC is R0

bootnew:    ghi   r0                    ; get current page when pc=r0

gotpage:    phi   r2                    ; set page of sp, return, and path
            phi   r6
            phi   rd

            br    setup


          ; Entry point for when the PC is R3

            ghi   r3                    ; get current page when pc=r3
            br    gotpage


          ; Finish setting up a stack pointer and the return address for the
          ; BIOS initcall to setup R4 and R5 for SCALL use. The high bytes
          ; of R2 and R6 were setup previously with the page address.
          
setup:      adi   12ch.1                ; point to master directory dirent
            phi   rb
            ldi   12ch.0
            plo   rb

            ldi   imgpath.0             ; point to kernel path name
            plo   rd

            ldi   0                     ; set stack pointer just below us
            plo   r2
            dec   r2

            plo   rf                    ; point to memory buffer 0300h
            ldi   300h.1
            phi   rf

            ldi   0e0h                  ; set lba mode and drive zero
            phi   r8

            ldi   finddir.0             ; set lsb of return from initcall
            plo   r6

            lbr   f_initcall            ; setup r4 and r5 for scall


          ; The boot loader is in sector zero along with the directory entry
          ; for the master file directory, so the dirent is already in memory
          ; we just need to get a pointer to it offset from the load address.

finddir:    sep   scall
            dw    openfil-offset


          ; Number of bytes of data to read. If we are in the last AU then
          ; this is the EOF count, otherwise is is the AU size of 8 sectors.

nextlat:    ldi   8*512/32
            plo   r9

            sep   scall
            dw    findlat-offset

            bnz   totalau


          ; Divide the bytes to search in this AU by 32 to get the number of
          ; directory entries to check. We divide by 32 by multiplying by 8,
          ; then dividing by 256 by taking the MSB of the result.

            ghi   rc
            phi   r7
            glo   rc
            plo   r7

            sep   scall
            dw    multby8-offset

            ghi   r7
            plo   r9

            bz    nofound                ; this au is empty


          ; Multiply the AU by 8 to get the starting sector address of AU .

totalau:    sep   scall
            dw    getsect-offset

            ghi   rb
            phi   ra
            glo   rb

            skp                         ; the checksum situation stinks
            db    0

            plo   ra

          #if $.0 != 42h
            #error Checksum byte is not at offset 40h
          #endif


          ; Scan an AU of a directory file checking all dirents for one that
          ; is in use and that matches the name passed in RD.

nextsec:    ghi   rf                    ; get copy of buffer pointer
            phi   rb
            glo   rf
            plo   rb

            sep   scall                 ; read the sector and advance rf
            dw    f_ideread

            ghi   rb                    ; set pointer back to start
            phi   rf

            ldi   512/32                ; number of dirents in sector
            plo   r6

            sex   rd                    ; for sm in string comparison


          ; Check if the entry is used, which is indicated by the AU being
          ; non-zero. The first two bytes of the AU are not really used.

srchsec:    inc   rb                    ; first two bytes are always zero
            inc   rb

            lda   rb                    ; entry is empty if au is zero
            bnz   usedent
            ldn   rb
            bz    nomatch

usedent:    glo   rb                    ; advance pointer to filename
            adi   9
            plo   rb

            glo   rd                    ; save pointer to start of string
            phi   r6


          ; Compare the name in the directory entry to that which we are
          ; searching for.

cmpname:    lda   rb                    ; stop if at end of dirent name
            bz    cmpzero

            sm                          ; keep looking if character matches
            inc   rd
            bz    cmpname

nomatch:    ghi   r6                    ; reset search string to start
            plo   rd

	    dec   rb                    ; advance pointer to next dirent
            glo   rb
            ori   31
            plo   rb
            inc   rb

            dec   r9                    ; if all dirents in au check next
            glo   r9
            bz    lastdir

            dec   r6                    ; loop if not last direct in sector
            glo   r6
            bnz   srchsec

            inc   r7                    ; advance to next sector address
            br    nextsec

lastdir:    ghi   r9                    ; check next au if there is one
            bnz   nextlat

nofound:    br    $                     ; file not found, just freeze here



cmpzero:    lda   rd                    ; no match if string not at end
            bnz   nomatch

            dec   rb                    ; set back to start of dirent
            glo   rb
            ani   255-31
            plo   rb

            ldn   rd                    ; if not end of path find next
            bnz   finddir


          ; Now we have the direcnt of the kernel file itself. Access it and
          ; load into memory starting at RB.

            sep   scall                 ; get the starting au and eof
            dw    openfil-offset


          ; Number of bytes of data to read. If we are in the last AU then
          ; this is the EOF count, otherwise is is the AU size of 8 sectors.

checkau:    ldi   8                     ; read 8 sectors if not last au
            plo   r9

            sep   scall                 ; lookup next au in chain
            dw    findlat-offset

            bnz   wholeau               ; if not last then keep 8 sectors

            glo   rc                    ; else add 511 to get ceiling
            adi   511.0
            ghi   rc
            adci  511.1

            shr                         ; divide by 512, if zero then done
            bz    jmpkern

            plo   r9                    ; save count of sectors to load


          ; Multiply the AU by 8 to get the starting sector address.

wholeau:    sep   scall
            dw    getsect-offset


          ; Read next sectors into memory at RF, with the read call advancing
          ; RF each time as we go.

getmore:    sep   scall                 ; read the sector and advance rf
            dw    f_ideread

            inc   r7                    ; advance to next sector address

            dec   r9                    ; failure if all dirents checked
            glo   r9
            bnz   getmore

            ghi   rb                    ; else get next au after this
            phi   ra
            glo   rb
            plo   ra

            ghi   r9                    ; if end of file jump to kernel
            bnz   checkau

jmpkern:    plo   r0                    ; jump to kernel with pc as r0
            ldi   300h.1
            phi   r0
            sep   r0


          ; Get ready to access the file described by the dirent which is
          ; pointed by RB. All we really need from the dirent is the starting
          ; AU to know where to start, and the EOF offset, to know when to
          ; stop. These are returned in RA and RC, respectively.

openfil:    inc   rb                    ; skip initial always-zero bytes
            inc   rb

            lda   rb                    ; get the au number from dirent
            phi   ra
            lda   rb
            plo   ra

            lda   rb                    ; get the eof offset from dirent
            phi   rc
            lda   rb
            plo   rc

            sep   sret


          ; Get the next entry in the file's AU chain through the LAT table.
          ; This is needed first to know if we are at the last AU so that the
          ; EOF count can be honored, and if not, to address the next AU.
          ;
          ; The current AU is in RA and the next AU is returned in RB. If
          ; this is the last AU (next is FEFE) then R9.1 is set to zero.

findlat:    ghi   ra                    ; add 17 to get sector of lat entry
            adi   17
            plo   r7

            glo   rf                    ; clear the high byte of sector
            plo   r8

            shlc                        ; carry of plus 17 into middle byte
            phi   r7

            sep   scall                 ; read the sector and advance rf
            dw    f_ideread

            ghi   rf                    ; point rf back to start
            smi   2
            phi   rf

            glo   ra                    ; get offset of lsb times two
            shl
            plo   r7
            ghi   rf
            adci  0
            phi   r7

            lda   r7                    ; pick up lat entry from offset
            phi   rb
            lda   r7
            plo   rb

            smi   0feh                  ; if end then set r9.1 to zero
            bnz   latret
            ghi   rb
            smi   0feh

latret:     phi   r9                    ; set r9 to zero if end and return
            sep   sret


          ; Get the sector address of the curent AU in RA by mutiplying it
          ; by eight, returning result in R8.1:R7. Note this falls through.

getsect:    ghi   ra                    ; move au into the sector address
            phi   r7
            glo   ra
            plo   r7


          ; Multiply the 24-bit number in R7 by eight, extending the result
          ; into the low bit (and zeroing the high bits) of R8.0.

multby8:    ldi   100h>>3               ; we will stop when one shifts out
            plo   r8

mulloop:    glo   r7                    ; shift R8.0:R7 left one bit
            shl
            plo   r7
            ghi   r7
            shlc
            phi   r7
            glo   r8
            shlc
            plo   r8

            bnf   mulloop               ; loop until stop bit comes out

            sep   sret                  ; return


          ; The path to the kernel image relative to the master directory,
          ; stored with zeros instead of slashes to make it easier to process.
          ; The extra zero marks the end.

imgpath:    db   'os',0
            db   'kernel',0
            db    0

          #if $ > bootnew+100h
            #error New bootloader code longer than a page.
          #endif

lastnew:    equ   $


          ; Pull in the classic boot loader, this is kept in a separate file
          ; as it has different copyright terms than this file.

            org   ($+0ffh)&0ff00h       ; start at new page

          #include boot.asm

          #if $ > bootold+100h
            #error Old bootloader code longer than a page.
          #endif


fildes:     db    0,0,0,0
            dw    dta
            db    0,0
            db    0
            db    0,0,0,0
            dw    0,0
            db    0,0,0,0

dta:        ds    512

buffer:     ds    512

end:        end   begin

