// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.10;
pragma abicoder v2;

// Kontrakt for håndtering av medisinske organmatchingsprosesser
contract medicalrecord {

    // Adresse til eier av kontrakten (den som deployer)
    address immutable owner = msg.sender;
    // Konstant for en tom adresse
    address constant blankAddress = 0x0000000000000000000000000000000000000000;
    // Hoved-ID for matchingsprosesser
    uint matchIDMain;
    // Konstanter for poengberegning
    uint constant initialScore = 30;
    uint constant patnerScore = 20;
    uint constant difScore = 1e6;

    // Struktur for mottakerspesifikasjon
    struct reqSpec {
        bool status; // Om mottakeren er aktiv
        address recipient; // Adresse til mottaker
        BloodType bloodType; // Blodtype
        uint organSize; // Størrelse på organ
        uint height; // Høyde
        uint weight; // Vekt
        uint condition; // Helsetilstand
        uint age; // Alder
        address hospital; // Sykehusadresse
        address donor; // Tilknyttet donor
        address bestMatch; // Beste match
        address[] bestMatchs; // Liste over beste matcher
    }

    // Struktur for donorspesifikasjon
    struct donaSpec {
        bool status; // Om donoren er aktiv
        address donor; // Adresse til donor
        BloodType bloodType; // Blodtype
        uint organSize; // Størrelse på organ
        uint height; // Høyde
        uint weight; // Vekt
        uint condition; // Helsetilstand
        uint age; // Alder
        address hospital; // Sykehusadresse
        bool alive; // Om donor er levende
        address recipient; // Tilknyttet mottaker
        address bestMatch; // Beste match
        address[] bestMatchs; // Liste over beste matcher
        string[] track; // Historikk/logg for donoren
    }

    // Struktur for et organ, med mappings for mottakere og donorer
    struct organ {
        uint did; // Antall donorer
        uint rid; // Antall mottakere
        mapping(uint => reqSpec) reqSpecs; // Mapping fra ID til mottaker
        mapping(uint => donaSpec) donaSpecs; // Mapping fra ID til donor
    }

    // Mapping fra organ-navn til organ-struktur
    mapping(string => organ) organs;

    // Enum for blodtyper
    enum BloodType {A, B, AB, O}

    // Struktur for å holde oversikt over matchingslister
    struct numList {
        string organ; // Navn på organ
        uint[] nums; // Poeng for hver kandidat
        uint[] userID; // ID-er til kandidater
        uint mainID; // Hoved-ID for matchen
        bool raccept; // Om mottaker har akseptert
        bool rreject; // Om mottaker har avslått
        bool daccept; // Om donor har akseptert
        bool dreject; // Om donor har avslått
        bool sorted; // Om listen er sortert
        // uint timee; // Tidspunkt (kan aktiveres ved behov)
        bool donation; // Om det gjelder donasjon
    }

    // Mapping fra matchID til numList
    mapping(uint => numList) numLists;

    /// @notice Registrerer en mottaker for et organ
    function hospitalReqReg(
        string memory _organ,
        uint _organSize,
        uint _height,
        uint _weight,
        uint _age,
        uint _condition,
        BloodType _bloodType,
        address _recipient,
        address _donor
    ) external returns(uint) {
        organs[_organ].rid++;
        uint _id = organs[_organ].rid;
        organs[_organ].reqSpecs[_id].status = true;
        organs[_organ].reqSpecs[_id].recipient = _recipient;
        organs[_organ].reqSpecs[_id].organSize = _organSize;
        organs[_organ].reqSpecs[_id].height = _height;
        organs[_organ].reqSpecs[_id].weight = _weight;
        organs[_organ].reqSpecs[_id].bloodType = _bloodType;
        organs[_organ].reqSpecs[_id].condition = _condition;
        organs[_organ].reqSpecs[_id].age = _age;
        organs[_organ].reqSpecs[_id].hospital = msg.sender;
        organs[_organ].reqSpecs[_id].donor = _donor;
        return(_id);
    }

    /// @notice Registrerer en donor for et organ
    function hospitalDonaReg(
        string memory _organ,
        uint _organSize,
        uint _height,
        uint _weight,
        uint _age,
        uint _condition,
        bool _alive,
        BloodType _bloodType,
        address _donor,
        address _recipient
    ) external returns(uint) {
        organs[_organ].did++;
        uint _id = organs[_organ].did;
        organs[_organ].donaSpecs[_id].status = true;
        organs[_organ].donaSpecs[_id].donor = _donor;
        organs[_organ].donaSpecs[_id].organSize = _organSize;
        organs[_organ].donaSpecs[_id].height = _height;
        organs[_organ].donaSpecs[_id].weight = _weight;
        organs[_organ].donaSpecs[_id].bloodType = _bloodType;
        organs[_organ].donaSpecs[_id].condition = _condition;
        organs[_organ].donaSpecs[_id].age = _age;
        organs[_organ].donaSpecs[_id].hospital = msg.sender;
        organs[_organ].donaSpecs[_id].alive = _alive;
        organs[_organ].donaSpecs[_id].recipient = _recipient;
        return(_id);
    }

    /// @notice Donor prøver å finne en passende mottaker
    function matchingListDonor(uint _ids, string memory _organ) external returns(uint) {
        require(organs[_organ].donaSpecs[_ids].status == true, "Den oppgitte ID-en er ikke tilgjengelig");
        uint score;
        uint matchID = matchIDMain;
        matchIDMain++;
        numLists[matchID].organ = _organ;
        numLists[matchID].mainID = _ids;

        for(uint i = 1; i <= organs[_organ].rid; i++) {
            score = initialScore;
            uint _id = i;
            // Sjekk blodtype og status
            if(organs[_organ].reqSpecs[_id].status == true && 
                (organs[_organ].donaSpecs[_ids].bloodType == organs[_organ].reqSpecs[_id].bloodType || 
                compareBlood(organs[_organ].donaSpecs[_ids].bloodType, organs[_organ].reqSpecs[_id].bloodType) == true)) {
                uint a = 0;
                if(organs[_organ].donaSpecs[_ids].alive == false) {
                    // Ekstra poeng hvis sykehus matcher
                    if(organs[_organ].reqSpecs[_id].hospital == organs[_organ].donaSpecs[_ids].hospital){score++;}
                    a = findDonorID(organs[_organ].reqSpecs[_id].donor, _organ);
                    // Sjekk om mottaker kom med donor
                    if(organs[_organ].reqSpecs[_id].donor == organs[_organ].donaSpecs[a].donor && organs[_organ].donaSpecs[a].recipient != blankAddress){score = score + patnerScore;}
                    // Sjekk match på størrelse, høyde, vekt, alder
                    if(organs[_organ].reqSpecs[_id].organSize == organs[_organ].donaSpecs[_ids].organSize){score++;}
                    if(organs[_organ].reqSpecs[_id].height == organs[_organ].donaSpecs[_ids].height){score++;}
                    if(organs[_organ].reqSpecs[_id].weight == organs[_organ].donaSpecs[_ids].weight){score++;}
                    if(organs[_organ].reqSpecs[_id].age == organs[_organ].donaSpecs[_ids].age){score++;}
                    // Legg til poeng for helsetilstand
                    score = score + organs[_organ].reqSpecs[_id].condition;
                    // Skaler poeng og legg til differanse
                    score = score * difScore;
                    score = score + difScore - _id;
                    numLists[matchID].nums.push(score);
                    numLists[matchID].userID.push(_id);
                } else {
                    a = findDonorID(organs[_organ].reqSpecs[_id].donor, _organ);
                    if(organs[_organ].reqSpecs[_id].donor == organs[_organ].donaSpecs[a].donor && organs[_organ].donaSpecs[a].recipient != blankAddress){score = score + patnerScore;}
                    if(organs[_organ].reqSpecs[_id].organSize == organs[_organ].donaSpecs[_ids].organSize){score++;}
                    if(organs[_organ].reqSpecs[_id].height == organs[_organ].donaSpecs[_ids].height){score++;}
                    if(organs[_organ].reqSpecs[_id].weight == organs[_organ].donaSpecs[_ids].weight){score++;}
                    if(organs[_organ].reqSpecs[_id].age == organs[_organ].donaSpecs[_ids].age){score++;}
                    score = score + organs[_organ].reqSpecs[_id].condition;
                    score = score * difScore;
                    score = score + difScore - _id;
                    numLists[matchID].nums.push(score);
                    numLists[matchID].userID.push(_id);
                }
            }
        }
        numLists[matchID].donation = true;
        // Sorter listen etter poeng (høyest først)
        decendingSort(matchID);
        return (matchID);
    }

    /// @notice Mottaker prøver å finne en passende donor
    function matchingListReci(uint _ids, string memory _organ) external returns(uint) {
        require(organs[_organ].reqSpecs[_ids].status == true, "Den oppgitte ID-en er ikke tilgjengelig");
        uint score;
        uint matchID = matchIDMain;
        matchIDMain++;
        numLists[matchID].organ = _organ;
        numLists[matchID].mainID = _ids;

        for(uint i = 1; i <= organs[_organ].did; i++) {
            score = initialScore;
            uint _id = i;
            // Sjekk blodtype og status
            if(organs[_organ].donaSpecs[_id].status == true && 
                (organs[_organ].donaSpecs[_id].bloodType == organs[_organ].reqSpecs[_ids].bloodType || 
                compareBlood(organs[_organ].donaSpecs[_id].bloodType, organs[_organ].reqSpecs[_ids].bloodType) == true)) {
                uint a = findRecipientID(organs[_organ].donaSpecs[_id].recipient, _organ);
                // Sjekk om donor kom med mottaker
                if(organs[_organ].donaSpecs[_id].donor == organs[_organ].reqSpecs[a].donor && organs[_organ].donaSpecs[_id].recipient != blankAddress){score = score + patnerScore;}
                // Sjekk match på størrelse, høyde, vekt, alder
                if(organs[_organ].donaSpecs[_id].organSize == organs[_organ].reqSpecs[_ids].organSize){score++;}
                if(organs[_organ].donaSpecs[_id].height == organs[_organ].reqSpecs[_ids].height){score++;}
                if(organs[_organ].donaSpecs[_id].weight == organs[_organ].reqSpecs[_ids].weight){score++;}
                if(organs[_organ].donaSpecs[_id].age == organs[_organ].reqSpecs[_ids].age){score++;}
                score = score * difScore;
                score = score + difScore - _id;
                numLists[matchID].nums.push(score);
                numLists[matchID].userID.push(_id);
                score++;
            }
        }
        // Sorter listen etter poeng (høyest først)
        decendingSort(matchID);
        return (matchID);
    }

    /// @notice Sjekker om blodtypene er kompatible
    function compareBlood (BloodType _bloodTypeDonor, BloodType _bloodTypeReci) private pure returns(bool) {
        bool aaa = false;
        if((_bloodTypeReci == BloodType.A || _bloodTypeReci == BloodType.AB) && _bloodTypeDonor == BloodType.A){
            aaa = true;
        } else if ((_bloodTypeReci == BloodType.B || _bloodTypeReci == BloodType.AB) && _bloodTypeDonor == BloodType.B ){
            aaa = true;
        } else if (_bloodTypeReci == BloodType.AB && _bloodTypeDonor == BloodType.AB){
            aaa = true;
        } else if ((_bloodTypeReci == BloodType.A || _bloodTypeReci == BloodType.B || _bloodTypeReci == BloodType.AB || _bloodTypeReci == BloodType.O) && _bloodTypeDonor == BloodType.O){
            aaa = true;
        }
        return (aaa);
    }

    /// @notice Sorterer kandidatlisten synkende etter poeng
    function decendingSort(uint _matchID) private {
        numLists[_matchID].nums.push(0);
        numLists[_matchID].userID.push(0);
        numLists[_matchID].sorted = true;
        for(uint j = 0; j < numLists[_matchID].nums.length-2; j++){
            sortd(_matchID);
        }
        numLists[_matchID].nums.pop();
        numLists[_matchID].userID.pop();
    }

    /// @notice Hjelpefunksjon for sortering
    function sortd (uint _matchID) private {
        for (uint i = 0; i < numLists[_matchID].nums.length-2; i++){
            if(numLists[_matchID].nums[i] < numLists[_matchID].nums[i+1]){
                uint currentNum = numLists[_matchID].nums[i];
                uint currentID = numLists[_matchID].userID[i];
                numLists[_matchID].nums[i] = numLists[_matchID].nums[i+1];
                numLists[_matchID].userID[i] = numLists[_matchID].userID[i+1];
                numLists[_matchID].nums[i + 1] = currentNum;
                numLists[_matchID].userID[i + 1] = currentID;
            }
        }
    }

    /// @notice Hent informasjon om en donor
    function viewDonor(uint _id, string memory _organ) external view returns(donaSpec memory){
        return(organs[_organ].donaSpecs[_id]);
    }

    /// @notice Hent informasjon om en mottaker
    function viewRecipient(uint _id, string memory _organ) external view returns(reqSpec memory){
        return(organs[_organ].reqSpecs[_id]);
    }

    /// @notice Finn donor-ID basert på adresse
    function findDonorID(address _donorAddress, string memory _organ) public view returns(uint){
        uint a = 0;
        for (uint i = 1; i <= organs[_organ].did; i++){
            if(organs[_organ].donaSpecs[i].donor == _donorAddress){
                a = i;
            }
        }
        return(a);
    }

    /// @notice Finn mottaker-ID basert på adresse
    function findRecipientID(address _recipientAddress, string memory _organ) public view returns(uint){
        uint a = 0;
        for (uint i = 1; i <= organs[_organ].rid; i++){
            if(organs[_organ].reqSpecs[i].recipient == _recipientAddress){
                a = i;
            }
        }
        return(a);
    }

    /// @notice Donor godkjenner eller avslår match
    function donorAcceptance(uint _matchID, bool _response) external {
        require(organs[numLists[_matchID].organ].donaSpecs[numLists[_matchID].mainID].status == true, "Denne donoren er ikke tilgjengelig");
        require(organs[numLists[_matchID].organ].donaSpecs[numLists[_matchID].mainID].donor == msg.sender, "Du er ikke eier av kontoen");
        if (_response == true && numLists[_matchID].daccept == false && numLists[_matchID].dreject == false){
            numLists[_matchID].daccept = true;
        } else if(_response == false && numLists[_matchID].daccept == false && numLists[_matchID].dreject == false){
            numLists[_matchID].dreject = true;
            decendingSort(_matchID);
        }
        deactivate(_matchID);
    }

    /// @notice Mottaker godkjenner eller avslår match
    function recipientAcceptance(uint _matchID, bool _response) external {
        if (_response == true && numLists[_matchID].raccept == false && numLists[_matchID].rreject == false){
            numLists[_matchID].raccept = true;
        } else if(_response == false && numLists[_matchID].raccept == false && numLists[_matchID].rreject == false){
            delete numLists[_matchID].nums[0];
            delete numLists[_matchID].userID[0];
            decendingSort(_matchID);
        }
        deactivate(_matchID);
    }

    /// @notice Deaktiverer donor og mottaker hvis begge har akseptert
    function deactivate (uint _matchID) private {
        uint recipientID = numLists[_matchID].userID[0];
        string memory _organ = numLists[_matchID].organ;
        uint _id = numLists[_matchID].mainID;
        if(numLists[_matchID].daccept == true && numLists[_matchID].raccept == true){
            organs[_organ].donaSpecs[_id].status = false;
            organs[_organ].reqSpecs[recipientID].status = false;
        }
    }

    /// @notice Fjerner første kandidat fra listen (f.eks. ved timeout)
    function removeFirstCandidate (uint _matchID) external {
        require(numLists[_matchID].raccept == false, "Mottakeren har akseptert");
        delete numLists[_matchID].nums[0];
        delete numLists[_matchID].userID[0];
        decendingSort(_matchID);
    }

    /// @notice Returnerer informasjon om beste match
    function bestMatch(uint _matchID) external view returns(string memory, bool, uint, uint){
        return(numLists[_matchID].organ, numLists[_matchID].donation, numLists[_matchID].mainID, numLists[_matchID].userID[0]);
    }

    /// @notice Oppdaterer donorens historikk/logg
    function updateTrack(string memory _organ, uint _id, string memory _update) external {
        organs[_organ].donaSpecs[_id].track.push(_update);
    }

    /// @notice Henter donorens historikk/logg
    function viewTrack(string memory _organ, uint _id) external view returns(string[] memory){
        return organs[_organ].donaSpecs[_id].track;
    }

    /// @notice Sjekker status på aksept/avslag for donor og mottaker
    function checkAcceptance (uint _matchID) external view returns(bool, bool, bool, bool){
        return(numLists[_matchID].daccept, numLists[_matchID].dreject, numLists[_matchID].raccept, numLists[_matchID].rreject);
    }
}
