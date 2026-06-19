# TripMeAI Genesis Admin Dashboard

A brand-new, production-grade internal operations platform for the TripMeAI ecosystem. Built from the ground up with a focus on premium aesthetics, robust data governance, and high-fidelity operational monitoring.

## 🚀 Quick Start

1. **Install Dependencies**:
   ```bash
   cd tripme-admin-genesis
   npm install
   ```

2. **Configure Environment**:
   Duplicate `.env.example` to `.env` and refine your MongoDB connection string.
   ```bash
   cp .env.example .env
   ```

3. **Seed the Database**:
   Populate MongoDB with Sri Lankan tourism nodes and initial admin credentials.
   ```bash
   npm run seed
   ```

4. **Launch Dashboard**:
   ```bash
   npm run dev
   ```
   Access the dashboard at: **http://localhost:3006**

## 🔐 Credentials
- **Admin**: `admin@tripme.ai` / `admin123`
- **Reviewer**: `reviewer@tripme.ai` / `admin123`

## 🛠 Tech Stack
- **Engine**: Node.js & Express.js
- **Database**: MongoDB (Mongoose ODM)
- **UI Architecture**: Server-Side Rendering (EJS)
- **Styling**: Tailwind CSS (Genesis Genesis Utility System)
- **Authentication**: Passport.js (Local Session Strategy)
- **Security**: RBAC (Super Admin, Admin, Reviewer), Audit Logging

## 📂 Modules
- **Overview**: Real-time analytics and activity feed.
- **Places Registry**: Full CRUD with advanced multi-dimensional filtering.
- **Review Workflow**: Moderation queue for AI-harvested nodes.
- **Pipeline Monitor**: Direct bridge to the Python data extraction engine.
- **Identity Management**: RBAC controls for administrative personnel.
- **Audit Logs**: Persistent security trace of all write operations.
- **Scheduler**: Management module for background crons.

---
Built by Antigravity for TripMeAI Genesis.
