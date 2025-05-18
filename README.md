# Instruksjoner for testing av smartkontrakten i Ethereum (f.eks. remix.ethereum.org)

1. **Registrer mottakere:**
   - Kjør funksjonen `hospitalReqReg` for å registrere mottakere først.

2. **Registrer donorer:**
   - Kjør funksjonen `hospitalDonaReg` for å registrere donorer etter mottakere.

3. **Start matching:**
   - Bruk donorens registreringsnummer og organets navn i funksjonen `matchingListDonor` for å initiere matching.

4. **Hent matchings-ID:**
   - Matching-funksjonen returnerer et matchings-ID.

5. **Finn beste match:**
   - Bruk `bestMatch` med matchings-ID for å få donor-ID og mottaker-ID med høyest prioritet.

6. **Godkjenn match:**
   - Donor bekrefter matchen med `donorAccept`.
   - Mottaker bekrefter matchen med `recipientAccept`.

7. **Kryssmatching og avklaringer:**
   - Bekreftelser skjer etter at kryssmatching er gjennomført og eventuelle bekymringer er håndtert.

8. **Sporing:**
   - Systemet sporer alle endringer og hendelser i blokkjeden gjennom hele prosessen.
