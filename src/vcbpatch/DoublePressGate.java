package vcbpatch;

import de.vw.mib.asl.api.system.DoublePressKeyAdapter;
import de.vw.mib.asl.framework.api.framework.Services;

/**
 * Single/double press classifier, registered only when Remap.USE_DOUBLE_PRESS is true.
 *
 * SUBCLASSES the OEM DoublePressKeyAdapter and must never shadow it: subclassing runs the
 * OEM implementation with the real 500 ms timeout, whereas a shadow would substitute our
 * copy, whose constant jxe2jar destroyed, silently breaking single/double classification
 * for every key in the system.
 */
public class DoublePressGate extends DoublePressKeyAdapter {

    public DoublePressGate(Services services) {
        super(services);
    }

    public void onSinglePressed(int n) {
    }

    public void onSingleReleased(int n) {
        if (n == Remap.KEY_PTT) {
            Remap.onShortPress();
        }
    }

    public void onDoublePressed(int n) {
        if (n == Remap.KEY_PTT) {
            Remap.onDoublePress();
        }
    }
}
