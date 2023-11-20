
#===============================================================
#
#  FileName:   RLSocket.tcl
#
#  Written by: Ilya / 27.01.2002
#
#  Abstract:   This file contains procedures for create and use 
#              by Socket mechanism of TCL.
#
#  Procedures:    - Open
#                 - ToClient
#                 - ToServer
#                 - Wait
#
#===============================================================

package require RLEH
package provide RLSocket 1.01


namespace eval RLSocket {

  namespace export Open ToClient ToServer Wait CloseClient  

  #***************************************************************
  #** Open
  #**
  #** Abstract: Create socket channel(s) between the Server and Client(s).
  #**
  #** Inputs:  list of clients.
  #**
  #** Outputs:
  #**
  #** Usage:  RLSocket::Open 2540 {FbA FbB}
  #**         RLSocket::Open 2644 [list $equipA $equipB]
  #**
  #***************************************************************
  proc Open {ip_firstPort ipl_clients} { 
   global tcl_pkgPath gMessage
   variable gaSC
   variable cPort
	set cPort $ip_firstPort
   for {set i 0} {$i<[llength $ipl_clients]} {incr i} { 
     set cl [lindex $ipl_clients $i]
     set port $cPort
     incr cPort
     if [ catch {_Server $port $cl} res] {
       set gMessage $res
       return [RLEH::Handle Syntax gMessage]
     } else {
       exec [info nameofexecutable] \
          c:/RLFiles/Socket/RLSocketClient.tcl $port $cl &  
     }
   }
   _delay 1000
  return 0
  }


  #***************************************************************
  #** ToClient
  #**
  #** Abstract: Send from server to client command to executing.
	#**           The command must appear as single parameter (see Usage).
  #**           Init the start value for result of client
	#**          
  #** Inputs:  client's name
	#            command to executing
  #**
  #** Outputs: 
  #**
	#** Usage:  RLSocket::ToClient FbA "InitFB E1"
	#**         RLSocket::ToClient [list LA140 "Setup bundle 5"]	
  #**
  #***************************************************************
 	proc ToClient {cl cmd} {
	  global gMessage
	  variable gaSC
		variable gaSet
		# init the start value for result of client: 	      
		set gaSet(res$cl) "NA"
		puts [set gaSC(cl$cl)] [list $cl $cmd]
		return {}
	}

  #***************************************************************
  #** ToServer
  #**
  #** Abstract: Send from client to server command to executing.
	#**           The command must appear as single parameter (see Usage) 
	#**           If need to return to server the result of executing any procedure
	#**           in client - the value must be inclose in ()
	#**          
  #** Inputs: command to executing
  #**
  #** Outputs: 
  #**
	#** Usage:  RLSocket::ToServer "Status Done"
	#**         RLSocket::ToServer [list Status "All Done"]
	#**         RLSocket::ToServer (ok)
	#**         RLSocket::ToServer (abort)
	#**         RLSocket::ToServer (-1)
  #**
  #***************************************************************
 	proc ToServer {cmd} {	  
	  variable ::sockSrv		
		puts $::sockSrv $cmd
		return {}
	}

  #***************************************************************
  #** CloseClient
  #**
  #** Abstract: Close the connection between the client and the server.
	#**           Client close his wish by 'exit'.
	#**          
  #** Inputs:  client's name
	#            command to executing
  #**
  #** Outputs: 
  #**
	#** Usage:  RLSocket::CloseClient FbA 	
  #**
  #***************************************************************
	proc CloseClient {cl} {
	  variable gaSC
	  puts [set gaSC(cl$cl)] [list $cl _close] 
 	  _delay 1000
	}

  #***************************************************************
  #** Wait
  #**
  #** Abstract: Wait to one of two things:
	#**              or the client will return any value, and the procedure
	#**                 return this value
	#**              or after timeOut the procedure return value NA 
  #**
  #** Inputs: timeOut in seconds'
	#**         client's name
  #**
  #** Outputs: or value from client
  #**          or NA
  #**
  #** Usage:  RLSocket::Wait 40 FbA
  #**
  #***************************************************************
  proc Wait {timeOut cl} {
    variable gaSet  
    for {set count 1} {$count<=$timeOut} {incr count} {
			if {$gaSet(res$cl) != "NA"} {
			  break
	    }	
 		  _delay 1000			
    }
    return $gaSet(res$cl)
  }

   
  proc _Server {port unit} {
    variable gaSC
    set gaSC(main) [socket -server "RLSocket::_FromClientAccept $unit" $port]
  }
    
  proc _FromClientAccept {unit sock addr port} {
    #puts "ftClAcc unit:$unit  sock:$sock"
    variable gaSC		
    set gaSC(cl$unit) $sock
		set gaSC($sock) $unit
    set gaSC(addr,$sock) [list $addr $port]
    fconfigure $sock -buffering line
    fileevent $sock readable [list RLSocket::_FromClient $sock]
  }
  
  proc _FromClient {soc} {
    global gMessage
    variable gaSC
		variable gaSet
    if {[eof $soc] || [catch {gets $soc line}]} {
      close $soc
		set cl $gaSC($soc)
  	  unset gaSC(addr,$soc)
  	  unset gaSC(cl$cl)
	  unset gaSC($soc)
  	  #exit
    } else {
		  #set line [lrange $line 0 end]
		  set cl $gaSC($soc)
			
  		if {[string index $line 0]=="(" && \
			    [string index $line [expr [string length $line] - 1]]==")"} {
				set gaSet(res$cl) $line
			} else {
			  if [catch {eval $line} ret] {			
			    set gMessage $ret
			    RLEH::Handle Syntax gMessage
			  }			  
			}
    }
  }
  
  
	proc _delay {msec} {
	  set x 0
		after $msec {set x 1}
		vwait x
	}

}; # end of namespace

  
  
  
  
  
  
  
  
  
  
  
  
  

