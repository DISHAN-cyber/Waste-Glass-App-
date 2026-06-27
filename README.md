# 🌍 Waste Glass Collection App

A comprehensive mobile application for managing waste glass collection routes, featuring barcode verification, real-time tracking, and offline data synchronization.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?logo=flutter)
![.NET](https://img.shields.io/badge/.NET-8.0-purple?logo=dotnet)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Supabase-blue?logo=postgresql)
![Railway](https://img.shields.io/badge/Hosted%20on-Railway-4c1?logo=railway)

---
## 📱 App live demo
## 📱 Project Overview

This application streamlines the waste glass collection process by providing collectors with an optimized daily route, barcode-based supplier verification, and seamless data management. The app works offline-first using SQLite and syncs data when connectivity is available.

---

## ✨ Features

### 🗺️ Route Management
- Display optimized daily collection routes
- Real-time distance and stop tracking
- Visual status indicators (Next, Pending, Collected)
- Turn-by-turn navigation integration

### 📷 Barcode Verification
- QR/Barcode scanning using device camera
- Supplier ID verification (Code 128 format)
- Real-time validation against database
- Offline barcode caching

### 📊 Collection Tracking
- Record clear and colored glass quantities (kg)
- Glass condition assessment (Good / Fair / Poor)
- Automatic database synchronization
- Offline data persistence with SQLite

### 📍 Location Services
- GPS-based distance calculation
- Supplier address mapping
- Real-time location tracking
- Proximity alerts

### 🌐 Offline-First Architecture
- Full offline functionality with SQLite
- Automatic sync when online
- Conflict resolution
- Data integrity guarantees

---

## 🛠️ Technology Stack

### 📱 Frontend (Mobile App)
- **Framework:** Flutter 3.0+
- **Language:** Dart
- **State Management:** Provider
- **Local Database:** SQLite (sqflite)
- **Camera/Barcode:** mobile_scanner ^7.2.0
- **Location:** geolocator ^10.1.0
- **Permissions:** permission_handler ^11.0.1

### ⚙️ Backend API
- **Framework:** .NET 8.0 Web API
- **Language:** C#
- **Database:** PostgreSQL (Supabase)
- **ORM:** Entity Framework Core
- **Hosting:** Railway
- **Authentication:** JWT (if implemented)

### 🗄️ Database
- **Primary:** Supabase PostgreSQL
- **Local:** SQLite (offline storage)
- **Migrations:** EF Core Migrations

---

## 📦 Installation & Setup

### 🧰 Prerequisites
- Flutter SDK 3.0+
- .NET 8.0 SDK
- PostgreSQL 14+
- Android Studio / VS Code

---

## ⚙️ Backend Setup

### 1. Clone the repository
```bash
git clone https://github.com/DISHAN-cyber/Waste-Glass-App-.git
````

---

## 📱 App Screenshots

* Route Overview
* Barcode Scanning
* Collection Form

(You can add real images here later)

---

## 🗂️ Project Structure

```
Waste-Glass-App/
├── flutter_app/                  # Flutter mobile application
│   ├── android/                  # Android platform files
│   ├── lib/                     # Dart source code
│   │   ├── main.dart            # App entry point
│   │   ├── models/              # Data models
│   │   │   ├── supplier.dart
│   │   │   └── collection.dart
│   │   ├── screens/             # UI screens
│   │   │   ├── trip_sequence_screen.dart
│   │   │   ├── scan_collect_screen.dart
│   │   │   └── trip_report_screen.dart
│   │   └── services/            # Business logic
│   │       ├── api_service.dart
│   │       └── local_db_service.dart
│   └── pubspec.yaml
│
├── dotnet_backend/              # .NET Web API
│   ├── Controllers/
│   │   ├── RouteController.cs
│   │   └── CollectionController.cs
│   ├── Models/
│   ├── Data/
│   ├── appsettings.json
│   └── Program.cs
│
└── README.md
```

---

## 🚀 Notes

* App is offline-first
* Sync happens automatically when internet is available
* Designed for real-world waste collection operations

```
