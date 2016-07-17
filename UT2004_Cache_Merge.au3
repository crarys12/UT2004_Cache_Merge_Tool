; Author: Shawn Crary

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=UT2004.ico
#AutoIt3Wrapper_Compile_Both=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <FileConstants.au3>
#include <StringConstants.au3>
Global $foundUT = False

Dim $FolderName = @DesktopDir
FindUnrealShortcut($FolderName)

If $foundUT = False Then
	MsgBox(48, "UT2004 Cache Merge Utility by Shawn", "Sorry, I could not spot a shortcut to Unreal Tournament 2004 anywhere on or near your desktop.")
EndIf

Func FindUnrealShortcut($SourceFolder)
	Local $Search
	Local $File
	Local $FileAttributes
	Local $FullFilePath
	Local $foundShortcut = False

	$Search = FileFindFirstFile($SourceFolder & "\*.*")
	While ($foundShortcut = False)
		If $Search = -1 Then
			ExitLoop
		EndIf
		$File = FileFindNextFile($Search)
		If @error Then ExitLoop
		$FullFilePath = $SourceFolder & "\" & $File
		$FileAttributes = FileGetAttrib($FullFilePath)
		If StringInStr($FileAttributes, "D") Then
			FindUnrealShortcut($FullFilePath)
		Else
			If StringRight($FullFilePath, 4) = ".lnk" Then
				$foundShortcut = ProcessShortcut($FullFilePath)
				If $foundShortcut = True Then
					If $foundUT = False Then
						$foundUT = True
					EndIf
				EndIf
			EndIf
		EndIf
	WEnd
	FileClose($Search)
EndFunc   ;==>FindUnrealShortcut

Func ProcessShortcut($FullFilePath)
	Local $foundShortcut = False
	Local $cachePath = ""
	If ((StringInStr($FullFilePath, "unreal", 2) > 0) Or (StringInStr($FullFilePath, "ut", 2) > 0)) Then
		$shortcutInfo = FileGetShortcut($FullFilePath)
		$filename = _Filepath_To_Filename($shortcutInfo[0])
		If StringInStr($filename, "Unreal Anthology", 2) > 0 Then
			; UT2004\Cache
			$cachePath = _Filepath_To_Path($shortcutInfo[0]) & "UT2004\Cache"
			$foundShortcut = True
		ElseIf StringInStr($filename, "ut2004", 2) > 0 Then
			; ..\Cache
			$cachePath = _Filepath_To_Path(_Filepath_To_Path($shortcutInfo[0])) & "Cache"
			$foundShortcut = True
		EndIf
	EndIf

	If $foundShortcut Then
		moveUtCachedFiles($cachePath)
	EndIf

	Return $foundShortcut
EndFunc   ;==>ProcessShortcut

; C:\path\file.ext -> file.ext
Func _Filepath_To_Filename($fullpathname)
	Local $newName = ""
	Local $split = StringSplit($fullpathname, "\")
	If $split[0] > 1 Then
		If StringLen($split[$split[0]]) > 0 Then
			$newName = $split[$split[0]]
		Else
			If $split[0] > 2 Then
				$newName = $split[$split[0] - 1]
			EndIf
		EndIf
	Else
		$newName = $split[1]
	EndIf
	Return $newName
EndFunc   ;==>_Filepath_To_Filename

; C:\path\file.ext -> C:\path\
; C:\path1\path2\ -> C:\path1\
Func _Filepath_To_Path($fullpathname)
	Local $newName = ""
	Local $split = StringSplit($fullpathname, "\")
	Local $end = $split[0] - 1
	If $split[$split[0]] = "" Then
		$end = $split[0] - 2
	EndIf

	If $split[0] > 1 Then
		For $i = 1 To $end
			$newName &= $split[$i] & "\"
		Next
	EndIf

	Return $newName
EndFunc   ;==>_Filepath_To_Path

; case 1: _Get_Extension_From_Filename("file.ext") returns ".ext"
; case 2: _Get_Extension_From_Filename("file") returns ""
Func _Get_Extension_From_Filename($name) ; correct
	Local $ext = ""

	Local $dot = StringInStr($name, ".", 2, -1)
	If $dot > 0 Then
		$ext = StringRight($name, StringLen($name) - $dot + 1)
	EndIf

	Return $ext
EndFunc   ;==>_Get_Extension_From_Filename

Func moveUtCachedFiles($cachePath)
	If Not (StringRight($cachePath, 1) = "\") Then
		$cachePath &= "\"
	EndIf

	Local $ini = $cachePath & "cache.ini"
	Local $dictionary = [[".ukx", "Animations", 0, 0], [".ut2", "Maps", 0, 0], [".ogg", "Music", 0, 0], [".uax", "Sounds", 0, 0], [".usx", "StaticMeshes", 0, 0], [".utx", "Textures", 0, 0], [".u", "System", 0, 0]]
	Local $failedFiles = @CRLF & "The following files could not be moved: " & @CRLF
	Local $filesFailed = False
	Local $utPath = ""
	Local $iniSection = ""
	Local $dictionaryIndex = -1
	Local $outputFolder = ""
	Local $shouldCopy = False
	Local $source = ""
	Local $destination = ""
	Local $destinationExists = False
	Local $sourceExists = False
	Local $oldSize = 0
	Local $newSize = 0
	Local $addSize = 0
	Local $moved = 0
	Local $stringStats = ""
	Local $dicLength = 0

	If FileExists($ini) Then
		$utPath = _Filepath_To_Path($cachePath)
		$iniSection = iniReadSections($ini)

		If $iniSection[0][0] > 0 Then
			For $i = 1 To $iniSection[0][0]
				$dictionaryIndex = dictionary($dictionary, _Get_Extension_From_Filename($iniSection[$i][2]))
				If $dictionaryIndex > -1 Then ; only continue if output folder is known
					$outputFolder = $dictionary[$dictionaryIndex][1]
					$shouldCopy = False
					$source = $cachePath & $iniSection[$i][1] & ".uxx"
					$destination = $utPath & $outputFolder & "\" & $iniSection[$i][2]
					$destinationExists = FileExists($destination)
					$sourceExists = FileExists($source)

					If $sourceExists Then
						If $destinationExists Then
							; compare size
							$oldSize = FileGetSize($destination)
							$newSize = FileGetSize($source)
							If $newSize >= $oldSize Then
								; overwrite existing file only if the newer file is larger or equal in size
								$shouldCopy = True
							EndIf
						Else
							$shouldCopy = True
						EndIf
					EndIf

					If $shouldCopy = True Then
						; calculate usefulness of the program
						$addSize = FileGetSize($source)
						ToolTip($destination, 300, 0)
						$moved = FileMove($source, $destination, $FC_OVERWRITE)
						If $moved = 0 Then
							$filesFailed = True
							$failedFiles &= $source & " -> " & $destination & @CRLF
						Else
							$dictionary[$dictionaryIndex][2] += 1
							$dictionary[$dictionaryIndex][3] += $addSize
							$iniSection[$i][1] = ""
						EndIf
					Else
						; trash cache files that are smaller than the existing ones (incomplete downloads) and invalid ini entries
						$iniSection[$i][1] = ""
						FileDelete($source)
					EndIf
				EndIf
			Next
		EndIf
	EndIf

	recreateIni($ini, $iniSection, "Cache")

	$dicLength = UBound($dictionary)
	For $i = 0 To $dicLength - 1
		$stringStats &= StringFormat("%-13s %5d files %15sMB" & @CRLF, $dictionary[$i][1] & ":", $dictionary[$i][2], Round($dictionary[$i][3] / 1048576, 2))
	Next

	If $filesFailed = True Then
		$stringStats &= $failedFiles
	EndIf

	MsgBox(48, "UT2004 Cache Merge Utility by Shawn", "Done. Unreal Tournament 2004 Cache files were moved to their appropriate UT paths." & @CRLF & @CRLF & $stringStats)
EndFunc   ;==>moveUtCachedFiles

Func recreateIni($ini, $iniSection, $mainSection)
	; delete old cache.ini
	Local $iniDeleted = FileDelete($ini)

	; recreate ini with leftover entries
	If $iniDeleted = 1 Then
		FileWriteLine($ini, "[" & $mainSection & "]")

		For $i = 0 To $iniSection[0][0]
			If StringLen($iniSection[$i][1]) > 0 Then
				IniWrite($ini, $mainSection, $iniSection[$i][1], $iniSection[$i][2])
			EndIf
		Next
	EndIf
EndFunc   ;==>recreateIni

Func dictionary(ByRef $dictionary, $ext)
	Local $returnIndex = -1
	Local $dicLength = UBound($dictionary)
	For $i = 0 To $dicLength - 1
		If $dictionary[$i][0] = $ext Then
			$returnIndex = $i
			ExitLoop
		EndIf
	Next
	Return $returnIndex
EndFunc   ;==>dictionary

Func iniReadSections($iniFile)
	Local $iniArray = FileReadToArray($iniFile)
	Dim $iniSectionsArray[UBound($iniArray) + 1][3]
	populateIniArraySections($iniArray, $iniSectionsArray)
	Return $iniSectionsArray
EndFunc   ;==>iniReadSections

Func populateIniArraySections(ByRef $iniArray, ByRef $iniSectionsArray)
	Local $sectionName = ""
	$iniSectionsArray[0][0] = 0
	Local $iniArraySize = UBound($iniArray)
	For $i = 0 To $iniArraySize - 1
		$iniArray[$i] = StringStripWS($iniArray[$i], $STR_STRIPLEADING + $STR_STRIPTRAILING)
		If (StringLeft($iniArray[$i], 1) = "[") And (StringRight($iniArray[$i], 1) = "]") Then
			$sectionName = $iniArray[$i]
			$sectionName = StringReplace($sectionName, "[", "")
			$sectionName = StringReplace($sectionName, "]", "")
		Else
			If StringLen($iniArray[$i]) > 0 Then
				$delimPosition = StringInStr($iniArray[$i], "=")
				If ($delimPosition > 0) And Not (StringLeft($iniArray[$i], 1) = ";") Then ; if contains = and is not a comment
					$iniSectionsArray[0][0] += 1
					$iniSectionsArray[$iniSectionsArray[0][0]][0] = $sectionName
					$iniSectionsArray[$iniSectionsArray[0][0]][1] = StringLeft($iniArray[$i], $delimPosition - 1)
					$iniSectionsArray[$iniSectionsArray[0][0]][2] = StringRight($iniArray[$i], StringLen($iniArray[$i]) - $delimPosition)
				EndIf
			EndIf
		EndIf
	Next
EndFunc   ;==>populateIniArraySections
