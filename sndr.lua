-- for use with Sounder
-- by Smelly


-- check for required modules
assert(love.math and love.audio and love.sound,"SNDR ERROR: The sndr library requires the following modules;\nlove.math, love.audio, and love.sound.\nPlease make sure those are supplied! .   o . ")


-- base sndr table
local sndr={
 channel={},
 channelAmount=4,
 buffer={},
 
 seeder="?",
 synth={
  sampler={0},
  soundExport={}
 }
}
for i=1,sndr.channelAmount do
 sndr.synth.soundExport[i]=0
end


-- vars that are useful for stuff
local chunkRate=30
local samplerate=44100
local sampleChunkSize=samplerate/chunkRate

-- update loop for lib
local function update()
 
 for i=1,sndr.channelAmount do
  if sndr.channel[i] then
   sndr.channel[i].age=sndr.channel[i].age+1
  end
 end
 
 sndr.soundMain()
 
 sndr.bufferMain()
 
 sndr.bufferUpdate()
end


















--[[
===== =====       ===== =====
----- ----- Synth ----- -----
===== =====       ===== =====
]]



-- encoded note value reader
local onechartable={
 "0",
 "1","2","3","4","5","6","7","8","9","a",
 "b","c","d","e","f","g","h","i","j","k",
 "l","m","n","o","p","q","r","s","t","u",
 "v","w","x","y","z","A","B","C","D","E",
 "F","G","H","I","J","K","L","M","N","O",
 "P","Q","R","S","T","U","V","W","X","Y"
}

local function readOneChar(c)

 for i=1,#onechartable do
  if c==onechartable[i] then return i-1 end
 end
end







-- synth main
local function SounderSynth(c,s,i,sConst)
 
 -- get data about song
 local data=s.data
 local datasize=#data/2-1
 local speed=s.noteSpeed
 if s.id then speed=sndr.channel[1].noteSpeed end
 
 
 
 
 -- entire system that deals with if the song ends or what should happen.
 if i>datasize*samplerate/speed then
  
  -- stop and reset
  if not s.flags.loop then
   
   if s.state and not s.flags.quit then s.state=false end
   if not s.id then
    s.source.bufferAdvance=0
   else
    
    for i=1,sndr.channelAmount do
     if sndr.channel[i] and sndr.channel[i].id then
      sndr.channel[i].source.bufferAdvance=0
     end
    end
    
   end
  -- loop
  else
   
   if s.id then s=sndr.channel[1] end
   
   local n = (s.chunksize*s.loopPoint) * (s.noteSpeed/samplerate)
   
   if not s.id then
    s.source.bufferAdvance=n
   else
    
    for i=1,sndr.channelAmount do
     if sndr.channel[i] and sndr.channel[i].id then
      sndr.channel[i].source.bufferAdvance=n
     end
    end
    
   end
   
  end
  
  -- quit
  if s.flags.quit then sndr.dump(c) end
  return false
 end
 
 
 
 
 
 
 local index=math.ceil( (i/((samplerate/speed)/60))/60 )
 
 local noteVolume= tonumber( string.sub( s.data,2 + index*2-1, 2 + index*2-1 ) )
 
 local notePitch= readOneChar( string.sub( s.data,2 + index*2, 2 + index*2 ) )
 
 
 
 
 
 sndr.seeder=c
 if s.id then sndr.seeder=1 end
 
 if sConst[2]==7 then notePitch={sndr.channel[c].noteSpeed,sConst[3],notePitch} end

 local n=0
 if notePitch~=0 or noteVolume~=0 then
  n = sndr.synth.getInstrument(notePitch,i,sConst[2],s.scale)
 end
 
 
 n = sndr.synth.getMasterVolume(n,i,sConst[1],noteVolume,index,s.data,speed)
 
 sndr.synth.soundExport[c]=n
 return n --math.sin( (6.2831853071 * (i/2) * 40 )/(samplerate/4) )
end



-- pitch info
sndr.synth.pitchTable={ 
 {
  016.35,017.32,018.35,019.45,020.60,021.83,023.12,024.50,025.96,027.50,029.14,030.87,
  032.70,034.65,036.71,038.89,041.20,043.65,046.25,049.00,051.91,055.00,058.27,061.73,
  065.40,069.29,073.41,077.78,082.40,087.30,092.49,097.99,103.82,110.00,116.54,123.47,
  130.81,138.59,146.83,155.56,164.81,174.61,184.99,195.99,207.65,220.00,233.08,246.94,
  261.62,277.18,293.66,311.12,329.62,349.22,369.99,391.99,415.30,440.00,466.16,493.88 
 },
 
 {
 021.21,022.74,024.37,026.12,027.99,030.00,032.15,034.46,036.93,039.58,
 042.42,045.47,048.73,052.23,055.98,060.00,064.30,068.92,073.87,079.17,
 084.85,090.94,097.47,104.46,111.96,120.00,128.60,137.84,147.73,158.35,
 169.70,181.88,194.93,208.92,223.92,239.99,257.22,275.68,295.46,316.67,
 339.40,363.76,389.87,417.85,447.84,479.98,514.43,551.36,590.93,633.34 
 }
}

sndr.synth.pitchNameTable={
 {
  "12 tet","none",
  "c 0","c#0","d 0","d#0","e 0","f 0","f#0","g 0","g#0","a 0","a#0","b 0",
  "c 1","c#1","d 1","d#1","e 1","f 1","f#1","g 1","g#1","a 1","a#1","b 1",
  "c 2","c#2","d 2","d#2","e 2","f 2","f#2","g 2","g#2","a 2","a#2","b 2",
  "c 3","c#3","d 3","d#3","e 3","f 3","f#3","g 3","g#3","a 3","a#3","b 3",
  "c 4","c#4","d 4","d#4","e 4","f 4","f#4","g 4","g#4","a 4","a#4","b 4"
 },
 
 {
 "10 tet","none",
 "a 0","a#0","b 0","b#0","c 0","c#0","d 0","d#0","e 0","e#0",
 "a 1","a#1","b 1","b#1","c 1","c#1","d 1","d#1","e 1","e#1",
 "a 2","a#2","b 2","b#2","c 2","c#2","d 2","d#2","e 2","e#2",
 "a 3","a#3","b 3","b#3","c 3","c#3","d 3","d#3","e 3","e#3",
 "a 4","a#4","b 4","b#4","c 4","c#4","d 4","d#4","e 4","e#4" 
 }
}




-- seed for the music
local function initmusicseed(c)
 sndr.channel[c].sfxseed = love.math.newRandomGenerator()
 sndr.channel[c].sfxseed:setSeed(1)
end



-- the base noise making
local function noisegen(min,max)
 local n = sndr.channel[sndr.seeder].sfxseed:random(min,max)
 return n
end



-- helps get the sound!
local function getInstrument(pitch,i,inst,scale)
 if type(pitch)=="table" then
  return sndr.synth.instrumentsTable[ inst+1](pitch,i-1,pitch[3] )
 end
 return sndr.synth.instrumentsTable[ inst+1](sndr.synth.pitchTable[scale][pitch],i-1,pitch )
end



-- empty instrument
local function none(pitch,i)
 return 0
end


-- square
local function square(pitch,i)
 return math.floor( math.sin( (6.2831853071 * (i) * pitch )/(samplerate/4) ))/16
end


-- accordion
local function accordion(pitch,i)
 local n = math.sin( (6.2831853071 * (i) * pitch )/(samplerate/4) )
 return math.floor( ((n+.5)^2) )/16
end


-- whistle
local function whistle(pitch,i)
 local n = i%2
 n=n/((n+64)/80)-n
 n=n + math.floor(math.sin( (6.2831853071 * (i-1) * pitch )/(samplerate/4)*8 )*8)/16
 return n/16
end


-- dinge
local function dinge(pitch,i)
 local n=math.floor( math.sin( (6.2831853071 * (i) * pitch )/(samplerate/4) )+.5 )/16
 return n-noisegen(0,1)/256
end


-- noise
local function noise(pitch,i,p)
 return -(noisegen(0,p)/(p*4))/4
end


-- bubble
local function bubble(pitch,i)
 local n=math.floor( (math.sin( (6.2831853071 * (i) * pitch )/(samplerate/4) )+.5 )*4)/16
 if math.sin( (6.2831853071 *(i/20)* pitch )/(samplerate/4)) < 0 then n=0 end
 return n/2
end


-- sampler (use sndr.setSampler to use.)
local function sampler(channelfInfo,i,p)
 i=i%((samplerate/channelfInfo[1])*channelfInfo[2])
 local n=math.floor(i/(p/4+1))+1
 
 if i>#sndr.synth.sampler-1 then
  n=n%#sndr.synth.sampler+1
 end

 
 return sndr.synth.sampler[n]/16
end



-- table which stores them
sndr.synth.instrumentsTable={
 none,
 square,
 accordion,
 whistle,
 dinge,
 noise,
 bubble,
 sampler
}





local function fadeGet(n,i,index,mode,data,speed)
 
 local defaultFadeAmount=600
 
 local fadeamount = defaultFadeAmount
 
 -- if mode==1 then it should only fadein/fadeout if no upcoming note.
 local pastnote=false
 local nextnote=false
 
 if mode~=0 then
  
  -- checks for if mode
  if string.sub( data,2 + (index-1)*2-1, 2 + (index-1)*2-1 )~="0" then
   pastnote=true
  end
  
  if string.sub( data,2 + (index+1)*2-1, 2 + (index+1)*2-1 )~="0" then
   nextnote=true
  end
 end
 
 if mode==2 then fadeamount=defaultFadeAmount*10 end
 
 
 
 
 
 -- make i not the whole size of song and instead the size of note
 local i=(i%(samplerate/speed) )+1
 
 -- fadein
 local f=fadeamount
 if mode==2 then f=100 end
 if mode==3 then f=20 end
 if i<=f and ((mode==0 and pastnote) or mode==2) then
  n=n/(f/i)
 end
 
 -- fadeout
 if mode==3 then
  local f=800
  local r=4
  if i>=f then
   n=n/(i*(r/(f-i)))
  end
  n=n*1.2
 end
 
 
 -- fadeout
 if i>(samplerate/speed)-fadeamount and ((mode==0 and not nextnote) or mode==2) then
  n=n/(fadeamount/ ((samplerate/speed)-i) )
 end
 
 return n
end






local function getMasterVolume(n,i,mode,vol,index,data,speed)
 
 -- get fades which are tied to the modes
 n = fadeGet(n,i,index,mode,data,speed)
 
 
 local volumeTable={
  0.06,
  0.25,
  0.5,
  0.8,
  1
 }
 
 n=n *volumeTable[vol+1]
 
 return n*2
end














--[[
===== =====        ===== =====
----- ----- Buffer ----- -----
===== =====        ===== =====
]]



-- adds the buffer table to a channel.
local function bufferAdd(channel)
 local i=#sndr.buffer+1
 if #sndr.buffer>=sndr.channelAmount then
  i=4
 end
 
 sndr.buffer[i]=channel
 
end



-- The main update for checking the buffers.
local function bufferMain()
 
 -- if buffer isn't empty
 if #sndr.buffer~=0 then
  
  -- find empty channels
  for i=1,sndr.channelAmount do
   
   if not sndr.channel[i] then
    
    sndr.channel[i] = sndr.buffer[1]
    --cycle buffer channels
    sndr.buffer[1]=nil
    for i=2,#sndr.buffer do
     sndr.buffer[i-1]=sndr.buffer[i]
     sndr.buffer[i]=nil
    end
    
   end
   
   
   
  end
  
  
 end
 
end



-- plays buffers while in the background, basicly runs them while having them mute.
local function bufferUpdate()
 
 for j=1,sndr.channelAmount do
  if sndr.buffer[j] and sndr.buffer[j].state then
   
   local src=sndr.buffer[j]
   for i=0,math.floor(sampleChunkSize/2)-1 do
    
    src.source.bufferAdvance=src.source.bufferAdvance+1
    
    -- what to do with once it's done 
    local size = #src.data/2-1
    if src.source.bufferAdvance>size*samplerate/src.noteSpeed then
     
     if not src.flags.loop then 
      if src.state and not src.flags.quit then src.state=false end
      if not src.id then
       if not src.flags.quit then
        src.source.bufferAdvance=0 return
       end
      else
       
       for i=1,sndr.channelAmount do
        if sndr.buffer[i] and sndr.buffer[i].id then
         sndr.buffer[i].source.bufferAdvance=0
        end
       end
       
      end
     else
      
      src.source.bufferAdvance=0
      
     end
     
     if src.flags.quit then sndr.buffer[j]=nil end
    end
    
   end
   
  
  end
 end
end



-- adds the source table to a channel
local function addSource()
 local t={
  
  queSource = love.audio.newQueueableSource(samplerate, 8, 1, 2),
  sourceBuffer = love.sound.newSoundData(math.floor(sampleChunkSize), samplerate, 8, 1),
  bufferAdvance = 0
 }

 return t
end

























--[[
===== =====     ===== =====
----- ----- API ----- -----
===== =====     ===== =====
]]



-- returns table of empty and not empty channels
local function list(i,table)

 if table=="buffer" then
  table=sndr.buffer
 else
  table=sndr.channel
 end

 local t={}
 
 local a=i or 1
 local b=i or sndr.channelAmount
 
 for i=a,b do
  if table[i] then
   t[i]=true
  else
   t[i]=false
  end
 end
 return t
end


-- gets info
local function info(index,table)
 
 if table=="buffer" then
  table=sndr.buffer
 else
  table=sndr.channel
 end
 
 local c=table[index]
 if not c then return nil end
 --if not c then error("SNDR ERROR: Tried to retrieve info from a invaild channel! ("..index..").") end
 return {
 name=c.name,
 data=c.data,
 id=c.id,
 state=c.state,
 
 speed=c.noteSpeed,
 
 
 prog=c.source.bufferAdvance,
 vol=c.vol,
 
 loop=c.loopPoint,
 start=c.startPoint,
 
 flags=c.flags,
 
 output=sndr.synth.soundExport[index],
 
 age=c.age
 
 }
end



-- loads sndr info (can load songs or sfx with flags and find the spots to put them.)
local function load(songdata,indexType,specialflags)
 if not specialflags then specialflags={} end
 if not indexType then indexType=#sndr.channel+1 if indexType>sndr.channelAmount then indexType=1 end end
 
 -- song sfxs ------
 if indexType=="song" then
  -- wipe old song
  for i=1,sndr.channelAmount do
   if sndr.channel[i] and sndr.channel[i].id then sndr.channel[i]=nil end
   if sndr.buffer[i]  and sndr.buffer[i].id  then sndr.buffer[i]=nil end
  end
  
  
  
  -- get number of channels in song
  local p=tonumber( string.sub(songdata,1,2) )
  if not p or p==0 then error("SNDR ERROR: Loaded sfx's name is invaild. please make sure it's proper! :o\nsoundData:\n"..songdata) end
  local l=tonumber( string.sub(songdata,p+19,p+19) )
  
  local c=tonumber(string.sub(songdata,p+6,p+8) ) * tonumber( string.sub(songdata,p+9,p+11)  )*2 +3
  for i=1,l do
   
   local t={}
   t.name=string.sub(songdata,3,2+p)
   t.data= string.sub(songdata,p + 21 + c*(i-1),p + 21 + c*(i)-2 )
   t.id=true
   t.source=addSource()
   
   t.chunksize = tonumber( string.sub(songdata,p+6,p+8) )
   
   t.scale = tonumber( string.sub(songdata,p+18,p+18) )
   
   t.noteSpeed=tonumber( string.sub(songdata,p+4,p+5) )
   
   t.age=0
   
   if sndr.channel[i] then sndr.bufferAdd(sndr.channel[i]) end
   
   t.flags=specialflags
   sndr.channel[i]=t
  end
  -- important info thats stored in the first channel about the song
  sndr.channel[1].state=false
  if specialflags.play then sndr.channel[1].state=true if not sndr.synth.sfxseed then initmusicseed(1) end end
  sndr.channel[1].vol=1
  
  
  local pos = tonumber( string.sub(songdata,1,2) ) + 12
  sndr.channel[1].startPoint= tonumber( string.sub(songdata,pos,pos+2) )
  pos=pos+3
  sndr.channel[1].loopPoint= tonumber( string.sub(songdata,pos,pos+2) )
  
  
  
  --sndr.channel[1].noteSpeed=tonumber( string.sub(songdata,p+4,p+5) )
  
  sndr.channel[1].flags.lock=true
  
 -- single sfx ------
 else
  
  -- find the oldest channel, works good enough.
  local y=false
  if not indexType then
   indexType=1
  end
  
  for i=1,sndr.channelAmount do
   
   if not sndr.channel[i] then
    y=true
    indexType=i
    break
   end
   
  end
  
  if not y then
   local n={}
   for i=1,sndr.channelAmount do
    
    local b=0
    if sndr.channel[i] then b=sndr.channel[i].age end
    n[i]=b
   end
   for i=2,sndr.channelAmount do
    for j=2,sndr.channelAmount do
     if n[i]<n[j] then
      indexType=j
      break
      
     end
     
    end
   end
  end
  
  
  local t={}
  local n=tonumber( string.sub(songdata,1,2) )
  if not n or n==0 then error("SNDR ERROR: Loaded sfx's name is invaild, please make sure it's proper! :o\nsoundData:\n"..songdata) end
  t.name=string.sub(songdata,3,2+n )
  
  local p=tonumber( string.sub(songdata,1,2) )
  local c=tonumber(string.sub(songdata,p+6,p+8) ) * tonumber( string.sub(songdata,p+9,p+11)  )*2 +3
  t.data=string.sub(songdata,p+21,p+19+c )
  t.id=false
  t.state=false
  t.vol=1
  t.source=addSource()
  t.noteSpeed=tonumber( string.sub(songdata,p+4,p+5) )
  
  t.age=0
  
  local pos = tonumber( string.sub(songdata,1,2) ) + 12
  t.startPoint= tonumber( string.sub(songdata,pos,pos+2) )
  pos=pos+3
  t.loopPoint= tonumber( string.sub(songdata,pos,pos+2) )
  
  t.chunksize = tonumber( string.sub(songdata,p+6,p+8) )
  
  t.scale = tonumber( string.sub(songdata,p+18,p+18) )
  
  t.flags=specialflags
  
  if sndr.channel[indexType] then sndr.bufferAdd(sndr.channel[indexType]) end
  sndr.channel[indexType]=t
  if specialflags.play then
   sndr.channel[indexType].state=true
   if not sndr.synth.sfxseed then initmusicseed(indexType) end
   
   sndr.channel[indexType].source.bufferAdvance=(t.startPoint*t.chunksize) * (samplerate/t.noteSpeed)
  end
 end
 
 
end



-- Trashes a sound once it's done.
local function dump(index)
 if not sndr.channel[index] then
  error("SNDR ERROR: Tried to dump a channel that was empty!\nPlease make sure you don't go dumping your sfx everywhere you go!")
 end
 
 if sndr.channel[index].id then
  for i=1,sndr.channelAmount do
   
   if sndr.channel[i] and sndr.channel[i].id then
    sndr.channel[i]=nil
   end
   
   if sndr.buffer[i] and sndr.buffer[i].id then
    sndr.buffer[i]=nil
   end
   
  end
 else
  sndr.channel[index]=nil
 end
end



-- plays the channel
local function play(index)

 local sfx=sndr.channel[index]
 if not sfx then error("SNDR ERROR: Tried to play a channel that doesn't exist! ("..index..").") end
 if sfx.id then
  for i=1,sndr.channelAmount do
   if sndr.channel[i] and sndr.channel[i].id then
    sndr.channel[i].state=true
   end
  end
  
 else
  sndr.channel[index].state=true
 end

end



-- pauses the channel
local function pause(index)
 local sfx=sndr.channel[index]
 if not sfx then error("SNDR ERROR: Tried to pause a channel that doesn't exist! ("..index..").") end
 if sfx.id then
  
  for i=1,sndr.channelAmount do
   if sndr.channel[i] and sndr.channel[i].id then
    sndr.channel[i].state=false
   end
  end
  
 else
  
  sndr.channel[index].state=false
  
 end
 
 
end



-- set global volume from 0..1 in 4ths
local function vol(index)
 local t={0.00,0.25,0.50,0.75,1}
 
 local src="?"
 for i=1,sndr.channelAmount do
  if sndr.channel[i] then
   src=sndr.channel[i].source.queSource
   src:setVolume(t[index+1])
  end
 end
 
end



-- gets global volume
local function getVol()
 for i=1,sndr.channelAmount do
  if sndr.channel[i] then
   return sndr.channel[i].source.queSource:getVolume()
  end
 end
end



-- sets progress in the song or sfx
local function prog(channel,unit,index)
 
 if not sndr.channel[channel] then error("SNDR ERROR: Invalid prog call! (index "..channel.." seems to be empty!).") end
 
 if index<0 then error("SNDR ERROR: Invalid prog call! value given is negative! ("..unit.." "..index..").") end
 
 local scr=sndr.channel[channel].source
 
 local value=0
 
 if unit=="note" then
  
  local speed=sndr.channel[channel].noteSpeed
  if sndr.channel[channel].id then speed=sndr.channel[1].noteSpeed end
  local speed=samplerate/speed
  
  value=index*speed
 
 elseif unit=="sample" then
  value=index
 else
  error([[SNDR ERROR: Invalid prog call! (Please provide either "note" or "sample"). :p]])
 end
 
 
 if sndr.channel[channel].id then
  for i=1,sndr.channelAmount do
   
   if sndr.channel[i] and sndr.channel[i].id then
    sndr.channel[i].source.bufferAdvance=value
   end
   
  end
 
 else
  
  scr.bufferAdvance=value
  
 end 
end



-- gets the progress
local function getProg(index)
 if not index then index=1 end
 
 if not sndr.channel[index] then
  return 0 --error("SNDR ERROR: Invalid getProg call! (index "..index.." is nil!).")
 else
  return sndr.channel[index].source.bufferAdvance
 end
 
end



-- set the sampler here, used for the synth.
local function setSampler(table)
 sndr.synth.sampler=table
end



















--[[
===== =====               ===== =====
----- ----- Sound Playing ----- -----
===== =====               ===== =====
]]




local function soundMain()

 for i=1,sndr.channelAmount do
  if sndr.channel[i] then
   
   local c=sndr.channel[i]
   local src=c.source
   
   
   if c and c.state or (c.id and sndr.channel[1].state) then
    
    
    local n=""
    while src.queSource:getFreeBufferCount()>0 do
     
     local sConst={}
     sConst[1]= tonumber( string.sub( sndr.channel[i].data, 1,1 ) )
     sConst[2]= tonumber( string.sub( sndr.channel[i].data, 2,2 ) )
     sConst[3]=sndr.channel[i].chunksize
     
     if c.id then src.bufferAdvance=sndr.channel[1].source.bufferAdvance end
     
     for j=0,math.floor(sampleChunkSize)-1 do
      src.bufferAdvance=src.bufferAdvance+1
      -- get value, if it's the end of the sfx then break out.
      n=SounderSynth(i,c,src.bufferAdvance,sConst)
      if not n then break end
      src.sourceBuffer:setSample(j, n )
     end
     
     
     if not n then break end
     
     src.queSource:queue(src.sourceBuffer)
    end
    
    if not src.queSource:isPlaying() then
     src.queSource:play()
    end
    
    
   elseif src.queSource:isPlaying() then
    
    src.queSource:stop()
    
   end
  end
  
 end
 
end

















--[[
===== =====         ===== =====
----- ----- Packing ----- -----
===== =====         ===== =====
]]




sndr.update=update

sndr.list=list
sndr.info=info

sndr.load=load
sndr.dump=dump

sndr.play=play
sndr.pause=pause

sndr.vol=vol
sndr.getVol=getVol
sndr.prog=prog
sndr.getProg=getProg

sndr.setSampler=setSampler

sndr.bufferAdd=bufferAdd
sndr.bufferMain=bufferMain
sndr.bufferUpdate=bufferUpdate

sndr.synth.getInstrument=getInstrument
sndr.synth.getMasterVolume=getMasterVolume

sndr.soundMain=soundMain

return sndr