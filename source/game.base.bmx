
'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame {_exposeToLua="selected"}
	'globals are not saveloaded/exposed
	'0=no debug messages; 1=some debugmessages
	Global debugMode:Int = 0
	Global debugInfos:Int = 0
	Global debugQuoteInfos:Int = 0
	Field debugAudienceInfo:TDebugAudienceInfos = new TDebugAudienceInfos

	'===== GAME STATES =====
	Const STATE_RUNNING:Int			= 0
	Const STATE_MAINMENU:Int		= 1
	Const STATE_NETWORKLOBBY:Int	= 2
	Const STATE_SETTINGSMENU:Int	= 3
	'mode when data gets synchronized
	Const STATE_STARTMULTIPLAYER:Int= 4

	'===== GAME SETTINGS =====
	'how many movies does a player get on a new game
	Const startMovieAmount:Int = 5					{_exposeToLua}
	'how many series does a player get on a new game
	Const startSeriesAmount:Int = 1					{_exposeToLua}
	'how many contracts a player gets on a new game
	Const startAdAmount:Int = 3						{_exposeToLua}
	'maximum level a news genre abonnement can have
	Const maxAbonnementLevel:Int = 3				{_exposeToLua}
	'how many contracts a player can possess
	Const maxContracts:Int = 10						{_exposeToLua}
	'how many movies can be carried in suitcase
	Const maxProgrammeLicencesInSuitcase:Int = 12	{_exposeToLua}

	'how many 0.0-1.0 (100%) audience is maximum reachable
	Field maxAudiencePercentage:Float = 0.3
	'used so that random values are the same on all computers having the same seed value
	Field randomSeedValue:Int = 0

	'username of the player ->set in config
	Global userName:String = ""
	'userport of the player ->set in config
	Global userPort:Short = 4544
	'channelname the player uses ->set in config
	Global userChannelName:String = ""
	'language the player uses ->set in config
	Global userLanguage:String = "de"
	Global userDB:String = ""
	Global userFallbackIP:String = ""

	'title of the game
	Field title:String = "MyGame"

	'which cursor has to be shown? 0=normal 1=dragging
	Field cursorstate:Int = 0
	'0 = Mainmenu, 1=Running, ...
	Field gamestate:Int = -1

	'last sync
	Field stateSyncTime:Int	= 0
	'sync every
	Field stateSyncTimer:Int = 2000

	'refill movie agency every X Minutes
	Field refillMovieAgencyTimer:Int = 180
	'minutes till movie agency gets refilled again
	Field refillMovieAgencyTime:Int = 180

	'refill ad agency every X Minutes
	Field refillAdAgencyTimer:Int = 240
	'minutes till ad agency gets refilled again
	Field refillAdAgencyTime:Int = 240


	'--networkgame auf "isNetworkGame()" umbauen
	'are we playing a network game? 0=false, 1=true, 2
	Field networkgame:Int = 0
	'is the network game ready - all options set? 0=false
	Field networkgameready:Int = 0
	'playing over internet? 0=false
	Field onlinegame:Int = 0

	Global _instance:TGame
	Global _initDone:int = FALSE
	Global _firstGamePreparationDone:int = FALSE


	Method New()
		if not _initDone
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			EventManager.registerListenerFunction("SaveGame.OnBeginSave", onSaveGameBeginSave)

			_initDone = TRUE
		Endif
	End Method


	Function GetInstance:TGame()
		if not _instance then _instance = new TGame
		return _instance
	End Function


	'Summary: create a game, every variable is set to Zero
	Method Create:TGame(initializePlayer:Int = true, initializeRoom:Int = true)
		LoadConfig("config/settings.xml")
		'add German and English to possible language
		TLocalization.AddLanguages("de, en")
		'select language
		TLocalization.SetLanguage(userlanguage)
		TLocalization.LoadResource("res/lang/lang_"+userlanguage+".txt")

		networkgame = 0

		GetGametime().SetStartYear(1985)
		title = "unknown"

		SetRandomizerBase( Time.MillisecsLong() )

		If initializePlayer Then CreateInitialPlayers()

		'creates all Rooms - with the names assigned at this moment
		If initializeRoom Then Init_CreateAllRooms()

		Return self
	End Method




	'run this before EACH started game
	Function PrepareStart()
		'load all movies, news, series and ad-contracts
		TLogger.Log("Game.PrepareStart()", "loading database", LOG_DEBUG)
		LoadDatabase(userdb)

		TLogger.Log("Game.PrepareStart()", "colorizing images corresponding to playercolors", LOG_DEBUG)
		ColorizePlayerExtras()

		TLogger.Log("Game.PrepareStart()", "drawing door-sprites on the building-sprite", LOG_DEBUG)

		TRoomDoor.DrawDoorsOnBackground()

		TLogger.Log("Game.PrepareStart()", "drawing plants and lights on the building-sprite", LOG_DEBUG)
		GetBuilding().Init() 'also registers events...

		'eg reset things
	End Function


	'run this BEFORE the first game is started
	Function PrepareFirstGameStart:int()
		if _firstGamePreparationDone then return False

		GetPopularityManager().Initialize()
		GetBroadcastManager().Initialize()


		'TLogger.Log("TGame", "Creating ingame GUIelements", LOG_DEBUG)
		InGame_Chat = New TGUIChat.Create(new TPoint.Init(520, 418), new TPoint.Init(280,190), "InGame")
		InGame_Chat.setDefaultHideEntryTime(10000)
		InGame_Chat.guiList.backgroundColor = TColor.Create(0,0,0,0.2)
		InGame_Chat.guiList.backgroundColorHovered = TColor.Create(0,0,0,0.7)
		InGame_Chat.setOption(GUI_OBJECT_CLICKABLE, False)
		InGame_Chat.SetDefaultTextColor( TColor.Create(255,255,255) )
		InGame_Chat.guiList.autoHideScroller = True
		'reposition input
		InGame_Chat.guiInput.rect.position.setXY( 275, 387)
		InGame_Chat.guiInput.setMaxLength(200)
		InGame_Chat.guiInput.setOption(GUI_OBJECT_POSITIONABSOLUTE, True)
		InGame_Chat.guiInput.maxTextWidth = gfx_GuiPack.GetSprite("Chat_IngameOverlay").area.GetW() - 20
		InGame_Chat.guiInput.spriteName = "Chat_IngameOverlay"
		InGame_Chat.guiInput.color.AdjustRGB(255,255,255,True)
		InGame_Chat.guiInput.SetValueDisplacement(0,5)


		'===== EVENTS =====
		EventManager.registerListenerFunction("Game.OnDay", 	GameEvents.OnDay )
		EventManager.registerListenerFunction("Game.OnHour", 	GameEvents.OnHour )
		EventManager.registerListenerFunction("Game.OnMinute",	GameEvents.OnMinute )
		EventManager.registerListenerFunction("Game.OnStart",	TGame.onStart )


		'Game screens
		GameScreen_Building = New TInGameScreen_Building.Create("InGame_Building")
		ScreenCollection.Add(GameScreen_Building)

		PlayerDetailsTimer = 0

		'=== SETUP TOOLTIPS ===
		TTooltip.UseFontBold = GetBitmapFontManager().baseFontBold
		TTooltip.UseFont = GetBitmapFontManager().baseFont
		TTooltip.ToolTipIcons = GetSpriteFromRegistry("gfx_building_tooltips")
		TTooltip.TooltipHeader = GetSpriteFromRegistry("gfx_tooltip_header")

		'interface needs tooltip definition done
		Interface = TInterface.Create()


		'register ai player events - but only for game leader
		If Game.isGameLeader()
			EventManager.registerListenerFunction("Game.OnMinute", GameEvents.PlayersOnMinute)
			EventManager.registerListenerFunction("Game.OnDay", GameEvents.PlayersOnDay)
		EndIf

		'=== REGISTER PLAYER EVENTS ===
		EventManager.registerListenerFunction("PlayerFinance.onChangeMoney", GameEvents.PlayerFinanceOnChangeMoney)
		EventManager.registerListenerFunction("PlayerFinance.onTransactionFailed", GameEvents.PlayerFinanceOnTransactionFailed)
		EventManager.registerListenerFunction("StationMap.onTrySellLastStation", GameEvents.StationMapOnTrySellLastStation)
		EventManager.registerListenerFunction("BroadcastManager.BroadcastMalfunction", GameEvents.PlayerBroadcastMalfunction)

		'init finished
		_firstGamePreparationDone = True
	End Function




	Method PrepareNewGame:int()
		'=== FIGURES ===
		'set all non human players to AI
		If Game.isGameLeader()
			For Local playerids:Int = 1 To 4
				If GetPlayerCollection().IsPlayer(playerids) And Not GetPlayerCollection().IsHuman(playerids)
					GetPlayerCollection().Get(playerids).SetAIControlled("res/ai/DefaultAIPlayer.lua")
				EndIf
			Next
		EndIf

		'create npc figures
		New TFigureJanitor.Create("Hausmeister", GetSpriteFromRegistry("figure_Hausmeister"), 210, 2, 65)
		New TFigurePostman.Create("Bote1", GetSpriteFromRegistry("BoteLeer"), 210, 6, 65, 0)
		New TFigurePostman.Create("Bote2", GetSpriteFromRegistry("BoteLeer"), 410, 0, -65, 0)



		'=== STATION MAP ===
		'load the used map
		GetStationMapCollection().LoadMapFromXML("config/maps/germany.xml")

		'create base stations
		For Local i:Int = 1 To 4
			GetPlayerCollection().Get(i).GetStationMap().AddStation( TStation.Create( new TPoint.Init(310, 260),-1, GetStationMapCollection().stationRadius, i ), False )
		Next


		'get names from settings
		For Local i:Int = 1 To 4
			GetPlayerCollection().Get(i).Name = ScreenGameSettings.guiPlayerNames[i-1].Value
			GetPlayerCollection().Get(i).channelname = ScreenGameSettings.guiChannelNames[i-1].Value
		Next


		'create series/movies in movie agency
		RoomHandler_MovieAgency.GetInstance().ReFillBlocks()

		'8 auctionable movies/series
		For Local i:Int = 0 To 7
			New TAuctionProgrammeBlocks.Create(i, Null)
		Next


		'create random programmes and so on - but only if local game
		If Not Game.networkgame
			For Local playerids:Int = 1 To 4
				Local ProgrammeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollectionCollection().Get(playerids)
				For Local i:Int = 0 To Game.startMovieAmount-1
					ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_MOVIE))
				Next
				'give series to each player
				For Local i:Int = Game.startMovieAmount To Game.startMovieAmount + Game.startSeriesAmount-1
					ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_SERIES))
				Next
				'give 1 call in
				ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandomWithGenre(20))

				For Local i:Int = 0 To 2
					ProgrammeCollection.AddAdContract(New TAdContract.Create(TAdContractBase.GetRandomWithLimitedAudienceQuote(0, 0.15)) )
				Next
			Next
		EndIf

		'=== SETUP NEWS + ABONNEMENTS ===
		'adjust abonnement for each newsgroup to 1
		For Local playerids:Int = 1 To 4
			For Local i:Int = 0 To 4 '5 groups
				GetPlayerCollection().Get(playerids).SetNewsAbonnement(i, 1)
			Next
		Next

		'create 3 starting news
		GetNewsAgency().AnnounceNewNewsEvent(-60)
		GetNewsAgency().AnnounceNewNewsEvent(-120)
		GetNewsAgency().AnnounceNewNewsEvent(-120)

		'place them into the players news shows
		local newsToPlace:TNews
		For Local playerID:int = 1 to 4
			For local i:int = 0 to 2
				'attention: instead of using "GetNewsAtIndex(i)" we always
				'use (0) - as each "placed" news is removed from the collection
				'leaving the next on listIndex 0
				newsToPlace = GetPlayerProgrammeCollectionCollection().Get(playerID).GetNewsAtIndex(0)
				if not newsToPlace then throw "Game.PrepareNewGame: initial news " + i + " missing."

				'set it paid
				newsToPlace.paid = true
				'set planned
				GetPlayerProgrammePlanCollection().Get(playerID).SetNews(newsToPlace, i)
			Next
		Next



		'=== SETUP START PROGRAMME PLAN ===

		Local lastblocks:Int=0
		local playerCollection:TPlayerProgrammeCollection
		Local playerPlan:TPlayerProgrammePlan

		'creation of blocks for players rooms
		For Local playerids:Int = 1 To 4
			lastblocks = 0
			playerCollection = GetPlayerProgrammeCollectionCollection().Get(playerids)
			playerPlan = GetPlayerProgrammePlanCollection().Get(playerids)

			SortList(playerCollection.adContracts)

			Local addWidth:Int = GetSpriteFromRegistry("pp_programmeblock1").area.GetW()
			Local addHeight:Int = GetSpriteFromRegistry("pp_adblock1").area.GetH()

			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetGameTime().GetStartDay(), 0 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetGameTime().GetStartDay(), 1 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetGameTime().GetStartDay(), 2 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetGameTime().GetStartDay(), 3 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetGameTime().GetStartDay(), 4 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetGameTime().GetStartDay(), 5 )

			Local currentLicence:TProgrammeLicence = Null
			Local currentHour:Int = 0
			For Local i:Int = 0 To 3
				currentLicence = playerCollection.GetMovieLicenceAtIndex(i)
				If Not currentLicence Then Continue
				playerPlan.SetProgrammeSlot(TProgramme.Create(currentLicence), GetGameTime().GetStartDay(), currentHour )
				currentHour:+ currentLicence.getData().getBlocks()
			Next
		Next
	End Method


	Method StartNewGame:int()
		_Start(True)
	End Method


	Method StartLoadedSaveGame:int()
		_Start(False)
	End Method


	'run when a specific game starts
	Method _Start:int(startNewGame:int = TRUE)

		PrepareStart()
		if not _firstGamePreparationDone then PrepareFirstGameStart()

		'new games need some initializations
		if startNewGame then PrepareNewGame()

		'disable chat if not networkgaming
		If Not game.networkgame
			InGame_Chat.hide()
		Else
			InGame_Chat.show()
		EndIf


		'set force=true so the gamestate is set even if already in this
		'state (eg. when loaded)
		Game.SetGamestate(TGame.STATE_RUNNING, TRUE)
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Savegame loaded - colorize players.", LOG_DEBUG | LOG_SAVELOAD)
		'reconnect AI and other things
		For local player:TPlayer = eachin GetPlayerCollection().players
			player.onLoad(null)
		Next

		'set active player again (sets correct game screen)
		GetInstance().SetActivePlayer()
	End Function


	'run when starting saving a savegame
	Function onSaveGameBeginSave(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Start saving - inform AI.", LOG_DEBUG | LOG_SAVELOAD)
		'inform player AI that we are saving now
		For local player:TPlayer = eachin GetPlayerCollection().players
			If player.figure.isAI() then player.PlayerKI.CallOnSave()
		Next
	End Function


	Method SetPaused(bool:Int=False)
		GetGameTime().paused = bool
	End Method


	Method GetRandomizerBase:Int()
		Return randomSeedValue
	End Method


	Method SetRandomizerBase( value:Int=0 )
		randomSeedValue = value
		'seed the random base for MERSENNE TWISTER (seedrnd for the internal one)
		SeedRand(randomSeedValue)
	End Method


	'computes daily costs like station or newsagency fees for every player
	Method ComputeDailyCosts(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			'stationfees
			Player.GetFinance().PayStationFees( Player.GetStationMap().CalculateStationCosts())
			'interest rate for your current credit
			Player.GetFinance().PayCreditInterest( Player.GetFinance().credit * TPlayerFinance.creditInterestRate )

			'newsagencyfees
			Local newsagencyfees:Int =0
			For Local i:Int = 0 To 5
				newsagencyfees:+ TNewsAgency.GetNewsAbonnementPrice( Player.newsabonnements[i] )
			Next
			Player.GetFinance(day).PayNewsAgencies((newsagencyfees))
		Next
	End Method


	'computes daily income like account interest income
	Method ComputeDailyIncome(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			if Player.GetFinance().money > 0
				Player.GetFinance().EarnBalanceInterest( Player.GetFinance().money * TPlayerFinance.balanceInterestRate )
			Else
				'attention: multiply current money * -1 to make the
				'negative value an "positive one" - a "positive expense"
				Player.GetFinance().PayDrawingCreditInterest( -1 * Player.GetFinance().money * TPlayerFinance.drawingCreditRate )
			EndIf
		Next
	End Method


	'computes penalties for expired ad-contracts
	Method ComputeContractPenalties(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			For Local Contract:TAdContract = EachIn Player.GetProgrammeCollection().adContracts
				If Not contract Then Continue

				'0 days = "today", -1 days = ended
				If contract.GetDaysLeft() < 0
					Player.GetFinance(day).PayPenalty(contract.GetPenalty(), contract)
					Player.GetProgrammeCollection().RemoveAdContract(contract)
				EndIf
			Next
		Next
	End Method


	'creates the default players (as shown in game-settings-screen)
	Method CreateInitialPlayers()
		'Creating PlayerColors - could also be done "automagically"
		Local playerColors:TList = TList(GetRegistry().Get("playerColors"))
		If playerColors = Null Then Throw "no playerColors found in configuration"
		For Local col:TColor = EachIn playerColors
			col.AddToList()
		Next

		'create players, draws playerfigures on figures-image
		'TColor.GetByOwner -> get first unused color,
		'TPlayer.Create sets owner of the color
		SetPlayer(1, TPlayer.Create(1, userName, userChannelName, GetSpriteFromRegistry("Player1"),	250,  2, 90, TColor.getByOwner(0), 1, "Player 1"))
		SetPlayer(2, TPlayer.Create(2, "Sandra", "SunTV", GetSpriteFromRegistry("Player2"),	280,  5, 90, TColor.getByOwner(0), 0, "Player 2"))
		SetPlayer(3, TPlayer.Create(3, "Seidi", "FunTV", GetSpriteFromRegistry("Player3"),	240,  8, 90, TColor.getByOwner(0), 0, "Player 3"))
		SetPlayer(4, TPlayer.Create(4, "Alfi", "RatTV", GetSpriteFromRegistry("Player4"),	290, 13, 90, TColor.getByOwner(0), 0, "Player 4"))
		'set different figures for other players
		GetPlayer(2).UpdateFigureBase(9)
		GetPlayer(3).UpdateFigureBase(2)
		GetPlayer(4).UpdateFigureBase(6)
	End Method


	'Things to init directly after game started
	Function onStart:Int(triggerEvent:TEventBase)
	End Function


	Method IsGameLeader:Int()
		Return (Game.networkgame And Network.isServer) Or (Not Game.networkgame)
	End Method



	Method SetGameState:Int(gamestate:Int, force:int=False )
		If Self.gamestate = gamestate and not force Then Return True

		'switch to screen
		Select gamestate
			Case TGame.STATE_MAINMENU
				ScreenCollection.GoToScreen(Null,"MainMenu")
			Case TGame.STATE_SETTINGSMENU
				ScreenCollection.GoToScreen(Null,"GameSettings")
			Case TGame.STATE_NETWORKLOBBY
				ScreenCollection.GoToScreen(Null,"NetworkLobby")
			Case TGame.STATE_STARTMULTIPLAYER
				ScreenCollection.GoToScreen(Null,"StartMultiplayer")
			Case TGame.STATE_RUNNING
				'when a game is loaded we should try set the right screen
				'not just the default building screen
				if GetPlayerCollection().Get().figure.inRoom
					ScreenCollection.GoToScreen(ScreenCollection.GetCurrentScreen())
				else
					ScreenCollection.GoToScreen(GameScreen_Building)
				endif
		EndSelect


		'remove focus of gui objects
		GuiManager.ResetFocus()
		GuiManager.SetKeystrokeReceiver(Null)

		'reset mouse clicks
		MouseManager.ResetKey(1)
		MouseManager.ResetKey(2)


		Self.gamestate = gamestate
		Select gamestate
			Case TGame.STATE_RUNNING
					'Begin Game - fire Events
					EventManager.registerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", GetGameTime().GetMinute()).addNumber("hour", GetGameTime().GetHour()).addNumber("day", GetGameTime().getDay()) ))
					EventManager.registerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", GetGameTime().GetMinute()).addNumber("hour", GetGameTime().GetHour()).addNumber("day", GetGameTime().getDay()) ))
					'so we start at day "1"
					EventManager.registerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", GetGameTime().GetMinute()).addNumber("hour", GetGameTime().GetHour()).addNumber("day", GetGameTime().getDay()) ))

					'so we could add news etc.
					EventManager.triggerEvent( TEventSimple.Create("Game.OnStart") )

					TSoundManager.GetInstance().PlayMusicPlaylist("default")
			Default
				'
		EndSelect
	End Method


	'sets the player controlled by this client
	Method SetActivePlayer(ID:int=-1)
		if ID = -1 then ID = GetPlayerCollection().playerID
		'for debug purposes we need to adjust more than just
		'the playerID.
		GetPlayerCollection().playerID = ID

		'get currently shown screen of that player
		if GetPlayer().figure.inRoom
			ScreenCollection.GoToScreen(TInGameScreen_Room.GetByRoom(GetPlayer().figure.inRoom))
		'go to building
		else
			ScreenCollection.GoToScreen(GameScreen_Building)
		endif
	End Method


	Method SetPlayer:TPlayer(playerID:Int=-1, player:TPlayer)
		GetPlayerCollection().Set(playerID, player)
	End Method


	Method GetPlayer:TPlayer(playerID:Int=-1)
		return GetPlayerCollection().Get(playerID)
	End Method


	'return the maximum audience of a player
	'if no playerID was given, the average of all players is returned
	Method GetMaxAudience:Int(playerID:Int=-1)
		If Not GetPlayerCollection().isPlayer(playerID)
			Local avg:Int = 0
			For Local i:Int = 1 To 4
				avg :+ GetPlayerCollection().Get(i).GetMaxAudience()
			Next
			avg:/4
			Return avg
		EndIf
		Return GetPlayerCollection().Get(playerID).GetMaxAudience()
	End Method


	Function SendSystemMessage(message:String)
		'send out to chats
		EventManager.triggerEvent(TEventSimple.Create("chat.onAddEntry", new TData.AddNumber("senderID", -1).AddNumber("channels", CHAT_CHANNEL_SYSTEM).AddString("text", message) ) )
	End Function


	'Summary: load the config-file and set variables depending on it
	Method LoadConfig:Byte(configfile:String="config/settings.xml")
		Local xml:TxmlHelper = TxmlHelper.Create(configfile)
		If xml <> Null Then TLogger.Log("TGame.LoadConfig()", "settings.xml read", LOG_LOADING)
		Local node:TxmlNode = xml.FindRootChild("settings")
		If node = Null Or node.getName() <> "settings"
			TLogger.Log("TGame.Loadconfig()", "settings.xml misses a setting-part", LOG_LOADING | LOG_ERROR)
			Print "settings.xml fehlt der settings-Bereich"
			Return 0
		EndIf
		username			= xml.FindValue(node,"username", "Ano Nymus")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'username' fehlt, setze Defaultwert: 'Ano Nymus'", LOG_LOADING)
		userchannelname		= xml.FindValue(node,"channelname", "SunTV")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'userchannelname' fehlt, setze Defaultwert: 'SunTV'", LOG_LOADING)
		userlanguage		= xml.FindValue(node,"language", "de")			'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'language' fehlt, setze Defaultwert: 'de'", LOG_LOADING)
		userport			= xml.FindValueInt(node,"onlineport", 4444)		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'onlineport' fehlt, setze Defaultwert: '4444'", LOG_LOADING)
		userdb				= xml.FindValue(node,"database", "res/database.xml")	'Print "settings.xml - missing 'database' - set to default: 'database.xml'"
		title				= xml.FindValue(node,"defaultgamename", "MyGame")		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'defaultgamename' fehlt, setze Defaultwert: 'MyGame'", LOG_LOADING)
		userFallbackIP		= xml.FindValue(node,"fallbacklocalip", "192.168.0.1")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'fallbacklocalip' fehlt, setze Defaultwert: '192.168.0.1'", LOG_LOADING)
	End Method


	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		local gameTime:TGameTime = GetGameTime()
		'==== ADJUST TIME ====
		gameTime.Update()

		'==== HANDLE TIMED EVENTS ====
		'time for news ?
		If GetNewsAgency().NextEventTime < gameTime.timeGone Then GetNewsAgency().AnnounceNewNewsEvent()
		If GetNewsAgency().NextChainCheckTime < gameTime.timeGone Then GetNewsAgency().ProcessNewsEventChains()

		'send state to clients
		If IsGameLeader() And networkgame And stateSyncTime < Time.GetTimeGone()
			NetworkHelper.SendGameState()
			stateSyncTime = Time.GetTimeGone() + stateSyncTimer
		EndIf

		'==== HANDLE IN GAME TIME ====
		'less than a ingame minute gone? nothing to do YET
		If gameTime.timeGone - gameTime.timeGoneLastUpdate < 1.0 Then Return

		'==== HANDLE GONE/SKIPPED MINUTES ====
		'if speed is to high - minutes might get skipped,
		'handle this case so nothing gets lost.
		'missedMinutes is >1 in all cases (else this part isn't run)
		Local missedMinutes:float = gameTime.timeGone - gameTime.timeGoneLastUpdate
		Local daysMissed:Int = Floor(missedMinutes / (24*60))

		'adjust the game time so GetGameTime().GetHour()/GetMinute()/... return
		'the correct value for each loop cycle. So Functions can rely on
		'that functions to get the time they request.
		'as everything can get calculated using "timeGone", no further
		'adjustments have to take place
		gameTime.timeGone:- missedMinutes
		For Local i:Int = 1 to missedMinutes
			'add back another gone minute each loop
			gameTime.timeGone:+1

			'day
			If gameTime.GetHour() = 0 And gameTime.GetMinute() = 0
				'increase current day
				gameTime.daysPlayed :+1
			 	'automatically change current-plan-day on day change
			 	'but do it silently (without affecting the)
			 	RoomHandler_Office.ChangePlanningDay(gameTime.GetDay())

				EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", gameTime.GetMinute()).addNumber("hour", gameTime.GetHour()).addNumber("day", gameTime.GetDay()) ))
			EndIf

			'hour
			If gameTime.GetMinute() = 0
				EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", gameTime.GetMinute()).addNumber("hour", gameTime.GetHour()).addNumber("day", gameTime.GetDay()) ))
			endif

			'minute
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", gameTime.GetMinute()).addNumber("hour", gameTime.GetHour()).addNumber("day", gameTime.GetDay()) ))
		Next

		'reset gone time so next update can calculate missed minutes
		gameTime.timeGoneLastUpdate = gameTime.timeGone
	End Method
End Type