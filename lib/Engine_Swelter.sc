// Engine_Swelter
//
// Live-input tape + heat-haze effect. One stereo SynthDef reads the audio
// input and writes a dry/wet blend to the engine output bus. Six lenses form
// a fixed serial chain; each is one labeled section.
//
// commands (all "f"): trim drywet out_trim drive
//   wow wow_rate flutter flutter_rate mirage mirage_detune
//   haze haze_rate haze_turb dropout age hiss
//
// polls: amp_in (input amplitude 0..1), haze_mod (modulation amount 0..1)

Engine_Swelter : CroneEngine {
  var synth;
  var ampBus, hazeBus;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    ampBus  = Bus.control(context.server, 1);
    hazeBus = Bus.control(context.server, 1);

    SynthDef(\swelter, {
      arg in_l, in_r, out, amp_out, haze_out,
          trim=1, drywet=0.5, out_trim=1,
          drive=0,
          wow=0, wow_rate=0.5, flutter=0, flutter_rate=8,
          mirage=0, mirage_detune=8,
          haze=0, haze_rate=2, haze_turb=0.5,
          dropout=0, age=0, hiss=0,
          slew=0.05;

      var dry, sig, hazemod, rip;

      // smoothed controls
      var ktrim  = Lag.kr(trim, slew);
      var kwet   = Lag.kr(drywet, slew);
      var kout   = Lag.kr(out_trim, slew);
      var kdrive = Lag.kr(drive, slew);
      var kwow   = Lag.kr(wow, slew);
      var kflut  = Lag.kr(flutter, slew);
      var kmir   = Lag.kr(mirage, slew);
      var kdet   = Lag.kr(mirage_detune, slew);
      var khaze  = Lag.kr(haze, slew);
      var kturb  = Lag.kr(haze_turb, slew);
      var kdrop  = Lag.kr(dropout, slew);
      var kage   = Lag.kr(age, slew);
      var khiss  = Lag.kr(hiss, slew);

      dry = In.ar([in_l, in_r]) * ktrim;
      sig = dry;
      hazemod = DC.kr(0);

      // === SATURATION === tanh soft-clip; gain-compensated
      sig = (sig * (1 + (kdrive * 8))).tanh;
      sig = sig * (1 - (kdrive * 0.35));
      // === REFRACTION === wow (slow) + flutter (fast) modulate a delay time;
      // [0, x] phase offsets give a stereo (non-mono-locked) wander
      sig = DelayC.ar(
        sig,
        0.06,
        (0.025
          + (SinOsc.kr(wow_rate,     [0, 0.5pi]) * kwow  * 0.012)
          + (SinOsc.kr(flutter_rate, [0, 0.3pi]) * kflut * 0.0018)
        ).clip(0.0005, 0.055)
      );
      // === MIRAGE === a detuned ghost voice summed in (cents -> ratio),
      // then level normalized so adding it doesn't blow up gain
      sig = (sig + (PitchShift.ar(sig, 0.2, (kdet / 100).midiratio, 0.01, 0.004) * kmir))
            * (1 / (1 + kmir));
      // === HEAT-HAZE ===         (identity — filled in Task 6)
      // === DROPOUT ===           (identity — filled in Task 7)
      // === TAPE-AGE ===          (identity — filled in Task 8)

      // dry/wet crossfade (-1 = dry, +1 = wet) + output trim
      sig = XFade2.ar(dry, sig, (kwet * 2) - 1) * kout;

      // polls
      Out.kr(amp_out, Amplitude.kr((dry[0] + dry[1]) * 0.5, 0.05, 0.2));
      Out.kr(haze_out, Lag.kr(hazemod.clip(0, 1), 0.1));

      Out.ar(out, sig);
    }).add;

    context.server.sync;

    synth = Synth.new(\swelter, [
      \in_l,     context.in_b[0].index,
      \in_r,     context.in_b[1].index,
      \out,      context.out_b.index,
      \amp_out,  ampBus.index,
      \haze_out, hazeBus.index
    ], context.xg);

    // commands — one per controllable arg
    [\trim, \drywet, \out_trim, \drive,
     \wow, \wow_rate, \flutter, \flutter_rate,
     \mirage, \mirage_detune,
     \haze, \haze_rate, \haze_turb,
     \dropout, \age, \hiss].do { |name|
      this.addCommand(name, "f", { |msg| synth.set(name, msg[1]) });
    };

    // polls
    this.addPoll(\amp_in,   { ampBus.getSynchronous });
    this.addPoll(\haze_mod, { hazeBus.getSynchronous });
  }

  free {
    synth.free;
    ampBus.free;
    hazeBus.free;
  }
}
