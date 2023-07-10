// // SPDX-License-Identifier: GPL-3.0

// pragma solidity ^0.8.18;

// contract IdentityDirectory {

//     modifier onlyRegistrar() {
//         require(registrars[msg.sender], "Only authorized registrars can perform this operation.");
//         _;
//     }

//     enum IdClass {
//         none,
//         dns,
//         id,
//         kyc,
//         future
//     }
//     enum IdType {
//         none,
//         web3,
//         web2,
//         web1,
//         formation,
//         cluster,
//         mx,
//         future
//     }
//     struct IdFlags{
//         bool requested;
//         bool signed;
//         bool valid; //combined with invalidated for 4 states (2 bits)
//         bool invalidated; // combines with valid to make a state for neutral, valid, invalid and frozen.
//         bool listed; // Also publishes to registrar list
//         bool future;
//         bool future1;
//         bool future2;
//     }

//     struct Signature {
//         bytes32 r;
//         bytes32 s;
//         uint8 v;
//     }

//     struct IdentityRequest {
//         IdClass requestClass;
//         IdType requestType;
//         IdFlags flags;
//         Signature registrant;
//     }

//     struct SignedIdentity {
//         IdentityRequest request;
//         Signature witness;
//     }

//     struct ValidatedIdentity {
//         SignedIdentity signed;
//         Signature registrar;
//         uint256 witnessSigCount;
//         mapping(uint256 => Signature) witnesses;
//         uint256 registrarSigCount;
//         mapping(uint256 => Signature) registrars;
//         uint256 kycSigCount;
//         mapping(uint256 => Signature) kycWitnesses;
//     }

//     struct RegistrantStats {
//         uint256 requestCount; // total count of requests sent
//         uint256 uniqueCount; // unique requests sent
//         uint256 signedCount; // total count of signed requests
//         uint256 rejectedCount; // total count of rejected requests
//         uint256 validCount; // total count of all validated IDs
//         uint256 invalidCount; // total count of all invalidated IDs
//         // publicly listed count can be inferred from selfIdList[address].length
//     }

//     struct WitnessStats {
//         uint256 requestCount; // a count of all recieved requests
//         uint256 rejectedCount; // a count of total identities rejected
//         uint256 signedCount; // a count of total identities signed
//         uint256 validCount; // total count of all validated signatures by a registrar
//         uint256 invalidCount; // total count of all invalidated signatures by a registrar
//         uint256 registrarRequestCount; // a count of total times the witness applied to become a registrar
//         uint256 registrarApprovalCount; // a count of registrars who approve the request for a witness to registrar elevation
//         uint256 registrarRejectedCount; // a count of registrars who rejected the request for a witness to registrar elevation
//         // publicly listed count can be inferred from witnessIdList[address].length
//     }

//     struct RegistrarStats {
//         uint256 validCount; // a count of total identities validated
//         uint256 invalidatedCount; // a count of how many invalidated records you've pushed
//         uint256 rejectedCount; // a count of total identities rejected for validation
//         uint256 removedCount; // total count of identities removed from the public directory
//         // publicly listed count can be inferred from validIdList[address].length
//     }

//     // Registrar list for public listing rights
//     mapping(address => bool) public projectFounder;
//     mapping(address => bool) public registrars;
//     uint256 public registrarCount;

//     // Publicly Listed Identity Directory Records
//     mapping(address => ValidatedIdentity[]) public validIdList; // the list of id records the address has validated which are public
//     mapping(address => SignedIdentity[]) public witnessIdList; // the list of listed signed Ids by witness, a witnesses public record of all signed ids
//     mapping(address => SignedIdentity[]) public selfIdList; // gets pushed to when a user requests a public record. This allows for reverse lookups
//     mapping(address => ValidatedIdentity) public defaultIdentity; // gets a default Identity profile for a given address. Public for reverse lookup.

//     // Public Identity Directory
//     mapping(string => ValidatedIdentity) public i; // the public record for an id
//     mapping(string => address) public validatingRegistrar; // the registrar of a validated id

//     // Identity Directory (Fully Qualified Identity witness.idname.entity)
//     mapping(address => mapping(string => mapping (address => SignedIdentity))) public listedId; // gets an identity using the FQID from the public record. ie com.tiktok.user.7157726993374938117
//     mapping(address => mapping(string => mapping (address => ValidatedIdentity))) private validId; // maps the registrant account to the validated identity and the identity to the witness. id[witness][idName][registrant]
//     mapping(address => mapping(string => mapping (address => SignedIdentity))) private signedId; // maps the registrant account to the signed identity and the identity to the witness. id[witness][idName][registrant]
//     mapping(address => mapping(string => mapping (address => IdentityRequest))) private requestedId; // maps the registrant account to the identity and the identity to the witness for approval. id[witness][idName][registrant]

//     // Stats mappings
//     mapping(address => RegistrantStats) public registrantStats;
//     mapping(address => WitnessStats) public witnessStats;
//     mapping(address => RegistrarStats) public registrarStats;
    
//     //Checks for prior requests, signing or public listings
//     mapping(string => bool) public isListed; // returns true or false if the identity is publicly listed.
//     mapping(string => bool) private isValid;
//     mapping(address => mapping(string => bool)) public isSigned; // returns true or false if the request has been signed by a specific witness.
//     mapping(address => mapping(string => mapping(address => bool))) private isRequested; // returns true or false if the request has been requested by the specific registrant/registrar.    
//     mapping(address => mapping(string => bool)) private hasRequested; // if the user has requested prior (used for unique calculations)
     
//     // check valid TLD before registration
//     mapping(string => bool) public validTLD;

//     //Alerts
//     event RequestIdentityAlert(
//         string indexed requestedId,
//         address witness,
//         IdClass idClass,
//         IdType idType
//     );
//     event SignedIdentityAlert(
//         string indexed signedId,
//         address witness,
//         IdClass idClass,
//         IdType idType
//     );
//     event RejectedIdentityAlert(
//         string indexed signedId,
//         address registrant,
//         IdClass idClass,
//         IdType idType
//     );
//     event UnsignedIdentityAlert(
//         string indexed signedId,
//         address witness,
//         IdClass idClass,
//         IdType idType
//     );
//     event ValidatedIdentityAlert(
//         string indexed validId,
//         address registrar,
//         address witness,
//         IdClass idClass,
//         IdType idType
//     );
//     event ValidationCollisionAlert(
//         string indexed validId,
//         address previousRegistrar,
//         address currentRegistrar,
//         IdClass idClass,
//         IdType idType
//     );
//     event ListedIdentityAlert(
//         address indexed lister,
//         string listedId,
//         address registrant,
//         IdClass idClass,
//         IdType idType
//     );

//     // contract deployment
//     constructor() {
//         // Initialize the authorized registrar addresses
//         projectFounder[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
//         projectFounder[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
//         projectFounder[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
//         projectFounder[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105

//         registrars[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
//         registrars[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
//         registrars[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
//         registrars[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105
//     }

//     function signatureAddress(
//         Signature memory _signature,
//         string memory _message
//     ) private pure returns (address) {
//         bytes32 messageHash = keccak256(abi.encodePacked(_message));
//         address recoveredAddress = ecrecover(
//             messageHash,
//             _signature.v,
//             _signature.r,
//             _signature.s
//         );
//         return recoveredAddress;
//     }

//     function signatureMatches(
//         Signature memory _signature,
//         address _signer,
//         string memory _message
//     ) private pure returns (bool) {
//         address recoveredAddress = signatureAddress(_signature, _message);
//         return (recoveredAddress != address(0) && recoveredAddress == _signer);
//     }

//     // user claims identity, requests signature from witness.
//     function requestIdentity(
//         address _witness,
//         string memory _requestedIdentity,
//         Signature memory _signature,
//         IdClass _idClass,
//         IdType _idType
//     ) public {
//         require(
//             msg.sender != _witness,
//             "Witness cannot sign their own request"
//         );
//         require(
//             !isSigned[_witness][_requestedIdentity],
//             "Identity already signed by this witness."
//         );
//         require(
//             !isRequested[_witness][_requestedIdentity][msg.sender],
//             "Identity already requested through registrar, use notifyRegistrar to emit another alert."
//         );
//         require(
//             signatureMatches(_signature, msg.sender, _requestedIdentity),
//             "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
//         );

//         // Initialize request
//         IdFlags memory flags = IdFlags(true, false, false, false, false, false, false, false);
//         // Store request
//         requestedId[_witness][_requestedIdentity][msg.sender] = IdentityRequest(_idClass, _idType, flags, _signature);
        
//         //updateStats(requestedId[_witness][_requestedIdentity][msg.sender]); // should update the RegistrantStats for requestCount and uniqueCount
//         registrantStats[msg.sender].requestCount ++;
//         registrantStats[msg.sender].uniqueCount += hasRequested[msg.sender][_requestedIdentity] ? 0 : 1;
//         hasRequested[msg.sender][_requestedIdentity] = true;
        
//         witnessStats[_witness].requestCount ++;


//         emit RequestIdentityAlert(_requestedIdentity,_witness,  _idClass, _idType);
//     }

//     function signIdentity(
//         address _witness,
//         string memory _requestedIdentity,
//         address _registrant,
//         Signature memory _signature
//     ) public {
//         require(
//             msg.sender == _witness, 
//             "Witness signature required."
//         );
//         require(
//             !isSigned[_witness][_requestedIdentity],
//             "Identity already signed."
//         );
//         require(
//             signatureMatches(_signature, msg.sender, _requestedIdentity),
//             "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
//         );

//         // Retrieve the identity request
//         IdentityRequest memory idRequest = requestedId[_witness][_requestedIdentity][_registrant];
//         Signature memory registrantSignature = idRequest.registrant;

//         require(
//             registrantSignature.r != bytes32(0),
//             "This record has not been requested, have the registrant request this identity first."
//         );
//         require(
//             signatureMatches(registrantSignature, _registrant, _requestedIdentity),
//             "Invalid signature. Registrant signature error"
//         );

//         // sign actions
//         registrantStats[_registrant].signedCount ++;
//         witnessStats[_witness].signedCount ++;
//         idRequest.flags.signed = true;
//         // adding record
//         isSigned[_witness][_requestedIdentity] = true;
//         signedId[_witness][_requestedIdentity][_registrant] = SignedIdentity(idRequest, _signature);
//         //privateSigned[_requestedIdentity][_registrant] = SignedIdentity(idRequest, _signature);

//         // sign notification
//         IdClass idClass = idRequest.requestClass;
//         IdType idType = idRequest.requestType;


//         emit SignedIdentityAlert(_requestedIdentity, _witness, idClass, idType);
//     }

//     function rejectIdentity(
//         address _witness,
//         string memory _requestedIdentity,
//         address _registrant
//     ) public {
//         require(
//             msg.sender == _witness, 
//             "Witness signature required."
//         );
//         require(
//             !isSigned[_witness][_requestedIdentity],
//             "Identity already signed."
//         );

//         // Retrieve the identity request
//         IdentityRequest memory idRequest = requestedId[_witness][_requestedIdentity][_registrant];
//         Signature memory registrantSignature = idRequest.registrant;

//         require(
//             registrantSignature.r != bytes32(0),
//             "This record has not been requested, have the registrant request this identity first."
//         );

//         // reject signature actions
//         idRequest.flags.requested = false;

//         // reject signature notification

//         IdClass idClass = idRequest.requestClass;
//         IdType idType = idRequest.requestType;

//         emit RejectedIdentityAlert(_requestedIdentity,_registrant,idClass, idType);
//     }

//     function unsignIdentity(
//         address _witness,
//         string memory _requestedIdentity,
//         address _registrant,
//         Signature memory _signature
//     ) public {
//         require(
//             msg.sender == _witness, 
//             "Only signing witness may unsign this record."
//         );
//         require(
//             !isValid[_requestedIdentity],
//             "Validated identities cannot be unsigned."
//         );
//         require(
//             isSigned[_witness][_requestedIdentity],
//             "Identity isn't signed."
//         );
//         require(
//             signatureMatches(_signature, msg.sender, _requestedIdentity),
//             "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
//         );

//         // Retrieve the identity request
//         SignedIdentity memory id = signedId[_witness][_requestedIdentity][_registrant];
        
//         // unsign actions
//         id.witness = Signature(bytes32(0),bytes32(0),0);
//         registrantStats[_registrant].signedCount --;
//         witnessStats[_witness].signedCount --;
//         id.request.flags.signed = false;
//         isSigned[_witness][_requestedIdentity] = true;

//         //unsign alerts
//         IdClass idClass = id.request.requestClass;
//         IdType idType = id.request.requestType;

//         emit UnsignedIdentityAlert(_requestedIdentity, _witness, idClass, idType);
//     }

//     function validateIdentity(
//         address _witness,
//         string memory _requestedIdentity,
//         address _registrant,
//         Signature memory _signature
//     ) public onlyRegistrar {

//         SignedIdentity storage sid = signedId[_witness][_requestedIdentity][_registrant];
//         IdClass idClass = sid.request.requestClass;
//         IdType idType = sid.request.requestType;
//         // should check signature validity of all requests
//         if(isValid[_requestedIdentity]) { // check if record already exists

//             // Retrieve the identity and registrant signature of the current request
//             Signature memory registrantSig = sid.request.registrant;

//             // Retrieve the address of the record's registrar and the record's signature, registrant signature should match
//             address previousRegistrar = validatingRegistrar[_requestedIdentity];
//             SignedIdentity storage oldId = signedId[previousRegistrar][_requestedIdentity][_registrant];
//             Signature memory previousSig = oldId.request.registrant;

//             if (registrantSig.r == previousSig.r) { // if record matches previous record
//                 // get the validated record and push new registrar signature
//                 ValidatedIdentity storage vid = validId[previousRegistrar][_requestedIdentity][_registrant];
//                 vid.registrars[registrarCount];
//                 // update registrant, witness and registrar stats
//                 registrantStats[_registrant].validCount ++;
//                 witnessStats[_registrant].validCount ++;
//                 registrarStats[msg.sender].validCount ++;

//             } else { // check for collision

//                 validId[msg.sender][_requestedIdentity][_registrant] = ValidatedIdentity(sid, _signature, 0, , 0, , 0, );
//                 sid.request.flags.invalidated=true;
//                 oldId.request.flags.invalidated=true; // valid but frozen

//                 address oldWitness = signatureAddress(oldId.witness, _requestedIdentity);
//                 address oldRegistrant = signatureAddress(oldId.request.registrant, _requestedIdentity);

//                 registrantStats[oldRegistrant].validCount --;
//                 witnessStats[oldWitness].validCount --;
//                 registrarStats[previousRegistrar].validCount --;

//                 registrarStats[previousRegistrar].invalidatedCount ++;
//                 registrarStats[msg.sender].invalidatedCount ++;

//                 emit ValidationCollisionAlert(_requestedIdentity, previousRegistrar, msg.sender, idClass, idType);
//             }

//         } else {
//             sid.request.flags.valid = true; // set record as valid
//             validId[msg.sender][_requestedIdentity][_registrant] = ValidatedIdentity(sid, _signature, new Signature[](0), new Signature[](0), new Signature[](0));
//             registrantStats[_registrant].validCount ++;
//             witnessStats[_registrant].validCount ++;
//             registrarStats[msg.sender].validCount ++;
//         }

//     }

//     function makePublic(address _authority, string memory _requestedIdentity, Signature memory _signature) public {
//         ValidatedIdentity storage vid = validId[_authority][_requestedIdentity][msg.sender];
//         SignedIdentity storage sid = signedId[_authority][_requestedIdentity][msg.sender];
//         if (vid.signed.request.flags.requested) {
//             // is a validated ID
//             vid.signed.request.flags.listed = true;
//             validIdList[_authority].push(vid);
//             selfIdList[msg.sender].push(vid.signed);
//             witnessIdList[signatureAddress(vid.signed.witness, _requestedIdentity)].push(vid.signed);

//             i[_requestedIdentity] = ValidatedIdentity(true, vid, _signature, 0, 0, 0);

//             IdClass idClass = vid.signed.request.requestClass;
//             IdType idType = vid.signed.request.requestType;

//             emit ListedIdentityAlert(msg.sender, _requestedIdentity, _authority, idClass, idType);

//         } else if (sid.request.flags.requested) {
//             // is a signed ID
//             sid.request.flags.listed = true;
//             selfIdList[msg.sender].push(sid);
//             witnessIdList[signatureAddress(sid.witness, _requestedIdentity)].push(vid.signed);

//         }
//     }

//     function lookupRecord(address _authority, string memory _requestedIdentity, address _registrant) public view onlyRegistrar returns (ValidatedIdentity memory) {
//         ValidatedIdentity storage vid = validId[_authority][_requestedIdentity][_registrant];
//         if (vid.signed.request.flags.requested) return vid;
//         ValidatedIdentity memory record;
//         return record; // for a 0 value? ... ValidatedIdentity(SignedIdentity(IdentityRequest(IdClass(0), IdType(0), IdFlags(0,0,0,0,0,0,0,0),Signature(bytes32(0),bytes32(0),0)),Signature(bytes32(0),bytes32(0),0)));
//     }
// }


// // How an Identity Directory registration occurs

// // User claims an identity and sends a request to a registrar (a registrar can guide a user through the process)

// // The identity gets saved to the requestedIdentity mapping under registrar/user/identity

// // Registrar gets notified and either approves or rejects the identity. 

// // The identity gets saved to the signedIdentity mapping under registrar/user/identity

// // The user can choose to list the identity, it gets pushed to their personal listedIdentities list as well as the registrar's signedIdentities list

// // The user can request public listing to an authorized registrar where it gets pushed to the public authorizedIdentities list and becomes resolvable

// // An Authorized Registrar can add a listed identity to the public identity directory and an authorized registrar can remove one
// // if an identity gets removed it gets marked in the Registrar's stats as a removal. Registrars will have a rating calculated
// // based on how many successful registrations the registrar had vs how many removals. Only prestine registrars will be able to add 
// // other registrars and if any of the added registrars get removed this also impacts rating.  


//     // struct Record {
//     //     bool[] booleanValue;
//     //     uint256[] unsignedIntegerValue;
//     //     int256[] signedIntegerValue;
//     //     address[] ethereumAddress;
//     //     string[] stringValue;
//     //     bytes32[] bytes32Value;
//     //     bytes[] dynamicBytesValue;
//     // }


// // {
// //   "A": {
// //     "ipv4": "string (IPv4 address)"
// //   },
// //   "AAAA": {
// //     "ipv6": "string (IPv6 address)"
// //   },
// //   "CNAME": {
// //     "canonicalName": "string (domain name)"
// //   },
// //   "MX": {
// //     "priority": "uint16",
// //     "mailServer": "string (domain name)"
// //   },
// //   "TXT": {
// //     "text": "string"
// //   },
// //   "NS": {
// //     "nameServer": "string (domain name)"
// //   },
// //   "PTR": {
// //     "domainName": "string (domain name)"
// //   },
// //   "SRV": {
// //     "service": "string",
// //     "protocol": "string",
// //     "priority": "uint16",
// //     "weight": "uint16",
// //     "port": "uint16",
// //     "target": "string (domain name)"
// //   },
// //   "SOA": {
// //     "primaryNS": "string (domain name)",
// //     "contactEmail": "string (email address)",
// //     "serialNumber": "uint32",
// //     "refresh": "uint32",
// //     "retry": "uint32",
// //     "expire": "uint32",
// //     "minimumTTL": "uint32"
// //   }
// // }


//     // // Function to add a TLD to the list
//     // function addTLD(string memory _tld) public onlyRegistrar {
//     //     validTLD[_tld] = true;
//     // }

//     // // Function to remove a TLD from the list
//     // function removeTLD(string memory _tld) public onlyRegistrar {
//     //     delete validTLD[_tld];
//     // }

//     // function addAuthorizedRegistrar(address newAuthorizedRegisrar) public onlyRegistrar() {
//     //     require(
//     //         !authorizedRegistrars[newAuthorizedRegisrar], 
//     //         "Address is already an authorized Registrar."
//     //     );
//     //     if (authorizedRegistrarCount < 50) {
//     //         require(projectFounder[msg.sender], "Project founder signature required to add new registrar.");
//     //         authorizedRegistrars[newAuthorizedRegisrar] = true;
//     //     } else {
//     //         //governance
//     //         authorizedRegistrars[newAuthorizedRegisrar] = true;
//     //     }
//     //     authorizedRegistrarCount ++;
//     // }