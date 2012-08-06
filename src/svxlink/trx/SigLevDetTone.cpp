/**
@file	 SigLevDetTone.cpp
@brief   A signal level detector using tone in the 5.5 to 6.4kHz band
@author  Tobias Blomberg / SM0SVX
@date	 2009-05-23

\verbatim
SvxLink - A Multi Purpose Voice Services System for Ham Radio Use
Copyright (C) 2003-2012 Tobias Blomberg / SM0SVX

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
\endverbatim
*/



/****************************************************************************
 *
 * System Includes
 *
 ****************************************************************************/

#include <iostream>
#include <cstdio>
#include <cstdlib>


/****************************************************************************
 *
 * Project Includes
 *
 ****************************************************************************/

#include <AsyncConfig.h>
#include <SigCAudioSink.h>
#include <AsyncAudioFilter.h>
#include <common.h>


/****************************************************************************
 *
 * Local Includes
 *
 ****************************************************************************/

#include "SigLevDetTone.h"
#include "Goertzel.h"



/****************************************************************************
 *
 * Namespaces to use
 *
 ****************************************************************************/

using namespace std;
using namespace Async;
using namespace SvxLink;



/****************************************************************************
 *
 * Defines & typedefs
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Local class definitions
 *
 ****************************************************************************/

#if 0
class SigLevDetTone::HammingWindow
{
  public:
    HammingWindow(unsigned wsize)
      : wsize(wsize)
    {
      window = new float[wsize];
      for (unsigned i=0; i<wsize; ++i)
      {
        window[i] = 0.54f - 0.46f * cosf(2*M_PI*(float)i/(float)wsize);
      }
      reset();
    }

    ~HammingWindow(void)
    {
      delete [] window;
    }

    void reset(void)
    {
      wpos = 0;
    }

    float calc(float sample)
    {
      float windowed = sample * window[wpos];
      wpos = wpos < wsize-1 ? wpos+1 : 0;
      return windowed;
    }

  private:
    const unsigned  wsize;
    float           *window;
    unsigned        wpos;
    
    HammingWindow(const HammingWindow&);
    HammingWindow& operator=(const HammingWindow&);
    
};  /* HammingWindow */
#endif


/****************************************************************************
 *
 * Prototypes
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Exported Global Variables
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Local Global Variables
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Public member functions
 *
 ****************************************************************************/

SigLevDetTone::SigLevDetTone(void)
  : tone_siglev_map(10), block_idx(0), last_siglev(0), passband_energy(0.0f)
{
  filter = new AudioFilter("BpBu8/5400-6500");
  setHandler(filter);

  SigCAudioSink *sigc_sink = new SigCAudioSink;
  sigc_sink->sigWriteSamples.connect(
      mem_fun(*this, &SigLevDetTone::processSamples));
  sigc_sink->sigFlushSamples.connect(
      mem_fun(*sigc_sink, &SigCAudioSink::allSamplesFlushed));
  filter->registerSink(sigc_sink, true);

  for (int i=0; i<10; ++i)
  {
    det[i] = new Goertzel(5500 + i * 100, 16000);
    tone_siglev_map[i] = 100 - i * 10;
  }
  reset();
} /* SigLevDetTone::SigLevDetTone */


SigLevDetTone::~SigLevDetTone(void)
{
  delete filter;

  for (int i=0; i<10; ++i)
  {
    delete det[i];
  }
} /* SigLevDetTone::~SigLevDetTone */


bool SigLevDetTone::initialize(Async::Config &cfg, const std::string& name)
{
  string mapstr;
  if (cfg.getValue(name, "TONE_SIGLEV_MAP", mapstr))
  {
    size_t list_len = splitStr(tone_siglev_map, mapstr, ", ");
    if (list_len != 10)
    {
      cerr << "*** ERROR: Config variable " << name << "/TONE_SIGLEV_MAP must "
           << "contain exactly ten comma separated siglev values.\n";
      return false;
    }
  }
  
  return true;
  
} /* SigLevDetTone::initialize */


void SigLevDetTone::reset(void)
{
  for (int i=0; i<10; ++i)
  {
    det[i]->reset();
  }
  block_idx = 0;
  last_siglev = 0;
  passband_energy = 0.0f;
} /* SigLevDetTone::reset */



/****************************************************************************
 *
 * Protected member functions
 *
 ****************************************************************************/



/****************************************************************************
 *
 * Private member functions
 *
 ****************************************************************************/

int SigLevDetTone::processSamples(const float *samples, int count)
{
  for (int i=0; i<count; ++i)
  {
    const float &sample = samples[i];

    passband_energy += sample * sample;

    for (int detno=0; detno < 10; ++detno)
    {
      det[detno]->calc(sample);
    }
    
    if (++block_idx == BLOCK_SIZE)
    {
      float max = 0.0f;
      int max_idx = -1;
      for (int detno=0; detno < 10; ++detno)
      {
        float res = det[detno]->relativeMagnitudeSquared();
        det[detno]->reset();
        if (res > max)
        {
          max = res;
          max_idx = detno;
        }
      }

      last_siglev = 0;
      if (max > 1.0e-6f)
      {
        float peak_to_tot_pwr = 2.0f * max / (BLOCK_SIZE * passband_energy);
        if ((peak_to_tot_pwr < 1.5f) && (peak_to_tot_pwr > 0.5f))
        {
          last_siglev = tone_siglev_map[max_idx];
          //printf("fq=%d  max=%f  siglev=%d  quality=%.1f\n",
          //       5500 + max_idx * 100, max, last_siglev, peak_to_tot_pwr);
        }
      }
      passband_energy = 0.0f;
      block_idx = 0;
    }
  }
  
  return count;
  
} /* SigLevDetTone::processSamples */



/*
 * This file has not been truncated
 */

