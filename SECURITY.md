# Security Policy

## Supported Versions

Security updates are provided for the most recent stable release of this project.

Older versions may not receive updates. Users are strongly encouraged to upgrade to the latest version to ensure they receive security fixes and improvements.

---

## Reporting a Vulnerability

If you believe you have identified a security vulnerability, please report it responsibly.

**Please do not publicly disclose security issues before they have been reviewed and addressed.**

### Preferred Reporting Method

* Use GitHub's **Private Vulnerability Reporting** (Security Advisory) feature, if available.

If private reporting is not available:

* Open an issue and clearly mark it as security-related.
* Do **not** include exploit code or sensitive technical details in public issues.

### Please Include

* A clear description of the vulnerability
* Steps to reproduce the issue
* Affected version(s)
* Environment details (OS, PowerShell version, etc.)
* Proof-of-concept information (if applicable and safe to share)

Reports submitted in good faith will be reviewed as promptly as reasonably possible.

---

## Response Process

Response times may vary depending on availability and severity. The general process is:

1. Acknowledge receipt of the report
2. Validate and assess impact
3. Develop and test a fix (if required)
4. Release an updated version
5. Publish advisory information when appropriate

There is no guaranteed remediation timeline. Prioritization is based on severity and available resources.

---

## Coordinated Disclosure

Responsible disclosure is appreciated.

Security issues should not be publicly disclosed until:

* The issue has been reviewed, and
* A fix or mitigation has been made available (when feasible)

Contributors who responsibly disclose vulnerabilities may be credited unless anonymity is requested.

---

## Safe Harbor for Security Research

This project supports good-faith security research.

No action will be taken against individuals who:

* Act in good faith
* Avoid privacy violations, data destruction, or service disruption
* Do not exploit vulnerabilities beyond what is necessary to demonstrate impact

Security testing should only be conducted against systems you own or have explicit permission to test.

---

## Security Considerations for This Module

MRNAP generates file paths and optionally moves files on the local filesystem. Users should be aware of the following:

* **Path injection** — `-ReportName` and `-DirectoryName` values are incorporated directly into file paths. Avoid passing untrusted or user-supplied input to these parameters without sanitization.
* **File overwrite** — MRNAP returns a path but does not itself write files. However, downstream code writing to the returned path may overwrite existing files if the same path is reused. Use timestamps (the default behavior) to avoid collisions.
* **Move behavior** — The `-Move` switch creates directories and moves files using `New-Item` and `Move-Item` with `-Force`. Confirm the destination directory is appropriate before using `-Move` in automated or elevated contexts.
* **Execution policy** — If importing this module via `Import-Module`, ensure your execution policy permits loading the module from its source location.

---

## Security Best Practices for Users

Users are responsible for securely deploying and operating this software. Recommended practices include:

* Review the source code before use
* Keep the module up to date via `Update-Module -Name MRNAP`
* Use least-privilege execution where possible
* Validate `-ReportName` and `-DirectoryName` input in downstream integrations that accept user-supplied data
* Test changes in non-production environments before deployment

---

## Disclaimer

This project is provided **"as is"**, without warranty of any kind, express or implied.

While reasonable efforts are made to maintain code quality and security, no guarantee is made that the software is free from vulnerabilities or defects.

Use of this project is at your own risk. The maintainers are not responsible for misuse, damages, or security incidents arising from the use of this software.

---

## Contact

For general questions regarding this security policy, please use the repository's discussion feature.
