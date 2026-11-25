package backend;

import flixel.FlxG;
import flixel.FlxState;
import openfl.events.Event;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import vlc.VlcBitmap;
import states.MainMenuState;

class MP4Handler
{
	public static var video:Video;
	public static var netStream:NetStream;
	public static var finishCallback:FlxState;
	static var hasFinished:Bool = false;

	#if desktop
	public static var vlcBitmap:VlcBitmap;
	#end

	public function new()
	{
		FlxG.autoPause = false;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}
	}

	public function playMP4(path:String, callback:FlxState, ?repeat:Bool = false, ?isWindow:Bool = false, ?isFullscreen:Bool = false):Void
	{
		hasFinished = false;
		#if html5
		FlxG.autoPause = false;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		finishCallback = callback;

		video = new Video();
		video.x = 0;
		video.y = 0;

		FlxG.stage.addChild(video);

		var nc = new NetConnection();
		nc.connect(null);

		netStream = new NetStream(nc);
		netStream.client = {onMetaData: client_onMetaData};

		nc.addEventListener("netStatus", netConnection_onNetStatus);

		netStream.play(path);

		// IMPORTANT FIX: attach immediately
		video.attachNetStream(netStream);

		video.width = FlxG.stage.stageWidth;
		video.height = FlxG.stage.stageHeight;

		#else
		// =========================
		// WINDOWS / DESKTOP (FIXED)
		// =========================

		finishCallback = callback;

		vlcBitmap = new VlcBitmap();

		FlxG.autoPause = false;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		// --- FIX: proper sizing ---
		var screenW = FlxG.stage.stageWidth;
		var screenH = FlxG.stage.stageHeight;

		vlcBitmap.width = screenW;
		vlcBitmap.height = screenH;
		vlcBitmap.x = 0;
		vlcBitmap.y = 0;

		// --- FIX: proper layer (CRITICAL) ---
		FlxG.stage.addChild(vlcBitmap);
		FlxG.stage.setChildIndex(vlcBitmap, FlxG.stage.numChildren - 1);

		// --- VLC events ---
		vlcBitmap.onVideoReady = function()
		{
			trace("VLC video ready");

			vlcBitmap.visible = true;
			vlcBitmap.alpha = 1;
		};

		vlcBitmap.onComplete = onVLCComplete;
		vlcBitmap.onError = onVLCError;

		// --- settings ---
		vlcBitmap.repeat = repeat ? -1 : 0;
		vlcBitmap.inWindow = isWindow;
		vlcBitmap.fullscreen = isFullscreen;

		// --- update volume sync ---
		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);

		// --- FIX: safe path ---
		var realPath = checkFile(path);
		trace("Playing video: " + realPath);

		vlcBitmap.play(realPath);
		#end
	}

	#if desktop
	// =========================
	// PATH FIX (IMPORTANT)
	// =========================
	function checkFile(fileName:String):String
	{
		if (StringTools.startsWith(fileName, "http") || StringTools.startsWith(fileName, "file:///"))
			return fileName;

		var path = Sys.getCwd().split("\\").join("/");

		return "file:///" + path + fileName;
	}

	// =========================
	// VLC EVENTS
	// =========================

	function onVLCVideoReady()
	{
		trace("video loaded!");
	}

	public function onVLCComplete()
	{
		trace("Video finished");
		finishVideo();
	}

	function onVLCError()
	{
		trace("VLC error - skipping video");
		finishVideo();
	}

	function update(e:Event)
	{
		if (vlcBitmap != null)
		{
			vlcBitmap.volume = FlxG.sound.volume;
		}
	}
	#end

	// =========================
	// HTML5 META HANDLING
	// =========================

	function client_onMetaData(data)
	{
		video.width = FlxG.stage.stageWidth;
		video.height = FlxG.stage.stageHeight;
	}

	function netConnection_onNetStatus(path)
	{
		if (path.info.code == "NetStream.Play.Complete")
		{
			finishVideo();
		}
	}

	function finishVideo()
	{
		if (hasFinished) return;
		hasFinished = true;

		#if desktop
		if (FlxG.stage != null)
			FlxG.stage.removeEventListener(Event.ENTER_FRAME, update);

		if (vlcBitmap != null)
		{
			vlcBitmap.onComplete = null;
			vlcBitmap.onError = null;
			vlcBitmap.onVideoReady = null;
			vlcBitmap.stop();

			if (FlxG.stage != null && FlxG.stage.contains(vlcBitmap))
				FlxG.stage.removeChild(vlcBitmap);

			vlcBitmap = null;
		}
		#end

		if (netStream != null)
		{
			netStream.close();
			netStream.dispose();
			netStream = null;
		}

		if (video != null)
		{
			video.attachNetStream(null);
			if (FlxG.stage != null && FlxG.stage.contains(video))
				FlxG.stage.removeChild(video);
			video = null;
		}

		var targetState = finishCallback;
		finishCallback = null;

		if (targetState != null)
		{
			LoadingState.loadAndSwitchState(targetState);
		}
		else
		{
			LoadingState.loadAndSwitchState(new MainMenuState());
		}
	}

	public function skipVideo():Void
	{
		finishVideo();
	}
}