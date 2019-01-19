( Super objects! )
\ An extension for high-level programming.
\ [ ] - Templates
\ [ ] - Three kinds of allocation - static, pool-based, and heap
\ [ ] - Constructors and destructors
\ [ ] - Automatic construction/destruction of embedded objects, such as collections
\ [ ] - Smart fields - different classes' fields can reuse names and you can check for field ownership on a class basis.
\ [ ] - Private words
\ [ ] - Inspection
\ [ ] - Inheritance
\ [ ] - NO methods/polymorphism!  (To be implemented by the user)

0 value me
0 value offsetTable
0 value cc \ current Class
0 value nextOffsetSlot \ next offset in offset table

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
    

previous

: >template  class.template @ ;
: >super  class.super @ ;
: >wordlist  class.wordlist @ ;
: sizeof  class.size @ ;

: >class s" @" evaluate ; immediate
: size  >class sizeof ;

: converse  ( class - )
    dup 
    begin >super dup while recurse repeat drop
    >wordlist +order
;
: -converse  ( class - )
    dup 
    begin >super dup while recurse repeat drop
    >wordlist -order
;
: ?converse
    state @ 0= if me >class converse then
;
: ?-converse
    state @ 0= if me >class -converse then
;

: >offsetTable  s" >class class>offsetTable" evaluate ; immediate
: as  ?-converse  dup to me  >offsetTable to offsetTable  ?converse ;  \ TODO: optimize
: >field  ( ofs - adr )  s" offsetTable + @ me +" evaluate ; immediate

: add-field  ( field class - )  push ;

: does-superfield
    immediate does> @ ?literal " >field" evaluate 
;

: create-superfield  ( size - <name> )
    >in @ exists not if
        ( not defined; define the superfield word )
        create nextOffsetSlot , does-superfield
        cell +to nextOffsetSlot
    then
    >in !
    
    
    ( create the field instance )
    %field sizeof allotment >r
        r@ /node
        r@ cc add-field
        ( size ) +to nextOffset
    r> drop
    
    \ ?already  \ can only define once per class
    >in !  
;

: /cc
    cc /node
    cc class>pool /node
    wordlist cc class.wordlist !
;

: class  ( superclass - <name> )
    create %class sizeof allotment to cc
    /cc
    cc class.super !
    
    \ TODO: need to copy all field instances and add them, plus the offset table
    cc >super class>offsetTable 
;

: /template
    cc sizeof allotment cc class.template !
    cc >super class.template @ cc class.template @ cc >super sizeof move
;

: end-class
    /template
;

: init  ( class object - object )
;

: static  dup sizeof allotment init ;

: dynamic  ( class - object )
    dup class.useHeap @ if
        sizeof allocate throw
    else
        dup class>pool length if
            dup class>pool pop
        else
            dup sizeof allotment 
        then
        init
    then
;

: destroy
    \ destructor
    dup >class class.useHeap @ if
        free throw
    else
        dup >class class>pool push
    then
;


create <object> %class /allot  <object> to cc  /cc

<object> >wordlist +order definitions
    : ; postpone ; -converse ; immediate
previous definitions


: :pub ( class - <name> <code> ; )
    dup converse :
;

: :: ( class - <name> <code> ; )
    :pub definitions
;

