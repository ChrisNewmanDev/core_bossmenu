# core_bossmenu

A modern boss menu for FiveM using the UI style from [core_gps_advanced](https://github.com/ChrisNewmanDev/core_gps_advanced), but for managing jobs through [qb-management](https://github.com/qbcore-framework/qb-management).

## Features
- Modern, dark UI inspired by core_gps_advanced
- Shows job, grade, account balance, and employees
- Pay and fire employees directly from the menu
- Uses NUI for a smooth experience

## Requirements
- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [qb-management](https://github.com/qbcore-framework/qb-management)
- [oxmysql](https://github.com/overextended/oxmysql)

## Installation
1. Place `core_bossmenu` in your `resources` folder.
2. Add `ensure core_bossmenu` to your `server.cfg` **after** `qb-core`, `qb-management`, and `oxmysql`.
3. Start your server.

## Usage
- Use `/bossmenu` in-game (for testing; restrict to boss roles in production).
- The menu will show your job, grade, account balance, and a list of employees.
- Select an employee to pay or fire them.

## Customization
- Edit `html/style.css` for UI changes.
- Edit `html/app.js` for menu logic.

## Credits
- UI inspired by [core_gps_advanced](https://github.com/ChrisNewmanDev/core_gps_advanced) by ChrisNewmanDev
- Boss menu logic based on [qb-management](https://github.com/qbcore-framework/qb-management)

---
Enjoy your new boss menu!
