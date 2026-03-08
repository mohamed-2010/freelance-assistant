# 🧠 Prompt — Freelance Project & Task Manager (Personal Assistant App)

---

## SYSTEM ROLE

You are an expert mobile app developer and UI/UX designer. Your task is to build a **complete, fully functional mobile application** that acts as a personal assistant for a freelancer to manage client projects, tasks, costs, and payment tracking.

---

## APP OVERVIEW

Build a **Freelance Assistant App** — a mobile-first single-page application (React or HTML/CSS/JS) that helps a freelancer:
- Organize work by client and project
- Log tasks under each project with cost and time
- Track whether each task has been invoiced/paid
- Get a financial overview at a glance

This is a **personal tool**, so it should feel like a smart, sleek assistant — not a corporate SaaS dashboard.

---

## CORE FEATURES TO BUILD

### 1. 📁 Clients & Projects
- Add / edit / delete **clients** (name, contact info, optional notes)
- Each client can have multiple **projects** (name, description, status: active / completed / on-hold)
- View all projects per client

### 2. ✅ Task Management
- Add tasks under each project
- Each task must have:
  - **Title** (what was done)
  - **Description** (optional details)
  - **Cost** (in EGP or USD — user can set preferred currency)
  - **Date** (when the task was done)
  - **Status**: `Pending` / `Invoiced` / `Paid`
- Edit and delete tasks
- Mark tasks as invoiced or paid with one tap

### 3. 💰 Financial Tracking
- Per project: total cost, total invoiced, total paid, total pending
- Per client: cumulative financials across all projects
- **Dashboard summary**: total earnings this month, unpaid balance, number of active projects

### 4. 🔔 Smart Filters & Views
- Filter tasks by: status (paid / unpaid / invoiced), date range, client, project
- Sort by: date, cost (high to low), status
- "What hasn't been paid yet?" quick view

### 5. 💾 Data Persistence & Backup
- Use **sqflite** or **Hive** for local storage — no backend needed, fully offline
- All data persists between app sessions

### 6. 🔄 Backup & Restore
- **Export backup**: serialize all data (clients, projects, tasks) into a single `.json` file and save to device storage using `path_provider` + `share_plus` — user can send it to WhatsApp, Google Drive, email, etc.
- **Import backup**: user picks a `.json` backup file via `file_picker`, app validates the format then restores all data (with a confirmation dialog warning that current data will be replaced)
- **Auto-backup reminder**: local notification via `flutter_local_notifications` if the user hasn't backed up in more than 7 days
- Backup file must be human-readable JSON with a version field (e.g. `"backup_version": 1`) to support future migrations
- Show last backup date prominently in the Settings screen

---

## UI/UX REQUIREMENTS

- **Mobile-first design** — optimized for Android & iOS screens
- **Dark theme** with Material 3 — feels like a professional tool, not a toy
- Clean, minimal, but with personality — think "designer's private notebook"
- Smooth page transitions and Hero animations
- `BottomNavigationBar` or `NavigationBar` (M3) for main sections
- `FloatingActionButton` to quickly add a task or project
- Use `Card`, `ListTile`, `Chip` widgets with custom styling
- Typography: use `GoogleFonts` package — pick something sharp and modern, avoid defaults

---

## TECHNICAL REQUIREMENTS

- **Flutter** (Dart) — cross-platform mobile app targeting Android & iOS
- Use **Flutter 3.x** stable — no deprecated APIs
- State management: **Provider** or **Riverpod** (choose what fits cleanest)
- Local data persistence: **sqflite** (SQLite) or **Hive** — no backend, fully offline
- Navigation: **GoRouter** or Flutter's built-in `Navigator 2.0`
- Project structure: feature-based folders (`/clients`, `/projects`, `/tasks`, `/dashboard`, `/settings`)
- Use **Material 3** design system with a custom dark `ThemeData`
- All monetary formatting via `intl` package (NumberFormat)
- UUID generation via `uuid` package
- Backup packages: `path_provider`, `share_plus`, `file_picker`, `flutter_local_notifications`
- No Firebase, no external APIs — fully local app

---

## DATA STRUCTURE REFERENCE

```json
{
  "clients": [
    {
      "id": "uuid",
      "name": "Client Name",
      "contact": "email or phone",
      "notes": "optional",
      "createdAt": "ISO date"
    }
  ],
  "projects": [
    {
      "id": "uuid",
      "clientId": "client uuid",
      "name": "Project Name",
      "description": "optional",
      "status": "active | completed | on-hold",
      "currency": "EGP | USD",
      "createdAt": "ISO date"
    }
  ],
  "tasks": [
    {
      "id": "uuid",
      "projectId": "project uuid",
      "title": "Task title",
      "description": "optional",
      "cost": 500,
      "date": "ISO date",
      "status": "pending | invoiced | paid",
      "createdAt": "ISO date"
    }
  ]
}
```

---

## SCREENS / VIEWS TO BUILD

| Screen | Description |
|---|---|
| **Dashboard** | Summary cards: total unpaid, this month's earnings, active projects count |
| **Clients List** | All clients with quick stats |
| **Client Detail** | Client info + list of their projects |
| **Project Detail** | Project info + all tasks with costs and statuses |
| **Add/Edit Task** | Form to log a new task with all fields |
| **Add/Edit Project** | Form to create/edit a project |
| **Add/Edit Client** | Form to add/edit a client |
| **Reports View** | Filter tasks, see unpaid balance, export option |
| **Settings** | Currency preference, backup/restore controls, last backup date |

---

## TONE & PERSONALITY

The app should feel like **محمد's personal assistant** — it knows his work, keeps things organized, and gives him a clear picture of his money at all times. The UI should be:
- Confident and clean
- Efficient — minimum taps to log a task
- Visually rewarding — good work should feel satisfying to record

---

## DELIVERABLE

A **complete Flutter project** with:
- `pubspec.yaml` with all dependencies listed
- Full folder structure (feature-based)
- All screens implemented as Flutter widgets
- Working navigation between all screens
- Data layer fully wired (models, local DB, repositories)
- Custom dark `ThemeData` applied globally
- Ready to run with `flutter pub get && flutter run`

Generate **all files** needed. Do not skip any screen or model. Make smart assumptions and build something exceptional — do not ask clarifying questions.
