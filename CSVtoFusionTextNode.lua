---[[
Taking values (e.g. speed info) from CSV file for every frame of a clip
and put it into a Fusion Text+ node.

CSV is parsed on "Start Render Scripts" and Text+ StyledText property is
replaced on Frame Render Scripts. Every line of CSV file contains frame number and speed
value separated by ; (e.g. 1;42). This CSV file must be named like the current clip file
and path just with a different file extension (.csv instead of .mp4) and must be placed
in the same folder.
]]

-- In Fusion create a Text+ node and add this to Settings/"Start Render Scripts":

function readCSV(path)
	io.input(path)
	local inputTable = {}
	for line in io.lines() do
		sepPos = string.find(line, ";") + 1
		speedValue = string.sub(line, sepPos)
		table.insert(inputTable, speedValue)
	end
	io.close()
	return inputTable
end

oPath = MediaIn1:GetData('MediaProps').MEDIA_PATH
timeTable = readCSV(string.sub(oPath, 1, string.len(oPath) - 3) .. "csv")
Text1:SetData("cpath", timeTable)



-- Add this to Settings/"Frame Render Script"

timeTable = Text1:GetData("cpath")
Text1["StyledText"] = timeTable[time + 1]
