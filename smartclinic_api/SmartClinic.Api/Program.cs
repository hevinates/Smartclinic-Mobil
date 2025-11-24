using Microsoft.OpenApi.Models;
using Microsoft.EntityFrameworkCore;
using SmartClinic.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// 🔹 PostgreSQL bağlantısı
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// 🔹 MVC
builder.Services.AddControllers();

// 🔹 Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SmartClinic API",
        Version = "v1"
    });
});

var app = builder.Build();

// 🔹 Swagger geliştirme ortamında açık kalsın
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "SmartClinic API v1");
    app.UseSwaggerUI(c => c.RoutePrefix = "swagger"); // /swagger adresinde açılır
});

// app.UseHttpsRedirection();

// 🔹 Authentication/Authorization
// app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
