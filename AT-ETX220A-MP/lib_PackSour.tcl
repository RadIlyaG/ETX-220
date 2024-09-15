wm iconify . ; update
## delete barcode files TO3001483079.txt
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
}
if [file exists c:/TEMP_FOLDER] {
  file delete -force c:/TEMP_FOLDER 
}
after 1000
set ::RadAppsPath c:/RadApps

if 1 {
  set gaSet(radNet) 0
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.9*} $ip]} {
      set gaSet(radNet) 1
    }  
  }
  if {$gaSet(radNet)} {
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautosync.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl c:/tcl/lib/rl
      after 2000
    }
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautoupdate.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl c:/tcl/lib/rl
      after 2000
    }
    update
  }
  
  package require RLAutoSync
  
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-220A-MP/AT-ETX220A-MP]
  set d1 [file normalize  c:/AT-ETX220A-MP]
#   set s2 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-220A-MP/download]
#   set d2 [file normalize  C:/download]
  
  if {$gaSet(radNet)} {
    set emailL {{yehoshafat_r@rad.com} {} {} }
  } else {
    set emailL [list]
  }
  
  set ret [RLAutoSync::AutoSync "$s1 $d1" -noCheckFiles {init*.tcl skipped.txt *.db} \
      -noCheckDirs {temp tmpFiles OLD old} -jarLocation $::RadAppsPath \
      -javaLocation $gaSet(javaLocation) -emailL $emailL -putsCmd 1 -radNet $gaSet(radNet)]
  #console show
  puts "ret:<$ret>"
  set gsm $gMessage
  foreach gmess $gMessage {
    puts "$gmess"
  }
  update
  if {$ret=="-1"} {
    set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
    -message "The AutoSync process did not perform successfully.\n\n\
    Do you want to continue? "]
    if {$res=="no"} {
      SQliteClose
      exit
    }
  }
  
  if {$gaSet(radNet)} {
    package require RLAutoUpdate
    set s2 [file normalize W:/winprog/ATE]
    set d2 [file normalize $::RadAppsPath]
    set ret [RLAutoUpdate::AutoUpdate "$s2 $d2" \
        -noCopyGlobL {Get_Li* Get28* Macreg.2* Macreg-i* DP* *.prd}]
    #console show
    puts "ret:<$ret>"
    set gsm $gMessage
    foreach gmess $gMessage {
      puts "$gmess"
    }
    update
    if {$ret=="-1"} {
      set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
      -message "The AutoSync process did not perform successfully.\n\n\
      Do you want to continue? "]
      if {$res=="no"} {
        #SQliteClose
        exit
      }
    }
  }
}

package require BWidget
package require img::ico
package require RLSerial
package require RLEH
package require RLTime
package require RLStatus
package require RLEtxGen
package require RLExPio
package require RLSound
RLSound::Open [list failbeep fail.wav passbeep pass.wav beep warning.wav information info.wav]
##package require RLScotty ; #RLTcp
package require ezsmtp
package require http
package require tls
package require base64
::http::register https 8445 ::tls::socket
::http::register https 8443 ::tls::socket
package require RLAutoUpdate
package require registry
set gaSet(hostDescription) [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters" srvcomment ]
package require sqlite3

source Gui_Etx220AMP.tcl
source Main_Etx220AMP.tcl
source Lib_Put_Etx220AMP.tcl
source Lib_Gen_Etx220AMP.tcl
source [info host]/init$gaSet(pair).tcl
source lib_bc.tcl
source Lib_DialogBox.tcl
source Lib_FindConsole.tcl
source LibEmail.tcl
source LibIPRelay.tcl
source Lib_Etx204.tcl
source lib_chkDdr.tcl
if {[info exists gaSet(DutInitName)] && \
    [file exists uutInits/$gaSet(DutInitName)]} {
  source uutInits/$gaSet(DutInitName)
} else {
  source [lindex [glob uutInits/ETX*.tcl] 0]
}
source lib_SQlite.tcl
source Lib_GetOperator.tcl
source LibUrl.tcl

source Lib_Ramzor.tcl
source lib_EcoCheck.tcl

if ![info exists gaSet(pioType)] {
  set gaSet(pioType) Ex
}
if {$gaSet(pioType)=="Usb"} {
  package require RLUsbPio
}

set gaSet(act) 1
set gaSet(initUut) 1
set gaSet(oneTest)    0
set gaSet(puts) 1
set gaSet(noSet) 0

set gaSet(toTestClr)    #aad5ff
set gaSet(toNotTestClr) SystemButtonFace
set gaSet(halfPassClr)  #ccffcc

set gaSet(useExistBarcode) 0
#set gaSet(1.barcode1) CE100025622
set gaSet(relDebMode) Release

if ![file exists c:/logs]  {
  file mkdir c:/logs
}
if ![file exists c:/logs/ddr]  {
  file mkdir c:/logs/ddr
}
set gaSet(eraseTitleTmp) $gaSet(eraseTitle)

GUI
BuildTests
update
wm deiconify .
wm geometry . $gaGui(xy)
update
Status "Ready"  
#set ret [SQliteOpen]