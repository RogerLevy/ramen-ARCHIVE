0 value lastRole \ used by map loaders (when loading objects scripts)
variable nextid

0  4 kb  class <role>
end-class

<node> sizeof  #1024  class <actor>
    var role <body
    var id 
    var en <hex
    var hidden <flag
    var marked <flag \ for deletion
    var x  var y  var vx  var vy
    var drw <adr
    var beha <adr
end-class
:noname me /node ; <actor> class.constructor !

: basis <actor> prototype ;  \ default rolevar and action values for all newly created roles

<actor> prototype as
    en on

create objlists  <node> static            \ parent of all objlists

: >first  ( node - node|0 ) node.first @ ;
: >last   ( node - node|0 ) node.last @ ;
: >parent  ( node - node|0 ) node.parent @ ;
: !id  1 nextid +!  nextid @ id ! ;
: init  ( - )  !id ;
: one ( parent - me=obj )  <actor> dynamic  me swap push  init  at@ x 2! ;
: ?remove  ( obj - ) dup >parent dup if remove else drop drop then ;
: dismiss ( - ) marked on ;
: dynamic?  ( - flag ) en @ #1 and ;
\ :noname  pool length 0= if here object, else pool pop then ; is new-node
\ :noname  >{ en @ $fffffffe <> if me pool push else me ?remove then } ; is free-node
' destroy is free-node

\ making stuff move and displaying them
: ?call  ( adr - ) ?dup -exit call ;
: draw   ( - ) en @ -exit  hidden @ ?exit  x 2@ at  drw @ ?call ;
: draws  ( objlist ) each> as draw ;
: act   ( - ) en @ -exit  beha @ ?call ;
: sweep ( objlist ) each> as marked @ -exit marked off id off me free-node ;
: acts  ( objlist ) each> as act ;
: draw>  ( - <code> ) r> drw ! hidden off ;
: act>   ( - <code> ) r> beha ! ;
: away  ( obj x y - ) rot 's x 2@ 2+ at ;
: -act  ( - ) act> noop ;
: objlist  ( - <name> )  create <node> static me objlists push ;

( stage )
objlist stage  \ default object list
: /stage  stage vacate  0 nextid ! ;

( static actors )
: actor   ( class parent - )  swap static  me swap push  init  $fffffffe en ! ;

( role fields )
: role@  ( - role )
    me >class dup 0= abort" Error: Role is null." ;
    
: rolefield>ofs  ( rolefield - offset )
    @ <role> >offsetTable + @ ;

: role's  ( - <field> adr )
    s" role@" evaluate ' >body rolefield>ofs ?literal s" +" evaluate
; immediate

( actions )
: is-action?  field.attributes @ ;

: action   ( - <name> ) ( ??? - ??? )
    var <adr
    true lastField field.attributes ! 
    does>  rolefield>ofs role@ + @ execute ;    

: :to   ( roledef - <name> ... )
    ' >body rolefield>ofs + :noname swap ! ;

: +exec  + @ execute ;

: ->  ( roledef - <action> )
    ' >body rolefield>ofs ?literal  s" +exec" evaluate ; immediate

( create role )
: ?update  ( - <name> )
    >in @
    defined if  >body to lastRole  r> drop drop ;then
    >in ! ;

: create-role  ( - <name> )
    ?update  create  <role> static
    me to lastRole
    ['] is-action? <role> >fields some>
        :noname swap
            rolefield>ofs
            dup basis + postpone literal s" @ ?execute ; " evaluate  \ compile "bridge" code
            lastRole + !  \ assign our "bridge" to the corresponding action    
;


( inspection )
: .role  ( obj - )
    >class ?dup if peek else ." No role" then ;

: .objlist  ( objlist - )
    dup length 1i i. each>
        >{  cr me h. ." ID: " id ?  ."  X/Y: " x 2?  } ;

