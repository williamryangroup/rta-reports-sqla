USE [RTA_SQLA]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_String_To_Table]    Script Date: 07/09/2015 09:55:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_String_To_Table]') and OBJECTPROPERTY(id, N'IsTableFunction') = 1)
	DROP FUNCTION [fn_String_To_Table]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[fn_String_To_Table]
(
	@String VARCHAR(max),
	@Delimeter char(1),
	@TrimSpace bit
)
RETURNS 
@Table TABLE
(
	Val varchar(4000)
)
AS
BEGIN
	DECLARE @Val VARCHAR(4000)
	
	WHILE LEN(@String) > 0
	BEGIN
		SET @Val = LEFT(@String, ISNULL(NULLIF(CHARINDEX(@Delimeter, @String) - 1, -1), LEN(@String)))
        SET @String = SUBSTRING(@String, ISNULL(NULLIF(CHARINDEX(@Delimeter, @String), 0), LEN(@String)) + 1, LEN(@String))
		
		IF @TrimSpace = 1 Set @Val = LTRIM(RTRIM(@Val))
		
		INSERT INTO @Table ( [Val] ) VALUES ( @Val )
    END

	RETURN 
END


GO


