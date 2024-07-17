package android;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import openfl.display.BitmapData;
import openfl.display.Shape;
import android.flixel.FlxButton;

/**
 * A zone with 4 hint's (A hitbox).
 * It's really easy to customize the layout.
 *
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class FlxNewHitbox extends FlxSpriteGroup
{
	public var buttonLeft:FlxButton = new FlxButton(0, 0);
	public var buttonDown:FlxButton = new FlxButton(0, 0);
	public var buttonUp:FlxButton = new FlxButton(0, 0);
	public var buttonRight:FlxButton = new FlxButton(0, 0);
        public var buttonSpace:FlxButton = new FlxButton(0, 0);
	public var buttonShift:FlxButton = new FlxButton(0, 0);
	public var buttonCtrl:FlxButton = new FlxButton(0, 0);
	/**
	 * Create the zone.
	 */
	public function new():Void
	{
		super();
	
		switch (PlayState.SONG.song.toLowerCase())
		{
		
		case 'tutorial' | 'merged' | 'darkness':
			
		add(buttonLeft = createHint(0, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF00FF));
		add(buttonDown = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0x00FFFF));
		add(buttonUp = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0x00FF00));
		add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF0000));
                add(buttonSpace = createHint(0, (FlxG.height / 5) * 4, Std.int(FlxG.width /3), Std.int(FlxG.height / 5), 0xFFFF00));
		add(buttonShift = createHint(FlxG.width / 3, 0, Std.int(FlxG.width / 3), Std.int(FlxG.height * 0.2), 0xFFFF00));
		add(buttonCtrl = createHint((FlxG.width / 1) + (FlxG.widht / 3), 0, Std.int(FlxG.width / 3), Std.int(FlxG.height * 0.2), 0xFFFF00)
				
                default:
        
                add(buttonLeft = createHint(0, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0xFF00FF));
		add(buttonDown = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0x00FFFF));
		add(buttonUp = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0x00FF00));
		add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0xFF0000));
        
        }			
		
		scrollFactor.set;
	}

	/**
	 * Clean up memory.
	 */
	override function destroy():Void
	{
		super.destroy();

		buttonLeft = null;
		buttonDown = null;
		buttonUp = null;
		buttonRight = null;
		buttonSpace = null;
		buttonShift = null;
		buttonCtrl = null;
	}

	private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF):BitmapData
	{
		var shape:Shape = new Shape();
		shape.graphics.beginFill(Color);
		shape.graphics.lineStyle(10, Color, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):FlxButton
	{
		var hint:FlxButton = new FlxButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height, Color));
		hint.solid = false;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.onDown.callback = hint.onOver.callback = function()
		{
			if (hint.alpha != ClientPrefs.hitboxalpha)
				hint.alpha = ClientPrefs.hitboxalpha;
		}
		hint.onUp.callback = hint.onOut.callback = function()
		{
			if (hint.alpha != 0.00001)
				hint.alpha = 0.00001;
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}
}
