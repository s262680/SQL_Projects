/*
Data Cleaning Nashville Housing
*/

----Original Data for back up purpose

select * 
from DataCleaning.dbo.OgNashvilleHousing

-----------------------------------------------------------------------------------------------------------

----Standardise Date format
----Using Alter function to change data type

alter table DataCleaning.dbo.NashvilleHousing
alter column saledate date

----Verify the results

select saledate
from DataCleaning.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------

----Populate the propertyAddress column to replace the null values
----Rows that have the same parcelID also share the same address

update a
set a.PropertyAddress=b.PropertyAddress
from DataCleaning.dbo.NashvilleHousing as a
inner join DataCleaning.dbo.NashvilleHousing as b
on a.parcelID=b.ParcelID
and a.uniqueID!=b.UniqueID
where a.PropertyAddress is null

----Verify the results

select PropertyAddress
from DataCleaning.dbo.NashvilleHousing
where PropertyAddress is null

-----------------------------------------------------------------------------------------------------------

----Breaking address into 2 different columns using substring

alter table DataCleaning.dbo.NashvilleHousing
add Street nvarchar(255), City nvarchar(255)

update DataCleaning.dbo.NashvilleHousing
set Street = substring(PropertyAddress, 1, charindex(',', PropertyAddress)-1),
City = substring(PropertyAddress, charindex(',', PropertyAddress)+1, len(PropertyAddress))

----Verify the results

select propertyAddress, street, city
from DataCleaning.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------

----Breaking OwerAddress into 3 different columns

/*
----Easier way to separate columns by replace , with . by using PARSENAME 

select OwnerAddress,
PARSENAME(replace(OwnerAddress, ',', '.'), 3),
PARSENAME(replace(OwnerAddress, ',', '.'), 2),
PARSENAME(replace(OwnerAddress, ',', '.'), 1)
from DataCleaning.dbo.NashvilleHousing

*/

----using substring

alter table DataCleaning.dbo.NashvilleHousing
add OwnerStreet nvarchar(255), OwnerCity nvarchar(255), OwnerState nvarchar(255)

update DataCleaning.dbo.NashvilleHousing
set 
OwnerStreet = 
	substring(OwnerAddress, 
	1, 
	charindex(',', OwnerAddress)-1),
OwnerCity = 
	substring(OwnerAddress, 
	charindex(',', OwnerAddress)+2, 
	charindex(',', OwnerAddress, charindex(',', OwnerAddress) + 1) -charindex(',', OwnerAddress)-2),
OwnerState = 
	substring(OwnerAddress, 
	charindex(',', OwnerAddress, charindex(',', OwnerAddress) + 1) + 2, 
	len(OwnerAddress) - charindex(',', OwnerAddress, charindex(',', OwnerAddress) + 1) - 1)

----Verify the results

select owneraddress, OwnerStreet, OwnerCity, OwnerState 
from DataCleaning.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------

----Update the Y and N in soldasvacant column to Yes and No

update DataCleaning.dbo.NashvilleHousing
set soldasvacant =
	case 
		when soldasvacant= 'Y' then 'Yes'
		when soldasvacant= 'N' then 'No'
		else soldasvacant
	end

----Verify the results

select distinct(soldasvacant), count(soldasvacant)
from DataCleaning.dbo.NashvilleHousing
group by soldasvacant

-----------------------------------------------------------------------------------------------------------

----Remove duplicated rows

with duplicateCTE as 
(
	select *, ROW_NUMBER() 
	over (partition by parcelid, propertyaddress, saledate, saleprice, legalreference order by uniqueid) as duplicateCount
	from DataCleaning.dbo.NashvilleHousing
)

----Use select to verify the results first
----Delete from CTE also delete the records that it refers to

delete from duplicateCTE
where duplicateCount > 1

----Verify results

select parcelid, propertyaddress, saledate, saleprice, legalreference, count(*) as duplicateCount
from DataCleaning.dbo.NashvilleHousing
group by parcelid, propertyaddress, saledate, saleprice, legalreference
having count(*) >1

-----------------------------------------------------------------------------------------------------------

----Delete unnecessary columns

alter table DataCleaning.dbo.NashvilleHousing
drop column propertyaddress, owneraddress, taxdistrict

-----------------------------------------------------------------------------------------------------------

----Using view instead of modify the original table as good practice
----Creating a view which shows only required columns and without duplicated rows

use DataCleaning
go

alter view tempView as
with duplicateCTE as 
(
	select *, ROW_NUMBER() 
	over (partition by parcelid, propertyaddress, saledate, saleprice, legalreference order by uniqueid) as duplicateCount
	from DataCleaning.dbo.ogNashvilleHousing
)

select *
from duplicateCTE
where duplicateCount =1
go

select uniqueid, parcelid, propertyaddress, saleprice 
from tempView

-----------------------------------------------------------------------------------------------------------

