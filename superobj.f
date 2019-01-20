( Super objects! )

\ [x] - Classed objects
\ [x] - Templates
\ [x] - Two kinds of allocation - dictionary (static) and heap (dynamic)
\ [x] - Smart fields - different classes' fields can reuse names and you can check for field ownership on a class basis.
\ [x] - Private words
\ [x] - Constructors and destructors
\ [x] - Inspection
\ [x] - Inheritance
\ [x] - Fixed-size classes
\ [x] - Class extensions
\ [x] - Metaclasses

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
0 value lastClass  \ last defined Class

: ?literal  state @ if postpone literal then ;

also venery
    
    struct %class
        %class %node sembed class>node   \ note: %node has first cell reserved for metaclass
        %class svar class.size           <int
        %class svar class.wordlist       <hex
        %class svar class.template       <adr
        %class svar class.templateSize   <adr
        %class svar class.super          <adr 
        %class svar class.fixedSize      <int
        \ %class %node sembed class>pool 
        \ %class svar class.useHeap
        %class svar class.constructor    <xt
        %class svar class.destructor     <xt

        %class 1024 cells sfield class>offsetTable  <int

    struct %superfield
        %superfield svar superfield.offset  <int
    
    struct %field 
        %field %node sembed superfield>node 
        %field svar field.size        <int   
        %field svar field.offset      <int      
        %field svar field.inspector   <xt    
        %field svar field.class       <adr
        %field svar field.superfield  <adr

    : old-sizeof  sizeof ;    

previous

( class utils )
: template  ( class - object )  class.template @ ;
: >super  ( class - class|0 )  class.super @ ;
: >wordlist  ( class - wordlist )  class.wordlist @ ;
: sizeof  ( class - n ) class.size @ ;
: >offsetTable  ( class - adr )  [ 0 class>offsetTable ]# ?literal s" +" evaluate ; immediate


( object utils )
: >class  ( object - class )  s" @" evaluate ; immediate
: size  ( object - n )  >class sizeof ;
: super  ( - class )  me >class >super ;

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

: does-superfield  does> @ offsetTable + @ me + ;

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

: class.class ;

: allocation  dup class.fixedSize @ dup if nip else drop class.size @ then ;

: /object  ( class object - )
    >r 
    dup template r@ rot class.templateSize @ move
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

: static  dup allocation allotment /object ;

: dynamic  ( class - object )
\    dup class.useHeap @ if
        dup allocation allocate throw
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

: class!  ! ;

: /template
    cc class.template @ cc class.class @ = if
        \ create a new template copied from superclass
        cc allocation allotment cc class.template !
        cc >super class.template @ cc class.template @ cc >super allocation move
        cc allocation cc class.templateSize !  \ support extensions
        cc dup class.template @ class!  \ set the template's class, v. important
    else
        \ create a new template copied from the current one.
        cc class.template @ 
            cc allocation allotment cc class.template !
            ( template ) cc class.template @ cc class.templateSize @ move
        cc allocation cc class.templateSize !
    then
;

: end-class
    /template
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
                      dup field.inspector @ r@ field.inspector !
                      dup field.size @ r@ field.size !
                      dup field.offset @ r@ field.offset !
                          field.class @ r@ field.class !
            r@ cc push
        r> drop
;

: metaclassed   ( superclass metaclass - <name> )
    create
    ( metaclass ) dup static  me class.class !
        me to cc
        cc to lastClass
        /cc
    ( superclass ) cc class.super !
    cc >super sizeof cc class.size !
    cc >super class.constructor @ cc class.constructor !
    cc >super class.destructor  @ cc class.destructor !
    copy-fields
    cc >super class>offsetTable cc class>offsetTable 1024 cells move
;

: class  ( superclass - <name> )
    dup class.class @ metaclassed
;

: fixed-class  ( size superclass - <name> )
    class  lastClass class.fixedSize !
;



( Root Metaclass )

create <class>  %class old-sizeof /allot  <class> to cc  /cc
    cc cc class.class !
    %class old-sizeof dup cc class.size !  cc class.templateSize !
    cc cc class.template !    cc class>offsetTable  1024  $80000000  ifill
    ' noop cc class.constructor !
    ' noop cc class.destructor !

( Root class )

create object-template 0 ,

create <object> %class old-sizeof /allot  <object> to cc  /cc
    <class> <object> class.class !
    1 cells cc class.size !  \ account for the class field
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

: define-fields  to cc ;

: field  create-superfield ;
: var  cell field ;

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

: (peek)  ( object class - ) 
    each> ( adr object, field, - adr )
        normal         
        dup field.superfield @ body> >name count type space
        bright
        2dup dup field.size @ swap field.inspector @ execute
        field.size @ +   \ go to next field in the passed instance
;

: peek  ( object - )
    dup >class  dup >fields dup length if node.first @ field.offset @ u+ ( skip any collection stuff )
                                       else drop then
        (peek) drop normal ;

: extend-class ( - <name> )
    ' >body to cc 
;

( Utils )
: .me   me peek ;
: .class  each> dup field.superfield @ .name   field.offset @ i.  cr ;


( TEST )

<node> class <fdsa>
    var en
    var x
    var y
    var flags
end-class

<node> class <asdf>
    var x
    var y
end-class

200 200 <fdsa> template 's x 2!
100 100 <asdf> template 's x 2!

create ako <fdsa> static
create bko <asdf> static

<fdsa> :: test ." hi" ;
<fdsa> :pub ok test ;

<fdsa> dynamic  me destroy

