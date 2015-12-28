# sql-sniffle
SQL Sniffle will contain useful scripts I have created to help me conquer and domesticate SQL-Server. The first
script added was **SQL Row Creator** which I created because I had to add rows into huge tables and I wanted
a quick way to handle it.

**On a side note...**
I only chose this name because GitHub suggested 'supreme-sniffle' which wasn't really advertising the SQL part of this project...

##Scripts
###SQL Row Creator
This script can be used to create an INSERT-statement for a table. Here is an example:

```SQL
--First create a table
CREATE TABLE [dbo].[User](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Age] [int] NOT NULL,
	[DateOfBirth] [datetime] NOT NULL,
	[Sallary] [money] NOT NULL,
	[AccountKey] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
```

Then run the script adding the name of the table, User, to the configuration at the beginning of the script. The output should look like this:

```SQL
INSERT INTO User
(
	Name, 
	Age, 
	DateOfBirth, 
	Sallary, 
	AccountKey

) 
VALUES
(
	'', --Name
	0, --Age
	'2015-12-28 11:49:01', --DateOfBirth
	0.00, --Sallary
	00000000-0000-0000-0000-000000000000--AccountKey

) 
```

As you can see the script has generated a well formatted INSERT-statement and it has added the name of the column to each of the values (this is configurable and can be removed). Just enter the values and you can insert your new user as quickly as, well, whatever.