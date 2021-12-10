USE tempdb
go
CREATE TABLE UserRole ( username sysname, rolename sysname, dbname sysname )
GO
DELETE FROM tempdb..UserRole
go
BEGIN
  DECLARE @sql VARCHAR(MAX)
  INSERT INTO tempdb..UserRole 
  SELECT member.name, role.name, @@SERVERNAME
    FROM sys.server_role_members  
    JOIN sys.server_principals AS role  
      ON sys.server_role_members.role_principal_id = role.principal_id   
    JOIN sys.server_principals AS member  
      ON sys.server_role_members.member_principal_id = member.principal_id
   WHERE member.is_disabled = 0 AND ( member.Name NOT IN ( 'sa' ) AND member.Name NOT LIKE 'NT SERVICE%' AND member.Name NOT LIKE 'NT AUTHORITY%' )
   ORDER BY 1,2

  SELECT @sql = 'USE ?;'
              + 'insert into tempdb..UserRole '
              + 'SELECT s.name, r.name, ''?''' 
              + '  FROM sys.database_principals r'
              + '  JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id'
              + '  JOIN sys.database_principals u ON m.member_principal_id = u.principal_id'
              + '  JOIN sys.server_principals s ON s.sid = u.sid and s.is_disabled = 0'
              + '                              AND ( s.Name NOT IN ( ''sa'' ) AND s.Name NOT LIKE ''NT SERVICE%'' AND s.Name NOT LIKE ''NT AUTHORITY%'' )'
              + ' WHERE r.type = ''R'''
              + ' ORDER BY 1,2'

  exec sp_MSforeachdb @Command1 = @sql
END
go
SELECT * FROM tempdb..UserRole ORDER BY 1
GO
DROP TABLE UserRole
go
