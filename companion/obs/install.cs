// SPDX-License-Identifier: GPL-2.0-or-later
using System;
using System.Diagnostics;
using System.IO;
using System.Security.Cryptography;
using System.Windows.Forms;
class InstallVoice {
  [STAThread] static void Main() {
    try {
      if (Process.GetProcessesByName("obs64").Length>0) {
        MessageBox.Show("Chiudi OBS, poi riapri questo programma per installare il filtro. La live non viene fermata automaticamente.", "APPISHOWDRIVE", MessageBoxButtons.OK, MessageBoxIcon.Information); return;
      }
      string source=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"appishowdrive-voice.dll");
      string hash;
      using(var stream=File.OpenRead(source)) using(var sha=SHA256.Create()) hash=BitConverter.ToString(sha.ComputeHash(stream)).Replace("-","").ToLowerInvariant();
      if(hash!="__PLUGIN_SHA__") throw new Exception("Il file del filtro non corrisponde alla versione verificata. Scarica nuovamente lo ZIP ufficiale.");
      string home=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),"obs-studio","plugins","appishowdrive-voice");
      string binary=Path.Combine(home,"bin","64bit"), data=Path.Combine(home,"data");
      Directory.CreateDirectory(binary); Directory.CreateDirectory(data);
      File.Copy(source,Path.Combine(binary,"appishowdrive-voice.dll"),true);
      foreach(string name in new[]{"LEGGIMI.txt","COPYING-RNNOISE.txt","COPYING-GPL-2.0.txt"}) File.Copy(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,name),Path.Combine(data,name),true);
      MessageBox.Show("Filtro installato.\n\nApri OBS: sulla sola sorgente del microfono del telefono apri Filtri, premi + e scegli APPISHOWDRIVE · Voce e ambiente.\n\nMusica, video e TTS devono restare su sorgenti separate. Trovi le istruzioni in LEGGIMI.txt.","APPISHOWDRIVE",MessageBoxButtons.OK,MessageBoxIcon.Information);
    } catch(Exception error) { MessageBox.Show(error.Message,"Installazione APPISHOWDRIVE non completata",MessageBoxButtons.OK,MessageBoxIcon.Error); }
  }
}
