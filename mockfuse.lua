MediaIn = {}
function MediaIn:new()
  o = {}
  setmetatable(o, self)
  self.__index = self
  self.MEDIA_PATH = "C:\\Users\\robert\\Videos\\2021-0209-Radfahren_im_Winterwald\\GH012994.MP4"
  self.MEDIA_SRC_FRAME_RATE = 25
  self.MEDIA_MARK_IN = 68
  self.MEDIA_MARK_OUT = 122
  return o
end

function MediaIn:SetData(name, input)
  print("storing " .. name)
end

function MediaIn:GetData(prop)
  return self
end

MediaIn1 = MediaIn:new()
MediaOut1 = MediaIn:new()

