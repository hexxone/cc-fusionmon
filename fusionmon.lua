-- Below are values you can change

local UpdateIntervalSeconds = 3
local isDisplay = true
local isTransmitter = false
local isReceiver = true
local wirelessChannel = 420

local setTextScale = 1.0;
local VersionInfo = "Craftana - Fusion Dashboard";

local backgroundColor = colors.lightGray;

local colorMapping = {
	water = colors.cyan,
	brine = colors.brown,
	lithium = colors.yellow,
	tritium = colors.green,
	deuterium = colors.red,
	d_t_fuel = colors.purple,
	steam = colors.white,
	energy = colors.orange
}

local defaultTextColor = colors.black;
local colorlessText = colors.black;
local notConnectedColor = colors.lightGray;

local categoryBgColor = colors.gray;
local categoryTextColor = colors.white;


-- Above are values you can change

local DataLen = 6; -- how long the (current/maximum) string will be

local NameLen = 18; -- will be calculated
local ScreenWidth = 7; -- will be calculated

local uid = "pc" .. math.random(100000000, 999999999)
print("Starting "..VersionInfo.." - uid: " .. uid);
local CurLine = 1;

local ContentLayout = {
	{
		key = "tritium",
		text = "Tritium Plant",
		items = {
			"water",
			"water heating temperature",
			"brine production",
			"brine",
			"brine heating temperature",
			"lithium production",
			"lithium",
			"tritium production",
			"tritium"
		}
	},
	{
		key = "buffer",
		text = "Input Buffer",
		items = {
			"tritium",
			"deuterium",
		}
	},
	{
		key = "fusion",
		text = "Reactor",
		items = {
			"water",
			"injection rate",
			"d-t fuel",
			"energy",
			"steam production",
			"steam"
		}
	},
	{
		key = "turbine",
		text = "Turbine",
		items = {
			"steam flow rate",
			"steam",
			"energy production",
			"energy"
		}
	}
}

local ContentData = {};

function PadString (sText, iLen)
	local iTextLen = string.len(sText);
	-- Too short, pad
	if (iTextLen < iLen) then
		local iDiff = iLen - iTextLen;
		return(sText..string.rep(" ",iDiff));
	end
	-- Too long, trim
	if (iTextLen > iLen) then
		return(string.sub(sText,1,iLen));
	end
	-- Exact length
	return(sText);
end

function PrepareMonitor(mon)
	mon.setTextScale(setTextScale)
	local ScreenWidth, _ = mon.getSize() -- Get the width of the monitor
	NameLen = (ScreenWidth) - (DataLen)

	if (mon.isColor() == false) then
		colorMapping.water = colorlessText
		colorMapping.brine = colorlessText
		colorMapping.lithium = colorlessText
		colorMapping.tritium = colorlessText
		colorMapping.deuterium = colorlessText
		colorMapping.d_t_fuel = colorlessText
		colorMapping.steam = colorlessText
		colorMapping.energy = colorlessText
	end
end

function UpdateTable(timestamp,strName,strCount,strMax,strCategory,strLegend,strColor)
	if (ContentData == nil) then
		ContentData = {}
	end
	if (ContentData[uid] == nil) then
		ContentData[uid] = {}
	end
	if (ContentData[uid][timestamp] == nil) then
		ContentData[uid][timestamp] = {}
	end

	if (ContentData[uid][timestamp][strCategory] == nil) then
		ContentData[uid][timestamp][strCategory] = {}
	end

	if (ContentData[uid][timestamp][strCategory][strName] == nil) then
		ContentData[uid][timestamp][strCategory][strName] = {}
	end

	if (ContentData[uid][timestamp][strCategory][strName]["count"] == nil) then
		ContentData[uid][timestamp][strCategory][strName]["count"] = strCount
	else
		ContentData[uid][timestamp][strCategory][strName]["count"] = ContentData[uid][timestamp][strCategory][strName]["count"] + strCount
	end

	if (ContentData[uid][timestamp][strCategory][strName]["max"] == nil) then
		ContentData[uid][timestamp][strCategory][strName]["max"] = strMax
	else
		ContentData[uid][timestamp][strCategory][strName]["max"] = ContentData[uid][timestamp][strCategory][strName]["max"] + strMax
	end

	ContentData[uid][timestamp][strCategory][strName]["legend"] = strLegend
	ContentData[uid][timestamp][strCategory][strName]["color"] = strColor

	--print("UpdateTable: " .. strName .. ", " .. strCount .. "/" .. strMax .. ", #" .. strCategory .. ", l=" .. strLegend)
end

function PrintMonitorCenter(mon, text, y)
	local ScreenWidth, _ = mon.getSize() -- Get the width of the monitor
	mon.setCursorPos(1, y)
	mon.write(string.rep(" ", ScreenWidth)) -- do a fill-pass
	mon.setCursorPos(math.floor((ScreenWidth-#text)/2), y) -- now write text to center
	mon.write(text)
end

function PrintMonitorCategory(mon, category)
	CurLine = CurLine + 1
	mon.setBackgroundColor(categoryBgColor)
	mon.setTextColor(categoryTextColor)
	PrintMonitorCenter(mon, category, CurLine)
	CurLine = CurLine + 1
end


function PrintMonitorCategoryEmpty(mon)
	mon.setBackgroundColor(backgroundColor)
	mon.setTextColor(categoryBgColor)
	PrintMonitorCenter(mon, "- no devices -", CurLine)
	CurLine = CurLine + 1
end

function PrintMonitorStat(mon, strName, strAmount, strMax, strLegend, barColor)

	local line = string.format("%s  %3i%s", PadString(strName, NameLen + 1), strAmount, PadString(strLegend, 1))
	if (strAmount >= 1099511627776) then
		line = string.format("%s  %3iT%s", PadString(strName, NameLen), math.floor(strAmount/1099511627776), PadString(strLegend, 1))
	elseif (strAmount >= 1073741824) then
			line = string.format("%s  %3iG%s", PadString(strName, NameLen), math.floor(strAmount/1073741824), PadString(strLegend, 1))
	elseif (strAmount >= 1048576) then
		line = string.format("%s  %3iM%s", PadString(strName, NameLen), math.floor(strAmount/1048576), PadString(strLegend, 1))
	elseif (strAmount >= 1024) then
		line = string.format("%s  %3iK%s", PadString(strName, NameLen), math.floor(strAmount/1024), PadString(strLegend, 1))
	end

	mon.setCursorPos(1,CurLine);
	local percent = 0;
	if(strMax > 0) then
		percent = strAmount / strMax * 100
		if (percent > 100) then percent = 100; end
	end

	local minCap = 0;
	if(strAmount > 0) then;	minCap = 1;	end -- always show one bar length if > 0
	local barlength = math.max(minCap, math.floor(percent / 100 * (string.len(line)-1)));

	mon.setTextColor(defaultTextColor)

	if (barlength > 0) then
		mon.setBackgroundColor(barColor);
	else
		-- bar is empty -> only text
		mon.setBackgroundColor(backgroundColor)
		if(strMax > 0) then
		else
			mon.setTextColor(notConnectedColor)
		end
	end

	if (string.len(line) > barlength) then
		-- bar is not filled completely -> split on fill level
		local msg = string.sub(line,1,barlength)
		mon.write(msg)

		mon.setBackgroundColor(backgroundColor)
		mon.setTextColor(defaultTextColor)
		mon.write(string.sub(line,barlength+1,-2))
	else
		-- bar is filled completely -> just print
		local spaces = barlength - string.len(line)
		mon.write(line)
		mon.write(string.rep(" ",spaces))
	end

	--mon.setTextColor(colors.white)
	CurLine = CurLine + 1
end

-- Find a monitor & prepare it
function GetMonitor()
	local mon = peripheral.find("monitor")
	if not mon then
		error("No monitor found")
	end

	PrepareMonitor(mon)
	return mon;
end

-- Find a wireless modem
function GetWirelessModem()
	local mod = peripheral.find("modem", function(name, object) return object.isWireless() end);
	if mod == nil then
		error("No Wireless modem found")
	end

	mod.closeAll()
	return mod;
end

function GetColorForFluidName(fluidName)
	if(string.find(fluidName, "water")) then
		return colorMapping.water
	end
	if(string.find(fluidName, "brine")) then
		return colorMapping.brine
	end
	if(string.find(fluidName, "lithium")) then
		return colorMapping.lithium
	end
	if(string.find(fluidName, "tritium")) then
		return colorMapping.tritium
	end
	if(string.find(fluidName, "deuterium")) then
		return colorMapping.deuterium
	end
	if(string.find(fluidName, "d-t fuel")) then
		return colorMapping.d_t_fuel
	end
	if(string.find(fluidName, "steam")) then
		return colorMapping.steam
	end

	return notConnectedColor; -- TODO separate fallback ?
end

function StripItemName(strName)
	if(strName ~= nil) then
		if(string.find(strName,":") ~= nil) then
			local k = string.find(strName,":")+1;
			strName = string.sub(strName,k);
		end
		return string.gsub(strName,"%s+"," ");
	end
	return strName
end

function CollectLocalData()
	PrintTerminalBottom("Collecing data.");
	local timestamp = os.clock();

	local peripherals = peripheral.getNames()
	for i,name in pairs(peripherals) do
		local p = peripheral.wrap(name);
		local pType = peripheral.getType(name);

		if (p.getBlockData ~= nil) then
			PrintTerminalBottom(i .. ": Processing Advanced Peripherals");
			local blockdata = p.getBlockData();

			if (blockdata.GasTanks) then
				PrintTerminalBottom(i .. ": Processing Gas Storage via Advanced Peripherals");
				local itemData = {};
				for j in pairs(blockdata.GasTanks) do
					local iteminfo = blockdata.GasTanks[j];
					local displayname = iteminfo.stored.gasName;
					if (displayname) then
						displayname = StripItemName(displayname);
						local amount = 0;
						if (not itemData[displayname]) then
							amount = iteminfo.stored.amount;
							if (amount == nil) then
								amount = 0;
							end
							amount = math.floor(amount/1000);
							itemData[displayname] = amount;
						else
							amount = iteminfo.stored.amount;
							if (amount == nil) then
								amount = 0;
							end	
							amount = math.floor(amount/1000);
							itemData[displayname] = itemData[displayname] + amount;
						end
					end
				end
				for key,val in pairs(itemData) do
					UpdateTable(timestamp,key,val, val, "buffer", "b", GetColorForFluidName(key)); -- @TODO MAX
				end
			end

			if (blockdata.FluidTanks) then
				PrintTerminalBottom(i .. ": Processing Fluid Storage via Advanced Peripherals");
				local itemData = {};
				for j in pairs(blockdata.FluidTanks) do
					local iteminfo = blockdata.FluidTanks[j];
					local displayname = iteminfo.stored.FluidName;
					if (displayname) then
						displayname = StripItemName(displayname);
						local amount = 0;
						if (not itemData[displayname]) then
							amount = iteminfo.stored.Amount;
							if (amount == nil) then
								amount = 0;
							end
							amount = math.floor(amount/1000);
							itemData[displayname] = amount;
						else
							amount = iteminfo.stored.Amount;
							if (amount == nil) then
								amount = 0;
							end	
							amount = math.floor(amount/1000);
							itemData[displayname] = itemData[displayname] + amount;
						end
					end
				end
				for key,val in pairs(itemData) do
					UpdateTable(timestamp,key,val, val , "buffer", "b", GetColorForFluidName(key)); -- @TODO MAX
				end
			end
		end

		if (p.getTankInfo ~= nil or p.getFilledPercentage ~= nil or p.tanks) then
			PrintTerminalBottom(i .. ": Processing Tank");
			local iteminfo;
			local capacity;
			if (p.getTankInfo ~= nil) then
				iteminfo = p.getTankInfo();
			end
			if (p.getFilledPercentage ~= nil) then
				iteminfo = p.getStored();
			end
			if (p.tanks ~= nil) then
				local tankinfo = p.tanks(); -- Industrial Foregoing blackhole tank
				if (tankinfo[1] ~= nil) then
					iteminfo = tankinfo[1];
				end
			end
			if(p.getCapacity ~= nil) then
				capacity = math.floor(p.getCapacity() / 1000); -- Mekanism Tank
			end
			if (iteminfo ~= nil) then
				local displayname = "Empty";
				local amount = 0;
				if (iteminfo[1] ~= nil) then
					if (iteminfo[1].contents) then
						displayname = iteminfo[1].contents.rawName;
						amount = iteminfo[1].contents.amount;
						amount = math.floor(amount/1000);
					end
				end
				if (iteminfo.name ~= nil) then
					displayname = iteminfo.name;
				end
				if (iteminfo.amount ~= nil) then
					amount = iteminfo.amount;
					amount = math.floor(amount/1000);
				end
				displayname = StripItemName(displayname);

				if(capacity == nil or capacity < amount) then
					capacity = amount;
				end
				if (amount ~= 0) then
					UpdateTable(timestamp, displayname, amount, capacity, "buffer", "b", GetColorForFluidName(displayname)); -- @TODO MAX, COLOR
				end
			end
		end

		--  Evaporation Plant
		if (pType == "thermalEvaporationValve") then
			PrintTerminalBottom(i .. ": Processing Thermal Evaporation Plant Valve");
			local category = "tritium"
			-- Input (sum)
			if(p.getInput ~= nil and p.getInputCapacity  ~= nil) then
				local input = p.getInput()
				local inputAmount = nil
				local inputName = nil
				local inputCapacity = p.getInputCapacity();
				if(input ~= nil) then
					inputAmount = input.amount
					inputName = StripItemName(input.name)
				end
				if(inputAmount ~= nil and inputName ~= nil and inputCapacity ~= nil) then
					local inputColor = GetColorForFluidName(inputName)
					UpdateTable(timestamp, inputName, inputAmount, inputCapacity, category, "b", inputColor)

					-- input heating (average)
					if(p.getTemperature ~= nil) then
						local temperature = p.getTemperature()
						local tempCapacity = 3000 -- TODO exact limit needed depends on height? and fluid???
						if(temperature ~= nil and tempCapacity ~= nil) then
							UpdateTable(timestamp, inputName .. " heating temperature", temperature, tempCapacity, category, "b", inputColor)
						end
					end

					-- output Production (sum), get this from input and invert it because output will probably be empty at some point.
					if(p.getProductionAmount ~= nil) then
						local productionAmount = p.getProductionAmount()
						local productionCapacity = 1080 -- hard capped
						local productionName = "brine" -- default (water -> brine)
						if(inputName == "brine") then
							productionName = "lithium" -- other case (brine -> lithium)
						end
						if(productionAmount ~= nil and productionName ~= nil and productionCapacity ~= nil) then
							local productionColor = GetColorForFluidName(productionName)
							UpdateTable(timestamp, productionName .. " production", productionAmount, productionCapacity, category, "b", productionColor)
						end

					end
				end
			end
			-- Output (sum)
			if(p.getOutput ~= nil and p.getOutputCapacity  ~= nil) then
				local output = p.getOutput()
				local outputAmount = nil
				local outputName = nil
				local outputCapacity = p.getOutputCapacity();
				if(output ~= nil) then
					outputAmount = output.amount
					outputName = StripItemName(output.name)
				end
				if(outputAmount ~= nil and outputName ~= nil and outputCapacity ~= nil) then
					UpdateTable(timestamp, outputName, outputAmount, outputCapacity, category, "b", GetColorForFluidName(outputName));
				end
			end
		end

		-- Solar Neutron Activator
		if (pType == "solarNeutronActivator") then
			PrintTerminalBottom(i .. ": Processing Solar Neutron Activator");
			local category = "tritium"
			-- Input (sum)
			if(p.getInput ~= nil and p.getInputCapacity  ~= nil) then
				local input = p.getInput()
				local inputAmount = nil
				local inputName = nil
				local inputCapacity = p.getInputCapacity();
				if(input ~= nil) then
					inputAmount = input.amount
					inputName = StripItemName(input.name)
				end
				if(inputAmount ~= nil and inputName ~= nil and inputCapacity ~= nil) then
					local inputColor = GetColorForFluidName(inputName)
					UpdateTable(timestamp, inputName, inputAmount, inputCapacity, category, "b", inputColor)

					-- output Production (sum), get this from input and invert it because output will probably be empty at some point.
					if(p.getProductionRate ~= nil and p.getPeakProductionRate ~= nil) then
						local productionAmount = p.getProductionRate()
						local productionCapacity = p.getPeakProductionRate()
						local productionName = "tritium" -- default (lithium -> tritium), other would be nulear waste, which doesnt make sense here.

						if(productionAmount ~= nil and productionName ~= nil and productionCapacity ~= nil) then
							local productionColor = GetColorForFluidName(productionName)
							UpdateTable(timestamp, productionName .. " production", productionAmount, productionCapacity, category, "b", productionColor)
						end

					end
				end
			end
			-- Output (sum)
			if(p.getOutput ~= nil and p.getOutputCapacity  ~= nil) then
				local output = p.getOutput()
				local outputAmount = nil
				local outputName = nil
				local outputCapacity = p.getOutputCapacity();
				if(output ~= nil) then
					outputAmount = output.amount
					outputName = StripItemName(output.name)
				end
				if(outputAmount ~= nil and outputName ~= nil and outputCapacity ~= nil) then
					UpdateTable(timestamp, outputName, outputAmount, outputCapacity, category, "b", GetColorForFluidName(outputName));
				end
			end
		end


		if (pType == "fusionReactorLogicAdapter") then
			PrintTerminalBottom(i .. ": Processing Fusion Reactor Logic Adapter");
			local category = "fusion";
			if(p.getDTFuel ~= nil) then
				local dtFuelData = p.getDTFuel();
				if (dtFuelData ~= nil) then
					UpdateTable(timestamp, "d-t fuel", dtFuelData.amount, 1000, category, "b", colorMapping.d_t_fuel);
				end
			end
			if (p.getInjectionRate ~= nil) then
				local injectionRate = p.getInjectionRate();
				if (injectionRate ~= nil) then
					UpdateTable(timestamp, "injection rate", injectionRate, 99, category, "b", colorMapping.d_t_fuel);
				end
			end
			if (p.getProductionRate ~= nil) then
				local productionRate = p.getProductionRate();
				if (productionRate ~= nil) then
					UpdateTable(timestamp, "steam production", productionRate, productionRate, category, "b", colorMapping.steam);
				end
			end
			if(p.getSteam ~= nil and p.getSteamCapacity  ~= nil) then
				local steam = p.getSteam()
				local steamAmount = nil;
				local steamCapacity = p.getSteamCapacity();
				if(steam ~= nil) then
					steamAmount = steam.amount
				end
				if(steamAmount ~= nil and steamCapacity ~= nil) then
					UpdateTable(timestamp, "steam", steamAmount, steamCapacity, category, "b", colorMapping.steam);
				end
			end
			if(p.getWater ~= nil and p.getWaterCapacity  ~= nil) then
				local water = p.getWater()
				local waterAmount = nil;
				local waterCapacity = p.getWaterCapacity();
				if(water ~= nil) then
					waterAmount = water.amount
				end
				if(waterAmount ~= nil and waterCapacity ~= nil) then
					UpdateTable(timestamp, "water", waterAmount, waterCapacity, category, "b", colorMapping.water);
				end
			end
			if(p.getDeuterium ~= nil and p.getDeuteriumCapacity  ~= nil) then
				local deuterium = p.getDeuterium()
				local deuteriumAmount = nil;
				local deuteriumCapacity = p.getDeuteriumCapacity();
				if(deuterium ~= nil) then
					deuteriumAmount = deuterium.amount
				end
				if(deuteriumAmount ~= nil and deuteriumCapacity ~= nil) then
					UpdateTable(timestamp, "deuterium", deuteriumAmount, deuteriumCapacity, category, "b", colorMapping.deuterium);
				end
			end
			if(p.getTritium ~= nil and p.getTritiumCapacity ~= nil) then
				local tritium = p.getTritium()
				local tritiumAmount = nil;
				local tritiumCapacity = p.getTritiumCapacity();
				if(tritium ~= nil) then
					tritiumAmount = tritium.amount
				end
				if(tritiumAmount ~= nil and tritiumCapacity ~= nil) then
					UpdateTable(timestamp, "tritium", tritiumAmount, tritiumCapacity, category, "b", colorMapping.tritium);
				end
			end
		end

		if(pType == "fusionReactorPort") then
			PrintTerminalBottom(i .. ": Processing Fusion Reactor Port");
			local category = "fusion";

			if (p.getEnergy ~= nil and p.getMaxEnergy ~= nil) then
				local energy = p.getEnergy();
				local maxEnergy = p.getMaxEnergy();
				if(energy ~= nil and maxEnergy ~= nil) then
					UpdateTable(timestamp, "energy", energy, maxEnergy, category, "FE", colorMapping.energy);
				end
			end
		end

		if (pType == "turbineValve") then
			local category = "turbine";
			PrintTerminalBottom(i .. ": Processing Steam Turbine");

			if(p.getFlowRate ~= nil and p.getMaxFlowRate ~= nil) then
				local turbineFlowRate = p.getFlowRate();
				local maxFlowRate = p.getMaxFlowRate();
				if (turbineFlowRate ~= nil and maxFlowRate ~= nil) then
					UpdateTable(timestamp,"steam flow rate", turbineFlowRate, maxFlowRate, category, "b", colorMapping.steam);
				end
			end

			if(p.getSteam ~= nil and p.getSteamCapacity  ~= nil) then
				local steam = p.getSteam()
				local steamAmount = nil;
				local steamCapacity = p.getSteamCapacity();
				if(steam ~= nil) then
					steamAmount = steam.amount
				end
				if(steamAmount ~= nil and steamCapacity ~= nil) then
					UpdateTable(timestamp, "steam", steamAmount, steamCapacity, category, "b", colorMapping.steam);
				end
			end

			if (p.getProductionRate ~= nil and p.getMaxProduction ~= nil) then
				local productionRate = p.getProductionRate();
				local maxProduction = p.getMaxProduction();
				if (productionRate ~= nil and maxProduction ~= nil) then
					UpdateTable(timestamp,"energy production",productionRate, maxProduction, category, "", colorMapping.energy);
				end
			end

			if (p.getEnergy ~= nil and p.getMaxEnergy ~= nil) then
				local energy = p.getEnergy();
				local maxEnergy = p.getMaxEnergy();
				if(energy ~= nil and maxEnergy ~= nil) then
					UpdateTable(timestamp, "energy", energy, maxEnergy, category, "FE", colorMapping.energy);
				end
			end
		end

		--print("Done");
	end

	-- remove old data
	if(ContentData[uid] ~= nil) then
		local sortedTimestamps = {}
		for timestamp in pairs(ContentData[uid]) do
			table.insert(sortedTimestamps, timestamp)
		end
		table.sort(sortedTimestamps)
		local latest = nil
		for j = table.maxn(sortedTimestamps), 1, -1 do
			if latest == nil then
				latest = sortedTimestamps[j]
			else
				ContentData[uid][sortedTimestamps[j]] = nil
			end
		end
	end
end

function UpdateMonitor(mon, stateChar)
	PrintTerminalBottom("Updating monitor.");

	ColumnWidth = NameLen + 7

	local ScreenWidth, _ = mon.getSize() -- Get the width of the monitor
	MaxColumn = math.floor(ScreenWidth / (ColumnWidth)) - 1
	mon.setBackgroundColor(backgroundColor)
	mon.clear()
	mon.setTextColor(colors.white)
	PrintMonitorCenter(mon, stateChar .. " " .. VersionInfo .. " " .. stateChar, 1)
	CurLine = 2

	-- process categories and items downward, skipping empty ones.
	for i,layout in pairs(ContentLayout) do
		local strCategory = layout.key;
		local printedItems = false;
		PrintMonitorCategory(mon, layout.text)
		for j,strName in pairs(layout.items) do

			local legend
			local color
			local strCount = 0
			local strMax = 0

			for id in pairs(ContentData) do
				for timestamp in pairs(ContentData[id]) do
					if(ContentData[id][timestamp][strCategory] == nil) then
						goto continue
					end
					if(ContentData[id][timestamp][strCategory][strName] == nil) then
						goto continue
					end
					-- assume we only have one timestamp entry
					if (ContentData[id][timestamp][strCategory][strName]["legend"] ~= nil) then
						legend = ContentData[id][timestamp][strCategory][strName]["legend"];
					end
					if (ContentData[id][timestamp][strCategory][strName]["color"] ~= nil) then
						color = ContentData[id][timestamp][strCategory][strName]["color"];
					end
					if (ContentData[id][timestamp][strCategory][strName]["count"] ~= nil) then
						strCount = strCount + ContentData[id][timestamp][strCategory][strName]["count"];
					end
					if (ContentData[id][timestamp][strCategory][strName]["max"] ~= nil) then
						strMax = strMax + ContentData[id][timestamp][strCategory][strName]["max"];
					end
				    ::continue::
				end
			end

			if ((strCount > 0 or strMax > 0) and (legend ~= nil and color ~= nil)) then
				PrintMonitorStat(mon, strName, strCount, strMax, legend, color)
				printedItems = true
			end
		end

		if(not printedItems) then
			PrintMonitorCategoryEmpty(mon)
		end
	end
end


function PrintTerminalCenter(text, y)
	local TermWidth, _ = term.getSize() -- Get the width of the monitor
	term.setCursorPos(1, y)
	term.write(string.rep(" ", TermWidth)) -- do a extra fill-pass
	term.setCursorPos(math.floor((TermWidth-#text)/2), y) -- now write text to center
	term.write(text)
end

function PrintTerminalBottom(text)
	local TermWidth, TermHeight = term.getSize()
	term.setCursorPos(1, TermHeight - 1)
	term.write(string.rep(" ", TermWidth)) -- do a extra fill-pass
	term.setCursorPos(1, TermHeight - 1)
	term.write("> " .. text)
	term.setCursorPos(1, TermHeight)
end

-- This is the main section of the script
local monitor = nil;
local modem = nil;
local peripherals = nil;
ContentData = {};

if(isReceiver and isTransmitter) then
	error("Cannot be receiver and transmitter at the same time.")
end

if(not isTransmitter and not isDisplay) then
	error("Not a Transmitter and not a Monitor -> nothing to do.")
end

function ConfigurePeripherals()
	if(isDisplay) then
		monitor = GetMonitor();
	end

	if(isReceiver or isTransmitter) then
		modem = GetWirelessModem();
		modem.open(wirelessChannel);
	end

	peripherals = peripheral.getNames()
	term.clear()
	term.setCursorPos(1,1)
	PrintTerminalCenter("Running " .. VersionInfo, 1)
	term.setCursorPos(1,3)
	print("Is Display:  " .. tostring(isDisplay))
	print("Is Sender:   " .. tostring(isTransmitter))
	print("Is Receiver: " .. tostring(isReceiver))
	print("Channel:     " .. wirelessChannel)
	print("Peripherals: " .. #peripherals)
	print("Heartbeat:   ")
	PrintTerminalBottom("Updated peripherals.")
end

ConfigurePeripherals();


-- Perform Initial Collection and Update the Monitor if given
CollectLocalData();
if monitor then
	UpdateMonitor(monitor, "#");
end

local timerUpdate = os.startTimer(UpdateIntervalSeconds);
local wirelessEventCount = 0;
local heartbeat = true

-- Main program loop
while true do
	local heartChar = "#"
	if(heartbeat) then
		heartChar = "+"
	end
	heartbeat = not heartbeat
	term.setCursorPos(14,8)
	term.write(heartChar)

	local event, param1, param2, param3, param4, param5 = os.pullEvent();
	if (event == "timer") then
		if (param1 == timerUpdate) then
			CollectLocalData();
			if (modem) then
				if (isTransmitter) then
					modem.transmit(wirelessChannel,1,ContentData);
					PrintTerminalBottom("Transmitted data.")
				end
			end
			if monitor then
				UpdateMonitor(monitor, heartChar);
			end
			wirelessEventCount = 0;
			timerUpdate = os.startTimer(UpdateIntervalSeconds);
		end
	end
	if (event == "modem_message") then
		if (isReceiver == true) then
			PrintTerminalBottom("Received data: "..event);
			wirelessEventCount = wirelessEventCount + 1;
			for extId,data in pairs(param4) do
				if (data ~= nil) then
					ContentData[extId] = data;
				end
			end
			if (wirelessEventCount >= 10) then
				timerUpdate = os.startTimer(1);
			end
		end
	end
	if (event == "monitor_touch") or (event == "monitor_resize") then
		if monitor then
			PrintTerminalBottom("Updating monitor.");
			UpdateMonitor(monitor, heartChar);
		end
	end
	if (event == "peripheral") or (event == "peripheral_detach") then
		PrintTerminalBottom("Updating peripherals.");
		ConfigurePeripherals();
	end
end