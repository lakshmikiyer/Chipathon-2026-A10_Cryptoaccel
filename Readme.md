\# A10\_A — Integrated with def file



Design now hardens against `A10\_A.def`. 

| | |

|---|---|

| \*\*Design\*\* | `A10\_A` |

| \*\*PDK / library\*\* | `gf180mcuD` / `gf180mcu\_fd\_sc\_mcu7t5v0` |

| \*\*Die\*\* | 1110 × 1110 µm, from `A10\_A.def` |

| \*\*Clock\*\* | 62.5 ns (16 MHz) |

| \*\*Terminals\*\* | 50 / 50 |

| \*\*Flow\*\* | LibreLane 3.0.2 |



\*\*Status:\*\* DRC / LVS / XOR / antenna / power-grid clear · 
\*\*61 max-slew violations:\*\* ( All in the SS Corner, Verified- These are SDC-target hits, not liberty failures) 
\*\*One disconnected terminal:\*\* miso\_IN — the receiver output of the only output-only pad.
We drive miso\_IE = 0 on that pad, which disables its receiver, so the macro reads nothing back from it. 
The port exists to satisfy the DEF's terminal count and is deliberately left unconnected inside the wrapper. 
LibreLane classifies it as non-critical. All 47 other signal terminals and both power terminals are connected.





\## Signoff 





| Check | Result | Value |

|---|---|---|

| Die | 1110 × 1110 µm, from `A10\_A.def` | — |

| Terminals | 50 / 50, verified against the template | ✅ clear |

| Routing DRC | TritonRoute | \*\*0\*\* ✅ |

| Magic DRC | `drc(full)`, from GDS | \*\*0\*\* ✅ |

| LVS | netgen — \*circuits match uniquely\* | ✅ clear |

| XOR | Magic vs KLayout streamout | \*\*0\*\* ✅ |

| Antenna | 0 net / 0 pin violations | \*\*0\*\* ✅ |

| Power-grid connectivity | PSM — all shapes connected, both nets | \*\*0\*\* ✅ |

| Disconnected terminals | 1 total, 0 critical — \[section 3](#3-the-one-disconnected-terminal) | 1 (expected) |

| Worst IR drop | VDD 11.2 mV (0.37 %) · VSS 12.4 mV (0.41 %) | ✅ clear |

| Utilisation | 74,585 instances | 47.61 % |

| Total power | `max\_ss\_125C\_3v00` | 17.77 mW |



\### Timing — three corners, 62.5 ns period



| Corner | Setup WS | Setup TNS | Hold WS | Hold TNS | Slew | Cap | Fanout |

|---|---:|---:|---:|---:|---:|---:|---:|

| `nom\_tt\_025C\_3v30` | +35.095 | 0 | +0.554 | 0 | 0 | 0 | 0 |

| `max\_ss\_125C\_3v00` | \*\*+7.881\*\* | 0 | +1.018 | 0 | \*\*61\*\* ⚠️ | 0 | 0 |

| `min\_ff\_n40C\_3v60` | +46.533 | 0 | \*\*+0.196\*\* | 0 | 0 | 0 | 0 |







