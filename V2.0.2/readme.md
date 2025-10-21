
### ! Kundenstamm-Struktur geändert !

Alle Kundenordner im Kundenstamm wurden in den Unterordner `root\acc\` verschoben.
**Grund:**  
Durch `lib\io` werden `.lock`-Ordner erstellt, um Zugriffskollisionen zu vermeiden.  
Um `.lock`-Ordner von Kunden-ID-Ordnern unterscheiden zu können, mussten die Kundenordner eine Ebene tiefer verschoben werden.

### Transaktionsprozesse ausgelagert

Transaktionen sind aufgrund der Kollisions­erkennung vergleichsweise langsam.  
Um den Verkaufsprozess nicht zu behindern, wird die Transaktion nun von einem Hintergrundprozess ausgeführt.  
Das Fenster schließt sich automatisch, sobald der Prozess abgeschlossen ist.
