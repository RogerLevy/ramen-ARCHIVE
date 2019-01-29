REM params: <buildname> <main.f> <projectpath>
SETLOCAL

if %1=="" (
    SET buildname=build
) else (
    SET buildname=%1
)

md bin\%buildname%\data
del /s /q bin\%buildname%

@REM Don't remove this; Ramen needs these files to start
copy /y  ramen\ide\data\*.*  bin\%buildname%\data

if %3=="" (
    copy /y  data\*.*  bin\%buildname%\data
) else (
    copy /y  %3\data\*.*  bin\%buildname%\data
)
copy  afkit\dep\allegro5\5.2.3\*.dll  bin\%buildname%

if %2=="" (
    sf include main.f publish bin\%buildname%\%buildname%
) else (
    sf include %2 publish bin\%buildname%\%buildname%
)


