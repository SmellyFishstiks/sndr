-- for use with Sounder
-- by Smelly
-- version 1.2


-- check for required modules
assert(love.math and love.audio and love.sound,"SNDR ERROR: The sndr library requires the following modules;\nlove.math, love.audio, and love.sound.\nPlease make sure those are supplied! .   o . ")

-- vars that are useful for stuff
local queCap=3
local chunkRate=30
local samplerate=44100
local sampleChunkSize=samplerate/chunkRate

-- base sndr table
local sndr={
 channel={},
 channelAmount=4,
 buffer={},
 
 seeder="?",
 synth={
  sfxseed=false,
  sampler={},
  soundExport={},
  queSource=love.audio.newQueueableSource(samplerate, 8, 1, queCap),
  soundSource=love.sound.newSoundData(math.floor(samplerate/chunkRate), samplerate, 8, 1),
  globalVolume={[0]=0,0}
 }
}

for i=1,sndr.channelAmount do
 sndr.synth.soundExport[i]={}
end




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
 --local datasize=#data/2-1
 local speed=s.noteSpeed
 if s.id then speed=sndr.channel[1].noteSpeed end
 
 
 
 
 local datasize=(#s.data)/2-1
 
 
 
 if i>datasize*samplerate/speed then
  -- stop and reset
  if not s.flags.loop then
   
   if s.state and not s.flags.quit then s.state=false end
   if not s.id then
    s.source.bufferAdvance=0
   else
    
    for i=1,sndr.channelAmount do
     sndr.channel[1].state=false
     if sndr.channel[i] and sndr.channel[i].id then
      sndr.channel[i].source.bufferAdvance=0
     end
    end
    
   end
  -- loop
  else
   
   if s.id then s=sndr.channel[1] end
   
   local n = (s.chunksize*s.loopPoint) * (samplerate/s.noteSpeed)
   
   
   if not s.id then
    s.source.bufferAdvance=n
    if string.sub(s.data,2,2)=="7" then s.source.bufferAdvance=n-n%sampleChunkSize end
   else
    
    for i=1,sndr.channelAmount do
     if sndr.channel[i] and sndr.channel[i].id then
      sndr.channel[i].source.bufferAdvance=n
      if string.sub(sndr.channel[i].data,2,2)=="7" then sndr.channel[i].source.bufferAdvance=n-n%sampleChunkSize end
     end
    end
    
    
   end
   
  end
  
  
  if s.flags.event then s.flags.event() end
  
  -- quit
  if s.flags.quit then sndr.dump(c) end
  return false
 end
 
 
 
 
 -- get index and the right notes...
 
 
 
 local index=math.ceil( (i/((samplerate/speed)/60))/60 )
 
 
 
 local sv,sp=tonumber(string.sub(s.data, (index)*2+1, (index)*2+1)),
             readOneChar(string.sub(s.data, (index)*2+2, (index)*2+2))
 
 if sv and sp then s.source.bufferMemory={sv,sp} end
 
 local noteVolume= sv or s.source.bufferMemory[1]
 local notePitch= sp or s.source.bufferMemory[2]
 
 
 
 assert( noteVolume and notePitch, "SNDR ERROR: pitch or Volume is broken durning playback, sorry! :<\n Pitch,Volume:"..tostring(notePitch)..", "..tostring(noteVolume))
 
 assert(tonumber(sConst[1]),"SNDR ERROR: durning playback mode was nil?")
 assert(tonumber(sConst[2]),"SNDR ERROR: durning playback instrument was nil?")
 
 sndr.seeder=c
 if s.id then sndr.seeder=1 end
 
 if sConst[2]==7 then notePitch={sndr.channel[c].noteSpeed,sConst[3],notePitch} end

 local n=0
 if notePitch~=0 or  noteVolume~=0 then
  n = sndr.synth.getInstrument(notePitch,i,sConst[2],s.scale,sndr.channel[c].pitchMOD,c)
 end
 
 
 n = sndr.synth.getMasterVolume(n,i,sConst[1],noteVolume,index,s.data,speed,s.flags.layer)
 
 return n,{sv,sp}
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
local function getInstrument(pitch,i,inst,scale,pitchMOD,c)
 assert(sndr.synth.pitchTable[scale],"SNDR ERROR: Hey! The pitch scale used seems to be all messed up! ;p")
 
 if type(pitch)=="table" then
  return sndr.synth.instrumentsTable[ inst+1](pitch,i-1,pitch[3],pitchMOD,c )
 end
 return sndr.synth.instrumentsTable[ inst+1](sndr.synth.pitchTable[scale][pitch],i-1,pitch,pitchMOD,c )
end


-- empty instrument
local function none()
 return 0
end


-- square
local function square(pitch,i,_,pitchMOD)
 return math.floor( math.sin( (6.2831853071 * (i) * pitch )/(samplerate/pitchMOD) ))/3.5
end


-- accordion
local function accordion(pitch,i,_,pitchMOD)
 return math.floor( ((  math.sin( (6.2831853071 * (i) * pitch )/(samplerate/pitchMOD) )  +.5)^2) )/7
end


-- whistle
local function whistle(pitch,i,_,pitchMOD)
 local n = i%2
 n=n/((n+64)/80)-n
 n=n + math.floor(math.sin( (6.2831853071 * (i-1) * pitch )/(samplerate/pitchMOD)*8 )*8)/16
 return (n/3)/3.5
end

--error("work on the rest of the intruements later and the output for some reason sounds better when /2? IDK\nAnd then there's the whole ripout the sources thing and other stuff but that can wait a tiny bit if needed.")

-- dinge
local function dinge(pitch,i,_,pitchMOD)
 local n=math.floor( math.sin( (6.2831853071 * (i) * pitch )/(samplerate/pitchMOD) )+.5 )/4
 return n-noisegen(0,1)/256
end


-- noise
local function noise(pitch,i,p,pitchMOD)
 return -(noisegen(0,p)/(p*4))/1.8
end


-- bubble
local function bubble(pitch,i,_,pitchMOD)
 local n=math.floor( (math.sin( (6.2831853071 * (i) * pitch )/(samplerate/pitchMOD) )+.5 )*4)/8
 if math.sin( (6.2831853071 *(i/20)* pitch )/(samplerate/pitchMOD)) < 0 then n=0 end
 return n/2
end


-- sampler (use sndr.setSampler to use.)
local function sampler(channelfInfo,i,p,_,c)
 local sound=sndr.synth.sampler[p] or {{1,1,"no sound",0,1},{128}}
 
 local n= ( sndr.synth.sampleTime[c][i%math.floor(sampleChunkSize)+1] or 127)+1
 
 local compress=sound[1][2]
 n=math.floor(n/compress+1)
 
 if n>#sound[2] then
  n=n%#sound[2]+1
 end
 
 local s=(sound[2][n]-128)/256
 return s/(math.max(math.abs(sound[1][5]),1) or 1)
 
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



sndr.synth.sampleTime={}
local function getSamplerTimings(c,time)
 
 sndr.synth.sampleTime[c]={}
 local y=math.ceil((time+1)/(samplerate/sndr.channel[c].noteSpeed))
 
 local p=readOneChar(string.sub(sndr.channel[c].data,y*2+2,y*2+2))
 local sound=sndr.synth.sampler[p] or {{1,1,"no sound",1,1},{128}}
 for k=1,math.floor(sampleChunkSize) do
  local i=time+k
  
  if sound[1][4]==0 then
   i=i%((samplerate/sndr.channel[c].noteSpeed)*sndr.channel[c].chunksize)
   
  elseif sound[1][4]==1 then
   i=i%(samplerate/sndr.channel[c].noteSpeed)
   
  elseif sound[1][4]==2 then
   
   local data=string.sub(sndr.channel[c].data,3,#sndr.channel[c].data-1)
   local d=math.floor(i/ (samplerate/sndr.channel[c].noteSpeed))+1
   
   for j=0,d do
    local l=d-j
    -- check if it's the end of said thingy
    if string.sub(data,l*2,l*2)~="" and string.sub(data,l*2,l*2)~=string.sub(data,d*2,d*2) then
     
     i=i-l*(samplerate/sndr.channel[c].noteSpeed)
     break
    end
   end
   
  elseif sound[1][4]==3 then
   
   i=i%(samplerate/sndr.channel[c].noteSpeed)
   --i=math.min(i,#sound[2])
   if i>#sound[2] then i=false end
  else
   error("SNDR ERROR: sampler ("..p..", "..sound[1][3].. ") looping mode is invaild!")
  end
  
  sndr.synth.sampleTime[c][k]=i
 end
 
end


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






local function getMasterVolume(n,i,mode,vol,index,data,speed,layer)
 
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
 
 
 
 -- apply layer volumes
 local vols={[0]=1,.75,.5,.25,.15,0}
 n=n*vols[sndr.synth.globalVolume[layer] or 0]
 
 return n*2
end














--[[
===== =====        ===== =====
----- ----- Buffer ----- -----
===== =====        ===== =====
]]



-- adds the buffer table to a channel.
local function bufferAdd(channel)
 
 -- count
 local c=0
 for i=1,sndr.channelAmount do
  if sndr.buffer[i] then c=c+1 end
 end
 
 -- find empty buffers
 local i="?"
 for j=1,sndr.channelAmount do
  if not sndr.buffer[j] then
   i=j
   break
  end
 end
 -- else find buffers that aren't songs,
 -- since channel 1 durning songs is always a song and buffer shares the same amount it should never fail to find a non song channel.
 if i=="?" then
  for j=1,sndr.channelAmount do
   if not sndr.buffer[j].id then
    i=j
    break
   end
  end
 end
 
 sndr.buffer[i]=channel
 --sndr.buffer[i].prog=0
 sndr.buffer[i].age=0
end



-- The main update for checking the buffers.
local function bufferMain()
 
 local c=0
 for i=1,sndr.channelAmount do
  if sndr.buffer[i] then c=c+1 end
 end
 
 -- if buffer isn't empty
 if c~=0 then
  
  -- find empty channels
  for i=1,sndr.channelAmount do
   
   if not sndr.channel[i] then
    if sndr.buffer[1] and sndr.buffer[1].id then
     sndr.buffer[1].source.bufferAdvance=sndr.channel[1].source.bufferAdvance
    end
    
    sndr.channel[i] = sndr.buffer[1]
    
    --cycle buffer channels
    for i=2,sndr.channelAmount do
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
    
    src.source.bufferAdvance=src.source.bufferAdvance+math.floor(sampleChunkSize)
    
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
 
 
 -- new code to sync music if it gets offset by being moved to the buffer.
 local s=sndr.channel[1]
 if not s or not s.id then return end
 for i=2,sndr.channelAmount do
  
  local n = s.source.bufferAdvance
  if sndr.channel[i] and sndr.channel[i].id and sndr.channel[i].source.bufferAdvance~=n then
   for j=2,sndr.channelAmount do
    if sndr.channel[j] and sndr.channel[j].id then
     sndr.channel[j].source.bufferAdvance=n
     if string.sub(sndr.channel[j].data,2,2)=="7" then sndr.channel[j].source.bufferAdvance=n-n%sampleChunkSize end
    end
   end
   break
  end
 end
 
 
end



-- adds the source table to a channel
local function addSource()
 local t={
  
  ---queSource = love.audio.newQueueableSource(samplerate, 8, 1, 2),
  sourceBuffer = {},--love.sound.newSoundData(math.floor(sampleChunkSize), samplerate, 8, 1),
  
  bufferAdvance = 0,
  bufferMemory = {}
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
 
 
 if not songdata then error("SNDR ERROR: sfx data is nil?\nPlease make sure your loading the right thing!") end
 
 if string.sub(songdata,1,1)~="~" then error("SNDR ERROR: Loaded sfx's data is outdated! please update it to 1.1+!\n. |____|  .") end
  
 -- song sfxs ------
 if indexType=="song" then
  -- wipe old song
  for i=1,sndr.channelAmount do
   if sndr.channel[i] and sndr.channel[i].id then sndr.channel[i]=nil end
   if sndr.buffer[i]  and sndr.buffer[i].id  then sndr.buffer[i]=nil end
  end
  
  
  
  
  -- get name length
  local p=tonumber( string.sub(songdata,3,4) )
  
  if not p or p==0 then error("SNDR ERROR: Loaded sfx's name is invaild. Please make sure it's proper! :o\nsoundData:\n"..songdata) end
  
  -- get number of channels in song
  local l=tonumber( string.sub(songdata,p+22,p+22) )
  assert(l~=0,"SNDR ERROR: wait.. no channels? something is amdist!, (l "..l.." )")
  
  --size of the channel's data, due to compression c and d are used to get the datas by parseing.
  local c,d=24+p,24+p
  
  for i=1,l do
   
   local t={}
   t.name=string.sub(songdata,5,4+p)
   
   
   while string.sub(songdata,c,c)~="\n" and c~=#songdata do c=c+1 end
   
   
   local data= string.sub(songdata,d,c )
   t.data=""
   local mc=""
   local h=-1
   while h<#data/2 do
    h=h+1
    local c=string.sub(data,h*2-1,h*2)
    if string.sub(c,1,1)=="~" then
     h=h-.5
     c=mc
    end
    t.data=t.data..c
    mc=c
   end
   
   c=c+1
   d=c
   
   t.id=true
   t.source=addSource()
   
   t.chunksize = tonumber( string.sub(songdata,p+8,p+10) )
   
   t.pitchMOD = tonumber( string.sub(songdata,p+20,p+20) )
   
   t.scale = tonumber( string.sub(songdata,p+21,p+21) )
   
   t.noteSpeed=tonumber( string.sub(songdata,p+6,p+7) )
   
   t.age=0
   
   if sndr.channel[i] then sndr.bufferAdd(sndr.channel[i]) end
   
   specialflags.layer=specialflags.layer or 1
   t.flags=specialflags
   sndr.channel[i]=t
   
   
  end
  
  -- important info thats stored in the first channel about the song
  sndr.channel[1].state=false
  if specialflags.play then sndr.channel[1].state=true if not sndr.synth.sfxseed then initmusicseed(1) end end
  sndr.channel[1].vol=1
  
  
  local pos=tonumber( string.sub(songdata,3,4) ) + 14
  sndr.channel[1].startPoint= tonumber( string.sub(songdata,pos,pos+2) )
  pos=pos+3
  sndr.channel[1].loopPoint= tonumber( string.sub(songdata,pos,pos+2) )
  
  sndr.channel[1].flags.lock=true
  
  
  
  
 -- single sfx ------ ~~~!!!~~~
 else
  
  -- find the oldest channel, works good enough. PS: maybe fix?
  local y=false
  if not indexType then
   indexType=1
  end
  
  if indexType==1 and sndr.channel[1] and sndr.channel[1].id then indexType=2 end
  
  if not sndr.channel[indexType] then y=true end
  
  for i=1,sndr.channelAmount do
   
   if not sndr.channel[i] and not y then
    y=true
    indexType=i
    
    break
   end
   
  end
  
  if not y then
   local n={}
   for i=2,sndr.channelAmount do
   -- i=sndr.channelAmount-i+1
    
    local b=0
    if sndr.channel[i] then b=sndr.channel[i].age end
    n[i]=b
   end
   for i=2,sndr.channelAmount do
    for j=2,sndr.channelAmount do
     if n[i]<n[j] then
      
      indexType=j
      
     end
     
    end
   end
  end
  
  local t={}
  local p=tonumber( string.sub(songdata,3,4) )
  if not p or p==0 then error("SNDR ERROR: Loaded sfx's name is invaild, please make sure it's proper! :o\nsoundData:\n"..songdata) end
  t.name=string.sub(songdata,5,4+p )
  
  
  -- read the dam data
  local data=string.sub(songdata,24+p,#songdata)
  t.data=string.sub(data,1,2)
  local mc=""
  local i=1
  while i<#data/2 do
   i=i+1
   local c=string.sub(data,i*2-1,i*2)
   if string.sub(c,1,1)=="~" then
    i=i-.5
    c=mc
   end
   t.data=t.data..c
   mc=c
  end
  
  
  
  
  t.id=false
  t.state=false
  t.vol=1
  t.source=addSource()
  t.noteSpeed=tonumber( string.sub(songdata,p+6,p+7) )
  
  t.age=0
  
  t.startPoint= tonumber( string.sub(songdata,p+14,p+16) )
  
  t.loopPoint= tonumber( string.sub(songdata,p+17,p+19) )
  
  t.chunksize = tonumber( string.sub(songdata,p+8,p+10) )
  
  t.pitchMOD = tonumber( string.sub(songdata,p+20,p+20) )
  t.scale = tonumber( string.sub(songdata,p+21,p+21) )
  
  specialflags.layer=specialflags.layer or 0
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
 
 initmusicseed(1)
 
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



local function vol(index,layer)
 sndr.synth.globalVolume[layer]=math.min(math.max(index,0),5)
end



-- gets global volume
local function getVol(layer)
 return sndr.synth.globalVolume[layer]
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
local function setSampler(index,table)
 assert(type(index)=="number" and type(table)=="table","SNDR ERROR: Invalid data given to setSampler! `_ `")
 sndr.synth.sampler[index]=table
end



-- make a sampleTable out of a file.
local function readSampleFile(data)
 local sampleTable={}
 
 -- header
 sampleTable[1] = {
  tonumber( string.byte( string.sub(data,1,1) ) ),
  tonumber( string.byte( string.sub(data,2,2) ) ),
 }
 local size = tonumber( string.byte( string.sub(data,3,3) ) )
 sampleTable[1][3] = string.sub(data,4,4+size)
 sampleTable[1][4] = tonumber( string.byte( string.sub(data,size+4,size+4) ) )
 sampleTable[1][5] = tonumber( string.byte( string.sub(data,size+5,size+5) ) )
 
 -- data
 sampleTable[2] = {}
 for i=size+6,#data do
  sampleTable[2][i-size-5] = tonumber( string.byte( string.sub(data,i,i) ) )
 end
 
 return sampleTable
end

























--[[
===== =====               ===== =====
----- ----- Sound Playing ----- -----
===== =====               ===== =====
]]


local function soundMain()
 
 
 while sndr.synth.queSource:getFreeBufferCount()>0 do
  
  -- for all channels
  for i=1,sndr.channelAmount do
   -- channel info
   local c=sndr.channel[i]
   if c then
    local src=c.source
    
    -- if this channel is being played do;
    if c.state or (c.id and sndr.channel[1].state) then
     
     local sConst={
      tonumber( string.sub( c.data, 1,1 ) ),
      tonumber( string.sub( c.data, 2,2 ) ),
      c.chunksize
     }
     
    
     local inst=string.sub(c.data,2,2)
     if inst=="7" then
      getSamplerTimings(i,src.bufferAdvance)
     end
     
     local n="?"
     local t,f={},{}
     
     for j=0,math.floor(sampleChunkSize)-1 do
      -- index of what info to send to synth of course dummy.
      local index=math.ceil( (src.bufferAdvance/((samplerate/c.noteSpeed)/60))/60 )
      src.bufferAdvance=src.bufferAdvance+1
      
      -- get value, if it's the end of the sfx then break out.
      local check
      n,check=SounderSynth(i,c,math.floor(src.bufferAdvance),sConst)
      --sndr.synth.soundExport[i]=sndr.synth.soundExport[i]+math.abs(tonumber(n) or 0)
      
      if check and check[2]~=0 then f[j+1]=true end
      if not n then break end
      t[#t+1]=n
     end
     
     -- used to break if not n, that broke if the next channel wasn't dead but 1 before was
     if n then
      src.sourceBuffer={ t,f }
      sndr.synth.soundExport[i]=t
      
     end
    end
    
   end
  end
  
  
  
  -- get sound data ready
  local f=false
  for j=1,math.floor(sampleChunkSize) do
   
   -- for all channels again to count up the sound datas are playing at once (PER SAMPLE!)
   local o=0
   for k=1,sndr.channelAmount do
    if sndr.channel[k] then
     
     if sndr.channel[k].source.sourceBuffer[2] then
      if sndr.channel[k].source.sourceBuffer[2][j] then o=o+1 end
     end
     
    end
   end
   
   
   local sum=0
   for i=1,sndr.channelAmount do
    
    if sndr.channel[i] and sndr.channel[i].source.sourceBuffer[1] then
     f=true
     sum=sum+sndr.channel[i].source.sourceBuffer[1][j]
     
    end
   end
   
   sndr.synth.soundSource:setSample(j-1,sum/math.max(o,1))
   
  end
   
   sndr.synth.queSource:queue(sndr.synth.soundSource)
   sndr.synth.queSource:play()
  
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
sndr.readSampleFile=readSampleFile

sndr.bufferAdd=bufferAdd
sndr.bufferMain=bufferMain
sndr.bufferUpdate=bufferUpdate

sndr.synth.getInstrument=getInstrument
sndr.synth.getSamplerTimings=getSamplerTimings
sndr.synth.getMasterVolume=getMasterVolume

sndr.soundMain=soundMain

return sndr
