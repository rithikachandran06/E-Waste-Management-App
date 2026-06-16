/**
 * database/seed.js
 * ---------------------------------------------------------------
 * Populates a freshly-created database with:
 *   - one admin account
 *   - one demo citizen account
 *   - a starter set of e-waste categories
 *   - a starter set of collection centers
 *
 * Run AFTER schema.sql has been imported and AFTER `npm install`:
 *
 *      npm run seed
 *
 * Safe to re-run — it checks for existing rows before inserting.
 * ---------------------------------------------------------------
 */

require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../config/db');

const ADMIN_EMAIL = 'admin@ewaste.com';
const ADMIN_PASSWORD = 'Admin@123';
const DEMO_EMAIL = 'citizen@ewaste.com';
const DEMO_PASSWORD = 'Citizen@123';

const categories = [
  ['Mobile Phones & Tablets', 'Smartphones, feature phones, tablets and accessories.', 'Medium'],
  ['Laptops & Computers', 'Laptops, desktops, monitors and peripherals.', 'Medium'],
  ['Batteries', 'Lithium-ion, lead-acid and dry-cell batteries.', 'High'],
  ['Large Appliances', 'Refrigerators, washing machines, air conditioners.', 'Medium'],
  ['Small Appliances', 'Mixers, irons, toasters, kettles.', 'Low'],
  ['Cables & Wires', 'Charging cables, network cables, adapters.', 'Low'],
  ['CRT / LED / LCD Screens', 'Old televisions and computer monitors.', 'High'],
  ['Printers & Cartridges', 'Inkjet/laser printers and toner cartridges.', 'Medium']
];

const centers = [
  ['GreenLoop Recovery Hub', '14 MG Road', 'Bengaluru', '080-22334455', 'contact@greenloop.in', 5000],
  ['EcoCircuit Collection Point', '221 Whitefield Main Road', 'Bengaluru', '080-66778899', 'info@ecocircuit.in', 3000],
  ['Reclaim Electronics Center', '9 Anna Salai', 'Chennai', '044-55667788', 'reclaim@recycle.in', 4000]
];

async function seed() {
  try {
    // ---- Admin user ----
    const [existingAdmin] = await db.query('SELECT id FROM users WHERE email = ?', [ADMIN_EMAIL]);
    if (existingAdmin.length === 0) {
      const hashedAdminPw = await bcrypt.hash(ADMIN_PASSWORD, 10);
      await db.query(
        `INSERT INTO users (full_name, email, password, phone, role, status)
         VALUES (?, ?, ?, ?, 'admin', 'active')`,
        ['System Admin', ADMIN_EMAIL, hashedAdminPw, '9999999999']
      );
      console.log(`✔ Admin created  -> ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
    } else {
      console.log('• Admin already exists, skipping.');
    }

    // ---- Demo citizen user ----
    const [existingDemo] = await db.query('SELECT id FROM users WHERE email = ?', [DEMO_EMAIL]);
    if (existingDemo.length === 0) {
      const hashedDemoPw = await bcrypt.hash(DEMO_PASSWORD, 10);
      await db.query(
        `INSERT INTO users (full_name, email, password, phone, address, role, status)
         VALUES (?, ?, ?, ?, ?, 'user', 'active')`,
        ['Demo Citizen', DEMO_EMAIL, hashedDemoPw, '9876543210', '12 Park Street, Bengaluru']
      );
      console.log(`✔ Demo user created -> ${DEMO_EMAIL} / ${DEMO_PASSWORD}`);
    } else {
      console.log('• Demo user already exists, skipping.');
    }

    // ---- Categories ----
    const [existingCats] = await db.query('SELECT COUNT(*) AS c FROM categories');
    if (existingCats[0].c === 0) {
      for (const [name, description, hazard_level] of categories) {
        await db.query(
          'INSERT INTO categories (name, description, hazard_level) VALUES (?, ?, ?)',
          [name, description, hazard_level]
        );
      }
      console.log(`✔ Inserted ${categories.length} categories.`);
    } else {
      console.log('• Categories already exist, skipping.');
    }

    // ---- Collection centers ----
    const [existingCenters] = await db.query('SELECT COUNT(*) AS c FROM collection_centers');
    if (existingCenters[0].c === 0) {
      for (const [name, address, city, phone, email, capacity_kg] of centers) {
        await db.query(
          `INSERT INTO collection_centers (name, address, city, phone, email, capacity_kg)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [name, address, city, phone, email, capacity_kg]
        );
      }
      console.log(`✔ Inserted ${centers.length} collection centers.`);
    } else {
      console.log('• Collection centers already exist, skipping.');
    }

    console.log('\nSeed complete. You can now log in with the credentials above.');
    process.exit(0);
  } catch (err) {
    console.error('Seeding failed:', err);
    process.exit(1);
  }
}

seed();
