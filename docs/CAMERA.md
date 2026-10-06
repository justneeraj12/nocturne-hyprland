# Camera quality and latency

Nocturne uses the ordinary Linux UVC/V4L2 and PipeWire path. It does not keep a
virtual camera, AI model or video filter alive in the background.

On the reference laptop, the integrated SunplusIT HD Webcam exposes MJPEG and
raw YUYV at up to 1280×720. MJPEG is the sensible conferencing path because it
keeps USB bandwidth and conversion cost lower; browsers still negotiate the
final format and frame rate.

## Enable hardware profiles

Ubuntu needs the standard control utility once:

```bash
sudo apt install v4l-utils
```

Then open **Settings → Sound & displays → Camera quality**. Profiles modify
only controls the sensor actually exposes:

- **Smart** — automatic exposure, white balance and focus, steady frame
  cadence, local mains anti-flicker and backlight compensation;
- **Natural** — automatic behavior without backlight compensation;
- **Low Light** — allows dynamic exposure/frame cadence when the sensor
  supports it.

If Meet, Discord or a browser already owns the device, Nocturne reports the
holder and refuses to race it. Close the camera in that application, apply the
profile, then reopen it. The camera card itself has zero idle process cost.

## What software cannot fix

A 720p laptop sensor cannot become a 4K camera through sharpening or an RTX
filter. Lighting the face from the front, keeping the lens clean and avoiding a
bright window behind the subject produce larger gains than heavy denoising.
Nocturne therefore tunes the sensor ISP first and leaves compressed meeting
video on the standard low-latency path.

Technical references: [Linux UVC driver](https://www.kernel.org/doc/html/v4.12/media/v4l-drivers/uvcvideo.html),
[GStreamer V4L2 source](https://gstreamer.freedesktop.org/documentation/video4linux2/v4l2src.html),
and [PipeWire architecture](https://docs.pipewire.org/).
