package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flare.basic.Scene3D;
import flare.basic.Viewer3D;
import flare.core.Camera3D;
import flare.core.Label3D;
import flare.core.Mesh3D;
import flare.core.Pivot3D;
import flare.system.Input3D;

/**
 * Test08_Animations2
 * 宇航员骨骼蒙皮动画演示 (Astronaut Skeletal Animation State Machine)
 * 
 * 还原 Flash Flare3D 官方示例 08：
 * - 骨骼蒙皮动画状态机: 奔跑 (run: 0-22)、跳跃 (jump: 22-65)、待机 (wait: 51)
 * - 键盘控制 (W / ↑ 奔跑, 空格 跳跃, S / ↓ 待机)
 * - 鼠标交互 (屏幕动作按钮、360° 自由旋转视角、滚轮缩放)
 * - 自动循环演示模式 (Auto Loop)
 * 
 * @author Ariel Nehmad
 */
class Test08_Animations2 extends Sprite 
{
	private var scene:Scene3D;
	private var model:Pivot3D;
	private var mesh:Mesh3D;
	
	private var state:String = "run";
	private var backTo:String = "run";
	private var autoLoop:Bool = true;
	private var autoTimer:Float = 0;
	
	// HUD UI Elements
	private var hudContainer:Sprite;
	private var statusText:TextField;
	private var btnRun:Sprite;
	private var btnJump:Sprite;
	private var btnWait:Sprite;
	private var btnAuto:Sprite;
	private var autoText:TextField;

	public function new() 
	{
		super();
		scene = new Viewer3D( this );
		scene.camera = new Camera3D( "AstronautCam", 45 );
		scene.camera.setPosition( -15, 10, 20 );
		scene.camera.lookAt( 0, 5.0, 0 );
		scene.autoResize = true;
		
		if (Std.isOfType(scene, Viewer3D)) {
			var v:Viewer3D = cast scene;
			v.target.setTo(0, 5.0, 0);
			v.radius = 25.0;
			v.syncOrbitFromCamera();
		}
		
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		model = scene.addChildFromFile( "astronaut.zf3d" );

		createHUD();
	}
	
	private function completeEvent(e:Event):Void 
	{
		// 确保人物中心处于视口中央 Y=5.0
		if (Std.isOfType(scene, Viewer3D)) {
			var v:Viewer3D = cast scene;
			v.target.setTo(0, 5.0, 0);
			v.radius = 25.0;
			v.updateCameraOrbit();
		} else if (scene.camera != null) {
			scene.camera.setPosition( -15, 10, 20 );
			scene.camera.lookAt( 0, 5.0, 0 );
		}

		var node = model.getChildByName( "astronaut" );
		if (node != null && Std.isOfType(node, Mesh3D)) {
			mesh = cast node;
		} else {
			mesh = null;
		}
		if (mesh == null) {
			model.forEach(function(p:Dynamic) {
				if (mesh == null && Std.isOfType(p, Mesh3D)) {
					mesh = cast p;
				}
			});
		}
		
		// 为模型和网格同时注册动作标签
		model.addLabel( new Label3D( "run", 0, 22 ) );
		model.addLabel( new Label3D( "jump", 22, 65 ) );
		
		if (mesh != null) {
			// 严格对齐 Flash AS3 原版：宇航员身体为不透明实体，只有头部太空透明头盔罩为半透明
			for (i in 0...mesh.materials.length) {
				var mat = mesh.materials[i];
				if (mat != null) {
					if (mat.name != null && (mat.name.toLowerCase().indexOf("head") != -1 || mat.name.toLowerCase().indexOf("glass") != -1)) {
						mat.sourceFactor = openfl.display3D.Context3DBlendFactor.ONE;
						mat.destFactor = openfl.display3D.Context3DBlendFactor.ONE;
						mat.depthWrite = false;
						mat.twoSided = false;
						mat.cullFace = openfl.display3D.Context3DTriangleFace.BACK;
					} else {
						// 头部五官、头发、衣服、手套、鞋子、背包等全部为实体不透明
						mat.transparent = false;
						mat.depthWrite = true;
						mat.twoSided = false;
						mat.cullFace = openfl.display3D.Context3DTriangleFace.BACK;
						mat.sourceFactor = openfl.display3D.Context3DBlendFactor.ONE;
						mat.destFactor = openfl.display3D.Context3DBlendFactor.ZERO;
					}
				}
			}

			mesh.addEventListener( Pivot3D.ANIMATION_COMPLETE_EVENT, animationCompleteEvent );
			mesh.addLabel( new Label3D( "run", 0, 22 ) );
			mesh.addLabel( new Label3D( "jump", 22, 65 ) );
		}
		
		// 加载完成后默认开始播放奔跑动画，保证人物画面充满活力
		playAction( "run" );
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}

	public function playAction(newAction:String):Void 
	{
		state = newAction;
		if (newAction == "run") {
			if (mesh != null) mesh.gotoAndPlay( "run", 5 );
			if (model != null) model.gotoAndPlay( "run", 5 );
		} else if (newAction == "jump") {
			if (mesh != null) mesh.gotoAndPlay( "jump", 5 );
			if (model != null) model.gotoAndPlay( "jump", 5 );
		} else if (newAction == "wait") {
			if (mesh != null) mesh.gotoAndStop( 51, 15 );
			if (model != null) model.gotoAndStop( 51, 15 );
		}
		updateStatusDisplay();
	}
	
	private function animationCompleteEvent(e:Event):Void 
	{
		if ( state == "jump" ) 
		{
			if ( isForwardKeyDown() ) {
				playAction( "run" );
			} else if ( autoLoop ) {
				playAction( "wait" );
				autoTimer = 0;
			} else {
				playAction( backTo != null ? backTo : "wait" );
			}
		}
	}

	private inline function isForwardKeyDown():Bool {
		return Input3D.keyDown( Input3D.UP ) || Input3D.keyDown( Input3D.W );
	}

	private inline function isForwardKeyHit():Bool {
		return Input3D.keyHit( Input3D.UP ) || Input3D.keyHit( Input3D.W );
	}

	private inline function isForwardKeyUp():Bool {
		return Input3D.keyUp( Input3D.UP ) || Input3D.keyUp( Input3D.W );
	}
	
	private function updateEvent(e:Event):Void 
	{
		if (mesh == null) return;
		
		// 键盘输入响应
		if ( state == "jump" ) 
		{
			if ( isForwardKeyHit() ) backTo = "run";
			if ( isForwardKeyUp() ) backTo = "wait";
		}
		else
		{
			if ( isForwardKeyHit() )
			{
				autoLoop = false;
				updateAutoButtonText();
				playAction( "run" );
			}
			if ( isForwardKeyUp() && !isForwardKeyDown() ) 
			{
				playAction( "wait" );
			}
			if ( Input3D.keyHit( Input3D.S ) || Input3D.keyHit( Input3D.DOWN ) )
			{
				autoLoop = false;
				updateAutoButtonText();
				playAction( "wait" );
			}
		}
		
		if ( Input3D.keyHit( Input3D.SPACE ) && state != "jump" ) 
		{
			autoLoop = false;
			updateAutoButtonText();
			backTo = isForwardKeyDown() ? "run" : "wait";
			playAction( "jump" );
		}

		// 自动演示循环逻辑 (Auto Loop)
		if ( autoLoop && state != "jump" ) 
		{
			autoTimer += 1.0 / 60.0;
			if ( state == "run" && autoTimer >= 3.5 ) 
			{
				autoTimer = 0;
				playAction( "jump" );
			} 
			else if ( state == "wait" && autoTimer >= 2.0 ) 
			{
				autoTimer = 0;
				playAction( "run" );
			}
		}

		// 刷新 HUD 状态文本
		if ( openfl.Lib.getTimer() % 10 == 0 ) {
			updateStatusDisplay();
		}
	}

	private function updateStatusDisplay():Void 
	{
		if (statusText == null) return;
		var curF = mesh != null ? Std.int(mesh.currentFrame) : 0;
		var actCn = switch(state) {
			case "run": "【奔跑 RUN】";
			case "jump": "【跳跃 JUMP】";
			case "wait": "【待机 WAIT】";
			default: "【" + state + "】";
		};
		statusText.text = "Flare3D - 宇航员骨骼蒙皮动画 (Test08)\n" +
			"当前动作: " + actCn + "  (帧号: " + curF + "/65)\n" +
			"按键: [W / ↑] 奔跑 | [空格 Space] 跳跃 | [S / ↓] 待机\n" +
			"视角: [鼠标左键拖拽] 360°旋转 | [滚轮] 缩放";
	}

	private function updateAutoButtonText():Void 
	{
		if (autoText != null) {
			autoText.text = autoLoop ? "自动循环: 开启" : "自动循环: 关闭";
		}
	}

	private function createHUD():Void 
	{
		hudContainer = new Sprite();
		addChild( hudContainer );

		var bg = new Sprite();
		bg.graphics.beginFill( 0x000000, 0.72 );
		bg.graphics.drawRoundRect( 12, 12, 420, 140, 10, 10 );
		bg.graphics.endFill();
		hudContainer.addChild( bg );

		var tf = new TextFormat( "_sans", 13, 0xffffff );
		statusText = new TextField();
		statusText.defaultTextFormat = tf;
		statusText.x = 22;
		statusText.y = 18;
		statusText.width = 400;
		statusText.height = 80;
		statusText.selectable = false;
		statusText.mouseEnabled = false;
		hudContainer.addChild( statusText );

		btnRun = createButton( "奔跑 (Run)", 22, 102, 85, 30, function() {
			autoLoop = false;
			updateAutoButtonText();
			playAction( "run" );
		});
		hudContainer.addChild( btnRun );

		btnJump = createButton( "跳跃 (Jump)", 117, 102, 85, 30, function() {
			autoLoop = false;
			updateAutoButtonText();
			backTo = "run";
			playAction( "jump" );
		});
		hudContainer.addChild( btnJump );

		btnWait = createButton( "待机 (Wait)", 212, 102, 85, 30, function() {
			autoLoop = false;
			updateAutoButtonText();
			playAction( "wait" );
		});
		hudContainer.addChild( btnWait );

		btnAuto = createButton( "自动循环: 开启", 307, 102, 115, 30, function() {
			autoLoop = !autoLoop;
			autoTimer = 0;
			updateAutoButtonText();
			if (autoLoop && state == "wait") {
				playAction( "run" );
			}
		});
		autoText = cast btnAuto.getChildAt(1);
		hudContainer.addChild( btnAuto );

		updateStatusDisplay();
	}

	private function createButton(label:String, x:Float, y:Float, w:Float, h:Float, onClick:Void->Void):Sprite 
	{
		var btn = new Sprite();
		btn.x = x;
		btn.y = y;
		btn.buttonMode = true;
		btn.mouseChildren = false;

		function drawBtn(color:Int, alpha:Float) {
			btn.graphics.clear();
			btn.graphics.beginFill( color, alpha );
			btn.graphics.lineStyle( 1, 0x66aaff, 0.9 );
			btn.graphics.drawRoundRect( 0, 0, w, h, 6, 6 );
			btn.graphics.endFill();
		}

		drawBtn( 0x223355, 0.85 );

		var tf = new TextFormat( "_sans", 12, 0xffffff, true );
		tf.align = openfl.text.TextFormatAlign.CENTER;
		var txt = new TextField();
		txt.defaultTextFormat = tf;
		txt.text = label;
		txt.width = w;
		txt.height = h;
		txt.y = 5;
		txt.selectable = false;
		txt.mouseEnabled = false;
		btn.addChild( txt );

		btn.addEventListener( MouseEvent.MOUSE_OVER, function(e:MouseEvent) {
			drawBtn( 0x336699, 1.0 );
		});
		btn.addEventListener( MouseEvent.MOUSE_OUT, function(e:MouseEvent) {
			drawBtn( 0x223355, 0.85 );
		});
		btn.addEventListener( MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
			drawBtn( 0x112244, 1.0 );
		});
		btn.addEventListener( MouseEvent.CLICK, function(e:MouseEvent) {
			onClick();
		});

		return btn;
	}
}
