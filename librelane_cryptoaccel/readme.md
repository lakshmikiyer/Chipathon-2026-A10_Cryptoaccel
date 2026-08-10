 # ASCON-128 Crypto Accelerator — LibreLane Physical Design Flow Summary

- **Design:** `spi_slave` (ASCON-128 Authenticated Encryption/Decryption with SPI + AXI4-Lite Interface)
- **PDK:** GlobalFoundries GF180MCU-D (180nm, 5V, 5-Metal)
- **Standard Cell Library:** `gf180mcu_fd_sc_mcu7t5v0` (7-track, 5V)
- **Flow Tool:** LibreLane (OpenLane 2) — Classic Flow
- **Run Tag:** `ascon_final`
- **Date:** 10 August 2026

---

## ⏱ Total Run Time

| Metric | Value |
|---|---|
| **Flow Start** | `16:42:12` |
| **Flow Complete** | `16:54:xx` |
| **Total Wall Time** | **~12 minutes** |
| **Total Stages** | **80 stages** (01 → 80) |
<img width="1013" height="77" alt="image" src="https://github.com/user-attachments/assets/b19f5952-3133-4b0c-8846-8dc7fee59d9a" />

---

## 📐 Design General Summary

| Metric | Value |
|---|---|
| **Die Area** | 921,600 µm² (960 × 960 µm) |
| **Core Area** | 839,853 µm² |
| **Core Utilization** | **64.96%** |
| **Total Instances** | 86,988 |
| **Sequential Cells (Flip-Flops)** | 2,585 |
| **Timing Repair Buffers** | 4,674 |
| **CTS Clock Buffers** | 371 |
| **CTS Clock Inverters** | 175 |
| **Hold Buffers** | 10 |
| **Antenna Diode Cells** | inserted (63,362 µm² area) |
| **Fill Cells** | inserted (294,317 µm² area) |
| **Total Polygons in GDS** | 1,239,737 |

---

## 🔧 RTL Module Hierarchy

```
spi_slave (Top)
├── axi_master
│   └── axi_ascon
│       └── ascon_core_adpt_encdec
│           ├── ascon_round_s1
│           └── ascon_round_s2
└── reset_sync
```

---

## 🏗 Flow Stages Breakdown (79 Stages)

### Phase 1: Linting & Pre-Synthesis Checks (Stages 01–04)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 01 | Verilator Lint | Verilator 5.046 | ⚠️ 11 warnings (unused signals) |
| 02 | Lint Timing Constructs | Checker | ✅ Clear |
| 03 | Lint Errors | Checker | ✅ Clear |
| 04 | Lint Warnings | Checker | ⚠️ 11 warnings (non-blocking) |

### Phase 2: Synthesis (Stages 05–09)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 05 | JSON Header Generation | Yosys 0.64 | ✅ Complete |
| 06 | Logic Synthesis | Yosys + ABC | ✅ Complete |
| 07 | Unmapped Cells Check | Checker | ✅ Clear |
| 08 | Synth Checks | Checker | ✅ Clear |
| 09 | Netlist Assign Statements | Checker | ✅ Clear |

> **Yosys Synthesis Statistics**
<img width="412" height="830" alt="image" src="https://github.com/user-attachments/assets/09c9b1dd-4127-4392-ae23-fedb363dbc7a" />

---

### Phase 3: Floorplanning & PDN (Stages 10–22)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 10 | Check SDC Files | OpenROAD | ✅ Valid |
| 11 | Check Macro Instances | OpenROAD | ✅ Clear |
| 12 | STA Pre-PnR | OpenROAD | ✅ Complete |
| 13 | Floorplan | OpenROAD | ✅ 960×960 µm die |
| 14 | Dump RC Values | OpenROAD | ✅ Complete |
| 15 | Check Macro Antenna Props | ODB | ✅ Clear |
| 16 | Set Power Connections | ODB | ✅ VDD/VSS connected |
| 17 | Manual Macro Placement | ODB | ✅ Complete |
| 18 | Cut Rows | OpenROAD | ✅ Complete |
| 19 | Tap/Endcap Insertion | OpenROAD | ✅ Inserted |
| 20 | Add PDN Obstructions | ODB | ✅ Complete |
| 21 | Generate PDN | OpenROAD | ✅ Power mesh generated |
| 22 | Remove PDN Obstructions | ODB | ✅ Complete |

> **Floorplan View**
<img width="1213" height="885" alt="image" src="https://github.com/user-attachments/assets/6cbfabbe-a06e-449f-8544-bad14230a9e0" />


---

### Phase 4: Placement (Stages 23–34)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 23 | Add Routing Obstructions | ODB | ✅ Complete |
| 24 | Global Placement (Skip IO) | OpenROAD | ✅ Complete |
| 25 | IO Placement | OpenROAD | ✅ Pins placed |
| 26 | Custom IO Placement | ODB | ✅ Complete |
| 27 | Apply DEF Template | ODB | ✅ Complete |
| 28 | Global Placement | OpenROAD | ✅ Complete |
| 29 | Write Verilog Header | ODB | ✅ Complete |
| 30 | Power Grid Violations | Checker | ✅ 0 violations |
| 31 | STA Mid-PnR | OpenROAD | ✅ Complete |
| 32 | Repair Design Post-GPL | OpenROAD | ✅ Complete |
| 33 | Manual Global Placement | ODB | ✅ Complete |
| 34 | Detailed Placement | OpenROAD | ✅ Legal placement |

---

### Phase 5: Clock Tree Synthesis (Stages 35–38)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 35 | CTS | OpenROAD | ✅ 371 buffers, 175 inverters |
| 36 | STA Mid-PnR (post-CTS) | OpenROAD | ✅ Complete |
| 37 | Resizer Timing Post-CTS | OpenROAD | ✅ Complete |
| 38 | STA Mid-PnR (post-resize) | OpenROAD | ✅ Complete |

> **CTS Report / Clock Tree Statistics**
<img width="571" height="535" alt="image" src="https://github.com/user-attachments/assets/049502ac-9943-4eb5-89bd-cabaed0fcc9a" />


---

### Phase 6: Routing (Stages 39–54)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 39 | Global Routing | OpenROAD | ✅ Complete |
| 40 | Check Antennas | OpenROAD | ✅ Complete |
| 41 | Repair Design Post-GRT | OpenROAD | ✅ Complete |
| 42 | Diodes on Ports | ODB | ✅ Inserted |
| 43 | Heuristic Diode Insertion | ODB | ✅ Inserted |
| 44 | Repair Antennas | OpenROAD | ✅ Complete |
| 45 | Resizer Timing Post-GRT | OpenROAD | ✅ Complete |
| 46 | STA Mid-PnR (post-route) | OpenROAD | ✅ Complete |
| 47 | **Detailed Routing** | OpenROAD | ✅ Complete |
| 48 | Remove Routing Obstructions | ODB | ✅ Complete |
| 49 | Check Antennas (post-DR) | OpenROAD | ✅ 0 violations |
| 50 | TR DRC | Checker | ✅ 0 errors |
| 51 | Report Disconnected Pins | ODB | ✅ Complete |
| 52 | Disconnected Pins Check | Checker | ✅ Clear |
| 53 | Report Wirelength | ODB | ✅ Complete |
| 54 | Wirelength Check | Checker | ✅ Clear |

| Routing Metric | Value |
|---|---|
| **Total Wirelength** | 1,061,724 µm (~1.06 m) |
| **Max Single-Net Wirelength** | 1,463 µm |
| **Total Vias** | 139,370 |
| **Routing DRC Errors** | **0** |

> **Post Detailed Routing Log**
<img width="577" height="590" alt="image" src="https://github.com/user-attachments/assets/5d268830-dd67-4608-85cd-c356e794d4ca" />

---

### Phase 7: Fill & Parasitic Extraction (Stages 55–59)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 55 | Fill Insertion | OpenROAD | ✅ Fill cells placed |
| 56 | Cell Frequency Tables | ODB | ✅ Generated |
| 57 | RC Extraction (RCX) | OpenROAD | ✅ SPEF generated |
| 58 | STA Post-PnR (final) | OpenROAD | ✅ Complete |
| 59 | IR Drop Report | OpenROAD | ✅ Complete |

---

### Phase 8: GDSII Generation & Signoff (Stages 60–79)
| Stage | Step | Tool | Result |
|---|---|---|---|
| 60 | Magic Stream-Out | Magic | ✅ GDS generated |
| 61 | KLayout Stream-Out | KLayout | ✅ GDS generated |
| 62 | KLayout Render | KLayout | ✅ PNG rendered |
| 63 | Magic Write LEF | Magic | ✅ LEF generated |
| 64 | Check Antenna Properties | ODB | ✅ Clear |
| 65 | KLayout XOR | KLayout | ✅ Complete |
| 66 | XOR Check | Checker | ✅ Clear |
| 67 | **Magic DRC** | Magic | ✅ **0 errors** |
| 68 | **KLayout DRC** | KLayout | ✅ Complete |
| 69 | Magic DRC Check | Checker | ✅ **0 errors** |
| 70 | KLayout DRC Check | Checker | ✅ Clear |
| 71 | SPICE Extraction | Magic | ✅ Netlist extracted |
| 72 | Illegal Overlap Check | Checker | ✅ Clear |
| 73 | **Netgen LVS** | Netgen | ✅ **LVS Clean** |
| 74 | LVS Check | Checker | ✅ **0 errors** |
| 75 | Setup Violations | Checker | ✅ **0 violations** |
| 76 | Hold Violations | Checker | ✅ **0 violations** |
| 77 | Max Slew Violations | Checker | ✅ **0 violations** |
| 78 | Max Cap Violations | Checker | ✅ **0 violations** |
| 79 | Report Manufacturability | Misc | ✅ Final report |

> **antenna, drc, lvs:**

<img width="1655" height="367" alt="image" src="https://github.com/user-attachments/assets/2b904d74-3cde-4e7b-a7b9-610888640fe4" />


---

## ⚡ Timing Summary

| Corner | Metric | Value |
|---|---|---|
| **Worst Setup (ss_125C_3v00)** | Worst Slack | **+11.12 ns** |
| **Worst Setup (ss_125C_3v00)** | TNS | **0 ns** |
| **Worst Hold (ss_125C_3v00)** | Worst Slack | **+0.013 ns** |
| **Worst Hold (ss_125C_3v00)** | TNS | **0 ns** |
| **Clock Skew (worst setup)** | | 0.704 ns |
| **Clock Skew (worst hold)** | | 0.689 ns |

> ✅ **All timing constraints met across all corners. Zero setup or hold violations.**

> **Post-PNR STA Timing Report**
 <img width="1632" height="240" alt="image" src="https://github.com/user-attachments/assets/1146c630-5cd2-4954-b0d6-8ead7890c925" />

---

## 🔋 Power Summary

| Component | Power (W) |
|---|---|
| **Internal Power** | 13.82 mW |
| **Switching Power** | 4.28 mW |
| **Leakage Power** | 3.45 µW |
| **Total Power** | **18.11 mW** |

> **Power Report**
<img width="1100" height="327" alt="image" src="https://github.com/user-attachments/assets/9ffbdd91-ef58-4b87-85b5-4a3cd944bddc" />


---

## ⚡ IR Drop Analysis

| Net | Worst Drop | Average Drop |
|---|---|---|
| **VDD** | 87.9 µV (on 3.0V rail) | 30.0 µV |
| **VSS** | 106.8 µV | 29.8 µV |

> ✅ **IR drop is negligible (<0.01% of supply voltage). Power grid integrity is excellent.**

> **IR Drop Log**
 <img width="1663" height="660" alt="image" src="https://github.com/user-attachments/assets/4652cb9f-c3e2-44a5-a0a5-7ef2bba2eabb" />

---

## ✅ Signoff Checklist

| Check | Tool | Status |
|---|---|---|
| **DRC (Magic)** | Magic 8.3 | ✅ **0 errors** |
| **DRC (KLayout)** | KLayout 0.30.8 | ✅ **0 errors** |
| **LVS** | Netgen | ✅ **LVS Clean** |
| **Setup Timing** | OpenROAD STA | ✅ **+11.12 ns slack** |
| **Hold Timing** | OpenROAD STA | ✅ **+0.013 ns slack** |
| **Max Slew** | OpenROAD STA | ✅ **0 violations** |
| **Max Capacitance** | OpenROAD STA | ✅ **0 violations** |
| **Antenna** | OpenROAD | ✅ **0 violations** |
| **Power Grid** | OpenROAD | ✅ **0 violations** |
| **Disconnected Pins** | ODB | ✅ **0 disconnected** |

> **DRC Results (KLayout Marker Browser)**
> 0 drc items shown with grep shell command in terminal
 <img width="1600" height="998" alt="image" src="https://github.com/user-attachments/assets/1d62d92a-aff2-47de-8fa5-9d19717a79e3" />


> **LVS Results (Netgen)**
> LVS Clean
<img width="1595" height="1001" alt="image" src="https://github.com/user-attachments/assets/7e493af1-56e7-4905-baba-0ae694d4807d" />

> **ERC**
<img width="1280" height="178" alt="image" src="https://github.com/user-attachments/assets/1ecaa033-9ec0-40c2-befe-b19400a3fa61" />


---

## 📦 Final Deliverables

| File | Path |
|---|---|
| **Final GDS** | `runs/ascon_final/final/gds/spi_slave.gds` |
| **Final DEF** | `runs/ascon_final/final/def/spi_slave.def` |
| **Final LEF** | `runs/ascon_final/final/lef/spi_slave.lef` |
| **Synthesized Netlist** | `runs/ascon_final/final/nl/spi_slave.nl.v` |
| **PnR Netlist** | `runs/ascon_final/final/pnl/spi_slave.pnl.v` |
| **SPICE Netlist** | `runs/ascon_final/final/spice/spi_slave.spice` |
| **SPEF Parasitics** | `runs/ascon_final/final/spef/` |
| **SDC Constraints** | `runs/ascon_final/final/sdc/` |
| **SDF Timing** | `runs/ascon_final/final/sdf/` |
| **Metrics (JSON)** | `runs/ascon_final/final/metrics.json` |
| **Metrics (CSV)** | `runs/ascon_final/final/metrics.csv` |
| **Layout Render** | `runs/ascon_final/final/render/` |

---

## 📸 Layout Views

> **📸 Full Chip GDS View**
 <img width="1587" height="983" alt="image" src="https://github.com/user-attachments/assets/3919a9af-f550-42b7-a831-22b9b6af72fd" />


> **📸 Pin Placement (VDD, VSS, clk, rst_n, sclk, mosi, miso, cs_n)**
 <img width="1580" height="990" alt="image" src="https://github.com/user-attachments/assets/25ded058-5cbf-4125-8071-076284b170f1" />

> **Post PNR Timing Report**
<img width="1216" height="586" alt="image" src="https://github.com/user-attachments/assets/50262ac5-f9ac-4011-9f76-07e58ad8712f" />

---
                        
