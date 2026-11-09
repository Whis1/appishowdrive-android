# APPISHOWDRIVE Android 1.1.2

- Rimossi il modello vocale integrato da circa 295 MB e tutti i pacchetti vocali TTS aggiuntivi; resta il motore predefinito configurato su Android. Restano le preferenze di velocità, tono e lettura.
- La migrazione al primo avvio elimina dal telefono solo le cartelle dei vecchi modelli vocali dell'app. Account, chat, impostazioni, sorgenti audio e aggiornamenti restano conservati.
- La sintesi vocale Android non richiede audio focus e non invia comandi di pausa alle sorgenti WebView audio/video. Il mix è stato verificato con una pagina locale di test nell'emulatore; l'overlay privato Sound Alerts/StreamElements e il telefono One UI 9 / Android 17 non erano disponibili per la prova diretta.
- Il comando streamer `!AggiungiPA N @utente` compare nel pannello Aura Arena e nel menu aperto tenendo premuto un messaggio. Il pannello prepara la bozza; il menu usa il login Twitch selezionato e chiede la quantità.

## 1.1.1

- Twitch, FrankerFaceZ, BetterTTV, Chatterino, pronomi scelti dagli utenti e nickname 7TV: controlli globali e singoli in Cronologia chat, attivi inizialmente. Un solo nome senza parentesi; tema 7TV applicato a quel nome. Correzione mirata al solo nero.
- Supertonic 2 e 3 rimossi dall’uso. Dieci profili di lettura italiana incorporati nell’APK, cinque femminili e cinque maschili, con anteprima e scelta indipendente Twitch/Kick. Sara/Nicola originali e otto timbri derivati. Motore in processo separato; ripiego Android quando non disponibile. Le voci integrate richiedono Android 8+ a 64 bit e memoria sufficiente.
- Mascotte Imperatore dopo login, una volta per avvio completo, in basso a sinistra con tocchi passanti, labiale sul tuo audio, sorriso finale a labbra chiuse, attesa di 2 secondi e dissolvenza. Spunta nelle impostazioni; nessuna ripetizione tornando da browser o pagine.
- I comandi Aura con destinatario, inclusi !Sfida e !Vincites, precompilano soltanto la chat. Menu utente, emote, TTS, account, temi e comandi esistenti preservati.
- Componente facoltativo OBS Windows per ridurre il rumore durante il parlato e ripristinare l’ambiente dopo. Installazione sul PC e sorgente microfono separata necessarie; musica, video e TTS restano su sorgenti distinte.

Telefono fisico, account dello streamer e collegamenti privati Sound Alerts/telefono→OBS non dichiarati testati. I combattimenti manuali non sono inclusi.

## Funzioni precedenti conservate

- Dieci temi colore nelle impostazioni: ciano, nero, blu, viola, verde, marrone, giallo, rosso, arancione e grigio, con anteprima e scelta salvata.
- Nuovo tema scuro, chat più leggibile, icone Twitch/Kick sul lato destro dei messaggi; badge originali dell'utente davanti al nome.
- Pannello Comandi Aura accanto alle emote, sezioni Solo Streamer e Solo utenti, comandi reali. Torneo in tre passaggi dopo !Creatorneo: ForzaTorneo / Senza Forzare → Partecipa al Torneo / Non partecipare → Iniziatorneo / Terminatorneo.
- Quattro decisioni durante le udienze e accettazione/ignora delle sfide. Menu utente con !Processo, !Sanziona e quantità HP/Aura. Nell'elenco i cinque comandi con destinatario precompilano soltanto il testo.
- Icona Android senza cornice nera vuota e anteprima HD Auto con selettore qualità.
- Mix delle voci neurali e audio video verificato sull'emulatore Android. Account, sorgenti audio, impostazioni e aggiornamenti conservati.
