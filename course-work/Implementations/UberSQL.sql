-- Create Passengers table
CREATE TABLE Passengers (
    PassengerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(15),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Create Drivers table
CREATE TABLE Drivers (
    DriverID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(15),
    LicenseNumber NVARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Create Cars table
CREATE TABLE Cars (
    CarID INT IDENTITY(1,1) PRIMARY KEY,
    Make NVARCHAR(50),
    Model NVARCHAR(50),
    Year INT,
    LicensePlate NVARCHAR(20),
    Color NVARCHAR(20)
);

-- Create Driver_Cars table (Many-to-Many relationship between Drivers and Cars)
CREATE TABLE Driver_Cars (
    DriverID INT,
    CarID INT,
    AssignmentStart DATETIME,
    AssignmentEnd DATETIME,
    PRIMARY KEY (DriverID, CarID),
    FOREIGN KEY (DriverID) REFERENCES Drivers(DriverID),
    FOREIGN KEY (CarID) REFERENCES Cars(CarID)
);

-- Create Locations table
CREATE TABLE Locations (
    LocationID INT IDENTITY(1,1) PRIMARY KEY,
    Latitude FLOAT,
    Longitude FLOAT,
    Address NVARCHAR(255)
);

-- Create Rides table
CREATE TABLE Rides (
    RideID INT IDENTITY(1,1) PRIMARY KEY,
    PassengerID INT,
    DriverID INT,
    CarID INT,
    StartLocationID INT,
    EndLocationID INT,
    StartTime DATETIME,
    EndTime DATETIME,
    Fare DECIMAL(10, 2),
    FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID),
    FOREIGN KEY (DriverID) REFERENCES Drivers(DriverID),
    FOREIGN KEY (CarID) REFERENCES Cars(CarID),
    FOREIGN KEY (StartLocationID) REFERENCES Locations(LocationID),
    FOREIGN KEY (EndLocationID) REFERENCES Locations(LocationID)
);

-- Create Payments table
CREATE TABLE Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    RideID INT,
    Amount DECIMAL(10, 2),
    PaymentMethod NVARCHAR(50),
    PaymentTime DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (RideID) REFERENCES Rides(RideID)
);

-- Create Ratings table (for driver and passenger ratings)
CREATE TABLE Ratings (
    RatingID INT IDENTITY(1,1) PRIMARY KEY,
    RideID INT,
    PassengerRating TINYINT CHECK (PassengerRating BETWEEN 1 AND 5),
    DriverRating TINYINT CHECK (DriverRating BETWEEN 1 AND 5),
    Feedback NVARCHAR(255),
    FOREIGN KEY (RideID) REFERENCES Rides(RideID)
);

go 

CREATE TRIGGER CreatePaymentOnRide
ON Rides
AFTER INSERT
AS
BEGIN
    -- Insert a payment for the newly created ride with default values
    INSERT INTO Payments (RideID, Amount, PaymentMethod)
    SELECT i.RideID, i.Fare, 'Pending'
    FROM inserted i;
END;

go


CREATE TRIGGER CreateReviewOnPayment
ON Payments
AFTER UPDATE
AS
BEGIN
    -- Create a review entry when payment is marked as 'Completed'
    IF EXISTS (SELECT * FROM inserted WHERE PaymentMethod = 'Completed')
    BEGIN
        INSERT INTO Ratings (RideID, PassengerRating, DriverRating)
        SELECT i.RideID, NULL, NULL
        FROM inserted i;
    END
END;


go

--drop procedure sp_CreateRide;
CREATE PROCEDURE sp_CreateRide
    @PassengerID INT,
    @DriverID INT,
    @CarID INT,
    @StartLocationID INT,
    @EndLocationID INT,
    @StartTime DATETIME,
    @Fare DECIMAL(10, 2)
AS
BEGIN
    INSERT INTO Rides (PassengerID, DriverID, CarID, StartLocationID, EndLocationID, StartTime, Fare)
    VALUES (@PassengerID, @DriverID, @CarID, @StartLocationID, @EndLocationID, @StartTime, @Fare);

    -- Get the ID of the newly created ride
    select SCOPE_IDENTITY()
END;

go

--drop procedure sp_CreateLocation
CREATE PROCEDURE sp_CreateLocation
    @Latitude FLOAT,
    @Longitude FLOAT,
    @Address NVARCHAR(255)
  
AS
BEGIN
    INSERT INTO Locations (Latitude, Longitude, Address)
    VALUES (@Latitude, @Longitude, @Address);

	select SCOPE_IDENTITY();
    -- Get the ID of the newly created location
END;


go
CREATE FUNCTION fn_GetAvgReviewForDriver
(
    @DriverID INT
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @AvgRating FLOAT;

    SELECT @AvgRating = AVG(DriverRating)
    FROM Rides r
    JOIN Ratings ra ON r.RideID = ra.RideID
    WHERE r.DriverID = @DriverID AND ra.DriverRating IS NOT NULL;

    RETURN @AvgRating;
END;

go

CREATE FUNCTION fn_GetInactiveDrivers
()
RETURNS TABLE
AS
RETURN
(
    SELECT d.DriverID, d.FirstName, d.LastName
    FROM Drivers d
    WHERE NOT EXISTS (
        SELECT 1
        FROM Rides r
        WHERE r.DriverID = d.DriverID
        AND r.StartTime >= DATEADD(DAY, -30, GETDATE())
    )
);
go

-- Declare a variable to store the new RideID
DECLARE @NewRideID INT;

-- Execute the procedure and pass the RideID as OUTPUT
EXEC sp_CreateRide 
    @PassengerID = 1, 
    @DriverID = 2, 
    @CarID = 3, 
    @StartLocationID = 10, 
    @EndLocationID = 11, 
    @StartTime = null , 
    @Fare = 25.50

-- Select the new RideID to verify
SELECT @NewRideID AS 'New Ride ID';

select * from rides


--INSERT INTO Passengers (FirstName, LastName, Email, Phone)
--VALUES 
--    ('John', 'Doe', 'john.doe@example.com', '555-1234'),
--    ('Jane', 'Smith', 'jane.smith@example.com', '555-5678'),
--    ('Michael', 'Brown', 'michael.brown@example.com', '555-8765'),
--    ('Emily', 'Johnson', 'emily.johnson@example.com', '555-4321');


--INSERT INTO Drivers (FirstName, LastName, Email, Phone, LicenseNumber)
--VALUES 
--    ('Tom', 'Anderson', 'tom.anderson@example.com', '555-1111', 'LIC123456'),
--    ('Laura', 'Wilson', 'laura.wilson@example.com', '555-2222', 'LIC654321'),
--    ('Robert', 'Jones', 'robert.jones@example.com', '555-3333', 'LIC789012'),
--    ('Sophia', 'Garcia', 'sophia.garcia@example.com', '555-4444', 'LIC321098');

--INSERT INTO Cars (Make, Model, Year, LicensePlate, Color)
--VALUES 
--    ('Toyota', 'Prius', 2018, 'ABC1234', 'Blue'),
--    ('Honda', 'Civic', 2020, 'XYZ5678', 'Black'),
--    ('Ford', 'Fusion', 2019, 'LMN9876', 'White'),
--    ('Tesla', 'Model 3', 2021, 'EVT1234', 'Red');


--INSERT INTO Driver_Cars (DriverID, CarID, AssignmentStart, AssignmentEnd)
--VALUES 
--    (1, 1, '2023-01-01', '2023-05-01'), -- Tom Anderson -> Toyota Prius
--    (1, 2, '2023-05-02', NULL),         -- Tom Anderson -> Honda Civic (currently active)
--    (2, 3, '2023-02-15', '2023-08-15'), -- Laura Wilson -> Ford Fusion
--    (3, 4, '2023-07-10', NULL);         -- Robert Jones -> Tesla Model 3 (currently active)

--INSERT INTO Locations (Latitude, Longitude, Address)
--VALUES 
--    (40.7128, -74.0060, 'New York, NY'),
--    (34.0522, -118.2437, 'Los Angeles, CA'),
--    (41.8781, -87.6298, 'Chicago, IL'),
--    (37.7749, -122.4194, 'San Francisco, CA');


INSERT INTO Locations (Latitude, Longitude, Address)
VALUES 
    (40.7128, -74.0060, 'New York, NY'),
    (34.0522, -118.2437, 'Los Angeles, CA'),
    (41.8781, -87.6298, 'Chicago, IL'),
    (37.7749, -122.4194, 'San Francisco, CA');


--	INSERT INTO Rides (PassengerID, DriverID, CarID, StartLocationID, EndLocationID, StartTime, EndTime, Fare)
--VALUES 
--    (1, 1, 1, 1, 2, '2023-10-10 08:00:00', '2023-10-10 08:30:00', 15.50), -- John Doe -> Tom Anderson (Toyota Prius)
--    (2, 2, 3, 3, 4, '2023-10-11 09:00:00', '2023-10-11 09:45:00', 20.75), -- Jane Smith -> Laura Wilson (Ford Fusion)
--    (3, 3, 4, 4, 1, '2023-10-12 10:00:00', '2023-10-12 10:40:00', 18.90), -- Michael Brown -> Robert Jones (Tesla Model 3)
--    (4, 1, 2, 2, 3, '2023-10-13 11:00:00', '2023-10-13 11:35:00', 22.30); -- Emily Johnson -> Tom Anderson (Honda Civic)

--select * from payments;

--select * from Ratings;

--update payments 
--set paymentMethod = 'Completed'
--where rideId = 1;
go 
EXEC sp_CreateLocation @Latitude = 40.7128, @Longitude = -74.0060, @Address = 'New York, NY';
