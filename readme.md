#rt1 - software to make and render molecular movie animations
rt1 is designed to make and render molecular movie animations. The software provides a framework allowing you to load PDB ([Protein Data Bank](http://www.rcsb.org/pdb/home/home.do)) files and easily generate atomic simulations rendered directly to movies. The software is capable of generating and rendering scenes containing millions of atoms. It is multi-threaded and uses OpenCL on either GPUs or CPUs to accelerate the rendering. It will also automatically use multiple GPUs to further accelerate rendering.

#Features
- Generate and animate complex atomic simulations
- Morph between states of a multi-state PDB file
- Multi-threaded and uses OpenCL on multiple GPUs to accelerate rendering
- Built-in ray tracer that can directly render movies
- Can output to Apple Pro-res including alpha-channel for easy compositing
- Ability to have atoms with intrisic (ie internal) lights, scaling to thousands of light sources

#Examples
- [ATPase top view with selective clip plane](https://youtu.be/b2W7l0rWg0w)
- [Row of ATPase dimers in curved membrane](https://youtu.be/P2rfZkK9Lv4)
- [ATPase rotating then zooming into C-ring](https://youtu.be/KMIf79RdINQ)
- [Flagellar motor rotating](https://youtu.be/hFH27Dq2AQ0)
- [Flagellar motor rotation from proton point-of-view](https://youtu.be/8qXhmkV3QSA)

##Installation
###Prerequisites
- A Mac with a reasonable GPU (high-end iMac or Mac Pro) running macOS 10.9 or later

Just clone this repository and load the project in XCode. The initial configuration is an empty scene, but please look at the code in the examples directory to get started.
