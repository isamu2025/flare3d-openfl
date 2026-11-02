package examples.starling_integration.example3;

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
	import flare.flsl.FLSLMaterial;
	import openfl.display.*;
	import openfl.display3D.*;
	import openfl.events.*;
	import openfl.geom.Point;
	import starling.core.*;
	
	// [SWF metadata]
	/**
	 * Flare3D + Starling integration.
	 * 
	 * @author Ariel Nehmad
	 */
	class StarlingTest extends Sprite 
	{
		// [Embed metadata]
		private var Model:Class<Dynamic>;
		// [Embed metadata]
		private var Dream:Class<Dynamic>;
		
		private var scene:Scene3D;
		private var model:Pivot3D;
		private var starlingTop:Starling;
		private var target:Texture3D;
		private var dream:FLSLMaterial;
		
		public function new() 
		{
			super();
			scene = new Viewer3D( this );
			scene.autoResize = true;
			scene.clearColor.setTo( 1, 1, 1 );
			scene.addEventListener( Event.CONTEXT3D_CREATE, contextCreateEvent );
			scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
			
			target = new Texture3D( new Point( 1024, 512 ) );
			target.mipMode = Texture3D.MIP_NONE;
			target.upload( scene );
			
			FLSLMaterial.semantics["TARGET_TEXTURE"].value = target;
			
			dream = new FLSLMaterial( "dream", Type.createInstance(Dream, []));
			dream.upload( scene );
			
			model = scene.addChildFromFile( Type.createInstance(Model, []));
		}
		
		private function contextCreateEvent(e:Event):Void 
		{
			starlingTop = new Starling( StarlingTop, stage, null, stage.stage3Ds[ scene.stageIndex ] );
			starlingTop.start();
		}
		
		private function renderEvent(e:Event):Void 
		{
			// prevents the 3d scene to render.
			// we'll handle the render by our own.
			e.preventDefault();
			
			scene.context.setRenderToTexture( target.texture, true );
			scene.context.clear();
			scene.render();
			
			scene.context.setRenderToBackBuffer();
			scene.drawQuadTexture( null, 0, 0, scene.viewPort.width, scene.viewPort.height, dream );
			scene.endFrame();
			
			// draw starling ui.
			starlingTop.nextFrame();
		}
	}
