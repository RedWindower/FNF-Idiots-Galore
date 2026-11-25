package states.editors;

import flixel.FlxObject;
import flixel.graphics.FlxGraphic;

import flixel.animation.FlxAnimation;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.*;
import flixel.ui.FlxButton;
import flixel.util.FlxDestroyUtil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;
import lime.system.Clipboard;

import objects.Character;
import objects.HealthIcon;
import objects.Bar;

class CharacterEditorState extends MusicBeatState
{
	var character:Character;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var charMarker:FlxSprite;
	var unsavedTxt:FlxText;
	var exitWarnTxt:FlxText;
	var unsavedChanges:Bool = false;
	var exitWarnTime:Float = 0;
	var autosaveTimer:Float = 0;

	var undoStack:Array<Array<Dynamic>> = [];
	var redoStack:Array<Array<Dynamic>> = [];
	var offsetGestureTime:Float = 0;

	var movingCharacter:Bool = false;

	var previewPlaying:Bool = false;
	var previewBpm:Float = 120;
	var previewTimer:Float = 0;
	var previewBeat:Int = 0;
	var previewDanced:Bool = false;
	var previewSingTimer:Float = 0;

	var anims = null;
	var animsTxtGroup:FlxTypedGroup<FlxText>;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if(this._char == null) this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		if(ClientPrefs.data.cacheOnGPU) Paths.clearStoredMemory();

		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		loadBG();

		animsTxtGroup = new FlxTypedGroup<FlxText>();
		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/silhouetteDad'));
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		silhouettes.add(dad);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		silhouettes.add(boyfriend);

		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);

		addCharacter();

		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		add(cameraFollowPointer);

		charMarker = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		charMarker.setGraphicSize(20, 20);
		charMarker.updateHitbox();
		charMarker.color = FlxColor.LIME;
		add(charMarker);

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		add(healthBar);
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, false);
		healthIcon.y = FlxG.height - 150;
		add(healthIcon);
		healthIcon.cameras = [camHUD];

		animsTxtGroup.cameras = [camHUD];
		add(animsTxtGroup);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 16);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		unsavedTxt = new FlxText(0, 100, 350, '* UNSAVED CHANGES *');
		unsavedTxt.setFormat(null, 16, FlxColor.YELLOW, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		unsavedTxt.scrollFactor.set();
		unsavedTxt.borderSize = 1;
		unsavedTxt.screenCenter(X);
		unsavedTxt.cameras = [camHUD];
		unsavedTxt.visible = false;
		add(unsavedTxt);

		exitWarnTxt = new FlxText(0, 0, 600, 'You have unsaved changes!\nPress ESC again to exit anyway.');
		exitWarnTxt.setFormat(null, 24, FlxColor.RED, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		exitWarnTxt.scrollFactor.set();
		exitWarnTxt.borderSize = 2;
		exitWarnTxt.screenCenter();
		exitWarnTxt.cameras = [camHUD];
		exitWarnTxt.visible = false;
		add(exitWarnTxt);

		addHelpScreen();
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		makeUIMenu();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		if(ClientPrefs.data.cacheOnGPU) Paths.clearUnusedMemory();

		super.create();
	}

	function addHelpScreen()
	{
		var str:String = "CAMERA
		\nE/Q - Camera Zoom In/Out
		\nMouse Wheel - Zoom In/Out (towards cursor)
		\nJ/K/L/I - Move Camera
		\nF - Focus Camera on Character
		\nR - Reset Camera Zoom
		\n
		\nCHARACTER
		\nCtrl + R - Reset Current Offset
		\nCtrl + C - Copy Current Offset
		\nCtrl + V - Paste Copied Offset on Current Animation
		\nCtrl + Z / Ctrl + Y - Undo/Redo Offset Changes
		\nW/S - Previous/Next Animation
		\nSpace - Replay Animation
		\nArrow Keys/Mouse & Right Click - Move Offset
		\nLeft Click & Drag - Move Character Position
		\n1/2/3/4 - Play Sing Animations
		\nA/D - Frame Advance (Back/Forward)
		\n
		\nOTHER
		\nF12 - Toggle Silhouettes
		\nHold Shift - Move Offsets 10x faster and Camera 4x faster
		\nHold Control - Move camera 4x slower";

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		var arr = str.split('\n');
		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i in 0...arr.length)
		{
			if(arr[i].length < 2) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, arr[i], 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - arr.length/2) * 16);
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		if(character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		var isPlayer = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if(!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if(check_player != null) check_player.checked = character.isPlayer;
		}
		character.debugMode = true;

		if(pos > -1) insert(pos, character);
		else add(character);
		updateCharacterPositions();
		reloadAnimList();
		if(healthBar != null && healthIcon != null) updateHealthBar();
	}

	function makeUIMenu()
	{
		var tabs = [
			{name: 'Ghost', label: 'Ghost'},
			{name: 'Settings', label: 'Settings'},
			{name: 'Preview', label: 'Preview'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camHUD];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camHUD];

		UI_characterbox.resize(350, 280);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addSettingsUI();
		addPreviewUI();
		addAnimationsUI();
		addCharacterUI();

		UI_box.selected_tab_id = 'Settings';
		UI_characterbox.selected_tab_id = 'Character';
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Ghost";

		//var hideGhostButton:FlxButton = null;
		var makeGhostButton:FlxButton = new FlxButton(25, 15, "Make Ghost", function() {
			var anim = anims[curAnim];
			if(!character.isAnimationNull())
			{
				var myAnim = anims[curAnim];
				if(!character.isAnimateAtlas)
				{
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				}
				else if(myAnim != null) //This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if(animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if(animateGhost == null || animateGhostImage != character.imageFile)
						Paths.loadAnimateAtlas(animateGhost, character.imageFile);
					
					if(myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}
				
				var spr:FlxSprite = !character.isAnimateAtlas ? ghost : animateGhost;
				if(spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if(otherSpr != null) otherSpr.visible = false;
				}
				/*hideGhostButton.active = true;
				hideGhostButton.alpha = 1;*/
				trace('created ghost image');
			}
		});

		/*hideGhostButton = new FlxButton(20 + makeGhostButton.width, makeGhostButton.y, "Hide Ghost", function() {
			ghost.visible = false;
			hideGhostButton.active = false;
			hideGhostButton.alpha = 0.6;
		});
		hideGhostButton.active = false;
		hideGhostButton.alpha = 0.6;*/

		var highlightGhost:FlxUICheckBox = new FlxUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, null, null, "Highlight Ghost", 100);
		highlightGhost.callback = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if(animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		};

		var ghostAlphaSlider:FlxUISlider = new FlxUISlider(this, 'ghostAlpha', 10, makeGhostButton.y + 25, 0, 1, 210, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		ghostAlphaSlider.nameLabel.text = 'Opacity:';
		ghostAlphaSlider.decimals = 2;
		ghostAlphaSlider.callback = function(relativePos:Float) {
			ghost.alpha = ghostAlpha;
			if(animateGhost != null) animateGhost.alpha = ghostAlpha;
		};
		ghostAlphaSlider.value = ghostAlpha;

		tab_group.add(makeGhostButton);
		//tab_group.add(hideGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
		UI_box.addGroup(tab_group);
	}

	var check_player:FlxUICheckBox;
	var charDropDown:FlxUIDropDownMenu;
	function addSettingsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = character.isPlayer;
		check_player.callback = function()
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			updateCharacterPositions();
			updatePointerPos(false);
			markUnsaved();
		};

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			final _template:CharacterFile =
			{
				animations: [
					newAnim('idle', 'BF idle dance'),
					newAnim('singLEFT', 'BF NOTE LEFT0'),
					newAnim('singDOWN', 'BF NOTE DOWN0'),
					newAnim('singUP', 'BF NOTE UP0'),
					newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: 'face',
				image: 'characters/BOYFRIEND',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				camera_position: [0, 0],
				position: [0, 0],
				vocals_file: null
			};

			character.loadCharacterFile(_template);
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
			markUnsaved();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;


		charDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(index:String)
		{
			var intended = characterList[Std.parseInt(index)];
			if(intended == null || intended.length < 1) return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				_char = intended;
				check_player.checked = character.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
		UI_box.addGroup(tab_group);
	}

	var previewBpmStepper:FlxUINumericStepper;
	var metronomeCheckBox:FlxUICheckBox;
	var playBeatButton:FlxButton;
	function addPreviewUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Preview";

		previewBpmStepper = new FlxUINumericStepper(10, 30, 1, 120, 1, 400, 0);
		metronomeCheckBox = new FlxUICheckBox(110, 27, null, null, "Metronome", 100);

		playBeatButton = new FlxButton(10, 60, "Play Beat", function()
		{
			previewPlaying = !previewPlaying;
			playBeatButton.text = previewPlaying ? "Stop Beat" : "Play Beat";
			if(previewPlaying)
			{
				previewTimer = 60 / previewBpm; //Makes the first beat trigger instantly
				previewBeat = -1;
				previewSingTimer = 999;
			}
		});

		tab_group.add(new FlxText(10, 12, 0, 'Preview BPM:'));
		tab_group.add(new FlxText(110, 62, 0, '1-4: Sing anims'));
		tab_group.add(previewBpmStepper);
		tab_group.add(metronomeCheckBox);
		tab_group.add(playBeatButton);
		UI_box.addGroup(tab_group);
	}

	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	function addAnimationsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";


		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenu(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if(indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(character.animOffsets.exists(animationInputText.text))
					{
						if(!character.isAnimateAtlas) character.animation.remove(animationInputText.text);
						else @:privateAccess character.atlas.anim.animsMap.remove(animationInputText.text);
					}
					character.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			character.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			markUnsaved();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 60, "Remove", function() {
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if(anim.anim == character.getAnimationName()) resetAnim = true;
					if(character.animOffsets.exists(anim.anim))
					{
						if(!character.isAnimateAtlas) character.animation.remove(anim.anim);
						else @:privateAccess character.atlas.anim.animsMap.remove(anim.anim);
						character.animOffsets.remove(anim.anim);
						character.animationsArray.remove(anim);
					}

					if(resetAnim && character.animationsArray.length > 0) {
						curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
						character.playAnim(anims[curAnim].anim, true);
						updateTextColors();
					}
					reloadAnimList();
					markUnsaved();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		var copyOffsetsButton:FlxButton = new FlxButton(160, animationInputText.y - 55, "Copy Offsets", function() {
			var selectedAnimation:Int = Std.parseInt(animationDropDown.selectedId);
			var source:AnimArray = character.animationsArray[selectedAnimation];
			var dest:AnimArray = anims[curAnim];
			if(source == null || dest == null || source == dest) return;

			pushOffsetUndo(dest.anim, dest.offsets[0], dest.offsets[1]);
			applyOffsets(dest, source.offsets[0], source.offsets[1]);
			trace('Copied offsets from ' + source.anim + ' to ' + dest.anim);
		});

		var moveUpButton:FlxButton = new FlxButton(10, animationIndicesInputText.y + 30, "Move Up", function() moveAnimation(-1));
		var moveDownButton:FlxButton = new FlxButton(100, animationIndicesInputText.y + 30, "Move Down", function() moveAnimation(1));
		var cloneButton:FlxButton = new FlxButton(190, animationIndicesInputText.y + 30, "Clone Anim", function() cloneAnimation());

		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(copyOffsetsButton);
		tab_group.add(moveUpButton);
		tab_group.add(moveDownButton);
		tab_group.add(cloneButton);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;
	var vocalsInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;
	function addCharacterUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, character.imageFile, 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(!character.isAnimationNull()) {
				character.playAnim(lastAnim, true);
			}
		});

		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon));
				character.healthColorArray[0] = coolColor.red;
				character.healthColorArray[1] = coolColor.green;
				character.healthColorArray[2] = coolColor.blue;
				updateHealthBar();
				markUnsaved();
			});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter(), 8);

		vocalsInputText = new FlxUIInputText(15, healthIconInputText.y + 35, 75, character.vocalsFile != null ? character.vocalsFile : '', 8);

		singDurationStepper = new FlxUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if(character.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function() {
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
			markUnsaved();
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			character.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing) {
				character.antialiasing = true;
			}
			character.noAntialiasing = noAntialiasingCheckBox.checked;
			markUnsaved();
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, character.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, character.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, character.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, character.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, vocalsInputText.y - 18, 0, 'Vocals File Postfix:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id != FlxUIInputText.CHANGE_EVENT && id != FlxUINumericStepper.CHANGE_EVENT) return;

		if(sender is FlxUIInputText)
		{
			if(sender == healthIconInputText) {
				var lastIcon = healthIcon.getCharacter();
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if(lastIcon != healthIcon.getCharacter()) updatePresence();
			}
			else if(sender == vocalsInputText)
				character.vocalsFile = vocalsInputText.text;
			else if(sender == imageInputText)
				character.imageFile = imageInputText.text;
		}
		else if(sender is FlxUINumericStepper)
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
			}
			else if(sender == positionXStepper)
			{
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
			}
			else if(sender == positionYStepper)
			{
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
			}
			else if(sender == singDurationStepper)
			{
				character.singDuration = singDurationStepper.value;
			}
			else if(sender == positionCameraXStepper)
			{
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if(sender == positionCameraYStepper)
			{
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if(sender == healthColorStepperR)
			{
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
			}
			else if(sender == healthColorStepperG)
			{
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
			}
			else if(sender == healthColorStepperB)
			{
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
			}
			else if(sender == previewBpmStepper)
			{
				previewBpm = Math.max(1, previewBpmStepper.value);
			}
		}

		if(sender == healthIconInputText || sender == vocalsInputText || sender == imageInputText
			|| (sender is FlxUINumericStepper && sender != previewBpmStepper)) markUnsaved();
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.destroyAtlas();
		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		if(Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			character.atlas = new FlxAnimate();
			character.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(character.atlas, character.imageFile);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			}
			character.isAnimateAtlas = true;
		}
		else if(Paths.fileExists('images/' + character.imageFile + '.txt', TEXT)) character.frames = Paths.getPackerAtlas(character.imageFile);
		else if(Paths.fileExists('images/' + character.imageFile + '.json', TEXT)) character.frames = Paths.getAsepriteAtlas(character.imageFile);
		else character.frames = Paths.getSparrowAtlas(character.imageFile);

		for (anim in anims) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if(anims.length > 0)
		{
			if(lastAnim != '') character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function reloadCharacterOptions() {
		if(UI_characterbox == null) return;

		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		reloadAnimationDropDown();
		updateHealthBar();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(animationInputText.hasFocus || animationNameInputText.hasFocus || animationIndicesInputText.hasFocus || imageInputText.hasFocus || healthIconInputText.hasFocus || vocalsInputText.hasFocus)
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if(FlxG.mouse.wheel != 0 && !FlxG.mouse.overlaps(UI_box, camHUD) && !FlxG.mouse.overlaps(UI_characterbox, camHUD))
		{
			var mouseWorld:FlxPoint = FlxG.mouse.getWorldPosition(FlxG.camera);
			FlxG.camera.zoom = FlxMath.bound(FlxG.camera.zoom + FlxG.mouse.wheel * 0.1 * FlxG.camera.zoom, 0.1, 3);
			var newWorld:FlxPoint = FlxG.mouse.getWorldPosition(FlxG.camera);
			FlxG.camera.scroll.x += mouseWorld.x - newWorld.x;
			FlxG.camera.scroll.y += mouseWorld.y - newWorld.y;
			mouseWorld.put();
			newWorld.put();
		}

		if(FlxG.keys.justPressed.F)
		{
			FlxG.camera.scroll.x = character.getMidpoint().x - FlxG.width / 2;
			FlxG.camera.scroll.y = character.getMidpoint().y - FlxG.height / 2;
		}

		if(lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if(anims.length > 1)
		{
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

			if(changedAnim)
			{
				offsetGestureTime = 0;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
				character.playAnim(anims[curAnim].anim, true);
				updateTextColors();
			}
		}

		var preOffsets:Array<Float> = [character.offset.x, character.offset.y];
		var changedOffset = false;
		var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if(moveKeysP.contains(true))
		{
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if(moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if(holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while(holdingArrowsElapsed > (1/60))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1/60);
					changedOffset = true;
				}
			}
		}
		else holdingArrowsTime = 0;

		if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if(FlxG.mouse.justPressed && !helpBg.visible && !FlxG.mouse.overlaps(UI_box, camHUD) && !FlxG.mouse.overlaps(UI_characterbox, camHUD))
			movingCharacter = true;

		if(movingCharacter)
		{
			if(!FlxG.mouse.pressed)
			{
				movingCharacter = false;
				positionXStepper.value = character.positionArray[0];
				positionYStepper.value = character.positionArray[1];
			}
			else if(FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)
			{
				character.positionArray[0] += FlxG.mouse.deltaScreenX / FlxG.camera.zoom;
				character.positionArray[1] += FlxG.mouse.deltaScreenY / FlxG.camera.zoom;
				updateCharacterPositions();
				updatePointerPos(false);
				markUnsaved();
			}
		}

		if(FlxG.keys.pressed.CONTROL)
		{
			if(FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.V)
			{
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.R)
			{
				character.offset.set(0, 0);
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.Z && undoStack.length > 0)
			{
				var entry:Array<Dynamic> = undoStack.pop();
				var target:AnimArray = findAnimByName(entry[0]);
				if(target != null)
				{
					redoStack.push([entry[0], target.offsets[0], target.offsets[1]]);
					applyOffsets(target, entry[1], entry[2]);
				}
			}
			else if(FlxG.keys.justPressed.Y && redoStack.length > 0)
			{
				var entry:Array<Dynamic> = redoStack.pop();
				var target:AnimArray = findAnimByName(entry[0]);
				if(target != null)
				{
					undoStack.push([entry[0], target.offsets[0], target.offsets[1]]);
					applyOffsets(target, entry[1], entry[2]);
				}
			}
		}

		offsetGestureTime -= elapsed;
		var anim = anims[curAnim];
		if(changedOffset && anim != null && anim.offsets != null)
		{
			if(preOffsets[0] != character.offset.x || preOffsets[1] != character.offset.y)
			{
				if(offsetGestureTime <= 0) pushOffsetUndo(anim.anim, preOffsets[0], preOffsets[1]);
				offsetGestureTime = 0.5;
				markUnsaved();
			}

			anim.offsets[0] = Std.int(character.offset.x);
			anim.offsets[1] = Std.int(character.offset.y);

			var myText:FlxText = animsTxtGroup.members[curAnim];
			myText.text = anim.anim + ": " + anim.offsets;
			character.addOffset(anim.anim, character.offset.x, character.offset.y);
		}

		var txt = 'ERROR: No Animation Found';
		var clr = FlxColor.RED;
		if(!character.isAnimationNull())
		{
			if(FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if(holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
			}
			else holdingFrameTime = 0;

			if(FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = 0;
			var length:Int = 0;
			if(!character.isAnimateAtlas)
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;
			}
			else
			{
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length;
			}

			if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
			{
				var isLeft = false;
				if((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
				character.animPaused = true;

				if(holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
				{
					frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length-1);
					if(!character.isAnimateAtlas) character.animation.curAnim.curFrame = frames;
					else character.atlas.anim.curFrame = frames;
					holdingFrameElapsed -= 0.1;
				}
			}

			txt = 'Frames: ( $frames / ${length-1} )';
			//if(character.animation.curAnim.paused) txt += ' - PAUSED';
			clr = FlxColor.WHITE;
		}
		if(txt != frameAdvanceText.text) frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;

		// PREVIEW
		var singKeys:Array<Bool> = [FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR];
		if(singKeys.contains(true))
		{
			var singAnims:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
			for (i in 0...singKeys.length)
			{
				if(singKeys[i])
				{
					previewPlayAnim(singAnims[i]);
					previewSingTimer = 0;
				}
			}
		}

		if(previewPlaying)
		{
			previewSingTimer += elapsed;
			previewTimer += elapsed;
			var crochet:Float = 60 / previewBpm;
			while(previewTimer >= crochet)
			{
				previewTimer -= crochet;
				previewBeat++;
				if(metronomeCheckBox.checked) FlxG.sound.play(Paths.sound('Metronome_Tick'));

				var danceBeats:Int = character.danceIdle ? 1 : 2;
				var singing:Bool = character.getAnimationName().startsWith('sing');
				if(previewBeat % danceBeats == 0 && (!singing || previewSingTimer >= (crochet / 4) * character.singDuration))
					previewDance();

				healthIcon.scale.set(1.2, 1.2);
			}
		}

		if(healthIcon.scale.x != 1)
		{
			var newScale:Float = FlxMath.lerp(1, healthIcon.scale.x, Math.exp(-elapsed * 9));
			if(Math.abs(newScale - 1) < 0.001) newScale = 1;
			healthIcon.scale.set(newScale, newScale);
		}

		charMarker.setPosition(character.x - charMarker.width / 2, character.y - charMarker.height / 2);

		if(exitWarnTime > 0)
		{
			exitWarnTime -= elapsed;
			if(exitWarnTime <= 0) exitWarnTxt.visible = false;
		}

		autosaveTimer += elapsed;
		if(autosaveTimer >= 60)
		{
			autosaveTimer = 0;
			if(unsavedChanges) autosaveCharacter();
		}

		// OTHER CONTROLS
		if(FlxG.keys.justPressed.F12)
			silhouettes.visible = !silhouettes.visible;

		if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
		{
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		}
		else if(FlxG.keys.justPressed.ESCAPE)
		{
			if(unsavedChanges && exitWarnTime <= 0)
			{
				exitWarnTime = 3;
				exitWarnTxt.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}

			if(unsavedChanges) autosaveCharacter();
			FlxG.mouse.visible = false;
			if(!_goToPlayState)
			{
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			else MusicBeatState.switchState(new PlayState());
			return;
		}
	}

	final assetFolder = 'week1';  //load from assets/week1/
	function pushOffsetUndo(animName:String, offX:Float, offY:Float)
	{
		undoStack.push([animName, offX, offY]);
		if(undoStack.length > 100) undoStack.shift();
		redoStack = [];
	}

	function findAnimByName(name:String):AnimArray
	{
		for (anim in character.animationsArray)
			if(anim.anim == name) return anim;
		return null;
	}

	function applyOffsets(target:AnimArray, offX:Float, offY:Float)
	{
		target.offsets[0] = Std.int(offX);
		target.offsets[1] = Std.int(offY);
		character.addOffset(target.anim, target.offsets[0], target.offsets[1]);

		var idx:Int = character.animationsArray.indexOf(target);
		if(idx > -1 && animsTxtGroup.members[idx] != null)
			animsTxtGroup.members[idx].text = target.anim + ": " + target.offsets;
		if(idx == curAnim) character.offset.set(target.offsets[0], target.offsets[1]);
		markUnsaved();
	}

	function moveAnimation(dir:Int)
	{
		var newIndex:Int = curAnim + dir;
		if(anims.length < 2 || newIndex < 0 || newIndex >= anims.length) return;

		var tmp:AnimArray = character.animationsArray[curAnim];
		character.animationsArray[curAnim] = character.animationsArray[newIndex];
		character.animationsArray[newIndex] = tmp;

		reloadAnimList();
		curAnim = newIndex;
		character.playAnim(anims[curAnim].anim, true);
		updateTextColors();
		markUnsaved();
	}

	function cloneAnimation()
	{
		var anim:AnimArray = anims[curAnim];
		if(anim == null) return;

		var newName:String = anim.anim + '-copy';
		while(findAnimByName(newName) != null) newName += '-copy';

		var cloned:AnimArray = {
			anim: newName,
			name: anim.name,
			fps: anim.fps,
			loop: anim.loop,
			indices: anim.indices != null ? anim.indices.copy() : [],
			offsets: [anim.offsets[0], anim.offsets[1]]
		};
		character.animationsArray.push(cloned);
		addAnimation(cloned.anim, cloned.name, cloned.fps, cloned.loop, cloned.indices);
		character.addOffset(cloned.anim, cloned.offsets[0], cloned.offsets[1]);

		reloadAnimList();
		curAnim = character.animationsArray.indexOf(cloned);
		character.playAnim(cloned.anim, true);
		updateTextColors();
		markUnsaved();
	}

	function markUnsaved()
	{
		unsavedChanges = true;
		if(unsavedTxt != null) unsavedTxt.visible = true;
	}

	function previewPlayAnim(name:String)
	{
		if(!character.animOffsets.exists(name)) return;
		character.playAnim(name, true);
		for (i in 0...anims.length)
		{
			if(anims[i].anim == name)
			{
				curAnim = i;
				break;
			}
		}
		updateTextColors();
	}

	function previewDance()
	{
		if(character.danceIdle)
		{
			previewDanced = !previewDanced;
			previewPlayAnim((previewDanced ? 'danceRight' : 'danceLeft') + character.idleSuffix);
		}
		else previewPlayAnim('idle' + character.idleSuffix);
	}

	function autosaveCharacter()
	{
		#if sys
		if(!FileSystem.exists('charBackups')) FileSystem.createDirectory('charBackups');
		File.saveContent('charBackups/$_char-backup.json', buildCharacterJson());
		#end
	}

	inline function loadBG()
	{
		var lastLoaded = Paths.currentLevel;
		Paths.currentLevel = assetFolder;

		/////////////
		// bg data //
		/////////////
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);

		dadPosition.set(100, 100);
		bfPosition.set(770, 100);
		/////////////

		Paths.currentLevel = lastLoaded;
	}


	inline function updatePointerPos(?snap:Bool = true)
	{
		var offX:Float = 0;
		var offY:Float = 0;
		if(!character.isPlayer)
		{
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		else
		{
			offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if(snap)
		{
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width/2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height/2;
		}
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
		healthIcon.changeIcon(character.healthIcon, false);
		updatePresence();
	}

	inline function updatePresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	inline function reloadAnimList()
	{
		anims = character.animationsArray;
		if(anims.length > 0) character.playAnim(anims[0].anim, true);
		curAnim = 0;

		for (text in animsTxtGroup)
			text.kill();

		var daLoop = 0;
		for (anim in anims)
		{
			var text:FlxText = animsTxtGroup.recycle(FlxText);
			text.x = 10;
			text.y = 32 + (20 * daLoop);
			text.fieldWidth = 400;
			text.fieldHeight = 20;
			text.text = anim.anim + ": " + anim.offsets;
			text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);

			daLoop++;
		}
		updateTextColors();
		if(animationDropDown != null) reloadAnimationDropDown();
	}

	inline function updateTextColors()
	{
		var daLoop = 0;
		for (text in animsTxtGroup)
		{
			text.color = FlxColor.WHITE;
			if(daLoop == curAnim) text.color = FlxColor.LIME;
			daLoop++;
		}
	}

	inline function updateCharacterPositions()
	{
		if((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char))) character.setPosition(dadPosition.x, dadPosition.y);
		else character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-dead')) ||
				name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if(!character.isAnimateAtlas)
		{
			if(indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		else
		{
			if(indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}

		if(!character.animOffsets.exists(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];
	function reloadCharacterDropDown() {
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt', Paths.getSharedPath());
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if(!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if(characterList.length < 1) characterList.push('');
		charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = _char;
	}

	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in anims) animList.push(anim.anim);
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animList, true));
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
		unsavedChanges = false;
		if(unsavedTxt != null) unsavedTxt.visible = false;
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function buildCharacterJson():String
	{
		var json:Dynamic = {
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position":	character.positionArray,
			"camera_position": character.cameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"vocals_file": character.vocalsFile,
			"_editor_isPlayer": character.isPlayer
		};
		return haxe.Json.stringify(json, "\t");
	}

	function saveCharacter() {
		if(_file != null) return;

		var data:String = buildCharacterJson();

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}
	}
}