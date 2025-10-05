# Nuclei Intelligent Automation — Service-Driven Scanning

This project provides a set of scripts to run vulnerability scans in an automated, intelligent, and efficient way using **ProjectDiscovery Nuclei** with Docker.

The core philosophy is **service-driven scanning**: instead of running thousands of templates indiscriminately, the scripts first use **Nmap** to discover which services are actually active on the target hosts and then run only the Nuclei templates relevant to the services found.

This method drastically reduces scan time, minimizes connection errors, and significantly increases the accuracy of the results.

-----

## 🧩 Logical Structure

The automation is divided into two main responsibilities, reflected in two scripts:

```
~/stacks/nuclei/
├── nuclei-templates/        # Official Nuclei templates repository
├── scans/                   # Output directory for all results
│   ├── fast/                # Results from 'fast' profile scans
│   └── full/                # Results from 'full' profile scans
├── run-scan.sh              # The unified, intelligent scan script
└── update-templates.sh      # Script to keep templates up-to-date
```

-----

## 🚀 Initial Setup (First-Time Use)

For a user who has never used this environment, some preparation steps are necessary. The scripts are orchestrators and depend on tools that must be pre-installed.

Follow this guide to set up your environment from scratch.

### Step 1: Install Dependencies

The following tools are required. On Debian/Ubuntu-based systems, use the command below:

```bash
sudo apt-get update && sudo apt-get install -y git nmap docker.io jq
```

  * **`git`**: To download and update Nuclei templates.
  * **`nmap`**: For intelligent host and service discovery.
  * **`docker`**: To run Nuclei in an isolated environment without needing to install it locally.
  * **`jq`**: To process JSON-formatted results.

### Step 2: Configure Docker Permissions (Post-installation)

To run `docker` without `sudo`, add your user to the `docker` group:

```bash
sudo usermod -aG docker ${USER}
```

**Attention:** You need to **log out and log back in** (or reboot the system) for this permission to take effect.

### Step 3: Download Nuclei Templates

This is a one-time step to get the base templates. Inside your working directory (e.g., `~/stacks/nuclei`), run:

```bash
git clone https://github.com/projectdiscovery/nuclei-templates.git ./nuclei-templates
```

The `update-templates.sh` script will handle keeping this directory updated from now on.

### Step 4: Make Scripts Executable

After saving the `run-scan.sh` and `update-templates.sh` scripts in your directory, grant them execution permission:

```bash
chmod +x update-templates.sh run-scan.sh
```

With these four steps, your environment is **ready to scan**.

-----

## 🔄 `update-templates.sh`

A simple, dedicated script with a single responsibility: keeping the local Nuclei templates repository synchronized with the official repository on GitHub.

**Usage:**
Run this script periodically to ensure your scans use the latest vulnerability definitions.

```bash
# Run the update
./update-templates.sh
```

-----

## 🚀 `run-scan.sh` — The Intelligent Scanner

This is the main script that performs the intelligent scan. It requires two main arguments: the **target** and a **scan profile** (`--profile`), which defines the depth of the analysis.

**Usage:**

```bash
# Syntax
./run-scan.sh <target> --profile [fast|full]
```

### Scan Profiles

| Profile | Description | Use Cases |
| :--- | :--- | :--- |
| `fast` | **Fast and Focused:** Scans only for `critical` and `high` severity vulnerabilities with high-impact tags (CVEs, default logins, exposed panels, etc.). | Ideal for daily, quick, low-noise checks or for integration into CI/CD pipelines. |
| `full` | **Complete and In-Depth:** Includes `medium` severity and a wider range of tags for a more exhaustive analysis (general vulnerabilities, technologies, etc.). | Ideal for baseline analyses, weekly/monthly scans, or when a deeper investigation is required. |

### Execution Examples

```bash
# Run a fast scan on the local subnet
./run-scan.sh 192.168.2.0/24 --profile fast

# Run a full scan on a specific domain
./run-scan.sh example.com --profile full
```

When executed, the script displays a detailed help message if the arguments are incorrect or if help is requested (`-h` or `--help`).

-----

## ⚙️ Recommended Workflow

1.  **Initial Setup:** Follow the steps in the **"Initial Setup (First-Time Use)"** section.

2.  **Maintenance (Scheduled):**

      * Set up a `cron` job to run `update-templates.sh` daily.
        ```cron
        # Example cron job to run every day at 05:00 AM
        0 5 * * * /path/to/your/scripts/update-templates.sh
        ```

3.  **Execution (On-Demand):**

      * Run `run-scan.sh` with the desired target and profile as needed.

-----

## 🔒 Security Best Practices

  * **Authorization:** Never run scans against targets without explicit authorization.
  * **Updates:** Keep templates updated to ensure the detection of new vulnerabilities.
  * **Rate-Limiting:** The parameters in the profiles are tuned for local networks. Be cautious when scanning internet-facing targets to avoid overloading services or being blocked by WAFs.
  * **Results Management:** Store the results in a secure and versioned location. Integrate with SIEM tools (Wazuh, Splunk) or correlation platforms (OpenCTI, DefectDojo).

-----