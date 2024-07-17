package;

import flixel.graphics.frames.FlxFrame;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import openfl.utils.Assets as OpenFlAssets;

import flash.system.System;
import openfl.Lib;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var pingSong:String = 'menuAudio';

	public static var psychEngineVersion:String = '0.4.1'; //This is also used for Discord RPC
	public var curSelected:Int = 0;

	var inContinue:Bool = false;

	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	private var curWeek:Int = 0;

	var logo:FlxSprite;

	var menuTexts:FlxTypedGroup<FlxText>;
	var weekTexts:FlxTypedGroup<FlxText>;

	private var camGame:FlxCamera;
	private var camHUD:FlxCamera;
	private var camAchievement:FlxCamera;

	var staticFilter:FlxSprite;
	
	var optionShit:Array<String> = ['Continue', #if ACHIEVEMENTS_ALLOWED 'Awards', #end #if !switch 'Donate', 'Fnati 2020', #end 'Settings', 'Quit'];

	var allTips:Array<Dynamic> =
	[
		['Pay attention to the radio'],
		['I recommend playing the tutorial if you have not played the original game.'],
		['It seems they have combined.\n Pay attention to its position, use your defenses accordingly.'],
	];

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		camGame.setFilters([ShadersHandler.chromaticAberration]);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		if(ClientPrefs.curSong != pingSong){
			FlxG.sound.playMusic(Paths.music(pingSong), 0.1);
			ClientPrefs.curSong = pingSong;
		}

		staticFilter = new FlxSprite();
		staticFilter.frames = Paths.getSparrowAtlas('StaticFilter');
		staticFilter.animation.addByPrefix('play', 'StaticFilter', 24, true);
		staticFilter.antialiasing = ClientPrefs.globalAntialiasing;
		staticFilter.animation.play('play');
		staticFilter.alpha = 0.3;
		staticFilter.setGraphicSize(Std.int(FlxG.width));
		staticFilter.updateHitbox();
		staticFilter.screenCenter();
		add(staticFilter);

		staticFilter.cameras = [camHUD];

		var mickey = new FlxSprite(500, 10);
		mickey.frames = Paths.getSparrowAtlas('Mickey_Menu');
		mickey.animation.addByPrefix('play', 'Mickey Idle', 24, true);
		mickey.animation.play('play');
		mickey.antialiasing = ClientPrefs.globalAntialiasing;
		mickey.alpha = 0.2;
		mickey.setGraphicSize(Std.int(mickey.width * 0.47));
		mickey.updateHitbox();
		add(mickey);

		logo = new FlxSprite(40, 40).loadGraphic(Paths.image('titlelogo'));
		add(logo);
		logo.setGraphicSize(Std.int(logo.width * 0.4));
		logo.updateHitbox();
		logo.antialiasing = ClientPrefs.globalAntialiasing;

		weekTexts = new FlxTypedGroup<FlxText>();
		add(weekTexts);

		menuTexts = new FlxTypedGroup<FlxText>();
		add(menuTexts);

		for (i in 0...optionShit.length)
		{
			var optionText = new FlxText(0, 300 + (i * 50), Std.int(FlxG.width * 0.4), optionShit[i], 32);
			optionText.setFormat('Calibri', 32, FlxColor.WHITE, CENTER);
			optionText.ID = i;
			menuTexts.add(optionText);		
			optionText.antialiasing = ClientPrefs.globalAntialiasing;
			optionText.updateHitbox();
		};

		for (i in 0...WeekData.weeksList.length)
			{
				if (!weekIsLocked(i))
					{
						var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
						WeekData.setDirectoryFromWeek(leWeek);

						var weekText:FlxText = new FlxText(340, 330 + (i * 50), leWeek.storyName, 32);
						weekText.font = 'Calibri';
						weekText.color = 0xFFFFFFFF;
						weekText.ID = i;
						weekTexts.add(weekText);
						weekText.antialiasing = ClientPrefs.globalAntialiasing;	
					}				
			}

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (!Achievements.achievementsUnlocked[achievementID][1] && leDate.getDay() == 5 && leDate.getHours() >= 18) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
			Achievements.achievementsUnlocked[achievementID][1] = true;
			giveAchievement();
			ClientPrefs.saveSettings();
		}
		#end

#if android
		addVirtualPad(UP_DOWN, A_B);
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	var achievementID:Int = 0;
	function giveAchievement() {
		add(new AchievementObject(achievementID, camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement ' + achievementID);
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if(inContinue){
			weekTexts.forEach(function(spr:FlxText){spr.visible = true;});
		}else{
			weekTexts.forEach(function(spr:FlxText){spr.visible = false;});
		}

		if (!selectedSomethin)
		{
			if(FlxG.random.bool(0.9)){logo.alpha = FlxG.random.float(0.2,1);}			
			if(FlxG.random.bool(0.8)){
				setChrome(0.06);
				new FlxTimer().start(0.1, function(tmr:FlxTimer){setChrome(0);});
			}
			if(FlxG.random.bool(0.1)){FlxG.sound.play(Paths.sound('MenuRandom/'+FlxG.random.int(1, 6)));}	

			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				if(inContinue){
					inContinue = false;
				}else{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));
					MusicBeatState.switchState(new TitleState());
				}				
			}

			if (controls.ACCEPT)
			{
				if(inContinue){
					FlxG.sound.play(Paths.sound('confirmMenu'));
		
						menuTexts.forEach(function(spr:FlxText){
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						});
		
						weekTexts.forEach(function(spr:FlxText)
						{
							if (curWeek != spr.ID)
							{
								FlxTween.tween(spr, {alpha: 0}, 0.4, {
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									}
								});
							}
							else
							{
								FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									selectWeek();
								});
							}
						});
				}else{
					if (optionShit[curSelected] == 'Donate'){
						CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
					}else if(optionShit[curSelected] == 'Fnati 2020'){
						CoolUtil.browserLoad('https://gamejolt.com/games/treasureislandofficial/222994');
					}
					else if(optionShit[curSelected] == 'Continue'){
						inContinue = true;
						changeItem();
					}else{
						selectedSomethin = true;
						FlxG.sound.play(Paths.sound('confirmMenu'));
		
						weekTexts.forEach(function(spr:FlxText){
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						});
		
						menuTexts.forEach(function(spr:FlxText)
						{
							if (curSelected != spr.ID)
							{
								FlxTween.tween(spr, {alpha: 0}, 0.4, {
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									}
								});
							}
							else
							{
								FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									var daChoice:String = optionShit[curSelected];
		
									switch (daChoice)
									{
										case 'Begin':
											curWeek = 0;
											selectWeek();
										case 'Awards':
											MusicBeatState.switchState(new AchievementsMenuState());
										case 'Credits':
											MusicBeatState.switchState(new CreditsState());
										case 'Settings':
											MusicBeatState.switchState(new OptionsState());
										case 'Quit':
											System.exit(0);
									}
								});
							}
						});
					}
				}				
			}
			#if desktop
			else if (FlxG.keys.justPressed.SEVEN)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

	}

	function changeItem(huh:Int = 0)
	{
		if(inContinue){
			curWeek += huh;

			if (curWeek >= weekTexts.length)
				curWeek = 0;
			if (curWeek < 0)
				curWeek = weekTexts.length - 1;

			weekTexts.forEach(function(spr:FlxText)
			{
				spr.alpha = 0.8;
				spr.updateHitbox();

				if (spr.ID == curWeek)
				{
					spr.alpha = 0.5;
				}
			});
		}else{
			curSelected += huh;

			if (curSelected >= menuTexts.length)
				curSelected = 0;
			if (curSelected < 0)
				curSelected = menuTexts.length - 1;

			menuTexts.forEach(function(spr:FlxText)
			{
				spr.alpha = 0.8;
				spr.updateHitbox();

				if (spr.ID == curSelected)
				{
					spr.alpha = 0.5;
				}
			});
		}		
	}

	function selectWeek()
	{
		if(ClientPrefs.keyBinds[12][0] != null && ClientPrefs.keyBinds[13][0] != null && ClientPrefs.keyBinds[14][0] != null){
			var dataWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
			WeekData.setDirectoryFromWeek(dataWeek);

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;

			var diffic = CoolUtil.difficultyStuff[0][1];
			if(diffic == null) diffic = '';

			PlayState.storyDifficulty = 0;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.weekName = dataWeek.storyName;
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				selectedSomethin = true;
				var back = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
				back.scrollFactor.set();
				back.screenCenter();
				add(back);
				staticFilter.visible = false;
				openSubState(new WeekIntroSubstate(PlayState.weekName, allTips[curWeek][0]));
			});
		}else{
			Lib.application.window.alert('Configure all your controls before starting.', 'Missing Controls');
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function weekIsLocked(weekNum:Int) {
		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[weekNum]);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}
}

class WeekIntroSubstate extends MusicBeatSubstate{

	var back:FlxSprite;

	var weekNames:FlxTypedGroup<FlxText>;
	var tips:FlxTypedGroup<FlxText>;

	var onTip:Bool = false;

	public function new(weekName:String, tip:String) {
		super();

		FlxG.sound.music.stop();

		var curTip = tip;

		back = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		back.scrollFactor.set();
		back.screenCenter();
		add(back);

		weekNames = new FlxTypedGroup<FlxText>();
		add(weekNames);

		tips = new FlxTypedGroup<FlxText>();
		add(tips);

		for(i in 0...3){
			switch(i){
				case 0:{
					var title = new FlxText(0,0, weekName, 120);
					title.font = 'Calibri';
					title.color = 0xFFFFFFFF;
					title.screenCenter();
					title.y -= 50;
					title.antialiasing = ClientPrefs.globalAntialiasing;	
					weekNames.add(title);

					var tip = new FlxText(0,0, FlxG.width - 20, 'Tip:\n' + curTip, 60);
					tip.font = 'Calibri';
					tip.alignment = 'center';
					tip.color = 0xFFFFFFFF;
					tip.alpha = 0;
					tip.screenCenter();
					tip.antialiasing = ClientPrefs.globalAntialiasing;	
					tips.add(tip);
				}

				case 1:{
					var hourText = new FlxText(0,0, '12:00 AM', 80);
					hourText.font = 'Calibri';
					hourText.color = 0xFFFFFFFF;
					hourText.screenCenter();
					hourText.y += 50;
					hourText.antialiasing = ClientPrefs.globalAntialiasing;	
					weekNames.add(hourText);

					var pressEnter = new FlxText(0,0, 'Press Enter to continue.', 40);
					pressEnter.font = 'Calibri';
					pressEnter.color = 0xFFFFFFFF;
					pressEnter.alpha = 0;
					pressEnter.screenCenter();
					pressEnter.y = FlxG.height - pressEnter.height - 20;
					pressEnter.antialiasing = ClientPrefs.globalAntialiasing;	
					tips.add(pressEnter);
				}
			}			
		}

		FlxG.sound.play(Paths.sound('CamFlash'), 1);
		FlxG.camera.flash(FlxColor.WHITE, 1, null, true);

		new FlxTimer().start(3, function(tmr:FlxTimer){
			weekNames.forEach(function(spr:FlxText){
				FlxTween.tween(spr, {alpha: 0}, 3, {ease: FlxEase.backIn});
			});			
		});

		new FlxTimer().start(5, function(tmr:FlxTimer){
			onTip = true;
			FlxG.sound.play(Paths.sound('MenuRandom/'+FlxG.random.int(1, 6)));
			tips.forEach(function(spr:FlxText){
				FlxTween.tween(spr, {alpha: 1}, 3, {ease: FlxEase.backIn});
			});					
		});
	}

	override function update(elapsed:Float)
		{
			#if android
                var justTouched:Bool = false;

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				justTouched = true;
			}
		}
		#end
			if (controls.ACCEPT #if android || justTouched #end && onTip)
			{				
				tips.forEach(function(spr:FlxText){
					FlxTween.tween(spr, {alpha: 0}, 3, {
						onComplete: function(tween:FlxTween)
						{
							LoadingState.loadAndSwitchState(new PlayState(), true);	
						},
					});
				});		
			}

			super.update(elapsed);
		}
}
