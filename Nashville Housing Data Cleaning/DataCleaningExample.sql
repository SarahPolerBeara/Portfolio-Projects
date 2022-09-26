DROP table IF EXISTS NashvilleHousing ;

CREATE TABLE IF NOT EXISTS NashvilleHousing (
UniqueID VARCHAR(50),
ParcelID VARCHAR (50),
LandUse VARCHAR(50),
PropertyAddress VARCHAR(50),
SaleDate TIMESTAMP,
SalePrice VARCHAR(50),
LegalReference VARCHAR(50),
SoldAsVacant VARCHAR(50),
OwnerName VARCHAR(100),
OwnerAddress VARCHAR(50),
Acreage DECIMAL,
TaxDistrict VARCHAR(50),
LandValue DECIMAL,
BuildingValue DECIMAL,
TotalValue DECIMAL,
YearBuilt VARCHAR (50),
Bedrooms DECIMAL,
FullBath DECIMAL,
HalfBath DECIMAL
);


COPY NashvilleHousing
FROM '/Applications/PostgreSQL 13/Nashville Housing Data for Data Cleaning.csv' 
DELIMITER ',' 
CSV HEADER;

SELECT *
FROM NashvilleHousing;
-------------------------------------------------------------------------------------------------
--standardize sale date

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted=DATE(saledate);
---------------------------------------------------------------------------------------------------
--correct null addresses

--view rows with null addresses
SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;

--create join statement
SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, COALESCE(a.propertyaddress,b.propertyaddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.parcelid =b.parcelid
AND a.uniqueid<>b.uniqueid
WHERE a.propertyaddress IS NULL;

--update address based on parcelid
UPDATE NashvilleHousing
SET propertyaddress = COALESCE(a.propertyaddress,b.propertyaddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.parcelid =b.parcelid
AND a.uniqueid<>b.uniqueid
WHERE a.propertyaddress IS NULL;

--check
SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;
--returns nothing now, null vlaues removed

--------------------------------------------------------------------------------------------------
---break out proeprty address into address and city
SELECT 
substring(PropertyAddress, 1, strpos( PropertyAddress, ',')-1) AS address,
substring(PropertyAddress, strpos( PropertyAddress, ',')+1, LENGTH(PropertyAddress)) AS City
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress VARCHAR(50);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity VARCHAR(50);

UPDATE NashvilleHousing
SET PropertySplitAddress = substring(PropertyAddress, 1, strpos( PropertyAddress, ',')-1);

UPDATE NashvilleHousing
SET PropertySplitCity = substring(PropertyAddress, strpos( PropertyAddress, ',')+1, LENGTH(PropertyAddress));

--check
SELECT * 
FROM NashvilleHousing

--separate owner's address to address, city, and state
SELECT SPLIT_PART(owneraddress, ',',1),
SPLIT_PART(owneraddress, ',',2),
SPLIT_PART(owneraddress, ',',3)
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress VARCHAR(50);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity VARCHAR(50);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState VARCHAR(50);

UPDATE NashvilleHousing
SET OwnerSplitAddress = SPLIT_PART(owneraddress, ',',1);

UPDATE NashvilleHousing
SET PropertySplitCity = SPLIT_PART(owneraddress, ',',2);

UPDATE NashvilleHousing
SET PropertySplitCity = SPLIT_PART(owneraddress, ',',3);

SELECT *
FROM NashvilleHousing

-----------------------------------------------------------------------------------

--Change Y and N to Yes and No in SoldAsVacant field

--currently y, n, yes, and no
SELECT DISTINCT(SoldAsVacant)
FROM NashvilleHousing;

SELECT SoldAsVacant
,CASE WHEN SoldAsVacant = 'Y'THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'N0'
ELSE SoldAsVacant END
FROM NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y'THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
WHEN SoldAsVacant= 'N0' Then 'No'
ELSE SoldAsVacant END;

--check
SELECT DISTINCT(SoldAsVacant)
FROM NashvilleHousing

---------------------------------------------------------------------------------------------