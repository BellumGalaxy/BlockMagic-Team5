// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract MyJourney is ERC721URIStorage, AccessControl {    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // using FunctionsRequest for FunctionsRequest.Request;

    uint256 public tokenIdCounter;

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

    mapping(address => Student) public students;
    mapping(address => EducationStage) public studentEducationStage;
    mapping(EducationStage => string) public stageNFTLinks;

    event NFTIssued(address indexed student, EducationStage stage);

    constructor() ERC721("MyJourneyNFT", "MJNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        stageNFTLinks[EducationStage.Fundamental] = "https://example.com/fundamental-nft";
        stageNFTLinks[EducationStage.HighSchool] = "https://example.com/highschool-nft";
        stageNFTLinks[EducationStage.University] = "https://example.com/university-nft";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function addStudent(address _studentAddress, uint256 id, string memory _name, uint256 _dateOfBirth) external onlyRole(MINTER_ROLE) {
        students[_studentAddress] = Student(id,_studentAddress, _name, _dateOfBirth);
    }

    function issueNFT(address _studentAddress) external onlyRole(MINTER_ROLE) {
        require(students[_studentAddress].studentAddress != address(0), "Student does not exist");

        EducationStage currentStage = studentEducationStage[_studentAddress];
        
        if (balanceOf(_studentAddress) == 0) {
            currentStage = EducationStage.Fundamental;
        } else {
            require(currentStage != EducationStage.University, "Student has completed all stages");
        }

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        
        _safeMint(_studentAddress, tokenId);
        _setTokenURI(tokenId, stageNFTLinks[currentStage]);

        // Update the student's stage
        if (currentStage == EducationStage.Fundamental) {
            studentEducationStage[_studentAddress] = EducationStage.HighSchool;
        } else if (currentStage == EducationStage.HighSchool) {
            studentEducationStage[_studentAddress] = EducationStage.University;
        }

        emit NFTIssued(_studentAddress, currentStage);
    }

    function issueNFTForStage(address _studentAddress, EducationStage _stage) external onlyRole(MINTER_ROLE) {
        require(students[_studentAddress].studentAddress != address(0), "Student does not exist");
        require(_stage >= EducationStage.Fundamental && _stage <= EducationStage.University, "Invalid education stage");

        // Ensure the student doesn't already have an NFT for the given stage or a higher stage
        require(studentEducationStage[_studentAddress] < _stage, "Student already has an NFT for this stage or higher");

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        _safeMint(_studentAddress, tokenId);
        _setTokenURI(tokenId, stageNFTLinks[_stage]);

        // Update the student's stage
        studentEducationStage[_studentAddress] = _stage;

        emit NFTIssued(_studentAddress, _stage);
    }
}
