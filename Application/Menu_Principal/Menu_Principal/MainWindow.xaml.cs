using System;
using System.Collections.Generic;
using System.Diagnostics;
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
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace Menu_Principal
{
    

    /// <summary>
    /// Logique d'interaction pour MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {

        Parametres FenetreParametre;

        //Chemin de l'exécutable de l'application du tir à l'arc. 
        // Lors du test hors de la date du 22 Mai, il sera nécessaire de changer cette variable.
        const string pathArc = "D:/Processing/Bow/";
  
        public MainWindow()
        {
            InitializeComponent();
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }

        //Lorsqu'on appuie sur le bouton «Paramètres»,
        //un écran paramètres se crée et s'ouvre et celle du menu principal se ferme.
        private void Button_Click_1(object sender, RoutedEventArgs e)
        {
            FenetreParametre = new Parametres();
            FenetreParametre.Show();

            this.Close();
            
        }

        //Cette fonction ouvre l'application processing du tir à l'arc.
        private void StartBowGame(object sender, RoutedEventArgs e)
        {
            Process AppArc = new Process();
            AppArc.StartInfo.UseShellExecute = false;

            //C'est ici qu'on identifie l'application à exécuter.
            AppArc.StartInfo.FileName = new StringBuilder(pathArc + "Bow.exe").ToString();
            AppArc.StartInfo.ErrorDialog = true;

            //Défini le chemin initial de l'application à exécuter.
            AppArc.StartInfo.WorkingDirectory = pathArc;
            AppArc.Start();

            //La fenêtre présente se ferme.
            this.Hide();

            AppArc.WaitForExit();
            this.Show();

        }
    }
}
