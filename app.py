from flask import Flask, render_template, request, redirect, url_for, send_from_directory
import os
import datetime

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'ado', 'do', 'sthlp'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def generate_toc():
    toc = "*! version 1.0.0 {}\n* My Stata Packages\n\n".format(datetime.date.today().strftime("%Y-%m-%d"))
    for filename in os.listdir(app.config['UPLOAD_FOLDER']):
        if allowed_file(filename):
            toc += "[{}]\n".format(filename)
            toc += "type: {}\n".format(filename.rsplit('.', 1)[1].lower())
            toc += "descr: Description of {}\n".format(filename)
            toc += "date: {}\n\n".format(datetime.date.today().strftime("%Y%m%d"))
    return toc

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        if 'file' not in request.files:
            return redirect(request.url)
        file = request.files['file']
        if file.filename == '':
            return redirect(request.url)
        if file and allowed_file(file.filename):
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], file.filename))
            return redirect(url_for('index'))
    return render_template('index.html', files=os.listdir(app.config['UPLOAD_FOLDER']))

@app.route('/uploads/<path:filename>')
def download_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/stata.toc')
def toc():
    return generate_toc(), {'Content-Type': 'text/plain; charset=utf-8'}

if __name__ == '__main__':
    app.run(debug=True)
