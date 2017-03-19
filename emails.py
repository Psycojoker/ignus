import os
import json
import base64
from lamson.encoding import from_file


def list_maildirs(path=None):
    if path is None:
        path = "."

    maildirs = []

    for i in os.listdir(path):
        if not os.path.isdir(i):
            continue

        if {"cur", "new", "tmp"}.issubset(set(os.listdir(i))):
            maildirs.append(i)

    return maildirs


def list_emails(maildir):
    def try_encoding(content):
        if content is None:
            return None

        try:
            return content.encode("Utf-8")
        except:
            try:
                return base64.b64encode(content)
            except:
                return content

    emails = []

    for status in ["new", "cur", "tmp"]:
        maildir_path = os.path.join(maildir, status)
        for i in [from_file(open(os.path.join(maildir_path, x), "r")) for x in os.listdir(maildir_path)]:
            emails.append({
                "headers": i.headers,
                "body": try_encoding(i.body),
                "content_encoding": i.content_encoding,
                "parts": [{
                    "body": json.dumps(try_encoding(x.body)),
                    "headers": x.headers,
                    "content_encoding": x.content_encoding,
                } for x in i.parts]
            })

    return emails
