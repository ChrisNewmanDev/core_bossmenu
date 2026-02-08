Config = {}

-- Currency symbol to display
Config.Currency = '$ ' --R ,$ ,€ ,£ ,¥ ,etc.
-- Command settings
Config.EnableCommand = false -- Enable /bossmenu command (true/false)
Config.UseKeybind = true -- Enable keybind for boss menu (true/false)
Config.Keybind = 'F6' -- Default keybind (can be changed in game settings) Only works if enable command is true

-- Admin settings
Config.AdminCommand = 'bossadmin' -- Command to open admin menu for managing boss menu locations
Config.AdminPermission = 'god' -- Permission level required (admin, god, or specific ace permission)

-- Webhook settings (leave empty to disable specific webhooks)
Config.Webhooks = {
    AdminActions = '', -- Logs place, move, and remove boss menu locations
    MoneyWithdraw = '', -- Logs money withdrawals from job account
    MoneyDeposit = '', -- Logs money deposits to job account
    EmployeeActions = '' -- Logs hire, fire, and grade changes
}

-- Hire settings
Config.HireRange = 5.0 -- Distance in meters to detect nearby players for hiring
Config.HireGrade = 0 -- Starting grade when hiring a new employee

-- Interaction settings
Config.TargetSystem = 'qb-target' -- Options: 'qb-target', 'ox_target', 'none' (for key press interaction)
Config.InteractionKey = 38 -- E key (default) for non-target interaction
Config.InteractionDistance = 2.0 -- Distance in meters to interact with boss menu
Config.DrawMarker = true -- Draw marker at boss menu locations (if not using target)
Config.MarkerDrawDistance = 3.5  -- Distance from which marker becomes visible (in meters)
Config.MarkerHeight = 1.0 -- Height offset for marker (0.5 = half meter higher)
Config.MarkerType = 2 -- Marker type (2 = upward cone)
Config.MarkerColor = {r = 0, g = 255, b = 0, a = 150} -- Marker color (RGBA)