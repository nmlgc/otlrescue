@echo off

poasm 1>NUL 2>NUL
if errorlevel 9009 goto no_pellesc

polink 1>NUL 2>NUL
if errorlevel 9009 goto no_pellesc

poasm otlrescue.asm && polink /ENTRY:main /SUBSYSTEM:console /DEFAULTLIB:kernel32.lib user32.lib shell32.lib otlrescue.obj
goto eof

:no_pellesc
echo This build script must be run from the Pelles C environment.
echo (Pelles C can be downloaded from http://www.smorgasbordet.com/pellesc/.)
:eof
