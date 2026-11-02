package examples;

import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.display.StageAlign;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Lib;
import openfl.Lib.getTimer;
import openfl.net.URLRequest;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.collisions.*;
import flare.loaders.*;
import flare.system.*;
import flare.events.*;
import flare.physics.*;
import flare.physics.colliders.*;
import flare.modifiers.*;
import flare.flsl.*;
import examples.components.*;

/**
 * How to attach a bone controller to an object.
 * 
 * @author Ariel Nehmad
 */
class Test23_BoneController extends Sprite 
{
	private var scene:Scene3D;
	private var model:Pivot3D;
	
	public function new() 
	{
		super();
		// stage configuration.
		if (stage != null) {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
		}
		
		scene = new Viewer3D( this );
		scene.autoResize = true;
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		
		model = scene.addChildFromFile( "player.f3d" );
	}
	
	private function completeEvent(e:Event):Void 
	{
		// this could besomething strange, but it has the reason to be ;)
		// we can not parent an object directly to a bone because the bones are not in the scene.
		// in fact, the skeletons are just an instance of a virtual skeleton.
		// it means, you could have a bunch of skinned meshes instances, and all will share the same skeleton.
		// so, a good way to attach an object to a bone could be a bone controller component like the followin code.
		
		var skinnedMesh:Mesh3D = cast(model.getChildByName( "PlayerFutbol" ), Mesh3D);
		if (skinnedMesh == null && Std.isOfType(model, Mesh3D)) {
			skinnedMesh = cast model;
		}
		
		var hand1:Cube = new Cube( "hand1", 0.1, 0.1, 0.1 );
		var hand2:Cube = new Cube( "hand2", 0.1, 0.1, 0.1 );
		var hat:Cube = new Cube( "hat", 0.4, 0.04, 0.4 );
		
		// rotates the hat, because the bone head has different orientation.
		hat.rotateZ(90);
		
		hand1.addComponent( new BoneController( skinnedMesh, "BipPlayerFutbol R Hand" ) );
		hand2.addComponent( new BoneController( skinnedMesh, "BipPlayerFutbol L Hand" ) );
		hat.addComponent( new BoneController( skinnedMesh, "BipPlayerFutbol HeadNub" ) );
		
		scene.addChild( hand1 );
		scene.addChild( hand2 );
		scene.addChild( hat );

		if (model != null) {
			model.play(true);
		}
	}
}
