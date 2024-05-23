// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";


contract MyJourney20 is ERC721URIStorage, AccessControl, FunctionsClient {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using FunctionsRequest for FunctionsRequest.Request;

    uint256 public s_tokenIdCounter;

    enum EducationStage { 
        Fundamental, 
        HighSchool, 
        University 
    }

    struct Student {
        uint256 id;
        address studentAddress;
        string name;
        uint256 dateOfBirth;
    }

    mapping(address => Student) public s_students;
    mapping(address => EducationStage) public s_studentEducationStage;
    mapping(EducationStage => string) public s_stageNFTLinks;
    mapping(address => bool) public s_financialInstitutions;
    mapping(address => bool) public s_administrators;

    event NFTIssued(address indexed student, EducationStage stage);


    // Function parameters
    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Hardcoded for Fuji
    address public immutable i_router_add = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;
    bytes32 public constant DON_ID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;

    // Callback gas limit
    uint32 public constant GAS_LIMIT = 300000;

    // Your subscription ID.
    uint64 public s_subscriptionId;

    // JavaScript source code
    string public s_source = "";


    constructor() ERC721("MyJourneyNFT", "MJNFT") FunctionsClient(i_router_add) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Initializing stage NFT links
        s_stageNFTLinks[EducationStage.Fundamental] = "https://example.com/fundamental-nft";
        s_stageNFTLinks[EducationStage.HighSchool] = "https://example.com/highschool-nft";
        s_stageNFTLinks[EducationStage.University] = "https://example.com/university-nft";

        // Adding the contract deployer as an administrator
        s_administrators[msg.sender] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, AccessControl) returns (bool) {
        return ERC721URIStorage.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || FunctionsClient.supportsInterface(interfaceId);
    }

    modifier onlyFinancialInstitution() {
        require(s_financialInstitutions[msg.sender], "Caller is not an authorized financial institution");
        _;
    }

    modifier onlyAdministrator() {
        require(s_administrators[msg.sender], "Caller is not an administrator");
        _;
    }

    function addStudent(address _studentAddress, uint256 _id, string memory _name, uint256 _dateOfBirth) external onlyFinancialInstitution {
        s_students[_studentAddress] = Student(_id, _studentAddress, _name, _dateOfBirth);
    }

    function issueNFT(address _studentAddress) external onlyFinancialInstitution {
        require(s_students[_studentAddress].studentAddress != address(0), "Student does not exist");

        EducationStage currentStage = s_studentEducationStage[_studentAddress];
        
        if (balanceOf(_studentAddress) == 0) {
            currentStage = EducationStage.Fundamental;
        } else {
            require(currentStage != EducationStage.University, "Student has completed all stages");
        }

        uint256 tokenId = s_tokenIdCounter.current();
        s_tokenIdCounter.increment();
        
        _safeMint(_studentAddress, tokenId);
        _setTokenURI(tokenId, s_stageNFTLinks[currentStage]);

        // Update the student's stage
        if (currentStage == EducationStage.Fundamental) {
            s_studentEducationStage[_studentAddress] = EducationStage.HighSchool;
        } else if (currentStage == EducationStage.HighSchool) {
            s_studentEducationStage[_studentAddress] = EducationStage.University;
        }

        emit NFTIssued(_studentAddress, currentStage);
        
        // TODO: Send to back-end
        // sendReponse( studentAddress, tokenId);
    }

    function issueNFTForStage(address _studentAddress, EducationStage _stage) external onlyFinancialInstitution {
        require(s_students[_studentAddress].studentAddress != address(0), "Student does not exist");
        require(_stage >= EducationStage.Fundamental && _stage <= EducationStage.University, "Invalid education stage");

        // Ensure the student doesn't already have an NFT for the given stage or a higher stage
        require(s_studentEducationStage[_studentAddress] < _stage, "Student already has an NFT for this stage or higher");

        uint256 tokenId = s_tokenIdCounter.current();
        s_tokenIdCounter.increment();

        _safeMint(_studentAddress, tokenId);
        _setTokenURI(tokenId, s_stageNFTLinks[_stage]);

        // Update the student's stage
        s_studentEducationStage[_studentAddress] = _stage;

        emit NFTIssued(_studentAddress, _stage);

        // TODO: Send to back-end
        // sendReponse( studentAddress, tokenId);
    }

    function addAdministrator(address _adminAddress) external onlyAdministrator {
        s_administrators[_adminAddress] = true;
    }

    function removeAdministrator(address _adminAddress) external onlyAdministrator {
        s_administrators[_adminAddress] = false;
    }

    function addFinancialInstitution(address _institutionAddress) external onlyAdministrator {
        s_financialInstitutions[_institutionAddress] = true;
    }

    function removeFinancialInstitution(address _institutionAddress) external onlyAdministrator {
        s_financialInstitutions[_institutionAddress] = false;
    }
    
    function setNFTMetadataURI(uint256 _tokenId, string memory _tokenURI) external onlyFinancialInstitution {
        require(_exists(_tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _setTokenURI(_tokenId, _tokenURI);
    }

    function getStudentByAddress(address _studentAddress) internal view returns (Student memory) {
        require(s_students[_studentAddress].studentAddress != address(0), "Student does not exist");
        return s_students[_studentAddress];
    }

    function sendReponse(address _studentAddress, uint256 _tokenId) internal {
        string[] memory args = new string[](1);

        Student memory student = getStudentByAddress(_studentAddress);

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_source); // Initialize the request with JS code
        req.setArgs(_tokenId);
        req.setArgs(student.id);

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, GAS_LIMIT, DON_ID);
    }

        // Receive the weather in the city requested
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        require(requests[requestId].exists, "request not found");

        s_lastError = err;
        s_lastResponse = response;
        timestamp = block.timestamp;

        // Emit an event to log the response
        // emit Response(requestId, lastTemperature, lastResponse, lastError);
    }
}