\ Tilemap rendering
\  Loading tiles, tile and tilemap display and collision routines

[undefined] #MAXTILES [if] 16384 constant #MAXTILES [then]

create tiles #MAXTILES array,
:noname tiles vacate ; +loadtrig

0 value tba  \ tileset base address

( Break up a bitmap into tiles )
: tilebmp  ( n - bmp )
    #MAXTILES 1 - and tiles [] @ ;

: maketiles  ( bitmap tilew tileh firstid - )
    locals| id th tw bmp |
    bmp bmph dup th mod - 0 do
        bmp bmpw dup tw mod - 0 do
            bmp i j 2i tw th 2i al_create_sub_bitmap  id tiles [] !
            1 +to id
        tw +loop
    th +loop
;

: -tiles  ( - )
    tiles capacity for  i tiles [] dup @ -bmp  off  loop ;

: tilebase!  ( tile# - )  tiles [] to tba ;
: >gid  ( tile - gid )  $003fff000 and ;
0 tilebase! 

decimal \ for speed
: tile>bmp  ( tiledata - bitmap )  $03fff000 and #10 >> tba + @ ;
: tilesize  ( tiledata - w h )  tile>bmp bmpwh ;
: draw-bitmap  over 0= if 2drop exit then  >r  at@ 2af  r> al_draw_bitmap ;
: tile  ( tiledat - )  ?dup -exit  dup tile>bmp swap #28 >> draw-bitmap ;
: tile+  ( stridex stridey tiledat - )  tile +at ;
fixed
