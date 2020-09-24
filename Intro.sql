
-- Subquery, Intro  
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

-- Subquery, More 
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

-- Let's give MAX fee per Animal type instead of overall 
SELECT B.Name AS Animal, C.Name AS AnimalType, A1.Fee AS AdoptionFee,
	( SELECT MAX(Fee)
	FROM Shelter.Adoption
	)  AS MaxFee
FROM Shelter.Adoption AS A1
	INNER JOIN Shelter.Animal AS B
	ON A1.AnimalID = B.AnimalID
	INNER JOIN Shelter.AnimalType AS C
	ON B.TypeID = C.TypeID

