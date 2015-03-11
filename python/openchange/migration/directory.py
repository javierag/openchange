#!/usr/bin/python
# -*- coding: utf-8 -*-

# OpenChangeDB DB schema and its migrations
# Copyright (C) Enrique J. Hernández Blasco <ejhernandez@zentyal.com> 2015
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
"""
Migration for OpenChange directory schema and data
"""
from openchange.migration import migration, Migration
import ldb
import openchange.provision


@migration('directory', 1)
class AddRecipientAttributes(Migration):
    description = 'Add missing recipient attributes'

    @classmethod
    def apply(cls, cur, extra):
        lp = extra['lp']
        creds = extra['creds']
        names = extra['names']
        setup_path = extra['setup_path']
        reporter = openchange.provision.TextProgressReporter()

        # Add any misisng schema
        openchange.provision.install_schemas(setup_path, names, lp, creds, reporter, skip_existent=True)

        db = openchange.provision.get_local_samdb(names, lp, creds)
        schema_dn = "CN=Schema,CN=Configuration,%s" % names.domaindn
        upgrade_schema_ldif = """
dn: CN=Mail-Recipient,%(schema_dn)s
changetype: modify
add: mayContain
mayContain: msExchRecipientDisplayType
mayContain: msExchRecipientTypeDetails
"""
        upgrade_schema_ldif = upgrade_schema_ldif % {'schema_dn': schema_dn}
        try:
            db.modify_ldif(upgrade_schema_ldif)
        except Exception, ex:
            print "Error adding msExchRecipientTypeDetails and msExchRecipientDisplayType to Mail-Recipient schema: %s" % str(ex)

        # Add missing attributes for users
        user_upgrade_ldif = ""
        user_upgrade_ldif_template = """
dn: %(user_dn)s
add: msExchRecipientTypeDetails
msExchRecipientTypeDetails: 6
add: msExchRecipientDisplayType
msExchRecipientDisplayType: 0
"""
        base_dn = "CN=Users,%s" % names.domaindn
        ldb_filter = "(objectClass=user)"
        res = db.search(base=base_dn, scope=ldb.SCOPE_SUBTREE, expression=ldb_filter)
        for element in res:
            dn = element.dn.get_linearized()
            ldif = user_upgrade_ldif_template % {'user_dn': dn}
            user_upgrade_ldif += ldif + "\n"
            try:
                db.modify_ldif(user_upgrade_ldif)
            except Exception, ex:
                print "Error migrating user %s: %s. Skipping user" % (dn, str(ex))

    @classmethod
    def unapply(cls, cur):
        raise Exception("Cannot revert directory migrations")
