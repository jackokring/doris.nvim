#include <stdlib.h>
#include <stdio.h>
#include <math.h>
// audio raw PCM_S16_LE producer

typedef struct {
  // main parameters
  // so para is 8
  float vol;
  float freq;
  float filt;
  float q;
  // drift parameters per 100%
  float vol_d;
  float freq_d;
  float filt_d;
  float q_d;
  //any extra state goes here
  float count;
} oscillator;

// max oscillators
#define maxo 3
#define para 8
#define sampRate 44000.0f
//wavelength in samples
#define waveLen 65536.0f
//concert pitch A
#define pitchA 440.0f
//the osc sample step for frequency
//using increment of 1 per semitone
#define step(f) (waveLen * pow(2, f / 12.0f) * pitchA / sampRate)
float len;
oscillator osc[maxo];//should be enough
// max parameters * osc + program + len
#define maxp (para * maxo + 2)
//default modulation scaling up the algorithm
//a mild default spice
#define spice 0.25f

void initOsc(oscillator* p, int num) {
  //basic unitary initialization
  p->vol = pow(spice, num);//max
  p->freq = 0.0f;//440Hz
  p->filt = 0.0f;//440Hz
  p->q = 1.0f;
  //basic scaling initialization
  p->vol_d = 0.0f;
  p->freq_d = 0.0f;
  p->filt_d = 0.0f;
  p->q_d = 0.0f;
  //extra stuff for state management
  p->count = 0.0f;
}

//output PCM_S16_LE
void out(float samp) {
  int16_t i = (int16_t)samp;
  putchar(i & 0xff);
  putchar(i >> 8);
}

//ratiometric frequency scaling
//makes the input parameters nicer
void ratiometric() {
  for(int i = 0; i < maxo; ++i) {
    //filter relative
    osc[i].filt += osc[i].freq;
  }
  for(int i = 1; i < maxo; ++i) {
    //make common frequency basis
    osc[i].freq += osc[i - 1].freq;
    osc[i].filt += osc[i - 1].filt;
  }
}

// scale oscillator sample
float scale(int num) {
  oscillator* p = &osc[num];
  return p->vol * (p->count - waveLen / 2.0f) * 2.0f / waveLen;
}

int main(int argc, char *argv[]) {
  if(argc > maxp) return EXIT_FAILURE;
  len = 1.0f;//1 second
  if(argc > 1) len = atof(argv[1]);
  //some insanity of sound?
  if(len > 16.0f || len < 0.0f) return EXIT_FAILURE;
  for(int i = 0; i < maxo; ++i) {
    initOsc(&osc[i], i);
  }
  oscillator* p = &osc[0];
  for(int i = 0; i < argc - 2; ++i) {
    //fill in osc parameter blocks
    float f = atof(argv[i + 2]);
    int o = i / para;//osc number
    ((float*)(&p[o]))[i % para] = f;
    ratiometric();
  }
  //number of samples to make
  int numSamp = sampRate * len;
  for(int i = 0; i < numSamp; ++i) {
    float mod = 0.0f;
    for(int o = maxo - 1; o != -1; --o) {
      //apply exponential FM
      osc[o].count += step(osc[o].freq * pow(2, mod));
      osc[o].count = fmodf(osc[o].count, waveLen);
      //apply drifts after 100%
      osc[o].vol += osc[o].vol_d / numSamp;
      osc[o].freq += osc[o].freq_d / numSamp;
      mod = scale(o);
    }
    // basic saw++
    out(mod);
  }
  return EXIT_SUCCESS;
}
