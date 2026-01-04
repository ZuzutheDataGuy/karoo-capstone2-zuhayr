-- Certification nearing expiry
INSERT INTO Certifications (supplier_id, certification_name, issued_by, issue_date)
VALUES (1, 'Organic', 'SA Organic', DATEADD(DAY, -335, GETDATE()));

-- Supplier with no recent orders
INSERT INTO Suppliers (supplier_id, farm_name, region, status)
VALUES (99, 'Test Farm', 'Northern Cape', 'Active');

-- Yield decline example
INSERT INTO Harvest_Log (supplier_id, harvest_date, crop_type, quantity_kg)
VALUES
(2, '2025-09-01', 'Grapes', 1000),
(2, '2025-10-01', 'Grapes', 950),
(2, '2025-11-01', 'Grapes', 600);
