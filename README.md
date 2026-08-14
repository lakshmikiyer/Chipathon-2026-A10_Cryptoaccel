# SSCS_CHIPATHON_2026_CRYPTOACCEL
---
- Link to project proposal:  [Click Here ↗](https://docs.google.com/document/d/e/2PACX-1vQ7hXiJkHFsaxKhHVbuH3Zd8qZDoJdL6WpXG3n53tD7aNz_2QSCsUlUvai5AVLdPrBWiSDReBhnfogW/pub)
- Link to github issue: [Click Here ↗](https://github.com/sscs-ose/sscs-chipathon-2026/issues/44)
- Link to proposal round presentation video: [Click Here ↗](https://youtu.be/4pfbP2isbxA?si=O9V1pwiTxTNE5hqo)
- Link to schematic review round video: [Click Here ↗](https://drive.google.com/file/d/1Om1IALZSBtE1XGMmxLGU7RnFuSFpBlrm/view)
- Link to progress tracker: [Click Here ↗](https://github.com/lakshmikiyer/SSCS_CHIPATHON_2026_CRYPTOACCEL/blob/main/Progress%20Tracker/readme.md)
- Link to Layout review ppt: [Click Here ↗](https://drive.google.com/drive/folders/1AtdcmwkP5GPB7IbjtLGPZMGSWETwX3VG?usp=sharing)
- Link to Layout review video: [Click Here ↗](https://drive.google.com/drive/folders/1AtdcmwkP5GPB7IbjtLGPZMGSWETwX3VG?usp=sharing)
--- 
<img width="2352" height="480" alt="cryptoaccel_logo" src="https://github.com/user-attachments/assets/9e05458b-7662-42a9-9287-e7aeeaf4b6a3" style="width:70%;" />

# Team CryptoAccel: ASCON AEAD128a Cryptographic Hardware Accelerator
![Chipathon](https://img.shields.io/badge/IEEE_SSCS-PICO_Chipathon_2026-blue)
![Track](https://img.shields.io/badge/Track-A-orange)
![PDK](https://img.shields.io/badge/PDK-GF180MCU-green)
![Algorithm](https://img.shields.io/badge/Algorithm-ASCON--AEAD128a-purple)
![License](https://img.shields.io/badge/License-MIT-lightgrey)
![Status](https://img.shields.io/badge/Status-In_Progress-yellow)
![GitHub last commit](https://img.shields.io/github/last-commit/lakshmikiyer/SSCS_CHIPATHON_2026_CRYPTOACCEL)
 
---
## Overview

CryptoAccel team is proposing a lightweight hardware accelerator implementing the **ASCON-AEAD128a** authenticated encryption algorithm, standardized by NIST (SP 800-232). It is designed for resource-constrained applications such as IoT security, secure boot, and root-of-trust.

The accelerator is built in synthesizable Verilog and taken through a complete open-source RTL-to-GDSII flow using Open-source toolchain targeting the **GlobalFoundries 180nm (GF180MCU)** process.

This repository is the padring fork of Mauricio-xx/chipathon-2026-gf180mcu-padring (via wafer-space/gf180mcu-project-template), which adds a workshop slot mirroring JuanMoya/padring_gf180 as a native LibreLane slot. It contains the integrated chip-level design with padframe, the accelerator macro, and all LibreLane run outputs.

---
## Repository Structure

```
Chipathon-2026-A10_Cryptoaccel/
├── .github/                         
│   ├── actions/
│   │   ├── build_nix/               # Nix build action
│   │   └── setup_nix/               # Nix setup action
│   └── workflows/
│       └── ci.yml                   # CI pipeline
│
├── cocotb/                       
│   └── chip_top_tb.py
│
├── docs/                            # Documentation
│   ├── reproducing-docker.md        # Docker-based reproduction guide
│   ├── reproducing-native.md        # Native reproduction guide
│   └── workshop-slot-spec.md        # Workshop slot specification
│
├── examples/                        # Example notebooks
│   └── rtl2gds_chipathon_padring.ipynb
│
├── gds_Cryptoaccel/                 # GDS output files
│   ├── gds_dry_run/
│   │   ├── Readme.md
│   │   └── spi_slave.klayout.gds    # Dry run GDS (KLayout)
│   └── readme.md
│
├── ip/                              # Hard IP blocks 
│   ├── gf180mcu_ws_ip__id/          
│   │   ├── gds/
│   │   ├── lef/
│   │   ├── lib/
│   │   └── vh/
│   └── gf180mcu_ws_ip__logo/        
│       ├── gds/
│       ├── image/
│       ├── lef/
│       ├── lib/
│       ├── script/
│       └── vh/
│
├── librelane/                       # LibreLane padring integration config & runs
│   ├── chip_top.sdc                 # Top-level timing constraints
│   ├── config.yaml                  # LibreLane/OpenLane configuration
│   ├── pdn_cfg.tcl                  # Power distribution network config
│   ├── runs/                        # LibreLane run outputs
│   │   ├── chip_top.klayout.gds     # Final integrated GDS
│   │   ├── integration1.txt         # Integration run log
│   │   └── metrics.csv              # Run metrics
│   └── slots/                       # Slot definitions
│       ├── slot_0p5x0p5.yaml
│       ├── slot_0p5x1.yaml
│       ├── slot_1x0p5.yaml
│       ├── slot_1x1.yaml
│       └── slot_workshop.yaml       
│
├── librelane_cryptoaccel/           # CryptoAccel standalone LibreLane run results
│   ├── metrics.csv
│   ├── readme.md
│   └── run2_maxtran6_rerun.txt
│
├── macro/                           # Accelerator macro (spi_slave) collateral
│   ├── gds/
│   │   └── spi_slave.gds
│   ├── lef/
│   │   └── spi_slave.lef
│   ├── lib/                         # Lib timing models (PVT corners)
│   │   ├── max_ss_125C_3v00/
│   │   ├── min_ff_n40C_3v60/
│   │   └── nom_tt_025C_3v30/
│   ├── nl/                          # Gate-level netlists
│   │   ├── spi_slave.nl.v
│   │   └── spi_slave.pnl.v
│   ├── pnl/
│   │   └── spi_slave.pnl.v
│   ├── spef/                        # PEX
│   │   ├── max/
│   │   ├── min/
│   │   └── nom/
│   └── vh/
│       └── spi_slave.vh
│
├── scripts/                         # Utility scripts
│   ├── lay2img.py                   # Layout to image converter
│   ├── padring.py                   # Padring generation script
│   ├── run_docker_iic.sh            # Docker run script (IIC-OSIC)
│   ├── run_native.sh                # Native run script
│   └── verify_workshop_slot.sh      # Workshop slot verification
│
├── src/                             # Padring top-level RTL
│   ├── chip_core.sv                 # Chip core wrapper
│   ├── chip_top.sv                  # Top-level chip with padring
│   ├── pad_map.svh                  # Pad mapping definitions
│   └── slot_defines.svh             # Slot parameter definitions
│
├── src_cryptoaccel/                 # CryptoAccel RTL source & OpenLane config
│   ├── ascon_core_adpt_encdec.v     # ASCON core (enc/dec state machine)
│   ├── ascon_round_s1.v             # ASCON round stage 1
│   ├── ascon_round_s2.v             # ASCON round stage 2
│   ├── axi_ascon.v                  # AXI-Lite wrapper for ASCON
│   ├── axi_master.v                 # AXI master interface
│   ├── config_run2_maxtran6.yaml    # OpenLane run config
│   ├── constraints_run2_maxtran6.sdc # Timing constraints
│   ├── io.cfg                       # I/O configuration
│   ├── readme.md
│   ├── reset_sync.v                 # Reset synchronizer
│   └── spi_slave.v                  # SPI slave top module
│
├── AUTHORS.md                       
├── CREDITS.md                       
├── LICENSE                          # License file
├── Makefile                         # Build targets
├── NOTICE                           
├── README.md                        # This file
├── flake.lock                       
├── flake.nix                        
├── info.yaml                        # Project info (LibreLane/Chipathon metadata) for layout round
├── lvs_config.json                  # LVS configuration
└── shell.nix                        
```
<img width="2048" height="1473" alt="image" src="https://github.com/user-attachments/assets/420a6632-c3ed-4a0d-82ad-7331dc9077f0" style="width:50%;"/>

---
## Architecture & Design  

The design consists of three main blocks:

1. **ASCON Core (`ascon_core_adpt_encdec`)** — Implements the full ASCON-AEAD128a state machine: initialization, associated data processing, plaintext/ciphertext processing, finalization, and tag generation/verification. Supports both encryption and decryption modes.

2. **ASCON Round (`ascon_round`)** — A single purely combinational round of the ASCON permutation, comprising the round constant addition (pC), the 5-bit S-box layer (pS), and the linear diffusion layer (pL).

3. **AXI-Lite Wrapper (`ascon_axi_wrapper`)** — Provides a standard AXI4-Lite slave interface for system-level integration. A CPU or SoC master writes key, nonce, associated data, and plaintext through memory-mapped registers, and reads back ciphertext and the authentication tag.

<img width="1340" height="967" alt="image" src="https://github.com/user-attachments/assets/19bc8b5f-9126-45ad-8db6-b8464ad2b238" style="width:70%;"/>

---
## Design Verification -- ASCON CORE
Functional verification of the ASCON core Design Verification:
Two independent testbench approaches were used to maximize stimulus coverage:

- **Directed Verilog TB**: 7 hard-coded test cases — empty AD/PT, short and multi-block AD/PT, full encrypt→decrypt roundtrip, and a tampered-tag case that must be rejected (auth_ok=0).
- **Cocotb TB + Python golden model**: 5 categories — known-answer tests, 16-byte block-boundary edges, authentication fault-injection, 50 randomized vectors (0–256B) sweeping key/nonce/AD/PT, and 20 randomized encrypt-then-decrypt roundtrips.
- **NIST ACVP-based verification**: Following a suggestion from reviewer Luqman during the proposal review round, we incorporated NIST's Automated Cryptographic Validation Protocol (ACVP) vectors. Using the 1089 KATs from itzmeanjan/ascon, we re-ran verification against official NIST-based test vectors — all 1089 cases passed.
- **Result**: 100% pass, 0 fails across all test cases above; the same Verilog testbench was later reused for post-synthesis GLS.

`Full Documentation`:  https://github.com/lakshmikiyer/SSCS_CHIPATHON_2026_CRYPTOACCEL/tree/main/rtl_design_verif#verification-of-the-ascon-core

---
## Team

| Name              | Discord name  | Affiliation                       | Role         | Experience                            | Contribution                                                                          |
| ----------------- | ------------- | ---------------------------------- | ------------ | -------------------------------------- | -------------------------------------------------------------------------------------- |
| Lakshmi K Iyer    | lakvlsi_90908 | IIT, Bombay                        | Team Lead    | Ph.D. Research Scholar / Postgraduate  | RTL Core Design & Architecture + RTL Design of Interface + Team Management + Documentation and Presentations            |
| Yashvardhan Singh | zysteresis    | MIT, Manipal / STMicroelectronics  | Team Member  | Undergraduate (III)                    | Design Verification + Post-Synth Verification + PD via Librelane + Documentation + GitHub VCS and Docs |
| Tarun R S         | tarun_rs05    | IIIT, Bangalore                    | Team Member  | Undergraduate (II)                     | RTL Design + PD via ORFS                                                                |


---

## References
- [NIST SP 800-232 — ASCON Standard](https://csrc.nist.gov/pubs/sp/800/232/final)
- [ASCON Official Website](https://ascon.iaik.tugraz.at/)
- [OpenROAD Flow Scripts (ORFS)](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
- [OpenROAD Project](https://theopenroadproject.org)
- [GlobalFoundries GF180MCU PDK](https://github.com/google/gf180mcu-pdk)
- [IIC-OSIC-TOOLS: Open-Source IC Design Environment](https://github.com/iic-jku/IIC-OSIC-TOOLS)
- [Robert Primas — ASCON Hardware Repository](https://github.com/rprimas/ascon-verilog)
- [Side-Channel and Fault Resistant ASCON Implementation: A Detailed Hardware Evaluation](https://ieeexplore.ieee.org/document/10682712)
- [A Robust ASCON Cryptographic Coprocessor for Secure IoT Applications](https://ieeexplore.ieee.org/document/10497076)
- [Lightweight and Secure Hardware Implementations — MDPI Electronics](https://www.mdpi.com/2079-9292/13/22/4550)
- [Implementation of ASCON in C — Cihangir Tezcan (YouTube)](https://www.youtube.com/watch?v=RWiH_6UwzzY)
- [ASCON — Tiny Titan of IoT Security (Sage Khan, Medium)](https://thesagekhan.medium.com/ascon-the-tiny-titan-of-iot-security-a-deep-technical-dive-8273ab4786b6)
- [OpenTitan — ASCON Documentation](https://opentitan.org/book/hw/ip/ascon/index.html)
- [OpenTitan — EarlGrey and Darjeeling Product Architectures](https://opentitan.org/book/doc/productarchitecture.html)
- [Caliptra: A Datacenter SoC Root of Trust (RoT)](https://www.opencompute.org/documents/caliptra-silicon-rot-services-09012022-pdf)
- IEEE SSCS PICO Chipathon 2026 Guidelines — Contest rules, area limits, padding template
