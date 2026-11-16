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
	// True once the charted final sustain segment has been hit and its tail
	// animation is waiting for the remaining chart time to elapse.
	var tailPending:Bool = false;
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
			// A released hold disappears immediately, but a tail already reached
			// may still finish its scheduled ending animation.
			visible = (holding || ending) && note.strum.visible;
			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
		}
	}

	public function setupSusSplash(daNote:Note, ?playbackRate:Float = 1):Void
	{
		if (daNote == null) return;

		// An end segment cannot revive a cover after this lane was released.
		if (daNote.isSustainEnds && !holding)
		{
			kill();
			return;
		}

		this.revive();
		var castNote:CastNote = daNote.toCastNote();
		this.note.recycleNote(castNote);
		note.strum = daNote.strum;
		timer.cancel();
		if (animation != null) animation.finishCallback = null;
		
		if (!note.isSustainEnds) {
			holding = true;
			ending = false;
			tailPending = false;

			if (note.strum != null) setPosition(note.strum.x, note.strum.y);
			animId = noShader ? Std.string(note?.noteData ?? 0) : '';

			if (animation.exists('start$animId'))
			{
				animation.play('start$animId', true);
				if (animation.curAnim != null)
				{
					animation.curAnim.looped = false;
					animation.curAnim.frameRate = frameRate;
					animation.finishCallback = a -> {
						animation.finishCallback = null;
						playHoldAnimation();
					};
				} else playHoldAnimation();
			} else playHoldAnimation();

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
		} else if (holding) {
			// Schedule the ending for the charted tail time, not the key-up event.
			tailPending = true;
			startCrochet = Math.max(0, (note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset) * 0.001 / playbackRate);
			timer.start(startCrochet, t -> {
				if (tailPending && note != null && note.exists && note.isSustainEnds)
					showEndSplash();
				else
					kill();
			});
		}
	}

	/** Stop the hold visual on key-up without playing its tail animation early. */
	public function releaseHold():Void
	{
		if (!holding) return;
		holding = false;
		if (!tailPending)
		{
			kill();
			return;
		}
		visible = false;
	}

	function playHoldAnimation():Void
	{
		animation.play('hold$animId', true);
		if (animation.curAnim != null)
		{
			animation.curAnim.frameRate = frameRate;
			animation.curAnim.looped = true;
		} else kill();
	}

	public function isTimerWorking() {
		return timer.active;
	}

	public function showEndSplash() {
		if (!tailPending || ending) return;
		tailPending = false;
		holding = false;
		ending = true;
		visible = true;
		timer.cancel();
		if (exists && animation != null && note != null && note.strum != null && animation.exists('end$animId'))
		{
			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
			animation.play('end$animId', true, false, 0);
			if (animation.curAnim == null)
			{
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
		if (timer != null) timer.cancel();
		holding = false;
		tailPending = false;
		ending = false;
		if (animation != null) animation.finishCallback = null;
		super.kill();
	}
}
