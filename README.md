# Waste Glass Collection App

Flutter (Android) + .NET 8 backend + Supabase PostgreSQL

---

## Project Structure

```
waste_glass_app/
├── flutter_app/          ← Flutter Android app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/supplier.dart
│   │   ├── services/
│   │   │   ├── api_service.dart        ← HTTP calls to .NET API
│   │   │   └── local_db_service.dart   ← SQLite offline storage
│   │   └── screens/
│   │       ├── trip_sequence_screen.dart   ← Screen 1
│   │       ├── scan_collect_screen.dart    ← Screen 2
│   │       └── trip_report_screen.dart     ← Screen 3
│   └── pubspec.yaml
└── dotnet_backend/       ← .NET 8 REST API
    ├── Controllers/
    │   ├── RouteController.cs
    │   ├── CollectionController.cs
    │   └── TripController.cs
    ├── Services/RouteService.cs   ← Haversine + Dijkstra
    ├── Models/Supplier.cs
    ├── Data/AppDbContext.cs       ← EF Core + seed data
    └── Program.cs
```

---

## Step 1 — Set Up Supabase (Database)

1. Go to [supabase.com](https://supabase.com) → New project → note your **password**
2. Go to **Settings → Database → Connection string (URI)**
3. Copy it — looks like:
   `postgresql://postgres:[PASSWORD]@db.xxxx.supabase.co:5432/postgres`

---

## Step 2 — Configure & Run the .NET Backend

```bash
cd dotnet_backend
```

Edit `appsettings.json` and replace the connection string with yours:
```json
"DefaultConnection": "Host=db.xxxx.supabase.co;Database=postgres;Username=postgres;Password=YOUR_PASSWORD;SSL Mode=Require;Trust Server Certificate=true"
```

Install EF Core tools and create migration:
```bash
dotnet tool install --global dotnet-ef
dotnet ef migrations add InitialCreate
dotnet ef database update
dotnet run
```

API runs at `http://localhost:5000`. Swagger at `http://localhost:5000/swagger`

Test endpoint: `GET http://localhost:5000/api/route`

---

## Step 3 — Deploy Backend to Railway (Free)

1. Push `dotnet_backend/` to a GitHub repo
2. Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub
3. Add environment variable: `DATABASE_URL` = your Supabase connection string
4. Note the public URL Railway gives you (e.g. `https://waste-glass-api.railway.app`)

---

## Step 4 — Configure Flutter App

Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://waste-glass-api.railway.app';
```

---

## Step 5 — Generate Barcodes for Testing

Go to [barcode.tec-it.com](https://barcode.tec-it.com) → Code 128 format

Generate one barcode per supplier with these values:
| Supplier | Barcode value |
|----------|--------------|
| Colombo Glass Depot | `SUP001` |
| Negombo Recycle Hub | `SUP002` |
| Ja-Ela Glass Store | `SUP003` |
| Wattala Collection Point | `SUP004` |
| Kelaniya Depot | `SUP005` |

Print them or display on a second phone.

---

## Step 6 — Run Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

Or build APK:
```bash
flutter build apk --release
```
APK at: `build/app/outputs/flutter-apk/app-release.apk`

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/route` | Returns Dijkstra-optimised stop sequence |
| POST | `/api/collection/{supplierId}` | Submit collection for a supplier |
| POST | `/api/collection/sync` | Batch sync all records from Screen 3 |
| GET | `/api/trip/summary` | Trip totals and shortfall report |
| POST | `/api/route/reset` | Reset all statuses (for testing) |

---

## How Dijkstra Works in This App

1. Start node = collector's GPS location
2. All 5 suppliers = graph nodes
3. Edge weights = Haversine distances (great-circle km)
4. Nearest-neighbour Dijkstra runs from start → returns sorted visit order
5. First unvisited stop = status "Next", rest = "Pending"

---

## Database Choice: Supabase (PostgreSQL)

- Free hosted tier, no infrastructure to manage
- Native PostgreSQL — perfect for EF Core + Npgsql
- Built-in connection pooling
- Easy to inspect data via Supabase dashboard
- APK points to Railway (which connects to Supabase) — no localhost required

---

## Screen Recording Flow (for submission)

1. Open app → Screen 1 loads route from backend
2. Tap "Scan Next" → Screen 2 opens
3. Scan barcode (SUP001 printed or on second phone) → form unlocks
4. Enter clear kg + coloured kg + condition → Confirm
5. Status updates → next stop becomes "Next"
6. Repeat for all stops
7. Screen 3 appears → shows totals + any shortfall flags
8. Tap "Sync to Server" → success message
