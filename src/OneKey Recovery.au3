#NoTrayIcon

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=V@no
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_Field=Description|Simple launcher that executes file from RunFile.ini
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; This is launcher. It must be compilled first into OneKey Recovery.exe before compilling installer

$file = IniRead("RunFile.ini", "General", "file", False)
$param = IniRead("RunFile.ini", "General", "param", "")
If $file Then
	ShellExecute($file, $param, StringLeft($file, StringInStr($file, "\", 1, -1)))
EndIf