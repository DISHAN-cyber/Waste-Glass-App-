using Microsoft.EntityFrameworkCore;
using WasteGlassApi.Data;
using WasteGlassApi.Services;

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("DATABASE_URL")
    ?? "Host=localhost;Database=waste_glass;Username=postgres;Password=password";

// ADD THIS LINE - Log the connection string (hide password)
Console.WriteLine($"[DEBUG] Using connection string: {connectionString.Replace(connectionString.Split(';').FirstOrDefault(s => s.StartsWith("Password=")) ?? "", "Password=***")}");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddScoped<RouteService>();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS — allow Flutter app
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var app = builder.Build();

// Auto-migrate and seed on startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();
app.MapControllers();

// Health check
app.MapGet("/", () => Results.Ok(new { status = "Waste Glass API running", version = "1.0" }));

app.Run();
