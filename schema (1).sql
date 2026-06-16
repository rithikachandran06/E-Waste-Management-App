-- ===================================================================
--  E-WASTE MANAGEMENT SYSTEM — DATABASE SCHEMA
--  Engine : MySQL 8.0+
--  Usage  : mysql -u root -p < database/schema.sql
-- ===================================================================

CREATE DATABASE IF NOT EXISTS ewaste_management
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ewaste_management;

-- -------------------------------------------------------------
-- 1. USERS
--    Holds both regular citizens (role = 'user') and staff
--    (role = 'admin'). status lets an admin disable an account
--    without deleting their request history.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100)  NOT NULL,
    email           VARCHAR(150)  NOT NULL UNIQUE,
    password        VARCHAR(255)  NOT NULL,         -- bcrypt hash
    phone           VARCHAR(20)   DEFAULT NULL,
    address         VARCHAR(255)  DEFAULT NULL,
    role            ENUM('admin','user') NOT NULL DEFAULT 'user',
    status          ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 2. CATEGORIES
--    Types of e-waste (Mobile Phones, Batteries, CRT Monitors...)
--    hazard_level drives a coloured badge in the UI.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    hazard_level    ENUM('Low','Medium','High') NOT NULL DEFAULT 'Low',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 3. COLLECTION_CENTERS
--    Physical drop-off / processing facilities an admin can
--    assign a pickup request to.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS collection_centers (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    address         VARCHAR(255) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    phone           VARCHAR(20),
    email           VARCHAR(150),
    capacity_kg     INT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 4. EWASTE_REQUESTS
--    The core table — one row per pickup request a citizen
--    raises for an item (or batch of items) of e-waste.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ewaste_requests (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    category_id     INT NOT NULL,
    item_name       VARCHAR(150) NOT NULL,
    description     TEXT,
    quantity        INT NOT NULL DEFAULT 1,
    item_condition  ENUM('Working','Not Working','Damaged') NOT NULL DEFAULT 'Not Working',
    image_path      VARCHAR(255) DEFAULT NULL,
    pickup_address  VARCHAR(255) NOT NULL,
    preferred_date  DATE DEFAULT NULL,
    center_id       INT DEFAULT NULL,
    status          ENUM('Pending','Approved','Scheduled','Collected','Recycled','Rejected','Cancelled')
                    NOT NULL DEFAULT 'Pending',
    admin_notes     TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_req_user     FOREIGN KEY (user_id)     REFERENCES users(id)               ON DELETE CASCADE,
    CONSTRAINT fk_req_category FOREIGN KEY (category_id) REFERENCES categories(id)           ON DELETE RESTRICT,
    CONSTRAINT fk_req_center   FOREIGN KEY (center_id)    REFERENCES collection_centers(id)   ON DELETE SET NULL
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 5. STATUS_HISTORY
--    Audit trail — every status change on a request is logged
--    so a citizen can see a timeline, and admins have a record
--    of who changed what.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS status_history (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    request_id      INT NOT NULL,
    status          VARCHAR(50) NOT NULL,
    remarks         TEXT,
    changed_by      INT DEFAULT NULL,
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_hist_request FOREIGN KEY (request_id) REFERENCES ewaste_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_hist_user    FOREIGN KEY (changed_by) REFERENCES users(id)            ON DELETE SET NULL
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 6. FEEDBACK
--    Star rating + comment a citizen leaves once their item
--    has been collected / recycled.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS feedback (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    request_id      INT NOT NULL,
    user_id         INT NOT NULL,
    rating          TINYINT NOT NULL,
    comments        TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_fb_request FOREIGN KEY (request_id) REFERENCES ewaste_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_fb_user    FOREIGN KEY (user_id)    REFERENCES users(id)            ON DELETE CASCADE,
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- INDEXES — speed up the filters/joins the app runs most
-- -------------------------------------------------------------
CREATE INDEX idx_requests_status   ON ewaste_requests(status);
CREATE INDEX idx_requests_user     ON ewaste_requests(user_id);
CREATE INDEX idx_requests_category ON ewaste_requests(category_id);
CREATE INDEX idx_requests_center   ON ewaste_requests(center_id);
CREATE INDEX idx_history_request   ON status_history(request_id);
