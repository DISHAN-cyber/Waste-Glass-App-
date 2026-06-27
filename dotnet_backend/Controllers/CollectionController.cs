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
        try
        {
            var supplier = await _db.Suppliers
                .FirstOrDefaultAsync(s => s.BarcodeRef == supplierId);

            if (supplier == null)
                return NotFound(new { error = $"Supplier '{supplierId}' not found." });

            // Update supplier status to Collected
            supplier.Status = "Collected";

            // Save collection record - FIX: Always use UTC DateTime
            var timestamp = dto.Timestamp == default 
                ? DateTime.UtcNow 
                : DateTime.SpecifyKind(dto.Timestamp, DateTimeKind.Utc);

            var record = new CollectionRecord
            {
                SupplierId = supplierId,
                ClearKg = dto.ClearKg,
                ColouredKg = dto.ColouredKg,
                Condition = dto.Condition,
                Timestamp = timestamp,
                Synced = true,
            };

            _db.CollectionRecords.Add(record);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Collection recorded", supplierId, status = "Collected" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message, inner = ex.InnerException?.Message });
        }
    }

    /// <summary>
    /// POST /api/collection/sync
    /// Final sync from Screen 3 — batch upsert all locally stored records.
    /// </summary>
    [HttpPost("sync")]
    public async Task<IActionResult> SyncAll([FromBody] List<CollectionSubmitDto> records)
    {
        try
        {
            foreach (var dto in records)
            {
                var supplier = await _db.Suppliers
                    .FirstOrDefaultAsync(s => s.BarcodeRef == dto.SupplierId);

                if (supplier == null) continue;

                supplier.Status = "Collected";

                // FIX: Always use UTC DateTime
                var timestamp = dto.Timestamp == default 
                    ? DateTime.UtcNow 
                    : DateTime.SpecifyKind(dto.Timestamp, DateTimeKind.Utc);

                var existing = await _db.CollectionRecords
                    .FirstOrDefaultAsync(r => r.SupplierId == dto.SupplierId);

                if (existing != null)
                {
                    existing.ClearKg = dto.ClearKg;
                    existing.ColouredKg = dto.ColouredKg;
                    existing.Condition = dto.Condition;
                    existing.Timestamp = timestamp;
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
                        Timestamp = timestamp,
                        Synced = true,
                    });
                }
            }

            await _db.SaveChangesAsync();
            return Ok(new { message = "Sync complete", count = records.Count });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message, inner = ex.InnerException?.Message });
        }
    }
}