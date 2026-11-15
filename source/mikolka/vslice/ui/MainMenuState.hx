
package mikolka.vslice.ui;

import states.MainMenuState as DesktopMenuState;
import mikolka.vslice.ui.MainMenuHooks;
import mikolka.vslice.VsliceOptions;
import mikolka.vslice.utils.ModsHelper;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
    public static var psychEngineVersion:String = '1.0.4';
    public static var psychEngineVersionLegacy:String = '0.6.3';

    public static var pSliceVersion:String = '';
    public static var funkinVersion:String = '';
    public static var hrkVersion:String = '';
    public static var dSliceVersion:String = '';

    public static var mSliceVersion:String = '0.0.3';

    public var curSelected:Int = 0;
    public var bg:FlxSprite;
    public var magenta:FlxSprite;

    public function new(isDisplayingRank:Bool = false)
    {
        super();
    }

    override function create()
    {
        ModsHelper.clearStoredMemory();
        ModsHelper.clearUnusedMemory();

        super.create();

        bg = new FlxSprite().loadGraphic(Paths.image('menuBG'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set();
        add(bg);

        magenta = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFD719B);
        magenta.visible = false;
        add(magenta);

        var versionText = new FlxText(12, FlxG.height - 24, 0, 'M-Slice v' + mSliceVersion, 12);
        versionText.scrollFactor.set();
        add(versionText);

        Achievements.load();

        if (FlxG.onMobile)
        {
            // Keep the existing mobile menu behavior.
            super.create();
        }
        else
        {
            DesktopMenuState.switchState();
        }
    }

    public function goToOptions()
    {
        MusicBeatState.switchState(new OptionsState());
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
