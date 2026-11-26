package states;

import backend.WeekData;
import flixel.util.FlxStringUtil;

class OstState extends MusicBeatState
{
	var songs:Array<{name:String, folder:String, color:FlxColor}> = [];
	var songTexts:Array<FlxText> = [];
	var curSelected:Int = 0;
	var curPlaying:Int = -1;

	var progressBg:FlxSprite;
	var progressBar:FlxSprite;
	var timeTxt:FlxText;
	var nowPlayingTxt:FlxText;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Listening to the OST", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF4B3A66;
		add(bg);

		// Collect every song from every week
		WeekData.reloadWeekFiles(false);
		for (weekName in WeekData.weeksList)
		{
			var week:WeekData = WeekData.weeksLoaded.get(weekName);
			if(week == null) continue;

			for (song in week.songs)
			{
				var exists:Bool = false;
				for (s in songs) if(s.name == song[0]) { exists = true; break; }
				if(exists) continue;

				var color:FlxColor = FlxColor.WHITE;
				var colors:Array<Int> = song[2];
				if(colors != null && colors.length > 2) color = FlxColor.fromRGB(colors[0], colors[1], colors[2]);
				songs.push({name: song[0], folder: week.folder, color: color});
			}
		}

		var title:FlxText = new FlxText(0, 25, FlxG.width, "OST", 40);
		title.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		add(title);

		for (i in 0...songs.length)
		{
			var txt:FlxText = new FlxText(0, 0, FlxG.width, songs[i].name, 28);
			txt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			txt.scrollFactor.set();
			add(txt);
			songTexts.push(txt);
		}

		if(songs.length < 1)
		{
			var emptyTxt:FlxText = new FlxText(0, 0, FlxG.width, "No songs found!", 32);
			emptyTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			emptyTxt.screenCenter(Y);
			add(emptyTxt);
		}

		progressBg = new FlxSprite(0, FlxG.height - 110).makeGraphic(1, 1, FlxColor.WHITE);
		progressBg.origin.set(0, 0);
		progressBg.scale.set(604, 24);
		progressBg.color = FlxColor.GRAY;
		progressBg.alpha = 0.6;
		progressBg.screenCenter(X);
		add(progressBg);

		progressBar = new FlxSprite(progressBg.x + 2, progressBg.y + 2).makeGraphic(1, 1, FlxColor.WHITE);
		progressBar.origin.set(0, 0);
		progressBar.scale.set(0, 20);
		progressBar.color = FlxColor.LIME;
		add(progressBar);

		timeTxt = new FlxText(0, progressBg.y + 28, FlxG.width, "", 20);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(timeTxt);

		nowPlayingTxt = new FlxText(0, progressBg.y - 35, FlxG.width, "", 20);
		nowPlayingTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(nowPlayingTxt);

		var helpTxt:FlxText = new FlxText(0, FlxG.height - 30, FlxG.width, "UP/DOWN - Browse / ENTER - Play / SPACE - Pause / ESC - Exit", 16);
		helpTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(helpTxt);

		updateListColors();
		super.create();
	}

	function changeSelection(change:Int)
	{
		if(songs.length < 1) return;
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		updateListColors();
	}

	function updateListColors()
	{
		for (i in 0...songTexts.length)
		{
			var txt:FlxText = songTexts[i];
			txt.text = (i == curPlaying ? '~ ' + songs[i].name + ' ~' : songs[i].name);
			txt.color = (i == curSelected) ? FlxColor.WHITE : FlxColor.fromRGB(160, 160, 160);
			if(i == curPlaying) txt.color = FlxColor.LIME;
		}
	}

	function playSong(index:Int)
	{
		Mods.currentModDirectory = songs[index].folder != null ? songs[index].folder : '';
		FlxG.sound.playMusic(Paths.inst(songs[index].name), 0.8, true);
		curPlaying = index;
		nowPlayingTxt.text = 'Now Playing: ' + songs[index].name;
		progressBar.color = songs[index].color;
		updateListColors();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);
		if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

		if (controls.ACCEPT && songs.length > 0)
			playSong(curSelected);

		if (FlxG.keys.justPressed.SPACE && curPlaying > -1 && FlxG.sound.music != null)
		{
			if(FlxG.sound.music.playing) FlxG.sound.music.pause();
			else FlxG.sound.music.play();
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			Mods.loadTopMod();
			MusicBeatState.switchState(new MainMenuState());
		}

		// Scrolling song list
		for (i in 0...songTexts.length)
		{
			var targetY:Float = 300 + (i - curSelected) * 40;
			songTexts[i].y = FlxMath.lerp(targetY, songTexts[i].y, Math.exp(-elapsed * 12));
			songTexts[i].alpha = Math.max(0.3, 1 - Math.abs(i - curSelected) * 0.15);
			if(i == curSelected || i == curPlaying) songTexts[i].alpha = 1;
		}

		// Progress bar
		if(curPlaying > -1 && FlxG.sound.music != null && FlxG.sound.music.length > 0)
		{
			progressBar.scale.x = 600 * Math.min(1, FlxG.sound.music.time / FlxG.sound.music.length);
			timeTxt.text = FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, false)
				+ ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false)
				+ (FlxG.sound.music.playing ? '' : ' (PAUSED)');
		}

		super.update(elapsed);
	}
}
