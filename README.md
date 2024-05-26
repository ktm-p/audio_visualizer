# Audio Visualizer

This is an audio visualizer made in Java Processing. It features usage of Fast Fourier Transforms (FFT) in order to extract frequency information, and uses it to create objects that react to the audio. Things implemented in this project include:
- Lighting system based on the frequencies of the audio.
- Lines representing the FFT for the first ~64% of the frequencies.
- 3D mesh terrain generated using Perlin Noise whose traversal speed depends on the strength of certain frequencies.
- 3D objects rendered based on certain frequencies of the audio, representing its amplitude.
- Concentric circles acting as a tunnel, with edges which reacts to the audio's frequencies and radius representing the audio's level.

## Setup
In order to use the audio visualizer, proceed as follows:
1. Download [Processing (Java)](https://processing.org/download).
2. In your command line, run `git clone https://github.com/ktm-p/audio_visualizer`.
3. Open `audio_visualizer.pde` using the Processing editor.
4. Install and add the `Minim` library by doing: `Sketch > Import Library > Manage Libraries`, then search for `Minim` and install it.
5. Run the program. Press `a` to play/pause the audio.

## Images

Below are some images of the audio visualizer:

![image](https://github.com/ktm-p/audio_visualizer/assets/119767232/752e9be8-4767-4f97-8865-fe170a90b095)

![image](https://github.com/ktm-p/audio_visualizer/assets/119767232/e9b5a4ac-9ad7-4202-ae6e-2f55227f8cad)

![image](https://github.com/ktm-p/audio_visualizer/assets/119767232/765e65a0-21f7-4c02-b559-211c0a264672)

![audio_visualizer](https://github.com/ktm-p/audio_visualizer/assets/119767232/d04464e1-1257-4ab5-8356-a1019d9fb011)
