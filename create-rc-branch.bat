@echo off
setlocal enabledelayedexpansion

:: ===========================================
:: Check required parameters
:: ===========================================
if "%~1"=="" (
    echo DEV_BRANCH parameter is required!
    echo Usage: create-rc-ready.bat DEV_BRANCH TEAM_RC_BRANCH
    exit /b 1
)
if "%~2"=="" (
    echo TEAM_RC_BRANCH parameter is required!
    echo Usage: create-rc-ready.bat DEV_BRANCH TEAM_RC_BRANCH
    exit /b 1
)

set DEV_BRANCH=%~1
set TEAM_RC_BRANCH=%~2
set RC_BRANCH=%DEV_BRANCH:-dev=-rc-ready%

echo ==================================================
echo Creating RC branch for team: %TEAM_RC_BRANCH%
echo Source branch: %DEV_BRANCH%
echo Target branch: %RC_BRANCH%
echo ==================================================
echo.

:: ===========================================
:: Step 1: Checkout and update team RC branch
:: ===========================================
echo Checking out base RC branch '%TEAM_RC_BRANCH%'...
git checkout %TEAM_RC_BRANCH%
if errorlevel 1 exit /b 1
git pull --rebase origin %TEAM_RC_BRANCH%
if errorlevel 1 exit /b 1
echo Base branch is up to date.
echo.

:: ===========================================
:: Step 2: Create new ticket-specific RC branch
:: ===========================================
echo Creating new RC branch: %RC_BRANCH%...
git checkout -b %RC_BRANCH%
if errorlevel 1 exit /b 1
echo New branch '%RC_BRANCH%' created from '%TEAM_RC_BRANCH%'.
echo.

:: ===========================================
:: Step 3: Cherry-pick commits from dev branch
:: ===========================================
echo Fetching latest commits from %DEV_BRANCH%...
git fetch origin %DEV_BRANCH%
if errorlevel 1 exit /b 1

:: Find merge base
for /f "delims=" %%m in ('git merge-base %TEAM_RC_BRANCH% origin/%DEV_BRANCH%') do set MERGE_BASE=%%m

:: List commits to cherry-pick
git log %MERGE_BASE%..origin/%DEV_BRANCH% --pretty=format:"%%h" --reverse > commits.txt

for /f %%c in (commits.txt) do (
    if not "%%c"=="" (
        echo Cherry-picking commit: %%c
        git cherry-pick %%c
        if errorlevel 1 (
            echo Cherry-pick conflict at commit %%c! Aborting.
            git cherry-pick --abort
            del commits.txt
            exit /b 1
        )
    )
)

del commits.txt
echo All commits cherry-picked successfully.
echo.

:: ===========================================
:: Step 4: Compare branches
:: ===========================================
git diff --quiet origin/%DEV_BRANCH% %RC_BRANCH%
if errorlevel 1 (
    echo Differences exist - expected since RC branch is based on team RC, not dev base.
    echo Summary of changes:
    git log %TEAM_RC_BRANCH%..%RC_BRANCH% --oneline
) else (
    echo Branches match! %RC_BRANCH% is up-to-date with %DEV_BRANCH%.
)
echo.

:: ===========================================
:: Step 5: Push RC branch to Bitbucket
:: ===========================================
echo Pushing RC branch to Bitbucket...
git push -u origin %RC_BRANCH%
if errorlevel 1 (
    echo Push failed! Manual intervention required.
    exit /b 1
) else (
    echo Branch '%RC_BRANCH%' pushed successfully.
)

echo ==================================================
echo RC branch '%RC_BRANCH%' is ready!
echo Summary:
echo    • Base: %TEAM_RC_BRANCH%
echo    • Created: %RC_BRANCH%
echo    • Source: %DEV_BRANCH%
echo ==================================================

endlocal
