( Z-sorted game objects )

depend ramen/lib/rsort.f

extend-class _actor
    var zdepth
end-class

:slang drawem  ( addr cells - )  cells bounds do  i @ as  draw  cell +loop ;
:slang enqueue  ( objlist - )  each> as  hidden @ ?exit  me , ;
:slang #queued  here swap - cell/ ;
: zdepth@  's zdepth @ ;
: drawzsorted  ( objlist - )
    here
        dup rot enqueue
        #queued 2dup ['] zdepth@ rsort
        drawem
    reclaim ;
