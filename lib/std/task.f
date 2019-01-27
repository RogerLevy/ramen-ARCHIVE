( Multitasking )

extend-class _actor
    var ddepth
    var rdepth
    var old-ddepth
    var old-rdepth
    30 cells field ds <skip
    60 cells field rs <skip
end-class

create main _actor static \ proxy for the Forth data and return stacks

: running?     sp@ ds >=  sp@ rs <= and ;
: (halt)    begin pause again ;

decimal
    : perform> ( n - <code> )
        \ running? if ds 27 cells + sp!  r>  rs 58 cells + rp!  >r noop exit then
        ds 28 cells + !  ds 27 cells + sp !  r> rs 58 cells + !  rs 58 cells + rp !
        ['] (halt) >code rs 59 cells + !
        \ running? if pause then
    ;
    : perform  ( xt n obj - )
        >{
        ds 28 cells + !
        ds 27 cells + sp !
        >code rs 58 cells + !
        ['] (halt) >code rs 59 cells + !
        rs 58 cells + rp !
        }
    ;

    : next-enabled  ( - flag )  begin  me node.next @ dup -exit   as   en @ until  true ;
    : pause  ( - ) 
        sp@ ds sp@ s0 - dup ddepth ! cells move
        rp@ rs rp@ r0 - dup rdepth ! cells move
        
        
        
        \ look for next task.  rp = 0 means no task.  end of list = jump to main task and resume that
        begin  next-enabled if  rp @  else  main dup as  then  until
        \ restore state
        rp @ rp!
        sp @ sp!
        drop \ ensure TOS is in TOS register
    ;
fixed

: pauses  ( n - ) for  pause  loop ;
: seconds  ( n - n ) fps * ;  \ not meant for precision timing
: dally  ( n - ) seconds pauses ;

: halt   0 rp !  running? if pause then ;
: end    dismiss halt ;
: ?end   -exit end ;

\ pulse the multitasker.
: multi  ( objlist - )
    dup 0= if drop ;then
    dup length 0= if drop ;then
    >first main node.next !
    dup
    sp@ main 's sp !
    rp@ main 's rp !
    main >{
        ['] pause catch ?dup if
            cr ." A task crashed. Halting it."
            \ 0 rp !  \ don't call HALT, we don't want PAUSE
            throw
        then
    }
    drop
    arbitrate
;
