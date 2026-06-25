using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace WasteGlassApi.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Suppliers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Address = table.Column<string>(type: "text", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    ExpectedKg = table.Column<double>(type: "double precision", nullable: false),
                    BarcodeRef = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Suppliers", x => x.Id);
                    table.UniqueConstraint("AK_Suppliers_BarcodeRef", x => x.BarcodeRef);
                });

            migrationBuilder.CreateTable(
                name: "CollectionRecords",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SupplierId = table.Column<string>(type: "text", nullable: false),
                    ClearKg = table.Column<double>(type: "double precision", nullable: false),
                    ColouredKg = table.Column<double>(type: "double precision", nullable: false),
                    Condition = table.Column<string>(type: "text", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Synced = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CollectionRecords", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CollectionRecords_Suppliers_SupplierId",
                        column: x => x.SupplierId,
                        principalTable: "Suppliers",
                        principalColumn: "BarcodeRef",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Suppliers",
                columns: new[] { "Id", "Address", "BarcodeRef", "ExpectedKg", "Latitude", "Longitude", "Name", "Status" },
                values: new object[,]
                {
                    { 1, "12 Galle Rd, Colombo 03", "SUP001", 45.0, 6.9146999999999998, 79.858400000000003, "Colombo Glass Depot", "Pending" },
                    { 2, "34 Beach Rd, Negombo", "SUP002", 30.0, 7.2096, 79.8369, "Negombo Recycle Hub", "Pending" },
                    { 3, "78 Kandy Rd, Ja-Ela", "SUP003", 60.0, 7.0731999999999999, 79.891300000000001, "Ja-Ela Glass Store", "Pending" },
                    { 4, "22 Main St, Wattala", "SUP004", 25.0, 6.9897, 79.889099999999999, "Wattala Collection Point", "Pending" },
                    { 5, "56 Kelani Rd, Kelaniya", "SUP005", 40.0, 6.9550000000000001, 79.920000000000002, "Kelaniya Depot", "Pending" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_CollectionRecords_SupplierId",
                table: "CollectionRecords",
                column: "SupplierId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CollectionRecords");

            migrationBuilder.DropTable(
                name: "Suppliers");
        }
    }
}
