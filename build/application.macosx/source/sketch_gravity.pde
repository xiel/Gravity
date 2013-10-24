//load serial lib
import processing.serial.*;
Serial port;

//load sound lib
import ddf.minim.*;

float inByte = 0;

boolean useArduino = false;
boolean buttonPressed = false;

int windowWidth = 1200;
int windowHeight = 840;
color backgroundColor = color(3, 3, 15);

int starsCount = 120;
int lightSize = 200;

PGraphics speedLinesLayer;
PGraphics lightLayer;
PGraphics starsLayer;
PGraphics starsLayerFront;

int rotationDir = 1;

float rotationVelocity = .3;
float currentRotation = 0;

float maxPos;
float movingVelocity = 2;
float currentPos = 0;


float lightLayerDiff = .5;
float starsFrontLayerDiff = .2;
float starsBGLayerDiff = .17;
float starsLayerSize = sqrt(sq(max(windowWidth, windowHeight)) * 2);


PImage lightImg;

float G = -1;

//game
PImage logoImg;
boolean gameStarted = false;

//levels
int lvl = 0;
int lvlCount = 3;
boolean nextLvlPending = false;

//score
int scoreTotal = 0;
int scoreLvl = 0;
int scoreGemLvl = 0;

int scoreTimeLvl = 0;
int lvlStartedAt = 0;
boolean hasSeenFinalScores = false;

//highscores
int rankInHighscores = 0;
float averageAll = 0;
float averageTop10 = 0;
IntList highscoresList;
JSONArray highscoresJSON;
int SHOW_MAX_SCORES = 10;
PImage motherImg;


//player
PImage playerImg;
PVector normalDirection = new PVector(1, 0);
float radius = 5;
PVector location;
PVector locationOld;
PVector accel;

int MAX_OLD_LOCATIONS = 100;
PVector[] oldLocations = new PVector[MAX_OLD_LOCATIONS];

//planets
int closestPlanet = -1;
int tmpClosest = -1;

JSONArray planets;
PVector[] planetLocations;
float[] planetRadiuses;

//gems
PImage gemImg;
JSONArray gems;
PVector[] gemLocations;
int collectedGemsCount = 0;

//pending animation
int PLANET_CHANGE_INTERVAL = 3000;
int SHOW_PENDING_AT_LEAST_FOR = 2000;
int pendingStartedAt = 0;
int lastPlanetChange = 0;

//texts
color textColor = color(100, 255, 255);
String textPressButtonStart = "P R E S S   B U T T O N   T O   S T A R T";
String textPressButtonRestart = "P R E S S   B U T T O N   T O   R E S T A R T";
String textPressButtonNextLvl = "P R E S S   B U T T O N   F O R   N E X T   L E V E L";
String textPressButtonHighscores = "P R E S S   B U T T O N   F O R   H I G H S C O R E S";
String textGemsLabel = "G E M S";
String textTimeLabel = "T I M E";
String textTotalLabel = "T O T A L";
String textHighscoresHeadline = "H A L L   O F   F A M E";

//fonts
PFont fontLatoRegular15;
PFont fontLatoBold15;
PFont fontLatoBold18;

//sounds
Minim minim;
AudioPlayer soundBG;
AudioPlayer soundGem;
AudioPlayer soundGravity;


//setup canvas
void setup(){

	//set frame background
	// if(frame){
	// 	frame.setBackground( new java.awt.Color(20,20,20) );
	// }

	//size(windowWidth, windowHeight); //2D size
	
	size(windowWidth, windowHeight, P3D); //3D size
	// smooth();
	
	if(useArduino){
		//init serial
		port = new Serial(this, Serial.list()[10], 9600);
	}

	//init fonts
	fontLatoRegular15 = loadFont("Lato-Regular-15.vlw");
	fontLatoBold15 = loadFont("Lato-Bold-15.vlw");
	fontLatoBold18 = loadFont("Lato-Bold-18.vlw");
	
	//init game
	logoImg = loadImage("logo.png");
	motherImg = loadImage("mother-of-god.png");
	
	//init player
	playerImg = loadImage("player.png");
	location = new PVector(width / 2, height-1);
	locationOld = PVector.sub(location, new PVector(0, -2) );
	
	//init planets
	initPlanets(lvl);
	
	//init gems
	gemImg = loadImage("gem.png");
	initGems(lvl);

	//init sounds
	minim = new Minim (this);
	soundBG = minim.loadFile("Edward_Shallow_-_03_-_You_Are_Lost.mp3");
	soundBG.play();
		soundBG.loop(); //loop sound

	//gem sound
	soundGem = minim.loadFile("gem.mp3");

		//gravity sound
		soundGravity = minim.loadFile("electricity.mp3");

	lightImg = loadImage("light.png");
	
	maxPos = width / 5;
	
	//init stars layer
	starsLayer = createGraphics( int(starsLayerSize), int(starsLayerSize) );
	starsLayerFront = createGraphics( int(starsLayerSize), int(starsLayerSize) );
	lightLayer = createGraphics( int(starsLayerSize), int(starsLayerSize) );
	speedLinesLayer = createGraphics( int(starsLayerSize), int(starsLayerSize) );
	
	println( int(starsLayerSize) );
	
	drawStars();
	drawFrontStars();
	
	restartGame();
	
}

//after finishing a lvl (or the end)
void startNextLvl(){

	int now = millis();
	
	//add pending startet here
	if(!nextLvlPending){
		lvl++;
		nextLvlPending = true;
		pendingStartedAt = millis();

		//if final lvl was played
		if(lvl >= lvlCount){
			println("WIN WIN WIN!!!!" + lvl);
			addToHighscore();
		}
	}

	boolean canGoOn = (now - pendingStartedAt) > SHOW_PENDING_AT_LEAST_FOR;
	
	if(nextLvlPending){
		pendingAnimation();
	}
	
	//if there are more lvls and user presses button
	if(lvl < lvlCount){

		//if user starts next round (and pending was shown long enough)
		if(buttonPressed && canGoOn){

			initPlanets(lvl);
			initGems(lvl);
			nextLvlPending = false;
			gameStarted = true;
			
			scoreLvl = 0;
			scoreGemLvl = 0;
			scoreTimeLvl = 0;
			lvlStartedAt = millis();

			//reset player
			location = new PVector(width / 2, height-1);
			locationOld = PVector.sub(location, new PVector(0, -1) );

		} else
		//start screen
		if(lvl == 0) {
			//draw mask
			drawMask();

			//draw logo
			pushMatrix();
			translate(width/2, height/2);
			imageMode(CENTER);
			image(logoImg, 0, 0);
			popMatrix();

			//draw text "press button"
			pushMatrix();
			textAlign(CENTER);
			translate(width/2, height - 60);
			textFont(fontLatoRegular15);
			textSize(13);
			fill(textColor);
			text(textPressButtonStart, 0, 0);
			popMatrix();
		} else
		//seqence screen (show score)
		{
			drawMask();
			drawScores();

			//draw text "press button"
			pushMatrix();
			textAlign(CENTER);
			translate(width/2, height - 60);
			textFont(fontLatoRegular15);
			textSize(13);
			fill(textColor);
			text(textPressButtonNextLvl, 0, 0);
			popMatrix();
		}

	} else {

		if(!hasSeenFinalScores){
			drawMask();
			drawScores();

			//draw text "press button"
			pushMatrix();
			textAlign(CENTER);
			translate(width/2, height - 60);
			textFont(fontLatoRegular15);
			textSize(13);
			fill(textColor);
			text(textPressButtonHighscores, 0, 0);
			popMatrix();

			if(buttonPressed && canGoOn){
				pendingStartedAt = millis();
				hasSeenFinalScores = true;
			}
		} else {
			drawMask();

			//draw highscores here
			drawHighScores();

			if(buttonPressed && canGoOn){
				restartGame();
			}
		}
	}
}

void drawScores(){
	pushMatrix();

	textFont(fontLatoRegular15);
	textSize(13);
	fill(textColor);

	//gem score
	translate(width/2, height / 4);
	textAlign(RIGHT, TOP);
	text("+" + scoreGemLvl, -20, 0);
	textAlign(LEFT, TOP);
	text(textGemsLabel, 20, 0);

	//time score
	translate(0, 13 + 15);
	textAlign(RIGHT, TOP);
	text("+" + scoreTimeLvl, -20, 0);
	textAlign(LEFT, TOP);
	text(textTimeLabel, 20, 0);

	//total score
	textFont(fontLatoBold15);
	textSize(13);
	translate(0, 13 + 15);
	textAlign(RIGHT, TOP);
	text(scoreTotal, -20, 0);
	textAlign(LEFT, TOP);
	text(textTotalLabel, 20, 0);

	popMatrix();
}

void drawHighScores(){

	pushMatrix();

	fill(textColor);
	translate(width/2, height / 4);

	//headline
	textAlign(CENTER);
	textFont(fontLatoBold18);
	text(textHighscoresHeadline, 0, 0);

	translate(0, 20);

	//draw highscores
	for (int i = 0; i < highscoresList.size() && i < SHOW_MAX_SCORES; i++) {
		//move to correct position
		translate(0, 13 + 15);

		if(i == rankInHighscores){
			textFont(fontLatoBold15);
			textSize(13);
		} else {
			textFont(fontLatoRegular15);
			textSize(13);
		}

		textAlign(RIGHT, TOP);
		text( (i+1) + ".", -15, 0); //human readable ranks ;)
		textAlign(LEFT, TOP);
		text(highscoresList.get(i), 0, 0);
	}

	//rank notice
	translate(0, 80);
	textAlign(CENTER, TOP);
	textFont(fontLatoRegular15);
	textSize(13);

	if(rankInHighscores == 0){
		imageMode(CENTER);
		image(motherImg, 0, 45);
	} else if (scoreTotal > averageTop10) {
		text("D A Y U M !   Y O U ' V E  R E A C H E D   R A N K   " + (rankInHighscores+1), 0, 0);
	} else if (rankInHighscores < 10) {
		text("G R E A T   J O B ,   Y O U ' R E   I N   T H E   T O P   1 0 !   R A N K   " + (rankInHighscores+1), 0, 0);
	} else if (scoreTotal > averageAll) {
		text("M H . . .   A T   L E A S T   B E T T E R   T H A N   A V E R A G E .   R A N K   " + (rankInHighscores+1), 0, 0);
	} else if(rankInHighscores == highscoresList.size() - 1) {
		text("I   D O N ' T   H A V E   A N Y   W O R D S   F O R   T H A T . . .   L A S T   R A N K   " + (rankInHighscores+1), 0, 0);
	} else {
		text("S E R I O U S L Y ? !   T R Y   H A R D E R   N E X T   T I M E ,   T H A T   W A S   R A N K   " + (rankInHighscores+1), 0, 0);
	}

	popMatrix();

	//draw text "press button..."
	pushMatrix();
	textAlign(CENTER);
	translate(width/2, height - 60);
	textFont(fontLatoRegular15);
	textSize(13);
	fill(textColor);
	text(textPressButtonRestart, 0, 0);
	popMatrix();
}

void updateLvlScore(){
	scoreLvl = scoreGemLvl + scoreTimeLvl;
}

void updateTotalScore (){
	scoreTotal = scoreTotal + scoreLvl;
	println("update total score:" + scoreTotal);
}

void addToHighscore(){
	println("ADD TO HIGHSCORE");

	//init list
	highscoresList = new IntList();
	rankInHighscores = 0;

	//reset averages
	averageAll = 0;
	averageTop10 = 0;

	//load json from disk
	highscoresJSON = loadJSONArray("data/highscores.json");

	//find place in highscores and copy to tmp list
	for (int i = 0; i < highscoresJSON.size(); i++) {
		JSONObject highscore = highscoresJSON.getJSONObject(i);
		int thisScore = highscore.getInt("score");

		//check for rank in scores
		if(thisScore >= scoreTotal){
			rankInHighscores++;
		}

		//update averages
		averageAll += thisScore;
		if(i < 10){
			averageTop10 += thisScore;
		}

		highscoresList.append(thisScore);
	}

	//calc averages
	averageAll = round(averageAll / highscoresJSON.size());
	averageTop10 = round(averageTop10 / (highscoresJSON.size() < 10 ? highscoresJSON.size() : 10));

	//append own score to tmp highscore list
	highscoresList.append(scoreTotal);
	highscoresList.sortReverse();

	highscoresJSON = new JSONArray();

	//copy items back to JSON
	for (int i = 0; i < highscoresList.size(); i++) {
		JSONObject highscore = new JSONObject();

		highscore.setInt("score", highscoresList.get(i));
		highscoresJSON.setJSONObject(i, highscore);
	}

	println("RANK IN SCORES: " + rankInHighscores);
	println("averageAll: "+averageAll);
	println("averageTop10: "+averageTop10);

	saveJSONArray(highscoresJSON, "data/highscores.json");
}

void calcTimeScore(){

	int now = millis();

	scoreTimeLvl = round(500 * ((gems.size() * 30 * 1000) / (float(now) - float(lvlStartedAt) )) ) * gems.size();

	println("TIME NEEDED: " + (now - lvlStartedAt) );
	println("TIMESCORE: " + scoreTimeLvl);
}

//draw current score to screen
void drawScore(){
	
	pushMatrix();
	textAlign(RIGHT, TOP);
	translate(width - 10, 10);

	textFont(fontLatoRegular15);
	textSize(13);
	fill(textColor);
	text(scoreLvl, 0, 0);

	popMatrix();
}

void drawMask(){
	translate(0, 0, 1); //draw on top of everything

	pushMatrix();

	fill(0, 50, 50, 255 / 100 * 60);
	rect(0, 0, width, height);

	fill(0, 0, 0, 255 / 100 * 60);
	rect(0, 0, width, height);

	popMatrix();
}

void pendingAnimation(){

	int currentTime = millis();
	
	if(currentTime - lastPlanetChange > PLANET_CHANGE_INTERVAL){
		lastPlanetChange = currentTime;
		int randomPlanet = round(random(1) * (planets.size()-1));
		closestPlanet = randomPlanet;
	}
	
}

void restartGame(){
	// lvl = -1;
	lvl = -1;
	gameStarted = false;
	nextLvlPending = false;
	hasSeenFinalScores = false;
	scoreLvl = 0;
	scoreTotal = 0;
}

void draw(){
	
	float rotation = currentRotation;
	
	if(!useArduino){
		buttonPressed = mousePressed;
	}
	
	//clear canvas
	imageMode(CORNER);
	background(backgroundColor);
	
	//render bg stars layer
	pushMatrix();
	translate( width/2 + currentPos * starsBGLayerDiff, height/2 );
	rotate( radians(rotation * starsBGLayerDiff) );
	//translation: x,y,z z needs to be negative for background
	translate( starsLayerSize / 2 * -1, starsLayerSize / 2 * -1 ); 
	image(starsLayer, 0, 0);
	popMatrix();
	
	//render front star layer
	pushMatrix();
	translate( width/2 + currentPos * starsFrontLayerDiff, height/2 );
	rotate( radians(rotation * starsFrontLayerDiff) );
	translate( starsLayerSize / 2 * -1, starsLayerSize / 2 * -1 );
	image(starsLayerFront, 0, 0);
	popMatrix();
	
	//draw light
	pushMatrix();
	translate( width/2 + currentPos * lightLayerDiff, height/2 );
	rotate( radians(rotation * lightLayerDiff * -1) );
	imageMode(CENTER);
	image(lightImg, 0, 0, lightSize/2, lightSize/2);
	popMatrix();
	
	drawPlanets();
	updateAndDrawPlayer();

	//score
	updateLvlScore();
	drawScore();
	
	if(!nextLvlPending){
		drawGems();
		checkGemCollection();
	}
	
	//startScreen
	if(!gameStarted){
		startNextLvl();
	}
	
	if(gameStarted && gems.size() > 0 && collectedGemsCount == gems.size()){
		//once after win, update scores
		if(!nextLvlPending){
			calcTimeScore();
			updateLvlScore();
			updateTotalScore();
		}
		//pending animation
		startNextLvl();
	}
	
	if(!useArduino){
		if(mouseX > width/2){
			rotationDir = 1;
		} else {
			rotationDir = -1;
		}
	}
	
	//update rotation
	currentRotation = currentRotation + rotationVelocity;
}

void updateAndDrawPlayer(){
	
	//put player back on screen, if he is out
	if(!buttonPressed && !nextLvlPending){
		if(location.x > width){
			location.set(location.x - width, location.y);
			locationOld.set(locationOld.x - width, locationOld.y);
		} else
		if(location.x < 0){
			location.set(location.x + width, location.y);
			locationOld.set(locationOld.x + width, locationOld.y);
		}
		if(location.y > height){
			location.set(location.x, location.y - height);
			locationOld.set(locationOld.x, locationOld.y - height);
		} else
		if(location.y < 0){
			location.set(location.x, location.y + height);
			locationOld.set(locationOld.x, locationOld.y + height);
		}
	}
	
	//acceleration in current frame
	accel = new PVector(0, 0);
	
	//find closest planet
	//if we have no planet yet...
	float closestDistance = 99999999;
	
	//find closest planet
	for (int i = 0; i < planets.size(); i++) {
		float distanceToPlanet = location.dist(planetLocations[i]) - planetRadiuses[i]; //distance betweet planet and player
		
		if(distanceToPlanet < closestDistance){
			closestDistance = distanceToPlanet;
			tmpClosest = i;
		}
	}

	if(buttonPressed && !nextLvlPending){
		  if(!soundGravity.isPlaying()){
			 soundGravity.play();
			 soundGravity.loop();
		  }
	} else {
		  soundGravity.pause();
	}
	
	
	if(buttonPressed || nextLvlPending){
		
		if(closestPlanet == -1){
			closestPlanet = tmpClosest;
		}
		
		//calc distance to closest planet
		float distanceToClosestPlanet = location.dist(planetLocations[closestPlanet]) - planetRadiuses[closestPlanet];
		
		//planet influence
		PVector gravity = PVector.sub(location, planetLocations[closestPlanet]); //direction vector to closest planet
		float planetRadius = planetRadiuses[closestPlanet];
		
		//makes gravity a unit vector (length = 1)
		gravity.normalize();

		
		// gravity.mult(0.1);

		//invert gravity vector, to pull ship
		gravity.mult(-1);

		//add weight (radius) to gravity
		float weightInfluence = 1 + ( (float)Math.pow(planetRadiuses[closestPlanet], 2) / 1700);
		gravity.mult( weightInfluence );
		// println("weightInfluence: "+weightInfluence);

		//reduce gravity depending on distance
		float distanceInfluence = max(0.07 , min(0.12 , 10/distanceToClosestPlanet) );
		gravity.mult( distanceInfluence );
		// println("distanceInfluence: "+distanceInfluence);

		//puts weight on gravity vector
		//gravity.mult( (planetRadius * G) / (float)Math.pow(closestDistance, 2)  ); //(float)Math.pow(closestDistance, 2) 
		
		//add gravity to acceleration
		accel.add(gravity);
	} else {
		closestPlanet = -1;
	}
	
	//calc velocity vector and set new position
	PVector velocityVector = PVector.add( PVector.sub(location, locationOld), accel);
	velocityVector.mult(.998);
	PVector newLocation = PVector.add( location, velocityVector );
	
	//create a draw pos, player can be offscreen if he is connected to a planet
	PVector drawPos = new PVector();
	drawPos = newLocation.get(); //make a copy of the vector, to manipulate draw indepentent from real position
	
	//put player back on screen, if he is out
	if(buttonPressed || nextLvlPending){
		if(drawPos.x > width){
			drawPos.set(drawPos.x - width, drawPos.y);
		} else
		if(drawPos.x < 0){
			drawPos.set(drawPos.x + width, drawPos.y);
		}
		if(drawPos.y > height){
			drawPos.set(drawPos.x, drawPos.y - height);
		} else
		if(drawPos.y < 0){
			drawPos.set(drawPos.x, drawPos.y + height);
		}
	}
	
	//calculate rotation angle
	PVector movementVector = PVector.sub(newLocation, locationOld);
	movementVector.normalize();
	
	//calc angle of ship
	float currentAngle = degrees( PVector.angleBetween(normalDirection, movementVector ) );
	
	//take obtuse angles into account if player moves upwarts
	if(movementVector.y < 0){
		currentAngle = 360 - currentAngle;
	}
	
	currentAngle = radians( currentAngle );
	
	//draw player
	pushMatrix();
	noStroke();
	fill(0, 190, 240);
	translate( drawPos.x , drawPos.y );
	rotate( currentAngle );
	imageMode(CENTER);
	image(playerImg, 0, 0);
	popMatrix();

	//save new and old location
	locationOld = location;
	location = newLocation;
}


//load and init planets
void initPlanets(int lvl){
	
	//reset closest planet
	closestPlanet = -1;
	
	//load planets of lvl
	planets = loadJSONArray("planets-lvl-" + lvl + ".json");
	
	//init location & radius collections
	planetLocations = new PVector[planets.size()];
	planetRadiuses = new float[planets.size()];
	
	//set values of collection
	for (int i = 0; i < planets.size(); i++) {
		JSONObject planet = planets.getJSONObject(i);
		
		planetLocations[i] = new PVector( planet.getFloat("posX"), planet.getFloat("posY") );
		planetRadiuses[i] = planet.getFloat("radius");    
	}
}

//load and init gems
void initGems(int lvl){
	
	collectedGemsCount = 0;
	
	gems = loadJSONArray("gems-lvl-" + lvl + ".json");
	gemLocations = new PVector[gems.size()];
	
	for (int i = 0; i < gems.size(); i++) {
		JSONObject gem = gems.getJSONObject(i);
		
		gem.setBoolean("collected", false);
		gemLocations[i] = new PVector( gem.getFloat("posX"), gem.getFloat("posY") );  
	}
}

//draw gems
void drawGems(){
	for (int i = 0; i < gems.size(); i++) {
		JSONObject gem = gems.getJSONObject(i);
		
		//if gem was already collected, don't show it anymore!
		if(gem.getBoolean("collected")){ continue; }
		
		float size = 20;
		pushMatrix();
		translate( gemLocations[i].x , gemLocations[i].y );
		rotate( radians(currentRotation * 1.5 * -1) );
		imageMode(CENTER);
		image(gemImg, 0, 0);
		popMatrix();
	}
}

//check if player collected a gem
void checkGemCollection(){
	for (int i = 0; i < gems.size(); i++) {
		JSONObject gem = gems.getJSONObject(i);
		
		if(gem.getBoolean("collected")){ continue; }
		
		float distanceFromGem = gemLocations[i].dist(location);
		float size = 20;
		
		if(distanceFromGem < size/1.45){
			println("gem " + i + " COLLECTED!!! " + distanceFromGem);
			gem.setBoolean("collected", true);
			collectedGemsCount++;

						//play sound
						soundGem.play(100);

			//score gem
			scoreGemLvl = scoreGemLvl + round(10000/size);
		}
		
	}
}

//draw planets on screen
void drawPlanets(){
	
	for (int i = 0; i < planets.size(); i++) {
		JSONObject planet = planets.getJSONObject(i); 
		float r = planetRadiuses[i];
		
		pushMatrix();
		noStroke();
		
		if(closestPlanet == -1 && tmpClosest == i){
			strokeWeight(1.5);
			stroke(0, 190, 240, 255 / 1.7);
		} else
		if(closestPlanet == i) {
			strokeWeight(2);
			stroke(0, 190, 240);
		}
		
		fill(90, 10, 220);
		translate( planetLocations[i].x , planetLocations[i].y );
		ellipse(0, 0, r*2, r*2);
		
		popMatrix();
	}
}

//draw stars layer (bg)
void drawStars(){
	starsLayer.beginDraw();
	starsLayer.noStroke();
	
	for(int i = 0; i < starsCount; i++){
		float starSize = random(1, 2);
		starsLayer.fill(255, random(40, 180));
		starsLayer.ellipse(random(starsLayerSize), random(starsLayerSize), starSize, starSize);
	}
	
	starsLayer.endDraw();
}

//draw stars layer (front)
void drawFrontStars(){
	starsLayerFront.beginDraw();
	starsLayerFront.noStroke();
	
	for(int i = 0; i < int(starsCount / 2); i++){
		float starSize = random(3, 4);
		starsLayerFront.fill(255, random(60, 200));
		starsLayerFront.ellipse(random(starsLayerSize), random(starsLayerSize), starSize, starSize);
	}
	
	starsLayerFront.endDraw();
}

void serialEvent(Serial port){
	String inString = port.readStringUntil('\n');
	
	if(inString != null){
		inString = trim(inString);
		inByte = float(inString);
	}
	
	if(useArduino){
		println(inByte);
	}
	
	buttonPressed = inByte > 0 ? true : false;
}




