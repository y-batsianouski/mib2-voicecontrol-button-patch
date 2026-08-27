package vcbpatch;

import de.vw.mib.asl.api.system.KeyAdapter;

public class RemapKeyListener extends KeyAdapter {

    public void onPressed(int n) {
        if (n == Remap.KEY_PTT) {
            Remap.onPress();
        }
    }

    public void onReleased(int n) {
        if (n == Remap.KEY_PTT && !Remap.USE_DOUBLE_PRESS) {
            Remap.onShortPress();
        }
    }

    public void onLongPressed(int n) {
        if (n == Remap.KEY_PTT) {
            Remap.onLongPress();
        }
    }
}
