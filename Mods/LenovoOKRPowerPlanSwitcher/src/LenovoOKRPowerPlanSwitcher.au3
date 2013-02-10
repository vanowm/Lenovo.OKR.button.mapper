#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_LegalCopyright=V@no
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Field=Description|Lenovo OKR (Novo) button power plan switcher installer
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <ListviewConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>

Const $version = "1.0"
$dir = @ScriptDir & "\"
If @ScriptName <> "OneKey Recovery.exe" Then $dir &= "OneKey Recovery\"
$iniFile = $dir & "settings.ini"

$exit = False
$saved = IniRead($iniFile, "General", "id", "")
$last = IniRead($iniFile, "General", "last", "")
$selected = $saved
$match = False
$matchLast = False
$current = False
$list = getList()

Func getList()
	Dim $l[1]
	$i = 100
	Local $line = ""
	Local $foo = Run(@ComSpec & " /c powercfg -list", @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	Do
		$line &= StdoutRead($foo)
		If @error Then ExitLoop
		Sleep(100)
		$p = ProcessExists($foo)
		If Not $p Then $i -= 1
	Until Not $i
	$data = StringSplit($line, @CRLF, 1)
	$i = 0
	For $n = 0 To $data[0]

		$line = StringRegExp($data[$n], "([0-9a-zA-Z\-]{36})\s+\(([^\}]+)\)(\s+\*)?", 1)

		If NOT UBound($line) Then ContinueLoop
		If UBound($line) < 4 Then
			ReDim $line[4]
			$line[3] = Binary("")
		EndIf
		If $line[2] Then $current = $i
		$array = $line
		If UBound($l) < $i + 1 Then ReDim $l[$i+1]
		$l[$i] = $line
		If $line[0] = $saved Then $match = $i
		If $line[0] = $last Then $matchLast = $i
		$i += 1
	Next
	Return $l
EndFunc

Func compareArray($a, $b)
	If UBound($a) <> UBound($b) Then Return False
	If Not IsArray($a) Or Not IsArray($b) Then Return $a = $b
	$e = UBound($a) - 1
	For $i = 0 To $e
		If Not IsArray($a[$i]) Or Not IsArray($b[$i]) Then
			If $a[$i] <> $b[$i] And VarGetType($a[$i]) <> "Binary" Then Return False
		Else
			If Not compareArray($a[$i], $b[$i]) Then Return False
		EndIf
	Next
	Return True
EndFunc

$starter = _ProcessIdPath(_ProcessGetParent(@AutoItPID))
If StringInStr($starter, "\Lenovo\Energy Management\utility.exe") Then
	If $match = False OR ($match == $matchLast AND $match == $current) OR $current == False OR ($match == $current AND $matchLast == False) Then Exit
	$lm = $list[$match]
	$lml = $list[$matchLast]
	$lc = $list[$current]
	$id = $lm[0]
	If $current <> $match Then
		IniWrite($iniFile, "General", "last", $lc[0])
		$id = $lm[0]
	Else
		$id = $lml[0]
	EndIf
	Run("powercfg -setactive " & $id, @SystemDir, @SW_HIDE)
	Exit
EndIf

If @OSArch = "X86" Then
	$reg = RegRead("HKLM\SOFTWARE\Lenovo\OneKey App\OneKey Recovery", "InstallPath")
Else
	$reg = RegRead("HKLM64\SOFTWARE\Wow6432Node\Lenovo\OneKey App\OneKey Recovery", "InstallPath")
EndIf
$isAdmin = IsAdmin()
$isReg = $reg = $dir
$file = $dir & "OneKey Recovery.exe"
$isFile = FileExists($file) And FileGetVersion($file) = FileGetVersion(@ScriptFullPath)
If (Not $isReg Or Not $isFile) And Not $isAdmin Then
	ShellExecute(@ScriptName, "", "", "runas")
	Exit
EndIf

Opt("GUIOnEventMode", 1)

$width = 400
$height = 250
$gui = GUICreate("Lenovo OKR power plan switcher v" & $version, $width, $height)
GUISetOnEvent($GUI_EVENT_CLOSE, "_exit")
;Opt("GUICoordMode", 1)
GUICtrlCreateLabel("Select a power plan", 0, 5, $width, 25, $SS_CENTER)
GUICtrlSetFont(-1, 12, 700)
$listHeight = $height-120
$header = "                                                                                                                       "
$guiList = GUICtrlCreateListView($header, 10, 25, $width-20, $listHeight, BitOR($LVS_NOCOLUMNHEADER, $LVS_NOSORTHEADER, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS, $LVS_NOLABELWRAP, $LVS_REPORT, 0x00800000), BitOR($LVS_EX_SNAPTOGRID, $LVS_EX_FULLROWSELECT))
$hListView = GUICtrlGetHandle($guiList)
GUICtrlSendMsg(-1,$LVM_SETCOLUMNWIDTH, 0,$width-27)
GUICtrlCreateLabel("* currently active    ☺ saved", 12, $listHeight+30)
GUICtrlSetFont(-1, -1, -1, 2)
GUICtrlCreateLabel("OKR button will switch between selected plan and currently active", 12, $listHeight+50, $width-24)
GUICtrlSetFont(-1, -1, -1, 2)
;$label = GUICtrlCreateLabel("a", 12, $listHeight+65, $width-24, 100)

$btnApply = GUICtrlCreateButton("Apply", $width - 190, $height-40, 60, 30)
GUICtrlSetOnEvent(-1, "apply")
$btnSave = GUICtrlCreateButton("Save", $width - 130, $height-40, 60, 30)
GUICtrlSetOnEvent(-1, "save")
$btnCancel = GUICtrlCreateButton("Cancel", $width - 70, $height-40, 60, 30)
GUICtrlSetOnEvent(-1, "_exit")

Dim $listGui[1]
$list = updateList($list)
selected()
GUISetState(@SW_SHOW)

$fChange = false

GUIRegisterMsg($WM_NOTIFY, "_WM_NOTIFY")
Func _WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)

    #forceref $hWnd, $iMsg, $wParam

    $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
    $iCode = DllStructGetData($tNMHDR, "Code")
    Switch $hWndFrom
		Case $hListView
            Switch $iCode
                Case $LVN_ITEMCHANGING
                    $fChange = True
            EndSwitch
    EndSwitch

EndFunc
While 1
	Sleep(100)
	$msg = GUIGetMsg()
	if $fChange Then selected()
	If $exit Then _exit()
	$l = getList()
;	count($powercfg)
	If isArray($l) AND Not compareArray($l, $list) Then
		$list = updateList($l)
		$l = $list[1]
	EndIf
WEnd

Func updateList($l)
	$e = UBound($l) - 1
	$n = _GUICtrlListView_GetItemCount($guiList)
	$s = False
	For $i = 0 To $e
		$a = $l[$i]
		If Not IsArray($a) Then Return False
		$text = "" & $a[1]
		$append = " "
		If $a[0] = $saved Then
			$append = ""
			$text = "☺ " & $text
		EndIf
		If $a[2] <> "" Then
	;		$text &= " *"
			$text = "*" & $append & $text
		EndIf

		If UBound($listGui) < $i + 1 Then ReDim $listGui[$i+1]
		If $i >= $n Then
			$a[3] = GUICtrlCreateListViewItem($text, $guiList)
			GUICtrlSetPos(-1, -1, -1, $width)
;			GUICtrlSetOnEvent(-1, "selected")
;			_GUICtrlListView_SetCallBackMask($guiList, 8)
		Else
			_GUICtrlListView_SetItemText($guiList, $i, $text)
		EndIf
		$l[$i] = $a
		_GUICtrlListView_SetItemSelected($guiList, $i, $a[0] = $selected)
		If $a[0] = $selected Then
			_GUICtrlListView_EnsureVisible($guiList, $i)
			$s = True
		EndIf
	Next
	If Not $s Then $selected = ''
	If $n > $e + 1 Then
		For $i = $e + 1 To $n - 1
			_GUICtrlListView_DeleteItem($guiList, $i)
		Next
	EndIf
	If _GUICtrlListView_GetSelectedIndices($guiList) = '' Then
		_GUICtrlListView_SetItemSelected($guiList, $e)
		_GUICtrlListView_SetItemSelected($guiList, $e, False)
	EndIf
	Return $l
EndFunc

Func selected()
	$s = _GUICtrlListView_GetSelectedIndices($guiList)
	If $s = "" Then
		Dim $l[2]
	Else
		$l = $list[$s]
	EndIf
	If Not $selected Or ($selected And $isFile And $isReg And $l[0] = $saved) Then
		GUICtrlSetState($btnApply, $GUI_DISABLE)
		GUICtrlSetState($btnSave, $GUI_DISABLE)
	Else
		GUICtrlSetState($btnApply, $GUI_ENABLE)
		GUICtrlSetState($btnSave, $GUI_ENABLE)
	EndIf
	$selected = $l[0]
EndFunc

Func apply()
	If Not $selected Then Return
	selected()
	If NOT $isFile Then
		$isFile = FileCopy(@ScriptFullPath, $dir & "OneKey Recovery.exe", 9)
		If Not $isFile Then MsgBox(4096+48, "Error", "Unable save file into " & $dir & @CRLF & "Please check directory permissions")
	EndIf
	IniWrite($iniFile, "General", "id", $selected)
	$saved = $selected
	If $isFile And Not $isReg Then
		If @OSArch = "X86" Then
			$isReg = RegWrite("HKLM\SOFTWARE\Lenovo\OneKey App\OneKey Recovery", "InstallPath", "REG_SZ", $dir)
		Else
			$isReg = RegWrite("HKLM64\SOFTWARE\Wow6432Node\Lenovo\OneKey App\OneKey Recovery", "InstallPath", "REG_SZ", $dir)
		EndIf
	EndIf
	$list = updateList($list)
	selected()
EndFunc

Func save()
	apply()
	_exit()
EndFunc

Func listFind($id)
	$e = UBound($list) - 1
	For $i = 0 To $e
		$l = $list[$i]
		If $id = $l[3] Then
			Return $i
		EndIf
	Next
	Return 0
EndFunc

Func _exit()
	$exit = True
	Exit
EndFunc


Func _ProcessGetParent($i_pid)
	Local Const $TH32CS_SNAPPROCESS = 0x00000002

	Local $a_tool_help = DllCall("Kernel32.dll", "long", "CreateToolhelp32Snapshot", "int", $TH32CS_SNAPPROCESS, "int", 0)
	If IsArray($a_tool_help) = 0 Or $a_tool_help[0] = -1 Then Return SetError(1, 0, $i_pid)

	Local $tagPROCESSENTRY32 = _
			DllStructCreate _
			( _
			"dword dwsize;" & _
			"dword cntUsage;" & _
			"dword th32ProcessID;" & _
			"uint th32DefaultHeapID;" & _
			"dword th32ModuleID;" & _
			"dword cntThreads;" & _
			"dword th32ParentProcessID;" & _
			"long pcPriClassBase;" & _
			"dword dwFlags;" & _
			"char szExeFile[260]" _
			)
	DllStructSetData($tagPROCESSENTRY32, 1, DllStructGetSize($tagPROCESSENTRY32))

	Local $p_PROCESSENTRY32 = DllStructGetPtr($tagPROCESSENTRY32)

	Local $a_pfirst = DllCall("Kernel32.dll", "int", "Process32First", "long", $a_tool_help[0], "ptr", $p_PROCESSENTRY32)
	If IsArray($a_pfirst) = 0 Then Return SetError(2, 0, $i_pid)

	Local $a_pnext, $i_return = 0
	If DllStructGetData($tagPROCESSENTRY32, "th32ProcessID") = $i_pid Then
		$i_return = DllStructGetData($tagPROCESSENTRY32, "th32ParentProcessID")
		DllCall("Kernel32.dll", "int", "CloseHandle", "long", $a_tool_help[0])
		If $i_return Then Return $i_return
		Return $i_pid
	EndIf

	While 1
		$a_pnext = DllCall("Kernel32.dll", "int", "Process32Next", "long", $a_tool_help[0], "ptr", $p_PROCESSENTRY32)
		If IsArray($a_pnext) And $a_pnext[0] = 0 Then ExitLoop
		If DllStructGetData($tagPROCESSENTRY32, "th32ProcessID") = $i_pid Then
			$i_return = DllStructGetData($tagPROCESSENTRY32, "th32ParentProcessID")
			If $i_return Then ExitLoop
			$i_return = $i_pid
			ExitLoop
		EndIf
	WEnd

	If $i_return = "" Then $i_return = $i_pid

	DllCall("Kernel32.dll", "int", "CloseHandle", "long", $a_tool_help[0])
	Return $i_return
EndFunc   ;==>_ProcessGetParent

;===============================================================================
;
; Function Name:		_ProcessIdPath ()
; Description:			Returns the full path of a Process ID
; Parameter ( s ):		$vPID	- Process ID  (String or Integer)
; Requirement ( s ):	AutIt 3.1.1 (tested with version 3.1.1.107)
; Return Value ( s ):	On Success - Returns the full path of the PID Executeable
;						On Failure - returns a blank string
;						@ERROR = 1 - Process doesn't exist  ( ProcessExist ( $vPID ) =0 )
;						@ERROR = 2 - Path is unknown
;									 $objItem.ExecutablePath=0
;												AND
;									 @SystemDir\$objItem.Caption doesn't exist
;						@ERROR = 3 - Process Not Found  ( in WMI )
;						@ERROR = 4 - WMI Object couldn't be created
;						@ERROR = 5 - Unknown Error
; Author:				JerryD
;
;===============================================================================
;
Func _ProcessIdPath($vPID)
	Local $objWMIService, $oColItems
	Local $sNoExePath = ''
	Local Const $wbemFlagReturnImmediately = 0x10
	Local Const $wbemFlagForwardOnly = 0x20

	Local $RetErr_ProcessDoesntExist = 1
	Local $RetErr_ProcessPathUnknown = 2
	Local $RetErr_ProcessNotFound = 3
	Local $RetErr_ObjCreateErr = 4
	Local $RetErr_UnknownErr = 5

	If Not ProcessExists($vPID) Then
		SetError($RetErr_ProcessDoesntExist)
		Return $sNoExePath
	EndIf

	$objWMIService = ObjGet('winmgmts:\\localhost\root\CIMV2')
	$oColItems = $objWMIService.ExecQuery('SELECT * FROM Win32_Process', 'WQL', $wbemFlagReturnImmediately + $wbemFlagForwardOnly)

	If IsObj($oColItems) Then
		For $objItem In $oColItems
			If $vPID = $objItem.ProcessId Then
				If $objItem.ExecutablePath = '0' Then
					If FileExists(@SystemDir & '\' & $objItem.Caption) Then
						Return @SystemDir & '\' & $objItem.Caption
					Else
						SetError($RetErr_ProcessPathUnknown)
						Return $sNoExePath
					EndIf
				Else
					Return $objItem.ExecutablePath
				EndIf
			EndIf
		Next
		SetError($RetErr_ProcessNotFound)
		Return $sNoExePath
	Else
		SetError($RetErr_ObjCreateErr)
		Return $sNoExePath
	EndIf

	SetError($RetErr_UnknownErr)
	Return $sNoExePath
EndFunc   ;==>_ProcessIdPath

Func _ReparsePoint($string)
    Local $FILE_ATTRIBUTE_REPARSE_POINT = 0x400
    If Not FileExists($string) Then
        Return SetError(1, 0, '')
    EndIf
    $rc = DllCall('kernel32.dll', 'Int', 'GetFileAttributes', 'str', $string)
    If IsArray($rc) Then
        If BitAND($rc[0], $FILE_ATTRIBUTE_REPARSE_POINT) = $FILE_ATTRIBUTE_REPARSE_POINT Then
            Return True
        EndIf
    EndIf
    Return False
EndFunc