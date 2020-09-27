-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Subquery,
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SELECT MAX(Fee)
FROM Shelter.Adoption;

-- There are 2 different and independent queries 
-- unrelated one value AdoptionFee for all rows 
SELECT Name,
	(SELECT MAX(Fee)
	FROM Shelter.Adoption
	) AS AdoptionFee
FROM Shelter.Animal;
-- (100 rows affected)

-- Join is helping for anmials who are adopted
-- still unrelated one value AdoptionFee for all rows
SELECT B.Name,
	(SELECT MAX(Fee)
	FROM Shelter.Adoption
	) AS AdoptionFee
FROM Shelter.Adoption AS A
	INNER JOIN Shelter.Animal AS B
	ON A.AnimalID = B.AnimalID;
-- (70 rows affected)

-- Correlated Subquery, helps here 
SELECT Name,
	(SELECT MAX(Fee)
	FROM Shelter.Adoption AS A
	WHERE A.AnimalID = B.AnimalID 
	) AS AdoptionFee
FROM Shelter.Animal AS B;
-- (100 rows affected)

-- Join approach 
SELECT B.Name, MAX(A.Fee) AS AdoptionFee
FROM Shelter.Adoption AS A
	INNER JOIN Shelter.Animal AS B
	ON A.AnimalID = B.AnimalID
GROUP by B.Name
-- (69 rows affected)

SELECT *
FROM Shelter.Animal
WHERE Name = 'Penelope';
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Let's provide MAX discont fee at overall level
-- Discont % = ((Y-X)*100/Y)
-- going with More fee, less discont 
SELECT *,
	(SELECT MAX(Fee)
	FROM Shelter.Adoption),
	(((SELECT MAX(Fee)
	FROM Shelter.Adoption)
	- Fee) * 100)
	/ (SELECT MAX(Fee)
	FROM Shelter.Adoption) AS DiscontPercent
FROM Shelter.Adoption;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Show people who adopted at least one animal 
SELECT COUNT(*)
FROM Shelter.Person;
-- 120

SELECT COUNT(*)
FROM Shelter.Adoption;
-- 70

-- Option A
SELECT DISTINCT P.*
FROM Shelter.Person AS P
	INNER JOIN Shelter.Adoption AS A
	ON P.PersonID = A.PersonID;
-- (49 rows affected)

-- Option B
SELECT *
FROM Shelter.Person
WHERE PersonID IN (SELECT PersonID
FROM Shelter.Adoption);
-- (49 rows affected)

-- Option C
SELECT *
FROM Shelter.Person P
WHERE EXISTS (
	-- below can be anything, NULL, *, 'Hello', .... Just making SELECT valid
	-- SELECT clause returns nothing when use with EXISTS 
	SELECT NULL
FROM Shelter.Adoption AS A
WHERE A.PersonID= P.PersonID
);
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/*
Set Operators
They stand between two different queries.
Note: Please review the set operators’ diagrams

UNION ALL
Returns all elements from data sources. 

UNION or UNION DISTINCT 
Returns none duplicate elements from data sources 

INTERSECT or INTERSECT DISTINCT
Returns none duplicate common element from data sources. 

EXCEPT or EXCEPT DISTINCT
Returns one of each main source elements that do not exist in target. It is by directional.
*/
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Find animals that were never adopted 

-- Option 1
SELECT A.Name, A.Breed, AD.*
FROM Shelter.Animal AS A
	LEFT OUTER JOIN
	Shelter.Adoption AS AD
	ON	A.AnimalID = AD.AnimalID
WHERE AD.AnimalID IS NULL;
-- (30 rows affected)

-- Option 2
SELECT A.AnimalID, A.Name, A.Breed
FROM Shelter.Animal AS A
WHERE NOT EXISTS (
	SELECT NULL
FROM Shelter.Adoption AS AD
WHERE AD.AnimalID = A.AnimalID);
-- (30 rows affected)

-- Option 3
SELECT AnimalID, Name, Breed
FROM Shelter.Animal
WHERE AnimalID
NOT IN (SELECT AnimalID
FROM Shelter.Adoption);
-- (30 rows affected)

-- Option 4, using Set Operators
	SELECT AnimalID, Name, Breed
	FROM Shelter.Animal
EXCEPT
	SELECT A.AnimalID, B.Name, B.Breed
	FROM Shelter.Adoption AS A
		INNER JOIN Shelter.Animal AS B
		ON A.AnimalID = B.AnimalID;
-- (30 rows affected)
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Show all Animal types were never adopted 

	SELECT B.Name AS AnimalType, Breed
	FROM Shelter.Animal AS A
		INNER JOIN Shelter.AnimalType AS B
		ON A.TypeID = B.TypeID
EXCEPT
	SELECT B.Name AS AnimalType, Breed
	FROM Shelter.Animal AS A
		INNER JOIN Shelter.AnimalType AS B
		ON A.TypeID = B.TypeID
		INNER JOIN Shelter.Adoption AS C
		ON A.AnimalID = C.AnimalID;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Self Join
-- Show adopters who adopted 2 animals in 1 day.
SELECT P.Email,
	A1.[Date] AS AdoptionDate,
	B.Name AS AnimalName,
	T.Name AS AnimalType
FROM Shelter.Adoption AS A1
	INNER JOIN Shelter.Adoption AS A2
	ON A1.PersonID = A2.PersonID
		AND A1.[Date] = A2.[Date]
		AND A1.AnimalID > A2.AnimalID
	INNER JOIN Shelter.Person AS P
	ON A1.PersonID = P.PersonID
	INNER JOIN Shelter.Animal AS B
	ON A1.AnimalID = B.AnimalID
	INNER JOIN Shelter.AnimalType AS T
	ON B.TypeID = T.TypeID
ORDER BY A1.PersonID, A2.[Date]
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Grouping adoption by date and filtering for groups that
--  have more than one adoption on a same date 
SELECT [Date] AS AdoptionDate,
	SUM(Fee) AS TotalFee
FROM Shelter.Adoption
GROUP BY [Date]
HAVING COUNT(*) > 1;

-- Also, show all animals adopted on that date
SELECT [Date] AS AdoptionDate,
	SUM(Fee) AS TotalFee,
	STRING_AGG(CONCAT(B.Name, ' The ', T.Name), ', ')
	WITHIN GROUP (ORDER BY T.Name, B.Name) AS AdoptedAnimal
FROM Shelter.Adoption AS A
	INNER JOIN Shelter.Animal AS B
	ON A.AnimalID = B.AnimalID
	INNER JOIN Shelter.AnimalType AS T
	ON B.TypeID = T.TypeID
GROUP BY [Date]
HAVING COUNT(*) > 1;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Number of annual, monthly, and overall adoptions

-- Option 1 
SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, COUNT(*) AS MonthlyAdoption
FROM Shelter.Adoption
GROUP BY YEAR([Date]), MONTH([Date]);

SELECT YEAR([Date]) AS Year, COUNT(*) AS AnnualAdoption
FROM Shelter.Adoption
GROUP BY YEAR([Date]);

SELECT COUNT(*) AS TotalAdoption
FROM Shelter.Adoption;

-- Option 2
	SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, COUNT(*) AS MonthlyAdoption
	FROM Shelter.Adoption
	GROUP BY YEAR([Date]), MONTH([Date])
UNION ALL
	SELECT YEAR([Date]) AS Year, NULL AS Month, COUNT(*) AS AnnualAdoption
	FROM Shelter.Adoption
	GROUP BY YEAR([Date])
UNION ALL
	SELECT NULL AS Year, NULL AS Month, COUNT(*) AS TotalAdoption
	FROM Shelter.Adoption
	GROUP BY ();

-- Option 3
WITH
	AggregatedAdoptions
	AS
	(
		SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, COUNT(*) AS MonthlyAdoption
		FROM Shelter.Adoption
		GROUP BY YEAR([Date]), MONTH([Date])
	)
	SELECT *
	FROM AggregatedAdoptions
UNION ALL
	SELECT Year, NULL , COUNT(*)
	FROM AggregatedAdoptions
	GROUP BY Year
UNION ALL
	SELECT NULL, NULL, COUNT(*)
	FROM AggregatedAdoptions
	GROUP BY ();

-- Option 4 
SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, COUNT(*) AS MonthlyAdoption
FROM Shelter.Adoption
GROUP BY GROUPING SETS
(
	(YEAR([Date]), MONTH([Date])),
	YEAR([Date]),
	()
)
ORDER BY Year, [Month];
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Count the number of vaccinations per:
-- year, animal type, animal type and year, staff, staff and animal type
-- also, include the latest vaccination year for each group

-- First try
SELECT YEAR(V.[Time]) AS Year,
	T.Name AS AnimalType,
	P.Email,
	MAX(P.FirstName) AS FirstName, -- Dummy aggregate
	MAX(P.LastName) AS LastName, -- Dummy aggregate
	COUNT(*) AS NumberOfVaccinations,
	MAX(YEAR(V.[Time])) AS LatestVaccinationYear
FROM Shelter.Vaccine AS V
	INNER JOIN Shelter.Person AS P
	ON V.PersonID = P.PersonID
	INNER JOIN Shelter.Animal AS A
	ON V.AnimalID = A.AnimalID
	INNER JOIN Shelter.AnimalType AS T
	ON A.TypeID = T.TypeID
GROUP BY GROUPING SETS
(
	(),
	YEAR(V.[Time]),
	T.Name,
	(YEAR(v.[Time]), T.Name),
	P.Email,
	(P.Email, T.Name)
);

-- Final 
SELECT COALESCE(CAST(YEAR(V.[Time]) AS VARCHAR(10)), 'All Years')  AS Year,
	COALESCE(T.Name, 'All Animal Types') AS AnimalType,
	COALESCE(P.Email, 'All Staff') AS Email,
	CASE WHEN GROUPING(P.Email) = 0
		THEN MAX(P.FirstName)
		ELSE ''
		END AS FirstName, -- Dummy aggregate
	CASE WHEN GROUPING(P.Email) = 0
		THEN MAX(P.LastName)
		ELSE ''
		END AS LastName, -- Dummy aggregate
	COUNT(*) AS NumberOfVaccinations,
	MAX(YEAR(V.[Time])) AS LatestVaccinationYear
FROM Shelter.Vaccine AS V
	INNER JOIN Shelter.Person AS P
	ON V.PersonID = P.PersonID
	INNER JOIN Shelter.Animal AS A
	ON V.AnimalID = A.AnimalID
	INNER JOIN Shelter.AnimalType AS T
	ON A.TypeID = T.TypeID
GROUP BY GROUPING SETS
(
	(),
	YEAR(V.[Time]),
	T.Name,
	(YEAR(v.[Time]), T.Name),
	P.Email,
	(P.Email, T.Name)
)
ORDER BY Year, AnimalType, FirstName, LastName;
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Generate a series 
WITH
	daysOf2019 (day)
	AS
	(
					SELECT CAST('20190101' AS DATE)
		UNION ALL
			SELECT DATEADD(DAY, 1, day)
			FROM DaysOf2019
			WHERE day < CAST('20191231' AS DATE)
	)
SELECT *
FROM DaysOf2019
ORDER BY day ASC
OPTION
(MAXRECURSION
365);
-- (365 rows affected)
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++




