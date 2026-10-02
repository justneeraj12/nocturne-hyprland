-- The first config pass can happen before the user-local plugin is loaded.
-- Returning here is intentional: HyprCapture requests a reload from
-- PLUGIN_INIT, at which point its config keys and Lua actions exist.
if not hl.plugin.hyprcapture then return end

hl.config({
    plugin = {
        hyprcapture = {
            default_mode = "region",
            fullscreen_scope = "all",
            overlay_scope = "fix",
            window_background = "follow-system",
            window_border = "keep",
            window_shadow = "keep",
            notification_backend = "system",
            screenshot_notification = true,
            notification_title_template = "Screenshot captured",
            notification_body_template = "Saved {filename} · ready to paste",
            save = true,
            clipboard = true,
            show_thumbnail = true,
            remember_settings = true,
            allow_quick = false,
            confirm_before_capture = false,
            fusion_mode = true,
            dynamic_window_metadata = true,
            window_wheel_scroll = true,
            window_wheel_scope = "workspace",
            fullscreen_preview_rounding = "0",
            save_dir = "$XDG_PICTURES_DIR/Screenshots",
            filename_template = "Screenshot-%Y-%m-%d-%H%M%S.png",
            record_save_dir = "$XDG_VIDEOS_DIR/Screenrecords",
            record_filename_template = "Recording-%Y-%m-%d-%H%M%S.mp4",
            record_format = "mp4",
            record_fps = 30,
            record_fps_options = "15 24 30 60",
            record_audio = "off",
            record_audio_output = "auto",
            record_audio_input = "default",
            record_codec = "auto",
            record_window_backend = "auto",
            record_countdown_seconds = 0,
            include_cursor = false,
            thumbnail_timeout_ms = 5000,
            thumbnail_monitor = "active",
        },
    },
})

-- One GNOME-like surface for area, window, display and screen recording.
hl.bind("Print", hl.plugin.hyprcapture.open)
