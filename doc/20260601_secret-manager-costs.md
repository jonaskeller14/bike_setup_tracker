# Firebase / Secret Manager – unerwartete Kosten (Analyse 2026-06-01)

## Ausgangslage

Im Billing tauchten unerwartete Ausgaben unter **„Secret Manager"** auf (~10 Cent),
beginnend ca. **26. Mai 2026**. Erwartet waren 0 €, da die App noch keine User hat
und damit vermeintlich weit unter allen kostenfreien Limits liegt.

Verdacht: Zusammenhang mit den neu hinzugefügten **Play- / App-Store-Webhooks**.

## Ergebnis: Es sind Speicherkosten, keine Nutzungskosten

Die 10 Cent sind **keine Nutzungskosten**, sondern **Speichergebühren für aktive
Secret-Versionen**. Das ist der Punkt, der die Annahme „keine User = keine Kosten" bricht.

Secret Manager hat zwei getrennte Kostenarten mit getrennten Free Tiers:

| Kostenart | Free Tier | Preis darüber | Unser Verbrauch |
|---|---|---|---|
| **Access-Operationen** (Secret lesen) | 10.000 / Monat | $0,03 / 10.000 | praktisch 0 — Monitoring-Metrik `secret/access_count` hatte keine Daten |
| **Aktive Secret-Versionen** (reine Existenz) | **6 Versionen** | **$0,06 / Version / Monat** | **10 aktive Versionen** |

Die zweite Zeile ist die Ursache: Versionen werden abgerechnet, **weil das Secret
existiert** — unabhängig von Usern oder Zugriffen.

## Timeline – passt zu den Webhooks

Abgefragte Versionsstände (`gcloud secrets versions list`):

| Zeitraum | Aktive Versionen | Über Free Tier (6)? |
|---|---|---|
| seit Feb 2026 (nur Strava: `STRAVA_CLIENT_ID`, `STRAVA_CLIENT_SECRET`, `STRAVA_VERIFY_TOKEN` ×2) | **4** | nein → 0 € |
| ab **13./14. Mai 2026** (zusätzlich `APP_STORE_BUNDLE_ID`, `APP_STORE_ISSUER_ID`, `APP_STORE_KEY_ID`, `APP_STORE_PRIVATE_KEY` ×2, `GOOGLE_PLAY_SERVICE_ACCOUNT`) | **10** | ja, **4 drüber** |

Die 6 neuen Versionen wurden am 13./14. Mai angelegt — exakt beim Aufbau des
Subscription-/Webhook-Backends für Play & App Store (`backend_strava/functions/subscription.js`).
Damit stieg die Zahl aktiver Versionen von 4 → 10, also 4 über dem Free Tier:

> **4 × $0,06 = $0,24 / Monat**, anteilig für den Rest des Monats ≈ die beobachteten ~10 Cent.

Dass das Billing es erst **ab 26. Mai** zeigt, ist mit hoher Wahrscheinlichkeit der
übliche **Reporting-Verzug** von GCP bei Kleinstbeträgen (Tagessatz ~$0,008 wird
verzögert/gebündelt ausgewiesen). Die *Ursache* ist das Anlegen der Secrets am 13./14. Mai.
Exakt nachsehen lässt sich das im Cloud Billing → **„Cost table"**, gruppiert nach SKU
(„Secret Manager – Active secret versions").

## Wie man wieder auf 0 € kommt

### Schritt 1 – Redundante alte Versionen entsorgen (risikofrei, sofort)

**Hintergrund:** Cloud Functions liest immer nur die **neueste** (= höchste,
`latest`) Version eines Secrets. Ältere `enabled` Versionen werden nicht genutzt,
zählen aber weiter für die Kosten. Diese beiden Secrets haben je eine veraltete v1,
die noch aktiv ist:

- `APP_STORE_PRIVATE_KEY` → v1 alt, **v2 in Benutzung**
- `STRAVA_VERIFY_TOKEN` → v1 alt, **v2 in Benutzung**

Ziel: beide v1 zerstören → 10 → **8** aktive Versionen.

> `destroy` ist **irreversibel** (der Versionsinhalt wird gelöscht). Da beide v1
> bereits durch v2 ersetzt und nicht in Benutzung sind, ist das unkritisch. Die
> Secrets selbst und ihre v2 bleiben unberührt.

#### 1a. Vorab prüfen, welche Version aktiv genutzt wird

Vor dem Löschen sicherstellen, dass die **höchste** Versionsnummer `enabled` ist
(die wird von `latest` genutzt) — gelöscht wird nur die **niedrigere** alte:

```powershell
$env:CLOUDSDK_PYTHON = "C:\Program Files\Python312\python.exe"
gcloud secrets versions list APP_STORE_PRIVATE_KEY --format="table(name,state,createTime)"
gcloud secrets versions list STRAVA_VERIFY_TOKEN  --format="table(name,state,createTime)"
```

Erwartet: jeweils `1 enabled` (alt) und `2 enabled` (neu). Falls die höchste Nummer
**nicht** `enabled` ist, hier stoppen und Lage neu bewerten.

#### 1b. Variante CLI (empfohlen)

```powershell
$env:CLOUDSDK_PYTHON = "C:\Program Files\Python312\python.exe"   # gcloud braucht Python 3.10–3.14

gcloud secrets versions destroy 1 --secret=APP_STORE_PRIVATE_KEY --quiet
gcloud secrets versions destroy 1 --secret=STRAVA_VERIFY_TOKEN  --quiet
```

- `1` ist die zu zerstörende Versionsnummer (die alte).
- `--quiet` überspringt die interaktive Rückfrage; ohne das Flag fragt gcloud
  „Are you sure?" und du tippst `y`.

#### 1c. Variante Google Cloud Console (ohne Terminal)

1. <https://console.cloud.google.com/security/secret-manager?project=bike-setup-tracker-strava>
2. Secret **`APP_STORE_PRIVATE_KEY`** anklicken → Tab **„Versions"**.
3. In der Zeile von **Version 1** rechts auf das Drei-Punkte-Menü (⋮) → **„Destroy"**.
4. Im Dialog bestätigen (Name/Version eingeben, falls verlangt).
5. Schritte 2–4 für **`STRAVA_VERIFY_TOKEN`**, Version 1, wiederholen.

#### 1d. Ergebnis verifizieren

```powershell
$env:CLOUDSDK_PYTHON = "C:\Program Files\Python312\python.exe"
$total = 0
gcloud secrets list --format="value(name)" | ForEach-Object {
  $s = ($_ -split '/')[-1]
  $n = @(gcloud secrets versions list $s --filter="state=ENABLED" --format="value(name)").Count
  $total += $n
}
"SUMME aktive Versionen: $total"   # erwartet: 8
```

Die zerstörten Versionen erscheinen danach mit Status `destroyed` (sie bleiben als
Eintrag sichtbar, zählen aber nicht mehr als aktiv und kosten nichts).

### Schritt 2 – Nicht-geheime Identifier aus Secret Manager nehmen (komplett auf 0 €)

Drei der „Secrets" sind gar keine echten Geheimnisse, nur Bezeichner:

- `APP_STORE_BUNDLE_ID` – iOS-Bundle-Identifier (der Android-Identifier steht ohnehin
  bereits hartkodiert in `subscription.js`, Konstante `ANDROID_PACKAGE_NAME`).
- `APP_STORE_KEY_ID` und `APP_STORE_ISSUER_ID` – öffentliche Kennungen; geheim ist
  nur der `APP_STORE_PRIVATE_KEY`.

Führt man diese als normale Function-Parameter/`params` statt als Secret, bleiben nur
**5 echte Secrets** übrig (STRAVA ×3 nach Cleanup + `APP_STORE_PRIVATE_KEY` +
`GOOGLE_PLAY_SERVICE_ACCOUNT`) → **unter den 6 Free-Tier-Versionen → 0 €**.

> Für ~10 Cent/Monat lohnt der Refactor in Schritt 2 kaum; Schritt 1 genügt in der Praxis.

## Aktive Secret-Versionen einsehen

Maßgeblich für die Kosten ist die **Gesamtzahl aktiver (`ENABLED`) Versionen über
alle Secrets** (Free Tier: 6).

### Befehl A – einzelnes Secret
```powershell
$env:CLOUDSDK_PYTHON = "C:\Program Files\Python312\python.exe"
gcloud secrets versions list APP_STORE_PRIVATE_KEY --filter="state=ENABLED"
```

### Befehl B – Gesamtsumme über alle Secrets (PowerShell)
```powershell
$env:CLOUDSDK_PYTHON = "C:\Program Files\Python312\python.exe"
$total = 0
gcloud secrets list --format="value(name)" | ForEach-Object {
  $s = ($_ -split '/')[-1]
  $n = @(gcloud secrets versions list $s --filter="state=ENABLED" --format="value(name)").Count
  "{0,-32} {1}" -f $s, $n
  $total += $n
}
"SUMME aktive Versionen: $total  (Free Tier: 6)"
```

Stand 2026-06-01: **10 aktive Versionen** (4 über dem Free Tier).

> Hinweis: `gcloud secrets list` liefert den vollen Pfad
> `projects/.../secrets/NAME` und unter Windows CRLF-Zeilenenden — deshalb im Skript
> `($_ -split '/')[-1]` zum Extrahieren des Kurznamens. Ein direktes
> `for`-Durchreichen des Listen-Outputs an `versions list` schlägt sonst mit
> `does not match expected format [projects/*/secrets/*]` fehl.

### In der Console (grafisch)
- **Google Cloud Console → Secret Manager:**
  <https://console.cloud.google.com/security/secret-manager?project=bike-setup-tracker-strava>
  Pro Secret im Tab **„Versions"** stehen alle Versionen mit Status
  `Enabled` / `Disabled` / `Destroyed`. Eine fertige Gesamtsumme gibt es nicht —
  dafür Befehl B nutzen.
- **Kosten-Nachweis:** Console → **Billing → Cost table**, Group-by **SKU** →
  Eintrag „Secret Manager – Active secret version" zeigt abgerechnete Versionen
  und Beträge pro Tag.
- In der **Firebase Console** gibt es dafür **keine** eigene Ansicht — Secret Manager
  läuft ausschließlich über die Google-Cloud-Console.

## Merksatz

Secret-Manager-Kosten entstehen durch die **Existenz** von Secret-Versionen
(6 frei, dann $0,06/Stück/Monat), nicht durch deren Nutzung. „Keine User" schützt
nur vor den Access-Kosten, nicht vor den Versions-Speicherkosten.
