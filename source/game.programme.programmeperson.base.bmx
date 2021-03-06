SuperStrict
Import Brl.Map
Import Brl.Math
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"
Import "game.programme.programmerole.bmx"




Type TProgrammePersonBaseCollection
	Field insignificant:TMap = CreateMap()
	Field celebrities:TMap = CreateMap()
	Field insignificantCount:int = -1 {nosave}
	Field celebritiesCount:int = -1 {nosave}
	Global _instance:TProgrammePersonBaseCollection


	Function GetInstance:TProgrammePersonBaseCollection()
		if not _instance then _instance = new TProgrammePersonBaseCollection
		return _instance
	End Function


	Method Initialize:TProgrammePersonBaseCollection()
		insignificant.Clear()
		insignificantCount = -1

		celebrities.Clear()
		celebritiesCount = -1

		return self
	End Method


	Method GetByGUID:TProgrammePersonBase(GUID:String)
		local result:TProgrammePersonBase
		result = TProgrammePersonBase(insignificant.ValueForKey(GUID))
		if not result
			result = TProgrammePersonBase(celebrities.ValueForKey(GUID))
		endif
		return result
	End Method
	

	Method GetInsignificantByGUID:TProgrammePersonBase(GUID:String)
		Return TProgrammePersonBase(insignificant.ValueForKey(GUID))
	End Method


	Method GetCelebrityByGUID:TProgrammePersonBase(GUID:String)
		Return TProgrammePersonBase(celebrities.ValueForKey(GUID))
	End Method


	'deprecated - used for v2-database
	Method GetCelebrityByName:TProgrammePersonBase(firstName:string, lastName:string)
		firstName = firstName.toLower()
		lastName = lastName.toLower()

		For local person:TProgrammePersonBase = eachin celebrities.Values()
			if person.firstName.toLower() <> firstName then continue
			if person.lastName.toLower() <> lastName then continue
			return person
		Next
		return Null
	End Method


	'useful to fetch a random "amateur" (aka "layman")
	Method GetRandomInsignificant:TProgrammePersonBase(array:TProgrammePersonBase[] = null, onlyFictional:int = False)
		if array = Null or array.length = 0 then array = GetAllInsignificantAsArray(onlyFictional)
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method
	

	Method GetRandomCelebrity:TProgrammePersonBase(array:TProgrammePersonBase[] = null, onlyFictional:int = False)
		if array = Null or array.length = 0 then array = GetAllCelebritiesAsArray(onlyFictional)
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetAllInsignificantAsArray:TProgrammePersonBase[](onlyFictional:int = False)
		local array:TProgrammePersonBase[]
		'create a full array containing all elements
		For local obj:TProgrammePersonBase = EachIn insignificant.Values()
			if onlyFictional and not obj.fictional then continue
			array :+ [obj]
		Next
		return array
	End Method


	Method GetAllCelebritiesAsArray:TProgrammePersonBase[](onlyFictional:int = False)
		local array:TProgrammePersonBase[]
		'create a full array containing all elements
		For local obj:TProgrammePersonBase = EachIn celebrities.Values()
			if onlyFictional and not obj.fictional then continue
			array :+ [obj]
		Next
		return array
	End Method


	Method GetInsignificantCount:Int()
		if insignificantCount >= 0 then return insignificantCount

		insignificantCount = 0
		For Local person:TProgrammePersonBase = EachIn insignificant.Values()
			insignificantCount :+1
		Next
		return insignificantCount
	End Method


	Method GetCelebrityCount:Int()
		if celebritiesCount >= 0 then return celebritiesCount

		celebritiesCount = 0
		For Local person:TProgrammePersonBase = EachIn celebrities.Values()
			celebritiesCount :+1
		Next
		return celebritiesCount
	End Method


	Method RemoveInsignificant:int(person:TProgrammePersonBase)
		if person.GetGuid() and insignificant.Remove(person.GetGUID())
			'invalidate count
			insignificantCount = -1

			return True
		endif

		return False
	End Method
	
	Method RemoveCelebrity:int(person:TProgrammePersonBase)
		if person.GetGuid() and celebrities.Remove(person.GetGUID())
			'invalidate count
			celebritiesCount = -1

			return True
		endif

		return False
	End Method
	

	Method AddInsignificant:int(person:TProgrammePersonBase)
		insignificant.Insert(person.GetGUID(), person)
		'invalidate count
		insignificantCount = -1

		return TRUE
	End Method

	Method AddCelebrity:int(person:TProgrammePersonBase)
		celebrities.Insert(person.GetGUID(), person)
		'invalidate count
		celebritiesCount = -1

		return TRUE
	End Method
End Type
'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammePersonBaseCollection:TProgrammePersonBaseCollection()
	Return TProgrammePersonBaseCollection.GetInstance()
End Function

Function GetProgrammePersonBase:TProgrammePersonBase(guid:string)
	Return TProgrammePersonBaseCollection.GetInstance().GetByGUID(guid)
End Function




Type TProgrammePersonBase extends TGameObject
	field lastName:String = ""
	field firstName:String = ""
	field nickName:String = ""
	field job:int = 0
	'indicator for potential "upgrades" to become a celebrity
	field jobsDone:int = 0
	field canLevelUp:int = True
	field countryCode:string = ""
	field gender:int = 0
	'is this an real existing person or someone we imaginated for the game?
	field fictional:int = False
	'is the person currently filming something?
	field producingGUIDs:string[]


	'override to add another generic naming
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "programmeperson-"+id
		self.GUID = GUID
	End Method


	Method SerializeTProgrammePersonBaseToString:string()
		return StringHelper.EscapeString(lastName, ":") + "::" + ..
		       StringHelper.EscapeString(firstName, ":") + "::" + ..
		       StringHelper.EscapeString(nickName, ":") + "::" + ..
		       job + "::" + ..
		       jobsDone + "::" + ..
		       canLevelUp + "::" + ..
		       fictional + "::" + ..
		       StringHelper.EscapeString(",".Join(producingGUIDs), ":") + "::" + ..
		       id + "::" + ..
		       StringHelper.EscapeString(GUID, ":")
	End Method


	Method DeSerializeTProgrammePersonBaseFromString(text:String)
		local vars:string[] = text.split("::")
		if vars.length > 0 then lastName = StringHelper.UnEscapeString(vars[0])
		if vars.length > 1 then firstName = StringHelper.UnEscapeString(vars[1])
		if vars.length > 2 then nickName = StringHelper.UnEscapeString(vars[2])
		if vars.length > 3 then job = int(vars[3])
		if vars.length > 4 then jobsDone = int(vars[4])
		if vars.length > 5 then canLevelUp = int(vars[5])
		if vars.length > 6 then fictional = int(vars[6])
		if vars.length > 7 then producingGUIDs = StringHelper.UnEscapeString(vars[7]).split(",")
		if vars.length > 8 then id = int(vars[8])
		if vars.length > 9 then GUID = StringHelper.UnEscapeString(vars[9])
	End Method


	Method Compare:Int(o2:Object)
		Local p2:TProgrammePersonBase = TProgrammePersonBase(o2)
		If Not p2 Then Return 1
		if GetFullName() = p2.GetFullName() 
			if GetAge() > p2.GetAge() then return 1
			if GetAge() < p2.GetAge() then return -1
			return 0
		endif
        if GetFullName().ToLower() > p2.GetFullName().ToLower() return 1
        if GetFullName().ToLower() < p2.GetFullName().ToLower() return -1
        return 0
	End Method
	

	Method GetTopGenre:Int()
		'base persons does not have top genres (-> unspecified)
		return TVTProgrammeGenre.undefined
	End Method


	Method SetJob(job:Int, enable:Int=True)
		If enable
			self.job :| job
		Else
			self.job :& ~job
		EndIf
	End Method


	Method HasJob:int(job:int)
		return self.job & job
	End Method


	Method SetFirstName:Int(firstName:string)
		self.firstName = firstName
	End Method


	Method SetLastName:Int(lastName:string)
		self.lastName = lastName
	End Method


	Method SetNickName:Int(nickName:string)
		self.nickName = nickName
	End Method


	Method GetNickName:String()
		if nickName = "" then return firstName
		return nickName
	End Method


	Method GetFirstName:String()
		return firstName
	End Method


	Method GetLastName:String()
		return lastName
	End Method


	Method GetFullName:string()
		if self.lastName<>"" then return self.firstName + " " + self.lastName
		return self.firstName
	End Method


	Method GetAge:int()
		return -1
	End Method


	Method IsAlive:int()
		return True
	End Method


	Method IsBorn:int()
		return True
	End Method
	

	Method GetBaseFee:Int(jobID:int, blocks:int, channel:int=-1)
		Select jobID
			case TVTProgrammePersonJob.ACTOR
				return 5000
			case TVTProgrammePersonJob.SUPPORTINGACTOR
				return 2500
			case TVTProgrammePersonJob.HOST
			    return 1500
			case TVTProgrammePersonJob.DIRECTOR
				return 7500
			case TVTProgrammePersonJob.SCRIPTWRITER 
				return 4000
			case TVTProgrammePersonJob.MUSICIAN 
				return 2500
			case TVTProgrammePersonJob.REPORTER 
				return 1000
			case TVTProgrammePersonJob.GUEST 
				return 500
			default
				return 1000
		End Select
	End Method


	Method IsProducing:int(programmeDataGUID:string)
		For local guid:string = EachIn producingGUIDs
			if guid = programmeDataGUID then return True
		Next
		return False
	End Method


	Method StartProduction:int(programmeDataGUID:string)
		if not IsProducing(programmeDataGUID)
			producingGUIDs :+ [programmeDataGUID]
		endif

		'emit event so eg. news agency could react to it ("bla has a new job")
		'-> or to set them on the "scandals" list
		EventManager.triggerEvent(TEventSimple.Create("programmepersonbase.onStartProduction", New TData.addString("programmeDataGUID", programmeDataGUID), Self))
	End Method


	Method FinishProduction:int(programmeDataGUID:string)
		jobsDone :+ 1

		local newProducingGUIDs:string[]
		For local guid:string = EachIn producingGUIDs
			if guid = programmeDataGUID then continue
			newProducingGUIDs :+ [guid]
		Next

		'emit event so eg. news agency could react to it ("bla goes on holiday")
		EventManager.triggerEvent(TEventSimple.Create("programmepersonbase.onFinishProduction", New TData.addString("programmeDataGUID", programmeDataGUID), Self))
	End Method
End Type




'role/function a person had in a movie/series
Type TProgrammePersonJob
	'the person having done this job
	'using the GUID instead of "TProgrammePersonBase" allows to upgrade
	'a "normal" person to a "celebrity"
	Field personGUID:string

	'job is a bitmask for values defined in TVTProgrammePersonJob
	Field job:int = 0
	'maybe only female directors are allowed?
	Field gender:int = 0
	'allows limiting the job to specific heritages
	Field country:string = ""

	'only valid for actors
	Field roleGUID:string = ""


	Method Init:TProgrammePersonJob(personGUID:string, job:int, gender:int=0, country:string="", roleGUID:string="")
		self.personGUID = personGUID
		self.job = job
		self.gender = gender
		self.country = country

		self.roleGUID = roleGUID
		
		return self
	End Method


	Method SerializeTProgrammePersonJobToString:string()
		return StringHelper.EscapeString(personGUID, ":") + "::" +..
		       job + "::" +..
		       gender + "::" +..
		       StringHelper.EscapeString(country, ":") + "::" + ..
		       StringHelper.EscapeString(roleGUID, ":")
	End Method


	Method DeSerializeTProgrammePersonJobFromString(text:String)
		local vars:string[] = text.split("::")
		if vars.length > 0 then personGUID = StringHelper.UnEscapeString(vars[0])
		if vars.length > 1 then job = int(vars[1])
		if vars.length > 2 then gender = int(vars[2])
		if vars.length > 3 then country = StringHelper.UnEscapeString(vars[3])
		if vars.length > 4 then roleGUID = StringHelper.UnEscapeString(vars[4])
	End Method
	

	Method IsSimilar:int(otherJob:TProgrammePersonJob)
		if job <> otherJob.job then return False
		if personGUID <> otherJob.personGUID then return False 
		if roleGUID <> otherJob.roleGUID then return False
		if gender <> otherJob.gender then return False
		if country <> otherJob.country then return False
		return True
	End Method
End Type

