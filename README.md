# Kafka System Control 
<img width="318" height="159" alt="images" src="https://github.com/user-attachments/assets/ae5d80ff-5b04-445c-8465-a56c35c5c727" />

**Version 3.0** | Developed (2023–2026)

A comprehensive Apache Kafka management system with a user‑friendly Bash interface and powerful Java utilities.  
Designed to simplify daily operations across multiple environments (DEV, PREPROD, PROD) while ensuring safety and auditability.

---

## ✨ Features

- **📋 Describe** – View details of topics, consumer groups, ACLs, and configurations.
- **➕ Create** – Safely create topics, consumer groups, and access rules.
- **🗑️ Delete** – Secure deletion with confirmation prompts and environment‑aware safeguards.
- **🔍 Message Search** – Locate messages by offset, key, or time range (Java‑powered).
- **📊 Monitoring** – Analyze consumer lag, collect metrics, and simulate rebalances.
- **🛡️ Multi‑Environment** – Switch between DEV, PREPROD, and PROD with isolated configurations.
- **⚙️ Extensible** – Modular design makes it easy to add new commands and integrations.

---

## 📁 Project Structure

kafka-system-control/

├── bin/ # Launch scripts and installers 
├── scripts/ # Core Bash modules (main menu, libs, sub‑modules) 

├── java/ # Java utilities (advanced search, metrics, etc.)
├── config/ # Environment‑specific configuration templates

├── docs/ # User and developer documentation

├── tools/ # Helper scripts (backup, migration, benchmarking)

├── kafka-bin/ # (Optional) Apache Kafka binaries

├── logs/ # Operation logs (excluded from version control)

└── examples/ # Usage examples

---

## 📋 Prerequisites

- **Linux** (developed and tested on RHEL / Ubuntu)
- **Bash 4+**
- **Java 11+** (required for Java‑based features)
- **Apache Kafka binaries** (either placed in `kafka-bin/` or available in `$PATH`)

---

## 🚀 Installation

1. **Clone the repository**  
   ```bash
   git clone https://github.com/Egorich88/kafka-system-control.git
   cd kafka-system-control
   
2. **Run the installation helper**
   ```bash
   ./bin/install-deps.sh
   This script checks for Java, sets up configuration templates, and builds the Java components if Maven is available.

3. **Configure your environments**
   Edit the configuration files in config/ (or use the provided templates) to set the correct bootstrap servers and security properties for DEV, PREPROD, and PROD.

4. **Make sure Kafka binaries are accessible**
   Either download Kafka and place it in kafka-bin/, or ensure the standard scripts (kafka-topics.sh, etc.) are in your PATH.
