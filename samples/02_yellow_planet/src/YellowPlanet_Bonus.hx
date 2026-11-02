package;

import flare.basic.Scene3D;
import flare.collisions.RayCollision;
import flare.collisions.SphereCollision;
import flare.collisions.CollisionInfo;
import flare.core.Camera3D;
import flare.core.Pivot3D;
import flare.core.Particles3D;
import flare.core.Label3D;
import flare.core.Light3D;
import flare.core.Mesh3D;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;
import flare.materials.filters.TextureMapFilter;
import flare.materials.filters.LightFilter;
import flare.core.Texture3D;
import flare.system.Input3D;
import flare.utils.Pivot3DUtils;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.display.StageScaleMode;
import openfl.display.StageAlign;
import openfl.display.CapsStyle;
import openfl.display.JointStyle;
import openfl.display.LineScaleMode;
import openfl.display3D.Context3DBlendFactor;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.geom.Vector3D;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;
import openfl.Lib;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.utils.Assets;

/**
 * YellowPlanet_Bonus - Flare3D OpenFL 现代化高保真移植版
 * 
 * 100% 忠实还原原版 Flash Stage3D 与 Away3D 真实游戏界面：
 * - 真实宏大球形行星俯瞰视角（前视焦点 + 地表法线 Up 向量 + 完整弯曲天际线）
 * - 原版正统 Flash 矢量 UI（左上角绿色徽章 points/best，右上角科技能量槽，开场 INSTRUCTIONS/CONTROLS 弹窗）
 * - 48 骨骼 10215 顶点宇航员平滑跑步动作
 * - 地表射线碰撞吸附与滑动障碍响应
 */
class YellowPlanet_Bonus extends Sprite 
{
    private var scene:Scene3D;
    private var planet:Pivot3D;
    private var astronaut:Pivot3D;
    private var container:Pivot3D;
    private var shadow:Pivot3D;
    private var sky:Pivot3D;
    private var energy:Pivot3D;
    private var smoke:Pivot3D;
    private var fire:Particles3D;
    private var energyColorFilter:ColorFilter;
    private var _ionSmokeTexture:Texture3D;
    private var _ionSmokeEmitters:Array<flare.core.IonSmokeParticles> = [];
    
    private var mines:Array<Pivot3D> = [];
    private var fan:Array<Pivot3D> = [];
    private var points:Array<Pivot3D> = [];
    
    private var collisions:SphereCollision;
    private var ray:RayCollision;
    
    // 游戏核心状态变量
    public var state:String = "start";
    public var jumpValue:Float = 0;
    public var speed:Float = 0.85;
    public var speedCounter:Int = 1;
    public var score:Int = 0;
    public var bestScore:Int = 0;
    public var energyCount:Int = 0;
    public var energyIndex:Int = 0;
    private var _energyCooldown:Int = 0;
    public var shakeFactor:Float = 0;
    public var resetCounter:Int = 0;
    
    private var lastTime:Float = 0;
    private var isLoaded:Bool = false;
    
    // 相机追踪向量
    private var _camPos:Vector3D;
    private var _camFocus:Vector3D;
    private var _camUp:Vector3D;
    
    // 正统原版 Flash UI 元素
    private var hudContainer:Sprite;
    private var _pointsPanel:Sprite;
    private var _pointsScoreText:TextField;
    private var _bestScoreText:TextField;
    
    private var _energyPanel:Sprite;
    private var _energyCountText:TextField;
    private var _stageLevelText:TextField;
    
    private var _instructionsModal:Sprite;
    private var _scoreModal:Sprite;
    private var _finalScoreText:TextField;
    
    private var _speedBanner:Sprite;
    private var _stageClearTitle:TextField;
    private var _speedValueText:TextField;
    private var _bonusScoreText:TextField;
    private var _continueBtnText:TextField;
    private var _lastUpdateMs:Float = 0;
    private var _powerBurstCanvas:Sprite;
    private var _burstActive:Bool = false;
    private var _burstX:openfl.Vector<Float>;
    private var _burstY:openfl.Vector<Float>;
    private var _burstVx:openfl.Vector<Float>;
    private var _burstVy:openfl.Vector<Float>;
    private var _burstLife:openfl.Vector<Float>;
    private var _burstSize:openfl.Vector<Float>;
    private var _burstColor:openfl.Vector<Int>;
    
    // 原版 Flash 音效与循环背景音乐
    private var sndMusic:Sound;
    private var sndCoin:Sound;
    private var sndDead:Sound;
    private var sndFan:Sound;
    private var sndJump:Sound;
    private var sndMine:Sound;
    private var sndStart:Sound;
    private var sndReset:Sound;
    private var sndScore:Sound;
    private var musicChannel:SoundChannel;
    
    private var loadingOverlay:Sprite;
    private var loadingText:TextField;
    
    private var _gameStartTime:Int = 0;
    private var _fpsCount:Int = 0;
    private var _fpsLastTime:Int = 0;
    
    // 零 GC 预分配临时向量 (用于 60 FPS 无垃圾回收的高频碰撞物理计算)
    private var _fanTempVec:Vector3D = new Vector3D();
    private var _astroTempVec:Vector3D = new Vector3D();
    private var _floorNormVec:Vector3D = new Vector3D();
    private var _pPosVec:Vector3D = new Vector3D();
    private var _targetLookVec:Vector3D = new Vector3D();
    private var _lookOffsetVec:Vector3D = new Vector3D(0, 4, 18);
    private var _containerUpVec:Vector3D = new Vector3D();
    private var _cTempVec:Vector3D = new Vector3D();
    private var _eTempVec:Vector3D = new Vector3D();
    
    public function new() 
    {
        super();
        #if html5
        untyped js.Browser.window._bonusInstance = this;
        #end
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }
    
    private function onAddedToStage(e:Event):Void 
    {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        _gameStartTime = Lib.getTimer();
        _fpsLastTime = _gameStartTime;
        
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.addEventListener(Event.RESIZE, onStageResize);
        
        initUI();
        initSounds();
        layoutGUI();
        
        // 场景与相机基础配置 (深邃蔚蓝宇宙星空，开启 4x MSAA 抗锯齿)
        scene = new Scene3D(this);
        scene.autoResize = true;
        scene.antialiasing = 4;
        scene.clearColor = 0x071D3E;
        
        scene.camera = new Camera3D("camera");
        scene.camera.fieldOfView = 65.0;
        scene.camera.near = 1.0;
        scene.camera.far = 10000.0;
        
        // 平行阳光指向星球起始跑道 (平衡漫反射与环境光，避免过曝泛白)
        var sun = new Light3D("sun", Light3D.DIRECTIONAL, 0xfff5e6, 0.95);
        sun.setPosition(150, 220, -180);
        sun.lookAt(47, 42, -80);
        scene.addChild(sun);
        
        var fillLight = new Light3D("fill", Light3D.DIRECTIONAL, 0x88aacc, 0.45);
        fillLight.setPosition(-150, -100, 150);
        fillLight.lookAt(0, 0, 0);
        scene.addChild(fillLight);
        
        scene.addEventListener(Scene3D.PROGRESS_EVENT, progressEvent);
        scene.addEventListener(Scene3D.COMPLETE_EVENT, completeEvent);
        scene.addEventListener(Scene3D.RENDER_EVENT, function(_) {
            _lastReportedDrawCalls = flare.system.Device3D.drawCalls;
            _lastReportedTriangles = flare.system.Device3D.triangles;
        });
        scene.pause();
        
        // 确保 HUD 在 Stage3D 最顶层
        addChild(hudContainer);
        addChild(loadingOverlay);
        
        // 加载 3D 游戏资产
        planet = scene.addChildFromFile("planet.f3d");
        astronaut = scene.addChildFromFile("astronaut.f3d");
        shadow = scene.addChildFromFile("shadow.f3d");
        energy = scene.addChildFromFile("energy.f3d");
        smoke = scene.addChildFromFile("smoke.zf3d");
        scene.addChildFromFile("fire.zf3d");
        
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    }
    
    private function onKeyDown(e:KeyboardEvent):Void 
    {
        if (e.keyCode == Keyboard.SPACE || e.keyCode == Keyboard.UP || e.keyCode == 87 || e.keyCode == Keyboard.ENTER) {
            handleActionTrigger();
        }
        if (e.keyCode == 189 || e.keyCode == 109 || e.keyCode == 219) { // - 或 [
            speed = Math.max(0.25, speed - 0.05);
        }
        if (e.keyCode == 187 || e.keyCode == 107 || e.keyCode == 221) { // + 或 ]
            speed = Math.min(1.5, speed + 0.05);
        }
        if (e.keyCode == 69) { // E 键: 测试能量 3/3 拾取与过关加速横幅
            score += 1;
            energyCount = 3;
            state = "energy";
            resetCounter = 180;
            showStageClearBanner();
            spawnPowerBurst();
            playSound(sndScore, 1.0);
            playSound(sndReset, 1.0);
            flare.system.DebugLog.log("[STAGE-TEST] Triggered Stage Clear Banner with Zero-GC PowerBurst!");
        }
        if (e.keyCode == 70) { // F 键: 视角对准最大号风扇 (观赏离子烟尘特效)
            for (f in fan) {
                if (f.scaleX > 1.3) {
                    var fPos = f.getPosition(false);
                    var fUp = f.getUp(false);
                    container.setPosition(fPos.x, fPos.y + 4.0, fPos.z - 48.0);
                    container.setNormalOrientation(fUp);
                    container.rotateY(180); // 面朝风扇
                    snapToFloor(1.0);
                    snapCameraToStart();
                    flare.system.DebugLog.log("[VIEW-FAN] Teleported to largest fan at " + fPos.toString());
                    break;
                }
            }
        }
    }
    
    private function onMouseDown(e:MouseEvent):Void 
    {
        handleActionTrigger();
    }
    
    private function handleActionTrigger():Void 
    {
        if (musicChannel == null) playMusic();
        if (state == "start") {
            startRun();
        } else if (state == "run") {
            performJump();
        } else if (state == "energy") {
            nextStage();
        } else if ((state == "die" || state == "fan") && _scoreModal.visible) {
            startRun();
        }
    }
    
    private function initSounds():Void 
    {
        sndStart = loadSoundSafe("StartSound");
        sndJump = loadSoundSafe("JumpSound");
        sndCoin = loadSoundSafe("CoinSound");
        sndMine = loadSoundSafe("MineSound");
        sndFan = loadSoundSafe("FanSound");
        sndDead = loadSoundSafe("DeadSound");
        sndReset = loadSoundSafe("ResetSound");
        sndScore = loadSoundSafe("ScoreSound");
        sndMusic = loadSoundSafe("MusicSound");
        
        playSound(sndStart, 0.85);
        playMusic();
    }

    private function loadSoundSafe(name:String):Sound 
    {
        var candidates = [
            "audio/" + name + ".ogg",
            "audio/" + name + ".mp3",
            "audio/" + name + ".wav",
            "assets/audio/" + name + ".ogg",
            "assets/audio/" + name + ".mp3",
            name + ".ogg",
            name + ".mp3"
        ];
        for (c in candidates) {
            try {
                if (Assets.exists(c)) {
                    var s = Assets.getSound(c);
                    if (s != null) {
                        flare.system.DebugLog.log("[AUDIO] Loaded sound from Assets: " + c);
                        return s;
                    }
                }
            } catch (e:Dynamic) {}
            try {
                var buf = lime.media.AudioBuffer.fromFile(c);
                if (buf != null) {
                    var s = Sound.fromAudioBuffer(buf);
                    if (s != null) {
                        flare.system.DebugLog.log("[AUDIO] Loaded sound from AudioBuffer: " + c);
                        return s;
                    }
                }
            } catch (e:Dynamic) {}
        }
        flare.system.DebugLog.log("[AUDIO] Sound not found: " + name);
        return null;
    }

    private function playSound(snd:Sound, vol:Float = 1.0):Void 
    {
        if (snd == null) return;
        try {
            snd.play(0, 0, new SoundTransform(vol));
        } catch (e:Dynamic) {}
    }

    private function playMusic():Void 
    {
        if (sndMusic == null) return;
        try {
            if (musicChannel != null) {
                musicChannel.stop();
            }
            musicChannel = sndMusic.play(0, 999999, new SoundTransform(0.55));
            flare.system.DebugLog.log("[AUDIO] Playing background music loop!");
        } catch (e:Dynamic) {}
    }
    
    private function initUI():Void 
    {
        hudContainer = new Sprite();
        
        _powerBurstCanvas = new Sprite();
        hudContainer.addChild(_powerBurstCanvas);
        
        _burstX = new openfl.Vector<Float>(30);
        _burstY = new openfl.Vector<Float>(30);
        _burstVx = new openfl.Vector<Float>(30);
        _burstVy = new openfl.Vector<Float>(30);
        _burstLife = new openfl.Vector<Float>(30);
        _burstSize = new openfl.Vector<Float>(30);
        _burstColor = new openfl.Vector<Int>(30);
        
        // ==================== 1. 左上角 POINTS / BEST 经典绿色徽章计分板 ====================
        _pointsPanel = new Sprite();
        hudContainer.addChild(_pointsPanel);

        var g = _pointsPanel.graphics;
        g.lineStyle(3, 0x99D918, 1.0, true, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
        g.beginFill(0x4C6D14, 0.90);
        g.moveTo(0, 0);
        g.lineTo(170, 0);
        g.lineTo(195, 45);
        g.lineTo(150, 75);
        g.lineTo(0, 70);
        g.lineTo(0, 0);
        g.endFill();

        g.lineStyle(2, 0x365012, 1.0);
        g.beginFill(0x27380D, 0.95);
        g.drawRoundRect(105, 8, 48, 25, 6, 6);
        g.drawRoundRect(105, 40, 48, 25, 6, 6);
        g.endFill();

        var lblPoints = new TextField();
        lblPoints.defaultTextFormat = new TextFormat("_sans", 17, 0xF9B219, true);
        lblPoints.text = "points";
        lblPoints.x = 14;
        lblPoints.y = 8;
        lblPoints.selectable = false;
        _pointsPanel.addChild(lblPoints);

        _pointsScoreText = new TextField();
        _pointsScoreText.defaultTextFormat = new TextFormat("_sans", 16, 0x5CD620, true, null, null, null, null, TextFormatAlign.CENTER);
        _pointsScoreText.text = "0";
        _pointsScoreText.x = 105;
        _pointsScoreText.y = 10;
        _pointsScoreText.width = 48;
        _pointsScoreText.selectable = false;
        _pointsPanel.addChild(_pointsScoreText);

        var lblBest = new TextField();
        lblBest.defaultTextFormat = new TextFormat("_sans", 17, 0xF9B219, true);
        lblBest.text = "best";
        lblBest.x = 14;
        lblBest.y = 40;
        lblBest.selectable = false;
        _pointsPanel.addChild(lblBest);

        _bestScoreText = new TextField();
        _bestScoreText.defaultTextFormat = new TextFormat("_sans", 16, 0xF9B219, true, null, null, null, null, TextFormatAlign.CENTER);
        _bestScoreText.text = "0";
        _bestScoreText.x = 105;
        _bestScoreText.y = 42;
        _bestScoreText.width = 48;
        _bestScoreText.selectable = false;
        _pointsPanel.addChild(_bestScoreText);

        _pointsPanel.x = 15;
        _pointsPanel.y = 15;

        // ==================== 2. 右上角 ENERGY / STAGE 科技感能量槽 ====================
        _energyPanel = new Sprite();
        hudContainer.addChild(_energyPanel);

        var eg = _energyPanel.graphics;
        eg.lineStyle(3, 0x1E5B5B, 1.0, true, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
        eg.beginFill(0x133946, 0.88);
        eg.moveTo(25, 0);
        eg.lineTo(165, 0);
        eg.lineTo(165, 78);
        eg.lineTo(0, 78);
        eg.lineTo(25, 0);
        eg.endFill();

        eg.lineStyle(2, 0x00FF88, 1.0);
        eg.beginFill(0x008844, 1.0);
        eg.drawRoundRect(28, 14, 16, 48, 8, 8);
        eg.endFill();
        eg.lineStyle(0, 0, 0);
        eg.beginFill(0x00FF88, 1.0);
        eg.drawRect(26, 22, 20, 4);
        eg.drawRect(26, 36, 20, 4);
        eg.drawRect(26, 50, 20, 4);
        eg.endFill();

        var lblEnergy = new TextField();
        lblEnergy.defaultTextFormat = new TextFormat("_sans", 17, 0x00E588, true);
        lblEnergy.text = "energy";
        lblEnergy.x = 60;
        lblEnergy.y = 6;
        lblEnergy.selectable = false;
        _energyPanel.addChild(lblEnergy);

        _energyCountText = new TextField();
        _energyCountText.defaultTextFormat = new TextFormat("_sans", 20, 0x33FFFF, true);
        _energyCountText.text = "0/3";
        _energyCountText.x = 75;
        _energyCountText.y = 28;
        _energyCountText.selectable = false;
        _energyPanel.addChild(_energyCountText);

        _stageLevelText = new TextField();
        _stageLevelText.defaultTextFormat = new TextFormat("_sans", 13, 0xFFDF33, true);
        _stageLevelText.text = "STAGE 1";
        _stageLevelText.x = 60;
        _stageLevelText.y = 52;
        _stageLevelText.selectable = false;
        _energyPanel.addChild(_stageLevelText);

        _energyPanel.x = 800 - 180;
        _energyPanel.y = 15;

        // ==================== 3. 开场说明大弹窗 (INSTRUCTIONS / CONTROLS) ====================
        _instructionsModal = new Sprite();
        hudContainer.addChild(_instructionsModal);

        var mw:Float = 480;
        var mh:Float = 330;
        var mg = _instructionsModal.graphics;

        mg.lineStyle(4, 0x00FFFF, 1.0);
        mg.beginFill(0x18BEE4, 0.96);
        mg.drawRoundRect(-mw * 0.5, -mh * 0.5, mw, mh, 20, 20);
        mg.endFill();

        mg.lineStyle(0, 0, 0);
        mg.beginFill(0xF7B519, 1.0);
        mg.drawRect(-mw * 0.5 + 4, -mh * 0.5 + 16, mw - 8, 36);
        mg.endFill();

        var titleFormat = new TextFormat("_sans", 22, 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        var tfInstructions = new TextField();
        tfInstructions.defaultTextFormat = titleFormat;
        tfInstructions.text = "INSTRUCTIONS";
        tfInstructions.x = -mw * 0.5;
        tfInstructions.y = -mh * 0.5 + 18;
        tfInstructions.width = mw * 0.5;
        tfInstructions.selectable = false;
        _instructionsModal.addChild(tfInstructions);

        var tfControls = new TextField();
        tfControls.defaultTextFormat = titleFormat;
        tfControls.text = "CONTROLS";
        tfControls.x = 0;
        tfControls.y = -mh * 0.5 + 18;
        tfControls.width = mw * 0.5;
        tfControls.selectable = false;
        _instructionsModal.addChild(tfControls);

        var goldFormat = new TextFormat("_sans", 15, 0xFFB71E, true, null, null, null, null, TextFormatAlign.CENTER);

        var lblPick = new TextField();
        lblPick.defaultTextFormat = goldFormat;
        lblPick.text = "PICK UP 3 ENERGY";
        lblPick.x = -mw * 0.5;
        lblPick.y = -mh * 0.5 + 68;
        lblPick.width = mw * 0.5;
        lblPick.selectable = false;
        _instructionsModal.addChild(lblPick);

        mg.lineStyle(2, 0x003311, 1.0);
        mg.beginFill(0x00FF66, 1.0);
        mg.drawRoundRect(-135, -mh * 0.5 + 98, 22, 44, 10, 10);
        mg.endFill();
        mg.beginFill(0x004411, 1.0);
        mg.drawRect(-138, -mh * 0.5 + 108, 28, 5);
        mg.drawRect(-138, -mh * 0.5 + 124, 28, 5);
        mg.endFill();

        var lblDestroy = new TextField();
        lblDestroy.defaultTextFormat = goldFormat;
        lblDestroy.text = "JUMP TO DESTROY";
        lblDestroy.x = -mw * 0.5;
        lblDestroy.y = -mh * 0.5 + 160;
        lblDestroy.width = mw * 0.5;
        lblDestroy.selectable = false;
        _instructionsModal.addChild(lblDestroy);

        mg.lineStyle(2, 0x003388, 1.0);
        mg.beginFill(0x2288EE, 1.0);
        mg.drawEllipse(-145, -mh * 0.5 + 200, 42, 18);
        mg.endFill();
        mg.beginFill(0xFF5500, 1.0);
        mg.drawEllipse(-135, -mh * 0.5 + 196, 22, 14);
        mg.endFill();
        mg.beginFill(0xFF1100, 1.0);
        mg.drawCircle(-152, -mh * 0.5 + 200, 5);
        mg.drawCircle(-96, -mh * 0.5 + 200, 5);
        mg.drawCircle(-146, -mh * 0.5 + 224, 5);
        mg.drawCircle(-102, -mh * 0.5 + 224, 5);
        mg.endFill();

        var lblMove = new TextField();
        lblMove.defaultTextFormat = goldFormat;
        lblMove.text = "MOVE WITH";
        lblMove.x = 0;
        lblMove.y = -mh * 0.5 + 68;
        lblMove.width = mw * 0.5;
        lblMove.selectable = false;
        _instructionsModal.addChild(lblMove);

        mg.lineStyle(2, 0x888888, 1.0);
        mg.beginFill(0xEEEEEE, 1.0);
        mg.drawRoundRect(70, -mh * 0.5 + 102, 34, 30, 6, 6);
        mg.drawRoundRect(115, -mh * 0.5 + 102, 34, 30, 6, 6);
        mg.endFill();

        var arrowFormat = new TextFormat("_sans", 16, 0x333333, true, null, null, null, null, TextFormatAlign.CENTER);
        var arrLeft = new TextField();
        arrLeft.defaultTextFormat = arrowFormat;
        arrLeft.text = "◄";
        arrLeft.x = 70;
        arrLeft.y = -mh * 0.5 + 106;
        arrLeft.width = 34;
        arrLeft.selectable = false;
        _instructionsModal.addChild(arrLeft);

        var arrRight = new TextField();
        arrRight.defaultTextFormat = arrowFormat;
        arrRight.text = "►";
        arrRight.x = 115;
        arrRight.y = -mh * 0.5 + 106;
        arrRight.width = 34;
        arrRight.selectable = false;
        _instructionsModal.addChild(arrRight);

        var lblJump = new TextField();
        lblJump.defaultTextFormat = goldFormat;
        lblJump.text = "JUMP WITH";
        lblJump.x = 0;
        lblJump.y = -mh * 0.5 + 160;
        lblJump.width = mw * 0.5;
        lblJump.selectable = false;
        _instructionsModal.addChild(lblJump);

        mg.lineStyle(2, 0x888888, 1.0);
        mg.beginFill(0xEEEEEE, 1.0);
        mg.drawRoundRect(35, -mh * 0.5 + 195, 150, 32, 6, 6);
        mg.endFill();

        var spaceFormat = new TextFormat("_sans", 12, 0x666666, true, null, null, null, null, TextFormatAlign.CENTER);
        var tfSpace = new TextField();
        tfSpace.defaultTextFormat = spaceFormat;
        tfSpace.text = "SPACEBAR";
        tfSpace.x = 35;
        tfSpace.y = -mh * 0.5 + 201;
        tfSpace.width = 150;
        tfSpace.selectable = false;
        _instructionsModal.addChild(tfSpace);

        var speedTuneFormat = new TextFormat("_sans", 11, 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        var tfSpeedTune = new TextField();
        tfSpeedTune.defaultTextFormat = speedTuneFormat;
        tfSpeedTune.text = "ADJUST SPEED: [-] SLOWER / [+] FASTER";
        tfSpeedTune.x = -mw * 0.5;
        tfSpeedTune.y = -mh * 0.5 + 236;
        tfSpeedTune.width = mw;
        tfSpeedTune.selectable = false;
        _instructionsModal.addChild(tfSpeedTune);

        mg.lineStyle(3, 0x00FFFF, 1.0);
        mg.beginFill(0x00D9FF, 1.0);
        mg.moveTo(-160, mh * 0.5 - 12);
        mg.lineTo(160, mh * 0.5 - 12);
        mg.lineTo(140, mh * 0.5 + 32);
        mg.lineTo(-140, mh * 0.5 + 32);
        mg.lineTo(-160, mh * 0.5 - 12);
        mg.endFill();

        var startFormat = new TextFormat("_sans", 16, 0xFFB71E, true, null, null, null, null, TextFormatAlign.CENTER);
        var tfStart = new TextField();
        tfStart.defaultTextFormat = startFormat;
        tfStart.text = "press spacebar to start";
        tfStart.x = -150;
        tfStart.y = mh * 0.5 + 3;
        tfStart.width = 300;
        tfStart.selectable = false;
        _instructionsModal.addChild(tfStart);

        _instructionsModal.x = 400;
        _instructionsModal.y = 230;
        _instructionsModal.buttonMode = true;
        _instructionsModal.addEventListener(MouseEvent.CLICK, function(_) {
            if (state == "start") {
                startRun();
            }
        });

        // ==================== 4. 游戏结束得分弹窗 ====================
        _scoreModal = new Sprite();
        hudContainer.addChild(_scoreModal);

        var sg = _scoreModal.graphics;
        sg.lineStyle(3, 0x00FFFF, 1.0);
        sg.beginFill(0x27C9F2, 0.95);
        sg.drawRoundRect(-160, -52, 320, 104, 14, 14);
        sg.endFill();

        var titleFormat = new TextFormat("_sans", 16, 0x0C3E6B, true, null, null, null, null, TextFormatAlign.CENTER);
        var tfTitle = new TextField();
        tfTitle.defaultTextFormat = titleFormat;
        tfTitle.text = "★ GAME OVER - FINAL SCORE ★";
        tfTitle.x = -160;
        tfTitle.y = -44;
        tfTitle.width = 320;
        tfTitle.selectable = false;
        _scoreModal.addChild(tfTitle);

        _finalScoreText = new TextField();
        _finalScoreText.defaultTextFormat = new TextFormat("_sans", 38, 0x1B2C68, true, null, null, null, null, TextFormatAlign.CENTER);
        _finalScoreText.text = "0";
        _finalScoreText.x = -160;
        _finalScoreText.y = -18;
        _finalScoreText.width = 320;
        _finalScoreText.selectable = false;
        _scoreModal.addChild(_finalScoreText);

        var restartTip = new TextField();
        restartTip.defaultTextFormat = new TextFormat("_sans", 13, 0x052B4D, true, null, null, null, null, TextFormatAlign.CENTER);
        restartTip.text = "PRESS SPACE OR CLICK TO RETRY ▶";
        restartTip.x = -160;
        restartTip.y = 26;
        restartTip.width = 320;
        restartTip.selectable = false;
        _scoreModal.addChild(restartTip);

        _scoreModal.x = 400;
        _scoreModal.y = 225;
        _scoreModal.visible = false;
        _scoreModal.buttonMode = true;
        _scoreModal.addEventListener(MouseEvent.CLICK, function(_) {
            if ((state == "die" || state == "fan") && _scoreModal.visible) {
                startRun();
            }
        });
        
        // ==================== 5. 通关加速庆典大横幅 (STAGE CLEARED / SPEED UP) ====================
        _speedBanner = new Sprite();
        hudContainer.addChild(_speedBanner);

        var bw:Float = 380;
        var bh:Float = 190;
        var bg2 = _speedBanner.graphics;

        // 1. 外层柔和霓虹青蓝微光晕层 (矢量硬加速，0 CPU 滤镜模糊开销)
        bg2.lineStyle(8, 0x00E5FF, 0.35);
        bg2.drawRoundRect(-bw * 0.5 - 3, -bh * 0.5 - 3, bw + 6, bh + 6, 22, 22);
        
        // 2. 中层高亮青色边框
        bg2.lineStyle(4, 0x00FFFF, 0.85);
        bg2.drawRoundRect(-bw * 0.5 - 1, -bh * 0.5 - 1, bw + 2, bh + 2, 21, 21);
        
        // 3. 科技深蓝主体背景
        bg2.lineStyle(2, 0x00FFFF, 1.0);
        bg2.beginFill(0x0A223D, 0.96);
        bg2.drawRoundRect(-bw * 0.5, -bh * 0.5, bw, bh, 20, 20);
        bg2.endFill();

        // 4. 内层金色科技条纹
        bg2.lineStyle(2, 0xFFDF33, 0.9);
        bg2.drawRoundRect(-bw * 0.5 + 6, -bh * 0.5 + 6, bw - 12, bh - 12, 16, 16);

        // 按钮高亮底框
        bg2.lineStyle(2, 0x00FFFF, 1.0);
        bg2.beginFill(0x0077B3, 0.92);
        bg2.drawRoundRect(-145, bh * 0.5 - 42, 290, 34, 10, 10);
        bg2.endFill();

        _stageClearTitle = new TextField();
        _stageClearTitle.defaultTextFormat = new TextFormat("_sans", 22, 0xFFDF33, true, null, null, null, null, TextFormatAlign.CENTER);
        _stageClearTitle.text = "★ STAGE 1 CLEARED! ★";
        _stageClearTitle.x = -bw * 0.5;
        _stageClearTitle.y = -bh * 0.5 + 14;
        _stageClearTitle.width = bw;
        _stageClearTitle.selectable = false;
        _speedBanner.addChild(_stageClearTitle);

        _speedValueText = new TextField();
        _speedValueText.defaultTextFormat = new TextFormat("_sans", 34, 0x00FFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        _speedValueText.text = "SPEED x2";
        _speedValueText.x = -bw * 0.5;
        _speedValueText.y = -bh * 0.5 + 44;
        _speedValueText.width = bw;
        _speedValueText.selectable = false;
        _speedBanner.addChild(_speedValueText);

        _bonusScoreText = new TextField();
        _bonusScoreText.defaultTextFormat = new TextFormat("_sans", 16, 0x5CD620, true, null, null, null, null, TextFormatAlign.CENTER);
        _bonusScoreText.text = "+3000 BONUS PTS!";
        _bonusScoreText.x = -bw * 0.5;
        _bonusScoreText.y = -bh * 0.5 + 86;
        _bonusScoreText.width = bw;
        _bonusScoreText.selectable = false;
        _speedBanner.addChild(_bonusScoreText);

        _continueBtnText = new TextField();
        _continueBtnText.defaultTextFormat = new TextFormat("_sans", 13, 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        _continueBtnText.text = "PRESS SPACEBAR FOR STAGE 2 ▶";
        _continueBtnText.x = -145;
        _continueBtnText.y = bh * 0.5 - 34;
        _continueBtnText.width = 290;
        _continueBtnText.selectable = false;
        _speedBanner.addChild(_continueBtnText);

        _speedBanner.x = 400;
        _speedBanner.y = 225;
        _speedBanner.visible = false;
        _speedBanner.buttonMode = true;
        _speedBanner.addEventListener(MouseEvent.CLICK, function(_) {
            if (state == "energy") {
                nextStage();
            }
        });
        
        // ==================== 6. 初始加载遮罩 ====================
        loadingOverlay = new Sprite();
        var bg = new Shape();
        bg.graphics.beginFill(0x051838, 1.0);
        bg.graphics.drawRect(0, 0, 800, 450);
        bg.graphics.endFill();
        loadingOverlay.addChild(bg);
        
        var title = createLabel(200, 160, 400, "YELLOW PLANET 3D", 0xFFD83B, 28, TextFormatAlign.CENTER);
        loadingOverlay.addChild(title);
        
        loadingText = createLabel(200, 210, 400, "LOADING PLANET WORLD ASSETS...", 0x33FFFF, 14, TextFormatAlign.CENTER);
        loadingOverlay.addChild(loadingText);
        
        layoutGUI();
    }
    
    private function onStageResize(e:Event = null):Void 
    {
        layoutGUI();
    }
    
    private function layoutGUI():Void 
    {
        var sw:Float = (stage != null && stage.stageWidth > 0) ? stage.stageWidth : 800.0;
        var sh:Float = (stage != null && stage.stageHeight > 0) ? stage.stageHeight : 450.0;

        if (_pointsPanel != null) {
            _pointsPanel.x = 15;
            _pointsPanel.y = 15;
        }

        if (_energyPanel != null) {
            _energyPanel.x = sw - 180;
            _energyPanel.y = 15;
        }

        if (_instructionsModal != null) {
            _instructionsModal.x = sw * 0.5;
            _instructionsModal.y = sh * 0.5;
        }

        if (_scoreModal != null) {
            _scoreModal.x = sw * 0.5;
            _scoreModal.y = sh * 0.5;
        }

        if (_speedBanner != null) {
            _speedBanner.x = sw * 0.5;
            _speedBanner.y = sh * 0.5;
        }

        if (loadingOverlay != null && loadingOverlay.numChildren > 0) {
            var bgShape = loadingOverlay.getChildAt(0);
            if (Std.isOfType(bgShape, Shape)) {
                var s:Shape = cast bgShape;
                s.graphics.clear();
                s.graphics.beginFill(0x051838, 1.0);
                s.graphics.drawRect(0, 0, sw, sh);
                s.graphics.endFill();
            }
            if (loadingOverlay.numChildren > 1) {
                var title = loadingOverlay.getChildAt(1);
                title.x = (sw - 400) * 0.5;
                title.y = sh * 0.5 - 65;
            }
            if (loadingText != null) {
                loadingText.x = (sw - 400) * 0.5;
                loadingText.y = sh * 0.5 - 15;
            }
        }
    }
    
    private function createLabel(x:Float, y:Float, w:Float, text:String, color:Int, size:Int = 14, align:TextFormatAlign = null):TextField 
    {
        var tf = new TextField();
        var fmt = new TextFormat("_sans", size, color, true);
        if (align != null) fmt.align = align;
        tf.defaultTextFormat = fmt;
        tf.text = text;
        tf.selectable = false;
        tf.x = x;
        tf.y = y;
        tf.width = w;
        tf.height = 36;
        return tf;
    }
    
    private function progressEvent(e:Event):Void 
    {
        if (loadingText != null) {
            var pct = Math.floor(scene.loadProgress * 100);
            loadingText.text = "LOADING PLANET WORLD ASSETS: " + pct + "%";
        }
    }
    
    private function getAssetBmd(name:String):openfl.display.BitmapData 
    {
        if (openfl.utils.Assets.exists(name)) return openfl.utils.Assets.getBitmapData(name);
        if (openfl.utils.Assets.exists("./" + name)) return openfl.utils.Assets.getBitmapData("./" + name);
        if (openfl.utils.Assets.exists("assets/" + name)) return openfl.utils.Assets.getBitmapData("assets/" + name);
        return null;
    }
    
    private function completeEvent(e:Event):Void 
    {
        if (isLoaded) return;
        isLoaded = true;
        
        if (loadingText != null) {
            loadingText.text = "OPTIMIZING ASTRONAUT 3D ANIMATION...";
        }
        
        sky = planet.getChildByName("sky");
        if (sky != null && Std.isOfType(sky, Mesh3D)) {
            sky.visible = true;
            var skyMesh:Mesh3D = cast sky;
            var spaceBmd = getAssetBmd("Space.jpg");
            flare.system.DebugLog.log("[SKY-TEX] spaceBmd=" + (spaceBmd != null ? (spaceBmd.width + "x" + spaceBmd.height) : "null") + " surfs=" + skyMesh.surfaces.length);
            if (spaceBmd != null) {
                var skyTex = new Texture3D(spaceBmd);
                var skyShader = new Shader3D("sky_unlit", [new TextureMapFilter(skyTex)]);
                skyShader.twoSided = true;
                skyShader.depthWrite = false;
                skyMesh.materials = [skyShader];
            }
        }
        
        var floor = planet.getChildByName("floor");
        if (floor != null && Std.isOfType(floor, Mesh3D)) {
            var floorMesh:Mesh3D = cast floor;
            var floorTexNames = [
                "planet_base2.jpg",
                "planet_base1.jpg",
                "planet_craters.jpg",
                "square01.jpg",
                "square02.jpg",
                "square03.jpg",
                "square04.jpg"
            ];
            for (i in 0...floorMesh.surfaces.length) {
                var texName = (i < floorTexNames.length) ? floorTexNames[i] : "planet_base1.jpg";
                var bmd = getAssetBmd(texName);
                if (bmd != null) {
                    var tex = new Texture3D(bmd);
                    var fm = new Shader3D("floor_mat_" + i, [new TextureMapFilter(tex), new LightFilter()]);
                    fm.twoSided = true;
                    if (i < floorMesh.materials.length) {
                        floorMesh.materials[i] = fm;
                    } else {
                        floorMesh.materials.push(fm);
                    }
                }
            }
        }
        
        // 彻底还原地雷 (mine) 与核心 (enemy) 的正统原版材质：红色爆炸警戒核心 + 蓝色三叉悬臂 + 金属底盘
        var mineBaseBmd = getAssetBmd("mine_base.jpg");
        var mineRedBmd = getAssetBmd("mine_red.jpg");
        var mineBlueBmd = getAssetBmd("mine_blue.jpg");
        
        var texMineBase = (mineBaseBmd != null) ? new Texture3D(mineBaseBmd) : null;
        var texMineRed = (mineRedBmd != null) ? new Texture3D(mineRedBmd) : null;
        var texMineBlue = (mineBlueBmd != null) ? new Texture3D(mineBlueBmd) : null;

        var matMineBase = (texMineBase != null) ? new Shader3D("mine_base_mat", [new TextureMapFilter(texMineBase), new LightFilter()]) : null;
        var matMineRed = (texMineRed != null) ? new Shader3D("mine_red_mat", [new TextureMapFilter(texMineRed), new LightFilter()]) : null;
        var matMineBlue = (texMineBlue != null) ? new Shader3D("mine_blue_mat", [new TextureMapFilter(texMineBlue), new LightFilter()]) : null;

        planet.forEach(function(p:Pivot3D) {
            if (Std.isOfType(p, Mesh3D)) {
                var m:Mesh3D = cast p;
                if (m.name == "mine" || StringTools.startsWith(m.name, "mine_")) {
                    if (matMineBase != null && matMineRed != null && m.surfaces.length >= 2) {
                        m.materials = [matMineBase, matMineRed];
                    }
                } else if (m.name == "enemy" || StringTools.startsWith(m.name, "enemy_")) {
                    if (matMineRed != null && matMineBlue != null && m.surfaces.length >= 2) {
                        m.materials = [matMineRed, matMineBlue];
                    }
                }
            }
        });

        // 能量模型材质
        var energyShader = cast(energy.getMaterialByName("energy"), Shader3D);
        if (energyShader != null && energyShader.filters != null && energyShader.filters.length > 1) {
            if (Std.isOfType(energyShader.filters[1], ColorFilter)) {
                energyColorFilter = cast(energyShader.filters[1], ColorFilter);
            }
        }
        
        var fireObj = scene.getChildByName("fire");
        if (fireObj != null && Std.isOfType(fireObj, Particles3D)) {
            fire = cast(fireObj, Particles3D);
            fire.parent = astronaut;
            fire.pause();
        }
        
        // 头部材质叠加半透明面罩高光
        var head = cast(astronaut.getMaterialByName("head"), Shader3D);
        if (head != null) {
            head.sourceFactor = Context3DBlendFactor.ONE;
            head.destFactor = Context3DBlendFactor.ONE;
        }

        // 阴影材质开启半透明混合与关闭深度写入
        if (shadow != null) {
            shadow.forEach(function(p:Pivot3D) {
                if (Std.isOfType(p, Mesh3D)) {
                    var m:Mesh3D = cast p;
                    for (mat in m.materials) {
                        if (mat != null) {
                            mat.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
                            mat.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
                            mat.depthWrite = false;
                        }
                    }
                }
            });
        }

        // 能量装置底部的阴影面片同样开启半透明混合与关闭深度写入 (优先使用 RGBA 优化贴图)
        if (energy != null) {
            energy.forEach(function(p:Pivot3D) {
                if (Std.isOfType(p, Mesh3D)) {
                    var m:Mesh3D = cast p;
                    if (m.name == "shadow" || (m.materials.length > 0 && m.materials[0].name.toLowerCase().indexOf("108") != -1)) {
                        var shadowBmd = getAssetBmd("shadow_energy.png");
                        if (shadowBmd != null) {
                            var sTex = new Texture3D(shadowBmd);
                            var sShader = new Shader3D("energy_shadow_mat", [new TextureMapFilter(sTex)]);
                            sShader.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
                            sShader.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
                            sShader.depthWrite = false;
                            sShader.twoSided = true;
                            m.materials = [sShader];
                        } else {
                            for (mat in m.materials) {
                                if (mat != null) {
                                    mat.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
                                    mat.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
                                    mat.depthWrite = false;
                                }
                            }
                        }
                    }
                }
            });
        }
        
        // 角色动作序列标签（原版 Flash: run=0~22, jump=22~65）
        astronaut.addLabel(new Label3D("run", 0, 22));
        astronaut.addLabel(new Label3D("jump", 22, 65));
        
        flare.system.DebugLog.log("[DEBUG] completeEvent: Labels added, checking astronaut modifier...");
        
        // 预烘焙跑步与跳跃踩雷全部 66 帧，全程锁定满帧 60 FPS！
        astronaut.forEach(function(p:Pivot3D) {
            if (Std.isOfType(p, Mesh3D)) {
                var m:Mesh3D = cast p;
                if (m.modifier != null && Std.isOfType(m.modifier, flare.modifiers.SkinModifier)) {
                    var sMod:flare.modifiers.SkinModifier = cast m.modifier;
                    sMod.prebakeAnimation();
                }
            }
        });
        
        // 玩家容器
        container = new Pivot3D("player_container");
        container.addChild(astronaut);
        container.addChild(shadow);
        scene.addChild(container);
        
        // 地表射线吸附
        ray = new RayCollision();
        var floor = planet.getChildByName("floor");
        if (floor != null) {
            ray.addCollisionWith(floor, false);
        } else {
            ray.addCollisionWith(planet, true);
        }
        
        // 障碍物碰撞检测 (完全对标原版 AS3 物理规格：半径 3.0，中心偏移高度 3.0，彻底消除陷入地面或穿透墙体)
        collisions = new SphereCollision(container, 3.0, new Vector3D(0, 3.0, 0));
        
        // 预加载风扇离子烟尘通用纹理
        var smokeBmd = getAssetBmd("smoke.png");
        if (smokeBmd != null) {
            _ionSmokeTexture = new Texture3D(smokeBmd);
        }

        // 扫描行星节点
        planet.forEach(setupScene);
        
        startGame();
        
        var loadTotal = Lib.getTimer() - _gameStartTime;
        flare.system.DebugLog.log("[PERF] >>> Yellow Planet is READY! Total startup & asset load time: " + loadTotal + " ms <<<");
        
        lastTime = Lib.getTimer();
        _fpsLastTime = Lib.getTimer();
        _fpsCount = 0;
        scene.resume();
        scene.addEventListener(Scene3D.UPDATE_EVENT, updateEvent);
        
        if (loadingOverlay != null && contains(loadingOverlay)) {
            removeChild(loadingOverlay);
        }
    }
    
    private function setupScene(pivot:Pivot3D):Void 
    {
        var name = pivot.name;
        if (name == "fan" || StringTools.startsWith(name, "fan_")) {
            pivot.updateWorldMatrix();
            var fPos = pivot.getPosition(false);
            var sx = pivot.scaleX;
            var fanRadius = Math.max(11.5, (sx > 0.05 ? sx : 1.0) * 16.0);
            flare.system.DebugLog.log("[FAN-INFO] name=" + name + " sx=" + sx + " pos=" + fPos.x + "," + fPos.y + "," + fPos.z);
            pivot.userData = {
                speed: Math.random() * 15 + 15,
                posX: fPos.x,
                posY: fPos.y,
                posZ: fPos.z,
                radius: fanRadius,
                radiusSq: fanRadius * fanRadius
            };
            fan.push(pivot);
            
            // 为全场最大号风扇注入高能离子烟尘特效 (最大号风扇: sx > 1.3，即极地超大通风扇，全场唯一)
            if (sx > 1.3 && _ionSmokeTexture != null) {
                var particleCount = 24;
                var ionSmoke = new flare.core.IonSmokeParticles("ion_smoke_" + fan.length, particleCount, _ionSmokeTexture, 0x00E5FF, 0.85);
                var fUp = pivot.getUp(false);
                ionSmoke.setEmitter(fPos, fUp, fanRadius * 0.65, sx);
                scene.addChild(ionSmoke);
                _ionSmokeEmitters.push(ionSmoke);
                flare.system.DebugLog.log("[ION-SMOKE] Added ion smoke plume to unique largest fan: name=" + name + " sx=" + sx + " count=" + particleCount + " radius=" + fanRadius);
            }
        } else if (name == "mine" || StringTools.startsWith(name, "mine_")) {
            pivot.userData = {
                speed: Math.random() * -5 - 5,
                frequency: Math.random() * 500 + 500
            };
            mines.push(pivot);
        } else if (name == "obstacle" || StringTools.startsWith(name, "obstacle_")) {
            if (collisions != null) {
                collisions.addCollisionWith(pivot, false);
            }
        } else if (name == "point" || StringTools.startsWith(name, "point_")) {
            points.push(pivot);
        }
    }
    
    public function startGame():Void 
    {
        var startPoint = planet.getChildByName("start");
        if (startPoint != null) {
            container.copyTransformFrom(startPoint);
        } else {
            container.setPosition(47.075, 42.356, -80.147);
            container.setNormalOrientation(new Vector3D(0.426, 0.383, -0.82));
        }
        
        container.gotoAndPlay("run");
        container.visible = true;
        if (shadow != null) shadow.visible = true;
        
        state = "start";
        speed = 0.32;
        speedCounter = 1;
        jumpValue = 0;
        energyCount = 0;
        _energyCooldown = 0;
        astronaut.y = 0;
        shakeFactor = 0;
        if (astronaut != null) astronaut.animationSpeed = 0.55;
        
        _instructionsModal.visible = true;
        _scoreModal.visible = false;
        if (_speedBanner != null) _speedBanner.visible = false;
        
        if (collisions != null) collisions.reset();
        
        // 贴合地面
        snapToFloor(1.0);
        
        // 宏大球形俯瞰追踪机位
        snapCameraToStart();
        
        // 智能前向刷新开局首个绿色能量点 (位于玩家前进路径前方)
        selectNextEnergyPoint();
    }
    
    /**
     * 智能前向能量刷新算法 (优先在玩家奔跑路径的前方视野 35~110 码范围内寻找点位)
     */
    private function selectNextEnergyPoint():Void 
    {
        if (energy == null || points.length == 0) return;
        if (points.length <= 1) {
            energyIndex = 0;
            energy.copyTransformFrom(points[0]);
            return;
        }

        var cPos = container.getPosition(false, _cTempVec);
        var cDir = container.getDir(false);
        var bestCandidates:Array<Int> = [];
        var acceptableCandidates:Array<Int> = [];

        for (i in 0...points.length) {
            if (i == energyIndex && points.length > 1) continue;
            var p = points[i];
            p.updateWorldMatrix();
            var pPos = p.getPosition(false);
            var dx = pPos.x - cPos.x;
            var dy = pPos.y - cPos.y;
            var dz = pPos.z - cPos.z;
            var dist = Math.sqrt(dx * dx + dy * dy + dz * dz);

            // 位于适中视距范围内 (30 ~ 115 码)
            if (dist >= 30.0 && dist <= 115.0) {
                var dot = (dx * cDir.x + dy * cDir.y + dz * cDir.z) / dist;
                if (dot > 0.05) {
                    // 位于玩家前进方向的前方锥形视野内
                    bestCandidates.push(i);
                } else if (dot > -0.35) {
                    // 侧前方半球视野
                    acceptableCandidates.push(i);
                }
            }
        }

        if (bestCandidates.length > 0) {
            energyIndex = bestCandidates[Std.int(Math.random() * bestCandidates.length)];
        } else if (acceptableCandidates.length > 0) {
            energyIndex = acceptableCandidates[Std.int(Math.random() * acceptableCandidates.length)];
        } else {
            // 兜底：纯随机
            var oldIdx = energyIndex;
            while (points.length > 1 && energyIndex == oldIdx) {
                energyIndex = Std.int(Math.random() * points.length);
            }
        }

        var curPoint = points[energyIndex % points.length];
        energy.copyTransformFrom(curPoint);
        flare.system.DebugLog.log("[ENERGY-SPAWN] Smart spawned energy at point idx=" + energyIndex + " (" + bestCandidates.length + " candidates)");
    }
    
    private function showStageClearBanner():Void 
    {
        _stageClearTitle.text = "★ STAGE " + speedCounter + " CLEARED! ★";
        _speedValueText.text = "STAGE " + (speedCounter + 1);
        _bonusScoreText.text = "SPEED UP!";
        _continueBtnText.text = "PRESS SPACEBAR FOR STAGE " + (speedCounter + 1) + " ▶";
        if (_speedBanner != null) _speedBanner.visible = true;
        shakeFactor = 3.5;
    }
    
    private function nextStage():Void 
    {
        energyCount = 0;
        _energyCooldown = 30;
        speedCounter++;
        speed += 0.05; // 升级关卡适度平稳提速 (STAGE 1: 0.32 -> STAGE 2: 0.37)
        state = "run";
        if (_speedBanner != null) _speedBanner.visible = false;
        container.gotoAndPlay("run");
        if (astronaut != null) astronaut.animationSpeed = 0.55 + (speed - 0.32) * 0.8;
    }
    
    private function spawnPowerBurst():Void 
    {
        var colors = [0xFFDF33, 0x00FFFF, 0xFF44AA, 0x5CD620, 0xFFFFFF];
        var cx = (stage != null && stage.stageWidth > 0 ? stage.stageWidth * 0.5 : 400.0);
        var cy = (stage != null && stage.stageHeight > 0 ? stage.stageHeight * 0.42 : 200.0);
        if (_burstX == null) return;
        for (i in 0...25) {
            _burstX[i] = cx;
            _burstY[i] = cy;
            var angle = Math.random() * Math.PI * 2.0;
            var spd = 4.0 + Math.random() * 8.0;
            _burstVx[i] = Math.cos(angle) * spd;
            _burstVy[i] = Math.sin(angle) * spd;
            _burstLife[i] = 1.0;
            _burstSize[i] = 4.0 + Math.random() * 5.0;
            _burstColor[i] = colors[i % colors.length];
        }
        _burstActive = true;
    }

    private function updatePowerBurst(dtScale:Float):Void 
    {
        if (!_burstActive || _powerBurstCanvas == null) return;
        var g = _powerBurstCanvas.graphics;
        g.clear();
        var anyAlive = false;
        for (i in 0...25) {
            if (_burstLife[i] > 0.0) {
                _burstLife[i] -= 0.025 * dtScale;
                if (_burstLife[i] > 0.0) {
                    anyAlive = true;
                    _burstX[i] += _burstVx[i] * dtScale;
                    _burstY[i] += _burstVy[i] * dtScale;
                    _burstVy[i] += 0.28 * dtScale; // 粒子重力轻柔下落
                    var alpha = Math.max(0.0, _burstLife[i]);
                    g.beginFill(_burstColor[i], alpha);
                    var s = _burstSize[i];
                    g.drawRect(_burstX[i] - s * 0.5, _burstY[i] - s * 0.5, s, s);
                    g.endFill();
                }
            }
        }
        if (!anyAlive) {
            _burstActive = false;
            g.clear();
        }
    }
    
    private function snapToFloor(smooth:Float = 0.35):Void 
    {
        container.getPosition(false, _pPosVec);
        var dist = _pPosVec.length;
        if (dist > 0.0001) {
            var invDist = 1.0 / dist;
            _floorNormVec.x = _pPosVec.x * invDist;
            _floorNormVec.y = _pPosVec.y * invDist;
            _floorNormVec.z = _pPosVec.z * invDist;
            container.setPosition(_floorNormVec.x * 102.15, _floorNormVec.y * 102.15, _floorNormVec.z * 102.15);
            container.setNormalOrientation(_floorNormVec, smooth);
        }
    }
    
    private function snapCameraToStart():Void 
    {
        container.updateWorldMatrix();
        astronaut.updateWorldMatrix();
        
        Pivot3DUtils.setPositionWithReference(scene.camera, 0, 50 + speed * 25, -28, astronaut);
        astronaut.localToGlobal(_lookOffsetVec, _targetLookVec);
        container.getUp(false, _containerUpVec);
        scene.camera.lookAt(_targetLookVec.x, _targetLookVec.y, _targetLookVec.z, _containerUpVec);
    }
    
    private var _debugFrameCount:Int = 0;
    
    private function updateCamera(dtScale:Float = 1.0):Void 
    {
        container.updateWorldMatrix();
        astronaut.updateWorldMatrix();
        
        var smooth = Math.min(1.0, 0.12 * dtScale);
        Pivot3DUtils.setPositionWithReference(scene.camera, 0, 50 + speed * 25, -28, astronaut, smooth);
        astronaut.localToGlobal(_lookOffsetVec, _targetLookVec);
        container.getUp(false, _containerUpVec);
        scene.camera.lookAt(_targetLookVec.x, _targetLookVec.y, _targetLookVec.z, _containerUpVec, smooth * 0.6);
        
        if (shakeFactor > 0.1) {
            scene.camera.x += (Math.random() - 0.5) * shakeFactor;
            scene.camera.y += (Math.random() - 0.5) * shakeFactor;
            scene.camera.z += (Math.random() - 0.5) * shakeFactor;
            shakeFactor *= 0.9;
        }
    }
    
    private function updateEvent(e:Event):Void 
    {
        if (!isLoaded) return;
        
        var curTime = Lib.getTimer();
        #if html5
        // 高刷显示器（144Hz、165Hz 等）限帧平滑稳定在 60 FPS，彻底解决超速奔跑问题
        var elapsed = curTime - _lastUpdateMs;
        if (elapsed < 14.5) {
            return;
        }
        _lastUpdateMs = curTime;
        #end
        
        var dt = (curTime - lastTime) / 1000.0;
        lastTime = curTime;
        var dtScale = Math.min(2.0, Math.max(0.2, dt / 0.016666));
        
        // 1. 游戏逻辑
        gameLogics(dtScale);
        
        // 2. 地表贴合 (Fan 弹射状态除外)
        if (state != "fan") {
            snapToFloor(0.1 * dtScale);
        }
        
        // 3. 障碍物碰撞滑动
        if (state == "run" || state == "jump") {
            if (collisions != null) collisions.slider();
        }
        
        // 4. 重力与垂直位移
        if (state == "run" || state == "jump") {
            jumpValue -= 0.3 * dtScale;
            astronaut.y += jumpValue * dtScale;
            
            if (astronaut.y <= 0) {
                astronaut.y = 0;
                jumpValue *= -0.7;
                if (Math.abs(jumpValue) < 0.2) {
                    jumpValue = 0;
                    if (state == "jump") {
                        state = "run";
                        container.gotoAndPlay("run");
                    }
                }
            }
            if (shadow != null) shadow.visible = true;
        } else if (state == "fan") {
            astronaut.y += jumpValue * dtScale;
            if (shadow != null) shadow.visible = (astronaut.y < 60);
        } else {
            astronaut.y = 0;
            jumpValue = 0;
            if (shadow != null) shadow.visible = true;
        }
        
        // 5. 机关与动态物体
        gameObjects(dtScale);
        
        // 6. 星空穹顶旋转
        if (sky != null) {
            sky.rotateX(0.08 * dtScale);
        }
        
        // 7. 第三人称平滑宏大俯瞰球体机位
        updateCamera(dtScale);
        
        // 8. 庆祝礼花粒子动画更新 (零 GC 单画布矢量渲染)
        if (_burstActive) {
            updatePowerBurst(dtScale);
        }
        
        // 9. 刷新 HUD 统计
        gameGUI();
        
        // 10. 精确 FPS 性能监测与分步耗时分析
        _fpsCount++;
        var curMs = Lib.getTimer();
        if (curMs - _fpsLastTime >= 1000) {
            var realFps = Math.round((_fpsCount * 1000.0) / (curMs - _fpsLastTime));
            flare.system.DebugLog.log("[PERF-FPS] FPS: " + realFps + " | DrawCalls: " + _lastReportedDrawCalls + " | Triangles: " + _lastReportedTriangles);
            flare.system.DebugLog.log("[PROF-BREAKDOWN] FPS: " + realFps + 
                " | Up:" + Math.round(flare.basic.Scene3D.profUpdate) + "ms" +
                " | Anim:" + Math.round(flare.basic.Scene3D.profAnim) + "ms" +
                " | Trans:" + Math.round(flare.basic.Scene3D.profTrans) + "ms" +
                " | Render:" + Math.round(flare.basic.Scene3D.profRender) + "ms" +
                " | Present:" + Math.round(flare.basic.Scene3D.profPresent) + "ms");
            flare.basic.Scene3D.profUpdate = 0;
            flare.basic.Scene3D.profAnim = 0;
            flare.basic.Scene3D.profTrans = 0;
            flare.basic.Scene3D.profRender = 0;
            flare.basic.Scene3D.profPresent = 0;
            _fpsCount = 0;
            _fpsLastTime = curMs;
        }
    }
    
    private function startRun():Void 
    {
        var startPoint = planet.getChildByName("start");
        if (startPoint != null) {
            container.copyTransformFrom(startPoint);
        } else {
            container.setPosition(47.075, 42.356, -80.147);
            container.setNormalOrientation(new Vector3D(0.426, 0.383, -0.82));
        }
        
        snapToFloor(1.0);
        snapCameraToStart();
        
        state = "run";
        _instructionsModal.visible = false;
        _scoreModal.visible = false;
        if (_speedBanner != null) _speedBanner.visible = false;
        
        container.gotoAndPlay("run");
        container.visible = true;
        if (shadow != null) shadow.visible = true;
        if (astronaut != null) {
            astronaut.animationSpeed = 0.55;
            astronaut.y = 0;
        }
        if (fire != null) fire.start();
        
        score = 0;
        speed = 0.32;
        speedCounter = 1;
        energyCount = 0;
        _energyCooldown = 0;
        jumpValue = 3.2;
        shakeFactor = 0;
        
        for (m in mines) {
            if (m != null) m.show();
        }
        
        if (collisions != null) collisions.reset();
        if (musicChannel == null) playMusic();
        playSound(sndCoin, 0.9);
    }
    
    private function performJump():Void 
    {
        jumpValue = 3.6;
        astronaut.y = 0;
        if (astronaut != null) astronaut.animationSpeed = 0.7;
        if (fire != null) fire.start();
        state = "jump";
        container.gotoAndPlay("jump", 3);
        playSound(sndJump, 0.85);
    }
    
    private function gameLogics(dtScale:Float):Void 
    {
        var turnRate = 3.8 * dtScale;
        var isLeft = Input3D.keyDown(Input3D.LEFT) || Input3D.keyDown(65);   // A 或 左
        var isRight = Input3D.keyDown(Input3D.RIGHT) || Input3D.keyDown(68); // D 或 右
        
        switch (state) {
            case "start":
                if (isRight) container.rotateY(turnRate);
                if (isLeft) container.rotateY(-turnRate);
                
            case "run":
                container.translateZ(speed * dtScale);
                if (astronaut != null) astronaut.animationSpeed = 0.55 + (speed - 0.32) * 0.8;
                if (isRight) container.rotateY(turnRate);
                if (isLeft) container.rotateY(-turnRate);
                if (speed > 0.55 && fire != null) fire.start();
                
            case "jump":
                container.translateZ(speed * dtScale);
                if (isRight) container.rotateY(turnRate);
                if (isLeft) container.rotateY(-turnRate);
                
            case "energy":
                if (isRight) container.rotateY(turnRate);
                if (isLeft) container.rotateY(-turnRate);
                resetCounter--;
                if (resetCounter <= 0 || Input3D.keyHit(Input3D.SPACE) || Input3D.keyHit(13)) {
                    nextStage();
                }
                
            case "fan":
                if (astronaut.y < 180) {
                    jumpValue = 3.6;
                } else {
                    jumpValue = 0;
                    astronaut.y = 180;
                }
                if (fire != null) fire.start();
                container.rotateY(3.2 * dtScale);
                if (shakeFactor > 0.5) shakeFactor *= 0.96;
                
                resetCounter--;
                if (resetCounter <= 0 || astronaut.y >= 160) {
                    if (!_scoreModal.visible) {
                        _scoreModal.visible = true;
                        _finalScoreText.text = "" + score;
                    }
                }
                
            case "die":
                resetCounter--;
                if (resetCounter < 0) {
                    if (!_scoreModal.visible) {
                        _scoreModal.visible = true;
                        _finalScoreText.text = "" + score;
                    }
                }
        }
    }
    
    private function gameObjects(dtScale:Float = 1.0):Void 
    {
        var cRaw = container.world.rawData;
        var cx = cRaw[12], cy = cRaw[13], cz = cRaw[14];
        
        // 风扇旋转与进入风扇致命危险区检测 (支持大号风扇、中级蓝色风扇及全尺寸风扇，预计算零分配极速物理判定)
        var aPos = astronaut.getPosition(false, _astroTempVec);
        var canTriggerFan = (state == "run" || state == "jump");
        
        for (f in fan) {
            var uData = f.userData;
            var fdx = aPos.x - uData.posX;
            var fdy = aPos.y - uData.posY;
            var fdz = aPos.z - uData.posZ;
            var distSq = fdx * fdx + fdy * fdy + fdz * fdz;
            
            // 视界距离内 (150码内) 才驱动叶片物理旋转，彻底卸载星球背面 30+ 远端风扇的无谓矩阵重算与空转开销
            if (distSq < 22500.0) {
                f.rotateY(uData.speed * dtScale);
            }
            
            if (canTriggerFan) {
                if (distSq < uData.radiusSq) {
                    // 人物进入大号风扇或中级蓝色风扇凹坑中：触发强劲风扇上升喷射死亡动画
                    state = "fan";
                    jumpValue = 3.6;
                    container.setNormalOrientation(f.getUp());
                    container.gotoAndPlay("jump", 1);
                    container.visible = true; // 确保角色全程可见，呈现震撼上升太空动画！
                    shakeFactor = 8.0;
                    if (fire != null) fire.start();
                    playSound(sndFan, 1.0);
                    playSound(sndDead, 0.95);
                    if (score > bestScore) bestScore = score;
                    resetCounter = 75;
                    flare.system.DebugLog.log("[FAN-DEATH] >>> Astronaut entered fan hazard! FanRadius: " + uData.radius + ", Dist: " + Math.sqrt(distSq) + ", Score: " + score + " <<<");
                    break;
                }
            }
        }
        
        // 地雷旋转、上下律动与空中踩爆检测 (完全对标原版 AS3，零 GC 临时对象分配)
        var aRaw = astronaut.world.rawData;
        var ax = aRaw[12], ay = aRaw[13], az = aRaw[14];
        
        for (m in mines) {
            var mRaw = m.world.rawData;
            var dx = ax - mRaw[12];
            var dy = ay - mRaw[13];
            var dz = az - mRaw[14];
            var distSq = dx * dx + dy * dy + dz * dz;

            // 视界距离内才驱动地雷旋转与上下浮动，卸载远端地雷无谓矩阵计算
            if (distSq < 22500.0) {
                m.rotateY(m.userData.speed * dtScale);
                m.userData.frequency += 0.1 * dtScale;
                m.translateY(Math.cos(m.userData.frequency) * 0.1 * dtScale);
            }
            
            if (m.visible && distSq < 100.0) { // 距离小于 10
                if (state == "jump") {
                    // 空中踩爆红色地雷加 50 分，原版规则！
                    m.hide();
                    score += 50;
                    if (score > bestScore) bestScore = score;
                    jumpValue = 4.8;
                    shakeFactor = 2.0;
                    playSound(sndMine, 0.9);
                } else if (state == "run") {
                    // 地面撞雷失败
                    container.visible = false;
                    shakeFactor = 15.0;
                    state = "die";
                    resetCounter = 100;
                    playSound(sndDead, 0.95);
                }
            }
            
            // 地雷在星球背面时自动重置复活显示 (原版规则，法线点积零内存分配)
            if (!m.visible) {
                var dot = mRaw[4] * cRaw[4] + mRaw[5] * cRaw[5] + mRaw[6] * cRaw[6];
                if (dot < 0) {
                    m.show();
                }
            }
        }
        
        // 能量晶体拾取与三连过关升级 (对标原版 AS3 标准 getPosition 距离检测，严格加 1 分与防重入冷却)
        if (energy != null && points.length > 0) {
            energy.rotateY(3.0 * dtScale);
            if (_energyCooldown > 0) _energyCooldown--;
            
            // 还原原版 AS3 能量模型绿色呼吸发光脉冲 (正弦波动强化视觉辨识度)
            if (energyColorFilter != null) {
                energyColorFilter.g = 1.0 + Math.sin(openfl.Lib.getTimer() / 100.0) * 0.5;
            }
            
            var curPoint = points[energyIndex % points.length];
            energy.copyTransformFrom(curPoint);
            
            var cPos = container.getPosition(false, _cTempVec);
            var ePos = energy.getPosition(false, _eTempVec);
            var edx = cPos.x - ePos.x;
            var edy = cPos.y - ePos.y;
            var edz = cPos.z - ePos.z;
            var distSq = edx * edx + edy * edy + edz * edz;
            
            if (_energyCooldown <= 0 && distSq < 100.0) { // 距离小于 10，精准触发 1 次
                score += 1; // 拾取 1 根能量：得分精准更新为 +1 分
                energyCount++;
                if (score > bestScore) bestScore = score;
                _energyCooldown = 35; // 开启 35 帧防连加保护锁
                
                flare.system.DebugLog.log("[ENERGY-PICK] >>> PICKED ENERGY! Added +1 point. Score: " + score + ", Count: " + energyCount + "/3 <<<");
                
                // 智能前向挑选下一个位于玩家前方道路的能量点，实现流畅奔跑与持续拾取
                selectNextEnergyPoint();
                
                if (energyCount >= 3) {
                    // 拾取第 3 根能量：得分精准更新为 3 分（右上角 3/3），触发过关横幅
                    state = "energy";
                    resetCounter = 120; // 暂停 2 秒并展示过关横幅
                    showStageClearBanner();
                    spawnPowerBurst();
                    playSound(sndScore, 1.0);
                    playSound(sndReset, 1.0);
                } else {
                    playSound(sndReset, 0.85);
                }
            }
        }
    }
    
    private var _lastGuiScore:Int = -1;
    private var _lastGuiBest:Int = -1;
    private var _lastGuiEnergy:Int = -1;
    private var _lastGuiStage:Int = -1;
    private var _lastReportedDrawCalls:Int = 0;
    private var _lastReportedTriangles:Int = 0;

    private function gameGUI():Void 
    {
        if (score != _lastGuiScore) {
            _pointsScoreText.text = "" + score;
            _lastGuiScore = score;
        }
        if (bestScore != _lastGuiBest) {
            _bestScoreText.text = "" + bestScore;
            _lastGuiBest = bestScore;
        }
        if (energyCount != _lastGuiEnergy) {
            _energyCountText.text = energyCount + "/3";
            _lastGuiEnergy = energyCount;
        }
        if (speedCounter != _lastGuiStage) {
            _stageLevelText.text = "STAGE " + speedCounter;
            _lastGuiStage = speedCounter;
        }
    }
}
