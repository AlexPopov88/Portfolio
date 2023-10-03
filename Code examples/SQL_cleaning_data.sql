/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 100 *
FROM [PortfolioDB].[dbo].[Nashville_housing_data]

-----------------------------------------------------------------

--Set standart date format for "Sale Date" column
SELECT [Sale Date], CAST([Sale Date] AS date) Sale_Date_format 
FROM PortfolioDB.dbo.Nashville_housing_data;

ALTER TABLE dbo.Nashville_housing_data
ADD SaleDateFormat date;

UPDATE dbo.Nashville_housing_data
SET SaleDateFormat = CAST([Sale Date] AS date);


--Populate Property Address data
SELECT *
FROM dbo.Nashville_housing_data
WHERE [Property Address] IS NULL

UPDATE nhd_null_addr
SET [Property Address] = nhd_addr.[Property Address]
FROM dbo.Nashville_housing_data nhd_null_addr
JOIN dbo.Nashville_housing_data nhd_addr
	ON nhd_null_addr.[Parcel ID] = nhd_addr.[Parcel ID]
	AND nhd_addr.[Property Address] IS NOT NULL
WHERE nhd_null_addr.[Property Address] IS NULL


-- Breaking out Address into individual columns (House, City, State)
SELECT [Property Address], LEFT([Property Address], CHARINDEX(' ', [Property Address]))
FROM dbo.Nashville_housing_data
WHERE [Property Address] IS NOT NULL AND ISNUMERIC(LEFT([Property Address], CHARINDEX(' ', [Property Address]))) = 1
ORDER BY 2

ALTER TABLE dbo.Nashville_housing_data
ADD Apartment_Num int 

UPDATE dbo.Nashville_housing_data
SET Apartment_Num = LEFT([Property Address], CHARINDEX(' ', [Property Address]))
WHERE [Property Address] IS NOT NULL AND ISNUMERIC(LEFT([Property Address], CHARINDEX(' ', [Property Address]))) = 1


-- Owner Address
ALTER TABLE dbo.Nashville_housing_data
ADD Owner_Apartment_Num int 

UPDATE dbo.Nashville_housing_data
SET Owner_Apartment_Num = LEFT(Address, CHARINDEX(' ', Address))
WHERE Address IS NOT NULL AND ISNUMERIC(LEFT(Address, CHARINDEX(' ', [Property Address]))) = 1


-- DELETE INCORRECT DATA
--Rows without Parcel Id have incorrect data in each columns
DELETE FROM dbo.Nashville_housing_data
WHERE [Parcel ID] is null


-- Change Yes or No column for bit column
ALTER TABLE dbo.Nashville_housing_data
ADD Sold_As_Vacant_bit BIT;

UPDATE dbo.Nashville_housing_data
SET Sold_As_Vacant_bit = (CASE WHEN [Sold As Vacant] = 'Yes' THEN 1
							   WHEN [Sold As Vacant] = 'No' THEN 0
							   ELSE NULL END);


------- Remove Duplicates -----------
WITH RowNum AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY [Parcel ID], [Sale Date], [Legal Reference] ORDER BY F1) Row_num
	FROM dbo.Nashville_housing_data
	)

DELETE 
--SELECT *
FROM RowNum
WHERE Row_num > 1


--Delete duplicate and unused columns 
ALTER TABLE dbo.Nashville_housing_data
DROP COLUMN [Unnamed: 0], [Sale Date];


-- Result
SELECT TOP 100 *
FROM [PortfolioDB].[dbo].[Nashville_housing_data]

