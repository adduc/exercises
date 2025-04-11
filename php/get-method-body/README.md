# Reading raw request bodies from GET requests in PHP

## Context

A project I am working on would benefit from caching certain GET
requests like search results that could be expensive to generate. While
thinking through the implementation, I became curious about "fat GET
requests" and their impact on caching.

## Testing

A makefile is provided to demonstrate the functionality. To serve the
example, run:

```bash
make serve
```

In a separate terminal, you can test the example with:

```bash
make test
```

Expected output:

```
<h1>$_GET</h1>
array (
  'a' => 'b',
)
<h1>$_POST</h1>
array (
)
<h1>Raw Input</h1>
'a=asdf'
```

## Lessons Learned

PHP does not parse the raw request body for GET requests, so `$_GET`
will not include any data from the request body. Instead, it only
populates `$_GET` from the query string.
