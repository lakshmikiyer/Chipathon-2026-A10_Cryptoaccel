# A10_A — Integrated with DEF File

Design hardened against `A10_A.def`.

| Parameter | Value |
|---|---|
| **Design** | `A10_A` |
| **PDK / Library** | `gf180mcuD` / `gf180mcu_fd_sc_mcu7t5v0` |
| **Die** | 1110 × 1110 µm, from `A10_A.def` |
| **Clock Period** | 62.5 ns (16 MHz) |
| **Terminals** | 50 / 50 |
| **Flow** | LibreLane 3.0.2 |

---

## Signoff Summary

| Check | Status |
|---|---|
| Routing DRC | ✅ **PASS — 0 violations** |
| Magic DRC | ✅ **PASS — 0 violations** |
| LVS | ✅ **PASS** |
| XOR | ✅ **PASS — 0 differences** |
| Antenna | ✅ **PASS — 0 violations** |
| Power-grid connectivity | ✅ **PASS** |
| IR Drop | ✅ **PASS** |
| Setup Timing | ✅ **PASS** |
| Hold Timing | ✅ **PASS** |
| Max Slew | ⚠️ **61 violations in SS corner** |
| Disconnected Terminals | ⚠️ **1 non-critical terminal** |

---

## Design Status

The `A10_A` design has been hardened using `A10_A.def` as the physical template.

All major physical signoff checks are clear:

- **Routing DRC:** 0 violations
- **Magic DRC:** 0 violations
- **LVS:** Circuits match uniquely
- **XOR:** 0 differences between Magic and KLayout streamout
- **Antenna:** 0 net / 0 pin violations
- **Power-grid connectivity:** All VDD/VSS shapes connected
- **IR drop:** Within limits
- **Terminal count:** 50 / 50

The only remaining timing issue is **61 max-slew violations**, all occurring in the `max_ss_125C_3v00` corner.

These are **SDC timing-target violations**, not Liberty characterization failures.

---

## Physical Signoff

| Check | Result | Value |
|---|---|---:|
| **Die Size** | From `A10_A.def` | 1110 × 1110 µm |
| **Terminals** | Verified against template | 50 / 50 |
| **Routing DRC** | TritonRoute | **0** ✅ |
| **Magic DRC** | `drc(full)` from GDS | **0** ✅ |
| **LVS** | Netgen | **Clear** ✅ |
| **XOR** | Magic vs. KLayout streamout | **0** ✅ |
| **Antenna** | Net / pin violations | **0 / 0** ✅ |
| **Power-grid connectivity** | PSM | **0 violations** ✅ |
| **Disconnected terminals** | Non-critical | **1** ⚠️ |
| **Worst IR Drop — VDD** | — | 11.2 mV (0.37%) |
| **Worst IR Drop — VSS** | — | 12.4 mV (0.41%) |
| **Utilisation** | — | 47.61% |
| **Instances** | — | 74,585 |
| **Total Power** | `max_ss_125C_3v00` | 17.77 mW |

---

## Timing

**Clock Period:** 62.5 ns (16 MHz)

| Corner | Setup WS (ns) | Setup TNS (ns) | Hold WS (ns) | Hold TNS (ns) | Slew | Cap | Fanout |
|---|---:|---:|---:|---:|---:|---:|---:|
| `nom_tt_025C_3v30` | +35.095 | 0 | +0.554 | 0 | 0 | 0 | 0 |
| `max_ss_125C_3v00` | **+7.881** | 0 | +1.018 | 0 | **61** ⚠️ | 0 | 0 |
| `min_ff_n40C_3v60` | +46.533 | 0 | **+0.196** | 0 | 0 | 0 | 0 |

### Timing Summary

| Metric | Result |
|---|---:|
| **Worst Setup Slack** | +7.881 ns |
| **Worst Hold Slack** | +0.196 ns |
| **Setup TNS** | 0 ns |
| **Hold TNS** | 0 ns |
| **Max Slew Violations** | 61 |
| **Capacitance Violations** | 0 |
| **Fanout Violations** | 0 |

### Max-Slew Violations

All **61 max-slew violations** occur in the:

```text
max_ss_125C_3v00
