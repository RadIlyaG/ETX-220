set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_191\\bin\\
switch -exact -- $gaSet(pair) {
  1 {
      set gaSet(comDut)    5 ; #6
      set gaSet(comGEN)    2 ; #4
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"}   
      set gaSet(pioPwr1)     1; #4
      set gaSet(pioPwr2)     2; #3
      set gaSet(pioBoxSerNum) FT2C88NL
  }
  2 {
      set gaSet(comDut)    6 ; #2
      set gaSet(comGEN)    4 ; #5
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"}          
      set gaSet(pioPwr1)     1 ; #2
      set gaSet(pioPwr2)     2 ; #1  
      set gaSet(pioBoxSerNum) FT2C82X0 ; #FTDAR8L   
  }
  3 {
      set gaSet(comDut)    9 ; #9
      set gaSet(comGEN)    8 ; #8
      console eval {wm geometry . +150+400}
      console eval {wm title . "Con 3"}   
      set gaSet(pioPwr1)     1 ; #8
      set gaSet(pioPwr2)     2 ; #7
      set gaSet(pioBoxSerNum) FT2C8JBL ; #FTDOZ8X
  }
  4 {
      set gaSet(comDut)    7 ; #7
      set gaSet(comGEN)    1 ; #1
      console eval {wm geometry . +150+600}
      console eval {wm title . "Con 4"}          
      set gaSet(pioPwr1)     1 ; #6
      set gaSet(pioPwr2)     2 ; #5  
      set gaSet(pioBoxSerNum) FTZ5BWT2 ; #FTDOBK6    
  }
}  
source lib_PackSour.tcl
