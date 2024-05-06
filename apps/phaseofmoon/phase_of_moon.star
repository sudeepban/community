"""
Applet: Phase of Moon
Summary: Shows the phase of the moon
Description: Shows the current phase of the moon.
Author: Alan Fleming
"""

# Phase of Moon App
#
# Copyright (c) 2022 Alan Fleming
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# See comments in the code for further attribution
#

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Default location

DEFAULT_LOCATION = """
{
    "lat": 55.861111,
    "lng": -4.25,
    "locality": "Glasgow, UK",
    "timezone": "GMT"
}
"""

#
# Time formats used in get_schema
#

TIME_FORMATS = {
    "No clock": None,
    "12 hour": ("3:04", "3 04", True),
    "24 hour": ("15:04", "15 04", False),
}

# Constants
LUNARDAYS = 29.53058770576
LUNARSECONDS = LUNARDAYS * (24 * 60 * 60)
FIRSTMOON = 947182440  # Saturday, 6 January 2000 18:14:00 in unix epoch time

# Moon Images
# Rendered to 30x30 from NASA images at https://spaceplace.nasa.gov/oreo-moon/en/
PHASE_IMAGES = [
    """iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAA8mVYSWZNTQAqAAAACAAHARIAAwAAAAEAAQAAARoABQAAAAEAAABiARsABQAAAAEAAABqASgAAwAAAAEAAgAAATEAAgAAACEAAAByATIAAgAAABQAAACUh2kABAAAAAEAAACoAAAAAAAAAEgAAAABAAAASAAAAAFBZG9iZSBQaG90b3Nob3AgMjEuMiAoTWFjaW50b3NoKQAAMjAyMDowOToyOSAxMzoxNjoyMAAABJAEAAIAAAAUAAAA3qABAAMAAAABAAEAAKACAAQAAAABAAAAHqADAAQAAAABAAAAHgAAAAAyMDIwOjA5OjI5IDEzOjEyOjM2AOt7u9YAAAAJcEhZcwAACxMAAAsTAQCanBgAAAtgaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgICAgICAgICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICAgICAgICAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iPgogICAgICAgICA8ZXhpZjpDb2xvclNwYWNlPjE8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjE5MjA8L2V4aWY6UGl4ZWxYRGltZW5zaW9uPgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+MTA4MDwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxkYzpmb3JtYXQ+aW1hZ2UvanBlZzwvZGM6Zm9ybWF0PgogICAgICAgICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj43MjwvdGlmZjpYUmVzb2x1dGlvbj4KICAgICAgICAgPHRpZmY6WVJlc29sdXRpb24+NzI8L3RpZmY6WVJlc29sdXRpb24+CiAgICAgICAgIDx4bXBNTTpIaXN0b3J5PgogICAgICAgICAgICA8cmRmOlNlcT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDpzb2Z0d2FyZUFnZW50PkFkb2JlIFBob3Rvc2hvcCAyMS4yIChNYWNpbnRvc2gpPC9zdEV2dDpzb2Z0d2FyZUFnZW50PgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDIwLTA5LTI5VDEzOjEyOjM2LTA3OjAwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6aW5zdGFuY2VJRD54bXAuaWlkOjFiODdjZDcwLTIyYWUtNGE2YS04Nzk3LWFhOWJlYjI5OTJiYjwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5jcmVhdGVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgIDwvcmRmOmxpPgogICAgICAgICAgICAgICA8cmRmOmxpIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5jb252ZXJ0ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OnBhcmFtZXRlcnM+ZnJvbSBpbWFnZS9wbmcgdG8gaW1hZ2UvanBlZzwvc3RFdnQ6cGFyYW1ldGVycz4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgMjEuMiAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAyMC0wOS0yOVQxMzoxNjoyMC0wNzowMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDo5NDcyYWY5MC01MzM3LTQwZDgtYTEwMy1jZDk3Y2E2MjA0NTg8L3N0RXZ0Omluc3RhbmNlSUQ+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgIDwvcmRmOlNlcT4KICAgICAgICAgPC94bXBNTTpIaXN0b3J5PgogICAgICAgICA8eG1wTU06T3JpZ2luYWxEb2N1bWVudElEPnhtcC5kaWQ6MWI4N2NkNzAtMjJhZS00YTZhLTg3OTctYWE5YmViMjk5MmJiPC94bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ+CiAgICAgICAgIDx4bXBNTTpEb2N1bWVudElEPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDpmYjg5N2JlMi1m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YmUuY29tL3hhcC8xLjAvIgogICAgICAgICAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iPgogICAgICAgICA8ZXhpZjpDb2xvclNwYWNlPjE8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjE5MjA8L2V4aWY6UGl4ZWxYRGltZW5zaW9uPgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+MTA4MDwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxkYzpmb3JtYXQ+aW1hZ2UvanBlZzwvZGM6Zm9ybWF0PgogICAgICAgICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj43MjwvdGlmZjpYUmVzb2x1dGlvbj4KICAgICAgICAgPHRpZmY6WVJlc29sdXRpb24+NzI8L3RpZmY6WVJlc29sdXRpb24+CiAgICAgICAgIDx4bXBNTTpIaXN0b3J5PgogICAgICAgICAgICA8cmRmOlNlcT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDpzb2Z0d2FyZUFnZW50PkFkb2JlIFBob3Rvc2hvcCAyMS4yIChNYWNpbnRvc2gpPC9zdEV2dDpzb2Z0d2FyZUFnZW50PgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDIwLTA5LTI5VDEzOjEyOjM2LTA3OjAwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6aW5zdGFuY2VJRD54bXAuaWlkOjFiODdjZDcwLTIyYWUtNGE2YS04Nzk3LWFhOWJlYjI5OTJiYjwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5jcmVhdGVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgIDwvcmRmOmxpPgogICAgICAgICAgICAgICA8cmRmOmxpIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmFjdGlvbj5jb252ZXJ0ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OnBhcmFtZXRlcnM+ZnJvbSBpbWFnZS9wbmcgdG8gaW1hZ2UvanBlZzwvc3RFdnQ6cGFyYW1ldGVycz4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgMjEuMiAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAyMC0wOS0yOVQxMzoxNjoyMC0wNzowMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDo5NDcyYWY5MC01MzM3LTQwZDgtYTEwMy1jZDk3Y2E2MjA0NTg8L3N0RXZ0Omluc3RhbmNlSUQ+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgIDwvcmRmOlNlcT4KICAgICAgICAgPC94bXBNTTpIaXN0b3J5PgogICAgICAgICA8eG1wTU06T3JpZ2luYWxEb2N1bWVudElEPnhtcC5kaWQ6MWI4N2NkNzAtMjJhZS00YTZhLTg3OTctYWE5YmViMjk5MmJiPC94bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ+CiAgICAgICAgIDx4bXBNTTpEb2N1bWVudElEPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDpmYjg5N2JlMi1m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""",
]

# Phase of the moon data.
# Dates in phase changes give 2 days for key phases and lengthen others to match. Removes over-display of key phases.
# Idea, data and calculation from https://minkukel.com/en/various/calculating-moon-phase/
NUM_PHASES = 8
MOON_PHASES = {
    "en": ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous", "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent", "New Moon"]
}
PHASE_CHANGES = [0, 1, 6.38264692644, 8.38264692644, 13.76529385288, 15.76529385288, 21.14794077932, 23.14794077932, 28.53058770576, 29.53058770576]

# Moon phases in Chinese (simplified).
MOON_PHASES_ZH = [
    """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""",
]

def main(config):
    # Get latitude from location
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(location["lat"])
    tz = location.get("timezone")

    # use latitude to work out which hemisphere we're in
    hemisphere = 1 if lat >= 0 else 0

    # Get the current time
    currtime = time.now("UTC")
    # currtime = time.parse_time("16-Sep-2022 20:17:00", format="02-Jan-2006 15:04:05")  # pick any date to debug/unit test

    # Get the current fraction of the moon cycle
    currentfrac = math.mod(currtime.unix - FIRSTMOON, LUNARSECONDS) / LUNARSECONDS

    # Calculate current day of the cycle from there
    currentday = currentfrac * LUNARDAYS

    displayText = config.get("display_text", "en")

    moonPhase = (MOON_PHASES[displayText][0] if displayText != "zh" else MOON_PHASES_ZH[0]) if displayText != "none" else ""
    phaseImage = PHASE_IMAGES[0]

    for x in range(0, NUM_PHASES):
        if currentday > PHASE_CHANGES[x] and currentday <= PHASE_CHANGES[x + 1]:
            moonPhase = (MOON_PHASES[displayText][x] if displayText != "zh" else MOON_PHASES_ZH[x]) if displayText != "none" else ""
            phaseImage = PHASE_IMAGES[x]
            if hemisphere == 0:
                phaseImage = PHASE_IMAGES[NUM_PHASES - x]

    # phaseImage = PHASE_IMAGES[4]  # pick any index from 0 to 7 to debug/unit test

    time_format = TIME_FORMATS.get(config.get("time_format"))
    blink_time = config.bool("blink_time")
    clock_has_shadow = config.bool("has_shadow")

    disp_time = time.now().in_location(tz).format(time_format[0]) if time_format else None
    disp_time_blink = time.now().in_location(tz).format(time_format[1]) if time_format else None

    # Got what we need to render.
    if displayText == "none":
        phaseText = render.WrappedText("")
    elif displayText == "zh":
        phaseText = render.Image(
            src = base64.decode(moonPhase),
        )
    else:
        phaseText = render.WrappedText(
            content = moonPhase,
            font = "tom-thumb",
        )

    phaseIndex = PHASE_IMAGES.index(phaseImage)

    align = "center"
    if displayText != "none" and phaseIndex <= 4:
        align = "start"
    elif displayText == "none" and time_format != None:
        align = "space_evenly"

    displaycomplete = render.Box(
        render.Row(
            expanded = True,
            main_align = align,
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (0, 0, 2, 0) if align == "start" else 0,
                    child = render.Image(src = base64.decode(phaseImage)),
                ),
                render.Column(
                    expanded = True,
                    main_align = "space_evenly" if time_format != None and displayText != "none" else "center",
                    cross_align = "start",
                    children = [
                        render.Padding(
                            pad = 0,
                            child = phaseText,
                        ),

                        # optional clock below
                        render.Animation(
                            children = [
                                # both w/ & w/out drop-shadow
                                render.Padding(
                                    pad = (0, 2, 0, 0),
                                    child = render.Stack(
                                        children = [
                                            render.Padding(
                                                # render extra pixels to the right to push time closer to moon
                                                pad = (3, 0, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#000",
                                                ),
                                            ),
                                            render.Padding(
                                                # faint shadow right
                                                pad = (1, 0, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#222",
                                                ),
                                            ),
                                            render.Padding(
                                                # faint shadow down
                                                pad = (0, 1, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#222",
                                                ),
                                            ),
                                            render.Padding(
                                                # medium shadow diagonal down-right
                                                pad = (1, 1, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#444",
                                                ),
                                            ),
                                            render.Text(
                                                # bright time
                                                content = disp_time,
                                                font = "tom-thumb",
                                                color = "#AAA",
                                            ),
                                        ],
                                    ),
                                ) if clock_has_shadow else render.Padding(
                                    pad = (0, 0, 0, 0),
                                    child = render.Text(
                                        content = disp_time,
                                        font = "tom-thumb",
                                        color = "#fff",
                                    ),
                                ),

                                # optional clock blink (w/ drop-shadow)
                                render.Padding(
                                    pad = (0, 2, 0, 0),
                                    child = render.Stack(
                                    children = [
                                        render.Padding(
                                            pad = (3, 0, 0, 0),
                                            child = render.Text(
                                                content = disp_time_blink,
                                                font = "tom-thumb",
                                                color = "#000",
                                            ),
                                        ),
                                        render.Padding(
                                            pad = (1, 0, 0, 0),
                                            child = render.Text(
                                                content = disp_time_blink,
                                                font = "tom-thumb",
                                                color = "#222",
                                            ),
                                        ),
                                        render.Padding(
                                            pad = (0, 1, 0, 0),
                                            child = render.Text(
                                                content = disp_time_blink,
                                                font = "tom-thumb",
                                                color = "#222",
                                            ),
                                        ),
                                        render.Padding(
                                            pad = (1, 1, 0, 0),
                                            child = render.Text(
                                                content = disp_time_blink,
                                                font = "tom-thumb",
                                                color = "#444",
                                            ),
                                        ),
                                        render.Text(
                                            content = disp_time_blink,
                                            font = "tom-thumb",
                                            color = "#AAA",
                                        ),
                                    ],
                                    ),
                                ) if blink_time and clock_has_shadow == True else None,
                                
                                # optional clock blink
                                render.Padding(
                                    pad = (0, 0, 0, 0),
                                    child = render.Text(
                                        content = disp_time_blink,
                                        font = "tom-thumb",
                                        color = "#fff",
                                    ),
                                ) if blink_time and clock_has_shadow != True else None,
                            ],
                        ) if time_format else None,
                    ],
                ),
            ],
        ),
    )

    return render.Root(
        delay = 1000,
        child = displaycomplete,
    )

def more_options(time_format):
    if time_format != "No clock":
        return [
            schema.Toggle(
                id = "blink_time",
                name = "Blinking Time Separator",
                desc = "Whether to blink the colon between hours and minutes.",
                icon = "asterisk",
                default = False,
            ),
            schema.Toggle(
                id = "has_shadow",
                name = "Shadow",
                desc = "Whether clock has drop-shadow.",
                icon = "umbrella-beach",
                default = False,
            ),
        ]
    else:
        return []

def get_schema():
    langs = [
        schema.Option(
            display = "Chinese (simplified)",
            value = "zh",
        ),
        schema.Option(
            display = "English",
            value = "en",
        ),
        schema.Option(
            display = "None",
            value = "none",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the moon phase.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "display_text",
                name = "Display Text",
                desc = "Display the text description of the moon phase.",
                icon = "font",
                default = langs[1].value,
                options = langs,
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "The format used for the time.",
                icon = "clock",
                default = "No clock",
                options = [
                    schema.Option(
                        display = format,
                        value = format,
                    )
                    for format in TIME_FORMATS
                ],
            ),
            schema.Generated(
                id = "generated",
                source = "time_format",
                handler = more_options,
            ),
        ],
    )