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
import flare.primitives.*;
import openfl.display.*;
import openfl.events.*;

/**
 * SkyBox example.
 * 
 * @author Ariel Nehmad
 */
class Test32_SkyBox extends Sprite 
{
	private var scene:Scene3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this );
		scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		
		// method 1 loads the complete skybox from a single image.
		//var sky:SkyBox = new SkyBox( "skybox1.png", SkyBox.HORIZONTAL_CROSS, scene );
		
		// method 2 loads the skybox from a folder.
		//var sky:SkyBox = new SkyBox( "skybox_folder", SkyBox.FOLDER_JPG, scene );
		
		// method 3 loads the skybox from a BitmapData array.
		var front = "skybox_folder/front.jpg";
		var back = "skybox_folder/back.jpg";
		var right = "skybox_folder/right.jpg";
		var left = "skybox_folder/left.jpg";
		var top = "skybox_folder/top.jpg";
		var bottom = "skybox_folder/bottom.jpg";
		var sky:SkyBox = new SkyBox( [front, back, right, left, top, bottom], SkyBox.BITMAP_DATA_ARRAY, scene );
		
		scene.addChild( sky );
	}
	
	private function progressEvent(e:Event):Void 
	{
		trace( scene.loadProgress );
	}
	
	private function completeEvent(e:Event):Void 
	{
		trace( "completed" );
	}
	
}
