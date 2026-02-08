# Me
Hello! If you’re enjoying the script and feel like supporting the work that went into it, consider buying me a coffee ☕
https://buymeacoffee.com/core_scripts

# core_bossmenu

A modern boss menu for FiveM for managing jobs.

## Some Screenshots

![bossmenu1](https://i.postimg.cc/L5nfFdMR/bossmenu1.png)

![bossmenu2](https://i.postimg.cc/XqpF6M0b/bossmenu2.png)

![bossmenu3](https://i.postimg.cc/fyJXQ4hs/bossmenu3.png)

## Features
- Modern UI
- Shows job, grade, account balance, and employees
- Pay, promote/demote and fire/hire employees directly from the menu
- Uses NUI for a smooth experience

## Requirements
- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [oxmysql](https://github.com/overextended/oxmysql)
- Banking Script: [qb-banking](https://github.com/qbcore-framework/qb-banking) (or any other banking script - see Custom Banking Integration section)
- Optional: [qb-target](https://github.com/qbcore-framework/qb-target) or [ox_target](https://github.com/overextended/ox_target) (configurable)

## Installation
1. Run the SQL query in `install.sql` to create the database table.
2. Place `core_bossmenu` in your `resources` folder.
3. Add `ensure core_bossmenu` to your `server.cfg` if not in an ensured folder.
4. Configure `config.lua` to your preferences.

## Custom Banking Integration
This resource uses **qb-banking** by default for managing job accounts. If you're using a different banking script, you'll need to replace the banking exports in `server/main.lua`:

**Look for these sections marked with comments:**
1. **Get Account Balance** (Line ~306-310): Check if job account exists and get balance
2. **Deposit Money** (Line ~397-398): Add money to job account
3. **Withdraw Money** (Line ~421-425): Remove money from job account

**Each section is clearly marked with:**
```lua
-- ==================================== 
-- BANKING INTEGRATION - qb-banking
-- ====================================
```

**Replace the exports with your banking script's functions:**
- `GetAccount(job)` - Check if job account exists
- `CreateJobAccount(job, 0)` - Create a new job account
- `GetAccountBalance(job)` - Get current balance
- `AddMoney(job, amount)` - Deposit money
- `RemoveMoney(job, amount)` - Withdraw money

## Usage
- **Admin Management:** Use `/bossadmin` to open the admin menu:
  1. Select a job from the list
  2. View existing locations or add a new one
  3. **Add Location Here:** Places location at your current position
  4. **Aim & Place Location:** Enter free-aim mode - look where you want to place the location, press **[E]** to confirm or **[X]** to cancel
  5. For each location you can:
     - **Move Here:** Update the location to your current position
     - **Remove:** Delete the location from the database
     - **Teleport:** Instantly teleport to that location
- **Access Menu:** Boss employees can interact with placed locations using:
  - **qb-target** - Target the location and select "Open Boss Menu"
  - **ox_target** - Target the location and select "Open Boss Menu"
  - **Key Press** - Stand near the location and press **[E]** (configurable in config.lua)
- **Command Access:** If enabled in config, use `/bossmenu` command to open the menu from anywhere (requires boss rank).
- **Keybind Access:** If enabled in config, press the keybind (default: F6) to open the menu. Can be rebound in `Settings > Key Bindings > FiveM`.
- The menu will show job info, account balance, employee management options, and nearby players to hire.
- **Hire Employees:** Boss can hire nearby players (within configurable range) directly from the menu.
  - Players within the hire range will appear in the "Hire Employee" section
  - Click the "✅ Hire" button next to a player to hire them at the starting grade
  - Hired players will be notified and added to the job immediately

## Customization
Edit `config.lua` to customize:
- **Currency Symbol:** Change `Config.Currency` (default: `$`)
- **Enable Command:** Set `Config.EnableCommand` to enable/disable `/bossmenu` command (default: `true`)
- **Enable Keybind:** Set `Config.UseKeybind` to enable/disable keybind for boss menu (default: `true`)
- **Keybind Key:** Change `Config.Keybind` for the default key (default: `F6`) - players can rebind in game settings
- **Admin Command:** Change `Config.AdminCommand` for managing locations (default: `bossadmin`)
- **Admin Permission:** Set `Config.AdminPermission` (default: `admin`)
- **Target System:** Set `Config.TargetSystem` to choose interaction method:
  - `'qb-target'` - Use qb-target for interaction
  - `'ox_target'` - Use ox_target for interaction
  - `'none'` - Use key press interaction with markers
- **Interaction Key:** Change `Config.InteractionKey` (default: `38` = E key) - used when TargetSystem is set to `'none'`
- **Interaction Distance:** Adjust `Config.InteractionDistance` in meters
- **Marker Settings:** Customize marker appearance when using key press interaction (TargetSystem = `'none'`)
- **Webhooks:** Configure Discord webhook URLs in `Config.Webhooks`:
  - `AdminActions` - Logs location placement, moves, and removals
  - `MoneyWithdraw` - Logs all money withdrawals from job accounts
  - `MoneyDeposit` - Logs all money deposits to job accounts
  - `EmployeeActions` - Logs grade changes, employee terminations, and new hires
- **Hire Settings:**
  - `Config.HireRange` - Distance in meters to detect nearby players for hiring (default: `5.0`)
  - `Config.HireGrade` - Starting grade when hiring a new employee (default: `0`)

Additional customization:
- Edit `html/style.css` for UI changes.
- Edit `html/app.js` for menu logic.

## 🔄 Automatic Update Checker

The script includes an automatic version checker that runs when the server starts. It will:
- Check for new versions on GitHub
- Display the latest version information in the console
- Show changelog entries for new updates
- List specific files that need to be updated
- Provide a download link to the latest release

### GitHub Workflow Automation

This resource includes a GitHub Actions workflow (`.github/workflows/update-version.yml`) that automatically updates the `version.json` file when you create a new release tag:

1. Create a new tag in the format `v1.0.0`
2. Push the tag to GitHub: `git push origin v1.0.0`
3. The workflow automatically updates `version.json` with the new version
4. Users will see update notifications when starting their servers

**Note:** You'll need to add a `GH_TOKEN_CNEW` secret to your GitHub repository settings for the workflow to work.

**Enjoy your advanced boss menu!** 💼📋

## Credits
- **Framework:** QB-Core
- **Developer:** ChrisNewmanDev