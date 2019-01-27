
\ Multitasking for game objects

\ The following words should only be used within a task:
\  PAUSE END FRAMES SECS
\ The following words should never be used within a task:
\  - External calls
\  - Console output 
\  (See below for a workaround)

extend-class _actor
    var sp <adr  16 cells field ds
    var rp <adr  var (rs) <adr
    var (task)  <flag
end-class

\ : ds  (ds) @ ;
: rs  (rs) @ ;
: dtop  ds 16 cells + ;
: rtop  rs 8 kbytes + ;

create main _actor static \ proxy for the Forth data and return stacks

: (more)  ( - flag )
    begin  me node.next @ dup -exit   as   en @ until  true ;

: pause  ( - ) 
    dup \ ensure TOS is on stack
    sp@ sp !
    rp@ rp !
    \ look for next task.  end of list = jump to main task and resume that
    begin  (more) if  (task) @  else  main dup as  then  until
    \ restore state
    rp @ rp!
    sp @ sp!
    drop \ ensure TOS is in TOS register
;
: pauses  ( n - ) for  pause  loop ;
: seconds  ( n - n ) fps * ;  \ not meant for precision timing
: dally  ( n - ) seconds pauses ;
: running?     sp@ ds >= sp@ dtop < and ;
: halt   (task) off  running? if pause then ;
: end    dismiss halt ;
: ?end   -exit end ;

decimal
    : *taskstack  8 kbytes allocate throw ;
    : ?stacks  (rs) @ ?exit  *taskstack (rs) ! ;
    : perform> ( n - <code> )
        \ running? if ds 27 cells + sp!  r>  rs 58 cells + rp!  >r noop exit then
        ?stacks
        (task) on
        dtop cell- !  dtop cell- cell- sp !  r> rtop cell- cell- !  rtop cell- cell- rp !
        ['] halt >code rtop cell- !
\        running? if pause then
    ;
\    : perform  ( xt n - )
\        ?stacks
\        ds 28 cells + !
\        ds 27 cells + sp !
\        >code rs 58 cells + !
\        ['] (halt) >code rs 59 cells + !
\        rs 58 cells + rp !
\    ;
fixed



\ pulse the multitasker.
: multi  ( objlist - )
    dup 0= if drop ;then
    dup length 0= if drop ;then
    >first main node.next !
    dup
    sp@ main 's sp !
    rp@ main 's rp !
    main >{
        begin
            ['] pause catch if
                cr ." A task crashed. Halting it."
                (task) off  \ don't call HALT, we don't want PAUSE
            then
        me node.next @ 0= me main = or until
    }
    drop
;

: free-task  ( - )
    (rs) @ -exit  (rs) @ free throw ;


: task:free-node
    dup _actor is? not if  destroy ;then
    dup actor:free-node
    >{ free-task }
;    

' task:free-node is free-node