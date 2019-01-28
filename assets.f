\ Asset manager, "toolbox" version; includes standard synchronous loader

cell #256 + cell+ constant /assetheader
defer initdata ( - )

\ ------------------------------------------------------------------------------
\ Asset framework

create assets 1000 *stack drop
variable permanent   permanent on
variable permanents
: ?permanent  permanent @ -exit   nip ['] drop swap  1 permanents +! ;

: register ( reloader-xt unloader-xt asset - ) ?permanent  dup assets push  2! ;


\ structure:  reloader , unloader , filepath ... 
: reload  ( asset - )  ( asset - )  dup @ execute ;
: unload  ( asset - )  ( asset - )  dup cell+ @ execute ;
: srcfile ( - ) cell+ cell+ ;


: -assets ( - )  ['] unload assets each   permanents @ assets truncate ;


\ Note: Don't worry that the paths during development are absolute;
\ in publish.f, all asset paths are "normalized".
: findfile ( path c - path c )
    locals| c fn |
    fn c 2dup file-exists ?exit
    including -name #1 + 2swap strjoin 2dup file-exists ?exit
    true abort" File not found" ;

: defasset  ( - <name> )  struct  /assetheader lastbody struct.size ! ;
: .asset  ( asset - ) srcfile count dup if  type  else  2drop  then ;
: .assets  ( - ) assets each> cr .asset ;

: loadtrig  ( xt - )  here assets push   ,  ['] drop , ;

\ ------------------------------------------------------------------------------
\ Standard synchronous loader

:make initdata  each> reload ;
