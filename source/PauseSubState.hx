package;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Toggle Practice Mode', 'Botplay', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var botplayText:FlxText;

	public static var transCamera:FlxCamera;

	public function new(x:Float, y:Float)
	{
		super();
		menuItems = menuItemsOG;

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(0, 15, FlxG.width - 20, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		levelInfo.screenCenter(X);
		levelInfo.updateHitbox();
		add(levelInfo);

		var blueballedTxt:FlxText = new FlxText(0, 15 + 32, FlxG.width - 20, "", 32);
		blueballedTxt.text = "Blueballed: " + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		blueballedTxt.screenCenter(X);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		practiceText = new FlxText(0, 15 + 64, FlxG.width - 20, "PRACTICE MODE", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		practiceText.screenCenter(X);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.practiceMode;
		add(practiceText);

		botplayText = new FlxText(0, FlxG.height - 40, FlxG.width - 20, "BOTPLAY", 32);
		botplayText.scrollFactor.set();
		botplayText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		botplayText.screenCenter(X);
		botplayText.updateHitbox();
		botplayText.visible = PlayState.cpuControlled;
		add(botplayText);

		blueballedTxt.alpha = 0;
		levelInfo.alpha = 0;

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = 2;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		switch(ClientPrefs.faceCam){
			case 1:{
				levelInfo.alignment = 'LEFT';
				blueballedTxt.alignment = 'LEFT';
				practiceText.alignment = 'LEFT';
			}
			case 3:{
				botplayText.alignment = 'LEFT';
			}
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (accepted)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Toggle Practice Mode':
					PlayState.practiceMode = !PlayState.practiceMode;
					PlayState.usedPractice = true;
					practiceText.visible = PlayState.practiceMode;
				case "Restart Song":
					CustomFadeTransition.nextCamera = transCamera;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
				case 'Botplay':
					PlayState.cpuControlled = !PlayState.cpuControlled;
					PlayState.usedPractice = true;
					botplayText.visible = PlayState.cpuControlled;
				case "Exit to menu":
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					CustomFadeTransition.nextCamera = transCamera;
					MusicBeatState.switchState(new MainMenuState());
					PlayState.usedPractice = false;
					PlayState.changedDifficulty = false;
					PlayState.cpuControlled = false;

				case 'BACK':
					menuItems = menuItemsOG;
					regenMenu();
			}
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			this.grpMenuShit.remove(this.grpMenuShit.members[0], true);
		}
		for (i in 0...menuItems.length) {
			var item = new Alphabet(0, 70 * i + 30, menuItems[i], true, false);
			item.isMenuItem = 2;
			item.targetY = i;
			grpMenuShit.add(item);
		}
		curSelected = 0;
		changeSelection();
	}
}
