```markdown
# RC Branch Automation Script

Automate the creation of **Release Candidate (RC) branches** from development branches in Git repositories hosted on **Bitbucket Cloud**.  
This script is ideal for multi-team projects and integrates smoothly with **Windows**, **Linux/Mac**, and **Jenkins**.

---

## Features

- Automatically create RC branches from dev branches (e.g., `LMS-1234-dev` → `LMS-1234-rc-ready`).  
- Cherry-pick only new commits from the development branch.  
- Compare RC branch and dev branch to verify consistency.  
- Push RC branch to Bitbucket Cloud.  
- Supports multiple team RC branches, such as `team1-rc-ready`, `team2-rc-ready`, `team1.5-rc-ready`.  
- Jenkins-ready for CI/CD automation.

---

## Requirements

- **Windows version:** `.bat` script  
- **Linux/Mac version:** `.sh` script  
- **Git:** Must be installed and available in PATH  
- Access to the Bitbucket repository (username & password or app password)  

> ⚠️ Cherry-pick conflicts must be resolved manually.

---

## Repository Structure

```

create-rc-branch/
│
├─ create-rc-ready.bat      # Main Windows batch script
├─ create-rc-ready.sh       # Linux/Mac shell script (optional)
├─ README.md                # This documentation

````

---

## Usage

### Windows

```cmd
create-rc-ready.bat DEV_BRANCH TEAM_RC_BRANCH
````

**Parameters:**

* `DEV_BRANCH` → Development branch, e.g., `LMS-1111-dev`
* `TEAM_RC_BRANCH` → Team RC branch, e.g., `team1-rc-ready`

**Example:**

```cmd
create-rc-ready.bat LMS-1234-dev team1-rc-ready
```

This will:

1. Checkout `team1-rc-ready` and update it.
2. Create a new branch `LMS-1234-rc-ready`.
3. Cherry-pick commits from `LMS-1234-dev`.
4. Push `LMS-1234-rc-ready` to Bitbucket Cloud.

---

### Linux / Mac

```bash
./create-rc-ready.sh DEV_BRANCH TEAM_RC_BRANCH
```

**Example:**

```bash
./create-rc-ready.sh LMS-1234-dev team1-rc-ready
```

---

## Jenkins Integration

1. Create a **Freestyle Jenkins Job**.
2. Add **String Parameter** `DEV_BRANCH`.
3. Add **Choice Parameter** `TEAM_RC_BRANCH` with values like:

```
team1-rc-ready
team2-rc-ready
team1.5-rc-ready
```

4. In **Execute Windows batch command / Execute Shell**, call:

```cmd
create-rc-ready.bat %DEV_BRANCH% %TEAM_RC_BRANCH%
```

or for Linux:

```bash
./create-rc-ready.sh $DEV_BRANCH $TEAM_RC_BRANCH
```

---

## Notes

* Ensure dev branch ends with `-dev` suffix for correct RC branch name generation.
* Cherry-pick conflicts must be resolved manually; script aborts on conflict.
* The script assumes proper authentication to Bitbucket Cloud for push. Using **Bitbucket app passwords** is recommended.
