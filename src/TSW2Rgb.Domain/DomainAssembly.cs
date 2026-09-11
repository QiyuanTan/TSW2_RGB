namespace TSW2Rgb.Domain;

/// <summary>
/// Identifies the platform-neutral domain assembly for composition and architecture tests.
/// </summary>
public static class DomainAssembly
{
    /// <summary>
    /// Gets the domain assembly without coupling callers to a future domain type.
    /// </summary>
    public static System.Reflection.Assembly Value => typeof(DomainAssembly).Assembly;
}
