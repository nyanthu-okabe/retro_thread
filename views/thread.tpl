<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Loading thread...</title>
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

        <h1 id="thread-title"></h1>

        <div id="comments-container">
            <!-- Comments will be loaded here by JavaScript -->
        </div>

        % if user:
            <form id="new-comment-form">
                <h2>Post a Comment</h2>
                <textarea name="comment" rows="5" placeholder="Comment" required></textarea><br>
                <input type="submit" value="Post Comment">
            </form>
        % else:
            <p><a href="/login">Login</a> to post a comment.</p>
        % end

        <br>
        <a href="/">Back to Board</a>
    </div>

    <script>
        const threadId = {{thread_id}};

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

        // Function to render a single comment
        function renderComment(post) {
            const postDiv = document.createElement('div');
            postDiv.className = 'post';

            // Apply 5ch-style quoting
            let formattedComment = escapeHtml(post.comment);
            formattedComment = formattedComment.replace(/^&gt;(.+)/gm, '<span class="quote">&gt;$1</span>');

            postDiv.innerHTML = `
                <div class="post-header">
                    <span class="name">${escapeHtml(post.name)}</span>
                </div>
                <div class="post-body">
                    <p>${formattedComment}</p>
                </div>
            `;
            return postDiv;
        }

        // Function to fetch and display thread data
        async function loadThread() {
            const response = await fetch(`/api/thread/${threadId}`);
            if (!response.ok) {
                document.getElementById('thread-title').innerText = 'Thread not found';
                return;
            }
            const thread = await response.json();

            // Update title
            document.title = escapeHtml(thread.title);
            document.getElementById('thread-title').innerText = escapeHtml(thread.title);

            // Render comments
            const container = document.getElementById('comments-container');
            container.innerHTML = ''; // Clear existing comments
            thread.comments.forEach(post => {
                container.appendChild(renderComment(post));
            });
        }

        // Function to handle new comment submission
        async function handleNewCommentSubmit(event) {
            event.preventDefault();
            const form = event.target;
            const formData = new FormData(form);

            const response = await fetch(`/new_comment/${threadId}`, {
                method: 'POST',
                body: new URLSearchParams(formData)
            });

            if (response.ok) {
                form.reset();
                const result = await response.json();
                // Add the new comment to the page instantly
                const container = document.getElementById('comments-container');
                container.appendChild(renderComment(result.comment));
            } else {
                const result = await response.json();
                alert('Error: ' + result.error);
            }
        }

        // Initial load
        loadThread();

        // Set up polling to refresh thread every 5 seconds
        setInterval(loadThread, 5000);

        // Add event listener for the form
        const newCommentForm = document.getElementById('new-comment-form');
        if (newCommentForm) {
            newCommentForm.addEventListener('submit', handleNewCommentSubmit);
        }
    </script>
</body>
</html>