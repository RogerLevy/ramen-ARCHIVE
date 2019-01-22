( Minimal library set )
\ pretty similar to the standard set,
\ but omits Tiled support, collision grid, tilemap rendering, and some animation words, and adds a.f

depend ramen/lib/std/rangetools.f  cr .( Loaded rangetools module. ) \ "
depend ramen/lib/std/task.f        cr .( Loaded task module. ) \ "
depend ramen/lib/std/zsort.f       cr .( Loaded zsort module. ) \ "
depend ramen/lib/std/v2d.f         cr .( Loaded vector2d module. ) \ "
depend ramen/lib/std/kb.f          cr .( Loaded keyboard lex. ) \ "
depend ramen/lib/std/audio1.f      cr .( Loaded audio module. ) \ "
depend ramen/lib/std/sprites.f     cr .( Loaded sprites module. ) \ "
depend ramen/lib/min/tile.f        cr .( Loaded tile module. ) \ "
depend ramen/lib/std/collision.f   cr .( Loaded tilemap collision module. ) \ "
depend ramen/lib/array2d.f
depend ramen/lib/buffer2d.f

: think  stage acts stage multi ;
: physics  stage each> as vx 2@ x 2+! ;
: default-step  step> think physics stage sweep ;

cr .( Finished loading Minimal pack. ) \ "