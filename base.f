exists ramen [if] \\ [then]
true constant ramen
include afkit/afkit.f  \ AllegroForthKit
#1 #5 #8 [afkit] [checkver]

( Low-level )
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

: ?p.  true if p. else i. then ;
: <int     is> bounds ?do i @ ." #" i. cell +loop ;
: <bin     is> dump ;
: <skip    is> nip ." ( " cell i/ i. ." )" space ;
: <fixed   is> bounds ?do i @ ?p. cell +loop ;
: sfield  sfield <fixed ;
: svar    svar   <fixed ;
: create-field  create-field <fixed ;

include ramen/types.f   cr .( Loaded essential datatypes... ) \ "
include ramen/superobj.f cr .( Loaded Super Objects extension... ) \ "

( Assets )
include ramen/assets.f  cr .( Loaded assets framework... ) \ "
include ramen/image.f   cr .( Loaded image module... ) \ "
include ramen/font.f    cr .( Loaded font module... ) \ "
include ramen/buffer.f  cr .( Loaded buffer module... ) \ "
include ramen/sample.f  cr .( Loaded sample module... ) \ "

( Higher level stuff )
create ldr 256 /allot
create project 256 /allot

include ramen/publish.f cr .( Loaded publish module... ) \ "
include ramen/draw.f    cr .( Loaded draw module... ) \ "

include ramen/default.f

: panic ( - ) step> noop ;
: void ( - ) panic show> ramenbg ;

: project:  ( -- <path/> ) bl parse slashes project place ;  \ must have trailing slash
: .project  project count type ;
: rld  ldr count nip -exit ldr count included ;
: ?project  project count nip ?exit  ldr count -filename project place ;
: ld
    bl parse s" .f" strjoin 2>r
        2r@ file-exists not if
            project count 2r> -path strjoin 2>r
        then
        2r@ ['] included catch
        2r@ ldr place
            dup 0= if  ?project  then
            throw 
    2r> 2drop ;

: empty
    page
    ." [Empty]" cr
    void
    -assets
    0 to now
    source-id 0> if including -name #1 + slashes project place then  \ swiftforth
    empty
;
: gild
    only forth definitions
    s" marker (empty)" evaluate
    ." [Gild] "
;
: now  now 1p ;  \ must go last


gild void