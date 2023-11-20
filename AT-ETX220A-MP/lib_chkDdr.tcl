proc GuiCheckDdrTool { } {
  global gaSet gaGui
  set base .topChkDdrTool
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1 
  wm title $base "Check DDR Tool"
  
  
  set gaSet(ddrPass) 0
  set gaSet(ddrFail) 0
  set gaSet(ddrRun) 0
  set inx 0
  incr inx
  set fr [frame $base.fr[set inx] -bd 0 -relief groove]
    pack [Label $fr.lab[set inx]  -text "Run quantity" -width 15 -justify left] -pady 1 -padx 2 -anchor w -side left
    pack [SpinBox $fr.cb[set inx] -justify center  -range  {1 400 1} -editable 1 -textvariable gaSet(ddrRunQty)] -pady 1 -padx 2 -anchor w -side left
  pack $fr -anchor w 
  
  incr inx
  set fr [frame $base.fr[set inx] -bd 0 -relief groove]
    pack [Label $fr.lab[set inx]  -text "Stop on Fail" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [checkbutton $fr.cb[set inx] -variable gaSet(ddrSOF)] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  
  
  pack [Separator $base.sep[incr inx] -orient horizontal] -fill x -padx 2 -pady 3
  
  incr inx
  set fr [frame $base.fr[set inx] -bd 0 -relief groove]
    pack [Label $fr.lab[set inx]  -text "Runnig" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [set gaGui(ddrRun) [Entry $fr.cb[set inx] -justify center -editable 0 -textvariable gaSet(ddrRun)]] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  incr inx
  set fr [frame $base.fr[set inx] -bd 0 -relief groove]
    pack [Label $fr.lab[set inx]  -text "Pass" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [set gaGui(ddrPass) [Entry $fr.cb[set inx] -justify center -editable 0 -textvariable gaSet(ddrPass)]] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  incr inx
  set fr [frame $base.fr[set inx] -bd 0 -relief groove]
    pack [Label $fr.lab[set inx]  -text "Fail" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [set gaGui(ddrFail) [Entry $fr.cb[set inx] -justify center -editable 0 -textvariable gaSet(ddrFail)]] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  
  pack [Separator $base.sep[incr inx] -orient horizontal] -fill x -padx 2 -pady 3
  
  pack [frame $base.frBut ] -pady 4 -anchor e
    pack [set gaGui(ddrButStop) [Button $base.frBut.butStopChkDdrTool -text Stop -command ButStopChkDdrTool -width 7]] -side right -padx 6
    pack [set gaGui(ddrButRun)  [Button $base.frBut.butRunChkDdrTool -text Run -command ButRunChkDdrTool -width 7]]  -side right -padx 6
  
  
  bind $base <F1> {console show}
  focus -force $base
  grab $base
  return {} 
}
# ***************************************************************************
# ButStopChkDdrTool
# ***************************************************************************
proc ButStopChkDdrTool  {} {
  global gaSet gaGui
  set gaSet(act) 0
  $gaGui(ddrButRun) configure -state normal  -relief raised
  $gaGui(ddrButStop) configure -state disabled  -relief sunken
}
# ***************************************************************************
# ButRunChkDdrTool
# ***************************************************************************
proc ButRunChkDdrTool  {} {
  global gaSet gaGui
  set gaSet(act) 1
   console eval {.console delete 1.0 end}
  $gaGui(ddrButRun) configure -state disabled -relief sunken
  $gaGui(ddrButStop) configure -state normal  -relief raised
  set grayBG [$gaGui(ddrRun) cget -bg]
  $gaGui(ddrPass) configure -bg $grayBG
  $gaGui(ddrFail) configure -bg $grayBG
  update
  LoadBootErrorsFile
  
  OpenRL
  set ret [ReadIdBarcodeFromPage3]
  CloseRL
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  ##set gaSet(logFile) c:/logs/ddr/ddrLogFile_[set ti]_$gaSet(pair).txt
  set gaSet(logFile) c:/logs/ddr/_[set ti]_$gaSet(pair).txt
  set pass 0
  set fail 0
  set gaSet(ddrPass) $pass
  set gaSet(ddrFail) $pass
  set maxCalSucc 0
  set maxReadWrite 0
  set ::calSucc 0
  set ::readWrite 0
  set ::leSw2 -
  set ::readLeSw2 1
  for {set i 1} {$i <= $gaSet(ddrRunQty)} {incr i} {
    AddToLog "Start DDR Test No. $i"
    set gaSet(ddrRun) $i
    if {$gaSet(act)==0} {
      AddToLog "User stop"
      break
    }
    OpenRL
    PowerOffOn
    set ret [DDR $i]
    if {$::readLeSw2=="1"} {
      AddToLog "UUt's SW ver. = $::leSw2"
      set ::readLeSw2 0
    }
    AddToLog "Finish DDR Test No. ${i}. Result: $ret. \'cal_success\'=$::calSucc \'ReadWrite\'=$::readWrite"
    if {$::calSucc!=""} {
      incr maxCalSucc $::calSucc
    }
    if {$::readWrite!=""} {
      incr maxReadWrite $::readWrite
    }
    if {$ret==0} {
      incr pass
      set gaSet(ddrPass) $pass
    }
    if {$ret=="-1"} {
      AddToLog "Failure: $gaSet(fail)"
      incr fail
      set gaSet(ddrFail) $fail
    } 
    if {$ret=="-1" && $gaSet(ddrSOF)==1} {
      break
    }
    AddToLog "-----------------------------------------\r"
  }
  set gaSet(ddrRun) ""
  Status "DDR Test finished"
  CloseRL
  AddToLog "================================\r"
  AddToLog "Test pass $pass times and failed $fail times"
  ButStopChkDdrTool
  if {$fail>0} {
    set txt FailDdr
     $gaGui(ddrFail) configure -bg red
  } elseif {$fail==0 && $pass==$gaSet(ddrRunQty)}  {
    set txt PassDdr
    $gaGui(ddrPass) configure -bg #00ff00
  } elseif {$fail==0 && $pass!=$gaSet(ddrRunQty)}  {
    set txt Fail
     $gaGui(ddrFail) configure -bg red
  }
  set txt ${txt}_${maxCalSucc}_${maxReadWrite}_$gaSet(BarcodeFromPage3)
  if ![catch  {file copy -force $gaSet(logFile)  [join [linsert [split $gaSet(logFile) _] 1  $txt] _]} rr] {
    file delete -force $gaSet(logFile)    
  }
}