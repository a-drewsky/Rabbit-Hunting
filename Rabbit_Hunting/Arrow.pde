class Arrow {

  PVector position;
  PVector velocity;
  PVector size;
  boolean hit=false;

  Arrow(float x, float y, float theta, float sX, float sY) {
    position = new PVector(x, y);
    velocity = PVector.fromAngle(theta);
    velocity.setMag(arrowSpeed*shootSpeed);
    size = new PVector(sX, sY);
  }

  void update() {
    if (debug) {
      stroke(200, 0, 0);
      strokeWeight(5);
      point(position.x, position.y);
      strokeWeight(1);
      stroke(0);
    }
    display();
    if (!hit)position.add(velocity);

    PVector tip = new PVector(position.x-size.x/2, position.y);

    for (Tree t : trees) {
      if (PVector.dist(tip, t.position)<treeHitBox/2) {
        hit=true;
      }
    }

    if (PVector.dist(tip, r.position)<r.size) {
      hit=true;
      dead=true;
    }
  }

  void display() {

    pushMatrix();
    translate(position.x-size.x/2, position.y);
    rotate(velocity.heading());
    if (!hit)image(arrow, 0, 0, size.x, size.y);
    else image(halfArrow, 0, 0, size.x, size.y);

    popMatrix();
  }
}
