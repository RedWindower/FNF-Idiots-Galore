package backend;

import flixel.tweens.FlxEase;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	public static var loadingPending:Bool = false;
	var isTransIn:Bool = false;
	var topBar:FlxSprite;
	var bottomBar:FlxSprite;
	var loadingBarBack:FlxSprite;
	var loadingBarFill:FlxSprite;
	var loadingText:FlxText;
	var elapsedTime:Float = 0;
	var finishDelay:Float = 0;
	var finishedShown:Bool = false;
	var showLoading:Bool = false;
	var viewHeight:Float = 0;
	var overscan:Float = 96;

	var duration:Float;
	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		showLoading = !isTransIn || loadingPending;
		if(isTransIn) loadingPending = false;
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
		final zoom:Float = Math.max(camera.zoom, 0.001);
		final width:Int = Std.int(Math.ceil(FlxG.width / zoom));
		final height:Int = Std.int(Math.ceil(FlxG.height / zoom));
		viewHeight = height;
		final barWidth:Int = width + Std.int(overscan * 2);
		final barHeight:Int = Std.int(Math.ceil(height * 0.5)) + Std.int(overscan);

		topBar = new FlxSprite(-overscan, 0).makeGraphic(barWidth, barHeight, FlxColor.BLACK);
		topBar.scrollFactor.set();
		add(topBar);

		bottomBar = new FlxSprite(-overscan, 0).makeGraphic(barWidth, barHeight, FlxColor.BLACK);
		bottomBar.scrollFactor.set();
		add(bottomBar);

		final loadingWidth:Int = Std.int(width * 0.45);
		final loadingHeight:Int = 14;
		final loadingX:Float = (width - loadingWidth) * 0.5;
		final loadingY:Float = (height - loadingHeight) * 0.5;

		loadingBarBack = new FlxSprite(loadingX, loadingY).makeGraphic(loadingWidth, loadingHeight, 0xFF222222);
		loadingBarBack.scrollFactor.set();
		add(loadingBarBack);

		loadingBarFill = new FlxSprite(loadingX + 2, loadingY + 2).makeGraphic(loadingWidth - 4, loadingHeight - 4, FlxColor.WHITE);
		loadingBarFill.scrollFactor.set();
		loadingBarFill.origin.set(0, 0);
		add(loadingBarFill);

		loadingText = new FlxText(0, loadingBarBack.y + 20, width, "Loading...", 18);
		loadingText.setFormat(null, 18, FlxColor.WHITE, "center");
		loadingText.scrollFactor.set();
		add(loadingText);

		if (!showLoading)
		{
			loadingBarBack.visible = false;
			loadingBarFill.visible = false;
			loadingText.visible = false;
		}

		updateBars(0);

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// The destination's create() has returned before its first transition update.
		if(isTransIn && showLoading && !finishedShown)
		{
			finishedShown = true;
			finishDelay = 0.25;
			loadingText.text = "Finished! :]";
			updateBars(0);
			return;
		}

		if(finishDelay > 0)
		{
			finishDelay = Math.max(finishDelay - elapsed, 0);
			return;
		}

		elapsedTime += elapsed;
		final progress:Float = duration > 0 ? Math.min(elapsedTime / duration, 1) : 1;
		updateBars(progress);

		if(progress >= 1)
		{
			if(isTransIn)
				close();
			else
			{
				final callback = finishCallback;
				finishCallback = null;
				loadingPending = callback != null;
				close();
				if(callback != null) callback();
			}
		}
	}

	function updateBars(progress:Float)
	{
		final closedTopY:Float = viewHeight * 0.5 - topBar.height;
		final closedBottomY:Float = viewHeight * 0.5;
		final openTopY:Float = -topBar.height - overscan;
		final openBottomY:Float = viewHeight + overscan;
		final easedProgress:Float = isTransIn ? FlxEase.quadIn(progress) : FlxEase.quadOut(progress);
		final t:Float = isTransIn ? easedProgress : 1 - easedProgress;

		topBar.y = closedTopY + (openTopY - closedTopY) * t;
		bottomBar.y = closedBottomY + (openBottomY - closedBottomY) * t;

		if (!showLoading) return;

		// Animation progress is not asset progress; reserve full for the ready state.
		final barProgress:Float = finishedShown ? 1 : (isTransIn ? 0.95 : progress * 0.95);
		loadingBarFill.scale.x = barProgress;
		loadingBarFill.updateHitbox();
		loadingBarFill.y = loadingBarBack.y + 2;
		loadingBarFill.x = loadingBarBack.x + 2;

		final fadeProgress:Float = isTransIn ? Math.min(progress / 0.2, 1) : 0;
		final alphaValue:Float = 1 - fadeProgress;
		loadingBarBack.alpha = alphaValue;
		loadingBarFill.alpha = alphaValue;
		loadingText.alpha = alphaValue;
	}
}