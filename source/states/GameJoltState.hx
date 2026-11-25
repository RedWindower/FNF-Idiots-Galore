package states;

import flixel.addons.ui.FlxUIInputText;
import flixel.ui.FlxButton;
import backend.GameJoltAPI;

class GameJoltState extends MusicBeatState
{
	var usernameInput:FlxUIInputText;
	var tokenInput:FlxUIInputText;
	var statusTxt:FlxText;
	var loginButton:FlxButton;
	var logoutButton:FlxButton;

	var pendingStatus:String = null; //Set from the request thread, applied in update()
	var busy:Bool = false;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("GameJolt Login", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF2F4F3F;
		add(bg);

		var title:FlxText = new FlxText(0, 80, FlxG.width, "GAMEJOLT LOGIN", 40);
		title.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		add(title);

		var userLabel:FlxText = new FlxText(FlxG.width / 2 - 150, 225, 300, "Username:", 16);
		userLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(userLabel);

		usernameInput = new FlxUIInputText(FlxG.width / 2 - 150, 250, 300, GameJoltAPI.username, 16);
		add(usernameInput);

		var tokenLabel:FlxText = new FlxText(FlxG.width / 2 - 150, 300, 300, "Game Token (NOT your password!):", 16);
		tokenLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(tokenLabel);

		tokenInput = new FlxUIInputText(FlxG.width / 2 - 150, 325, 300, '', 16);
		add(tokenInput);

		loginButton = new FlxButton(FlxG.width / 2 - 110, 380, "Login", doLogin);
		add(loginButton);

		logoutButton = new FlxButton(FlxG.width / 2 + 30, 380, "Logout", doLogout);
		add(logoutButton);

		statusTxt = new FlxText(0, 440, FlxG.width, "", 20);
		statusTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(statusTxt);

		if(GameJoltAPI.loggedIn)
			statusTxt.text = 'Logged in as ${GameJoltAPI.username}!';
		else if(!GameJoltAPI.hasCredentials())
			statusTxt.text = 'Game ID / Private Key not set in GameJoltAPI.hx!';

		var infoTxt:FlxText = new FlxText(0, FlxG.height - 120, FlxG.width,
			"Your Game Token can be found on GameJolt:\nProfile Picture -> Settings -> Game Tokens\n\nESC - Go Back", 16);
		infoTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(infoTxt);

		FlxG.mouse.visible = true;
		super.create();
	}

	function doLogin()
	{
		if(busy) return;

		var user:String = usernameInput.text.trim();
		var token:String = tokenInput.text.trim();
		if(user.length < 1 || token.length < 1)
		{
			statusTxt.text = 'Enter your username and game token!';
			return;
		}

		busy = true;
		statusTxt.text = 'Logging in...';
		GameJoltAPI.authUser(user, token, function(success:Bool, message:String)
		{
			pendingStatus = success ? 'Logged in as $user!' : 'Login failed! $message';
			busy = false;
		});
	}

	function doLogout()
	{
		GameJoltAPI.logout();
		statusTxt.text = 'Logged out.';
	}

	override function update(elapsed:Float)
	{
		if(pendingStatus != null)
		{
			statusTxt.text = pendingStatus;
			pendingStatus = null;
		}

		var typing:Bool = usernameInput.hasFocus || tokenInput.hasFocus;
		ClientPrefs.toggleVolumeKeys(!typing);

		if(!typing && !busy && (FlxG.keys.justPressed.ESCAPE || controls.BACK))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}
}
