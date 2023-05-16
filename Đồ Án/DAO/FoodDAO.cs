using Đồ_Án.DTO;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Đồ_Án.DAO
{
    public class FoodDAO
    {
        
            private static FoodDAO instance;

            public static FoodDAO Instance
            {
                get { if (instance == null) instance = new FoodDAO(); return FoodDAO.instance; }
                private set { FoodDAO.instance = value; }
            }
            private FoodDAO()
            {

            }
        public List<Food> GetFoodByCategoryID(int id)
        {   
            List<Food> list = new List<Food>();
            string query = "Select * from food where idcategory =" + id;
            DataTable data = DataProvider.Instance.ExecuteQuery(query);
            foreach (DataRow item in data.Rows)
            {
                Food food = new Food(item);
                list.Add(food);
            }
            return list;
        }
        public List<Food> GetListFood()
        {
            List<Food> list = new List<Food>();
            string query = "Select * from food";
            DataTable data = DataProvider.Instance.ExecuteQuery(query);
            foreach (DataRow item in data.Rows)
            {
                Food food = new Food(item);
                list.Add(food);
            }
            return list;
        }

        public List<Food> SearchFoodByName(string name)
        {
            List<Food> list = new List<Food>();
            string query = string.Format("Select * from dbo.food where dbo.fuConvertToUnsign1(name) Like N'%'+dbo.fuConvertToUnsign1(N'{0}')+'%'", name);
            DataTable data = DataProvider.Instance.ExecuteQuery(query);
            foreach (DataRow item in data.Rows)
            {
                Food food = new Food(item);
                list.Add(food);
            }
            return list;
        }
        public bool InsertFood(string name,int id,float price)
        {
            var sqlconnectstring = @"Data Source=LAPTOP-OJIJN2TQ\SQLEXPRESS;Initial Catalog=QuanLyQuanCaPhe;Integrated Security=True";
            var connection = new SqlConnection(sqlconnectstring);
            connection.Open();
            using var command = new SqlCommand();
            command.Connection = connection;
            string query1 = string.Format("Select name from dbo.Food where name = '{0}'", name);
            command.CommandText = query1;
            using var reader = command.ExecuteReader();
            if (reader.HasRows)
            {
                return false;
            }
            else
            {
                string query = string.Format("Insert dbo.Food(name,idCategory,price) Values (N'{0}',{1},{2})", name, id, price);
                int result = DataProvider.Instance.ExecuteNonQuery(query);
                return result > 0;
            }
        }

        public bool UpdateFood(int idFood,string name, int id, float price)
        {
            string query = string.Format("update dbo.Food set Name = N'{0}',idCategory = {1},price = {2} where id = {3}", name, id, price,idFood);
            int result = DataProvider.Instance.ExecuteNonQuery(query);
            return result > 0;
        }

        public bool DeleteFood(int idFood)
        {
            BillInfoDAO.Instance.DeleteBillInfoByFoodID(idFood);
            string query = string.Format("Delete food where id = {0}", idFood);
            int result = DataProvider.Instance.ExecuteNonQuery(query);
            return result > 0;
        }
    }
}
