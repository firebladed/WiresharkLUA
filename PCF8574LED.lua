-- PCF8574 LCD Display protocol
-- declare our protocol
trivial_proto = Proto("PCF8574LED","PCF8574LCD Protocol")
trivialsub_proto = Proto("qapasssub","PCF8574LCD sub Protocol")

-- create a function to dissect it
 function trivial_proto.dissector(buffer,pinfo,tree)

	length = buffer:len()
	if length == 0 then return end
	local offset = 0
	
	pinfo.cols.protocol = "PCF8574LCD"
	local subtree = tree:add(trivial_proto,buffer(),"PCF8574LCD LCD Driver Data")
	
	while ((bit.rshift(buffer(offset,1):uint(),4) == bit.band(bit.rshift(buffer(offset+1,1):uint(),4),bit.rshift(buffer(offset+2,1):uint(),4))) and (bit.band(buffer(offset+1,1):uint(), 0x1) == 0x1)) do
		offset = offset + 1
		
	end
	
	local outstring = ""
	while offset < length do
		
		-- P7 P6 P5 P4 P3 P2 P1 P0
		-- D7 D6 D5 D4 NC E  RW RS  
		-- compare data with Instruction set
		
		-- 3 BYTES PER 4bits write, with middle byte E high
		-- two 4bit writes per char 
		local h4bit = bit.rshift(buffer(offset,1):uint(),4)
		local l4bit = bit.rshift(buffer(offset+3,1):uint(),4)
		
		local Data = bit.lshift(h4bit, 4) + l4bit
		
		if (bit.band(buffer(offset,1):uint(),0x1)) == 0x1 then
			subtree:add(trivialsub_proto,buffer(offset,6),"Data Byte:" .. bit.tohex(Data) .. "[" .. string.char(Data) .. "]")
			outstring = outstring ..  string.char(Data)
		
		else
			subtree:add(trivialsub_proto,buffer(offset,6),"Instruction Byte:" .. bit.tohex(Data))
		end
				
		offset = offset+6
	end

	local subsubtree = subtree:add(trivialsub_proto,buffer(),"PCF8574LCD Char output")
	
	
	subtree:add(buffer(0,length-1),"LED Display string: " .. outstring)

	
end

-- Registration
local i2c_table = DissectorTable.get("i2c.message")
i2c_table:add(0, trivial_proto)