proc FansTemperatureTest {} {
  global gaSet buffer
  Status "FansTemperatureTest"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read thermostat"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-220A 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "debug thermostat\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point upper 60\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point lower 55\r" thermostat]
  if {$ret!=0} {return $ret}
  
  scan $gaSet(dbrSW) %3d\.%3d\.%3d v1 v2 v3
  set sw $v1.$v2.$v3
  if {$gaSet(clkOpt)=="SYE"} {
    set fanState "off off off off"
  } elseif {$gaSet(clkOpt)=="PTP"} {
    if {$sw>="5.9.1"} {
      set fanState "on on on on"
    } else {
      set fanState "off off off off"
    }
  }
  puts "clkOpt:$gaSet(clkOpt) sw:$sw fanState:$fanState"
      
  set gaSet(fail) "Read from thermostat fail"
  for {set i 1} {$i<=40} {incr i} {
    puts "i:$i wait for \'$fanState\'" ; update
    set ret [Send $com "show status\r" thermostat]
    if {$ret!=0} {return $ret}
#     set offQty [regexp -all $fanState $buffer]
#     if {$offQty==4} {
#       break
#     }
    set res [string match *$fanState* $buffer]
    if {$res=="1"} {
      break
    }
    after 2000
  }
#   if {$offQty!=4} {
#     set gaSet(fail) "\'$fanState\' doesn't apprear 4 times"
#     return -1
#   }
  if {$res!="1"} {
    set gaSet(fail) "\'$fanState\' doesn't apprear"
    return -1
  }
  regexp  {Current:\s([\d\.]+)\s} $buffer - ct1
  puts "ct1:$ct1"  
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "set-point lower 20\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point upper 30\r" thermostat]
  if {$ret!=0} {return $ret}
    
  set gaSet(fail) "Read from thermostat fail"
  for {set i 1} {$i<=40} {incr i} {
    puts "i:$i wait for 4 on" ; update
    set ret [Send $com "show status\r" thermostat]
    if {$ret!=0} {return $ret}
    set onQty [regexp -all {\son} $buffer]
    if {$onQty==4} {
      break
    }
    after 2000
  }
  if {$onQty!=4} {
    set gaSet(fail) "\"on\" doesn't apprear 4 times"
    return -1
  } 
  
  if {$fanState=="off off off off"} {
    ## if we turn off the fans, the temperature should change and we should check it
    set gaSet(fail) "Read from thermostat fail"
    for {set i 1} {$i<=5} {incr i} {
      set ret [Send $com "show status\r" thermostat 1]
      if {$ret!=0} {return $ret}
      regexp  {Current:\s([\d\.]+)\s} $buffer - ct2 
      puts "i:$i ct2:$ct2" ; update
      if {$ct2!=$ct1} {
        set ret 0
        break
      }
      after 2000
    }  
    if {$ct2==$ct1} {
      
      set gaSet(fail) "\"Current\" doesn't change: $ct2"
      return -1
    }
  }
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "set-point upper 40\r" thermostat 1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point lower 32\r" thermostat 1]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# SK_IDTest
# ***************************************************************************
proc SK_IDTest {} {
  global gaSet buffer
  Status "SK_ID Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set gaSet(fail) "Read SK version fail"
  set ret [Send $com "exit all\r" ETX-220A]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure qos queue-group-profile \"DefaultQueueGroup\" queue-block 0/1\r" (0/1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" #]
  if {$ret!=0} {return $ret}
  set ret [Send $com "queue-block 0/2\r" (0/2)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" #]
  if {$ret!=0} {return $ret}
  set ret [Send $com "queue-block 0/3\r" stam 1]
  #if {$ret!=0} {return $ret}
  
  if {$gaSet(sk)=="BSK" && [string match {*cli error: License limitation*} $buffer]} {
    set ret 0
  } elseif {$gaSet(sk)=="BSK" && ![string match {*cli error: License limitation*} $buffer]} {
    set ret -1
  } elseif {$gaSet(sk)=="ESK" && [string match {*cli error: License limitation*} $buffer]} {
    set ret -1
  } elseif {$gaSet(sk)=="ESK" && ![string match {*cli error: License limitation*} $buffer]} {
    set ret 0
  }
  if {$ret=="-1"} {
    set gaSet(fail) "The $gaSet(sk) unmatch License limitation"
  }
  return $ret
}
# ***************************************************************************
# PS_IDTest
# ***************************************************************************
proc PS_IDTest {} {
  global gaSet buffer
  Status "PS_ID Test"
  
  #21/04/2020 08:47:49
  Power all off
  after 2000
  
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  
  puts "gaSet(loginBuffer):<$gaSet(loginBuffer)>"
  set res [regexp {Boot version: ([\w\.]+)\s} $gaSet(loginBuffer) ma value]
  if {$res==0} {
    set gaSet(fail) "Can't read the Boot version"
    return -1
  }
  set dutBootVer [string trim $value]
  
  set com $gaSet(comDut)  
  set ret [Send $com "exit all\r" ETX-220A]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "configure system\r" ">system"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "show device-information\r" ">system"]
  if {$ret!=0} {return $ret}
  set res [regexp {Hw:\s+([\.\w\/]+),\s} $buffer - hw]
  if {$res==0} {
    set gaSet(fail) "Can't read the Hw version"
    return -1
  }
  set dutHw [string range $hw 0 [expr {[string first / $hw] -1}]]  ; # take 2.0 from 2.0/E
  puts "dutBootVer:<$dutBootVer>  hw:<$hw>  dutHw:<$dutHw>"; update
  if {($dutBootVer=="1.13" && $dutHw==0.0) || ($dutBootVer>="1.18" && $dutHw>="2.0")} {
    ## all right
  } else {
    set gaSet(fail) "BootVer:$dutBootVer Hw:$dutHw"
    return -1
  }
  
  set ret [Send $com "exit all\r" ETX-220A]
  if {$ret!=0} {return $ret}
  
#   set ret [Send $com "info\r" ETX-220 20]  
    set ret [Send $com "le\r" ETX-220 20] 
    regexp {sw\s+\"([\.\d\(\)]+_?)\"\s} $buffer - sw
#   if {[string match *more* $buffer]} {
#     set ret [Send $com "\3" ETX-220A 0.25]
#     if {$ret!=0} {return $ret}
#   }
  
   
  if ![info exists sw] {
    set gaSet(fail) "Can't read the SW version"
    return -1
  }
  puts "sw:$sw"
  ## perform the SW test after the PSs ID test
#   if {$sw!=$gaSet(dbrSW)} {
#     set gaSet(fail) "SW is \"$sw\". Should be \"$gaSet(dbrSW)\""
#     return -1
#   }
  
  set ret [Send $com "exit all\r" ETX-220A]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  
##   take only major part of version
  set majorPart [lindex [split $sw (] 0]
  puts "majorPart:$majorPart"
  ## 01/03/2015 15:11:07 all SW versions know to read the DC PS
#   if {$majorPart<5.5} {
#     set psQty [regexp -all AC $buffer]
#     set sb AC
#   } else {
#     set psQty [regexp -all $gaSet(ps) $buffer]
#     set sb $gaSet(ps)
#   }
  set psQty [regexp -all $gaSet(ps) $buffer]
  set sb $gaSet(ps)
  if {$psQty!=2} {
    set gaSet(fail) "Type of PS is wrong. Should be \'$sb\'"
#     AddToLog $gaSet(fail)
    return -1
  }
  regexp {\-+\s(.+)\s+FAN} $buffer - psStatus
  regexp {1\s+\w+\s+([\s\w]+)\s+2} $psStatus - ps1Status
  set ps1Status [string trim $ps1Status]
  if {$ps1Status!="OK"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
#     AddToLog $gaSet(fail)
    return -1
  }
  regexp {2\s+\w+\s+([\s\w]+)\s+} $psStatus - ps2Status
  set ps2Status [string trim $ps2Status]
  if {$ps2Status!="OK"} {
    set gaSet(fail) "Status of PS-2 is \'$ps2Status\'. Should be \'OK\'"
#     AddToLog $gaSet(fail)
    return -1
  }
  
  if {$sw!=$gaSet(dbrSW)} {
    set gaSet(fail) "SW is \"$sw\". Should be \"$gaSet(dbrSW)\""
    return -1
  }
#   set gRelayState red
#   IPRelay-LoopRed
#   SendEmail "ETX220A-MP" "Manual Test"
#   RLSound::Play information
#   set txt "Verify on each PS that GREEN led lights"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
#   
#   foreach PS {2 1} {
#     Power $PS off
#     after 3000
#     set ret [Send $com "show environment\r" chassis]
#     if {$ret!=0} {return $ret}
#     if {$PS==1} {
#       regexp {1\s+[AD]C\s+(\w+)\s} $buffer - val
#     } elseif {$PS==2} {
#       regexp {2\s+[AD]C\s+(\w+)\s} $buffer - val
#     }
#     puts "val:<$val>"
#     if {$val!="Failed"} {
#       set gaSet(fail) "PS $PS $val. Expected \"Failed\""
#       AddToLog $gaSet(fail)
#       return -1
#     }
#     RLSound::Play information
#     set txt "Verify on PS $PS that RED led lights"
#     set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#     update
#     if {$res!="OK"} {
#       set gaSet(fail) "LED Test failed"
#       return -1
#     } else {
#       set ret 0
#     }
#     
#     RLSound::Play information
#     set txt "Remove PS $PS"
#     set res [DialogBox -type "OK Cancel" -icon /images/question -title "LED Test" -message $txt]
#     update
#     if {$res!="OK"} {
#       set gaSet(fail) "PS_ID Test failed"
#       return -1
#     } else {
#       set ret 0
#     }
#     set ret [Send $com "show environment\r" chassis]
#     if {$ret!=0} {return $ret}
#     if {$PS==1} {
#       regexp {1\s+[AD]C\s+(\w+\s\w+)\s} $buffer - val
#     } elseif {$PS==2} {
#       regexp {2\s+[AD]C\s+(\w+\s\w+)\s} $buffer - val
#     }
#     
#     puts "val:<$val>"
#     if {$val!="Not exist"} {
#       set gaSet(fail) "PS $PS $val. Expected \"Not exist\""
#       AddToLog $gaSet(fail)
#       return -1
#     }
#     
#     RLSound::Play information
#     set txt "Verify on PS $PS that led no lights"
#     set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#     update
#     if {$res!="OK"} {
#       set gaSet(fail) "LED Test failed"
#       return -1
#     } else {
#       set ret 0
#     }
#     
#     RLSound::Play information
#     set txt "Assemble PS $PS"
#     set res [DialogBox -type "OK Cancel" -icon /images/question -title "LED Test" -message $txt]
#     update
#     if {$res!="OK"} {
#       set gaSet(fail) "PS_ID Test failed"
#       return -1
#     } else {
#       set ret 0
#     }
#     Power $PS on
#     after 2000
#   }
 
  return $ret
}
# ***************************************************************************
# DyingGaspSetup
# ***************************************************************************
proc DyingGaspSetup {} {
  global gaSet buffer gRelayState
  Status "DyingGaspTest"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(dgCF)
  set cfTxt "Dying Gasp"
  set ret [DownloadConfFile $cf $cfTxt 1]
  if {$ret!=0} {return $ret}
  
  set dutIp 10.10.10.1[set gaSet(pair)]  
  for {set i 1} {$i<=20} {incr i} {   
    set ret [Ping $dutIp]
    puts "DyingGaspSetup ping after download i:$i ret:$ret"
    if {$ret!=0} {return $ret}
  }
  
#   if {$gaSet(ps)=="DC"} {
#     Power all off
#     set gRelayState red
#     IPRelay-LoopRed
#     SendEmail "ETX220A-MP" "Manual Test"
#     RLSound::Play information
#     set txt "Remove the DC PSs and insert AC PSs"
#     set res [DialogBox -type "OK Cancel" -icon /images/question -title "Change PS" -message $txt]
#     update
#     if {$res!="OK"} {
#       return -2
#     } else {
#       set ret 0
#     }
#     Power all on
#     set gRelayState green
#     IPRelay-Green
#   } elseif {$gaSet(ps)=="AC"} {
#     Power all off
#     after 1000
#     Power all on
#   }
# 23/09/2019 09:46:16
  Power all off
  after 1000
  Power all on
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }

#   set snmpId [RLScotty::SnmpOpen $dutIp]
#   RLScotty::SnmpConfig $snmpId -version SNMPv3 -user initial
  return $ret
}    
 
# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc DyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
  puts "[MyTime] DyingGaspPerf $psOffOn $psOff"
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set ret [Wait "Wait for Management ON" 135 white]  ; # 35 07/08/2019 10:02:41
  if {$ret!=0} {return $ret}
      
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 

   
  set wsDir C:\\Program\ Files\\Wireshark
  set npfL [exec $wsDir\\tshark.exe -D]
  ## 1. \Device\NPF_{3EEEE372-9D9D-4D45-A844-AEA458091064} (ATE net)
  ## 2. \Device\NPF_{6FBA68CE-DA95-496D-83EA-B43C271C7A28} (RAD net)
  set intf ""
  foreach npf [split $npfL "\n\r"] {
    set res [regexp {(\d)\..*ATE} $npf - intf] ; puts "<$res> <$npf> <$intf>"
    if {$res==1} {break}
  }
  if {$res==0} {
    set gaSet(fail) "Get ATE net's Network Interface fail"
    return -1
  }
  
  Status "Wait for Ping traps"
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  set dur 10
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &
  after 1000
  set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  after "[expr {$dur +1}]000" ; ## one sec more then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\r---<$monData>---\r"; update
  
  set res [regexp -all "Src: $dutIp, Dst: 10.10.10.10" $monData]
  #set res [regexp -all "Src: $dutIp \\($dutIp\\), Dst: 10.10.10.10" $monData]
  puts "res:$res"
  if {$res<2} {
    set gaSet(fail) "2 Ping traps did not sent"
    return -1
  }
  file delete -force $resFile
  
  catch {exec arp.exe -d $dutIp} resArp
  puts "[MyTime] resArp:$resArp"
  
  Power $psOffOn on
  Power $psOff off
  
  Status "Wait for Dying Gasp trap"
  set dur 10
  set resFile c:\\temp\\te_$gaSet(pair)_ps${psOffOn}_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &  
     
  after 1000
  Power $psOffOn off
  after 1000
  Power $psOffOn on
  
  after "[expr {$dur +1}]000" ; ## one more sec then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\rMonData---<$monData>---\r"; update
  
  
  ## 4479696e672067617370
  ## D y i n g   g a s p
  #set framsL [regexp -all -inline "Src: $dutIp.+?\\n\\n\\n" $monData]
  #set framsL [split $monData %]
  set framsL [wsplit $monData lIsT]
  if {[llength $framsL]==0} {
    set gaSet(fail) "No frame from $dutIp was detected"
    return -1
  }
  puts "\rDying gasp == 4479696e672067617370\r"; update
  set res 0
  foreach fram $framsL {
    puts "\rFrameA---<$fram>---\r"; update
    if {[string match "*Src: $dutIp*" $fram] && \
        ([string match *4479696e672067617370* $fram] || [string match {*Dying gasp*} $fram])} {
      set res 1
      #file delete -force $resFile
      break
    }
  } 
  if {$res} {
    puts "\rFrameB---<$fram>---\r"; update
  }
#   set frameQty [expr {[regexp -all "Frame " $monData] - 1}]
#   for {set fFr 1; set nextFr 2} {$fFr <= $frameQty} {incr fFr} {
#     puts "fFr:$fFr  nextFr:$nextFr"
#     if [regexp "Frame $fFr:.*\\sFrame $nextFr" $monData m] {
#       if [regexp "Src: [set dutIp].*" $m mm] {
#         if [string match *4479696e672067617370* $mm] {
#           puts $mm
#           set res 1
#         }
#       }
#     }
#     puts ""
#     
#     incr nextFr
#     if {$nextFr>$frameQty} {set nextFr 99}
#   }
# 
#   

  if {$res==1} {
    set ret 0
    set ret [Wait "Wait for UUT ON" 20 white]
    if {$ret!=0} {return $ret}
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}

proc scottyDyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  
  RLScotty::SnmpCloseAllTrap
  for {set wc 1} {$wc<=10} {incr wc} {
    set trp(id) [RLScotty::SnmpOpenTrap tmsg]
    puts "wc:$wc trp(id):$trp(id)"
    if {$trp(id)=="-1"} {
      set ret -1
      set gaSet(fail) "Open Trap failed"
      set ret [Wait "Wait for SNMP session" 5 white]
      if {$ret!=0} {return $ret}
    } else {
      set ret 0
      break
    }
  }
  if {$ret!=0} {return $ret}
  RLScotty::SnmpConfigTrap $trp(id) -version SNMPv3 -user initial ; #SNMPv2c ;# SNMPv1 , SNMPv2c , SNMPv3
  
  set tmsg ""
  #Power $psOff off
  set ret [Send $com "configure system clock station 1/1\r" "(1/1)"]
  if {$ret!=0} {
    RLScotty::SnmpCloseTrap $trp(id)
    return $ret
  }
  
  set ret -1
  for {set i 1} {$i<=5} {incr i} {
    set ret [Send $com "shutdown\r" "(1/1)"]
      if {$ret==0} {
      after 1000
      set ret [Send $com "no shutdown\r" "(1/1)"]
      if {$ret!=0} {
        RLScotty::SnmpCloseTrap $trp(id)
        return $ret
      }
    }
    puts "tmsgStClk:<$tmsg>"
    if {$tmsg!=""} {
      set ret 0
      break
    }
    after 1000
  }
  if {$ret=="-1"} {
    set gaSet(fail) "Trap is not sent"
    RLScotty::SnmpCloseTrap $trp(id)
    return -1
  }
  
  after 1000
  set tmsg ""
  
  Power $psOffOn on
  Power $psOff off
  Wait "Wait for trap 1" 3 white
  puts "tmsgDG 1.1:<$tmsg>"
  set tmsg ""
  puts "tmsgDG 1.2:<$tmsg>"
  
  Power $psOffOn off
  Wait "Wait for trap 2" 3 white 
   
  #set ret [regexp -all "$dutIp\[\\s\\w\\:\\-\\.\\=\]+\\\"\\w+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\:\\-\\.\]+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\-\]+\\\"" $tmsg v]  
  puts "tmsgDG 2:<$tmsg>"
  set res [regexp "from\\s$dutIp:\\s\.\+\:systemDyingGasp" $tmsg -]
  Power $psOffOn on
  
  # Close sesion:
  RLScotty::SnmpCloseTrap $trp(id)  

  if {$res==1} {
    set ret 0
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}

# ***************************************************************************
# XFP_ID_Test
# ***************************************************************************
proc XFP_ID_Test {} {
  global gaSet buffer
  Status "XFP_ID_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  
  foreach 10Gp {3/1 3/2 4/1 4/2} {
    if {$gaSet(10G)=="2" && ($10Gp=="3/1" || $10Gp=="3/2")} {
      continue
    }
    if {$gaSet(10G)=="3" && $10Gp=="3/2"} {
      continue
    }
    Status "XFP $10Gp ID Test"
    set gaSet(fail) "Read XFP status of port $10Gp fail"
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure port ethernet $10Gp\r" #]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show status\r" "MAC Address" 20]
    if {$ret!=0} {return $ret}
    set b $buffer
    set ::b1 $b
      
    set ret [Send $com "\r" #]
    if {$ret!=0} {return $ret}
    append b $buffer
    set ::b2 $b
    set res [regexp {Connector Type\s+:\s+(.+)Auto} $b - connType]
    set connType [string trim $connType]
    if {$connType!="XFP In"} {
      set gaSet(fail) "XFP status of port $10Gp is \"$connType\". Should be \"XFP In\"" 
      set ret -1
      break 
    }
    set xfpL [list "XFP-1D" XPMR01CDFBRAD]
    regexp {Part Number[\s:]+([\w\-]+)\s} $b - xfp
    if ![info exists xfp] {
      puts "b:<$b>"
      puts "b1:<$::b1>"
      puts "b2:<$::b2>"
      set gaSet(fail) "Port $10Gp. Can't read XFP's Part Number"
      return -1
    }
#     if {$xfp!="XFP-1D"} {}
    if {[lsearch $xfpL $xfp]=="-1"} {
      set gaSet(fail) "XFP Part Number of port $10Gp is \"$xfp\". Should be one from $xfpL" 
      set ret -1
      break 
    }    
  }
  return $ret  
}

# ***************************************************************************
# SfpUtp_ID_Test
# ***************************************************************************
proc SfpUtp_ID_Test {} {
  global gaSet buffer
#   if {$gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP"} {
#     ## don't check ports UTP
#     return 0
#   }
  Status "SfpUtp_ID_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  
  foreach 1Gp {1/1 1/2 1/3 1/4 1/5 1/6 1/7 1/8 1/9 1/10 2/1 2/2 2/3 2/4 2/5 2/6 2/7 2/8 2/9 2/10} {
    if {($gaSet(1G)=="10SFP" || $gaSet(1G)=="10UTP") && [lindex [split $1Gp /] 0]==2} {
      ## dont check ports 2/x
      continue
    }
#     if {$gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP"} {
#       ## dont check ports UTP
#       set ret 0
#       break
#     }
#     if {$gaSet(1G)=="10SFP_10UTP" && [lindex [split $1Gp /] 0]==2} {
#       ## dont check ports UTP  2/x
#       continue
#     }
    Status "SfpUtp $1Gp ID Test"
    set gaSet(fail) "Read SfpUtp status of port $1Gp fail"
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure port ethernet $1Gp\r" #]
    if {$ret!=0} {return $ret}
    if [string match {*Entry instance doesn't exist*} $buffer] {
      set gaSet(fail) "Status of port $1Gp is \"Entry instance doesn't exist\"." 
      set ret -1
      break
    }
    set ret [Send $com "show status\r\r" "#" 20]
    if {$ret!=0} {return $ret}    
    
    #21/04/2020 11:13:17
    set res [regexp {Operational Status\s+:\s+Up} $buffer]
    if {$res==0} {
      set gaSet(fail) "Operational Status of port $1Gp is not Up" 
      set ret -1
      break
    }
    set res [regexp {Connector Type\s+:\s+(.+)Auto} $buffer - connType]
    set connType [string trim $connType]
    if {([lindex [split $1Gp /] 0]==1 && ($gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP")) ||\
        ([lindex [split $1Gp /] 0]==2 && ($gaSet(1G)=="10SFP_10UTP" || $gaSet(1G)=="20UTP"))} {
      ## 1/x ports
      ## 2/x ports
      set conn "RJ45" 
      set name "UTP"
    } else {
      set conn "SFP In"
      set name "SFP"
    } 
    
    if {$connType!=$conn} {
      set gaSet(fail) "$name status of port $1Gp is \"$connType\". Should be \"$conn\"" 
      set ret -1
      break 
    }
    if {$name=="SFP"} {
      regexp {Part Number[\s:]+([\w\-]+)\s} $buffer - sfp
      if ![info exists sfp] {
        set gaSet(fail) "Can't read SFP's Part Number"
        return -1
      }
      set sfpL [list "SFP-5D" "SFP-6D" "SFP-6H" "SFP-6DH" "SFP-30" "SFP-6" "SPGBTXCNFCRAD"\
               "EOLS-1312-10-RAD" "EOLS131210RAD" "FTMC012RLCGRAD" "FTM-3012C-SLG"\
               "OFP-6"]
      if {[lsearch $sfpL $sfp]=="-1"} {
        set gaSet(fail) "SFP Part Number of port $1Gp is \"$sfp\". Should be one from $sfpL" 
        set ret -1
        break 
      }
    }
    
  }
  return $ret  
}

# ***************************************************************************
# DateTime_Test
# ***************************************************************************
proc DateTime_Test {} {
  global gaSet buffer
  Status "DateTime_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system\r" >system]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show system-date\r" >system]
  if {$ret!=0} {return $ret}
  
  regexp {date\s+([\d-]+)\s+([\d:]+)\s} $buffer - dutDate dutTime
  
  set dutTimeSec [clock scan $dutTime]
  set pcSec [clock seconds]
  set delta [expr abs([expr {$pcSec - $dutTimeSec}])]
  if {$delta>300} {
    set gaSet(fail) "Difference between PC and the DUT is more then 5 minutes ($delta)"
    set ret -1
  } else {
    set ret 0
  }
  
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    if {$pcDate!=$dutDate} {
      set gaSet(fail) "Date of the DUT is \"$dutDate\". Should be \"$pcDate\""
      set ret -1
    } else {
      set ret 0
    }
  }
  return $ret
}

# ***************************************************************************
# DataTransmissionSetup
# ***************************************************************************
proc DataTransmissionSetup {port} {
  global gaSet
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  if {$port=="4/2"} {
    if {$gaSet(1G)=="None"} {
      set cf $gaSet(Only4CF) 
      set cfTxt "Only4XFP"
    } else {
      set cf $gaSet($gaSet(10G)CF) 
      set cfTxt "$gaSet(10G)XFP"
    }
  } elseif {$port=="4/1"} {
    set cf $gaSet(3ACF) 
    set cfTxt "$gaSet(10G)XFP"
  }
  set ret [DownloadConfFile $cf $cfTxt 1]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# ExtClkTest
# ***************************************************************************
proc ExtClkTest {mode} {
  puts "[MyTime] ExtClkTest $mode"
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
#   set ret [Send $com "configure system clock station 1/1\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "shutdown\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   Send $com "exit all\r" stam 0.25 
  
  if {$mode=="Unlocked"} {
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "show status\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set syst [set clkSrc [set state ""]]
    regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
    if {$clkSrc!="0" && $state!="Freerun"} {
      set gaSet(fail) "$syst"
      return -1
    }
  }
 
 if {$mode=="Locked"} {
    
    set ret [Send $com "\r" "stam" 1]
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    for {set i 1} {$i<=10} {incr i} {
      set ret [Send $com "show status\r" "domain(1)"]
      if {$ret!=0} {return $ret} 
      set syst [set clkSrc [set state ""]]
      regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
      if {$clkSrc=="1" && $state=="Locked"} {
        set ret 0
        break
      } else {      
        set ret -1
        after 1000
      }
    }
    if {$ret=="-1"} {
      set gaSet(fail) "$syst"
    } elseif {$ret=="0"} {
      set ret [Send $com "no source 1\r" "domain(1)"]
      if {$ret!=0} {return $ret}
    }
  }
  return $ret
}

# ***************************************************************************
# TstAlm
# ***************************************************************************
proc TstAlm {state} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  if {$state=="off"} { 
    set ret [Send $com "mask-minimum-severity log major\r" ">reporting"]
  } elseif {$state=="on"} { 
    set ret [Send $com "no mask-minimum-severity log\r" ">reporting"]
  } 
  return $ret
}

# ***************************************************************************
# ReadMac
# ***************************************************************************
proc ReadMac {} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    #if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure system\r" ">system"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "show device-information\r" ">system"]
  if {$ret!=0} {return $ret}
  
  set mac 00-00-00-00-00-00
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  set mac2 0x$mac1
  puts "mac1:$mac1" ; update
  AddToPairLog $gaSet(pair) "MAC $mac"
  if {($mac2<0x0020D2200000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF )} {
    RLSound::Play failbeep
    set gaSet(fail) "The MAC of UUT is $mac"
    set ret [DialogBox -type "Terminate Continue" -icon /images/error -title "MAC check"\
        -text $gaSet(fail) -aspect 2000]
    if {$ret=="Terminate"} {
      return -1
    }
  }
  set gaSet(${::pair}.mac1) $mac1
  
  return 0
}

#***************************************************************************
#**  Login
#***************************************************************************
proc Login {} {
  global gaSet buffer gaLocal
  set ret 0
  set gaSet(loginBuffer) ""
  set buffer ""
  set statusTxt $gaSet(sstatus)
  Status "Login into ETX220"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-220A user>} 5 1]
  Send $gaSet(comDut) "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $gaSet(comDut) "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {([string match {*220*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  puts ""
  puts "$buffer" 
  puts ""; update
  if {[string match {*Are you sure?*} $buffer]==0} {
   Send $gaSet(comDut) n\r stam 1
   append gaSet(loginBuffer) "$buffer"
  }
   
  if {[string match *password* $buffer]} {
    set ret 0
    Send $gaSet(comDut) \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $gaSet(comDut) exit\r\r 220
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *220* $buffer]} {
    set ret 0
    return 0
  }
  if {[string match *user>* $buffer]} {
    Send $gaSet(comDut) su\r stam 0.25
    set ret [Send $gaSet(comDut) 1234\r "ETX-220A"]
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
#     set ret [Wait "Wait for ETX up" 20 white]
#     if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 64} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into ETX220"
    puts "Login into ETX220 i:$i"; update
    $gaSet(runTime) configure -text $i
    Send $gaSet(comDut) \r stam 5
  
    append gaSet(loginBuffer) "$buffer"
    puts "<$gaSet(loginBuffer)>\n" ; update
    foreach ber $gaSet(bootErrorsL) {
      if [string match "*$ber*" $gaSet(loginBuffer)] {
       set gaSet(fail) "\'$ber\' occured during ETX220's up"  
        return -1
      } else {
        puts "[MyTime] \'$ber\' was not found"
      } 
    }
  
    #set ret [MyWaitFor $gaSet(comDut) {ETX-220A user> } 5 60]
    ## 31/03/2019 15:53:49
    ##if {([string match {*220*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} { }
    if {([string match {*user>*} $buffer]==1)} {
      set ::if1b $buffer
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $gaSet(comDut) run\r stam 1
    }   
  }
    
    
  if {$ret==0} {
    if {[string match *user* $buffer]} {
      Send $gaSet(comDut) su\r stam 1
      set ret [Send $gaSet(comDut) 1234\r "220"]
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to ETX220 Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# FormatFlash
# ***************************************************************************
proc FormatFlash {} {
  global gaSet buffer
  set com $gaSet(comDut)
  
  Power all on 
  
  return $ret
}
# ***************************************************************************
# FactDefault
# ***************************************************************************
proc FactDefault {mode} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Set to Default fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  Status "Factory Default..."
  if {$mode=="std"} {
    set ret [Send $com "admin factory-default\r" "yes/no" ]
  } elseif {$mode=="stda"} {
    set ret [Send $com "admin factory-default-all\r" "yes/no" ]
  }
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "seconds" 20]
  if {$ret!=0} {return $ret}
  set ret [Wait "Wait DUT down" 20 white]
  return $ret
}
# ***************************************************************************
# ShowPS
# ***************************************************************************
proc ShowPS {ps} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read PS-$ps status"
  set gaSet(fail) "Read PS status fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  if {$ps==1} {
    regexp {1\s+[AD]C\s+([\w\s]+)\s2} $buffer - val
  } elseif {$ps==2} {
    regexp {2\s+[AD]C\s+([\w\s]+)\sFAN} $buffer - val
  }
  if ![info exists val] {
    set gaSet(fail) "Status of PS-$ps is \"--\". Expected \"$gaSet(ps)\""
    return -1
  }
  set val [string trim $val]
  return $val
}
# ***************************************************************************
# Loopback
# ***************************************************************************
proc Loopback {mode} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Set Loopback to \'$mode\'"
  set gaSet(fail) "Loopback configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure port ethernet 4/1\r" (4/1)]
  if {$ret!=0} {return $ret}
  if {$mode=="off"} {
    set ret [Send $com "no loopback\r" (4/1)]
  } elseif {$mode=="on"} {
    set ret [Send $com "loopback remote\r" (4/1)]
  }
  if {$ret!=0} {return $ret}
#   30/01/2018 15:30:12     No need open-close loop on 4/2 (acc to Yehoshafat)
#   Send $com "exit\r" stam 0.25 
#   set ret [Send $com "ethernet 4/2\r" (4/2)]
#   if {$ret!=0} {return $ret}
#   if {$mode=="off"} {
#     set ret [Send $com "no loopback\r" (4/2)]
#   } elseif {$mode=="on"} {
#     set ret [Send $com "loopback remote\r" (4/2)]
#   }
#   if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# DateTime_Set
# ***************************************************************************
proc DateTime_Set {} {
  global gaSet buffer
  OpenComUut
  Status "Set DateTime"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
  }
  if {$ret==0} {
    set gaSet(fail) "Logon fail"
    set com $gaSet(comDut)
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure system\r" >system]
  }
  if {$ret==0} {
    set gaSet(fail) "Set DateTime fail"
    set ret [Send $com "date-and-time\r" "date-time"]
  }
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    set ret [Send $com "date $pcDate\r" "date-time"]
  }
  if {$ret==0} {
    set pcTime [clock format [clock seconds] -format "%H:%M"]
    set ret [Send $com "time $pcTime\r" "date-time"]
  }
  CloseComUut
  RLSound::Play information
  if {$ret==0} {
    Status Done yellow
  } else {
    Status $gaSet(fail) red
  } 
}
# ***************************************************************************
# LoadDefConf
# ***************************************************************************
proc LoadDefConf {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Load Default Configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(defConfCF) 
  set cfTxt "DefaultConfiguration"
  set ret [DownloadConfFile $cf $cfTxt 1]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "file copy running-config user-default-config\r" "yes/no" ]
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "successfull" 30]
  
  return $ret
}
# ***************************************************************************
# DdrTest
# ***************************************************************************
proc DdrTest {} {
  global gaSet buffer
  Status "DDR Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  
  if {![info exists ::readLeSw2]} {
    set ::readLeSw2 1
  }
  if {$::readLeSw2=="1"} {
    ## if the  ::leSw2 is not defined early -> read it
    Send $com "exit all\r" stam 0.5
    set ret [Send $com "le\r" ETX]
    if {$ret!=0} {return $ret}
    set res [regexp {sw\s+\"([\d\.\(\)]+)_?\"\s} $buffer ma leSw]
    if {$res==0} {
      set gaSet(fail) "Read SW fail"
    }
    puts "DdrTest ma:<$ma> leSw:<$leSw>"
    set leSw1 [lindex [split $leSw \(] 0]
    foreach {x y z} [split $leSw1 .] {}
    set leSw2 ${x}${y}${z}
    set ::leSw2 $leSw2
    puts "DdrTest leSw1:<$leSw1> leSw2:<$leSw2>"
  }
  
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-220A 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read MEA LOG fail"
  set ret [Send $com "debug mea\r" FPGA 11]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea debug log show\r" FPGA>> 30]
  if {$ret!=0} {return $ret}
  
#   if {[string match {*ENTU_ERROR*} $buffer]} {
#     set gaSet(fail) "\'ENTU_ERROR\' exists in the MEA log"
#     return -1
#   }
  if {$::leSw2=="570" || $::leSw2>"591"} {
    set ::calSucc "NA"
    set ::readWrite "NA"
    set res [regexp {EVENT -----cal_success (\d+)  Download Fpga} $buffer ma ::calSucc]
    if {$res==0} {
      set gaSet(fail) "Read \'cal_success\' fail"
      return -1
    } 
    set res [regexp {EVENT -----Read write  (\d+)  Reinit Fpga} $buffer ma ::readWrite]
    if {$res==0} {
      set gaSet(fail) "Read \'Read write\' fail"
      return -1
    } 
  } 

  if {[string match {*ENTU_ERROR Init DDR FAile................NOT OK*} $buffer]} {
    set gaSet(fail) "\'ENTU_ERROR Init DDR FAile................NOT OK\' exists in the MEA log"
    return -1
  }
  if {[string match {*ENTU_ERROR Write*} $buffer]} {
    set gaSet(fail) "\'ENTU_ERROR Write\' exists in the MEA log"
    return -1
  }
  if {[string match {*init DDR ..........................OK*} $buffer]==0} {
    set gaSet(fail) "\'init DDR ..OK\' doesn't exist in the MEA log"
    return -1
  }
  
  set gaSet(fail) "Exit from FPGA fail"
  set ret [Send $com "exit\r\r" ETX-220A 16]
  if {$ret!=0} {
    set ret [Send $com "\r\r" ETX-220A]
    if {$ret!=0} {return $ret}
  }
  return $ret
}  
# ***************************************************************************
# ReadIdBarcodeFromPage3
# ***************************************************************************
proc ReadIdBarcodeFromPage3 {} {
  global gaSet buffer
  set gaSet(BarcodeFromPage3) ""
  PowerOffOn
  
  set startSec [clock seconds]
  while 1 {
    set nowSec [clock seconds]
    set upSec [expr {$nowSec - $startSec}]
    if {$upSec>120} {
      set gaSet(fail) "Login to Boot fail"
      set ret -1
      break
    }
  
    Send $gaSet(comDut) "\r" stam 0.25
    if {[string match *boot* $buffer]} {
      set ret 0
      break
    }
    after 500 
  }
  
  if {$ret==0} {
    set ret [Send $gaSet(comDut) "d2 00\r" boot]
    if {$ret!=0} {
      set gaSet(fail) "Read Page fail"
    }
  }
  
  if {$ret==0} {
    set page3 ""
    set res [regexp {Page 3:\s+ ([\w\.]+)} $buffer ma page3] 
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read Page 03 fail"
    } 
    
    set b1 [lrange [split $page3 .] 2 12]
    set b2 ""
    foreach hex $b1 {
      append b2 [format %c [scan $hex %x]]
    }
    puts "page3:<$page3>"
    puts "b1:<$b1>"
    puts "b2:<$b2>"
    set gaSet(BarcodeFromPage3) $b2
  }
  
  return $ret
}
# ***************************************************************************
# ExtClkTxTest
# ***************************************************************************
proc ExtClkTxTest {mode} {
  global gaSet buffer
  Status "ExtClkTxTest $mode"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  if {$mode=="en"} {
    set frc "force-t4-as-t0"
  } else {
    set frc "no force-t4-as-t0"
  }
  set ret [Send $com "con sys clock domain 1\r" (1)]
  set ret [Send $com "$frc\r" (1)]
  
}
