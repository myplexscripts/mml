"""Original looping town, ruin and battle scores plus original garden/UI Foley.
Run with Python, numpy and ffmpeg. Runtime playback requires no dependencies.
"""
from pathlib import Path
import numpy as np
import wave, subprocess

OUT = Path(__file__).resolve().parents[1] / 'assets/audio'
RATE = 22050
rng = np.random.default_rng(74)

def hz(note): return 440 * 2 ** ((note - 69) / 12)

def voice(note, length, kind='pluck'):
    t=np.arange(int(length*RATE))/RATE
    f=hz(note)
    if kind=='pad':
        s=np.sin(2*np.pi*f*t)*.55 + np.sin(2*np.pi*f*1.002*t)*.3 + np.sin(4*np.pi*f*t)*.1
        env=np.minimum(1,t/.2)*np.minimum(1,(length-t)/.3)*.4
    elif kind=='bass':
        s=np.sin(2*np.pi*f*t)+np.sin(4*np.pi*f*t)*.18
        env=np.minimum(1,t/.008)*np.exp(-t*2.2)
    else:
        s=np.sin(2*np.pi*f*t)+np.sin(4*np.pi*f*t)*.45+np.sin(6*np.pi*f*t)*.12
        env=np.minimum(1,t/.003)*np.exp(-t*4.5)
    return s*env

def export(name, buffer):
    buffer=np.tanh(buffer*.7)
    stereo=np.column_stack((buffer,np.roll(buffer,103)*.94))
    temporary=OUT/(name+'.wav')
    with wave.open(str(temporary),'wb') as w:
        w.setnchannels(2);w.setsampwidth(2);w.setframerate(RATE)
        w.writeframes((np.clip(stereo,-1,1)*32700).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(temporary),'-c:a','libvorbis','-q:a','4',str(OUT/(name+'.ogg'))],check=True)
    temporary.unlink()

def compose(name,bpm,chords,melody):
    beat=60/bpm; duration=beat*64
    buf=np.zeros(round(duration*RATE))
    def add(note,start,length,kind,volume):
        signal=voice(note,length,kind)*volume; indices=(np.arange(len(signal))+round(start*RATE))%len(buf)
        np.add.at(buf,indices,signal)
    for bar in range(16):
        chord=chords[bar%len(chords)]
        for note in chord: add(note,bar*4*beat,4*beat,'pad',.12)
        for b in range(4):
            add(chord[0]-24,(bar*4+b)*beat,beat*.8,'bass',.24 if name=='town' else .33)
            add(chord[(b+bar)%len(chord)]+12,(bar*4+b+.5)*beat,beat*1.2,'pluck',.11)
        for b,note in enumerate(melody[bar%len(melody)]):
            if note: add(note,(bar*4+b*.5)*beat,beat*1.4,'pluck',.29)
        # Brushed, filtered percussion. The battle loop has a firmer pulse.
        for b in range(8):
            start=round((bar*4+b*.5)*beat*RATE);length=1200
            noise=rng.normal(0,1,length)*np.exp(-np.arange(length)/240)
            noise=np.convolve(noise,np.ones(8)/8,'same')*(.035 if name=='town' else .07)
            np.add.at(buf,(np.arange(length)+start)%len(buf),noise)
    # Circular delay means the tail wraps to the first sample, preserving the loop.
    buf+=np.roll(buf,round(beat*.75*RATE))*.19
    export(name,buf)

compose('town',98,[[60,64,67,71],[57,60,64,67],[53,57,60,64],[55,59,62,69]],
        [[76,0,79,0,81,79,76,0],[72,0,74,76,0,74,72,0],[69,0,72,0,76,74,72,0],[71,0,74,0,79,0,74,0]])
compose('ruins',82,[[45,52,57,60],[41,48,53,57],[43,50,55,58],[40,47,52,55]],
        [[69,0,0,64,0,0,72,0],[65,0,0,69,0,0,64,0],[67,0,0,62,0,0,70,0],[64,0,0,67,0,0,59,0]])
compose('boss',132,[[45,52,57],[41,48,53],[43,50,55],[40,47,52]],
        [[69,69,72,69,76,72,69,64],[65,65,69,65,72,69,65,60],[67,67,70,67,74,70,67,62],[64,64,67,64,71,67,64,59]])
for name,seconds in [('select',.10),('plant',.18),('step',.09),('water',.4)]:
    t=np.arange(round(seconds*RATE))/RATE
    if name=='select': signal=np.sin(2*np.pi*(660*t+1400*t*t))*np.exp(-t*38)*.35
    elif name=='water': signal=np.convolve(rng.normal(0,1,len(t)),np.ones(14)/14,'same')*np.sin(np.pi*t/seconds)*.5
    else: signal=np.convolve(rng.normal(0,1,len(t)),np.ones(7)/7,'same')*np.exp(-t*35)*.4
    export(name,signal)
print('Built three original seamless music loops and four Foley/UI sounds.')
