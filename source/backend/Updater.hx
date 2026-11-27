package backend;

import haxe.Json;
import haxe.io.BytesInput;
import haxe.io.Path;
import haxe.zip.Reader;

#if sys
import sys.thread.Thread;
import sys.FileSystem;
import sys.io.File;
#end

class Updater
{
    public static var GITHUB_REPO:String = 'RedWindower/FNF-Idiots-Galore';
    public static var ASSET_NAME:String = 'FNF-Idiots-Galore-windows.zip';
    public static var CURRENT_VERSION:String = '0.0.3';

    public static var latestVersion:String = '';
    public static var downloadUrl:String = null;

    public static function hasRepo():Bool
    {
        return GITHUB_REPO.length > 0 && GITHUB_REPO.contains('/');
    }

    public static function checkForUpdates(?callback:Bool->String->Void)
    {
        if (!hasRepo())
        {
            trace('Updater: Invalid GitHub repository!');
            return;
        }

        #if sys
        Thread.create(function()
        {
            doCheck(callback);
        });
        #else
        doCheck(callback);
        #end
    }

    static function doCheck(?callback:Bool->String->Void)
    {
        try
        {
            var repo = GITHUB_REPO.replace('https://github.com/', '');

            var http = new haxe.Http(
                'https://api.github.com/repos/' + repo + '/releases/latest'
            );

            http.setHeader('User-Agent', 'FNF-Idiots-Galore-Updater');

            http.onData = function(data:String)
            {
                try
                {
                    var json:Dynamic = Json.parse(data);

                    latestVersion = Std.string(json.tag_name).trim();
                    downloadUrl = null;

                    var assets:Array<Dynamic> = cast json.assets;

                    if (assets != null)
                    {
                        for (asset in assets)
                        {
                            if (asset.name == ASSET_NAME)
                            {
                                downloadUrl = asset.browser_download_url;
                                break;
                            }
                        }
                    }

                    var outdated:Bool =
                        latestVersion.length > 0 &&
                        latestVersion != CURRENT_VERSION;

                    trace('Updater: Latest: ' + latestVersion);
                    trace('Updater: Current: ' + CURRENT_VERSION);
                    trace('Updater: Outdated: ' + outdated);
                    trace('Updater: Download: ' + downloadUrl);

                    if (callback != null)
                        callback(outdated, latestVersion);
                }
                catch (e:Dynamic)
                {
                    trace('Updater JSON error: ' + e);
                }
            };

            http.onError = function(error:String)
            {
                trace('Updater HTTP error: ' + error);
            };

            http.request(false);
        }
        catch (e:Dynamic)
        {
            trace('Updater exception: ' + e);
        }
    }

    public static function downloadAndInstall(
        onProgress:Float->Void,
        onStatus:String->Void,
        onError:String->Void
    )
    {
        if (downloadUrl == null || downloadUrl.length == 0)
        {
            onError('No "' + ASSET_NAME + '" found on the latest release!');
            return;
        }

        #if sys
        onStatus('Downloading update...');

        var request = new lime.net.HTTPRequest<lime.utils.Bytes>(downloadUrl);
        request.followRedirects = true;

        var future = request.load();

        future.onProgress(function(loaded:Int, total:Int)
        {
            if (total > 0)
                onProgress(loaded / total);
        });

        future.onError(function(e:Dynamic)
        {
            onError('Download failed: ' + e);
        });

        future.onComplete(function(bytes:lime.utils.Bytes)
        {
            try
            {
                onStatus('Preparing update...');
                installUpdate(bytes);
                onStatus('Update prepared! Restarting...');
            }
            catch (e:Dynamic)
            {
                onError('Installation failed: ' + e);
            }
        });
        #else
        onError('Auto-updating is only supported on desktop!');
        #end
    }

    #if sys

    static function ensureDirectory(path:String)
    {
        if (path == null || path.length == 0 || FileSystem.exists(path))
            return;

        var parent = Path.directory(path);

        if (parent != path && parent.length > 0 && !FileSystem.exists(parent))
            ensureDirectory(parent);

        if (!FileSystem.exists(path))
            FileSystem.createDirectory(path);
    }

    static function safeZipPath(name:String):String
    {
        name = name.replace('\\', '/');

        if (name.startsWith('/') || name.indexOf(':') >= 0)
            throw 'Unsafe ZIP path: ' + name;

        for (part in name.split('/'))
        {
            if (part == '..')
                throw 'Unsafe ZIP path: ' + name;
        }

        return name;
    }

    static function installUpdate(bytes:lime.utils.Bytes)
    {
        // Convert Lime Bytes into Haxe Bytes.
        var zipBytes:haxe.io.Bytes = haxe.io.Bytes.ofData(bytes.getData());

        var entries = Reader.readZip(new BytesInput(zipBytes));

        if (entries == null || entries.length < 1)
            throw 'Downloaded ZIP is empty!';

        var baseDir = Path.directory(Sys.programPath());

        if (baseDir == null || baseDir.length == 0)
            baseDir = Sys.getCwd();

        var rootDir:String = null;
        var hasCommonRoot:Bool = true;

        // Detect a single enclosing folder.
        for (entry in entries)
        {
            var name = safeZipPath(entry.fileName);

            if (name.length == 0)
                continue;

            var slash = name.indexOf('/');
            var root = slash < 0 ? '' : name.substr(0, slash);

            if (root.length == 0)
            {
                hasCommonRoot = false;
                break;
            }

            if (rootDir == null)
                rootDir = root;
            else if (root != rootDir)
            {
                hasCommonRoot = false;
                break;
            }
        }

        if (rootDir == null)
            hasCommonRoot = false;

        var tempDir = Path.join([baseDir, 'update_temp']);

        if (FileSystem.exists(tempDir))
            FileSystem.deleteDirectory(tempDir);

        ensureDirectory(tempDir);

        // Extract update files.
        for (entry in entries)
        {
            var name = safeZipPath(entry.fileName);

            if (hasCommonRoot)
            {
                if (name == rootDir)
                    continue;

                if (name.startsWith(rootDir + '/'))
                    name = name.substr(rootDir.length + 1);
            }

            if (name.length == 0 || name.endsWith('/'))
                continue;

            var path = Path.join([tempDir, name]);
            var directory = Path.directory(path);

            ensureDirectory(directory);

            File.saveBytes(path, Reader.unzip(entry));
        }

        var exeName = Path.withoutDirectory(Sys.programPath());

        if (exeName == null || exeName.length == 0)
            throw 'Could not determine game executable name!';

        var batPath = Path.join([baseDir, 'update.bat']);

        var bat = '@echo off\r\n'
            + 'title FNF Idiots Galore Updater\r\n'
            + 'cd /d "%~dp0"\r\n'
            + 'echo Updating FNF Idiots Galore...\r\n'
            + ':WAIT\r\n'
            + 'tasklist /FI "IMAGENAME eq ' + exeName + '" 2>NUL | find /I "' + exeName + '" >NUL\r\n'
            + 'if not errorlevel 1 (\r\n'
            + '    timeout /t 1 /nobreak >nul\r\n'
            + '    goto WAIT\r\n'
            + ')\r\n'
            + 'echo Installing update...\r\n'
            + 'xcopy "%~dp0update_temp\\*" "%~dp0" /s /e /y /i >nul\r\n'
            + 'if errorlevel 1 goto ERROR\r\n'
            + 'rmdir /s /q "%~dp0update_temp"\r\n'
            + 'echo Update complete!\r\n'
            + 'start "" "%~dp0' + exeName + '"\r\n'
            + 'del "%~f0"\r\n'
            + 'exit /b\r\n'
            + ':ERROR\r\n'
            + 'echo Update failed! Files remain in update_temp.\r\n'
            + 'pause\r\n';

        File.saveContent(batPath, bat);

        trace('Updater: Launching installer...');

new sys.io.Process('cmd', [
    '/c',
    'start "" /min "' + batPath + '"'
]);

Sys.exit(0);
    }

    #end
}
