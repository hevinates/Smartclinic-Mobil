using Microsoft.EntityFrameworkCore;
using SmartClinic.Api.Models;

namespace SmartClinic.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> opt) : base(opt) { }

        public DbSet<User> Users { get; set; }
        public DbSet<TestResult> TestResults { get; set; }

        protected override void OnModelCreating(ModelBuilder b)
        {
            b.Entity<User>().HasIndex(u => u.Email).IsUnique();
        }
    }
}
