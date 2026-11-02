package flare.core;

/**
 * IComponent defines the lifecycle interface for pluggable components attached to Pivot3D nodes.
 */
interface IComponent {
    public function added(target:Pivot3D):Bool;
    public function removed():Bool;
}
