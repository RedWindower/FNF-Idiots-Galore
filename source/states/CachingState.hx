package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import Intro;

class CachingState extends MusicBeatState
{
	var bg:FlxSprite;
	var splashImage:FlxSprite;
	var barBack:FlxSprite;
	var barFill:FlxSprite;
	var loadingText:FlxText;

	var queue:Array<String> = [];
	var assetTypes:Map<String, AssetType> = [];
	var totalAssets:Int = 0;
	var loadedAssets:Int = 0;
	var cacheStarted:Bool = false;
	var cacheDone:Bool = false;
	var cacheFinished:Bool = false;

	inline static var ASSETS_PER_FRAME:Int = 4;
	inline static var FADE_TIME:Float = 0.6;
	inline static var DONE_HOLD_TIME:Float = 0.3;

	override function create()
	{
		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		splashImage = new FlxSprite().loadGraphic(Paths.image('newgrounds_logo'));
		splashImage.antialiasing = ClientPrefs.data.antialiasing;
		splashImage.screenCenter();
		splashImage.alpha = 0;
		add(splashImage);

		var barWidth:Int = Std.int(FlxG.width * 0.6);
		var barHeight:Int = 18;
		var barX:Float = (FlxG.width - barWidth) * 0.5;
		var barY:Float = splashImage.y + splashImage.height + 24;

		barBack = new FlxSprite(barX, barY).makeGraphic(barWidth, barHeight, 0xFF262626);
		barBack.alpha = 0;
		add(barBack);

		barFill = new FlxSprite(barBack.x + 2, barBack.y + 2).makeGraphic(barWidth - 4, barHeight - 4, FlxColor.WHITE);
		barFill.origin.set(0, 0);
		barFill.scale.x = 0;
		barFill.alpha = 0;
		add(barFill);

		loadingText = new FlxText(0, barBack.y + 26, FlxG.width, "Preparing cache...", 24);
		loadingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, "center");
		loadingText.alpha = 0;
		add(loadingText);

		queue = buildAssetQueue();
		totalAssets = queue.length;

		FlxTween.tween(splashImage, {alpha: 1}, FADE_TIME, {
			onComplete: function(_)
			{
				cacheStarted = true;
				FlxTween.tween(barBack, {alpha: 1}, 0.2);
				FlxTween.tween(barFill, {alpha: 1}, 0.2);
				FlxTween.tween(loadingText, {alpha: 1}, 0.2);
				loadingText.text = "Caching Assets... (ENTER to skip)";
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (cacheStarted && FlxG.keys.justPressed.ENTER && !cacheFinished && !cacheDone)
		{
			skipToTitle();
			return;
		}

		if (!cacheStarted || cacheFinished || cacheDone) return;

		var i:Int = 0;
		while (i < ASSETS_PER_FRAME && queue.length > 0)
		{
			var id:String = queue.shift();
			cacheAsset(id);
			loadedAssets++;
			i++;
		}

		var progress:Float = (totalAssets > 0) ? (loadedAssets / totalAssets) : 1;
		barFill.scale.x = progress;
		barFill.updateHitbox();

		if (queue.length == 0)
			finishAndGoToTitle();
	}

	function buildAssetQueue():Array<String>
	{
		var result:Array<String> = [];
		var supportedTypes:Array<AssetType> = [IMAGE, SOUND, MUSIC, FONT, TEXT, BINARY];
		for (id in OpenFlAssets.list())
		{
			if (!shouldCacheAsset(id)) continue;

			var type = getAssetType(id, supportedTypes);
			if (type != null)
			{
				assetTypes.set(id, type);
				result.push(id);
			}
		}
		return result;
	}

	function shouldCacheAsset(id:String):Bool
	{
		var key:String = id.toLowerCase();
		if (key.indexOf("assets/shared/images/") != -1) return true;
		if (key.indexOf("assets/songs/") != -1 || key.indexOf("songs:") == 0) return true;
		if (key.indexOf("assets/videos/") != -1) return true;
		if (key.indexOf("/data/") != -1) return true;
		return false;
	}

	function cacheAsset(id:String):Void
	{
		var type:Null<AssetType> = assetTypes.get(id);
		if (type == null) return;
		try
		{
			switch (type)
			{
				case IMAGE:
					OpenFlAssets.getBitmapData(id);
				case SOUND | MUSIC:
					OpenFlAssets.getSound(id);
				case FONT:
					OpenFlAssets.getFont(id);
				case TEXT:
					OpenFlAssets.getText(id);
				case BINARY:
					OpenFlAssets.getBytes(id);
				default:
			}
		}
		catch (e)
		{
			trace('Failed to cache asset "$id": $e');
		}
	}

	function getAssetType(id:String, supportedTypes:Array<AssetType>):Null<AssetType>
	{
		for (type in supportedTypes)
		{
			if (OpenFlAssets.exists(id, type))
				return type;
		}
		return null;
	}

	function finishAndGoToTitle():Void
	{
		if (cacheFinished || cacheDone) return;
		cacheDone = true;
		loadingText.text = "Done!";

		new FlxTimer().start(DONE_HOLD_TIME, function(_)
		{
			cacheFinished = true;
			FlxTween.tween(splashImage, {alpha: 0}, FADE_TIME);
			FlxTween.tween(barBack, {alpha: 0}, FADE_TIME);
			FlxTween.tween(barFill, {alpha: 0}, FADE_TIME);
			FlxTween.tween(loadingText, {alpha: 0}, FADE_TIME);
			new FlxTimer().start(FADE_TIME, function(_)
			{
				MusicBeatState.switchState(new Intro());
			});
		});
	}

	function skipToTitle():Void
	{
		if (cacheFinished) return;
		cacheDone = true;
		cacheFinished = true;
		loadingText.text = "Skipped!";
		FlxTween.tween(splashImage, {alpha: 0}, 0.25);
		FlxTween.tween(barBack, {alpha: 0}, 0.25);
		FlxTween.tween(barFill, {alpha: 0}, 0.25);
		FlxTween.tween(loadingText, {alpha: 0}, 0.25);
		new FlxTimer().start(0.25, function(_)
		{
			MusicBeatState.switchState(new Intro());
		});
	}
}
