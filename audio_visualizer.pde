import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer player;
AudioMetaData meta;
BeatDetect beat;
FFT fft;

int currentPosition;

// Percentage of frequencies chosen from fft.specSize()
float specLow = 0.03;
float specMid = 0.125;
float specHigh = 0.2;

// Scores used to determine the colour
float scoreLow = 0;
float scoreMid = 0;
float scoreHigh = 0;

// Previous scores to make smooth transition
float prevScoreLow;
float prevScoreMid;
float prevScoreHigh;

// Information for Cubes
Cube[] cubes;
int numCubes;
float theta = 0;

// Information for 3D Terrain Generation
int cols, rows; // Rows is calculated as fft.specSize() * (specLow + specMid + specHigh); used for other things as well.
int scale;
float[][] terrain;
float terrainMovement = 0; // Starting position of the 3D Terrain

// Text Transparency
int textTransparency = 0;

// Calculates smallest divisor greater than or equal to specified value
int findDivisor(int dim, int minDiv) {
  int div = minDiv;
  while (dim % div != 0) {
    div++;
  }
  return div;
}

// Formats time (in milliseconds) in MM:SS format
String formatTime(int ms) {
  int t = (int) (ms / 1000);
  int s = t % 60;
  int m = (t - s) / 60;
  
  return String.format("%02d:%02d", m, s);
}

// Extracts file name, separating it from the .mp3
String getName(String fileName) {
  return split(fileName, ".mp3")[0];
}

// Enables user to play/pause the audio. Uses 'a' key.
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
    
  fft = new FFT(player.bufferSize(), player.sampleRate());

  scale = findDivisor(width, 30);
  rows = int(fft.specSize() * (specLow + specMid + specHigh));
  cols = width/scale;
  terrain = new float[cols + 1][rows];
  
  numCubes = (int)(fft.specSize() * specHigh);
  cubes = new Cube[numCubes];
  
  //Créer tous les objets
  //Créer les objets cubes
  for (int i = 0; i < numCubes; i++) {
   cubes[i] = new Cube(); 
  }
  
  background(0);
}

void draw() {
  fft.forward(player.mix);
  
  // Reassigns last draw's scores to prevScore variables
  prevScoreLow = scoreLow;
  prevScoreMid = scoreMid;
  prevScoreHigh = scoreHigh;
  
  // Re-initializes scores to zero
  scoreLow = 0;
  scoreMid = 0;
  scoreHigh = 0;
  
  // Initializes scores with amplitudes of each section
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
  
  // Defining colors to be used
  color lineColor = color(100 + scoreLow, 100 + scoreMid, 100 + scoreHigh);
  //color circleColor = color(100 + scoreLow, 0, 25 + scoreHigh);
  
  pushMatrix();
  //translate(width / 2, height / 2);
  //rotateZ(theta);
  //translate(-width / 2, -height / 2);
  
  theta += (scoreGlobal / 1000) * (PI / 1000);

  // 3D TERRAIN
  // Moving terrain
  terrainMovement += (scoreGlobal / 2500) + 0.01;
  // Populating terrain array with values
  float zOffset = terrainMovement;
  for (int z = 0; z < rows; z++) {
    float xOffset = 0;
    for (int x = 0; x <= cols; x++) {
      terrain[x][z] = map(noise(xOffset, zOffset), 0, 1, -50, 50);
      xOffset += 0.1;
    }
    zOffset += 0.1;
  }
  // Drawing the 3D Terrain using Perlin Noise
  noFill();
  strokeWeight(1);
  for (int z = 0; z < rows - 1; z++) {
    stroke(lineColor, 255 - z);
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x <= cols; x++) {
      vertex(x * scale, height - terrain[x][z], -z * scale);
      vertex(x * scale, height - terrain[x][z+1], -(z+1) * scale);
    }
    endShape();
  }
  
  
  for(int i = 0; i < numCubes; i++)
  {
    float bandValue = fft.getBand(i);
    cubes[i].display(scoreLow, scoreMid, scoreHigh, bandValue, scoreGlobal);
  }
  
  // Bar tracking track position
  //strokeWeight(1 + (scoreGlobal / 300));
  //stroke(lineColor, 255 - 25);
  //line(0, (height / 2) - 25, -25, 0, (height / 2) + 25, -25);
  //line(0, (height / 2) - 25, -25, 0, (height / 2) - 25, -750);
  //line(0, (height / 2) + 25, -25, 0, (height / 2) + 25, -750);
  //line(0, (height / 2) - 25, -750, 0, (height / 2) + 25, -750);
  
  // WAVEFORM LINES
  // Calculating values to be used for waveform lines
  float prevBandValue = fft.getBand(0);
  float dist = -25;
  float heightMult = 1.5;
  
  // Drawing waveform lines
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
  
  if (!player.isPlaying()) {
    textTransparency -= 5;
    textTransparency = max(0, textTransparency);
  } else {
    textTransparency += 5;
    textTransparency = min(150, textTransparency);
  }
  
  // CENTER TEXT
  // Song name text
  fill(255, 150 - textTransparency);
  textAlign(CENTER, CENTER);
  textSize(35);
  text(getName(meta.fileName()), width/2, height/2 - 25, 0);
  // Current track position text
  fill(255, 150 - 32 - textTransparency);
  text(formatTime(player.position()), width/2, height/2, -1000);
  
  popMatrix();
  
  // CENTER CIRCLE
  //fill(backgroundColor, 255 - 64);
  //strokeWeight(2);
  //stroke(circleColor, 255 - 64);
  //// Averages the level of the left and right audio streams
  //float multiplier = (player.left.level() + player.right.level()) / 10;
  //translate(width/2, height/2, -2000);
  //// Drawing center circle
  //for (int s = -1; s <= 1; s += 2) {
  //  beginShape();
  //  for (float theta = 0; theta <= 180; theta += 0.5) {
  //    // Mapping angle to frequency band
  //    int i = (int) map(theta, 0, 180, 0, rows);
  //    // Radius for frequency band
  //    float r = (fft.getBand(i) * 1.25) + ((width / 5) * (1 + multiplier));
  //    float x = r * sin(radians(theta));
  //    float y = r * cos(radians(theta));
  //    // Plotting frequency band vertex
  //    vertex(s * x, y);
  //  }
  //  endShape();
  //}
}

class Cube {
  float startingZ = -10000;
  float maxStartingZ = -2000;
  float maxZ = 1000;
  
  float x, y, z;
  float rotX, rotY, rotZ;
  float sumRotX, sumRotY, sumRotZ;
  
  float lastValue;
  
  Cube() {
    x = random(0, width);
    y = random(0, height / 2);
    z = random(startingZ, maxStartingZ);
    
    rotX = random(0, 1);
    rotY = random(0, 1);
    rotZ = random(0, 1);
  }
  
  void drawSelf(float bandValue) {
    box(50 + (bandValue / 5));
  }
  
  void display(float scoreLow, float scoreMid, float scoreHigh, float bandValue, float scoreGlobal) {
    color fillColor;
    color strokeColor;
    if (player.isPlaying()) {
      fillColor = color(scoreLow, scoreMid, scoreHigh, bandValue * 10);
      strokeColor = color(255, 150 - (20 * bandValue));
      
      lastValue = bandValue;
    }
    else {
      fillColor = color(scoreLow, scoreMid, scoreHigh, lastValue * 10);
      strokeColor = color(255, max(150 - (20 * lastValue/10), 15));
      
      lastValue += 1;
    }
    
    fill(fillColor);
    stroke(strokeColor);
    strokeWeight(1 + (scoreGlobal / 500));
    
    pushMatrix();
    translate(x, y, z);
    
    sumRotX += max(bandValue, 1) * (rotX / 250);
    sumRotY += max(bandValue, 1) * (rotY / 250);
    sumRotZ += max(bandValue, 1) * (rotZ / 250);
    
    rotateX(sumRotX);
    rotateY(sumRotY);
    rotateZ(sumRotZ);
    
    drawSelf(bandValue);
    popMatrix();
    
    z += 5 + bandValue + pow(scoreGlobal/200, 2);
    
    if (z >= maxZ) {
      x = random(0, width);
      y = random(0, height / 2);
      z = startingZ;
    }
  }
}

class Pyramids {
  ;
}
