<!DOCTYPE html>
<html>
<head>
    <title>Register</title>
    <meta charset="UTF-8">
    <link rel="stylesheet" type="text/css" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Register</h1>
        % if error:
            <p style="color:red;">{{error}}</p>
        % end
        <form action="/register" method="post">
            <input type="text" name="username" placeholder="Username" required><br>
            <input type="password" name="password" placeholder="Password" required><br>
            <input type="submit" value="Register">
        </form>
        <p>Already have an account? <a href="/login">Login here</a>.</p>
    </div>
</body>
</html>
