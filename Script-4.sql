-- 1. Non-optimized query (зроблено за аналогією тільки перемінено ситуацію вона описана в рідмі)

EXPLAIN ANALYZE
SELECT
    (
        SELECT CONCAT(name, ' ', surname, ': ', cnt)
        FROM (
            SELECT name, surname, COUNT(*) AS cnt
            FROM (
                SELECT
                    o.order_id,
                    o.order_date,
                    p.product_id,
                    p.product_category,
                    c.id AS client_id,
                    c.name,
                    c.surname
                FROM opt_orders AS o
                JOIN opt_products AS p
                    ON o.product_id = p.product_id
                JOIN opt_clients AS c
                    ON o.client_id = c.id
                WHERE c.status = 'active'
                  AND p.product_category = 'Category4'
                  AND c.address LIKE '%Street%'
            ) AS sub1
            GROUP BY name, surname
        ) AS sub2
        WHERE cnt = (
            SELECT MIN(cnt)
            FROM (
                SELECT COUNT(*) AS cnt
                FROM (
                    SELECT
                        o.order_id,
                        o.order_date,
                        p.product_id,
                        p.product_category,
                        c.id AS client_id,
                        c.name,
                        c.surname
                    FROM opt_orders AS o
                    JOIN opt_products AS p
                        ON o.product_id = p.product_id
                    JOIN opt_clients AS c
                        ON o.client_id = c.id
                    WHERE c.status = 'active'
                      AND p.product_category = 'Category4'
                      AND c.address LIKE '%Street%'
                ) AS sub3
                GROUP BY name, surname
            ) AS sub4
        )
        LIMIT 1
    ) AS min_cnt,

    (
        SELECT CONCAT(name, ' ', surname, ': ', cnt)
        FROM (
            SELECT name, surname, COUNT(*) AS cnt
            FROM (
                SELECT
                    o.order_id,
                    o.order_date,
                    p.product_id,
                    p.product_category,
                    c.id AS client_id,
                    c.name,
                    c.surname
                FROM opt_orders AS o
                JOIN opt_products AS p
                    ON o.product_id = p.product_id
                JOIN opt_clients AS c
                    ON o.client_id = c.id
                WHERE c.status = 'active'
                  AND p.product_category = 'Category4'
                  AND c.address LIKE '%Street%'
            ) AS sub1
            GROUP BY name, surname
        ) AS sub2
        WHERE cnt = (
            SELECT MAX(cnt)
            FROM (
                SELECT COUNT(*) AS cnt
                FROM (
                    SELECT
                        o.order_id,
                        o.order_date,
                        p.product_id,
                        p.product_category,
                        c.id AS client_id,
                        c.name,
                        c.surname
                    FROM opt_orders AS o
                    JOIN opt_products AS p
                        ON o.product_id = p.product_id
                    JOIN opt_clients AS c
                        ON o.client_id = c.id
                    WHERE c.status = 'active'
                      AND p.product_category = 'Category4'
                      AND c.address LIKE '%Street%'
                ) AS sub3
                GROUP BY name, surname
            ) AS sub4
        )
        LIMIT 1
    ) AS max_cnt;


-- 2. Indexes for optimization

CREATE INDEX IF NOT EXISTS idx_opt_orders_product_id ON opt_orders(product_id);
CREATE INDEX IF NOT EXISTS idx_opt_orders_client_id ON opt_orders(client_id);
CREATE INDEX IF NOT EXISTS idx_opt_clients_status ON opt_clients(status);
CREATE INDEX IF NOT EXISTS idx_opt_products_category ON opt_products(product_category);


-- 3. Optimized query 
EXPLAIN ANALYZE
WITH filtered_orders AS (
    SELECT
        o.order_id,
        o.order_date,
        p.product_id,
        p.product_category,
        c.id AS client_id,
        c.name,
        c.surname
    FROM opt_orders AS o
    JOIN opt_products AS p
        ON o.product_id = p.product_id
    JOIN opt_clients AS c
        ON o.client_id = c.id
    WHERE c.status = 'active'
      AND p.product_category = 'Category4'
      AND c.address LIKE '%Street%'
),
cnt_clients AS (
    SELECT
        name,
        surname,
        COUNT(*) AS cnt
    FROM filtered_orders
    GROUP BY name, surname
),
ranked_clients AS (
    SELECT
        name,
        surname,
        cnt,
        ROW_NUMBER() OVER (ORDER BY cnt ASC, name ASC, surname ASC) AS min_rn,
        ROW_NUMBER() OVER (ORDER BY cnt DESC, name ASC, surname ASC) AS max_rn
    FROM cnt_clients
)
SELECT
    MAX(CONCAT(name, ' ', surname, ': ', cnt)) FILTER (WHERE min_rn = 1) AS min_cnt,
    MAX(CONCAT(name, ' ', surname, ': ', cnt)) FILTER (WHERE max_rn = 1) AS max_cnt
FROM ranked_clients;