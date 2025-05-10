<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="dark light">
    <title>Register | Lumen Bookmark DB</title>
</head>
<body>
    <h1>Lumen Bookmark DB</h1>
    <h2>Register</h2>
    @if (!empty($error))
        <p style="color: red;">{{ $error }}</p>
    @endif
    <form method="post">
        <label for="email">Email:</label>
        <input type="text" id="email" name="email" required><br><br>
        <label for="password">Password:</label>
        <input type="password" id="password" name="password" required><br><br>
        <label for="confirm_password">Confirm Password:</label>
        <input type="password" id="confirm_password" name="confirm_password" required><br><br>
        <button type="submit">Register</button>
    </form>
</body>
</html>