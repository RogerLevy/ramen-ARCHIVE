[defined] roledef-size [if] roledef-size [else] 4 kb [then] constant /roledef

variable lastrole \ used by map loaders (when loading objects scripts)
variable nextid
struct %role
<node> class <actor>
    var id  \ don't move this (?)
    var en <hex  var hidden <flag  
    var x  var y  var vx  var vy
    var drw <adr  var beha <adr
    var marked <flag \ for deletion
    var role <adr
end-class
create basis /roledef /allot  \ default rolevar and action values for all newly created roles
variable redef \ for rolevars and actions

<actor> template as
    en on
    basis role !

\ create pool  <node> static            \ where we cache free objects
create root  <node> static            \ parent of all objlists

: >first  ( node - node|0 ) node.first @ ;
: >last   ( node - node|0 ) node.last @ ;
: >parent  ( node - node|0 ) node.parent @ ;
: !id  1 nextid +!  nextid @ id ! ;
: init  ( - )  !id ;
: one ( parent class - me=obj ) dynamic  init me swap push at@ x 2! ;
: objects  ( parent n - ) for dup one loop drop ;
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

\ static objects
: object   ( class - ) static me stage push init $fffffffe en ! ;

\ Roles
\ Note that role vars are global and not tied to any specific role.
\ also, note that DERIVE defaults all actions to call the BASIS's current definition
\ indirectly, so it can be changed anytime.
: ?update  ( - <name> )  >in @  defined if  >body lastrole !  drop r> drop exit then  drop >in ! ;
: >magic  ( adr - n ) %field sizeof + @ ;
: ?unique  ( size - size | <cancel caller> )
    redef @ ?exit
    >in @
        bl word find  if
            >body dup >r >magic $76543210 =  if
                r> to lastfield
                r> drop  ( value of >IN ) drop  ( size ) drop  exit
            else
                r> ( body ) drop
            then
        else
            ( addr ) drop
        then
    >in ! ;
: role@  ( - role ) role @ dup 0= abort" Error: Role is null." ;
: create-rolefield  ( size - <name> ) %role swap create-field $76543210 , 0 , ;
: rolefield  ( size - <name> ) ?unique create-rolefield  does> field.offset @ role@ + ;
: rolevar  ( - <name> ) 0 ?unique drop  cell create-rolefield  does> field.offset @ role@ + ;
: is-action?  %field sizeof + cell+ @ ;
: ?execute  dup if execute ;then drop ;
: action   ( - <name> ) ( ??? - ??? )
    0 ?unique drop  cell create-rolefield  true here cell- ! <adr
    does> field.offset @ role@ + @ ?execute ;
: :to   ( roledef - <name> ... )  ' >body field.offset @ + :noname swap ! ;
: +exec  + @ execute ;
: ->  ( roledef - <action> )
    ' >body field.offset @ postpone literal postpone +exec ; immediate

:slang relate
    here locals| child |
    basis /roledef move,
    ['] is-action? %role some>
        :noname swap
        field.offset @ 
        dup basis + postpone literal s" @ ?execute ; " evaluate  \ compile "bridge"
        child + !  \ assign our "bridge" to the corresponding action
;
: defrole  ( - <name> ) ?update  create  here lastrole !  relate ;



\ Inspection
: .role  ( obj - )  's role @ ?dup if %role .fields else ." No role" then ;
: .objlist  ( objlist - )  dup length . each> >{  cr ." ID: " id ?  ."  X/Y: " x 2?  } ;