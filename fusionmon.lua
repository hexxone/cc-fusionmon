-- Craftana Fusion Dashboard https://github.com/hexxone/cc-fusionmon
-- heavily inspired by https://pastebin.com/4XYCedMC
-- made by https://hexx.one

-- ======== SETTINGS START ========

local UpdateIntervalSeconds = 3
local RemoveOldDataAfterSec = 120

local isDisplay = true
local isTransmitter = true
local isReceiver = true
local wirelessChannel = 420

local setTextScale = 1.0
local linesBetweenCategories = 0

local printVersion = true
local VersionInfo = "Craftana - Fusion Dashboard"

local backgroundColor = colors.lightGray

local colorMap = {
	water = colors.cyan,
	brine = colors.brown,
	lithium = colors.yellow,
	tritium = colors.green,
	deuterium = colors.red,
	d_t_fuel = colors.purple,
	steam = colors.white,
	energy = colors.orange
}

local defaultTextColor = colors.black
local colorlessText = colors.black
local notConnectedColor = colors.lightGray

local printCategories = true
local categoryBgColor = colors.gray
local categoryTextColor = colors.white

-- ======== SETTINGS END ========

local uid = "pc" .. math.random(100000000, 999999999)
local MaxLegendLen = 2
local CurLine = 1
local IsCliMode = not isTransmitter and not isDisplay
if(IsCliMode) then
	printVersion = false
	printCategories = false
end

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
			"tritium production"
		}
	}, {
		key = "buffer",
		text = "Input Buffer",
		items = {
			"tritium",
			"deuterium",
		}
	}, {
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
	}, {
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

function PadStringR(str, targLen)
	local txtLen = string.len(str)
	if (txtLen < targLen) then
		return(str..string.rep(" ",targLen - txtLen)) -- Too short, pad
	end
	if (txtLen > targLen) then
		return(string.sub(str,1,targLen)) -- Too long, trim
	end
	return(str) -- Exact length
end

function PrepareMonitor(mon)
	if (mon.isColor() == false) then
		colorMap.water = colorlessText
		colorMap.brine = colorlessText
		colorMap.lithium = colorlessText
		colorMap.tritium = colorlessText
		colorMap.deuterium = colorlessText
		colorMap.d_t_fuel = colorlessText
		colorMap.steam = colorlessText
		colorMap.energy = colorlessText
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
end

function WriteMonitorCenter(mon, text, y)
	local ScreenWidth, _ = mon.getSize() -- Get the width of the monitor
	mon.setCursorPos(1, y)
	mon.write(string.rep(" ", ScreenWidth)) -- do a fill-pass
	mon.setCursorPos(math.floor((ScreenWidth-#text)/2), y) -- now write text to center
	mon.write(text)
end

function PrintMonitorCategory(mon, category)
	CurLine = CurLine + linesBetweenCategories
	mon.setBackgroundColor(categoryBgColor)
	mon.setTextColor(categoryTextColor)
	WriteMonitorCenter(mon, category, CurLine)
	CurLine = CurLine + 1
end

function PrintMonitorCategoryEmpty(mon)
	mon.setBackgroundColor(backgroundColor)
	mon.setTextColor(categoryBgColor)
	WriteMonitorCenter(mon, "- no devices -", CurLine)
	CurLine = CurLine + 1
end

function PrintMonitorStat(mon, strName, strAmount, strMax, strLegend, barColor)
	local screenWidth, _ = mon.getSize()
	local nameLen = screenWidth - 10 -- 2 = space, 5 = unit, 1 = exponent, 2 = legend

	local padLegend = PadStringR(strLegend, math.min(MaxLegendLen, string.len(strLegend)))
	local padName = PadStringR(strName, nameLen)

	local formattedAmount, unit = strAmount, ""
	-- Determine the unit and format the amount accordingly
	if (strAmount >= 1099511627776) then
		formattedAmount = math.floor(strAmount / 1099511627776)
		unit = "T"
	elseif (strAmount >= 1073741824) then
		formattedAmount = math.floor(strAmount / 1073741824)
		unit = "G"
	elseif (strAmount >= 1048576) then
		formattedAmount = math.floor(strAmount / 1048576)
		unit = "M"
	elseif (strAmount >= 1024) then
		formattedAmount = math.floor(strAmount / 1024)
		unit = "K"
	elseif (strAmount >= 100) then
		formattedAmount = string.format("%.1f", strAmount)
	elseif (strAmount >= 10) then
		formattedAmount = string.format("%.2f", strAmount)
	else
		formattedAmount = string.format("%.3f", strAmount)
	end
	local paddedAmount = string.format("%5s", formattedAmount)
	local line = string.format("%s  %8s", padName, paddedAmount .. unit .. padLegend)

	mon.setCursorPos(1,CurLine);
	local percent = 0;
	if(strMax > 0) then
		percent = strAmount / strMax * 100
		if (percent > 100) then percent = 100; end
	end

	local minCap = 0;
	if(strAmount > 0) then;	minCap = 1;	end -- always show one bar length if > 0
	local barlength = math.max(minCap, math.floor(percent / 100 * (string.len(line))));

	mon.setTextColor(defaultTextColor)

	if (barlength > 0) then
		mon.setBackgroundColor(barColor);
	else
		-- bar is empty -> only text
		mon.setBackgroundColor(backgroundColor)
		if(strMax <= 0) then
			mon.setTextColor(notConnectedColor)
		end
	end
	if (string.len(line) > barlength) then
		-- bar is not filled completely -> split on fill level
		local msg = string.sub(line,1,barlength)
		mon.write(msg)
		mon.setBackgroundColor(backgroundColor)
		mon.setTextColor(defaultTextColor)
		mon.write(string.sub(line,barlength+1))
	else
		-- bar is filled completely -> just print
		local spaces = barlength - string.len(line)
		mon.write(line)
		mon.write(string.rep(" ",spaces))
	end
	CurLine = CurLine + 1
end

function GetMonitor()
	local mon = peripheral.find("monitor")
	if not mon then
		error("No monitor found")
	end
	mon.setTextScale(setTextScale)
	return mon;
end

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
		return colorMap.water
	end
	if(string.find(fluidName, "brine")) then
		return colorMap.brine
	end
	if(string.find(fluidName, "lithium")) then
		return colorMap.lithium
	end
	if(string.find(fluidName, "tritium")) then
		return colorMap.tritium
	end
	if(string.find(fluidName, "deuterium")) then
		return colorMap.deuterium
	end
	if(string.find(fluidName, "d-t fuel")) then
		return colorMap.d_t_fuel
	end
	if(string.find(fluidName, "steam")) then
		return colorMap.steam
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
	PrintTermBottom("Collecing data.");
	local timestamp = os.epoch("local");

	local peripherals = peripheral.getNames()
	for i,name in pairs(peripherals) do
		local p = peripheral.wrap(name);
		local pType = peripheral.getType(name);

		if (p.getBlockData ~= nil) then
			PrintTermBottom(i .. ": Processing Advanced Peripherals");
			local blockdata = p.getBlockData();
			if (blockdata.GasTanks) then
				PrintTermBottom(i .. ": Processing Gas Storage via Advanced Peripherals");
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
				PrintTermBottom(i .. ": Processing Fluid Storage via Advanced Peripherals");
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
							amount = amount/1000;
							itemData[displayname] = amount;
						else
							amount = iteminfo.stored.Amount;
							if (amount == nil) then
								amount = 0;
							end	
							amount = amount/1000;
							itemData[displayname] = itemData[displayname] + amount;
						end
					end
				end
				for key,val in pairs(itemData) do
					UpdateTable(timestamp,key,val, val , "buffer", "b", GetColorForFluidName(key)); -- @TODO MAX
				end
			end
		end

		if string.match(pType, "ChemicalTank") then
			PrintTermBottom(i .. ": Processing Chemical Tank");
			local category = "buffer"
			-- Content (sum)
			if(p.getStored ~= nil and p.getCapacity ~= nil) then
				local stored = p.getStored()
				local capacity = p.getCapacity()
				if(stored.amount ~= nil and stored.name ~= nil and capacity ~= nil) then
					local displayname = StripItemName(stored.name)
					UpdateTable(timestamp, displayname, stored.amount/1000, capacity/1000, category, "b", GetColorForFluidName(displayname)); -- @TODO MAX
				end
			end
		end

		--  Evaporation Plant
		if (pType == "thermalEvaporationValve") then
			PrintTermBottom(i .. ": Processing Thermal Evaporation Plant Valve");
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
					UpdateTable(timestamp, inputName, inputAmount/1000, inputCapacity/1000, category, "b", inputColor)

					-- input heating (average)
					if(p.getTemperature ~= nil) then
						local temperature = p.getTemperature()
						local tempCapacity = 3000 -- TODO exact limit needed depends on height? and fluid???
						if(temperature ~= nil and tempCapacity ~= nil) then
							UpdateTable(timestamp, inputName .. " heating temperature", temperature, tempCapacity, category, "^C", inputColor)
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
							UpdateTable(timestamp, productionName .. " production", productionAmount/1000, productionCapacity/1000, category, "b", productionColor)
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
					UpdateTable(timestamp, outputName, outputAmount/1000, outputCapacity/1000, category, "b", GetColorForFluidName(outputName));
				end
			end
		end

		-- Solar Neutron Activator
		if (pType == "solarNeutronActivator") then
			PrintTermBottom(i .. ": Processing Solar Neutron Activator");
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
					UpdateTable(timestamp, inputName, inputAmount/1000, inputCapacity/1000, category, "b", inputColor)

					-- output Production (sum), get this from input and invert it because output will probably be empty at some point.
					if(p.getProductionRate ~= nil and p.getPeakProductionRate ~= nil) then
						local productionAmount = p.getProductionRate()
						local productionCapacity = p.getPeakProductionRate()
						local productionName = "tritium" -- default (lithium -> tritium), other would be nulear waste, which doesnt make sense here.

						if(productionAmount ~= nil and productionName ~= nil and productionCapacity ~= nil) then
							local productionColor = GetColorForFluidName(productionName)
							UpdateTable(timestamp, productionName .. " production", productionAmount/1000, productionCapacity/1000, category, "b", productionColor)
						end

					end
				end
			end
			-- Output (sum) -> assume as buffer
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
					UpdateTable(timestamp, outputName, outputAmount/1000, outputCapacity/1000, "buffer", "b", GetColorForFluidName(outputName));
				end
			end
		end


		if (pType == "fusionReactorLogicAdapter") then
			PrintTermBottom(i .. ": Processing Fusion Reactor Logic Adapter");
			local category = "fusion";
			if(p.getDTFuel ~= nil) then
				local dtFuelData = p.getDTFuel();
				if (dtFuelData ~= nil) then
					UpdateTable(timestamp, "d-t fuel", dtFuelData.amount/1000, 1, category, "b", colorMap.d_t_fuel);
				end
			end
			if (p.getInjectionRate ~= nil) then
				local injectionRate = p.getInjectionRate();
				if (injectionRate ~= nil) then
					UpdateTable(timestamp, "injection rate", injectionRate/1000, 99/1000, category, "b", colorMap.d_t_fuel);
				end
			end
			if (p.getProductionRate ~= nil) then
				local productionRate = p.getProductionRate();
				if (productionRate ~= nil) then
					UpdateTable(timestamp, "steam production", productionRate/1000, productionRate/1000, category, "b", colorMap.steam);
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
					UpdateTable(timestamp, "steam", steamAmount/1000, steamCapacity/1000, category, "b", colorMap.steam);
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
					UpdateTable(timestamp, "water", waterAmount/1000, waterCapacity/1000, category, "b", colorMap.water);
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
					UpdateTable(timestamp, "deuterium", deuteriumAmount/1000, deuteriumCapacity/1000, "buffer", "b", colorMap.deuterium);
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
					UpdateTable(timestamp, "tritium", tritiumAmount/1000, tritiumCapacity/1000, "buffer", "b", colorMap.tritium);
				end
			end
		end

		if(pType == "fusionReactorPort") then
			PrintTermBottom(i .. ": Processing Fusion Reactor Port");
			local category = "fusion";

			if (p.getEnergy ~= nil and p.getMaxEnergy ~= nil) then
				local energy = p.getEnergy();
				local maxEnergy = p.getMaxEnergy();
				if(energy ~= nil and maxEnergy ~= nil) then
					UpdateTable(timestamp, "energy", energy, maxEnergy, category, "FE", colorMap.energy);
				end
			end
		end

		if (pType == "turbineValve") then
			local category = "turbine";
			PrintTermBottom(i .. ": Processing Steam Turbine");

			if(p.getFlowRate ~= nil and p.getMaxFlowRate ~= nil) then
				local turbineFlowRate = p.getFlowRate();
				local maxFlowRate = p.getMaxFlowRate();
				if (turbineFlowRate ~= nil and maxFlowRate ~= nil) then
					UpdateTable(timestamp,"steam flow rate", turbineFlowRate/1000, maxFlowRate/1000, category, "b", colorMap.steam);
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
					UpdateTable(timestamp, "steam", steamAmount/1000, steamCapacity/1000, category, "b", colorMap.steam);
				end
			end

			if (p.getProductionRate ~= nil and p.getMaxProduction ~= nil) then
				local productionRate = p.getProductionRate();
				local maxProduction = p.getMaxProduction();
				if (productionRate ~= nil and maxProduction ~= nil) then
					UpdateTable(timestamp,"energy production", productionRate, maxProduction, category, "FE", colorMap.energy);
				end
			end

			if (p.getEnergy ~= nil and p.getMaxEnergy ~= nil) then
				local energy = p.getEnergy();
				local maxEnergy = p.getMaxEnergy();
				if(energy ~= nil and maxEnergy ~= nil) then
					UpdateTable(timestamp, "energy", energy, maxEnergy, category, "FE", colorMap.energy);
				end
			end
		end
	end
end

function UpdateMonitor(mon, stateChar)
	PrintTermBottom("Updating monitor.");

	mon.setBackgroundColor(backgroundColor)
	mon.clear()
	CurLine = 1
	if(printVersion) then
		mon.setTextColor(colors.white)
		WriteMonitorCenter(mon, stateChar .. " " .. VersionInfo .. " " .. stateChar, 1)
		CurLine = 2
	end

	-- process categories and items downward, skipping empty ones.
	for i,layout in pairs(ContentLayout) do
		local strCategory = layout.key;
		local printedItems = false;
		if(printCategories) then
			PrintMonitorCategory(mon, layout.text)
		end
		for j,strName in pairs(layout.items) do

			local legend = nil
			local color = nil
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

		if(not printedItems and not IsCliMode) then
			PrintMonitorCategoryEmpty(mon)
		end
	end
end

function PrintTermCenter(text, y)
	local TermWidth, _ = term.getSize() -- Get the width of the monitor
	term.setCursorPos(1, y)
	term.write(string.rep(" ", TermWidth)) -- do a extra fill-pass
	term.setCursorPos(math.floor((TermWidth-#text)/2), y) -- now write text to center
	term.write(text)
end

function PrintTermBottom(text)
	if(IsCliMode) then
		return -- dont print update msgs in cli mode
	end
	local TermWidth, TermHeight = term.getSize()
	term.setCursorPos(1, TermHeight)
	term.write(string.rep(" ", TermWidth)) -- do a extra fill-pass
	term.setCursorPos(1, TermHeight)
	term.write("> " .. text)
end

function GetTableSize(t)
	local count = 0
	for _, __ in pairs(t) do
		count = count + 1
	end
	return count
end

function CheckMonitorSize(mon)
	local dataLen = 10
	local longestLine = dataLen
	local lineCount = 1
	for i,layout in pairs(ContentLayout) do
		lineCount = lineCount + 1 + linesBetweenCategories
		for j, itm in pairs(layout.items) do
			lineCount = lineCount + 1
			local sLen = string.len(itm) + dataLen
			if (sLen > longestLine) then
				longestLine = sLen
			end
		end
	end
	local scaledLines = math.ceil(lineCount * setTextScale)
	local scaledWidth = math.ceil(longestLine * setTextScale)
	local screenWidth, screenHeight = mon.getSize()
	if(scaledLines > screenHeight) then
		print("WARNING: Monitor height: " .. scaledLines .. " > " .. screenHeight)
		sleep(7)
	end
	if(scaledWidth > screenWidth) then
		print("WARNING: Monitor width: " .. scaledWidth .. " > " .. screenWidth)
		sleep(7)
	end
end

-- ======== MAIN SECTION ========

print("Starting: " .. VersionInfo);
print("UID:      " .. uid);

if(IsCliMode) then
	print("Not a Transmitter and not a Monitor.")
	print("Running in CLI mode.")
	sleep(5)
	CheckMonitorSize(term)
end

local monitor = nil;
local modem = nil;
local peripherals = nil;

function ConfigurePeripherals(checkSize)
	if(isDisplay) then
		monitor = GetMonitor()
		PrepareMonitor(monitor)
		if(checkSize ~= nil) then
			CheckMonitorSize(monitor)
		end
	end
	if(isReceiver or isTransmitter) then
		modem = GetWirelessModem();
		modem.open(wirelessChannel);
	end

	peripherals = peripheral.getNames()
	if(not IsCliMode) then
		term.clear()
		term.setCursorPos(1,1)
		PrintTermCenter("Running " .. VersionInfo, 1)
		term.setCursorPos(1,3)
		print("Is Display:   " .. tostring(isDisplay))
		print("Is Sender:    " .. tostring(isTransmitter))
		print("Is Receiver:  " .. tostring(isReceiver))
		print("Channel:      " .. wirelessChannel)
		print("Peripherals:  " .. #peripherals)
		print("Data sources: " .. (GetTableSize(ContentData)))
		print("Heartbeat:    ")
		PrintTermBottom("Updated peripherals.")
	end
end

ConfigurePeripherals(true);

-- Perform Initial Collection and Update the Monitor if given
if monitor then
	UpdateMonitor(monitor, "+");
elseif IsCliMode then
	UpdateMonitor(term, "+")
end
CollectLocalData();
if monitor then
	UpdateMonitor(monitor, "#");
elseif IsCliMode then
	UpdateMonitor(term, "+")
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
	if(not IsCliMode) then
		term.setCursorPos(15,9)
		term.write(heartChar)
	end

	local event, param1, param2, param3, param4, param5 = os.pullEvent();
	if (event == "timer") then
		if (param1 == timerUpdate) then
			CollectLocalData();
			if (modem) then
				if (isTransmitter) then
					modem.transmit(wirelessChannel,1,ContentData);
					PrintTermBottom("Transmitted data.")
				end
			end
			if monitor then
				UpdateMonitor(monitor, heartChar);
			elseif IsCliMode then
				UpdateMonitor(term, heartChar)
			end
			wirelessEventCount = 0;
			timerUpdate = os.startTimer(UpdateIntervalSeconds);
		end
	end

	if (event == "modem_message") then
		if (isReceiver == true) then
			wirelessEventCount = wirelessEventCount + 1;
			for extId,data in pairs(param4) do
				local isNew = ContentData[extId] ~= nil;
				if (extId ~= uid and data ~= nil) then
					ContentData[extId] = data;
					if (isNew) then
						ConfigurePeripherals()
					end
					PrintTermBottom("Received data from: "..extId);
				end
			end
			if (wirelessEventCount >= 10) then
				timerUpdate = os.startTimer(1);
			end
		end
	end

	if (event == "monitor_touch") or (event == "monitor_resize") then
		if monitor then
			PrintTermBottom("Updating monitor.");
			UpdateMonitor(monitor, heartChar);
		elseif IsCliMode then
			UpdateMonitor(term, heartChar)
		end
	end

	if (event == "peripheral") or (event == "peripheral_detach") then
		PrintTermBottom("Updating peripherals.");
		ConfigurePeripherals();
	end

	-- remove old data
	if(ContentData ~= nil) then
		local removeBefore = (os.epoch("local") / 1000) - RemoveOldDataAfterSec
		for id in pairs(ContentData) do
			local sortedTimestamps = {}
			for timestamp in pairs(ContentData[id]) do
				if(timestamp / 1000 >= removeBefore) then
					table.insert(sortedTimestamps, timestamp)
				else
					ContentData[id][timestamp] = nil -- network device timeout
				end
			end
			table.sort(sortedTimestamps)
			local latest = nil
			for j = table.maxn(sortedTimestamps), 1, -1 do
				if latest == nil then
					latest = sortedTimestamps[j]
				else
					ContentData[id][sortedTimestamps[j]] = nil -- not the latest data
				end
			end
			if(next(ContentData[id]) == nil) then
				ContentData[id] = nil -- device has no data
			end
		end
	end
end