package states.stages;

class SceneryStage extends BaseStage
{
	override function create()
	{
		var bg:BGSprite = new BGSprite('sceneryassets/stage', 0, 0, 1, 1);
		bg.scale.set(1.5, 1.5);
		bg.updateHitbox();
		add(bg);
	}
}
