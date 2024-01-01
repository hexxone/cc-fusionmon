# General TODOs

- fully rename to "Craftana"
- write errors to log file as well
- get max values for advanced peripherals tanks

- support induction matrix
- support SPS
- support mekanism multi-block tanks.
- support fission reactor?
- support boiler??

- use IP whitelist on traefik
- environment sensor -> is sun | storm ?
- open issue about Mekanism weirdness (case temp, activemode, outdated docs)
- online player count???

## UI

### Tritium Plant

- CALCULATE TRITIUM MAX RATE: minimum of maximum (Brine Prod Rate[TEP], Lithium Prod Rate[TEP], Tritium Prod Rate[SNA])

### Input Buffers

- WARN IF Tritium  BUFFER SIZE IS TOO SMALL FOR TRITIUM PRODUCTION RATE and INJECTION RATES

The game normally runs at a fixed rate of 20 ticks per second, so one tick happens every 0.05 seconds (50 milliseconds).
So an in-game day last exactly 24000 ticks, or 20 minutes.
The Solar Neutron Activators are only running with sunlight, so at max half the time of the day.
However, there might also be rain & storm, which means SNAs wont work either, maybe 15% of the time.
So the Tritium Buffer size needs to be at least `(24000 / 2 * 1.15 x (INJ_Rate + D_T_Fuel_Rate))`

### Fusion Reactor

- WARN IF ((INJECTION RATE + D-T FUEL Rate) > (Calculated Tritium Max Rate / 2)) -> INJECTION RATE TOO HIGH
- WARN IF REACTOR WATER IS LOW (<50%)
- WARN IF REACTOR IS INACTIVE ( OFF )

### Generator Turbine

- WARN IF FULL AND DUMPING IS DISABLED ??
