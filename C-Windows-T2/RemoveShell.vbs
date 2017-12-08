Dim WinScriptHost
Set WinScriptHost = CreateObject("WScript.Shell")
WinScriptHost.Run Chr(34) & "C:\Windows\T2\RemoveShell.cmd" & Chr(34), 0
Set WinScriptHost = Nothing