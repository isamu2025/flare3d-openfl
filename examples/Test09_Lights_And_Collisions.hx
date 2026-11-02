package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Vector3D;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flare.basic.Scene3D;
import flare.collisions.CollisionInfo;
import flare.collisions.SphereCollision;
import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Pivot3D;
import flare.materials.filters.LightFilter;
import flare.system.Input3D;

class Test09_Lights_And_Collisions extends Sprite 
{
	private var scene:Scene3D;
	private var player:Pivot3D;
	private var map:Pivot3D;
	private var collisions:SphereCollision;
	private var light0:Light3D;
	
	// Player physics variables
	private var jump:Bool = false;
	private var velocity:Vector3D = new Vector3D();
	private var friction:Vector3D = new Vector3D(0.6, 1, 0.6);
	private var oldPosition:Vector3D = new Vector3D();
	private var camPitch:Float = 0;

	// Dynamic moving elevator platforms
	private var _platform1:Pivot3D = null;
	private var _platform2:Pivot3D = null;
	private var _prevPlat1Y:Float = 0;
	private var _prevPlat2Y:Float = 0;
	private var _plat1Initialized:Bool = false;
	private var _plat2Initialized:Bool = false;

	// On-screen UI overlay
	private var txtStatus:TextField;
	
	public function new() 
	{
		super();
		scene = new Scene3D(this);
		scene.skipFrames = false;
		scene.autoResize = true;
		
		// Set clear color (warm orange sky matching Flash original: 0.7, 0.4, 0.2)
		scene.clearColor.setTo( 0.7, 0.4, 0.2 );
		
		// Deactivate default light, we will use the lights included on the map file.
		scene.lights.defaultLight = null;
		
		// 8 point lights brute force configuration matching authentic Flare3D demo
		scene.lights.maxPointLights = 8;
		scene.lights.maxDirectionalLights = 0;
		scene.lights.ambientColor = new Vector3D( 0.4, 0.38, 0.35 );
		scene.lights.techniqueName = LightFilter.SAMPLED;

		// Load map
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
		map = scene.addChildFromFile( "map.f3d" );
		
		// Player pivot
		player = new Pivot3D( "ourPlayer" );
		player.parent = scene;
		player.setPosition( 0, 100, -100 );
		oldPosition.copyFrom( player.getPosition() );
		
		// FPS Camera parented to player
		scene.camera = new Camera3D( "ourCamera", 85 );
		scene.camera.y = 20;
		scene.camera.parent = player;

		// Create on-screen HUD UI
		setupUI();
	}

	private function setupUI():Void 
	{
		txtStatus = new TextField();
		txtStatus.x = 16;
		txtStatus.y = 16;
		txtStatus.width = 768;
		txtStatus.height = 70;
		txtStatus.selectable = false;
		txtStatus.mouseEnabled = false;
		var fmt = new TextFormat("_sans", 13, 0xffffff, true);
		txtStatus.defaultTextFormat = fmt;
		addChild(txtStatus);
		updateLightingUI();
	}

	public function setLightingTechnique(tech:String):Void 
	{
		scene.lights.techniqueName = tech;
		scene.clearColor.setTo( 0.7, 0.4, 0.2 );
		updateLightingUI(tech);
	}

	public function updateLightingUI(tech:String = null):Void 
	{
		var currentTech = tech != null ? tech : (scene != null && scene.lights != null ? scene.lights.techniqueName : LightFilter.SAMPLED);
		var label = "SAMPLED";
		if (currentTech == LightFilter.NO_LIGHTS) label = "NO_LIGHTS (无动态光/仅环境光)";
		else if (currentTech == LightFilter.PER_VERTEX) label = "PER_VERTEX (顶点高对比度)";
		else if (currentTech == LightFilter.LINEAR) label = "LINEAR (线性平滑衰减)";
		else if (currentTech == LightFilter.SAMPLED) label = "SAMPLED (Flare3D真实采样)";

		if (txtStatus != null) {
			txtStatus.text = "【Flare3D Test09 光照技术】 [1] NO_LIGHTS  [2] PER_VERTEX  [3] LINEAR  [4] SAMPLED\n" +
			                 "当前光照模式: " + label + "\n" +
			                 "操作指南: W/S/A/D 移动 | 鼠标拖拽 视角 | 空格 跳跃 | SHIFT 加速 | 1~4 切换光照";
		}
	}
	
	private function progressEvent(e:Event):Void 
	{
		// Scene loading progress
	}
	
	private function completeEvent(e:Event):Void 
	{
		// Access broken flickering light Omni032
		if (light0 == null) {
			if (scene.lights != null && scene.lights.list != null) {
				for (l in scene.lights.list) {
					if (l.name == "Omni032") {
						light0 = l;
						break;
					}
				}
			}
			if (light0 == null) {
				var lNode = scene.getChildByName( "Omni032" );
				if (lNode == null && map != null) lNode = map.getChildByName( "Omni032" );
				if (lNode != null && Std.isOfType(lNode, Light3D)) {
					light0 = cast lNode;
				}
			}
		}

		// Locate dynamic moving elevator platforms
		if (map != null) {
			_platform1 = map.getChildByName("VBSP_Object_model_1");
			_platform2 = map.getChildByName("VBSP_Object_model_4");
		}
		
		// Create 3D polygon sphere collision manager
		collisions = new SphereCollision( player, 25 );
		collisions.addCollisionWith( map );
		
		// Start game loop
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		// simulate the broken light. 
		if ( light0 != null ) {
			if ( Math.random() > 0.5 ) 
				light0.visible = true; 
			else 
				light0.visible = false;
		}

		// switch between different light configurations (Keys 1, 2, 3, 4).
		if ( Input3D.keyHit( Input3D.NUMBER_1 ) || Input3D.keyHit( Input3D.NUMPAD_1 ) ) setLightingTechnique( LightFilter.NO_LIGHTS );
		if ( Input3D.keyHit( Input3D.NUMBER_2 ) || Input3D.keyHit( Input3D.NUMPAD_2 ) ) setLightingTechnique( LightFilter.PER_VERTEX );
		if ( Input3D.keyHit( Input3D.NUMBER_3 ) || Input3D.keyHit( Input3D.NUMPAD_3 ) ) setLightingTechnique( LightFilter.LINEAR );
		if ( Input3D.keyHit( Input3D.NUMBER_4 ) || Input3D.keyHit( Input3D.NUMPAD_4 ) ) setLightingTechnique( LightFilter.SAMPLED );
		
		// 3. Mouse drag view: strictly lock FPS camera (no roll, pitch clamped between -80 and +80)
		if ( Input3D.mouseDown )
		{
			// Horizontal rotation around Y turns player body
			player.rotateY( Input3D.mouseXSpeed * 0.2 );
			
			// Vertical pitch on camera clamped between -80 and +80 degrees
			camPitch += Input3D.mouseYSpeed * 0.2;
			if (camPitch > 80) camPitch = 80;
			if (camPitch < -80) camPitch = -80;
			scene.camera.setRotation( camPitch, 0, 0 );
		}
		
		// 4. Movement physics
		var playerVel:Float = 1.2;
		if ( Input3D.keyDown( Input3D.SHIFT ) ) playerVel *= 1.8;
		
		// WASD and Arrow Keys translation in left-handed Stage3D coordinates (+Z forward, -Z backward, +X right, -X left)
		if ( Input3D.keyDown( Input3D.A ) || Input3D.keyDown( Input3D.LEFT ) ) player.translateX( -playerVel );
		if ( Input3D.keyDown( Input3D.D ) || Input3D.keyDown( Input3D.RIGHT ) ) player.translateX( playerVel );
		if ( Input3D.keyDown( Input3D.S ) || Input3D.keyDown( Input3D.DOWN ) ) player.translateZ( -playerVel );
		if ( Input3D.keyDown( Input3D.W ) || Input3D.keyDown( Input3D.UP ) ) player.translateZ( playerVel );
		
		// Jump
		if ( !jump && Input3D.keyHit( Input3D.SPACE ) )
		{
			player.translateY( 10 ); 
			jump = true;
		}
		
		// Update player position with gravity
		player.x += velocity.x;
		player.y += velocity.y - 0.75;
		player.z += velocity.z;
		
		// 5. 3D polygon sphere sliding collision check (floors, walls, ramps, ceilings)
		if ( collisions != null && collisions.slider() )
		{
			for ( info in collisions.data )
			{
				if ( info.normal.y > 0.7 ) jump = false;
			}
		}

		// 6. Dynamic moving elevator platform 1 riding & physics
		if (_platform1 != null) {
			var platTopY = _platform1.y + 66.0;
			if (!_plat1Initialized) {
				_prevPlat1Y = platTopY;
				_plat1Initialized = true;
			}
			_prevPlat1Y = platTopY;

			// Platform 1 bounds: X in [328, 458], Z in [-278, -146]
			var onX = player.x >= 328 && player.x <= 458;
			var onZ = player.z >= -278 && player.z <= -146;

			if (onX && onZ) {
				var targetPlayerY = platTopY + 25.0;
				if (!jump && player.y >= platTopY - 10.0 && player.y <= targetPlayerY + 15.0) {
					player.y = targetPlayerY;
					oldPosition.y = targetPlayerY;
					velocity.y = 0;
				} else if (jump && player.y <= targetPlayerY) {
					player.y = targetPlayerY;
					oldPosition.y = targetPlayerY;
					velocity.y = 0;
					jump = false;
				}
			}
		}

		// 7. Dynamic moving elevator platform 2 riding & physics
		if (_platform2 != null) {
			var platTopY = _platform2.y + 74.0;
			if (!_plat2Initialized) {
				_prevPlat2Y = platTopY;
				_plat2Initialized = true;
			}
			_prevPlat2Y = platTopY;

			// Platform 2 bounds: X in [136, 266], Z in [424, 560]
			var onX = player.x >= 136 && player.x <= 266;
			var onZ = player.z >= 424 && player.z <= 560;

			if (onX && onZ) {
				var targetPlayerY = platTopY + 25.0;
				if (!jump && player.y >= platTopY - 10.0 && player.y <= targetPlayerY + 15.0) {
					player.y = targetPlayerY;
					oldPosition.y = targetPlayerY;
					velocity.y = 0;
				} else if (jump && player.y <= targetPlayerY) {
					player.y = targetPlayerY;
					oldPosition.y = targetPlayerY;
					velocity.y = 0;
					jump = false;
				}
			}
		}

		// 8. Void fall-through protection (matching flare3d-ts)
		if (player.y < -20) {
			player.setPosition(0, 30, -100);
			velocity.setTo(0, 0, 0);
			oldPosition.copyFrom(player.getPosition());
		}
		
		// 9. Update player velocity with friction (Verlet integration)
		velocity.x = ( player.x - oldPosition.x ) * friction.x;
		velocity.y = ( player.y - oldPosition.y ) * friction.y;
		velocity.z = ( player.z - oldPosition.z ) * friction.z;

		// Clamp velocities to prevent collision tunneling
		var maxHVel:Float = 3.5;
		var maxVVel:Float = 12.0;
		velocity.x = Math.max(-maxHVel, Math.min(maxHVel, velocity.x));
		velocity.y = Math.max(-maxVVel, Math.min(maxVVel, velocity.y));
		velocity.z = Math.max(-maxVVel, Math.min(maxVVel, velocity.z));
		
		// Store last position
		oldPosition.copyFrom( player.getPosition() );
	}
}
