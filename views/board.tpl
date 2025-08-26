<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test</title>
    <link rel="stylesheet" type="text/css" href="/static/style.css">
</head>
<body>
    <div class="container">
        <div class="header">
            % if user:
                <span>Welcome, {{user}}!</span>
                <a href="/logout">Logout</a>
            % else:
                <a href="/login">Login</a>
                <a href="/register">Register</a>
            % end
        </div>

        <h1>Nyanchu ch</h1>

        <div class="thread-list">
            <h2>Threads</h2>
            <ul id="thread-list-ul">
                <!-- Threads will be loaded here by JavaScript -->
            </ul>
        </div>

        % if user:
            <form id="new-thread-form">
                <h2>Create New Thread</h2>
                <input type="text" name="title" placeholder="Thread Title" required><br>
                <textarea name="comment" rows="5" placeholder="Comment" required></textarea><br>
                <input type="submit" value="Create Thread">
            </form>
        % else:
            <p><a href="/login">Login</a> to create a thread.</p>
        % end
    </div>

    <script>
        // Helper function to escape HTML for XSS prevention
        function escapeHtml(text) {
            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            };
            return text.replace(/[&<>"']/g, function(m) { return map[m]; });
        }

        // Function to fetch and display threads
        async function loadThreads() {
            const response = await fetch('/api/threads');
            const threads = await response.json();
            const ul = document.getElementById('thread-list-ul');
            ul.innerHTML = ''; // Clear existing list
            threads.forEach(thread => {
                const li = document.createElement('li');
                // Escape thread title before displaying
                li.innerHTML = `<a href="/thread/${thread.id}">${escapeHtml(thread.title)}</a>`;
                ul.appendChild(li);
            });
        }

        // Function to handle form submission
        async function handleNewThreadSubmit(event) {
            event.preventDefault(); // Prevent normal form submission
            const form = event.target;
            const formData = new FormData(form);

            const response = await fetch('/new_thread', {
                method: 'POST',
                body: new URLSearchParams(formData) // Correctly format form data
            });

            if (response.ok) {
                form.reset(); // Clear the form
                loadThreads(); // Reload the thread list
            } else {
                const result = await response.json();
                alert('Error: ' + result.error);
            }
        }

        // Initial load
        loadThreads();

        // Set up polling to refresh threads every 5 seconds
        setInterval(loadThreads, 5000);

        // Add event listener for the form
        const newThreadForm = document.getElementById('new-thread-form');
        if (newThreadForm) {
            newThreadForm.addEventListener('submit', handleNewThreadSubmit);
        }
    </script>
</body>
</html>
