﻿
Global debugAudienceInfos:TDebugAudienceInfos = New TDebugAudienceInfos
Type TDebugAudienceInfos
	Field currentStatement:TBroadcastFeedbackStatement
	Field lastCheckedMinute:Int

	Method Draw()
		SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetColor 255, 255, 255

		'GetBitmapFontManager().baseFont.Draw("Bevölkerung", 25, startY)

		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( GetPlayerCollection().playerID )

		Local x:Int = 200
		Local y:Int = 25
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		GetBitmapFontManager().baseFont.drawBlock("|b|Taste |color=255,100,0|~qQ~q|/color| drücken|/b| um (Debug-)Quotenbildschirm wieder auszublenden.", 0, 355, GetGraphicsManager().GetWidth(), 25, ALIGN_CENTER_CENTER, TColor.clRed)

		font.drawBlock("Gesamt", x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
		font.drawBlock("Kinder", x + (70*1), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Jugendliche", x + (70*2), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Hausfrau.", x + (70*3), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Arbeitneh.", x + (70*4), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Arbeitslose", x + (70*5), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Manager", x + (70*6), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Rentner", x + (70*7), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)


		font.Draw("Bevölkerung", 25, 50, TColor.clWhite);
		DrawAudience(audienceResult.WholeMarket, 200, 50);

		Local percent:String = MathHelper.NumberToString(audienceResult.GetPotentialMaxAudienceQuotePercentage()*100,2) + "%"
		font.Draw("Potentielle Zuschauer", 25, 70, TColor.clWhite);
		font.Draw(percent, 160, 70, TColor.clWhite);
		DrawAudience(audienceResult.PotentialMaxAudience, 200, 70);

		local colorLight:TColor = TColor.CreateGrey(150)

		'font.drawStyled("      davon Exklusive", 25, 90, TColor.clWhite);
		'DrawAudience(audienceResult.ExclusiveAudienceSum, 200, 90, true);

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 105, colorLight);
		'DrawAudience(audienceResult.AudienceFlowSum, 200, 105, true);

		'font.drawStyled("      davon Zapper", 25, 120, colorLight);
		'DrawAudience(audienceResult.ChannelSurferToShare, 200, 120, true);


		font.Draw("Aktuelle Zuschauerzahl", 25, 90, TColor.clWhite);
		percent = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage()*100,2) + "%"
		font.Draw(percent, 160, 90, TColor.clWhite);
		DrawAudience(audienceResult.Audience, 200, 90);

		'font.drawStyled("      davon Exklusive", 25, 155, colorLight);
		'DrawAudience(audienceResult.ExclusiveAudience, 200, 155, true);

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 170, colorLight);
		'DrawAudience(audienceResult.AudienceFlow, 200, 170, true);

		'font.drawStyled("      davon Zapper", 25, 185, colorLight);
		'DrawAudience(audienceResult.ChannelSurfer, 200, 185, true);







		Local attraction:TAudienceAttraction = audienceResult.AudienceAttraction
		Local genre:String = "kein Genre"
		Select attraction.BroadcastType
			case TVTBroadcastMaterialType.PROGRAMME
				If (attraction.BaseAttraction <> Null and attraction.genreDefinition)
					genre = GetLocale("PROGRAMME_GENRE_"+TVTProgrammeGenre.GetAsString(attraction.genreDefinition.referenceID))
				Endif
			case TVTBroadcastMaterialType.ADVERTISEMENT
				If (attraction.BaseAttraction <> Null)
					genre = GetLocale("INFOMERCIAL")
				Endif
			case TVTBroadcastMaterialType.NEWSSHOW
				If (attraction.BaseAttraction <> Null)
					genre = "News-Genre-Mix"
				Endif
		End Select

		Local offset:Int = 110

		GetBitmapFontManager().baseFontBold.drawStyled("Sendung: " + audienceResult.Title + "     (" + genre + ")", 25, offset, TColor.clRed);
		offset :+ 20

		font.Draw("1. Programmqualität & Aktual.", 25, offset, TColor.clWhite)
		If attraction.Quality
			DrawAudiencePercent(new TAudience.InitValue(attraction.Quality,  attraction.Quality), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("2. * Zielgruppenattraktivität", 25, offset, TColor.clWhite)
		if attraction.GetTargetGroupAttractivity()
			DrawAudiencePercent(attraction.GetTargetGroupAttractivity(), 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("3. * TrailerMod", 25, offset, TColor.clWhite)
		If attraction.TrailerMod
			font.drawBlock(genre, 60, offset, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.TrailerMod.Copy().MultiplyFloat(TAudienceAttraction.MODINFLUENCE_TRAILER).AddFloat(1), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("4. + Sonstige Mods", 25, offset, TColor.clWhite)
		If attraction.MiscMod
			DrawAudiencePercent(attraction.MiscMod, 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("5. * SenderimageMod", 25, offset, TColor.clWhite)
		If attraction.PublicImageMod
			DrawAudiencePercent(attraction.PublicImageMod.Copy().AddFloat(1.0), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("6. + Zuschauerentwicklung (inaktiv)", 25, offset, TColor.clWhite)
	'	DrawAudiencePercent(new TAudience.InitValue(-1, attraction.QualityOverTimeEffectMod), 200, offset, true, true)
		offset :+ 20

		font.Draw("7. + Glück / Zufall", 25, offset, TColor.clWhite)
		If attraction.LuckMod
			DrawAudiencePercent(attraction.LuckMod, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("8. + Audience Flow Bonus", 25, offset, TColor.clWhite)
		if attraction.AudienceFlowBonus
			DrawAudiencePercent(attraction.AudienceFlowBonus, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("9. * Genreattraktivität (zeitabh.)", 25, offset, TColor.clWhite)
		if attraction.GetGenreAttractivity()
			DrawAudiencePercent(attraction.GetGenreAttractivity(), 200, offset, true, true)
		endif
		offset :+ 20
	
		font.Draw("10. + Sequence", 25, offset, TColor.clWhite)
		If attraction.SequenceEffect
			DrawAudiencePercent(attraction.SequenceEffect, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("Finale Attraktivität (Effektiv)", 25, offset, TColor.clRed)
		If attraction.FinalAttraction
			DrawAudiencePercent(attraction.FinalAttraction, 200, offset, false, true)
		endif
rem
		font.Draw("Basis-Attraktivität", 25, offset+230, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BaseAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BaseAttraction, 200, offset+230, false, true);
		Endif
		endrem
		rem
		endrem

		rem
		font.Draw("10. Nachrichteneinfluss", 25, offset+330, TColor.clWhite)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.NewsShowBonus Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.NewsShowBonus, 200, offset+330, true, true);
		Endif
		endrem

		rem
		font.Draw("Block-Attraktivität", 25, offset+290, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BlockAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BlockAttraction, 200, offset+290, false, true);
		Endif
		endrem



		rem
		font.Draw("Ausstrahlungs-Attraktivität", 25, offset+270, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BroadcastAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BroadcastAttraction, 200, offset+270, false, true);
		Endif
		endrem

		Local currBroadcast2:TBroadcast = GetBroadcastManager().GetCurrentBroadcast()
		Local feedback:TBroadcastFeedback = currBroadcast2.GetFeedback(GetPlayerCollection().playerID)

		Local minute:Int = GetWorldTime().GetDayMinute()

		If ((minute Mod 5) = 0)
			If Not (self.lastCheckedMinute = minute)
				self.lastCheckedMinute = minute
				currentStatement = null
				'DebugStop
			End If
		Endif

		If Not currentStatement Then
			currentStatement:TBroadcastFeedbackStatement = feedback.GetNextAudienceStatement()
		Endif

		SetColor 0,0,0
		DrawRect(520,415,250,40)
		font.Draw("Statements: " + feedback.AudienceInterest.ToStringMinimal(), 530, 420, TColor.clRed);
		font.Draw("Statements: " + feedback.FeedbackStatements.Count(), 530, 430, TColor.clRed);
		If currentStatement Then
			font.Draw(currentStatement.ToString(), 530, 440, TColor.clRed);
		Endif

		SetColor 255,255,255


rem
		font.Draw("Genre <> Sendezeit", 25, offset+240, TColor.clWhite)
		Local genreTimeMod:string = MathHelper.NumberToString(attraction.GenreTimeMod  * 100,2) + "%"
		Local genreTimeQuality:string = MathHelper.NumberToString(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 160, offset+240, TColor.clWhite)
		font.drawBlock(genreTimeQuality, 200, offset+240, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)

		'Nur vorübergehend
		font.Draw("Trailer-Mod", 25, offset+250, TColor.clWhite)
		Local trailerMod:String = MathHelper.NumberToString(attraction.TrailerMod  * 100,2) + "%"
		Local trailerQuality:String = MathHelper.NumberToString(attraction.TrailerQuality * 100,2) + "%"
		font.Draw(trailerMod, 160, offset+250, TColor.clWhite)
		font.drawBlock(trailerQuality, 200, offset+250, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)



		font.Draw("Image", 25, offset+295, TColor.clWhite);
		font.Draw("100%", 160, offset+295, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+295);

		font.Draw("Effektive Attraktivität", 25, offset+325, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+325)
endrem
	End Method


	Function DrawAudience(audience:TAudience, x:Int, y:Int, gray:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		val = TFunctions.convertValue(audience.GetTotalSum(), 2)
		If gray Then
			font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.Create(150, 80, 80))
		Else
			font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
		End If

		for local i:int = 1 to TVTTargetGroup.baseGroupCount
			val = TFunctions.convertValue(audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)), 2)
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, ALIGN_RIGHT_TOP, color)
		next
	End Function


	Function DrawAudiencePercent(audience:TAudience, x:Int, y:Int, gray:Int = false, hideAverage:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		If Not hideAverage Then
			val = MathHelper.NumberToString(audience.GetWeightedAverage(),2)
			If gray Then
				font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.Create(150, 80, 80))
			Else
				font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
			End If
		End if

		for local i:int = 1 to TVTTargetGroup.baseGroupCount
			val = MathHelper.NumberToString(0.5 * audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)),2)
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, ALIGN_RIGHT_TOP, color)
		Next
	End Function
End Type