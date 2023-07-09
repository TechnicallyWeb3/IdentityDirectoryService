// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

contract IdentityDirectory {

    constructor() {
        // Initialize the authorized registrar addresses
        isFounder[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
        isFounder[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
        isFounder[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
        isFounder[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105

        isRegistrar[0x7b9a421575f72D17331CA7433aeA46eC5d5B2739] = true; //@mancinotech
        isRegistrar[0x80484108D571f4Ee96521710F5D027E9d2F59AdF] = true; //@furt_tech
        isRegistrar[0xE7D3039dFDa68Ffa9Bc56e731CF9e8f85904703d] = true; //@theafrocoder
        isRegistrar[0xe0B02A2652Caa79041f2798Fa615ec39bfBbBfA8] = true; //@devilking6105

        registrarCount = 4;
    }

    // User Types: Project Founders(super admins), Registrars(admin group), Witnesses, Registrant

    // Registrar list for public listing rights
    mapping(address => bool) internal isFounder;
    mapping(address => bool) public isRegistrar;
    uint256 internal registrarCount;

    modifier onlyFounder() {
        require(isFounder[msg.sender], "Only Project Founders can perform this operation.");
        _;
    }

    modifier onlyRegistrar() {
        require(isRegistrar[msg.sender], "Only authorized registrars can perform this operation.");
        _;
    }

    struct IdType {
        bool dns; // domain names
        bool email; // email addresses
        bool web1; // any other web1 address
        bool social; // public profiles, can include any service offering login APIs
        bool service; // additional identity service including KYC
        bool web2; // any other form of web2 identity
        bool web3; // web3 addresses that don't follow a 160 bit (0xabc123) format ie xrp.rU6K7V3Po4snVhBBaU29sesqs2qTQJWDw1
        bool hashed; // a hashed id for an extra layer of privacy
    }

    // encoding/decoding functions for representing Type as a uint8 value
    function encodeIdType(IdType memory idType) internal pure returns (uint8) {
        uint8 encoded;
        if (idType.dns) encoded |= 0x01;
        if (idType.email) encoded |= 0x02;
        if (idType.web1) encoded |= 0x04;
        if (idType.social) encoded |= 0x08;
        if (idType.service) encoded |= 0x10;
        if (idType.web2) encoded |= 0x20;
        if (idType.web3) encoded |= 0x40;
        if (idType.hashed) encoded |= 0x80;
        return encoded;
    }

    function decodeIdType(uint8 encoded) internal pure returns (IdType memory) {
        return IdType(
            (encoded & 0x01) != 0,
            (encoded & 0x02) != 0,
            (encoded & 0x04) != 0,
            (encoded & 0x08) != 0,
            (encoded & 0x10) != 0,
            (encoded & 0x20) != 0,
            (encoded & 0x40) != 0,
            (encoded & 0x80) != 0
        );
    }

    struct IdStatus {
        bool claimed; // once a request is made this bit will go true and will inicate someone has claimed this record
        bool signed; // if approved by witness will be true
        bool validated; // if approved by registrar will be true
        bool rejected; // if registrar or witness rejects the request this bit will be true
        bool listed; // if the ID is public or if the user pushes their ID public this will be true
        bool frozen; // ID can be frozen by any registrar who offers a conflicting record.
        bool reserved; // web3 addresses that don't follow a 160 bit (0xabc123) format ie xrp.rU6K7V3Po4snVhBBaU29sesqs2qTQJWDw1
        bool futureUse; // a hashed id for an extra layer of privacy
    }

    function encodeIdStatus(IdStatus memory idStatus) internal pure returns (uint8) {
        uint8 encoded;
        if (idStatus.claimed) encoded |= 0x01;
        if (idStatus.signed) encoded |= 0x02;
        if (idStatus.validated) encoded |= 0x04;
        if (idStatus.rejected) encoded |= 0x08;
        if (idStatus.listed) encoded |= 0x10;
        if (idStatus.frozen) encoded |= 0x20;
        if (idStatus.reserved) encoded |= 0x40;
        if (idStatus.futureUse) encoded |= 0x80;
        return encoded;
    }

    function decodeIdStatus(uint8 encoded) internal pure returns (IdStatus memory) {
        return IdStatus(
            (encoded & 0x01) != 0,
            (encoded & 0x02) != 0,
            (encoded & 0x04) != 0,
            (encoded & 0x08) != 0,
            (encoded & 0x10) != 0,
            (encoded & 0x20) != 0,
            (encoded & 0x40) != 0,
            (encoded & 0x80) != 0
        );
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    function signatureAddress(
        Signature memory _signature,
        string memory _message
    ) internal pure returns (address) {
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
    ) internal pure returns (bool) {
        address recoveredAddress = signatureAddress(_signature, _message);
        return (recoveredAddress != address(0) && recoveredAddress == _signer);
    }
    function parseSignature(string memory signature) internal pure returns (Signature memory) {
        require(bytes(signature).length == 132, "Invalid signature length");

        bytes32 r = bytesToBytes32(bytes(signature), 0);
        bytes32 s = bytesToBytes32(bytes(signature), 32);
        uint8 v = uint8(bytes(signature)[64]);

        return Signature(r, s, v);
    }

    function bytesToBytes32(bytes memory b, uint256 offset) internal pure returns (bytes32 result) {
        require(b.length >= offset + 32, "Invalid bytes length");

        assembly {
            result := mload(add(b, add(32, offset)))
        }
    }


    struct SigType {
        bool witness;
        bool registrar;  
        bool authority;
        bool kyc;
    }

    struct ClaimedId {
        IdType idType;
        IdStatus idStatus;
        Signature registrant;
    }
    mapping(address => mapping(string => mapping (address => ClaimedId))) public claimedRecord; // Claimed ID record can be found at witness => idName => registrant  

    struct IdReceipt {
        ClaimedId claimedId;
        SigType sigType;
        Signature signer;
    }
    mapping(address => mapping(string => IdReceipt)) public signerReceipt; // Signer could be a witness or registrar record exists at signer => idName
    mapping(address => mapping(string => IdReceipt[])) idSignatures; // A list of all IdReceipts pushed to a registrant's identity record found at registrant => idName []

    struct IdRecord {
        IdReceipt signedId;
        uint totalSigCount;
        uint witnessSigCount;
        uint registrarSigCount;
        uint authoritySigCount;
        uint kycSigCount;
    }
    mapping(address => mapping(string => IdRecord)) public signedRecord; // The base record on which to collect additional signatures record exists at registrant => idName
    mapping(string => IdRecord) public i; // the public record

    event ClaimedIdAlert(
        string indexed signedId,
        ClaimedId request
    );
    function claimIdentity(
        address _witness,
        string memory _idName,
        Signature memory _signature
    ) public {
        require(
            msg.sender != _witness,
            "Witness cannot sign their own request"
        );
        require(
            !claimedRecord[_witness][_idName][msg.sender].idStatus.rejected,
            "The witness rejected the claim this identity belongs to you."
        );
        require(
            !claimedRecord[_witness][_idName][msg.sender].idStatus.claimed,
            "The witness already has this request, have them sign it to continue."
        );

        require(
            signatureMatches(_signature, msg.sender, _idName),
            "Invalid signature. you did not sign string _idName with Signature(v,r,s) _signature"
        );

        // Initialize request
        // ideally create a function which takes _idName and returns encoded IdType based on string rules, if invalid 0. require type!0 
        IdType memory claimType = IdType(true,false,false,false,false,false,false,false); // should be user defined/auto detected
        IdStatus memory claimStatus = IdStatus(true,false,false,false,true,false,false,false); // listed should be defined by user for private records
        ClaimedId memory claimRecord = ClaimedId(claimType, claimStatus, _signature);
        
        // Store request
        claimedRecord[_witness][_idName][msg.sender] = claimRecord; // storing the claim with the witness to sign or reject
        
        // emit alert
        emit ClaimedIdAlert(_idName, claimRecord);
    }

    function signIdentity(
        string memory _idName,
        address _registrant,
        Signature memory _signature
    ) public {

        ClaimedId memory request = claimedRecord[msg.sender][_idName][_registrant];
        require(
            request.idStatus.claimed,
            "The registrant must request you sign the claimed ID before you can sign it."
        );
        require(
            !request.idStatus.signed,
            "You have already signed this ID."
        );
        // signature checks
        require(
            signatureMatches(request.registrant, _registrant, _idName),
            "Signature, registrant signature invalid."
        );
        require(
            signatureMatches(_signature, msg.sender, _idName),
            "Invalid signature. you did not sign string _idName with Signature(v,r,s) _signature"
        );

        IdRecord memory record = signedRecord[_registrant][_idName];
        SigType memory sigType;

        // define signature type and incriment counters
        if (isRegistrar[msg.sender]) {
            record.registrarSigCount ++;
            sigType = SigType(false, true, false, false);
        } else {
            record.witnessSigCount ++;
            sigType = SigType(true, false, false, false);
        }

        record.totalSigCount ++;

        // Sign the receipt
        IdReceipt memory receipt = IdReceipt(request, sigType, _signature);
        
        // add claim request to signedRecord (if it doesn't already exist)
        if (!record.signedId.claimedId.idStatus.claimed) {
            receipt.claimedId = request;
        }

        // Store receipt with signer and registrant
        signerReceipt[msg.sender][_idName] = receipt;
        idSignatures[_registrant][_idName].push(receipt);

        if(record.signedId.claimedId.idStatus.listed && isRegistrar[msg.sender]) {
            i[_idName] = record;
        }
    }
}