using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace Menu_Principal
{
    /// <summary>
    /// Logique d'interaction pour Parametres.xaml
    /// </summary>
    public partial class Parametres : Window
    {
        int SPEED_Mode_Value;
        int Compteur = 0;
        string line;

        //C'est à cet endroit que les informations d'utilisation du gant seront enregistrées.
        string FichierConfig = "D:Processing/Mouse/Config.conf";

        //Fonction qui écrit dans un fichier .txt les informations d'utilisation du gant défini par l'utilisateur.
        public void EcrireInfoConfiguration()
        {

            string[] lines = { "SPEED_MODE " + SPEED_Mode_Value,"ANGLE_THRESH " + Lbl_AngleX.Content + " " + Lbl_AngleY.Content + " " + Lbl_AngleZ.Content,
            "SPEED " + lbl_VitesseX.Content + " " + lbl_VitesseY.Content + " " + lbl_VitesseZ.Content, "SENSIBILITY " + lbl_Sens.Content };
            System.IO.File.WriteAllLines(FichierConfig, lines);

        }


        //Cette fonction lit le fichier où sont situé les informations, gère ces informations et les met à jour.
        public void LireInfoConfiguration()
        {
            
            //On s'assure que le fichier existe
            if(File.Exists(FichierConfig))
            { 

            System.IO.StreamReader file =
               new System.IO.StreamReader(@FichierConfig);
            
            
            while ((line = file.ReadLine()) != null)
            {
                if (Compteur == 0) //La première ligne correspond au mode de mouvement
                {

                    int pos = line.IndexOf(" ");

                    line = line.Substring(pos + 1);

                    SPEED_Mode_Value = Convert.ToInt32(line);

                    if(SPEED_Mode_Value == 1)
                    {
                        txtBlockSens.Visibility = Visibility.Visible;
                        sld_Sens.Visibility = Visibility.Visible;
                        lbl_Sens.Visibility = Visibility.Visible;

                        CheckBox_Angle.IsChecked = true;
                        CheckBox_Constant.IsChecked = false;
                    }
                }

                    

                if (Compteur == 1) // La deuxième ligne correspond à l'angle mort
                {

                    int pos = line.IndexOf(" ");
                    line = line.Substring(pos + 1);
                    int pos2 = line.IndexOf(" ");

                    Lbl_AngleX.Content = line.Substring(0, pos2); //Le premier chiffre de la ligne correspond à l'angle en x
                               //Pour arriver à ce chiffre, j'isole les chiffres se situant entre les caractères espace (" ")
                    sld_AngleX.Value = Convert.ToDouble(Lbl_AngleX.Content);
     
                   
                    line = line.Substring(pos2 + 1);
                    int pos3 = line.IndexOf(" ");

                    Lbl_AngleY.Content = line.Substring(0, pos3); //Le deuxième chiffre de la ligne correspond à l'angle en y
                    sld_AngleY.Value = Convert.ToDouble(Lbl_AngleY.Content);

                    line = line.Substring(pos3 + 1);

                    Lbl_AngleZ.Content = line; //Le troisième chiffre de la ligne correspond à l'angle en z
                    sld_AngleZ.Value = Convert.ToDouble(Lbl_AngleZ.Content);
                }

                if (Compteur == 2) //// La troisième ligne correspond à la vitesse du curseur
                {
                    int pos = line.IndexOf(" ");
                    line = line.Substring(pos + 1);
                    int pos2 = line.IndexOf(" ");

                    lbl_VitesseX.Content = line.Substring(0, pos2); 
                    sld_VitesseX.Value = Convert.ToDouble(lbl_VitesseX.Content);


                    line = line.Substring(pos2 + 1);
                    int pos3 = line.IndexOf(" ");

                    lbl_VitesseY.Content = line.Substring(0, pos3); 
                    sld_VitesseY.Value = Convert.ToDouble(lbl_VitesseY.Content);

                    line = line.Substring(pos3 + 1);

                    lbl_VitesseZ.Content = line; 
                    sld_VitesseZ.Value = Convert.ToDouble(lbl_VitesseZ.Content);
                }

                if(Compteur == 3) //La quatrième ligne correspond à la sensibilité du curseur.
                {
                    int pos = line.IndexOf(" ");
                    line = line.Substring(pos + 1);
                    lbl_Sens.Content = line;
                    sld_Sens.Value = Convert.ToDouble(lbl_Sens.Content);
                }

                Compteur++;
            }

            file.Close();

            }

        }

        //Si on clique sur le bouton +, la valeur du slider augmente de 1.
        private void AjusterSliderPlus(Slider sld)
        {
            sld.Value += 1;
        }

        //Si on clique sur le bouton -, la valeur du slider diminue de 1.
        private void AjusterSliderMinus(Slider sld)
        {
            sld.Value -= 1;
        }

        //Fonction ajustant le chiffre visible dans le «label» avec la valeur du «slider».
        private void AjusterLabel(Label label, object sender)
        {
            Slider changedSlider = sender as Slider;

            //Le StackPanel est l'outil d'affichage contenant les boutons, sliders, etc.
            StackPanel parent = changedSlider.Parent as StackPanel;

            foreach (var item in parent.Children)
            {
                //Lorsqu'un «label» est détecté dans le «stackpanel», il est ajusté.
                if (item.GetType() == typeof(Label) && item == label)
                {
                    Label lbl = item as Label;

                    lbl.Content = changedSlider.Value;
                      
                }
            }
        }

        public Parametres()
        {
            
            InitializeComponent();
            LireInfoConfiguration();

        }

        private void sld_AngleX_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AjusterLabel(Lbl_AngleX, sender);
        }

        private void sld_AngleY_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AjusterLabel(Lbl_AngleY, sender); 
        }

        private void sld_AngleZ_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AjusterLabel(Lbl_AngleZ, sender); 
        }

        private void sld_VitesseX_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AjusterLabel(lbl_VitesseX, sender); 
        }

        private void sld_VitesseY_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AjusterLabel(lbl_VitesseY, sender); 
        }

        private void sld_VitesseZ_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AjusterLabel(lbl_VitesseZ, sender); 
        }

        private void sld_Sens_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AjusterLabel(lbl_Sens, sender); 
        }

        //Lorsqu'on clique sur le checkbox «Variation de l'angle», les paramètres de sensibilité deviennent visibles 
        // et cela devient possible de modifier leur valeur.
        private void CheckBox_Angle_Click(object sender, RoutedEventArgs e)
        {
            txtBlockSens.Visibility = Visibility.Visible;
            sld_Sens.Visibility = Visibility.Visible;
            lbl_Sens.Visibility = Visibility.Visible;
            btn_sensePlus.Visibility = Visibility.Visible;
            btn_senseMinus.Visibility = Visibility.Visible;

            //Le mode de mouvement n'est plus en mode «Constant», donc on le décoche.
            CheckBox_Constant.IsChecked = false;

            //La valeur du mode de mouvement devient 1, c'est cela qui sera enregistrée et lue dans un fichier .txt. 
            SPEED_Mode_Value = 1;
        }

        //Lorsqu'on clique sur le checkbox «Constant», les paramètres de sensibilité deviennent invisibles 
        // et cela devient impossible de modifier leur valeur.
        private void CheckBox_Constant_Click(object sender, RoutedEventArgs e)
        {

            txtBlockSens.Visibility = Visibility.Hidden;
            sld_Sens.Visibility = Visibility.Hidden;
            lbl_Sens.Visibility = Visibility.Hidden;
            btn_sensePlus.Visibility = Visibility.Hidden;
            btn_senseMinus.Visibility = Visibility.Hidden;

            //Le mode de mouvement n'est plus en mode «Variation de l'angle», donc on le décoche.
            CheckBox_Angle.IsChecked = false;

            lbl_Sens.Content = 6; //Quand on coche le checkbox «Constant» 
            sld_Sens.Value = 6;   //les valeurs de la sensibilité reviennent à leurs valeurs initiales.

            //La valeur du mode de mouvement devient 0, c'est cela qui sera enregistrée et lue dans un fichier .txt. 
            SPEED_Mode_Value = 0;
        }

        //Cette fonction réinitialise toutes les données d'utilisation du gant.
        //Initialement, le mode de mouvement est «Constant» et les valeurs des 
        //angles morts, des vitesses et de la sensibilité sont celles ci-dessous.
        private void ButtonInitialize_Click(object sender, RoutedEventArgs e)
        {
            
            SPEED_Mode_Value = 0;
            CheckBox_Angle.IsChecked = false;
            CheckBox_Constant.IsChecked = true;

            sld_AngleX.Value = 15;
            sld_AngleY.Value = 15;
            sld_AngleZ.Value = 15;

            sld_VitesseX.Value = 5;
            sld_VitesseY.Value = 5;
            sld_VitesseZ.Value = 5;
            
            sld_Sens.Value = 6;

            txtBlockSens.Visibility = Visibility.Hidden;
            sld_Sens.Visibility = Visibility.Hidden;
            lbl_Sens.Visibility = Visibility.Hidden;
            btn_sensePlus.Visibility = Visibility.Hidden;
            btn_senseMinus.Visibility = Visibility.Hidden;

            //Les données sont enregistrées.
            EcrireInfoConfiguration();

            //Pour assurer à l'utilisateur que cela a bien eu lieu.
            MessageBox.Show("Les données ont bien été enregistrées.");
        }

        private void ButtonSave_Click(object sender, RoutedEventArgs e)
        {

            //Les données sont enregistrées.
            EcrireInfoConfiguration();

            //Pour assurer à l'utilisateur que cela a bien eu lieu.
            MessageBox.Show("Les données ont bien été enregistrées.");

        }

        //Fonction pour revenir au menu principal.
        private void ButtonQuit_Click(object sender, RoutedEventArgs e)
        {

            MainWindow EcranPrincipal;

            EcranPrincipal = new MainWindow();
            EcranPrincipal.Show();
            this.Close();
        }

        //Chaque slider correspondant aux angles X, Y et Z sont ajustés si on clique sur le bouton + ou -
        private void Btn_AngleX_Plus(object sender, RoutedEventArgs e)
        {
            AjusterSliderPlus(sld_AngleX);
        }

        private void Btn_AngleX_Minus(object sender, RoutedEventArgs e)
        {
            AjusterSliderMinus(sld_AngleX);
        }

        private void Btn_AngleY_Plus(object sender, RoutedEventArgs e)
        {
            AjusterSliderPlus(sld_AngleY);
        }

        private void Btn_AngleY_Minus(object sender, RoutedEventArgs e)
        {
            AjusterSliderMinus(sld_AngleY);
        }

        private void Btn_AngleZ_Plus(object sender, RoutedEventArgs e)
        {
            AjusterSliderPlus(sld_AngleZ);
        }

        private void Btn_AngleZ_Minus(object sender, RoutedEventArgs e)
        {
            AjusterSliderMinus(sld_AngleZ);
        }


        //Chaque slider correspondant aux vitesses X, Y et Z sont ajustés si on clique sur le bouton + ou -
        private void Btn_VitesseX_Plus(object sender, RoutedEventArgs e)
        {
            AjusterSliderPlus(sld_VitesseX);
        }

        private void Btn_VitesseX_Minus(object sender, RoutedEventArgs e)
        {
            AjusterSliderMinus(sld_VitesseX);
        }

        private void Btn_VitesseY_Plus(object sender, RoutedEventArgs e)
        {
            AjusterSliderPlus(sld_VitesseY);
        }

        private void Btn_VitesseY_Minus(object sender, RoutedEventArgs e)
        {
            AjusterSliderMinus(sld_VitesseY);
        }

        private void Btn_VitesseZ_Plus(object sender, RoutedEventArgs e)
        {
            AjusterSliderPlus(sld_VitesseZ);
        }

        private void Btn_VitesseZ_Minus(object sender, RoutedEventArgs e)
        {
            AjusterSliderMinus(sld_VitesseZ);
        }

        private void Btn_Sense_Minus(object sender, RoutedEventArgs e)
        {
            AjusterSliderMinus(sld_Sens);
        }

        private void Btn_Sense_Plus(object sender, RoutedEventArgs e)
        {
            AjusterSliderPlus(sld_Sens);
        }
       
    }
}
