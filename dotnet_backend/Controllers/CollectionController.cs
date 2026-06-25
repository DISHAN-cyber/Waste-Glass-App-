using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WasteGlassApi.Data;
using WasteGlassApi.Models;

namespace WasteGlassApi.Controllers;

[ApiController]
[Route("api/collection")]
public class CollectionController : ControllerBase
{
    private readonly AppDbContext _db;

    public CollectionController(AppDbContext db) => _db = db;

    /// <summary>
    /// POST /api/collection/{supplierId}
    /// Submits a collection for a specific supplier (identified by barcode/supplierId).
    /// Updates status to Collected and saves the collection record.
    /// </summary>
    [HttpPost("{supplierId}")]
    public async Task<IActionResult> SubmitCollection(
        string supplierId,
        [FromBody] CollectionSubmitDto dto)
    {
        var supplier = await _db.Suppliers
            .FirstOrDefaultAsync(s => s.BarcodeRef == supplierId);

        if (supplier == null)
            return NotFound(new { error = $"Supplier '{supplierId}' not found." });

        // Update supplier status to Collected
        supplier.Status = "Collected";

        // Save collection record
        var record = new CollectionRecord
        {
            SupplierId = supplierId,
            ClearKg = dto.ClearKg,
            ColouredKg = dto.ColouredKg,
            Condition = dto.Condition,
            Timestamp = dto.Timestamp == default ? DateTime.UtcNow : dto.Timestamp,
            Synced = true,
        };

        _db.CollectionRecords.Add(record);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Collection recorded", supplierId, status = "Collected" });
    }

    /// <summary>
    /// POST /api/collection/sync
    /// Final sync from Screen 3 — batch upsert all locally stored records.
    /// </summary>
    [HttpPost("sync")]
    public async Task<IActionResult> SyncAll([FromBody] List<CollectionSubmitDto> records)
    {
        foreach (var dto in records)
        {
            var supplier = await _db.Suppliers
                .FirstOrDefaultAsync(s => s.BarcodeRef == dto.SupplierId);

            if (supplier == null) continue;

            supplier.Status = "Collected";

            var existing = await _db.CollectionRecords
                .FirstOrDefaultAsync(r => r.SupplierId == dto.SupplierId);

            if (existing != null)
            {
                existing.ClearKg = dto.ClearKg;
                existing.ColouredKg = dto.ColouredKg;
                existing.Condition = dto.Condition;
                existing.Synced = true;
            }
            else
            {
                _db.CollectionRecords.Add(new CollectionRecord
                {
                    SupplierId = dto.SupplierId,
                    ClearKg = dto.ClearKg,
                    ColouredKg = dto.ColouredKg,
                    Condition = dto.Condition,
                    Timestamp = dto.Timestamp == default ? DateTime.UtcNow : dto.Timestamp,
                    Synced = true,
                });
            }
        }

        await _db.SaveChangesAsync();
        return Ok(new { message = "Sync complete", count = records.Count });
    }
}
