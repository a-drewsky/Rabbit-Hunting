class Rabbit {

  PVector position;
  PVector velocity;
  PVector acceleration = new PVector(0, 0);
  float maxForce;    // Maximum steering force
  float maxSpeed;    // Maximum speed
  PVector dir;
  float size = 20;

  float arriveDist=50;
  int treeTimer=0;

  Rabbit(float x, float y, float theta, float ms, float mf) {
    maxSpeed = ms;
    maxForce = mf;
    position = new PVector(x, y);
    dir= PVector.fromAngle(radians(theta));
    velocity = dir.setMag(0);
  }

  void update() {
    if (treeTimer>0)treeTimer--;
    getDir();
    speedUp();
    if (goingToWP)avoidTrees();
    if (goingToWP && treeTimer==0)arrive();

    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    acceleration.mult(0);
  }

  void speedUp() {
    PVector f = new PVector(dir.x, dir.y);
    f.mult(0.2);
    if (goingToWP && dist(position.x, position.y, wayPoint.x, wayPoint.y)>arriveDist && correctDir()  && velocity.mag()<maxSpeed) applyForce(f);
  }

  boolean correctDir() {
    PVector dir = PVector.sub(wayPoint, position);
    float ang = degrees(PVector.angleBetween(velocity, dir)); 
    if (ang<90 && ang>-90) return true;
    else return false;
  }

  void display() {
    float m = velocity.mag();
    float theta;
    if (m>0.01) {
      theta = velocity.heading();
    } else {
      theta = dir.heading();
    }

    if (debug) {
      noStroke();
      fill(0);
      pushMatrix();
      translate(position.x, position.y);
      rotate(theta);
      beginShape();
      vertex(0, 0);
      vertex(-size/2, -size/8);
      vertex(-size/2, size/8);
      endShape();
      popMatrix();
    } else {
      if (theta>PI/4 && theta<3*PI/4) image(rabbitFront, position.x, position.y, size, size*1.5);
      else if (theta>3*PI/4 || theta<-3*PI/4) image(rabbitLeft, position.x, position.y, size, size*1.5);
      else if (theta>-3*PI/4 && theta<-PI/4) image(rabbitBack, position.x, position.y, size, size*1.5);
      else {
        pushMatrix();
        translate(position.x,position.y);
        scale(-1.0, 1.0);
        image(rabbitLeft, 0,0, size, size*1.5);
        popMatrix();
      }
    }
  }

  void getDir() {
    if (velocity.mag()>0.01) {
      dir= new PVector(velocity.x, velocity.y);
      dir.normalize();
    }
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  void avoidTrees() {

    for (Tree t : trees) {
      if (PVector.dist(position, t.position)<PVector.dist(position, wayPoint)) {
        PVector sight = PVector.add(position, velocity.copy().setMag(arriveDist));
        if (lineCircle(position.x, position.y, sight.x, sight.y, t.position.x, t.position.y, treeHitBox)) {
          treeTimer=30;
          PVector norm = getNormalPoint(t.position, position, sight);
          PVector f = PVector.sub(norm, t.position);
          f.setMag(maxForce);
          applyForce(f);
        }
      }
    }
  }

  void arrive() {
    PVector target = wayPoint.copy();
    PVector desire = PVector.sub(target, position);
    float slow = desire.mag();

    if (slow<arriveDist) {
      float s = (maxSpeed * (dist(position.x, position.y, target.x, target.y) / arriveDist));
      desire.setMag(s);
    } else desire.setMag(maxSpeed);

    PVector steering = PVector.sub(desire, velocity);
    steering.limit(maxForce);
    if (dist(wayPoint.x, wayPoint.y, position.x, position.y)>2)applyForce(steering);
    else {
      velocity.mult(0);
      goingToWP=false;
    }
  }
}
