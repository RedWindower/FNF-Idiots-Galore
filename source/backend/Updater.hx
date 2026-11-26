package backend;

import haxe.Json;
import haxe.io.BytesInput;
import haxe.io.Path;
import haxe.zip.Reader;
#if sys
import sys.thread.Thread;
#end

/**
 * Auto-updater that checks GitHub Releases and installs new versions.
 *
 * SETUP:
 * 1. Set GITHUB_REPO to your repository (ex: 'SomeUser/FNF-Idiots-Galore').
 * 2. Publish your builds as GitHub Releases, attaching a zip named ASSET_NAME
 *    containing the game files (exe + assets, same layout as the game folder).
 * 3. Set the release's tag to the new version and keep CURRENT_VERSION in sync
 *    with the tag of the build you're compiling.
 */
class Updater
{
	// FILL THIS IN! Your GitHub repository ('owner/repo')
	public static var GITHUB_REPO:String = 'RedWindower/FNF-Idiots-Galore';
	// The zip attached to every GitHub release
	public static var ASSET_NAME:String = 'FNF-Idiots-Galore-windows.zip';
	// Must match the tag_name of the release this build came from
	public static var CURRENT_VERSION:String = '0.0.0';

	public static var latestVersion:String = '';
	public static var downloadUrl:String = null;

	public static function hasRepo():Bool
    return GITHUB_REPO.length > 0 && GITHUB_REPO.contains('/');

	// callback(outdated, latestVersion) - called from a background thread!
	public static function checkForUpdates(?callback:Bool->String->Void)
	{
		if(!hasRepo()) return;
		#if sys
		Thread.create(function() doCheck(callback));
		#else
		doCheck(callback);
		#end
	}

	static function doCheck(?callback:Bool->String->Void)
	{
		try
		{
			var http:haxe.Http = new haxe.Http('https://api.github.com/repos/' + GITHUB_REPO.replace('https://github.com/', '') + '/releases/latest');
			http.setHeader('User-Agent', 'FNF-Idiots-Galore-Updater'); //GitHub API requires a User-Agent
			http.onData = function(data:String)
			{
				var json:Dynamic = Json.parse(data);
				latestVersion = Std.string(json.tag_name).trim();

				var assets:Array<Dynamic> = cast json.assets;
				if(assets != null)
				{
					for (asset in assets)
					{
						if(asset.name == ASSET_NAME)
						{
							downloadUrl = asset.browser_download_url;
							break;
						}
					}
				}

				var outdated:Bool = (latestVersion.length > 0 && latestVersion != CURRENT_VERSION);
				trace('Updater: latest: $latestVersion, current: $CURRENT_VERSION, outdated: $outdated');
				if(callback != null) callback(outdated, latestVersion);
			};
			http.onError = function(error:String) trace('Updater error: $error');
			http.request(false);
		}
		catch(e:Dynamic) trace('Updater exception: $e');
	}

	public static function downloadAndInstall(onProgress:Float->Void, onStatus:String->Void, onError:String->Void)
	{
		if(downloadUrl == null)
		{
			onError('No "$ASSET_NAME" found on the latest release!');
			return;
		}

		#if sys
		onStatus('Downloading update...');
		var request:lime.net.HTTPRequest<lime.utils.Bytes> = new lime.net.HTTPRequest<lime.utils.Bytes>(downloadUrl);
		request.followRedirects = true;
		var future = request.load();
		future.onProgress(function(loaded:Int, total:Int)
		{
			if(total > 0) onProgress(loaded / total);
		});
		future.onError(function(e:Dynamic) onError('Download failed: $e'));
		future.onComplete(function(bytes:lime.utils.Bytes)
		{
			try
			{
				onStatus('Installing update...');
				installUpdate(bytes);
			}
			catch(e:Dynamic) onError('Install failed: $e');
		});
		#else
		onError('Auto-updating is only supported on desktop!');
		#end
	}

	#if sys
	static function installUpdate(bytes:haxe.io.Bytes)
	{
		var entries = Reader.readZip(new BytesInput(bytes));
		if(entries == null || entries.length < 1) throw 'Downloaded zip is empty!';

		// If everything in the zip sits inside one root folder, strip it
		var rootDir:String = null;
		var hasCommonRoot:Bool = true;
		for (entry in entries)
		{
			var slash:Int = entry.fileName.indexOf('/');
			var root:String = slash < 0 ? '' : entry.fileName.substr(0, slash);
			if(root.length < 1)
			{
				hasCommonRoot = false;
				break;
			}
			if(rootDir == null) rootDir = root;
			else if(root != rootDir)
			{
				hasCommonRoot = false;
				break;
			}
		}

		var tempDir:String = 'update_temp';
		if(!FileSystem.exists(tempDir)) FileSystem.createDirectory(tempDir);

		for (entry in entries)
		{
			var name:String = entry.fileName;
			if(hasCommonRoot) name = name.substr(rootDir.length + 1);
			if(name == null || name.length < 1 || name.endsWith('/')) continue;

			var path:String = tempDir + '/' + name;
			var dir:String = Path.directory(path);
			if(dir.length > 0 && !FileSystem.exists(dir)) FileSystem.createDirectory(dir);
			File.saveBytes(path, Reader.unzip(entry));
		}

		// A running exe can't overwrite itself, so a batch script swaps the
		// files after the game closes, then relaunches it
		var exeName:String = Path.withoutDirectory(Sys.programPath());
		var bat:String = '@echo off\r\n'
			+ 'echo Updating, please wait...\r\n'
			+ 'timeout /t 3 /nobreak >nul\r\n'
			+ 'xcopy "%~dp0update_temp\\*" "%~dp0" /s /e /y >nul\r\n'
			+ 'rmdir /s /q "%~dp0update_temp"\r\n'
			+ 'start "" "%~dp0$exeName"\r\n'
			+ 'del "%~f0"\r\n';
		File.saveContent('update.bat', bat);

		new sys.io.Process('cmd', ['/c', 'start', '/min', '', 'update.bat']);
		Sys.exit(0);
	}
	#end
}
