// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

contract AcademicRegistry {

    event AddedInstitution();
    event AddedCourse();

    address private contractOwner;

    mapping(address => Institution) private institutions;

    address[] private institution_address_list;

    function getInstitution_address_list() public view returns(address[] memory) {
        return institution_address_list;
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

    string stringComparator;

    struct Course {
        string code;
        string name;
        string course_type;
        address institution_address;
        int number_of_semesters;
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
    }

    // course_code -> Lista de Disciplinas
    mapping(string => Discipline[]) private disciplines;

    Discipline[] private disciplineList;

    function getDisciplinesFromCourse(string calldata course_code) public view returns(Discipline[] memory){
        return disciplines[course_code];
    }

    struct Professor {
        address id_professor_account;
        string name;
        string document;
    }

    // Maps the Institution address to the professors it has registered
    mapping(address => Professor[]) private professors;

    Professor[] private professorList;

    function getProfessorsFromInstitution(address institution_address) public view returns(Professor[] memory){
        return professors[institution_address];
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
        for (uint256 i = 0; i < institution_address_list.length; i++) {
            require(
                institution_address != institutions[institution_address_list[i]].id_institution_account,
                "Institution is already registered!"
            );
        }

        institution_address_list.push(institution_address);

        institutions[institution_address].id_institution_account = institution_address;
        institutions[institution_address].name = institution_name;
        institutions[institution_address].document = institution_document;

        emit AddedInstitution();
    }

    function addCourse(address institution_address, string calldata course_code, string calldata course_name, string calldata course_type, int number_of_semesters) public {

        // Remove contractOwner from being able to add course (it's being allowed to make testing easier)
        require(
            contractOwner == msg.sender || msg.sender == institution_address,
            "Only the contract owner or the Institution can add a new Course!"
        );

        // #TODO: Adicionar validação se o curso já existe!

        courseList.push(Course (course_code, course_name, course_type, institution_address, number_of_semesters ));

        courses[institution_address].push(Course (course_code, course_name, course_type, institution_address, number_of_semesters ));

    }

    function compareStrings(string memory str1) public view returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(stringComparator));
    }

    function addDisciplineToCourse(string calldata course_code, string calldata discipline_code, string calldata discipline_name, string calldata ementa, int workload, int credit_count) public {
        
        address institution_address;

        for (uint256 i = 0; i < institution_address_list.length; i++) {
            if (msg.sender == institutions[institution_address_list[i]].id_institution_account) {
                institution_address = institutions[institution_address_list[i]].id_institution_account;
            }
        }

        require(
                contractOwner == msg.sender || msg.sender == institution_address,
                "Only the contract owner or the Institution can add a new Course!"
        );

        stringComparator = discipline_code;

        Discipline[] storage existent = disciplines[course_code];

        for (uint256 i = 0; i < existent.length; i++) {

            if(compareStrings(existent[i].code)) {
                stringComparator = "";
                require(
                    false,
                    "Course is already registered!"
                );
            }

        }

        // Resets the stringComparator
        stringComparator = "";

        disciplines[course_code].push(Discipline(discipline_code, discipline_name, ementa, workload, credit_count));

    }

    function addProfessorToInstitution(address id_professor_account, string calldata name, string calldata document) public {

        address institution_address;

        for (uint256 i = 0; i < institution_address_list.length; i++) {
            if (msg.sender == institutions[institution_address_list[i]].id_institution_account) {
                institution_address = institutions[institution_address_list[i]].id_institution_account;
            }
        }

        require(
                contractOwner == msg.sender || msg.sender == institution_address,
                "Only the contract owner or the Institution can add a new Professor!"
        );

        professors[msg.sender].push(Professor(id_professor_account, name, document));
        
    }
}