using System.Collections;
using System.Reflection;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace MenuGreen.API.Security;

/// <summary>
/// Applies defensive, cross-cutting validation to every MVC action argument.
/// Domain-specific DTO validation still belongs in DataAnnotations/IValidatableObject.
/// </summary>
public sealed class InputSecurityFilter : IAsyncActionFilter
{
    private const int MaxStringLength = 16_384;
    private const int MaxCollectionItems = 500;
    private const int MaxObjectDepth = 16;
    private const int MaxVisitedNodes = 10_000;

    private static readonly string[] SensitivePropertyMarkers =
    [
        "password",
        "token",
        "secret",
        "signature",
        "authorization",
        "otpcode",
    ];

    private static readonly string[] DangerousTextMarkers =
    [
        "<script",
        "</script",
        "<iframe",
        "<object",
        "<embed",
        "javascript:",
        "data:text/html",
        "onerror=",
        "onload=",
    ];

    public Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next
    )
    {
        var state = new InspectionState();

        foreach (var argumentName in context.ActionArguments.Keys.ToArray())
        {
            var value = context.ActionArguments[argumentName];
            Inspect(
                value,
                argumentName,
                depth: 0,
                state,
                sanitized => context.ActionArguments[argumentName] = sanitized
            );
        }

        if (state.Errors.Count > 0)
        {
            context.Result = new BadRequestObjectResult(
                new ValidationProblemDetails(state.Errors)
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Request validation failed.",
                }
            );
            return Task.CompletedTask;
        }

        return next();
    }

    private static void Inspect(
        object? value,
        string path,
        int depth,
        InspectionState state,
        Action<object?>? assign = null
    )
    {
        if (value is null || state.Errors.Count >= 20)
        {
            return;
        }

        if (depth > MaxObjectDepth)
        {
            state.Add(path, $"Object depth cannot exceed {MaxObjectDepth}.");
            return;
        }

        if (value is JsonElement jsonElement)
        {
            InspectJsonElement(jsonElement, path, depth, state);
            return;
        }

        state.VisitedNodes++;
        if (state.VisitedNodes > MaxVisitedNodes)
        {
            state.Add(path, "Request contains too many values.");
            return;
        }

        if (value is string text)
        {
            var sanitized = ValidateAndNormalizeString(text, path, state);
            if (!string.Equals(sanitized, text, StringComparison.Ordinal))
            {
                assign?.Invoke(sanitized);
            }
            return;
        }

        if (
            value is IFormFile
            || value is Stream
            || value is CancellationToken
            || IsSimpleType(value.GetType())
        )
        {
            return;
        }

        if (!value.GetType().IsValueType && !state.Seen.Add(value))
        {
            return;
        }

        if (value is IDictionary dictionary)
        {
            if (dictionary.Count > MaxCollectionItems)
            {
                state.Add(path, $"Dictionary cannot contain more than {MaxCollectionItems} entries.");
                return;
            }

            foreach (DictionaryEntry entry in dictionary)
            {
                var key = entry.Key?.ToString() ?? "<null>";
                ValidateAndNormalizeString(key, $"{path}.key", state);
                Inspect(entry.Value, $"{path}[{key}]", depth + 1, state);
            }
            return;
        }

        if (value is IList list)
        {
            if (list.Count > MaxCollectionItems)
            {
                state.Add(path, $"Collection cannot contain more than {MaxCollectionItems} items.");
                return;
            }

            for (var index = 0; index < list.Count; index++)
            {
                var capturedIndex = index;
                Inspect(
                    list[index],
                    $"{path}[{index}]",
                    depth + 1,
                    state,
                    sanitized => TrySetListItem(list, capturedIndex, sanitized)
                );
            }
            return;
        }

        if (value is IEnumerable enumerable)
        {
            var index = 0;
            foreach (var item in enumerable)
            {
                if (index >= MaxCollectionItems)
                {
                    state.Add(path, $"Collection cannot contain more than {MaxCollectionItems} items.");
                    return;
                }

                Inspect(item, $"{path}[{index}]", depth + 1, state);
                index++;
            }
            return;
        }

        foreach (
            var property in value
                .GetType()
                .GetProperties(BindingFlags.Instance | BindingFlags.Public)
                .Where(p => p.CanRead && p.GetIndexParameters().Length == 0)
        )
        {
            object? propertyValue;
            try
            {
                propertyValue = property.GetValue(value);
            }
            catch
            {
                continue;
            }

            Inspect(
                propertyValue,
                $"{path}.{property.Name}",
                depth + 1,
                state,
                sanitized => TrySetProperty(value, property, sanitized)
            );
        }
    }

    private static string ValidateAndNormalizeString(
        string value,
        string path,
        InspectionState state
    )
    {
        if (value.Length > MaxStringLength)
        {
            state.Add(path, $"String cannot exceed {MaxStringLength} characters.");
            return value;
        }

        if (value.Any(character => char.IsControl(character) && character is not '\r' and not '\n' and not '\t'))
        {
            state.Add(path, "String contains disallowed control characters.");
            return value;
        }

        var isSensitive = SensitivePropertyMarkers.Any(marker =>
            path.Contains(marker, StringComparison.OrdinalIgnoreCase)
        );

        if (
            !isSensitive
            && DangerousTextMarkers.Any(marker =>
                value.Contains(marker, StringComparison.OrdinalIgnoreCase)
            )
        )
        {
            state.Add(path, "String contains unsafe active-content markup.");
            return value;
        }

        if (isSensitive)
        {
            return value;
        }

        return value.Trim().Normalize(NormalizationForm.FormC);
    }

    private static void InspectJsonElement(
        JsonElement element,
        string path,
        int depth,
        InspectionState state
    )
    {
        if (depth > MaxObjectDepth)
        {
            state.Add(path, $"Object depth cannot exceed {MaxObjectDepth}.");
            return;
        }

        state.VisitedNodes++;
        if (state.VisitedNodes > MaxVisitedNodes)
        {
            state.Add(path, "Request contains too many values.");
            return;
        }

        switch (element.ValueKind)
        {
            case JsonValueKind.String:
                ValidateAndNormalizeString(element.GetString() ?? string.Empty, path, state);
                break;
            case JsonValueKind.Array:
            {
                var length = element.GetArrayLength();
                if (length > MaxCollectionItems)
                {
                    state.Add(path, $"JSON array cannot contain more than {MaxCollectionItems} items.");
                    return;
                }

                var index = 0;
                foreach (var item in element.EnumerateArray())
                {
                    InspectJsonElement(item, $"{path}[{index++}]", depth + 1, state);
                }
                break;
            }
            case JsonValueKind.Object:
            {
                var count = 0;
                foreach (var property in element.EnumerateObject())
                {
                    count++;
                    if (count > MaxCollectionItems)
                    {
                        state.Add(path, $"JSON object cannot contain more than {MaxCollectionItems} properties.");
                        return;
                    }

                    ValidateAndNormalizeString(property.Name, $"{path}.propertyName", state);
                    InspectJsonElement(property.Value, $"{path}.{property.Name}", depth + 1, state);
                }
                break;
            }
        }
    }

    private static bool IsSimpleType(Type type)
    {
        var underlying = Nullable.GetUnderlyingType(type) ?? type;
        return underlying.IsPrimitive
            || underlying.IsEnum
            || underlying == typeof(decimal)
            || underlying == typeof(Guid)
            || underlying == typeof(DateTime)
            || underlying == typeof(DateTimeOffset)
            || underlying == typeof(DateOnly)
            || underlying == typeof(TimeOnly)
            || underlying == typeof(Uri);
    }

    private static void TrySetProperty(object target, PropertyInfo property, object? value)
    {
        if (!property.CanWrite || property.SetMethod is null || !property.SetMethod.IsPublic)
        {
            return;
        }

        try
        {
            property.SetValue(target, value);
        }
        catch
        {
            // Immutable/init-only request models are still validated; they are just not normalized.
        }
    }

    private static void TrySetListItem(IList list, int index, object? value)
    {
        try
        {
            list[index] = value;
        }
        catch
        {
            // Read-only collections are still validated; they are just not normalized.
        }
    }

    private sealed class InspectionState
    {
        public int VisitedNodes { get; set; }

        public HashSet<object> Seen { get; } = new(ReferenceEqualityComparer.Instance);

        public Dictionary<string, string[]> Errors { get; } =
            new(StringComparer.OrdinalIgnoreCase);

        public void Add(string path, string error)
        {
            if (!Errors.ContainsKey(path))
            {
                Errors[path] = [error];
            }
        }
    }
}
