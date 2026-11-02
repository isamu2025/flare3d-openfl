package flare.materials.filters;

/**
 * FlipNormalsFilter inverts normal vectors for rendering backfaces or interior models.
 */
class FlipNormalsFilter extends Filter3D {
    public function new() {
        super("flipNormals");
    }
}
