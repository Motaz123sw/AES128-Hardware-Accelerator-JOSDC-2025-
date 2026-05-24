# 🔒 Multi-Core AES-128 Hardware Accelerator (JOSDC 2025)

A high-throughput, highly scalable AES-128 cryptographic accelerator written in SystemVerilog. This project was developed as a competitive entry for the **Jordan Open Source Design Competition (JOSDC) 2025**. 

The repository documents the engineering evolution of the core across two distinct competition phases, transitioning from a baseline single-core ECB accelerator to a highly optimized, dual-core architecture supporting dynamic load allocation, multiple cipher modes, and on-the-fly multi-keying.

---

## 🛠️ Hardware & Development Environment
* **Target FPGA:** Intel MAX 10 (`10M50DAF484C7G`)
* **EDA Toolchain:** Intel Quartus Prime 20.1
* **Language:** SystemVerilog
* **Software Interface:** Custom PC companion software (Phase 2)

---

## 🏆 Project Evolution & Architecture

### Phase 1: Baseline Architecture (Single-Core ECB)
Phase 1 focuses on establishing a reliable datapath and a robust control infrastructure. It implements standard AES-128 in Electronic Codebook (ECB) mode.

* **Custom Internal Packet System:** The core operates using a tailor-made packet structure. To successfully interface with this IP, developers **must** adhere to this packet protocol. (Detailed packet mapping is available in the Phase 1 Technical Report).
* **Decoupled I/O Interface:** The UART communication module is strictly separated from the cryptographic core via asynchronous FIFOs. This modularity allows the UART to be easily swapped out for higher-speed communication protocols (like PCIe or AXI4) without altering the core logic.

![Phase 1 Architecture](Phase_1_Architecture.jpg)
📄 **Documentation:** [Read the Phase 1 Technical Report](JOSDC_TECHNICAL_REPORT_1.pdf)

---

### Phase 2: Optimized Multi-Core Architecture
Phase 2 represents a massive architectural overhaul designed for maximum throughput and operational flexibility, supported by a custom software GUI for seamless UART stream generation.

* **Dual-Core Processing:** Features two independent AES-128 cores operating concurrently. 
* **Dynamic Load Allocation:** The hardware router dynamically allocates data packets across available cores. You can mix and match data streams requiring different operation modes (Encryption vs. Decryption) simultaneously.
* **Comprehensive Cipher Modes:** Fully supports ECB, CBC, OFB, and CTR modes.
* **On-the-Fly Multi-Keying:** The design supports two entirely separate data streams (scalable to four), each capable of maintaining and switching its own cryptographic keys dynamically without stalling the pipeline.
* **Scalability vs. Hardware Limits:** The updated Phase 2 packet system was engineered to support a **Quad-Core** configuration. However, the physical implementation was bottlenecked by the logic cell/BRAM limits of the Intel MAX 10 (`10M50`) board, restricting the physical instantiation to Dual-Core.

![Phase 2 Architecture](Phase_2_Architecture.jpg)
📄 **Documentation:** [Read the Phase 2 Technical Report](phase_2_technical_report_final.pdf)

---

## 📊 Performance Metrics

* **Core Throughput:** **> 500 Mbps** *(Note: This metric reflects the internal datapath capability of the cryptographic cores, excluding external UART interface bottlenecks).*
* **Stream Capacity:** 2 Concurrent Independent Streams (Protocol supports up to 4).

---

## 🚀 Getting Started

Because this IP relies on a highly specialized internal packet structure rather than standard memory-mapped AXI registers, standard terminal inputs will not work. 

1. **Review the Technical Reports:** Understand the header, payload, and tail structure of the data packets.
2. **Phase 1 Execution:** Data must be packaged manually or via script according to the Phase 1 report before being sent over UART.
3. **Phase 2 Execution:** Utilize the included custom PC software to generate the correct packet structures, select cipher modes, and stream data to the MAX 10 board.
