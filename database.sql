CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  email VARCHAR(255) NOT NULL
);

CREATE TABLE cars (
  car_id SERIAL PRIMARY KEY,
  make VARCHAR(255) NOT NULL,
  model VARCHAR(255) NOT NULL,
  year INTEGER NOT NULL,
  color VARCHAR(255) NOT NULL,
  rental_price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE rentals (
  rental_id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  car_id INTEGER NOT NULL REFERENCES cars(car_id),
  rental_start_date DATE NOT NULL,
  rental_end_date DATE NOT NULL,
  total_cost DECIMAL(10, 2) NOT NULL
);

CREATE TABLE reservations (
  reservation_id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  car_id INTEGER NOT NULL REFERENCES cars(car_id),
  reservation_start_date DATE NOT NULL,
  reservation_end_date DATE NOT NULL,
  status VARCHAR(255) NOT NULL
);

CREATE TABLE locations (
  location_id SERIAL PRIMARY KEY,
  address VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  hours_of_operation VARCHAR(255) NOT NULL
);

CREATE TABLE employees (
  employee_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  email VARCHAR(255) NOT NULL,
  location_id INTEGER NOT NULL REFERENCES locations(location_id)
);

CREATE TABLE transactions (
  transaction_id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  transaction_date DATE NOT NULL,
  transaction_type VARCHAR(255) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL
);

CREATE TABLE maintenance (
  maintenance_id SERIAL PRIMARY KEY,
  car_id INTEGER NOT NULL REFERENCES cars(car_id),
  maintenance_date DATE NOT NULL,
  maintenance_type VARCHAR(255) NOT NULL,
  cost DECIMAL(10, 2) NOT NULL
);
INSERT INTO customers (name, address, phone_number, email)
VALUES
  ('John Smith', '123 Main St, Anytown USA', '555-1234', 'john.smith@example.com'),
  ('Jane Doe', '456 Elm St, Anytown USA', '555-5678', 'jane.doe@example.com'),
  ('Bob Johnson', '789 Oak St, Anytown USA', '555-9012', 'bob.johnson@example.com');

-- Cars
INSERT INTO cars (make, model, year, color, rental_price)
VALUES
  ('Toyota', 'Corolla', 2020, 'Red', 50.00),
  ('Honda', 'Civic', 2019, 'Blue', 55.00),
  ('Ford', 'Mustang', 2021, 'Yellow', 75.00);

-- Rentals
INSERT INTO rentals (customer_id, car_id, rental_start_date, rental_end_date, total_cost)
VALUES
  (1, 1, '2023-05-01', '2023-05-05', 200.00),
  (2, 2, '2023-05-02', '2023-05-06', 220.00),
  (3, 3, '2023-05-03', '2023-05-07', 300.00);

-- Reservations
INSERT INTO reservations (customer_id, car_id, reservation_start_date, reservation_end_date, status)
VALUES
  (1, 2, '2023-05-10', '2023-05-15', 'Pending'),
  (2, 3, '2023-05-12', '2023-05-17', 'Confirmed'),
  (3, 1, '2023-05-14', '2023-05-19', 'Pending');

-- Locations
INSERT INTO locations (address, phone_number, hours_of_operation)
VALUES
  ('100 Main St, Anytown USA', '555-1111', 'Mon-Fri 9am-5pm'),
  ('200 Elm St, Anytown USA', '555-2222', 'Mon-Fri 9am-5pm'),
  ('300 Oak St, Anytown USA', '555-3333', 'Mon-Fri 9am-5pm');

-- Employees
INSERT INTO employees (name, address, phone_number, email, location_id)
VALUES
  ('Tom Jones', '100 Main St, Anytown USA', '555-4444', 'tom.jones@example.com', 1),
  ('Sue Smith', '200 Elm St, Anytown USA', '555-5555', 'sue.smith@example.com', 2),
  ('Bob Brown', '300 Oak St, Anytown USA', '555-6666', 'bob.brown@example.com', 3);

-- Transactions
INSERT INTO transactions (customer_id, transaction_date, transaction_type, amount)
VALUES
  (1, '2023-05-01', 'Rental', 200.00),
  (2, '2023-05-02', 'Rental', 220.00),
  (3, '2023-05-03', 'Rental', 300.00);

-- Maintenance
INSERT INTO maintenance (car_id, maintenance_date, maintenance_type, cost)
VALUES
  (1, '2023-04-01', 'Oil Change', 50.00),
  (2, '2023-04-15', 'Tire Rotation', 25.00),
  (3, '2023-05-01', 'Brake Replacement', 150.00);
  
  CREATE OR REPLACE FUNCTION update_rental_cost()
RETURNS TRIGGER AS $$
BEGIN
  NEW.total_cost = (NEW.rental_end_date - NEW.rental_start_date) * (SELECT rental_price FROM cars WHERE car_id = NEW.car_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rental_end_date_trigger
BEFORE UPDATE ON rentals
FOR EACH ROW
WHEN (OLD.rental_end_date IS DISTINCT FROM NEW.rental_end_date)
EXECUTE FUNCTION update_rental_cost();
--trigger-2---
CREATE OR REPLACE FUNCTION insert_rental_transaction()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO transactions (customer_id, transaction_date, transaction_type, amount)
  VALUES (NEW.customer_id, NEW.rental_end_date, 'Rental', NEW.total_cost);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rental_completed_trigger
AFTER UPDATE ON rentals
FOR EACH ROW
WHEN (OLD.rental_end_date IS DISTINCT FROM NEW.rental_end_date AND NEW.rental_end_date IS NOT NULL)
EXECUTE FUNCTION insert_rental_transaction();
---trigger3----
CREATE OR REPLACE FUNCTION update_reservation_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.reservation_end_date <= CURRENT_DATE THEN
    NEW.status = 'Expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reservation_status_trigger
BEFORE UPDATE ON reservations
FOR EACH ROW
WHEN (OLD.reservation_end_date IS DISTINCT FROM NEW.reservation_end_date)
EXECUTE FUNCTION update_reservation_status();
--trigger4---
CREATE OR REPLACE FUNCTION update_maintenance_cost()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.maintenance_type = 'Oil Change' THEN
    NEW.cost = 50.00;
  ELSIF NEW.maintenance_type = 'Tire Rotation' THEN
    NEW.cost = 25.00;
  ELSIF NEW.maintenance_type = 'Brake Replacement' THEN
    NEW.cost = 150.00;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER maintenance_type_trigger
BEFORE UPDATE ON maintenance
FOR EACH ROW
WHEN (OLD.maintenance_type IS DISTINCT FROM NEW.maintenance_type)
EXECUTE FUNCTION update_maintenance_cost();
---trigger5----
CREATE OR REPLACE FUNCTION update_car_rental_price()
RETURNS TRIGGER AS $$
BEGIN
  NEW.rental_price = CASE
    WHEN NEW.year >= 2021 THEN 75.00
    WHEN NEW.year >= 2020 THEN 70.00
    ELSE 65.00
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER car_year_trigger
BEFORE UPDATE ON cars
FOR EACH ROW
WHEN (OLD.year IS DISTINCT FROM NEW.year)
EXECUTE FUNCTION update_car_rental_price();
--v1---
CREATE VIEW rental_info AS
SELECT rental_id, customers.name AS customer_name, cars.make, cars.model, rental_start_date, rental_end_date, total_cost
FROM rentals
JOIN customers ON rentals.customer_id = customers.customer_id
JOIN cars ON rentals.car_id = cars.car_id;
--v2---
CREATE VIEW reservation_info AS
SELECT reservation_id, customers.name AS customer_name, cars.make, cars.model, reservation_start_date, reservation_end_date, status
FROM reservations
JOIN customers ON reservations.customer_id = customers.customer_id
JOIN cars ON reservations.car_id = cars.car_id;
---v3---
CREATE VIEW transaction_info AS
SELECT transaction_id, customers.name AS customer_name, transaction_date, transaction_type, amount
FROM transactions
JOIN customers ON transactions.customer_id = customers.customer_id;
---v4----
CREATE VIEW maintenance_info AS
SELECT maintenance_id, cars.make, cars.model, maintenance_date, maintenance_type, cost
FROM maintenance
JOIN cars ON maintenance.car_id = cars.car_id;
---v5----
CREATE VIEW employee_info AS
SELECT employee_id, name, email, locations.address AS location_address, locations.phone_number AS location_phone_number, hours_of_operation
FROM employees
JOIN locations ON employees.location_id = locations.location_id;
