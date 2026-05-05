Config = {}

-- === UI SETTINGS ===
Config.UI = {
    accentColor = "#1ABC9C",                -- Main theme color (Hex)
    accentGlow = "rgba(26, 188, 156, 0.4)",   -- Glow effect for borders and buttons (RGBA)
    bgDark = "rgba(0, 0, 0, 0.7)"            -- Sidebar and overlay background opacity
}

-- === ANIMATION SETTINGS ===
Config.Animations = {
    randomEnabled = true,                    -- If true, picks a random scenario. If false, uses the first one.
    scenarios = { 
        "WORLD_HUMAN_TOURIST_MAP",
        "PROP_HUMAN_STAND_IMPATIENT", 
        "WORLD_HUMAN_SMOKING",
        "WORLD_HUMAN_SMOKING_POT",
        "WORLD_HUMAN_AA_SMOKE", 
        "CODE_HUMAN_CROSS_ROAD_WAIT",
        "WORLD_HUMAN_BUM_STANDING", 
        "WORLD_HUMAN_AA_COFFEE", 
        "WORLD_HUMAN_DRUG_DEALER_HARD"
    }
}

-- === LOCALIZATION & TEXT ===
Config.Locale = {
    mainpage = {
        server_name = "MY SERVER NAME",
        discord_display = "JOIN OUR COMMUNITY",      -- Visible text on the Discord card
        discord_url = "https://discord.gg/DmsF6DbCJ9", -- Redirect link on click
        website_display = "www.myserver.com",        -- Visible text on the Website card
        website_url = "https://myserver.com",         -- Redirect link on click
        resume = "RESUME GAME",
        
        -- Menu Items
        map = { title = "MAP", description = "Open the world map" },
        settings = { title = "SETTINGS", description = "Game options" },
        exit = { title = "QUIT", description = "Leave the server" },
        
        -- Help & Rules Section
        rules = { 
            title = "HELP & RULES", 
            rules = { "Type /help in chat", "Click for full rules" }, -- Summarized rules on main page
            fullRules = {                                           -- Content of the popup modal
                "1. Do not advertise other servers!",
                "2. Respect your fellow players!",
                "3. Exploiting bugs will result in a ban.",
                "4. Follow the instructions of the staff.",
                "5. Have fun and enjoy the game!"
            },
            closeButton = "CLOSE"
        },
        
        -- Player Stats Labels
        stats = { name = "Name", job = "Job", cash = "Cash" }
    },
    
    -- Confirmation Modals
    confirm = {
        title = "Are you sure?",
        yes = "YES",
        no = "CANCEL",
        exit_confirmation = "Do you want to quit?",
    },
    
    player_id = "Player ID",
    dropplayer = "Logged out. See you later!"
}
