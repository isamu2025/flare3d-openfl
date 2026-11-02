package examples.physics;

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
	import flare.loaders.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.system.*;
	import openfl.display.*;
	import openfl.events.*;
	import openfl.filters.*;
	import openfl.media.*;
	import openfl.text.*;
	import openfl.utils.*;
	
	// [SWF metadata]
	/**
	 * @author Ariel Nehmad
	 */
	class Test06_FlappyFlare extends Sprite 
	{
		// [Embed metadata]
		private var Model:Class<Dynamic>;
		// [Embed metadata]
		private var SndTrigger:Class<Dynamic>;
		// [Embed metadata]
		private var SndJump:Class<Dynamic>;
		// [Embed metadata]
		private var SndLose:Class<Dynamic>;
		
		private var sndTrigger:Sound = Type.createInstance(SndTrigger, []);
		private var sndJump:Sound = Type.createInstance(SndJump, []);
		private var sndLose:Sound = Type.createInstance(SndLose, []);
		
		private var scene:Scene3D;
		private var floor:Pivot3D;
		private var bird:Pivot3D;
		private var state:String;
		private var model:Flare3DLoader;
		private var sky:TextureMapFilter;
		private var obstacles:Array<Pivot3D>;
		private var trigger:Pivot3D;
		private var text:TextField;
		private var score:Int;
		
		public function new() 
		{
			super();
			scene = new Scene3D( this );
			scene.autoResize = true;
			scene.physics.gravity.setTo( 0, -8, 0 );
			
			text = new TextField();
			text.selectable = false;
			text.autoSize = TextFieldAutoSize.CENTER;
			text.defaultTextFormat = new TextFormat( "arial", 50, 0xffffff, true );
			text.x = stage.stageWidth * 0.5;
			text.y = 30;
			text.filters = [new GlowFilter( 0x0, 1, 8, 8, 2, 1, false, false )];
			addChild( text );
			
			resetGame();
		}
		
		public function resetGame():Void 
		{
			scene.pause();
			scene.removeEventListener( Scene3D.UPDATE_EVENT, updateEvent );
			
			if (model != null) 
				model.dispose();
			
			model = new Flare3DLoader( Type.createInstance(Model, []));
			model.addEventListener( Event.COMPLETE, completeEvent );
			model.load();
			model.parent = scene;
			
			score = 0;
			state = "wait";
			text.text = score.toString();
		}
		
		private function completeEvent(e:Event):Void 
		{
			obstacles = new Array<Pivot3D>();
			
			var skyMat:Shader3D = cast(model.getMaterialByName( "sky" ), Shader3D);
			sky = skyMat.getFilterByClass( TextureMapFilter );
			
			scene.forEach( setupScene );
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
			scene.resume();
		}
		
		private function setupScene( p:Pivot3D ):Void 
		{
			// look for obstacles, trigger zone, floor, camera, and the bird.
			if ( p.name == "obstacle" ) {
				p.y = Math.random() * 170 - 30;
				obstacles.push( p );
			} else if ( p.name == "trigger" ) {
				trigger = p;
			} else if ( p.name == "floor" ) {
				floor = p;
			} else if ( p.name == "camera" ) {
				scene.camera = cast(p, Camera3D); 
			} else if ( p.name == "bird" ) {
				bird = p;
				bird.gotoAndPlay( "fly" );
			}
		}
		
		private function updateEvent(e:Event):Void 
		{
			if ( state == "wait" ) {
				bird.y = Math.cos( getTimer() / 100 ) * 15;
				if ( Input3D.mouseHit ) 
					state = "fly";
			}
			
			if ( state == "fly" ) {
				
				// moves the trigger zone.
				trigger.z -= 2.5;
				
				// animates the floor.
				floor.z -= 2.5;
				if ( floor.z < -1000 ) floor.z += 1000;
				
				// animates the cylinders.
				for (p in obstacles ) {
					p.z -= 2.5;
					if ( p.z < -400 ) {
						p.z += 200 * obstacles.length;
						p.y = Math.random() * 170 - 30;
					}
				}
				
				// when mouse is pressed, apply a new force.
				if ( Input3D.mouseHit ) {
					bird.collider.resetVelocities();
					bird.collider.applyImpulse( 0, 140, 0 );
					bird.x = 0;
					sndJump.play();
				}
				
				// animate the sky.
				sky.offsetX += 0.005;
			}
			
			// update physics.
			if ( state != "wait" )
				scene.physics.step();
			
			// when colliding with something.
			if ( state == "fly" && bird.collider.numContacts ) {
				if (trigger.collider.numContacts > 0) {
					trigger.z += 200;
					score++;
					text.text = score.toString();
					sndTrigger.play();
				} else {
					state = "die";
					bird.gotoAndPlay( "die", 0, Pivot3D.ANIMATION_STOP_MODE );
					bird.collider.applyTorque( 200, 0, -200 );
					sndLose.play();
					setTimeout( resetGame, 3000 );
				}
			}
		}
	}
