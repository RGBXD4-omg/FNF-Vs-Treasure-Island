package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef DataEnemie = {
    var name:String;
    var path:String;

    var antialiasing:Bool;

    var attacks:Array<AttackArray>;

    var jumpscare:String;
    var offset_Jumpscare:Array<Float>;
    var sJumpscare:String;
}

typedef AttackArray = {
    var id:Int; // SHOULD BE INDEX
    var animation:String;

    var animation_off:String;
    var offset_off:Array<Float>;

    var position:Array<Float>;
    var scale:Float;

    var mechanic:Int;
}

class Enemie extends FlxSprite{
    public static var DEFAULT:String = 'mickeynt';
    public var curEnemie:String = DEFAULT;

    public var defaultWidth:Float;
    public var positionArray:Array<Float> = [0, 0];
    public var attacksArray:Array<AttackArray> = [];
    public var animOffsets:Map<String, Array<Dynamic>>;

    public var attacking:Int = -1;

    public var scaring:Bool = false;
    public var soundScares:String;
    public var offset_Jumpscare:Array<Float>;
    
    public function new(x:Float, y:Float, ?enemie:String = 'mickeynt'){
        super(x, y);

        #if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end

        curEnemie = enemie;
		antialiasing = ClientPrefs.globalAntialiasing;

        switch (curEnemie){
            default:{
                var enemiePath:String = 'enemies/' + curEnemie + '.json';

                var path:String = Paths.getPreloadPath(enemiePath);
				if (!Assets.exists(path)){
					path = Paths.getPreloadPath('enemies/' + DEFAULT + '.json'); //If the enemy is not found, the default will be used.
				}

                var rawJson = Assets.getText(path);
                var json:DataEnemie = cast Json.parse(rawJson);
                frames = Paths.getSparrowAtlas(json.path);

                defaultWidth = this.width;
                soundScares = json.sJumpscare;
                offset_Jumpscare = json.offset_Jumpscare;

                if(ClientPrefs.globalAntialiasing){antialiasing = json.antialiasing;}

				attacksArray = json.attacks;
                if(attacksArray != null && attacksArray.length > 0){
                    trace('----- Adding ' + curEnemie + ' -----');
                    trace('');
                    for (attack in attacksArray){
                        animation.addByPrefix('attack_' +  attack.id, attack.animation, 24, true);
                        trace('Animation Normal: attack_' +  attack.id + ' - ' + attack.animation);
                        animation.addByPrefix('attack_' +  attack.id + '_off', attack.animation_off, 24, true);
                        trace('Animation Off: attack_' +  attack.id + '_off' + ' - ' + attack.animation_off);
                    }
                    trace('');
                    animation.addByPrefix('jumpscare', json.jumpscare, 24, false);
                    trace('----- Enemie Added -----');
                }
            }
        }
    }

    override function update(elapsed:Float){
        if(attacking >= 0){
            visible = true;
        }else{visible = false;}

        super.update(elapsed);
    }

    public function startAttack(attackAnim:Int, ?isOff:Bool):Void{
        var off:Bool = false;
        if(isOff != null){off = isOff;}

        var anim = 'attack_' + attackAnim;        
        if(off){anim =  'attack_' + attackAnim + '_off';}

        animation.play(anim);
        x = attacksArray[attackAnim].position[0];
        y = attacksArray[attackAnim].position[1];        

        offset.set(0, 0);
        if(off){offset.set(attacksArray[attackAnim].offset_off[0], attacksArray[attackAnim].offset_off[1]);}

        setGraphicSize(Std.int(defaultWidth * attacksArray[attackAnim].scale));
    }

    public function scare():Void{
        if(!scaring){
            scaring = true;

            animation.play('jumpscare');
            x = 0;
            y = 0;    
        
            offset.set(0, 0);
            offset.set(offset_Jumpscare[0], offset_Jumpscare[1]);

            setGraphicSize(Std.int(FlxG.width));
            
            FlxG.sound.play(Paths.sound(soundScares), 0.6);
        }        
    }

    public function setJumpOffest(x:Int, y:Int):Void{
        offset.add(x, y);
        trace("Enemie: " + curEnemie + " | Current Offset: " + offset.x + ", " + offset.y);
    }

    public function temSaveOffest(attack:Int):Void{
        attacksArray[attack].offset_off[0] = offset.x;
        attacksArray[attack].offset_off[1] = offset.y;
        trace("Enemie: " + curEnemie + " | Offset temporarily saved: " + offset.x + ", " + offset.y);
    }
}