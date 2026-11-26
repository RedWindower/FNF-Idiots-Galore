package states;

class GalleryState extends MusicBeatState
{
	var images:Array<String> = [];
	var curSelected:Int = 0;

	var picture:FlxSprite;
	var nameTxt:FlxText;
	var counterTxt:FlxText;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Viewing the Gallery", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF333344;
		add(bg);

		// Find every PNG inside an images/gallery folder (base game + mods)
		#if sys
		var folders:Array<String> = [Paths.getSharedPath('images/gallery/')];
		#if MODS_ALLOWED
		folders.push(Paths.mods('images/gallery/'));
		for (mod in Mods.parseList().enabled)
			folders.push(Paths.mods(mod + '/images/gallery/'));
		#end

		for (folder in folders)
		{
			if(!FileSystem.exists(folder)) continue;
			for (file in FileSystem.readDirectory(folder))
			{
				if(file.toLowerCase().endsWith('.png'))
				{
					var name:String = file.substr(0, file.length - 4);
					if(!images.contains(name)) images.push(name);
				}
			}
		}
		images.sort(function(a:String, b:String) return (a.toLowerCase() < b.toLowerCase()) ? -1 : 1);
		#end

		var title:FlxText = new FlxText(0, 20, FlxG.width, "GALLERY", 40);
		title.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(title);

		picture = new FlxSprite();
		picture.antialiasing = ClientPrefs.data.antialiasing;
		add(picture);

		nameTxt = new FlxText(0, FlxG.height - 90, FlxG.width, "", 28);
		nameTxt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(nameTxt);

		counterTxt = new FlxText(0, FlxG.height - 55, FlxG.width, "", 20);
		counterTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(counterTxt);

		var helpTxt:FlxText = new FlxText(0, FlxG.height - 30, FlxG.width, "LEFT/RIGHT - Browse / ESC - Exit", 16);
		helpTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(helpTxt);

		if(images.length < 1)
		{
			nameTxt.text = 'No images yet!';
			counterTxt.text = 'Put PNGs in "images/gallery" to show them here.';
		}
		else changeImage(0);

		super.create();
	}

	function changeImage(change:Int)
	{
		if(images.length < 1) return;
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
		curSelected = FlxMath.wrap(curSelected + change, 0, images.length - 1);

		picture.loadGraphic(Paths.image('gallery/' + images[curSelected]));
		var scale:Float = Math.min(1100 / picture.frameWidth, 500 / picture.frameHeight);
		if(scale > 1) scale = 1;
		picture.scale.set(scale, scale);
		picture.updateHitbox();
		picture.screenCenter();
		picture.y += 10;

		nameTxt.text = images[curSelected];
		counterTxt.text = '< ' + (curSelected + 1) + ' / ' + images.length + ' >';
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_LEFT_P) changeImage(-1);
		if (controls.UI_RIGHT_P) changeImage(1);
		if (FlxG.mouse.wheel != 0) changeImage(-FlxG.mouse.wheel);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}
}
