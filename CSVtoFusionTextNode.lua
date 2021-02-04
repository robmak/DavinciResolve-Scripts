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
	local data1Table = {}
	local data2Table = {}
	for line in io.lines() do
		sepPos = string.find(line, ";")
		data1Value = string.sub(line, 1, sepPos-1)
		data2Value = string.sub(line, sepPos+1)
		table.insert(data1Table, data1Value)
		table.insert(data2Table, data2Value)
	end
	io.close()
	return data1Table, data2Table
end

oPath = MediaIn1:GetData('MediaProps').MEDIA_PATH
data1Table, data2Table = readCSV(string.sub(oPath, 1, string.len(oPath) - 3) .. "csv")

MediaOut1:SetData("data1", data1Table)
MediaOut1:SetData("data2", data2Table)


-- Add this to Settings/"Frame Render Script"

timeTable = Text1:GetData("data1")
Text1["StyledText"] = timeTable[time + 1]
