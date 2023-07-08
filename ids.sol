// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

contract IdentityDirectory {

    modifier onlyRegistrar() {
        require(registrars[msg.sender], "Only authorized registrars can perform this operation.");
        _;
    }

    enum IdClass {
        dns,
        id,
        kyc,
        future
    }
    enum IdType {
        web3,
        web2,
        web1,
        formation,
        cluster,
        mx,
        future
    }
    struct IdFlags{
        bool requested;
        bool signed;
        bool valid; //combined with invalidated for 4 states (2 bits)
        bool invalidated; // combines with valid to make a state for neutral, valid, invalid and frozen.
        bool selfListed; // Also publishes to registrar list
        bool publicListed;
        bool future;
        bool future2;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct IdentityRequest {
        IdClass requestClass;
        IdType requestType;
        IdFlags flags;
        Signature registrant;
    }

    struct SignedIdentity {
        IdentityRequest request;
        Signature witness;
    }

    struct ValidatedIdentity {
        SignedIdentity identity;
        Signature[] witnesses;
        Signature[] registrars;
        Signature[] kycWitnesses;
    }

    struct ListedIdentity {
        bool active;
        ValidatedIdentity[] validId;
        Signature lister; // the registrar that authorized public listing of the validated record
        Signature[] witnesses; 
        Signature[] registrars;
        Signature[] kycWitnesses;
    }

    struct RegistrantStats {
        uint256 requestCount; // total count of requests sent
        uint256 uniqueCount; // unique requests sent
        uint256 signedCount; // total count of signed requests
        uint256 rejectedCount; // total count of rejected requests
        uint256 validCount; // total count of all validated IDs
        uint256 invalidCount; // total count of all invalidated IDs
        // publicly listed count can be inferred from selfIdList[address].length
    }

    struct WitnessStats {
        uint256 requestCount; // a count of all recieved requests
        uint256 rejectedCount; // a count of total identities rejected
        uint256 signedCount; // a count of total identities signed
        uint256 validCount; // total count of all validated signatures by a registrar
        uint256 invalidCount; // total count of all invalidated signatures by a registrar
        uint256 registrarRequestCount; // a count of total times the witness applied to become a registrar
        uint256 registrarApprovalCount; // a count of registrars who approve the request for a witness to registrar elevation
        uint256 registrarRejectedCount; // a count of registrars who rejected the request for a witness to registrar elevation
        // publicly listed count can be inferred from witnessIdList[address].length
    }

    struct RegistrarStats {
        uint256 validationCount; // total count of identities publicly listed
        uint256 rejectedCount; // a count of total identities rejected for validation
        uint256 validCount; // a count of total identities validated
        uint256 idRemovedCount; // total count of identities removed from the public directory
        uint256 uniqueRequestCount; // unique requests sent
        uint256 signedRequestCount; // total count of signed requests
        uint256 rejectedRequestCount; // total count of rejected requests
        // publicly listed count can be inferred from validIdList[address].length
    }

    // Registrar list for public listing rights
    mapping(address => bool) public projectFounder;
    mapping(address => bool) public registrars;
    uint256 public registrarCount;

    // Listed Identity Directory Records
    mapping(address => ListedIdentity[]) public validIdList; // the list of id records the address has validated which are public
    mapping(address => ListedIdentity[]) public witnessIdList; // the list of listed signed Ids by witness, a witnesses public record of all signed ids
    mapping(address => ListedIdentity[]) public selfIdList; // gets pushed to when a user requests a public record. This allows for reverse lookups
    mapping(address => ListedIdentity) public defaultIdentity; // gets a default Identity profile for a given address. Public for reverse lookup.

    // Identity Directory (Full)
    mapping(address => mapping(string => mapping (address => SignedIdentity))) public listedId; // gets an identity using the FQID from the public record. ie com.tiktok.user.7157726993374938117
    mapping(address => mapping(string => mapping (address => SignedIdentity))) private validId; // maps the registrant account to the validated identity and the identity to the witness. id[witness][idName][registrant]
    mapping(address => mapping(string => mapping (address => SignedIdentity))) private signedId; // maps the registrant account to the signed identity and the identity to the witness. id[witness][idName][registrant]
    mapping(address => mapping(string => mapping (address => IdentityRequest))) private requestedId; // maps the registrant account to the identity and the identity to the witness for approval. id[witness][idName][registrant]

    // Stats mappings
    mapping(address => RegistrantStats) public registrantStats;
    mapping(address => WitnessStats) public witnessStats;
    mapping(address => RegistrarStats) public registrarStats;
    
    //Checks for prior requests, signing or public listings
    mapping(string => bool) public isListed; // returns true or false if the identity is publicly listed.
    mapping(string => bool) public isValid;
    mapping(address => mapping(string => bool)) public isSigned; // returns true or false if the request has been signed by a specific witness.
    mapping(address => mapping(string => mapping(address => bool))) private isRequested; // returns true or false if the request has been requested by the specific registrant/registrar.    
    mapping(address => mapping(string => bool)) private hasRequested; // if the user has requested prior (used for unique calculations)
     
    // check valid TLD before registration
    mapping(string => bool) public validTLD;

    //Alerts
    event RequestIdentityAlert(
        address indexed witness,
        string requestedId,
        address registrant,
        IdClass idClass,
        IdType idType
    );
    event SignedIdentityAlert(
        address indexed witness,
        string signedId,
        address registrant,
        IdClass idClass,
        IdType idType
    );
    event RejectedIdentityAlert(
        address indexed witness,
        string signedId,
        address registrant,
        IdClass idClass,
        IdType idType
    );
    event UnsignedIdentityAlert(
        address indexed witness,
        string signedId,
        address registrant,
        IdClass idClass,
        IdType idType
    );
    event ValidatedIdentityAlert(
        address indexed registrar,
        address witness,
        string validId,
        address registrant,
        IdClass idClass,
        IdType idType
    );
    event ListedIdentityAlert(
        address indexed lister,
        address witness,
        string listedId,
        address registrant,
        IdClass idClass,
        IdType idType
    );

    // contract deployment
    constructor() {
        // Initialize the authorized registrar addresses
        projectFounder[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
        projectFounder[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
        projectFounder[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
        projectFounder[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105

        registrars[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
        registrars[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
        registrars[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
        registrars[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105
    }

    function signatureAddress(
        Signature memory _signature,
        string memory _message
    ) private pure returns (address) {
        bytes32 messageHash = keccak256(abi.encodePacked(_message));
        address recoveredAddress = ecrecover(
            messageHash,
            _signature.v,
            _signature.r,
            _signature.s
        );
        return recoveredAddress;
    }

    function signatureMatches(
        Signature memory _signature,
        address _signer,
        string memory _message
    ) private pure returns (bool) {
        address recoveredAddress = signatureAddress(_signature, _message);
        return (recoveredAddress != address(0) && recoveredAddress == _signer);
    }

    // user claims identity, requests signature from witness.
    function requestIdentity(
        address _witness,
        string memory _requestedIdentity,
        Signature memory _signature,
        IdClass _idClass,
        IdType _idType
    ) public {
        require(
            msg.sender != _witness,
            "Witness cannot sign their own request"
        );
        require(
            !isSigned[_witness][_requestedIdentity],
            "Identity already signed by this witness."
        );
        require(
            !isRequested[_witness][_requestedIdentity][msg.sender],
            "Identity already requested through registrar, use notifyRegistrar to emit another alert."
        );
        require(
            signatureMatches(_signature, msg.sender, _requestedIdentity),
            "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
        );

        // Initialize request
        IdFlags memory flags = IdFlags(true, false, false, false, false, false, false, false);
        // Store request
        requestedId[_witness][_requestedIdentity][msg.sender] = IdentityRequest(_idClass, _idType, flags, _signature);
        
        //updateStats(requestedId[_witness][_requestedIdentity][msg.sender]); // should update the RegistrantStats for requestCount and uniqueCount
        registrantStats[msg.sender].requestCount ++;
        registrantStats[msg.sender].uniqueCount += hasRequested[msg.sender][_requestedIdentity] ? 0 : 1;
        hasRequested[msg.sender][_requestedIdentity] = true;
        
        witnessStats[_witness].requestCount ++;


        emit RequestIdentityAlert(_witness, _requestedIdentity, msg.sender, _idClass, _idType);
    }

    function signIdentity(
        address _witness,
        string memory _requestedIdentity,
        address _registrant,
        Signature memory _signature
    ) public {
        require(
            msg.sender == _witness, 
            "Witness signature required."
        );
        require(
            !isSigned[_witness][_requestedIdentity],
            "Identity already signed."
        );
        require(
            signatureMatches(_signature, msg.sender, _requestedIdentity),
            "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
        );

        // Retrieve the identity request
        IdentityRequest memory idRequest = requestedId[_witness][_requestedIdentity][_registrant];
        Signature memory registrantSignature = idRequest.registrant;

        require(
            registrantSignature.r != bytes32(0),
            "This record has not been requested, have the registrant request this identity first."
        );

        // sign actions
        registrantStats[_registrant].signedCount ++;
        witnessStats[_witness].signedCount ++;
        idRequest.flags.signed = true;
        // adding record
        signedId[_witness][_requestedIdentity][_registrant] = SignedIdentity(idRequest, _signature);

        // sign notification
        IdClass idClass = idRequest.requestClass;
        IdType idType = idRequest.requestType;


        emit SignedIdentityAlert(_witness,_requestedIdentity,_registrant,idClass, idType);
    }

    function rejectIdentity(
        address _witness,
        string memory _requestedIdentity,
        address _registrant,
        Signature memory _signature
    ) public {
        require(
            msg.sender == _witness, 
            "Witness signature required."
        );
        require(
            !isSigned[_witness][_requestedIdentity],
            "Identity already signed."
        );
        require(
            signatureMatches(_signature, msg.sender, _requestedIdentity),
            "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
        );

        // Retrieve the identity request
        IdentityRequest memory idRequest = requestedId[_witness][_requestedIdentity][_registrant];
        Signature memory registrantSignature = idRequest.registrant;

        require(
            registrantSignature.r != bytes32(0),
            "This record has not been requested, have the registrant request this identity first."
        );

        // reject signature actions
        idRequest.flags.requested = false;

        // reject signature notification

        IdClass idClass = idRequest.requestClass;
        IdType idType = idRequest.requestType;

        emit RejectedIdentityAlert(_witness,_requestedIdentity,_registrant,idClass, idType);
    }

    function unsignIdentity(
        address _witness,
        string memory _requestedIdentity,
        address _registrant,
        Signature memory _signature
    ) public {
        require(
            msg.sender == _witness, 
            "Only signing witness unsign this record."
        );
        require(
            isSigned[_witness][_requestedIdentity],
            "Identity isn't signed."
        );
        require(
            signatureMatches(_signature, msg.sender, _requestedIdentity),
            "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
        );

        // Retrieve the identity request
        SignedIdentity memory id = signedId[_witness][_requestedIdentity][_registrant];
        
        // unsign actions
        id.witness = Signature(bytes32(0),bytes32(0),0);
        registrantStats[_registrant].signedCount --;
        witnessStats[_witness].signedCount --;
        id.request.flags.signed = false;

        //unsign alerts
        IdClass idClass = id.request.requestClass;
        IdType idType = id.request.requestType;

        emit UnsignedIdentityAlert(_witness,_requestedIdentity,_registrant,idClass, idType);
    }
}


// How an Identity Directory registration occurs

// User claims an identity and sends a request to a registrar (a registrar can guide a user through the process)

// The identity gets saved to the requestedIdentity mapping under registrar/user/identity

// Registrar gets notified and either approves or rejects the identity. 

// The identity gets saved to the signedIdentity mapping under registrar/user/identity

// The user can choose to list the identity, it gets pushed to their personal listedIdentities list as well as the registrar's signedIdentities list

// The user can request public listing to an authorized registrar where it gets pushed to the public authorizedIdentities list and becomes resolvable

// An Authorized Registrar can add a listed identity to the public identity directory and an authorized registrar can remove one
// if an identity gets removed it gets marked in the Registrar's stats as a removal. Registrars will have a rating calculated
// based on how many successful registrations the registrar had vs how many removals. Only prestine registrars will be able to add 
// other registrars and if any of the added registrars get removed this also impacts rating.  


    // struct Record {
    //     bool[] booleanValue;
    //     uint256[] unsignedIntegerValue;
    //     int256[] signedIntegerValue;
    //     address[] ethereumAddress;
    //     string[] stringValue;
    //     bytes32[] bytes32Value;
    //     bytes[] dynamicBytesValue;
    // }


// {
//   "A": {
//     "ipv4": "string (IPv4 address)"
//   },
//   "AAAA": {
//     "ipv6": "string (IPv6 address)"
//   },
//   "CNAME": {
//     "canonicalName": "string (domain name)"
//   },
//   "MX": {
//     "priority": "uint16",
//     "mailServer": "string (domain name)"
//   },
//   "TXT": {
//     "text": "string"
//   },
//   "NS": {
//     "nameServer": "string (domain name)"
//   },
//   "PTR": {
//     "domainName": "string (domain name)"
//   },
//   "SRV": {
//     "service": "string",
//     "protocol": "string",
//     "priority": "uint16",
//     "weight": "uint16",
//     "port": "uint16",
//     "target": "string (domain name)"
//   },
//   "SOA": {
//     "primaryNS": "string (domain name)",
//     "contactEmail": "string (email address)",
//     "serialNumber": "uint32",
//     "refresh": "uint32",
//     "retry": "uint32",
//     "expire": "uint32",
//     "minimumTTL": "uint32"
//   }
// }


    // // Function to add a TLD to the list
    // function addTLD(string memory _tld) public onlyRegistrar {
    //     validTLD[_tld] = true;
    // }

    // // Function to remove a TLD from the list
    // function removeTLD(string memory _tld) public onlyRegistrar {
    //     delete validTLD[_tld];
    // }

    // function addAuthorizedRegistrar(address newAuthorizedRegisrar) public onlyRegistrar() {
    //     require(
    //         !authorizedRegistrars[newAuthorizedRegisrar], 
    //         "Address is already an authorized Registrar."
    //     );
    //     if (authorizedRegistrarCount < 50) {
    //         require(projectFounder[msg.sender], "Project founder signature required to add new registrar.");
    //         authorizedRegistrars[newAuthorizedRegisrar] = true;
    //     } else {
    //         //governance
    //         authorizedRegistrars[newAuthorizedRegisrar] = true;
    //     }
    //     authorizedRegistrarCount ++;
    // }