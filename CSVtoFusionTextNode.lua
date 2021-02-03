---[[
Taking values (e.g. speed info) from CSV file for every frame of a clip
and put it into a Fusion Text+ node.

CSV is parsed on "Start Render Scripts" and Text+ StyledText property is
replaced on Frame Render Scripts. Every line of CSV file contains speed value and height
value separated by ; (e.g. 23;42). This CSV file must be named like the current clip file
and path just with a different file extension (.csv instead of .mp4) and must be placed
in the same folder.
]]

-- In Fusion create a Text+ node and add this to Settings/"Start Render Scripts":

function readCSV(path)
	io.input(path)
	local speedTable = {}
	local heightTable = {}
	for line in io.lines() do
		sepPos = string.find(line, ";")
		speedValue = string.sub(line, 1, sepPos)
		heigthValue = string.sub(line, sepPos + 1)
		table.insert(speedTable, speedValue)
		table.insert(heightTable, heightValue)
	end
	io.close()
	return speedTable, heightTable
end

oPath = MediaIn1:GetData('MediaProps').MEDIA_PATH
speedTable, heightTable = readCSV(string.sub(oPath, 1, string.len(oPath) - 3) .. "csv")
Text1:SetData("cpath", timeTable)



-- Add this to Settings/"Frame Render Script"

timeTable = Text1:GetData("cpath")
Text1["StyledText"] = timeTable[time + 1]
