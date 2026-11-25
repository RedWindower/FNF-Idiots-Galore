package backend;

import haxe.crypto.Md5;
import haxe.Http;
import haxe.Json;
#if sys
import sys.thread.Thread;
#end

/**
 * Lightweight GameJolt Game API (v1.2) wrapper.
 *
 * SETUP:
 * 1. Go to your game's page on gamejolt.com -> Manage Game -> Game API -> API Settings
 * 2. Copy your Game ID and Private Key into GAME_ID and PRIVATE_KEY below.
 * 3. Create trophies on GameJolt (Game API -> Trophies) and fill `trophyMap`
 *    with your achievement names (from Achievements.hx / achievements.json)
 *    mapped to the GameJolt trophy IDs.
 */
class GameJoltAPI
{
	// FILL THESE IN! (see instructions above)
	public static var GAME_ID:String = 'YOUR_GAME_ID';
	public static var PRIVATE_KEY:String = 'YOUR_PRIVATE_KEY';

	// Achievement name -> GameJolt Trophy ID
	public static var trophyMap:Map<String, Int> = [
		// 'friday_night_play' => 123456,
		// 'week1_nomiss' => 123457,
	];

	public static var loggedIn:Bool = false;
	public static var username:String = '';
	public static var userToken:String = '';

	static final API_URL:String = 'https://api.gamejolt.com/api/game/v1_2';
	static var _inited:Bool = false;

	public static function hasCredentials():Bool
	{
		return GAME_ID != 'YOUR_GAME_ID' && PRIVATE_KEY != 'YOUR_PRIVATE_KEY'
			&& GAME_ID.length > 0 && PRIVATE_KEY.length > 0;
	}

	// Tries to log back in with saved credentials. Called once on boot.
	public static function init()
	{
		if(_inited) return;
		_inited = true;

		if(FlxG.save.data.gjUsername != null && FlxG.save.data.gjToken != null)
		{
			var user:String = FlxG.save.data.gjUsername;
			var token:String = FlxG.save.data.gjToken;
			if(user.length > 0 && token.length > 0)
				authUser(user, token, null);
		}
	}

	public static function authUser(user:String, token:String, ?callback:Bool->String->Void)
	{
		if(!hasCredentials())
		{
			if(callback != null) callback(false, 'Game ID / Private Key not set in GameJoltAPI.hx!');
			return;
		}

		request('/users/auth/?game_id=$GAME_ID&username=${StringTools.urlEncode(user)}&user_token=${StringTools.urlEncode(token)}',
			function(success:Bool, message:String)
			{
				loggedIn = success;
				if(success)
				{
					username = user;
					userToken = token;
					FlxG.save.data.gjUsername = user;
					FlxG.save.data.gjToken = token;
					FlxG.save.flush();
				}
				if(callback != null) callback(success, message);
			});
	}

	public static function logout()
	{
		loggedIn = false;
		username = '';
		userToken = '';
		FlxG.save.data.gjUsername = null;
		FlxG.save.data.gjToken = null;
		FlxG.save.flush();
	}

	// Called automatically when a Psych achievement unlocks
	public static function unlockTrophyByAchievement(achievementName:String)
	{
		if(!loggedIn || !trophyMap.exists(achievementName)) return;
		unlockTrophy(trophyMap.get(achievementName));
	}

	public static function unlockTrophy(trophyId:Int, ?callback:Bool->String->Void)
	{
		if(!loggedIn) return;
		request('/trophies/add-achieved/?game_id=$GAME_ID&username=${StringTools.urlEncode(username)}&user_token=${StringTools.urlEncode(userToken)}&trophy_id=$trophyId', callback);
	}

	static function request(path:String, ?callback:Bool->String->Void)
	{
		var url:String = API_URL + path + '&format=json';
		url += '&signature=' + Md5.encode(url + PRIVATE_KEY);

		#if sys
		Thread.create(function()
		{
			doRequest(url, callback);
		});
		#else
		doRequest(url, callback);
		#end
	}

	static function doRequest(url:String, ?callback:Bool->String->Void)
	{
		var success:Bool = false;
		var message:String = '';
		try
		{
			var http:Http = new Http(url);
			http.onData = function(data:String)
			{
				try
				{
					var json:Dynamic = Json.parse(data);
					success = (json.response.success == 'true' || json.response.success == true);
					if(json.response.message != null) message = Std.string(json.response.message);
				}
				catch(e:Dynamic) message = 'Invalid response: $e';
			};
			http.onError = function(err:String) message = err;
			http.request(false);
		}
		catch(e:Dynamic) message = Std.string(e);

		trace('GameJolt request: success=$success message=$message');
		if(callback != null) callback(success, message);
	}
}
