-- Sample users
INSERT INTO users (username, email, first_name, last_name, role, active) VALUES
    ('admin',    'admin@myapp.com',    'Admin',   'User',    'ADMIN',     TRUE),
    ('jdoe',     'john.doe@myapp.com', 'John',    'Doe',     'USER',      TRUE),
    ('jsmith',   'jane.smith@myapp.com','Jane',   'Smith',   'MODERATOR', TRUE),
    ('bwilson',  'bob.wilson@myapp.com','Bob',    'Wilson',  'USER',      TRUE),
    ('agarcia',  'alice.garcia@myapp.com','Alice','Garcia',  'USER',      TRUE);

-- Sample products
INSERT INTO products (name, description, price, category, stock, image_url, active) VALUES
    ('Wireless Headphones',   'Premium noise-cancelling over-ear headphones with 30-hour battery life.',          149.99, 'Electronics', 250, 'https://images.example.com/headphones.jpg',   TRUE),
    ('Ergonomic Keyboard',    'Mechanical keyboard with split design and programmable keys.',                      89.99,  'Electronics', 180, 'https://images.example.com/keyboard.jpg',     TRUE),
    ('Running Shoes',         'Lightweight running shoes with responsive cushioning and breathable mesh upper.',   129.99, 'Footwear',    320, 'https://images.example.com/shoes.jpg',        TRUE),
    ('Stainless Steel Bottle','Double-wall insulated water bottle, keeps drinks cold 24h or hot 12h.',             34.99,  'Accessories', 500, 'https://images.example.com/bottle.jpg',       TRUE),
    ('Laptop Stand',          'Adjustable aluminium laptop stand with cable management and ventilation.',           59.99,  'Accessories', 150, 'https://images.example.com/stand.jpg',        TRUE),
    ('Organic Coffee Beans',  'Single-origin arabica beans, medium roast, 1 kg bag.',                              24.99,  'Food',        400, 'https://images.example.com/coffee.jpg',       TRUE),
    ('Yoga Mat',              'Non-slip natural rubber yoga mat, 6 mm thick, with carrying strap.',                 45.99,  'Fitness',     220, 'https://images.example.com/yogamat.jpg',      TRUE),
    ('Desk Lamp',             'LED desk lamp with adjustable brightness, colour temperature, and USB charging.',    69.99,  'Home',        175, 'https://images.example.com/lamp.jpg',         TRUE);
