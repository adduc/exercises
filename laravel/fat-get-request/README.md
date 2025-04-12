# Playing with "fat" GET requests in Laravel

This exercise shows how Laravel handles GET requests with a request body when the `Content-Type` is set to `application/json`. It highlights the potential for unexpected behavior when query string parameters are overridden by the request body.

## Example

With the following Laravel Route (QueryRequest has a single rule for 'a' to be required and a string):

```php
Route::get('/', function (QueryRequest $request) {
    return [
        'all' => $request->all('a'),
        'get' => $request->get('a'),
        'query' => $request->query('a'),
        'input' => $request->input('a'),
        'validated' => $request->validated()['a'] ?? null,
    ];
});
```

You can test the behavior with a curl command:

```bash
curl "localhost:8000/?a[]=b&a[]=c" \
  -X GET \
  --data '{"a":"asdf"}' \
  -H 'Content-Type: application/json'
```

This will return JSON:

```jsonc
// formatted for clarity
{
    "all": [
        "asdf"
    ],
    "get": "asdf",
    "query": [
        "b",
        "c"
    ],
    "input": "asdf",
    "validated": "asdf"
}
```

Despite a validation rule requiring 'a' to be a string, the request body with `Content-Type: application/json` has overridden the query string parameters when the validation occurs. An application following best practices of using `$request->validated()` would use data from the request body instead of the query string.

## Potential Impact

If the Laravel application were to be served behind a CDN and the query string parameters were used as a cache key (e.g. for common filters), this could lead to cache poisoning, as the CDN would cache the response based on the request body rather than the query string.

Access logs may also show the query string parameters as they were sent, while the application processed different parameters due to the request body overriding them. This can make diagnosing issues more difficult.

## Lessons Learned

Laravel will parse GET request bodies if the `Content-Type` header is set to `application/json`, and **override** the query string parameters in certain request methods due to the way Laravel handles request data.
