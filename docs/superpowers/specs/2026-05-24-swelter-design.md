# Swelter — design spec

A live-input tape + heat-haze effect for monome norns. External audio (line-in /
FOH) passes through a fixed chain of six "optical lenses" that waver, detune, and
age the sound, then mixes back against the dry signal. Performed from the three
encoders via page-cycling; the screen shows a layered heat-haze visualization with
a param readout that surfaces on activity.

The optical vocabulary (refraction, heat haze, mirage) is the naming language for
the sonic shaping — it maps onto concrete DSP parameters, documented below.

## Goals

- A musical, performable live insert effect — tweakable in real time without
  menu-diving for the core gestures.
- Tape character (wow/flutter, saturation, rolloff, hiss, dropout) plus two
  "creative optical" layers (heat-haze shimmer, mirage doubling).
- Conventions matching the user's other norns scripts: `project/lib/Engine_X.sc`
  SuperCollider engine + top-level `<name>.lua`.

## Non-goals (v1)

- No buffer capture / looping (live passthrough only). [[may revisit later]]
- No grid, arc, MIDI, or clock integration.
- No preset save/recall beyond what the norns PARAMS PSET system gives for free.

## Architecture

Two files plus the spec:

- **`lib/Engine_Swelter.sc`** — one `CroneEngine` subclass allocating a single
  stereo processing `SynthDef`. The synth reads the audio input with
  `In.ar([in_l, in_r])` and writes to the **engine's own output bus** with
  `Out.ar` (→ summed to main). The hardware input bus is left untouched; the
  engine performs its own dry/wet crossfade internally (dry = the input passed
  straight through, wet = the processed chain). To avoid doubling the dry path,
  `swelter.lua` mutes the norns hardware input monitor on init
  (`audio.level_monitor(0)`), so the engine is the sole path the input reaches the
  main output through. All six lenses are a **fixed serial chain** inside this one
  SynthDef. Every controllable value is a SynthDef arg smoothed with `Lag.kr` to
  avoid zipper noise. Engine commands set those args.

- **`swelter.lua`** — `engine.name = "Swelter"`; param definitions
  (`params:add_control` + `set_action` → `engine.*`, the Yarn glue pattern); the
  page-cycled encoder UI; key handling; and a `metro`-driven (~30 fps) layered
  screen redraw.

- **`docs/superpowers/specs/2026-05-24-swelter-design.md`** — this document.

### Engine commands (Lua → SC)

One command per controllable param (snake_case), each setting the corresponding
SynthDef arg:

```
trim f              input gain (0–2)
drywet f            dry/wet mix (0–1)
drive f             saturation amount (0–1 → tanh pre-gain)
wow f               wow depth (0–1)         wow_rate f     (0.05–2 Hz)
flutter f           flutter depth (0–1)     flutter_rate f (4–14 Hz)
haze f              shimmer depth (0–1)      haze_rate f   (0.1–8 Hz)
haze_turb f         shimmer turbulence/noise vs. sine (0–1)
mirage f            mirage mix (0–1)         mirage_detune f (cents, -25..25)
age f               HF rolloff amount (0–1 → LPF cutoff)
hiss f              hiss level (0–1)
dropout f           dropout amount (0–1, drives rate+depth of sags)
out_trim f          output trim (0–2)
```

### Engine polls (SC → Lua, for the screen)

```
amp_in    input amplitude (Amplitude.kr of summed input)
haze_mod  combined modulation value 0–1 (envelope of the wow+flutter+haze
          LFO sum), drives how hard the screen haze field bends
```

## Signal chain

Order follows tape signal flow (record → transport → playback) with the optical
layers woven in:

```
in → trim
   → Saturation   tanh soft-clip, pre-gain set by `drive`
   → Refraction   DelayL whose delay time is modulated by a slow wow SinOsc
                  (wow_rate, wow depth) summed with a fast flutter SinOsc
                  (flutter_rate, flutter depth) → pitch wander
   → + Mirage     a parallel second DelayL voice pitch-shifted by mirage_detune
                  cents, summed in at `mirage` level (the image that isn't there)
   → Heat-haze    amplitude + micro-pitch ripple from a SinOsc/LFNoise blend
                  (blend = haze_turb) at haze_rate, depth = haze
   → Dropout      LFNoise1-gated level sags; `dropout` scales both how often and
                  how deep the sags are
   → Tape-age     LPF rolloff (cutoff set by `age`, more age = lower cutoff)
                  + summed pink-ish hiss at `hiss` level
   → dry/wet      crossfade wet against the untouched input, `drywet`
   → out_trim → Out.ar (engine output → main)
```

Stereo throughout. The wow/flutter/haze LFOs run per-channel with a small phase
offset between L and R so the wander is not mono-locked. The `haze_mod` poll is
the rectified, lag-smoothed sum of the modulation LFOs, normalized 0–1.

### Optical → sonic mapping (reference)

| Lens       | Optical idea                         | DSP                                   |
|------------|--------------------------------------|---------------------------------------|
| Refraction | light bending through moving air     | wow + flutter delay-line pitch mod    |
| Heat haze  | shimmering waver over a hot surface  | amp + micro-pitch ripple, rate/turb   |
| Mirage     | an image that isn't there            | detuned parallel doubling voice       |
| Saturation | (the literal distortion)             | tanh soft-clip drive                  |
| Tape-age   | worn playback                        | LPF HF rolloff + hiss                 |
| Dropout    | worn tape, signal sagging            | random gated level sags               |

## Control surface

- **E1** — dry/wet (`drywet`), always live regardless of page.
- **K2** — cycle to next page (wraps).
- **K3** — momentary bypass: while held, output is fully dry, for A/B comparison.
- **K1** — shift: while held, E2/E3 address the *rate* params instead of the
  depth macros (wow_rate/flutter_rate on page 1, haze_rate/mirage_detune on page
  2, etc.), so rates are reachable without leaving the play screen.
- Granular params not on a page are still in the norns PARAMS menu for setup.

### Pages (E2 / E3 are depth macros; K1-shift reaches rates)

| Page | Name           | E2                | E3                     | K1 + E2        | K1 + E3          |
|------|----------------|-------------------|------------------------|----------------|------------------|
| 1    | REFRACTION     | wow               | flutter                | wow_rate       | flutter_rate     |
| 2    | HAZE / MIRAGE  | haze              | mirage                 | haze_rate      | mirage_detune    |
| 3    | TAPE           | drive             | age                    | hiss           | (—)              |
| 4    | WEAR           | dropout           | out_trim               | (—)            | (—)              |

A page macro may drive more than one underlying param where it reads as one
gesture (e.g. `age` lowers LPF cutoff; `haze` scales the ripple depth). The
underlying params remain individually addressable in the PARAMS menu.

## Screen (128×64, layered)

Redraw on a ~30 fps `metro`.

- **Background — heat-haze field.** Horizontal scanlines (every few px) drawn with
  a per-line horizontal pixel offset = `sin(phase + line*k) * bend`, where `bend`
  scales with `haze_mod` and `amp_in`. The field continuously animates (phase
  advances each frame) so it wavers even when readout is hidden. Low brightness.
- **Foreground — param readout.** Page name (top), two labeled bars/values for the
  current E2/E3 params, and a small dry/wet indicator. Hidden by default; an
  `activity` timer is reset to ~1.5 s on any encoder turn or key event, and the
  readout fades/disappears when it expires, leaving just the haze field.
- Bypass (K3 held) shows a clear "DRY" indicator.

## Error handling / edge cases

- Engine load failure → norns shows the standard engine error; nothing special.
- All depth params clamp 0–1; rates clamp to their stated ranges; `Lag.kr`
  smoothing prevents clicks on fast encoder moves.
- Page index wraps modulo 4; activity timer guards against divide-by-zero on the
  fade.
- Mono input (one channel) still works — the L/R LFO phase offset just produces a
  near-mono result.

## Testing / verification

norns DSP is not unit-testable off-device, so verification is:

1. `luac -p swelter.lua` — Lua compiles cleanly.
2. SuperCollider class parses (sclang `-D` parse check, or load on device).
3. On-device playtest by the user: load script, feed line-in, confirm each lens
   audibly does the right thing, encoders/pages/screen behave, no clicks.

Per the user's norns workflow: SynthDef changes require **SYSTEM > RESTART** on the
device; never restart norns-sclang over SSH.

## Open questions

- None blocking. Name provisionally **Swelter** (alternates: Mirage, Heatwave,
  Asphalt) — trivial to rename before first commit of code.
