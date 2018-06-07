import requests
import json
import csv
import datetime
import argparse

from influxdb import InfluxDBClient

# epoch = datetime.datetime.utcfromtimestamp(0)
def unix_time_hours(dt):
    return int(dt.total_seconds() * 3600)

def loadCsv(csvfile, server, user, password, metric, timecolumn, timeformat, tagcolumns, fieldcolumns, delimiter):
    host = '54.193.103.207'
    port = 8086
    dbname= 'power-data'
    # user = 'ubuntu'
    # password = 'Slac_2018'
    client = InfluxDBClient(host, port, user, password, dbname)

    print('Creating Database %s'%dbname)
    client.create_database(dbname)




if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Csv to influxdb.')
    parser.add_argument('-i', '--input', nargs='?', required=True, help='Input csv file.')
    parser.add_argument('-d', '--delimiter', nargs='?', required=False,default=',', help='CSV delimiter. Default:\',\'.')
    parser.add_argument('-s', '--server', nargs='?', default='54.193.103.207:8086', help='Server address. Default:54.193.103.207:8086')
    parser.add_argument('-u', '--user', nargs='?', default='ubuntu', help='user name.')
    parser.add_argument('-p', '--password', nargs='?', default='Slac_2018', help='password')
    # parser.add_argument('--dbname', nargs='?', required=false, default='power-data', help="DataBase name")
    parser.add_argument('-m', '--metricname', nargs='?', default='value',
                        help='Metric column name. Default: value')
    parser.add_argument('-tc', '--timecolumn', nargs='?', default='timestamp',
                        help='Timestamp column name. Default: timestamp.')
    parser.add_argument('-tf', '--timeformat', nargs='?', default='%Y-%m-%d %H:%M:%S',
                        help='Timestamp format. Default: \'%%Y-%%m-%%d %%H:%%M:%%S\' e.g.: 1970-01-01 00:00:00')
    parser.add_argument('--fieldcolumns', nargs='?', default='value',
                        help='List of csv columns to use as fields, separated by comma, e.g.: value1,value2. Default: value')

    parser.add_argument('--tagcolumns', nargs='?', default='host',
                        help='List of csv columns to use as tags, separated by comma, e.g.: host,data_center. Default: host')
    #
    # parser.add_argument('-g', '--gzip', action='store_true', default=False,
    #                     help='Compress before sending to influxdb.')

    args = parser.parse_args()
    loadCsv(args.input, args.server, args.user, args.password, args.metricname, args.timecolumn, args.timeformat, args.tagcolumns, args.fieldcolumns, args.delimiter)
