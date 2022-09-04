

									-- Cleaning data in sql queries   

------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM CleaningPTP.dbo.Nashville_Homes


--Standrdize Date format

SELECT SaleDate, CONVERT (DATE, SaleDate)
FROM CleaningPTP.dbo.Nashville_Homes

UPDATE Nashville_Homes
SET SaleDate = CONVERT (DATE, SaleDate)

ALTER TABLE Nashville_Homes
ADD Date_Of_Sale DATE

UPDATE Nashville_Homes
SET Date_Of_Sale = CONVERT (DATE, SaleDate)

SELECT Date_Of_Sale
FROM CleaningPTP.dbo.Nashville_Homes

--------------------------------------------------------------------------------------------------------------------------------

--Populate propert address data

SELECT *
FROM CleaningPTP.dbo.Nashville_Homes
--WHERE PropertyAddress is NULL
ORDER BY ParcelID


SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM CleaningPTP.dbo.Nashville_Homes A
JOIN CleaningPTP.dbo.Nashville_Homes B
ON A.ParcelID = B.ParcelID
and A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL


UPDATE	A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM CleaningPTP.dbo.Nashville_Homes A
JOIN CleaningPTP.dbo.Nashville_Homes B
ON A.ParcelID = B.ParcelID
and A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL


-- Braking address in to Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM CleaningPTP.dbo.Nashville_Homes
--WHERE PropertyAddress is NULL
--ORDER BY ParcelID

-- Finding Address (Separate Address)
SELECT PropertyAddress , SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)  AS Address
FROM CleaningPTP.dbo.Nashville_Homes

-- Finding City (Separate City)
SELECT PropertyAddress , SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN (PropertyAddress))  AS City
FROM CleaningPTP.dbo.Nashville_Homes

-- Finding Both Address and City of Property Separatly (Separate Address & City)
SELECT PropertyAddress , SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)  AS LocAddress, 
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN (PropertyAddress))  AS City
FROM CleaningPTP.dbo.Nashville_Homes

-- Need to add these new coulmen (LocAddress , City) to CleaningPTP.dbo.Nashville_Homes


-- Add new coulmn as 'LocAddress'
ALTER TABLE CleaningPTP.dbo.Nashville_Homes
ADD LocAddress NVARCHAR(225);

UPDATE CleaningPTP.dbo.Nashville_Homes
SET LocAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

-- Add new coulmn as 'City'
ALTER TABLE CleaningPTP.dbo.Nashville_Homes
ADD City NVARCHAR(225);

UPDATE CleaningPTP.dbo.Nashville_Homes
SET City = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN (PropertyAddress))

SELECT *
FROM CleaningPTP.dbo.Nashville_Homes

--Separating owner address

SELECT *
FROM CleaningPTP.dbo.Nashville_Homes

SELECT OwnerAddress,PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS Owner_Home_Street,
	   PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS Owner_City,
	   PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS Owner_State
FROM CleaningPTP.dbo.Nashville_Homes

-- Time to alter tables as above --

ALTER TABLE CleaningPTP.dbo.Nashville_Homes
ADD Owner_Home_Street NVARCHAR(225);

UPDATE CleaningPTP.dbo.Nashville_Homes
SET Owner_Home_Street = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

----------------
ALTER TABLE CleaningPTP.dbo.Nashville_Homes
ADD Owner_City NVARCHAR(225);

UPDATE CleaningPTP.dbo.Nashville_Homes
SET Owner_City = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

----------------
ALTER TABLE CleaningPTP.dbo.Nashville_Homes
ADD Owner_State NVARCHAR(225);

UPDATE CleaningPTP.dbo.Nashville_Homes
SET Owner_State = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT*
FROM CleaningPTP.dbo.Nashville_Homes

---------------------------------------------------------------------------

--Change 'Y' and 'N' to '' and '' in 'SoldAsVacant' column

SELECT DISTINCT SoldAsVacant , COUNT (SoldAsVacant)
FROM CleaningPTP.dbo.Nashville_Homes
GROUP BY SoldAsVacant


SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'N' THEN 'No' 
		WHEN SoldAsVacant = 'Y' THEN 'Yes' 
		ELSE SoldAsVacant
		END
FROM CleaningPTP.dbo.Nashville_Homes

UPDATE CleaningPTP.dbo.Nashville_Homes
SET SoldAsVacant = CASE 
		WHEN SoldAsVacant = 'N' THEN 'No' 
		WHEN SoldAsVacant = 'Y' THEN 'Yes' 
		ELSE SoldAsVacant
		END

------------------------------------------------------------------------------------------------------------
--Remove duplicates (Unique ID would be unique but if other details are same how to remove such rows)


SELECT*
FROM CleaningPTP.dbo.Nashville_Homes


SELECT*, 
		ROW_NUMBER() OVER 
		(PARTITION BY	ParcelID, 
						PropertyAddress, 
						SalePrice, 
						SaleDate, 
						LegalReference 
						ORDER BY
							UniqueID) AS ROW_NUM		  
FROM CleaningPTP.dbo.Nashville_Homes
----WHERE ROW_NUM >1  (This is not working with above, therefore , need to use CTE)
ORDER BY ParcelID

-- TO remove identified duplicates by raw number (More than 01 or ROW_NUM >1 )  need to use CTE

WITH RowNumCte AS (
SELECT*, 
		ROW_NUMBER() OVER(
		PARTITION BY	ParcelID, 
						PropertyAddress, 
						SalePrice, 
						SaleDate, 
						LegalReference 
						ORDER BY
							UniqueID) AS ROW_NUM		  
FROM CleaningPTP.dbo.Nashville_Homes
--ORDER BY ParcelID
)

SELECT *
FROM RowNumCte
WHERE ROW_NUM > 1
ORDER BY PropertyAddress

--Now its time to delete duplicates

WITH RowNumCte AS (
SELECT*, 
		ROW_NUMBER() OVER(
		PARTITION BY	ParcelID, 
						PropertyAddress, 
						SalePrice, 
						SaleDate, 
						LegalReference 
						ORDER BY
							UniqueID) AS ROW_NUM		  
FROM CleaningPTP.dbo.Nashville_Homes
--ORDER BY ParcelID
)

DELETE
FROM RowNumCte
WHERE ROW_NUM > 1
--ORDER BY PropertyAddress

-------------------------------------------------------------------------------------------------------------------------------

--DELETE unused columns (Those are OwnerAddress, PropertyAddress, TaxDistrict)

SELECT *
FROM CleaningPTP.dbo.Nashville_Homes

ALTER TABLE CleaningPTP.dbo.Nashville_Homes
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate