# cloud-computing-aws-practice

This repository contains the checkpoint implementation of the **Games@Cloud** project. It deploys a Java-based service (running Capture the Flag, 15-Puzzle, and Game of Life workloads) on AWS using multi-threaded EC2 workers. An AWS-configured **Load Balancer (LB)** distributes requests across workers, while an **Auto-Scaler (AS)** adjusts the number of active instances based on system load. The application is instrumented with **Javassist** to collect execution metrics for request complexity estimation. The system operates fully with EC2 workers, LB, AS, and instrumentation. 

All **server source code** and **deployment scripts** are located under the [`files`](./files) folder. The `javassist` folder includes its own `README.md` explaining in more detail how the instrumentation works. A demonstration video (`video-ccv-aws-p1.mp4`) is provided to show the system in action and the deployment procedure. The assignment report (`ccv-report-aws-p1.pdf`) is also included, summarizing the architecture, implemented components, and next steps.  

## To watch the video:

1. Install Git LFS (if you haven’t already):
   ```bash
   git lfs install
   ```
2. Clone the repository as usual.

---

## AWS CLI Automation

The infrastructure setup script performs:  

- **Load Balancer creation** with health checks  
- **Launch Configuration** with:  
  - AMI from `image.id`  
  - `t2.micro` instance type  
  - SSH key, monitoring, security group  
- **Auto Scaling Group** setup with:  
  - Min/Max/Desired instances  
  - Linked to the load balancer  
- **CloudWatch Alarms** for:  
  - Scaling out if CPU > 50%  
  - Scaling in if CPU < 25%  

To run the deployment:  
1. Change the credentials in `config.sh`  
2. Run `create-image.sh` to prepare and store the AMI  
3. Then run `launch-deployment.sh` to deploy the infrastructure  

---

## Architecture Overview

1. **Instrumentation Layer (`JavassistWrapper` / `ICount`)**  
   - Probes are woven into each handler’s bytecode using Javassist at load-time.  
   - Counts methods, basic blocks, and instructions globally and per thread.  
   - Uses `ThreadLocal` counters to separate stats per request.  
   - Automatically logs global stats (`global_stats.txt`) and per-thread stats (`thread_stats_<thread>.txt`).  
   - Statistics are reset after each workload using `resetThreadStatistics()`.  

2. **Workload Modules**  
   - `capturetheflag` – Capture-the-Flag logic  
   - `fifteenpuzzle` – 15-Puzzle solver  
   - `gameoflife` – Conway’s Game of Life  
   - Each exposes a `handleWorkload(...)` function used by the webserver.  

3. **Web Server Front-End**  
   - Lightweight HTTP server using `com.sun.net.httpserver`.  
   - Routes incoming requests to the appropriate workload handler.  
   - Before executing a request:  
     - Calls `resetThreadStatistics()`  
   - After execution:  
     - Calls `printThreadStatistics()` and `writeThreadStatisticsToFile()` to persist metrics  
   - This enables per-request insight on instruction usage and behavior complexity.  

4. **Cloud Deployment (AWS)**  
   - **AMI**: Pre-configured image with Java, Maven, and the built application.  
   - **Load Balancer (ELB)**: HTTP listener on port 80 forwarding to instance port 8000, with health check on `/test`.  
   - **Auto Scaling Group (ASG)**:  
     - Minimum: 1 instance  
     - Maximum: 3 instances  
     - Desired: 1 instance  
     - **Scale-Out**: CPU > 50% → Add instance  
     - **Scale-In**: CPU < 25% → Remove instance  
     - Grace period: 60 seconds  

---

## Instrumentation Enhancements

- `ICount` supports:  
  - **Global Statistics** – Total counts for methods, blocks, and instructions (printed at `main()` exit).  
  - **Thread Statistics** – Tracked separately using `ThreadLocal` for each incoming HTTP request.  
  - **Reset & Logging** – At the start of each workload, stats are reset. After processing, they are printed and logged.  

- Output files:  
  - `global_stats.txt` – cumulative metrics over server lifetime.  
  - `thread_stats_<thread>.txt` – isolated stats per workload execution.  

  ---

This project was developed as part of the **Cloud Computing and Virtualization** course at **Instituto Superior Técnico**.  
It is intended for **educational purposes only**.

### Configuración de Credenciales

Este proyecto requiere que configures tus credenciales AWS. 

1. Copia el archivo de ejemplo:
   ```bash
   cp files/scripts/config_template.sh files/scripts/config.sh
   ```
2. Edita config.sh y añade tus credenciales temporales.
