exists ramen [if] \\ [then]
true constant ramen
include afkit/afkit.f  \ AllegroForthKit
#1 #5 #8 [afkit] [checkver]

\ Low-level
0 value (count)
0 value (ts)
0 value (bm)
\ include ramen/plat.f
[undefined] LIGHTWEIGHT [if]
include afkit/dep/zlib/zlib.f
[then]
include ramen/fixops.f
include afkit/plat/sf/fixedp.f   \ must come after fixops.  
include ramen/res.f     cr .( Loaded fixed-point... ) \ "
include venery/venery.f cr .( Loaded Venery... ) \ "
include ramen/structs.f cr .( Loaded structs... ) \ "

: <decimal is> bounds ?do i @ i. cell +loop ;
: <int     is> bounds ?do i @ 1i i. cell +loop ;
: <bin     is> dump ;
: <skip    is> nip ." ( " cell i/ i. ." )" space ;
: <fixed   is> bounds ?do i @ dup if p. else i. then cell +loop ;
: sfield  sfield <fixed ;
: svar    svar   <fixed ;
: create-field  create-field <fixed ;
include ramen/types.f   cr .( Loaded essential datatypes... ) \ "
include ramen/superobj.f cr .( Loaded Super Objects extension... ) \ "

\ Assets
include ramen/assets.f  cr .( Loaded assets framework... ) \ "
include ramen/image.f   cr .( Loaded image module... ) \ "
include ramen/font.f    cr .( Loaded font module... ) \ "
include ramen/buffer.f  cr .( Loaded buffer module... ) \ "
include ramen/sample.f  cr .( Loaded sample module... ) \ "

\ Higher level stuff
include ramen/publish.f cr .( Loaded publish module... ) \ "
include ramen/draw.f    cr .( Loaded draw module... ) \ "

include ramen/default.f

: void ( - ) show> ramenbg ;
: panic ( - ) step> noop ;

: empty
    page
    ." [Empty]" cr
    panic void empty
    0 to now
;

: now  now 1p ;

: gild
    only forth definitions
    s" marker (empty)" evaluate
    ." [Gild] "
;

create ldr 64 allot
: rld  ." [Reload] " ldr count included ;
: ld   bl parse s" .f" strjoin 2dup 2>r ['] included catch 2r> ldr place throw ;

gild
