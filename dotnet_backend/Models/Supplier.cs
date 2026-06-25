namespace WasteGlassApi.Models;

public class Supplier
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double ExpectedKg { get; set; }
    public string BarcodeRef { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending"; // Pending, Next, Collected
    public ICollection<CollectionRecord> CollectionRecords { get; set; } = new List<CollectionRecord>();
}

public class CollectionRecord
{
    public int Id { get; set; }
    public string SupplierId { get; set; } = string.Empty;
    public double ClearKg { get; set; }
    public double ColouredKg { get; set; }
    public string Condition { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public bool Synced { get; set; }
    public Supplier? Supplier { get; set; }
}

// DTOs
public class RouteSupplierDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double ExpectedKg { get; set; }
    public string BarcodeRef { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending";
    public int StopOrder { get; set; }
    public double DistanceFromPrev { get; set; }
}

public class CollectionSubmitDto
{
    public string SupplierId { get; set; } = string.Empty;
    public double ClearKg { get; set; }
    public double ColouredKg { get; set; }
    public string Condition { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}

public class SyncRequestDto
{
    public List<CollectionSubmitDto> Records { get; set; } = new();
}

public class TripSummaryDto
{
    public List<SupplierSummaryDto> SupplierSummaries { get; set; } = new();
    public double TotalKg { get; set; }
    public double TotalDistance { get; set; }
}

public class SupplierSummaryDto
{
    public string SupplierId { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public double ExpectedKg { get; set; }
    public double CollectedKg { get; set; }
    public bool HasShortfall { get; set; }
    public string Condition { get; set; } = string.Empty;
}
