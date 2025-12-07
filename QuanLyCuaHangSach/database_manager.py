from datetime import datetime, date
from decimal import Decimal
from config import DatabaseConfig


class MongoDBManager:
    def __init__(self):
        self.client = None
        self.db = None
        self.connect_mongodb()

    def connect_mongodb(self):
        try:
            self.client = DatabaseConfig.get_mongo_client()
            if self.client is not None:
                self.db = self.client[DatabaseConfig.MONGO_DATABASE]
                self.ensure_collections()
                return True
            return False
        except Exception:
            return False

    def ensure_collections(self):
        """Chỉ tạo các collection thực sự được sử dụng"""
        if self.db is None:
            return

        try:
            collections = ['books', 'customers', 'orders', 'imports']
            existing = self.db.list_collection_names()

            for col in collections:
                if col not in existing:
                    self.db.create_collection(col)
        except Exception:
            pass

    def convert_for_mongodb(self, data):
        """Chuyển đổi dữ liệu để tương thích với MongoDB"""
        if isinstance(data, dict):
            result = {}
            for key, value in data.items():
                result[key] = self.convert_for_mongodb(value)
            return result
        elif isinstance(data, list):
            return [self.convert_for_mongodb(item) for item in data]
        elif isinstance(data, Decimal):
            return float(data)
        elif isinstance(data, date) and not isinstance(data, datetime):
            return datetime.combine(data, datetime.min.time())
        elif isinstance(data, (datetime, str, int, float, bool, type(None))):
            return data
        else:
            try:
                return str(data)
            except:
                return None

    def save_to_mongodb(self, collection_name: str, data: dict):
        """Lưu dữ liệu vào MongoDB"""
        if self.db is None:
            return False

        try:
            data_to_save = data.copy()
            data_to_save['created_at'] = datetime.now()
            data_to_save['source'] = 'sql_sync'

            prepared_data = self.convert_for_mongodb(data_to_save)
            result = self.db[collection_name].insert_one(prepared_data)

            return result.inserted_id is not None
        except Exception:
            return False

    def update_to_mongodb(self, collection_name: str, filter_data: dict, update_data: dict):
        """Cập nhật dữ liệu trong MongoDB"""
        if self.db is None:
            return False

        try:
            prepared_filter = self.convert_for_mongodb(filter_data)
            prepared_update = self.convert_for_mongodb(update_data)

            self.db[collection_name].update_one(
                prepared_filter,
                {"$set": prepared_update},
                upsert=True
            )
            return True
        except Exception:
            return False

class DatabaseManager:
    def __init__(self):
        self.connection = None
        self.mongo_manager = MongoDBManager()
        self.connect_sql()

    def connect_sql(self):
        """Kết nối SQL Server"""
        try:
            self.connection = DatabaseConfig.get_sql_connection()
            return self.connection is not None
        except Exception:
            return False

    def execute_query(self, query: str, params: tuple = None, fetch: bool = True):
        """Thực thi query SQL"""
        if self.connection is None:
            return None if fetch else False

        cursor = None
        try:
            cursor = self.connection.cursor()

            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)

            if fetch and query.strip().upper().startswith('SELECT'):
                result = cursor.fetchall()
                return result
            else:
                self.connection.commit()
                return True

        except Exception:
            if self.connection:
                try:
                    self.connection.rollback()
                except:
                    pass
            return None if fetch else False
        finally:
            if cursor:
                try:
                    cursor.close()
                except:
                    pass

    # ========== QUẢN LÝ SÁCH ==========
    def get_all_books(self):
        """Lấy tất cả sách"""
        try:
            result = self.execute_query("""
                SELECT book_id, book_code, title, author, publisher, 
                       publish_year, quantity_in_stock, price 
                FROM Books ORDER BY book_id
            """)
            return result if result else []
        except Exception:
            return []

    def add_book(self, book_data: tuple) -> bool:
        """Thêm sách mới"""
        try:
            book_code, title, author, publisher, publish_year, quantity, price = book_data

            # Kiểm tra mã sách trùng
            check_result = self.execute_query(
                "SELECT book_id FROM Books WHERE book_code = ?",
                (book_code,),
                fetch=True
            )

            if check_result:
                return False

            # Thêm vào SQL
            sql_success = self.execute_query("""
                INSERT INTO Books (book_code, title, author, publisher, publish_year, quantity_in_stock, price)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, book_data, fetch=False)

            if not sql_success:
                return False

            # Lấy ID vừa tạo
            result = self.execute_query("SELECT @@IDENTITY", fetch=True)

            if not result or not result[0]:
                return False

            book_id = result[0][0]

            # Đồng bộ lên MongoDB
            mongo_data = {
                "book_id": int(book_id),
                "book_code": book_code,
                "title": title,
                "author": author if author else "Không có",
                "publisher": publisher if publisher else "Không có",
                "publish_year": int(publish_year) if publish_year else 0,
                "quantity_in_stock": int(quantity) if quantity else 0,
                "price": float(price) if price else 0.0
            }

            self.mongo_manager.save_to_mongodb("books", mongo_data)
            return True

        except Exception:
            return False

    def update_book(self, book_data: tuple) -> bool:
        """Cập nhật thông tin sách"""
        try:
            title, author, publisher, publish_year, quantity, price, book_code = book_data

            # Cập nhật SQL
            sql_success = self.execute_query("""
                UPDATE Books SET title=?, author=?, publisher=?, 
                publish_year=?, quantity_in_stock=?, price=? 
                WHERE book_code=?
            """, book_data, fetch=False)

            if not sql_success:
                return False

            # Lấy ID sách
            result = self.execute_query(
                "SELECT book_id FROM Books WHERE book_code = ?",
                (book_code,),
                fetch=True
            )

            if result and result[0]:
                book_id = result[0][0]

                # Đồng bộ lên MongoDB
                mongo_data = {
                    "book_id": int(book_id),
                    "book_code": book_code,
                    "title": title,
                    "author": author if author else "Không có",
                    "publisher": publisher if publisher else "Không có",
                    "publish_year": int(publish_year) if publish_year else 0,
                    "quantity_in_stock": int(quantity) if quantity else 0,
                    "price": float(price) if price else 0.0
                }

                self.mongo_manager.update_to_mongodb(
                    "books",
                    {"book_id": book_id},
                    mongo_data
                )

            return True

        except Exception:
            return False

    def delete_book(self, book_code: str) -> bool:
        """Xóa sách"""
        try:
            # Lấy ID sách trước khi xóa
            result = self.execute_query(
                "SELECT book_id FROM Books WHERE book_code = ?",
                (book_code,),
                fetch=True
            )

            book_id = None
            if result and result[0]:
                book_id = result[0][0]

            # Xóa từ SQL
            sql_success = self.execute_query(
                "DELETE FROM Books WHERE book_code = ?",
                (book_code,),
                fetch=False
            )

            if not sql_success:
                return False

            # Xóa từ MongoDB
            if book_id and self.mongo_manager.db:
                self.mongo_manager.db['books'].delete_one({"book_id": book_id})

            return True

        except Exception:
            return False

    def search_books(self, **kwargs):
        """Tìm kiếm sách"""
        try:
            query = """
                SELECT book_id, book_code, title, author, publisher, 
                       publish_year, quantity_in_stock, price 
                FROM Books WHERE 1=1
            """
            params = []

            if kwargs.get('title'):
                query += " AND title LIKE ?"
                params.append(f"%{kwargs['title']}%")

            if kwargs.get('book_code'):
                query += " AND book_code LIKE ?"
                params.append(f"%{kwargs['book_code']}%")

            if kwargs.get('author'):
                query += " AND author LIKE ?"
                params.append(f"%{kwargs['author']}%")

            if kwargs.get('publisher'):
                query += " AND publisher LIKE ?"
                params.append(f"%{kwargs['publisher']}%")

            if kwargs.get('publish_year'):
                query += " AND publish_year = ?"
                params.append(int(kwargs['publish_year']))

            if kwargs.get('min_price'):
                query += " AND price >= ?"
                params.append(float(kwargs['min_price']))

            if kwargs.get('max_price'):
                query += " AND price <= ?"
                params.append(float(kwargs['max_price']))

            query += " ORDER BY title"

            result = self.execute_query(query, tuple(params) if params else None)
            return result if result else []

        except Exception:
            return []

    # ========== QUẢN LÝ KHÁCH HÀNG ==========
    def get_all_customers(self):
        """Lấy tất cả khách hàng"""
        try:
            result = self.execute_query("""
                SELECT customer_id, customer_code, full_name, address, phone_number
                FROM Customers ORDER BY customer_id
            """)
            return result if result else []
        except Exception:
            return []

    def add_customer(self, customer_data: tuple) -> bool:
        """Thêm khách hàng mới"""
        try:
            customer_code, full_name, address, phone_number = customer_data

            # Kiểm tra mã KH trùng
            check_result = self.execute_query(
                "SELECT customer_id FROM Customers WHERE customer_code = ?",
                (customer_code,),
                fetch=True
            )

            if check_result:
                return False

            # Thêm vào SQL
            sql_success = self.execute_query("""
                INSERT INTO Customers (customer_code, full_name, address, phone_number)
                VALUES (?, ?, ?, ?)
            """, customer_data, fetch=False)

            if not sql_success:
                return False

            # Lấy ID vừa tạo
            result = self.execute_query("SELECT @@IDENTITY", fetch=True)

            if not result or not result[0]:
                return False

            customer_id = result[0][0]

            # Đồng bộ lên MongoDB
            mongo_data = {
                "customer_id": int(customer_id),
                "customer_code": customer_code,
                "full_name": full_name,
                "address": address if address else "Không có",
                "phone_number": phone_number if phone_number else "Không có"
            }

            self.mongo_manager.save_to_mongodb("customers", mongo_data)
            return True

        except Exception:
            return False

    def update_customer(self, customer_data: tuple) -> bool:
        """Cập nhật thông tin khách hàng"""
        try:
            full_name, address, phone_number, customer_code = customer_data

            # Cập nhật SQL
            sql_success = self.execute_query("""
                UPDATE Customers SET full_name=?, address=?, phone_number=?
                WHERE customer_code=?
            """, customer_data, fetch=False)

            if not sql_success:
                return False

            # Lấy ID khách hàng
            result = self.execute_query(
                "SELECT customer_id FROM Customers WHERE customer_code = ?",
                (customer_code,),
                fetch=True
            )

            if result and result[0]:
                customer_id = result[0][0]

                # Đồng bộ lên MongoDB
                mongo_data = {
                    "customer_id": int(customer_id),
                    "customer_code": customer_code,
                    "full_name": full_name,
                    "address": address if address else "Không có",
                    "phone_number": phone_number if phone_number else "Không có"
                }

                self.mongo_manager.update_to_mongodb(
                    "customers",
                    {"customer_id": customer_id},
                    mongo_data
                )

            return True

        except Exception:
            return False

    def delete_customer(self, customer_code: str) -> bool:
        """Xóa khách hàng"""
        try:
            # Lấy ID khách hàng trước khi xóa
            result = self.execute_query(
                "SELECT customer_id FROM Customers WHERE customer_code = ?",
                (customer_code,),
                fetch=True
            )

            customer_id = None
            if result and result[0]:
                customer_id = result[0][0]

            # Xóa từ SQL
            sql_success = self.execute_query(
                "DELETE FROM Customers WHERE customer_code = ?",
                (customer_code,),
                fetch=False
            )

            if not sql_success:
                return False

            # Xóa từ MongoDB
            if customer_id and self.mongo_manager.db:
                self.mongo_manager.db['customers'].delete_one({"customer_id": customer_id})

            return True

        except Exception:
            return False

    # ========== QUẢN LÝ ĐƠN HÀNG ==========
    def create_order(self, order_code: str, customer_id: int, order_date=None):
        """Tạo đơn hàng mới"""
        try:
            if order_date is None:
                order_date = datetime.now()
            elif isinstance(order_date, date) and not isinstance(order_date, datetime):
                order_date = datetime.combine(order_date, datetime.min.time())

            # Thêm đơn hàng vào SQL
            sql_success = self.execute_query("""
                INSERT INTO Orders (order_code, customer_id, order_date, total_amount, status)
                VALUES (?, ?, ?, 0, 'Pending')
            """, (order_code, customer_id, order_date), fetch=False)

            if not sql_success:
                return None

            # Lấy ID đơn hàng vừa tạo
            result = self.execute_query(
                "SELECT order_id FROM Orders WHERE order_code = ?",
                (order_code,),
                fetch=True
            )

            if not result or not result[0]:
                return None

            order_id = result[0][0]

            # Đồng bộ lên MongoDB
            mongo_data = {
                "order_id": int(order_id),
                "order_code": order_code,
                "customer_id": int(customer_id),
                "order_date": order_date,
                "total_amount": 0.0,
                "status": "Pending"
            }

            self.mongo_manager.save_to_mongodb("orders", mongo_data)
            return order_id

        except Exception:
            return None

    def add_order_item(self, order_id: int, book_id: int, quantity: int, unit_price: float) -> bool:
        """Thêm sách vào đơn hàng"""
        try:
            subtotal = quantity * unit_price

            # Thêm chi tiết đơn hàng
            sql_success = self.execute_query("""
                INSERT INTO OrderDetails (order_id, book_id, quantity, unit_price, subtotal)
                VALUES (?, ?, ?, ?, ?)
            """, (order_id, book_id, quantity, unit_price, subtotal), fetch=False)

            if not sql_success:
                return False

            # Cập nhật tồn kho
            self.execute_query(
                "UPDATE Books SET quantity_in_stock = quantity_in_stock - ? WHERE book_id = ?",
                (quantity, book_id),
                fetch=False
            )

            return True

        except Exception:
            return False

    def complete_order(self, order_id: int) -> bool:
        """Hoàn thành đơn hàng"""
        try:
            # Kiểm tra trạng thái đơn hàng
            check_result = self.execute_query(
                "SELECT status, order_code FROM Orders WHERE order_id = ?",
                (order_id,),
                fetch=True
            )

            if not check_result:
                return False

            status, order_code = check_result[0]
            if status == 'Completed':
                return True

            # Tính tổng tiền
            total_result = self.execute_query("""
                SELECT SUM(quantity * unit_price) 
                FROM OrderDetails 
                WHERE order_id = ?
            """, (order_id,), fetch=True)

            if not total_result or total_result[0][0] is None:
                return False

            total_amount = total_result[0][0]
            if isinstance(total_amount, Decimal):
                total_amount = float(total_amount)

            # Cập nhật đơn hàng
            sql_success = self.execute_query("""
                UPDATE Orders 
                SET total_amount = ?, status = 'Completed'
                WHERE order_id = ?
            """, (total_amount, order_id), fetch=False)

            if not sql_success:
                return False

            # Lấy thông tin đơn hàng để đồng bộ MongoDB
            order_info = self.execute_query("""
                SELECT order_code, customer_id, order_date 
                FROM Orders WHERE order_id = ?
            """, (order_id,), fetch=True)

            if order_info:
                order_code, customer_id, order_date = order_info[0]

                if isinstance(order_date, date) and not isinstance(order_date, datetime):
                    order_date = datetime.combine(order_date, datetime.min.time())

                # Đồng bộ lên MongoDB
                mongo_data = {
                    "order_id": int(order_id),
                    "order_code": order_code,
                    "customer_id": int(customer_id),
                    "order_date": order_date,
                    "total_amount": float(total_amount),
                    "status": "Completed",
                    "completed_at": datetime.now()
                }

                self.mongo_manager.update_to_mongodb(
                    "orders",
                    {"order_id": order_id},
                    mongo_data
                )

            return True

        except Exception:
            return False

    def get_all_orders(self):
        """Lấy tất cả đơn hàng"""
        try:
            result = self.execute_query("""
                SELECT o.order_id, o.order_code, o.order_date, 
                       c.full_name as customer_name,
                       o.total_amount, o.status 
                FROM Orders o
                LEFT JOIN Customers c ON o.customer_id = c.customer_id
                ORDER BY o.order_date DESC
            """)
            return result if result else []
        except Exception:
            return []

    def get_order_statistics_by_date(self, start_date, end_date):
        """Thống kê đơn hàng theo khoảng thời gian"""
        try:
            if isinstance(start_date, date) and not isinstance(start_date, datetime):
                start_date = datetime.combine(start_date, datetime.min.time())
            if isinstance(end_date, date) and not isinstance(end_date, datetime):
                end_date = datetime.combine(end_date, datetime.max.time())

            result = self.execute_query("""
                SELECT 
                    COUNT(*) as total_orders,
                    ISNULL(SUM(total_amount), 0) as total_revenue
                FROM Orders 
                WHERE status = 'Completed'
                    AND order_date >= ? 
                    AND order_date <= ?
            """, (start_date, end_date), fetch=True)

            if result and result[0]:
                return result[0]
            return (0, 0)
        except Exception:
            return (0, 0)

    # ========== QUẢN LÝ NHẬP SÁCH ==========
    def create_import(self, import_code: str, import_date=None, supplier=""):
        """Tạo phiếu nhập sách"""
        try:
            if import_date is None:
                import_date = datetime.now()
            elif isinstance(import_date, date) and not isinstance(import_date, datetime):
                import_date = datetime.combine(import_date, datetime.min.time())

            # Thêm phiếu nhập vào SQL
            sql_success = self.execute_query("""
                INSERT INTO ImportBooks (import_code, import_date, supplier, total_amount)
                VALUES (?, ?, ?, 0)
            """, (import_code, import_date, supplier), fetch=False)

            if not sql_success:
                return None

            # Lấy ID phiếu nhập vừa tạo
            result = self.execute_query(
                "SELECT import_id FROM ImportBooks WHERE import_code = ?",
                (import_code,),
                fetch=True
            )

            if not result or not result[0]:
                return None

            import_id = result[0][0]

            # Đồng bộ lên MongoDB
            mongo_data = {
                "import_id": int(import_id),
                "import_code": import_code,
                "import_date": import_date,
                "supplier": supplier if supplier else "Không có",
                "total_amount": 0.0
            }

            self.mongo_manager.save_to_mongodb("imports", mongo_data)
            return import_id

        except Exception:
            return None

    def add_import_item(self, import_id: int, book_id: int, quantity: int, unit_price: float) -> bool:
        """Thêm sách vào phiếu nhập"""
        try:
            subtotal = quantity * unit_price

            # Thêm chi tiết phiếu nhập
            sql_success = self.execute_query("""
                INSERT INTO ImportDetails (import_id, book_id, quantity, unit_price, subtotal)
                VALUES (?, ?, ?, ?, ?)
            """, (import_id, book_id, quantity, unit_price, subtotal), fetch=False)

            if not sql_success:
                return False

            # Cập nhật tồn kho
            self.execute_query(
                "UPDATE Books SET quantity_in_stock = quantity_in_stock + ? WHERE book_id = ?",
                (quantity, book_id),
                fetch=False
            )

            # Cập nhật tổng tiền phiếu nhập
            self.execute_query(
                "UPDATE ImportBooks SET total_amount = total_amount + ? WHERE import_id = ?",
                (subtotal, import_id),
                fetch=False
            )

            return True

        except Exception:
            return False

    def get_all_imports(self):
        """Lấy tất cả phiếu nhập"""
        try:
            result = self.execute_query("""
                SELECT import_id, import_code, import_date, supplier, total_amount
                FROM ImportBooks ORDER BY import_date DESC
            """)
            return result if result else []
        except Exception:
            return []

    # ========== BÁO CÁO VÀ THỐNG KÊ ==========
    def get_best_selling_books(self, year: int = None, month: int = None, limit: int = 10):
        """Lấy sách bán chạy"""
        try:
            current_year = datetime.now().year
            current_month = datetime.now().month

            if year is None:
                year = current_year
            if month is None:
                month = current_month

            start_date = f"{year}-{month:02d}-01"
            if month == 12:
                end_date = f"{year + 1}-01-01"
            else:
                end_date = f"{year}-{month + 1:02d}-01"

            return self.execute_query(f"""
                SELECT TOP {limit} 
                    b.book_code, b.title, b.author, b.publisher,
                    SUM(od.quantity) as total_sold,
                    SUM(od.subtotal) as total_revenue
                FROM OrderDetails od
                JOIN Orders o ON od.order_id = o.order_id
                JOIN Books b ON od.book_id = b.book_id
                WHERE o.status = 'Completed'
                    AND o.order_date >= '{start_date}'
                    AND o.order_date < '{end_date}'
                GROUP BY b.book_id, b.book_code, b.title, b.author, b.publisher
                ORDER BY total_sold DESC
            """)
        except Exception:
            return self.execute_query(f"""
                SELECT TOP {limit} 
                    b.book_code, b.title, b.author, b.publisher,
                    SUM(od.quantity) as total_sold,
                    SUM(od.subtotal) as total_revenue
                FROM OrderDetails od
                JOIN Orders o ON od.order_id = o.order_id
                JOIN Books b ON od.book_id = b.book_id
                WHERE o.status = 'Completed'
                GROUP BY b.book_id, b.book_code, b.title, b.author, b.publisher
                ORDER BY total_sold DESC
            """)

    def get_inventory_by_publisher(self):
        """Lấy tồn kho theo nhà xuất bản"""
        try:
            result = self.execute_query("""
                SELECT 
                    publisher,
                    COUNT(book_id) as book_count,
                    SUM(quantity_in_stock) as total_quantity,
                    SUM(quantity_in_stock * price) as total_value
                FROM Books 
                WHERE publisher IS NOT NULL AND publisher != ''
                GROUP BY publisher 
                ORDER BY total_value DESC
            """, fetch=True)

            return result if result else []
        except Exception:
            return []

    def get_regular_customers(self, min_orders=2):
        """Lấy khách hàng thường xuyên"""
        try:
            result = self.execute_query(f"""
                SELECT 
                    c.customer_code, c.full_name, c.phone_number,
                    COUNT(o.order_id) as total_orders,
                    SUM(o.total_amount) as total_spent
                FROM Customers c
                JOIN Orders o ON c.customer_id = o.customer_id
                WHERE o.status = 'Completed'
                GROUP BY c.customer_id, c.customer_code, c.full_name, c.phone_number
                HAVING COUNT(o.order_id) >= {min_orders}
                ORDER BY total_spent DESC
            """, fetch=True)

            return result if result else []
        except Exception:
            return []

    def get_revenue_by_book(self):
        """Lấy doanh thu theo từng sách"""
        try:
            result = self.execute_query("""
                SELECT 
                    b.book_code, b.title, b.author, b.publisher,
                    COUNT(DISTINCT o.order_id) as order_count,
                    SUM(od.quantity) as total_sold,
                    SUM(od.subtotal) as total_revenue
                FROM Books b
                LEFT JOIN OrderDetails od ON b.book_id = od.book_id
                LEFT JOIN Orders o ON od.order_id = o.order_id AND o.status = 'Completed'
                WHERE od.quantity IS NOT NULL
                GROUP BY b.book_id, b.book_code, b.title, b.author, b.publisher 
                ORDER BY total_revenue DESC
            """, fetch=True)

            return result if result else []
        except Exception:
            return []

    def get_customers_by_purchases(self, limit: int = 10):
        """Lấy khách hàng mua nhiều nhất"""
        try:
            result = self.execute_query(f"""
                SELECT TOP ({limit}) 
                    c.customer_code, c.full_name, c.phone_number,
                    ISNULL(SUM(od.quantity), 0) as total_books,
                    COUNT(DISTINCT o.order_id) as total_orders,
                    ISNULL(SUM(o.total_amount), 0) as total_spent
                FROM Customers c
                LEFT JOIN Orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
                LEFT JOIN OrderDetails od ON o.order_id = od.order_id
                GROUP BY c.customer_id, c.customer_code, c.full_name, c.phone_number
                ORDER BY total_books DESC, total_spent DESC
            """, fetch=True)

            return result if result else []
        except Exception:
            return []

    def close(self):
        """Đóng kết nối database"""
        try:
            if self.connection:
                self.connection.close()
        except Exception:
            pass

        try:
            if self.mongo_manager.client:
                self.mongo_manager.client.close()
        except Exception:
            pass
