
\ Multitasking for game objects

\ The following words should only be used within a task:
\  PAUSE END FRAMES SECS
\ The following words should never be used within a task:
\  - External calls
\  - Console output 
\  (See below for a workaround)

0 value task  \ current task

extend-class _actor
    var sp <adr  96 cells field ds <skip
    var rp <adr  var (rs) <adr
    var (task)  <flag
end-class



: rs  (rs) @ ;
: dtop  ds 96 cells + ;
: rtop  rs 8 kbytes + ;

: .ds  's ds 96 cells idump ;


create main _actor static \ proxy for the Forth data and return stacks
main to task

: (more)  ( - flag )
    begin  me node.next @ dup -exit   as   en @ until  true ;

: pause  ( - ) 
    dup \ ensure TOS is on stack
    sp@ sp !
    rp@ rp !
    \ look for next task.  end of list = jump to main task and resume that
    begin  (more) if  (task) @  else  main dup as  then  until
    me to task
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
    : perform  ( n xt - )
        ?stacks
        \ running? if ds 27 cells + sp!  r>  rs 58 cells + rp!  >r noop exit then
        (task) on
        >code rtop cell- cell- !
        dtop cell- !
        dtop cell- cell- sp !
        ['] halt >code rtop cell- !
        rtop cell- cell- rp !
\        running? if pause then
    ;
    : perform> ( n - <code> )
        r> code> perform ;

fixed

0 value (xt)
0 value (sp)
: farcall ( val xt - )  ( val - )
    task main = if sp@ to (sp) execute (sp) sp! drop drop ;then
    to (xt)
    sp@ sp !
    rp@ rp !
    main 's sp @ sp!
    main 's rp @ rp!
    { (xt) execute }
    rp @ rp!
    sp @ sp!
    drop
;


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
                dtop cell- sp! .me
                cr ." Data stack: "
                ds 128 cells idump
                (task) off  \ don't call HALT, we don't want PAUSE
            then
        me node.next @ 0= me main = or until
    }
    drop
    main to task
;

: free-task  ( - )
    (rs) @ -exit  (rs) @ free throw ;


: task:free-node
    dup _actor is? not if  destroy ;then
    dup actor:free-node
    >{ free-task }
;


\ : empty  sp@ main 's sp !  rp@ main 's rp !  empty ;
sp@ main 's sp !  rp@ main 's rp !

' task:free-node is free-node

