package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;

/**
 * Demonstrates a sphere textured with diffuse rock map, repeated normal map,
 * and environment reflection map rotating around its vertical axis.
 * 
 * @author Ariel Nehmad
 */
class Test15_SimpleNormalMap extends Sprite 
{
	private var scene:Scene3D;
	private var sphere:Mesh3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.camera.setPosition( 0, 0, -15 );
		scene.camera.lookAt( 0, 0, 0 );
		
		var customShader:Shader3D = new Shader3D();
		customShader.filters.push( new TextureMapFilter( scene.addTextureFromFile( "tex6.jpg" ) ) );
		customShader.filters.push( new NormalMapFilter( scene.addTextureFromFile( "images.jpg" ) ) );
		customShader.filters.push( new EnvironmentMapFilter( scene.addTextureFromFile( "reflections.jpg" ), BlendMode.MULTIPLY, 1.5 ) );
		customShader.transparent = false;
		customShader.depthWrite = true;
		customShader.sourceFactor = openfl.display3D.Context3DBlendFactor.ONE;
		customShader.destFactor = openfl.display3D.Context3DBlendFactor.ZERO;
		customShader.build();
		
		customShader.filters[1].repeatX = 4;
		customShader.filters[1].repeatY = 4;
		
		sphere = new Sphere( "sphere", 5, 25, customShader );
		sphere.parent = scene;
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		sphere.rotateY(0.5);
	}
}
