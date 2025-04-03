# Notes: Laravel Authentication

I wrote this document while diving through Laravel's authentication components in an attempt to understand what is provided out-of-box and what extensibility options are available. I've tried to document my thoughts between code snippets from Laravel's source code.

## What Are Guards?

```php

// Each of the supported guard drivers in Laravel implement the Guard interface. Let's take a look at the interface to get a sense of what a guard is responsible for.

namespace Illuminate\Contracts\Auth

interface Guard
{
    /**
     * Determine if the current user is authenticated.
     *
     * @return bool
     */
    public function check();

    /**
     * Determine if the current user is a guest.
     *
     * @return bool
     */
    public function guest();

    /**
     * Get the currently authenticated user.
     *
     * @return \Illuminate\Contracts\Auth\Authenticatable|null
     */
    public function user();

    /**
     * Get the ID for the currently authenticated user.
     *
     * @return int|string|null
     */
    public function id();

    /**
     * Validate a user's credentials.
     *
     * @param  array  $credentials
     * @return bool
     */
    public function validate(array $credentials = []);

    /**
     * Determine if the guard has a user instance.
     *
     * @return bool
     */
    public function hasUser();

    /**
     * Set the current user.
     *
     * @param  \Illuminate\Contracts\Auth\Authenticatable  $user
     * @return $this
     */
    public function setUser(Authenticatable $user);
}

// From the interface, we can see that a guard is responsible for checking if a user is authenticated, retrieving the currently authenticated user, validating user credentials, and setting the current user.

```

## Resolving Guards

```php

// Let's start by trying to get a guard instance using the auth() helper function.
$guard = auth('web');

// behind the scenes, this is equivalent to:
// @see vendor/laravel/framework/src/Illuminate/Foundation/helpers.php
$guard = app(AuthFactory::class)->guard('web');

// AuthFactory resolves to Illuminate\Auth\AuthManager
// @see Illuminate\Foundation\Application::registerCoreContainerAliases
// @see https://laravel.com/docs/12.x/facades

// AuthManager::guard
public function guard($name = null)
{
    $name = $name ?: $this->getDefaultDriver();

    return $this->guards[$name] ?? $this->guards[$name] = $this->resolve($name);
}

// The guard function retrieves the guard instance for the specified name (resolving the guard if it hasn't been created yet).

// AuthManager::resolve
protected function resolve($name)
{
    $config = $this->getConfig($name);

    if (is_null($config)) {
        throw new InvalidArgumentException("Auth guard [{$name}] is not defined.");
    }

    if (isset($this->customCreators[$config['driver']])) {
        return $this->callCustomCreator($name, $config);
    }

    $driverMethod = 'create'.ucfirst($config['driver']).'Driver';

    if (method_exists($this, $driverMethod)) {
        return $this->{$driverMethod}($name, $config);
    }

    throw new InvalidArgumentException(
        "Auth driver [{$config['driver']}] for guard [{$name}] is not defined."
    );
}

// getConfig works as you would expect, effectively returning the auth.php config for the specified guard name.

// What are custom creators? Searching through the AuthManager, the only place the customCreators property is set is in the extend method.
public function extend($driver, Closure $callback)
{
    $this->customCreators[$driver] = $callback;

    return $this;
}

// The extend method is publicly accessible, so you can add your own custom guard drivers if you want to. Looking for uses of the function, the AuthManager's viaRequest method makes use of it to allow you to specify a guard for a request.
// @see https://laravel.com/docs/12.x/authentication#closure-request-guards
public function viaRequest($driver, callable $callback)
{
    return $this->extend($driver, function () use ($callback) {
        $guard = new RequestGuard($callback, $this->app['request'], $this->createUserProvider());

        $this->app->refresh('request', $guard, 'setRequest');

        return $guard;
    });
}

// Of note, when custom drivers are resolved, their closure callback is passed `$this->app, $name, $config`, which means you have access to the application instance, the guard name, and the configuration for the guard. This allows the guard to take into account providers or any other configuration that may be relevant to the guard's implementation.

// Getting back to resolve, when no custom creator is defined for the driver, it will call the create{Driver}Driver method on the AuthManager. For example, for the session driver, it will call createSessionDriver. Despite behind named create{Driver}Driver, it actually returns an implementation of the Guard interface, which appeares to be the base interface for all guards in Laravel.

// Thus, resolve should always return an object that implements Illuminate\Contracts\Auth\Guard
```

## Using Guards

```php
// Laravel's documentation provides an example of how to use guards in a route definition. The example uses the api guard.
Route::middleware('auth:api')->get('/user', fn () => /* ... */ );

// Where is the auth middleware alias defined? Searching through the framework, we find it in Illuminate\Foundation\Configuration\Middleware::defaultAliases(), and it resolves to Illuminate\Auth\Middleware\Authenticate

// Something Laravel's documentation doesn't mention but the auth middleware appears to support: you can specify multiple guards for the middleware.
// @see Illuminate\Auth\Middleware\Authenticate::handle

protected function authenticate($request, array $guards)
{
    if (empty($guards)) {
        $guards = [null];
    }

    foreach ($guards as $guard) {
        if ($this->auth->guard($guard)->check()) {
            return $this->auth->shouldUse($guard);
        }
    }

    $this->unauthenticated($request, $guards);
}


// For example, you can specify both the web and api guards like so:
Route::middleware('auth:web,api')->get('/user', fn () => /* ... */ );

// If you specify multiple guards, the middleware will check each guard in the order specified until one determines the user is authenticated. If none of the guards authenticate the user, the unauthenticated method is called, which will typically return a 401 Unauthorized response.
```


## What are User Providers?

Looking through the `config/auth.php` file, we can see that there is a providers key. We can also see that providers are referenced in some of the guards. What are user providers? Laravel's documentation doesn't proivde a lot of detail, so let's dive into the source code to find out.

```php

// The auth middleware does not have any references to user providers; it looks like providers are managed by AuthManager. Looking at the class, we can see a provider function, which interacts with the customProvidersCreators property, similar to how custom guard drivers are managed.
public function provider($name, Closure $callback)
{
    $this->customProviderCreators[$name] = $callback;

    return $this;
}

// There's also a call to createUserProvider in the viaRequest, createSessionDriver, and createTokenDriver methods. It looks like the bulk of the provider functionality is implemented within the CreatesUserProviders trait, which is used by the AuthManager.
public function createUserProvider($provider = null)
{
    if (is_null($config = $this->getProviderConfiguration($provider))) {
        return;
    }

    if (isset($this->customProviderCreators[$driver = ($config['driver'] ?? null)])) {
        return call_user_func(
            $this->customProviderCreators[$driver], $this->app, $config
        );
    }

    return match ($driver) {
        'database' => $this->createDatabaseProvider($config),
        'eloquent' => $this->createEloquentProvider($config),
        default => throw new InvalidArgumentException(
            "Authentication user provider [{$driver}] is not defined."
        ),
    };
}

// Similar to guards, the createUserProvider method will attempt to use a custom provider if defined, otherwise it will use one of the built-in providers.

// The createUserProvider returns an object that implements Illuminate\Contracts\Auth\UserProvider

// I've modified the code snippet to include the hinted return types.
// The actual code defines these in comments

interface UserProvider
{
    public function retrieveById($identifier): ?Authenticatable;
    public function retrieveByToken($identifier, #[\SensitiveParameter] $token): ?Authenticatable;
    public function updateRememberToken(Authenticatable $user, #[\SensitiveParameter] $token): void;
    public function retrieveByCredentials(#[\SensitiveParameter] array $credentials): ?Authenticatable;
    public function validateCredentials(Authenticatable $user, #[\SensitiveParameter] array $credentials): bool;
    public function rehashPasswordIfRequired(Authenticatable $user, #[\SensitiveParameter] array $credentials, bool $force = false): void;
}

// The UserProvider trait allows for user retrieval, credential validation, and management of remember tokens.

// The Authenticatable interface that's returned is used by a lot of other classes in Laravel's authentication system.

interface Authenticatable
{
    public function getAuthIdentifierName();
    public function getAuthIdentifier();
    public function getAuthPasswordName();
    public function getAuthPassword();
    public function getRememberToken();
    public function setRememberToken($value);
    public function getRememberTokenName();
}

// For situations where Eloquent is not used, a GenericUser class is available to return an Authenticatable object from an array of attributes. It's used by the DatabaseUserProvider.



```
