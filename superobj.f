( Super objects! )

\ [x] - Classed objects
\ [x] - Templates
\ [x] - Two kinds of allocation - dictionary (static) and heap (dynamic)
\ [x] - Smart fields - different classes' fields can reuse names and you can check for field ownership on a class basis.
\ [x] - Private words
\ [x] - Constructors and destructors
\ [x] - Inspection
\ [x] - Inheritance 

\ TODO:
\ [x] - CLASS: copy all field instances and add them, plus the offset table
\ [x] - Make nodes compatible with this so we can subclass from them
\ [ ] - Implement arrays, stacks and strings, including dynamic ones.
\ [x] - Initialize offset tables with high offsets intended to cause segfaults
\ [x] - >{ { }
\ [ ] - Implement ?ALREADY

\ MAYBE, MAYBE NOT:
\ [ ] - Automatic construction/destruction of embedded objects, such as collections  (downside: slow)
\ [ ] - The ability to call superclass constructors/destructors
\ [ ] - Pool allocation (problem: objects aren't all nodes!!! what do?? maybe just custom build for actors)


\ depends on structs.f and Venery


0 value me
0 value offsetTable
0 value cc \ current Class
0 value nextOffsetSlot \ next offset in offset table
0 value (superfield)  \ a temporary variable

: ?literal  state @ if postpone literal then ;

also venery
    
    struct %class
        %class %node sembed class>node   
        %class svar class.size           
        %class svar class.wordlist
        %class svar class.template
        %class svar class.super
        \ %class %node sembed class>pool 
        \ %class svar class.useHeap
        %class svar class.constructor
        %class svar class.destructor

        %class 1024 cells sfield class>offsetTable

    struct %superfield
        %superfield svar superfield.offset
    
    struct %field 
        %field %node sembed superfield>node 
        %field svar field.size              
        %field svar field.offset            
        %field svar field.inspector         
        %field svar field.class
        %field svar field.superfield

    : old-sizeof  sizeof ;    

previous

( class utils )
: template  class.template @ ;
: >super  class.super @ ;
: >wordlist  class.wordlist @ ;
: sizeof  class.size @ ;
: >offsetTable  [ 0 class>offsetTable ]# ?literal s" +" evaluate ; immediate


( object utils )
: >class s" @" evaluate ; immediate
: size  >class sizeof ;
: super  me >class >super ;

( search order )
: converse  ( class - )
    dup >super dup if recurse else drop then
    >wordlist +order
;
: -converse  ( class - )
    dup >super dup if recurse else drop then
    >wordlist -order
;
: ?converse  me -exit state @ ?exit me >class converse  ;
: ?-converse me -exit state @ ?exit me >class -converse ;

: as  ( obj - )
    ( ?-converse )
    dup to me  >class >offsetTable to offsetTable
    ( ?converse )
;
create mestk  0 , 16 cells allot
: i{ ( - ) me mestk dup @ cells + cell+ !  mestk @ 1 + 15 and mestk ! ;  \ interpreter version, uses a circular stack
: i} ( - ) mestk @ 1 - 15 and mestk !  mestk dup @ cells + cell+ @ as ; 
: {  ( - ) state @ if s" me >r" evaluate else  i{  then ; immediate
: }  ( - ) state @ if s" r> as" evaluate else  i}  then ; immediate
: >{ ( object - )  s" { as " evaluate ; immediate 


: add-field  ( field class - )  push ;

: does-superfield
    immediate does>  @ ?literal  s" offsetTable + @ me +" evaluate
;

: 's
    s" dup >class >offsetTable" evaluate ' >body @ ?literal s" + @ +" evaluate
; immediate

: field-exists  >in @ defined if >body cell+ @ $12345678 = else drop 0 then swap >in ! ;

: (.field)  ( adr size - )
    bounds ?do i @ . cell +loop ;

: create-superfield  ( size - <name> )  ( - adr )
    field-exists not if
        ( not defined; define the superfield word )
        >in @ create >in !
        nextOffsetSlot , $12345678 , does-superfield
        cell +to nextOffsetSlot
    then
    
    ' >body to (superfield)
    
    \ ?already  \ can only define once per class
    
    cc sizeof
        cc class>offsetTable
            (superfield) @ ( the offset slot offset ) + !
        
    
    ( create the field instance, for great justice )
    %field old-sizeof allotment >r
        r@ to lastfield
        r@ /node
        (superfield)  r@ field.superfield !
        r@ cc add-field
        ( size ) dup r@ field.size !
        cc class.size @ r@ field.offset !
        ['] (.field) r@ field.inspector !
    r> drop

    ( size ) cc class.size +!
;

: /cc
    cc /node
    \ cc class>pool /node
    wordlist cc class.wordlist !
;

: >fields ; 

: copy-fields
    cc >super >fields each>
        here >r  %field old-sizeof /allot
            r@ /node 
            ( field ) dup field.superfield @ r@ field.superfield !
                          field.inspector @ r@ field.inspector !
            r@ cc push
        r> drop
;

: class  ( superclass - <name> )
    create %class old-sizeof allotment to cc
    /cc
    cc class.super !
    cc >super sizeof cc class.size !
    copy-fields
    cc >super class>offsetTable cc class>offsetTable 1024 cells move
;

: /template
    cc sizeof allotment cc class.template !
    cc >super class.template @ cc class.template @ cc >super sizeof move
    cc dup class.template @ !  \ set the template's class, v. important
;

: end-class
    /template
;

: /object  ( class object - )
    >r 
    dup template r@ rot sizeof move
    r> as 
    me >class class.constructor @ execute
    ( initialize embedded objects )
\    me >class >fields each>
\        dup field.class @ dup if
\            ( field class )
\            swap  @ offsetTable + @ me +
\                >{ recurse }
\        else
\            drop drop
\        then
;

: static  dup sizeof allotment /object ;

: dynamic  ( class - object )
\    dup class.useHeap @ if
        dup sizeof allocate throw
\    else
\        dup class>pool length if
\            dup class>pool pop
\        else
\            dup sizeof allotment 
\        then
\    then
    /object
;

: destroy  ( object - )
    dup >{ dup >class class.destructor @ execute } 
\    dup >class class.useHeap @ if
    free throw
\    else
\        dup >class class>pool .s push
\    then
;


create object-template 0 ,

create <object> %class old-sizeof /allot  <object> to cc  /cc
    cell cc class.size !  \ the class field
    object-template cc class.template !
    cc class>offsetTable  1024  $80000000  ifill
    ' noop cc class.constructor !
    ' noop cc class.destructor !


<object> >wordlist +order definitions
    : ; postpone ; -converse set-current ; immediate
previous definitions


: knowing  ( class - current class ) get-current swap dup converse ;

: :pub ( class - <name> <code> current class ; )
    knowing :
;

: :: ( class - <name> <code> ; )
    knowing definitions : 
;

( Venery classes )

<object> class <node>
    %node venery:sizeof <node> class.size !
    :noname me /node ; <node> class.constructor !
end-class

\ <object> class <array>
\     %array venery:sizeof <array> class.size !
\ end-class
\ 
\ <object> class <string>
\     %string venery:sizeof <string> class.size !
\ end-class

( Inspection )

: (peek)
    each> ( object field )
        normal         
        dup field.superfield @ body> >name count type space
        bright
        2dup dup field.size @ swap field.inspector @ execute
        field.size @ +   \ go to next field in the passed instance
;

: peek  ( object - )
    dup >class  dup node.first @ field.offset @ u+  (peek)  drop ;

: extend-class ( - <name> )
    ' >body to cc
;

: .me   me peek ;

( TEST )

: var  cell create-superfield ;
\ : embed  dup sizeof create-superfield  lastfield

<node> class <actor>
    var en
    var flags
    var x
    var y
end-class

<node> class <particle>
    var x
    var y
end-class

200 200 <actor> template 's x 2!
100 100 <particle> template 's x 2!

create ako <actor> static
create bko <particle> static

<actor> :: test ." hi" ;
<actor> :pub ok test ;

<actor> dynamic  me destroy