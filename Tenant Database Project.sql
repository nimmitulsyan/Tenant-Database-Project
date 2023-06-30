CREATE TABLE [Tenancy_histories] 
(
	id INT IDENTITY(1,1),
	profile_id INT NOT NULL,
	house_id INT NOT NULL,
	move_in_date DATE NOT NULL,
	move_out_date DATE,
	rent INT NOT NULL,
	Bed_type VARCHAR(255),
	move_out_reason VARCHAR(255),
	CONSTRAINT tenancy_pk PRIMARY KEY (id),
	CONSTRAINT fk_profile_tenancy FOREIGN KEY (profile_id) REFERENCES Profiles (profile_id),
	CONSTRAINT fk_houses_tenancy FOREIGN KEY (house_id) REFERENCES Houses (house_id)
)

CREATE TABLE Profiles
(
	profile_id INT IDENTITY(1,1),
	first_name VARCHAR(255) ,
	last_name VARCHAR(255),
	email VARCHAR(255) NOT NULL,
	phone VARCHAR(255) NOT NULL,
	city VARCHAR(255),
	pan_card VARCHAR(255),
	created_at DATE NOT NULL,
	gender VARCHAR(255) NOT NULL,
	referral_code VARCHAR(255),
	marital_status VARCHAR(255),
	CONSTRAINT pk_profiles PRIMARY KEY (profile_id)
)

CREATE TABLE Houses
(
	house_id INT IDENTITY(1,1),
	house_type VARCHAR(255),
	bhk_details VARCHAR(255),
	bed_count INT NOT NULL,
	furnishing_type VARCHAR(255),
	Beds_vacant INT NOT NULL,
	CONSTRAINT pk_houses PRIMARY KEY (house_id)
)

CREATE TABLE Addresses
(
	ad_id INT IDENTITY (1,1),
	[name] VARCHAR(255),
	[description] TEXT ,
	pincode INT,
	city VARCHAR(255),
	house_id INT NOT NULL,
	CONSTRAINT pk_ad PRIMARY KEY (ad_id),
	CONSTRAINT fk_houses_addresses FOREIGN KEY (house_id) REFERENCES Houses (house_id)
)

CREATE TABLE Referrals
(
	ref_id INT IDENTITY(1,1),
	referrer_id INT NOT NULL,
	referrer_bonus_amount FLOAT,
	referral_valid TINYINT,
	valid_from DATE,
	valid_till DATE,
	CONSTRAINT pk_referrals PRIMARY KEY (ref_id),
	CONSTRAINT fk_profile_referrals FOREIGN KEY (referrer_id) REFERENCES Profiles (profile_id),
	CONSTRAINT validity CHECK (referral_valid=0 OR referral_valid=1)
)

CREATE TABLE Employment_details
(
	id INT IDENTITY(1,1),
	profile_id INT NOT NULL ,
	latest_employer VARCHAR(255),
	official_mail_id VARCHAR(255),
	yrs_experience INT,
	Occupational_category VARCHAR(255),
	CONSTRAINT pk_emp PRIMARY KEY (id),
	CONSTRAINT fk_profile_employment FOREIGN KEY (profile_id) REFERENCES Profiles (profile_id)
)

LOAD DATA INFILE 'F:/Simplilearn Certificate/Edvancer Data Analytics/SQL/Houses.csv'
INTO TABLE Houses
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE Tenancy_history ALTER COLUMN Move_In_Date DATE


Select * from Profiles$
Select * from Houses$
Select * from Tenancy_History
Select * from Addresses$
Select * from Employment_details$
Select * from Referral$

/*Write a query to get Profile ID, Full Name and Contact Number of the tenant 
who has stayed with us for the longest time period in the past*/
SELECT p.profile_id [Profile ID], p.first_name+' '+ p.last_name AS [Full Name], p.phone [Contact Number]
FROM Tenancy_History t
Inner JOIN Profiles$ p
ON p.profile_id=t.profile_id
WHERE DATEDIFF(d,t.move_in_date,t.move_out_date)=(SELECT MAX(DATEDIFF(d,move_in_date,move_out_date)) FROM Tenancy_History);

/*Write a query to get the Full name, email id, phone of tenants who are married and paying
rent > 9000 using subqueries */
SELECT p.first_name+' '+ p.last_name AS [Full Name], p.email_id [Email id], p.phone Phone
FROM Profiles$ p
WHERE p.marital_status='Y' 
AND p.profile_id IN (Select t.profile_id FROM Tenancy_History t WHERE t.rent>9000);

/*Write a query to get the house details of the house having highest occupancy*/
SELECT h.house_id, h.house_type, h.bhk_type, h.furnishing_type, h.bed_count-h.beds_vacant [Maximum Occupancy]
FROM Houses$ h
WHERE h.bed_count-h.beds_vacant=(SELECT MAX(bed_count-beds_vacant) FROM Houses$)

/*Write a query to display profile id, full name, phone, email id, city , house id, move_in_date ,
move_out date, rent, total number of referrals made, latest employer and the occupational
category of all the tenants living in Bangalore or Pune in the time period of jan 2015 to jan
2016 sorted by their rent in descending order*/
Select p.profile_id, p.first_name+' '+ p.last_name AS [Full Name], p.phone [Phone], p.email_id, 
t.house_id, t.Move_In_Date, t.Move_Out_Date, t.rent,
e.latest_employer, e.occupational_category, rs.[Total Number of Referrals]
FROM Profiles$ p 
Join Tenancy_History t
on p.profile_id=t.profile_id
join Employment_Details$ e
ON p.profile_id=e.profile_id
join (Select r.profile_id, sum(r.referral_valid) AS [Total Number of Referrals]
FROM Referral$ r
GRoup by r.profile_id) rs
on p.profile_id=rs.profile_id
WHERE (p.city='Pune' or p.city='Bangalore')
AND (t.move_in_date>= '01 Jan 2015' and t.move_in_date<= '01 Jan 2016'
AND t.move_out_date>= '01 Jan 2015' and t.move_out_date<= '01 Jan 2016')
ORDER BY rent DESC;


Select * from Referral$

/*Write a sql snippet to find the full_name, email_id, phone number and referral code of all
the tenants who have referred more than once.
 Also find the total bonus amount they should receive given that the bonus gets calculated
only for valid referrals.*/ 
Select p.first_name+' '+ p.last_name AS [Full Name], p.phone , p.email_id, p.referral_code, rp.[Bonus Amount]
From Profiles$ p
JOIN (
Select r.profile_id , sum(r.referrer_bonus_amount) AS [Bonus Amount]
FROM Referral$ r
WHERE r.referral_valid=1
Group by r.profile_id
Having sum(r.profile_id)>1 ) rp
ON p.profile_id=rp.profile_id;

/*Write a query to find the rent generated from each city and also the total of all cities*/
Select ISNULL(p.city, 'Grand Total') AS [City] , sum(t.rent) AS [Total rent]
from Tenancy_History t
join Profiles$ p
on p.profile_id=t.profile_id
group by ROLLUP(p.city)

/*Create a view 'vw_tenant' find
profile_id,rent,move_in_date,house_type,beds_vacant,description and city of tenants who
shifted on/after 30th april 2015 and are living in houses having vacant beds and its address.*/
CREATE VIEW vw_tenant
AS
SELECT t.profile_id, t.rent, t.Move_In_Date, h.house_type, h.beds_vacant, a.description, a.city [House Address], p.city [City of Tenant]
FROM Tenancy_History t 
Join Profiles$ p
ON t.profile_id=p.profile_id
join Houses$ h
on t.house_id=h.house_id
Inner join Addresses$ a
on h.house_id=a.house_id
WHERE t.Move_In_Date>='30 Apr 2015' 
AND h.beds_vacant>0

Select * from vw_tenant

/*Write a code to extend the valid_till date for a month of tenants who have referred more
than two times*/
Update  referral$
set  valid_till=DATEADD(month, 1, valid_till)
where profile_id IN (
Select r.profile_id 
FROM Referral$ r
Group by r.profile_id
Having count(r.profile_id)>2)

Select * from Referral$;

/*Write a query to get Profile ID, Full Name , Contact Number of the tenants along with a new
column 'Customer Segment' wherein if the tenant pays rent greater than 10000, tenant falls
in Grade A segment, if rent is between 7500 to 10000, tenant falls in Grade B else in Grade C*/
Select p.profile_id, p.first_name+' '+ p.last_name AS [Full Name], p.phone [Contact Number], 
IIF(t.rent>10000, 'Grade A', IIF(t.rent>=7500, 'Grade B', 'Grade C')) AS [Customer Segment]
from Profiles$ p
Join Tenancy_History t
on p.profile_id=t.profile_id;


/*Write a query to get Fullname, Contact, City and House Details of the tenants who have not
referred even once*/
Select   p.first_name+' '+ p.last_name AS [Full Name], p.phone Contact, p.city, h.*
from Profiles$ p
join Tenancy_History t
on p.profile_id=t.profile_id
join Houses$ h
on t.house_id=h.house_id
where p.profile_id NOT IN (
Select Distinct r.profile_id 
FROM Referral$ r);



