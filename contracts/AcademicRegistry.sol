// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

/// @title Academic registry smart contract.
/// @notice This contract manages records for institutions, courses, disciplines, students, and grades in an academic registry system.
contract AcademicRegistry {
    /// @dev Emitted when a new institution is added.
    /// @param institutionAddress The address of the institution being registered.
    /// @param name The name of the institution.
    event InstitutionAdded(address indexed institutionAddress, string name);

    /// @dev Emitted when a new course is added.
    /// @param institutionAddress The address of the institution adding the course.
    /// @param courseCode The code of the course being added.
    event CourseAdded(address indexed institutionAddress, string courseCode);

    /// @dev Emitted when a new discipline is added to a course.
    /// @param courseCode The code of the course to which the discipline is being added.
    /// @param disciplineCode The code of the discipline being added.
    event DisciplineAdded(string courseCode, string disciplineCode);

    /// @dev Emitted when a new student is added.
    /// @param studentAddress The address of the student being added.
    event StudentAdded(address indexed studentAddress);

    /// @dev Emitted when a new grade is added for a student.
    /// @param studentAddress The address of the student receiving the grade.
    /// @param disciplineCode The code of the discipline for which the grade is recorded.
    /// @param semester The semester in which the grade was recorded.
    event GradeAdded(address indexed studentAddress, string disciplineCode, uint16 year, uint8 semester);

    /// @dev Emitted when a new address is allowed by a student.
    /// @param studentAddress The address of the student allowing the address.
    /// @param allowedAddress The address being allowed by the student.
    event AllowedAddressAdded(address indexed studentAddress, address allowedAddress);

    /// @dev Emitted when the information of the student is added by it.
    /// @param studentAddress The address of the student adding the information.
    event StudentInformationAdded(address indexed studentAddress);

    /// @dev Contract ownership. Only the owner can perform certain actions.
    address immutable private contractOwner;

    /// @dev Represents an institution.
    struct Institution {
        address institutionAddress;
        string name;
        string document;
        string publicKey;
    }

    /// @dev Represents a course.
    struct Course {
        string code;
        string name;
        string courseType;
        int numberOfSemesters;
    }

    /// @dev Represents a discipline.
    struct Discipline {
        string code;
        string name;
        string syllabus;
        int workload;
        int creditCount;
    }

    /// @dev Represents a student.
    struct Student {
        address studentAddress;
        string selfEncryptedInformation;
        string institutionEncryptedInformation;
        string publicKey;
        string publicHash;
    }

    /// @dev Represents a student's grade.
    struct Grade {
        string disciplineCode;
        uint8 semester;
        uint16 year;
        uint8 grade;
        uint8 attendance;
        bool status; // true = approved, false = failed
    }

    // ** State Variables **
    mapping(address => Institution) private institutions;
    mapping(address => Course[]) private courses;

    mapping(address => Student) private students;
    mapping(address => Grade[]) private grades;
    
    // Mapping to store the relationship between disciplines and courses
    mapping(bytes32 => mapping(bytes32 => bool)) private disciplineExistsInCourse; // [courseHash][disciplineHash]
    mapping(bytes32 => Discipline[]) private disciplinesByCourse; // [courseHash] => disciplines

    // Mapping to store the recipient's public key with the student's address and the recipient's address 
    mapping(address => mapping(address => string)) private recipientEncryptKey;

    // Mapping to store the student's information encrypted with the recipient's public key with the student's address and the recipient's address
    mapping(address => mapping(address => string)) private studentInfoRecipient;

    mapping(address => address) private studentToInstitution; // studentAddress => institutionAddress
    mapping(address => string) private studentToCourse;

    address[] private institutionAddressList;

    /// @dev Restricts function execution to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can perform this action!");
        _;
    }

    /// @dev Restricts function execution to a specific institution.
    modifier onlyInstitution(address institutionAddress) {
        require(
            msg.sender == institutionAddress,
            "Only the institution can perform this action!"
        );
        _;
    }

    /// @dev Restricts function execution to a specific student.
    modifier onlyStudent(address studentAddress) {
        require(
            msg.sender == studentAddress,
            "Only the student can perform this action!"
        );
        _;
    }

    /// @dev Ensures the institution is registered.
    modifier institutionExists(address institutionAddress) {
        require(
            institutions[institutionAddress].institutionAddress != address(0),
            "Institution is not registered!"
        );
        _;
    }

    /// @dev Ensures the student is registered.
    modifier studentExists(address studentAddress) {
        require(
            students[studentAddress].studentAddress != address(0),
            "Student is not registered!"
        );
        _;
    }

    /// @dev Ensures the student is registered for an institution.
    modifier studentIsInstitution(address studentAddress, address institutionAddress) {
        require(
            studentToInstitution[studentAddress] == institutionAddress,
            "Student is not in this Institution!"
        );
        _;
    }

    /// @dev Ensures the course exists for the provided institution.
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

    /// @dev Contract constructor that sets the owner.
    constructor() {
        contractOwner = msg.sender;
    }

    /// @notice Adds a new institution.
    /// @dev Verifies that the institution is not already registered before adding it. Maintains a list of institution addresses for enumeration.
    /// @param institutionAddress Address of the institution.
    /// @param name Name of the institution.
    /// @param document Identification document of the institution.
    function addInstitution(
        address institutionAddress,
        string calldata name,
        string calldata document
    ) public onlyOwner {
        require(
            institutions[institutionAddress].institutionAddress == address(0),
            "Institution already registered!"
        );

        institutions[institutionAddress] = Institution(institutionAddress, name, document, "");
        institutionAddressList.push(institutionAddress);

        emit InstitutionAdded(institutionAddress, name);
    }

    /// @notice Adds the instituition public key.
    /// @dev 
    function addInstitutionPublicKey(
        address institutionAddress,
        string calldata publicKey
    ) public onlyInstitution(institutionAddress) {
        institutions[institutionAddress].publicKey = publicKey;
    }

    /// @notice Retrieves an institution's data.
    /// @dev Fetches the details of an institution using its address as the mapping key.
    /// @param institutionAddress Address of the institution.
    /// @return Institution structure.
    function getInstitution(address institutionAddress)
        public
        view
        returns (Institution memory)
    {
        return institutions[institutionAddress];
    }

    /// @notice Retrieves the list of registered institution addresses.
    /// @dev Returns the complete list of addresses for all registered institutions.
    /// @return List of institution addresses.
    function getInstitutionList()
        public
        view
        returns (address[] memory)
    {
        return institutionAddressList;
    }

    /// @notice Adds a new course to an institution.
    /// @dev Ensures that the course does not already exist in the institution before adding it to the mapping.
    /// @param institutionAddress Address of the institution.
    /// @param code Unique course code.
    /// @param name Name of the course.
    /// @param courseType Type of the course (e.g., Bachelor, Masters).
    /// @param numberOfSemesters Number of semesters in the course.
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

    /// @notice Adds a new discipline to a specific course in an institution.
    /// @dev Uses the internal helper `_addDisciplineToCourse` to handle logic. Ensures the course exists before adding the discipline.
    /// @param institutionAddress Address of the institution.
    /// @param courseCode Code of the course to which the discipline is being added.
    /// @param disciplineCode Unique code of the discipline.
    /// @param name Name of the discipline.
    /// @param syllabus Syllabus of the discipline.
    /// @param workload Workload of the discipline in hours.
    /// @param creditCount Number of credits assigned to the discipline.
    function addDisciplineToCourse(
        address institutionAddress,
        string calldata courseCode,
        string calldata disciplineCode,
        string calldata name,
        string calldata syllabus,
        int workload,
        int creditCount
    ) public courseExists(institutionAddress, courseCode) onlyInstitution(institutionAddress) {
        _addDisciplineToCourse(courseCode, disciplineCode, name, syllabus, workload, creditCount);
    }

    /// @dev Internal function to add a discipline to a course.
    /// @param courseCode Code of the course to which the discipline is being added.
    /// @param disciplineCode Unique code of the discipline.
    /// @param name Name of the discipline.
    /// @param syllabus Syllabus of the discipline.
    /// @param workload Workload of the discipline in hours.
    /// @param creditCount Number of credits assigned to the discipline.
    function _addDisciplineToCourse(
        string calldata courseCode,
        string calldata disciplineCode,
        string calldata name,
        string calldata syllabus,
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
            Discipline(disciplineCode, name, syllabus, workload, creditCount)
        );

        // Mark discipline as registered in the course
        disciplineExistsInCourse[courseHash][disciplineHash] = true;

        emit DisciplineAdded(courseCode, disciplineCode);
    }

    /// @notice Adds a student to the academic registry system.
    /// @dev Verifies that the student is not already registered before adding them to the mapping.
    /// @param institutionAddress Address of the institution where the student is being added.
    /// @param studentAddress Address of the student being added.
    function addStudent(
        address institutionAddress,
        address studentAddress
    ) public institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        // Check if student is already registered
        require(
            students[studentAddress].studentAddress == address(0),
            "Student already registered!"
        );

        students[studentAddress] = Student(studentAddress, "", "", "", "");
        studentToInstitution[studentAddress] = institutionAddress;

        emit StudentAdded(studentAddress);
    }

    /// @notice Retrieves a student's data from the registry.
    /// @dev Fetches student details using their unique address as the mapping key.
    /// @param studentAddress Address of the student.
    /// @return Student structure containing the student's data.
    function getStudent(address studentAddress)
        public
        view
        returns (Student memory)
    {
        return students[studentAddress];
    }

    /// @notice Adds a grade for a student in a specific discipline and semester.
    /// @dev Verifies the existence of the institution, student, and discipline. Ensures that no duplicate grades exist for the same semester and discipline before adding a new grade.
    /// @param institutionAddress Address of the institution recording the grade.
    /// @param studentAddress Address of the student receiving the grade.
    /// @param disciplineCode Code of the discipline for which the grade is recorded.
    /// @param semester Academic semester in which the grade is being recorded.
    /// @param grade Final grade of the student.
    /// @param attendance Attendance percentage of the student.
    /// @param status Approval status (true = approved, false = failed).
    function addGrade(
        address institutionAddress,
        address studentAddress,
        string calldata courseCode,
        string calldata disciplineCode,
        uint8 semester,
        uint16 year,
        uint8 grade,
        uint8 attendance,
        bool status
    ) public institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        // bytes32 disciplineHash = keccak256(abi.encodePacked(disciplineCode));

        // Check if student is registered
        require(
            students[studentAddress].studentAddress != address(0),
            "Student not registered!"
        );

        // Ensures that only the first insertion is written
        if (bytes(studentToCourse[studentAddress]).length == 0) {
            studentToCourse[studentAddress] = courseCode;
        }

        // Check if grade for this semester and discipline already exists
        Grade[] storage studentGrades = grades[studentAddress];
        for (uint256 i = 0; i < studentGrades.length; i++) {
            require(
                !(
                    keccak256(abi.encodePacked(studentGrades[i].disciplineCode)) ==
                        keccak256(abi.encodePacked(disciplineCode)) &&
                    studentGrades[i].semester == semester
                ),
                "Grade already recorded for this discipline and semester!"
            );
        }

        // Add grade
        grades[studentAddress].push(
            Grade(disciplineCode, semester, year, grade, attendance, status)
        );

        emit GradeAdded(studentAddress, disciplineCode, year, semester);
    }

    /// @notice Adds an address to be allowed to retrieve the student data.
    /// @dev Verifies the existence of the student.
    /// @param allowedAddress Address of the account to be given permition to retrieve student data.
    /// @param studentAddress Address of the student allowing its data to be retrieved by the allowedAddress.
    function retrieveRecipientEncrpytKey(
        address allowedAddress,
        address studentAddress) public view studentExists(studentAddress) onlyStudent(studentAddress)
        returns (string memory) {

            require(
                bytes(recipientEncryptKey[studentAddress][allowedAddress]).length != 0,
                "Recipient's Key was not shared yet!"
            );

            return recipientEncryptKey[studentAddress][allowedAddress];
    }

    /// @notice Adds the student's data encrypted with the recipient's public encryption key.
    /// @dev Verifies the existence of the student.
    /// @param allowedAddress Address of the account to be given permition to retrieve student data.
    /// @param studentAddress Address of the student allowing its data to be retrieved by the allowedAddress.
    /// @param encryptedData Student's info encrypted with the Recipient public encryption key.
    function addEncryptedInfoWithRecipientKey(
        address allowedAddress,
        address studentAddress,
        string calldata encryptedData) public studentExists(studentAddress) onlyStudent(studentAddress) {

            studentInfoRecipient[studentAddress][allowedAddress] = encryptedData;
    }

    function getEncryptedInfoWithRecipientKey(
        address allowedAddress,
        address studentAddress) public view studentExists(studentAddress)
        returns (string memory) {
            return studentInfoRecipient[studentAddress][allowedAddress];
    }

    /// @notice Adds the public key and personal information of the student's account.
    /// @dev Verifies the existence of the student.
    /// @param encryptedInformation Personal information of the student encrypted by its public key.
    function addStudentInformation(
        string calldata encryptedInformation,
        string calldata publicKey,
        string calldata publicHash
        ) onlyStudent(msg.sender) public studentExists(msg.sender) {

        // Add personal information
        students[msg.sender].institutionEncryptedInformation = encryptedInformation;
        students[msg.sender].publicKey = publicKey;
        students[msg.sender].publicHash = publicHash;

        emit StudentInformationAdded(msg.sender);
    }

    function confirmStudentInformation(
        address studentAddress,
        address institutionAddress,
        string calldata encryptedInformation
    ) public onlyInstitution(msg.sender) studentExists(studentAddress) studentIsInstitution(studentAddress, institutionAddress) {

        students[studentAddress].selfEncryptedInformation = encryptedInformation;
    }

    function addGrades(
        address institutionAddress,
        address studentAddress,
        string calldata courseCode,
        Grade[] calldata gradeInfos
    ) public studentExists(studentAddress) institutionExists(institutionAddress) onlyInstitution(institutionAddress) {
        // Ensures that only the first insertion is written
        if (bytes(studentToCourse[studentAddress]).length == 0) {
            studentToCourse[studentAddress] = courseCode;
        }

        for (uint256 i = 0; i < gradeInfos.length; i++) {
            Grade memory grade = gradeInfos[i];

            // Check if grade for this semester and discipline already exists
            for (uint256 j = 0; j < grades[studentAddress].length; j++) {
                require(
                    !(keccak256(abi.encodePacked(grades[studentAddress][j].disciplineCode)) == keccak256(abi.encodePacked(grade.disciplineCode)) &&
                    grades[studentAddress][j].semester == grade.semester),
                    "Grade already recorded for this discipline and semester!"
                );
            }

            grades[studentAddress].push(
                Grade(grade.disciplineCode, grade.semester, grade.year, grade.grade, grade.attendance, grade.status)
            );
        }   
    }

    /// @notice Retrieves the permission for the message sender's account address.
    /// @dev Returns a string containing the role of the sender's account address.
    /// @return A string representing the account's role in the system.
    function getPermission()
        public view
        returns (string memory) {
            if (msg.sender == contractOwner) {
                return "owner";
            }

            if (students[msg.sender].studentAddress != address(0)) {
                return "student";
            }

            if (institutions[msg.sender].institutionAddress != address(0)) {
                return "institution";
            }

            return "viewer";
    }

    /// @notice Retrieves the institution and course information for a student.
    /// @param studentAddress Address of the student.
    /// @return institution Institution data.
    /// @return course Course data.
    function getStudentInstitutionData(address studentAddress)
        public
        view
        returns (Institution memory institution, Course memory course) {
        address institutionAddress = studentToInstitution[studentAddress];

        string memory courseCode = studentToCourse[studentAddress];

        require(
            bytes(courseCode).length > 0, "Student not enrolled in any course!"
        );

        Course[] memory institutionCourses = courses[institutionAddress];

        for (uint i = 0; i < institutionCourses.length; i++) {
            if (keccak256(abi.encodePacked(institutionCourses[i].code)) == keccak256(abi.encodePacked(courseCode))) {
                return (institutions[institutionAddress], institutionCourses[i]);
            }
        }
    }

    /// @notice Retrieves the grades along with detailed discipline information for a specific student.
    /// @param studentAddress Address of the student.
    /// @return An array of tuples containing grade and discipline information.
    function getStudentTranscript(address studentAddress)
        public
        view
        //onlyAllowedAddresses(studentAddress, msg.sender)
        returns (Grade[] memory, Discipline[] memory)
    {
        Grade[] memory studentGrades = grades[studentAddress];
        Discipline[] memory disciplineDetails = new Discipline[](studentGrades.length);

        for (uint256 i = 0; i < studentGrades.length; i++) {
            bytes32 disciplineHash = keccak256(abi.encodePacked(studentGrades[i].disciplineCode));
            bytes32 courseHash = keccak256(abi.encodePacked(studentToCourse[studentAddress]));

            Discipline[] memory courseDisciplines = disciplinesByCourse[courseHash];

            for (uint256 j = 0; j < courseDisciplines.length; j++) {
                if (keccak256(abi.encodePacked(courseDisciplines[j].code)) == disciplineHash) {
                    disciplineDetails[i] = courseDisciplines[j];
                    break;
                }
            }
        }

        return (studentGrades, disciplineDetails);
    }

    /// @notice Retrieves the grades along with detailed discipline information for a specific student.
    /// @param studentAddress Address of the student.
    /// @param encryptKey The recipient's public encrypt key.
    function requestAccess(address studentAddress, string calldata encryptKey)
        public studentExists(studentAddress)
    {
        recipientEncryptKey[studentAddress][msg.sender] = encryptKey;
    }
}
