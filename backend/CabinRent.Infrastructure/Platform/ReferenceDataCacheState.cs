namespace CabinRent.Infrastructure.Platform;

public sealed class ReferenceDataCacheState
{
    private int _version;
    public int Version => Volatile.Read(ref _version);
    public void Bump() => Interlocked.Increment(ref _version);
}
