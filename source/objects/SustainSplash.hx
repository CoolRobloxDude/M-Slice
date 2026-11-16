package objects;

import backend.animation.PsychAnimationController;
import objects.Note.CastNote;
import flixel.math.FlxRandom;

class SustainSplash extends FlxSprite
{
	public static var frameRate = 24;
	private static var noShader = false;
	
	public var startCrochet = 0.0;
	public var holding = false;
	public var ending = false;
	public var note:Note;

	var rnd:FlxRandom;
	var timer:FlxTimer;
	var animId:String;

	public function new():Void
	{
		super();
		holding = ending = false;
		note = new Note();
		note.visible = false;
		timer = new FlxTimer();

		animation = new PsychAnimationController(this);

		x = -50000;
		rnd = new FlxRandom();

		frames = Paths.getSparrowAtlas('holdCovers/holdCover-' + ClientPrefs.data.holdSkin);
		noShader = ClientPrefs.data.holdSkin.toLowerCase().contains('classic');

		if (noShader) {
			// Load anims for without color shader
			for (i => str in Note.colArray) {
				var pascalCase = str.substr(0, 1).toUpperCase() + str.substr(1).toLowerCase();
				animation.addByPrefix('hold$i', 'holdCover${pascalCase}0', 24, true);
				animation.addByPrefix('end$i', 'holdCoverEnd${pascalCase}0', 24, false);
				animation.addByPrefix('start$i', 'holdCoverStart${pascalCase}0', 24, false);

				// Check the added anims exist in memory
				if(!animation.getNameList().contains('start$i')) trace('Hold splash is missing \'start$i\' anim!');
				if(!animation.getNameList().contains('hold$i')) trace('Hold splash is missing \'hold$i\' anim!');
				if(!animation.getNameList().contains('end$i')) trace('Hold splash is missing \'end$i\' anim!');
			}
		} else {
			// Load anims for with color shader
			animation.addByPrefix('hold', 'holdCover0', 24, true);
			animation.addByPrefix('end', 'holdCoverEnd0', 24, false);
			animation.addByPrefix('start', 'holdCoverStart0', 24, false);

			// Check the added anims exist in memory
			if(!animation.getNameList().contains("start")) trace("Hold splash is missing 'start' anim!");
			if(!animation.getNameList().contains("hold")) trace("Hold splash is missing 'hold' anim!");
			if(!animation.getNameList().contains("end")) trace("Hold splash is missing 'end' anim!");
		}
	}

	override function update(elapsed)
	{
		super.update(elapsed);
		
		if (note.exists && note.strum != null)
		{
			setPosition(note.strum.x, note.strum.y);
			visible = note.strum.visible;
			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
		}
	}

	public function setupSusSplash(daNote:Note, ?playbackRate:Float = 1):Void
	{
		this.revive();
		var wasHolding:Bool = holding;
		// Cancel any previous sustain's delayed end and discard stale callbacks
		// before this pooled splash is assigned to a new note.
		timer.cancel();
		if (animation != null) animation.finishCallback = null;
		holding = false;
		ending = false;
		var castNote:CastNote = daNote.toCastNote();
		this.note.recycleNote(castNote);
		note.strum = daNote.strum;
		// trace(note.isSustainEnds);
		
		if (!note.isSustainEnds) {
			holding = true;
			ending = false;

			if (note.strum != null) setPosition(note.strum.x, note.strum.y);
			animId = noShader ? Std.string(note?.noteData ?? 0) : '';

			animation.play('start$animId', true);

			if (animation.curAnim != null)
			{
				animation.curAnim.looped = false;
				animation.curAnim.frameRate = frameRate;
				animation.finishCallback = a -> {
					animation.finishCallback = null;
					playHoldAnimation();
				};
			} else {
				// Some custom skins omit the intro. Fall back to the looping hold
				// animation instead of leaving an invisible active splash.
				playHoldAnimation();
			}

			clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

			if (note.shader != null && note.rgbShader.enabled)
			{
				shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
				shader.data.r.value = note.shader.data.r.value;
				shader.data.g.value = note.shader.data.g.value;
				shader.data.b.value = note.shader.data.b.value;
				shader.data.mult.value = note.shader.data.mult.value;
			}

			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
			offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);
		} else if (wasHolding) {
			startCrochet = (Conductor.stepCrochet - Conductor.songPosition + note.strumTime) * 0.001 / playbackRate;
			timer.start(startCrochet, t -> showEndSplash());
		} else {
			// An end segment without an active hold splash must not leave a
			// revived, animation-less pooled object on screen.
			kill();
		}
	}

	function playHoldAnimation():Void
	{
		animation.play('hold$animId', true);
		if (animation.curAnim != null)
		{
			animation.curAnim.frameRate = frameRate;
			animation.curAnim.looped = true;
		} else {
			kill();
		}
	}

	public function isTimerWorking() {
		return timer.active;
	}

	public function showEndSplash() {
		if (!exists || ending) return;
		holding = false;
		ending = true;
		timer.cancel();
		if (animation != null && note != null && note.strum != null && animation.exists('end$animId'))
		{
			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
			animation.play('end$animId', true, false, 0);
			if (animation.curAnim == null) {
				kill();
				return;
			}
			animation.curAnim.looped = false;
			animation.curAnim.frameRate = rnd.int(22, 26);
			clipRect = null;
			animation.finishCallback = idkEither -> kill();
			return;
		}
		kill();
	}

	override function kill() {
		timer.cancel();
		holding = false;
		ending = false;
		if (animation != null) animation.finishCallback = null;
		super.kill();
	}
}
