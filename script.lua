--------------------UNSAFE or SAFE-----------------------------------------------------------------------------
-- Controllo modalità unsafe con gestione errori migliorata
if os.access() == 0 then
    if os.master() == 1 then 
        os.restart()
    else
        os.message("UNSAFE MODE is required for this HB!", 0)
        os.exit()
    end
end

-- Pulizia directory temp con controllo
local tempPath = "ux0:pspemu/temp/"
if files.exists(tempPath) then 
    if not files.delete(tempPath) then
        os.message("Failed to delete temp directory!", 0)
    end
end

__NAMEVPK = "ArkFast"
dofile("updater.lua")

----------------------Vars and resources------------------------------------------------------------------------------------
-- Caricamento risorse con gestione errori
local function loadResource(path, defaultW, defaultH)
    local res = image.load(path, defaultW, defaultH)
    if not res then
        os.message("Failed to load resource: "..path, 0)
        return image.create(10, 10, color.new(255,0,0)) -- Immagine fallback
    end
    return res
end

color.loadpalette()
back = loadResource("back.png")
buttonskey = loadResource("buttons.png", 20, 20)
buttonskey2 = loadResource("buttons2.png", 30, 20)

-- Stato applicazione
local appState = {
    status = false,
    sizeUxo = 0,
    clon = 0,
    pos = 1,
    dels = 0,
    actived = files.exists("tm0:npdrm/act.dat"),
    mgsid = "",
    list = {
        data = {},
        icons = {},
        picons = {},
        len = 0
    }
}

-- Costanti organizzate
local PATHS = {
    NPUZ = "ux0:pspemu/PSP/GAME/NPUZ00146",
    GAME = "ux0:pspemu/PSP/GAME/",
    CLON = "ur0:appmeta/",
    TEMP = "ux0:pspemu/temp/"
}

-- Caricamento moduli con gestione errori
local function safeDofile(path)
    if files.exists(path) then
        return dofile(path)
    else
        os.message("Module missing: "..path, 0)
        os.exit()
    end
end

safeDofile("system/ark.lua")
safeDofile("system/functions.lua")
safeDofile("system/callbacks.lua")

------------------------Funzioni Utilità-----------------------------------------------------------------------------------
local function checkFreeSpace()
    local required = 40 * 1024 * 1024 -- 40MB in bytes
    appState.sizeUxo = os.freespace("ux0:")
    return appState.sizeUxo >= required
end

local function drawButton(x, y, iconIndex, text, align, isLarge)
    local btnImg = isLarge and buttonskey2 or buttonskey
    if btnImg then 
        btnImg:blitsprite(x, y, iconIndex) 
    end
    screen.print(x + (isLarge and 35 or 25), y + 3, text, 1, color.white, color.blue, align or __ALEFT)
end

local function updateGameList()
    reload_list() -- Funzione definita in system/functions.lua
    checkFreeSpace()
    files.mkdir(PATHS.GAME)
end

------------------------Menu Principal--------------------------------------------------------------------------------------
updateGameList()
buttons.interval(10, 10)

while true do
    buttons.read()
    if back then back:blit(0, 0) end

    --------- Prints Text Basics ---------
    screen.print(480, 10, appState.actived and "PSVita Actived" or "PSVita NOT Actived", 
                 1, appState.actived and color.green or color.red, 0x0, __ACENTER)
    
    screen.print(480, 35, "ARK-2 Installer", 1, color.white, color.blue, __ACENTER)
    screen.print(10, 10, "Count: " .. appState.list.len, 1, color.red, 0x0)
    screen.print(10, 30, "Sel Clons: " .. appState.dels, 1, color.red, 0x0)
    screen.print(950, 10, "ux0: "..files.sizeformat(appState.sizeUxo).." Free", 1, color.white, color.blue, __ARIGHT)

    appState.status = false
    
    if appState.list.len > 0 then
        -- Blit Icons
        if appState.list.icons[appState.pos] then
            appState.list.icons[appState.pos]:center()
            appState.list.icons[appState.pos]:resize(80, 80)
            appState.list.icons[appState.pos]:blit(784, 125)
        end

        -- Pboot
        if appState.list.picons[appState.pos] then
            appState.list.picons[appState.pos]:center()
            appState.list.picons[appState.pos]:resize(80, 80)
            appState.list.picons[appState.pos]:blit(886, 125)
        end

        -- Lista giochi
        local y = 85
        for i = appState.pos, math.min(appState.list.len, appState.pos + 14) do
            if i == appState.pos then screen.print(10, y, "->") end
            
            screen.print(40, y, appState.list.data[i].id or "unk")
            
            local flagColor = appState.list.data[i].flag == 1 and color.green or color.red
            screen.print(195, y, appState.list.data[i].comp or "unk", 1, flagColor, 0x0, __ALEFT)
            screen.print(245, y, appState.list.data[i].title or "unk", 1, color.white, 0x0, __ALEFT)
            
            if appState.list.data[i].del then 
                draw.fillrect(33, y, 700, 16, color.new(255, 255, 255, 100)) 
            end
            
            screen.print(700, y, appState.list.data[i].sceid or "", 1, color.white, 0x0, __ARIGHT)
            screen.print(725, y, appState.list.data[i].clon or "", 1, color.green, 0x0, __ARIGHT)
            
            y += 20
        end

        ---------- Pulsanti ----------
        -- Colonna sinistra
        drawButton(10, 465, 0, "Install ARK") -- X
        drawButton(10, 488, 2, "Clone Game") -- []
        drawButton(5, 508, 1, "Install MINI Sasuke & ARK2", __ALEFT, true) -- Start (large)
        
        -- Colonna destra
        drawButton(930, 465, 3, "Delete CLON(s)", __ARIGHT) -- Circle
        drawButton(930, 488, 1, "Mark/Unmark CLON(s)", __ARIGHT) -- Triangle
        
        if appState.dels > 0 then
            drawButton(923, 508, 0, "Unmark all CLON(s)", __ARIGHT, true) -- Select (large)
        end
    else
        -- Nessun gioco trovato
        screen.print(10, 480, "No PSP games found :(")
        drawButton(10, 508, 0, "Install MINI Sasuke & ARK", __ALEFT)
        
        if buttons.cross then 
            if checkFreeSpace() then 
                install_ark_from0() 
            else
                os.message("Not Enough Memory (minimum 40 MB)")
            end
        end
    end

    ---------- Controlli Input ----------
    -- Navigazione lista
    if (buttons.up or buttons.analogly < -60) and appState.pos > 1 then 
        appState.pos -= 1 
    end
    if (buttons.down or buttons.analogly > 60) and appState.pos < appState.list.len then 
        appState.pos += 1 
    end

    -- Installazione ARK
    if buttons.cross and appState.list.data[appState.pos].flag == 1 then
        if checkFreeSpace() then
            if os.message("Install ARK in the game "..appState.list.data[appState.pos].id.." ?", 1) == 1 then
                appState.status = false
                buttons.homepopup(0)
                install_ark(appState.list.data[appState.pos].path)
                update_db(true)
            end
        else
            os.message("Not Enough Memory (minimum 40 MB)")
        end
    end

    -- Clonazione gioco
    if buttons.square and appState.list.data[appState.pos].flag == 1 then
        if checkFreeSpace() then
            local delp = false
            if os.message("Clone this game to install ARK or Adrenaline?", 1) == 1 then
                local pbootPath = PATHS.GAME..appState.list.data[appState.pos].id.."/PBOOT.PBP"
                
                if files.exists(pbootPath) then
                    local sfo = game.info(pbootPath)
                    if os.message("PBOOT.PBP found: "..tostring(sfo.TITLE).."\n\nDelete it? (Clones will be clean)", 1) == 1 then
                        delp = true
                    end
                end

                local defaultClones = 1
                local maxClones = 9
                local cloneMsg = string.format("Create Clones (1 to %d)", maxClones)
                local number_clons = math.minmax(tonumber(osk.init(cloneMsg, tostring(defaultClones), 2, 1)), 1, maxClones)
                
                install_clone(appState.list.data[appState.pos].path, appState.list.data[appState.pos].id, number_clons, delp)        
            end
        else
            os.message("Not Enough Memory (minimum 40 MB)")
        end        
    end

    -- Gestione cloni
    if buttons.triangle and appState.list.data[appState.pos].clon == "©" then
        appState.list.data[appState.pos].del = not appState.list.data[appState.pos].del
        if appState.list.data[appState.pos].del then 
            appState.dels += 1 
        else 
            appState.dels -= 1 
        end
    end

    -- Eliminazione cloni
    if buttons.circle and appState.list.data[appState.pos].clon == "©" then
        if appState.list.data[appState.pos].del then
            if os.message("Delete "..appState.dels.." selected CLON(s)?", 1) == 1 then
                buttons.homepopup(0)
                for i = 1, appState.list.len do
                    if appState.list.data[i].del then
                        delete_bubble(appState.list.data[i].id)
                    end
                end
                os.message(appState.dels.." CLON(s) deleted")
                update_db(false)
                appState.dels = 0
            end
        elseif appState.dels == 0 then
            if os.message("Delete this CLON: "..appState.list.data[appState.pos].id.."?", 1) == 1 then
                buttons.homepopup(0)
                delete_bubble(appState.list.data[appState.pos].id)
                update_db(false)
            end
        end
    end

    -- Deseleziona tutti i cloni
    if buttons.select then
        for i = 1, appState.list.len do
            if appState.list.data[i].del then
                appState.list.data[i].del = false
            end
        end
        appState.dels = 0
    end

    -- Installazione di default
    if buttons.start then
        if checkFreeSpace() then
            if files.exists(PATHS.NPUZ.."/EBOOT.PBP") then
                os.message("MINI Sasuke vs Commander is already installed", 0)
            else
                install_ark_from0()
            end
        else
            os.message("Not Enough Memory (minimum 40 MB)")
        end
    end

    screen.flip()
end
