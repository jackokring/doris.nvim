#include <stdlib.h>
#include <stdio.h>
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
#define step(f) (waveLen * f * pitchA / sampRate)
float len;
oscillator osc[maxo];//should be enough
// max parameters * osc + program + len
#define maxp (para * maxo + 2)

void initOsc(oscillator* p) {
  //basic unitary initialization
  p->vol = 1.0f;//max
  p->freq = 1.0f;//440Hz
  p->filt = 1.0f;//440Hz
  p->q = 1.0f;
  //basic scaling initialization
  p->vol_d = 0.0f;
  p->freq_d = 0.0f;
  p->filt_d = 0.0f;
  p->q_d = 0.0f;
  //extra stuff for state management
}

//output PCM_S16_LE
void out(float samp) {
  int16_t i = (int16_t)samp;
  putchar(i & 0xff);
  putchar(i >> 8);
}

int main(int argc, char *argv[]) {
  if(argc > maxp) return EXIT_FAILURE;
  len = 1.0f;//1 second
  if(argc > 1) len = atof(argv[1]);
  //some insanity of sound?
  if(len > 16.0f || len < 0.0f) return EXIT_FAILURE;
  for(int i = 0; i < maxo; ++i) {
    initOsc(&osc[i]);
  }
  oscillator* p = &osc[0];
  for(int i = 0; i < argc - 2; ++i) {
    //fill in osc parameter blocks
    float f = atof(argv[i + 2]);
    int o = i / para;//osc number
    ((float*)(&p[o]))[i % para] = f;
  }
  //number of samples to make
  int numSamp = sampRate * len;
  return EXIT_SUCCESS;
}
