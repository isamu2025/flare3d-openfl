package flare.materials.filters;

/**
 * TransformFilter performs default model-view-projection matrix transformations on vertices.
 */
class TransformFilter extends Filter3D {
    public function new() {
        super("transform");
    }

    public function process():Void {}
}
