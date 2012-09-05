#!/usr/bin/python
#coding=utf-8
# A python script for publishing app packages.
# The app packages can be publish to ftp server and git repos.

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

# app publish dir
__app_publish_dir__ = "/opt/scm/app_publish"

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
        print '''Usage: %s app_dir app_regex
        Publish app packages to products repos(ftp, git, etc).

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
    publish_apps(sys.argv[1], sys.argv[2])


def publish_apps(app_dir, app_regex):
    """ Publish matched app packages to the products repos. """

    if not os.path.isdir(app_dir):
        print '%s is not a directory.' % app_dir
        sys.exit()

    matched_pkgs = []
    matched_dirs = []
    all_files = os.listdir(app_dir)
    for p in all_files:
        m = re.search(app_regex, p, re.I)
        if m is None:
            continue
        if os.path.isdir(app_dir + "/" + p):
            matched_dirs += [p]
        else:
            matched_pkgs += [p]
    matched_pkgs.sort()
    matched_dirs.sort()

    if not matched_pkgs and not matched_dirs:
        print "Can't find any app packages with regex '%s'." % app_regex
        sys.exit()

    is_ftp_usable = True
    ftp = ftplib.FTP(__ftp_host__)
    try:
        #ftp.set_debuglevel(2)
        ftp.login(__ftp_user__, __ftp_pass__)
    except ftplib.error_perm:
        is_ftp_usable = False
        print "Login ftp failed with user '%s'. App packages will not be uploaded to ftp server." % __ftp_user__

    if is_ftp_usable:
        print "\nUploading all matched packages to ftp[%s]:\n" % __ftp_host__
        for pkg_name in matched_pkgs:
            ftp_publish(app_dir, pkg_name, ftp)
        ftp.quit()
        ftp.close()

    for pkg_name in matched_dirs:
        git_publish(app_dir, pkg_name)

    print ""


def extract_app_info(package_name):
    """ Extract app info from app's package/dir name. """
    # package name is like this:
    #   demo-1.1.0-r16859-release.war, demo-1.1.0-r16859-release-sql.zip
    #   demo-sub-1.0.0-r16565-release.war, demo-sub-1.0.0-r16565-release-sql.zip
    #   demo-1.0.0-r16565-release, demo-sub-1.0.0-r16565-release
    app_info = package_name.split('-')
    m = re.search('(\d\.)+', app_info[1])
    if m is None:
        app_fullname = app_info[0] + '-' + app_info[1]
        app_version = app_info[2]
        app_cls_suffix = app_info[4]
    else:
        app_fullname = app_info[0]
        app_version = app_info[1]
        app_cls_suffix = app_info[3]

    # app_fullname example: demo, demo-sub
    app_type_index = app_fullname.find('_')
    if app_type_index == -1:
        app_name = app_fullname
    else:
        app_name = app_fullname[:app_type_index]
        app_type = app_fullname[app_type_index]

    # major version example: 1.1
    app_major_version = app_version[:3]

    # app_cls_suffix example: release, release.war, release.zip
    dot_index = app_cls_suffix.find('.')
    if dot_index == -1:
        app_classifier = app_cls_suffix
    else:
        app_classifier = app_cls_suffix[:dot_index]

    app_info_dict = {"app_name": app_name, "app_fullname": app_fullname, "app_type": app_type,
                    "app_classifier": app_classifier, "app_major_version": app_major_version,
                    "app_version": app_version}
    return app_info_dict 


def git_publish(app_dir, pkg_name):
    """ Publish app packages to git repos. """

    app_info = extract_app_info(pkg_name)
    app_name = app_info["app_name"]
    app_fullname = app_info["app_fullname"]
    app_deploy_dir = __app_publish_dir__ + "/" + app_name + "-deploy"
    if not os.path.exists(app_deploy_dir):
        print "Package will not be published to git repos because there is no repos '%s'." % app_deploy_dir
        #sys.exit()
        continue

    working_dir = os.getcwd()
    print "Changing dir %s -> %s..." % (working_dir, app_deploy_dir)
    os.chdir(app_deploy_dir)
    # Checkout git branch
    os.system("git checkout -B %s" % app_fullname)
    # Update package files of git repos
    pkg_full_path = os.path.join(working_dir, app_dir, pkg_name)
    print "Copying %s/* -> %s..." % (pkg_full_path, app_deploy_dir)
    os.system("cp %s/* -rp %s" % (pkg_full_path, app_deploy_dir))
    #os.chdir(app_deploy_dir)
    os.system("git add .")
    os.system("git commit -m 'Deployment publish commit.'")
    os.system("git push origin %s" % app_fullname)
    # reset working dir
    os.chdir(working_dir)


def ftp_publish(pkg_name, app_dir, ftp):
    """ Publish app packages to ftp server. """

    app_info = extract_app_info(pkg_name)
    app_classifier = app_info["app_classifier"]
    app_name = app_info["app_name"]
    app_major_version = app_info["app_major_version"]
    remote_path = os.path.join(__ftp_dir__, app_classifier, app_name, app_major_version)
    ftp_mkds(ftp, remote_path)

    try:
        print "\t%s => %s" % (pkg_name, remote_path)
        pkg_file = os.path.join(app_dir, pkg_name)
        openFile = open(pkg_file, 'rb')

        ftp.cwd(remote_path)
        ftp.storbinary('STOR ' + pkg, openFile, 8196)
    finally:
        if openFile:
            openFile.close()


def ftp_mkds(ftp, path):
    """ Create ftp dirs. """

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

