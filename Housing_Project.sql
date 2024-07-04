-- Choose Our Database

USE Housing;


-- Show Our Data

SELECT * 
FROM Housing..Nashville;

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Show [Saledate] Column

SELECT SaleDate
FROM Housing..Nashville;


-- Convert [Saledate] Column Datatype into (Date)

-- In SQL Server, I can't directly change the Datatype of a column from a string (or another type) to a (date) Datatype using the [UPDATE] statement alone.
-- So, I creating a new column with the (date) Datatype, updating it with the converted values And drop my old column.

-- Step 1: Add a new column
ALTER TABLE Nashville
ADD SaleDateNew DATE;

-- Step 2: Update the new column with converted dates
UPDATE Nashville
SET SaleDateNew = CONVERT(DATE, SaleDate, 120);

-- Step 3: Drop the old column 
ALTER TABLE Nashville
DROP COLUMN SaleDate;

-- Step 4: Rename the new column to the original name
EXEC sp_rename 'Nashville.SaleDateNew', 'SaleDate', 'COLUMN';


-- -- Show Our Converted Column

SELECT SaleDate 
FROM Housing..Nashville;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Checking if i have Nulls in [PropertyAddress] Column

SELECT PropertyAddress 
FROM Housing..Nashville
WHERE PropertyAddress IS NULL;

-- After checking my data, I found few [ParcellID] is frequent, Therefore I have Nulls in [PropertyAddress] Column
-- So, I need to Populate these Nulls With these addresses that's already populated 
-- So, I will solve it by self join 

-- Show Nulls in [PropertyAddress] Column
SELECT a.ParcelID , a.PropertyAddress , b.ParcelID , b.PropertyAddress , ISNULL(a.PropertyAddress , b.PropertyAddress)
FROM Housing..Nashville a INNER JOIN Housing..Nashville b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> B.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Replace Nulls in [PropertyAddress] Column by addresses that's already populated
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress , b.PropertyAddress)
FROM Housing..Nashville a INNER JOIN Housing..Nashville b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> B.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Check Nulls again in [PropertyAddress] Column
SELECT a.ParcelID , a.PropertyAddress , b.ParcelID , b.PropertyAddress , ISNULL(a.PropertyAddress , b.PropertyAddress)
FROM Housing..Nashville a INNER JOIN Housing..Nashville b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> B.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Show [PropertyAddress] Column

SELECT PropertyAddress 
FROM Housing..Nashville;

-- I notice that [PropertyAddress] is a Column have (2) Columns inside but Separated by Commas 
-- So, I will break [PropertyAddress] Column into (2) Columns (Address , City)
-- So, I will solve it by Substring

-- I can Separate them like that

SELECT SUBSTRING(PropertyAddress , 1 , CHARINDEX(',' , PropertyAddress) -1) AS Property_Address ,
       LTRIM(SUBSTRING(PropertyAddress , CHARINDEX(',' , PropertyAddress) +1 , LEN(PropertyAddress))) AS Property_City
FROM Housing..Nashville;

-- Or like that

SELECT LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1) AS Property_Address,
       LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))) AS Property_City
FROM Housing..Nashville;

-- Or like that

SELECT LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1) AS Property_Address,
       SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress)) AS Property_City
FROM Housing..Nashville;



-- So, I add 2 New Columns to the table
ALTER TABLE Nashville
ADD Property_Address NVARCHAR(255), Property_City NVARCHAR(255);

-- Update the table with the split data
UPDATE Nashville
SET Property_Address = LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1),
      Property_City  = LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)));


-- Show [PropertyAddress] Column & Our 2 New Columns [Address , City]

SELECT PropertyAddress , Property_Address , Property_City 
FROM Housing..Nashville;


-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Show [OwnerAddress] Column

SELECT OwnerAddress 
FROM Housing..Nashville;


-- I also notice that [OwnerAddress] is a Column have (3) Columns inside but Separated by Commas 
-- So, I will break [OwnerAddress] Column into (3) Columns [Address , City, State]
-- So, I will solve it by Parsename

-- I can Separate them like that    -->  (Parsename : do with dots not Commas, so We replace Commas by dats first)

Select PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) AS Owner_Address ,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) AS Owner_City ,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) AS Owner_State
From Housing..Nashville;


-- So, I add 3 New Columns to the table
ALTER TABLE Nashville
ADD Owner_Address NVARCHAR(255), Owner_City NVARCHAR(255), Owner_State NVARCHAR(255);

-- Update the table with the split data
UPDATE Nashville
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) ,
    Owner_City    = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) ,
    Owner_State   = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


-- Show [PropertyAddress] Column & Our 2 New Columns (Address , City)

SELECT OwnerAddress , Owner_Address , Owner_City , Owner_State
FROM Housing..Nashville;


-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Show [SoldAsVacant] Column

SELECT SoldAsVacant
FROM Housing..Nashville;


-- Show Distinct Values in [SoldAsVacant] Column

SELECT DISTINCT(SoldAsVacant) , COUNT(SoldAsVacant)
FROM Housing..Nashville
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);


-- So, I need to Change (Y and N) to (Yes and No) in [SoldAsVacant] Column

-- I will using Case statement
SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END AS New
FROM Housing..Nashville;


-- -- Update the table with these changes 

UPDATE Nashville
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END;

-- Or i can Update the table by using (iif) function

UPDATE Nashville
SET SoldAsVacant = IIF(SoldAsVacant = 'Y', 'Yes', IIF(SoldAsVacant = 'N', 'No', SoldAsVacant));


-- Show Distinct Values in [SoldAsVacant] Column again to Check Changes

SELECT DISTINCT(SoldAsVacant) , COUNT(SoldAsVacant)
FROM Housing..Nashville
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);


-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Here, I want to Remove Duplicate rows
-- I solve it by using (CTE)

--Here, I can see all duplicated rows

WITH RowNumCTE AS(
							Select *,
							ROW_NUMBER() OVER (
							PARTITION BY ParcelID , PropertyAddress , SalePrice , SaleDate , LegalReference 
							ORDER BY UniqueID
				 ) row_num

From Housing..Nashville)

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress


-- Here, I will delete all duplicated rows

WITH RowNumCTE AS(
							Select *,
							ROW_NUMBER() OVER (
							PARTITION BY ParcelID , PropertyAddress , SalePrice , SaleDate , LegalReference 
							ORDER BY UniqueID
				 ) row_num

From Housing..Nashville)


DELETE
From RowNumCTE
Where row_num > 1


-- Check duplicated rows again 

WITH RowNumCTE AS(
							Select *,
							ROW_NUMBER() OVER (
							PARTITION BY ParcelID , PropertyAddress , SalePrice , SaleDate , LegalReference 
							ORDER BY UniqueID
				 ) row_num

From Housing..Nashville)

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress



-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Like i did before when I delete [SaleDate] after Creating new Column & put data on it 
-- I will do this again & Delete Unused Columns

-- Delete Unused Columns

ALTER TABLE Housing..Nashville
DROP COLUMN PropertyAddress , OwnerAddress, TaxDistrict


-- Show Final view of my data

Select *
From Housing..Nashville


