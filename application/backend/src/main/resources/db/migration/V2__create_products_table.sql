CREATE TABLE products (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(150)   NOT NULL,
    description VARCHAR(2000),
    price       DECIMAL(12,2)  NOT NULL,
    category    VARCHAR(50)    NOT NULL,
    stock       INTEGER        NOT NULL DEFAULT 0,
    image_url   VARCHAR(500),
    active      BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products (category);
CREATE INDEX idx_products_active   ON products (active);
CREATE INDEX idx_products_name     ON products (name);
