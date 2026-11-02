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
	import flare.events.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import openfl.display.Sprite;
	import openfl.display3D.*;
	import openfl.events.*;
	
	/**
	 * This example creates a stroke fake or border around the 3d models.
	 * Is a very old trick, but it is very fast and easy to implement.
	 * 
	 * @author Ariel Nehmad
	 */
	class Test28_Stroke extends Sprite 
	{
		private var scene:Scene3D;
		private var stroke:Mesh3D;
		private var model:Mesh3D;
		private var clone1:Mesh3D;
		private var clone2:Mesh3D;
		private var _autoTest:Bool = false;
		private var _autoTimer:Float = 0;
		private var _autoStep:Int = 0;
		
		public function new() 
		{
			super();
			#if sys
			try {
				var args = Sys.args();
				if (args != null && (args.indexOf("--test-auto") != -1 || args.indexOf("--auto") != -1)) {
					_autoTest = true;
					flare.system.DebugLog.log("[Test28] Auto test mode enabled via CLI.");
				}
			} catch (e:Dynamic) {}
			#end
			scene = new Viewer3D(this);
			scene.camera = new Camera3D();
			scene.camera.setPosition( 0, 0, -200 );
			scene.camera.lookAt( 0, 0, 0 );
			var viewer = Std.isOfType(scene, Viewer3D) ? cast(scene, Viewer3D) : null;
			if (viewer != null) viewer.syncOrbitFromCamera();
			
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			scene.addChildFromFile( "elsa.zf3d" );			
		}
		
		private function completeEvent(e:Event):Void 
		{
			// gets the loaded 'elsa' model.
			var model:Mesh3D = cast(scene.getChildByName( "elsa" ), Mesh3D);
			
			var clone1:Mesh3D = cast(model.clone(), Mesh3D);
			clone1.x = -80;
			
			var clone2:Mesh3D = cast(model.clone(), Mesh3D);
			clone2.x = 80;
			
			scene.addChild( clone1 );
			scene.addChild( clone2 );
			
			var strokeMaterial:Shader3D = new Shader3D( "stroke", [new ColorFilter( 0xff0000 )], false );
			// culiing the front faces will cause that only the back faces will be visibles.
			strokeMaterial.cullFace = Context3DTriangleFace.FRONT;
			
			// scale a bit the model in order to get the edges.
			stroke = cast(model.clone(), Mesh3D);
			stroke.setScale( 1.05, 1.05, 1.05 );
			stroke.setMaterial( strokeMaterial );
			stroke.parent = scene;
			
			this.model = model;
			this.clone1 = clone1;
			this.clone2 = clone2;

			model.addEventListener( MouseEvent3D.MOUSE_OVER, mouseOverEvent );
			clone1.addEventListener( MouseEvent3D.MOUSE_OVER, mouseOverEvent );
			clone2.addEventListener( MouseEvent3D.MOUSE_OVER, mouseOverEvent );

			var st = (stage != null) ? stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
			if (st != null) {
				st.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, onKeyDown);
			}

			if (_autoTest) {
				addEventListener(openfl.events.Event.ENTER_FRAME, onAutoTestUpdate);
			}
		}

		private function onKeyDown(e:openfl.events.KeyboardEvent):Void
		{
			var st = (stage != null) ? stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
			if (st == null) return;
			if (e.keyCode == 49 || e.keyCode == 97 || e.keyCode == 37) { // 1 or Left
				st.dispatchEvent(new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_MOVE, true, false, 244, 225));
			} else if (e.keyCode == 50 || e.keyCode == 98 || e.keyCode == 40) { // 2 or Down
				st.dispatchEvent(new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_MOVE, true, false, 400, 225));
			} else if (e.keyCode == 51 || e.keyCode == 99 || e.keyCode == 39) { // 3 or Right
				st.dispatchEvent(new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_MOVE, true, false, 556, 225));
			}
		}

		private function onAutoTestUpdate(e:openfl.events.Event):Void
		{
			_autoTimer += 1.0 / 60.0;
			if (_autoTimer >= 1.5) {
				_autoTimer = 0;
				_autoStep = (_autoStep + 1) % 3;
				var targetX:Float = 400.0;
				var targetY:Float = 225.0;
				if (_autoStep == 1) {
					targetX = 244.0; // Left model
				} else if (_autoStep == 2) {
					targetX = 556.0; // Right model
				} else {
					targetX = 400.0; // Middle model
				}
				var st = (stage != null) ? stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
				if (st != null) {
					st.dispatchEvent(new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_MOVE, true, false, targetX, targetY));
				}
			}
		}
		
		private function mouseOverEvent(e:MouseEvent3D):Void 
		{
			var target:Pivot3D = (e.info != null && e.info.mesh != null) ? e.info.mesh : (Std.isOfType(e.target, Pivot3D) ? cast e.target : null);
			flare.system.DebugLog.log("[Test28] mouseOverEvent! target=" + (target != null ? (target.name + " x=" + target.x) : "null"));
			
			if (target != null && stroke != null) {
				stroke.setPosition( target.x, target.y, target.z );
			}
		}
	}
