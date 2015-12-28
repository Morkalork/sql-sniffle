--#################################################################################
--#                                                                               #
--#  / ___| / _ \| |     |  _ \ _____      __  / ___|_ __ ___  __ _| |_ ___  _ __ #
--#  \___ \| | | | |     | |_) / _ \ \ /\ / / | |   | '__/ _ \/ _` | __/ _ \| '__|#
--#   ___) | |_| | |___  |  _ < (_) \ V  V /  | |___| | |  __/ (_| | || (_) | |   #
--#  |____/ \__\_\_____| |_| \_\___/ \_/\_/    \____|_|  \___|\__,_|\__\___/|_|   #
--#  Written by Magnus Ferm, No rights reserved                                   #
--#  A part of SQL-Sniffle                                                        #
--#                                                                               #
--#  This is a tool that can be used to generate an insert script for a           #
--#  particular table in a database.                                              #
--#################################################################################



--###	SETTINGS	###--
DECLARE @TableName NVARCHAR(255) = N'olh'   --SET THIS TO YOUR TABLE NAME
DECLARE @AddColumnNameComment INT = 1		--0 false, 1 true
DECLARE @TakeOnlyRequiredColumns INT = 1	--0 false, 1 true


--###	APPLICATION	###---
--Declarations
DECLARE @Sql NVARCHAR(MAX)
DECLARE @Cursor	CURSOR
DECLARE @CurrentColumnName VARCHAR(255)
DECLARE @ColumnName VARCHAR(255)
DECLARE @ColumnType VARCHAR(255)
DECLARE @Query VARCHAR(MAX)
DECLARE @Insert VARCHAR(MAX)
DECLARE @Values VARCHAR(MAX)

--Initial settings
SET NOCOUNT ON
SET @Query = 'INSERT INTO ' + @TableName + CHAR(13)
SET @Insert = '(' + CHAR(13)
SET @Values = '(' + CHAR(13)

IF OBJECT_ID(N'tempdb.dbo.#information', 'U') IS NOT NULL
  DROP TABLE #information; 

CREATE TABLE #information (name NVARCHAR(255), system_type_id int)

SET @Sql = N'
	INSERT INTO #information (name, system_type_id)
	SELECT c.name as name, c.system_type_id as system_type_id
	FROM sys.tables t
	INNER JOIN sys.columns c
		ON c.object_id = t.object_id
	WHERE t.name = ''' + @TableName +
	''' AND c.is_nullable = 0 '

IF @TakeOnlyRequiredColumns = 1
BEGIN
	SET @Sql = @Sql + N'AND c.is_identity = 0 '
END

EXEC sp_executesql @Sql

--Execution
SET @Cursor = CURSOR FOR
SELECT name, system_type_id FROM #information

OPEN @Cursor

--Fetch an initial column name
FETCH NEXT FROM @Cursor
INTO @ColumnName, @ColumnType

WHILE @@FETCH_STATUS = 0
BEGIN
	--Add the column name to the insert statement
	SET @CurrentColumnName = @ColumnName
	SET @Insert = @Insert + CHAR(9) + @CurrentColumnName

	--Let's add a value as well
	IF (@ColumnType = 48 OR @ColumnType = 52 OR @ColumnType = 56
		OR @ColumnType = 127)	--Smallint, tiny int, int, bigint
	BEGIN
		SET @Values = @Values + CHAR(9) + '0'
	END
	ELSE IF (@ColumnType = 40 OR @ColumnType = 61 OR @ColumnType = 42)	--Date, DateTime, DateTime2
	BEGIN
		SET @Values = @Values + CHAR(9) + '''' + CONVERT(VARCHAR(25), GETDATE(), 120) + ''''
	END
	ELSE IF (@ColumnType = 60 OR @ColumnType = 62 OR @ColumnType = 106
			 OR @ColumnType = 108) --Money, Float, Decimal, Numeric	
	BEGIN
		SET @Values = @Values + CHAR(9) + '0.00'
	END
	ELSE IF (@ColumnType = 36) --Unique identifier
	BEGIN
		SET @Values = @Values + CHAR(9) + '00000000-0000-0000-0000-000000000000'
	END
	ELSE IF (@ColumnType = 189)	--Timestamp
	BEGIN
		SET @Values = @Values + CHAR(9) + CURRENT_TIMESTAMP
	END
	ELSE
	BEGIN
		SET @Values = @Values + CHAR(9) + ''''''
	END

	--Let's see if we can find another column name
	FETCH NEXT FROM @Cursor
	INTO @ColumnName, @ColumnType

	IF @@FETCH_STATUS = 0
	BEGIN
		--So, if fetch status is ok (that means we found something after the
		--one we just added) we'll need another comma
		SET @Insert = @Insert + ', '
		SET @Values = @Values + ', '
	END

	IF @AddColumnNameComment = 1
	BEGIN
		SET @Values = @Values + '--' + @CurrentColumnName
	END

	SET @Insert = @Insert + CHAR(13)
	SET @Values = @Values + CHAR(13)
END

SET @Insert = @Insert + CHAR(13) + ') '
SET @Values = @Values + CHAR(13) + ') '
SET @Query = @Query + @Insert + CHAR(13) + 'VALUES' + CHAR(13) + @Values

PRINT @Query

CLOSE @Cursor
DEALLOCATE @Cursor
DROP TABLE #information
SET NOCOUNT OFF