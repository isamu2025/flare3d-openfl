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
import flare.system.*;
import openfl.display.*;
import openfl.events.*;
import openfl.geom.*;

/**
 * Change textures in realtime.
 * 
 * @author Ariel Nehmad
 */
class Test34_ChangeTextures extends Sprite 
{
	private var scene:Scene3D;
	private var preLoadedTexture0:Texture3D;
	private var preLoadedTexture1:Texture3D;
	private var preLoadedTexture2:Texture3D;
	private var customShader:Shader3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addChildFromFile( "elsa.zf3d" );
		
		preLoadedTexture0 = scene.addTextureFromFile( "terrain.png" );
		preLoadedTexture1 = scene.addTextureFromFile( "tree.png" );
		preLoadedTexture2 = scene.addTextureFromFile( "displacement.jpg" );
	}
	
	private function completeEvent(e:Event):Void 
	{
		customShader = cast(scene.getMaterialByName( "mElsa" ), Shader3D);
		
		if (Std.isOfType(scene, Viewer3D)) {
			var viewer:Viewer3D = cast scene;
			viewer.target.setTo(0, 0, 0);
			scene.camera.setPosition(0, 50, -200);
			scene.camera.lookAt(0, 0, 0);
			viewer.syncOrbitFromCamera();
		}
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		if (customShader == null || customShader.filters == null || customShader.filters.length == 0) return;
		var filter:Dynamic = customShader.filters[0];
		
		// in this case, the first filter on the customShader is a TextureFilter.
		
		// using this method, the texture will be loaded here, so the mesh will disappear until the new texture is loaded.
		if ( Input3D.keyHit( Input3D.NUMBER_1 ) ) filter.texture = new Texture3D( "metal.jpg" );
		if ( Input3D.keyHit( Input3D.NUMBER_2 ) ) filter.texture = new Texture3D( "r42.jpg" );
		if ( Input3D.keyHit( Input3D.NUMBER_3 ) ) filter.texture = new Texture3D( "reflections.jpg" );
		if ( Input3D.keyHit( Input3D.NUMBER_4 ) ) filter.texture = new Texture3D( "gorda.png" );
		
		// using preloaded textures, the result will be immediately.
		if ( Input3D.keyHit( Input3D.NUMBER_5 ) ) filter.texture = preLoadedTexture0;
		if ( Input3D.keyHit( Input3D.NUMBER_6 ) ) filter.texture = preLoadedTexture1;
		if ( Input3D.keyHit( Input3D.NUMBER_7 ) ) filter.texture = preLoadedTexture2;
	}
}
