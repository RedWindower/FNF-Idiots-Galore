package states.stages;

class Paperworld extends BaseStage
{
	override function create()
	{
		var bg:BGSprite = new BGSprite('paperworld/whitesky', 0, 0, 1, 1);
		bg.scale.set(1.5, 1.5);
		bg.updateHitbox();
		add(bg);

        var hil1:BGSprite = new BGSprite('paperworld/back_hill', 389.35, 88.35, 1, 1);
        hil1.scale.set(1.5, 1.5);
        hil1.updateHitbox();
        add(hil1);

        var hill2:BGSprite = new BGSprite('paperworld/front_hills', -43.45, 222.45, 1, 1);
        hill2.scale.set(1.5, 1.5);
        hill2.updateHitbox();
        add(hill2);

        var ground:BGSprite = new BGSprite('paperworld/grass', -89.7, 467.3, 1, 1);
        ground.scale.set(1.5, 1.5);
        ground.updateHitbox();
        add(ground);

        var cloud1:BGSprite = new BGSprite('paperworld/cloud', -351.15, -45.95, 1, 1);
        cloud1.scale.set(1.5, 1.5);
        cloud1.updateHitbox();
        add(cloud1);

        var cloud2:BGSprite = new BGSprite('paperworld/cloud', 864.1, -91.8, 1, 1);
        cloud2.scale.set(1.5, 1.5);
        cloud2.updateHitbox();
        add(cloud2);
	}
}
