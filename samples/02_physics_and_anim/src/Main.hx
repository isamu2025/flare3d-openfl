package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Vector3D;
import flare.basic.Viewer3D;
import flare.core.Label3D;
import flare.core.Particles3D;
import flare.core.Pivot3D;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;
import flare.materials.filters.LightFilter;
import flare.physics.colliders.BoxCollider;
import flare.physics.colliders.SphereCollider;
import flare.primitives.Box;
import flare.primitives.Sphere;

class Main extends Sprite {
    public function new() {
        super();

        // 1. 初始化 3D 视口与摄像机
        var scene = new Viewer3D(this);
        scene.autoResize = true;
        scene.clearColor = 0x141419;
        scene.radius = 450.0;
        scene.target.setTo(0, 50, 0);
        scene.physics.gravity.setTo(0, -350, 0);
        scene.updateCameraOrbit();

        // 添加主方向光源
        var sunLight = new flare.core.Light3D("sun", flare.core.Light3D.DIRECTIONAL);
        sunLight.setParams(0xffffff, 0, 1, 1.3, true);
        sunLight.setPosition(200, 350, 150);
        sunLight.lookAt(0, 0, 0);
        scene.addChild(sunLight);

        // 2. 静态地面与碰撞盒
        var groundMat = new Shader3D("groundMat", [new ColorFilter(0x3a4f63), new LightFilter()]);
        var groundMesh = new Box("ground", 500, 10, 500, 1, groundMat);
        groundMesh.setPosition(0, -5, 0);
        scene.addChild(groundMesh);

        var groundCollider = new BoxCollider(groundMesh, 500, 10, 500);
        groundCollider.isStatic = true;
        groundCollider.invMass = 0;
        groundCollider.restitution = 0.6;
        scene.physics.addCollider(groundCollider);

        // 3. 动态物理球体（受重力下落与弹性弹跳）
        var colors = [0xff3344, 0x33ff66, 0x3388ff, 0xffbb00, 0xaa33ff];
        for (i in 0...5) {
            var sphereMat = new Shader3D("sphereMat" + i, [new ColorFilter(colors[i]), new LightFilter()]);
            var sphere = new Sphere("sphere_" + i, 20, 16, 12, sphereMat);
            sphere.setPosition((i - 2) * 50, 150 + i * 40, (Math.random() - 0.5) * 60);
            scene.addChild(sphere);

            var sphereCollider = new SphereCollider(sphere, 20);
            sphereCollider.mass = 1.0;
            sphereCollider.restitution = 0.75;
            sphereCollider.linearVelocity.setTo((Math.random() - 0.5) * 20, 0, (Math.random() - 0.5) * 20);
            scene.physics.addCollider(sphereCollider);
        }

        // 4. 骨骼动画时间轴节点
        var character = new Pivot3D("character");
        character.totalFrames = 60;
        character.addLabel(new Label3D("idle", 0, 20));
        character.addLabel(new Label3D("run", 21, 45));
        character.addLabel(new Label3D("jump", 46, 60));
        character.gotoAndPlay("run");
        scene.addChild(character);

        // 5. 3D 粒子系统喷泉
        var particles = new Particles3D("sparkParticles", 100);
        particles.setPosition(0, 10, 0);
        particles.gravity = new Vector3D(0, -15, 0);
        particles.startSize = 6.0;
        particles.endSize = 1.0;
        scene.addChild(particles);
    }
}
