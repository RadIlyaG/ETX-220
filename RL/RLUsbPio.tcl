#***************************************************************************
#** Filename: RLUsbPio.tcl 
#** Written by Semion  13.6.2007  
#** 
#** Absrtact: This file operate with Pci PC card PIO, used functions
#**           in RLDUsbPio.dll
#** Inputs:
#**     The COMMANDs are:
#**       - RLUsbPio::Open            : Open port of specific group: PORT/SPDT/RBA ,return Id (list of port group card) of this port.
#**       - RLUsbPio::Close           : Close port of specific group: PORT/SPDT/RBA.
#**       - RLUsbPio::SetConfig       : Configure PIO(in/out) of group: PORT.
#**       - RLUsbPio::GetStateUsbPio  : Get Configure status PIO(in/out) of group: PORT and pin status of RBA/SPDT.
#**       - RLUsbPio::Set             : Set port to binary value (e.g. 10101010).
#**       - RLUsbPio::Get             : Get from port of PORT group its binary status. 
#**       - RLUsbPio::GetBusy         : Return opened state of specific port or all ports. 
#**       - RLUsbPio::Reset           : Resets PIO Card. 
#**       - RLUsbPio::WriteExtI2c     : Write data to external I2C.
#**       - RLUsbPio::ReadExtI2C      : Read data from external I2C. 
#**            
#** Examples:  
#**
#**     set id [RLUsbPio::Open 3 PORT 2]   ; #opens port 3 of ports group PORT channel number 2(default 1)
#**     set id [RLUsbPio::Open 1 PORT]     ; #opens port 1 of ports group PORT channel number 1(default)
#**     set id [RLUsbPio::Open 2 SPDT 2]   ; #opens port 2 of ports group SPDT channel number 2(default 1)
#**     set id [RLUsbPio::Open 5 RBA]      ; #opens port 5 of ports group RBA channel number 1(default)
#**     RLUsbPio::Reset                    ; #Resets USB PIO channel(default 1). 
#**     RLUsbPio::Close $id                ; #closes port with id = $id 
#**     RLUsbPio::SetConfig $id 10101010   ; #configure output pins of port(group PORT) with id=$id in/out: 1-in 0-out
#**     RLUsbPio::GetStateUsbPio $id state ; #return configuration state(in/out) of port(group PORT) with id=$id by state variable 1-in 0-out
#**                                          or pin status of RBA/SPDT                                          
#**     RLUsbPio::Set $id 11110000         ; #set port with id=$id to 11110000 value
#**     RLUsbPio::Set $id 1                ; #set port with id=$id LSB bit to 1 value (e.g. for RBA or SPDT group)
#**     RLUsbPio::Get $id buff             ; #get from port with id=$id its value returned by buff variable
#**     RLUsbPio::GetBusy $id state        ; #get busy state of port with id=$id returned by state variable,
#**																					 if id == "all group card" procedure return busy state of all ports of this group
#***************************************************************************

package require RLEH 1.0
package require RLDUsPio 1.0


  #**  1  .  RLDLLGetUsbChannels descr
  #**  2  .  RLDLLOpenUsbPio     port  group     [channel]
  #**  3  .  RLDLLConfigUsbPio   port  cfgData   [channel] note: configured only group PORT
  #**  4  .  RLDLLSetUsbPio      port    group     byte     [channel]
  #**  5  .  RLDLLGetUsbPio      port    readByte  [channel]
	#**  6  .  RLDLLSetGPIO        configByte  dataByte [channel]
	#**  7  .  RLDLLGetGPIO        dataByte [channel]
  #**  8  .  RLDLLGetStateUsbPio port grour  cfgState  [channel]
  #**  9  .  RLDLLGetBusyUsbPio  group busyState [channel]
	#**  10 .  RLDLLWriteExtI2cUsbPio devAddress writeAddress data [channel]
	#**  11 .  RLDLLReadExtI2cUsbPio devAddress readAddress data [channel]
  #**  12 .  RLDLLClosePio       port		group		  [channel]
	#**  13 .  RLDLLResetUsbPio		[card]
	#**  14 .  RLDLLCloseAllCurrentUsbPio channel

package provide RLUsbPio 1.0
namespace eval RLUsbPio    { 

  namespace export GetUsbChannels Open Close SetConfig GetStateUsbPio Set Get WriteExtI2C ReadExtI2C GetBusy Reset
 
  global gMessage
  variable vPioChannelsQty
	set vPioChannelsQty 0



#***************************************************************************
#**                        RLUsbPio::GetUsbChannels
#** 
#** Absrtact: return number of PIO USB channels connected to PC. 
#**
#** Inputs:     
#**           descript    variable where the GetUsbChannels procedure return descriptions of all USB PIO connected to PC
#**
#** Outputs:  number of PIO USB channels connected to PC    	if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**     set qty [RLUsbPio::GetUsbChannels descript]  
#**     parray descript                           
#***************************************************************************
proc GetUsbChannels {args} {

 #global (import) from RLDUsbPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set maxarg       1
  set minarg       1
  set ok           0
  upvar [lindex $args 0] description

  if { $arrleng != $minarg}  {
    set gMessage "GetUsbChannels:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
	} else {
      set qty [RLDLLGetUsbChannels description]
	}
	if {$qty < 0} {
    set gMessage $ERRMSG
    append gMessage "\nERROR while GetUsbChannels."
    tk_messageBox -message $gMessage -title Warning -type ok -icon warning
		return -1
  } else {
	   set vPioChannelsQty $qty
		 return $qty
	}

}
#***************************************************************************
#**                        RLUsbPio::Open
#** 
#** Absrtact: Open procedure use RLDUsPio dll to open port in USB PIO channel. 
#**
#** Inputs:     
#**           port     port number to open (1-24 for PORT group , 1-8 for RBA  group , 1-5 for SPDT group)
#**           group    1 - PORT , 2 - SPDT , 3 - RBA	, EXI2C - 4
#**           channel     channel number (default = 1)
#**
#**
#** Outputs:  id (list of portnumber groupnumber cardnumber)	if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**     set id [RLUsbPio::Open 3 PORT 2]   ; #opens port 3 of ports group PORT channel number 2(default 1)
#**     set id [RLUsbPio::Open 1 PORT]     ; #opens port 1 of ports group PORT channel number 1(default)
#**     set id [RLUsbPio::Open 2 SPDT] 2   ; #opens port 2 of ports group SPDT channel number 2(default 1)
#**     set id [RLUsbPio::Open 5 RBA]      ; #opens port 5 of ports group RBA channel number 1(default)
#**     set id [RLUsbPio::Open 5 EXTI2C]   ; #opens External I2C channel number 1(default)
#***************************************************************************

proc Open { args }  {
 
  #global (import) from RLDUsbPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set maxarg       3
  set minarg       2
	set portnumber   [lindex $args 0]
	set group        [string toupper [lindex $args 1]]
  set ok           0
  
  if {$portnumber == "?"} {
    return "arguments options:  First: port number , Second: group (PORT/SPDT/RBA) , Third: card number (default = 1)"
  }

  if { $arrleng > $maxarg|| $arrleng < $minarg }  {
    set gMessage "Open UsbPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
	} elseif {$arrleng == $maxarg} {
			set cardnumber   [lindex $args 2]
	} else {
			set cardnumber   1
	}
     
  switch  $group {
    PORT  { set groupnumber 1 }
    SPDT  { set groupnumber 2 }
    RBA   { set groupnumber 3 }
    EXTI2C { set groupnumber 4 }
    default {
      set gMessage "Open UsbPio: Syntax error ,use: PORT/SPDT/RBA/EXTI2C for group parameter."
      return [RLEH::Handle SAsyntax gMessage]
    }
	}
	if {$vPioChannelsQty == 0} {
    set gMessage "There are not USB PIO Channels in PC."
    RLEH::Handle Warning  gMessage
		return -1
	}
  set err [RLDLLOpenUsbPio $portnumber $groupnumber $cardnumber]
	if {$err < 0} {
    set gMessage $ERRMSG
    append gMessage "\nERROR while open UsbPio."
    RLEH::Handle Warning  gMessage
		return -1
  } else {
	    return "$portnumber $groupnumber $cardnumber"
	}
}  
 
#******************************************************************************
#**                        RLUsbPio::Close
#** 
#** Absrtact: Close procedure use RLDUsbPio dll to close Pio port. 
#**
#** Inputs:   idPio : The port ID returned by Open procedure. 
#**
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**                              
#**           RLUsbPio::Close $id
#*****************************************************************************

proc Close { args }  {

  # global (import) from RLDUsPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set idpiolist [lindex $args 0]
  set numbargs     1
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  ID list in form: {port group card}"
  }

  # Checking number arguments
  if { $arrleng != $numbargs } {
    set gMessage "Close UsbPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    
    # Close pio                   
  } else {
      if {[set err [RLDLLCloseUsbPio [lindex $idpiolist 0] [lindex $idpiolist 1] [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Close UsbPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLUsbPio::SetConfig
#** 
#** Absrtact: SetConfig procedure use RLDUsPio dll to configure Pio port of PORT group. 
#**
#** Inputs:    
#**           idPio   : The port ID returned by Open procedure
#**					  binary code for all bits 1-for input 0-for output
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLUsbPio::SetConfig $id 11110000
#**           RLUsbPio::SetConfig $id 10101010
#***************************************************************************

proc SetConfig { args } {
 
  # global (import) from RLDUsbPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
  set cfgCode  [lindex $args 1]
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: bits config. (in/out) 1-for input 0-for output "
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "SetConfig UsbPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    # config pio                   
  } else {
      if {[set err [RLDLLConfigUsbPio [lindex $idpiolist 0] $cfgCode [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while SetConfig UsbPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLUsbPio::GetStateUsbPio
#** 
#** Absrtact: GetStateUsbPio procedure use RLDUsPio dll to get how was configure Pio port of PORT group and output state of SPDT and RBA. 
#**
#** Inputs:    
#**           idPio   : The port ID returned by Open procedure
#**           state   : Variable where procedure return configuration state.
#**
#**
#** Outputs:  0  and configured value by state variable   if success
#**           negativ code and error message by RLEH      if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLUsbPio::GetStateUsbPio $id state
#***************************************************************************

proc GetStateUsbPio { args } {
 
  # global (import) from RLDUsPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
  set group [lindex $idpiolist 1]
  set readstatus [ lindex $args 1]
  upvar $readstatus cfgStatus
	set state ""
	set cfgStatus ""
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: variable where procedure return config value."
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "GetStateUsbPio UsbPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    #get config pio                   
  } else {
      if {[set err [RLDLLGetStateUsbPio [lindex $idpiolist 0] $group state [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while GetStateUsbPio UsbPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
    	set cfgStatus $state
      return $ok
  }
}

#***************************************************************************
#**                        RLUsbPio::Set
#** 
#** Absrtact: RLUsbPio::Set procedure use RLDUsPio dll to Write to Pio port. 
#**
#** Inputs:   
#**           idPio   : The port ID returned by Open procedure
#**           byteCod : binary cod from 1 to 8 bit
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**                              
#**     RLUsbPio::Set $id 10101111
#**     RLUsbPio::Set $id 1                ; #set port with id=$id LSB bit to 1 value (e.g. for RBA or SPDT group)
#***************************************************************************

proc Set { args } {
 
  # global (import) from RLDUsPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
	set value	  [lindex $args 1]
	set group [lindex $idpiolist 1]
  set ok           0

	if {$group == 2 ||  $group == 3} {
	  if {$value != 0} {
   	  set value 1
	  } else {
	     set value 0
		}
	}

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: bynary value to write to port(e.g. 10101010)."
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "Set UsbPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    # Write pio                   
  } else {
      if {[set err [RLDLLSetUsbPio [lindex $idpiolist 0] $group $value [lindex $idpiolist 2]]]} {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Set UsbPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#*******************************************************************************
#**                        RLUsbPio::Get
#** 
#** Absrtact: Get procedure use RLDUsPio dll to get the binary valuue of port from PORT group. 
#**
#** Inputs:    
#**           idPio       : The port ID returned by Open procedure
#**           state       : Variable where procedure return binary valuue of port.
#**					  [register]  : Which register read(output or input) default input
#**
#** Outputs:  0  and port value by state variable         if success
#**           negativ code and error message by RLEH      if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLUsbPio::Get $id state
#**           RLUsbPio::Get $id state out
#******************************************************************************

proc Get { args } {
 
  # global (import) from RLDUsbPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
  set readstatus [lindex $args 1]
	set register 1
  upvar $readstatus valStatus
	set valStatus ""
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: variable where procedure return value, [Third]: register to be read(out/in) default: in."
  }
  # Checking number arguments
  if { $arrleng < $numbargs }  {
    set gMessage "Get UsbPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    #get pio 
  } else {
	    if {$arrleng > $numbargs} {
	      set register [lindex $args 2]
		    if {[string tolower $register] == "out"} {
	 		    set register 0
				} elseif {[string tolower $register] == "in"} {
	 		    set register 1
				} else {
	         set gMessage "Get UsbPio:  Wrong third argument MUST BE out or in"
	         return [RLEH::Handle SAsyntax gMessage]
				}
			}
			if {[lindex $idpiolist 1] != 1} {
	      set gMessage "Get UsbPio: Syntax error ,only ports from PORT group may be for this procedure."
	      #return [RLEH::Handle SAsyntax gMessage]
				return -1
			}
      if {[set err [RLDLLGetUsbPio [lindex $idpiolist 0] valStatus $register [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Get UsbPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLUsbPio::WriteExtI2C
#** 
#** Absrtact: RLUsbPio::WriteExtI2C procedure use RLDUsPio dll to Write to External I2C port. 
#**
#** Inputs:   
#**           DevAddress     : External I2C port address
#**           writeAddress   : Address where the data will be written
#**           data           : Data to be written (format of data: xx xx xx ... where x is 0-F)
#**					  [channel]			 : Usb Pio channel(default 1) 
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**                              
#**     RLUsbPio::WriteExtI2C 70 80 "44 aa cc 56 89"
#***************************************************************************

proc WriteExtI2C { args } {
 
  # global (import) from RLDUsPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

	set channel 1
  set arrleng      [llength $args]
  set numbargs     3
  set devAddress [lindex $args 0]
  set writeAddress [lindex $args 1]
	set data	  [lindex $args 2]
  set ok           0

  if {$devAddress == "?"} {
    return "arguments options:  First:Device address ,Second Write address, Third: data to write, forth channel(default 1)"
  }
  # Checking number arguments
  if {$arrleng > $numbargs} {
      set channel [lindex $args 3]
	}
	if {$channel <= 0 || $channel > $vPioChannelsQty} {
    set gMessage "WriteExtI2C:  Wrong channel number"
    return [RLEH::Handle SAsyntax gMessage]
	}
  if { $arrleng < $numbargs }  {
    set gMessage "WriteExtI2C:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
	}
	if {$devAddress >127 || $devAddress < 0} {
    set gMessage "WriteExtI2C:  Wrong I2C Device address: MUST BE <=127, >=0"
    return [RLEH::Handle SAsyntax gMessage]
    # Write pio 
  } else {
	    foreach part $data {
			  if {[regexp {^[0-9a-fA-F]{2}$} $part] == 0} {
			    set gMessage "WriteExtI2C:  Wrong data: $part"
			    return [RLEH::Handle SAsyntax gMessage]

				}
			}
      if {[set err [RLDLLWriteExtI2cUsbPio $devAddress $writeAddress [join $data ""] $channel]]} {
        set gMessage $ERRMSG
        append gMessage "\nERROR while Set WriteExtI2C."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}


#*******************************************************************************
#**                        RLUsbPio::ReadExtI2C
#** 
#** Absrtact: ReadExtI2C procedure use RLDUsPio dll to get data from External I2C port. 
#**
#** Inputs:    
#**           DevAddress     : External I2C port address
#**           readAddress    : Address from the data will be read
#**           data           : Data to be read (format of data: xx xx xx ... where x is 0-F)
#**           number         : Qty of data to be read.
#**					  [channel]			 : Usb Pio channel(default 1) 
#**
#**
#** Outputs:  0  and port value by state variable         if success
#**           negativ code and error message by RLEH      if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLUsbPio::ReadExtI2C 80 100 readData 8
#******************************************************************************

proc ReadExtI2C { args } {
 
  # global (import) from RLDUsbPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

 	set channel 1
  set arrleng      [llength $args]
  set numbargs     4
  set devAddress [lindex $args 0]
  set readAddress [lindex $args 1]
	set readData	  [lindex $args 2]
	set qtyData	  [lindex $args 3]
  set ok           0

	upvar $readData data

  if {$devAddress == "?"} {
    return "arguments options:  First:Device address ,Second Read address, Third: data to read, forth quantity of data to be read, fivth channel(default 1)"
  }
  # Checking number arguments
  if {$arrleng > $numbargs} {
      set channel [lindex $args 4]
	}
	if {$channel <= 0 || $channel > $vPioChannelsQty} {
    set gMessage "WriteExtI2C:  Wrong channel number"
    return [RLEH::Handle SAsyntax gMessage]
	}
  if { $arrleng != $numbargs }  {
    set gMessage "ReadExtI2C:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
	}
	if {$devAddress >127 || $devAddress < 0} {
    set gMessage "ReadExtI2C:  Wrong I2C Device address: MUST BE <=127, >=0"
    return [RLEH::Handle SAsyntax gMessage]
    #get pio                   
  } else {
      if {[set err [RLDLLReadExtI2cUsbPio $devAddress $readAddress data $qtyData $channel]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while WriteExtI2C."
        return [RLEH::Handle SAsyntax gMessage]
      }
      return $ok
  }
}

#***************************************************************************
#**                        RLUsbPio::GetBusy
#** 
#** Absrtact: GetBusy procedure use RLDUsbPio dll to get busy statuses of PIO ports. 
#**
#** Inputs:    
#**           idPio   : The port ID returned by Open procedure or other list of {portnumber groupnamber card number}
#**           state   : Variable where procedure return busy state of PIO ports.
#**
#**
#** Outputs:  0  and busy status by state variable        if success
#**           negativ code and error message by RLEH      if error   
#**                                 
#**                                 
#** Example:                        
#**                              
#**           RLUsbPio::GetBusy $id state
#**           RLUsbPio::GetBusy "24 1 1" state ;#first arg from id list - port 24 , second arg 1 - group PORT , third arg 1 - card 1 
#***************************************************************************

proc GetBusy { args } {
 
  # global (import) from RLDUsbPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set numbargs     2
  set idpiolist [lindex $args 0]
  set readstatus [ lindex $args 1]
  upvar $readstatus busyStatus
	set state ""
	set busyStatus ""
  set ok           0

  if {$idpiolist == "?"} {
    return "arguments options:  First: ID list in form: {port group card} , Second: variable where procedure return value."
  }
  # Checking number arguments
  if { $arrleng != $numbargs }  {
    set gMessage "GetBusy UsbPio:  Wrong number of arguments"
    return [RLEH::Handle SAsyntax gMessage]
    #get config pio                   
  } else {
	    set group [lindex $idpiolist 1]
			set port  [lindex $idpiolist 0]
      if {[set err [RLDLLGetBusyUsbPio $group state [lindex $idpiolist 2]]]}  {
        set gMessage $ERRMSG
        append gMessage "\nERROR while GetBusy UsbPio."
        return [RLEH::Handle SAsyntax gMessage]
      }
			if {![string match [string tolower $port] "all"]} {
				if {$group == 1 && ($port < 0 || $port > 24)} {
		      set gMessage "GetBusy UsbPio: Syntax error ,port number missmatch with group PORT."
		      #return [RLEH::Handle SAsyntax gMessage]
					return -1
				} elseif {$group == 2 && ($port < 0 || $port > 5)} {
			      set gMessage "GetBusy UsbPio: Syntax error ,port number missmatch with group SPDT."
			      #return [RLEH::Handle SAsyntax gMessage]
						return -1
				} elseif {$group == 3 && ($port < 0 || $port > 8)} {
			      set gMessage "GetBusy UsbPio: Syntax error ,port number missmatch with group RBA."
			      #return [RLEH::Handle SAsyntax gMessage]
						return -1
				}
				#specific port busy status
				if {[string index $state [expr $port - 1]] == 1} {
				  set busyStatus busy
				} else {
				    set busyStatus free
				}
			} else {
			    #all ports busy status 
			    set busyStatus	$state
			}
      return $ok
  }
}

#***************************************************************************************
#**                        RLUsbPio::Reset
#** 
#** Absrtact: RLUsbPio::Reset procedure use RLDUsbPio dll to reset Pio card. 
#**
#** Inputs:   
#**           [card]   : The card number (default = 1)
#**
#** Outputs:  0                           	                  if success
#**           negativ code and error message by RLEH          if error   
#**                                 
#** Example:                        
#**                              
#**     RLUsbPio::Reset 2
#**     RLUsbPio::Reset                ; #reset card number 1
#*************************************************************************************

proc Reset { args } {
 
  # global (import) from RLDUsbPio.dll
  global ERRMSG
  #Message to be send to EH 
  global gMessage
  variable vPioChannelsQty

  set arrleng      [llength $args]
  set ok           0

  if {$args == "?"} {
    return "arguments options:  card number (if empty, card number = 1)"
  }
  # Checking number arguments
  if { $arrleng == 0 }  {
    set cardnumber 1
	} else {
      set cardnumber [lindex $args 0]
	}
  if {[set err [RLDLLResetUsbPio $cardnumber ]]} {
    set gMessage $ERRMSG
    append gMessage "\nERROR while Reset UsbPio."
    return [RLEH::Handle SAsyntax gMessage]
  }
  return $ok
}
set qty [RLDLLGetUsbChannels description]
if {$qty > 0} {
  set RLUsbPio::vPioChannelsQty $qty             
}
# end name space
} 
                 
