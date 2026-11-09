# APPISHOWDRIVE Android — guida rapida

[Scarica l’APK Android firmato](https://github.com/Whis1/appishowdrive-android/releases/latest/download/APPISHOWDRIVE-Android.apk) · Versione 1.1.2 · Android 7 o successivo. Usa la voce predefinita configurata su Android.

Puoi inoltrare questo collegamento su Discord. Le voci TTS aggiuntive e i relativi modelli sono stati rimossi; non serve scaricare pacchetti vocali.

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

## Sintesi vocale Android

In **Impostazioni → Testo in voce** l'app usa soltanto la voce predefinita configurata nelle impostazioni TTS di Android. Puoi ascoltare il messaggio di prova e regolare velocità e tono. Le voci aggiuntive e il modello di grandi dimensioni sono stati rimossi; al primo avvio dopo l'aggiornamento vengono eliminati solo i vecchi file vocali dell'app. Account, chat, impostazioni e sorgenti audio restano conservati.

La lettura della chat non prende audio focus e non invia comandi di pausa alle sorgenti audio/video dell'app. Per il collaudo è stata usata una pagina locale di test: il collegamento privato di Sound Alerts/StreamElements e il telefono One UI 9 / Android 17 non erano disponibili per una prova diretta.

## Badge, pronomi e nomi

In **Impostazioni → Cronologia chat** scegli cosa mostrare: Twitch, FrankerFaceZ, BetterTTV, Chatterino, i pronomi scelti dagli utenti e i temi/effetti 7TV del nickname. Tutti sono attivi inizialmente; puoi disattivarli singolarmente o con **Disattiva tutto**, e riattivarli con **Attiva tutto**. Rimane disponibile la scelta dei singoli badge Twitch. I dati delle estensioni dipendono dai loro servizi pubblici; un errore di rete non deve fermare la chat.

Compare un solo nome, quello visualizzato sulla piattaforma, senza login tra parentesi. Il tema 7TV si applica a quel nome. L’opzione **Usa il nome di accesso** mostra soltanto il login in alternativa, mai due nomi. I nickname neri diventano chiari e leggibili sul tema scuro; gli altri colori mantengono il trattamento precedente.

## Mascotte di benvenuto

Dopo il login l’Imperatore saluta in basso a sinistra, con il tuo audio e il labiale sincronizzato. Alla fine mantiene un lieve sorriso a labbra chiuse per due secondi e durante la dissolvenza. I tocchi passano attraverso la figura: puoi continuare a usare chat e impostazioni. Si avvia una volta per apertura completa; tornare dal browser o da un’altra pagina non lo fa ripartire. La spunta **Impostazioni → Mascotte di benvenuto** lo disattiva.

## Colori dell'interfaccia

In **Impostazioni → Colori dell’interfaccia** trovi dieci riquadri: ciano, nero, blu, viola, verde, marrone, giallo, rosso, arancione e grigio. Tocca il colore desiderato: l'interfaccia cambia subito e conserva la scelta al riavvio. Le modalità chiara, scura e automatica originali restano disponibili.

## Comandi Aura Arena — solo Twitch

Accanto alle emote premi l'icona Aura Arena: trovi **Comandi Aura**, con le sezioni **Solo Streamer** e **Solo utenti**. I comandi amministrativi sono utilizzabili dall'account proprietario del canale Twitch; il bot del gioco continua a verificarne i permessi.

Dall'elenco **!Processo, !Sanziona, !HP, !LevaHP, !LevaPA, !AggiungiPA** compilano soltanto la bozza nella chat: completa nome/quantità e premi Invio. I comandi sono `!AggiungiPA quantità @utente` e `!LevaPA quantità @utente`. Il comando reale per aggiungere HP è **!HP N @utente**. Tenendo invece premuto il messaggio di un utente, **!Processo** e **!Sanziona** inviano subito il tag; **!AggiungiHP, !LevaHP, !LevaPA, !AggiungiPA** chiedono la quantità e usano il nome Twitch del messaggio selezionato.

Dopo **!Creatorneo** appaiono soltanto **ForzaTorneo / Senza Forzare**. Dopo la scelta appaiono **Partecipa al Torneo / Non partecipare**. Soltanto dopo questa seconda scelta compaiono **Iniziatorneo / Terminatorneo**. Le scelte Senza Forzare e Non partecipare non inviano comandi inventati. Il bot mantiene le regole del torneo, compreso il minimo di iscritti.

Durante le udienze il pannello streamer mostra **!Chiudiudienze, !Approva, !Rifiuta, !Arresta**; chiudendo torna all'elenco. Una sfida ricevuta dal bot offre **Accetta / Ignora**. Ignora nasconde l'invito senza inviare messaggi. Nessuno di questi controlli introduce i combattimenti manuali.

## Chat e anteprima

I badge di abbonamento/ruolo restano davanti al nome; la sola icona Twitch o Kick identifica la piattaforma sul lato destro del messaggio. La chat parte con caratteri più grandi, regolabili nelle impostazioni. L'anteprima usa **HD Auto**: il selettore consente anche 360p quando la connessione è debole. La qualità effettiva resta quella disponibile dalla live e dalla rete.

## Microfono e OBS

Android non consente ad APPISHOWDRIVE di filtrare il microfono catturato da un’altra app. Per questo il componente [APPISHOWDRIVE Voce OBS](https://github.com/Whis1/appishowdrive-android/releases/latest/download/APPISHOWDRIVE-Voce-OBS.zip) lavora sul PC che riceve la voce del telefono.

Dal PC: scarica ed estrai lo ZIP, chiudi OBS e apri **Installazione-Voce-OBS.exe**. Poi riapri OBS e aggiungi il filtro **APPISHOWDRIVE · Voce e ambiente** alla sola sorgente del microfono del telefono. Durante la voce riduce il rumore e rinforza il parlato; dopo la frase fa tornare l’ambiente. Lascia i valori iniziali e prova una breve registrazione. Nelle impostazioni dell’app trovi la stessa guida in **Voce e rumori della live**.

TTS, Sound Alerts e video devono avere sorgenti separate dal microfono. Se il telefono invia già tutto insieme, occorre prima separare la voce nel programma di trasmissione. Il filtro rileva il parlato, ma non identifica biometricamente lo streamer e non può garantire di distinguere un cantante se la canzone rientra nel microfono. Cuffie/auricolari evitano questo rientro. Il collegamento privato dello streamer richiede ancora una prova sul suo PC.

## Sound Alerts e video YouTube

In **Impostazioni → Sorgenti audio** inserisci il link della tua **sorgente Sound Alerts / Video Share**, non il link del singolo video YouTube donato da uno spettatore. La coda delle donazioni resta gestita da Sound Alerts.

Il lettore TTS Android della base aggiornata riproduce la voce insieme alle altre sorgenti senza richiedere l'esclusiva dell'audio. Una lettura della chat non deve ricaricare la sorgente o inviare una pausa al lettore. Il link privato dello streamer va provato direttamente: i test automatici usano video e audio controllati, senza attivare donazioni reali.

## Aggiornamenti

APPISHOWDRIVE controlla GitHub all'apertura. Se non ci sono novità non riscarica l'app. Durante TTS o sorgenti audio attivi, propone il nuovo download e aspetta che tu prema **Scarica**, per non occupare automaticamente la connessione della live. A riposo può scaricare automaticamente.

Quando compare **Installa**, fallo al termine della live. Android chiederà conferma e, la prima volta, potrà chiederti di autorizzare APPISHOWDRIVE a installare i suoi aggiornamenti. Poi torna nell'app e premi nuovamente **Installa**. La verifica della firma impedisce di aggiornare l'app con APK appartenenti a un altro autore.

Il controllo manuale è in **Impostazioni → Aggiornamenti APPISHOWDRIVE**. La versione Android e quella dell'app Windows hanno aggiornamenti separati.
