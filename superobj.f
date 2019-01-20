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
\ [ ] - Figure out a way to cull all EMPTY'd classes from all class's lists of children 

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
        %class %node sembed class>fields
        %class svar class.isMeta         <flag

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
        %field svar field.attributes

    : old-sizeof  sizeof ;    

previous

( class utils )
: template  ( class - object )  class.template @ ;
: >super  ( class - class|0 )  class.super @ ;
: >wordlist  ( class - wordlist )  class.wordlist @ ;
: sizeof  ( class - n ) class.size @ ;
: >offsetTable  ( class - adr )  [ 0 class>offsetTable ]# ?literal s" +" evaluate ; immediate
: >fields  class>fields ; 
: isMeta?  class.isMeta @ ;


( object utils )
: >class  ( object - class )  s" @" evaluate ; immediate
: size  ( object - n )  >class sizeof ;
: super  ( - class )  me >class >super ;
: class!  ( class object - ) ! ;

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


: add-field  ( field class - )  >fields push ;

: does-superfield  does> @ offsetTable + @ me + ;

: 's
    s" dup >class >offsetTable" evaluate ' >body @ ?literal s" + @ +" evaluate
; immediate

: field-exists  >in @ defined if >body cell+ @ $12345678 = else drop 0 then swap >in ! ;

: (.field)  ( adr size - )
    bounds ?do i @ . cell +loop ;

( create the anonymous field instance, for great justice )
: create-field-instance  ( size superfield - )
    to (superfield)
    
    \ ?already  \ can only have one of each superfield per class
    
    cc sizeof
        cc class>offsetTable
            (superfield) @ ( the offset slot offset ) + !
    
    %field old-sizeof allotment >r
        r@ to lastfield  \ needed for defining inspectors
        r@ /node
        (superfield)  r@ field.superfield !
        ( size ) dup r@ field.size !
        cc class.size @ r@ field.offset !
        ['] (.field) r@ field.inspector !
        r@ cc add-field
    r> drop

    ( size ) cc class.size +!
;

defer (propogate-superfield)
0 value (size)
: propogate-superfield 
    (size) (superfield) create-field-instance
    cc each>
        cc >r
            ( class ) to cc (propogate-superfield)   \ RECURSE doesn't work with EACH> unfortunately
        r> to cc
;
' propogate-superfield is (propogate-superfield)

: create-superfield  ( size - <name> )  ( - adr )
    field-exists not if
        ( not defined; define the superfield word )
        >in @ create >in !
        nextOffsetSlot , $12345678 , does-superfield
        cell +to nextOffsetSlot
    then
    
    ' >body to (superfield)
    ( size ) to (size)
    propogate-superfield
;

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

: 0node  ( node - )
    dup cell+ %node venery:sizeof cell- erase
    /node
;

: /cc
    cc 0node
    cc >fields 0node
    wordlist cc class.wordlist !
;

: copy-fields
    cc >super >fields each>
        here >r  %field old-sizeof /allot
            r@ /node 
            ( field ) dup field.superfield @ r@ field.superfield !
                      dup field.inspector @ r@ field.inspector !
                      dup field.size @ r@ field.size !
                      dup field.offset @ r@ field.offset !
                          field.class @ r@ field.class !
            r@ cc add-field
        r> drop
;

variable makeItFixedSize

: inherit   ( superclass metaclass - <name> )
    create
    ( metaclass ) dup static  me class!
        me to cc
        cc to lastClass
        /cc
        
    ( superclass ) cc class.super !
    
    cc dup >super push
    cc >super sizeof cc class.size !
    cc >super class.constructor @ cc class.constructor !
    cc >super class.destructor  @ cc class.destructor !
    cc >super class.fixedSize   @ cc class.fixedSize !
    cc >super class.isMeta      @ cc class.isMeta !
    cc isMeta? 0= if cc class.template off then  \ kludgey but necessary
    makeItFixedSize @ cc class.fixedSize !
    cc isMeta? makeItFixedSize @ and if  cc class.fixedSize @  cc sizeof - #8000 + /allot  then
    copy-fields
    cc >super class>offsetTable cc class>offsetTable 1024 cells move
;

: class  ( superclass - <name> )
    makeItFixedSize off  dup >class inherit
;

: fixed-class  ( size superclass - <name> )
    swap makeItFixedSize !  dup >class inherit
;


: /template
    cc isMeta? if
        cc dup class.template !  \ class is its own template
        cc allocation cc class.templateSize !
        cc dup class! \ metaclass's classes are themselves
    ;then
    cc class.template @ 0= if
        \ create a new template copied from superclass
        cc allocation allotment cc class.template !
        cc >super template cc template cc >super allocation move
        cc allocation cc class.templateSize !  \ support extensions
        cc dup template class!  \ set the template's class, v. important
    else
        \ create a new template copied from the current one.  (for when extending classes)
        cc template 
            cc allocation allotment cc class.template !
            ( template ) cc template cc class.templateSize @ move
        cc allocation cc class.templateSize !
    then
;

: end-class
    /template
    cc each> cc >r to cc recurse r> to cc
;


( Root Metaclass )

create <class>  %class old-sizeof /allot  <class> to cc  /cc
    cc cc class!
    %class old-sizeof dup cc class.size !  cc class.templateSize !
    cc cc class.template !
    cc class>offsetTable  1024  $80000000  ifill
    ' noop cc class.constructor !
    ' noop cc class.destructor !
    cc class.isMeta on

( Root class )

create object-template 0 ,

create <object> %class old-sizeof /allot  <object> to cc  /cc
    <class> <object> class!
    1 cells cc class.size !  \ account for the class field
    object-template cc class.template !
    cc class>offsetTable  1024  $80000000  ifill
    ' noop cc class.constructor !
    ' noop cc class.destructor !

<object> object-template class!



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
    >fields each> ( adr object, field, - adr )
        normal         
        dup field.superfield @ body> >name count type space
        bright
        2dup dup field.size @ swap field.inspector @ execute
        field.size @ +   \ go to next field in the passed instance
;

: peek  ( object - )
    dup >class .name 
    dup >class  dup >fields dup length if node.first @ field.offset @ u+ ( skip any collection stuff )
                                       else drop then
        (peek) drop normal ;

: extend-class ( - <name> )
    ' >body to cc 
;

( Utils )
: .me   me peek ;
: .class  >fields each> dup field.superfield @ .name   field.offset @ i.  cr ;

variable lev
: indent>  cr lev @ 1i spaces  3 lev +!   r> call    -3 lev +!  ;
: .classtree  each> indent> dup .name dup length if recurse else drop then ;

( TEST )

marker dispose
: test  not abort" Super Objects unit test fail" ;

<node> isMeta? 0= test

<node> class <fdsa>
    var en
    var x
    var y
    var flags
end-class

( test basic class stuff: )
<fdsa> isMeta? 0= test
<fdsa> >class isMeta? test
<fdsa> template >class <fdsa> = test

( test that <FDSA>'s offset table is right: )
<fdsa> >offsetTable @ $80000000 <> test
<fdsa> >offsetTable cell+ @ $80000000 <> test
<fdsa> >offsetTable cell+ cell+ @ $80000000 <> test
<fdsa> >offsetTable cell+ cell+ cell+ @ $80000000 <> test

( test templates and overloaded fields: )
200 200 <fdsa> template 's x 2!

<node> class <asdf>
    var x
    var y
end-class

100 100 <asdf> template 's x 2!

create ako <fdsa> static
create bko <asdf> static

ako >{ x @ 200 = } test
ako 's x @ 200 = test
bko >{ x @ 100 = } test
bko 's x @ 100 = test

<fdsa> :: test ." hi" ;
<fdsa> :pub ok test ;

<fdsa> class <sub>
end-class

( test EXTEND-CLASS: )
extend-class <fdsa>
    var blah
end-class

20 <fdsa> template 's blah !

<fdsa> dynamic
    me >class <fdsa> = test
    blah @ 20 = test
    me peek
me destroy

( test that the field defined in the extension propogated: )
123 <sub> template 's blah !
<sub> dynamic
    blah @ 123 = test 
me destroy

\ undo everything added above ...
<node> 0node
<object> 0node

( test that 0NODE worked: )
<node> length 0= test
<object> node.first @ 0= test

dispose
