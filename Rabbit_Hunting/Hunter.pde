class Hunter {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float size;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  PVector predictpos;
  float predictDist = 50;
  PVector target;

  PVector LOS1 = new PVector(0, 0); //for debugging
  PVector LOS2 = new PVector(0, 0); //for debugging
  PVector dir;

  boolean targeted;
  float arriveDist=targetMag; //distance slowing begins
  float shootDistance = targetMag/1.5; //distance to stop and shoot
  int treeTimer=0;

  Edge curEdge = p.edges[0];
  int curEdgeNum=0;
  float bowRestDist = 30;
  boolean bowBehind=false;

  boolean shooting=false;
  float arrowDraw=0;
  float maxDraw=25;
  boolean shot=false;
  int arrowPause=0;
  int pauseTime=30;

  Hunter(PVector l, float ms, float mf, float theta) {
    position = l.copy();
    size = 40.0;
    maxspeed = ms;
    maxforce = mf;
    acceleration = new PVector(0, 0);
    dir= PVector.fromAngle(radians(theta));
    velocity = dir.setMag(maxspeed);
  }

  void getDir() {
    if (velocity.mag()>0.01) {
      dir= velocity.copy();
      dir.normalize();
    }
  }

  void lineOfSightViz() {
    strokeWeight(1);
    if (!targeted)stroke(0);
    else stroke(200, 0, 0);
    noFill();
    if (velocity.mag()>0.1)LOS1 = PVector.fromAngle(radians(-targetAngle)+velocity.heading());
    else LOS1 = PVector.fromAngle(radians(-targetAngle)+dir.heading());
    LOS1.mult(targetMag);
    LOS1.add(position);
    line(LOS1.x, LOS1.y, position.x, position.y);

    if (velocity.mag()>0.1) LOS2 = PVector.fromAngle(radians(targetAngle)+velocity.heading());
    else LOS2 = PVector.fromAngle(radians(targetAngle)+dir.heading());
    LOS2.mult(targetMag);
    LOS2.add(position);
    line(LOS2.x, LOS2.y, position.x, position.y);
    pushMatrix();
    translate(position.x, position.y);
    rotate(dir.heading() + radians(90));
    arc(0, 0, targetMag*2, targetMag*2, radians(-targetAngle)-PI/2, radians(targetAngle)-PI/2);
    popMatrix();
    noStroke();
  }

  void display() {
    PVector theta_ = PVector.sub(r.position, position);
    float theta;
    if (shooting==false) theta = dir.heading() + radians(90);
    else theta = theta_.heading() + radians(90);
    if (debug) {
      fill(175);
      stroke(0);
      strokeWeight(2);
      pushMatrix();
      translate(position.x, position.y);
      rotate(theta);
      beginShape(PConstants.TRIANGLES);
      vertex(0, -size/5);
      vertex(-size/10, size/5);
      vertex(size/10, size/5);
      endShape();
      popMatrix();
    } else {
      theta-=radians(90);
      if (theta>PI/4 && theta<3*PI/4) image(hunterFront, position.x, position.y, size, size*2);
      else if (theta>-PI/4 && theta<PI/4) image(hunterSide, position.x, position.y, size, size*2);
      else if (theta>-3*PI/4 && theta<-PI/4) image(hunterBack, position.x, position.y, size, size*2);
      else {
        pushMatrix();
        translate(position.x, position.y);
        scale(-1.0, 1.0);
        image(hunterSide, 0, 0, size, size*2);
        popMatrix();
      }
    }
  }

  void getTarget() {
    PVector f = PVector.sub(r.position, position);
    boolean blocked=false;
    for (Tree t : trees) {
      PVector col = getNormalPoint(t.position, position, r.position);
      if (PVector.dist(t.position, col)<treeHitBox/2) blocked=true;
    }

    if ((dist(position.x, position.y, r.position.x, r.position.y)<targetMag 
      && (degrees(abs(f.heading()-dir.heading()))<targetAngle || degrees(abs(f.heading()-dir.heading()))>360-targetAngle)
      && blocked==false) || shooting) targeted=true;
  }

  boolean updateEdge(PVector pos, Edge e) { //change current edge when reaching end point
    if (dist(pos.x, pos.y, e.end.x, e.end.y)<2) return true;
    else return false;
  }

  void follow(Edge e) {

    // Predict position
    PVector predict = velocity.get();
    predict.normalize();
    predict.mult(predictDist);
    predictpos = PVector.add(position, predict);

    // Look at the path
    PVector a = e.start;
    PVector b = e.end;

    // Get the normal point to that path
    PVector normalPoint = getNormalPoint(predictpos, a, b);

    // Find target point
    PVector dir_ = PVector.sub(b, a);
    dir_.normalize();
    dir_.mult(10);
    target = PVector.add(normalPoint, dir_);

    float distance = PVector.dist(predictpos, normalPoint);
    if (distance > pathRadius) {
      seek(target);
    }

    // Draw the debugging stuff
    if (debug) {
      fill(0);
      stroke(0);
      line(position.x, position.y, predictpos.x, predictpos.y);
      ellipse(predictpos.x, predictpos.y, 4, 4);

      // Draw normal position
      fill(0);
      stroke(0);
      line(predictpos.x, predictpos.y, normalPoint.x, normalPoint.y);
      ellipse(normalPoint.x, normalPoint.y, 4, 4);
      stroke(0);
      if (distance > pathRadius) fill(255, 0, 0);
      noStroke();
      ellipse(target.x+dir.x, target.y+dir.y, 8, 8);
    }
  }



  void update() { //Update Method
    targeted=false;
    if (arrowPause>0)arrowPause--;
    if (!shooting || dead) arrowDraw=0;
    else shoot();
    if (shot)shootArrow();
    if (treeTimer>=0)treeTimer--;
    avoidTrees();
    getTarget();
    getDir();
    if (debug)lineOfSightViz();
    if (bowBehind) showBowBehind();
    display();
    bowBehind=false;
    showBow();
    if (!targeted)dirForce();
    if (targeted) pursue();
    else if (treeTimer<=0) follow(curEdge);
    if (!targeted)speedUp();
    if (targeted) locatePath();

    if (updateEdge(target, curEdge) && !targeted) {
      if (curEdgeNum<11)curEdgeNum++;
      else curEdgeNum=0;
      curEdge = p.edges[curEdgeNum];
    }

    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
  }

  void showBow() {
    PVector dir_;
    if(targeted)dir_ = PVector.sub(r.position, position);
    else dir_=dir.copy();
    pushMatrix();
    translate(position.x, position.y);
    if (!targeted || dead)rotate(HALF_PI);
    else rotate(dir_.heading());
    float theta=dir_.heading();
    if (theta>-PI/4 && theta<3*PI/4) {
      bowBehind=false;
      image(bow, size/2, 0, size/4, size);
      stroke(100);
      line((size)-arrowDraw-size/1.75, 0, size/2.5, size/2);
      line((size)-arrowDraw-size/1.75, 0, size/2.5, -size/2);
      if (shooting && arrowPause<=0 && !dead) {
        image(arrow, (size*1.2)-arrowDraw-size/4, 0, size, size/4);
      }
    } else{
      bowBehind=true;
    }
    popMatrix();
  }

  void showBowBehind() {

    PVector dir_ = PVector.sub(r.position, position);
    pushMatrix();
    translate(position.x, position.y);
    if (!targeted || dead)rotate(HALF_PI);
    else rotate(dir_.heading());
    image(bow, size/2, 0, size/4, size);
    stroke(100);
    line((size)-arrowDraw-size/1.75, 0, size/2.5, size/2);
    line((size)-arrowDraw-size/1.75, 0, size/2.5, -size/2);
    if (shooting && arrowPause<=0 && !dead) {
      image(arrow, (size*1.2)-arrowDraw-(size/4), 0, size, size/4);
    }
    popMatrix();
  }

  void locatePath() {
    float record=99999;
    for (int i=0; i<p.edges.length; i++) {
      Edge e = p.edges[i];
      PVector p = getNormalPoint(position, e.start, e.end);
      if (dist(position.x, position.y, p.x, p.y)<record) {
        record = dist(position.x, position.y, p.x, p.y);
        curEdgeNum=e.num;
        curEdge=e;
      }
    }
  }

  void pursue() {
    PVector target = r.position.copy();
    PVector desire = PVector.sub(target, position);
    float slow = desire.mag();

    if (slow<arriveDist) {
      float s;
      if(!dead) s = ((maxspeed*2) * ((dist(position.x, position.y, target.x, target.y)-(shootDistance/1.5)) / arriveDist));
      else  s = ((maxspeed*2) * (dist(position.x, position.y, target.x, target.y) / arriveDist));
      desire.setMag(s);
    } else {
      desire.setMag(maxspeed);
      shooting=false;
    }

    PVector steering = PVector.sub(desire, velocity);
    steering.limit(maxforce);
    if ((dist(target.x, target.y, position.x, position.y)>shootDistance && shooting==false && !dead) || (dist(target.x, target.y, position.x, position.y)>r.size && dead)) {
      applyForce(steering);
    } else {
      velocity.mult(0);
      if(!dead)shooting=true;
    }
  }

  void shoot() {
    if (arrowDraw>=maxDraw) shot=true;
    else if (arrowPause<=0) arrowDraw+=arrowSpeed;
  }

  void shootArrow() {
    float arrowDist = new PVector((size*1.2),0).mag();
    arrowDraw-=arrowSpeed*shootSpeed;
    if (arrowDraw<=0) {
      PVector dir_ = PVector.sub(r.position, position);
    PVector arrowLoc = dir_.copy();
    //arrowLoc.rotate(radians(-18));
    arrowLoc.setMag(arrowDist);
    arrowLoc.add(new PVector(position.x+(size)-size/1.75,position.y));
      shot=false;
      arrows.add(new Arrow(arrowLoc.x,arrowLoc.y,dir_.heading(),size,size/4));
      arrowPause=pauseTime;
    }
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  void speedUp() {
    if (velocity.mag()<maxspeed && correctDir()) applyForce(dir.copy().normalize());
  }

  void dirForce() {
    PVector dir_ = PVector.sub(curEdge.end, position);
    float ang = degrees(PVector.angleBetween(velocity, dir_)); 
    if (ang>90 || ang<-90) seek(curEdge.end);
  }

  boolean correctDir() {
    PVector dir_ = PVector.sub(curEdge.end, position);
    float ang = degrees(PVector.angleBetween(velocity, dir_)); 
    if (ang<90 && ang>-90) return true;
    else return false;
  }

  void avoidTrees() {

    for (Tree t : trees) {
      PVector sight = PVector.add(position, velocity.copy().setMag(arriveDist));
      if (lineCircle(position.x, position.y, sight.x, sight.y, t.position.x, t.position.y, treeHitBox*2)) {
        treeTimer=30;
        PVector norm = getNormalPoint(t.position, position, sight);
        PVector f = PVector.sub(norm, t.position);
        f.setMag(maxforce);
        applyForce(f);
      }
    }
  }


  void seek(PVector target) {
    PVector desired = PVector.sub(target, position); 
    if (desired.mag() == 0) return;

    desired.normalize();
    desired.mult(maxspeed);
    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, dir);
    steer.limit(maxforce);  // Limit to maximum steering force

    applyForce(steer);
  }
}
