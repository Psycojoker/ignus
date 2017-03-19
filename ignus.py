import subprocess
import json
from flask import Flask, Response, render_template
app = Flask(__name__)

from utils import crossdomain

from emails import list_maildirs, list_emails


@app.route("/maildir")
@crossdomain(origin="http://localhost:3000")
def maildirs():
    return Response(json.dumps(list_maildirs()), mimetype="application/json")


@app.route("/maildir/<maildir>")
@crossdomain(origin="http://localhost:3000")
def emails(maildir):
    return Response(json.dumps(list_emails(maildir), indent=4), mimetype="application/json")


@app.route("/")
def index():
    p = subprocess.Popen("elm-make frontend/index.elm --output templates/index.html", shell=True, stderr=subprocess.STDOUT, stdout=subprocess.PIPE)
    if p.wait() != 0:
        return '<div style="margin: auto; max-width: 700px; margin-top: 80px"><pre style="padding: 15px; background-color: #eee; white-space: pre-wrap;">' + p.communicate()[0] + '</pre></div>'

    return render_template("index.html")


if __name__ == "__main__":
    app.run(debug=True)
