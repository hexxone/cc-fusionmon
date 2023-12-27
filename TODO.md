
I want to write a ComputerCraft - Mekanism Fusion Reactor Monitoring Script.
The software should be able to gather Information about the plant, transmit it, receive it, and show it on a Monitor.
There should be a boolean "hasMonitor" and "isTransmitter" and "isReceiver" which are responsible for configuring this.
Gathered information will have an name, amount, max, category and a color.
The gathered Plant data should be stored in a table like this:
{
	data: {
		0: { name: "Water Amount", count: 1024, max: 2048, category: "Lithium", color: "cyan", legend: "b" },
		1: { name: "Brine Production": count: 64, max: 64, category: "Lithium", color: "brown", legend: "b" },
		2: { name: "Brine Amount", count: 128, max: 256, category: "Lithium", color: "brown", legend: "b" },
		3: { name: "Lithium Production": count: 16, max: 16, category: "Lithium", color: "yellow", legend: "b" }
	},
	warnings: [ "", "" ]
}

it is important that this data is getting aggreated (summed together) if there are multiple entries for the same name, category and color.

# UI Layout

- Header Bar gray with White Text (is centered)
- centered Plant Name Bar
- Plant Name Background gray with LightGray text
- Fill whole Screen Background with lightgray
- Text Color always Black ?? Except too Dark BG -> White
- show warning in console if screen is too small?

Show the following Texts below each other:

## Tritium Plant

- (!) Water = Cyan        		(Evap Plant Max Capacity)
- (%) Brine Production Rate = Brown     (Evap Plant Max Rate)
- (%) Brine Amount = Brown		(Evap Plant Max Capacity)
- ($) Lithium Production Rate = Yellow  (Evap Plant Max Rate)
- ($) Lithium Amount = Yellow           (Tank MaxCapacity)
- (+) Tritium Production Rate = green   (from connected Solar Neutron Activators)

- CALCULATED TRITIUM MAX RATE: minimum of maximum (Brine Prod Rate[TEP], Lithium Prod Rate[TEP], Tritium Prod Rate[SNA])

## Input Buffers

- (*) Deuterium = red      (Tank MaxCapacity)
- (+) Tritium = green      (Tank MaxCapacity)  

- WARN IF Tritium  BUFFER SIZE IS TOO SMALL FOR TRITIUM PRODUCTION RATE and INJECTION RATES

The game normally runs at a fixed rate of 20 ticks per second, so one tick happens every 0.05 seconds (50 milliseconds), making an in-game day last exactly 24000 ticks, or 20 minutes.
The Solar Neutron Activators are only running with sunlight, half the time of the day.
So the Tritium Buffer size needs to be at least (24000 / 2 * (INJ Rate + D-T Fuel Rate))


## Fusion Reactor

- (~) D-T Fuel = Purple     	(Required DT-Fuel (max something like 9500 mb, dependant on INJ rate?))
- (~) Fusion Rate = Purple   	(Max Rate = 99)
- (!) Water = Cyan        	(Max = Reactor Max Capacity)
- (#) Steam Production = Gray 	(Max Rate = fromTemp?)

- WARN IF ((INJECTION RATE + D-T FUEL Rate) > (Calculated Tritium Max Rate / 2)) -> INJECTION RATE TOO HIGH
- WARN IF REACTOR WATER IS LOW (<50%)
- WARN IF REACTOR IS INACTIVE ( OFF )

## Generator Turbine 

- (#) Steam Flow Rate = Gray       (Max Rate = from Building)
- (=) Energy Production = orange   (Max Rate = from Building)
- (=) Energy = orange              (Max Rate = from Building)