( Super objects! )
\ An extension on structs for high-level programming.
\ - Templates
\ - Three kinds of allocation - static, pool-based, and heap
\ - Constructors and destructors
\ - Automatic construction/destruction of embedded objects, such as collections
\ - Smart fields - different classes' fields can reuse names and you can check for field ownership on a class basis.
\ - Private words
\ - NO inheritance!
\ - NO methods/polymorphism!

0 value me
0 value offsetTable
0 value currentClass

: >class s" @" evaluate ; immediate
: >offsetTable  s" >class @" evaluate ; immediate
: as  dup to me  >offsetTable to offsetTable  ( ?tongue ) ;
: >field  ( ofs - adr )  s" offsetTable + @ me +" evaluate ; immediate

: create-superfield  ( size - <name> )
    ?already  \ can only define once per class
;

: class ;
: end-class ;

: :private ( class - <name> <code> ; )
;

: :public ( class - <name> <code> ; )
;
