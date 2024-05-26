import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer player;
AudioMetaData meta;
BeatDetect beat;
FFT fft;

float bufferSize;
int currentPosition;

// Percentage of frequencies chosen from fft.specSize()
float specLow = 0.03;
float specMid = 0.125;
float specHigh = 0.2;

// Scores used to determine the colour
float scoreLow = 0;
float scoreMid = 0;
float scoreHigh = 0;

float prevScoreLow;
float prevScoreMid;
float prevScoreHigh;

int cols, rows;
int scl;

float[][] terrain;
float terrainMovement = 0;

int findDivisor(int dim, int minDiv) {
  int div = minDiv;
  while (dim % div != 0) {
    div++;
  }
  return div;
}

String formatTime(int ms) {
  int t = (int) (ms / 1000);
  int s = t % 60;
  int m = (t - s) / 60;
  
  return String.format("%02d:%02d", m, s);
}

String getName(String fileName) {
  return split(fileName, ".")[0];
}

void keyPressed() {
  if (key == 'a') {
    if (player.isPlaying()) {
      player.pause();
    }
    else if (player.position() == player.length()) {
      player.rewind();
      player.play();
    }
    else {
      player.play();
    }
  }
}

void setup() {
  fullScreen(P3D);
  
  minim = new Minim(this);
  player = minim.loadFile("Everglow.mp3");
  meta = player.getMetaData();
  beat = new BeatDetect();
  
  bufferSize = player.bufferSize();
  
  fft = new FFT(player.bufferSize(), player.sampleRate());

  scl = findDivisor(width, 30);
  
  rows = fft.specSize();
  cols = width/scl;
  
  terrain = new float[cols + 1][rows];
  
  background(0);
}

void draw() {
  fft.forward(player.mix);
  
  prevScoreLow = scoreLow;
  prevScoreMid = scoreMid;
  prevScoreHigh = scoreHigh;
  
  scoreLow = 0;
  scoreMid = 0;
  scoreHigh = 0;
  
  int specSize = fft.specSize();
  for (int i = 0; i < specSize * specLow; i++) {
    scoreLow += fft.getBand(i);
  }
  
  for (int i = (int)(specSize * specLow); i < specSize * specMid; i++) {
    scoreMid += fft.getBand(i);
  }
  
  for (int i = (int)(specSize * specMid); i < specSize * specHigh; i++) {
    scoreHigh += fft.getBand(i);
  }
  
  // For smooth transitions if previous score was higher
  if (prevScoreLow > scoreLow) {
    scoreLow = prevScoreLow - 10;
  }
  
  if (prevScoreMid > scoreMid) {
    scoreMid = prevScoreMid - 10;
  }
  
  if (prevScoreHigh > scoreHigh) {
    scoreHigh = prevScoreHigh - 10;
  }
  
  // Slight background colour changem depending on frequency scores
  color backgroundColor = color(scoreLow/75, scoreMid/75, scoreHigh/75);
  background(backgroundColor);
  
  // Used for movement; faster the stronger the higher frequencies are
  float scoreGlobal = (0.66 * scoreLow) + (0.8 * scoreMid) + (1 * scoreHigh);
  
  float prevBandValue = fft.getBand(0);
  float dist = -25;
  float heightMult = 1.5;
  
  color lineColor = color(100 + scoreLow, 100 + scoreMid, 100 + scoreHigh);
  
  // Moving 3D Terrain at the bottom
  terrainMovement += (scoreGlobal / 2500);
  float zOffset = terrainMovement;
  for (int z = 0; z < rows; z++) {
    float xOffset = 0;
    for (int x = 0; x <= cols; x++) {
      terrain[x][z] = map(noise(xOffset, zOffset), 0, 1, -50, 50);
      xOffset += 0.1;
    }
    zOffset += 0.1;
  }
  
  noFill();
  strokeWeight(1);
  for (int z = 0; z < rows - 1; z++) {
    stroke(lineColor, 255 - z);
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x <= cols; x++) {
      vertex(x * scl, height - terrain[x][z], -z * scl);
      vertex(x * scl, height - terrain[x][z+1], -(z+1) * scl);
    }
    endShape();
  }
  
  //strokeWeight(1 + (scoreGlobal / 300));
  //stroke(lineColor, 255 - 25);
  //line(0, (height / 2) - 25, -25, 0, (height / 2) + 25, -25);
  //line(0, (height / 2) - 25, -25, 0, (height / 2) - 25, -750);
  //line(0, (height / 2) + 25, -25, 0, (height / 2) + 25, -750);
  //line(0, (height / 2) - 25, -750, 0, (height / 2) + 25, -750);
  
  // Top waveform lines
  for (int i = 1; i < fft.specSize(); i++) {
    float bandValue = fft.getBand(i);
    
    stroke(lineColor, 255 - i);
    strokeWeight(1 + (scoreGlobal / 300));
    
    // Bottom left
    line(0, height, dist * (i-1), 0, height, dist * i);
    
    //line(0, height - (prevBandValue * heightMult), dist * (i - 1), 0, height - (bandValue * heightMult), dist * i);
    //line(0, height - (prevBandValue * heightMult), dist * (i - 1), (bandValue * heightMult), height, dist * i);
    //line((prevBandValue * heightMult), height, dist * (i - 1), (bandValue * heightMult), height, dist * i);
    
    // Bottom right
    line(width, height, dist * (i-1), width, height, dist * i);
    
    //line(width, height - (prevBandValue * heightMult), dist * (i - 1), width, height - (bandValue * heightMult), dist * i);
    //line(width, height - (prevBandValue * heightMult), dist * (i - 1), width - (bandValue * heightMult), height, dist * i);
    //line(width - (prevBandValue * heightMult), height, dist * (i - 1), width - (bandValue * heightMult), height, dist * i);
    
    // Top Left
    line(0, (prevBandValue * heightMult), dist * (i-1), 0, (bandValue * heightMult), dist * i);
    line((prevBandValue * heightMult), 0, dist * (i-1), (bandValue * heightMult), 0, dist * i);
    line(0, (prevBandValue * heightMult), dist * (i-1), (bandValue * heightMult), 0, dist * i);
    
    //line(0, 0, dist * (i - 1), 0, 0, dist * i);
    
    // Top Right
    line(width, (prevBandValue * heightMult), dist * (i-1), width, (bandValue * heightMult), dist * i);
    line(width - (prevBandValue * heightMult), 0, dist * (i-1), width - (bandValue * heightMult), 0, dist * i);
    line(width, (prevBandValue * heightMult), dist * (i-1), width - (bandValue * heightMult), 0, dist * i);
    
    //line(width, 0, dist * (i - 1), width, 0, dist * i);
  }
  
  // Center circle
  fill(255, 150);
  textAlign(CENTER, CENTER);
  textSize(35);
  text(getName(meta.fileName()), width/2, height/2 - 25, 0);
  fill(255, 150 - 32);
  text(formatTime(player.position()), width/2, height/2, -1000);
  
  fill(backgroundColor);
  float multiplier = 1 + ((player.left.level() + player.right.level()) / 2);
  stroke(lineColor, 255 - 32);
  translate(0, 0, -1001);
  ellipse(width/2, height/2 - 25, multiplier * (width/5), multiplier * (width/5));
}
