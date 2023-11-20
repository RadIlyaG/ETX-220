# ***************************************************************************
# ConfigEtxGen
# ***************************************************************************
proc ConfigEtxGen {} {
  global gaSet
  set id $gaSet(id204)
  Status "EtxGen::PortsConfig"
  RLEtxGen::PortsConfig $id -updGen all -autoneg enbl -maxAdvertize 1000-f \
      -admStatus up ; #-save yes 
  Status "EtxGen::PacketConfig"
  RLEtxGen::PacketConfig $id MAC -updGen all 
  Status "EtxGen::GenConfig"
  RLEtxGen::GenConfig $id -updGen all -factory yes -genMode GE -minLen 64 -maxLen 64 \
      -chain 1 -packRate 1200000 -packType MAC     
}
# ***************************************************************************
# InitEtxGen
# ***************************************************************************
proc InitEtxGen {} {
  global gaSet
  Status "Opening EtxGen..."
  set gaSet(id204) [RLEtxGen::Open $gaSet(comGEN) -package RLSerial]
  ConfigEtxGen
  Status Done
  catch {RLEtxGen::CloseAll}
}

# ***************************************************************************
# Etx204Start
# ***************************************************************************
proc Etx204Start {} {
  global gaSet buffer
  set id $gaSet(id204)
  puts "Etx204Start .. [MyTime]" ; update
  RLEtxGen::Start $id 
  after 500
  RLEtxGen::Clear $id
  after 500
  RLEtxGen::Start $id 
  after 500
  RLEtxGen::Clear $id
  return 0
}  

# ***************************************************************************
# Etx204Check
# ***************************************************************************
proc Etx204Check {} {
  global gaSet aRes
  puts "Etx204Check .. [MyTime]" ; update
  set id $gaSet(id204)
  set ret 0
#   RLEtxGen::Stop $id
#   after 1000
  RLEtxGen::GetStatistics $id aRes 
  set res1 0
  set res2 0
  
  foreach gen {1 2} {
    mparray aRes *Gen$gen
    foreach stat {ERR_CNT FRAME_ERR FRAME_NOT_RECOGN PRBS_ERR SEQ_ERR} {
      set res $aRes(id$id,[set stat],Gen$gen)
      if {$res!=0} {
        set gaSet(fail) "The $stat in Generator-$gen is $res. Should be 0"
        set res$gen -1
        # return -1
      }
    }
    foreach stat {PRBS_OK RCV_BPS RCV_PPS} {
      set res $aRes(id$id,[set stat],Gen$gen)
      if {$res==0} {
        set gaSet(fail) "The $stat in Generator-$gen is 0. Should be more"
        set res$gen -1
        # return -1
      }
    }
  }
  if {$res1!=0 || $res2!=0} {
    set ret -1
  } else {
    set ret 0
  }
  return $ret
}

# ***************************************************************************
# Etx204Stop
# ***************************************************************************
proc Etx204Stop {} {
  global gaSet
  puts "Etx204Stop .. [MyTime]" ; update
  set id $gaSet(id204)
  RLEtxGen::Stop $id
  return 0
}
