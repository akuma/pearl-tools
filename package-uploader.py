#!/usr/bin/python
#coding=utf-8
# A python script for uploading product package to ftp server.

import sys
import re
import os
import ftplib

__version__ = "0.1"

# ftp params
__ftp_host__ = "ftp.gm.com"
__ftp_user__ = "anonymous"
__ftp_pass__ = ""
__ftp_dir__ = "/products"

def upload_package(package_dir, package_regex):
    """Upload matched product package files to the ftp."""

    if not os.path.exists(package_dir):
        print '%s is not a directory' % package_dir
        sys.exit()

    matched_pkgs = []
    all_pkgs = os.listdir(package_dir)
    for p in all_pkgs:
        m = re.search(package_regex, p, re.I)
        if m is not None:
            matched_pkgs += [p]
    matched_pkgs.sort()

    if not matched_pkgs:
        print "Can't find any product package with regex '%s'." % package_regex
        sys.exit()


    ftp = ftplib.FTP(__ftp_host__)
    try:
        #ftp.set_debuglevel(2)
        ftp.login(__ftp_user__, __ftp_pass__)
    except ftplib.error_perm:
        print "Login ftp failed with user '%s'." % __ftp_user__
        ftp.quit()
        ftp.close()
        sys.exit()

    print "\nUploading all matched packages to ftp[%s]:\n" % __ftp_host__
    for pkg in matched_pkgs:
        # package name is like this:
        #   demo-1.1.0-r16859-release.war, demo-1.1.0-r16859-release-sql.zip
        #   demo-sub-1.0.0-r16565-release.war, demo-sub-1.0.0-r16565-release.war
        pkg_infos = pkg.split('-')
        m = re.search('^\d\.\d$', pkg_infos[1], re.I)
        if m is None:
            pkg_fullname = pkg_infos[0] + '-' + pkg_infos[1]
            pkg_version = pkg_infos[2]
            pkg_cls_suffix = pkg_infos[4]
        else:
            pkg_fullname = pkg_infos[0]
            pkg_version = pkg_infos[1]
            pkg_cls_suffix = pkg_infos[3]

        # pkg_fullname example: demo, demo-sub
        pkg_type_index = pkg_fullname.find('_')
        if pkg_type_index == -1:
            pkg_name = pkg_fullname
        else:
            pkg_name = pkg_fullname[:pkg_type_index]
            pkg_type = pkg_fullname[pkg_type_index]

        # major version example: 1.1
        pkg_major_version = pkg_version[:3]

        # pkg_cls_suffix example: release, release.war, release.zip
        dot_index = pkg_cls_suffix.find('.')
        if dot_index == -1:
            pkg_classifier = pkg_cls_suffix
        else:
            pkg_classifier = pkg_cls_suffix[:dot_index]

        remote_path = os.path.join(__ftp_dir__, pkg_classifier, pkg_name, pkg_major_version)
        ftp_mkds(ftp, remote_path)

        try:
            print "\t%s => %s" % (pkg, remote_path)
            pkg_file = os.path.join(package_dir, pkg)
            openFile = open(pkg_file, 'rb')

            ftp.cwd(remote_path)
            ftp.storbinary('STOR ' + pkg, openFile, 8196)
        finally:
            if openFile:
                openFile.close()

    ftp.quit()
    ftp.close()
    print ""

def ftp_mkds(ftp, path):
    """Create ftp dirs."""

    path = path.split("/")
    for i in xrange(len(path)):
        p = "/".join(path[:i+1])
        try:
            ftp.cwd(p)
        except ftplib.error_perm:
            try:
                ftp.mkd(p)
            except ftplib.error_perm:
                print "\nERROR: User '%s' has no permission to make dir %s" % (__ftp_user__, p)
                break

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
        print '''Usage: %s package_dir package_regex
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
