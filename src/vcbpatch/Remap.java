package vcbpatch;

import de.vw.mib.asl.api.system.ASLSystemAPI;
import de.vw.mib.asl.api.system.ASLSystemFactory;
import de.vw.mib.asl.framework.api.framework.ASLFrameworkFactory;
import de.vw.mib.asl.framework.api.framework.Services;
import de.vw.mib.asl.internal.speechgeneral.ptt.DialogSession;

/**
 * Voice-button remap: short press mutes, long press keeps stock OEM behaviour.
 *
 * USE_DOUBLE_PRESS is the only switch. It exists because the OEM double-press window is
 * 500 ms and cannot be shortened: the constant lives in DoublePressKeyAdapter, which must
 * never be shadowed (jxe2jar destroyed its timeout, and a bad copy would break single/double
 * classification for every key in the system). The wait is therefore avoided by not
 * consulting the classifier, not by retuning it.
 *
 *   false - mute fires on onReleased, immediately. A double press reads as two short presses.
 *   true  - mute fires on onSingleReleased, so it costs the 500 ms window, and double press
 *           opens App-Connect. This is the shipped configuration.
 *
 * Two measured on-car facts the design depends on:
 *  - a long press emits onPressed -> onLongPressed -> onLongReleased and NEVER onReleased,
 *    so acting on onReleased is inherently short-press-only;
 *  - with CarPlay connected the OEM calls activate() from its own 500 ms timer ~2 ms after
 *    our callback, so suppression is armed on press and held until the NEXT press rather
 *    than trying to win that race.
 *
 * A suppressed activate() is parked, not dropped, so a long press replays it by calling
 * activate() again with the flag cleared. Reusing the OEM method keeps the shadow ABI intact.
 */
public class Remap {

    public static final boolean USE_DOUBLE_PRESS = true;

    static final int KEY_PTT = 15;

    private static final int DSI_KEY_MUTE = 88;
    private static final int DSI_KEY_SMARTPHONE = 114;
    private static final int STATE_PRESSED = 1;
    private static final int STATE_RELEASED = 0;

    private static boolean installed = false;
    private static boolean suppressActivate = false;
    private static DialogSession parked = null;

    private Remap() {
    }

    public static synchronized void install() {
        if (installed) {
            return;
        }
        installed = true;
        try {
            ASLSystemAPI api = ASLSystemFactory.getSystemApi();
            if (api == null) {
                installed = false;
                return;
            }
            api.addKeyListener(KEY_PTT, new RemapKeyListener());
            if (USE_DOUBLE_PRESS) {
                Services services = ASLFrameworkFactory.getASLFrameworkAPI().getServices();
                if (services != null) {
                    api.addKeyListener(KEY_PTT, new DoublePressGate(services));
                }
            }
        } catch (Throwable t) {
            installed = false;
        }
    }

    public static synchronized boolean shouldSuppressAndPark(DialogSession session) {
        if (!suppressActivate) {
            return false;
        }
        parked = session;
        return true;
    }

    static synchronized void onPress() {
        suppressActivate = true;
        parked = null;
    }

    static synchronized void onShortPress() {
        tapKey(DSI_KEY_MUTE);
    }

    static synchronized void onDoublePress() {
        tapKey(DSI_KEY_SMARTPHONE);
    }

    private static void tapKey(int dsiKey) {
        try {
            ASLSystemAPI api = ASLSystemFactory.getSystemApi();
            if (api == null) {
                return;
            }
            api.createAndSubmitHardkeyEvent(dsiKey, STATE_PRESSED);
            api.createAndSubmitHardkeyEvent(dsiKey, STATE_RELEASED);
        } catch (Throwable t) {
            // a failed injection must never propagate into the OEM key callback
        }
    }

    static synchronized void onLongPress() {
        DialogSession p = parked;
        parked = null;
        suppressActivate = false;
        if (p == null) {
            return;
        }
        try {
            p.activate();
        } catch (Throwable t) {
            // replay failure must never propagate into the OEM key callback
        }
    }
}
