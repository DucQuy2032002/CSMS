using Đồ_Án.DTO;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Đồ_Án.DAO
{
    public class AccountDAO
    {
        private static AccountDAO Instance;

        public static AccountDAO Instance1 {
            get { if (Instance == null) Instance = new AccountDAO(); return Instance; }
            private set { Instance = value; } 
        }
        private AccountDAO() { }
        public bool Login(string userName,string passWord)
        {
            
            string query = "USP_Login @userName , @passWord";
            DataTable result = DataProvider.Instance.ExecuteQuery(query,new object[] {userName, passWord});
            return result.Rows.Count > 0;
        }

        public bool UpdateAccount(string userName,string displayName,string pass,string newPass)
        {
            int result = DataProvider.Instance.ExecuteNonQuery("exec USP_UpdateAccount @userName , @displayName , @password , @newpassword ",new object[] {userName,displayName,pass,newPass});

            return result > 0;
        }

        public DataTable GetListAccount()
        {
            return DataProvider.Instance.ExecuteQuery("Select Username, DisplayName, Type from account");
        }
        public Account GetAccountByUserName(string userName)
        {
            DataTable data = DataProvider.Instance.ExecuteQuery("Select * from account where userName ='" + userName+"'");
            foreach (DataRow item in data.Rows)
            {
                return new Account(item);
            }
            return null;
        }

        public bool InsertAccount(string name, string displayName,int Type)
        {
            if (CheckInsertAccountByName(name))
            {
                return false;
            }
            if(CheckInsertAccountByDisplayName(displayName))
            {
                return false;
            }
            if (CheckInsertAccountByDisplayName(name) == true && CheckInsertAccountByDisplayName(displayName) == true)
            {
                return false;
            }
            else
            {
                string query = string.Format("Insert dbo.Account(UserName,DisplayName,Type) Values (N'{0}',N'{1}',{2})", name, displayName, Type);
                int result = DataProvider.Instance.ExecuteNonQuery(query);
                return result > 0;
            }
        }

        public bool UpdateAccount(string name, string displayName, int Type)
        {
            string query = string.Format("update dbo.Account set DisplayName = N'{1}',Type = {2} where UserName = N'{0}'", name, displayName, Type);
            int result = DataProvider.Instance.ExecuteNonQuery(query);
            return result > 0;
        }

        public bool DeleteAccount(string name)
        {
            string query = string.Format("Delete Account where UserName = N'{0}'", name);
            int result = DataProvider.Instance.ExecuteNonQuery(query);
            return result > 0;
        }

        public bool ResetPassword(string name)
        {
            string query = string.Format("update account set password = N'0' where UserName = N'{0}'", name);
            int result = DataProvider.Instance.ExecuteNonQuery(query);
            return result > 0;
        }
        public bool CheckInsertAccountByName(string name)
        {
            var sqlconnectstring = @"Data Source=LAPTOP-OJIJN2TQ\SQLEXPRESS;Initial Catalog=QuanLyQuanCaPhe;Integrated Security=True";
            var connection = new SqlConnection(sqlconnectstring);
            connection.Open();
            using var command1 = new SqlCommand();
            command1.Connection = connection;
            string query1 = string.Format("Select username from dbo.Account where username = '{0}'", name);
            command1.CommandText = query1;
            using var reader1 = command1.ExecuteReader();
            if (reader1.HasRows)
            {
                return true;
            }
            else return false;
        }
        public bool CheckInsertAccountByDisplayName(string displayName)
        {
            var sqlconnectstring = @"Data Source=LAPTOP-OJIJN2TQ\SQLEXPRESS;Initial Catalog=QuanLyQuanCaPhe;Integrated Security=True";
            var connection = new SqlConnection(sqlconnectstring);
            connection.Open();
            using var command1 = new SqlCommand();
            command1.Connection = connection;
            string query1 = string.Format("Select displayname from dbo.Account where displayname = '{0}'", displayName);
            command1.CommandText = query1;
            using var reader1 = command1.ExecuteReader();
            if (reader1.HasRows)
            {
                return true;
            }
            else return false;
        }
    }
}
