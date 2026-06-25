using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WasteGlassApi.Data;
using WasteGlassApi.Models;
using WasteGlassApi.Services;

namespace WasteGlassApi.Controllers;

[ApiController]
[Route("api/trip")]
public class TripController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly RouteService _routeService;

    public TripController(AppDbContext db, RouteService routeService)
    {
        _db = db;
        _routeService = routeService;
    }

    /// <summary>
    /// GET /api/trip/summary
    /// Returns trip summary: per-supplier collected amounts, shortfalls, totals.
    /// </summary>
    [HttpGet("summary")]
    public async Task<ActionResult<TripSummaryDto>> GetSummary()
    {
        var suppliers = await _db.Suppliers.ToListAsync();
        var records = await _db.CollectionRecords.ToListAsync();

        var route = _routeService.CalculateOptimalRoute(suppliers);
        double totalDist = route.Sum(r => r.DistanceFromPrev);

        var summaries = suppliers.Select(s =>
        {
            var record = records.FirstOrDefault(r => r.SupplierId == s.BarcodeRef);
            double collected = record == null ? 0 : record.ClearKg + record.ColouredKg;
            return new SupplierSummaryDto
            {
                SupplierId = s.BarcodeRef,
                SupplierName = s.Name,
                ExpectedKg = s.ExpectedKg,
                CollectedKg = collected,
                HasShortfall = collected < s.ExpectedKg,
                Condition = record?.Condition ?? "N/A",
            };
        }).ToList();

        return Ok(new TripSummaryDto
        {
            SupplierSummaries = summaries,
            TotalKg = summaries.Sum(s => s.CollectedKg),
            TotalDistance = Math.Round(totalDist, 2),
        });
    }
}
