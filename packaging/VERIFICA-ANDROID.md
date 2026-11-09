# Verifica APPISHOWDRIVE Android 1.1.2/build13 — 9 novembre 2026

Revisione del codice rilasciato, con nuove misure sulla versione corrente:

- 597 test Flutter dell’app e 94 del plugin passati; analyzer senza segnalazioni. I vecchi conteggi 632/47 riportati nel resoconto locale 1.1.2 provenivano dalla versione con i modelli neurali: non descrivevano la suite corrente dopo la loro rimozione.
- 12 test JVM attuali: 10 per l’identità degli aggiornamenti e 2 per la sicurezza delle callback TTS. I test dei motori neurali rimossi non sono più inclusi.
- Nuova prova nativa su emulatore Android API35, compilata dai sorgenti 1.1.2: sei letture con TTS Android e sei impulsi keep-alive mentre la sorgente video rimane attiva. Il video avanza, non viene messo in pausa e la pagina si apre una sola volta.
- Cattura audio indipendente: tono del video presente in tutte le 1.012 finestre di 20 ms misurate durante il parlato, 0 ms di vuoto rilevato. Anche il TTS è udibile nel mix. Il controllo deliberato pausa/ripresa è passato.
- Verificata la migrazione che elimina soltanto i modelli vocali dell’app e conserva le altre preferenze. `!AggiungiPA` verificato come bozza dalla lista e come login selezionato più quantità dal menu utente.
- Aggiunto un vincolo alla pubblicazione: la misura audio deve corrispondere all’impronta dei sorgenti vocali, nativi e della versione attuale. Un report di una versione precedente viene rifiutato.

Il report audio precedente del 7 novembre era stato richiamato dal resoconto locale della 1.1.2. Questa revisione lo sostituisce con una registrazione nuova del 9 novembre, riferita ai sorgenti correnti. L’APK pubblico 1.1.2 resta quello rilasciato: 98.913.335 byte, SHA256 `e2a146529e1f754cd3f14ec05242ef0abb8bbc39b1e03d15f95bffb6f0d240b5`.

La misura riguarda una sorgente controllata sull’emulatore. Link privato Sound Alerts/StreamElements, donazioni reali e telefono dello streamer restano da provare. La cattura QA non è inclusa nell’app. Non è stato modificato il codice runtime dell’APK durante questa revisione.

---

## Storico 1.1.0/build11

Verifiche dell'8 novembre 2026:

- Dieci temi colore con scelta salvata; contrasto di testo e pulsanti verificato per tutte le20combinazioni chiare/scure.
- 619 test Flutter dell'app e 94 del motore vocale superati; analyzer senza segnalazioni.
- 41 test JVM superati; un controllo opzionale di parità resta escluso perché richiede tensori di riferimento esterni. Tre controlli del collegamento al lettore Twitch superati.
- Voci italiane reali Supertonic 3 su emulatore Android15/API35: quattro timbri sintetizzati, sei messaggi riprodotti con il video attivo, nessuna pausa né ricarica della sorgente.
- Cattura indipendente del mix Android: segnale del video presente in tutte le 894 finestre da20ms durante la lettura neurale; nessun intervallo senza segnale video rilevato. Voce presente nello stesso mix; pausa/resume intenzionale successiva come controllo.
- UI Android con widget di produzione e account/messaggi di prova: comandi canonici, icone piattaforma solo sulla destra, sequenza torneo, udienze con quattro decisioni, invito e selezioni voci. I messaggi di prova non sono stati inviati in live.
- Il codice della barra originale Home, dei suoi controlli TTS/anteprima/notifiche/spettatori e del pannello emote originale è conservato. Il pulsante per aprire le emote ora usa una faccina locale sempre disponibile.
- Modello opzionale:16file,401.276.744byte, SHA256 e dimensioni verificati; peso esterno all'APK, dieci voci in un solo pacchetto. Licenza completa OpenRAIL-M inclusa, motoreMIT e fontOFL attribuiti.

La cattura è un'app di QA separata, esclusa dalla release. Nessuna nuova autorizzazione di acquisizione microfono nell'app. Telefono fisico, account reali e sorgente Sound Alerts privata dello streamer non sono stati provati. Il microfono in OBS richiede di identificare la sorgente reale inviata dal telefono.

Release1.1.0/build11 pubblicata e verificata: APK196.549.930byte, SHA256 `049bbc96c2c7d2e5c3885b28518f93af53155c50eb220960098333af0a5aed54`, stesso certificato permanente della1.0.0. Download pubblico completo e feed controllati. Aggiornamento reale1.0.0/build10→1.1.0/build11 tramite download nativo dal feedGitHub e normale installerAndroid, con autorizzazione della sorgente e conferma dell'utente; preferenzeTTS della configurazioneQA conservate. Nessun account reale usato.

Controlli GitHub del codice rilasciato superati: https://github.com/Whis1/appishowdrive-android/actions/runs/42505553654 .

---

## Storico1.0.0

# Verifica APPISHOWDRIVE Android 1.0.0

Verifiche del 7 novembre 2026:

- 599 test Flutter dell'app e 94 del motore vocale superati.
- 41 test JVM Android superati (un controllo opzionale di parità del motore neurale escluso per assenza dei tensori di riferimento), inclusi 10 controlli dell'identità degli aggiornamenti.
- 3 test della sorgente Twitch e analisi Flutter senza segnalazioni.
- Prova su Android 15/API35 con il motore TTS di sistema reale: sei messaggi, sei impulsi del mantenimento audio e una sola apertura della sorgente video.
- Registrazione del mix Android attraverso un'app QA separata: il segnale audio del video è presente in tutte le 1.268 finestre misurate da 20ms durante il TTS. Nessun intervallo di audio video assente rilevato. La voce è presente nello stesso mix; una pausa/resume deliberata successiva verifica il controllo della misura.

La prima fixture video di tre secondi presentava pause ai riavvii del loop: è stata sostituita con una clip continua di sessanta secondi. Le soglie della verifica non sono state allentate per superare la prova.

La cattura del mix è solo uno strumento di test sull'emulatore e non è inclusa nell'APK. Non sono state attivate donazioni, inviati messaggi in live o usate credenziali dello streamer. Il suo telefono, l'accesso reale ai suoi account e la sua sorgente privata Sound Alerts devono ancora essere provati direttamente.
## Pubblicazione e aggiornamento verificati — 8 novembre 2026

APK 1.0.0/build10 pubblico: 195.139.801 byte; SHA256 `c443a7a893d3e2e029cccfe470c98bb0395190d7c6979246900188d3350ba2f8`. Download pubblico completo, feed e firma verificati. APK minimo Android7/API24, ARM32/ARM64/x86_64. Nessun permesso di registrazione audio aggiunto nell'APK di produzione.

Aggiornamento reale sul solo emulatore Android15: baselineQA0.9.9/build9 → download dal feedGitHub pubblico → controllo nativo di integrità/firma → autorizzazione della sorgente e conferma nel normale installerAndroid → versione1.0.0/build10 avviata. Preferenze TTS conservate. L'accesso e la persistenza di account reali dello streamer non sono stati provati.

Controlli GitHub superati: https://github.com/Whis1/appishowdrive-android/actions/runs/42423209331 . Il repository pubblico parte da una copia verificata dei sorgenti attuali: non include vecchi commit upstream nei quali GitHub aveva rilevato credenziali di servizio. Nessun aggiramento della protezione, nessuna chiave di firma pubblicata.
