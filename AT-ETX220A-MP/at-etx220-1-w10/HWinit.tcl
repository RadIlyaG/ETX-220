set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_191\\bin\\
switch -exact -- $gaSet(pair) {
  1 {
      set gaSet(comDut)    2
      set gaSet(comGEN)    6
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"}   
      set gaSet(pioPwr1)     4
      set gaSet(pioPwr2)     3
        }
  2 {
      set gaSet(comDut)    7
      set gaSet(comGEN)    8
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"}          
      set gaSet(pioPwr1)     2
      set gaSet(pioPwr2)     1      
  }
  3 {
      set gaSet(comDut)    10
      set gaSet(comGEN)    9
      console eval {wm geometry . +150+400}
      console eval {wm title . "Con 3"}   
      set gaSet(pioPwr1)     8
      set gaSet(pioPwr2)     7
        }
  4 {
      set gaSet(comDut)    12
      set gaSet(comGEN)    1
      console eval {wm geometry . +150+600}
      console eval {wm title . "Con 4"}          
      set gaSet(pioPwr1)     6
      set gaSet(pioPwr2)     5      
  }
}  
source lib_PackSour.tcl
