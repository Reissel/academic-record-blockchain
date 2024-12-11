// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

contract AcademicRegistry {
   // ** Events **
    event InstitutionAdded(address indexed institutionAddress, string name);
    event CourseAdded(address indexed institutionAddress, string courseCode);
    event DisciplineAdded(string courseCode, string disciplineCode);
    event ProfessorAdded(address indexed institutionAddress, address professorAddress, string name);
    event StudentAdded(address indexed studentAddress, string name);
    event GradeAdded(address indexed studentAddress, string disciplineCode, uint8 period);

    // ** Owner **
    address private contractOwner;

    // ** Structures **
    struct Institution {
        address idInstitutionAccount;
        string name;
        string document;
    }

    struct Course {
        string code;
        string name;
        string courseType;
        int numberOfSemesters;
    }

    struct Discipline {
        string code;
        string name;
        string ementa;
        int workload;
        int creditCount;
    }

    struct Professor {
        address idProfessorAccount;
        string name;
        string document;
    }

    struct Student {
        address idStudentAccount;
        string name;
        string document;
    }

    struct Grade {
        string disciplineCode;
        uint8 period;
        uint8 media;
        uint8 attendance;
        bool status; // true = approved, false = failed
    }

    // ** State Variables **
    mapping(address => Institution) private institutions;
    mapping(address => Course[]) private courses;

    // Maps the Institution address to the professors it has registered
    mapping(address => Professor[]) private professors;

    mapping(address => Student) private students;
    mapping(address => Grade[]) private grades;
    
    // Mapping to store the relationship between disciplines and courses
    mapping(bytes32 => mapping(bytes32 => bool)) private disciplineExistsInCourse; // [courseHash][disciplineHash]
    mapping(bytes32 => Discipline[]) private disciplinesByCourse; // [courseHash] => disciplines

    mapping(address => mapping(address => bool)) private isProfessorInInstitution;

    // Mapping to store the relationship between students and disciplines
    mapping(address => mapping(bytes32 => bool)) private enrollments;

    address[] private institutionAddressList;

    // ** Modifiers **
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can perform this action!");
        _;
    }

    modifier onlyInstitution(address institutionAddress) {
        require(
            msg.sender == institutionAddress,
            "Only the institution can perform this action!"
        );
        _;
    }

    modifier institutionExists(address institutionAddress) {
        require(
            institutions[institutionAddress].idInstitutionAccount != address(0),
            "Institution is not registered!"
        );
        _;
    }

    modifier courseExists(address institutionAddress, string memory courseCode) {
        bool exists = false;
        Course[] storage institutionCourses = courses[institutionAddress];
        for (uint256 i = 0; i < institutionCourses.length; i++) {
            if (
                keccak256(abi.encodePacked(institutionCourses[i].code)) ==
                keccak256(abi.encodePacked(courseCode))
            ) {
                exists = true;
                break;
            }
        }
        require(exists, "Course not found!");
        _;
    }

    // ** Constructor **
    constructor() {
        contractOwner = msg.sender;
    }

    // ** Institution Functions **
    function addInstitution(
        address institutionAddress,
        string calldata name,
        string calldata document
    ) public onlyOwner {
        require(
            institutions[institutionAddress].idInstitutionAccount == address(0),
            "Institution already registered!"
        );

        institutions[institutionAddress] = Institution(institutionAddress, name, document);
        institutionAddressList.push(institutionAddress);

        emit InstitutionAdded(institutionAddress, name);
    }

    function getInstitution(address institutionAddress)
        public
        view
        returns (Institution memory)
    {
        return institutions[institutionAddress];
    }

    function getInstitutionList()
        public
        view
        returns (address[] memory)
    {
        return institutionAddressList;
    }

    // ** Course Functions **
    function addCourse(
        address institutionAddress,
        string calldata code,
        string calldata name,
        string calldata courseType,
        int numberOfSemesters
    ) public institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        // Checks if the course is already registered in the institution
        Course[] storage institutionCourses = courses[institutionAddress];
        for (uint256 i = 0; i < institutionCourses.length; i++) {
            require(
                keccak256(abi.encodePacked(institutionCourses[i].code)) !=
                    keccak256(abi.encodePacked(code)),
                "Course already registered!"
            );
        }

        courses[institutionAddress].push(
            Course(code, name, courseType, numberOfSemesters)
        );

        emit CourseAdded(institutionAddress, code);
    }

    function getCoursesFromInstitution(address institutionAddress)
        public
        view
        returns (Course[] memory)
    {
        return courses[institutionAddress];
    }

    // ** Discipline Functions **
    function addDisciplineToCourse(
        address institutionAddress,
        string calldata courseCode,
        string calldata disciplineCode,
        string calldata name,
        string calldata ementa,
        int workload,
        int creditCount
    ) public courseExists(institutionAddress, courseCode) onlyInstitution(institutionAddress) {
        _addDisciplineToCourse(courseCode, disciplineCode, name, ementa, workload, creditCount);
    }

    function _addDisciplineToCourse(
        string calldata courseCode,
        string calldata disciplineCode,
        string calldata name,
        string calldata ementa,
        int workload,
        int creditCount
    ) internal {
        // Hash the course code and discipline code for consistent mapping
        bytes32 courseHash = keccak256(abi.encodePacked(courseCode));
        bytes32 disciplineHash = keccak256(abi.encodePacked(disciplineCode));

        // Check if discipline already exists in the course
        require(
            !disciplineExistsInCourse[courseHash][disciplineHash],
            "Discipline already registered in this course!"
        );

        // Add the discipline to the course
        disciplinesByCourse[courseHash].push(
            Discipline(disciplineCode, name, ementa, workload, creditCount)
        );

        // Mark discipline as registered in the course
        disciplineExistsInCourse[courseHash][disciplineHash] = true;

        emit DisciplineAdded(courseCode, disciplineCode);
    }

    function getDisciplinesFromCourse(string calldata courseCode)
        public
        view
        returns (Discipline[] memory)
    {
        bytes32 courseHash = keccak256(abi.encodePacked(courseCode));
        return disciplinesByCourse[courseHash];
    }

    // ** Professor Functions **
    function addProfessorToInstitution(
        address institutionAddress,
        address professorAddress,
        string calldata name,
        string calldata document
    ) public institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        // Check if professor is already registered
        require(
            !isProfessorInInstitution[institutionAddress][professorAddress],
            "Professor already registered in this institution!"
        );

        professors[institutionAddress].push(Professor(professorAddress, name, document));
        isProfessorInInstitution[institutionAddress][professorAddress] = true;

        emit ProfessorAdded(institutionAddress, professorAddress, name);
    }

    function getProfessorsFromInstitution(address institutionAddress)
        public
        view
        returns (Professor[] memory)
    {
        return professors[institutionAddress];
    }

    // ** Student Functions **
    function addStudent(
        address institutionAddress,
        address studentAddress,
        string calldata name,
        string calldata document
    ) public institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        // Check if student is already registered
        require(
            students[studentAddress].idStudentAccount == address(0),
            "Student already registered!"
        );

        students[studentAddress] = Student(studentAddress, name, document);

        emit StudentAdded(studentAddress, name);
    }

    function getStudent(address studentAddress)
        public
        view
        returns (Student memory)
    {
        return students[studentAddress];
    }

    function enrollStudentInDiscipline(
        address institutionAddress,
        address studentAddress,
        string calldata disciplineCode,
        string calldata courseCode
    ) public institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        bytes32 courseHash = keccak256(abi.encodePacked(courseCode));
        bytes32 disciplineHash = keccak256(abi.encodePacked(disciplineCode));

        // Check if student is registered
        require(
            students[studentAddress].idStudentAccount != address(0),
            "Student not registered!"
        );

        // Check if discipline exists in the course
        require(
            disciplineExistsInCourse[courseHash][disciplineHash],
            "Discipline not found in the course!"
        );

        // Enroll the student
        enrollments[studentAddress][disciplineHash] = true;
    }

    // ** Grade Functions **
    function addGrade(
        address institutionAddress,
        address studentAddress,
        string calldata disciplineCode,
        uint8 period,
        uint8 media,
        uint8 attendance,
        bool status
    ) public institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        bytes32 disciplineHash = keccak256(abi.encodePacked(disciplineCode));

        // Check if student is registered
        require(
            students[studentAddress].idStudentAccount != address(0),
            "Student not registered!"
        );

        // Check if student is enrolled in the discipline
        require(
            enrollments[studentAddress][disciplineHash],
            "Student not enrolled in the discipline!"
        );

        // Check if grade for this period and discipline already exists
        Grade[] storage studentGrades = grades[studentAddress];
        for (uint256 i = 0; i < studentGrades.length; i++) {
            require(
                !(
                    keccak256(abi.encodePacked(studentGrades[i].disciplineCode)) ==
                        keccak256(abi.encodePacked(disciplineCode)) &&
                    studentGrades[i].period == period
                ),
                "Grade already recorded for this discipline and period!"
            );
        }

        // Add grade
        grades[studentAddress].push(
            Grade(disciplineCode, period, media, attendance, status)
        );

        emit GradeAdded(studentAddress, disciplineCode, period);
    }

    function getGrades(address studentAddress)
        public
        view
        returns (Grade[] memory)
    {
        return grades[studentAddress];
    }
}
