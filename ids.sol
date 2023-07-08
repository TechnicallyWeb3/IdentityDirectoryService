// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

contract IdentityDirectory {
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct IdentityRequest {
        Signature registrant;
    }

    struct SignedIdentity {
        Signature registrant;
        Signature registrar;
    }

    struct ListedIdentity {
        string name;
        SignedIdentity identity;
    }

    // struct Record {
    //     bool[] booleanValue;
    //     uint256[] unsignedIntegerValue;
    //     int256[] signedIntegerValue;
    //     address[] ethereumAddress;
    //     string[] stringValue;
    //     bytes32[] bytes32Value;
    //     bytes[] dynamicBytesValue;
    // }

    // Identity Directory Records Self-Listed
    mapping(address => ListedIdentity[]) public listedIdentities; // gets pushed to when a user requests a public record. This allows for reverse lookups
    mapping(address => ListedIdentity) public defaultIdentity; // gets a default Identity profile for a given address. Public for reverse lookup.

    // Public Identity Directory
    mapping(string => SignedIdentity) public authorizedIdentity; // gets an identity using the FQID from the public record. ie com.tiktok.user.7157726993374938117

    //Checks for prior requests, signing or public listings
    mapping(address => mapping(string => bool)) public isRequested; // returns true or false if the request has been signed by the specified registrar.
    mapping(address => mapping(string => bool)) public isSigned; // returns true or false if the request has been signed by the specified registrar.
    mapping(string => bool) public isListed; // returns true or false if the identity is publicly listed.

    // Write Request Mappings
    mapping(address => mapping(address => mapping(string => IdentityRequest)))
        private requestedIdentity;
    mapping(address => mapping(address => mapping(string => SignedIdentity)))
        private signedIdentity;
    mapping(address => mapping(address => mapping(string => ListedIdentity)))
        public listedIdentity; //Authorized registrars only

    // Registrar list for public publishing
    mapping(address => bool) public projectFounder;
    mapping(address => bool) public authorizedRegistrars;
    uint256 public authorizedRegistrarCount;

    // Registrant stats
    mapping(address => uint256) public requestCount; // total count of requests sent
    mapping(address => uint256) public uniqueRequestCount; // unique requests sent
    mapping(address => uint256) public signedRequestCount; // total count of signed requests
    mapping(address => uint256) public rejectedRequestCount; // total count of rejected requests
    mapping(address => mapping(string => bool)) public hasRequested; // if the user has requested prior (used for unique calculations)
    // by registrar
    mapping(address => mapping(address => uint256))
        public registrarRequestCount; // total count of requests sent to a particular registrar
    mapping(address => mapping(address => uint256))
        public registrarSignedRequestCount; // count of signed request per registrar

    // Registrar stats
    mapping(address => ListedIdentity[]) public signedIdentityList; // a list of identities signed by the registrar which are either self or publicly listed
    mapping(address => uint256) public signedIdentityCount; // a count of total identities signed
    mapping(address => uint256) public rejectedIdentityCount; // a count of total identities signed
    mapping(address => uint256) public listedIdentityCount; // a count of identities signed by this regisrtat which have been publicly listed
    mapping(address => uint256) public removedIdentityCount; // a count of signed identities forcably removed from the smart contract by the authorized registrars

    //Identity Directory public records related to an entry allows users to create records linked to their identities similar to DNS
    // mapping(Identity => address[]) public addressRecords;
    // mapping(Identity => string[]) public aliasRecords;
    // mapping(Identity => bytes4[]) public ipv4Records;
    // mapping(Identity => bytes16[]) public ipv6Records;
    // mapping(Identity => Record[]) public customRecords;// use a custom variable? Record customRecord

    // check valid TLD before registration
    mapping(string => bool) public validTLDs;

    modifier onlyAuthorizedRegistrar() {
        require(authorizedRegistrars[msg.sender], "Only authorized registrars can perform this operation.");
        _;
    }

    //Alerts
    event RequestIdentityAlert(
        address indexed registrar,
        address registrant,
        string requestedIdentity
    );
    event SignedIdentityAlert(
        address indexed registrar,
        address registrant,
        string requestedIdentity
    );

    // contract deployment
    constructor() {
        // Initialize the authorized registrar addresses
        projectFounder[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
        projectFounder[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
        projectFounder[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
        projectFounder[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105

        authorizedRegistrars[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
        authorizedRegistrars[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
        authorizedRegistrars[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
        authorizedRegistrars[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105
    }

    // // Function to add a TLD to the list
    // function addTLD(string memory _tld) public onlyAuthorizedRegistrar {
    //     validTLDs[_tld] = true;
    // }

    // // Function to remove a TLD from the list
    // function removeTLD(string memory _tld) public onlyAuthorizedRegistrar {
    //     delete validTLDs[_tld];
    // }

    // function addAuthorizedRegistrar(address newAuthorizedRegisrar) public onlyAuthorizedRegistrar() {
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


    // user claims identity, requests signature from registrar.
    function requestIdentity(
        address _registrar,
        string memory _requestedIdentity,
        Signature memory _signature
    ) public {
        require(
            !isListed[_requestedIdentity],
            "Identity already publicly registered."
        );
        require(
            !isSigned[_registrar][_requestedIdentity],
            "Identity already signed by this registrar."
        );
        require(
            !isRequested[_registrar][_requestedIdentity],
            "Identity already requested through registrar, feel free to try to use the notifyRegistrar function to emit another alert."
        );
        require(
            signatureMatches(_signature, msg.sender, _requestedIdentity),
            "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
        );
        require(
            msg.sender != _registrar,
            "Registrar cannot sign their own request"
        );

        requestedIdentity[_registrar][msg.sender][
            _requestedIdentity
        ] = IdentityRequest(_signature);
        emit RequestIdentityAlert(_registrar, msg.sender, _requestedIdentity);
    }

    function signIdentity(
        string memory _requestedIdentity,
        address _registrant,
        address _registrar,
        Signature memory _signature
    ) public {
        require(
            msg.sender == _registrar, 
            "Registrar signature required."
        );
        require(
            !isListed[_requestedIdentity], 
            "Identity already registered."
        );
        require(
            !isSigned[_registrar][_requestedIdentity],
            "Identity already signed."
        );
        require(
            signatureMatches(_signature, msg.sender, _requestedIdentity),
            "Invalid signature. you did not sign string _requestedIdentity with Signature(v,r,s) _signature"
        );


        // Retrieve the identity request
        Signature storage registrantSignature = requestedIdentity[_registrar][
            _registrant
        ][_requestedIdentity].registrant;

        require(
            registrantSignature.r != bytes32(0),
            "This record has not been requested, have the registrant request this identity first."
        );

        signedIdentity[_registrar][_registrant][
            _requestedIdentity
        ] = SignedIdentity(registrantSignature, _signature);
        emit SignedIdentityAlert(_registrar, _registrant, _requestedIdentity);
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
