package states;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import backend.Song;
class MainMenuState extends MusicBeatState
{
    public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
    public static var idiotsVersion:String = 'DEMO :)';
    public static var curSelected:Int = 0;
    var menuItems:FlxTypedGroup<FlxSprite>;
    var sideBar:FlxSprite;
    var optionShit:Array<String> = [
        'story_mode',
        'freeplay',
        'credits'
    ];
    var itemAssets:Array<String> = ['play', 'freeplay', 'credits'];
    var itemBaseX:Array<Float> = [];
    // Bottom dropdown for extras
    var dropGroup:FlxSpriteGroup;
    var dropBar:FlxSprite;
    var dropItems:Array<FlxSprite> = [];
    var dropOptions:Array<String> = ['awards', 'options', 'gamejolt'];
    var dropOpen:Bool = false;
    var dropSelected:Int = 0;
    var dropClosedY:Float = 0;
    var dropOpenY:Float = 0;
    var dropTween:FlxTween;
    var magenta:FlxSprite;
    var camFollow:FlxObject;
    // Secret main-menu code
    var thanosCode:String = '';
    override function create()
    {
        #if MODS_ALLOWED
        Mods.pushGlobalMods();
        #end

        Mods.loadTopMod();
        #if DISCORD_ALLOWED
        // Updating Discord Rich Presence
        DiscordClient.changePresence("In the Menus", null);
        #end

        transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;
        persistentUpdate = persistentDraw = true;
        backend.GameJoltAPI.init();

        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(1, 1);
        bg.setGraphicSize(Std.int(bg.width * 1.175));
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);
        
        camFollow = new FlxObject(FlxG.width / 2, FlxG.height / 2, 1, 1);
        add(camFollow);
        magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
        magenta.antialiasing = ClientPrefs.data.antialiasing;
        magenta.scrollFactor.set(1, 1);
        magenta.setGraphicSize(Std.int(magenta.width * 1.175));
        magenta.updateHitbox();
        magenta.screenCenter();
        magenta.visible = false;
        magenta.color = 0xFFfd719b;
        add(magenta);
        // SIDEBAR
        sideBar = new FlxSprite().loadGraphic(Paths.image('idiotsmenu/side menu'));
        sideBar.antialiasing = ClientPrefs.data.antialiasing;
        sideBar.setGraphicSize(0, FlxG.height + 10);
        sideBar.updateHitbox();
        sideBar.setPosition(0, -5);
        sideBar.scrollFactor.set();
        add(sideBar);
        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);
        for (i in 0...optionShit.length)
        {
            var menuItem:FlxSprite = new FlxSprite();
            menuItem.antialiasing = ClientPrefs.data.antialiasing;
            menuItem.frames = Paths.getSparrowAtlas('idiotsmenu/' + itemAssets[i]);
            menuItem.animation.addByPrefix('idle', itemAssets[i] + 'anim', 24, false);
            menuItem.animation.addByPrefix('selected', itemAssets[i] + 'select', 24, false);
            menuItem.animation.play('idle');
            menuItem.scale.set(0.6, 0.6);
            menuItem.updateHitbox();
            menuItem.setPosition(55, 100 + i * 185);
            menuItem.scrollFactor.set();
            itemBaseX.push(menuItem.x);
            menuItems.add(menuItem);
        }
        // BOTTOM DROPDOWN
        dropGroup = new FlxSpriteGroup();
        dropGroup.scrollFactor.set();
        add(dropGroup);
        dropBar = new FlxSprite().loadGraphic(Paths.image('idiotsmenu/dropdownalt'));
        dropBar.antialiasing = ClientPrefs.data.antialiasing;
        dropBar.scale.set(1.25, 1.25);
        dropBar.updateHitbox();
        dropGroup.add(dropBar);
        var tabH:Float = 38;
        var slotX:Array<Float> = [dropBar.width \ 1 / 6, dropBar.width \ 3 / 6, dropBar.width * 5 / 6];
        for (i in 0...dropOptions.length)
        {
            var entry:FlxSprite;
            if(dropOptions[i] == 'options')
            {
                entry = new FlxSprite().loadGraphic(Paths.image('idiotsmenu/settings'));
                entry.antialiasing = ClientPrefs.data.antialiasing;
                entry.setGraphicSize(0, 80);
                entry.updateHitbox();
            }
            else
            {
                var txt:FlxText = new FlxText(0, 0, 0, dropOptions[i] == 'awards' ? 'AWARDS' : 'GAMEJOLT', 24);
                txt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                entry = txt;
            }
            entry.x = slotX[i] - entry.width / 2;
            entry.y = tabH + ((dropBar.height - tabH) - entry.height) / 2;
            dropItems.push(entry);
            dropGroup.add(entry);
        }
        dropClosedY = FlxG.height - tabH;
        dropOpenY = FlxG.height - dropBar.height;
        dropGroup.setPosition(FlxG.width - dropBar.width - 25, dropClosedY);
        var idiotsVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "FNF Idiots Galore " + idiotsVersion, 12);
        idiotsVer.scrollFactor.set();
        idiotsVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(idiotsVer);
        var psychVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Psych Engine v" + psychEngineVersion, 12);
        psychVer.scrollFactor.set();
        psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(psychVer);
        changeItem();
        FlxG.mouse.visible = true;
        #if ACHIEVEMENTS_ALLOWED
        // Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
        var leDate = Date.now();
        if (leDate.getDay() == 5 && leDate.getHours() >= 18)
            Achievements.unlock('friday_night_play');
        #if MODS_ALLOWED
        Achievements.reloadList();
        #end
        #end
        super.create();
        FlxG.camera.follow(camFollow, null, 9);
    }
    var selectedSomethin:Bool = false;
    override function update(elapsed:Float)
    {
        if (FlxG.sound.music.volume < 0.8)
        {
            FlxG.sound.music.volume += 0.5 * elapsed;
            if (FreeplayState.vocals != null)
                FreeplayState.vocals.volume += 0.5 * elapsed;
        }
        // Camera subtly follows the cursor
        camFollow.setPosition(
            FlxG.width / 2 + (FlxG.mouse.screenX - FlxG.width / 2) * 0.04,
            FlxG.height / 2 + (FlxG.mouse.screenY - FlxG.height / 2) * 0.04);
        if (!selectedSomethin)
        {
            // Secret code can be entered while the main menu is active.
            if (!dropOpen)
                checkThanosCode();
            // Hover to select
            if (FlxG.mouse.justMoved)
            {
                if (!dropOpen)
                {
                    for (i in 0...menuItems.length)
                    {
                        if (i != curSelected && FlxG.mouse.overlaps(menuItems.members[i]))
                        {
                            selectItem(i);
                            break;
                        }
                    }
                }
                else
                {
                    for (i in 0...dropItems.length)
                    {
                        if (i != dropSelected && FlxG.mouse.overlaps(dropItems[i]))
                        {
                            selectDropItem(i);
                            break;
                        }
                    }
                }
            }
            if (!dropOpen)
            {
                if (controls.UI_UP_P)
                    changeItem(-1);
                if (controls.UI_DOWN_P)
                    changeItem(1);
                if (controls.BACK)
                {
                    selectedSomethin = true;
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                    MusicBeatState.switchState(new TitleState());
                }
                if (controls.ACCEPT)
                    confirmSidebar();
            }
            else
            {
                if (controls.UI_LEFT_P)
                    changeDropItem(-1);
                if (controls.UI_RIGHT_P)
                    changeDropItem(1);
                if (controls.BACK)
                    toggleDropdown();
                if (controls.ACCEPT)
                    confirmDrop();
            }
            if (!selectedSomethin && FlxG.keys.justPressed.TAB)
                toggleDropdown();
            // MOUSE SUPPORT
            if (!selectedSomethin && FlxG.mouse.justPressed)
            {
                if (FlxG.mouse.overlaps(dropBar))
                {
                    var hitItem:Bool = false;
                    if (dropOpen)
                    {
                        for (i in 0...dropItems.length)
                        {
                            if (FlxG.mouse.overlaps(dropItems[i]))
                            {
                                selectDropItem(i);
                                confirmDrop();
                                hitItem = true;
                                break;
                            }
                        }
                    }
                    if (!hitItem) toggleDropdown();
                }
                else if (!dropOpen)
                {
                    for (i in 0...menuItems.length)
                    {
                        if (FlxG.mouse.overlaps(menuItems.members[i]))
                        {
                            selectItem(i);
                            confirmSidebar();
                            break;
                        }
                    }
                }
            }
            #if desktop
            if (!selectedSomethin && controls.justPressed('debug_1'))
            {
                selectedSomethin = true;
                MusicBeatState.switchState(new MasterEditorMenu());
            }
            #end
        }
        super.update(elapsed);
    }
    // Typing THANOS launches scratch-it on Normal difficulty.
    function checkThanosCode()
    {
        if (FlxG.keys.justPressed.T)
            thanosCode = 'T';
        else if (FlxG.keys.justPressed.H)
            thanosCode = thanosCode == 'T' ? 'TH' : '';
        else if (FlxG.keys.justPressed.A)
            thanosCode = thanosCode == 'TH' ? 'THA' : '';
        else if (FlxG.keys.justPressed.N)
            thanosCode = thanosCode == 'THA' ? 'THAN' : '';
        else if (FlxG.keys.justPressed.O)
            thanosCode = thanosCode == 'THAN' ? 'THANO' : '';
        else if (FlxG.keys.justPressed.S)
            thanosCode = thanosCode == 'THANO' ? 'THANOS' : '';
        if (thanosCode == 'THANOS')
        {
            thanosCode = '';
            selectedSomethin = true;
            FlxG.sound.play(Paths.sound('confirmMenu'));
            PlayState.SONG = Song.loadFromJson('scratch-it', 'scratch-it');
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = 1; // Normal
            LoadingState.loadAndSwitchState(new PlayState());
        }
    }
    function confirmSidebar()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        selectedSomethin = true;
        if (ClientPrefs.data.flashing)
            FlxFlicker.flicker(magenta, 1.1, 0.15, false);
        FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
        {
            switch (optionShit[curSelected])
            {
                case 'story_mode':
                    MusicBeatState.switchState(new SectionSelectState(false));
                case 'freeplay':
                    MusicBeatState.switchState(new SectionSelectState(true));
                case 'credits':
                    MusicBeatState.switchState(new CreditsState());
            }
        });
        for (i in 0...menuItems.members.length)
        {
            if (i == curSelected)
                continue;
            FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
                ease: FlxEase.quadOut,
                onComplete: function(twn:FlxTween)
                {
                    menuItems.members[i].kill();
                }
            });
        }
    }
    function toggleDropdown()
    {
        dropOpen = !dropOpen;
        FlxG.sound.play(Paths.sound('scrollMenu'));
        dropBar.loadGraphic(Paths.image(dropOpen ? 'idiotsmenu/dropdown' : 'idiotsmenu/dropdownalt'));
        dropBar.updateHitbox();
        if (dropTween != null) dropTween.cancel();
        dropTween = FlxTween.tween(dropGroup, {y: dropOpen ? dropOpenY : dropClosedY}, 0.35, {ease: FlxEase.quartOut});
        if (dropOpen) changeDropItem(0);
    }
    function changeDropItem(huh:Int)
    {
        selectDropItem(FlxMath.wrap(dropSelected + huh, 0, dropItems.length - 1));
    }
    function selectDropItem(index:Int)
    {
        if (index != dropSelected) FlxG.sound.play(Paths.sound('scrollMenu'));
        dropSelected = index;
        for (i in 0...dropItems.length)
            dropItems[i].color = (i == dropSelected) ? 0xFFFFE97F : FlxColor.WHITE;
    }
    function confirmDrop()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        selectedSomethin = true;
        switch (dropOptions[dropSelected])
        {
            case 'awards':
                #if ACHIEVEMENTS_ALLOWED
                MusicBeatState.switchState(new AchievementsMenuState());
                #else
                selectedSomethin = false;
                #end
            case 'options':
                MusicBeatState.switchState(new OptionsState());
                OptionsState.onPlayState = false;
                if (PlayState.SONG != null)
                {
                    PlayState.SONG.arrowSkin = null;
                    PlayState.SONG.splashSkin = null;
                    PlayState.stageUI = 'normal';
                }
            case 'gamejolt':
                MusicBeatState.switchState(new GameJoltState());
        }
    }
    function changeItem(huh:Int = 0)
    {
        if (curSelected >= menuItems.length) curSelected = 0;
        selectItem(FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1));
    }
    function selectItem(index:Int)
    {
        FlxG.sound.play(Paths.sound('scrollMenu'));
        for (i in 0...menuItems.length)
        {
            var item:FlxSprite = menuItems.members[i];
            if (i == index)
            {
                item.animation.play('selected');
                item.centerOffsets();
                item.x = itemBaseX[i] + 25;
            }
            else
            {
                item.animation.play('idle');
                item.centerOffsets();
                item.x = itemBaseX[i];
            }
        }
        curSelected = index;
    }
}
