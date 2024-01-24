import streamlit as st
import psycopg2

# Connect to the database
def create_connection():
    conn = psycopg2.connect(
        host="localhost",
        database="project_1",
        user="postgres",
        password="apple121"
    )
    return conn

# Define a context manager for executing database operations
@st.cache_resource(show_spinner=False)
def get_cursor():
    conn = create_connection()
    cur = conn.cursor()
    return cur

# Define functions to retrieve data from each table
@st.cache_data(show_spinner=False)
def get_table_data(table_name):
    cur = get_cursor()
    cur.execute(f"SELECT * FROM {table_name}")
    rows = cur.fetchall()
    return rows

# Define functions to insert data into each table
def insert_data(table_name, values):
    cur = get_cursor()
    columns = ", ".join(values.keys())
    placeholders = ", ".join(["%s"] * len(values))
    query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
    cur.execute(query, list(values.values()))
    cur.connection.commit()
    st.success(f"{table_name.capitalize()} added successfully!")

# Define functions to update data in each table
def update_data(table_name, id, values):
    cur = get_cursor()
    set_values = ", ".join([f"{key} = %s" for key in values.keys()])
    query = f"UPDATE {table_name} SET {set_values} WHERE id = %s"
    cur.execute(query, list(values.values()) + [id])
    cur.connection.commit()
    st.success(f"{table_name.capitalize()} updated successfully!")

# Define functions to delete data from each table
def delete_data(table_name, id):
    cur = get_cursor()
    query = f"DELETE FROM {table_name} WHERE id = %s"
    cur.execute(query, [id])
    cur.connection.commit()
    st.success(f"{table_name.capitalize()} deleted successfully!")

# Define a function to display a table with CRUD operations
def display_table(table_name, fields):
    st.subheader(f"{table_name.capitalize()} Table")
    entries = get_table_data(table_name)
    for entry in entries:
        st.write(entry)
        if st.button(f"Edit {table_name.capitalize()} {entry[0]}", key=f"edit_{table_name}_{entry[0]}"):
            edit_values = {}
            for field in fields:
                edit_values[field] = st.text_input(field.capitalize(), value=entry[fields.index(field)+1])
            if st.button(f"Update {table_name.capitalize()} {entry[0]}", key=f"update_{table_name}_{entry[0]}"):
                update_data(table_name, entry[0], edit_values)
        if st.button(f"Delete {table_name.capitalize()} {entry[0]}", key=f"delete_{table_name}_{entry[0]}"):
            if st.button(f"Confirm Delete {table_name.capitalize()} {entry[0]}", key=f"confirm_delete_{table_name}_{entry[0]}"):
                delete_data(table_name, entry[0])

# Define a function to add a new entry to a table
def add_entry(table_name, fields):
    st.subheader(f"Add a new {table_name.capitalize()}")
    values = {}
    for field in fields:
        values[field] = st.text_input(field.capitalize())
    if st.button(f"Add {table_name.capitalize()}", key=f"add_{table_name}"):
        insert_data(table_name, values)

# Define the main app function
def app():
    st.title("Car Rental Database")

    # Define table names and fields
    tables = {
        "customers": ["name", "address", "phone_number", "email"],
        "cars": ["make", "model", "year", "color", "rental_price"],
        "rentals": ["customer_id", "car_id", "rental_start_date", "rental_end_date", "total_cost"],
        "locations": ["address", "phone_number", "hours_of_operation"],
        "employees": ["name", "address", "phone_number", "email", "location_id"],
        "transactions": ["customer_id", "transaction_date", "transaction_type", "amount"],
        "maintenance": ["car_id", "maintenance_date", "maintenance_type", "cost"]
    }

    # Define the sidebar menu
    menu = ["Home"]
    for table_name in tables.keys():
        menu.append(f"Add {table_name.capitalize()}")
        menu.append(f"View {table_name.capitalize()} Table")
    menu.append("About")

    # Display the selected page
    choice = st.sidebar.selectbox("Select an option", menu)
    if choice == "Home":
        st.subheader("Welcome to the Car Rental Database!")
    elif choice == "About":
        st.subheader("About")
        st.write("This app was created using Streamlit and PostgreSQL.")
    else:
        table_name = choice.split()[1].lower()
        fields = tables[table_name]
        if choice.startswith("Add"):
            add_entry(table_name, fields)
        elif choice.startswith("View"):
            display_table(table_name, fields)

if __name__ == "__main__":
    app()
