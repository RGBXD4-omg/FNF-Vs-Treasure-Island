package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;

import Controls;

using StringTools;

// TO DO: Redo the menu creation system for not being as dumb
class OptionsState extends MusicBeatState
{
	var options:Array<Dynamic> = [
		[-1 , 'Preference', 62],
		[-1 , 'GRAPHICS', 40],
		[0 , 'Low Quality', 32],
		[0 , 'Anti-Aliasing', 32],
		[0 , 'Persistent Cached Data', 32],
		#if !html5
		[1 , 'Framerate', 32], //Apparently 120FPS isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		#end
		[-1 , 'GAMEPLAY', 40],
		[0 , 'Downscroll', 32],
		[0 , 'Ghost Tapping', 32],
		[1 , 'Note Delay', 32],
		[0 , 'Note Splashes', 32],
		[0 , 'Hide HUD', 32],
		[0 , 'Flashing Lights', 32],
		[0 , 'Camera Zooms', 32],
		#if !mobile
		[0 , 'FPS Counter', 32],
		#end
		[-1 , 'OTHER', 40],
		[0 , 'Facecam Mode', 32],
		[1 , 'Change Facecam Position', 16],
		[1 , 'Customize Notes', 32],
		[-1, '', 60],
		[-1, 'Preference', 1],
		[-1 , 'Controls', 62],
		[-1 , 'NOTES', 40],
		[2 , ClientPrefs.keyBinds[0][1], 32, 0, 1],
		[2 , ClientPrefs.keyBinds[1][1], 32, 2, 3],
		[2 , ClientPrefs.keyBinds[2][1], 32, 4, 5],
		[2 , ClientPrefs.keyBinds[3][1], 32, 6, 7],
		[-1 , 'UI', 40],
		[2 , ClientPrefs.keyBinds[4][1], 32, 8, 9],
		[2 , ClientPrefs.keyBinds[5][1], 32, 10, 11],
		[2 , ClientPrefs.keyBinds[6][1], 32, 12, 13],
		[2 , ClientPrefs.keyBinds[7][1], 32, 14, 15],
		[-1 , '', 16],
		[2 , ClientPrefs.keyBinds[8][1], 32, 16, 17],
		[2 , ClientPrefs.keyBinds[9][1], 32, 18, 19],
		[2 , ClientPrefs.keyBinds[10][1], 32, 20, 21],
		[2 , ClientPrefs.keyBinds[11][1], 32, 22, 23],
		[-1 , 'MECHANICS', 40],
		[2 , ClientPrefs.keyBinds[12][1], 32, 24, 25],
		[2 , ClientPrefs.keyBinds[13][1], 32, 26, 27],
		[2 , ClientPrefs.keyBinds[14][1], 32, 28, 29],
		[-1 , '', 16],
		[1 , 'Reset to Default', 32],
		[-1 , 'Controls', 1]
	];

	private var grpOptions:FlxTypedGroup<FlxText>;

	//CheckBox
	private var checkboxArray:Array<CheckboxThingie> = [];
	private var checkboxNumber:Array<Int> = [];

	//Inputs
	private var controlArray:Array<FlxKey> = [];
	var rebindingKey:Int = -1;

	var descText:FlxText;

	private var curSelected:Int = 2;
	private var isAlt:Bool;
	private static var changed:Int = 1;

	public var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	private var camFollow:FlxObject;

	var staticFilter:FlxSprite;

	override function create() {

		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];

		camGame.setFilters([ShadersHandler.chromaticAberration]);

		staticFilter = new FlxSprite();
		staticFilter.frames = Paths.getSparrowAtlas('StaticFilter');
		staticFilter.animation.addByPrefix('play', 'StaticFilter', 24, true);
		staticFilter.animation.play('play');
		staticFilter.alpha = 0.3;
		staticFilter.setGraphicSize(Std.int(FlxG.width));
		staticFilter.updateHitbox();
		staticFilter.screenCenter();
		add(staticFilter);

		staticFilter.cameras = [camHUD];

		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		controlArray = ClientPrefs.lastControls.copy();

		var size:Float = 0;
		for (i in 0...options.length)
		{
			var optionText = new FlxText(10, 0, Std.int(FlxG.width), options[i][1], options[i][2]);
			optionText.setFormat('Calibri', options[i][2], FlxColor.WHITE);
			optionText.antialiasing = ClientPrefs.globalAntialiasing;
			optionText.ID = i;
			optionText.y =  10 + size;
			size += options[i][2];
			
			if(options[i][0] == -1){optionText.alignment = 'center';}else{optionText.x += 50;}

			switch(options[i][0]){
				case 0:{
					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x, optionText.y, false);
					checkbox.alpha = 0.5;
					checkbox.sprTracker = optionText;
					checkboxArray.push(checkbox);
					checkboxNumber.push(i);
					add(checkbox);
				}
			}
			optionText.updateHitbox();
			grpOptions.add(optionText);	
		}

		descText =  new FlxText(FlxG.width - (FlxG.width / 3) - 20, 20, Std.int(FlxG.width / 3), '', 32);
		descText.setFormat('Calibri', 32, FlxColor.WHITE, CENTER);
		descText.antialiasing = ClientPrefs.globalAntialiasing;
		add(descText);

		changeSelection();
		reloadValues();

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 1);
		FlxG.camera.focusOn(camFollow.getPosition());

		#if android
		addVirtualPad(FULL, A_B);
		addPadCamera();
		#end

		super.create();
	}

	override function openSubState(SubState:FlxSubState){
		staticFilter.visible = false;

		super.openSubState(SubState);	
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var bindingTime:Float = 0;
	override function update(elapsed:Float) {

		if(FlxG.random.bool(0.8)){
			setChrome(0.06);
			new FlxTimer().start(0.1, function(tmr:FlxTimer){setChrome(0);});
		}

		if(options[curSelected][0] < 0){
			changeSelection(changed);
		}

		if(rebindingKey < 0) {
			if (controls.UI_UP_P) {
				changeSelection(-1);
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
			}
	
			if (controls.BACK) {
				ClientPrefs.reloadControls(controlArray);
				staticFilter.visible = true;	
				ClientPrefs.saveSettings();
				reloadValues();
				changeSelection();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
	
			if(controls.ACCEPT && nextAccept <= 0){
				switch(options[curSelected][0]){
					case 0, 1:{
						switch(options[curSelected][1]){
							case 'FPS Counter':
								ClientPrefs.showFPS = !ClientPrefs.showFPS;
								if(Main.fpsVar != null)
									Main.fpsVar.visible = ClientPrefs.showFPS;
			
							case 'Low Quality':
								ClientPrefs.lowQuality = !ClientPrefs.lowQuality;
			
							case 'Anti-Aliasing':
								ClientPrefs.globalAntialiasing = !ClientPrefs.globalAntialiasing;
								for (item in grpOptions) {
									item.antialiasing = ClientPrefs.globalAntialiasing;
								}
								for (i in 0...checkboxArray.length) {
									var spr:CheckboxThingie = checkboxArray[i];
									if(spr != null) {
										spr.antialiasing = ClientPrefs.globalAntialiasing;
									}
								}
			
							case 'Note Splashes':
								ClientPrefs.noteSplashes = !ClientPrefs.noteSplashes;
			
							case 'Flashing Lights':
								ClientPrefs.flashing = !ClientPrefs.flashing;
			
							case 'Violence':
								ClientPrefs.violence = !ClientPrefs.violence;
			
							case 'Swearing':
								ClientPrefs.cursing = !ClientPrefs.cursing;
			
							case 'Downscroll':
								ClientPrefs.downScroll = !ClientPrefs.downScroll;
			
							case 'Middlescroll':
								ClientPrefs.middleScroll = !ClientPrefs.middleScroll;
			
							case 'Ghost Tapping':
								ClientPrefs.ghostTapping = !ClientPrefs.ghostTapping;
			
							case 'Camera Zooms':
								ClientPrefs.camZooms = !ClientPrefs.camZooms;
			
							case 'Hide HUD':
								ClientPrefs.hideHud = !ClientPrefs.hideHud;
			
							case 'Persistent Cached Data':
								ClientPrefs.imagesPersist = !ClientPrefs.imagesPersist;
								FlxGraphic.defaultPersist = ClientPrefs.imagesPersist;
							
							case 'Hide Song Length':
								ClientPrefs.hideTime = !ClientPrefs.hideTime;
			
							case 'Reset to Default':{
								controlArray = ClientPrefs.defaultKeys.copy();
								reloadValues();
								changeSelection();
							}
							case 'Customize Notes':{
								openSubState(new NotesSubstate());
							}
							case 'Facecam Mode':{
								if(ClientPrefs.faceCam == -1){
									openSubState(new FacecamSubstate());
								}else{
									ClientPrefs.faceCam = -1;
								}								
							}
							case 'Change Facecam Position':{
								openSubState(new FacecamSubstate());
							}
						}
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					case 2:{
						bindingTime = 0;
						rebindingKey = getSelectedKey();
						if(rebindingKey > -1) {
							FlxG.sound.play(Paths.sound('scrollMenu'));
						} else {
							FlxG.log.warn('Error! No input found/badly configured');
							FlxG.sound.play(Paths.sound('cancelMenu'));
						}
					}
				}			
				reloadValues();
			}
	
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
				if(options[curSelected][0] == 2){
				isAlt = !isAlt;
				reloadValues();
				}
			}
	
			if(controls.UI_LEFT || controls.UI_RIGHT){
				var add:Int = controls.UI_LEFT ? -1 : 1;
				if(holdTime > 0.5 || controls.UI_LEFT_P || controls.UI_RIGHT_P)
				switch(options[curSelected][1]) {
					case 'Framerate':
						ClientPrefs.framerate += add;
						if(ClientPrefs.framerate < 60) ClientPrefs.framerate = 60;
						else if(ClientPrefs.framerate > 240) ClientPrefs.framerate = 240;
	
						if(ClientPrefs.framerate > FlxG.drawFramerate) {
							FlxG.updateFramerate = ClientPrefs.framerate;
							FlxG.drawFramerate = ClientPrefs.framerate;
						} else {
							FlxG.drawFramerate = ClientPrefs.framerate;
							FlxG.updateFramerate = ClientPrefs.framerate;
						}
					case 'Note Delay':
						var mult:Int = 1;
						if(holdTime > 1.5) { //Double speed after 1.5 seconds holding
							mult = 2;
						}
						ClientPrefs.noteOffset += add * mult;
						if(ClientPrefs.noteOffset < 0) ClientPrefs.noteOffset = 0;
						else if(ClientPrefs.noteOffset > 500) ClientPrefs.noteOffset = 500;
				}
				reloadValues();
	
				if(holdTime <= 0) FlxG.sound.play(Paths.sound('scrollMenu'));
				holdTime += elapsed;
			}
		}else{
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1) {
				controlArray[rebindingKey] = keyPressed;
				var opposite:Int = rebindingKey + (rebindingKey % 2 == 1 ? -1 : 1);
				trace('Rebinded key with ID: ' + rebindingKey + ', Opposite is: ' + opposite);
				if(controlArray[opposite] == controlArray[rebindingKey]) {
					controlArray[opposite] = NONE;
				}

				reloadValues();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				rebindingKey = -1;
			}

			bindingTime += elapsed;
			if(bindingTime > 5) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				rebindingKey = -1;
				bindingTime = 0;
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}

		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0) {
		changed = change;
		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		switch(options[curSelected][1]){
			case 'Preference':{
				camFollow.setPosition(FlxG.width / 2, FlxG.height * 0.5);
			}
			case 'Controls':{
				camFollow.setPosition(FlxG.width / 2, FlxG.height * 1.5);
			}
			case 'Notes':{
				camFollow.setPosition(FlxG.width / 2, FlxMath.lerp(camFollow.y, FlxG.height * 2.5, 0.5));
			}
		}

		grpOptions.forEach(function(spr:FlxText)
			{
				spr.alpha = 1;
				spr.updateHitbox();

				if (options[spr.ID][0] >= 0)
					{
						spr.alpha = 0.5;
					}

				if (spr.ID == curSelected)
				{
					spr.alpha = 0.3;
				}
			});

		var daText:String = '';
		switch(options[curSelected][1]){
			case 'Framerate':
				daText = "Pretty self explanatory, isn't it?\nDefault value is 60.";
			case 'Note Delay':
				daText = "Changes how late a note is spawned.\nUseful for preventing audio lag from wireless earphones.";
			case 'FPS Counter':
				daText = "If unchecked, hides FPS Counter.";
			case 'Low Quality':
				daText = "If checked, disables some background details,\ndecreases loading times and improves performance.\Dont check it, it has a little bugs in playing games.";
			case 'Persistent Cached Data':
				daText = "If checked, images loaded will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.";
			case 'Anti-Aliasing':
				daText = "If unchecked, disables anti-aliasing, increases performance\nat the cost of the graphics not looking as smooth.";
			case 'Downscroll':
				daText = "If checked, notes go Down instead of Up, simple enough.";
			case 'Middlescroll':
				daText = "If checked, hides Opponent's notes and your notes get centered.";
			case 'Ghost Tapping':
				daText = "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.";
			case 'Swearing':
				daText = "If unchecked, your mom won't be angry at you.";
			case 'Violence':
				daText = "If unchecked, you won't get disgusted as frequently.";
			case 'Note Splashes':
				daText = "If unchecked, hitting \"Sick!\" notes won't show particles.";
			case 'Flashing Lights':
				daText = "Uncheck this if you're sensitive to flashing lights!";
			case 'Camera Zooms':
				daText = "If unchecked, the camera won't zoom in on a beat hit.";
			case 'Hide HUD':
				daText = "If checked, hides most HUD elements.";
			case 'Hide Song Length':
				daText = "If checked, the bar showing how much time is left\nwill be hidden.";
			case 'Customize Notes':
				daText = "Customize the style of your game notes.";
			case 'Facecam Mode':
				daText = "Place your camera on one of the blocks to display all the information on the screen.";
			case 'Change Facecam Position':
				daText = "Change the position of the frame to that of the camera.";
		}
		descText.text = daText;
	}

	function reloadValues() {
		for(i in 0...options.length){
			grpOptions.forEach(function(spr:FlxText)
				{
					if(spr.ID == i){
						if(options[i][1] == 'Change Facecam Position'){
							if(ClientPrefs.faceCam == -1){
								options[i][0] = -1;
								spr.visible = false;
							}else{
								options[i][0] = 1;
								spr.visible = true;
							}	
						}

						if(options[i][0] == 1){
							switch(options[i][1]){
								case 'Framerate':
									spr.text = options[i][1] + ': ' + ClientPrefs.framerate;
								case 'Note Delay':
									spr.text = options[i][1] + ': ' + ClientPrefs.noteOffset + 'ms';	
							}
						}else if(options[i][0] == 2){
							if(isAlt){
								spr.text = options[i][1] + ': ' + InputFormatter.getKeyName(controlArray[options[i][3]]) + ' / <' + InputFormatter.getKeyName(controlArray[options[i][4]]) + '>';
							}else{
								spr.text = options[i][1] + ': <' + InputFormatter.getKeyName(controlArray[options[i][3]]) + '> / ' + InputFormatter.getKeyName(controlArray[options[i][4]]);
							}							
						}						
					}					
				});
		}		
			
		for (i in 0...checkboxArray.length) {
			var checkbox:CheckboxThingie = checkboxArray[i];
			if(checkbox != null) {
				var daValue:Bool = false;
				switch(options[checkboxNumber[i]][1]) {
					case 'FPS Counter':
						daValue = ClientPrefs.showFPS;
					case 'Low Quality':
						daValue = ClientPrefs.lowQuality;
					case 'Anti-Aliasing':
						daValue = ClientPrefs.globalAntialiasing;
					case 'Note Splashes':
						daValue = ClientPrefs.noteSplashes;
					case 'Flashing Lights':
						daValue = ClientPrefs.flashing;
					case 'Downscroll':
						daValue = ClientPrefs.downScroll;
					case 'Middlescroll':
						daValue = ClientPrefs.middleScroll;
					case 'Ghost Tapping':
						daValue = ClientPrefs.ghostTapping;
					case 'Swearing':
						daValue = ClientPrefs.cursing;
					case 'Violence':
						daValue = ClientPrefs.violence;
					case 'Camera Zooms':
						daValue = ClientPrefs.camZooms;
					case 'Hide HUD':
						daValue = ClientPrefs.hideHud;
					case 'Persistent Cached Data':
						daValue = ClientPrefs.imagesPersist;
					case 'Hide Song Length':
						daValue = ClientPrefs.hideTime;
					case 'Facecam Mode':{
						if(ClientPrefs.faceCam == -1){
							daValue = false;
						}else{
							daValue = true;
						}
					}
				}
				checkbox.daValue = daValue;
			}
		}
	}

	private function getSelectedKey():Int {
		var altValue:Int = (isAlt ? 1 : 0);
		for (i in 0...ClientPrefs.keyBinds.length) {
			if(ClientPrefs.keyBinds[i][1] == options[curSelected][1]) {
				return i*2 + altValue;
			}
		}
		return -1;
	}
}

class NotesSubstate extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var hsvText:Alphabet;
	var nextAccept:Int = 5;

	var staticFilter:FlxSprite;

	var posX = 100;
	public function new() {
		super();

		var background:FlxSprite = new FlxSprite(0,0).makeGraphic((Std.int(FlxG.width + 50)),Std.int(FlxG.width + 20),FlxColor.BLACK);
		background.scrollFactor.set();
		add(background);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...ClientPrefs.arrowHSV.length) {
			var yPos:Float = (165 * i) + 65;
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(0, yPos, Std.string(ClientPrefs.arrowHSV[i][j]), true);
				optionText.x = posX + (225 * j) + 100 - ((optionText.lettersArray.length * 90) / 2);
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX - 70, yPos);
			note.frames = Paths.getSparrowAtlas('NOTE_assets');
			switch(i) {
				case 0:
					note.animation.addByPrefix('idle', 'purple0');
				case 1:
					note.animation.addByPrefix('idle', 'blue0');
				case 2:
					note.animation.addByPrefix('idle', 'green0');
				case 3:
					note.animation.addByPrefix('idle', 'red0');
			}
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.globalAntialiasing;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.hue = ClientPrefs.arrowHSV[i][0] / 360;
			newShader.saturation = ClientPrefs.arrowHSV[i][1] / 100;
			newShader.brightness = ClientPrefs.arrowHSV[i][2] / 100;
			shaderArray.push(newShader);
		}
		hsvText = new Alphabet(0, 0, "Hue    Saturation  Brightness", true, false, 0, 0.65);
		add(hsvText);

		staticFilter = new FlxSprite();
		staticFilter.frames = Paths.getSparrowAtlas('StaticFilter');
		staticFilter.animation.addByPrefix('play', 'StaticFilter', 24, true);
		staticFilter.animation.play('play');
		staticFilter.alpha = 0.3;
		staticFilter.setGraphicSize(Std.int(FlxG.width));
		staticFilter.updateHitbox();
		staticFilter.screenCenter();
		add(staticFilter);

		changeSelection();
	}

	var changingNote:Bool = false;
	var hsvTextOffsets:Array<Float> = [240, 130];
	override function update(elapsed:Float) {
		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				for (i in 0...3) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			var intendedPos:Float = posX - 70;
			if (curSelected == i) {
				item.x = FlxMath.lerp(item.x, intendedPos + 100, lerpVal);
			} else {
				item.x = FlxMath.lerp(item.x, intendedPos, lerpVal);
			}
			for (j in 0...3) {
				var item2 = grpNumbers.members[(i * 3) + j];
				item2.x = item.x + 265 + (225 * (j % 3)) - (30 * item2.lettersArray.length) / 2;
				if(ClientPrefs.arrowHSV[i][j] < 0) {
					item2.x -= 20;
				}
			}

			if(curSelected == i) {
				hsvText.setPosition(item.x + hsvTextOffsets[0], item.y - hsvTextOffsets[1]);
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			changeSelection();
			if(!changingNote) {
				grpNumbers.forEachAlive(function(spr:Alphabet) {
					spr.alpha = 0;
				});
				grpNotes.forEachAlive(function(spr:FlxSprite) {
					spr.alpha = 0;
				});
				close();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = ClientPrefs.arrowHSV.length-1;
		if (curSelected >= ClientPrefs.arrowHSV.length)
			curSelected = 0;

		curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(1, 1);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1.2, 1.2);
				hsvText.setPosition(item.x + hsvTextOffsets[0], item.y - hsvTextOffsets[1]);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		ClientPrefs.arrowHSV[selected][type] = 0;
		switch(type) {
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}
		grpNumbers.members[(selected * 3) + type].changeText('0');
	}
	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) {
			case 1 | 2: max = 100;
		}

		if(roundedValue < -max) {
			curValue = -max;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		ClientPrefs.arrowHSV[curSelected][typeSelected] = roundedValue;

		switch(typeSelected) {
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}
		grpNumbers.members[(curSelected * 3) + typeSelected].changeText(Std.string(roundedValue));
	}
}

class FacecamSubstate extends MusicBeatSubstate
{
	private var camBoxs:FlxTypedGroup<FlxSprite>;

	var staticFilter:FlxSprite;

	public static var curCam = -1;

	public function new(){
		super();

		FlxG.mouse.visible = true;

		var background:FlxSprite = new FlxSprite(0,0).makeGraphic((Std.int(FlxG.width + 50)),Std.int(FlxG.width + 20),FlxColor.BLACK);
		background.scrollFactor.set();
		add(background);

		var exitText = new FlxText(0, 0, Std.int(FlxG.width), 'Press ' + Control.BACK + ' to leave', 40);
		exitText.setFormat('Calibri', 40, FlxColor.WHITE, CENTER);
		exitText.antialiasing = ClientPrefs.globalAntialiasing;
		add(exitText);

		var titletext = new FlxText(0, 300, Std.int(FlxG.width / 2), 'Please keep your facecam inside the yellow box at all times!\n Thank you!', 40);
		titletext.setFormat('Calibri', 40, FlxColor.WHITE, CENTER);
		titletext.antialiasing = ClientPrefs.globalAntialiasing;
		titletext.screenCenter(X);
		add(titletext);

		camBoxs = new FlxTypedGroup<FlxSprite>();
		add(camBoxs);

		for(i in 0...4){
			var camBox:FlxSprite = new FlxSprite();
			camBox.frames = Paths.getSparrowAtlas('camBox');
			camBox.animation.addByPrefix('unselect', 'camBox Unselected', 24, true);
			camBox.animation.addByPrefix('select', 'camBox Selected', 24, true);
			camBox.animation.play('unselect');
			camBox.setGraphicSize(Std.int(camBox.width * 0.7));
			camBox.ID = i;
			camBox.updateHitbox();
			camBoxs.add(camBox);

			switch(i){
				case 0:{
					camBox.setPosition(0,0);
				}
				case 1:{
					camBox.setPosition(FlxG.width - camBox.width, 0);
				}
				case 2:{
					camBox.setPosition(0, FlxG.height - camBox.height);
				}
				case 3:{
					camBox.setPosition(FlxG.width - camBox.width, FlxG.height - camBox.height);
				}
			}
		}

		staticFilter = new FlxSprite();
		staticFilter.frames = Paths.getSparrowAtlas('StaticFilter');
		staticFilter.animation.addByPrefix('play', 'StaticFilter', 24, true);
		staticFilter.animation.play('play');
		staticFilter.alpha = 0.3;
		staticFilter.setGraphicSize(Std.int(FlxG.width));
		staticFilter.updateHitbox();
		staticFilter.screenCenter();
		add(staticFilter);

		changeCam();
	}

	override function update(elapsed:Float){
		if (controls.BACK){
			FlxG.mouse.visible = false;
			close();
		}
		
		camBoxs.forEach(function(spr:FlxSprite){
			if(FlxG.mouse.overlaps(spr) && FlxG.mouse.justPressed){
				changeCam(spr.ID);
			}
		});

		super.update(elapsed);
	}

	function changeCam(?value:Int):Void{
		if(value != null){
			ClientPrefs.faceCam = value;
		}		

		camBoxs.forEach(function(spr:FlxSprite){
			spr.animation.play('unselect');

			if(spr.ID == ClientPrefs.faceCam){
				spr.animation.play('select');
			}
		});
	}
}
