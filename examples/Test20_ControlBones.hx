package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.filters.DropShadowFilter;
import flare.basic.*;
import flare.collisions.*;
import flare.core.*;
import flare.events.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.modifiers.*;
import flare.primitives.*;

/**
 * Procedural bone tracking & Inverse Kinematics control test.
 * Real-time mouse raycasting drives the character head bone (CATRigHub02).
 * 
 * @author Ariel Nehmad.
 */
class Test20_ControlBones extends Sprite 
{
	private var scene:Scene3D;
	private var model:Pivot3D;
	private var head:Pivot3D;
	private var floor:Plane;
	private var sphere:Sphere;
	private var _infoText:TextField;
	private var _targetX:Float = 0.0;
	private var _targetZ:Float = -100.0;
	private var _autoTest:Bool = false;
	private var _autoTimer:Int = 0;
	
	public function new() 
	{
		super();
		#if sys
		try {
			var args = Sys.args();
			if (args != null && (args.indexOf("--test-auto") != -1 || args.indexOf("--auto") != -1)) {
				_autoTest = true;
			}
		} catch (e:Dynamic) {}
		#end

		scene = new Viewer3D(this);
		var viewer:Viewer3D = cast scene;
		viewer.target = new Vector3D(0, 50, 0);
		scene.camera.setPosition(0, 500, -500);
		scene.camera.lookAt(0, 50, 0);
		viewer.syncOrbitFromCamera();

		scene.addEventListener(Scene3D.COMPLETE_EVENT, completeEvent);
		scene.addEventListener(Scene3D.RENDER_EVENT, onRender);
		scene.addEventListener(Scene3D.UPDATE_EVENT, onUpdate);
		
		model = scene.addChildFromFile("vaca.zf3d");

		if (stage != null || (openfl.Lib.current != null && openfl.Lib.current.stage != null)) {
			initStageEvents();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, function(e:Event) {
				initStageEvents();
			});
		}

		initUI();
	}

	private function initStageEvents():Void 
	{
		var st = stage != null ? stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
		if (st != null) {
			st.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
		}
	}

	private function initUI():Void 
	{
		var fontName:String = "_sans";
		#if sys
		try {
			var testPaths = [
				"C:/Windows/Fonts/simhei.ttf",
				"C:/Windows/Fonts/msyh.ttc",
				"C:/Windows/Fonts/simsun.ttc"
			];
			for (fp in testPaths) {
				if (sys.FileSystem.exists(fp)) {
					var font = openfl.text.Font.fromFile(fp);
					if (font != null) {
						openfl.text.Font.registerFont(font);
						fontName = font.fontName;
						break;
					}
				}
			}
		} catch (e:Dynamic) {}
		#end

		_infoText = new TextField();
		_infoText.defaultTextFormat = new TextFormat(fontName, 13, 0xffffff, true);
		_infoText.autoSize = TextFieldAutoSize.LEFT;
		_infoText.selectable = false;
		_infoText.mouseEnabled = false;
		_infoText.x = 16;
		_infoText.y = 16;
		_infoText.filters = [new DropShadowFilter(2, 45, 0x000000, 0.9, 4, 4)];
		addChild(_infoText);

		_infoText.text = "Test20_ControlBones | 动画控制\n" +
			"程序化骨骼反向动力学追踪 | 鼠标在三维空间移动，实时驱动角色头部/脊柱节点注视\n" +
			"状态：程序化骨骼追踪控制器激活，角色骨骼随鼠标移动实时注视\n" +
			"操作：在窗口中移动鼠标引导小白球，奶牛头部实时追踪注视；按住左键拖拽旋转视角";
	}
	
	private function completeEvent(e:Event):Void 
	{
		flare.system.DebugLog.log("[Test20] completeEvent called!");
		var viewer:Viewer3D = cast scene;
		viewer.target = new Vector3D(0, 50, 0);
		scene.camera.setPosition(0, 500, -500);
		scene.camera.lookAt(0, 50, 0);
		viewer.syncOrbitFromCamera();

		// Get model and the head bone
		if (model != null) {
			head = model.getChildByName("CATRigHub02");
			var child = model.getChildByName("Line01");
			var mesh:Mesh3D = Std.isOfType(child, Mesh3D) ? cast child : null;
			var skin:SkinModifier = (mesh != null && Std.isOfType(mesh.modifier, SkinModifier)) ? cast mesh.modifier : null;
			if (head == null && skin != null && skin.root != null) {
				head = skin.root.getChildByName("CATRigHub02");
			}
			
			// Enable dynamic deformation so real-time procedural head bone rotations update the mesh vertices
			if (skin != null) {
				skin.dynamicDeformation = true;
				flare.system.DebugLog.log("[Test20] Enabled dynamicDeformation on SkinModifier");
			}
			
			// Prevent keyframe animation from overriding manual orientation
			if (head != null) {
				head.frames = null;
				flare.system.DebugLog.log("[Test20] Found head bone CATRigHub02 and disabled static keyframes");
			}
		}
		
		var sphereMat = new Shader3D("sphereMat", [new ColorFilter(0xdddddd)]);
		sphere = new Sphere("sphere", 7, 24, 16, sphereMat);
		sphere.parent = scene;
		sphere.setPosition(_targetX, 7, _targetZ);
		
		var floorMat = new Shader3D("floorMat", [new ColorFilter(0x383c42)]);
		floorMat.twoSided = true;
		floor = new Plane("floor", 1000, 1000, 1, floorMat, "+xz");
		floor.addEventListener(MouseEvent3D.MOUSE_MOVE, mouseMoveEvent);
		floor.parent = scene;

		updateTarget(_targetX, _targetZ);
	}
	
	private function onUpdate(e:Event):Void 
	{
		if (_autoTest) {
			_autoTimer++;
			var phase = (_autoTimer % 360);
			if (phase < 120) {
				updateTarget(0.0, -100.0);
			} else if (phase < 240) {
				updateTarget(-120.0, -100.0);
			} else {
				updateTarget(120.0, -100.0);
			}
		}
	}
	
	private function mouseMoveEvent(e:MouseEvent3D):Void 
	{
		var info:CollisionInfo = e.info;
		if (info != null && info.point != null) {
			updateTarget(info.point.x, info.point.z);
		}
	}

	private function onStageMouseMove(e:MouseEvent):Void 
	{
		var ray = scene.getScreenRay(e.stageX, e.stageY);
		if (ray != null && Math.abs(ray.dir.y) > 0.0001) {
			var t = -ray.origin.y / ray.dir.y;
			if (t > 0) {
				var hx = ray.origin.x + ray.dir.x * t;
				var hz = ray.origin.z + ray.dir.z * t;
				updateTarget(hx, hz);
			}
		}
	}

	private function updateTarget(x:Float, z:Float):Void 
	{
		_targetX = x;
		_targetZ = z;
		if (sphere != null) {
			sphere.x = x;
			sphere.y = 7;
			sphere.z = z;
		}
		if (head != null) {
			head.setRotation(x * 0.1, z * 0.1, 0);
		}
	}

	private function onRender(e:Event):Void 
	{
		// Continuously re-apply procedural rotation right before deformation and rendering
		if (head != null) {
			head.setRotation(_targetX * 0.1, _targetZ * 0.1, 0);
		}
	}
}
