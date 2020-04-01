class Path {

  // A Path is an arraylist of points (PVector objects)
  PVector[] points;
  Edge[] edges;
  
  Path(PVector[] p) {
    points = p;
    edges = new Edge[p.length];
    for(int i=0; i<p.length; i++){
      if(i<points.length-1) edges[i]= new Edge(points[i],points[i+1],i);
      else edges[i]= new Edge(points[i],points[0],points.length-1);
    }
  }


  // Draw the path
  void display() {
    // Draw thick line for radius
    stroke(175);
    strokeWeight(pathRadius*2);
    noFill();
    beginShape();
    for (PVector v : points) {
      vertex(v.x, v.y);
    }
    vertex(points[0].x,points[0].y);
    endShape();
    // Draw thin line for center of path
    stroke(0);
    strokeWeight(1);
    noFill();
    beginShape();
    for (PVector v : points) {
      vertex(v.x, v.y);
    }
    vertex(points[0].x,points[0].y);
    endShape();
  }
}
