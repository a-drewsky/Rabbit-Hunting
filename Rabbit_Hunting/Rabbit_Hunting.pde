int resolution = 700;
PVector[] points = genPoints(); //procedurally generate points
PVector[] path= {points[1], points[0], points[2], points[3], points[5], points[4], points[6], points[7], points[5], points[4], points[2], points[3]};

ArrayList<Hunter> hunters = new ArrayList<Hunter>();
ArrayList<Arrow> arrows = new ArrayList<Arrow>();
Rabbit r = new Rabbit(200, 200, 90, 3, 0.25);
Path p = new Path(path);

boolean debug = false;
int pathRadius=20;

PVector wayPoint;
boolean goingToWP =false;

float targetMag = 250;
float targetAngle = 60;

boolean sizeSet=false;

int saplingCount;
ArrayList<Sapling> saplings = new ArrayList<Sapling>();
ArrayList<Tree> trees = new ArrayList<Tree>();
float pickUpDistance = 10;
float treeHitBox = 40;

int tickTime = 60;
int tickTimer=tickTime;
int seedDropScale = 5; //max distance from tree for seed to spawn
float dropDecRate = 2;

float hunterSpawnChance;
float time=1;
float spawnRate=0.0003;
float hunterSpawnProb = 20; //lower number spawns hunters more often

float arrowSpeed = 0.2;
float shootSpeed = 20;

float initProb = 0.02;

boolean dead=true;
boolean played=false;

//images
PImage arrow;
PImage halfArrow;
PImage bow;
PImage hunterFront;
PImage hunterBack;
PImage hunterSide;
PImage rabbitBack;
PImage rabbitFront;
PImage rabbitLeft;
PImage sapling;
PImage tree;

PImage back;

int tLength=50;

void setup() {
  size(700, 700, P2D);
  surface.setResizable(true);

  arrow = loadImage("images/arrow.png");
  halfArrow = loadImage("images/half-arrow.png");
  bow = loadImage("images/bow.png");
  hunterFront = loadImage("images/hunter-front.png");
  hunterBack = loadImage("images/hunter-back.png");
  hunterSide = loadImage("images/hunter-side.png");
  rabbitBack = loadImage("images/rabbit-back.png");
  rabbitFront = loadImage("images/rabbit-front.png");
  rabbitLeft = loadImage("images/rabbit-side.png");
  sapling = loadImage("images/sapling.png");
  tree = loadImage("images/tree.png");
  back = loadImage("images/texture.jpg");
  imageMode(CENTER);
}

void initialize() {
  saplingCount=0;
  played=true;
  hunters.clear();
  trees.clear();
  saplings.clear();
  arrows.clear();

  dead=false;
  PVector start = new PVector(width, 0);
  saplings.add(new Sapling(random(width/2-width/4, width/2+width/4), random(height/2-height/4, height/2+height/4)));
  hunters.add(new Hunter(start, 1, 0.1, 180));
}

void draw() {
  if (!sizeSet) {
    sizeSet=true;
    back.resize(width,height);
  }
  tint(255);
  image(back,width/2,height/2);
  noTint();
  if (debug)p.display();

  //game tick (for tree growth)
  tickTimer--;
  if (tickTimer<0)tickTimer=tickTime;


  //arrows
  for (Arrow a : arrows) a.update();

  //hunter and rabbit
  if (!dead)r.update();
  r.display();
  if (!dead)hunterChance();
  for (Hunter h : hunters) h.update();
  if (!dead)showWayPoint();

  //trees and saplings
  for (int i=0; i<saplings.size(); i++) {
    Sapling s = saplings.get(i);
    s.update();
    if (dist(s.position.x, s.position.y, r.position.x, r.position.y)<pickUpDistance) {
      saplingCount++;
      saplings.remove(s);
    }
  }
  for (Tree t : trees) t.update();

  //GUI
  if (dead) showGUI();
}

void mouseClicked() {
  if (mouseButton==LEFT) {
    if (!dead) {
      wayPoint = new PVector(mouseX, mouseY); 
      for (Tree t : trees) {
        while (PVector.dist(t.position, wayPoint)<treeHitBox) {
          PVector f = PVector.sub(wayPoint, r.position); 
          f.setMag(f.mag()-1);
          wayPoint = PVector.add(r.position, f);
        }
      }
      goingToWP=true;
    } else if (mouseY>height/2+height/3-10 && mouseY<height/2+height/3+10) {

      if (mouseX>width/2-width/4-tLength && mouseX<width/2-width/4+tLength) { //slow
        spawnRate=0.0001;
        initProb=0.01;
        initialize();
      }
      if (mouseX>width/2-tLength && mouseX<width/2+tLength) { //normal
        spawnRate=0.0003;
        initProb=0.02;
        initialize();
      }
      if (mouseX>width/2+width/4-tLength && mouseX<width/2+width/4+tLength) { //fast
        spawnRate=0.003;
        initProb=0.06;
        initialize();
      }
    }
  }
  if (mouseButton==RIGHT && saplingCount>0) {
    trees.add(new Tree(mouseX, mouseY));
    saplingCount--;
  }
}

void showGUI() {
  fill(50, 200);
  rect(0, 0, width, height);
  textAlign(CENTER);
  textSize(25);
  fill(200);
  text("Rabbit Hunting", width/2, height/2);
  textSize(20);
  if (played)text("trees planted: "+trees.size(), width/2, height/2+height/6);
  if (mouseX>width/2-width/4-tLength && mouseX<width/2-width/4+tLength && mouseY>height/2+height/3-10 && mouseY<height/2+height/3+10) { //slow
    fill(100);
  } else fill(200);
  text("Play Slow", width/2-width/4, height/2+height/3);
  if (mouseX>width/2-tLength && mouseX<width/2+tLength && mouseY>height/2+height/3-10 && mouseY<height/2+height/3+10) { //normal
    fill(100);
  } else fill(200);
  text("Play Normal", width/2, height/2+height/3);
  if (mouseX>width/2+width/4-tLength && mouseX<width/2+width/4+tLength && mouseY>height/2+height/3-10 && mouseY<height/2+height/3+10) { //fast
    fill(100);
  } else fill(200);
  text("Play Fast", width/2+width/4, height/2+height/3);



  if (mouseX>width/2+width/4-tLength && mouseX<width/2+width/4+tLength && mouseY>height/2+height/3-10 && mouseY<height/2+height/3+10) { //fast
    fill(100);
  } else fill(200);
}

void hunterChance() {
  time+=spawnRate;
  hunterSpawnChance=log(time);
  if (tickTimer==0) {
    float f = random(0, hunterSpawnProb);
    if (f<hunterSpawnChance) spawnHunter();
  }
}

void spawnHunter() {
  int x=0;
  int y=0;
  int side = (int)random(0, 4);

  if (side==0) {
    x=-100; 
    y=(int)random(0, height);
  }
  if (side==1) {
    x=width+100; 
    y=(int)random(0, height);
  }
  if (side==2) {
    y=-100; 
    x=(int)random(0, width);
  }
  if (side==3) {
    y=height+100; 
    x=(int)random(0, width);
  }

  hunters.add(new Hunter(new PVector(x, y), 1, 0.1, 180));
  Hunter h = hunters.get(hunters.size()-1);
  h.locatePath();
}

void showWayPoint() {
  stroke(50);
  if (goingToWP) {
    line(wayPoint.x-5, wayPoint.y-5, wayPoint.x+5, wayPoint.y+5); 
    line(wayPoint.x+5, wayPoint.y-5, wayPoint.x-5, wayPoint.y+5);
  }
}

PVector[] genPoints() {
  int count=0;
  PVector[] p = new PVector[8];
  for (int i=0; i<4; i++) {
    for (int j=0; j<2; j++) {
      p[count]= new PVector(resolution/5+(j*(resolution/2))+getOffset(), resolution/5+(i*(resolution/5))+getOffset());
      count++;
    }
  }
  return p;
}

int getOffset() {
  int rez = resolution/24;
  return (int)random(-rez, rez);
}

void showPoints() {
  fill(0);
  int count=0;
  for (PVector p : points) {
    text(count, p.x, p.y);
    count++;
  }
}




//COLLISION DETECTION

//Normal Point
PVector getNormalPoint(PVector p, PVector a, PVector b) {
  PVector ap = PVector.sub(p, a);
  PVector ab = PVector.sub(b, a);
  ab.normalize();
  ab.mult(ap.dot(ab));
  PVector normalPoint = PVector.add(a, ab);
  return normalPoint;
}

// LINE/CIRCLE
boolean lineCircle(float x1, float y1, float x2, float y2, float cx, float cy, float r) {

  // is either end INSIDE the circle?
  // if so, return true immediately
  boolean inside1 = pointCircle(x1, y1, cx, cy, r);
  boolean inside2 = pointCircle(x2, y2, cx, cy, r);
  if (inside1 || inside2) return true;

  // get length of the line
  float distX = x1 - x2;
  float distY = y1 - y2;
  float len = sqrt( (distX*distX) + (distY*distY) );

  // get dot product of the line and circle
  float dot = ( ((cx-x1)*(x2-x1)) + ((cy-y1)*(y2-y1)) ) / pow(len, 2);

  // find the closest point on the line
  float closestX = x1 + (dot * (x2-x1));
  float closestY = y1 + (dot * (y2-y1));

  // is this point actually on the line segment?
  // if so keep going, but if not, return false
  boolean onSegment = linePoint(x1, y1, x2, y2, closestX, closestY);
  if (!onSegment) return false;

  // optionally, draw a circle at the closest
  // point on the line
  if (debug) {
    fill(255, 0, 0);
    noStroke();
    ellipse(closestX, closestY, 20, 20);
  }
  // get distance to closest point
  distX = closestX - cx;
  distY = closestY - cy;
  float distance = sqrt( (distX*distX) + (distY*distY) );

  if (distance <= r) {
    return true;
  }
  return false;
}


// POINT/CIRCLE
boolean pointCircle(float px, float py, float cx, float cy, float r) {

  // get distance between the point and circle's center
  // using the Pythagorean Theorem
  float distX = px - cx;
  float distY = py - cy;
  float distance = sqrt( (distX*distX) + (distY*distY) );

  // if the distance is less than the circle's
  // radius the point is inside!
  if (distance <= r) {
    return true;
  }
  return false;
}


// LINE/POINT
boolean linePoint(float x1, float y1, float x2, float y2, float px, float py) {

  // get distance from the point to the two ends of the line
  float d1 = dist(px, py, x1, y1);
  float d2 = dist(px, py, x2, y2);

  // get the length of the line
  float lineLen = dist(x1, y1, x2, y2);

  // since floats are so minutely accurate, add
  // a little buffer zone that will give collision
  float buffer = 0.1;    // higher # = less accurate

  // if the two distances are equal to the line's
  // length, the point is on the line!
  // note we use the buffer here to give a range,
  // rather than one #
  if (d1+d2 >= lineLen-buffer && d1+d2 <= lineLen+buffer) {
    return true;
  }
  return false;
}
