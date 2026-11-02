package examples.starling_integration.example1;

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

import starling.display.*;
	import starling.textures.*;
	
	/**
	 * @author Ariel Nehmad
	 */
	class StarlingBack extends Sprite
	{
		// [Embed metadata]
		private var Backgounrd:Class<Dynamic>;
		
		public function new()
		{
			super();
			var texture:Texture = Texture.fromBitmap( Type.createInstance(Backgounrd, []));
			var image:Image = new Image( texture );
			
			addChild( image );
		}
	}
