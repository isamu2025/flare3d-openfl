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
	import flare.modifiers.*;
	import openfl.events.*;
	import openfl.geom.*;
	
	/**
	 * @author Ariel Nehmad
	 */
	class BoneController2 implements IComponent 
	{
		private var _skin:SkinModifier;
		private var _mesh:Mesh3D;
		private var _bone:Pivot3D;
		private var _target:Pivot3D;
		private var _transform:Matrix3D;
		
		public function new( skinnedMesh:Mesh3D, boneName:String ) 
		{
			_mesh = skinnedMesh;
			_skin = cast(skinnedMesh.modifier, SkinModifier);
			
			if (_skin != null)
			{
				_bone = _skin.root.getChildByName( boneName );
				
				if (_bone != null) return;
			}
			
			throw skinnedMesh.name + " isn't a skinned mesh!";			
		}
		
		/* INTERFACE flare.core.IComponent */
		
		public function added( target:Pivot3D ):Bool 
		{
			_target = target;
			
			// this forces to the target to be drawn after the skinned mesh is transformed.
			_target.setLayer( _mesh.layer + 1 );
			
			_transform = target.world.clone();
			
			// we listening to the exit draw, because we need the bones already transformed.
			_target.addEventListener( Pivot3D.ENTER_DRAW_EVENT, enterDrawEvent, false, 0, true );
			_target.addEventListener( Pivot3D.EXIT_DRAW_EVENT, exitDrawEvent, false, 0, true );
			
			return true;
		}
		
		private function enterDrawEvent(e:Event):Void 
		{
			// get the bone matrix transform. ( bone transform + mesh transform )
			_transform.copyFrom( _target.world );
			_target.world.append( _bone.global ); 
			_target.world.append( _mesh.global );
			_target.updateTransforms(true);
		}
		
		private function exitDrawEvent(e:Event):Void 
		{
			// reset the transformations back.
			_target.world.copyFrom( _transform );
		}
		
		public function removed():Bool 
		{
			_target.removeEventListener( Pivot3D.ENTER_DRAW_EVENT, enterDrawEvent );
			_target.removeEventListener( Pivot3D.EXIT_DRAW_EVENT, exitDrawEvent );
			_target = null;
			_transform = null;
			
			return true;
		}
	}
