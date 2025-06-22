-- ARK-2 Installer - Versione Refactor

-- ================== SICUREZZA =====================
if os.access() ~= 1 then
	if os.master() == 1 then
		if os.message("PS Vita must reboot to enter UNSAFE mode.\nDo you want to continue?", 1) == 1 then
			os.restart()
		else
			os.exit()
		end
	else
		os.message("UNSAFE MODE is required for this HB!", 0)
		os.exit()
	end
end

if files.exists("ux0:pspemu/temp/") then files.delete("ux0:pspemu/temp/") end

-- ================== COSTANTI =====================
__NAMEVPK = "ArkFast"
PATHTONPUZ = "ux0:pspemu/PSP/GAME/NPUZ00146"
PATHTOGAME = "ux0:pspemu/PSP/GAME/"
PATHTOCLON = "ur0:appmeta/"

-- ================== CARICAMENTO =====================
dofile("updater.lua")
dofile("system/ark.lua")
dofile("system/functions.lua")
dofile("system/callbacks.lua")

color.loadpalette()
back = image.load("back.png")
buttonskey = image.load("buttons.png",20,20)
buttonskey2 = image.load("buttons2.png",30,20)

-- ================== VARIABILI =====================
status,sizeUxo,clon,pos,dels = false, 0, 0, 1, 0
actived = files.exists("tm0:npdrm/act.dat")

-- ================== FUNZIONI =====================
function draw_button_hint(sprite, index, x, y, text, align)
	if sprite then sprite:blitsprite(x, y, index) end
	screen.print(x + 35, y + 3, text, 1, color.white, color.blue, align or __ALEFT)
end

-- ================== INIZIALIZZAZIONE =====================
reload_list()
check_freespace()
files.mkdir(PATHTOGAME)
buttons.interval(10,10)

-- ================== LOOP PRINCIPALE =====================
while true do
	buttons.read()
	if back then back:blit(0,0) end

	-- Stato attivazione
	screen.print(480,10, actived and "PSVita Actived" or "PSVita NOT Actived", 1, actived and color.green or color.red, 0x0, __ACENTER)
	screen.print(480,35,"ARK-2 Installer",1,color.white,color.blue,__ACENTER)
	screen.print(10,10,"Count: " .. list.len,1,color.red)
	screen.print(10,30,"Sel Clons: " .. dels,1,color.red)
	screen.print(950,10,"ux0: "..files.sizeformat(sizeUxo).." Free",1,color.white,color.blue,__ARIGHT)

	status = false

	if list.len > 0 then
		-- Icone
		if list.icons[pos] then list.icons[pos]:resize(80,80):blit(784,125) end
		if list.picons[pos] then list.picons[pos]:resize(80,80):blit(886,125) end

		-- Lista
		local y = 85
		for i=pos,math.min(list.len,pos+14) do
			if i == pos then screen.print(10,y,"->") end
			local entry = list.data[i]
			local ccolor = entry.flag == 1 and color.green or color.red
			screen.print(40,y,entry.id or "unk")
			screen.print(195,y,entry.comp or "unk",1,ccolor)
			screen.print(245,y,entry.title or "unk")
			if entry.del then draw.fillrect(33,y,700,16,color.new(255,255,255,100)) end
			screen.print(700,y,entry.sceid or "",1,color.white,__ARIGHT)
			screen.print(725,y,entry.clon or "",1,color.green,__ARIGHT)
			y += 20
		end

		-- Pulsanti sinistra
		draw_button_hint(buttonskey, 0, 10, 465, "Install ARK")
		draw_button_hint(buttonskey, 2, 10, 488, "Clone Game")
		draw_button_hint(buttonskey2, 1, 5, 508, "Install MINI Sasuke vs Commander & ARK2")

		-- Pulsanti destra
		draw_button_hint(buttonskey, 3, 930, 465, "Delete CLON(s)", __ARIGHT)
		draw_button_hint(buttonskey, 1, 930, 488, "Mark/Unmark CLON(s)", __ARIGHT)
		if dels > 0 then draw_button_hint(buttonskey2, 0, 923, 508, "Unmark all CLON(s)", __ARIGHT) end
	else
		screen.print(10,480,"No games PSP :(")
		draw_button_hint(buttonskey, 0, 10, 508, "Install MINI Sasuke vs Commander & ARK2")
		if buttons.cross and check_freespace() then install_ark_from0() end
	end

	-- Controlli navigazione
	if (buttons.up or buttons.analogly < -60) and pos > 1 then pos -= 1 end
	if (buttons.down or buttons.analogly > 60) and pos < list.len then pos += 1 end

	-- Controlli azioni
	local game = list.data[pos]
	if game then
		if buttons.cross and game.flag == 1 and check_freespace() then
			if os.message("Install ARK in the game "..game.id.." ?",1) == 1 then
				buttons.homepopup(0)
				install_ark(game.path)
				update_db(true)
			end
		end

		if buttons.square and game.flag == 1 and check_freespace() then
			if os.message("Clone this game for ARK or Adrenaline?",1) == 1 then
				local delp = false
				if files.exists(PATHTOGAME..game.id.."/PBOOT.PBP") then
					local sfo = game.info(PATHTOGAME..game.id.."/PBOOT.PBP")
					if os.message("PBOOT.PBP: "..tostring(sfo.TITLE).." found.\nDelete for clean clone?",1) == 1 then
						delp = true
					end
				end
				local number_clons = math.minmax(tonumber(osk.init("Create Clones (1 to 9)","1",2,1)),1,9)
				install_clone(game.path, game.id, number_clons, delp)
			end
		end

		if buttons.triangle and game.clon == "©" then
			game.del = not game.del
			dels += game.del and 1 or -1
		end

		if buttons.circle and game.clon == "©" then
			if game.del and os.message("Delete "..dels.." CLON(s)?",1) == 1 then
				buttons.homepopup(0)
				for i=1,list.len do if list.data[i].del then delete_bubble(list.data[i].id) end end
				os.message("CLON(s) Eliminated")
				update_db(false)
			elseif dels == 0 and os.message("Delete CLON: "..game.id.." ?",1) == 1 then
				buttons.homepopup(0)
				delete_bubble(game.id)
				update_db(false)
			end
		end
	end

	if buttons.select then
		for i=1,list.len do list.data[i].del = false end
		dels = 0
	end

	if buttons.start and check_freespace() then
		if files.exists(PATHTONPUZ.."/EBOOT.PBP") then
			os.message("The MINI Sasuke vs Commander is already installed",0)
		else
			install_ark_from0()
		end
	end

	screen.flip()
end
