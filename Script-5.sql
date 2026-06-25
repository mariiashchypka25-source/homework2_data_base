
TRUNCATE TABLE opt_orders, opt_products, opt_clients RESTART IDENTITY CASCADE;

INSERT INTO opt_clients (id, name, surname, email, phone, address, status)
SELECT 
    gen_random_uuid(),
    'Name' || g,
    'Surname' || g,
    'user' || g || '@test.com',
    '123456789',
    (ARRAY['Main Street 1', 'Second Avenue', 'Green Street', 'Central Blvd'])[floor(random()*4)+1],
    (ARRAY['active', 'inactive'])[floor(random()*2)+1]
FROM generate_series(1, 5000) AS g;

INSERT INTO opt_products (product_name, product_category, description)
SELECT 
    'Product ' || g,
    'Category' || (floor(random()*5)+1),
    'Description ' || g
FROM generate_series(1, 100) AS g;

INSERT INTO opt_orders (order_date, client_id, product_id)
SELECT 
    CURRENT_DATE - (random() * 365)::integer,
    c.id,
    p_ids[floor(random() * array_length(p_ids, 1)) + 1]
FROM opt_clients c
CROSS JOIN (SELECT array_agg(product_id) as p_ids FROM opt_products) AS products
CROSS JOIN generate_series(1, 10) 
WHERE c.status = 'active';