import pyodbc
from pymongo import MongoClient

class DatabaseConfig:
    # SQL Server Config
    SQL_SERVER = 'LINH\\LINHLINH22'
    SQL_DATABASE = 'BookStoreManagement'
    SQL_USERNAME = 'sa'
    SQL_PASSWORD = 'aa:123'
    SQL_DRIVER = '{ODBC Driver 17 for SQL Server}'

    # MongoDB Config
    MONGO_URI = "mongodb://localhost:27017/"
    MONGO_DATABASE = "bookstore_analytics"

    @staticmethod
    def get_sql_connection():
        """Kết nối SQL Server"""
        try:
            conn = pyodbc.connect(
                f'DRIVER={DatabaseConfig.SQL_DRIVER};'
                f'SERVER={DatabaseConfig.SQL_SERVER};'
                f'DATABASE={DatabaseConfig.SQL_DATABASE};'
                f'UID={DatabaseConfig.SQL_USERNAME};'
                f'PWD={DatabaseConfig.SQL_PASSWORD}'
            )
            return conn
        except Exception:
            return None

    @staticmethod
    def get_mongo_client():
        """Kết nối MongoDB"""
        try:
            client = MongoClient(DatabaseConfig.MONGO_URI)
            client.admin.command('ping')
            return client
        except Exception:
            return None

    @staticmethod
    def get_mongo_db():
        """Lấy MongoDB database"""
        try:
            client = DatabaseConfig.get_mongo_client()
            if client:
                return client[DatabaseConfig.MONGO_DATABASE]
            return None
        except Exception:
            return None