REM ( ) innebär att kommandona i detta kommer att läsas in och 
REM sedan exekveras därmed kommer vi kunna utföra shutdown efter att vi tagit bort oss själva :)
(
rmdir /S /Q C:\setup\
rmdir /S /Q C:\Windows\T2
shutdown /f /r /t 0
)