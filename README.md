# 🔒 Multi-Core AES-128 Hardware Accelerator (JOSDC 2025)

A high-throughput, highly scalable AES-128 cryptographic accelerator written in SystemVerilog. This project was developed by **Team Die Hard** as a competitive entry for the **Jordan Semiconductor Design Competition (JOSDC) 2025**. 

The repository documents the engineering evolution of the core across two distinct competition phases. It transitions from a baseline single-core ECB accelerator to a highly optimized, dual-core architecture supporting dynamic load allocation, 5 distinct cipher modes, and on-the-fly multi-keying.

---

## 🛠️ Hardware & Development Environment
* **Target FPGA:** Intel MAX 10 (`10M50DAF484C7G` / Terasic DE-10 Lite)
* **EDA Toolchain:** Intel Quartus Prime 20.1
* **System Clock:** 50 MHz
* **Language:** SystemVerilog
* **Software Interface:** Custom PC companion software ("Crypto Tool")

---

## 🚀 Key Features (Phase 2)
* **Dual-Core Processing:** Two independent AES-128 cores operating concurrently.
* **5 Cipher Modes Supported:** Fully implements **ECB, CTR, CBC, CFB, and OFB**. Modes can be switched dynamically on a per-packet basis.
* **Adaptive Load Allocation ("Two-Level Brain"):** A hierarchical FSM automatically detects the workload. If two streams are active, cores run independently. If a single stream is active, the router shares the single stream across both cores (round-robin) to double per-stream throughput.
* **On-the-Fly Rekeying:** Supports seamless mid-session key rotation, allowing the core to switch keys between packets without dropping data.
* **Quad-Core Ready Protocol:** The custom 19-byte packet structure uses a 2-bit Stream ID, allowing the architecture to scale to 4 independent cores natively.

---

## 🏆 Architectural Evolution

### Phase 1: Baseline Architecture
Phase 1 focuses on establishing a reliable datapath and a robust control infrastructure using a 1-stage iterative architecture.

* **Throughput:** ~581 Mbps theoretical (11 cycles per block).
* **Decoupled I/O Interface:** The UART communication module is strictly separated from the cryptographic core via asynchronous FIFOs, preventing the slow serial interface from bottlenecking the 50 MHz core logic.
* **Custom Packet System:** Developed a fixed 19-byte packet protocol (1-byte Header, 2-byte Sequence ID, 16-byte Payload) for deterministic parsing.

![Phase 1 Architecture](phase1_baseline/Phase_1_Architecture.png)
📄 **Documentation:** [Read the Phase 1 Technical Report](phase1_baseline/phase_1_technical_report.pdf)

---

### Phase 2: Optimized Multi-Core Architecture
Phase 2 represents a massive architectural overhaul designed for maximum throughput and operational flexibility, supported by the Python-based Crypto Tool GUI for seamless UART stream generation.

* **Hardware Efficiency:** Achieves a highly optimized **24 cycle packet latency** (~480ns per block).
* **Logic Utilization:** Efficiently packed into ~78% of the MAX 10 LUTs, retaining all advanced routing and FSM logic.
* **Throughput Capacity:** ~246 Mbps per core, delivering a combined theoretical throughput of **~532 Mbps** at 50 MHz.
* **Crypto Tool GUI:** A custom software driver that parses any file format, applies PKCS#7 padding, and manages Sequence IDs for automatic packet reordering upon decryption.

![Phase 2 Architecture](phase2_optimized/Phase_2_Architecture.png)
📄 **Documentation:** [Read the Phase 2 Technical Report](phase2_optimized/phase_2_technical_report.pdf)

---

## 📊 Performance & Benchmarks
Extensive hardware validation was performed against NIST Known-Answer Test (KAT) vectors. Across 50 individual sequence verifications covering all 5 modes, the core achieved a **100% pass rate** with zero bit errors.

| Metric | Phase 1 (Single Core) | Phase 2 (Dual Core) |
| :--- | :--- | :--- |
| **Datapath** | Iterative (11 cycles/block) | Iterative (24-26 cycles/packet) |
| **Max Theoretical Throughput** | ~581 Mbps | ~532 Mbps (Combined) |
| **UART Tested Throughput** | Interface Bound | ~37.85 KB/s @ 460800 baud |
| **Cipher Modes** | ECB | ECB, CTR, CBC, CFB, OFB |

> **Note:** The physical throughput is strictly limited by the UART serial baud rate. The internal dual-core architecture possesses the headroom to saturate much faster interfaces (e.g., USB 3.0 FIFO, PCIe DMA) with zero RTL redesign.
