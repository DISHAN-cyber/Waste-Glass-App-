using Microsoft.EntityFrameworkCore;
using WasteGlassApi.Models;

namespace WasteGlassApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<CollectionRecord> CollectionRecords => Set<CollectionRecord>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CollectionRecord>()
            .HasOne(c => c.Supplier)
            .WithMany(s => s.CollectionRecords)
            .HasForeignKey(c => c.SupplierId)
            .HasPrincipalKey(s => s.BarcodeRef);

        // Seed supplier data for testing
        modelBuilder.Entity<Supplier>().HasData(
            new Supplier
            {
                Id = 1, Name = "Colombo Glass Depot",
                Address = "12 Galle Rd, Colombo 03",
                Latitude = 6.9147, Longitude = 79.8584,
                ExpectedKg = 45.0, BarcodeRef = "SUP001", Status = "Pending"
            },
            new Supplier
            {
                Id = 2, Name = "Negombo Recycle Hub",
                Address = "34 Beach Rd, Negombo",
                Latitude = 7.2096, Longitude = 79.8369,
                ExpectedKg = 30.0, BarcodeRef = "SUP002", Status = "Pending"
            },
            new Supplier
            {
                Id = 3, Name = "Ja-Ela Glass Store",
                Address = "78 Kandy Rd, Ja-Ela",
                Latitude = 7.0732, Longitude = 79.8913,
                ExpectedKg = 60.0, BarcodeRef = "SUP003", Status = "Pending"
            },
            new Supplier
            {
                Id = 4, Name = "Wattala Collection Point",
                Address = "22 Main St, Wattala",
                Latitude = 6.9897, Longitude = 79.8891,
                ExpectedKg = 25.0, BarcodeRef = "SUP004", Status = "Pending"
            },
            new Supplier
            {
                Id = 5, Name = "Kelaniya Depot",
                Address = "56 Kelani Rd, Kelaniya",
                Latitude = 6.9550, Longitude = 79.9200,
                ExpectedKg = 40.0, BarcodeRef = "SUP005", Status = "Pending"
            }
        );
    }
}
