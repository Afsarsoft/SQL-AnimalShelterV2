SELECT B.Name, MAX(A.Fee)
FROM Shelter.Adoption AS A
	INNER JOIN Shelter.Animal AS B
	ON A.AnimalID = B.AnimalID
GROUP by B.Name
-- (69 rows affected)