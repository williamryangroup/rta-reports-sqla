use ANI
go

exec dbo.aspnet_Users_DeleteUser @ApplicationName='ANI', @UserName='testuser', @TablesToDeleteFrom=15, @NumTablesDeletedFrom=0
go