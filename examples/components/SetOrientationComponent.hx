package examples.components;

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

import flare.core.*;
	import openfl.events.*;
	
	/**
	 * ...
	 * @author Ariel Nehmad
	 */
	class SetOrientationComponent implements IComponent 
	{
		private var _oritnetaion:Pivot3D;
		private var _target:Pivot3D;
		
		public function new( orientation:Pivot3D ) 
		{
			_oritnetaion = orientation;
		}
		
		/* INTERFACE flare.components.IComponent */
		
		public function added(target:Pivot3D):Bool 
		{
			_target = target;
			
			target.addEventListener( Pivot3D.ENTER_FRAME_EVENT, enterFrameEvent );
			
			return true;
		}
		
		public function removed():Bool 
		{
			_target.removeEventListener( Pivot3D.ENTER_FRAME_EVENT, enterFrameEvent );
			
			return true;
		}
		
		private function enterFrameEvent(e:Event):Void 
		{
			_target.setOrientation( _oritnetaion.getDir(), _oritnetaion.getUp(), 0.6 );
		}
	}
