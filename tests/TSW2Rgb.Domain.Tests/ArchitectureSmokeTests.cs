using TSW2Rgb.Domain;
using Xunit;

namespace TSW2Rgb.Domain.Tests;

public sealed class ArchitectureSmokeTests
{
    [Fact]
    public void DomainAssemblyDoesNotReferenceApplicationOrPlatformAdapters()
    {
        string[] forbiddenPrefixes = ["TSW2Rgb.App", "TSW2Rgb.Bindings", "TSW2Rgb.State", "TSW2Rgb.Rgb"];

        string[] references = DomainAssembly.Value
            .GetReferencedAssemblies()
            .Select(reference => reference.Name ?? string.Empty)
            .ToArray();

        Assert.DoesNotContain(
            references,
            reference => forbiddenPrefixes.Any(prefix => reference.StartsWith(prefix, StringComparison.Ordinal)));
    }
}
