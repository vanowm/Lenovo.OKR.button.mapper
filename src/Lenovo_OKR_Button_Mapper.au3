#NoTrayIcon
#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=V@no
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_Field=Description|launcher installer that will launch user selected program when pressed OKR (Novo) button on Lenovo laptops
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; This is launcher installer

$dir = @TempDir & "\OneKey Recovery\"
If NOT FileExists($dir) Then DirCreate($dir)
FileInstall("OneKey Recovery.exe", $dir, 1)

While 1
	$file = FileOpenDialog("Select file that will be opened by the OKR (Nova) Button", "", "Executables (*.exe;*.bat;*.vbs)|All files (*.*)")
	If @error Then Exit

	If NOT FileExists($file) OR $file = $dir & "OneKey Recovery.exe" Then ContinueLoop

	$param = InputBox("Parameters (optional)", "Input additional parameters for this file." & @CRLF & "You can leave it blank")

	IniWrite($dir & "RunFile.ini", "General", "file", $file)
	IniWrite($dir & "RunFile.ini", "General", "param", $param)
	RegWrite("HKLM\SOFTWARE\Lenovo\OneKey App\OneKey Recovery", "InstallPath", "REG_SZ", $dir)
	RegWrite("HKLM64\SOFTWARE\Wow6432Node\Lenovo\OneKey App\OneKey Recovery", "InstallPath", "REG_SZ", $dir)

	MsgBox(0, "Done.", "Launcher successfully installed in " & @CRLF & $dir)
	Exit
WEnd

