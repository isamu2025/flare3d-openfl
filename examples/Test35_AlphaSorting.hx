package examples;

import openfl.display.Sprite;
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

import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.system.*;
import flare.utils.*;
import openfl.display.*;
import openfl.events.*;
import openfl.text.*;

/**
 * Alpha sorting test. Press SPACE to change the sort mode.
 * 
 * @author Ariel Nehmad
 */
class Test35_AlphaSorting extends Sprite
{
	private var scene:Viewer3D;
	private var mode:Int;
	private var info:TextField;
	
	public function new() 
	{
		super();
		info = new TextField();
		info.textColor = 0xffffff;
		info.autoSize = "left";
		info.background = true;
		info.backgroundColor = 0x0;
		info.y = 0;
		addChild( info );
		
		scene = new Viewer3D(this);
		scene.camera = new Camera3D();
		scene.camera.setPosition( 0, 0, -200 );
		scene.autoResize = true;
		scene.setLayerSortMode(10, Scene3D.SORT_NONE);
		
		var mat:Shader3D = new Shader3D( "", [new ColorFilter(0xff0000, 0.2)]);
		mat.transparent = true;
		var cube:Cube = new Cube( "cube", 10, 10, 10, 1, mat );
		
		for (i in 0...300)
		{
			var d:Mesh3D = cast(cube.clone(), Mesh3D);
			d.x = Math.random() * 100 - 50;
			d.y = Math.random() * 100 - 50;
			d.z = Math.random() * 100 - 50;
			d.setLayer( 10 );
			scene.addChild( d );
		}
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		if ( Input3D.keyHit( Input3D.SPACE ) )
		{
			if ( ++mode > 2 ) mode = 0;
			
			switch (mode)
			{
				case 0: scene.setLayerSortMode(10, Scene3D.SORT_NONE);
				case 1: scene.setLayerSortMode(10, Scene3D.SORT_FRONT_TO_BACK);
				case 2: scene.setLayerSortMode(10, Scene3D.SORT_BACK_TO_FRONT);
			}
		}
		
		if ( !Input3D.mouseDown ) scene.camera.rotateY( 1, false, Vector3DUtils.ZERO );
		
		if (mode == 0) info.text = "Sort mode: NONE";
		else if (mode == 1) info.text = "Sort mode: SORT_FRONT_TO_BACK";
		else if (mode == 2) info.text = "Sort mode: SORT_BACK_TO_FRONT";
	}
}
