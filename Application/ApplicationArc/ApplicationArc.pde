/*
    But: On doit atteindre la cible qui est en mouvement en choisissant une position pour l'arc, une inclinaison et une force de tir.
    Auteur: Marc Simard
    Date: 15 avril 2015
    Dernière modification: 7 mai 2015
    Version: 1.5
    1.0: Application fonctionelle.
    1.1: Ajout d'une pause lorsque la flèche touche la cible et correction de l'angle de la flèche une fois lancée.
    1.2: Ajout d'un timer et d'un score. Modification de la méthode de collision.
    1.3: Modification de la méthode de d'inclinaison de l'arc.
    1.4: Ajout des niveaux de difficultés et du son.
    1.5: Finalisation du jeu, des commentaires et ajout des instructions.
*/

// On doit importer cette librairie pour le fonctionnement du son. Le dossier minim existe déjà dans: processing-2.2.1\modes\java\libraries. Il doit être remplacé pour que le son fonctionne.
// librairie trouvé sur: http://code.compartmental.net/tools/minim/
import ddf.minim.*;

// On crée la variable qui servira à lire le son.
Minim minim;

// Variable servant à importer le son.
AudioPlayer bowSound;
AudioPlayer backgroundMusic;

// Variable qui sert à importer les images.
PImage bow;
PImage arrow;
PImage target;
PImage targetEasy;
PImage targetMedium;
PImage targetHard;
PImage background;
PImage howToPlay;
PImage tuto1;
PImage tuto2;
PImage tuto3;

// Variables servant à importer les images animés.
Animation handLR;
Animation handUD;
Animation handC;

// Variable pour le texte.
PFont f;

// Variable qui dit si la cible a été atteinte.
boolean hitTarget = false;

// Variables qui disent si la souris est sur une certaine zone.
boolean overEasy, overMedium, overHard, overHowToPlay;

// Variable qui dit si on doit mettre à jour la position de la cible. Seulement utilisé si on a choisi le niveau de difficulté moyen.
boolean updateTargetPosition = true;

// Variable qui dit si on a tiré la flèche.
boolean shooted;

// Variable qui dit si on est en train de faire le tutoriel.
boolean tutorial = false;

// Pour savoir a quel étape du tutoriel on est rendu. Sert a mettre à jour le texte.
int tutoStep;

// Variable si sert à vérifier l'état de l'arc.
int bowState;

// Niveau de difficulté.
int difficulty;

// Vitesse de la cible;
int targetSpeed = 10;

// Nombre de cible touché.
int targetHit;

// Direction de la cible, 1 = descend, 0 = monte.
int targetDirection = 1;

// Temps de jeu restant en secondes.
int time;

// Position en Y de la cible.
float targetX, targetY;

// Variable pour la vitesse de la flèche.
float speed;

// Variable servant a garder la rotation.
float rotation;

// Taille de l'application.
float scale = 0.5;

// Variables qui sert a garder la position de la souris.
float mouse_X,mouse_X2,mouse_Y,mouse_Y2;

// Variable pour le temps relatif à la cible.
float targetLastTime = millis();
float targetTimer;

// Variables utilisés pour les formules de physique qui servent a calculer le déplacement de la flèche.
float lastTime; // Pour initialiser le timer.
float A; // Angle de la flèche.
float g; // Gravité.
float t; // Temps.
float V; // Vitesse.
float Vx; // Vitesse en X.
float ViY; // Vitesse initiale en Y.
float Vy; // Vitesse en Y.
float Sx; // Déplacement en X.
float Sy; // Déplacement en Y.
float arrowX; // Position de la flèche en X.
float arrowY; // Position de la flèche en Y.
//Fin des variables de physique.

// Temps du jeu totale en secondes.
float globalTimer;

// Pour initialiser le temps au début de la partie.
float globalLastTime;

// Temps pour faire jouer la musique.
float musicTimer;

// Temps pour faire jouer les animations.
float animationTimer;

// Temps avant de changer d'animation en millisecondes.
float animationTime = 500;

// On initialise les variables ici, cette fonction n'est appelé qu'une seule fois en début de partie.   
void setup(){
  size(1200,600); // Taille de l'application.
  noFill(); // On ne veut pas que les formes dessinés (comme par exemple le bezier utilisé pour la corde) possède un remplissage.
  minim = new Minim(this); // On initialise la variable pour le son.
  // On importe les images, les animations et le son.
  bow = loadImage("Sprite/Bow.png");
  arrow = loadImage("Sprite/Arrow.png");
  target = loadImage("Sprite/Target.png");
  targetEasy = loadImage("Sprite/Facile.png");
  targetMedium = loadImage("Sprite/Moyen.png");
  targetHard = loadImage("Sprite/Difficile.png");
  howToPlay = loadImage("Sprite/HowToPlay.png");
  tuto1 = loadImage("Sprite/Tuto1.png");
  tuto2 = loadImage("Sprite/Tuto2.png");
  tuto3 = loadImage("Sprite/Tuto3.png");
  background = loadImage("Sprite/Background.jpg");
  handLR = new Animation("AnimatedSprite/HandLR", 4);
  handUD = new Animation("AnimatedSprite/HandUD", 4);
  handC = new Animation("AnimatedSprite/HandC", 4);
  bowSound = minim.loadFile("Sound/BowFire.wav");
  backgroundMusic = minim.loadFile("Sound/BackgroundMusic.mp3");
  // Fin de l'importation.
  animationTimer = millis(); // On initialise le temps pour faire jouer les animations.
  musicTimer = millis(); // On initialise le temps pour faire jouer la musique.
  backgroundMusic.play(); // On fait jouer le bruit de fond.
  f = createFont("Arial",16,true); // On initialise le texte.
}

void draw(){
  imageMode(CORNER); // Spécifie le point 0,0 de l'image comme étant au coin en haut a gauche.
  image(background,0,height-background.height); // On fais apparaitre l'image du fond d'écran.
  imageMode(CENTER); // Spécifie le point 0,0 de l'image comme étant au centre.
  
  if(millis() - musicTimer >= 115000) // On fait jouer le bruit de fond en boucle. On compte 1 minutes 55 secondes avant de le recommencer (on laisse 5 secondes pour ne pas se faire avoir par un délais car l'audio dure 2 minutes).
  {
    backgroundMusic.rewind(); // Pour recommencer le son depuis le début.
    backgroundMusic.play(); // Pour faire jouer le son.
    musicTimer = millis(); // Pour réinitialiser le temps.
  }
  
  if(difficulty == 0 && tutorial == false) // Lorsque la difficulté n'a pas été choisi et qu'on est pas dans le tutoriel, on affiche l'écran des difficultés.
  {
    textAlign(CENTER);
    textFont(f,75); // On change la taille du texte.
    text("Choisissez une difficulté:",width/2,height/4);
    textAlign(LEFT);
    // Lorsqu'on est dans la zone des images, on l'affiche avec une différente teinte, si non on l'affiche normalement.
    if(overEasy)
    {
      tint(100);
      image(targetEasy,width/4,height/2);
    } else {
      tint(255);
      image(targetEasy,width/4,height/2);
    }
    if(overMedium)
    {
      tint(100);
      image(targetMedium,width/2,height/2);
    } else {
      tint(255);
      image(targetMedium,width/2,height/2);
    }
    if(overHard)
    {
      tint(100);
      image(targetHard,3*width/4,height/2);
    } else {
      tint(255);
      image(targetHard,3*width/4,height/2);
    }
    if(overHowToPlay)
    {
      tint(100);
      image(howToPlay,width/2,3*height/4);
    } else {
      tint(255);
      image(howToPlay,width/2,3*height/4);
    }
    tint(255); // On remet la teinte par défaut pour que les autres images ne soient pas modifiés.
  }
  
  if(tutorial == true) // Lorsqu'on est dans le tutoriel, on fait afficher le texte et les animations.
  {
    if(millis() - animationTimer > animationTime) // On vérifie si l'animation doit être mis à jour. Le timer est utilisé pour que l'animation de se passe pas trop rapidement.
    {
      // On met les animations à jour et on réinitialise le temps.
      handLR.update();
      handUD.update();
      handC.update();
      animationTimer = millis();
    }
    // On affiche les textes et les animations.
    imageMode(CORNER);
    if(tutoStep == 0)
      image(tuto1,0,0);
    else if(tutoStep == 1)
      image(tuto2,0,0);
    else if(tutoStep == 2)
      image(tuto3,0,0);
    imageMode(CENTER);
    handLR.display(780,550);
    handUD.display(870,550); 
    handC.display(1100,550); 
    // Fin de l'affichage.
  }
  
  scale(scale); // On change la taille du jeu.
  textFont(f,50/scale); // On change la taille du texte pour qu'il soit toujours de la même grosseur même si on change la taille du jeu.
  
  // Boucle de jeu principale, lorsqu'on a choisi le niveau de difficulté, on commence à jouer.
  if(difficulty > 0)
  {
    // Si on n'est pas dans le tutoriel, on fait en sorte que le temps diminue, si non, on gèle le temps a 60 secondes pour éviter qu'il affiche partie terminé.
    if(tutorial == false)
      time = int(globalTimer - ((millis()-globalLastTime) /1000));
    else
      time = 60;
      
    // Boucle lorsque la partie est terminé (lorsque le temps est écoulé).
    if(time <= 0)
    {
      time = 0; // Pour être sur que le temps affiché sera 0.
      textAlign(CENTER); // On aligne le texte au centre.
      text("Partie terminé,",width/2/scale,height/2/scale); // On affiche le texte proportionnellement à la dimension de l'écran et du scale.
      text("clic droit pour retourner au menu!",width/2/scale,height/2/scale + 80);
      textAlign(LEFT);  // On aligne le texte à gauche.   
      
      //Lorsqu'on fait un clic droit, on retourne au menu principale.
      if(mouseButton == RIGHT && mousePressed == true)
      {
        // On réinitialise les variables, ce qui aura pour effet de recommencer le programme depuis le début.
        globalLastTime = millis();
        globalTimer = 61;
        difficulty = 0;
        bowState = 0;
        targetHit = 0;
      }
    }
    
    // Lorsqu'on est pas dans le tutoriel, on affiche la cible, le temps restant et le score.
    if(tutorial == false)
    {
      updateTarget(); // Met à jour la position de la cible.
      text(time,width/2/scale,50/scale); // On affiche le temps restant.
      text("Touché: " + targetHit,20/scale,50/scale); // On affiche le score.
    }
    
    updateBow(); // Met à jour l'arc.
  }
  
}

// Cette fonction met à jour les différents déplacement de l'arc, de la flèche et les collisions.
void updateBow(){
  
  if(bowState == 0) // Premier stade lorsqu'on commence le jeu pour laisser le temps au joueur de se situé, il suffit de cliquer pour passer au stade suivant.
  {
      textAlign(CENTER); // On aligne le texte au centre.
      text("Cliquez pour commencer!",width/2/scale,height/2/scale); // On affiche le texte pour dire au joueur de cliquer pour commencer la partie.
      textAlign(LEFT);  // On aligne le texte à gauche pour les prochains texte.
      globalTimer = 61; // On initialise le timer du jeu.
      globalLastTime = millis(); // On initialise le temps lorsque la partie débute.
  }
  
  if(time > 0)
  {
    
    if(bowState == 1) // Le premier cas est utilisé pour choisir la position de l'arc.
    {
        tutoStep = 0; // Cette étape correspond à la première étape si on est dans le tutoriel.
        shooted = false; // On spécifie qu'on peut faire jouer le bruit de l'arc à nouveau. Utile lorsqu'on a déjà tiré au moins une flèche pour pouvoir entendre le son à nouveau.
        mouse_X = constrain(mouseX/scale,0,width/5/scale); // Position X de l'arc, pouvant seulement se déplacer dans le premier cinquième de l'écran pour ne pas rendre le jeu trop facile.
        mouse_Y = mouseY/scale; // Position Y de l'arc.
        pushMatrix(); // Cette fonction est utilisé pour apporter des modifications à l'image sans modifier la matrice du jeu en entier.
        translate(mouse_X,mouse_Y); // On définie le point 0,0 de cette matrice à la position de la souris.
        bezier(0, -bow.height/2, 0,0,0, 0,0, bow.width/2); // Dessine la corde.
        image(bow,0,0); // Dessine l'arc.
        popMatrix(); // Fin de la matrice
    }
    
    else if(bowState == 2) // Le deuxième cas est utilisé pour choisir l'angle de l'arc.
    {
        tutoStep = 1; // Cette étape correspond à la deuxième étape si on est dans le tutoriel.
        mouse_Y2 = mouseY/scale; // Deuxième position en Y de la souris.
        mouse_X2 = mouseX/scale; // Deuxième position en X de la souris.
        pushMatrix();
        translate(mouse_X,mouse_Y);
        float a = atan2(mouseY-mouse_Y/2, abs(mouseX-mouse_X/2)); // On défini l'angle de l'arc par rapport à la souris.
        
        // La rotation ne peut pas être la même si on est à gauche de l'arc ou si on est à droite, elle doit être inversé.
        if(mouseX <= mouse_X/2)
        {
          rotate(-a);
          rotation = -a;
        }
        else
        {
          rotate(a);
          rotation = a;
        }
        
        bezier(0, -bow.height/2, 0,0,0, 0,0, bow.width/2); // Dessine la corde.
        image(bow,0,0); // Dessine l'arc.
        popMatrix();
    }
    
    else if(bowState == 3) // Le troisième cas est utilisé pour étirer la corde.
    {
        tutoStep = 2; // Cette étape correspond à la troisième et dernière étape si on est dans le tutoriel.
        pushMatrix();
        translate(mouse_X,mouse_Y);
        rotate(rotation);
        if(mouse_X2-mouseX/scale < 0) // Cas ou la souris est a droite de la corde, on doit dessiner la corde et la flèche au repos.
        {
          bezier(0, -bow.height/2, 0,0,0, 0,0, bow.width/2); // Dessine la corde.
          image(arrow,125,0); // Desine la flèche
          speed = 0; // Définie la vitesse de tir.
        }
        else if(mouse_X2-mouseX/scale > 180) // Cas ou la souris est trop a gauche, on gèle la corde et la flèche pour en pas trop les étirer.
        {
          bezier(0, -bow.height/2, -180,0,-180, 0,0, bow.width/2); // Dessine la corde.
          image(arrow,-180/1.35 + 125,0);  // Desine la flèche
          speed = 180; // Définie la vitesse de tir.
        }
        else // Cas ou on est entre les 2, la corde suit la souris.
        {
          bezier(0, -bow.height/2, -(mouse_X2-mouseX/scale),0,-(mouse_X2-mouseX/scale), 0,0, bow.width/2); // Dessine la corde et permet de la bouger.
          image(arrow,-(mouse_X2-mouseX/scale)/1.35 + 125,0);  // Desine la flèche
          speed = mouse_X2-mouseX/scale; // Définie la vitesse de tir.
        }
        image(bow,0,0); // Dessine l'arc.
        popMatrix();
        lastTime = millis()/10; // On initialise le temps pour le prochain stade.
    }
    
    else if(bowState == 4) // Le dernier cas est utilisé pour faire bouger la flèche et vérifier la collision.
    {
        pushMatrix();
        translate(mouse_X,mouse_Y);
        rotate(rotation);
        image(bow,0,0); // Dessine l'arc.
        bezier(0, -bow.height/2, 0,0,0, 0,0, bow.width/2); // Dessine la corde.
        rotate(-rotation); // On revien à la rotation initiale.
        
        // Formules et variables de physique mécanique pour déterminer la position et la vitesse de l'arc (voir définitions lors de la création au début du programme).
        A = rotation;
        g = 0.5;
        V = speed/3;
        t = millis()/10 - lastTime;
        ViY = V*sin(A);
        Vy = ViY + g * t;
        Vx = V*cos(A);
        Sx = Vx * t;
        Sy = ViY * t + 0.5*g*(t*t);
        arrowX = Sx + arrow.width/2*scale - arrow.width/5; // On met à jour la position X de la flèche selons son référentiel pour pouvoir tester la collision.
        arrowY = Sy + tan(asin(Vy/V))*arrow.width/2*scale; // On met à jour la position Y de la flèche selons son référentiel pour pouvoir tester la collision.
        // Fin des formules et variables.
        
        if(arrowX > width/scale || arrowY > height/scale || t >= 200) // Si la flèche quitte l'écran, on recommence depuis le début.
        {
          if(tutorial) // Si la flèche quitte l'écran et qu'on est dans le tutoriel, on revient au menu principale car il est terminé.
          {
            bowState = 0;
            difficulty = 0;
            tutorial = false;
            overHowToPlay = false; // Pour prévenir un petit bug.
          }
          else
            bowState = 1;
        }
        
        // Boucle utilisé pour tester la collision. On vérifie si le bout de l'image de la flèche entre dans la zone circulaire formé par la cible.
        if(arrowX >= targetX - mouse_X - cos(Vy/V)*target.width/2 && arrowX < targetX - mouse_X + cos(Vy/V)*target.width/2 
           && arrowY >= targetY - mouse_Y - target.height/2 && arrowY <= targetY - mouse_Y + target.height/2) // Si la flèche touche la cible, on entre dans cette boucle.
        {
          hitTarget = true; // On spécifie qu'on a touché la cible.
          targetLastTime = millis(); // On initialise le timer.
          while(millis() - targetLastTime < 3000) // On exécute cette fonction pendant 3 secondes pour simuler une pause. On à donc le temps de voir le positionnement de la flèche.
          {}
          globalTimer += 3; // On remet les 3 secondes perdu durant la pause au temps de jeu.
          targetHit++; // On augmente de 1 le nombre de cible touché.
          updateTargetPosition = true; // On spécifie qu'on veut mettre à jour la position de la cible si on est à la difficulté moyenne.
        }
        
        pushMatrix();
        translate(Sx,Sy); // On transpose la position 0,0 pour qu'elle soit toujours au centre de l'arc
        if(Float.isNaN(asin(Vy/V))) // Si l'orientation de la flèche retourne null, on lui donne une orientation de 1.40 rad pour qu'elle arrête de tourner.
          rotate(1.40);
        else
          rotate(asin(Vy/V)); // On fait tourner la flèche pour qu'elle suive la direction vers laquelle elle se dirige.
        image(arrow,0,0); // On affiche la flèche selons son déplacement. 
        popMatrix();
        popMatrix();
    }  
  }
}

// Fonction qui met a jour la position de la cible.
void updateTarget() {
  
  targetX = width/scale-target.width/scale; // On définie la position de la cible en X selons le scale. Elle reste la même peu importe la difficulté.
  
  if(difficulty == 1) // Si on a choisi la difficulté facile, on positionne la cible au milieu de l'écran.
  {
    targetY = height/2/scale - target.height/2*scale;
    image(target,targetX,targetY); // On affiche la cible
  }
  else if(difficulty == 2) // Si on a choisi la difficulté moyenne, on change la position Y de la cible aléatoirement à chaque fois que la flèche touche la cible.
  {
     if(updateTargetPosition)
     {
       targetY = random(height/scale - target.height*scale) + target.height/2*scale;
       updateTargetPosition = false;
     }
     image(target,targetX,targetY); // On affiche la cible
  }
  else if(difficulty == 3) // Si on a choisi la difficulté difficile, la cible bouge de haut en bas.
  {
     if(targetDirection == 1) // Si on descend, on augmente la valeur dans les Y.
     {
       targetY+=targetSpeed;
       if(targetY + target.height >= height/scale) // Lorsque la cible touche le bas de l'écran, on la change de direction.
         targetDirection = 0; 
     }
     else if(targetDirection == 0) // Si on monte, on diminue la valeur dans les Y.
     {
       targetY-=targetSpeed;
       if(targetY <= 100) // Lorsque la cible touche le haut de l'application, on change la direction.
         targetDirection = 1; 
     }
     image(target,targetX,targetY); // On affiche la cible
  }
}

// Cette fonction vérifie S'il y a un clic de souris.
void mouseClicked() {
  if(mouseButton == LEFT) // On spécifie que ça doit petre un clic gauche de souris.
  {
    if(bowState >= 0 && bowState < 4 && difficulty != 0) // On change le mode de l'arc a toute les clic.
       bowState++;
    
    if(bowState == 4 && shooted == false && time > 0) // On fait jouer le bruit de l'arc lorsqu'on tire.
    {
        shooted = true;
        bowSound.rewind();
        bowSound.play(); 
    }
    
    if(tutorial == false)
    {
      // Lorsqu'on clic sur une option du menu, on commence la partie en changeant la difficulté ou on commence le tutoriel.
      if(overEasy)
      {
        difficulty = 1;
      }
      else if(overMedium)
      {
        difficulty = 2;
      }
      else if(overHard)
      {
        difficulty = 3;
      }
      else if(overHowToPlay)
      {
         tutorial = true; // On spécifie qu'on est dans le tutoriel.
         difficulty = 1; // Le nombre n'a pas d'importance, il doit seulement être entre 1 et 3.
         bowState = 1; // Pour commencer tout de suite à choisir la position de l'arc (étape 1).
      }
    }
  }
}

// Cette fonction détecte le mouvement de la souris.
void mouseMoved()
{
  if(difficulty == 0) // Lorsqu'on est au menu, on vérifie si la souris se trouve sur une image.
  {
    if(mouseX >= width/4 - targetEasy.width/2 && mouseX <= width/4 + targetEasy.width/2
        && mouseY >= height/2 - targetEasy.height/2 && mouseY <= height/2 + targetEasy.height/2)
    {
       overEasy = true;
    }
    else
      overEasy = false;
      
    if(mouseX >= width/2 - targetMedium.width/2 && mouseX <= width/2 + targetMedium.width/2
        && mouseY >= height/2 - targetMedium.height/2 && mouseY <= height/2 + targetMedium.height/2)
    {
       overMedium = true;
    }
    else
      overMedium = false;
      
    if(mouseX >= 3*width/4 - targetHard.width/2 && mouseX <= 3*width/4 + targetHard.width/2
        && mouseY >= height/2 - targetHard.height/2 && mouseY <= height/2 + targetHard.height/2)
    {
       overHard = true;
    }
    else
      overHard = false;
  
    if(mouseX >= width/2 - howToPlay.width/2 && mouseX <= width/2 + howToPlay.width/2
        && mouseY >= 3*height/4 - howToPlay.height/2 && mouseY <= 3*height/4 + howToPlay.height/2)
    {
       overHowToPlay = true;
    }
    else
      overHowToPlay = false;
  }
}

// Classe utilisé pour gérer les images animés.
class Animation {
  PImage[] images; // On définie un tableau d'images.
  int imageCount; // Variable servant à savoir le nombre d'images.
  int frame; // Variable servant à savoir à quel image on est rendu à afficher.
  
  Animation(String imagePrefix, int count) { // Constructeur prenant le nom de la série d'image et le nombre d'images animés.
    imageCount = count;
    images = new PImage[imageCount]; // On initialise un tableau d'image vide d'après le nombre d'images.

    for (int i = 0; i < imageCount; i++) {
      String filename = imagePrefix + nf(i, 1) + ".png"; // On commence par définir le nom de chaque images. nf est utilisé pour transformer un int en string en spécifiant le nombre de décimales.
      images[i] = loadImage(filename); // On importe par la suite chaque image dans le tableau. 
    }
  }
  
  // Fonction qui met à jour l'état de l'animation.
  void update()
  {
     frame = (frame+1) % imageCount; // On change d'image à toute les fois qu'on update pour simuler une animation.
  }
  
  // Fonction qui affiche l'animation.
  void display(float xpos, float ypos) {
    image(images[frame], xpos, ypos); // On affiche l'image qu'on est rendu à une certaine position.
  }
}
