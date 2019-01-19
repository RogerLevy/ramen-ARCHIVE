( Super objects! )
\ An extension for high-level programming.
\ [x] - Templates
\ [x] - Two kinds of allocation - dictionary (static) and heap (dynamic)
\ [x] - Smart fields - different classes' fields can reuse names and you can check for field ownership on a class basis.
\ [x] - Private words
\ [ ] - Constructors and destructors, plus the ability to call superclass constructors/destructors? 
\ [ ] - Automatic construction/destruction of embedded objects, such as collections
\ [ ] - Inspection
\ [ ] - Inheritance 

\ TODO:
\ [ ] - CLASS: copy all field instances and add them, plus the offset table
\ [ ] - Make venery use this so we can subclass from collections
\ [x] - Initialize offset tables with high offsets intended to cause segfaults
\ [ ] - >{ { }
\ [ ] - DESTROY: call destructor
\ [ ] - /OBJECT: call constructor
\ [ ] - Pool allocation (problem: objects aren't all nodes!!! what do?? maybe just custom build for actors)

0 value me
0 value offsetTable
0 value cc \ current Class
0 value nextOffsetSlot \ next offset in offset table
0 value lastFieldInstance \ last field instance

: ?literal  state @ if postpone literal then ;

also venery

    struct %class
        %class %node sembed class>node
        %class 128 cells sfield class>offsetTable
        %class svar class.size
        %class svar class.wordlist
        %class svar class.template
        %class svar class.super
        %class %node sembed class>pool  \ optional
        %class svar class.useHeap

    struct %superfield
        %superfield svar superfield.offset
    
    struct %field
        %field %node sembed superfield>node
        %field svar field.inspector
        \ constructor
        \ destructor

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
: ?converse
    me -exit state @ 0= if me >class converse then
;
: ?-converse
    me -exit state @ 0= if me >class -converse then
;

: as  ( ?-converse )  dup to me  >class >offsetTable to offsetTable  ( ?converse ) ;

: add-field  ( field class - )  push ;

: does-superfield
    immediate does> @ ?literal s" offsetTable + @ me +" evaluate 
;

: 's
    s" dup >class >offsetTable" evaluate ' >body @ ?literal s" + @ +" evaluate
; immediate

: field-exists  >in @ defined if >body cell+ @ $12345678 = else drop 0 then swap >in ! ;

: create-superfield  ( size - <name> )
    field-exists not if
        ( not defined; define the superfield word )
        >in @ create >in !
        nextOffsetSlot , $12345678 , does-superfield
        cell +to nextOffsetSlot
    then
    
    \ ?already  \ can only define once per class
    
    cc sizeof
        cc class>offsetTable
            ' >body @ ( the offset slot ) + !
        
    ( size ) cc class.size +!
    
    ( create the field instance, for great justice )
    %field old-sizeof allotment >r
        r@ to lastFieldInstance
        r@ /node
        r@ cc add-field
    r> drop
;

: /cc
    cc /node
    cc class>pool /node
    wordlist cc class.wordlist !
;

: class  ( superclass - <name> )
    create %class old-sizeof allotment to cc
    /cc
    cc class.super !
    cc >super sizeof cc class.size !
    cc class>offsetTable  128  $80000000  ifill
    \ TODO: need to copy all field instances and add them, plus the offset table
    \ cc >super class>offsetTable 
;

: /template
    cc sizeof allotment cc class.template !
    cc >super class.template @ cc class.template @ cc >super sizeof move
    cc dup class.template @ !  \ set the template's class, v. important
;

: end-class
    /template
;

: /object  ( class - )
    dup template me rot sizeof move
;

: static  here as  dup sizeof allot  /object ;

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
    as /object
;

: destroy  ( object - )
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



( TEST )

: var  cell create-superfield ;

<object> class <actor>
    var en
    var flags
    var x
    var y
end-class

<object> class <particle>
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