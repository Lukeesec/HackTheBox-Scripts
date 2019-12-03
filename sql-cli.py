#!/usr/bin/env python

import pymysql

connection = pymysql.connect(<SETTIGNS>)
cmd = ''
while cmd != 'st0p':
    cmd=input("SQL: ")
    try:
        with connection.cursor() as cursor:
            sql = cmd
            cursor.execute(sql)
            result = cursor.fetchall()
            print(result)

    finally:
        print('__)')