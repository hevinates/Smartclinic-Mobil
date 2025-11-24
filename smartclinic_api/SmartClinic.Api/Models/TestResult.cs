using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartClinic.Api.Models
{
    public class TestResult
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string TestName { get; set; } = "";
        public string Result { get; set; } = "";
        public string ReferenceRange { get; set; } = "Bilinmiyor";

        public bool IsOutOfRange { get; set; }

        [Column(TypeName = "timestamp with time zone")]
        public DateTime Date { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Utc);
    }
}
