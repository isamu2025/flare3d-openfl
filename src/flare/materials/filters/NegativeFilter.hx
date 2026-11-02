package flare.materials.filters;

/**
 * NegativeFilter inverts the RGB color spectrum for photographic negative visual effects.
 */
class NegativeFilter extends Filter3D {
    public function new() {
        super("negative");
    }
}
