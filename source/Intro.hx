package;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import backend.MP4Handler;
import states.TitleState;

class Intro extends MusicBeatState
{
	var video:MP4Handler;
	var skippingVideo:Bool = false;

	override function create()
	{
		FlxTransitionableState.skipNextTransOut = true;
		super.create();

		video = new MP4Handler();
		video.playMP4(Paths.video("olympic"), new TitleState());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!skippingVideo && FlxG.keys.justPressed.ENTER)
		{
			skippingVideo = true;
			if (video != null) video.skipVideo();
		}
	}
}
