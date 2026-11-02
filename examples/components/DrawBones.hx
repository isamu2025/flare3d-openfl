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
import flare.system.Device3D;
import openfl.display3D.*;
import openfl.events.*;
import openfl.geom.*;

/**
 * Sample component.
 * Draw skinned bones as lines.
 * 
 * @author Ariel Nehmad.
 */
class DrawBones implements IComponent
{
	private var _target:Pivot3D;
	private var _mesh:Mesh3D;
	private var _skin:Array<SkinModifier>;
	private var _lines:Lines3D;
	private var _matrix:Matrix3D;
	private var _thickness:Float;
	private var _color:Int;
	
	public function new( color:Int = 0xff0000, thickness:Float = 1 )
	{
		_color = color;
		_thickness = thickness;
	}
	
	/* INTERFACE flare.components.IComponent */
	
	public function added( target:Pivot3D ):Bool
	{
		_target = target;
		
		// find down for the skinned mesh.
		target.forEach( function(p:Pivot3D) {
			if (Std.isOfType(p, Mesh3D)) findSkin(cast p);
		} );
		
		if (_skin != null) 
		{
			// initialize.
			_mesh.addEventListener( Pivot3D.EXIT_DRAW_EVENT, exitDrawEvent, false, 0, true );
			_matrix = new Matrix3D();
			_lines = new Lines3D();
			
			// succesfully added.
			return true;
		}
		else 
			throw "No skinned meshes found in " + target.name;
		
		return false;
	}
	
	public function removed():Bool
	{
		// free resources.
		if (_mesh != null) {
			_mesh.removeEventListener( Pivot3D.EXIT_DRAW_EVENT, exitDrawEvent );
		}
		_mesh = null;
		_skin = null;
		_lines = null;
		_matrix = null;
		_target = null;
		
		// succesfully removed.
		return true;
	}
	
	/* PRIVATE METHODS. */
	
	private function exitDrawEvent(e:Event):Void 
	{
		// setup line style.
		_lines.clear();
		_lines.lineStyle( _thickness, _color );
		
		// create lines.
		if (_skin != null) {
			for (s in _skin ) {
				if (s != null && s.bones != null) {
					for (b in s.bones ) drawBone( s.mesh, b );
				}
			}
		}
		
		// draw lines to screen. 
		var ctx = (_mesh != null && _mesh.scene != null) ? _mesh.scene.context : Device3D.context;
		if (ctx != null) {
			Device3D.ignoreStates = true;
			ctx.setDepthTest( false, Context3DCompareMode.ALWAYS );
			ctx.setCulling( Context3DTriangleFace.NONE );
			_lines.draw();
			ctx.setDepthTest( true, Context3DCompareMode.LESS_EQUAL );
			ctx.setCulling( Context3DTriangleFace.BACK );
			Device3D.ignoreStates = false;
		}
	}
	
	private function drawBone( mesh:Mesh3D, bone:Pivot3D ):Void
	{
		if ( bone == null || bone.children == null || bone.children.length == 0 || bone.parent == null ) return;
		
		// get the bone matrix transform. ( bone transform + mesh transform )
		_matrix.copyFrom( bone.world ); 
		if (mesh != null) {
			_matrix.append( mesh.world );
		}
		
		// result bone position.
		var from:Vector3D = _matrix.position;
		
		for (child in bone.children )
		{
			if (child == null) continue;
			_lines.moveTo( from.x, from.y, from.z );
			
			// get the child bone matrix transform. ( bone transform + mesh transform )
			_matrix.copyFrom( child.world ); 
			if (mesh != null) {
				_matrix.append( mesh.world );
			}
			
			// result bone children position.
			var to:Vector3D = _matrix.position;
			
			if (flare.system.Device3D.frame == 1) {
				flare.system.DebugLog.log("[DrawBones] bone=" + bone.name + " -> child=" + child.name + " from=(" + from.x + "," + from.y + "," + from.z + ") to=(" + to.x + "," + to.y + "," + to.z + ")");
			}
			
			// draw bone line.
			_lines.lineTo( to.x, to.y, to.z );
		}
	}
	
	/**
	 * Find a skinned mesh recursively down in the hierarchy.
	 */
	private function findSkin( mesh:Mesh3D ):Void
	{
		if ( mesh != null && Std.isOfType(mesh.modifier, SkinModifier) )
		{
			if (_skin == null) _skin = new Array<SkinModifier>();
			
			_mesh = mesh;
			
			_skin.push( cast mesh.modifier );
		}
	}
}
