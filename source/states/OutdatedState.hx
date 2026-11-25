package states;

import backend.Updater;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	var progressBg:FlxSprite;
	var progressBar:FlxSprite;
	var progressTxt:FlxText;
	var updating:Bool = false;

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Sup bro, looks like you're running an\n
			outdated version of FNF Idiots Galore (" + Updater.CURRENT_VERSION + "),\n
			please update to " + TitleState.updateVersion + "!\n
			\n
			ENTER - Update automatically\n
			G - Open the GitHub page\n
			ESCAPE - Continue anyway",
			32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		warnText.y -= 60;
		add(warnText);

		progressBg = new FlxSprite(0, FlxG.height - 150).makeGraphic(1, 1, FlxColor.WHITE);
		progressBg.origin.set(0, 0);
		progressBg.scale.set(604, 28);
		progressBg.color = FlxColor.GRAY;
		progressBg.screenCenter(X);
		progressBg.visible = false;
		add(progressBg);

		progressBar = new FlxSprite(progressBg.x + 2, progressBg.y + 2).makeGraphic(1, 1, FlxColor.WHITE);
		progressBar.origin.set(0, 0);
		progressBar.scale.set(0, 24);
		progressBar.color = FlxColor.LIME;
		progressBar.visible = false;
		add(progressBar);

		progressTxt = new FlxText(0, progressBg.y - 40, FlxG.width, "", 24);
		progressTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.YELLOW, CENTER);
		add(progressTxt);
	}

	function startUpdate()
	{
		updating = true;
		progressBg.visible = progressBar.visible = true;
		progressTxt.text = 'Downloading update...';
		FlxG.sound.play(Paths.sound('confirmMenu'));

		Updater.downloadAndInstall(
			function(progress:Float)
			{
				progressBar.scale.x = 600 * progress;
				progressTxt.text = 'Downloading update... ' + Math.floor(progress * 100) + '%';
			},
			function(status:String)
			{
				progressTxt.text = status;
			},
			function(error:String)
			{
				updating = false;
				progressBg.visible = progressBar.visible = false;
				progressTxt.text = 'ERROR: ' + error;
			}
		);
	}

	function leaveState()
	{
		leftState = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		FlxTween.tween(warnText, {alpha: 0}, 1, {
			onComplete: function (twn:FlxTween) {
				MusicBeatState.switchState(new MainMenuState());
			}
		});
	}

	override function update(elapsed:Float)
	{
		if(!updating && !leftState) {
			if (controls.ACCEPT) {
				if(Updater.downloadUrl != null)
					startUpdate();
				else
				{
					if(Updater.hasRepo()) CoolUtil.browserLoad('https://github.com/' + Updater.GITHUB_REPO + '/releases');
					leaveState();
				}
			}
			else if (FlxG.keys.justPressed.G) {
				if(Updater.hasRepo()) CoolUtil.browserLoad('https://github.com/' + Updater.GITHUB_REPO + '/releases');
				leaveState();
			}
			else if (controls.BACK) {
				leaveState();
			}
		}
		super.update(elapsed);
	}
}
