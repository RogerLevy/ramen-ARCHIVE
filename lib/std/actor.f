0 value lastRole \ used by map loaders (when loading objects scripts)
variable nextid

0  4 kb  class _role
end-class

_node sizeof  #1024  class _actor
    var role <body
    var id 
    var en <hex
    var hidden <flag
    var marked <flag \ for deletion
    var x  var y  var vx  var vy
    var drw <adr
    var beha <adr
end-class
:noname me /node ; _actor class.constructor !

: basis _role prototype ;  \ default role-var and action values for all newly created roles

_actor prototype as
    en on

create objlists  _node static            \ parent of all objlists

: >first  ( node - node|0 ) node.first @ ;
: >last   ( node - node|0 ) node.last @ ;
: >parent  ( node - node|0 ) node.parent @ ;
: !id  1 nextid +!  nextid @ id ! ;
: init  ( - )  !id ;
: one ( parent - me=obj )  _actor dynamic  me swap push  init  at@ x 2! ;
: ?remove  ( obj - ) dup >parent dup if remove else drop drop then ;
: dismiss ( - ) marked on ;
: dynamic?  ( - flag ) en @ #1 and ;

:noname
    dup _actor is? not if  destroy ;then
    >{ en @ $fffffffe <> if  me ?remove  me destroy  else  me ?remove  then }
; is free-node

\ making stuff move and displaying them
: ?call  ( adr - ) ?dup -exit call ;
: draw   ( - ) en @ -exit  hidden @ ?exit  x 2@ at  drw @ ?call ;
: draws  ( objlist ) each> as draw ;
: act   ( - ) en @ -exit  beha @ ?call ;
: sweep ( objlist ) each> as marked @ -exit  marked off  id off  me free-node ;
: acts  ( objlist ) each> as act ;
: draw>  ( - <code> ) r> drw ! hidden off ;
: act>   ( - <code> ) r> beha ! ;
: away  ( obj x y - ) rot 's x 2@ 2+ at ;
: -act  ( - ) act> noop ;
: objlist  ( - <name> )  create _node static me objlists push ;

( stage )
objlist stage  \ default object list
: /stage  stage vacate  0 nextid ! ;

( static actors )
: actor,  ( parent - )  _actor static  me swap push  init  $fffffffe en ! ;
: actor   ( parent - <name> )  create  actor, ;

( role stuff )
: role@  ( - role )
    role @ dup 0= abort" Error: Role is null." ;

: role's  ( - <field> adr )
    s" role@" evaluate  ' >body _role superfield>offset ?literal s" +" evaluate
; immediate

( actions )
: is-action?  field.attributes @ ;

: action   ( - <name> ) ( ??? - ??? )
    _role fields:
    cell ?superfield <adr ( flag ) 
    true lastField field.attributes ! 
    -exit
    does>  _role superfield>offset role@ + @ execute ;    

: role-var  _role fields: var ;
: role-field  _role fields: field ;


: :to   ( roledef - <name> ... )
    postpone 's :noname swap ! ;

: ->  ( roledef - <action> )
    postpone 's s" @ execute" evaluate ; immediate

( create role )
: ?update  ( - <name> )
    >in @
    defined if  >body to lastRole  r> drop drop ;then
    drop
    >in ! ;

: create-role  ( - <name> )
    ?update  create  _role static
    me to lastRole
    ['] is-action? _role >fields some>
        :noname swap
            field.offset @
            dup basis + postpone literal s" @ execute ; " evaluate  \ compile "bridge" code
            lastRole + !  \ assign our "bridge" to the corresponding action    
;


( inspection )
: .role  ( obj - )
    >class ?dup if peek else ." No role" then ;

: .objlist  ( objlist - )
    dup length 1i i. each>
        >{  cr me h. ." ID: " id ?  ."  X/Y: " x 2?  } ;

