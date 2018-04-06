$000100 [version] cgrid-ver

\ Fast collision manager object (RAMEN).
\ Does efficient collision checks of massive
\ numbers of AABB (axis-aligned bounding boxes).
\ Very useful for broad-phase collision checks.

\ Notes:
\  - Doesn't support hitboxes bigger than sectw x secth

struct cbox

var x1  var y1  var x2  var y2  \ absolute hitbox

define cgriding

    cbox int svar s1    cbox int svar s2  \ sectors 1-4
    cbox int svar s3    cbox int svar s4

    #8 #12 + constant bitshift

    \ variable topleft
    \ variable topright
    \ variable btmleft
    variable lastsector
    variable lastsector2

    defer collide  ( ... true cbox1 cbox2 -- ... keepgoing? )

    \ defer cfilter  ( cbox1 cbox2 ... cbox1 cbox2 flag )  ' true is cfilter

    0 value cgrid  \ current cgrid
    : cgrid-var  sfield  does> @ cgrid + ;

    struct %cgrid
    %cgrid cell int cgrid-var cols
    %cgrid cell int cgrid-var rows
    %cgrid cell int cgrid-var sectors         \ link to array of sectors
    %cgrid cell int cgrid-var links           \
    %cgrid cell int cgrid-var i.link          \ points to structure in links:  link to next ( i.link , box , )


    256 constant sectw
    256 constant secth
    \ the size of each sector is a constant.
    \  use a smaller size if you're going to have lots of small objects.
    \  use a larger size if you're going to have lots of large objects.

    decimal
    : sector  ( x y -- addr )
      ( y ) bitshift >> cols @ p* swap ( x ) bitshift >> + cells sectors @ + ;
    fixed

    \ find if 2 rectangles (x1,y1,x2,y2) and (x3,y3,x4,y4) overlap.
    : overlap? ( xyxy xyxy -- flag )
        2swap 2rot rot > -rot <= and >r rot >= -rot < and r> and ;

    : link  ( box sector -- )
      >r
      i.link @ cell+ !  \ 1. link box
      r@ @ i.link @ !  \ 2. link the i.link to address in sector
      i.link @ r> !   \ 3. store current link in sector
      2 cells i.link +! ;  \ 4. and increment current link

    : box>box?  ( box1 box2 -- box1 box2 flag )
      2dup = if  false  exit  then           \ boxes can't collide with themselves!
      \ cfilter not if  false exit  then
      2dup >r  4@  r> 4@   overlap? ;

    0 value cnt
    : check-sector  ( cbox1 sector -- flag )
      0 to cnt
      swap true locals| flag cbox1 |
      begin ( sector ) @ ( link|0 ) dup flag and while
        ( link ) >r  cbox1  r@ cell+ @  box>box? if
          flag -rot  collide  to flag
        else
          ( box box ) 2drop
        then
        r> ( link )
        1 +to cnt
      repeat
      ( link|0 ) drop
      flag
    ;

    : ?check-sector  ( cbox1 sector|0 -- flag )  \ check a cbox against a sector
      dup if  check-sector  else  nip  then ;

    : ?corner  ( x y -- 0 | sector )  \ see what sector the given coords are in & cull already checked corners
      sector
      ;
      \ dup lastsector @ = if  drop 0  exit  then
      \ dup lastsector2 @ = if  drop 0  exit  then
      \ lastsector @ lastsector2 !
      \ dup  lastsector ! ;

only forth definitions also cgriding

: cbox!  ( x y w h cbox -- )  >r  2over 2+  #1 #1 2-  r@ x2 2!  r> x1 2! ;
: cbox@  ( cbox -- x y w h ) dup >r x1 2@ r> x2 2@  2over 2-  #1 #1 2+ ;

: reset-cgrid ( cgrid -- )
  to cgrid
  sectors @ cols 2@ * ierase
  links @ i.link ! ;

: add-cbox  ( cbox cgrid -- )
  to cgrid
  ( box ) >r  lastsector off  lastsector2 off
  r@ x1 2@         ?corner ?dup if  dup r@ s1 !  r@ swap link  else  r@ s1 off  then
  r@ x2 @ r@ y1 @  ?corner ?dup if  dup r@ s2 !  r@ swap link  else  r@ s2 off  then
  r@ x1 @ r@ y2 @  ?corner ?dup if  dup r@ s4 !  r@ swap link  else  r@ s4 off  then
  r@ x2 2@         ?corner ?dup if  dup r@ s3 !  r@ swap link  else  r@ s3 off  then
  r> drop
  ( topleft off topright off btmleft off ) ;

\ perform collision checks.  assumes box has already been added to the cgrid.
\   this avoids unnecessary work for the CPU.
: check-cgrid  ( cbox1 xt cgrid -- )  \ xt is the response; see COLLIDE
  to cgrid  is collide
  locals| cbox |
  cbox dup s1 @ ?check-sector -exit
  cbox dup s2 @ ?check-sector -exit
  cbox dup s3 @ ?check-sector -exit
  cbox dup s4 @ ?check-sector drop ;

\ this doesn't require the box to be added to the cgrid
: check-cbox  ( cbox1 xt cgrid -- )  \ xt is the response; see COLLIDE
  to cgrid  is collide
  locals| cbox |
  lastsector off lastsector2 off
  cbox dup x1 2@        ?corner  ?check-sector -exit
  cbox dup x2 @ cbox y1 @  ?corner  ?check-sector -exit
  cbox dup x1 @ cbox y2 @  ?corner  ?check-sector -exit
  cbox dup x2 2@        ?corner  ?check-sector drop ;

: >#sectors  sectw 1 - secth 1 - 2+  sectw secth 2/  2pfloor ;

: cgrid:  ( maxboxes width height -- <name> )  \ give width and height in regular units
  create  %cgrid sizeof buffer  to cgrid
  >#sectors
  2dup cols 2!  here sectors !  ( cols rows ) * cells /allot
                here links !    ( maxboxes )  4 * 2 cells * /allot ;

: cgrid-size  ( cgrid -- w h )
  to cgrid  cols 2@  sectw secth 2* ;