proc BuildTests {} {
  global gaSet gaGui glTests
  
  set lTestNames [list DDR SetToDefault\
      DyingGaspConf DyingGaspTest_1 DyingGaspTest_2 \
      SK_ID PS_ID FansTemperature \
      XFP_ID SfpUtp_ID DateTime ExtClkUnlocked ExtClkLocked\
      DataTransmissionConf DataTransmissionTest\
      DataTransmissionConf_for3XFP DataTransmissionTest_for3XFP\
      DDR Leds Mac_BarCode SetToDefaultAll]
      # ExtClkUnlocked ExtClkLocked
      
  if {$gaSet(1G)=="None"} {
    foreach t $lTestNames {
      if ![string match SfpUtp_ID $t] {
        lappend pmtL $t
      }
    }
    set lTestNames $pmtL
  }    
  
  if {$gaSet(10G)!=3} {
    foreach t $lTestNames {
      if ![string match DataTr*_for3XFP $t] {
        lappend lTestsAllTests $t
      }
    }
  } else {
    set lTestsAllTests $lTestNames
  }
  
  if {$gaSet(chbPsTest)==1} {
    RLSound::Play information
    set lTestsAllTests [list]
    set res [DialogBox -icon /images/question -aspect 3000 -type "Yes No" \
        -message "Do you want to perform the FactoryDefault and download the Conf. file?"]
    if {$res=="Yes"} {
      lappend lTestsAllTests SetToDefault DyingGaspConf
    }
    if {$gaSet(ps)=="AC"} {
      lappend lTestsAllTests PS_ID DyingGaspTest_1 DyingGaspTest_2 Leds   
    } elseif {$gaSet(ps)=="DC"} {
      lappend lTestsAllTests PS_ID  Leds   
    } 
  }
  
  ## next lines remove DataTransmissionConf and DataTransmissionTest
  foreach t $lTestNames {
    if ![string match DataTr* $t] {
     lappend lTestsTestsWithoutDataRun $t
    }
  }
#   set lTestsFTwihtoutDataRun [lreplace $lTestNames [lsearch $lTestNames DataTransmissionConf] [lsearch $lTestNames DataTransmissionConf]]
#   set lTestsFTwihtoutDataRun [lreplace $lTestsFTwihtoutDataRun [lsearch $lTestsFTwihtoutDataRun DataTransmissionTest] [lsearch $lTestsFTwihtoutDataRun DataTransmissionTest]]  
  
  
    
  set glTests ""
  set lTests [set lTests$gaSet(TestMode)]
  
  if {$gaSet(chbPsTest)==0} {
    if {$gaSet(defConfEn)=="1"} {
      lappend lTests LoadDefaultConfiguration
    }
  }
  
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests
  
}
# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* DUT start *********..[MyTime].."
  Status "DUT start"
  set gaSet(curTest) ""
  update
    
  #AddToLog "********* DUT start *********"
  AddToPairLog $gaSet(pair) "********* DUT start *********"
     
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
      
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
    #AddToLog "Test \'$testName\' started"
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]
    if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode" && $testName!="ID" && $testName!="Leds"} {
#     set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
#     puts $logFileID "**** Test $numberedTest fail and rechecked. Reason: $gaSet(fail); [MyTime]"
#     close $logFileID
#     puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#     $gaSet(startTime) configure -text "$startTime .."
      
#     set ret [$testName 2]
    }
    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
    #AddToLog "Test \'$testName\' $retTxt"
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }
  
  AddToPairLog $gaSet(pair) "WS: $::wastedSecs"

  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
  return $ret
}

# ***************************************************************************
# FansTemperature
# ***************************************************************************
proc FansTemperature {run} {
  global gaSet
  Power all on
  set ret [FansTemperatureTest]
  return $ret
}

# ***************************************************************************
# PS_ID
# ***************************************************************************
proc PS_ID {run} {
  global gaSet
  Power all on
  set ret [PS_IDTest]
  return $ret
}

# ***************************************************************************
# SK_ID
# ***************************************************************************
proc SK_ID {run} {
  global gaSet
  Power all on
  set ret [SK_IDTest]
  return $ret
}

# ***************************************************************************
# DyingGaspConf
# ***************************************************************************
proc DyingGaspConf {run} {
  global gaSet
  Power all on
  set ret [DyingGaspSetup]
  return $ret
}
# ***************************************************************************
# DyingGaspTest_1
# ***************************************************************************
proc DyingGaspTest_1 {run} {
  global gaSet
  Power all on
  set ret [DyingGaspPerf 1 2]
  if {$ret!=0} {
    set ret [DyingGaspPerf 1 2]
    if {$ret!=0} {return $ret}
  }
  
  return $ret
}
# ***************************************************************************
# DyingGaspTest_2
# ***************************************************************************
proc DyingGaspTest_2 {run} {
  global gaSet gRelayState
  Power all on
  set ret [DyingGaspPerf 2 1]
  if {$ret!=0} {
    set ret [DyingGaspPerf 2 1]
    if {$ret!=0} {return $ret}
  }
  if {$gaSet(ps)=="DC"} {
    Power all off
    set gRelayState red
    IPRelay-LoopRed
    SendEmail "ETX220A-MP" "Manual Test"
    RLSound::Play information
    set txt "Remove the AC PSs and insert DC PSs"
    set res [DialogBox -type "OK Cancel" -icon /images/question -title "Change PS" -message $txt]
    update
    if {$res!="OK"} {
      return -2
    } else {
      set ret 0
    }
    Power all on
    set gRelayState green
    IPRelay-Green
  }
  return $ret
}

# ***************************************************************************
# XFP_ID
# ***************************************************************************
proc XFP_ID {run} {
  global gaSet
  Power all on
  set ret [XFP_ID_Test]
  return $ret
}  

# ***************************************************************************
# SfpUtp_ID
# ***************************************************************************
proc SfpUtp_ID {run} {
  global gaSet
  Power all on
  set ret [SfpUtp_ID_Test]
  return $ret
} 
# ***************************************************************************
# DateTime
# ***************************************************************************
proc DateTime {run} {
  global gaSet
  Power all on
  set ret [DateTime_Test]
  return $ret
} 

# ***************************************************************************
# DataTransmissionConf
# ***************************************************************************
proc DataTransmissionConf {run} {
  global gaSet
  Power all on
  set ret [DataTransmissionSetup 4/2]
  return $ret
} 
# ***************************************************************************
# DataTransmissionConf_for3XFP
# ***************************************************************************
proc DataTransmissionConf_for3XFP {run} {
  global gaSet
  Power all on
  set ret [DataTransmissionSetup 4/1]
  return $ret
}
# ***************************************************************************
# DataTransmissionTest
# ***************************************************************************
proc DataTransmissionTest {run} {
  global gaSet
  Status "Open ETH GENERATOR"
  set gaSet(id204) [RLEtxGen::Open $gaSet(comGEN) -package RLSerial]
  if {$gaSet(id204)<0} {
    set gaSet(fail) "Cann't open Etx-204 COM-$gaSet(comGEN)"
    return -1
  }  
  ConfigEtxGen
  return [DataTransmissionTestPerf]  
}
# ***************************************************************************
# DataTransmissionTest_for3XFP
# ***************************************************************************
proc DataTransmissionTest_for3XFP {run} {
  global gaSet
  catch {RLEtxGen::CloseAll}
  after 1000
  Status "Open ETH GENERATOR"
  set gaSet(id204) [RLEtxGen::Open $gaSet(comGEN) -package RLSerial]
  if {$gaSet(id204)<0} {
    set gaSet(fail) "Cann't open Etx-204 COM-$gaSet(comGEN)"
    return -1
  }
  ConfigEtxGen  
  
  return [DataTransmissionTestPerf]  
}
# ***************************************************************************
# DataTransmissionTestPerf
# ***************************************************************************
proc DataTransmissionTestPerf {} {
  global gaSet
  Power all on 
  set ret [Wait "Waiting for stabilization" 10 white]
  if {$ret!=0} {return $ret}
  
  Etx204Start
  set ret [Wait "Data is running" 10 white]
  if {$ret!=0} {return $ret}
  set ret [Etx204Check]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Data is running" 120 white]
  if {$ret!=0} {return $ret}
  
  set ret [Etx204Check]
  if {$ret!=0} {return $ret}
 
  return $ret
}  
# ***************************************************************************
# ExtClkUnlocked
# ***************************************************************************
proc ExtClkUnlocked {run} {
  global gaSet
  Power all on
  set ret [ExtClkTest Unlocked]
  return $ret
}
# ***************************************************************************
# ExtClkLocked
# ***************************************************************************
proc ExtClkLocked {run} {
  global gaSet
  Power all on
  set ret [Login]
  if {$ret!=0} {return $ret}

  set cf $gaSet(ExtClkCF) 
  set cfTxt "EXT CLK"
  set ret [DownloadConfFile $cf $cfTxt 1]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Locked]
  if {$ret!=0} {
    Power all off
    after 3000
    Power all on
    set ret [ExtClkTest Locked]
    if {$ret!=0} {return $ret}
  }  
  #set ret [FactDefault std]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# ExtClk
# ***************************************************************************
proc ExtClk {run} {
  global gaSet
  # Power all off
  # after 3000
  Power all on
  # Wait "Wait for UUT up" 30 white 
  set ret [ExtClkTest Unlocked]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Locked]
  return $ret
}
# ***************************************************************************
# Leds
# ***************************************************************************
proc Leds {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  
  if {$gaSet(10G)==3} {
    set ret [Loopback on]
    if {$ret!=0} {return $ret}
    set almText "blinking"
  } else {
    set almText "ON"
  }
  if {$gaSet(TestMode)!="AllTests"} {
    ## full configuration for LINKs' led
    set cf $gaSet($gaSet(10G)CF) 
    set cfTxt "$gaSet(10G)XFP"
    set ret [DownloadConfFile $cf $cfTxt 0]
    if {$ret!=0} {return $ret}
    
    ## DyingGasp for pings
    set cf $gaSet(dgCF)
    set cfTxt "Dying Gasp"
    set ret [DownloadConfFile $cf $cfTxt 1]
    if {$ret!=0} {return $ret}
  }
  
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX220A-MP" "Manual Test"
  
  if {$gaSet(chbPsTest)==0} {
    ## check the leds and pings in case of regular test, not PSs' test
  
    catch {set pingId [exec ping.exe 10.10.10.1[set gaSet(pair)] -t &]}
    
    RLSound::Play information
    set txt "Verify that:\n\
    GREEN \'PWR\' led is ON\n\
    RED \'TST/ALM\' led is $almText\n\
    GREEN \'LINK\' led of \'MNG-ETH\' is ON\n\
    ORANGE \'ACT\' led of \'MNG-ETH\' is blinking\n\
    On each PS GREEN \'POWER\' led is ON\n\
    GREEN \'LINK\' leds of 1 Giga ports are blinking\n\
    GREEN \'LINK\' leds of 10 Giga ports are ON\n\
    ORANGE \'ACT\' leds of 10 Giga ports are blinking\n\
    EXT CLK's GREEN \'SD\' led is ON\n\
    Verify fans rotate"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
    update
    
    catch {exec pskill.exe -t $pingId}
    
    if {$res!="OK"} {
      set gaSet(fail) "LED Test failed"
      return -1
    } else {
      set ret 0
    }
    if {$gaSet(10G)==3} {
      set ret [Loopback off]
      if {$ret!=0} {return $ret}
    }  
  }
  
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
#   set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 
  
  foreach ps {2 1} {
    Power $ps off
    after 3000
    set val [ShowPS $ps]
    puts "val:<$val>"
    if {$val=="-1"} {return -1}
    if {$val!="Failed"} {
      set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Failed\""
#       AddToLog $gaSet(fail)
      return -1
    }
    RLSound::Play information
    set txt "Verify on PS-$ps that RED led is ON"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "LED Test failed"
      return -1
    } else {
      set ret 0
    }
    
    RLSound::Play information
    set txt "Remove PS-$ps and verify that led is OFF"
    set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "PS_ID Test failed"
      return -1
    } else {
      set ret 0
    }
    
    set val [ShowPS $ps]
    puts "val:<$val>"
    if {$val=="-1"} {return -1}
    if {$val!="Not exist"} {
      set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
#       AddToLog $gaSet(fail)
      return -1
    }
    
#     RLSound::Play information
#     set txt "Verify on PS $ps that led is OFF"
#     set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#     update
#     if {$res!="OK"} {
#       set gaSet(fail) "LED Test failed"
#       return -1
#     } else {
#       set ret 0
#     }
    
    RLSound::Play information
    set txt "Assemble PS-$ps"
    set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "PS_ID Test failed"
      return -1
    } else {
      set ret 0
    }
    Power $ps on
    after 2000
  }
  if {$gaSet(chbPsTest)==1} {
    ## don't check the rest in test of PSs
    return $ret
  }
  
#   RLSound::Play information
#   set txt "Verify EXT CLK's GREEN SD led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  RLSound::Play information
  set txt "Remove the EXT CLK cable and verify the SD led is OFF"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
 
  set ret [TstAlm off]
  if {$ret!=0} {return $ret} 
  RLSound::Play information
  set txt "Verify the TST/ALM led is off"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
  RLSound::Play information
  set txt "Disconnect all cables and optic fibers and verify GREEN leds are off"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
#   set ret [TstAlm on]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  set res [regexp {\.[AD]{1,2}C\.} $gaSet(DutInitName)]
  puts "Leds_Fan $gaSet(DutInitName) res:<$res>"
  if {$res==0} {
    # if two PSs - no message
    set ret 0
  } else {    
    Power 2 off
    RLSound::Play information
    set txt "Remove PS-2"
    set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" \
      -message $txt -bg yellow -font {TkDefaultFont 11}]
    update
    
    if {$res!="OK"} {
      set gaSet(fail) "Remove PS-2 fail"
      set ret -1
    } else {
      set ret 0
    }    
  }
  
  return $ret
}
# ***************************************************************************
# SetToDefault
# ***************************************************************************
proc SetToDefault {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault std]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefaultAll
# ***************************************************************************
proc SetToDefaultAll {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  global gaSet  
  set pair $::pair 
  puts "Mac_BarCode \"$pair\" "
  mparray gaSet *mac* ; update
  mparray gaSet *barcode* ; update
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [ReadMac]
      if {$ret!=0} {return $ret}
    }  
  } 
  #set ret [ReadBarcode [PairsToTest]]
  set ret [ReadBarcode]
  if {$ret!=0} {return $ret}
  set ret [RegBC]
      
  return $ret
}

# ***************************************************************************
# LoadDefaultConfiguration
# ***************************************************************************
proc LoadDefaultConfiguration {run} {
  global gaSet  
  Power all on
  set ret [LoadDefConf]
  return $ret
}
# ***************************************************************************
# DDR
# ***************************************************************************
proc DDR {run} {
  global gaSet
  set ::readLeSw2 1
  Power all on
  set ret [DdrTest]
  return $ret
}
