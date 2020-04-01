class Sapling {
  
  PVector position;
  int size = 20;
  
  
 Sapling(float x, float y){
   position = new PVector(x,y);
 }
  
  void update(){
    if(debug){
    noFill();
    strokeWeight(4);
    stroke(25);
    ellipse(position.x,position.y,pickUpDistance,pickUpDistance);
    }else{
     image(sapling,position.x,position.y,size,size*1.5); 
    }
  }
  
  
}
