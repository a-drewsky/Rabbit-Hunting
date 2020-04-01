class Tree {

  PVector position;
  boolean adult;
  float growProb = initProb;
  float dropProb = initProb;
  int seedsDropped=0;

  Tree(int x, int y) {
    position = new PVector(x, y);
  }

  void update() {
    if (!adult)grow();
    else if (!dead) drop();


    strokeWeight(2);
    stroke(25);
    if (debug) {
      if (!adult)ellipse(position.x, position.y, treeHitBox, treeHitBox);
      else ellipse(position.x, position.y, treeHitBox, treeHitBox*2);
    } else {
      if (!adult)image(tree, position.x, position.y-10, treeHitBox/2, treeHitBox);
      else image(tree, position.x, position.y-10, treeHitBox, treeHitBox*2);
    }
  }

  void grow() {
    if (tickTimer==0) {
      float chance = random(0, 1);
      if (chance<growProb) adult=true;
      else growProb+=initProb;
    }
  }

  void drop() {
    if (tickTimer==0) {
      float chance = random(0, 1);
      if (chance<dropProb/((seedsDropped+1)*dropDecRate)) dropSeed();
      else dropProb+=initProb;
    }
  }

  void dropSeed() {
    dropProb=initProb;
    int mag = (int)random(treeHitBox, treeHitBox*seedDropScale);
    float angle = random(0, TWO_PI);
    PVector location = PVector.fromAngle(angle);
    location.setMag(mag);
    location.add(position);
    for (Tree t : trees) {
      if (PVector.dist(location, t.position)<treeHitBox) {
        dropSeed();
        return;
      }
    }
    seedsDropped++;
    saplings.add(new Sapling(constrain(location.x, 0, width), constrain(location.y, 0, height)));
  }
}
