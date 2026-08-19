namespace CabinRent.Services.Exceptions;

public abstract class ApplicationExceptionBase(string message) : Exception(message);

public sealed class RequestValidationException(string message) : ApplicationExceptionBase(message);

public sealed class BusinessRuleException(string message) : ApplicationExceptionBase(message);

public sealed class ResourceNotFoundException(string message) : ApplicationExceptionBase(message);

public sealed class ForbiddenOperationException(string message) : ApplicationExceptionBase(message);
