\ fat pixels and subscreens

depend ramen/draw.f
nativewh canvas: canv
create tempres  0 , 0 ,

: (size)  viewwh canv resize-canvas ;
: (upscale)  ( code - ) canv >bmp onto>  black 0 alpha backdrop  unmount  call ;
: upscaled  ( xt - )  >code  (size)  (upscale) ;
: ?blit>  ( xt xt - )
    catch dup if display onto 2d 0 0 at then
    r> call  mount canv >bmp blit  throw ;
: upscale>  ( - <code> )  r> code> ['] upscaled ?blit> noop ;
: subscreen>  ( w h - )
        res 2@ tempres 2! 
        2i res 2! 
    r> code> ['] upscaled ?blit> tempres 2@ res 2! ;
