using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartClinic.Api.Data;
using SmartClinic.Api.Models;

namespace SmartClinic.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TestController(AppDbContext context)
        {
            _context = context;
        }

        // 🔹 1. Yeni tahlil sonucu kaydetme
        [HttpPost("add")]
        public async Task<IActionResult> AddTest([FromBody] TestResult result)
        {
            if (result == null) return BadRequest("Eksik veri gönderildi.");

           
            _context.TestResults.Add(result);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tahlil kaydedildi", result });
        }

        // 🔹 2. Belirli kullanıcıya ait tüm tahlilleri listele
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetTestsByUser(int userId)
        {
            var tests = await _context.TestResults
                .Where(t => t.UserId == userId)
                .OrderByDescending(t => t.Date)
                .ToListAsync();

            // 🔹 Aynı tarihteki testleri grupluyoruz
            var grouped = tests
                .GroupBy(t => t.Date.Date)
                .Select(g => new
                {
                    Date = g.Key.ToString("yyyy-MM-dd"),
                    Tests = g.ToList()
                });

            return Ok(grouped);
        }

    }
}
