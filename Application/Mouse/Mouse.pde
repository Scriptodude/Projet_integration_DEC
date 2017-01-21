// Fait par : Jonathan Lavigne
// Temps de réalisation : 5h+
// Contrôle le mouvement de la souris via
// les données du gyroscope
// Créé le : 10 Avril 2015 - Jonathan Lavigne

import processing.serial.*;
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;

// Librairies pour le robot qui contrôle la souris
import java.awt.*;
import java.awt.event.InputEvent;

/***
Speed Modes Definition
***/

final int CONSTANT_SPEED = 0;    // la vitesse est constante, toujours identique.
final int DELTA_ANGLE_SPEED = 1;  // la vitesse varie selon l'écart entre les angles.

/***
Constantes pour le mouvement de la souris
***/
final int WIN_SIZE_X = 250;
final int WIN_SIZE_Y = 250;
final int WIN_X = 1440 - WIN_SIZE_X;  // Position de la fenêtre en X
final int WIN_Y = 0;     // Position de la fenêtre en Y

/***
Variables Initiales
***/
final int INIT_SPEED_MODE = 0;
final int[] INIT_ANGLE_TRESH = {15, 15, 15};
final int[] INIT_SPEED = {5, 5, 5};
final int INIT_SENSIBILITY = 6;
String path = "D:/Processing/Mouse/Config.conf";

//////////////////////////////////////////////
/////// Variables Configurables //////////////
/********************************************/
int[] ANGLE_TRESH = INIT_ANGLE_TRESH;  // tous les angles entre initAngle et initAngle ± ANGLE_TRESH sont considérés comme inertes
int SPEED_MODE = INIT_SPEED_MODE;
int[] SPEED = INIT_SPEED;          // Vitesse si de déplacement de la souris en mode constant
int SENSIBILITY = INIT_SENSIBILITY;               // Sensibilité du mode de vitesse Delta angle

// ********** Exemple de package venant du port série **********
// Package envoyé dans le port série
// Format : {'a', 2, yaw, neg?, pitch, neg?, 'b', roll, neg?,
//           'c', flex, 'd', Left_Contact?, Right_Contact?,
//           'e', '\r', '\n'} 
// *************************************************************
//////////////////////////////////////////////
///// Variables pour le port série ///////////
/********************************************/
final int maxSize = 17;
Serial port;
char[] packet = new char[maxSize]; // Recevra les données port série
int serialCount = 0;                // Dans quel bit du package on est
int aligned = 0;                    // si on est bien alignés sur les données (Voir Exemple Package)
int interval = 0;                   // Interval de temps

/////////////////////////////////////////////
// Variables pour la stabilisation des données
/*******************************************/
boolean stable = false;
boolean dataStarted = false;
int totalTime = 0;
int startTime = 0;
int[] lastAngle = new int[3];
int angleCount = 0;
String message = "Veuillez ne pas bouger pendant la stabilisation des données";

//////////////////////////////////////////////
///// Variables pour la rotation ///////////
/********************************************/
// Déf des angles : http://en.wikipedia.org/wiki/Euler_angles
int[] angle = new int[3];                 // Psi (Autour axe Z) = 0, Théta (autour axe des Y) = 1, phi (autour axe des X) = 2
int[] initAngle = new int[3];             // Angles initiaux

//////////////////////////////////////////////
///// Variables pour la position ///////////
/********************************************/
int[] position = new int[2];
int[] variation = new int[2];

//////////////////////////////////////////////
///////// Variables pour la souris ///////////
/********************************************/
int lastLeftClick = 0;
final int leftClickInterval = 250;
boolean leftReleased = false;
int leftClick = 0;

int lastRightClick = 0;
final int rightClickInterval = 250;
boolean rightReleased = false;
int rightClick = 0;

int flexPos = 0;
boolean appStarted = false;
Robot robot;

//////////////////////////////////////////////
//// Variables pour la lecture du fichier ////
/********************************************/
BufferedReader reader; // Lecteur de fichier
String line;           // Ligne actuelle dans le fichier
boolean reseted = false;
int lastRead = 0;
int intervalRead = 1000;

void setup(){
  size(WIN_SIZE_X, WIN_SIZE_Y);  // Grosseur de l'écran
  appStarted = true;
  
  try {  // Tentative de création du robot, demande la gestion d'exception
    robot = new Robot();
    reader = createReader(path);
  } 
  catch (AWTException e) {
    e.printStackTrace();
  }
  
  // Défs du port série
  port = new Serial(this, "COM4", 115200); // On ouvre le port série COM4
  
  port.write('r');  // On écrit quelque chose sur le port série pour commencer le transfert de données
}

/*****************************
* Boucle Principale de dessin*
*****************************/
void draw(){ 
    
  // à chaques secondes on envoie une lettre pour garder le port série actif
  if(millis() - interval > 1000){
     port.write('z');
     interval = millis(); 
  }
  
    // Remplit le fond de blanc, et le reste en noir.
    background(255);
    fill(0);
  
  if(stable){
      if((millis() - lastRead) > intervalRead){
       lastRead = millis();
       parseFile();  // On reçoit les données nécessaire au fonctionnement de l'application 
      }

        // Se produit uniquement au lancement de l'appliaction
    if(appStarted){
       appStarted = false;
       frame.setLocation(WIN_X, WIN_Y); // on met la fenêtre dans le deuxième écran pour qu'il ne nuit pas
    }
    
    // On calcule la variation d'angle venant du gyroscope
    getMouvementVariation();
      
    // On met une contraite à la souris pour qu'elle reste dans le premier écran
    position[0] = constrain(position[0]+variation[0], 0, 1435);  
    position[1] = constrain(position[1]+variation[1], 0, 895);
    // Dessin du rectangle à la position voulue
    robot.mouseMove(position[0], position[1]);
    
    // Lors du click, on appèle l'événement correspondant
    CheckMouseClick(); 

  }
  else {
    
    // Message pour faire patienter l'utilisateur
   frame.setLocation(100, 250);
   waitStableData();
   textSize(18);
   text(message, 0, 0, WIN_SIZE_X, WIN_SIZE_Y);
   text("Temps passé : "+totalTime/1000 + "s   Sur un max de : 20s", 0, height/2+35, WIN_SIZE_X, WIN_SIZE_Y); 
  }
}



/* Le code suivant a été copié-collé de l'exemple MPU-teapot
*** Les commentaires ont été traduits et le code expliqué plus  clairement
************************************************************/
void serialEvent(Serial port) {
    interval = millis(); // on reçoit l'interval de temps pour la réécriture sur le port série

// Format : {'a', 2, yaw, neg?, pitch, neg?, 'b', roll, neg?,
//           'c', flex, 'd', Left_Contact?, Right_Contact?,
//           'e', '\r', '\n'} 

    while (port.available() > 0) {
        int ch = port.read();  // Lecture du caractère du port série
        
        if (ch == 'a') {serialCount = 0;} // Si le caractère est $, alors nous sommes à la position 0 du packet.
        if (aligned < 5) {
          // ensuite on vérifie les caractères 1 à maxSize-1 pour s'assurer que les données sont bien alignées
            if (serialCount == 0) {
                if (ch == 'a') aligned++; else aligned = 0;
            } else if (serialCount == 1) {
                if (ch == 2) aligned++; else aligned = 0;
            } else if (serialCount == 6) {
                if (ch == 'b') aligned++; else aligned = 0;
            } else if (serialCount == 9) {
                if (ch == 'c') aligned++; else aligned = 0;
            } else if (serialCount == 11) {
                if (ch == 'd') aligned++; else aligned = 0;
            } else if (serialCount == maxSize-3) {
                if (ch == 'e') aligned++; else aligned = 0;
            } else if (serialCount == maxSize-2) {
                if (ch == '\r') aligned++; else aligned = 0;
            } else if (serialCount == maxSize-1) {
                if (ch == '\n') aligned++; else aligned = 0;
            }
               
            //println(ch + " " + aligned + " " + serialCount);
            serialCount++;
            if (serialCount == maxSize) serialCount = 0; // Si on a atteint maxSize(dans ce cas 8) données, on recommence
        } else {
          if (serialCount > 0 || ch == 'a') {
                packet[serialCount++] = (char)ch; // On écrit les données dans le packet lorsqu'on est aligné
                if (serialCount == maxSize) {
                    serialCount = 0; // on recommence la lecture des données
                    
                    angleCount ++;
                    dataStarted = true;
                    
                    // Si on a pas encore stabilisé les données
                    if(!stable && angleCount > 30){
                      angleCount = 0;
                      for(int i=0; i<3; i++){
                       lastAngle[i] = angle[i];
                      }
                      
                    }                    
                    
                    // Les angles arrivent en radian x100, le byte suivant indique s'il est négatif ou positif
                    angle[0] = packet[3]==1 ? -(packet[2]) : packet[2]; 
                    angle[1] = packet[5]==1 ? -(packet[4]) : packet[4];
                    angle[2] = packet[8]==1 ? -(packet[7]) : packet[7];
                    
                    flexPos = (int)packet[10];
                    leftClick = 1-(int)packet[12];
                    rightClick = 1-(int)packet[13];
                    
                    // les données arrivent en radian, 100x plus grandes, on les transforment alors en degrés
                    for(int i=0; i<3; i++){
                      angle[i] = (int)(angle[i] * 180/PI)/100;
                    }
                    
                }
            }
        }
    }
}

/******************************************************
// La fonction calcul la variation du mouvement
// selon l'angle du gyroscope et selon le mode
// de mouvement.
******************************************************/
void getMouvementVariation() {
 
  int axis = 0; // l'axe sur lequel on travaille, 0 = x, 1 = y, 2 = z
  
  if(SPEED_MODE == CONSTANT_SPEED){ // si on est dans le cas d'une vitesse constante
      
      for(axis = 0; axis < 2; axis++){
        // Si le mouvement relativement à l'angle de départ est assez élevé
        if(angle[axis] > initAngle[axis] + ANGLE_TRESH[axis])
          variation[axis]=SPEED[axis];      // Alors on bouge
        else if(angle[axis] < initAngle[axis] - ANGLE_TRESH[axis])
          variation[axis]=-SPEED[axis];
        else
          variation[axis] = 0;
      }
   }
   else if(SPEED_MODE == DELTA_ANGLE_SPEED)   {
        
     for(axis = 0; axis < 2; axis++){
        // Si le mouvement relativement à l'angle de départ est assez élevé
        if(angle[axis] > initAngle[axis] + ANGLE_TRESH[axis]) {
          variation[axis]=(SPEED[axis] * 
          (abs(angle[axis] - (initAngle[axis] + ANGLE_TRESH[axis]))))/SENSIBILITY;      // Alors on bouge
        }
        else if(angle[axis] < initAngle[axis] - ANGLE_TRESH[axis]) {
          variation[axis]=(-SPEED[axis] * 
          (abs(angle[axis] - (initAngle[axis] - ANGLE_TRESH[axis]))))/SENSIBILITY;
        }
        else
          variation[axis] = 0;
      }
     
   }
}

/******************************************************
// La fonction suivante fait attendre l'usager pendant
// environ 10 secondes pour la stabilisation des données
*******************************************************/
void waitStableData() {
  if(dataStarted)
    totalTime = millis() - startTime;
  else
    startTime = millis();
  
   if(totalTime > 20000){
    // Si les angles n'ont pas eu de variation majeure
   for(int i=0; i<3; i++){
     if(lastAngle[i]-2 < angle[i] && lastAngle[i]+2 > angle[i]){
       initAngle[i] = angle[i]; // Alors on met l'angle initiale
       stable = true;
      }
      else
        stable = false;
    }
  }
}

/******************************************************
// Les fonctions suivantes se produisent lors de clics
// de souris.
*******************************************************/
void CheckMouseClick() {
  boolean Both = false;
  // Si les deux boutons sont appuyé 
  if(!leftReleased && !rightReleased && leftClick == 1 && rightClick == 1){
   frame.toFront();
   frame.repaint(); 
   Both = true;
  }
  
  if(!Both){
    // Click gauche
    if(leftClick == 1 && leftReleased && (millis() - lastLeftClick > leftClickInterval)){
     lastLeftClick = millis();
     leftClick = 0;
     leftReleased = false;
     
     // On simule le clic simple
     robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
    }
    else {
      if(!leftReleased && leftClick == 0){
        leftReleased = true;
        robot.mouseRelease(InputEvent.BUTTON1_MASK);
      }
    }
      
    // Click droit
    if(rightClick == 1 && rightReleased && (millis() - lastRightClick > rightClickInterval)){
     lastRightClick = millis();
     rightClick = 0;
     rightReleased = false;
     
     // On simule le clic droit simple
     robot.mousePress(InputEvent.BUTTON3_DOWN_MASK);
    }
    else {
      if(!rightReleased && rightClick == 0){
        rightReleased = true;
        robot.mouseRelease(InputEvent.BUTTON3_MASK);
      }
    }
  }
}

/**********************************************************
// Les Fonctions Suivantes Sont pour la gestion des touches du clavier
**********************************************************/

void keyPressed(){
 if(key == 'a'){
  for(int i=0; i<3; i++){
    initAngle[i] = angle[i];
  } 
 }
 if(key == 'r'){
    reseted = true;
  /*else{
   reseted = false; 
  }*/
 }
 if(keyCode == ESC) exit(); 
}

/**********************************************************
// La fonction suivante lit et analyse le fichier Config.conf
// Qui contient les valeurs nécessaire au fonctionnement
// de l'application - Par Marc Simard et Jonathan Lavigne
**********************************************************/
void parseFile()
{
 if(!reseted){
    reader = createReader(path);
    try {
      line = reader.readLine();
    } catch (IOException e) { // Attrape un exception s'il y a lieu
      e.printStackTrace();
      line = null;
    }
    while(line != null) { 
      if(line != null){
        String[] result = split(line, ' ');
        // On cherche les données qu'on a besoins et on les met dans leur variables respective
        if(result[0].equals("SPEED_MODE"))
        {
          SPEED_MODE = int(result[1]);
          print(SPEED_MODE);
        }
        else if(result[0].equals("ANGLE_TRESH"))
        {
          ANGLE_TRESH[0] = int(result[1]);
          ANGLE_TRESH[1] = int(result[2]);
          ANGLE_TRESH[2] = int(result[3]);
        }
        else if(result[0].equals("SPEED"))
        {
          SPEED[0] = int(result[1]);
          SPEED[1] = int(result[2]);
          SPEED[2] = int(result[3]);
        }
        else if(result[0].equals("SENSIBILITY"))
        {
          SENSIBILITY = int(result[1]);
        }
      }
      
      // Lecture des données dans le fichier config
      try {
        line = reader.readLine();
      } catch (IOException e) { // Attrape un exception s'il y a lieu
        e.printStackTrace();
        line = null;
      }
    }
  }
  else {
    SPEED_MODE = INIT_SPEED_MODE;
    for(int i=0; i<3; i++){
      ANGLE_TRESH[i] = INIT_ANGLE_TRESH[i];
      SPEED[i] = INIT_SPEED[i];
    }
    SENSIBILITY = INIT_SENSIBILITY;  
  }
}
