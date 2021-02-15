------------------------------------------------------------------------
--- @file speedcalc.lua
--- @brief Computes DJI metrics files with GPS coordinates
--- to speeds in CSV format.
--- Author: Manfred Kühn
------------------------------------------------------------------------

local deb = true

-- Ausgabefunktion für Arrays
function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- User-Parameter je nach dem von welchem Aufzeichnungsgerät die Daten stammen
function set_device (device)
  if device == "Mavic2Pro" then
    suchWort = "latitude"
    lat_offset = 11 --Pos. Latitude
    lat_length = 8 --Genauigkeit Latitude (max. 8)
    lon_offset = 35 --Pos. Longitude
    lon_length = 8 --Genauigkeit Longitude (max. 8)
    alt_offset = 58 --Pos. Altitude
    alt_length = 5 --Genauigkeit Altitude
    alt_ref = -10 --Höhe, wenn Drohne am Boden, aus erster Datei eintragen
    framerate = 30 --Frequenz der Daten für Geschwindigkeitsberechnung
    anzahl_fuer_mittelwert = 60 --Mittelwert Vergangenheit
    anzahl_smoothing2 = 3 --Mittelwert Zukunft
  end
end

-- SRT-Datei laden
function load_file (path)
  local f = assert(io.open(path,"r"))
  local temps = f:read("*all")
  --f:close()
  --print(dump(temps))
  return temps
end

-- Suchwort suchen und Koordinaten zurückgeben
function search (key, data)
  local i=0
  local s={}
  while true do
    i = string.find(data, key, i+1)    -- find 'next' newline
    if i == nil then
      break
    end
    table.insert(s, i)
  end
  return s
end

-- Daten anhand der Koordinaten auslesen. lat + lon + alt
function read_Koord (ind, input_data)
  local temps = {}
  for i=1,#ind do
    --print(s[i])
    --print(string.sub(t,s[i]+lat_offset,s[i]+lat_offset+lat_length))
    temp ={string.sub(input_data,ind[i]+lat_offset,ind[i]+lat_offset+lat_length),string.sub(input_data,ind[i]+lon_offset,ind[i]+lon_offset+lat_length),string.sub(input_data,ind[i]+alt_offset,ind[i]+alt_offset+alt_length)}
    table.insert(temps,temp)
  end
  return temps
end

-- Speed-Array erzeugen
function speed_table (input_koord)
  local sp = {}
  for i=1, (#input_koord) do
    --print(speed(koord[i],koord[i+1]).." km/h")
    if i<#input_koord then
      table.insert(sp,speed_calc(input_koord[i],input_koord[i+1]))
    else
      table.insert(sp,speed_calc(input_koord[i-1],input_koord[i]))
    end
  end
  return sp
end

-- Geschwindigkeit zwischen zwei xy-Koordinaten berechnen
function speed_calc (a, b) --{a={lat,long},b={lat,long}}
  temp = 111.3 * math.cos(((a[1]-b[1])/2+b[1])*math.pi/180)
  dx = temp * (a[1] - b[1])
  dy = 111.3* (a[2] - b[2])
  d=math.sqrt((dx*dx)+(dy*dy))*framerate
  --print(d)
  d=d*3600
  d=math.floor(d+0.5)
  return d
end

--Mittelwert Vergangenheit
function smoothing1(input_table)
  local smoothed = {}
  local i = 1
  while i<=#input_table do
    temp=0
    for x=0,anzahl_fuer_mittelwert do
      if (i-x)>0 then
        temp=temp+input_table[i-x]
      else
        temp=temp+input_table[i]
      end
    end
    temp = temp / anzahl_fuer_mittelwert
    temp = math.floor(temp)
    --print(temp)
    table.insert(smoothed,temp)
    i = i+1
  end
  return smoothed
end

--Mittelwert in die Zukunft
function smoothing2(input_table)
  local smoothed = {}
  local i = 1
  while i<=#input_table do
    temp=0
    if i<=(#input_table-anzahl_smoothing2+1) then
      for x=0,(anzahl_smoothing2-1) do
        temp=temp+input_table[i+x]
      end
      temp = temp / anzahl_smoothing2
      temp = math.floor(temp)
      --print(temp)
      table.insert(smoothed,temp)
    else
      for x=0,(#input_table-i) do
        temp=temp+input_table[i+x]
      end
      temp = temp / (#input_table-i+1)
      temp = math.floor(temp)
      --print(temp)
      table.insert(smoothed,temp)
    end
    i = i+1
    end
  return smoothed
end

-- In CSV-Datei schreiben, Speed + Alt
function write_file (output_table1, output_table2)
  local file,err = io.open(pfad..".csv",'w')
  if file then
    for i=1,#output_table1 do
      file:write(output_table1[i]..";"..(output_table2[i][3]-alt_ref).."\n")
    end
    file:close()
  else
    print("error:", err)
  end
end

-------/
function main ()
  set_device("Mavic2Pro") --Geräteparameter
  pfad = "E:/Folder1/Folder2/Folder3/Drohne/DJI_0296" --Dateipfad setzen, ohne Endung
  input_data = load_file(pfad..".SRT")
  index = search(suchWort, input_data) --Index suchen
  koord = read_Koord (index, input_data) --Koord auslesen und in table speichern
  speed = speed_table(koord) --Speed berechnen zwischen zwei Frames
  speed_s = smoothing1(speed) --Mittelwertbildung anhand der Vergangenheit
  speed_s2 = smoothing2(speed_s) --Mittelwertbildung anhand der Zukunft
  speed_s3 = smoothing2(speed_s2)--Endglättung
  write_file(speed_s3,koord)--Speed und Höhen in Datei schreiben
  if deb then
    print("Anzahl an Input-Frames: "..#index)
    print("Anzahl an Output-Frames: "..#speed_s2)
    print("Topspeed: "..speed_s3[#speed_s3].." km/h")
    koord2 = {}
    for i=1,#koord do
      table.insert(koord2,tonumber(koord[i][3]))
    end
    table.sort(koord2)
    print("Maximale Höhe: "..koord2[#koord2].." hm")
  end
end

main()
