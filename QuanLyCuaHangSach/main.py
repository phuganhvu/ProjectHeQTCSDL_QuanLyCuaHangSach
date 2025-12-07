import tkinter as tk
from tkinter import ttk, messagebox
from database_manager import DatabaseManager
import random
from datetime import datetime, timedelta

class ModernBookStoreSystem:
    def __init__(self, root):
        self.root = root
        self.root.title("📚 HỆ THỐNG QUẢN LÝ CỬA HÀNG SÁCH")
        self.root.geometry("1400x900")
        self.root.configure(bg='#F0F8FF')

        self.center_window()
        self.setup_styles()
        self.db = DatabaseManager()

        # Khởi tạo dữ liệu
        self.current_order_items = []
        self.current_import_items = []
        self.books_data = []
        self.customers_data = []

        self.create_header()
        self.create_main_interface()
        self.update_clock()
        self.books_notebook = None

    # ========== STYLE ==========
    def center_window(self):
        """Căn giữa cửa sổ"""
        self.root.update_idletasks()
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        x = (screen_width - 1400) // 2
        y = (screen_height - 900) // 2
        self.root.geometry(f"1400x900+{x}+{y}")

    def setup_styles(self):
        """Cài đặt styles"""
        style = ttk.Style()
        colors = {
            'primary': '#4A90E2',
            'secondary': '#7BAAF7',
            'background': '#F0F8FF',
            'surface': '#FFFFFF',
            'text_primary': '#1E3A8A',
            'table_header': '#EBF8FF',
            'blue_dark': '#2563EB',
            'green_dark': '#059669'
        }

        style.configure('Modern.TFrame', background=colors['background'])
        style.configure('Header.TFrame', background=colors['primary'])
        style.configure('Card.TFrame', background=colors['surface'], relief='flat', borderwidth=1)
        style.configure('Primary.TButton',
                        background=colors['primary'],
                        foreground=colors['text_primary'],
                        font=('Segoe UI', 12, 'bold'),
                        borderwidth=0)
        style.configure('Modern.Treeview',
                        background=colors['surface'],
                        fieldbackground=colors['surface'],
                        foreground=colors['text_primary'],
                        rowheight=35,
                        font=('Segoe UI', 11))
        style.configure('Modern.Treeview.Heading',
                        background=colors['table_header'],
                        foreground=colors['text_primary'],
                        font=('Segoe UI', 11, 'bold'))
        style.configure('Modern.TNotebook', background=colors['background'])
        style.configure('Modern.TNotebook.Tab', font=('Segoe UI', 11), padding=[10, 5])

    def create_header(self):
        """Tạo header"""
        header_frame = tk.Frame(self.root, bg='#4A90E2', height=90)
        header_frame.pack(fill='x')
        header_frame.pack_propagate(False)

        title_label = tk.Label(header_frame,
                               text="📚 HỆ THỐNG QUẢN LÝ CỬA HÀNG SÁCH",
                               font=('Segoe UI', 24, 'bold'),
                               bg='#4A90E2',
                               fg='white')
        title_label.pack(side='left', padx=30, pady=25)

        self.time_label = tk.Label(header_frame,
                                   font=('Segoe UI', 13),
                                   bg='#4A90E2',
                                   fg='white')
        self.time_label.pack(side='right', padx=30, pady=25)

    def update_clock(self):
        """Cập nhật đồng hồ"""
        current_time = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
        self.time_label.config(text=f"🕒 {current_time}")
        self.root.after(1000, self.update_clock)

    def create_main_interface(self):
        """Tạo giao diện chính"""
        main_frame = ttk.Frame(self.root, style='Modern.TFrame')
        main_frame.pack(fill='both', expand=True, padx=20, pady=20)

        self.notebook = ttk.Notebook(main_frame, style='Modern.TNotebook')
        self.notebook.pack(fill='both', expand=True)

        self.create_dashboard_tab()
        self.create_books_tab()
        self.create_customers_tab()
        self.create_orders_tab()
        self.create_import_tab()
        self.create_reports_tab()

    def create_stat_card(self, parent, title, value, color):
        """Tạo card thống kê"""
        card = tk.Frame(parent, bg='white', relief='raised', bd=1)

        title_label = tk.Label(card, text=title, font=('Segoe UI', 12), bg='white', fg='#2C5282')
        title_label.pack(pady=(15, 5))

        value_frame = tk.Frame(card, bg='white')
        value_frame.pack(pady=5)

        circle = tk.Canvas(value_frame, width=35, height=35, bg='white', highlightthickness=0)
        circle.create_oval(5, 5, 30, 30, fill=color, outline='')
        circle.pack(side='left', padx=(0, 10))

        value_label = tk.Label(value_frame, text=value, font=('Segoe UI', 18, 'bold'), bg='white', fg='#2C5282')
        value_label.pack(side='left')

        return card

    # ========== DASHBOARD ==========
    def create_dashboard_tab(self):
        """Tab Dashboard"""
        dashboard_tab = ttk.Frame(self.notebook, style='Modern.TFrame')
        self.notebook.add(dashboard_tab, text="🏠 Dashboard")

        # Thống kê
        stats_frame = ttk.Frame(dashboard_tab, style='Modern.TFrame')
        stats_frame.pack(fill='x', padx=10, pady=10)

        try:
            total_books = len(self.db.get_all_books() or [])
            total_customers = len(self.db.get_all_customers() or [])
            total_orders = len(self.db.get_all_orders() or [])
            revenue_data = self.db.get_revenue_by_book()
            total_revenue = sum(row[-1] for row in revenue_data) if revenue_data else 0
        except:
            total_books = total_customers = total_orders = total_revenue = 0

        stats = [
            ("📊 Tổng sách", f"{total_books:,}", '#4A90E2'),
            ("👥 Khách hàng", f"{total_customers:,}", '#7BAAF7'),
            ("🛒 Đơn hàng", f"{total_orders:,}", '#A8D1FF'),
            ("💰 Doanh thu", f"{total_revenue:,.0f} đ", '#63B3ED')
        ]

        for i, (title, value, color) in enumerate(stats):
            card = self.create_stat_card(stats_frame, title, value, color)
            card.grid(row=0, column=i, padx=10, pady=10, sticky='nsew')
            stats_frame.columnconfigure(i, weight=1)

        # Thao tác nhanh
        actions_frame = ttk.LabelFrame(dashboard_tab, text="🚀 Thao tác nhanh", style='Card.TFrame')
        actions_frame.pack(fill='x', padx=10, pady=10)

        actions = [
            ("📖 Thêm sách", self.show_books_tab),
            ("👥 Thêm khách hàng", self.show_customers_tab),
            ("🛒 Tạo đơn hàng", self.show_orders_tab),
            ("📥 Nhập sách", self.show_import_tab),
            ("📊 Xem báo cáo", self.show_reports_tab)
        ]

        for i, (text, command) in enumerate(actions):
            btn = ttk.Button(actions_frame, text=text, command=command, style='Primary.TButton')
            btn.grid(row=0, column=i, padx=10, pady=15, sticky='ew')
            actions_frame.columnconfigure(i, weight=1)

    # ========== QUẢN LÝ SÁCH ==========
    def create_books_tab(self):
        """Tab quản lý sách"""
        books_tab = ttk.Frame(self.notebook, style='Modern.TFrame')
        self.notebook.add(books_tab, text="📚 Sách")

        books_notebook = ttk.Notebook(books_tab)
        books_notebook.pack(fill='both', expand=True, padx=10, pady=10)
        self.books_notebook = books_notebook

        # Tab quản lý sách
        manage_books_tab = ttk.Frame(books_notebook)
        books_notebook.add(manage_books_tab, text="📝 Quản lý sách")
        self.create_book_management(manage_books_tab)

        # Tab tìm kiếm sách
        search_books_tab = ttk.Frame(books_notebook)
        books_notebook.add(search_books_tab, text="🔍 Tìm kiếm sách")
        self.create_book_search(search_books_tab)

    def create_book_management(self, parent):
        """Form quản lý sách"""
        form_frame = ttk.LabelFrame(parent, text="📝 Thông tin sách", style='Card.TFrame')
        form_frame.pack(fill='x', padx=15, pady=15)
        self.create_book_form(form_frame)

        button_frame = ttk.Frame(parent, style='Modern.TFrame')
        button_frame.pack(fill='x', padx=15, pady=10)

        buttons = [
            ("💾 Thêm sách", self.add_book),
            ("✏️ Cập nhật", self.update_book),
            ("🗑️ Xóa", self.delete_book),
            ("🔄 Làm mới", self.clear_book_form)
        ]

        for i, (text, command) in enumerate(buttons):
            btn = ttk.Button(button_frame, text=text, command=command, style='Primary.TButton', width=15)
            btn.grid(row=0, column=i, padx=5, pady=5)

        self.create_books_table(parent)

    def create_book_form(self, parent):
        """Form nhập thông tin sách"""
        label_config = {'font': ('Segoe UI', 11), 'bg': 'white', 'fg': '#1E3A8A'}

        # Dòng 1: Mã sách và Tên sách
        tk.Label(parent, text="🔤 Mã sách:", **label_config).grid(row=0, column=0, padx=10, pady=8, sticky='e')
        self.book_code = ttk.Entry(parent, width=20, font=('Segoe UI', 11))
        self.book_code.grid(row=0, column=1, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="📖 Tên sách:", **label_config).grid(row=0, column=2, padx=10, pady=8, sticky='e')
        self.book_name = ttk.Entry(parent, width=25, font=('Segoe UI', 11))
        self.book_name.grid(row=0, column=3, padx=10, pady=8, sticky='w')

        # Dòng 2: Tác giả và NXB
        tk.Label(parent, text="✍️ Tác giả:", **label_config).grid(row=1, column=0, padx=10, pady=8, sticky='e')
        self.book_author = ttk.Entry(parent, width=20, font=('Segoe UI', 11))
        self.book_author.grid(row=1, column=1, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="🏢 Nhà xuất bản:", **label_config).grid(row=1, column=2, padx=10, pady=8, sticky='e')
        self.book_publisher = ttk.Entry(parent, width=25, font=('Segoe UI', 11))
        self.book_publisher.grid(row=1, column=3, padx=10, pady=8, sticky='w')

        # Dòng 3: Năm XB, Số lượng và Giá
        tk.Label(parent, text="📅 Năm XB:", **label_config).grid(row=2, column=0, padx=10, pady=8, sticky='e')
        current_year = datetime.now().year
        years = [str(year) for year in range(current_year, 1900, -1)]
        self.book_year = ttk.Combobox(parent, width=18, values=years, state='readonly', font=('Segoe UI', 11))
        self.book_year.grid(row=2, column=1, padx=10, pady=8, sticky='w')
        self.book_year.set(str(current_year))

        tk.Label(parent, text="📦 Số lượng:", **label_config).grid(row=2, column=2, padx=10, pady=8, sticky='e')
        self.book_quantity = ttk.Entry(parent, width=20, font=('Segoe UI', 11))
        self.book_quantity.grid(row=2, column=3, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="💰 Giá bán:", **label_config).grid(row=2, column=4, padx=10, pady=8, sticky='e')
        self.book_price = ttk.Entry(parent, width=20, font=('Segoe UI', 11))
        self.book_price.grid(row=2, column=5, padx=10, pady=8, sticky='w')

        for i in range(6):
            parent.columnconfigure(i, weight=1)

    def create_books_table(self, parent):
        """Bảng danh sách sách"""
        table_frame = ttk.LabelFrame(parent, text="📊 Danh sách sách", style='Card.TFrame')
        table_frame.pack(fill='both', expand=True, padx=15, pady=15)

        columns = ('ID', 'Mã sách', 'Tên sách', 'Tác giả', 'NXB', 'Năm XB', 'Số lượng', 'Giá bán')
        self.books_tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=15,
                                       style='Modern.Treeview')

        col_configs = [
            ('ID', 50, 'center'),
            ('Mã sách', 120, 'center'),
            ('Tên sách', 250, 'w'),
            ('Tác giả', 180, 'w'),
            ('NXB', 150, 'center'),
            ('Năm XB', 80, 'center'),
            ('Số lượng', 90, 'center'),
            ('Giá bán', 120, 'e')
        ]

        for col, width, anchor in col_configs:
            self.books_tree.heading(col, text=col)
            self.books_tree.column(col, width=width, anchor=anchor)

        v_scroll = ttk.Scrollbar(table_frame, orient='vertical', command=self.books_tree.yview)
        h_scroll = ttk.Scrollbar(table_frame, orient='horizontal', command=self.books_tree.xview)
        self.books_tree.configure(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)

        self.books_tree.pack(side='left', fill='both', expand=True)
        v_scroll.pack(side='right', fill='y')
        h_scroll.pack(side='bottom', fill='x')

        self.books_tree.bind('<<TreeviewSelect>>', self.on_book_select)
        self.load_books()

    def create_book_search(self, parent):
        """Form tìm kiếm sách nâng cao"""
        search_frame = ttk.LabelFrame(parent, text="🔍 Tìm kiếm sách nâng cao", style='Card.TFrame')
        search_frame.pack(fill='x', padx=15, pady=15)

        label_config = {'font': ('Segoe UI', 11), 'bg': 'white', 'fg': '#1E3A8A'}

        # Dòng 1: Tên sách và Mã sách
        tk.Label(search_frame, text="📖 Tên sách:", **label_config).grid(row=0, column=0, padx=10, pady=10, sticky='e')
        self.search_book_name = ttk.Entry(search_frame, width=25, font=('Segoe UI', 11))
        self.search_book_name.grid(row=0, column=1, padx=10, pady=10, sticky='w')

        tk.Label(search_frame, text="🔤 Mã sách:", **label_config).grid(row=0, column=2, padx=10, pady=10, sticky='e')
        self.search_book_code = ttk.Entry(search_frame, width=20, font=('Segoe UI', 11))
        self.search_book_code.grid(row=0, column=3, padx=10, pady=10, sticky='w')

        # Dòng 2: Tác giả và NXB
        tk.Label(search_frame, text="✍️ Tác giả:", **label_config).grid(row=1, column=0, padx=10, pady=10, sticky='e')
        self.search_book_author = ttk.Entry(search_frame, width=25, font=('Segoe UI', 11))
        self.search_book_author.grid(row=1, column=1, padx=10, pady=10, sticky='w')

        tk.Label(search_frame, text="🏢 Nhà xuất bản:", **label_config).grid(row=1, column=2, padx=10, pady=10,
                                                                            sticky='e')
        self.search_book_publisher = ttk.Entry(search_frame, width=25, font=('Segoe UI', 11))
        self.search_book_publisher.grid(row=1, column=3, padx=10, pady=10, sticky='w')

        # Dòng 3: Năm XB và Khoảng giá
        tk.Label(search_frame, text="📅 Năm XB:", **label_config).grid(row=2, column=0, padx=10, pady=10, sticky='e')
        current_year = datetime.now().year
        years = [""] + [str(y) for y in range(current_year, 1900, -1)]
        self.search_book_year = ttk.Combobox(search_frame, width=15, values=years, state='readonly',
                                             font=('Segoe UI', 11))
        self.search_book_year.grid(row=2, column=1, padx=10, pady=10, sticky='w')

        tk.Label(search_frame, text="💰 Khoảng giá:", **label_config).grid(row=2, column=2, padx=10, pady=10, sticky='e')
        price_frame = ttk.Frame(search_frame)
        price_frame.grid(row=2, column=3, padx=10, pady=10, sticky='w')

        self.search_min_price = ttk.Entry(price_frame, width=10, font=('Segoe UI', 11))
        self.search_min_price.pack(side='left')
        tk.Label(price_frame, text=" - ", **label_config).pack(side='left', padx=5)
        self.search_max_price = ttk.Entry(price_frame, width=10, font=('Segoe UI', 11))
        self.search_max_price.pack(side='left')
        tk.Label(price_frame, text=" đ", **label_config).pack(side='left', padx=5)

        # Dòng 4: Nút tìm kiếm
        button_frame = ttk.Frame(search_frame)
        button_frame.grid(row=3, column=0, columnspan=4, pady=15)

        ttk.Button(button_frame, text="🔍 Tìm kiếm",
                   command=self.search_books,
                   style='Primary.TButton', width=15).pack(side='left', padx=5)

        ttk.Button(button_frame, text="🔄 Làm mới",
                   command=self.clear_search_books,
                   style='Primary.TButton', width=15).pack(side='left', padx=5)

        ttk.Button(button_frame, text="📋 Xem tất cả",
                   command=self.show_all_books,
                   style='Primary.TButton', width=15).pack(side='left', padx=5)

        # Bảng kết quả
        result_frame = ttk.LabelFrame(parent, text="📊 Kết quả tìm kiếm", style='Card.TFrame')
        result_frame.pack(fill='both', expand=True, padx=15, pady=15)

        columns = ('ID', 'Mã sách', 'Tên sách', 'Tác giả', 'NXB', 'Năm XB', 'Số lượng', 'Giá bán')
        self.search_books_tree = ttk.Treeview(
            result_frame,
            columns=columns,
            show='headings',
            height=15,
            style='Modern.Treeview'
        )

        col_configs = [
            ('ID', 50, 'center'),
            ('Mã sách', 120, 'center'),
            ('Tên sách', 250, 'w'),
            ('Tác giả', 180, 'w'),
            ('NXB', 150, 'center'),
            ('Năm XB', 80, 'center'),
            ('Số lượng', 90, 'center'),
            ('Giá bán', 120, 'e')
        ]

        for col, width, anchor in col_configs:
            self.search_books_tree.heading(col, text=col)
            self.search_books_tree.column(col, width=width, anchor=anchor)

        v_scroll = ttk.Scrollbar(result_frame, orient='vertical', command=self.search_books_tree.yview)
        h_scroll = ttk.Scrollbar(result_frame, orient='horizontal', command=self.search_books_tree.xview)
        self.search_books_tree.configure(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)

        self.search_books_tree.pack(side='left', fill='both', expand=True)
        v_scroll.pack(side='right', fill='y')
        h_scroll.pack(side='bottom', fill='x')

        self.search_books_tree.bind('<<TreeviewSelect>>', self.on_search_book_select)

    def load_books(self):
        """Tải danh sách sách"""
        for item in self.books_tree.get_children():
            self.books_tree.delete(item)

        try:
            books = self.db.get_all_books()
            if books:
                for i, book in enumerate(books):
                    if len(book) >= 8:
                        formatted_book = list(book)

                        try:
                            price = float(book[7])
                            formatted_book[7] = f"{price:,.0f}₫"
                        except:
                            formatted_book[7] = "0₫"

                        try:
                            quantity = int(book[6])
                            formatted_book[6] = f"{quantity:,}"
                        except:
                            formatted_book[6] = "0"

                        tag = 'even' if i % 2 == 0 else 'odd'
                        self.books_tree.insert('', 'end', values=formatted_book, tags=(tag,))

                self.books_tree.tag_configure('even', background='#FFFFFF')
                self.books_tree.tag_configure('odd', background='#F8FAFC')
        except Exception:
            pass

    def load_books_to_search_table(self):
        """Tải tất cả sách vào bảng tìm kiếm"""
        try:
            books = self.db.get_all_books()
            self.display_search_results(books)
        except Exception:
            pass

    def add_book(self):
        """Thêm sách mới"""
        try:
            book_data = (
                self.book_code.get().strip(),
                self.book_name.get().strip(),
                self.book_author.get().strip(),
                self.book_publisher.get().strip(),
                int(self.book_year.get() or datetime.now().year),
                int(self.book_quantity.get() or 0),
                float(self.book_price.get() or 0)
            )

            if not all(book_data[:4]):
                messagebox.showerror("Lỗi", "Vui lòng điền đầy đủ thông tin bắt buộc!")
                return

            result = self.db.add_book(book_data)
            if result:
                messagebox.showinfo("Thành công", "Thêm sách thành công!")
                self.clear_book_form()
                self.load_books()
                self.load_combo_data()
            else:
                messagebox.showerror("Lỗi", "Không thể thêm sách! Có thể mã sách đã tồn tại.")
        except ValueError:
            messagebox.showerror("Lỗi", "Số lượng và giá phải là số!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi thêm sách!")

    def update_book(self):
        """Cập nhật sách"""
        try:
            book_data = (
                self.book_name.get(),
                self.book_author.get(),
                self.book_publisher.get(),
                int(self.book_year.get()),
                int(self.book_quantity.get()),
                float(self.book_price.get()),
                self.book_code.get()
            )
            result = self.db.update_book(book_data)
            if result:
                messagebox.showinfo("Thành công", "Cập nhật sách thành công!")
                self.load_books()
                self.load_combo_data()
            else:
                messagebox.showerror("Lỗi", "Không thể cập nhật sách!")
        except ValueError:
            messagebox.showerror("Lỗi", "Số lượng và giá phải là số!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi cập nhật sách!")

    def delete_book(self):
        """Xóa sách"""
        if messagebox.askyesno("Xác nhận", "Bạn có chắc chắn muốn xóa sách này?"):
            result = self.db.delete_book(self.book_code.get())
            if result:
                messagebox.showinfo("Thành công", "Xóa sách thành công!")
                self.clear_book_form()
                self.load_books()
                self.load_combo_data()
            else:
                messagebox.showerror("Lỗi", "Không thể xóa sách!")

    def clear_book_form(self):
        """Làm mới form sách"""
        for widget in [self.book_code, self.book_name, self.book_author,
                       self.book_publisher, self.book_quantity, self.book_price]:
            widget.delete(0, tk.END)

        current_year = datetime.now().year
        self.book_year.set(str(current_year))

    def search_books(self):
        """Tìm kiếm sách"""
        try:
            book_name = self.search_book_name.get().strip()
            book_code = self.search_book_code.get().strip()
            author = self.search_book_author.get().strip()
            publisher = self.search_book_publisher.get().strip()
            year_str = self.search_book_year.get().strip()
            min_price = self.search_min_price.get().strip()
            max_price = self.search_max_price.get().strip()

            result = self.db.search_books(
                title=book_name,
                book_code=book_code,
                author=author,
                publisher=publisher,
                publish_year=year_str,
                min_price=min_price,
                max_price=max_price
            )

            self.display_search_results(result)

            if not result:
                messagebox.showinfo("Thông báo", "Không tìm thấy sách phù hợp!")
        except ValueError:
            messagebox.showerror("Lỗi", "Vui lòng nhập đúng định dạng số!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tìm kiếm!")

    def display_search_results(self, books):
        """Hiển thị kết quả tìm kiếm"""
        for item in self.search_books_tree.get_children():
            self.search_books_tree.delete(item)

        if books:
            for i, book in enumerate(books):
                if len(book) >= 8:
                    formatted_book = list(book)

                    try:
                        price = float(book[7])
                        formatted_book[7] = f"{price:,.0f}₫"
                    except:
                        formatted_book[7] = "0₫"

                    try:
                        quantity = int(book[6])
                        formatted_book[6] = f"{quantity:,}"
                    except:
                        formatted_book[6] = "0"

                    tag = 'even' if i % 2 == 0 else 'odd'
                    self.search_books_tree.insert('', 'end', values=formatted_book, tags=(tag,))

            self.search_books_tree.tag_configure('even', background='#FFFFFF')
            self.search_books_tree.tag_configure('odd', background='#F8FAFC')

            messagebox.showinfo("Thông báo", f"Tìm thấy {len(books)} sách phù hợp!")

    def clear_search_books(self):
        """Làm mới form tìm kiếm"""
        self.search_book_name.delete(0, tk.END)
        self.search_book_code.delete(0, tk.END)
        self.search_book_author.delete(0, tk.END)
        self.search_book_publisher.delete(0, tk.END)
        self.search_book_year.set('')
        self.search_min_price.delete(0, tk.END)
        self.search_max_price.delete(0, tk.END)

        for item in self.search_books_tree.get_children():
            self.search_books_tree.delete(item)

    def show_all_books(self):
        """Hiển thị tất cả sách"""
        self.clear_search_books()
        self.load_books_to_search_table()

    def on_book_select(self, event):
        """Xử lý khi chọn sách"""
        selection = self.books_tree.selection()
        if selection:
            item = self.books_tree.item(selection[0])
            values = item['values']
            if values:
                self.book_code.delete(0, tk.END)
                self.book_code.insert(0, values[1])
                self.book_name.delete(0, tk.END)
                self.book_name.insert(0, values[2])
                self.book_author.delete(0, tk.END)
                self.book_author.insert(0, values[3])
                self.book_publisher.delete(0, tk.END)
                self.book_publisher.insert(0, values[4])
                self.book_year.set(values[5])
                self.book_quantity.delete(0, tk.END)
                self.book_quantity.insert(0, values[6])
                price_str = str(values[7]).replace('₫', '').replace(',', '').strip()
                self.book_price.delete(0, tk.END)
                self.book_price.insert(0, price_str)

    def on_search_book_select(self, event):
        """Xử lý khi chọn sách trong bảng tìm kiếm"""
        selection = self.search_books_tree.selection()
        if selection:
            item = self.search_books_tree.item(selection[0])
            values = item['values']
            if values:
                self.notebook.select(1)
                self.books_notebook.select(0)

                self.book_code.delete(0, tk.END)
                self.book_code.insert(0, values[1])
                self.book_name.delete(0, tk.END)
                self.book_name.insert(0, values[2])
                self.book_author.delete(0, tk.END)
                self.book_author.insert(0, values[3])
                self.book_publisher.delete(0, tk.END)
                self.book_publisher.insert(0, values[4])
                self.book_year.set(values[5])
                self.book_quantity.delete(0, tk.END)
                self.book_quantity.insert(0, values[6])
                price_str = str(values[7]).replace('₫', '').replace(',', '').strip()
                self.book_price.delete(0, tk.END)
                self.book_price.insert(0, price_str)

    # ========== QUẢN LÝ KHÁCH HÀNG ==========
    def create_customers_tab(self):
        """Tab quản lý khách hàng"""
        customers_tab = ttk.Frame(self.notebook, style='Modern.TFrame')
        self.notebook.add(customers_tab, text="👥 Khách hàng")

        form_frame = ttk.LabelFrame(customers_tab, text="📝 Thông tin khách hàng", style='Card.TFrame')
        form_frame.pack(fill='x', padx=15, pady=15)
        self.create_customer_form(form_frame)

        button_frame = ttk.Frame(customers_tab, style='Modern.TFrame')
        button_frame.pack(fill='x', padx=15, pady=10)

        buttons = [
            ("💾 Thêm KH", self.add_customer),
            ("✏️ Cập nhật", self.update_customer),
            ("🗑️ Xóa", self.delete_customer),
            ("🔄 Làm mới", self.clear_customer_form)
        ]

        for i, (text, command) in enumerate(buttons):
            btn = ttk.Button(button_frame, text=text, command=command, style='Primary.TButton', width=15)
            btn.grid(row=0, column=i, padx=5, pady=5)

        self.create_customers_table(customers_tab)

    def create_customer_form(self, parent):
        """Form nhập thông tin khách hàng"""
        label_config = {'font': ('Segoe UI', 11), 'bg': 'white', 'fg': '#1E3A8A'}

        tk.Label(parent, text="🔤 Mã KH:", **label_config).grid(row=0, column=0, padx=10, pady=8, sticky='e')
        self.customer_code = ttk.Entry(parent, width=25, font=('Segoe UI', 11))
        self.customer_code.grid(row=0, column=1, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="👤 Họ tên:", **label_config).grid(row=0, column=2, padx=10, pady=8, sticky='e')
        self.customer_name = ttk.Entry(parent, width=30, font=('Segoe UI', 11))
        self.customer_name.grid(row=0, column=3, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="🏠 Địa chỉ:", **label_config).grid(row=1, column=0, padx=10, pady=8, sticky='e')
        self.customer_address = ttk.Entry(parent, width=60, font=('Segoe UI', 11))
        self.customer_address.grid(row=1, column=1, columnspan=3, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="📞 Số ĐT:", **label_config).grid(row=2, column=0, padx=10, pady=8, sticky='e')
        self.customer_phone = ttk.Entry(parent, width=25, font=('Segoe UI', 11))
        self.customer_phone.grid(row=2, column=1, padx=10, pady=8, sticky='w')

        for i in range(4):
            parent.columnconfigure(i, weight=1)

    def create_customers_table(self, parent):
        """Bảng danh sách khách hàng"""
        table_frame = ttk.LabelFrame(parent, text="📊 Danh sách khách hàng", style='Card.TFrame')
        table_frame.pack(fill='both', expand=True, padx=15, pady=15)

        columns = ('ID', 'Mã KH', 'Họ tên', 'Địa chỉ', 'Số ĐT')
        self.customers_tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=15,
                                           style='Modern.Treeview')

        col_configs = [
            ('ID', 50, 'center'),
            ('Mã KH', 100, 'center'),
            ('Họ tên', 200, 'w'),
            ('Địa chỉ', 350, 'w'),
            ('Số ĐT', 120, 'center')
        ]

        for col, width, anchor in col_configs:
            self.customers_tree.heading(col, text=col)
            self.customers_tree.column(col, width=width, anchor=anchor)

        v_scroll = ttk.Scrollbar(table_frame, orient='vertical', command=self.customers_tree.yview)
        h_scroll = ttk.Scrollbar(table_frame, orient='horizontal', command=self.customers_tree.xview)
        self.customers_tree.configure(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)

        self.customers_tree.pack(side='left', fill='both', expand=True)
        v_scroll.pack(side='right', fill='y')
        h_scroll.pack(side='bottom', fill='x')

        self.customers_tree.bind('<<TreeviewSelect>>', self.on_customer_select)
        self.load_customers()

    def load_customers(self):
        """Tải danh sách khách hàng"""
        for item in self.customers_tree.get_children():
            self.customers_tree.delete(item)

        try:
            customers = self.db.get_all_customers()
            if customers:
                for i, customer in enumerate(customers):
                    if len(customer) >= 5:
                        formatted_customer = list(customer)
                        if len(formatted_customer) > 5:
                            formatted_customer = formatted_customer[:5]

                        tag = 'even' if i % 2 == 0 else 'odd'
                        self.customers_tree.insert('', 'end', values=formatted_customer, tags=(tag,))

                self.customers_tree.tag_configure('even', background='#FFFFFF')
                self.customers_tree.tag_configure('odd', background='#F8FAFC')
        except Exception:
            pass

    def add_customer(self):
        """Thêm khách hàng mới"""
        try:
            customer_data = (
                self.customer_code.get().strip(),
                self.customer_name.get().strip(),
                self.customer_address.get().strip(),
                self.customer_phone.get().strip()
            )

            if not all(customer_data[:2]):
                messagebox.showerror("Lỗi", "Vui lòng điền mã KH và họ tên!")
                return

            result = self.db.add_customer(customer_data)
            if result:
                messagebox.showinfo("Thành công", "Thêm khách hàng thành công!")
                self.clear_customer_form()
                self.load_customers()
                self.load_combo_data()
            else:
                messagebox.showerror("Lỗi", "Không thể thêm khách hàng!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi thêm khách hàng!")

    def update_customer(self):
        """Cập nhật khách hàng"""
        try:
            customer_data = (
                self.customer_name.get(),
                self.customer_address.get(),
                self.customer_phone.get(),
                self.customer_code.get()
            )
            result = self.db.update_customer(customer_data)
            if result:
                messagebox.showinfo("Thành công", "Cập nhật khách hàng thành công!")
                self.load_customers()
                self.load_combo_data()
            else:
                messagebox.showerror("Lỗi", "Không thể cập nhật khách hàng!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi cập nhật khách hàng!")

    def delete_customer(self):
        """Xóa khách hàng"""
        if messagebox.askyesno("Xác nhận", "Bạn có chắc chắn muốn xóa khách hàng này?"):
            result = self.db.delete_customer(self.customer_code.get())
            if result:
                messagebox.showinfo("Thành công", "Xóa khách hàng thành công!")
                self.clear_customer_form()
                self.load_customers()
                self.load_combo_data()
            else:
                messagebox.showerror("Lỗi", "Không thể xóa khách hàng!")

    def clear_customer_form(self):
        """Làm mới form khách hàng"""
        for widget in [self.customer_code, self.customer_name, self.customer_address, self.customer_phone]:
            widget.delete(0, tk.END)

    def on_customer_select(self, event):
        """Xử lý khi chọn khách hàng"""
        selection = self.customers_tree.selection()
        if selection:
            item = self.customers_tree.item(selection[0])
            values = item['values']
            if values:
                self.customer_code.delete(0, tk.END)
                self.customer_code.insert(0, values[1])
                self.customer_name.delete(0, tk.END)
                self.customer_name.insert(0, values[2])
                self.customer_address.delete(0, tk.END)
                self.customer_address.insert(0, values[3])
                self.customer_phone.delete(0, tk.END)
                self.customer_phone.insert(0, values[4])

    # ========== QUẢN LÝ ĐƠN HÀNG ==========
    def create_orders_tab(self):
        """Tab quản lý đơn hàng"""
        orders_tab = ttk.Frame(self.notebook, style='Modern.TFrame')
        self.notebook.add(orders_tab, text="🛒 Đơn hàng")

        orders_notebook = ttk.Notebook(orders_tab)
        orders_notebook.pack(fill='both', expand=True, padx=10, pady=10)

        create_order_tab = ttk.Frame(orders_notebook)
        orders_notebook.add(create_order_tab, text="➕ Tạo đơn hàng")

        order_list_tab = ttk.Frame(orders_notebook)
        orders_notebook.add(order_list_tab, text="📋 Danh sách đơn hàng")

        # Form tạo đơn hàng
        order_frame = ttk.LabelFrame(create_order_tab, text="🛍️ Tạo đơn hàng mới", style='Card.TFrame')
        order_frame.pack(fill='x', padx=15, pady=15)
        self.create_order_form(order_frame)

        # Bảng sách trong đơn hàng
        items_frame = ttk.LabelFrame(create_order_tab, text="📦 Sách trong đơn hàng", style='Card.TFrame')
        items_frame.pack(fill='both', expand=True, padx=15, pady=15)
        self.create_order_items_table(items_frame)

        # Thống kê đơn hàng
        stats_frame = ttk.LabelFrame(order_list_tab, text="📊 Thống kê đơn hàng theo thời gian", style='Card.TFrame')
        stats_frame.pack(fill='x', padx=15, pady=15)

        stats_form_frame = ttk.Frame(stats_frame, style='Modern.TFrame')
        stats_form_frame.pack(fill='x', padx=10, pady=10)

        label_config = {'font': ('Segoe UI', 11), 'bg': 'white', 'fg': '#1E3A8A'}

        # Loại thống kê
        tk.Label(stats_form_frame, text="📊 Loại thống kê:", **label_config).grid(row=0, column=0, padx=10, pady=10,
                                                                                 sticky='e')
        self.order_stats_type = ttk.Combobox(stats_form_frame, width=15,
                                             values=['Theo ngày', 'Theo tháng', 'Theo năm'],
                                             state='readonly', font=('Segoe UI', 11))
        self.order_stats_type.grid(row=0, column=1, padx=10, pady=10, sticky='w')
        self.order_stats_type.set('Theo tháng')
        self.order_stats_type.bind('<<ComboboxSelected>>', self.on_order_stats_type_change)

        # Ngày tháng năm
        tk.Label(stats_form_frame, text="📅 Ngày:", **label_config).grid(row=0, column=2, padx=10, pady=10, sticky='e')
        self.order_stats_day = ttk.Entry(stats_form_frame, width=12, font=('Segoe UI', 11))
        self.order_stats_day.grid(row=0, column=3, padx=10, pady=10, sticky='w')
        self.order_stats_day.insert(0, datetime.now().strftime('%d/%m/%Y'))
        self.order_stats_day.grid_remove()

        tk.Label(stats_form_frame, text="📆 Tháng:", **label_config).grid(row=0, column=4, padx=10, pady=10, sticky='e')
        self.order_stats_month = ttk.Combobox(stats_form_frame, width=12, state='readonly', font=('Segoe UI', 11))
        self.order_stats_month.grid(row=0, column=5, padx=10, pady=10, sticky='w')
        self.order_stats_month.grid_remove()

        current_year = datetime.now().year
        tk.Label(stats_form_frame, text="📅 Năm:", **label_config).grid(row=0, column=6, padx=10, pady=10, sticky='e')
        self.order_stats_year = ttk.Combobox(stats_form_frame, width=10,
                                             values=[str(y) for y in range(current_year - 5, current_year + 1)],
                                             state='readonly', font=('Segoe UI', 11))
        self.order_stats_year.grid(row=0, column=7, padx=10, pady=10, sticky='w')
        self.order_stats_year.set(str(current_year))

        # Nút thống kê
        ttk.Button(stats_form_frame, text="📊 Xem thống kê",
                   command=self.show_order_statistics,
                   style='Primary.TButton').grid(row=0, column=8, padx=10, pady=10)

        ttk.Button(stats_form_frame, text="📅 Hôm nay",
                   command=self.show_today_order_stats,
                   style='Primary.TButton').grid(row=0, column=9, padx=10, pady=10)

        for i in range(10):
            stats_form_frame.columnconfigure(i, weight=1)

        # Kết quả thống kê
        stats_results_frame = ttk.Frame(stats_frame)
        stats_results_frame.pack(fill='x', padx=10, pady=10)

        self.order_stats_label = tk.Label(
            stats_results_frame,
            text="Chọn thời gian và nhấn 'Xem thống kê'",
            font=('Segoe UI', 12, 'bold'),
            bg='white',
            fg='#1E3A8A'
        )
        self.order_stats_label.pack()

        # Bảng danh sách đơn hàng
        orders_list_frame = ttk.LabelFrame(order_list_tab, text="📋 Tất cả đơn hàng", style='Card.TFrame')
        orders_list_frame.pack(fill='both', expand=True, padx=15, pady=15)
        self.create_orders_list_table(orders_list_frame)

        self.load_order_stats_combobox_data()
        self.on_order_stats_type_change()

    def create_order_form(self, parent):
        """Form tạo đơn hàng"""
        label_config = {'font': ('Segoe UI', 11), 'bg': 'white', 'fg': '#1E3A8A'}

        tk.Label(parent, text="👤 Khách hàng:", **label_config).grid(row=0, column=0, padx=10, pady=8, sticky='e')
        self.customer_combo = ttk.Combobox(parent, width=25, state='readonly', font=('Segoe UI', 11))
        self.customer_combo.grid(row=0, column=1, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="📚 Chọn sách:", **label_config).grid(row=1, column=0, padx=10, pady=8, sticky='e')
        self.book_combo = ttk.Combobox(parent, width=25, state='readonly', font=('Segoe UI', 11))
        self.book_combo.grid(row=1, column=1, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="🔢 Số lượng:", **label_config).grid(row=1, column=2, padx=10, pady=8, sticky='e')
        self.order_quantity = ttk.Spinbox(parent, from_=1, to=100, width=10, font=('Segoe UI', 11))
        self.order_quantity.grid(row=1, column=3, padx=10, pady=8, sticky='w')
        self.order_quantity.set(1)

        ttk.Button(parent, text="➕ Thêm vào đơn", command=self.add_to_order, style='Primary.TButton').grid(row=1,
                                                                                                           column=4,
                                                                                                           padx=10,
                                                                                                           pady=8)

        self.order_summary = tk.Label(parent, text="Tổng tiền: 0₫", font=('Segoe UI', 14, 'bold'), bg='white',
                                      fg='#1E3A8A')
        self.order_summary.grid(row=2, column=0, columnspan=5, padx=10, pady=12)

        ttk.Button(parent, text="✅ Xác nhận đơn hàng", command=self.confirm_order, style='Primary.TButton').grid(row=3,
                                                                                                                 column=0,
                                                                                                                 padx=10,
                                                                                                                 pady=8)
        ttk.Button(parent, text="🗑️ Hủy đơn", command=self.clear_order, style='Primary.TButton').grid(row=3, column=1,
                                                                                                      padx=10, pady=8)

        for i in range(5):
            parent.columnconfigure(i, weight=1)

        self.load_combo_data()

    def create_order_items_table(self, parent):
        """Bảng sách trong đơn hàng"""
        table_frame = ttk.Frame(parent)
        table_frame.pack(fill='both', expand=True, padx=5, pady=5)

        columns = ('STT', 'Mã sách', 'Tên sách', 'Số lượng', 'Đơn giá', 'Thành tiền')
        self.order_items_tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=10,
                                             style='Modern.Treeview')

        col_configs = [
            ('STT', 60, 'center'),
            ('Mã sách', 120, 'center'),
            ('Tên sách', 300, 'w'),
            ('Số lượng', 100, 'center'),
            ('Đơn giá', 120, 'e'),
            ('Thành tiền', 150, 'e')
        ]

        for col, width, anchor in col_configs:
            self.order_items_tree.heading(col, text=col)
            self.order_items_tree.column(col, width=width, anchor=anchor)

        v_scroll = ttk.Scrollbar(table_frame, orient='vertical', command=self.order_items_tree.yview)
        self.order_items_tree.configure(yscrollcommand=v_scroll.set)

        self.order_items_tree.pack(side='left', fill='both', expand=True)
        v_scroll.pack(side='right', fill='y')

    def create_orders_list_table(self, parent):
        """Bảng danh sách đơn hàng"""
        table_frame = ttk.Frame(parent)
        table_frame.pack(fill='both', expand=True, padx=5, pady=5)

        columns = ('ID', 'Mã đơn', 'Ngày đặt', 'Khách hàng', 'Tổng tiền', 'Trạng thái')
        self.orders_tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=15,
                                        style='Modern.Treeview')

        col_configs = [
            ('ID', 60, 'center'),
            ('Mã đơn', 150, 'center'),
            ('Ngày đặt', 150, 'center'),
            ('Khách hàng', 200, 'center'),
            ('Tổng tiền', 120, 'e'),
            ('Trạng thái', 120, 'center')
        ]

        for col, width, anchor in col_configs:
            self.orders_tree.heading(col, text=col)
            self.orders_tree.column(col, width=width, anchor=anchor)

        v_scroll = ttk.Scrollbar(table_frame, orient='vertical', command=self.orders_tree.yview)
        h_scroll = ttk.Scrollbar(table_frame, orient='horizontal', command=self.orders_tree.xview)
        self.orders_tree.configure(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)

        self.orders_tree.pack(side='left', fill='both', expand=True)
        v_scroll.pack(side='right', fill='y')
        h_scroll.pack(side='bottom', fill='x')

        self.load_orders()

    def load_orders(self):
        """Tải danh sách đơn hàng"""
        for item in self.orders_tree.get_children():
            self.orders_tree.delete(item)

        try:
            orders = self.db.get_all_orders()
            if orders:
                for order in orders:
                    formatted_order = list(order)

                    if isinstance(formatted_order[2], datetime):
                        formatted_order[2] = formatted_order[2].strftime("%d/%m/%Y %H:%M")
                    elif formatted_order[2]:
                        try:
                            if isinstance(formatted_order[2], str):
                                formatted_order[2] = formatted_order[2][:10]
                        except:
                            formatted_order[2] = str(formatted_order[2])

                    try:
                        total = float(formatted_order[4] or 0)
                        formatted_order[4] = f"{total:,.0f}₫"
                    except:
                        formatted_order[4] = "0₫"

                    status = formatted_order[5]
                    if status == 'Completed':
                        formatted_order[5] = "✅ Hoàn thành"
                    elif status == 'Pending':
                        formatted_order[5] = "⏳ Chờ xử lý"
                    elif status == 'Cancelled':
                        formatted_order[5] = "❌ Đã hủy"
                    elif status == 'Processing':
                        formatted_order[5] = "🔄 Đang xử lý"
                    else:
                        formatted_order[5] = "📋 Mới"

                    if len(formatted_order) > 6:
                        formatted_order = formatted_order[:6]

                    self.orders_tree.insert('', 'end', values=formatted_order)
        except Exception:
            pass

    def load_order_stats_combobox_data(self):
        """Tải dữ liệu cho combobox thống kê"""
        try:
            current_year = datetime.now().year
            years = [str(y) for y in range(current_year - 5, current_year + 1)]
            self.order_stats_year['values'] = years
            self.order_stats_year.set(str(current_year))

            months = [f"{i:02d} - Tháng {i}" for i in range(1, 13)]
            self.order_stats_month['values'] = months
            self.order_stats_month.set(f"{datetime.now().month:02d} - Tháng {datetime.now().month}")
        except Exception:
            pass

    def add_to_order(self):
        """Thêm sách vào đơn hàng"""
        try:
            customer_idx = self.customer_combo.current()
            book_idx = self.book_combo.current()
            quantity = int(self.order_quantity.get())

            if customer_idx == -1:
                messagebox.showwarning("Cảnh báo", "Vui lòng chọn khách hàng!")
                return

            if book_idx == -1:
                messagebox.showwarning("Cảnh báo", "Vui lòng chọn sách!")
                return

            book = self.books_data[book_idx]
            if quantity > book[6]:
                messagebox.showwarning("Cảnh báo", f"Số lượng vượt quá tồn kho! Chỉ còn {book[6]} cuốn")
                return

            order_item = {
                'book_id': book[0],
                'book_code': book[1],
                'book_name': book[2],
                'quantity': quantity,
                'price': book[7],
                'total': quantity * book[7]
            }

            self.current_order_items.append(order_item)
            self.update_order_display()
        except ValueError:
            messagebox.showerror("Lỗi", "Số lượng không hợp lệ!")

    def update_order_display(self):
        """Cập nhật hiển thị đơn hàng"""
        for item in self.order_items_tree.get_children():
            self.order_items_tree.delete(item)

        total = 0
        for i, item in enumerate(self.current_order_items, 1):
            self.order_items_tree.insert('', 'end', values=(
                i, item['book_code'], item['book_name'], item['quantity'],
                f"{item['price']:,.0f}₫", f"{item['total']:,.0f}₫"
            ))
            total += item['total']

        self.order_summary.config(text=f"Tổng tiền: {total:,.0f}₫")

    def confirm_order(self):
        """Xác nhận đơn hàng"""
        if not self.current_order_items:
            messagebox.showwarning("Cảnh báo", "Đơn hàng trống!")
            return

        customer_idx = self.customer_combo.current()
        if customer_idx == -1:
            messagebox.showwarning("Cảnh báo", "Vui lòng chọn khách hàng!")
            return

        try:
            customer = self.customers_data[customer_idx]
            order_code = f"DH{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(100, 999)}"

            order_id = self.db.create_order(order_code, customer[0], datetime.now())

            if not order_id:
                messagebox.showerror("Lỗi", "Không thể tạo đơn hàng!")
                return

            success_count = 0
            for item in self.current_order_items:
                book_stock = self.db.execute_query(
                    "SELECT quantity_in_stock FROM Books WHERE book_id = ?",
                    (item['book_id'],)
                )

                if book_stock and book_stock[0][0] >= item['quantity']:
                    result = self.db.add_order_item(order_id, item['book_id'], item['quantity'], item['price'])
                    if result:
                        success_count += 1

            if success_count > 0:
                complete_result = self.db.complete_order(order_id)

                if complete_result:
                    total_amount = sum(item['total'] for item in self.current_order_items)
                    messagebox.showinfo("Thành công",
                                        f"Tạo đơn hàng thành công!\nMã đơn: {order_code}\nTổng tiền: {total_amount:,.0f}₫")
                    self.clear_order()
                    self.load_books()
                    self.load_combo_data()
                    self.load_orders()
                else:
                    messagebox.showwarning("Cảnh báo", "Đơn hàng được tạo nhưng có lỗi khi hoàn thành!")
            else:
                self.db.execute_query("DELETE FROM Orders WHERE order_id = ?", (order_id,))
                messagebox.showerror("Lỗi", "Không thể thêm sách vào đơn hàng!")

        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tạo đơn hàng!")

    def clear_order(self):
        """Làm mới đơn hàng"""
        self.current_order_items = []
        self.update_order_display()
        self.customer_combo.set('')
        self.book_combo.set('')
        self.order_quantity.set(1)

    def on_order_stats_type_change(self, event=None):
        """Xử lý khi thay đổi loại thống kê"""
        stats_type = self.order_stats_type.get()

        self.order_stats_day.grid_remove()
        self.order_stats_month.grid_remove()
        self.order_stats_year.grid_remove()

        if stats_type == 'Theo ngày':
            self.order_stats_day.grid()
        elif stats_type == 'Theo tháng':
            self.order_stats_month.grid()
            self.order_stats_year.grid()
        elif stats_type == 'Theo năm':
            self.order_stats_year.grid()

    def show_order_statistics(self):
        """Hiển thị thống kê đơn hàng"""
        try:
            stats_type = self.order_stats_type.get()

            if stats_type == 'Theo ngày':
                date_str = self.order_stats_day.get().strip()
                try:
                    date_obj = datetime.strptime(date_str, '%d/%m/%Y')
                    start_date = date_obj.replace(hour=0, minute=0, second=0, microsecond=0)
                    end_date = date_obj.replace(hour=23, minute=59, second=59, microsecond=999999)

                    stats = self.db.get_order_statistics_by_date(start_date, end_date)
                    if stats:
                        total_orders, total_revenue = stats
                        avg_order = total_revenue / total_orders if total_orders > 0 else 0

                        self.order_stats_label.config(
                            text=f"📊 Thống kê ngày {date_str}: "
                                 f"Số đơn hàng: {total_orders:,} | "
                                 f"Tổng doanh thu: {total_revenue:,.0f}₫ | "
                                 f"Đơn TB: {avg_order:,.0f}₫"
                        )
                    else:
                        self.order_stats_label.config(
                            text=f"📊 Thống kê ngày {date_str}: Không có dữ liệu"
                        )

                except ValueError:
                    messagebox.showerror("Lỗi", "Ngày không hợp lệ! Định dạng đúng: dd/mm/yyyy")

            elif stats_type == 'Theo tháng':
                month = int(self.order_stats_month.get())
                year = int(self.order_stats_year.get())

                start_date = datetime(year, month, 1, 0, 0, 0)
                if month == 12:
                    end_date = datetime(year + 1, 1, 1, 23, 59, 59) - timedelta(days=1)
                else:
                    end_date = datetime(year, month + 1, 1, 23, 59, 59) - timedelta(days=1)

                stats = self.db.get_order_statistics_by_date(start_date, end_date)
                if stats:
                    total_orders, total_revenue = stats
                    avg_order = total_revenue / total_orders if total_orders > 0 else 0

                    self.order_stats_label.config(
                        text=f"📊 Thống kê tháng {month}/{year}: "
                             f"Số đơn hàng: {total_orders:,} | "
                             f"Tổng doanh thu: {total_revenue:,.0f}₫ | "
                             f"Đơn TB: {avg_order:,.0f}₫"
                    )
                else:
                    self.order_stats_label.config(
                        text=f"📊 Thống kê tháng {month}/{year}: Không có dữ liệu"
                    )

            elif stats_type == 'Theo năm':
                year = int(self.order_stats_year.get())

                start_date = datetime(year, 1, 1, 0, 0, 0)
                end_date = datetime(year, 12, 31, 23, 59, 59)

                stats = self.db.get_order_statistics_by_date(start_date, end_date)
                if stats:
                    total_orders, total_revenue = stats
                    avg_order = total_revenue / total_orders if total_orders > 0 else 0

                    self.order_stats_label.config(
                        text=f"📊 Thống kê năm {year}: "
                             f"Số đơn hàng: {total_orders:,} | "
                             f"Tổng doanh thu: {total_revenue:,.0f}₫ | "
                             f"Đơn TB: {avg_order:,.0f}₫"
                    )
                else:
                    self.order_stats_label.config(
                        text=f"📊 Thống kê năm {year}: Không có dữ liệu"
                    )

        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi thống kê!")

    def show_today_order_stats(self):
        """Thống kê đơn hàng hôm nay"""
        try:
            today = datetime.now().strftime('%d/%m/%Y')
            self.order_stats_day.delete(0, tk.END)
            self.order_stats_day.insert(0, today)
            self.order_stats_type.set('Theo ngày')
            self.on_order_stats_type_change()
            self.show_order_statistics()
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi thống kê hôm nay!")

    # ========== QUẢN LÝ NHẬP SÁCH ==========
    def create_import_tab(self):
        """Tab nhập sách"""
        import_tab = ttk.Frame(self.notebook, style='Modern.TFrame')
        self.notebook.add(import_tab, text="📥 Nhập sách")

        import_notebook = ttk.Notebook(import_tab)
        import_notebook.pack(fill='both', expand=True, padx=10, pady=10)

        create_import_tab = ttk.Frame(import_notebook)
        import_notebook.add(create_import_tab, text="➕ Tạo phiếu nhập")

        import_list_tab = ttk.Frame(import_notebook)
        import_notebook.add(import_list_tab, text="📋 Danh sách phiếu nhập")

        # Form nhập sách
        import_frame = ttk.LabelFrame(create_import_tab, text="📦 Nhập sách mới", style='Card.TFrame')
        import_frame.pack(fill='x', padx=15, pady=15)
        self.create_import_form(import_frame)

        # Bảng sách nhập
        items_frame = ttk.LabelFrame(create_import_tab, text="📚 Sách nhập", style='Card.TFrame')
        items_frame.pack(fill='both', expand=True, padx=15, pady=15)
        self.create_import_items_table(items_frame)

        # Bảng phiếu nhập
        imports_list_frame = ttk.LabelFrame(import_list_tab, text="📋 Tất cả phiếu nhập", style='Card.TFrame')
        imports_list_frame.pack(fill='both', expand=True, padx=15, pady=15)
        self.create_imports_list_table(imports_list_frame)

    def create_import_form(self, parent):
        """Form nhập sách"""
        label_config = {'font': ('Segoe UI', 11), 'bg': 'white', 'fg': '#1E3A8A'}

        tk.Label(parent, text="🏢 Nhà cung cấp:", **label_config).grid(row=0, column=0, padx=10, pady=8, sticky='e')
        self.supplier_entry = ttk.Entry(parent, width=25, font=('Segoe UI', 11))
        self.supplier_entry.grid(row=0, column=1, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="📚 Chọn sách:", **label_config).grid(row=1, column=0, padx=10, pady=8, sticky='e')
        self.import_book_combo = ttk.Combobox(parent, width=25, state='readonly', font=('Segoe UI', 11))
        self.import_book_combo.grid(row=1, column=1, padx=10, pady=8, sticky='w')

        tk.Label(parent, text="🔢 Số lượng:", **label_config).grid(row=1, column=2, padx=10, pady=8, sticky='e')
        self.import_quantity = ttk.Spinbox(parent, from_=1, to=1000, width=10, font=('Segoe UI', 11))
        self.import_quantity.grid(row=1, column=3, padx=10, pady=8, sticky='w')
        self.import_quantity.set(1)

        tk.Label(parent, text="💰 Giá nhập:", **label_config).grid(row=1, column=4, padx=10, pady=8, sticky='e')
        self.import_price = ttk.Entry(parent, width=15, font=('Segoe UI', 11))
        self.import_price.grid(row=1, column=5, padx=10, pady=8, sticky='w')

        ttk.Button(parent, text="➕ Thêm vào phiếu", command=self.add_to_import, style='Primary.TButton').grid(row=1,
                                                                                                              column=6,
                                                                                                              padx=10,
                                                                                                              pady=8)

        self.import_summary = tk.Label(parent, text="Tổng tiền: 0₫", font=('Segoe UI', 14, 'bold'), bg='white',
                                       fg='#1E3A8A')
        self.import_summary.grid(row=2, column=0, columnspan=7, padx=10, pady=12)

        ttk.Button(parent, text="✅ Xác nhận nhập", command=self.confirm_import, style='Primary.TButton').grid(row=3,
                                                                                                              column=0,
                                                                                                              padx=10,
                                                                                                              pady=8)
        ttk.Button(parent, text="🗑️ Hủy phiếu", command=self.clear_import, style='Primary.TButton').grid(row=3,
                                                                                                         column=1,
                                                                                                         padx=10,
                                                                                                         pady=8)

        for i in range(7):
            parent.columnconfigure(i, weight=1)

        self.load_import_combo_data()

    def create_import_items_table(self, parent):
        """Bảng sách nhập"""
        table_frame = ttk.Frame(parent)
        table_frame.pack(fill='both', expand=True, padx=5, pady=5)

        columns = ('STT', 'Mã sách', 'Tên sách', 'Số lượng', 'Giá nhập', 'Thành tiền')
        self.import_items_tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=10,
                                              style='Modern.Treeview')

        col_configs = [
            ('STT', 60, 'center'),
            ('Mã sách', 120, 'center'),
            ('Tên sách', 300, 'w'),
            ('Số lượng', 100, 'center'),
            ('Giá nhập', 120, 'e'),
            ('Thành tiền', 150, 'e')
        ]

        for col, width, anchor in col_configs:
            self.import_items_tree.heading(col, text=col)
            self.import_items_tree.column(col, width=width, anchor=anchor)

        v_scroll = ttk.Scrollbar(table_frame, orient='vertical', command=self.import_items_tree.yview)
        self.import_items_tree.configure(yscrollcommand=v_scroll.set)

        self.import_items_tree.pack(side='left', fill='both', expand=True)
        v_scroll.pack(side='right', fill='y')

    def create_imports_list_table(self, parent):
        """Bảng phiếu nhập"""
        table_frame = ttk.Frame(parent)
        table_frame.pack(fill='both', expand=True, padx=5, pady=5)

        columns = ('ID', 'Mã phiếu', 'Ngày nhập', 'Nhà cung cấp', 'Tổng tiền')
        self.imports_tree = ttk.Treeview(table_frame, columns=columns, show='headings', height=15,
                                         style='Modern.Treeview')

        col_configs = [
            ('ID', 60, 'center'),
            ('Mã phiếu', 120, 'center'),
            ('Ngày nhập', 150, 'center'),
            ('Nhà cung cấp', 200, 'w'),
            ('Tổng tiền', 120, 'e')
        ]

        for col, width, anchor in col_configs:
            self.imports_tree.heading(col, text=col)
            self.imports_tree.column(col, width=width, anchor=anchor)

        v_scroll = ttk.Scrollbar(table_frame, orient='vertical', command=self.imports_tree.yview)
        h_scroll = ttk.Scrollbar(table_frame, orient='horizontal', command=self.imports_tree.xview)
        self.imports_tree.configure(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)

        self.imports_tree.pack(side='left', fill='both', expand=True)
        v_scroll.pack(side='right', fill='y')
        h_scroll.pack(side='bottom', fill='x')

        self.load_imports()

    def load_imports(self):
        """Tải danh sách phiếu nhập"""
        for item in self.imports_tree.get_children():
            self.imports_tree.delete(item)

        try:
            imports = self.db.get_all_imports()
            if imports:
                for import_data in imports:
                    formatted_import = list(import_data)

                    if isinstance(formatted_import[2], datetime):
                        formatted_import[2] = formatted_import[2].strftime("%d/%m/%Y %H:%M")

                    try:
                        total = float(formatted_import[4] or 0)
                        formatted_import[4] = f"{total:,.0f}₫"
                    except:
                        formatted_import[4] = "0₫"

                    self.imports_tree.insert('', 'end', values=formatted_import)
        except Exception:
            pass

    def add_to_import(self):
        """Thêm sách vào phiếu nhập"""
        try:
            book_idx = self.import_book_combo.current()
            quantity = int(self.import_quantity.get())
            price = float(self.import_price.get())

            if book_idx == -1:
                messagebox.showwarning("Cảnh báo", "Vui lòng chọn sách!")
                return

            if quantity <= 0 or price <= 0:
                messagebox.showwarning("Cảnh báo", "Số lượng và giá phải lớn hơn 0!")
                return

            book = self.books_data[book_idx]

            import_item = {
                'book_id': book[0],
                'book_code': book[1],
                'book_name': book[2],
                'quantity': quantity,
                'price': price,
                'total': quantity * price
            }

            self.current_import_items.append(import_item)
            self.update_import_display()
        except ValueError:
            messagebox.showerror("Lỗi", "Số lượng và giá phải là số!")

    def update_import_display(self):
        """Cập nhật hiển thị phiếu nhập"""
        for item in self.import_items_tree.get_children():
            self.import_items_tree.delete(item)

        total = 0
        for i, item in enumerate(self.current_import_items, 1):
            self.import_items_tree.insert('', 'end', values=(
                i, item['book_code'], item['book_name'], item['quantity'],
                f"{item['price']:,.0f}₫", f"{item['total']:,.0f}₫"
            ))
            total += item['total']

        self.import_summary.config(text=f"Tổng tiền: {total:,.0f}₫")

    def confirm_import(self):
        """Xác nhận phiếu nhập"""
        if not self.current_import_items:
            messagebox.showwarning("Cảnh báo", "Phiếu nhập trống!")
            return

        try:
            supplier = self.supplier_entry.get().strip()
            import_code = f"PN{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(100, 999)}"

            import_id = self.db.create_import(import_code, datetime.now(), supplier)

            if not import_id:
                messagebox.showerror("Lỗi", "Không thể tạo phiếu nhập!")
                return

            success_count = 0
            for item in self.current_import_items:
                result = self.db.add_import_item(import_id, item['book_id'], item['quantity'], item['price'])
                if result:
                    success_count += 1

            if success_count > 0:
                total_amount = sum(item['total'] for item in self.current_import_items)
                messagebox.showinfo("Thành công",
                                    f"Tạo phiếu nhập thành công!\nMã phiếu: {import_code}\nTổng tiền: {total_amount:,.0f}₫")
                self.clear_import()
                self.load_books()
                self.load_imports()
            else:
                self.db.execute_query("DELETE FROM ImportBooks WHERE import_id = ?", (import_id,))
                messagebox.showerror("Lỗi", "Không thể thêm sách vào phiếu nhập!")

        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tạo phiếu nhập!")

    def clear_import(self):
        """Làm mới phiếu nhập"""
        self.current_import_items = []
        self.update_import_display()
        self.supplier_entry.delete(0, tk.END)
        self.import_book_combo.set('')
        self.import_quantity.set(1)
        self.import_price.delete(0, tk.END)

    # ========== BÁO CÁO ==========
    def create_reports_tab(self):
        """Tab báo cáo"""
        reports_tab = ttk.Frame(self.notebook, style='Modern.TFrame')
        self.notebook.add(reports_tab, text="📊 Báo cáo")

        report_frame = ttk.LabelFrame(reports_tab, text="📈 Báo cáo cơ bản", style='Card.TFrame')
        report_frame.pack(fill='x', padx=15, pady=15)

        basic_reports = [
            ("🔥 Sách bán chạy", self.show_best_sellers),
            ("👑 Khách hàng mua nhiều", self.show_top_customers),
            ("📦 Tồn kho theo NXB", self.show_inventory_report),
            ("⭐ Khách hàng thường xuyên", self.show_regular_customers),
            ("💰 Doanh thu theo sách", self.show_revenue_by_book)
        ]

        for i, (text, command) in enumerate(basic_reports):
            btn = ttk.Button(report_frame, text=text, command=command, style='Primary.TButton', width=20)
            btn.grid(row=0, column=i, padx=8, pady=10, sticky='ew')
            report_frame.columnconfigure(i, weight=1)

        results_frame = ttk.LabelFrame(reports_tab, text="📊 Kết quả báo cáo", style='Card.TFrame')
        results_frame.pack(fill='both', expand=True, padx=15, pady=15)

        self.report_tree = ttk.Treeview(results_frame, show='headings', height=15, style='Modern.Treeview')
        self.report_tree.pack(fill='both', expand=True, padx=10, pady=10)

        v_scroll = ttk.Scrollbar(results_frame, orient='vertical', command=self.report_tree.yview)
        h_scroll = ttk.Scrollbar(results_frame, orient='horizontal', command=self.report_tree.xview)
        self.report_tree.configure(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)

        v_scroll.pack(side='right', fill='y')
        h_scroll.pack(side='bottom', fill='x')

    # ========== CHỨC NĂNG BÁO CÁO ==========
    def show_best_sellers(self):
        """Hiển thị sách bán chạy"""
        try:
            years_query = """
                SELECT DISTINCT YEAR(order_date) as year
                FROM Orders 
                WHERE status = 'Completed'
                ORDER BY year DESC
            """

            years_data = self.db.execute_query(years_query)

            if not years_data:
                messagebox.showinfo("Thông báo", "Không có dữ liệu đơn hàng hoàn thành!")
                return

            result_data = []

            for year_row in years_data:
                year = year_row[0]

                months_query = """
                    SELECT DISTINCT MONTH(order_date) as month
                    FROM Orders 
                    WHERE status = 'Completed' AND YEAR(order_date) = ?
                    ORDER BY month
                """

                months_data = self.db.execute_query(months_query, (year,))

                if not months_data:
                    continue

                for month_row in months_data:
                    month = month_row[0]

                    try:
                        data = self.db.get_best_selling_books(year, month, 1)

                        if data and len(data) > 0:
                            book = data[0]
                            month_name = f"Tháng {month}"

                            if len(book) >= 2:
                                book_name = book[1]
                                if len(book_name) > 50:
                                    book_name = book_name[:50] + "..."

                                sold = book[4] if len(book) > 4 else 0

                                result_data.append([
                                    month_name,
                                    str(year),
                                    book_name,
                                    f"{int(sold):,}" if sold else "0"
                                ])
                            else:
                                result_data.append([
                                    f"Tháng {month}",
                                    str(year),
                                    "Không có dữ liệu chi tiết",
                                    "0"
                                ])
                        else:
                            result_data.append([
                                f"Tháng {month}",
                                str(year),
                                "Không có sách bán chạy",
                                "0"
                            ])

                    except Exception:
                        result_data.append([
                            f"Tháng {month}",
                            str(year),
                            "Lỗi khi tải dữ liệu",
                            "0"
                        ])
                        continue

            if result_data:
                columns = ['Tháng', 'Năm', 'Sách bán chạy nhất', 'Số lượng bán']

                for item in self.report_tree.get_children():
                    self.report_tree.delete(item)

                self.report_tree['columns'] = columns

                col_widths = [80, 70, 350, 100]
                col_aligns = ['center', 'center', 'w', 'center']

                for i, col in enumerate(columns):
                    self.report_tree.heading(col, text=col)
                    width = col_widths[i] if i < len(col_widths) else 150
                    align = col_aligns[i] if i < len(col_aligns) else 'w'
                    self.report_tree.column(col, width=width, anchor=align)

                for i, row in enumerate(result_data):
                    tags = ()
                    if i % 2 == 0:
                        tags = ('evenrow',)
                    else:
                        tags = ('oddrow',)

                    self.report_tree.insert('', 'end', values=row, tags=tags)

                self.report_tree.tag_configure('evenrow', background='#FFFFFF')
                self.report_tree.tag_configure('oddrow', background='#F8FAFC')

                messagebox.showinfo("Thành công", f"Đã tải {len(result_data)} tháng có dữ liệu!")
            else:
                messagebox.showinfo("Thông báo", "Không có dữ liệu sách bán chạy!")

        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tải báo cáo!")

    def show_top_customers(self):
        """Hiển thị khách hàng mua nhiều nhất"""
        try:
            data = self.db.get_customers_by_purchases(10)

            if data:
                for item in self.report_tree.get_children():
                    self.report_tree.delete(item)

                columns = ['Xếp hạng', 'Mã KH', 'Họ tên', 'Số sách mua', 'Tổng chi tiêu']
                self.report_tree['columns'] = columns

                col_widths = [80, 100, 250, 120, 150]
                col_aligns = ['center', 'center', 'w', 'center', 'e']

                for i, col in enumerate(columns):
                    self.report_tree.heading(col, text=col)
                    width = col_widths[i] if i < len(col_widths) else 150
                    align = col_aligns[i] if i < len(col_aligns) else 'w'
                    self.report_tree.column(col, width=width, anchor=align)

                for i, row in enumerate(data):
                    rank = i + 1
                    rank_icon = "🥇" if rank == 1 else ("🥈" if rank == 2 else ("🥉" if rank == 3 else f"{rank}."))

                    books_bought = row[3] if len(row) > 3 and row[3] else 0
                    total_spent = row[5] if len(row) > 5 and row[5] else 0

                    formatted_row = [
                        rank_icon,
                        row[0] if len(row) > 0 else "",
                        row[1] if len(row) > 1 else "",
                        f"{int(books_bought):,}",
                        f"{float(total_spent):,.0f}₫"
                    ]

                    tags = ()
                    if rank <= 3:
                        tags = ('top3',)
                    elif i % 2 == 0:
                        tags = ('evenrow',)
                    else:
                        tags = ('oddrow',)

                    self.report_tree.insert('', 'end', values=formatted_row, tags=tags)

                self.report_tree.tag_configure('top3', background='#E8F5E8', font=('Segoe UI', 11))
                self.report_tree.tag_configure('evenrow', background='#FFFFFF')
                self.report_tree.tag_configure('oddrow', background='#F8FAFC')

            else:
                messagebox.showinfo("Thông báo", "Không có dữ liệu khách hàng!")

        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tải báo cáo!")

    def show_inventory_report(self):
        """Hiển thị tồn kho theo NXB"""
        try:
            data = self.db.get_inventory_by_publisher()
            if data:
                columns = ['Nhà xuất bản', 'Số đầu sách', 'Tổng tồn kho', 'Tổng giá trị']
                self.display_report(data, columns,
                                    column_widths=[200, 120, 150, 150],
                                    aligns=['center', 'center', 'center', 'e'])
            else:
                messagebox.showinfo("Thông báo", "Không có dữ liệu tồn kho!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tải báo cáo!")

    def show_regular_customers(self):
        """Hiển thị khách hàng thường xuyên"""
        try:
            data = self.db.get_regular_customers(2)
            if data:
                columns = ['Mã KH', 'Họ tên', 'Số ĐT', 'Số đơn', 'Tổng chi tiêu']
                self.display_report(data, columns,
                                    column_widths=[100, 200, 120, 100, 150],
                                    aligns=['center', 'w', 'center', 'center', 'e'])
            else:
                messagebox.showinfo("Thông báo", "Không có dữ liệu khách hàng thường xuyên!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tải báo cáo!")

    def show_revenue_by_book(self):
        """Hiển thị doanh thu theo sách"""
        try:
            data = self.db.get_revenue_by_book()
            if data:
                columns = ['Mã sách', 'Tên sách', 'Tác giả', 'NXB', 'Số đơn', 'Số lượng bán', 'Doanh thu']
                self.display_report(data, columns,
                                    column_widths=[100, 250, 150, 150, 100, 120, 150],
                                    aligns=['center', 'w', 'w', 'center', 'center', 'center', 'e'])
            else:
                messagebox.showinfo("Thông báo", "Không có dữ liệu doanh thu!")
        except Exception:
            messagebox.showerror("Lỗi", "Lỗi khi tải báo cáo!")

    def display_report(self, data, columns, column_widths=None, aligns=None):
        """Hiển thị báo cáo"""
        try:
            for item in self.report_tree.get_children():
                self.report_tree.delete(item)

            self.report_tree['columns'] = columns

            if column_widths is None:
                column_widths = [150] * len(columns)
            if aligns is None:
                aligns = ['w'] * len(columns)

            for i, col in enumerate(columns):
                self.report_tree.heading(col, text=col)
                width = column_widths[i] if i < len(column_widths) else 150
                align = aligns[i] if i < len(aligns) else 'w'
                self.report_tree.column(col, width=width, anchor=align)

            for row in data:
                formatted_row = []
                for i, value in enumerate(row):
                    if value is None:
                        formatted_row.append("")
                    elif isinstance(value, (int, float)):
                        column_name = columns[i].lower() if i < len(columns) else ""

                        money_keywords = ['doanh thu', 'tổng giá', 'tổng chi', 'thành tiền', 'giá trị', 'tiền']
                        if any(keyword in column_name for keyword in money_keywords):
                            formatted_value = f"{float(value):,.0f} đ".replace(",", "X").replace(".", ",").replace("X",
                                                                                                                   ".")
                            formatted_row.append(formatted_value)
                        else:
                            formatted_row.append(f"{int(value):,}")
                    else:
                        formatted_row.append(str(value))

                self.report_tree.insert('', 'end', values=formatted_row)

        except Exception:
            pass

    def load_combo_data(self):
        """Tải dữ liệu cho combobox"""
        try:
            customers = self.db.get_all_customers()
            if customers:
                customer_list = [f"{cust[1]} - {cust[2]}" for cust in customers]
                self.customer_combo['values'] = customer_list
                self.customers_data = customers

            books = self.db.get_all_books()
            if books:
                book_list = [f"{book[1]} - {book[2]}" for book in books]
                self.book_combo['values'] = book_list
                self.books_data = books
        except Exception:
            pass

    def load_import_combo_data(self):
        """Tải dữ liệu sách cho combobox nhập hàng"""
        try:
            books = self.db.get_all_books()
            if books:
                book_list = [f"{book[1]} - {book[2]}" for book in books]
                self.import_book_combo['values'] = book_list
        except Exception:
            pass

    def show_books_tab(self):
        """Chuyển đến tab sách"""
        self.notebook.select(1)

    def show_customers_tab(self):
        """Chuyển đến tab khách hàng"""
        self.notebook.select(2)

    def show_orders_tab(self):
        """Chuyển đến tab đơn hàng"""
        self.notebook.select(3)

    def show_import_tab(self):
        """Chuyển đến tab nhập sách"""
        self.notebook.select(4)

    def show_reports_tab(self):
        """Chuyển đến tab báo cáo"""
        self.notebook.select(5)

if __name__ == "__main__":
    root = tk.Tk()
    app = ModernBookStoreSystem(root)
    root.mainloop()