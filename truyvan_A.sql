﻿--VIEW


--View học sinh của lớp
create view v_studentsOfClass(CLassID, ClassName, UserID, Name, Birth, Gender, Address, Avatar)
as select c.CLassID, c.ClassName, u.UserID, p.ProName, p.ProBirth, p.ProGender, p.ProAddress, p.ProAva
from class as c, users as u, profiles as p 
where c.ClassID = u.ClassID and u.UserID = p.UserID

select * from v_studentsOfClass

--2.Tạo view v_scoresOfStudent để hiển thị thông tin của học sinh và môn học gồm UserID, UserName, ClassName, SubjectName, SubjectType,
-- cofe_one, Coef_two, Cofe_three, Summary, Conduct
create view v_scoresOfStudent(UserID, UserName, ClassID, ClassName, SubjectID, SubjectName, SubjectType, Coef_one, Coef_two, Coef_three, Summary)
as
	select u.UserID, u.UserName, c.ClassID, ClassName, sb.SubjectID, sb.SubjectName, sb.SubjectType, st.Coef_one, st.Coef_two, 
			st.Coef_three, st.Summary
	from users as u, class as c, subjects as sb, study as st
	where u.ClassID=c.ClassID and st.UserID=u.UserID and st.SubjectID=sb.SubjectID


select * from v_scoresOfStudent



--FUNCTION

--1.Viết một hàm f_DiemTrungBinh trả về một bảng chi tiết họ tên, lớp, số điểm trung bình của 1 học sinh 
	--với DiemTrungBinh = ((Coef_one * 1 + Coef_two * 2 + Coef_three * 3)/6)
	--với UserID là tham số truyền vào
create function f_DiemTrungBinh (@UserID varchar(4), @SubjectID varchar(10))
returns float
as
	begin
		declare @DiemTrungBinh float
		select @DiemTrungBinh = ((Coef_one * 1 + Coef_two * 2 + Coef_three * 3)/6)
		from study where UserID=@UserID and SubjectID = @SubjectID
		return @DiemTrungBinh
	end

select dbo.f_DiemTrungBinh('1001', 'toan10')


--2.Viết một hàm f_DiemTrungBinh trả về một bảng chi tiết họ tên, lớp, điểm số 1, điểm số 2, điểm số 3 và số điểm trung bình của 1 học sinh 
	--với UserID là tham số truyền vào
create function f_Diem(@UserID nvarchar(4))
returns @Diem table(HoVaTen nvarchar(60), Mon nvarchar(20), Lop nvarchar(10), Coef_one float, Coef_tow float, Coef_three float, DiemTrungBinh float)
as
	begin
		insert into @Diem
		select UserName, SubjectID, ClassName, Coef_one, 
		Coef_two, Coef_three, dbo.f_DiemTrungBinh(UserID, SubjectID)
		from v_scoresOfStudent where UserID=@UserID;
		return
	end

select * from dbo.f_Diem('1001')


-- Hàm đếm sĩ số của lớp tham số truyền vào là 1 ID lớp
create function f_SiSoHocSinh(@ClassID varchar(10))
returns int
as
begin
	declare @SiSo int;
	select @SiSo = count(*) from users where ClassID = @ClassID;
	return @SiSo
end
	
select dbo.f_SiSoHocSinh('2020A1')

select * from dbo.f_SiSoHocSinh()
drop function f_SiSoHocSinh


--PROCEDURE
--1. Thủ tục lấy ra sĩ số của các lớp có sĩ số < x(với x là đầu vào) dưới dạng con trỏ
Create procedure sp_SiSoNhieu
@SiSo int, @dsss cursor varying output
as begin
set @dsss=cursor for
	select ClassID, ClassName, ClassGrade, SiSo = dbo.f_SiSoHocSinh(ClassID) from Class where dbo.f_SiSoHocSinh(ClassID) <= @SiSo order by SiSo asc
open @dsss
end

declare @contro_sp cursor;
exec sp_SiSoNhieu 0, @contro_sp out;
Fetch Next from @contro_sp
begin
	Fetch Next from @contro_sp
end
close @contro_sp
deallocate @contro_sp

--2.Viết 1 thủ tục số lượng tin nhắn đã đc gửi đi & nhận về từ ngày nào đó -> ngày
Create proc sp_SoLuongTinNhan
 @UserID nvarchar(4), @NgayDau date, @NgayCuoi date, @TongTinNhan int out
 as 
	begin
		Select @TongTinNhan = Count(*) from messenger 
		where FromID = @UserID and MessTime>=@ngaydau and MessTime<=@ngaycuoi
	end
 
 declare @tn1 int;
 exec sp_SoLuongTinNhan '1001', '2021-1-12', '2021-12-12', @tn1 out
 print 'Số lượng tin nhắn là: ' +  @tn1

 drop proc sp_SoLuongTinNhan


 --TRIGGER
 
-- Xóa user -> xóa profile, xóa message
-- Học sinh -> xóa điểm
-- Giáo viên -> xóa teach
 create trigger del_user
on users
instead of delete as
	begin
		print N'Xóa thành công'
		declare @UserID varchar(4), @Role Nvarchar(20);
		select @UserID = UserID, @Role = UserRole from deleted;

		delete from profiles where UserID = @UserID;
		delete from messenger where FromID = @UserID or ToID = @UserID;
		if @Role = N'Học sinh'
			begin
				delete from study where UserID = @UserID;
			end
		else if @Role = N'Giáo viên'
			begin
				delete from teach where UserID = @UserID;
			end
		delete from users where UserID = @UserID;
	end

delete from users where UserName = 'haicaiten'


-- Sua diem -> sua lai tong diem
create trigger update_scores
on study
after update as
	begin
		print N'Cập nhật điểm thành công'
		update study set summary = dbo.f_DiemTrungBinh(inserted.UserID, inserted.SubjectID) 
		from inserted where study.UserID = inserted.UserID and study.SubjectID = inserted.SubjectID;
	end

update study set Coef_one = 10, Coef_two = 9, Coef_three = 9 where UserID = '1001' and SubjectID = N'Toan10';

