( ---=== Publish: SwiftForth ===--- )

create default-font  \ note not a registered asset
    /assetheader /allot  al-default-font , 8 , 0 , 

defer cold  :make cold ;   \ cold boot: executed once at runtime
defer warm  :make warm ;   \ warm boot: executed potentially multiple times 

: boot
    false to allegro?
    false to display
    #3 to #globalscale
    ALLEGRO_WINDOWED
    ALLEGRO_NOFRAME or
        to allegro-display-flags
    fs off
    +display
    initaudio
    project off
    ['] initdata catch if s" An asset failed to load." alert then
    al-default-font default-font font.fnt !
;
: runtime  boot cold warm go ;
: relify
    dup asset? if srcfile dup count s" data/" search if  rot place  else 3drop then
               else drop then ;

[defined] program [if]
    
    :make bye  0 ExitProcess ; 
    
    : publish ( - <name> )
        cr ." Publishing to "  >in @ bl parse type >in !  ." .exe ... "
        ['] relify assets each
        ['] runtime 'main !
        program ;
[else]
    cr .( PROGRAM not defined; PUBLISH disabled )
[then]