// Mise à jour par Jonathan Lavigne
// Code original pour le gyroscope et l'interrupt : 
// I2C device class (I2Cdev) demonstration Arduino sketch for MPU6050 class using DMP (MotionApps v2.0)
// 6/21/2012 by Jeff Rowberg <jeff@rowberg.net>
// Date de création : 14 Avril 2015

// Les commentaires initiaux ont été gardé de l'anglais 
// puisque le programme n'est pas mien.

// Les librairies I2Cdev ainsi que MPU6050 doivent être installés
// Dans le répertoire "librairies" du répertoire arduino
#include "I2Cdev.h"

#include "MPU6050_6Axis_MotionApps20.h"

// On doit utiliser Wire.h si I2CDEV_IMPLEMENTATION le requiert
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
    #include "Wire.h"
#endif

// Création de l'objet du MPU6050 - contient tous les fonctions nécessaire à la réceptions des données
MPU6050 mpu;

// On indique que l'on veut retrouver les angles Yaw, pitch, roll (Précession, nutation et Rotation propre)
#define OUTPUT_READABLE_YAWPITCHROLL

#define LED_PIN 13 // (Arduino is 13, Teensy is 11, Teensy++ is 6)
#define FLEX_PIN 0            // Pin du capteur de flexion
#define CONTACT_LEFT_PIN 22   // Pin du capteur de contact gauche
#define CONTACT_RIGHT_PIN 24  // Pin du capteur de contact droite

// Est-ce qu'on allume la lumière de la pin 13?
bool blinkState = false;

// MPU control/status variables
bool dmpReady = false;  // vrai si l'initialisation est un succès
uint8_t mpuIntStatus;   // Recoit la donnée actuelle de l'interrupt du MPUT
uint8_t devStatus;      // Est-ce qu'il y a eu un problème avec le matériel 0 = vrai, !0 = oui
uint16_t packetSize;    // la grosseur du package de DMP (42 bytes par défaut)
uint16_t fifoCount;     // garde la trace du nombre de bytes dans le FiFo buffer
uint8_t fifoBuffer[64]; // First in First Out buffer (FiFo)

// orientation/motion vars
Quaternion q;           // [w, x, y, z]         quaternion
VectorFloat gravity;    // [x, y, z]            vecteur de gravité
float euler[3];         // [psi, theta, phi]    Angles d'Euleur
float ypr[3];           // [yaw, pitch, roll]   conteneur des angles Yaw, pitch et Roll

// Valeurs des angles à écrire dans le port série
float yaw = 0, pitch = 0, roll = 0;
int yawNeg = 0, pitchNeg = 0, rollNeg = 0;

// Valeur de la flexion
int flexPos = 0;

// Valeurs des contacts
int contactLeft = 0;
int contactRight = 0;
unsigned int contactInterval = 500;
unsigned int lastContact = 0;

// Package envoyé dans le port série
// Format : {'a', 2, rx, neg?, ry, neg?, 'b', rz, neg?,
//           'c', flex, 'd', Left_Contact?, Right_Contact?,
//           'e', '\r', '\n'} 
uint8_t package[] = {'a', 2, yaw, yawNeg, pitch, pitchNeg, 'b', roll, rollNeg,
                        'c', flexPos, 'd', contactLeft, contactRight, 'e', '\r', '\n'};
const int PACKAGE_SIZE = 17;

// ================================================================
// ===               INTERRUPT DETECTION ROUTINE                ===
// ================================================================

volatile bool mpuInterrupt = false;     // Est-ce qu'on a eu un interruption ?
void dmpDataReady() {
    mpuInterrupt = true;
}

// ================================================================
// ===                      INITIAL SETUP                       ===
// ================================================================

void setup() {
    // Ajout du I2C au BUS
    #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
        Wire.begin();
        TWBR = 24; // 400kHz
    #elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
        Fastwire::setup(400, true);
    #endif

    // Initialisation de la communication du port série
	// le 115200 est pour s'assurer que les données 
	// Viennent rapidement pour un temps de réponse court.
    Serial.begin(115200);
    while (!Serial);

    // Initialisation du matériel
    Serial.println(F("Initializing I2C devices..."));
    mpu.initialize();

    // Vérification de la connection
    Serial.println(F("Testing device connections..."));
    Serial.println(mpu.testConnection() ? F("MPU6050 connection successful") : F("MPU6050 connection failed"));

    // On attend que tout soit prêt
    Serial.println(F("\nSend any character to begin DMP programming and demo: "));
    while (Serial.available() && Serial.read()); // Buffer Serie Vide
    while (!Serial.available());                 // On attend les données
    while (Serial.available() && Serial.read()); // et on revide le buffer Série

    // Initialisation du DMP
    Serial.println(F("Initializing DMP..."));
    devStatus = mpu.dmpInitialize();

    // On met les offset du MPU pour que les données soient
	// le plus stable possible.
    mpu.setXGyroOffset(220);
    mpu.setYGyroOffset(76);
    mpu.setZGyroOffset(-85);
    mpu.setZAccelOffset(1688); // 1688 est la valeur par défaut

    // On s'assure que tout a fonctionné
    if (devStatus == 0) {
        // On allume le gyroscope
        Serial.println(F("Enabling DMP..."));
        mpu.setDMPEnabled(true);

        // On admet l'interruption d'arduino
        Serial.println(F("Enabling interrupt detection (Arduino external interrupt 0)..."));
        attachInterrupt(0, dmpDataReady, RISING);
        mpuIntStatus = mpu.getIntStatus();

        // On test l'interrupt
        Serial.println(F("DMP ready! Waiting for first interrupt..."));
        dmpReady = true;

        // On prend un exemple de grosseur de package pour référence future
        packetSize = mpu.dmpGetFIFOPacketSize();
    } else {
        // Il y a eu une erreur
        // 1 = Pas assez de mémoire initiale
        // 2 = la mise à jour DMP a échoué
        Serial.print(F("DMP Initialization failed (code "));
        Serial.print(devStatus);
        Serial.println(F(")"));
    }
   
    // On met le pin mode pour la lumière
	// Et pour le capteur de flexion
    pinMode(LED_PIN, OUTPUT);
    pinMode(FLEX_PIN, INPUT);
    
    // Mise du mode de Pin pour les contact avec un PullUp (Résistance interne)
    pinMode(CONTACT_LEFT_PIN, INPUT_PULLUP);
    pinMode(CONTACT_RIGHT_PIN, INPUT_PULLUP);
}



// ================================================================
// ===                    MAIN PROGRAM LOOP                     ===
// ================================================================

void loop() {
   flexPos = map(analogRead(FLEX_PIN), 0, 680, 0, 255); 
   contactLeft = digitalRead(CONTACT_LEFT_PIN);
   contactRight = digitalRead(CONTACT_RIGHT_PIN);
  
  
// ================================================================
// ===                    Programme du Gyro                     ===
// ================================================================  
  
    // Si le programme a échoué, on ferme tout
    if (!dmpReady) return;

    // on attend soit un interrupt, soit des données
    while (!mpuInterrupt && fifoCount < packetSize) { }
    
    // Réception de la position du capteur de flexion
    flexPos = map(analogRead(FLEX_PIN), 0, 680, 0, 255);
    
    //Si le delay de contact s'est écoulé
    if(millis() - lastContact > contactInterval)
    {
      lastContact = millis();
      // Réception des capteurs de contact
      contactLeft = digitalRead(CONTACT_LEFT_PIN);
      contactRight = digitalRead(CONTACT_RIGHT_PIN);
    }
    else
    {
       contactLeft = contactRight = 1; 
    }
    
    // Écriture dans le package série
    package[10] = flexPos;
    package[12] = contactLeft;
    package[13] = contactRight;

    // On remet l'interrupt à false et on attend l'état du MPU
    mpuInterrupt = false;
    mpuIntStatus = mpu.getIntStatus();

    // on compte la grosseur du buffer FiFo
    fifoCount = mpu.getFIFOCount();

    // On vérifie si on ne dépasse pas la grosseur maximale
    if ((mpuIntStatus & 0x10) || fifoCount == 1024) {
        // on remet tout à zéro pour qu'on puisse continuer
        mpu.resetFIFO();
        Serial.println(F("FIFO overflow!"));

    // sinon on vérifie l'état -- se produit souvent
    } else if (mpuIntStatus & 0x02) {
        // on attend d'avoir le bon nombre de données
        while (fifoCount < packetSize) fifoCount = mpu.getFIFOCount();

        // on lit un package du fifo
        mpu.getFIFOBytes(fifoBuffer, packetSize);
        
        // Cette ligne nous permet de continuer
		// Même sans interrupt
        fifoCount -= packetSize;

        #ifdef OUTPUT_READABLE_YAWPITCHROLL
            // On recoit les données nécessaire au
			// calcul des angles
            mpu.dmpGetQuaternion(&q, fifoBuffer);
            mpu.dmpGetGravity(&gravity, &q);
            mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
 
            //Conservation de données, en plus, l'angle ne devrait pas pouvoir dépasser 2.5 radian
            for(int i=0; i<3; i++)
            {
              if(ypr[i] > 2.55)
                ypr[i] = 2.55;
              else if(ypr[i] < -2.55)
                ypr[i] = -2.55;
            }
            
            // Les angles sont en radian, donc très petit, alors on fait x100
            // pour garder la précision lors de la transformation en unsigned int 8
            yawNeg = ypr[0] < 0 ? 1 : 0;
            yaw = (abs(ypr[0])*100);
            
            pitchNeg = ypr[1] < 0 ? 1 : 0;
            pitch = (abs(ypr[1])*100);
            
            rollNeg = ypr[2] < 0 ? 1 : 0;
            roll = (abs(ypr[2])*100);
            
            
            /*uint8_t package[] = {'a', 2, yaw, yawNeg, pitch, pitchNeg, 'b', roll, rollNeg,
                        'c', flexPos, 'd', contactLeft, contactRight, 'e', '\r', '\n'};*/
            package[2] = yaw;
            package[3] = yawNeg;
            package[4] = pitch;
            package[5] = pitchNeg;
            package[7] = roll;
            package[8] = rollNeg;
            
        #endif

        // Écriture des données dans le port série
        Serial.write(package, PACKAGE_SIZE);
        
        // on flash la LED de la pin 13 pour montrer 
		// que le MPU est toujours actif.
        blinkState = !blinkState;
        digitalWrite(LED_PIN, blinkState);
    }
}
