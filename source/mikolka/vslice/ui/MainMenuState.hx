
package mikolka.vslice.ui;

import mikolka.vslice.ui.mainmenu.DesktopMenuState;
import mikolka.compatibility.ui.MainMenuHooks;
import mikolka.compatibility.VsliceOptions;
import mikolka.compatibility.ModsHelper;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	#if !LEGACY_PSYCH
	public static var psychEngineVersion:String = '1.0.4';
	#else
	public static var psychEngineVersion:String = '0.6.3';
	#end

	public static var pSliceVersion:String = '3.3.1';
	public static var funkinVersion:String = '0.7.4';
	public static var hrkVersion:String = '0.2.4';
	public static var dSliceVersion:String = '0.0.2';

	public static var curSelected:Int = 0;

	var bg:FlxSprite;
	var magenta:FlxSprite;

	public function new(isDisplayingRank:Bool = false)
	{
		super();
	}

	override function create()
	{
		ModsHelper.clearStoredWithoutStickers();
		Paths.clearUnusedMemory();
		ModsHelper.resetActiveMods();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Main Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = VsliceOptions.ANTIALIASING;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = VsliceOptions.ANTIALIASING;
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		var mSliceVer:FlxText = new FlxText(
			8,
			FlxG.height - 28,
			FlxG.width,
			'M-Slice v0.0.3',
			16
		);

		mSliceVer.setFormat(
			Paths.font("vcr.ttf"),
			16,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		mSliceVer.scrollFactor.set();
		mSliceVer.antialiasing = ClientPrefs.data.antialiasing;
		add(mSliceVer);

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();

		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			MainMenuHooks.unlockFriday();

		#if MODS_ALLOWED
		MainMenuHooks.reloadAchievements();
		#end
		#end

		super.create();

		#if TOUCH_CONTROLS_ALLOWED
		if (controls.mobileC)
			new mobile.states.MobileMenuState(this);
		else
		#end
		new DesktopMenuState(this);
	}

	function goToOptions()
	{
		MusicBeatState.switchState(new OptionsState());

		#if !LEGACY_PSYCH
		OptionsState.onPlayState = false;
		#end

		if (PlayState.SONG != null)
		{
			PlayState.SONG.arrowSkin = null;
			PlayState.SONG.splashSkin = null;

			#if !LEGACY_PSYCH
			PlayState.stageUI = 'normal';
			#end
		}
	}

	override function update(elapsed:Float)
	{
		if (FlxG?.sound?.music?.length > 1000 && FlxG?.sound?.music?.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		super.update(elapsed);
	}
}
