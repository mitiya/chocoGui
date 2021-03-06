#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Color_icon_brown_v2.ico
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;*****************************************
;ChocoGUI by mitiya
;*****************************************
Opt("GUIResizeMode", 2 + 8 + 32)  
Opt("WinTitleMatchMode", 2)

Global $_ver = '0.4.3'
Global $_aboutTxt = 'chocoGUI v' & $_ver & @CR & 'ChocoGUI is a portable Gui for Chocolatey'
Global $Listsfolder = @ScriptDir & "\lists"
Global $g_idListView
Global $isTap2taped = 0
Global $isUpdListGeted = 0
Global $cGreen = 0xCCFFCC
Global $cYellow = 0xFCFF4A	
global $inifile = @ScriptDir & "\settings.ini"
	
#include "libs\cash.au3"
#include "GUI.isf"	
#include <GUIConstantsEx.au3>
#include "libs\_log.au3"
#include "libs\funcs.au3"
#include "libs\WM_NOTIFY.au3"
#include "libs\main.au3"
#include "libs\modalW.au3"

Global $h_i_search = GUICtrlGetHandle($i_search)
Global $h_i_list = GUICtrlGetHandle($i_list)

;~ ini reads
Global $UseCReps = IniRead ( $inifile, "repos", "use",False)
GUICtrlSetData ( $I_repoList, IniRead ( $inifile, "repos", "RepoList","https://chocolatey.org/api/v2;http://m-it.su/nuget/api/v2"))
if $UseCReps == True Then 
		GUICtrlSetState  ( $CB_useRep, $GUI_CHECKED )
		GUICtrlSetState  ( $I_repoList, $GUI_ENABLE )
		_CmdLineCreate($cmdLine1,$CB_useRep,'-s ' & GUICtrlRead ($I_repoList))
		_CmdLineCreate($cmdLine2,$CB_useRep,'-s ' & GUICtrlRead ($I_repoList))
	Else
		GUICtrlSetState  ( $CB_useRep, $GUI_UNCHECKED )
		GUICtrlSetState  ( $I_repoList, $GUI_DISABLE )
EndIf



;~ GUICtrlSetState  ( $CB_ignorechecksum, $GUI_CHECKED )
GUICtrlSetState  ( $CB_allowdowngrade, $GUI_CHECKED )
_CmdLineCreate($cmdLine2,$CB_allowdowngrade,'--allowdowngrade')

;~ test button
;~ GUICtrlSetState  ( $B_test, $GUI_SHOW+$GUI_ENABLE )

GUISetState(@SW_SHOW,$Gui)

_chocolateyInstall()

While 1
	
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			Exit
		Case $B_test
			_testButton()
			
		Case $tab
;~ 			_log("tab")
			Switch GUICtrlRead($tab)
				Case 0
					_log("tab 0")
					$g_idListView = $pkLIst
				Case 1
					_log("tab 1")
					$g_idListView = $pkInstaledLIst
					if $isTap2taped == 0 then 
						_GUI_SearchLoacal(True,True,True)
						$isTap2taped = 1
;~ 						_ArrayDisplay($updLstrArr, "$updLstrArr")
					EndIf
			EndSwitch
				
		Case $i_search
			_log('$i_search')
			If ControlGetHandle($GUI, '', '') == $h_i_search Then _GUI_SeachInRepos()
		Case $B_search
			_GUI_SeachInRepos()
		Case $B_addtoInstallList
			_RightToLeftList($pkLIst,$Lv_installList)
			
		Case $B_delFromInstallList
			_delFromLeftList($Lv_installList)
			_GUICtrlButton_SetFocus($Lv_installList)
		Case $B_install
			_modal(true,"Working...",$Gui)
			_log("install bt")
			_processLeftList($Lv_installList,'install')
			_GUI_SeachInRepos(False)
			_modal(false,"Working...",$Gui)
		Case $B_save	
			if not(FileExists($Listsfolder)) Then DirCreate ( $Listsfolder )
			Local $svList = FileSaveDialog ( "save list", $Listsfolder, "Text files (*.txt)")
			_saveList($svList)
		Case $B_load
			Local $svList = FileOpenDialog ( "save list", $Listsfolder, "Text files (*.txt)")
			_loadList($svList)
			_GUICtrlButton_SetFocus($B_install)
		Case $CB_apr
			_log("box $CB_apr")
			_CmdLineCreate($cmdLine1,$CB_apr,'--approved-only')
			_GUICtrlButton_SetFocus($B_search)
		Case $CB_rbk
			_log("box $CB_rbk")
			_CmdLineCreate($cmdLine1,$CB_rbk,'--not-broken')
			_GUICtrlButton_SetFocus($B_search)
		Case $CB_all
			_log("box $CB_all")
			_CmdLineCreate($cmdLine1,$CB_all,'--all')
			_toggleElement($B_save)
			_toggleElement($B_load)
			_GUICtrlButton_SetFocus($B_search)
		Case $CB_exact
			_log("box $CB_exact")
			_CmdLineCreate($cmdLine1,$CB_exact,'--exact')
			_GUICtrlButton_SetFocus($B_search)
			
		Case $CB_ignorechecksum
			_log("box $CB_ignorechecksum")
			_CmdLineCreate($cmdLine2,$CB_ignorechecksum,'--ignorechecksum')

		Case $CB_x86
			_log("box $CB_x86")
			_CmdLineCreate($cmdLine2,$CB_x86,'--x86')
			
		Case $CB_allowdowngrade
			_log("box $CB_allowdowngrade")
			_CmdLineCreate($cmdLine2,$CB_allowdowngrade,'--allowdowngrade')
			
		Case $CB_useRep
			_log("box $CB_useRep")
			_CmdLineCreate($cmdLine1,$CB_useRep,'-s ' & GUICtrlRead ($I_repoList))
			_CmdLineCreate($cmdLine2,$CB_useRep,'-s ' & GUICtrlRead ($I_repoList))
			GUICtrlSetState  ( $I_repoList, _GuiToggle(GUICtrlGetState($I_repoList) - $GUI_SHOW) )
			
		Case $pkLIst
			_GUICtrlListView_RegisterSortCallBack($pkLIst)			
			_GUICtrlListView_SortItems($pkLIst, GUICtrlGetState($pkLIst))
			
		Case $pkInstaledLIst
			_GUICtrlListView_RegisterSortCallBack($pkInstaledLIst)		
			_GUICtrlListView_SortItems($pkInstaledLIst, GUICtrlGetState($pkInstaledLIst))
			
		Case $i_list
			If ControlGetHandle($GUI, '', '') == $h_i_list Then _GUI_SearchLoacal()		
		Case $B_list
			_GUI_SearchLoacal()
		Case $B_addtoUnInstallList
			_RightToLeftList($pkInstaledLIst,$Lv_uninstallList)
		Case $B_delFromUnInstallList
			_delFromLeftList( $Lv_uninstallList )	
		Case $B_Uninstall
			_modal(True,"Working...",$Gui)
			_processLeftList($Lv_uninstallList,'uninstall')
;~ 			_GUI_SearchLoacal(False)
			_modal(False,"Working...",$Gui)		
		Case $B_update
			_modal(true,"Working...",$Gui)
			_processLeftList($Lv_uninstallList,'update')
;~ 			_GUI_SearchLoacal(False)	
			_modal(False,"Working...",$Gui)	
		Case $B_pin
			_processLeftList($Lv_uninstallList,'pin')
;~ 			_GUI_SearchLoacal(False)
		Case $B_UnPin
			_modal(True,"Working...",$Gui)
			_processLeftList($Lv_uninstallList,'unpin')
;~ 			_GUI_SearchLoacal(False)
			_modal(False,"Working...",$Gui)
		Case $B_UbdAll	
			_RightToLeftList($pkInstaledLIst,$Lv_uninstallList,'updAll')
		Case $L_pkURL
			_log("$L_pkURL")
			_goToUrl(GUICtrlRead($L_pkURL))
		Case $L_pkURL2
			_goToUrl(GUICtrlRead($L_pkURL2))
		Case $L_ChpkURL
			_goToUrl(GUICtrlRead($L_ChpkURL))
		Case $L_ChpkURL2
			_goToUrl(GUICtrlRead($L_ChpkURL2))
		Case $_peleaseUrl
			_goToUrl(GUICtrlRead($_peleaseUrl))	
		Case $B_saveSet
			_SaveSettings()
			
					
	EndSwitch
WEnd


