# swelter

A live-input **tape & heat-haze effect** for [monome norns](https://monome.org/docs/norns/).

> The name of the way light is distorted by heat became the name of the way sound is.

Feed it line-in and the signal passes through a fixed chain of six **optical lenses**
that waver, detune, saturate, and age it, then blend back against the dry signal.

| Lens | Optical idea | DSP |
|------|--------------|-----|
| **Refraction** | light bending through moving air | wow + flutter delay-line pitch wander |
| **Heat haze** | shimmer over a hot surface | sine↔noise amplitude + micro-pitch ripple |
| **Mirage** | an image that isn't there | detuned parallel doubling voice |
| **Saturation** | the heat in the signal | gain-compensated `tanh` soft-clip |
| **Tape age** | worn playback | LPF rolloff + hiss bed |
| **Dropout** | tape losing the head | random level sags |

## Controls

- **E1** — dry/wet (always live)
- **K2** — cycle page · **hold K3** — momentary bypass (A/B) · **hold K1** — E2/E3 reach rates
- Pages: `REFRACTION` · `HAZE / MIRAGE` · `TAPE` · `WEAR`
- Screen: an animated heat-haze field with a param readout that surfaces on activity.

## Status

- ✅ Design spec — [`docs/superpowers/specs/`](docs/superpowers/specs/)
- ✅ Implementation plan (13 tasks) — [`docs/superpowers/plans/`](docs/superpowers/plans/)
- ⏳ Engine (`lib/Engine_Swelter.sc`) + script (`swelter.lua`) — to build
- ⏳ On-device playtest

**Browsable design & features:** open [`swelter-devlog.html`](swelter-devlog.html) in a browser.

## Layout

```
swelter.lua                 # script: params, UI, screen (to build)
lib/Engine_Swelter.sc       # SuperCollider engine: six-lens chain (to build)
swelter-devlog.html         # single-file design/features site
docs/superpowers/specs/     # design spec
docs/superpowers/plans/     # implementation plan
```
