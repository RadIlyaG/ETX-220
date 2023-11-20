set pair [lindex $argv 0]
set gaSet(pair) $pair

switch -exact -- $gaSet(pair) {
  1 {
      set gaSet(comDut)    2
      set gaSet(comGEN)    4
      console eval {wm geometry . +1+1}
      console eval {wm title . "Con 1"}   
      set gaSet(pioPwr1)     4
      set gaSet(pioPwr2)     3
        }
  2 {
      set gaSet(comDut)    5
      set gaSet(comGEN)    6
      console eval {wm geometry . +1+1}
      console eval {wm title . "Con 2"}          
      set gaSet(pioPwr1)     2
      set gaSet(pioPwr2)     1      
  }
}  
source lib_PackSour.tcl
