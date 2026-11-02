package flare.utils;

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
	import flare.materials.*;
	import flare.system.*;
	import openfl.display.*;
	import openfl.display3D.*;
	import openfl.geom.*;
	
	/**
	 * @author Jason Huang
	 */
	class PlanarReflection
	{
		private var _camera:Camera3D;
		private var _camProj:Matrix3D;
		private var _camPlane:Vector3D;
		private var _planeVec:Vector3D;
		private var _matrix:Matrix3D;
		private var _vector:Vector3D;
		private var _raw:openfl.Vector<Float>;
		private var _out:Vector3D;
		private var _inv:Matrix3D;
		
		public var accuracy:Float;
		
		public function new()
		{
			_camera = new Camera3D();
			_matrix = new Matrix3D();
			_vector = new Vector3D();
			_planeVec = new Vector3D();
			_camProj = new Matrix3D();
			_raw = new openfl.Vector<Float>( 16, true );
			_out = new Vector3D();
			_inv = new Matrix3D();
		}
		
		public function update( worldMatrix:Matrix3D ):Void
		{
			_matrix.copyFrom( worldMatrix );
			_matrix.invert();
			_matrix.copyRowTo( 1, _vector );
			_planeVec.x = -_vector.x;
			_planeVec.y = -_vector.y;
			_planeVec.z = -_vector.z;
			_planeVec.w = -_vector.w + 0.1;
		}
		
		public function setupCamera( camera:Camera3D ):Void
		{
			updateCamera( camera );
			Device3D.camera = _camera;
			Device3D.view.copyFrom( _camera.view );
			Device3D.viewProj.copyFrom( Device3D.view );
			Device3D.viewProj.append( _camProj );
			Device3D.currentMesh = null;
		}
		
		private function updateCamera( camera:Camera3D ):Void
		{
			reflection( _planeVec, _matrix );
			_matrix.prepend( camera.world );
			_camera.transform = _matrix;
			_camera.updateTransforms( true );
			if (_camera.view == null) _camera.view = new Matrix3D();
			_camera.view.copyFrom( _camera.world );
			_camera.view.invert();
			_camPlane = transformPlane( _planeVec, _matrix );
			_camera.fieldOfView = camera.fieldOfView;
			_camera.viewPort = camera.viewPort;
			_camera.updateProjection();
			updateProj();
		}
		
		private function updateProj():Void
		{
			_camProj.copyFrom( _camera.projection );
			
			var x:Float = _camPlane.x;
			var y:Float = _camPlane.y;
			var z:Float = _camPlane.z;
			var w:Float = -_camPlane.w;
			var cornerX:Float = x >= 0 ? 1 : -1;
			var cornerY:Float = y >= 0 ? 1 : -1;
			
			_out.x = cornerX;
			_out.y = cornerY;
			_out.z = 1;
			_out.w = 1;
			
			var newMatrix:Matrix3D = _matrix.clone();
			newMatrix.invert();
			
			var projCorner:Vector3D = newMatrix.transformVector( _out );
			_camProj.copyRowTo( 3, _out );
			
			var sumCorner:Float = ( projCorner.x * _out.x + projCorner.y * _out.y + projCorner.z * _out.z + projCorner.w * _out.w ) / ( x * projCorner.x + y * projCorner.y + z * projCorner.z + w * projCorner.w );
			sumCorner *= accuracy;
			sumCorner = sumCorner > 0 ? -sumCorner : sumCorner;
			
			_out.x = x * sumCorner;
			_out.y = y * sumCorner;
			_out.z = z * sumCorner;
			_out.w = w * sumCorner;
			
			_camProj.copyRowFrom( 2, _out );
		}
		
		private function transformPlane( vec:Vector3D, transform:Matrix3D ):Vector3D
		{
			var x:Float = vec.x;
			var y:Float = vec.y;
			var z:Float = vec.z;
			var w:Float = vec.w;
			
			transform.copyRawDataTo( _raw );
			_out.x = x * _raw[ 0 ] + y * _raw[ 1 ] + z * _raw[ 2 ] + w * _raw[ 3 ]; 
			_out.y = x * _raw[ 4 ] + y * _raw[ 5 ] + z * _raw[ 6 ] + w * _raw[ 7 ];
			_out.z = x * _raw[ 8 ] + y * _raw[ 9 ] + z * _raw[ 10 ] + w * _raw[ 11 ];
			_out.w = -( x * _raw[ 12 ] + y * _raw[ 13 ] + z * _raw[ 14 ] + w * _raw[ 15 ] );
			_out.normalize();
			
			return _out;
		}
		
		public function isBehind( camera:Camera3D ):Bool
		{
			var worldPos:Vector3D = camera.world.position;
			
			return worldPos.x * _planeVec.x + worldPos.y * _planeVec.y + worldPos.z * _planeVec.z + _planeVec.w >= 0;
		}
		
		private function reflection( reflectVec:Vector3D, out:Matrix3D = null ):Matrix3D
		{
			if (out == null) out = new Matrix3D();
			var right:Float = reflectVec.x;
			var up:Float = reflectVec.y;
			var dir:Float = reflectVec.z;
			var pos:Float = reflectVec.w;
			var refR:Float = -2 * up * right;
			var refD:Float = -2 * right * dir;
			var refU:Float = -2 * dir * up;
			
			_raw[ 0 ] = 1 - ( 2 * right * right );
			_raw[ 5 ] = 1 - ( 2 * up * up );
			_raw[ 10 ] = 1 - ( 2 * dir * dir );
			
			_raw[ 1 ] = _raw[ 4 ] = refR;
			_raw[ 2 ] = _raw[ 8 ] = refD;
			_raw[ 6 ] = _raw[ 9 ] = refU;
			
			_raw[ 12 ] = -2 * right * pos;
			_raw[ 13 ] = ( -2 * up ) * pos;
			_raw[ 14 ] = -2 * dir * pos;
			
			_raw[ 3 ] = _raw[ 7 ] = _raw[ 15 ] = 0;
			_raw[ 15 ] = 1;
			
			out.copyRawDataFrom( _raw );
			
			return ( out );
		}
	}
