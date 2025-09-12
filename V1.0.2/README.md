# Point of Sale [Kassenprogramm]

Netzwerkfähiges Kassenprogramm, komplett in Windows Batch Script.
Am besten mit Laserscanner und Kundenkarten.
Selbstverständlich nicht für den produktiven Einsatz gedacht.

## Kurzanleitung
Ist direkt startklar in Standard Konfiguration. Bis auf die "kassenID" selbst sind keine Kundenkonten registriert.
Kunden registrieren, die Kundennummer sollte eine Nummer sein, kann aber auch aus Buchstaben bestehen.
Die artikel.csv am besten im Texteditor anpassen. Wichtig: das Format waren wie im Beispiel gezeigt.
Artikelnummern 0-9 als Beispiele eingerichtet.
Für Netzwerkfähigkeit, einfach den Ordner "files\kundenDatenbank" und "files\artikel.csv" im Netzwerk freigeben und entsprechend den Netzwerkpfad in der "config.ini" anpassen.


## Fehlerbehebung
Programme fertig rechnen lassen und dann erst schließen, vermeidet Fehler.
Schreibe "UNLOCK" im Kundennummern Feld um Blockaden zu lösen. 

