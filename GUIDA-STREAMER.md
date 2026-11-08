# APPISHOWDRIVE Android — guida rapida

[Scarica l’APK Android firmato](https://github.com/Whis1/appishowdrive-android/releases/latest/download/APPISHOWDRIVE-Android.apk) · Versione 1.1.0 · Richiede Android 7 o successivo.

Puoi inoltrare questo collegamento su Discord: evita di dover allegare l’APK da circa 195 MB.

## Installazione

Scarica l'APK dal collegamento GitHub che ti viene fornito, aprilo sul telefono e conferma l'installazione Android. Se richiesto, autorizza una volta il browser o Discord a installare il file. L'icona è l'immagine ISHOWDRIVE fornita dalla community.

Questa è un'app separata: puoi tenere RealtimeChat originale installata. Al primo avvio collega i tuoi account e reimposta voce e sorgenti audio: questa nuova app ha uno spazio dati separato. Gli aggiornamenti successivi di APPISHOWDRIVE conservano account e impostazioni della nuova app.

## Twitch e Kick

1. Apri APPISHOWDRIVE e premi **Accedi con Twitch**, oppure entra in **Impostazioni → Account**.
2. Si apre il browser del telefono: accedi a Twitch e autorizza il collegamento. Poi torna in APPISHOWDRIVE.
3. In **Impostazioni → Account** premi il pulsante per aggiungere **Kick**. Accedi e autorizza nel browser, poi torna nell'app.
4. Quando entrambi sono collegati, l'app apre la chat unita dei tuoi canali Twitch e Kick.
5. Nella barra superiore della chat premi l’icona **altoparlante**: da barrata deve diventare attiva. Questo abilita il **TTS dei messaggi**. Non lasciare la modalità **Solo avvisi** se vuoi che legga le normali conversazioni di entrambe le piattaforme.

Non devi creare applicazioni sviluppatore, copiare Client ID, password o chiavi Kick. Le password si inseriscono soltanto nelle pagine ufficiali delle piattaforme. Il collegamento usa i servizi originali di RealtimeChat.

Se il browser non si apre o preferisci un altro dispositivo, nella schermata di collegamento trovi il QR. Puoi riaprire il browser dal pulsante dedicato. Se l'accesso scade, chiudi il collegamento e riprova.

## Voci italiane IA

In **Impostazioni → Testo in voce → Voci italiane IA**, premi **Scarica le voci italiane**. È un unico download facoltativo da circa 383 MiB per dieci voci, preferibilmente con Wi-Fi. Non viene riscaricato a ogni aggiornamento dell'app. Le voci sono generate da IA e la sintesi avviene sul telefono.

Ascolta il pulsante di anteprima accanto a una voce. Seleziona **Usa per Twitch**, **Usa per Kick**, oppure entrambe le spunte sulla stessa voce. Puoi scegliere due voci diverse. **Usa velocità naturale** imposta il ritmo di partenza; il cursore consente di regolarlo. Attiva il TTS dalla barra della chat come spiegato sopra.

La riga **Voce Android** permette di tornare alla voce di sistema per una o entrambe le piattaforme. Le opzioni avanzate originali, i filtri e gli utenti silenziati rimangono disponibili. Le prestazioni dipendono dal telefono; se il motore IA non è disponibile l'app conserva la selezione e ripiega sulla voce Android.

## Colori dell'interfaccia

In **Impostazioni → Colori dell’interfaccia** trovi dieci riquadri: ciano, nero, blu, viola, verde, marrone, giallo, rosso, arancione e grigio. Tocca il colore desiderato: l'interfaccia cambia subito e conserva la scelta al riavvio. Le modalità chiara, scura e automatica originali restano disponibili.

## Comandi Aura Arena — solo Twitch

Accanto alle emote premi l'icona Aura Arena: trovi **Comandi Aura**, con le sezioni **Solo Streamer** e **Solo utenti**. I comandi amministrativi sono utilizzabili dall'account proprietario del canale Twitch; il bot del gioco continua a verificarne i permessi.

Dall'elenco **!Processo, !Sanziona, !HP, !LevaHP, !LevaPA** compilano soltanto la bozza nella chat: completa nome/quantità e premi Invio. Il comando reale per aggiungere HP è **!HP N @utente**. Tenendo invece premuto il messaggio di un utente, **!Processo** e **!Sanziona** inviano subito il tag; **!AggiungiHP, !LevaHP, !LevaPA** chiedono la quantità e la spunta verde di invio.

Dopo **!Creatorneo** appaiono soltanto **ForzaTorneo / Senza Forzare**. Dopo la scelta appaiono **Partecipa al Torneo / Non partecipare**. Soltanto dopo questa seconda scelta compaiono **Iniziatorneo / Terminatorneo**. Le scelte Senza Forzare e Non partecipare non inviano comandi inventati. Il bot mantiene le regole del torneo, compreso il minimo di iscritti.

Durante le udienze il pannello streamer mostra **!Chiudiudienze, !Approva, !Rifiuta, !Arresta**; chiudendo torna all'elenco. Una sfida ricevuta dal bot offre **Accetta / Ignora**. Ignora nasconde l'invito senza inviare messaggi. Nessuno di questi controlli introduce i combattimenti manuali.

## Chat e anteprima

I badge di abbonamento/ruolo restano davanti al nome; la sola icona Twitch o Kick identifica la piattaforma sul lato destro del messaggio. La chat parte con caratteri più grandi, regolabili nelle impostazioni. L'anteprima usa **HD Auto**: il selettore consente anche 360p quando la connessione è debole. La qualità effettiva resta quella disponibile dalla live e dalla rete.

## Microfono e OBS

APPISHOWDRIVE gestisce chat, ascolto e anteprima: non acquisisce né trasmette il microfono. Il rumore del camion va trattato sulla sorgente reale che porta il telefono a OBS sul PC di casa. Per configurarlo serve sapere quale app invia quel segnale e se la voce arriva separata da TTS e Sound Alerts. Non applicare filtri all'uscita audio generale della live: altererebbero anche musica e avvisi.

## Sound Alerts e video YouTube

In **Impostazioni → Sorgenti audio** inserisci il link della tua **sorgente Sound Alerts / Video Share**, non il link del singolo video YouTube donato da uno spettatore. La coda delle donazioni resta gestita da Sound Alerts.

Il lettore TTS Android della base aggiornata riproduce la voce insieme alle altre sorgenti senza richiedere l'esclusiva dell'audio. Una lettura della chat non deve ricaricare la sorgente o inviare una pausa al lettore. Il link privato dello streamer va provato direttamente: i test automatici usano video e audio controllati, senza attivare donazioni reali.

## Aggiornamenti

APPISHOWDRIVE controlla GitHub all'apertura. Se non ci sono novità non riscarica l'app. Durante TTS o sorgenti audio attivi, propone il nuovo download e aspetta che tu prema **Scarica**, per non occupare automaticamente la connessione della live. A riposo può scaricare automaticamente.

Quando compare **Installa**, fallo al termine della live. Android chiederà conferma e, la prima volta, potrà chiederti di autorizzare APPISHOWDRIVE a installare i suoi aggiornamenti. Poi torna nell'app e premi nuovamente **Installa**. La verifica della firma impedisce di aggiornare l'app con APK appartenenti a un altro autore.

Il controllo manuale è in **Impostazioni → Aggiornamenti APPISHOWDRIVE**. La versione Android e quella dell'app Windows hanno aggiornamenti separati.
