package flare.basic;

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
	import openfl.display.*;
	import openfl.display3D.*;
	import openfl.events.*;
	import openfl.geom.*;
	
	/**
	 * This example shows how to create an stereo/anaglyph render extending the basic functionality of the Scene3D.
	 * 
	 * @author Ariel Nehmad.
	 */
	class AnaglyphScene3D extends Scene3D 
	{
		private var _transform:Matrix3D = new Matrix3D();
		private var _depthReference:Vector3D = new Vector3D();
		
		// The distance between the eyes.
		public var eyeDistance:Float = 5;
		
		// The distance of the reference point. This is the point where the eyes intersect.
		public var depthDistance:Float = 1000;
		
		public function new( container:Sprite ) 
		{
			super( container );
		}

		override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Texture3D = null ):Void 
		{
			if (camera == null) camera = scene.camera;
			
			// store the source camera position and rotation.
			_transform.copyFrom( camera.world );
			
			// the cameras should not be parallel, so we create a point of reference
			// where the cameras will look. that's the point where the two cameras intersect each other.
			// taking the depth distance, transforms from local camera to global point.
			_depthReference.setTo( 0, 0, depthDistance );
			
			camera.localToGlobal( _depthReference, _depthReference );
			
			// translates the camera and orientates the first camera.
			camera.translateX( -eyeDistance );
			camera.lookAt( _depthReference.x, _depthReference.y, _depthReference.z, camera.getUp(false) );
			
			// the first render.
			super.context.clear();
			super.context.setColorMask( true, false, false, false );
			super.render( camera );
			
			// transform the second camera.
			camera.world.copyFrom( _transform );
			camera.translateX( eyeDistance );
			camera.lookAt( _depthReference.x, _depthReference.y, _depthReference.z, camera.getUp(false) );
			
			//the second render.
			super.context.setColorMask( false, true, true, false );
			super.render( camera, true );
			
			// restore the original camera transform.
			camera.world.copyFrom( _transform );
		}
	}
