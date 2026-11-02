package examples.mesh;

import openfl.display.Shape;
import openfl.display.GradientType;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;

/**
 * High performance rendering of 10,000+ batched cubes rotating in 3D space.
 * 
 * @author Ariel Nehmad
 */
class CubesMesh extends Mesh3D
{
	private var _material:Shader3D;
	private var _needToUpload:Bool = false;
	
	public function new() 
	{
		super("cubes");
		
		var mtx:Matrix = new Matrix(); 
		mtx.createGradientBox( 256, 10 );
			
		var shp:Shape = new Shape();
		shp.graphics.beginGradientFill( GradientType.LINEAR, [0x00FCFF, 0xB48AFF, 0xF72335, 0xFFD73A ], null, null, mtx );
		shp.graphics.drawRect( 0, 0, 256, 10 );
			
		var bmp:BitmapData = new BitmapData( 256, 2, false, 0 );
		bmp.draw( shp );
			
		_material = new Shader3D( "grayScale", [ new TextureMapFilter( new Texture3D(bmp) ) ] );
		_material.twoSided = true;
		_material.build();
		this.material = _material;
		
		var surf0 = new Surface3D();
		surf0.material = _material;
		surf0.addVertexData( Surface3D.POSITION );
		surf0.addVertexData( Surface3D.UV0 );
		surf0.addVertexData( Surface3D.NORMAL );
		surfaces.push( surf0 );
		materials.push( _material );
	}
	
	public function addCube( x:Float, y:Float, z:Float, size:Float = 5, color:Float = 0 ):Void
	{
		// gets the last used surface.
		var surf:Surface3D = surfaces[surfaces.length - 1];
		
		// each surface cannot have more than 65000 vertices (16-bit IndexBuffer limit is 65535)
		if ( (surf.vertexVector.length / surf.sizePerVertex) + 24 >= 65000 )
		{
			surf = new Surface3D();
			surf.material = _material;
			surf.addVertexData( Surface3D.POSITION );
			surf.addVertexData( Surface3D.UV0 );
			surf.addVertexData( Surface3D.NORMAL );
			surfaces.push( surf );
			materials.push( _material );
		}
		
		var s:Float = size * 0.5;
		var i:Int = Std.int(surf.vertexVector.length / surf.sizePerVertex);
		var v = surf.vertexVector;
		
		// front
		v.push(-s + x); v.push( s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push(-1);
		v.push( s + x); v.push( s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push(-1);
		v.push(-s + x); v.push(-s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push(-1);
		v.push( s + x); v.push(-s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push(-1);
		
		// back
		v.push(-s + x); v.push(-s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push( 1);
		v.push( s + x); v.push(-s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push( 1);
		v.push(-s + x); v.push( s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push( 1);
		v.push( s + x); v.push( s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push( 0); v.push( 1);
		
		// left
		v.push(-s + x); v.push( s + y); v.push( s + z); v.push(color); v.push(0); v.push(-1); v.push( 0); v.push( 0);
		v.push(-s + x); v.push( s + y); v.push(-s + z); v.push(color); v.push(0); v.push(-1); v.push( 0); v.push( 0);
		v.push(-s + x); v.push(-s + y); v.push( s + z); v.push(color); v.push(0); v.push(-1); v.push( 0); v.push( 0);
		v.push(-s + x); v.push(-s + y); v.push(-s + z); v.push(color); v.push(0); v.push(-1); v.push( 0); v.push( 0);
		
		// right
		v.push( s + x); v.push( s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 1); v.push( 0); v.push( 0);
		v.push( s + x); v.push( s + y); v.push( s + z); v.push(color); v.push(0); v.push( 1); v.push( 0); v.push( 0);
		v.push( s + x); v.push(-s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 1); v.push( 0); v.push( 0);
		v.push( s + x); v.push(-s + y); v.push( s + z); v.push(color); v.push(0); v.push( 1); v.push( 0); v.push( 0);
		
		// top
		v.push(-s + x); v.push( s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push( 1); v.push( 0);
		v.push( s + x); v.push( s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push( 1); v.push( 0);
		v.push(-s + x); v.push( s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push( 1); v.push( 0);
		v.push( s + x); v.push( s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push( 1); v.push( 0);
		
		// bottom
		v.push(-s + x); v.push(-s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push(-1); v.push( 0);
		v.push( s + x); v.push(-s + y); v.push(-s + z); v.push(color); v.push(0); v.push( 0); v.push(-1); v.push( 0);
		v.push(-s + x); v.push(-s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push(-1); v.push( 0);
		v.push( s + x); v.push(-s + y); v.push( s + z); v.push(color); v.push(0); v.push( 0); v.push(-1); v.push( 0);
		
		var l:Int = i + 24;
		var idx = surf.indexVector;
		while (i < l) 
		{ 
			idx.push(i); 
			idx.push(i + 1); 
			idx.push(i + 2); 
			idx.push(i + 1); 
			idx.push(i + 3); 
			idx.push(i + 2); 
			i += 4; 
		}
		
		_needToUpload = true;
	}
	
	public function upload( scene:Scene3D = null, includeChildren:Bool = true ):Void 
	{
		_needToUpload = false;
		var ctx = flare.system.Device3D.context;
		if (ctx != null) {
			for (s in surfaces) {
				s.upload(ctx);
			}
		}
	}
	
	override public function draw( includeChildren:Bool = true, material:Material3D = null ):Void 
	{
		if ( _needToUpload && scene != null ) upload( scene );
		if ( _needToUpload ) return;
		super.draw(includeChildren, material);
	}
}
