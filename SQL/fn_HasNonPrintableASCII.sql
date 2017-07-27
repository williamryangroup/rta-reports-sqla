USE [RTSS]
GO

/****** Object:  UserDefinedFunction [dbo].[HasNonPrintableASCII]    Script Date: 09/13/2016 11:06:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[HasNonPrintableASCII]') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION [HasNonPrintableASCII]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[HasNonPrintableASCII] 
(
    @nstring nvarchar(255)
)
RETURNS varchar(255)
AS
BEGIN

	DECLARE @result nvarchar(1) = 'N'
	DECLARE @nchar nvarchar(1)
	DECLARE @position int = 1

	WHILE @position <= LEN(@nstring)
	BEGIN
		SET @nchar = SUBSTRING(@nstring, @position, 1)
		IF UNICODE(@nchar) not between 32 and 127
			SET @result = 'Y'
		SET @position = @position + 1
	END
	
    RETURN @Result

END

GO


