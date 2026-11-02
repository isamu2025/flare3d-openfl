package flare.primitives;

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
	import openfl.geom.*;
	
	/**
	 * @author Ariel Nehmad
	 */
	class PieChart3D extends Mesh3D
	{
		public function new( from:Float, to:Float, radius:Float = 20, height:Float = 5, material:Material3D = null )
		{
			super();
			if (material == null)
				material = new Shader3D( name + "_material" );
			
			var segments:Int = 24;
			var steps:Int = 12;
			
			var indices:openfl.Vector<UInt> = new openfl.Vector<UInt>();
			var positions:openfl.Vector<Float> = new openfl.Vector<Float>();
			var uvs:openfl.Vector<Float> = new openfl.Vector<Float>();
			var normals:openfl.Vector<Float> = new openfl.Vector<Float>();
			var vertex:openfl.Vector<Float> = new openfl.Vector<Float>();
			var normal:openfl.Vector<Float> = new openfl.Vector<Float>();
			var matrix:Matrix3D = new Matrix3D();
			var i:Int;
			var j:Int;
			
			from = from * 360 / 100;
			to = to * 360 / 100;
			
			{ vertex.push(0); vertex.push(height); vertex.push(0); };
			{ vertex.push(radius); vertex.push(height); vertex.push(0); };
			{ vertex.push(radius); vertex.push(height); vertex.push(0); };
			{ vertex.push(radius); vertex.push(0); vertex.push(0); };
			{ vertex.push(radius); vertex.push(0); vertex.push(0); };
			{ vertex.push(0); vertex.push(0); vertex.push(0); };
			{ normal.push(0); normal.push(1); normal.push(0); };
			{ normal.push(0); normal.push(1); normal.push(0); };
			{ normal.push(1); normal.push(0); normal.push(0); };
			{ normal.push(1); normal.push(0); normal.push(0); };
			{ normal.push(0); normal.push(-1); normal.push(0); };
			{ normal.push(0); normal.push(-1); normal.push(0); };
			
			var length:Int = Std.int(vertex.length / 3);
			
			// project vertex positions and normals.
			var out:openfl.Vector<Float> = new openfl.Vector<Float>();
			matrix.identity();
			matrix.appendRotation( from, Vector3D.Y_AXIS );
			for (i in 0...segments + 1) {
				matrix.transformVectors( vertex, out );
				positions = positions.concat( out );
				matrix.transformVectors( normal, out );
				normals = normals.concat( out );
				matrix.appendRotation( (to-from) / segments, Vector3D.Y_AXIS );
			}
			
			// uvs.
			for (i in 0...segments + 1)
				for (j in 0...length)
					{ uvs.push(i / segments); uvs.push(j / (length - 1)); };
			
			// build indices.
			for (i in 0...segments) {
				for (j in 0...length - 1) {
					var id0:Int = ((i + 1) * length) + j;
					var id1:Int = (i * length) + j;
					var id2:Int = ((i + 1) * length) + j + 1;
					var id3:Int = (i * length) + j + 1;
					{ indices.push(id1); indices.push(id2); indices.push(id0); };
					{ indices.push(id2); indices.push(id1); indices.push(id3); };
				}
			}
			
			var len:Int = Std.int(positions.length / 3);
			
			out = new openfl.Vector<Float>();
			uvs = uvs.concat( openfl.Vector.ofArray([ 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0 ]) );
			vertex = openfl.Vector.ofArray([0.0, height, 0.0, radius, height, 0.0, radius, 0.0, 0.0, 0.0, 0.0, 0.0]);
			
			normal = openfl.Vector.ofArray([ 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0 ]);
			matrix.identity();
			matrix.appendRotation( from, Vector3D.Y_AXIS );
			matrix.transformVectors( vertex, out );
			positions = positions.concat( out );
			matrix.transformVectors( normal, out );
			normals = normals.concat( out );
			{ indices.push(len + 2); indices.push(len + 1); indices.push(len); };
			{ indices.push(len + 3); indices.push(len + 2); indices.push(len); };
			
			normal = openfl.Vector.ofArray([ 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0 ]);
			matrix.appendRotation( to - from, Vector3D.Y_AXIS );
			matrix.transformVectors( vertex, out );
			positions = positions.concat( out );
			matrix.transformVectors( normal, out );
			normals = normals.concat( out );
			{ indices.push(len + 4); indices.push(len + 5); indices.push(len + 6); };
			{ indices.push(len + 4); indices.push(len + 6); indices.push(len + 7); };
			
			var surf:Surface3D = new Surface3D( "pieChart" );
			surf.vertexVector = positions;
			surf.indexVector = indices;
			surf.addVertexData( Surface3D.POSITION );
			surf.addVertexData( Surface3D.UV0, 2, uvs );
			surf.addVertexData( Surface3D.NORMAL, 3, normals );
			surf.material = material;
			surfaces.push( surf );
		}		
	}
