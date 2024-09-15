#***************************************************************************
#** GUI
#***************************************************************************
proc GUI {} {
  global gaSet gaGui glTests  
  if ![info exists gaSet(DutFullName)] {set gaSet(DutFullName) ""}
  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  if {$gaSet(eraseTitle)==1} {
    wm title . "$gaSet(pair) : "
  }
  wm protocol . WM_DELETE_WINDOW {Quit}
  wm geometry . $gaGui(xy)
  wm resizable . 0 0
  set descmenu {
    "&File" all file 0 {	          
      {cascad "&Console" {} console 0 {
        {checkbutton "console show" {} "Console Show" {} -command "console show" -variable gConsole}  
        {command "Capture Console" cc "Capture Console" {} -command CaptureConsole}
        {command "Find Console" console "Find Console" {} -command {GuiFindConsole}}          
      }
      }
      {separator}
      {command "History" History "" {} \
         -command {
           set cmd [list exec "C:\\Program\ Files\\Internet\ Explorer\\iexplore.exe" [pwd]\\history.html &]
           eval $cmd
         }
      }
      {separator}
      {command "COMs mapping" init "" {} -command "ShowComs"}
      {separator}
      {command "E&xit" exit "Exit" {Alt x} -command {Quit}}		
    }
    "&Tools" tools tools 0 {
      {command "Inventory" init {} {} -command {GuiInventory}}	
      {command "Load Init File" init {} {} -command {GetInitFile}}
      {separator} 	                          	
      {command "Single test" init {} {} -command {set gaSet(oneTest) 1}}
      {separator}
      {radiobutton "Scan barcode each UUT" {} "" {} -command {ToogleEraseTitle 1} -variable gaSet(gaSet(eraseTitleTmp)) -value 1}  
      {radiobutton "Scan barcode each batch" {} "" {} -command {ToogleEraseTitle 0} -variable gaSet(eraseTitleTmp) -value 0}  
      {separator}    
      {command "Release / Debug mode" {} "" {} -command {GuiReleaseDebugMode}}   
      {separator}                                                       
      {command "PS-1 & PS-2 ON" {} "" {} -command {GuiPower $gaSet(pair) 1}} 
      {command "PS-1 & PS-2 OFF" {} "" {} -command {GuiPower $gaSet(pair) 0}}  
      {command "PS-1 ON" {} "" {} -command {GuiPower $gaSet(pair).1 1}} 
      {command "PS-1 OFF" {} "" {} -command {GuiPower $gaSet(pair).1 0}} 
      {command "PS-2 ON" {} "" {} -command {GuiPower $gaSet(pair).2 1}} 
      {command "PS-2 OFF" {} "" {} -command {GuiPower $gaSet(pair).2 0}} 
      {separator}
      {radiobutton "PIO PCI" init {} {} -command {} -variable gaSet(pioType) -value Ex}
      {radiobutton "PIO USB" init {} {} -command {} -variable gaSet(pioType) -value Usb}
      {separator}
      {command "E-mail Setting" gaGui(ToolAdd) {} {} -command {GuiEmail .mail}} 
		  {command "E-mail Test" gaGui(ToolAdd) {} {} -command {TestEmail}} 
      {command "IPRelay IP Address" {} "IPRelay IP Address" {} -command {GuiIPRelay}} 
      {separator}    
      {radiobutton "Use existing Barcode" init {} {} -command {} -variable gaSet(useExistBarcode) -value 1}
      {separator}
      {command "Init Etx GEN" {} "" {} -command {InitEtxGen}}  
      {separator}
      {command "Init date-and-time" {} "" {} -command {DateTime_Set}} 
      {separator}
      {command "Check DDR tool" {} "" {} -command {GuiCheckDdrTool}}        
    }
    "&Terminal" terminal tterminal 0  {
      {command "UUT" "" "" {} -command {OpenTeraTerm gaSet(comDut)}}
      {command "ETX" "" "" {} -command {OpenTeraTerm gaSet(comGEN)}}
       }
    "&About" all about 0 {
      {command "&About" about "" {} -command {About} 
      }          
    }
  }
   #  {command "SW init" init {} {} -command {GuiSwInit}}	
   ##{command "Log File"  {} {} {} -command ShowLog}
	 ##   {separator}  
   # {command "Update INIT and UserDefault files on all the Testers" {} "Exit" {} -command {UpdateInitsToTesters}}
      # {separator}
      

  set mainframe [MainFrame .mainframe -menu $descmenu]
  set gaSet(sstatus) [$mainframe addindicator]  
  $gaSet(sstatus) configure -width 70 
  set gaSet(startTime) [$mainframe addindicator]
  set gaSet(runTime) [$mainframe addindicator]
  $gaSet(runTime) configure -width 5
  

  set tb0 [$mainframe addtoolbar]
  pack $tb0 -fill x
  set labstartFrom [Label $tb0.labSoft -text "Start From   "]
  set gaGui(startFrom) [ComboBox $tb0.cbstartFrom  -height 19 -width 35 \
      -textvariable gaSet(startFrom) -justify center  -editable 0]
  $gaGui(startFrom) bind <Button-1> {SaveInit}
  pack $labstartFrom $gaGui(startFrom) -padx 2 -side left
  set sepIntf [Separator $tb0.sepIntf -orient vertical]
  pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0
	 
  set bb [ButtonBox $tb0.bbox0 -spacing 1 -padx 5 -pady 5]
    set gaGui(tbrun) [$bb add -image [Bitmap::get images/run1] \
        -takefocus 0 -command ButRun \
        -bd 1 -padx 5 -pady 5 -helptext "Run the Tester"]		 		 
    set gaGui(tbstop) [$bb add -image [Bitmap::get images/stop1] \
        -takefocus 0 -command ButStop \
        -bd 1 -padx 5 -pady 5 -helptext "Stop the Tester"]
    set gaGui(tbpaus) [$bb add -image [Bitmap::get images/pause] \
        -takefocus 0 -command ButPause \
        -bd 1 -padx 5 -pady 1 -helptext "Pause/Continue the Tester"]	    
  pack $bb -side left  -anchor w -padx 7 ;#-pady 3
  
  set bb [ButtonBox $tb0.bbox12 -spacing 1 -padx 5 -pady 5]
    set gaGui(email) [$bb add -image [image create photo -file  images/email16.ico] \
        -takefocus 0 -command {GuiEmail .mail} \
        -bd 1 -padx 5 -pady 5 -helptext "Email Setup"] 
    set gaGui(ramzor) [$bb add -image [image create photo -file  images/TRFFC09_1.ico] \
        -takefocus 0 -command {GuiIPRelay} \
        -bd 1 -padx 5 -pady 5 -helptext "IP-Relay Setup"]        
  pack $bb -side left  -anchor w -padx 7
  
  set sepIntf [Separator $tb0.sepFL -orient vertical]
  #pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0 
  
  
  set bb [ButtonBox $tb0.bbox2]
    set gaGui(butShowLog) [$bb add -image [image create photo -file images/find1.1.ico] \
        -takefocus 0 -command {ShowLog} -bd 1 -helptext "View Log file"]    
  pack $bb -side left  -anchor w -padx 7     
  
  set sepView [Separator $tb0.sepVi -orient vertical]
  set bb [ButtonBox $tb0.bbox3]
    set gaGui(butGuiCheckDdrTool) [$bb add -image [image create photo -file images/columns.ico] \
        -takefocus 0 -command {GuiCheckDdrTool} -bd 1 -helptext "Check DDR tool"]    
  pack $bb -side left  -anchor w -padx 7
  
    set frCommon [frame $mainframe.frCommon -bd 0]
#       set frOpt [frame $frCommon.frOpt -bd 0 -relief groove]
#         set frOptions [TitleFrame $frOpt.frOptions -bd 2 -relief groove -text "Options"]
#           set gaGui(chbDefConf) [checkbutton [$frOptions getframe].chbDefConf -text "Def. Configuration"\
#              -variable gaSet(defConfEn) -command BuildTests]
#           pack $gaGui(chbDefConf) -anchor w   
#         #pack $frOptions -fill both  -expand 1 -padx 2 -pady 2
        
#         set frClkOpt [frame $frOpt.frClkOpt -bd 2 -relief groove]
#           set gaGui(rbClkOptSYE) [radiobutton $frClkOpt.rbClkOptSYE -text "SYE" -variable gaSet(clkOpt) -value SYE]
#           set gaGui(rbClkOptPTP) [radiobutton $frClkOpt.rbClkOptPTP -text "PTP" -variable gaSet(clkOpt) -value PTP]
#           pack $gaGui(rbClkOptSYE) -side left 
#           pack $gaGui(rbClkOptPTP) -side right 
#         pack $frClkOpt -fill both  -expand 1 -padx 2 -pady 2
      #pack $frOpt -fill both  -expand 1 -padx 2 -pady 2 -side left ; # -ipadx 1
      
      set frUut [frame $frCommon.frUut -bd 2 -relief groove]   
        #set frTestMode [TitleFrame $frUut.frTestMode -bd 2 -relief groove -text "Test"] 
        set frTestMode [frame $frUut.frTestMode -bd 0 -relief groove] 
          set gaGui(TestMode) [ComboBox $frTestMode.frTestMode -justify center\
              -values "AllTests TestsWithoutDataRun" -textvariable gaSet(TestMode) -height 3 -editable 0\
              -modifycmd {SaveInit ; BuildTests} \
              -helptext "BOT: Basic Operational Test\nFT: Final Test"]          
          pack $gaGui(TestMode) -anchor w -fill x -expand 1
          set gaGui(chbPsTest) [checkbutton $frTestMode.chbPsTest -text "PS test"\
             -variable gaSet(chbPsTest) -command BuildTests]
          pack $gaGui(chbPsTest) -anchor w  
        pack $frTestMode -fill x -expand 1 -anchor n ; # -side left
        
#         set fr1 [frame $frUut.fr1 -bd 0 -relief groove]
#           set frE1 [TitleFrame $fr1.frE1 -bd 2 -relief groove -text "ESK-BSK"] 
#             set gaGui(cbSk) [ComboBox [$frE1 getframe].frUserPort -justify center\
#                 -values "ESK BSK" -textvariable gaSet(sk) -height 3 -editable 0\
#                 -width 11 -modifycmd {SaveInit}]          
#             #pack $gaGui(cbSk) -anchor w
#           #pack $frE1 -fill x -expand 1 -anchor n  -side left
#           set frE2 [TitleFrame $fr1.frE2 -bd 2 -relief groove -text "PS"] 
#             set gaGui(cbPs) [ComboBox [$frE2 getframe].frPS -justify center\
#                 -values "AC DC" -textvariable gaSet(ps) -height 3 -editable 0\
#                 -width 11 -modifycmd {SaveInit}]          
#             #pack $gaGui(cbPs) -anchor w
#           #pack $frE2 -fill x -expand 1 -anchor n -side left
#         #pack $fr1 -fill x -expand 1 -anchor n ; # -side left
        
      pack $frUut -fill both  -expand 1 -padx 2 -pady 2 -side left -anchor n ; # -ipadx 10   
      
#       set frPorts [frame $frCommon.frPorts]
#         set fr1 [frame $frPorts.fr1 -bd 0 -relief groove]
#           set frE1 [TitleFrame $fr1.frE1 -bd 2 -relief groove -text "10G ports"] 
#             set gaGui(cb10G) [ComboBox [$frE1 getframe].frUserPort -justify center\
#                 -values "2 3 4" -textvariable gaSet(10G) -height 3 -editable 0\
#                 -width 13 -modifycmd {TogglePorts}]          
#             pack $gaGui(cb10G) -anchor w
#           pack $frE1 -fill y -expand 1 -anchor n
#           set frE2 [TitleFrame $fr1.frE2 -bd 2 -relief groove -text "1G ports"] 
#             set gaGui(cb1G) [ComboBox [$frE2 getframe].frPS -justify center\
#                 -values "10SFP 10UTP 20SFP 20UTP 10SFP_10UTP None" \
#                 -textvariable gaSet(1G) -height 6 -editable 0\
#                 -width 13 -modifycmd {TogglePorts; #25/08/2014 09:42:30}]          
#             pack $gaGui(cb1G) -anchor w
#           pack $frE2 -fill y -expand 1 -anchor n
#         pack $fr1 -fill x -expand 1 -anchor n ; # -side left
#       #pack $frPorts -fill x -expand 1 -padx 2 -pady 2 -side left
    pack $frCommon -fill both -expand 1 -padx 2 -pady 0 -side left  -anchor n

    set frDUT [frame $mainframe.frDUT -bd 2 -relief groove] 
      set labDUT [Label $frDUT.labDUT -text "UUT's barcode" -width 15]
      set gaGui(entDUT) [Entry $frDUT.entDUT -bd 1 -justify center -width 50\
            -editable 1 -relief groove -textvariable gaSet(entDUT) -command {GetDbrName}\
            -helptext "Scan a barcode here"]
      set gaGui(clrDut) [Button $frDUT.clrDut -image [image create photo -file  images/clear1.ico] \
            -takefocus 1 \
            -command {
                global gaSet gaGui
                set gaSet(entDUT) ""
                focus -force $gaGui(entDUT)
            }]         
      pack $labDUT $gaGui(entDUT) $gaGui(clrDut) -side left -padx 2
      
    set frTestPerf [TitleFrame $mainframe.frTestPerf -bd 2 -relief groove \
        -text "Test Performance"] 
      set f [$frTestPerf getframe]
      set frCur [frame $f.frCur]  
        set labCur [Label $frCur.labCur -text "Current Test  " -width 12]
        set gaGui(curTest) [Entry $frCur.curTest -bd 1 -justify center\
            -editable 0 -relief groove -textvariable gaSet(curTest) -width 70]
        pack $labCur $gaGui(curTest) -padx 7 -pady 3 -side left -fill x;# -expand 1 
      pack $frCur  -anchor w
      
#       set frStatus [frame $f.frStatus]
#         set labStatus [Label $frStatus.labStatus -text "Status  " -width 12]
#         set gaGui(labStatus) [Entry $frStatus.entStatus \
#             -bd 1 -editable 0 -relief groove -textvariable gaSet(status) -justify center -width 70]
#         pack $labStatus $gaGui(labStatus) -fill x -padx 7 -pady 3 -side left;# -expand 1 	 
#       pack $frStatus -anchor w
      set frFail [frame $f.frFail]
      set gaGui(frFailStatus) $frFail
        set labFail [Label $frFail.labFail -text "Fail Reason  " -width 12]
        set labFailStatus [Entry $frFail.labFailStatus \
            -bd 1 -editable 1 -relief groove \
            -textvariable gaSet(fail) -justify center -width 70]
      pack $labFail $labFailStatus -fill x -padx 7 -pady 3 -side left; # -expand 1	
      #pack $gaGui(frFailStatus) -anchor w
      
      set frPairPerf [frame [$frTestPerf getframe].frPairPerf -bd 0 -relief groove]
      set gaGui(labPairPerf0) [Button $frPairPerf.labPairPerf0 -text 0 -bd 1 -relief raised -command [list TogglePairButAll 0]]
      if {$gaSet(pair)=="5"} {
        pack $gaGui(labPairPerf0) -side left -padx 1 -fill x -expand 1
      }
      for {set i 1} {$i <= 27} {incr i} {
        set gaGui(labPairPerf$i) [Button $frPairPerf.labPairPerf$i -text $i -bd 1 -relief raised -command [list TogglePairBut $i]]
        #set gaGui(labPairPerf$i) [Label $frPairPerf.labPairPerf$i -text $i -bd 1 -relief raised]
        #bind  $gaGui(labPairPerf$i) <ButtonRelease-1> [list TogglePairBut $i]
        if {$gaSet(pair)=="5"} {
          pack $gaGui(labPairPerf$i) -side left -padx 1 -fill x -expand 1
        } else {
          if {$i=="1"} {
            #pack $gaGui(labPairPerf$i) -side left -padx 1 -fill x -expand 1
          }
        }
      }
      set gaGui(labPairPerfAll) [Button $frPairPerf.labPairPerfAll -text ALL -bd 1 -relief raised -command [list TogglePairButAll All]]
      if {$gaSet(pair)=="5"} {
        pack $gaGui(labPairPerfAll) -side left -padx 1 -fill x -expand 1
      } else {
        TogglePairBut 1
      }
      pack $frPairPerf -fill x -padx 2 -pady 2 -expand 1 
           
    pack $frDUT $frTestPerf -fill both -expand yes -padx 2 -pady 2 -anchor n	 
  pack $mainframe -fill both -expand yes

  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled  

  console eval {.console config -height 14 -width 92}
  console eval {set ::tk::console::maxLines 10000}
  console eval {.console config -font {Verdana 8}}
  focus -force .
  bind . <F1> {console show}
  
  set gaSet(entDUT) ""
  focus -force $gaGui(entDUT)
  
  TogglePorts
  
  bind . <Alt-i> {GuiInventory}
  bind . <Alt-r> {ButRun}
  bind . <Alt-s> {ButStop}
  bind . <Control-b> {set gaSet(useExistBarcode) 1}
  bind . <Control-i> {GuiInventory}
  
  .menubar.tterminal entryconfigure 0 -label "UUT: COM $gaSet(comDut)"
  .menubar.tterminal entryconfigure 2 -label "ETX: COM $gaSet(comGEN)"

  #RLStatus::Show -msg fti
  #RLStatus::Show -msg atp
  
  if ![info exists ::RadAppsPath] {
    set ::RadAppsPath c:/RadApps
  }
  set gaSet(GuiUpTime) [clock seconds]
}
# ***************************************************************************
# About
# ***************************************************************************
proc About {} {
  if [file exists history.html] {
    set id [open history.html r]
    set hist [read $id]
    close $id
#     regsub -all -- {[<>]} $hist " " a
#     regexp {div ([\d\.]+) \/div} $a m date
    regsub -all -- {<[\w\=\#\d\s\"\/]+>} $hist "" a
    regexp {<!---->\s(.+)\s<!---->} $a m date
  } else {
    set date 03.01.2016 
  }
  DialogBox -title "About the Tester" -icon /images/info -type ok \
      -message "The software upgrated at $date"
  #DialogBox -title About -icon /images/info -type ok\
          -message "The software upgrated at 03.01.2016"
}

#***************************************************************************
#** ButRun
#***************************************************************************
proc ButRun {} {
  global gaSet gaGui glTests gRelayState
  puts "\r[MyTime] ButRun"; update
  Ramzor green on
  set gaSet(runStatus) ""
  set gaSet(act) 1
  focus $gaGui(tbrun)
  console eval {.console delete 1.0 end}
  console eval {set ::tk::console::maxLines 100000}
  LoadBootErrorsFile
  IPRelay-Green
  set gaSet(ButRunTime) [clock seconds]
  set ::wastedSecs 0
  
  set gaSet(1.barcode1.IdMacLink) ""
  
  
  Status ""
  set gaSet(curTest) ""
  console eval {.console delete 1.0 end}
  pack forget $gaGui(frFailStatus)
  $gaSet(startTime) configure -text " Start: [MyTime] "
  $gaGui(tbrun) configure -relief sunken -state disabled
  $gaGui(tbstop) configure -relief raised -state normal
  $gaGui(tbpaus) configure -relief raised -state normal
  set gaSet(fail) ""
#     foreach wid {startFrom cbUserPort cbWire} {
#       $gaGui($wid) configure -state disabled
#     }
  #.mainframe setmenustate tools disabled
  update
  catch {exec taskkill.exe /im pw5.exe /f /t}
  RLTime::Delay 1
  
  catch {unset gaSet(1.barcode1)}
  catch {unset gaSet(1.mac1)}
  
  set ret 0
  set ti [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M"]
  set gaSet(logFile.$gaSet(pair)) c:/logs/$ti.$gaSet(pair).logFile.txt
  set gaSet(logTime) [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
  
  puts "[wm title .]"
  if {[wm title .]=="$gaSet(pair) : "} {
    set ret -1
    set gaSet(fail) "Please scan the UUT's barcode"
  }
  
  if {$ret==0} {
    Ramzor red on
    set ret [GuiReadOperator]
    Ramzor green on
    parray gaSet *arco*
    parray gaSet *rato*
    if {$ret!=0} {
      set ret -3
    } elseif {$ret==0} {
      set ret [ReadBarcode]
      if {$ret=="-3" || $ret=="-1"} {
        ## SKIP is pressed, we can continue
        #set ret 0
      }
  #     if {$gaSet(TestMode)=="FT"} {
  #       set ret [ReadBarcode]
  #     } else {
  #       set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}.txt
  #       set ret 0
  #     }
      if {$ret==0} {
        set ret [CheckTitleDbrNameVsUutDbrName] 
        puts "Ret of CheckTitleDbrNameVsUutDbrName: <$ret>"
      
      }
    }
  }
  
  set gRelayState red
  IPRelay-LoopRed
  
  if {$ret==0 && $gaSet(relDebMode)=="Debug"} {
    #RLSound::Play beep
    RLSound::Play information
    set txt "Be aware!\r\rYou are about to perform tests in Debug mode.\r\r\
    If you are not sure, in the GUI's \'Tools\'->\'Release / Debug mode\' choose \"Release Mode\""
    set res [DialogBoxRamzor -icon images/info -type "Continue Abort" -text $txt -default 1 -aspect 2000 -title "ETX-220"]
    if {$res=="Abort"} {
      set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}.txt
      set ret -2
      set gaSet(fail) "Debug mode abort"
      Status "Debug mode abort"
#       AddToLog $gaSet(fail)
      AddToPairLog $gaSet(pair) $gaSet(fail)
    } else {
      AddToPairLog $gaSet(pair) "\n!!! DEBUG MODE !!!\n"
      set ret 0
    }
  }
   
  if {$ret==0} {
    AddToPairLog $gaSet(pair) "$gaSet(operatorID) $gaSet(operator)"
    
    IPRelay-Green
    set ret [OpenRL]
    puts "OpenRL ret:$ret"
    if {$ret==0} {
      set ret [Testing]
    }
  
    puts "ret of Testing: $ret"  ; update
#     foreach wid {startFrom cbUserPort cbWire} {
#       $gaGui($wid) configure -state normal
#     }
#     $gaGui(labPairPerf0) configure -state normal
#     $gaGui(labPairPerfAll) configure -state normal
    #.mainframe setmenustate tools normal
    puts "end of normal widgets"  ; update
    update
    set retC [CloseRL]
    puts "ret of CloseRL: $retC"  ; update
    
    set gaSet(oneTest) 0
#     set gaSet(rerunTesterMulti) conf
#     set gaSet(nextPair) begin
  
    set gRelayState red
    IPRelay-LoopRed
    puts "ButRun ret:$ret"
  }
  
  Ramzor red on
  if {$ret==0} {     
    #exec C:\\RLFiles\\Tools\\Btl\\passbeep.exe &
    RLSound::Play pass
    if  {[info exists gaSet(pair)] && [info exists gaSet(log.$gaSet(pair))] && [file exists $gaSet(log.$gaSet(pair))]} {
      file rename -force $gaSet(log.$gaSet(pair)) [file rootname $gaSet(log.$gaSet(pair))]-Pass.txt
    }
    set gaSet(runStatus) Pass
    Status "Done" #00ff00
	  set gaSet(curTest) ""
	  set gaSet(startFrom) [lindex $glTests 0]
  } elseif {$ret==1} {
    #exec C:\\RLFiles\\Tools\\Btl\\beep.exe &
    RLSound::Play information
    Status "The test has been performed"  yellow
  } else {
    set gaSet(runStatus) Fail 
    if {$ret=="-2"} {
	    set gaSet(fail) "User stop"
      
      ## do not include UserStop in statistics
      set gaSet(runStatus) ""
	  }
    if {$ret=="-3"} {
	    ## do not include No Operator fail in statistics
      set gaSet(runStatus) ""  
	  }
    if {$gaSet(runStatus)!=""} {
      UnregIdBarcode $gaSet(1.barcode1)
    }
	  pack $gaGui(frFailStatus)  -anchor w
   	$gaSet(runTime) configure -text ""
	  #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play failbeep
	  Status "Test FAIL (DUT's com:$gaSet(comDut) GEN's com:$gaSet(comGEN))"  red
    if {[info exists gaSet(pair)] && [info exists gaSet(log.$gaSet(pair))] && [file exists $gaSet(log.$gaSet(pair))]} {
      file rename -force $gaSet(log.$gaSet(pair)) [file rootname $gaSet(log.$gaSet(pair))]-Fail.txt
    }  
    
	  set gaSet(startFrom) $gaSet(curTest)
    update
  }
  puts "gaSet(runStatus):$gaSet(runStatus)"
  if {$gaSet(runStatus)!=""} {
    SQliteAddLine
  }
  SendEmail "ETX220A-MP" [$gaSet(sstatus) cget -text]
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  
  set res [DialogBox -type "OK" -icon /images/info -title "Finish" -message "The test is done" ]
  update
  Ramzor all off
  
  if {$gaSet(eraseTitle)==1} {
    wm title . "$gaSet(pair) : "
  }
  update
}


#***************************************************************************
#** ButStop
#** 
#** 
#***************************************************************************
proc ButStop {} {
  global gaGui gaSet
  set gaSet(act) 0
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  foreach wid {startFrom} {
    $gaGui($wid) configure -state normal
  }
  .mainframe setmenustate tools normal
  CloseRL
  update
}
# ***************************************************************************
# ButPause
# ***************************************************************************
proc ButPause {} {
  global gaGui gaSet
  if { [$gaGui(tbpaus) cget -relief] == "raised" } {
    $gaGui(tbpaus) configure -relief "sunken"     
    #CloseRL
  } else {
    $gaGui(tbpaus) configure -relief "raised" 
    #OpenRL   
  }
        
  while { [$gaGui(tbpaus) cget -relief] != "raised" } {
    RLTime::Delay 1
  }  
}

#***************************************************************************
#** GuiSwInit
#***************************************************************************
proc GuiSwInit {} {  
  global gaSet tmpSw tmpCsl
  set tmpSw  $gaSet(soft)
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base +200+200
  wm resizable $base 1 1 
  wm title $base "SW init"
  pack [LabelEntry $base.entHW -label "LA's SW:  " \
      -justify center -textvariable tmpSw] -pady 1 -padx 3  
  pack [Separator $base.sep1 -orient horizontal] -fill x -padx 2 -pady 3
  pack [frame $base.frBut ] -pady 4 -anchor e
    pack [Button $base.frBut.butCanc -text Cancel -command ButCanc -width 7] -side right -padx 6
    pack [Button $base.frBut.butOk -text Ok -command ButOk -width 7]  -side right -padx 6
  
  focus -force $base
  grab $base
  return {}  
}


#***************************************************************************
#** ButOk
#***************************************************************************
proc ButOk {} {
  global gaSet lp
  #set lp [PasswdDlg .topHwInit.passwd -parent .topHwInit]
  set login 1 ; #[lindex $lp 0]
  set pw    1 ; #[lindex $lp 1]
  if {$login!="1" || $pw!="1"} {
    #exec c:\\rlfiles\\Tools\\btl\\beep.exe &
    RLSound::Play information
    tk_messageBox -icon error -title "Access denied" -message "The Login or Password isn't correct" \
       -type ok
  } else {
    set sw  [.topHwInit.entHW cget -text]
    puts "$sw"
    set gaSet(soft) $sw
    SaveInit
  }
  ButCanc
}


#***************************************************************************
#** ButCanc -- 
#**
#** Abstract:
#**
#** Inputs:
#** Outputs:
#** Returned code:
#***************************************************************************
proc ButCanc {} {
  grab release .topHwInit
  focus .
  destroy .topHwInit
}



#***************************************************************************
#** GuiInventory
#***************************************************************************
proc GuiInventory {} {  
  global gaSet gaTmp gaGui gaTmpSet  
  
  if {![info exists gaSet(DutFullName)] || $gaSet(DutFullName)==""} {
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play failbeep    
    set txt "Define the UUT first"
    DialogBox -title "Wrong UUT" -message $txt -type OK -icon images/error
    focus -force $gaGui(entDUT)
    return -1
  }
  
  array unset gaTmpSet
  
  foreach indx {2 3 4 Only4 3A ExtClk dg defConf} { 
    if ![info exists gaSet([set indx]CF)] {set gaSet([set indx]CF) c:/aa}
    set gaTmpSet([set indx]CF)  $gaSet([set indx]CF)
  }
  
  ## for new product, which has not an init file, fill all fields by ?? and aa
  ## 29/12/2016 14:46:20
  if {![file exists uutInits/$gaSet(DutInitName)]} {
    set parL [list defConfEn clkOpt sk ps 10G 1G]
    foreach par $parL {
      set gaSet($par) ??
      set gaTmpSet($par) ??
    }
    foreach indx {2 3 4 Only4 3A ExtClk dg defConf} { 
      set gaSet([set indx]CF)  c:/aa
      set gaTmpSet([set indx]CF)  c:/aa
    }
  }
  
  set parL [list defConfEn clkOpt sk ps 10G 1G]
  foreach par $parL {
    if ![info exists gaSet($par)] {set gaSet($par) ??}
    set gaTmpSet($par) $gaSet($par)
  }
  
  if ![info exists gaSet(sw)] {set gaSet(sw) 0.0}
  set gaTmpSet(sw)  $gaSet(sw)
  if ![info exists gaSet(dbrSW)] {set gaSet(dbrSW) 0.0}
  set gaTmpSet(dbrSW)  $gaSet(dbrSW)
  
  if ![info exists gaSet(swPack)] {
    set gaSet(swPack)  "NA" 
  }
  set gaTmpSet(swPack)  $gaSet(swPack)
  
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1 
  wm title $base "Inventory"
#   pack [LabelEntry $base.entSW -label "SW:  " -width 25\
#       -justify center -textvariable gaTmp(sw)] -pady 1 -padx 3     
  
  set inx 0
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.labSW  -text "SW Ver" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [Entry $fr.cbSW -justify center -state disabled -editable 0 -textvariable gaTmpSet(dbrSW)] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.labSW  -text "SW Pack" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [Entry $fr.cbSW -justify center -editable 1 -textvariable gaTmpSet(swPack)] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  
  pack [Separator $base.sep[incr inx] -orient horizontal] -fill x -padx 2 -pady 3
  
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.labdefConfEn  -text "Def. Conf." -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [checkbutton $fr.cbdefConfEn -justify center -variable gaTmpSet(defConfEn)] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.labPs  -text "PS" -width 15 -justify left] -pady 1 -padx 2 -anchor w -side left
    pack [ComboBox $fr.cbPs -justify center -state disabled -editable 0 -textvariable gaTmpSet(ps) -values {AC DC}] -pady 1 -padx 2 -anchor w -side left
  pack $fr -anchor w 
  
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.lab10G  -text "10G ports" -width 15 -justify left] -pady 1 -padx 2 -anchor w -side left
    pack [ComboBox $fr.cb10G -justify center -state disabled -editable 0 -textvariable gaTmpSet(10G) -values {2 3 4}] -pady 1 -padx 2 -anchor w -side left
  pack $fr -anchor w 
  
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.lab1G  -text "1G ports" -width 15 -justify left] -pady 1 -padx 2 -anchor w -side left
    pack [ComboBox $fr.cb1G -justify center -state disabled -editable 0 -textvariable gaTmpSet(1G) \
         -values {10SFP 10UTP 20SFP 20UTP 10SFP_10UTP None}] -pady 1 -padx 2 -anchor w -side left
  pack $fr -anchor w
  
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.labclkOpt  -text "Clk. Option" -width 15 -justify left] -pady 1 -padx 2 -anchor w -side left
    pack [ComboBox $fr.cbclkOpt -state disabled -justify center -editable 0 -textvariable gaTmpSet(clkOpt) -values {SYE PTP}] -pady 1 -padx 2 -anchor w -side left
  pack $fr -anchor w 
  
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    pack [Label $fr.labSk  -text "ESK-BSK" -width 15 -justify left] -pady 1 -padx 2 -anchor w -side left
    pack [ComboBox $fr.cbSk -justify center -state disabled -editable 0 -textvariable gaTmpSet(sk) -values {ESK BSK}] -pady 1 -padx 2 -anchor w -side left
  pack $fr -anchor w 
  
  pack [Separator $base.sep[incr inx] -orient horizontal] -fill x -padx 2 -pady 3

  set txtWidth 30
  set indx 1
  set fr [frame $base.fr[incr inx] -bd 0 -relief groove]
    set txt "Browse Dying Gasp Conf File..."
    set f dgCF
    pack [Button $fr.brw -text $txt -width $txtWidth -command [list BrowseCF $txt $f]] -side left -pady 1 -padx 3 -anchor w
    pack [Label $fr.lab  -textvariable gaTmpSet($f)] -pady 1 -padx 3 -anchor w
  pack $fr  -fill x -pady 3       
  
  foreach indx {2 3 4 Only4 3A} {
    set fr [frame $base.frF$indx -bd 0 -relief groove]
      set txt "Browse [set indx]XFP Conf File..."
      set f [set indx]CF
      pack [Button $fr.brw -text $txt -width $txtWidth -command [list BrowseCF $txt $f]] -side left -pady 1 -padx 3 -anchor w
      pack [Label $fr.lab  -textvariable gaTmpSet($f)] -pady 1 -padx 3 -anchor w
    pack $fr  -fill x -pady 3
  } 
  
  set indx ExtClk
  set fr [frame $base.frF$indx -bd 0 -relief groove]
    set txt "Browse ExtClk Conf File..."
    set f [set indx]CF
    pack [Button $fr.brw -text $txt -width $txtWidth -command [list BrowseCF $txt $f]] -side left -pady 1 -padx 3 -anchor w
    pack [Label $fr.lab  -textvariable gaTmpSet($f)] -pady 1 -padx 3 -anchor w
  pack $fr  -fill x -pady 3
  
  #pack [Separator $base.sep4 -orient horizontal] -fill x -padx 2 -pady 3
  
  set indx defConf
  set fr [frame $base.frF$indx -bd 0 -relief groove]
    set txt "Browse Default Conf File..."
    set f [set indx]CF
    pack [Button $fr.brw -text $txt -width $txtWidth -command [list BrowseCF $txt $f]] -side left -pady 1 -padx 3 -anchor w
    pack [Label $fr.lab  -textvariable gaTmpSet($f)] -pady 1 -padx 3 -anchor w
  pack $fr  -fill x -pady 3 
  
  pack [Separator $base.sep[incr inx] -orient horizontal] -fill x -padx 2 -pady 3
  
  pack [frame $base.frBut ] -pady 4 -anchor e
#     pack [Button $base.frBut.butCanc -text Cancel -command ButCancInventory -width 7] -side right -padx 6
#     pack [Button $base.frBut.butOk -text Ok -command ButOkInventory -width 7]  -side right -padx 6
    pack [Button $base.frBut.butImp -text Import -command ButImportInventory -width 7] -side right -padx 6
    pack [Button $base.frBut.butCanc -text Cancel -command ButCancInventory -width 7] -side right -padx 6
    pack [Button $base.frBut.butOk -text Ok -command ButOkInventory -width 7]  -side right -padx 6
  
  focus -force $base
  grab $base
  return {}  
}
# ***************************************************************************
# BrowseCF
# ***************************************************************************
proc BrowseCF {txt f} {
  global gaTmpSet
  set gaTmpSet($f) [tk_getOpenFile -title $txt -initialdir "[pwd]/ConfFiles"]
  focus -force .topHwInit
}
# ***************************************************************************
# ButImportInventory
# ***************************************************************************
proc ButImportInventory {} {
  global gaSet gaTmpSet
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl ]
  if {$fil!=""} {  
    set gaTmpSet(DutFullName) $gaSet(DutFullName)
    set gaTmpSet(DutInitName) $gaSet(DutInitName)
    set DutInitName $gaSet(DutInitName)
    
    source $fil
    set parL [list sk sw swPack ps dgCF 10G 1G 2CF 3CF 4CF Only4CF 3ACF defConfCF clkOpt]
    foreach par $parL {
      set gaTmpSet($par) $gaSet($par)
    }
    
    set gaSet(DutFullName) $gaTmpSet(DutFullName)
    set gaSet(DutInitName) $DutInitName ; #xcxc ; #gaTmpSet(DutInitName)    
  }    
  focus -force .topHwInit
}
#***************************************************************************
#** ButOk
#***************************************************************************
# proc ButOkInventory {} {
#   global gaSet gaTmp
#   if {$gaTmp(sw)!=""} {
#     set gaSet(sw) $gaTmp(sw)
#   }
#   if {$gaTmp(dgCF)!=""} {
#     set gaSet(dgCF) $gaTmp(dgCF)
#   }
#   foreach indx {2 3 4 Only4 3A ExtClk defConf} {
#     if {$gaTmp([set indx]CF)!=""} {
#       set gaSet([set indx]CF) $gaTmp([set indx]CF)
#     }
#   } 
#   SaveInit
#   ButCancInventory
# }
# ***************************************************************************
# ButOkInventory
# ***************************************************************************
proc ButOkInventory {} {
  global gaSet gaTmpSet
  
#   set saveInitFile 0
#   foreach nam [array names gaTmpSet] {
#     if {$gaTmpSet($nam)!=$gaSet($nam)} {
#       puts "ButOkInventory1 $nam tmp:$gaTmpSet($nam) set:$gaSet($nam)"
#       #set gaSet($nam) $gaTmpSet($nam)      
#       set saveInitFile 1 
#       break
#     }  
#   }
  
  set saveInitFile 1  
  if {$saveInitFile=="1"} {
    set res Save
    if {[file exists uutInits/$gaSet(DutInitName)]} {
      set txt "Init file for \'$gaSet(DutFullName)\' exists.\n\nAre you sure you want overwright the file?"
      set res [DialogBox -title "Save init file" -message  $txt -icon images/question \
          -type [list Save "Save As" Cancel] -default 2]
      if {$res=="Cancel"} {array unset gaTmpSet ; return -1}
    }
    if ![file exists uutInits] {
      file mkdir uutInits
    }
    if {$res=="Save"} {
      #SaveUutInit uutInits/$gaSet(DutInitName)
      set fil "uutInits/$gaSet(DutInitName)"
    } elseif {$res=="Save As"} {
      set fil [tk_getSaveFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl ]
      if {$fil!=""} {        
        set fil1 [file tail [file rootname $fil]]
        puts fil1:$fil1
        set gaSet(DutInitName) $fil1.tcl
        set gaSet(DutFullName) $fil1
        #set gaSet(entDUT) $fil1
        wm title . "$gaSet(pair) : $gaSet(DutFullName)"
        #SaveUutInit $fil
        update
      }
    } 
    puts "\nButOkInventory fil:<$fil>"
    if {$fil!=""} {
      foreach nam [array names gaTmpSet] {
        if {$gaTmpSet($nam)!=$gaSet($nam)} {
          puts "ButOkInventory2 $nam tmp:$gaTmpSet($nam) set:$gaSet($nam)"
          set gaSet($nam) $gaTmpSet($nam)      
        }  
      }
      SaveUutInit $fil
    } 
  }
  array unset gaTmpSet
  SaveInit
  BuildTests
  ButCancInventory
}



#***************************************************************************
#** ButCancInventory
#***************************************************************************
proc ButCancInventory {} {
  grab release .topHwInit
  focus .
  destroy .topHwInit
}


#***************************************************************************
#** Quit
#***************************************************************************
proc Quit {} {
  global gaSet
  SaveInit
  set ret [DialogBox -title "Confirm exit"\
      -type "yes no" -icon /images/question -aspect 2000\
      -text "Are you sure you want to close the application?"]
  if {$ret=="yes"} {CloseRL; IPRelay-Green; exit}
}

#***************************************************************************
#** CaptureConsole
#***************************************************************************
proc CaptureConsole {} {
  console eval { 
    set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
    set fi c:\\temp\\ConsoleCapt_[set ti].txt
    if [file exists $fi] {
      set res [tk_messageBox -title "Save Console Content" \
        -icon info -type yesno \
        -message "File $fi already exist.\n\
               Do you want overwrite it?"]      
      if {$res=="no"} {
         set types { {{Text Files} {.txt}} }
         set new [tk_getSaveFile -defaultextension txt \
                 -initialdir c:\\temp -initialfile [file rootname $fi]  \
                 -filetypes $types]
         if {$new==""} {return {}}
      }
    }
    set aa [.console get 1.0 end]
    set id [open $fi w]
    puts $id $aa
    close $id
  }
}
#***************************************************************************
#** PairPerfLab
#***************************************************************************
proc PairPerfLab {lab bg} {
  global gaGui gaSet
  $gaGui(labPairPerf$lab) configure -bg $bg
}

# ***************************************************************************
# AllPairPerfLab
# ***************************************************************************
proc AllPairPerfLab {bg} {
  for {set i 1} {$i <= 27} {incr i} {
    PairPerfLab $i $bg
  }
}
# ***************************************************************************
# TogglePairBut
# ***************************************************************************
proc TogglePairBut {pair} {
  global gaGui gaSet
  set _toTestClr $gaSet(toTestClr)
  set _toNotTestClr $gaSet(toNotTestClr)
  set bg  [$gaGui(labPairPerf$pair) cget -bg]
  set _bg $bg
  #puts "pair:$pair bg1:$bg"
  if {$bg=="gray" || $bg==$_toNotTestClr} {
    ## initial state, for change to _toTest change it to blue
    set _bg $_toTestClr
  } elseif {$bg==$_toTestClr || $bg=="green" || $bg=="red" || $bg==$gaSet(halfPassClr)} {
    ## for under Test, pass or fail - for change to _toNoTest change it to gray
    set _bg $_toNotTestClr
    IPRelay-Green
  } 
  $gaGui(labPairPerf$pair) configure -bg $_bg
}
# ***************************************************************************
# TogglePairButAll
# ***************************************************************************
proc TogglePairButAll {mode} {
  global gaGui   gaSet
  set _toNotTestClr $gaSet(toNotTestClr)
  set _toTestClr $gaSet(toTestClr)
  if {$mode=="0"} {
    set _bg $_toNotTestClr
  } elseif {$mode=="All"} {
    set _bg $_toTestClr
  }
  for {set pair 1} {$pair <= 27} {incr pair} {
    $gaGui(labPairPerf$pair) configure -bg $_bg
  }
}
# ***************************************************************************
# PairsToTest
# ***************************************************************************
proc PairsToTest {} {
  global gaGui gaSet
  set _toTestClr $gaSet(toTestClr)
  set l [list]
  for {set i 1} {$i <= 27} {incr i} {
    set bg  [$gaGui(labPairPerf$i) cget -bg]
    if {$bg==$_toTestClr} {
      lappend l $i
    }
  }
  return $l
}

# ***************************************************************************
# CheckPairsToTest
# ***************************************************************************
proc CheckPairsToTest {} {
  global gaGui gaSet
  set l [list]
  for {set i 1} {$i <= 27} {incr i} {
    set bg  [$gaGui(labPairPerf$i) cget -bg]
    if {$bg!=$gaSet(toNotTestClr)} {
      lappend l $i
    }
  }
  return $l
}

# ***************************************************************************
# TogglePorts
# ***************************************************************************
proc TogglePorts {} {
  return 0
  global gaGui gaSet
  switch -exact -- [$gaGui(cb10G) cget -text] {
    2 {set pL "20SFP 20UTP 10SFP_10UTP"}
    3 {set pL "10SFP 10UTP"}
    4 {set pL "10SFP 10UTP None"}
  }
  
  $gaGui(cb1G) configure -values $pL  
  
  ## if 1G port is configured as one of possibility ports of 10G port,
  ## do nothing, else set the 1G port as first port from 10G port's list 
  set 1G [$gaGui(cb1G) cget -text]
  if {[lsearch $pL $1G]!="-1"} {
    ## do nothing
  } else {  
    set gaSet(1G) [lindex $pL 0]
  }
  BuildTests
  update
}
#-values "10SFP 10UTP 20SFP 20UTP 10SFP_10UTP"

# ***************************************************************************
# ToogleEraseTitle
# ***************************************************************************
proc ToogleEraseTitle {changeTo} {
  global gaSet
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  if {$gaSet(eraseTitle)==1 && $changeTo==0} {
    set gaSet(eraseTitle) 0
#     set log ""
#     while 1 {
#       set p [PasswdDlg .p -parent . -type okcancel]
#       if {[llength $p]==0} {
#         ## cancel button
#         return {}
#       } else {
#         foreach {log pass} $p {}
#       }
#       if {$log=="rad" && $pass=="123"} {set gaSet(eraseTitle) 0; break}
#     }
  }
  if {$changeTo==1} {
    set gaSet(eraseTitle) 1
    wm title . "$gaSet(pair) : "
  }  
}
# ***************************************************************************
# ShowComs
# ***************************************************************************
proc ShowComs {} {                                                                        
  global gaSet gaGui
  DialogBox -title "COMs definitions" -type OK \
    -message "UUT: COM $gaSet(comDut)\nETX204-Gen: COM $gaSet(comGEN)"
  return {}
}
# ***************************************************************************
# GuiReadOperator
# ***************************************************************************
proc GuiReadOperator {} {
  global gaSet gaGui gaDBox gaGetOpDBox
  catch {array unset gaDBox} 
  catch {array unset gaGetOpDBox} 
  #set ret [GetOperator -i pause.gif -ti "title Get Operator" -te "text Operator's Name "]
  set sn [clock seconds]
  set ret [GetOperator -i images/oper32.ico -gn $::RadAppsPath]
  incr ::wastedSecs [expr {[clock seconds]-$sn}]
  if {$ret=="-1"} {
    set gaSet(fail) "No Operator Name"
    return $ret
  } else {
    set gaSet(operator) $ret
    return 0
  }
} 

# ***************************************************************************
# GuiReleaseDebugMode
# ***************************************************************************
proc GuiReleaseDebugMode {} {
  global gaSet gaGui gaTmpSet glTests 
  
  set base .topReleaseDebugMode
  if [winfo exists $base] {
    wm deiconify $base
    return {}
  }
    
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1 
  wm title $base "Release/Debug Mode"
  
   array unset gaTmpSet
   
  if ![info exists gaSet(relDebMode)] {
    set gaSet(relDebMode) Release  
  }
  foreach par {relDebMode} {
    set gaTmpSet($par) $gaSet($par) 
  }
    
  set fr1 [ttk::frame $base.fr1 -relief groove]
    set fr11 [ttk::frame $fr1.fr11]
      set gaGui(rbRelMode) [ttk::radiobutton $fr11.rbRelMode -text "Release Mode" -variable gaTmpSet(relDebMode) -value Release -command ToggleRelDeb]
      set gaGui(rbDebMode) [ttk::radiobutton $fr11.rbDebMode -text "Debug Mode" -variable gaTmpSet(relDebMode) -value Debug -command ToggleRelDeb]
      set gaGui(butBuildTest) [ttk::button $fr11.butBuildTest -text "Refresh Tests" \
           -command {
               BuildTests
               after 200
               ButCancReleaseDebugMode
               after 100
               update
               GuiReleaseDebugMode
           }]      
      pack $gaGui(rbRelMode) $gaGui(rbDebMode) $gaGui(butBuildTest) -anchor nw
      
    set fr12 [ttk::frame $fr1.fr12]
      set fr121 [ttk::frame $fr12.fr121]
        set l2 [ttk::label $fr121.l2 -text "Available Tests"]
        pack $l2 -anchor w
        scrollbar $fr121.yscroll -command {$gaGui(lbAllTests) yview} -orient vertical
        pack $fr121.yscroll -side right -fill y
        set gaGui(lbAllTests) [ListBox $fr121.lb1  -selectmode multiple \
            -yscrollcommand "$fr121.yscroll set" -height 25 -width 33 \
            -dragenabled 1 -dragevent 1 -dropenabled 1 -dropcmd DropRemTest]
        pack $gaGui(lbAllTests) -side left -fill both -expand 1
        
      set fr122 [frame $fr12.fr122 -bd 0 -relief groove]
        grid [button $fr122.b0 -text ""   -command {} -state disabled -relief flat] -sticky ew
        $fr122.b0 configure -background [ttk::style lookup . -background disabled]
        grid [set gaGui(addOne) [ttk::button $fr122.b3 -text ">"  -command {AddTest sel}]] -sticky ew
        grid [set gaGui(addAll) [ttk::button $fr122.b4 -text ">>" -command {AddTest all}]] -sticky ew
        grid [set gaGui(remOne) [ttk::button $fr122.b5 -text "<"  -command {RemTest sel}]] -sticky ew
        grid [set gaGui(remAll) [ttk::button $fr122.b6 -text "<<" -command {RemTest all}]] -sticky ew
            
      set fr123 [frame $fr12.fr123 -bd 0 -relief groove]  
        set l3 [Label $fr123.l3 -text "Tests to run"]
        pack $l3 -anchor w  
        scrollbar $fr123.yscroll -command {$gaGui(lbTests) yview} -orient vertical  
        pack $fr123.yscroll -side right -fill y
        set gaGui(lbTests) [ListBox $fr123.lb2  -selectmode multiple \
            -yscrollcommand "$fr123.yscroll set" -height 25 -width 33 \
            -dragenabled 1 -dragevent 1 -dropenabled 1 -dropcmd DropAddTest] 
        pack $gaGui(lbTests) -side left -fill both -expand 1  
      
      grid $fr121 $fr122 $fr123 -sticky news  
          
    pack $fr11 -side left -padx 14 -anchor n -pady 2
    pack $fr12 -side left -padx 2 -anchor n -pady 2
  pack $fr1  -padx 2 -pady 2
  pack [ttk::frame $base.frBut] -pady 4 -anchor e    -padx 2 
    #pack [Button $base.frBut.butImp -text Import -command ButImportInventory -width 7] -side right -padx 6
    pack [ttk::button $base.frBut.butCanc -text Cancel -command ButCancReleaseDebugMode -width 7] -side right -padx 6
    pack [ttk::button $base.frBut.butOk -text Ok -command ButOkReleaseDebugMode -width 7]  -side right -padx 6
  
  #BuildTests
  ##ToggleTestMode  ; just in ASMi54
  foreach te $glTests {
    $gaGui(lbAllTests) insert end $te -text $te
  }
  
  ToggleRelDeb
  
  focus -force $base
  grab $base
  return {}  
}
# ***************************************************************************
# ButCancReleaseDebugMode
# ***************************************************************************
proc ButCancReleaseDebugMode {} {
  grab release .topReleaseDebugMode
  focus .
  destroy .topReleaseDebugMode
}
# ***************************************************************************
# ButOkReleaseDebugMode
# ***************************************************************************
proc ButOkReleaseDebugMode {} {
  global gaGui gaSet gaTmpSet glTests
  
  if {[llength [$gaGui(lbTests) items]]==0} {
    return 0
  }
  
  set gaSet(relDebMode) $gaTmpSet(relDebMode) 
  
  set glTests [$gaGui(lbTests) items]
  set gaSet(startFrom) [lindex $glTests 0]
  
  $gaGui(startFrom) configure -values $glTests
  if {$gaSet(relDebMode)=="Debug"} {
    set gaSet(debugTests) $glTests
  }
  
  if {[llength [$gaGui(lbAllTests) items]] != [llength [$gaGui(lbTests) items]]} {
    Status "Debug Mode" red
  }
  array unset gaTmpSet
  #SaveInit
  #BuildTests
  ButCancReleaseDebugMode
}  
# ***************************************************************************
# AddTest
# ***************************************************************************
proc AddTest {mode} {
   global gaSet gaGui
   if {$mode=="sel"} {
     set ftL [$gaGui(lbAllTests) selection get]
   } elseif {$mode=="all"} {
     set ftL [$gaGui(lbAllTests) items]
   }
   foreach ft $ftL {
     if {[lsearch [$gaGui(lbTests) items] $ft]=="-1"} {
       $gaGui(lbTests) insert end $ft -text $ft
     }
   }
   $gaGui(lbAllTests) selection clear
   $gaGui(lbTests) reorder [lsort -dict [$gaGui(lbTests) items]]
}
# ***************************************************************************
# RemTest
# ***************************************************************************
proc RemTest {mode} {
   global gaSet gaGui
   if {$mode=="sel"} {
     set ftL [$gaGui(lbTests) selection get]
   } elseif {$mode=="all"} {
     set ftL [$gaGui(lbTests) items]
     eval $gaGui(lbTests) selection set $ftL
#      RLSound::Play beep
#      set res [DialogBox -title "Remove all tests" -type [list Cancel Yes] \
#        -text "Are you sure you want to remove ALL the tests?" -icon images/info]
#      if {$res=="Cancel"} {
#        $gaGui(lbTests) selection clear
#        return {}
#      }
   }
   foreach ft $ftL {
     $gaGui(lbTests) delete $ftL
   }
}
# ***************************************************************************
# DropAddTest
# ***************************************************************************
proc DropAddTest {listbox dragsource itemList operation datatype data} {
  puts [list $listbox $dragsource $itemList $operation $datatype $data]
  global gaSet gaGui
  if {$dragsource=="$gaGui(lbAllTests).c"} {
    set ft $data
    if {[lsearch [$gaGui(lbTests) items] $ft]=="-1"} {
      $gaGui(lbTests) insert end $ft -text $ft
    }
    $gaGui(lbTests) reorder [lsort -dict [$gaGui(lbTests) items]]
  } elseif {$dragsource=="$gaGui(lbTests).c"} {
    set destIndx [$gaGui(lbTests) index [lindex $itemList 1]]
    $gaGui(lbTests) move $data $destIndx
    $gaGui(lbTests) selection clear
    
  }
}
# ***************************************************************************
# DropRemTest
# ***************************************************************************
proc DropRemTest {listbox dragsource itemList operation datatype data} {
  puts [list $listbox $dragsource $itemList $operation $datatype $data]
  global gaSet gaGui gaTmpSet
  if {$gaTmpSet(relDebMode)=="Debug"} {
    if {$dragsource=="$gaGui(lbTests).c"} {
      set ft $data
      $gaGui(lbTests) delete $ft
    }
  }
}
# ***************************************************************************
# ToggleRelDeb
# ***************************************************************************
proc ToggleRelDeb {} {
  global gaGui gaTmpSet
  if {$gaTmpSet(relDebMode)=="Release"} {
    puts "ToggleRelDeb Release"
    #BuildTests
    after 100
    AddTest all
    set state disabled
  } elseif {$gaTmpSet(relDebMode)=="Debug"} {
    puts "ToggleRelDeb Debug"
    RemTest all
    after 100 ; update
    set state normal
    if {[info exists gaSet(debugTests)] && [llength $gaSet(debugTests)]>0} {
      foreach ft $gaSet(debugTests) {
        if {[lsearch [$gaGui(lbTests) items] $ft]=="-1"} {
          $gaGui(lbTests) insert end $ft -text $ft
        }
      }
    }
  }
  foreach b [list $gaGui(addOne) $gaGui(addAll) $gaGui(remOne) $gaGui(remAll)] {
    $b configure -state $state
  }
}
