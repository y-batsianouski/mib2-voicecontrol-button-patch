package vcbpatch;

import de.vw.mib.asl.api.system.KeyAdapter;

public class RemapKeyListener extends KeyAdapter {

    private static final long DOUBLE_PRESS_INTERVAL = 400L;

    private boolean longPressed = false;
    private boolean waitingForSecondPress = false;

    public void onPressed(int n) {
        if (n == Remap.KEY_PTT) {
            longPressed = false;
            Remap.onPress();
        }
    }

    public void onReleased(int n) {
        if (n != Remap.KEY_PTT) {
            return;
        }

        // Do not trigger a short press after a long press
        if (longPressed) {
            longPressed = false;
            return;
        }

        if (!Remap.USE_DOUBLE_PRESS) {
            Remap.onShortPress();
            return;
        }

        if (waitingForSecondPress) {
            waitingForSecondPress = false;
            Remap.onDoublePress();
            return;
        }

        waitingForSecondPress = true;

        Thread thread = new Thread(new Runnable() {
            public void run() {
                try {
                    Thread.sleep(DOUBLE_PRESS_INTERVAL);
                } catch (InterruptedException e) {
                    return;
                }

                synchronized (RemapKeyListener.this) {
                    if (waitingForSecondPress) {
                        waitingForSecondPress = false;
                        Remap.onShortPress();
                    }
                }
            }
        });

        thread.start();
    }

    public void onLongPressed(int n) {
        if (n == Remap.KEY_PTT) {
            longPressed = true;
            waitingForSecondPress = false;
            Remap.onLongPress();
        }
    }
}
