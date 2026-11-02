package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.geom.Vector3D;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.modifiers.*;
import flare.utils.*;
import flare.system.*;

/**
 * Loads external animation files and appends them to a base character model.
 * Flare3D Example 24: Append Animations.
 * 
 * Press '1' to play anim1 (running).
 * Press '2' to play anim2 (action/special).
 * 
 * @author Ariel Nehmad
 */
class Test24_AppendAnimations extends Sprite 
{
	private var scene:Scene3D;
	private var char:Pivot3D;
	private var anim1:Pivot3D;
	private var anim2:Pivot3D;

	public var currentAnim:String = "anim1";
	public var character(get, never):Pivot3D;
	private inline function get_character():Pivot3D return char;

	public function new() 
	{
		super();
		scene = new Viewer3D(this);

		var viewer = Std.isOfType(scene, Viewer3D) ? cast(scene, Viewer3D) : null;
		if (viewer != null) {
			viewer.setTarget(0, 0.9, 0);
			scene.camera.setPosition(-0.365, 1.21, -2.45);
			scene.camera.lookAt(0, 0.9, 0);
			viewer.syncOrbitFromCamera();
		}

		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		
		// load and add the main character without animations.
		char = scene.addChildFromFile( "anim_base.f3d" );
		
		// there is no needed to add the animations to the scene, so
		// we just load them through the scene library that manages all resources 
		// loading process.
		anim1 = new Flare3DLoader( "anim_base1.f3d" );
		anim2 = new Flare3DLoader( "anim_base2.f3d" );
		scene.library.push(cast(anim1, Flare3DLoader));
		scene.library.push(cast(anim2, Flare3DLoader));

		// Keyboard shortcut interaction
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(e:Event):Void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null) {
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
	}

	private function onKeyDown(e:KeyboardEvent):Void 
	{
		if (e.keyCode == 49 || e.keyCode == Keyboard.NUMBER_1 || e.keyCode == Keyboard.NUMPAD_1) {
			playAnim1();
		} else if (e.keyCode == 50 || e.keyCode == Keyboard.NUMBER_2 || e.keyCode == Keyboard.NUMPAD_2) {
			playAnim2();
		}
	}

	public function playAnim1(blendFrames:Float = 15):Void 
	{
		if (char != null) {
			char.gotoAndPlay("anim1", blendFrames);
			currentAnim = "anim1";
			DebugLog.log("[Test24] Switched to anim1: " + char.labels["anim1"]);
			trace("Playing anim1: " + char.labels["anim1"]);
		}
	}

	public function playAnim2(blendFrames:Float = 15):Void 
	{
		if (char != null) {
			char.gotoAndPlay("anim2", blendFrames);
			currentAnim = "anim2";
			DebugLog.log("[Test24] Switched to anim2: " + char.labels["anim2"]);
			trace("Playing anim2: " + char.labels["anim2"]);
		}
	}
	
	private function completeEvent(e:Event):Void 
	{
		DebugLog.log("[Test24] completeEvent fired! Appending animations...");
		// adds the loaded animations to the char pivot.
		Pivot3DUtils.appendAnimation( char, anim1, "anim1" );
		Pivot3DUtils.appendAnimation( char, anim2, "anim2" );
		char.gotoAndPlay( "anim1" );
		currentAnim = "anim1";
		
		var viewer = Std.isOfType(scene, Viewer3D) ? cast(scene, Viewer3D) : null;
		if (viewer != null) {
			viewer.setTarget(0, 0.9, 0);
			scene.camera.setPosition(-0.365, 1.21, -2.45);
			scene.camera.lookAt(0, 0.9, 0);
			viewer.syncOrbitFromCamera();
		}
		
		DebugLog.log("[Test24] anim1 label: " + char.labels["anim1"]);
		DebugLog.log("[Test24] anim2 label: " + char.labels["anim2"]);
		trace( char.labels["anim1"] );
		trace( char.labels["anim2"] );
	}
}
