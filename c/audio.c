// #include <locale.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
// audio raw PCM_S16_LE producer

typedef struct {
  // main parameters
  // so para is 8
  float vol;
  float freq;
  float filt;
  // drift parameters per 100%
  float vol_d;
  float freq_d;
  float filt_d;
  // any extra state goes here
  float count;
  float buf;
} oscillator;

// max oscillators
#define maxo 3
#define para 6
#define sampRate 44000.0f
// wavelength in samples
#define waveLen 65536.0f
// max int amplitude
#define amplitude (65536.0f / 2.0f)
// concert pitch A
#define pitchA 440.0f
// the osc sample step for frequency
// using increment of 1 per semitone
#define step(f) (waveLen * powf(2, f / 12.0f) * pitchA / sampRate)
float len;
oscillator osc[maxo]; // should be enough
// max parameters * osc + program + len
#define maxp (para * maxo + 2)
// default modulation scaling up the algorithm
// a mild default spice
#define spice 0.25f

void initOsc(oscillator *p, int num) {
  // basic unitary initialization
  p->vol = pow(spice, num); // max
  p->freq = 0.0f;           // 440Hz
  p->filt = 0.0f;           // 440Hz
  // basic scaling initialization
  p->vol_d = 0.0f;
  p->freq_d = 0.0f;
  p->filt_d = 0.0f;
  // extra stuff for state management
  p->count = 0.0f;
  p->buf = 0.0f;
}

// output PCM_S16_LE
void out(float samp) {
  int16_t i = (int16_t)(samp * amplitude);
  putchar(i & 0xff);
  putchar(i >> 8);
  // fprintf(stderr, "%.2f ", samp);
  // fprintf(stderr, "%d ", i);
}

// ratiometric frequency scaling
// makes the input parameters nicer
void ratiometric() {
  for (int i = 1; i < maxo; ++i) {
    // make common frequency basis
    osc[i].freq += osc[0].freq;
  }
  for (int i = 0; i < maxo; ++i) {
    // filter relative
    // fprintf(stderr, "%f, %f\n", osc[i].filt, osc[i].freq);
    osc[i].filt += osc[i].freq;
  }
}

// scale oscillator sample
float scale(int num) {
  oscillator *p = &osc[num];
  return p->vol * (p->count - waveLen / 2.0f) * 2.0f / waveLen;
}

int main(int argc, char *argv[]) {
  if (argc > maxp)
    return EXIT_FAILURE;
  len = 1.0f; // 1 second
  // just in case non-standard locale
  // char *oldLocale = setlocale(LC_NUMERIC, NULL);
  // setlocale(LC_NUMERIC, "en_US");
  if (argc > 1)
    len = atof(argv[1]);
  // some insanity of sound?
  if (len > 16.0f || len < 0.0f)
    return EXIT_FAILURE;
  for (int i = 0; i < maxo; ++i) {
    initOsc(&osc[i], i);
  }
  oscillator *p = &osc[0];
  for (int i = 0; i < argc - 2; ++i) {
    // fill in osc parameter blocks
    float f = atof(argv[i + 2]);
    int o = i / para; // osc number
    ((float *)(&p[o]))[i % para] = f;
  }
  // restore locale
  // setlocale(LC_NUMERIC, oldLocale);
  ratiometric();
  for (int i = 0; i < maxo; ++i) {
    oscillator *o = &osc[i];
    /* fprintf(
        stderr,
        "os: %d, vl: %.2f, fw: %.2f, ff: %.2f, vd: %.2f, wd: %.2f, fd: %.2f\n",
        i, o->vol, o->freq, o->filt, o->vol_d, o->freq_d, o->filt_d); */
  }
  // number of samples to make
  int numSamp = sampRate * len;
  // fprintf(stderr, "numSamp: %d\n", numSamp);
  for (int i = 0; i < numSamp; ++i) {
    float mod = 0.0f;
    for (int o = maxo - 1; o != -1; --o) {
      // apply exponential FM
      osc[o].count += step(osc[o].freq * powf(2, mod));
      osc[o].count = fmodf(osc[o].count, waveLen);
      // apply drifts after 100%
      osc[o].vol += osc[o].vol_d / numSamp;
      osc[o].freq += osc[o].freq_d / numSamp;
      mod = scale(o);
      // single pole filter per osc for excursion control
      float f1 = tanf(M_PI * pitchA * powf(2, osc[o].filt / 12.0f) / sampRate);
      float f2 = 1.0f / (1.0f + f1);
      float t = (f1 * mod + osc[o].buf) * f2;
      osc[o].buf = f1 * (mod - t) + t;
      mod = t;
      osc[o].filt += osc[o].filt_d / numSamp;
    }
    // basic saw++
    out(mod);
  }
  return EXIT_SUCCESS;
}
