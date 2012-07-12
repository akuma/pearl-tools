#!/usr/bin/python
#coding=utf-8
# A python script for uploading product package to ftp server.

import sys
import re
import os
from ftplib import FTP

__version__ = "0.1"

# ftp info
__ftp_host__ = "ftp.gm.com"
__ftp_user__ = "anonymous"
__ftp_pass__ = ""
__ftp_dir__ = "/products"

def upload_package(package_dir, package_regex):
    if not os.path.exists(package_dir):
        print '%s is not a directory' % package_dir
        sys.exit()

    matched_packages = []
    all_packages = os.listdir(package_dir)
    for p in all_packages:
        m = re.search(package_regex, p, re.I)
        if m is not None:
            matched_packages += [p]
    matched_packages.sort()

    if not matched_packages:
        print "Can't find any product package with regex '%s'." % package_regex
        sys.exit()

    # package name is like this: demo-1.1.0-r16859-release.war
    latest_package = matched_packages[-1]

    package_infos = latest_package.split('-')
    package_classifier = package_infos[:-4]
    package_name = package_infos[0]
    package_major_version = package_infos[1][:3]
    remote_path = os.path.join(__ftp_dir__, package_classifier, package_name, package_major_version)

    try:
        latest_package_file = os.path.join(package_dir, latest_package)
        #print 'Latest package file is %s' % latest_package_file
        openFile = open(latest_package_file, 'rb')

        ftp = FTP(__ftp_host__)
        #ftp.set_debuglevel(2)
        ftp.login(__ftp_user__, __ftp_pass__)
        ftp.cwd(remote_path)

        print '''Uploading latest product package to ftp:

\t%s => %s
''' % (latest_package, remote_path)

        ftp.storbinary('STOR ' + latest_package, openFile, 8196)
    finally:
        if ftp:
            ftp.quit()
        if openFile:
            openFile.close()

# Script starts from here
if len(sys.argv) < 2:
    print '''%s: too few arguments
Try `%s --help' for more information.''' % (sys.argv[0], sys.argv[0])
    sys.exit()

if sys.argv[1].startswith('--'):
    option = sys.argv[1][2:]
    # Fetch sys.argv[1] but without the first two characters
    if option == 'version':
        print '%s %s' % (sys.argv[0], __version__)
        sys.exit()
    elif option == 'help':
        print '''Usage: %s [OPTION] package_dir package_regex
Upload product package to ftp server.

Options include:
  --version        Prints the version number
  --help           Display this help''' % sys.argv[0]
    else:
        print '''%s: invalid option -- %s
Try `%s --help' for more information.''' % (sys.argv[0], option, sys.argv[0])
        sys.exit()
elif len(sys.argv) != 3:
    print '''%s: too few arguments
Try `%s --help' for more information. ''' % (sys.argv[0], sys.argv[0])
else:
    upload_package(sys.argv[1], sys.argv[2])

