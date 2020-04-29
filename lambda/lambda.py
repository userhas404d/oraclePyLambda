import cx_Oracle
import os
import sys


def handler(event, context):

    con = cx_Oracle.connect(
        os.environ["user"],
        os.environ["password"],
        os.environ["endpoint"] + "/" + os.environ["my_db"],
    )

    return con.version
