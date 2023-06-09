create Database QuanLyQuanCaPhe
go

use QuanLyQuanCaPhe
go 

-- Food
-- Table
-- Bill
-- Account
-- FoodCategory
-- Billinfo

Create TABLE Tablefood
(
	id INT IDENTITY PRIMARY KEY,
	name Nvarchar(100) Not null Default N'Bàn chưa có tên',
	status nvarchar(100) Not null Default N'Trống'-- Trống || Có người
)
GO

Create TABLE Account
(
	UserName Nvarchar(100) primary key,
	Displayname nvarchar(100) Not null Default N'Trần Văn Phong',
	Password Nvarchar(1000) Not null default 0,
	Type int Not null -- 1 là admin , 0 là staff
)
Go

Create Table FoodCategory
(
	id INT IDENTITY PRIMARY KEY,
	NAME NVARCHAR(100) Not null default N'Chưa đặt tên'
	)
Go

Create table Food
(
	id INT IDENTITY PRIMARY KEY,
	NAME NVARCHAR(100) NOT NULL Default N'Chưa đặt tên',
	IDCATEGORY INT NOT NULL,
	price Float Not null default 0
	Foreign key (idCategory) references dbo.FoodCategory(id)
)
Go

Create table bill
(
	id int identity primary key,
	DateCheckIn Date NOT NULL default getDate(),
	DateCheckOut Date,
	idTable int NOT NULL,
	status  int Not null Default 0,  -- 1 là đã thanh toán , 0 là chưa thanh toán
	discount int,
	TotalPrice int,
	Foreign key (idTable) references dbo.TableFood(id)
)
Go
Create table billinfo
(
	id int identity primary key,
	idBill int Not Null,
	idFood int not null,
	Count int not null Default 0
	Foreign key (idBill) references dbo.Bill(id),
	Foreign key (idFood) references dbo.Food(id)
)
Go


Create Proc USP_Login
@userName nvarchar(100) , @passWord nvarchar(100)
as
Begin
	Select * from dbo.Account where UserName = @userName and Password = @passWord
End
Go

--thêm bàn



Create proc USP_GetTableList
As select * from dbo.Tablefood
go


create proc  USP_InsertBill
@idTable Int
As
Begin
	Insert dbo.Bill(DateCheckIn,DateCheckOut,idTable,status,discount)
	Values (GETDATE(),Null,@idTable,0,0)

End
Go 

Create proc  USP_InsertBillInfo
@idBill Int,@idFood int, @count int
As
Begin
	Declare @isExitBillInfo int
	Declare @foodCount int = 1
	Select @isExitBillInfo = id, @foodCount = count from dbo.BillInfo where idBill = @idBill and idFood = @idFood

	if(@isExitBillInfo>0)
	Begin
		Declare @newCount int = @foodCount + @count
		if(@newCount>0)
		Update dbo.billinfo set count = @foodCount + @count where idFood = @idFood and idBill = @idBill
		else
		Delete dbo.billinfo where idBill = @idBill and idFood = @idFood
	End
	else 
	begin
		insert dbo.billinfo(idBill,idFood,Count)
		Values (@idBill,@idFood,@count)
	end

End
Go 


create Trigger UTG_UpdateBillInfo
On dbo.BillInfo for insert, update
as
begin
	Declare @idBill int
	Select @idBill = idBill From Inserted
	Declare @idTable int
	Select @idTable = idTable From dbo.Bill where id = @idBill and status = 0
	Declare @count int
	select @count = Count(*) from dbo.billinfo where idBill = @idbill
	if(@count > 0)
	update dbo.TableFood set status = N'Có người' where id = @idTable
	else
	update dbo.TableFood set status = N'Trống' where id = @idTable
	
end
go

Create Trigger UTG_UpdateTable 
on dbo.TableFood for update 
as 
begin
	declare @idTable int 
	Declare @status Nvarchar(100)
	Select @idTable = id,@status = inserted.status from inserted
	Declare @idBill int 
	Select @idBill = id from dbo.Bill where idTable = @idTable and status = 0
	declare @countBillInfo int
	Select @countBillInfo = Count(*) from dbo.billinfo where idBill = @idBill
	if(@countBillInfo>0 and @status <> N'Có người') 
		update dbo.Tablefood set status = N'Có người' where id = @idTable
	else if(@countBillInfo <= 0 and @status <> N'Trống')
		Update dbo.Tablefood set status = N'Trống' where id = @idTable  
	 
end
go

Create Trigger UTG_UpdateBill
On dbo.Bill for update
as
begin
	Declare @idBill int
	Select @idBill = id From Inserted
	Declare @idTable int
	Select @idTable = idTable From dbo.Bill where id = @idBill
	Declare @count int = 0
	Select @count = count(*) from dbo.Bill where idTable = @idTable and status = 0
	if(@count =0)
		update dbo.TableFood set status = N'Trống' where id = @idTable
	

end
go


create proc USP_SwitchTable
@idTable1 int , @idTable2 int
as
begin

	Declare @idFirstBill int
	Declare @idSecondBill int
	Declare @isFirstTableEmty int = 1
	Declare @isSecondTableEmty int = 1
	Select @idFirstBill=id from dbo.Bill where idTable = @idTable1 and Status = 0
	Select @idSecondBill=id from dbo.Bill where idTable = @idTable2 and Status = 0

	if(@idFirstBill is null)
	Begin
		insert into dbo.bill(DateCheckIn,DateCheckOut,idTable,status)
		Values(getdate(),null,@idTable1,0)
		Select @idFirstBill = Max(id) from dbo.Bill where idTable = @idTable1 and Status = 0
	
	End

	select @isFirstTableEmty = count(*) from dbo.billinfo where idBill = @idFirstBill

	if(@idSecondBill is null)
	Begin
		insert into dbo.bill(DateCheckIn,DateCheckOut,idTable,status)
		Values(getdate(),null,@idTable2,0)
		Select @idSecondBill = Max(id) from dbo.Bill where idTable = @idTable2 and Status = 0

	End
	select @isSecondTableEmty = count(*) from dbo.billinfo where idBill = @idSecondBill

	Select id into IDBillInfoTable from dbo.billinfo where idBill = @idSecondBill

	update dbo.billinfo set idBill = @idSecondBill where idBill = @idFirstBill

	update dbo.billinfo set idBill = @idFirstBill where id in (select * from IDBillInfoTable)

	drop table IDBillInfoTable
	if(@isFirstTableEmty = 0) update dbo.Tablefood set status = N'Trống' where id = @idTable2
	if(@isSecondTableEmty = 0) update dbo.Tablefood set status = N'Trống' where id = @idTable1
end
go


create proc USP_GetListBillByDate
@checkin date,@checkout date
as
begin
	select t.name as [Tên bàn], b.TotalPrice as [Tổng tiền], DateCheckIn as [Ngày vào],DateCheckOut as [Ngày ra],discount as [Giảm giá]
from dbo.bill as b,  dbo.TableFood as t
where datecheckin > =@checkin and DateCheckOut <= @checkout and b.status = 1
and t.id = b.idTable 
end
go

create Proc USP_UpdateAccount
@userName Nvarchar(100), @displayName nvarchar(100), @password nvarchar(100), @newpassword nvarchar(100)
as
begin
	Declare @isRightPass int
	select @isRightPass = Count(*) from dbo.Account where userName = @userName and PassWord = @password
	if(@isRightPass =1 )
	begin
		if(@newpassword = null or @newpassword = '')
		begin
			update dbo.Account set Displayname = @displayName where username = @userName
		end
		else update dbo.Account set Displayname = @displayName, Password = @newpassword where userName = @userName
	end
end
go

create trigger UTG_DeleteBillInfo1
on dbo.BillInfo for delete 
as
begin
	Declare @idBillInfo int
	Declare @idBill int
	select @idBillInfo=id , @idBill = Deleted.idBill from Deleted
	declare @idTable int 
	select @idTable = idTable from dbo.Bill where id = @idBill

	Declare @count int = 0
	Select @count = count(*) from dbo.BillInfo as bi,dbo.Bill as b where b.id = bi.idBill and b.id = @idBill and b.status = 0
	if(@count = 0)
		update dbo.TableFood set status = N'Trống' where id = @idTable
end
go


CREATE FUNCTION [dbo].[fuConvertToUnsign1]
(
 @strInput NVARCHAR(4000)
)
RETURNS NVARCHAR(4000)
AS
BEGIN 
 IF @strInput IS NULL RETURN @strInput
 IF @strInput = '' RETURN @strInput
 DECLARE @RT NVARCHAR(4000)
 DECLARE @SIGN_CHARS NCHAR(136)
 DECLARE @UNSIGN_CHARS NCHAR (136)
 SET @SIGN_CHARS = N'ăâđêôơưàảãạáằẳẵặắầẩẫậấèẻẽẹéềểễệế
 ìỉĩịíòỏõọóồổỗộốờởỡợớùủũụúừửữựứỳỷỹỵý
 ĂÂĐÊÔƠƯÀẢÃẠÁẰẲẴẶẮẦẨẪẬẤÈẺẼẸÉỀỂỄỆẾÌỈĨỊÍ
 ÒỎÕỌÓỒỔỖỘỐỜỞỠỢỚÙỦŨỤÚỪỬỮỰỨỲỶỸỴÝ'
 +NCHAR(272)+ NCHAR(208)
 SET @UNSIGN_CHARS = N'aadeoouaaaaaaaaaaaaaaaeeeeeeeeee
 iiiiiooooooooooooooouuuuuuuuuuyyyyy
 AADEOOUAAAAAAAAAAAAAAAEEEEEEEEEEIIIII
 OOOOOOOOOOOOOOOUUUUUUUUUUYYYYYDD'
 DECLARE @COUNTER int
 DECLARE @COUNTER1 int
 SET @COUNTER = 1
 WHILE (@COUNTER <=LEN(@strInput))
 BEGIN 
 SET @COUNTER1 = 1
 WHILE (@COUNTER1 <=LEN(@SIGN_CHARS)+1)
 BEGIN
 IF UNICODE(SUBSTRING(@SIGN_CHARS, @COUNTER1,1))
 = UNICODE(SUBSTRING(@strInput,@COUNTER ,1) )
 BEGIN 
 IF @COUNTER=1
 SET @strInput = SUBSTRING(@UNSIGN_CHARS, @COUNTER1,1)
 + SUBSTRING(@strInput, @COUNTER+1,LEN(@strInput)-1) 
 ELSE
 SET @strInput = SUBSTRING(@strInput, 1, @COUNTER-1)
 +SUBSTRING(@UNSIGN_CHARS, @COUNTER1,1)
 + SUBSTRING(@strInput, @COUNTER+1,LEN(@strInput)- @COUNTER)
 BREAK
 END
 SET @COUNTER1 = @COUNTER1 +1
 END
 SET @COUNTER = @COUNTER +1
 END
 SET @strInput = replace(@strInput,' ','-')
 RETURN @strInput
END


create proc USP_GetListBillByDateAndPage
@checkin date,@checkout date,@page int
as
begin
	declare @pageRows int =10 
	Declare @selectRows int = @pageRows
	Declare @exceptRows int = (@page -1)*@pageRows

	;with BillShow as(select b.id, t.name as [Tên bàn], b.TotalPrice as [Tổng tiền], DateCheckIn as [Ngày vào],DateCheckOut as [Ngày ra],discount as [Giảm giá]
	from dbo.bill as b,  dbo.TableFood as t
	where datecheckin > =@checkin and DateCheckOut <= @checkout and b.status = 1
	and t.id = b.idTable)

	select top (@selectRows) * from BillShow where id not in (select top (@exceptRows) id from BillShow)
	
end
go

create proc USP_GetNumBillByDate
@checkin date,@checkout date
as
begin
	select count(*)
	from dbo.bill as b,  dbo.TableFood as t
	where datecheckin > =@checkin and DateCheckOut <= @checkout and b.status = 1
	and t.id = b.idTable 
end
go

INSERT [dbo].[Account] ([UserName], [Displayname], [Password], [Type]) VALUES (N'admin01', N'Trần Văn Phong', N'1', 1)
INSERT [dbo].[Account] ([UserName], [Displayname], [Password], [Type]) VALUES (N'nv01', N'Quang Sinh', N'1', 0)
INSERT [dbo].[Account] ([UserName], [Displayname], [Password], [Type]) VALUES (N'nv02', N'Hoàng Tú', N'1', 0)

GO


SET IDENTITY_INSERT [dbo].[FoodCategory] ON 
INSERT [dbo].[FoodCategory] ([id], [NAME]) VALUES (1, N'Cà Phê')
INSERT [dbo].[FoodCategory] ([id], [NAME]) VALUES (2, N'Trà Sữa')
INSERT [dbo].[FoodCategory] ([id], [NAME]) VALUES (3, N'Nước Ngọt')
INSERT [dbo].[FoodCategory] ([id], [NAME]) VALUES (4, N'Bánh')
SET IDENTITY_INSERT [dbo].[FoodCategory] OFF
GO

SET IDENTITY_INSERT [dbo].[Food] ON 
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (1, N'Cà Phê Phin', 1, 25000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (2, N'Cà Phê', 1, 20000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (3, N'Cà Phê Sữa Đá', 1, 25000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (4, N'Trà Sữa Chân Châu', 2, 30000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (5, N'Trà Sữa MatCha', 2, 35000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (6, N'Trà Sữa Đường Đen', 2, 30000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (7, N'7Up', 3, 15000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (8, N'Sting', 3, 15000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (9, N'Pepsi', 3, 15000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (10, N'Coca-cola', 3, 15000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (11, N'Bánh Mì Que', 4, 25000)
INSERT [dbo].[Food] ([id], [NAME], [IDCATEGORY], [price]) VALUES (12, N'Bánh Phô Mai', 4, 25000)
SET IDENTITY_INSERT [dbo].[Food] OFF
GO


SET IDENTITY_INSERT [dbo].[Tablefood] ON 
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (1, N'Bàn 0', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (2, N'Bàn 1', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (3, N'Bàn 2', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (4, N'Bàn 3', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (5, N'Bàn 4', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (6, N'Bàn 5', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (7, N'Bàn 6', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (8, N'Bàn 7', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (9, N'Bàn 8', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (10, N'Bàn 9', N'Trống')
INSERT [dbo].[Tablefood] ([id], [name], [status]) VALUES (11, N'Bàn 10', N'Trống')
SET IDENTITY_INSERT [dbo].[Tablefood] OFF
GO


SET IDENTITY_INSERT [dbo].[bill] ON 
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (1, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 1, 1, 0, 6119994)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (2, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 2, 1, 0, 2999997)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (3, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 1, 1, 0, 2999997)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (4, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 2, 1, 0, 75000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (5, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 3, 1, 0, 150000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (6, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 4, 1, 0, 120000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (7, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 1, 1, 0, 30000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (8, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 5, 1, 0, 90000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (9, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 7, 1, 0, 30000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (10, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 5, 1, 2, 29400)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (11, CAST(N'2022-08-19' AS Date), NULL, 7, 0, 0, NULL)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (12, CAST(N'2022-08-19' AS Date), CAST(N'2022-08-19' AS Date), 5, 1, 0, 30000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (13, CAST(N'2022-08-20' AS Date), NULL, 2, 0, 0, NULL)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (14, CAST(N'2022-08-20' AS Date), NULL, 6, 0, 0, NULL)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (15, CAST(N'2022-08-20' AS Date), NULL, 5, 0, NULL, NULL)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (16, CAST(N'2022-08-20' AS Date), NULL, 1, 0, NULL, NULL)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (17, CAST(N'2022-08-20' AS Date), CAST(N'2022-08-20' AS Date), 3, 1, 0, 40000)
INSERT [dbo].[bill] ([id], [DateCheckIn], [DateCheckOut], [idTable], [status], [discount], [TotalPrice]) VALUES (18, CAST(N'2022-08-20' AS Date), CAST(N'2022-08-20' AS Date), 3, 1, 0, 40000)
SET IDENTITY_INSERT [dbo].[bill] OFF
GO


SET IDENTITY_INSERT [dbo].[billinfo] ON 
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (10, 4, 2, 1)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (11, 4, 6, 1)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (12, 4, 11, 1)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (13, 12, 6, 1)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (14, 10, 9, 2)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (15, 18, 9, 1)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (16, 18, 8, 1)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (17, 17, 9, 1)
INSERT [dbo].[billinfo] ([id], [idBill], [idFood], [Count]) VALUES (18, 17, 12, 1)
SET IDENTITY_INSERT [dbo].[billinfo] OFF
GO