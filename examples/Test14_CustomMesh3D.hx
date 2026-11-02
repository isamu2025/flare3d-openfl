package examples;

import openfl.display.Sprite;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;

/**
 * Custom mesh test.
 * 
 * @author Ariel Nehmad.
 */
class Test14_CustomMesh3D extends Sprite 
{
	private var scene:Scene3D;
	private var mesh:Mesh3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.autoResize = true;
		scene.camera.setPosition( 0, 20, -30 );
		scene.camera.lookAt( 0, 0, 0 );
		
		mesh = new Mesh3D();
		mesh.surfaces[0] = new Surface3D();
		mesh.surfaces[0].addVertexData( Surface3D.POSITION, 3 );
		mesh.surfaces[0].addVertexData( Surface3D.NORMAL, 3 );
		mesh.surfaces[0].addVertexData( Surface3D.UV0, 2 );
		mesh.surfaces[0].addVertexData( Surface3D.COLOR0, 3 );
		
		// position, normal, uv0, color0
		// Vertex 0: (-10, 0, 10), normal (0, 1, 0), uv (0, 0), color (1, 0, 0) - Red
		mesh.surfaces[0].vertexVector.push(-10); mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(10);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(0);
		mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(0);
		
		// Vertex 1: (10, 0, 10), normal (0, 1, 0), uv (1, 0), color (0, 1, 0) - Green
		mesh.surfaces[0].vertexVector.push(10); mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(10);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0);
		mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0);
		
		// Vertex 2: (-10, 0, -10), normal (0, 1, 0), uv (0, 1), color (0, 0, 1) - Blue
		mesh.surfaces[0].vertexVector.push(-10); mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(-10);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(1);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(1);
		
		// Vertex 3: (10, 0, -10), normal (0, 1, 0), uv (1, 1), color (1, 1, 0) - Yellow
		mesh.surfaces[0].vertexVector.push(10); mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(-10);
		mesh.surfaces[0].vertexVector.push(0); mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0);
		mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(1);
		mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(1); mesh.surfaces[0].vertexVector.push(0);
		
		mesh.surfaces[0].indexVector.push(0);
		mesh.surfaces[0].indexVector.push(1);
		mesh.surfaces[0].indexVector.push(2);
		mesh.surfaces[0].indexVector.push(1);
		mesh.surfaces[0].indexVector.push(3);
		mesh.surfaces[0].indexVector.push(2);
		
		var customShader:Shader3D = new Shader3D( "material", [ new TextureMapFilter(), new VertexColorFilter() ] );
		customShader.twoSided = true;
		
		mesh.surfaces[0].material = customShader;			
		
		var clone:Mesh3D = cast(mesh.clone(), Mesh3D);
		clone.setRotation( 23, 10, 56 );
		clone.y = 10;
		
		scene.addChild( mesh );
		scene.addChild( clone );
	}
}
