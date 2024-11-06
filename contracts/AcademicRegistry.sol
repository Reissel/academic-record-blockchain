// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

contract AcademicRegistry {

    event AddedInstitution();
    event AddedCourse();

    address private contractOwner;

    mapping(address => Institution) private institutions;

    address[] private institutionList;

    function getInstitutionList() public view returns(address[] memory) {
        return institutionList;
    }

    function getInstitution(address institution_address) public view returns(Institution memory){
        return institutions[institution_address];
    }
    
    struct Institution {
        address id_institution_account;
        string name;
        string document;
    }

    mapping(address => Course[]) private courses;

    Course[] private courseList;

    struct Course {
        string name;
        string course_type;
        address institution_address;
    }

    function getCoursesFromInstitution(address institution_address) public view returns(Course[] memory){
        return courses[institution_address];
    }

    struct Discipline {
        string code;
        string name;
        string ementa;
        int workload;
        int credit_count;
        int year;
        int semester;
    }

    struct Professor {
        address id_professor_account;
        string name;
        string document;
    }

    struct Student {
        address id_student_account;
        string name;
        string document;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function addInstitution(address institution_address, string calldata institution_name, string calldata institution_document) public {
        
        require(
            contractOwner == msg.sender,
            "Only the contract owner can add a new Institution!"
        );

        // Checks if the new institution is registered.
        for (uint256 i = 0; i < institutionList.length; i++) {
            require(
                institution_address != institutions[institutionList[i]].id_institution_account,
                "Institution is already registered!"
            );
        }

        institutionList.push(institution_address);

        institutions[institution_address].id_institution_account = institution_address;
        institutions[institution_address].name = institution_name;
        institutions[institution_address].document = institution_document;

        emit AddedInstitution();
    }

    function addCourse(address institution_address, string calldata course_name, string calldata course_type) public {

        require(
            contractOwner == msg.sender || msg.sender == institution_address,
            "Only the contract owner or the Institution can add a new Course!"
        );

        courseList.push(Course(course_name, course_type, institution_address));

        courses[institution_address].push(Course(course_name, course_type, institution_address));

    }
}