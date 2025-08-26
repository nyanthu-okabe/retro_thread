import json
import os
from bottle import (
    route, run, template, request, redirect, static_file, response, SimpleTemplate, error, Bottle
)
from werkzeug.security import generate_password_hash, check_password_hash
from test.test_typing import BottomTypeTestsMixin
#from black.output import err

# --- 設定 ---
DATA_FILE = 'threads.json'
USERS_FILE = 'users.json'
SECRET_KEY = 'your_very_secret_key'  # 必ず複雑なキーに変更してください

# --- テンプレートのデフォルトエンコーディング設定 ---
SimpleTemplate.defaults['encoding'] = 'utf-8'



application = Bottle()


# --- データ操作 ---
def load_json(filename):
    if os.path.exists(filename) and os.path.getsize(filename) > 0:
        with open(filename, 'r', encoding='utf-8') as f:
            try:
                return json.load(f)
            except json.JSONDecodeError:
                return {} if filename == USERS_FILE else []
    return {} if filename == USERS_FILE else []

def save_json(data, filename):
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

load_threads = lambda: load_json(DATA_FILE)
save_threads = lambda data: save_json(data, DATA_FILE)
load_users = lambda: load_json(USERS_FILE)
save_users = lambda data: save_json(data, USERS_FILE)

# --- ユーザー認証 ---
def get_current_user():
    username = request.get_cookie('username', secret=SECRET_KEY)
    return username

# --- HTMLページ表示ルート ---
@application.route('/static/<filename>')
def server_static(filename):
    return static_file(filename, root='./static')

@application.route('/')
def index():
    user = get_current_user()
    # 初期表示はテンプレートを返すだけ。データはJSで読み込む
    return template('board', user=user)

@application.route('/thread/<thread_id>')
def view_thread(thread_id):
    user = get_current_user()
    # 初期表示はテンプレートを返すだけ。データはJSで読み込む
    return template('thread', thread_id=thread_id, user=user, thread={})

# --- APIルート (JSONを返す) ---
@application.route('/api/threads')
def api_threads():
    response.content_type = 'application/json'
    threads = load_threads()
    # スレッドIDを各スレッドに追加して返す
    threads_with_ids = [dict(t, id=i) for i, t in enumerate(threads)]
    return json.dumps(threads_with_ids)

@application.route('/api/thread/<thread_id>')
def api_view_thread(thread_id):
    response.content_type = 'application/json'
    threads = load_threads()
    thread_id = int(thread_id)
    if 0 <= thread_id < len(threads):
        return json.dumps(threads[thread_id])
    response.status = 404
    return json.dumps({'error': 'Thread not found'})

@application.route('/new_thread', method='POST')
def new_thread():
    user = get_current_user()
    if not user:
        response.status = 401 # Unauthorized
        return {'error': 'Please login to post.'}

    title = request.forms.getunicode('title')
    comment = request.forms.getunicode('comment')

    if title and comment:
        threads = load_threads()
        new_thread_data = {
            'title': title,
            'comments': [{'name': user, 'comment': comment}]
        }
        threads.append(new_thread_data)
        save_threads(threads)
        response.status = 201 # Created
        return {'success': True, 'thread': new_thread_data}
    response.status = 400 # Bad Request
    return {'error': 'Title and comment are required.'}

@application.route('/new_comment/<thread_id>', method='POST')
def new_comment(thread_id):
    user = get_current_user()
    if not user:
        response.status = 401 # Unauthorized
        return {'error': 'Please login to post.'}

    threads = load_threads()
    thread_id = int(thread_id)

    if 0 <= thread_id < len(threads):
        comment = request.forms.getunicode('comment')
        if comment:
            new_comment_data = {'name': user, 'comment': comment}
            threads[thread_id]['comments'].append(new_comment_data)
            save_threads(threads)
            response.status = 201 # Created
            return {'success': True, 'comment': new_comment_data}
    response.status = 400 # Bad Request
    return {'error': 'Comment is required.'}

# --- ログイン/登録/ログアウト (変更なし) ---
@application.route('/register', method=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.forms.getunicode('username')
        password = request.forms.getunicode('password')
        users = load_users()
        if username in users:
            return template('register', error="Username already exists.")
        if not username or not password:
            return template('register', error="Username and password are required.")
        users[username] = generate_password_hash(password)
        save_users(users)
        response.set_cookie('username', username, secret=SECRET_KEY, path='/')
        return redirect('/')
    return template('register', error=None)

@application.route('/login', method=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.forms.getunicode('username')
        password = request.forms.getunicode('password')
        users = load_users()
        if username not in users or not check_password_hash(users[username], password):
            return template('login', error="Invalid username or password.")
        response.set_cookie('username', username, secret=SECRET_KEY, path='/')
        return redirect('/')
    return template('login', error=None)

@application.route('/logout')
def logout():
    response.delete_cookie('username', path='/')
    return redirect('/')

@application.error(403)
@application.error(404)
@application.error(405)
@application.error(500)
def error_return(error):
    return template('error',
        error_body=error.body,
        error_status=error.status)

if __name__ == '__main__':
    run(app=application, host='localhost', port=8081)
