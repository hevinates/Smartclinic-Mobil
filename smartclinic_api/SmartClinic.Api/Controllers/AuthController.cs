using Microsoft.AspNetCore.Mvc;
using Npgsql;
using Dapper;

namespace SmartClinic.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly string _connString = "Host=localhost;Port=5432;Database=smartclinic;Username=smartuser;Password=smartpass";

        // ✅ REGISTER (Kayıt)
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            using var connection = new NpgsqlConnection(_connString);

            // Aynı e-posta var mı kontrol et
            var exists = await connection.QueryFirstOrDefaultAsync<string>(
                "SELECT \"Email\" FROM users WHERE \"Email\" = @Email", new { request.Email });

            if (exists != null)
                return Conflict(new { message = "Bu e-posta zaten kayıtlı." });

            // Yeni kullanıcı ekle
            const string sql = @"INSERT INTO users (""FirstName"", ""LastName"", ""Email"", ""PasswordHash"", ""Role"")
                                 VALUES (@FirstName, @LastName, @Email, @Password, @Role)";

            await connection.ExecuteAsync(sql, request);

            return Ok(new { message = "Kayıt başarılı", user = request.Email });
        }

        // ✅ LOGIN (Giriş)
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            using var connection = new NpgsqlConnection(_connString);

            var user = await connection.QueryFirstOrDefaultAsync<UserLoginDto>(
                "SELECT \"Id\", \"FirstName\", \"LastName\", \"Email\", \"PasswordHash\", \"Role\" FROM users WHERE \"Email\" = @Email",
                new { request.Email });

            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı." });

            if (user.PasswordHash != request.Password)
                return Unauthorized(new { message = "Parola hatalı." });

            return Ok(new
            {
                message = "Giriş başarılı",
                user = new
                {
                    user.Id,
                    user.FirstName,
                    user.LastName,
                    user.Email,
                    user.Role
                }
            });
        }
    }

    // ✳️ MODELLER
    public class RegisterRequest
    {
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string Email { get; set; } = "";
        public string Password { get; set; } = "";
        public string Role { get; set; } = "";
    }

    public class LoginRequest
    {
        public string Email { get; set; } = "";
        public string Password { get; set; } = "";
    }

    public class UserLoginDto
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string Email { get; set; } = "";
        public string PasswordHash { get; set; } = "";
        public string Role { get; set; } = "";
    }
}
