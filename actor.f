[defined] roledef-size [if] roledef-size [else] 4 kb [then] constant /roledef

variable lastRole \ used by map loaders (when loading objects scripts)
variable nextid
<object> class <role>
end-class

<node> class <actor>
    var id 
    var en <hex
    var hidden <flag  
    var x  var y  var vx  var vy
    var drw <adr
    var beha <adr
    var marked <flag \ for deletion
    var role <adr
end-class
create basis <role> static \ default rolevar and action values for all newly created roles
variable redef \ for rolevars and actions

<actor> template as
    en on
    basis role !

: var  cell create-superfield ;
: field  create-superfield ;

\ create pool  <node> static            \ where we cache free objects
create root  <node> static            \ parent of all objlists

: >first  ( node - node|0 ) node.first @ ;
: >last   ( node - node|0 ) node.last @ ;
: >parent  ( node - node|0 ) node.parent @ ;
: !id  1 nextid +!  nextid @ id ! ;
: init  ( - )  !id ;
: one ( class parent - me=obj )  swap dynamic  init me swap push  at@ x 2! ;
: actors  ( class parent n - ) { for 2dup one loop drop drop } ;
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
: objlist  ( - <name> )  create <node> static me root push ;

\ stage
objlist stage  \ default object list
\ : /pool   pool %node venery:sizeof erase  pool /node ;
: /stage  stage vacate  ( /pool )  0 nextid ! ;

\ static actors
: actor   ( class parent - )  swap static  me swap push  init  $fffffffe en ! ;

\ Roles
\ Note that role vars are global and not tied to any specific role.
\ also, note that DERIVE defaults all actions to call the BASIS's current definition
\ indirectly, so it can be changed anytime.
: ?update  ( - <name> )
    >in @
    defined if  >body to lastRole  drop r> drop  ;then  drop
    >in ! ;
: role@  ( - role ) role @ dup 0= abort" Error: Role is null." ;
: create-rolefield  ( size - <name> )  <role> define-fields  create-superfield 0 , ;
: rolefield  ( size - <name> ) create-rolefield  does> field.offset @ role@ + ;
: rolevar  ( - <name> )  cell rolefield ;
: is-action?  %field old-sizeof + @ ;
: ?execute  dup if execute ;then drop ;
: action   ( - <name> ) ( ??? - ??? )
    rolevar <adr true here cell- ! 
    does> field.offset @ role@ + @ ?execute ;
: :to   ( roledef - <name> ... )  ' >body field.offset @ + :noname swap ! ;
: +exec  + @ execute ;
: ->  ( roledef - <action> )
    ' >body field.offset @ postpone literal postpone +exec ; immediate

: role,
    here locals| child |
    basis /roledef move,
    ['] is-action? <role> some>
        :noname swap
        field.offset @ 
        dup basis + postpone literal s" @ ?execute ; " evaluate  \ compile "bridge"
        child + !  \ assign our "bridge" to the corresponding action
;
: defrole  ( - <name> ) ?update  create  here to lastRole  role, ;

\ Inspection
: .role  ( obj - )  's role @ ?dup if peek else ." No role" then ;
: .objlist  ( objlist - )  dup length 1i i. each> >{  cr ." ID: " id ?  ."  X/Y: " x 2?  } ;