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

import examples.components.*;
import flare.basic.*;
import flare.core.*;
import flare.system.*;
import openfl.display.*;
import openfl.events.*;

/**
 * Animations. Animations - Press 1 and 2 to switch between the animations.
 * 'P' to pause/resume, 'S' to stop the animation and '+' and '-' (from numpad) to change the animation speed.
 * 
 * @author Ariel Nehmad
 */
class Test06_Animations extends Sprite 
{
	private var scene:Scene3D;
	private var model:Pivot3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this );
		scene.autoResize = true;
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		
		model = scene.addChildFromFile( "player.f3d" );
	}
	
	private function completeEvent(e:Event):Void 
	{
		// this component search for a skinned mesh 
		// and draw the bones as lines.
		model.addComponent( new DrawBones() );
		
		// the labels can be defined in 3dmax, but also can be define manually by code.
		model.addLabel( new Label3D( "walk", 0, 41 ) );
		model.addLabel( new Label3D( "run", 50, 74 ) );
		model.gotoAndPlay( "walk" );
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		// P key: toggle Pause / Play (or resume if stopped)
		if ( Input3D.keyHit( Input3D.P ) ) {
			if ( model.isPlaying ) {
				flare.system.DebugLog.log("[Test06] Key P -> Pause");
				model.stop();
			} else {
				flare.system.DebugLog.log("[Test06] Key P -> Resume");
				model.play();
			}
		}
		
		// S key: stop the model animation.
		if ( Input3D.keyHit( Input3D.S ) ) {
			flare.system.DebugLog.log("[Test06] Key S -> Stop");
			model.stop();
		}
		
		// play certain animation label and blend between the animations.
		if ( Input3D.keyHit( Input3D.NUMBER_1 ) ) model.gotoAndPlay( "walk", 15 );
		if ( Input3D.keyHit( Input3D.NUMBER_2 ) ) model.gotoAndPlay( "run", 15 );
		if ( Input3D.keyHit( Input3D.NUMBER_3 ) ) model.gotoAndStop( 0, 10 );
		
		// increment and decrement frameSpeed.
		if ( Input3D.keyHit( Input3D.NUMPAD_ADD ) ) model.frameSpeed += 0.1;
		if ( Input3D.keyHit( Input3D.NUMPAD_SUBTRACT ) ) model.frameSpeed -= 0.1;
		
		// reset the frameSpeed.
		if ( Input3D.keyHit( Input3D.R ) ) model.frameSpeed = 1;
	}		
}
