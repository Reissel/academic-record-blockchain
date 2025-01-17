// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

/// @title Academic registry smart contract.
/// @notice This contract manages records for institutions, courses, disciplines, professors, students, and grades in an academic registry system.
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

    /// @dev Emitted when a new professor is added to an institution.
    /// @param institutionAddress The address of the institution adding the professor.
    /// @param professorAddress The address of the professor being added.
    /// @param name The name of the professor.
    event ProfessorAdded(address indexed institutionAddress, address professorAddress, string name);

    /// @dev Emitted when a new student is added.
    /// @param studentAddress The address of the student being added.
    event StudentAdded(address indexed studentAddress);

    /// @dev Emitted when a new grade is added for a student.
    /// @param studentAddress The address of the student receiving the grade.
    /// @param disciplineCode The code of the discipline for which the grade is recorded.
    /// @param period The period in which the grade was recorded.
    event GradeAdded(address indexed studentAddress, string disciplineCode, uint8 period);

    /// @dev Emitted when a new address is allowed by a student.
    /// @param studentAddress The address of the student allowing the address.
    /// @param allowedAddress The address being allowed by the student.
    event AllowedAddressAdded(address indexed studentAddress, address allowedAddress);

    /// @dev Emitted when the information of the student is added by it.
    /// @param studentAddress The address of the student adding the information.
    event StudentInformationAdded(address indexed studentAddress);

    /// @dev Contract ownership. Only the owner can perform certain actions.
    address private contractOwner;

    /// @dev Represents an institution.
    struct Institution {
        address idInstitutionAccount;
        string name;
        string document;
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
        string ementa;
        int workload;
        int creditCount;
    }

    /// @dev Represents a professor.
    struct Professor {
        address idProfessorAccount;
        string name;
        string document;
    }

    /// @dev Represents a student.
    struct Student {
        address idStudentAccount;
        string encryptedInformation;
        string publicKey;
    }

    /// @dev Represents a student's grade.
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

    // Mapping to store addresses that can retrieve Student data
    mapping(address => mapping(address => bool)) private isAllowedByStudent;

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

    /// @dev Restricts function execution to a specific student.
    modifier onlyAllowedAddresses(address studentAddress, address requesterAddress) {
        require(
            isAllowedByStudent[studentAddress][msg.sender] == true,
            "Only allowed addresses can perform this action!"
        );
        _;
    }

    /// @dev Ensures the institution is registered.
    modifier institutionExists(address institutionAddress) {
        require(
            institutions[institutionAddress].idInstitutionAccount != address(0),
            "Institution is not registered!"
        );
        _;
    }

    /// @dev Ensures the student is registered.
    modifier studentExists(address studentAddress) {
        require(
            students[studentAddress].idStudentAccount != address(0),
            "Student is not registered!"
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
            institutions[institutionAddress].idInstitutionAccount == address(0),
            "Institution already registered!"
        );

        institutions[institutionAddress] = Institution(institutionAddress, name, document);
        institutionAddressList.push(institutionAddress);

        emit InstitutionAdded(institutionAddress, name);
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

    /// @notice Retrieves all courses associated with an institution.
    /// @dev Retrieves the list of courses offered by an institution using its address as the mapping key.
    /// @param institutionAddress Address of the institution.
    /// @return List of courses offered by the institution.
    function getCoursesFromInstitution(address institutionAddress)
        public
        view
        returns (Course[] memory)
    {
        return courses[institutionAddress];
    }

    /// @notice Adds a new discipline to a specific course in an institution.
    /// @dev Uses the internal helper `_addDisciplineToCourse` to handle logic. Ensures the course exists before adding the discipline.
    /// @param institutionAddress Address of the institution.
    /// @param courseCode Code of the course to which the discipline is being added.
    /// @param disciplineCode Unique code of the discipline.
    /// @param name Name of the discipline.
    /// @param ementa Syllabus of the discipline.
    /// @param workload Workload of the discipline in hours.
    /// @param creditCount Number of credits assigned to the discipline.
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

    /// @dev Internal function to add a discipline to a course.
    /// @param courseCode Code of the course to which the discipline is being added.
    /// @param disciplineCode Unique code of the discipline.
    /// @param name Name of the discipline.
    /// @param ementa Syllabus of the discipline.
    /// @param workload Workload of the discipline in hours.
    /// @param creditCount Number of credits assigned to the discipline.
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

    /// @notice Retrieves the list of disciplines associated with a course.
    /// @dev Retrieves all disciplines associated with a specific course using its hashed code as the mapping key.
    /// @param courseCode Code of the course whose disciplines are to be retrieved.
    /// @return List of disciplines offered in the course.
    function getDisciplinesFromCourse(string calldata courseCode)
        public
        view
        returns (Discipline[] memory)
    {
        bytes32 courseHash = keccak256(abi.encodePacked(courseCode));
        return disciplinesByCourse[courseHash];
    }

    /// @notice Adds a professor to a specific institution.
    /// @dev Ensures that the professor is not already registered in the institution before adding them. Maintains a mapping to track registration status.
    /// @param institutionAddress Address of the institution where the professor is being added.
    /// @param professorAddress Address of the professor being added.
    /// @param name Name of the professor.
    /// @param document Identification document of the professor.
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

    /// @notice Retrieves the list of professors associated with a specific institution.
    /// @dev Retrieves the list of professors associated with a specific institution using its address as the mapping key.
    /// @param institutionAddress Address of the institution.
    /// @return List of professors registered in the institution.
    function getProfessorsFromInstitution(address institutionAddress)
        public
        view
        returns (Professor[] memory)
    {
        return professors[institutionAddress];
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
            students[studentAddress].idStudentAccount == address(0),
            "Student already registered!"
        );

        students[studentAddress] = Student(studentAddress, "", "");
        isAllowedByStudent[studentAddress][institutionAddress] = true;
        isAllowedByStudent[studentAddress][studentAddress] = true;

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

    /// @notice Enrolls a student in a discipline within a course.
    /// @dev Checks if the institution, student, and discipline exist before allowing enrollment. Uses hashes for efficient mapping lookups.
    /// @param institutionAddress Address of the institution offering the discipline.
    /// @param studentAddress Address of the student being enrolled.
    /// @param disciplineCode Code of the discipline.
    /// @param courseCode Code of the course containing the discipline.
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

    /// @notice Adds a grade for a student in a specific discipline and period.
    /// @dev Verifies the existence of the institution, student, and discipline. Ensures that no duplicate grades exist for the same period and discipline before adding a new grade.
    /// @param institutionAddress Address of the institution recording the grade.
    /// @param studentAddress Address of the student receiving the grade.
    /// @param disciplineCode Code of the discipline for which the grade is recorded.
    /// @param period Academic period in which the grade is being recorded.
    /// @param media Final grade of the student.
    /// @param attendance Attendance percentage of the student.
    /// @param status Approval status (true = approved, false = failed).
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
        // TODO: Encrypt with student's public key
        grades[studentAddress].push(
            Grade(disciplineCode, period, media, attendance, status)
        );

        emit GradeAdded(studentAddress, disciplineCode, period);
    }

    /// @notice Retrieves all grades for a specific student.
    /// @dev Grades are stored in an array indexed by the student's address.
    /// @param studentAddress Address of the student.
    /// @return An array of Grade structures containing the student's grades.
    function getGrades(address studentAddress)
        public onlyAllowedAddresses(studentAddress, msg.sender)
        view
        returns (Grade[] memory)
    {
        return grades[studentAddress];
    }

    /// @notice Adds an address to be allowed to retrieve the student data.
    /// @dev Verifies the existence of the student.
    /// @param allowedAddress Address of the account to be given permition to retrieve student data.
    /// @param studentAddress Address of the student allowing its data to be retrieved by the allowedAddress.
    function addAllowedAddress(
        address allowedAddress,
        address studentAddress) public studentExists(studentAddress) onlyStudent(studentAddress) {

            require(
                isAllowedByStudent[studentAddress][allowedAddress] == false,
                "Address is already allowed!"
            );

            isAllowedByStudent[studentAddress][allowedAddress] = true;
            emit AllowedAddressAdded(studentAddress, allowedAddress);
    }

    /// @notice Adds the public key and personal information of the student's account.
    /// @dev Verifies the existence of the student.
    /// @param publicKey Public key of the student's account.
    /// @param encryptedInformation Personal information of the student encrypted by its public key.
    function addStudentInformation(
        string calldata publicKey,
        string calldata encryptedInformation) public studentExists(msg.sender) onlyStudent(msg.sender) {

        // Add public key
        students[msg.sender].publicKey = publicKey;
        // Add personal information
        students[msg.sender].encryptedInformation = encryptedInformation;

        emit StudentInformationAdded(msg.sender);
    }
}
