
##***************************************************************************
##** OpenRL
##***************************************************************************
proc OpenRL {} {
  global gaSet
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  RLEH::Open
  RLSound::Open
  puts "Open PIO [MyTime]"
  set ret1 [OpenPio]
  set ret2 [OpenComUut] 
  set gaSet(curTest) $curTest  
  if {$ret1!=0 || $ret2!=0} {
    return -1
  } 
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  RLSerial::Open $gaSet(comDut) 9600 n 8 1
  return 0
}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  catch {RLSerial::Close $gaSet(comDut)}
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  ClosePio
  puts "CloseRL ClosePio" ; update
  
  CloseComUut
  puts "CloseRL CloseComUut" ; update
  
  catch {RLEtxGen::CloseAll}
  puts "CloseRL EtxGen" ; update
  
  
  catch {RLEH::Close}
}  

# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  # parray ::RLUsbPio::description *Ser*
  if {$gaSet(pioType)=="Ex"} {
    return 1
  }
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
  if {[llength $boxL]!=28} {
    set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
    return -1
  }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet
  
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  foreach rb {1 2} {
    set gaSet(idPwr$rb)  [RL[set gaSet(pioType)]Pio::Open $gaSet(pioPwr$rb) RBA $channel]
  }
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet gaFS
  set ret 0
  foreach rb "1 2" {
	  catch {RL[set gaSet(pioType)]Pio::Close $gaSet(idPwr$rb)}
  }
  return $ret
}

# ***************************************************************************
# SaveUutInit
# ***************************************************************************
proc SaveUutInit {fil} {
  global gaSet
  set id [open $fil w]
  puts $id "set gaSet(sk)          \"$gaSet(sk)\""
  puts $id "set gaSet(sw)          \"$gaSet(sw)\""
  puts $id "set gaSet(dbrSW)       \"$gaSet(dbrSW)\""
  puts $id "set gaSet(ps)          \"$gaSet(ps)\""
  puts $id "set gaSet(defConfEn)   \"$gaSet(defConfEn)\""
  puts $id "set gaSet(dgCF)        \"$gaSet(dgCF)\""
  
  
  puts $id "set gaSet(10G)         \"$gaSet(10G)\""
  puts $id "set gaSet(1G)          \"$gaSet(1G)\""
  #puts $id "set gaSet(uaf)        \"$gaSet(uaf)\""
  foreach indx {2 3 4 Only4 3A ExtClk defConf} {
    puts $id "set gaSet([set indx]CF) \"$gaSet([set indx]CF)\""
  }
   
  if {![info exists gaSet(clkOpt)]} {
    set gaSet(clkOpt) PTP
  }  
  puts $id "set gaSet(clkOpt)   \"$gaSet(clkOpt)\""
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(DutFullName) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
  if ![info exists gaSet(swPack)] {
    set gaSet(swPack)  "NA" 
  }
  puts $id "set gaSet(swPack) \"$gaSet(swPack)\""
  close $id
}  


#***************************************************************************
#** SaveInit 
#***************************************************************************
proc SaveInit {} {
  global gaSet
  set id [open [info host]/init$gaSet(pair).tcl w]
  
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  
  if {[info exists gaSet(iprelay)]} {
    puts $id "set gaSet(iprelay)   \"$gaSet(iprelay)\""
  }
  puts $id "set gaSet(TestMode)    \"$gaSet(TestMode)\""
       
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(entDUT) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
  puts $id "set gaSet(ddrRunQty)   \"$gaSet(ddrRunQty)\""
  puts $id "set gaSet(ddrSOF)   \"$gaSet(ddrSOF)\""
  
  if [info exists gaSet(pioType)] {
    set pioType $gaSet(pioType)
  } else {
    set pioType Ex
  }  
  puts $id "set gaSet(pioType) \"$pioType\""
  
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  puts $id "set gaSet(eraseTitle) \"$gaSet(eraseTitle)\""
  
  close $id
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}

#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [RLCom::Send $com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent expected {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

##  set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  set cmd [list RLSerial::Send $com $sent buffer $expected $timeOut]
  
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } elseif {[scan $car %c]=="10"} {
      append sentNew "\\n"
    } {
      append sentNew $car
    }
  }
  set sent $sentNew
  
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J} $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=$expected,  buffer=<$b3>"
    puts "send: ----------------------------------------\n"
    update
  }
  
  RLTime::Delayms 50
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  update
}


##***************************************************************************
##** Wait
##***************************************************************************
proc Wait {txt count color} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	 $gaSet(runTime) configure -text $i
	 RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}

#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}


# ***************************************************************************
# MyWaitFor
# ***************************************************************************
proc MyWaitFor {com expected testEach timeout} {
  global buffer gaGui gaSet
  #Status "Waiting for \"$expected\""
  if {$gaSet(act)==0} {return -2}
  puts [MyTime] ; update
  set startTime [clock seconds]
  set runTime 0
  while 1 {
    set ret [RLSerial::Waitfor $com buffer stam $testEach]
    foreach expd $expected {
      Send $com \r stam 0.25
      puts "expected:\"$expected\" expd:$expd ret:$ret runTime:$runTime" ; update
      
      if [string match *$expd* $buffer] {
        set ret 0
        break
      }
    }
    #set ret [Send $com \r $expected $testEach]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    $gaSet(runTime) configure -text $runTime
    #puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
    if {$runTime>$timeout} {break }
    if {$gaSet(act)==0} {set ret -2 ; break}
    update
  }
  puts "[MyTime] runTime:$runTime"
  $gaSet(runTime) configure -text ""
  Status ""
  return $ret
}


#***************************************************************************
#** Power
#***************************************************************************
proc Power {ps state} {
  global gaSet gaGui 
  puts "[MyTime] Power $ps $state"
  set ret 0
  switch -exact -- $ps {
    1   {set pioL 1}
    2   {set pioL 2}
    all {set pioL "1 2"}
  } 
  switch -exact -- $state {
    on  {
	    foreach pio $pioL {      
        RL[set gaSet(pioType)]Pio::Set $gaSet(idPwr$pio) 1
      }
    } 
	  off {
	    foreach pio $pioL {
	      RL[set gaSet(pioType)]Pio::Set $gaSet(idPwr$pio) 0
      }
    }
  }
#   $gaGui(tbrun)  configure -state disabled 
#   $gaGui(tbstop) configure -state normal
  Status ""
  update
  #exec C:\\RLFiles\\Btl\\beep.exe &
#   RLSound::Play information
  return $ret
}

#***************************************************************************
#** PowerOffOn
#***************************************************************************
proc PowerOffOn {} {
  Power all off
  RLTime::Delay 2
  Power all on
}
# ***************************************************************************
# GuiPower
# ***************************************************************************
proc GuiPower {n state} { 
  global gaSet 
  RLEH::Open
  switch -exact -- $n {
    1.1 - 2.1 - 3.1 - 4.1 {set portL [list $gaSet(pioPwr1)]}
    1.2 - 2.2 - 3.2 - 4.2 {set portL [list $gaSet(pioPwr2)]}      
    1 - 2 - 3 - 4  {set portL [list $gaSet(pioPwr1) $gaSet(pioPwr2)]}  
  }        
  set channel [RetriveUsbChannel]
  foreach rb $portL {
    set id [RL[set gaSet(pioType)]Pio::Open $rb RBA $channel]
    puts "rb:<$rb> id:<$id>"
    RL[set gaSet(pioType)]Pio::Set $id $state
    RL[set gaSet(pioType)]Pio::Close $id 
  }
  RLEH::Close
} 
#***************************************************************************
#** Wait
#***************************************************************************
proc _Wait {ip_time ip_msg {ip_cmd ""}} {
  global gaSet 
  Status $ip_msg 

  for {set i $ip_time} {$i >= 0} {incr i -1} {       	 
	 if {$ip_cmd!=""} {
      set ret [eval $ip_cmd]
		if {$ret==0} {
		  set ret $i
		  break
		}
	 } elseif {$ip_cmd==""} {	   
	   set ret 0
	 }

	 #user's stop case
	 if {$gaSet(act)==0} {		 
      return -2
	 }
	 
	 RLTime::Delay 1	 
    $gaSet(runTime) configure -text " $i "
	 update	 
  }
  $gaSet(runTime) configure -text ""
  update   
  return $ret  
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
#   set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
  set id [open $gaSet(logFile) a+]
  puts $id "..[MyTime]..$line"
  close $id
}
# ***************************************************************************
# AddToPairLog
# ***************************************************************************
proc AddToPairLog {pair line}  {
  global gaSet
  set logFileID [open $gaSet(log.$pair) a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# ShowLog
# ***************************************************************************
proc ShowLog {} {
	global gaSet
# 	exec notepad tmpFiles/logFile-$gaSet(pair).txt &
#   exec notepad $gaSet(logFile)  &
  exec notepad $gaSet(log.$gaSet(pair))   &
}


# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}
# ***************************************************************************
# Ping
# ***************************************************************************
proc Ping {dutIp} {
  global gaSet
  set i 0
  while {$i<=10} {
    if {$gaSet(act)==0} {return -2}
    incr i
    #------
    catch {exec arp.exe -d}  ;#clear pc arp table
    catch {exec ping.exe $dutIp -n 2} buffer
    if {[info exist buffer]!=1} {
	    set buffer "?"  
    }  
    set ret [regexp {Packets: Sent = 2, Received = 2, Lost = 0 \(0% loss\)} $buffer var]
    puts "ping i:$i ret:$ret buffer:<$buffer>"  ; update
    if {$ret==1} {break}    
    #------
    after 500
  }
  
  if {$ret!=1} {
    puts $buffer ; update
	  set gaSet(fail) "Ping fail"
 	  return -1  
  }
  return 0
}

# ***************************************************************************
# Filter
# ***************************************************************************
proc Filter {buffer} {
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " buff
  regsub -all -- {\x1B\x5B..\;..r} $buff " " buff
  regsub -all -- {\x1B\x5B.J} $buff " " buff
  set re \[\x1B\x0D-\]
  regsub -all -- $re $buff " " buff
  
  regsub -all {\s+} $buff " " buff
  regsub -all -- {[0-9]+ ALM [0-9]+} $buff " " buff
  regsub -all {\s+} $buff "  " buff
  
  regsub -all {\[[0-9]+m} $buff "  " buff
  regsub -all {\[m} $buff "  " buff 
  return $buff
}

# ***************************************************************************
# DownloadConfFile
# ***************************************************************************
proc DownloadConfFile {cf cfTxt save} {
  global gaSet  buffer
  puts "[MyTime] DownloadConfFile $cf $cfTxt $save"
  set com $gaSet(comDut)
  if ![file exists $cf] {
    set gaSet(fail) "The $cfTxt configuration file ($cf) doesn't exist"
    return -1
  }
  Status "Download Configuration File $cf" ; update
  set s1 [clock seconds]
  set id [open $cf r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {close $id ; return -2}
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      #puts "line:<$line>"
      if {[string match {*address*} $line] && [llength $line]==2} {
        if {[string match *DefaultConf* $cfTxt]} {
          ## don't change address in DefaultConf
        } else {
          ##  address 10.10.10.12/24
          set dutIp 10.10.10.1[set gaSet(pair)]
          set address [set dutIp]/[lindex [split [lindex $line 1] /] 1]
          set line "address $address"
        }
      }
      if {[string match *eeEXT* $cfTxt] || [string match *vvDefaultConf* $cfTxt]} {
        ## perform the configuration fast (without expected)
        set ret 0
        set buffer bbb
        RLSerial::Send $com "$line\r" 
      } else {
        if {[string match {*configure management login-user su shutdown*} $line]} {
          ## if a line contains a command, which will cause to UUT to ask
          ## a question (Are you sure?), and it will never return to path with
          ## '220', we send such line without waitfor
           
          set ret 0
          Send $com $line\r "yes/no" 4
        } else {
          set ret [Send $com $line\r 220 60]
        }
      }  
      if {$ret!=0} {
        set gaSet(fail) "Config of DUT failed"
        break
      }
      if {[string match {*cli error*} [string tolower $buffer]]==1} {
        set gaSet(fail) "CLI Error"
        set ret -1
        break
      }            
    }
  }
  close $id  
  if {$ret==0} {
    set ret [Send $com "exit all\r" "220"]
    if {$save==1} {
      set ret [Send $com "admin save\r" "successfull" 60]
    }
     
    set s2 [clock seconds]
    puts "[expr {$s2-$s1}] sec c:$c" ; update
  }
  Status ""
  puts "[MyTime] Finish DownloadConfFile" ; update
  return $ret 
}

# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {} {
  global gaSet gaGui
  Status "Please wait for retriving DBR's parameters"
  set barcode [set gaSet(entDUT) [string toupper $gaSet(entDUT)]] ; update
  
  set ret [MainEcoCheck $barcode]
  if {$ret!=0} {
    $gaGui(startFrom) configure -text "" -values [list]
    set gaSet(log.$gaSet(pair)) c:/logs/[clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"].txt
    AddToPairLog $gaSet(pair) $ret
    RLSound::Play information
    DialogBoxRamzor -type "OK" -icon /images/error -title "Unapproved changes" -message $ret
    Status ""
    return -2
  }
  
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  wm title . "$gaSet(pair) : "
  after 500
  
#   set javaLoc1 C:\\Program\ Files\\Java\\jre6\\bin\\
#   set javaLoc2 C:\\Program\ Files\ (x86)\\Java\\jre6\\bin\\
#   if {[file exist $javaLoc1]} {
#     set javaLoc $javaLoc1
#   } elseif {[file exist $javaLoc2]} {
#     set javaLoc $javaLoc2
#   } else {
#     set gaSet(fail) "Java application is missing"
#     return -1
#   }
   
  set javaLoc $gaSet(javaLocation)
  catch {exec $javaLoc\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b
  set fileName MarkNam_$barcode.txt
  after 1000
  if ![file exists MarkNam_$barcode.txt] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play failbeep
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  
  #set txt "$barcode $res"
  set txt "[string trim $res]"
  #set gaSet(entDUT) $txt
  set gaSet(entDUT) ""
  puts "GetDbrName <$txt>"
  
  set initName [regsub -all / $res .]
  set gaSet(DutFullName) $res
  set gaSet(DutInitName) $initName.tcl
  
  file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  if {[file exists uutInits/$gaSet(DutInitName)]} {
    source uutInits/$gaSet(DutInitName)  
    #UpdateAppsHelpText  
  } else {
    ## if the init file doesn't exist, fill the parameters by ? signs
    foreach v {sw hw bootVer uut eth e1} {
      set gaSet($v) ??
    }
    foreach en {licEn uafEn udfEn plEn} {
      set gaSet($v) 0
    } 
  } 
  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  pack forget $gaGui(frFailStatus)
  Status ""
  update
  set ret [RetriveDutFam]
  puts "GetDbrName ret of RetriveDutFam:$ret" ; update
  BuildTests
  
  set ret [GetDbrSW $barcode]
  puts "GetDbrName ret of GetDbrSW:$ret" ; update
  
  puts ""
  foreach indx {2 3 4 Only4 3A ExtClk dg} { 
    set gaSet([set indx]CF) "NA"
  }
  foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
    if {$10G=="2"} {
      set gaSet(2CF) "[pwd]/ConfFiles/2XFP.txt" 
    } elseif {$10G=="3"} {
      set gaSet(3CF) "[pwd]/ConfFiles/3XFP.txt" 
      set gaSet(3ACF) "[pwd]/ConfFiles/3XFPA.txt" 
    } elseif {$10G=="4" && $1G!="None"} {
      set gaSet(4CF) "[pwd]/ConfFiles/4XFP.txt" 
    } elseif {$10G=="4" && $1G=="None"} {
      set gaSet(Only4CF) "[pwd]/ConfFiles/4xfp_no_1g_ports.txt" 
    }
  }
  set gaSet(ExtClkCF) "[pwd]/ConfFiles/ExtClk.txt"
  
  regexp {(\d+\.\d+\.\d+)\(} $gaSet(dbrSW) - dbrSW
  puts "gaSet(dbrSW):<$gaSet(dbrSW)> dbrSW:<$dbrSW>" ; update
  if {$dbrSW>="5.9.1"} {
    set gaSet(dgCF) "[pwd]/ConfFiles/mng_5.9.1.txt"
  } elseif {$dbrSW<="5.8.0"} {
    set gaSet(dgCF) "[pwd]/ConfFiles/mng.txt"
  } else {
    puts dd
  }
  #mparray gaSet *il
  
  focus -force $gaGui(tbrun)
  if {$ret==0} {
    Status "Ready"
  }
}

# ***************************************************************************
# DelMarkNam
# ***************************************************************************
proc DelMarkNam {} {
  if {[catch {glob MarkNam*} MNlist]==0} {
    foreach f $MNlist {
      file delete -force $f
    }  
  }
}

# ***************************************************************************
# GetInitFile
# ***************************************************************************
proc GetInitFile {} {
  global gaSet gaGui
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl]
  if {$fil!=""} {
    source $fil
    set gaSet(entDUT) "" ; #$gaSet(DutFullName)
    wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    #UpdateAppsHelpText
    pack forget $gaGui(frFailStatus)
    Status ""
    BuildTests
    GuiInventory
  }
}
# ***************************************************************************
# RetriveDutFam
# RetriveDutFam [regsub -all / ETX-220A/ACR/4XFP/10U/SYE .].tcl
# ***************************************************************************
proc RetriveDutFam {{dutInitName ""}} {
  global gaSet 
  set gaSet(dutFam) NA 
  set gaSet(dutBox) NA 
  set gaSet(ps) NA
  set gaSet(10G) NA
  set gaSet(1G) NA
  set gaSet(clkOpt) NA
  set gaSet(sk) NA
  
  if {$dutInitName==""} {
    set dutInitName $gaSet(DutInitName)
  }
  puts "RetriveDutFam $dutInitName"
  
  if {[string match *.AC*.* $dutInitName]==1} {
    set ps AC
  } elseif {[string match *.DC*.* $dutInitName]==1} {
    set ps DC
  } 
  
  if {[string match *.*XFP.* $dutInitName]==1} {
    regexp {(\d)XFP} $dutInitName - 10G
  } else {
    set 10G NA
  }
  
  set 1G None
  if {[string match *.*U.* $dutInitName]==1} {
    regexp {(([1|2])0)U\.} $dutInitName - utpQty b
    set 1G ${utpQty}UTP
  }
  if {[string match *.*S.* $dutInitName]==1} {
    regexp {(([1|2])0)S\.} $dutInitName - sfpQty b
    set 1G ${sfpQty}SFP
  }
  if {[string match *.10U10S.* $dutInitName]==1} {
    set 1G 10SFP_10UTP
  }
  
  if {[string match *.PTP.* $dutInitName]==1} {
    set clkOpt PTP
  } elseif {[string match *.SYE.* $dutInitName]==1} {
    set clkOpt SYE
  } else {
    set clkOpt NA
  }
  
  if {[string match *.ESK.* $dutInitName]==1} {
    set sk ESK
  } elseif {[string match *.BSK.* $dutInitName]==1} {
    set sk BSK
  } else {
    set sk NA
  }
#   if {[string match *_FT.* $dutInitName]==1} {
#     set sk ESK
#   }
  set gaSet(dutFam) $ps.$10G.$1G.$clkOpt.$sk
  set gaSet(ps) $ps
  set gaSet(10G) $10G
  set gaSet(1G) $1G
  set gaSet(clkOpt) $clkOpt
  set gaSet(sk) $sk
  
  if 0 {
  set gaSet(dutFam) 0.0.None.0.0
  
  if {[string match *.H.* $dutInitName]==1 || [string match *.K.* $dutInitName]==1 ||\
      [string match *.HN.* $dutInitName]==1} {
    set optL  [list etx h ps 10G 1G clkOpt sk]
  } elseif {[string match *.SFP.* $dutInitName]==1} {
    set optL  [list etx ps sfp 10G 1G clkOpt sk]
  } else {
    set optL  [list etx ps 10G 1G clkOpt sk]
  }
  
  if {[string match *.AC*.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) AC.$10G.$1G.$clkOpt.$sk  
    }
  }
  if {[string match *.DC*.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) DC.$10G.$1G.$clkOpt.$sk  
    }
  }
  if {[string match *.*XFP.* $dutInitName]==1} {
    foreach $optL [split $dutInitName .] {}
    set 10Gqty  [string index $10G 0]
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10Gqty.$1G.$clkOpt.$sk  
    }
  }
  if {[string match *.*0U.* $dutInitName]==1} {
    foreach $optL [split $dutInitName .] {}
    set 1Gtype  [string index $1G 0]0UTP
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.$1Gtype.$clkOpt.$sk  
    }
  }
  if {[string match *.*0S.* $dutInitName]==1} {
    foreach $optL [split $dutInitName .] {}
    set 1Gtype  [string index $1G 0]0SFP
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.$1Gtype.$clkOpt.$sk  
    }
  }
  if {[string match *.10U10S.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.10SFP_10UTP.$clkOpt.$sk  
    }
  }
  if {[string match *.PTP.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.$1G.PTP.$sk  
    }
  }
  if {[string match *.SYE.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.$1G.SYE.$sk  
    }
  }
  if {[string match *.ESK.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.$1G.$clkOpt.ESK  
    }
  }
  if {[string match *.ESK.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.$1G.$clkOpt.BSK  
    }
  }
  if {[string match *_FT.* $dutInitName]==1} {
    foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $ps.$10G.$1G.$clkOpt.ESK  
    }
  }
  }
  
  foreach par {ps 10G 1G clkOpt sk} {
    puts -nonewline "${par}=$gaSet($par), "
  }
  puts ""
  

#   puts "DutFam:$gaSet(dutFam)" ; update
#   foreach {ps 10G 1G clkOpt sk} [split $gaSet(dutFam) .]  {}
#   set gaSet(ps) $ps
#   set gaSet(10G) $10G
#   set gaSet(1G) $1G
#   set gaSet(clkOpt) $clkOpt
  
  return {}
}  

# ***************************************************************************
# GetDbrSW
# ***************************************************************************
proc GetDbrSW {barcode} {
  global gaSet gaGui
  set gaSet(dbrSW) "" 
  
#   set javaLoc1  C:\\Program\ Files\\Java\\jre6\\bin\\
#   set javaLoc2 C:\\Program\ Files\ (x86)\\Java\\jre6\\bin\\
#   if {[file exist $javaLoc1]} {
#     set javaLoc $javaLoc1
#   } elseif {[file exist $javaLoc2]} {
#     set javaLoc $javaLoc2
#   } else {
#     set gaSet(fail) "Java application is missing"
#     return -1
#   }  
  set javaLoc $gaSet(javaLocation)
  catch {exec $javaLoc\\java -jar $::RadAppsPath/SWVersions4IDnumber.jar $barcode} b
  puts "GetDbrSW b:<$b>" ; update
  after 1000
  file delete -force SW_4_$barcode.txt
  set swIndx [lsearch $b $gaSet(swPack)]  
  if {$swIndx<0} {
    set gaSet(fail) "There is no SW ID for $gaSet(swPack) ID:$barcode. Verify the Barcode."
    RLSound::Play failbeep
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set dbrSW [string trim [lindex $b [expr {1+$swIndx}]]]
  puts dbrSW:<$dbrSW>
  set gaSet(dbrSW) $dbrSW
  pack forget $gaGui(frFailStatus)
  Status ""
  update
  BuildTests
  focus -force $gaGui(tbrun)
  return 0
}


proc xx {} {
  return [list ETX-220A/AC/2X10GE/4XGE  ETX-220A/ACR/2X10GE/4XGE ETX-220A/AC/2XFP/10U10S/SYE \
  ETX-220A/AC/2XFP/20S/SYE ETX-220A/AC/3XFP/10S/PTP ETX-220A/AC/3XFP/10S/SYE \
  ETX-220A/AC/3XFP/10U/PTP ETX-220A/AC/3XFP/10U/SYE ETX-220A/AC/4XFP/10S/PTP \
  ETX-220A/AC/4XFP/10S/SYE ETX-220A/AC/4XFP/10U/SYE ETX-220A/AC/4XFP/SYE\
  ETX-220A/ACR/2XFP/10U10S/PTP ETX-220A/ACR/2XFP/10U10S/SYE ETX-220A/ACR/2XFP/20S/PTP\
  ETX-220A/ACR/2XFP/20S/SYE ETX-220A/ACR/2XFP/20U/SYE ETX-220A/ACR/3XFP/10S/PTP\
  ETX-220A/ACR/3XFP/10S/SYE ETX-220A/ACR/3XFP/10U/SYE ETX-220A/ACR/4XFP/10S/PTP\
  ETX-220A/ACR/4XFP/10S/SYE ETX-220A/ACR/4XFP/10U/SYE ETX-220A/ACR/4XFP/PTP\
  ETX-220A/ACR/4XFP/SYE ETX-220A/DC/2X10GE/4XGE ETX-220A/DC/2XFP/10U10S/SYE\
  ETX-220A/DC/2XFP/20S/SYE ETX-220A/DC/3XFP/10S/PTP ETX-220A/DC/3XFP/10S/SYE\
  ETX-220A/DC/3XFP/10U/SYE ETX-220A/DC/4XFP/10S/PTP ETX-220A/DC/4XFP/10S/SYE\
  ETX-220A/DCR/2X10GE/4XGE ETX-220A/DCR/2XFP/10U10S/SYE ETX-220A/DCR/2XFP/20S/PTP\
  ETX-220A/DCR/2XFP/20S/SYE ETX-220A/DCR/3XFP/10U/SYE ETX-220A/DCR/4XFP/10S/PTP\
  ETX-220A/DCR/4XFP/10S/SYE ETX-220A/DCR/4XFP/SYE ETX-220A/H/AC/3XFP/10S/PTP\
  ETX-220A/H/AC/3XFP/10S/SYE ETX-220A/H/AC/3XFP/10U/PTP ETX-220A/H/AC/3XFP/10U/SYE\
  ETX-220A/H/ACR/2XFP/20U/SYE ETX-220A/H/DC/3XFP/10S/SYE ETX-220A/H/DC/3XFP/10U/SYE\
  ETX-220A/H/DCR/2XFP/20S/SYE ETX-220A/H/DCR/2XFP/20U/SYE ETX-220A/H/DCR/3XFP/10S/SYE\
  ETX-220A/K/ACR/2XFP/20U/SYE ETX-220A_EQ/ACR/2XFP/20U/SYE ETX-220A_EQ/ACR/4XFP/10U/SYE\
  ETX-220A_FT/AC/2XFP/20S/SYE ETX-220A_FT/AC/3XFP/10S/SYE ETX-220A_FT/AC/4XFP/SYE\
  ETX-220A_FT/DC/2XFP/20S/SYE ETX-220A_FT/DC/3XFP/10S/SYE ETX-220A_FTR/ACR/2XFP/20S/PTP\
  ETX-220A_FTR/ACR/3XFP/10S/PTP ETX-220A_FTR/DCR/2XFP/20S/PTP ETX-220A_FTR/DCR/3XFP/10S/PTP\
  ETX-220A_FTR/HN/ACR/2XFP/20S/PTP ETX-220A_FTR/HN/ACR/3XFP/10S/PTP ETX-220A_FTR/HN/DCR/2XFP/20S/PTP\
  ETX-220A_FTR/HN/DCR/3XFP/10S/PTP ETX-220A_SH/AC/3XFP/10S/SYE ETX-220A_SH/ACR/3XFP/10S/SYE\
  ETX-220A_SH/AC/4XFP/SYE ETX-220A_SH/ACR/2XFP/10U10S/SYE ETX-220A_TMX/DCR/SFP/2XFP/20S/SYE\
  ETX-220A_TWC/AC/3XFP/10U/SYE ETX-220A_TWC/ACR/4XFP/10S/SYE ETX-220A_TWC/DC/3XFP/10S/PTP\
  ETX-220A_TWC/DCR/4XFP/10S/SYE ETX-220A_EIR/H/ACR/4XFP/10S/SYE ETX-220A_EIR/H/DCR/4XFP/10S/SYE\
  ETX-220A/AC/2XFP/20S/PTP ETX-220A/DCR/4XFP/10U/PTP ETX-220A_CELLCOM/ACR/2XFP/20S/PTP\
  ETX-220A_CELLCOM/DCR/2XFP/20S/PTP ETX-220A_CELLCOM/DCR/2XFP/20U/SYE ETX-220A_CELLCOM/DCR/3XFP/10S/SYE\
  ETX-220A_CELLCOM/DCR/3XFP/10U/SYE ETX-220A_CELLCOM/DCR/4XFP/SYE ETX-220A/H/ACR/4XFP/10S/SYE\
  ETX-220A/H/DCR/4XFP/10S/SYE ETX-220A/DC/2XFP/20U/SYE ETX-220A/DCR/3XFP/10S/SYE\
  ETX-220A_SH/ACR/2XFP/20S/SYE ETX-220A_EIR/AC/4XFP/10S/SYE ETX-220A_EIR/ACR/4XFP/10S/SYE\
  ETX-220A_EIR/DCR/4XFP/10S/SYE ETX-220A_TA/ACR/2XFP/10U10S/SYE ETX-220A_TA/ACR/2XFP/20S/SYE\
  ETX-220A_TA/ACR/2XFP/20U/SYE ETX-220A_TA/DCR/2XFP/10U10S/SYE ETX-220A_TA/DCR/2XFP/20S/SYE\
  ETX-220A_TA/DCR/2XFP/20U/SYE ETX-220A_TA/ACR/4XFP/SYE ETX-220A_TA/DCR/4XFP/SYE \
  ETX-220A/DCR/4XFP/PTP]
}
if 0 {
set i 0
foreach uut [xx] {
  puts [incr i]
  RetriveDutFam [regsub -all / $uut .].tcl
}
}

# ***************************************************************************
# wsplit
# ***************************************************************************
proc wsplit {str sep} {
  split [string map [list $sep \0] $str] \0
}

# ***************************************************************************
# LoadBootErrorsFile
# ***************************************************************************
proc LoadBootErrorsFile {} {
  global gaSet
  set gaSet(bootErrorsL) [list] 
  if ![file exists bootErrors.txt]  {
    return {}
  }
  
  set id [open  bootErrors.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet(bootErrorsL) $line
      }
    }

  close $id
  
#   foreach ber $bootErrorsL {
#     if [string length $ber] {
#      lappend gaSet(bootErrorsL) $ber
#    }
#   }
  return {}
}

# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  if [file exist $path1] {
    set path $path1
  } elseif [file exist $path2] {
    set path $path2  
  } else {
    puts "no teraterm installed"
    return {}
  }
  if {[string match *Dut* $comName] || [string match *Dls* $comName]} {
    set baud 9600
  } else {
    set baud 115200
  }
  regexp {com(\w+)} $comName ma val
  set val Tester-$gaSet(pair).[string toupper $val]
  exec $path /c=[set $comName] /baud=$baud /W="$val" &
  return {}
}  

# ***************************************************************************
# UpdateInitsToTesters
# ***************************************************************************
proc UpdateInitsToTesters {} {
  global gaSet
  set sdl [list]
  set unUpdatedHostsL [list]
  set hostsL [list AT-ETX220-1-W10 AT-ETX220-2-W10  AT-ETX220-3-W10]
  set initsPath AT-ETX220A-MP/uutInits
  set usDefPath AT-ETX220A-MP/ConfFiles/Default_conf
  
  set s1 c:/$initsPath
  set s2 c:/$usDefPath
  foreach host $hostsL {
    if {$host!=[info host]} {
      set dest //$host/c$/$initsPath
      if [file exists $dest] {
        lappend sdl $s1 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
      
      set dest //$host/c$/$usDefPath
      if [file exists $dest] {
        lappend sdl $s2 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
    }
  }
  
  set msg ""
  set unUpdatedHostsL [lsort -unique $unUpdatedHostsL]
  if {$unUpdatedHostsL!=""} {
    append msg "The following PCs are not reachable:\n"
    foreach h $unUpdatedHostsL {
      append msg "$h\n"
    }  
    append msg \n
  }
  if {$sdl!=""} {
    if {$gaSet(radNet)} {
      set emailL {ilya_g@rad.com}
    } else {
      set emailL [list]
    }
    set ret [RLAutoUpdate::AutoUpdate $sdl]
    set updFileL    [lsort -unique $RLAutoUpdate::updFileL]
    set newestFileL [lsort -unique $RLAutoUpdate::newestFileL]
    if {$ret==0} {
      if {$updFileL==""} {
        ## no files to update
        append msg "All files are equal, no update is needed"
      } else {
        append msg "Update is done"
        if {[llength $emailL]>0} {
          RLAutoUpdate::SendMail $emailL $updFileL "file://R:\\IlyaG\\220A"
          if ![file exists R:/IlyaG/220A] {
            file mkdir R:/IlyaG/220A
          }
          foreach fi $updFileL {
            catch {file copy -force $s1/$fi R:/IlyaG/220A } res
            puts $res
            catch {file copy -force $s2/$fi R:/IlyaG/220A } res
            puts $res
          }
        }
      }
      tk_messageBox -message $msg -type ok -icon info -title "Tester update" ; #DialogBox icon /images/info
    }
  } else {
    tk_messageBox -message $msg -type ok -icon info -title "Tester update"
  } 
}
# ***************************************************************************
# CheckTitleDbrNameVsUutDbrName
# ***************************************************************************
proc CheckTitleDbrNameVsUutDbrName {} {
  global gaSet
  set barcode $gaSet(1.barcode1) 
  set fileName MarkNam_$barcode.txt
  if [file exists $fileName] {
    file delete -force $fileName
    after 1000
  }
  set res [catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b]
  puts "CTDNVUDN barcode:<$barcode> res:<$res> b:<$b>"
  
  after 1000
  if ![file exists $fileName] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error -title "Get DbrName Problem"
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  catch {file delete -force $fileName}
  
  set uutDbrName "[string trim $res]"
  puts "CTDNVUDN uutDbrName:<$uutDbrName> gaSet(DutFullName):<$gaSet(DutFullName)>"
  if {$uutDbrName != $gaSet(DutFullName)} {
    set gaSet(fail) "Mismatch between UUT's Barcode and GUI" 
    AddToPairLog $gaSet(pair) "Mismatch between UUT's Barcode ($uutDbrName) and GUI ($gaSet(DutFullName))"
    return -1
  } else {
    return 0
  }
}
# ***************************************************************************
# DialogBoxRamzor
# ***************************************************************************
proc DialogBoxRamzor {args}  {
  Ramzor red on
  set ret [eval DialogBox $args]
  puts "DialogBoxRamzor ret after DialogBox:<$ret>"
  Ramzor green on
  return $ret
}
