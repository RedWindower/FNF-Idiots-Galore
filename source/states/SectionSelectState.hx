package states;

import backend.WeekData;

class SectionSelectState extends MusicBeatState
{
	//The section that Story Mode / Freeplay will be filtered by
	public static var chosenSection:String = 'Main Game';
	public static var curSelected:Int = 0;

	var toFreeplay:Bool = false;
	var sections:Array<String> = [];
	//Sections that always show up, even before any week is assigned to them
	var extraSections:Array<String> = ['SamelThing'];

	var portrait:FlxSprite;
	var nameTxt:FlxText;
	var arrowLeft:FlxText;
	var arrowRight:FlxText;
	var selectedSomethin:Bool = false;

	public function new(toFreeplay:Bool = false)
	{
		this.toFreeplay = toFreeplay;
		super();
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Selecting a Section", null);
		#end

		// Collect every section from the weeks visible in this mode
		WeekData.reloadWeekFiles(!toFreeplay);
		for (weekName in WeekData.weeksList)
		{
			var week:WeekData = WeekData.weeksLoaded.get(weekName);
			if(week != null && !sections.contains(week.section))
				sections.push(week.section);
		}
		if(sections.length < 1) sections.push('Main Game');
		for (extra in extraSections)
			if(!sections.contains(extra))
				sections.push(extra);
		if(curSelected >= sections.length) curSelected = 0;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xFFAAAAFF;
		add(bg);

		var title:FlxText = new FlxText(0, 50, FlxG.width, toFreeplay ? "FREEPLAY" : "STORY MODE", 40);
		title.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(title);

		var subTitle:FlxText = new FlxText(0, 105, FlxG.width, "Select a Section", 24);
		subTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(subTitle);

		portrait = new FlxSprite();
		portrait.antialiasing = ClientPrefs.data.antialiasing;
		add(portrait);

		nameTxt = new FlxText(0, FlxG.height - 150, FlxG.width, "", 36);
		nameTxt.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(nameTxt);

		arrowLeft = new FlxText(80, FlxG.height / 2 - 30, 0, "<", 60);
		arrowLeft.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(arrowLeft);

		arrowRight = new FlxText(FlxG.width - 120, FlxG.height / 2 - 30, 0, ">", 60);
		arrowRight.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(arrowRight);

		arrowLeft.visible = arrowRight.visible = (sections.length > 1);

		changeSelection(0);
		FlxG.mouse.visible = true;
		super.create();
	}

	function changeSelection(change:Int)
	{
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
		curSelected = FlxMath.wrap(curSelected + change, 0, sections.length - 1);

		var section:String = sections[curSelected];
		nameTxt.text = section;

		var portraitPath:String = 'sections/' + Paths.formatToSongPath(section);
		if(!Paths.fileExists('images/$portraitPath.png', IMAGE))
			portraitPath = 'newgrounds_logo';

		portrait.loadGraphic(Paths.image(portraitPath));
		var scale:Float = Math.min(500 / portrait.width, 350 / portrait.height);
		portrait.scale.set(scale, scale);
		portrait.updateHitbox();
		portrait.screenCenter();
		portrait.y += 30;
	}

	function acceptSection()
	{
		var section:String = sections[curSelected];

		// Don't enter a section that has no weeks yet, that would crash the menus
		var hasWeeks:Bool = false;
		for (weekName in WeekData.weeksList)
		{
			var week:WeekData = WeekData.weeksLoaded.get(weekName);
			if(week != null && week.section == section)
			{
				hasWeeks = true;
				break;
			}
		}
		if(!hasWeeks)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			nameTxt.text = section + ' (No weeks yet!)';
			return;
		}

		selectedSomethin = true;
		chosenSection = section;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		MusicBeatState.switchState(toFreeplay ? new FreeplayState() : new StoryMenuState());
	}

	override function update(elapsed:Float)
	{
		if(!selectedSomethin)
		{
			if (controls.UI_LEFT_P) changeSelection(-1);
			if (controls.UI_RIGHT_P) changeSelection(1);
			if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

			if (controls.ACCEPT || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(portrait)))
				acceptSection();
			else if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(arrowLeft) && arrowLeft.visible)
				changeSelection(-1);
			else if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(arrowRight) && arrowRight.visible)
				changeSelection(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		super.update(elapsed);
	}
}
