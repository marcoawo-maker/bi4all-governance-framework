INSERT INTO dbo.ingestion_execution_log VALUES
(1, 'sales', 'sales_1.csv', current_timestamp(), current_timestamp(), 12, 'Success', 5000, 'Manual'),
(2, 'customer360', 'customer_1.csv', current_timestamp(), current_timestamp(), 18, 'Success', 5000, 'Manual'),
(3, 'inventorycore', 'inventory_1.csv', current_timestamp(), current_timestamp(), 9, 'Success', 5000, 'Manual'),
(4, 'sales', 'bad_file.csv', current_timestamp(), current_timestamp(), 5, 'Failed', 0, 'Manual'),
(5, 'supplier', 'supplier_1.csv', current_timestamp(), current_timestamp(), 15, 'Success', 5000, 'Manual'),
(6, 'customer360', 'corrupt.csv', current_timestamp(), current_timestamp(), 6, 'Failed', 0, 'Manual');