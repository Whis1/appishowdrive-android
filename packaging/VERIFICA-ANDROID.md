# Verifica APPISHOWDRIVE Android 1.0.0

Verifiche del 7 novembre 2026:

- 599 test Flutter dell'app e 94 del motore vocale superati.
- 41 test JVM Android superati (un controllo opzionale di parità del motore neurale escluso per assenza dei tensori di riferimento), inclusi 10 controlli dell'identità degli aggiornamenti.
- 3 test della sorgente Twitch e analisi Flutter senza segnalazioni.
- Prova su Android 15/API35 con il motore TTS di sistema reale: sei messaggi, sei impulsi del mantenimento audio e una sola apertura della sorgente video.
- Registrazione del mix Android attraverso un'app QA separata: il segnale audio del video è presente in tutte le 1.268 finestre misurate da 20ms durante il TTS. Nessun intervallo di audio video assente rilevato. La voce è presente nello stesso mix; una pausa/resume deliberata successiva verifica il controllo della misura.

La prima fixture video di tre secondi presentava pause ai riavvii del loop: è stata sostituita con una clip continua di sessanta secondi. Le soglie della verifica non sono state allentate per superare la prova.

La cattura del mix è solo uno strumento di test sull'emulatore e non è inclusa nell'APK. Non sono state attivate donazioni, inviati messaggi in live o usate credenziali dello streamer. Il suo telefono, l'accesso reale ai suoi account e la sua sorgente privata Sound Alerts devono ancora essere provati direttamente.
