dofile("./mockfuse.lua") -- remove this before using in Fuse

FILL_LAST_VALUE = false -- if we get 0 or nil we want to keep the last value
VALUE_IS_MPS = true -- if true we multiply with 3.6 to get kph
SHIFT_VALUES = 0 -- this is added to all affected values in range
MUL_VALUES = 1 -- multiply values by then add shift

function splitString(inputstr, sep)
    sep = sep or "%s"
    local result = {}
    for match in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
      table.insert(result, match)
    end
    return result
end

function msToFrames(msTable, valueTable, fps, startFrame, endFrame)
  frameMilliSeconds = 1000 / fps
  startValue = valueTable[0]
  startMs = msTable[0]
  resultTable = {}
  
  lastValue = 0
  lastFrame = 0
  for index, ms in pairs(msTable) do
    frame = math.floor(ms / frameMilliSeconds)
    skippedFrames = frame - (lastFrame + 1)
    
    if frame > endFrame then
      break
    end
    
    if frame >= startFrame then
      while skippedFrames > 0 do
        resultTable[lastFrame + skippedFrames] = lastValue
        skippedFrames = skippedFrames - 1
      end
      lastValue = valueTable[index]
      resultTable[frame ] = lastValue
    end
    lastFrame = frame    

  end
  return resultTable
end


function readCSV(path)
  io.input(path)
  local msTable = {}
  local data1Table = {}
  local lastValue1 = 0
  for line in io.lines() do
    if line:len() > 0 then
      local values = splitString(line, ",")
      local ms = tonumber(values[1])
      local value1 = tonumber(values[6])
      if FILL_LAST_VALUE and (value1 == 0 or value1 == nil) then
        value1 = lastValue1
      end
      if value1 then
        lastValue1 = value1
        local data1Value = VALUE_IS_MPS and (3.6 * value1) or value1
        data1Value = math.ceil(data1Value * MUL_VALUES) + SHIFT_VALUES
        table.insert(msTable, ms)
        table.insert(data1Table, data1Value)
      end
    end
  end
  return msTable, data1Table
end

mediaProps = MediaIn1:GetData('MediaProps')
oPath = mediaProps.MEDIA_PATH
oFPS = mediaProps.MEDIA_SRC_FRAME_RATE
startFrame = mediaProps.MEDIA_MARK_IN - 1
endFrame = mediaProps.MEDIA_MARK_OUT + 1
msTable, data1Table = readCSV(string.sub(oPath, 1, string.len(oPath) - 4) .. "-gps.csv")

data1Table = msToFrames(msTable, data1Table, oFPS, startFrame, endFrame)

MediaOut1:SetData("data1", data1Table)
