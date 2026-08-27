# MIB2 Voice Control Button Patch

Remaps the steering-wheel **Voice Control** button on VW MQB cars with a MIB2 / MIB2.5 head unit,
so the button you rarely use becomes the mute/pause button the wheel never shipped with — while
long press still does exactly what this button did before.

More details about the development are in my drive2.ru blog: [Volkswagen Tiguan 2.0TDI R-Line
](https://www.drive2.ru/r/volkswagen/tiguan/707173444466250910/)

## Mappings

| Gesture | Action |
|---|---|
| **single press** | mute/unmute |
| **double press** | jump to App-Connect (CarPlay / Android Auto interface) |
| **long press** | Built-in voice control / Siri / Google Assistant |

## Compatibility

Developed and tested on a **Discover Pro MHI2_ER_VWG13_K4525_MU1367**.

| Firmware version | compatibility |
|---|---|
| **MHI2_ER_VWG13_K4525_MU1367** | ✅ |

## Build from source

```sh
export VCB_JDK_DIR=/path/to/jdk
export VCB_LSD_JAR=/path/to/lsd.jar
sh build.sh
```

## License

MIT — see [LICENSE](LICENSE).

The patch contains no VW code. `lsd.jar` is required only as a compile-time classpath and is
deliberately not distributed here; extract it from your own head unit.
