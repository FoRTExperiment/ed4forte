Prescribing disturbance treatments in ED2
================

# Event files

The most straightforward, albeit somewhat inflexible, way to prescribe disturbances in ED2 is through "Events" ([ED2 wiki link][edwiki-events]).
Briefly, the ED2IN variable `EVENT_FILE` may point to an XML file that describes the kind (e.g. fertilization, till, irrigation, harvest) of event, when it takes place, and (depending on the event type) some additional parameters.
An example event file is included in the [unit tests](../tests/testthat/test-data/events.xml) for `ed4forte`, and is reproduced below:

[edwiki-events]: https://github.com/EDmodel/ED2/wiki/Event-files

```
<?xml version="1.0"?>
<!DOCTYPE config SYSTEM "ed_event.dtd">
<eventlist>
  <event>
    <year> 2004 </year>
    <doy> 187 </doy>
    <harvest>
      <agb_frac> 0.1 </agb_frac>
      <bgb_frac> 0.1 </bgb_frac>
      <fol_frac> 0.1 </fol_frac>
      <stor_frac> 0.1 </stor_frac>
    </harvest>
  </event>
</eventlist>
```

This indicates that a harvest will take place on the day 187 of 2004 (July 5, 2004) that will remove 10% of all above- (`agb_frac`), belowground (`bgb_frac`), foliar, (`fol_frac`), and storage (`stor_frac`) biomass.
This will be applied proportionally to _all_ patches and plant functional types.

When prescribing multiple events, each event has to have its own tag.
So, three harvests (a small one in 2004, followed by two larger ones in 2005) would look something like:

```
<?xml version="1.0"?>
<!DOCTYPE config SYSTEM "ed_event.dtd">
<eventlist>
  <event>
    <year> 2004 </year>
    <doy> 187 </doy>
    <harvest>
      <agb_frac> 0.1 </agb_frac>
      <bgb_frac> 0.1 </bgb_frac>
      <fol_frac> 0.1 </fol_frac>
      <stor_frac> 0.1 </stor_frac>
    </harvest>
  </event>
  <event>
    <year> 2005 </year>
    <doy> 162 </doy>
    <harvest>
      <agb_frac> 0.2 </agb_frac>
      <bgb_frac> 0.05 </bgb_frac>
      <fol_frac> 0.2 </fol_frac>
      <stor_frac> 0.1 </stor_frac>
    </harvest>
  </event>
  <event>
    <year> 2005 </year>
    <doy> 195 </doy>
    <harvest>
      <agb_frac> 0.4 </agb_frac>
      <bgb_frac> 0.1 </bgb_frac>
      <fol_frac> 0.2 </fol_frac>
      <stor_frac> 0.6 </stor_frac>
    </harvest>
  </event>
</eventlist>
```

# Land use drivers

A more comprehensive approach to prescribing land use is via a land use transition matrix, which is described in the [ED2 wiki][edwiki-lumatrix].

[edwiki-lumatrix]: https://github.com/EDmodel/ED2/wiki/Drivers#Land_use_and_plantation_rotation

# Modifying initial condition files

Probably the best balance between flexibility and complexity.
The general approach is as follows:

- Run ED2 up to the disturbance date
- Pull out the variables necessary for the vegetation (and site) initial condition files ([`ed4forte` docs](03-initial-conditions.md); [ED2 wiki](edwiki-initial-conditions)).
- Create new initial condition files using as much information from ED2 as you can pull out (in particular, including soil water and nutrient conditions).
    - The goal here is to preserve as much ED2 information from the pre-disturbance state as possible, to emulate the fact that you are actually continuing a previous ED2 run (rather than starting a new one from a different baseline).
- Modify these new initial condition files based on the disturbance you are trying to simulate.
- Re-start ED2 form the day of the disturbance, pointing it to the new initial condition files.

[edwiki-initial-conditions]: https://github.com/EDmodel/ED2/wiki/Initial-conditions


# Modifying restart files

By far the most difficult, but also most flexible, approach is to modify ED2 run restart files.
This basically guarantees continuity between the pre- and post-disturbance states; however, the cost
The general approach is as follows:

- Set up ED2 to write out "history" files (in the ED2IN, `ISOUTPUT = 3`). Also, pay attention to the `FRQSTATE` and `UNITSTATE` settings, which determine how frequently these files are generated. If you want a disturbance to take place on a specific date, you will have to make ED2 spit these out daily (`UNITSTATE = 1`, `FRQSTATE = 1`).
- Run ED2 through the date of the disturbance event.
- In R, read in the history file corresponding to the last run day (day of the disturbance), modify the variables corresponding to the disturbance (e.g. C storage pools, etc.), and write out a new file.
    - NOTE: Confusingly, although ED2 does not actually use everything in the history file -- in fact, after reading the history file, it re-derives a lot of the derived quantities in the history file, so changes to them are effectively ignored.
    You will have to look carefully at the ED2 initialization source code to understand which variables are re-derived and which are used directly.
    Any variables that are read directly can be passed directly to the history file.
    However, for variables that are not read directly, you will have to see how they are derived and back-calculate accordingly.
    For instance, leaf area index (LAI) is a derived quantity that is calculated using an allometric equation with leaf biomass (`bleaf`), stem diameter (`dbh`), and PFT-specific parameters.
    So to prescribe a change, you will have to extract the target cohort's DBH and PFT-specific leaf allometry parameters and then solve for the target leaf biomass, which is what you will end up setting.
- Once you've modified the history file accordingly, save it to a new location and start a new ED2 run from the date of the disturbance with ED2IN `RUNTYPE = 'HISTORY'` and `SFILIN = /path/to/history/prefix`.
ED2 should try to initialize itself from the new history files you created.
