using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WasteGlassApi.Data;
using WasteGlassApi.Models;
using WasteGlassApi.Services;

namespace WasteGlassApi.Controllers;

[ApiController]
[Route("api/route")]
public class RouteController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly RouteService _routeService;

    public RouteController(AppDbContext db, RouteService routeService)
    {
        _db = db;
        _routeService = routeService;
    }

    /// <summary>
    /// GET /api/route
    /// Returns today's supplier list in optimal Dijkstra order with statuses.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<RouteSupplierDto>>> GetRoute()
    {
        var suppliers = await _db.Suppliers.ToListAsync();
        if (!suppliers.Any())
            return Ok(new List<RouteSupplierDto>());

        var route = _routeService.CalculateOptimalRoute(suppliers);
        return Ok(route);
    }

    /// <summary>
    /// POST /api/route/reset
    /// Resets all supplier statuses to Pending (for testing a new trip).
    /// </summary>
    [HttpPost("reset")]
    public async Task<IActionResult> ResetRoute()
    {
        var suppliers = await _db.Suppliers.ToListAsync();
        foreach (var s in suppliers) s.Status = "Pending";
        await _db.SaveChangesAsync();
        return Ok(new { message = "All statuses reset to Pending" });
    }
}
