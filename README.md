# Point of Sale [Kassenprogramm]
### Das Programm ist besser als die Anleitung.

Netzwerkfähiges Kassenprogramm, komplett in Windows Batch Script.
Am besten mit Laserscanner und EAN nummern für Artikel und Kundenkarten.
Selbstverständlich nicht für den produktiven Einsatz gedacht.

## Kurzanleitung
Point of Sale, ist direkt startklar in Standard Konfiguration. Bis auf die "kassenID" selbst sind keine Kundenkonten registriert.
Kunden registrieren, die Kundennummer sollte eine Nummer sein, kann aber auch aus Buchstaben bestehen.
Artikel registrieren, die artikel.csv am besten im Texteditor anpassen. Wichtig: das Format bewahren wie in den beispielen gezeigt.
Artikelnummern 0-9 als Beispiele eingerichtet.

Für Netzwerkfähigkeit, einfach den Ordner "files\kundenDatenbank" und "files\artikel.csv" im Netzwerk freigeben und entsprechend den Netzwerkpfad in der "config.ini" anpassen.
Dann können im selben Netzwerk beliebig viele Rechner als Kasse benutzt werden.

## Fehlerbehebung
Programme fertig rechnen lassen und dann erst schließen, vermeidet Fehler.
Schreibe im Point of Sale "UNLOCK" im Kundennummern Feld um Blockaden zu lösen.


