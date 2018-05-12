assetdef sample
    sample int svar sample.smp
    sample int svar sample.loop

: reload-sample  ( sample -- )
    >r  r@ srcfile count  findfile  zstring al_load_sample  r> sample.smp ! ;

: init-sample  ( looping adr c sample -- )
    >r  r@ srcfile place  r@ sample.loop !  ['] reload-sample r@ register
    r> reload-sample ;

: sample:  ( loopmode adr c -- <name> )
    create sample sizeof allotment init-sample ;

: >smp  sample.smp @ ;

