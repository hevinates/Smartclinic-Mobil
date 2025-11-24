namespace SmartClinic.Api.Dtos;

public record RegisterDto(string Role, string FirstName, string LastName, string Email, string Password);
public record LoginDto(string Email, string Password);
public record UserDto(Guid Id, string Role, string FirstName, string LastName, string Email);
public record TokenDto(string accessToken, UserDto user);
