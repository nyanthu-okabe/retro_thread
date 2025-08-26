<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
    <meta charset="UTF-8">
    <link rel="stylesheet" type="text/css" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Login</h1>
        % if error:
            <p style="color:red;">{{error}}</p>
        % end
        <form action="/login" method="post">
            <input type="text" name="username" placeholder="Username" required><br>
            <input type="password" name="password" placeholder="Password" required><br>
            <input type="submit" value="Login">
        </form>
        <p>Don't have an account? <a href="/register">Register here</a>.</p>
    </div>
</body>
</html>
