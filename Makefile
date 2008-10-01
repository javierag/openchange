# Makefile for OpenChange
# Written by Jelmer Vernooij <jelmer@samba.org>, 2005.

default: all

# Until we add proper dependencies for all the C files:
.NOTPARALLEL:

config.mk: config.status config.mk.in
	./config.status

config.status: configure
	./configure

configure: configure.ac
	autoconf -f

samba:
	./script/installsamba4.sh all

samba-git: 
	./script/installsamba4.sh git-all

ifneq ($(MAKECMDGOALS), samba)
ifneq ($(MAKECMDGOALS), samba-git)
include config.mk
endif
endif

#################################################################
# top level compilation rules
#################################################################

all: 		$(OC_IDL)		\
		$(OC_LIBS)		\
		$(OC_TOOLS)		\
		$(OC_TORTURE)		\
		$(OC_SERVER)		\
		$(SWIGDIRS-ALL)					

install: 	all 			\
		installlib 		\
		installpc 		\
		installheader 		\
		$(OC_TOOLS_INSTALL) 	\
		$(OC_SERVER_INSTALL) 	\
		$(OC_TORTURE_INSTALL) 	\
		$(SWIGDIRS-INSTALL) 	\
		installnagios

installlib:	$(OC_LIBS_INSTALL)
installpc:	$(OC_LIBS_INSTALLPC)
installheader:	$(OC_LIBS_INSTALLHEADERS)

uninstall:: 	$(OC_LIBS_UNINSTALL) 	\
		$(OC_TOOLS_UNINSTALL) 	\
		$(OC_SERVER_UNINSTALL) 	\
		$(OC_TORTURE_UNINSTALL) \
		$(SWIGDIRS-UNINSTALL)

distclean:: clean
	rm -rf autom4te.cache
	rm -f Doxyfile
	rm -f libmapi/Doxyfile
	rm -f libmapiadmin/Doxyfile
	rm -f libocpf/Doxyfile
	rm -f libmapi++/Doxyfile
	rm -f mapiproxy/Doxyfile
	rm -f config.status config.log
	rm -f utils/mapitest/Doxyfile
	rm -f intltool-extract intltool-merge intltool-update
	rm -rf apidocs
	rm -rf gen_ndr
	rm -f tags

clean::
	rm -f *~
	rm -f */*~
	rm -f */*/*~
	rm -f doc/examples/mapi_sample1
	rm -f doc/examples/fetchappointment
	rm -f doc/examples/fetchmail

re:: clean install

#################################################################
# Suffixes compilation rules
#################################################################

.SUFFIXES: .c .o .h .po .idl

.idl.h:
	@echo "Generating $@"
	@$(PIDL) --outputdir=gen_ndr --header -- $<

.c.o:
	@echo "Compiling $<"
	@$(CC) $(CFLAGS) -c $< -o $@

.c.po:
	@echo "Compiling $< with -fPIC"
	@$(CC) $(CFLAGS) -fPIC -c $< -o $@



#################################################################
# IDL compilation rules
#################################################################

idl: gen_ndr gen_ndr/ndr_exchange.h gen_ndr/ndr_property.h

exchange.idl: mapitags_enum.h mapicodes_enum.h

gen_ndr:
	@echo "Creating the gen_ndr directory"
	mkdir -p gen_ndr

gen_ndr/ndr_%.h gen_ndr/ndr_%.c: %.idl %.h
	@echo "Generating $@"
	@$(PIDL) --outputdir=gen_ndr --ndr-parser -- $<

gen_ndr/ndr_%_c.h gen_ndr/ndr_%_c.c: %.idl %.h
	@echo "Generating $@"
	@$(PIDL) --outputdir=gen_ndr --client -- $<

gen_ndr/ndr_%_s.c: %.idl
	@echo "Generating $@"
	@$(PIDL) --outputdir=gen_ndr --server -- $<



#################################################################
# libmapi compilation rules
#################################################################

LIBMAPI_SO_VERSION = 0

libmapi:	idl					\
		libmapi/version.h			\
		libmapi/proto.h				\
		libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)	

libmapi-install:	libmapi-installpc	\
			libmapi-installlib	\
			libmapi-installheader	\
			libmapi-installscript

libmapi-uninstall:	libmapi-uninstallpc	\
			libmapi-uninstalllib	\
			libmapi-uninstallheader	\
			libmapi-uninstallscript

libmapi-clean::
	rm -f libmapi/*.o libmapi/*.po
	rm -f libmapi/utf8_convert.yy.c
	rm -f libmapi/tests/*.o, libmapi/tests/*.po
	rm -f libmapi/socket/*.o libmapi/socket/*.po
	rm -f libmapi/util/*.o, libmapi/util/*.po
	rm -f libmapi/version.h
	rm -f libmapi/mapicode.c libmapi/mapicode.h
	rm -f libmapi/mapitags.c libmapi/mapitags.h
	rm -f libmapi/mapi_nameid.h libmapi/mapi_nameid_private.h
	rm -f libmapi/proto.h
	rm -f libmapi/proto_private.h
	rm -f gen_ndr/ndr_exchange*
	rm -f gen_ndr/exchange.h
	rm -f gen_ndr/ndr_property*
	rm -f gen_ndr/property.h
	rm -f ndr_mapi.o ndr_mapi.po
	rm -f mapicodes_enum.h
	rm -f mapitags_enum.h
	rm -f *~
	rm -f */*~
	rm -f */*/*~
	rm -f libmapi.$(SHLIBEXT).$(PACKAGE_VERSION) libmapi.$(SHLIBEXT).$(LIBMAPI_SO_VERSION) \
		  libmapi.$(SHLIBEXT)

clean:: libmapi-clean

libmapi-distclean::
	rm -f libmapi.pc

distclean:: libmapi-distclean

libmapi-installpc:
	@echo "[*] install: libmapi pc files"
	$(INSTALL) -d $(DESTDIR)$(libdir)/pkgconfig
	$(INSTALL) -m 0644 libmapi.pc $(DESTDIR)$(libdir)/pkgconfig

libmapi-installlib:
	@echo "[*] install: libmapi library"
	$(INSTALL) -d $(DESTDIR)$(libdir)
	$(INSTALL) -m 0755 libmapi.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)
	ln -sf libmapi.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)/libmapi.$(SHLIBEXT)

libmapi-installheader:
	@echo "[*] install: libmapi headers"
	$(INSTALL) -d $(DESTDIR)$(includedir)/libmapi 
	$(INSTALL) -d $(DESTDIR)$(includedir)/libmapi/socket 
	$(INSTALL) -d $(DESTDIR)$(includedir)/gen_ndr
	$(INSTALL) -m 0644 libmapi/dlinklist.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/libmapi.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/proto.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/nspi.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/emsmdb.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapi_ctx.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapi_provider.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapi_id_array.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapi_notification.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapi_object.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapi_profile.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapi_nameid.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapidefs.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/version.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/mapicode.h $(DESTDIR)$(includedir)/libmapi/
	$(INSTALL) -m 0644 libmapi/socket/netif.h $(DESTDIR)$(includedir)/libmapi/socket/
	$(INSTALL) -m 0644 gen_ndr/exchange.h $(DESTDIR)$(includedir)/gen_ndr/
	$(INSTALL) -m 0644 gen_ndr/property.h $(DESTDIR)$(includedir)/gen_ndr/

libmapi-installscript:
	$(INSTALL) -d $(DESTDIR)$(datadir)/setup
	# $(INSTALL) -m 0644 setup/oc_profiles* $(DESTDIR)$(datadir)/setup/

libmapi-uninstallpc:
	rm -f $(DESTDIR)$(libdir)/pkgconfig/libmapi.pc

libmapi-uninstalllib:
	rm -f $(DESTDIR)$(libdir)/libmapi.*

libmapi-uninstallheader:
	rm -rf $(DESTDIR)$(includedir)/libmapi
	rm -f $(DESTDIR)$(includedir)/gen_ndr/exchange.h
	rm -f $(DESTDIR)$(includedir)/gen_ndr/property.h

libmapi-uninstallscript:
	rm -f $(DESTDIR)$(datadir)/setup/oc_profiles*

libmapi.$(SHLIBEXT).$(PACKAGE_VERSION): 		\
	libmapi/IABContainer.po				\
	libmapi/IProfAdmin.po				\
	libmapi/IMAPIContainer.po			\
	libmapi/IMAPIFolder.po				\
	libmapi/IMAPIProp.po				\
	libmapi/IMAPISession.po				\
	libmapi/IMAPISupport.po				\
	libmapi/IStream.po				\
	libmapi/IMAPITable.po				\
	libmapi/IMessage.po				\
	libmapi/IMsgStore.po				\
	libmapi/IStoreFolder.po				\
	libmapi/IUnknown.po				\
	libmapi/IMSProvider.po				\
	libmapi/IXPLogon.po				\
	libmapi/FXICS.po				\
	libmapi/utils.po 				\
	libmapi/property.po				\
	libmapi/cdo_mapi.po 				\
	libmapi/lzfu.po					\
	libmapi/mapi_object.po				\
	libmapi/mapi_id_array.po			\
	libmapi/mapitags.po				\
	libmapi/mapidump.po				\
	libmapi/mapicode.po 				\
	libmapi/mapi_nameid.po				\
	libmapi/emsmdb.po				\
	libmapi/nspi.po 				\
	libmapi/simple_mapi.po				\
	libmapi/util/lcid.po 				\
	libmapi/util/codepage.po			\
	libmapi/x500.po 				\
	ndr_mapi.po					\
	gen_ndr/ndr_exchange.po				\
	gen_ndr/ndr_exchange_c.po			\
	gen_ndr/ndr_property.po				\
	libmapi/socket/interface.po			\
	libmapi/socket/netif.po				\
	libmapi/utf8_convert.yy.po
	@echo "Linking $@"
	@$(CC) $(DSOOPT) -Wl,-soname,libmapi.$(SHLIBEXT).$(LIBMAPI_SO_VERSION) -o $@ $^ $(LIBS)


libmapi.$(SHLIBEXT).$(LIBMAPI_SO_VERSION): libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	ln -fs $< $@

libmapi/version.h: VERSION
	@./script/mkversion.sh 	VERSION libmapi/version.h $(PACKAGE_VERSION) $(top_builddir)/

libmapi/utf8_convert.yy.c: 	libmapi/utf8_convert.l
	@echo "Generating $@"
	@$(FLEX) -t $< > $@

# Avoid warnings:
libmapi/utf8_convert.yy.o: CFLAGS=

libmapi/proto.h libmapi/proto_private.h:		\
	libmapi/nspi.c					\
	libmapi/emsmdb.c				\
	libmapi/cdo_mapi.c				\
	libmapi/simple_mapi.c				\
	libmapi/mapitags.c				\
	libmapi/mapicode.c				\
	libmapi/mapidump.c				\
	libmapi/mapi_object.c				\
	libmapi/mapi_id_array.c				\
	libmapi/mapi_nameid.c				\
	libmapi/property.c				\
	libmapi/IABContainer.c				\
	libmapi/IProfAdmin.c				\
	libmapi/IMAPIContainer.c			\
	libmapi/IMAPIFolder.c 				\
	libmapi/IMAPIProp.c 				\
	libmapi/IMAPISession.c				\
	libmapi/IMAPISupport.c				\
	libmapi/IMAPITable.c 				\
	libmapi/IMSProvider.c				\
	libmapi/IMessage.c 				\
	libmapi/IMsgStore.c 				\
	libmapi/IStoreFolder.c				\
	libmapi/IUnknown.c 				\
	libmapi/IStream.c				\
	libmapi/IXPLogon.c				\
	libmapi/FXICS.c					\
	libmapi/x500.c 					\
	libmapi/lzfu.c					\
	libmapi/utils.c 				\
	libmapi/util/lcid.c 				\
	libmapi/util/codepage.c 			\
	libmapi/socket/interface.c			\
	libmapi/socket/netif.c		
	@echo "Generating $@"
	@./script/mkproto.pl --private=libmapi/proto_private.h --public=libmapi/proto.h $^

libmapi/emsmdb.c: libmapi/emsmdb.h gen_ndr/ndr_exchange_c.h

libmapi/mapitags.c libmapi/mapicode.c mapitags_enum.h mapicodes_enum.h: \
	libmapi/conf/mapi-properties 					\
	libmapi/conf/mapi-codes 					\
	libmapi/conf/mapi-named-properties 				\
	libmapi/conf/mparse.pl
	@./libmapi/conf/build.sh

#################################################################
# libmapi++ compilation rules
#################################################################

libmapixx: libmapi libmapixx-tests libmapixx-examples

libmapixx-installpc:

libmapixx-clean: libmapixx-tests-clean

libmapixx-install: libmapixx-installheader

libmapixx-uninstall: libmapixx-uninstallheader

libmapixx-installheader:
	@echo "[*] install: libmapi++ headers"
	$(INSTALL) -d $(DESTDIR)$(includedir)/libmapi++
	$(INSTALL) -m 0644 libmapi++/attachment.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/clibmapi.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/folder.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/libmapi++.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/mapi_exception.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/message.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/message_store.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/object.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/profile.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/property_container.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -m 0644 libmapi++/session.h $(DESTDIR)$(includedir)/libmapi++/
	$(INSTALL) -d $(DESTDIR)$(includedir)/libmapi++/impl
	$(INSTALL) -m 0644 libmapi++/impl/* $(DESTDIR)$(includedir)/libmapi++/impl/

libmapixx-uninstallheader:
	rm -rf $(DESTDIR)$(includedir)/libmapi++


libmapixx-tests:	libmapixx-test		\
			libmapixx-attach

libmapixx-tests-clean:	libmapixx-test-clean	\
			libmapixx-attach-clean	

libmapixx-test: bin/libmapixx-test

libmapixx-test-clean:
	rm -f bin/libmapixx-test
	rm -f libmapi++/tests/*.o

bin/libmapixx-test:	libmapi++/tests/test.cpp	\
		libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking sample application $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

clean:: libmapixx-test-clean

libmapixx-attach: bin/libmapixx-attach

libmapixx-attach-clean:
	rm -f bin/libmapixx-attach
	rm -f libmapi++/tests/*.o

bin/libmapixx-attach: libmapi++/tests/attach_test.cpp	\
		  libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking sample application $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

clean:: libmapixx-attach-clean


libmapixx-examples: libmapi++/examples/foldertree \
		  libmapi++/examples/messages

libmapixx-foldertree-clean:
	rm -f libmapi++/examples/foldertree
	rm -f libmapi++/examples/*.o

libmapixx-messages-clean:
	rm -f libmapi++/examples/messages
	rm -f libmapi++/examples/*.o

libmapi++/examples/foldertree: libmapi++/examples/foldertree.cpp	\
		  libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking foldertree example application $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

clean:: libmapixx-foldertree-clean

libmapi++/examples/messages: libmapi++/examples/messages.cpp	\
		  libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking messages example application $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

clean:: libmapixx-messages-clean

#################################################################
# libmapiadmin compilation rules
#################################################################

LIBMAPIADMIN_SO_VERSION = 0

libmapiadmin:	libmapiadmin/proto.h				\
		libmapiadmin.$(SHLIBEXT).$(PACKAGE_VERSION)

libmapiadmin-install:	libmapiadmin-installpc		\
			libmapiadmin-installlib		\
			libmapiadmin-installheader

libmapiadmin-uninstall:	libmapiadmin-uninstallpc	\
			libmapiadmin-uninstalllib	\
			libmapiadmin-uninstallheader

libmapiadmin-clean::
	rm -f libmapiadmin/*.o libmapiadmin/*.po
	rm -f libmapiadmin/proto.h
	rm -f libmapiadmin/proto_private.h
	rm -f libmapiadmin.$(SHLIBEXT).$(PACKAGE_VERSION) libmapiadmin.$(SHLIBEXT).$(LIBMAPIADMIN_SO_VERSION) \
		  libmapiadmin.$(SHLIBEXT)

clean:: libmapiadmin-clean

libmapiadmin-distclean::
	rm -f libmapiadmin.pc

distclean:: libmapiadmin-distclean

libmapiadmin-installpc:
	@echo "[*] install: libmapiadmin pc files"
	$(INSTALL) -d $(DESTDIR)$(libdir)/pkgconfig
	$(INSTALL) -m 0644 libmapiadmin.pc $(DESTDIR)$(libdir)/pkgconfig

libmapiadmin-installlib:
	@echo "[*] install: libmapiadmin library"
	$(INSTALL) -d $(DESTDIR)$(libdir)
	$(INSTALL) -m 0755 libmapiadmin.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)
	ln -sf libmapiadmin.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)/libmapiadmin.$(SHLIBEXT)

libmapiadmin-installheader:
	@echo "[*] install: libmapiadmin headers"
	$(INSTALL) -d $(DESTDIR)$(includedir)/libmapiadmin 
	$(INSTALL) -m 0644 libmapiadmin/proto.h $(DESTDIR)$(includedir)/libmapiadmin/
	$(INSTALL) -m 0644 libmapiadmin/libmapiadmin.h $(DESTDIR)$(includedir)/libmapiadmin/

libmapiadmin-uninstallpc:
	rm -f $(DESTDIR)$(libdir)/pkgconfig/libmapiadmin.pc

libmapiadmin-uninstalllib:
	rm -f $(DESTDIR)$(libdir)/libmapiadmin.*

libmapiadmin-uninstallheader:
	rm -rf $(DESTDIR)$(includedir)/libmapiadmin

libmapiadmin.$(SHLIBEXT).$(PACKAGE_VERSION):	\
	libmapiadmin/mapiadmin_user.po		\
	libmapiadmin/mapiadmin.po 		\
	libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) $(DSOOPT) -Wl,-soname,libmapiadmin.$(SHLIBEXT).$(LIBMAPIADMIN_SO_VERSION) -o $@ $^ $(LIBS) $(LIBMAPIADMIN_LIBS) 

libmapiadmin/proto.h libmapiadmin/proto_private.h: 	\
	libmapiadmin/mapiadmin.c 			\
	libmapiadmin/mapiadmin_user.c			
	@echo "Generating $@"
	@./script/mkproto.pl -private=libmapiadmin/proto_private.h --public=libmapiadmin/proto.h $^



#################################################################
# libocpf compilation rules
#################################################################

LIBOCPF_SO_VERSION = 0

libocpf:	libocpf/proto.h				\
		libocpf.$(SHLIBEXT).$(PACKAGE_VERSION)

libocpf-install:	libocpf-installpc	\
			libocpf-installlib	\
			libocpf-installheader

libocpf-uninstall:	libocpf-uninstallpc	\
			libocpf-uninstalllib	\
			libocpf-uninstallheader

libocpf-clean::
	rm -f libocpf/*.o libocpf/*.po
	rm -f libocpf/lex.yy.c
	rm -f libocpf/ocpf.tab.c libocpf/ocpf.tab.h
	rm -f libocpf/proto.h
	rm -f libocpf/proto_private.h
	rm -f libocpf.$(SHLIBEXT).$(PACKAGE_VERSION) libocpf.$(SHLIBEXT).$(LIBOCPF_SO_VERSION) \
		  libocpf.$(SHLIBEXT)

clean:: libocpf-clean

libocpf-distclean::
	rm -f libocpf.pc

distclean:: libocpf-distclean

libocpf-installpc:
	@echo "[*] install: libocpf pc files"
	$(INSTALL) -d $(DESTDIR)$(libdir)/pkgconfig
	$(INSTALL) -m 0644 libocpf.pc $(DESTDIR)$(libdir)/pkgconfig

libocpf-installlib:
	@echo "[*] install: libocpf library"
	$(INSTALL) -d $(DESTDIR)$(libdir)
	$(INSTALL) -m 0755 libocpf.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)
	ln -sf libocpf.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)/libocpf.$(SHLIBEXT)

libocpf-installheader:
	@echo "[*] install: libocpf headers"
	$(INSTALL) -d $(DESTDIR)$(includedir)/libocpf
	$(INSTALL) -m 0644 libocpf/ocpf.h $(DESTDIR)$(includedir)/libocpf/
	$(INSTALL) -m 0644 libocpf/proto.h $(DESTDIR)$(includedir)/libocpf/

libocpf-uninstallpc:
	rm -f $(DESTDIR)$(libdir)/pkgconfig/libocpf.pc

libocpf-uninstalllib:
	rm -f $(DESTDIR)$(libdir)/libocpf.*

libocpf-uninstallheader:
	rm -rf $(DESTDIR)$(includedir)/libocpf

libocpf.$(SHLIBEXT).$(PACKAGE_VERSION):		\
	libocpf/ocpf.tab.po			\
	libocpf/lex.yy.po			\
	libocpf/ocpf_public.po			\
	libocpf/ocpf_dump.po			\
	libocpf/ocpf_api.po			\
	libocpf/ocpf_write.po			\
	libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) $(DSOOPT) -Wl,-soname,libocpf.$(SHLIBEXT).$(LIBOCPF_SO_VERSION) -o $@ $^ $(LIBS)

libocpf.$(SHLIBEXT).$(LIBOCPF_SO_VERSION): libocpf.$(SHLIBEXT).$(PACKAGE_VERSION)
	ln -fs $< $@

libocpf/proto.h:	libocpf/ocpf_public.c	\
			libocpf/ocpf_dump.c	\
			libocpf/ocpf_api.c	\
			libocpf/ocpf_write.c
			@echo "Generating $@"
			@./script/mkproto.pl --private=libocpf/proto_private.h \
			--public=libocpf/proto.h $^

libocpf/lex.yy.c:		libocpf/lex.l
	@echo "Generating $@"
	@$(FLEX) -t $< > $@

libocpf/ocpf.tab.c:	libocpf/ocpf.y
	@echo "Generating $@"
	@$(BISON) -pocpf_yy -d $< -o $@

# Avoid warnings
libocpf/lex.yy.o: CFLAGS=
libocpf/ocpf.tab.o: CFLAGS=



#################################################################
# torture suite compilation rules
#################################################################

torture:	torture/torture_proto.h		\
		torture/openchange.$(SHLIBEXT)

torture-install:
	@echo "[*] install: openchange torture suite"
	$(INSTALL) -d $(DESTDIR)$(TORTURE_MODULESDIR)
	$(INSTALL) -m 0755 torture/openchange.$(SHLIBEXT) $(DESTDIR)$(TORTURE_MODULESDIR)

torture-uninstall:
	rm -f $(DESTDIR)$(TORTURE_MODULESDIR)/openchange.*

torture-clean::
	rm -f torture/*.$(SHLIBEXT)
	rm -f torture/torture_proto.h
	rm -f torture/*.o torture/*.po

clean:: torture-clean

torture/openchange.$(SHLIBEXT):			\
	torture/nspi_profile.po			\
	torture/nspi_resolvenames.po		\
	torture/mapi_restrictions.po		\
	torture/mapi_criteria.po		\
	torture/mapi_copymail.po		\
	torture/mapi_sorttable.po		\
	torture/mapi_bookmark.po		\
	torture/mapi_fetchmail.po		\
	torture/mapi_sendmail.po		\
	torture/mapi_sendmail_html.po		\
	torture/mapi_deletemail.po		\
	torture/mapi_newmail.po			\
	torture/mapi_sendattach.po		\
	torture/mapi_fetchattach.po		\
	torture/mapi_fetchappointment.po	\
	torture/mapi_sendappointment.po		\
	torture/mapi_fetchcontacts.po		\
	torture/mapi_sendcontacts.po		\
	torture/mapi_fetchtasks.po		\
	torture/mapi_sendtasks.po		\
	torture/mapi_common.po			\
	torture/mapi_permissions.po		\
	torture/mapi_createuser.po		\
	torture/exchange_createuser.po		\
	torture/mapi_namedprops.po		\
	torture/mapi_recipient.po		\
	torture/openchange.po			\
	libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $(DSOOPT) $^ -L. $(LIBS)

torture/torture_proto.h: torture/mapi_restrictions.c	\
	torture/mapi_criteria.c		\
	torture/mapi_deletemail.c	\
	torture/mapi_newmail.c		\
	torture/mapi_fetchmail.c	\
	torture/mapi_sendattach.c 	\
	torture/mapi_sorttable.c	\
	torture/mapi_bookmark.c		\
	torture/mapi_copymail.c		\
	torture/mapi_fetchattach.c	\
	torture/mapi_sendmail.c		\
	torture/mapi_sendmail_html.c	\
	torture/nspi_profile.c 		\
	torture/nspi_resolvenames.c	\
	torture/mapi_fetchappointment.c	\
	torture/mapi_sendappointment.c	\
	torture/mapi_fetchcontacts.c	\
	torture/mapi_sendcontacts.c	\
	torture/mapi_fetchtasks.c	\
	torture/mapi_sendtasks.c	\
	torture/mapi_common.c		\
	torture/mapi_permissions.c	\
	torture/mapi_namedprops.c	\
	torture/mapi_recipient.c	\
	torture/mapi_createuser.c	\
	torture/exchange_createuser.c	\
	torture/openchange.c
	@echo "Generating $@"
	@./script/mkproto.pl --private=torture/torture_proto.h --public=torture/torture_proto.h $^



#################################################################
# server and providers compilation rules
#################################################################

server:		providers/providers_proto.h server/dcesrv_proto.h	\
		server/dcesrv_exchange.$(SHLIBEXT)			

server-install: python-install
	$(INSTALL) -m 0755 server/dcesrv_exchange.$(SHLIBEXT) $(DESTDIR)$(SERVER_MODULESDIR)
	$(INSTALL) -d $(DESTDIR)$(datadir)/setup
	$(INSTALL) -m 0644 setup/oc_provision* $(DESTDIR)$(datadir)/setup/

server-uninstall: python-uninstall
	rm -f $(DESTDIR)$(SERVER_MODULESDIR)/dcesrv_exchange.*
	rm -f $(DESTDIR)$(datadir)/setup/oc_provision_configuration.ldif
	rm -f $(DESTDIR)$(datadir)/setup/oc_provision_schema.ldif
	rm -f $(DESTDIR)$(datadir)/setup/oc_provision_schema_modify.ldif

server-clean::
	rm -f providers/*.o providers/*.po
	rm -f server/*.o server/*.po
	rm -f server/dcesrv_proto.h
	rm -f providers/providers_proto.h
	rm -f server/*.$(SHLIBEXT)
	rm -f server/dcesrv_exchange.$(SHLIBEXT)

clean:: server-clean

server/dcesrv_exchange.$(SHLIBEXT): 	providers/emsabp.po 		\
					server/dcesrv_exchange.po	\
					libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $(DSOOPT) $^ -L. $(LIBS)

server/dcesrv_exchange.c: providers/providers_proto.h gen_ndr/ndr_exchange_s.c gen_ndr/ndr_exchange.c

providers/providers_proto.h: providers/emsabp.c
	@echo "Generating $@"
	@./script/mkproto.pl --private=providers/providers_proto.h --public=providers/providers_proto.h $^

server/dcesrv_proto.h: server/dcesrv_exchange.c
	@echo "Generating $@"
	@./script/mkproto.pl --private=server/dcesrv_proto.h --public=server/dcesrv_proto.h $^


#################################################################
# mapiproxy compilation rules
#################################################################
LIBMAPIPROXY_SO_VERSION = 0

.PHONY: mapiproxy

mapiproxy: 	idl 					\
		mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION)	\
		mapiproxy/dcesrv_mapiproxy.$(SHLIBEXT) 	\
		mapiproxy-modules

mapiproxy-install: mapiproxy mapiproxy-modules-install
	$(INSTALL) -d $(DESTDIR)$(SERVER_MODULESDIR)
	$(INSTALL) -m 0755 mapiproxy/dcesrv_mapiproxy.$(SHLIBEXT) $(DESTDIR)$(SERVER_MODULESDIR)
	$(INSTALL) -m 0755 mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)
	ln -sf libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION) $(DESTDIR)$(libdir)/libmapiproxy.$(SHLIBEXT)
	$(INSTALL) -m 0644 mapiproxy/libmapiproxy.h $(DESTDIR)$(includedir)/


mapiproxy-uninstall: mapiproxy-modules-uninstall
	rm -f $(DESTDIR)$(SERVER_MODULESDIR)/dcesrv_mapiproxy.*
	rm -f $(DESTDIR)$(libdir)/libmapiproxy.*
	rm -f $(DESTDIR)$(includedir)/libmapiproxy.h

mapiproxy-clean:: mapiproxy-modules-clean
	rm -f mapiproxy/*.o mapiproxy/*.po
	rm -f mapiproxy/dcesrv_mapiproxy.$(SHLIBEXT)
	rm -f mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION) \
		  mapiproxy/libmapiproxy.$(SHLIBEXT).$(LIBMAPIPROXY_SO_VERSION)

clean:: mapiproxy-clean


mapiproxy/dcesrv_mapiproxy.$(SHLIBEXT): 	mapiproxy/dcesrv_mapiproxy.po		\
						mapiproxy/dcesrv_mapiproxy_nspi.po	\
						mapiproxy/dcesrv_mapiproxy_rfr.po	\
						mapiproxy/dcesrv_mapiproxy_unused.po	\
						ndr_mapi.po				\
						gen_ndr/ndr_exchange.po				

	@echo "Linking $@"
	@$(CC) -o $@ $(DSOOPT) $^ -L. $(LIBS) -Lmapiproxy mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION)

mapiproxy/dcesrv_mapiproxy.c: gen_ndr/ndr_exchange_s.c gen_ndr/ndr_exchange.c

mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION):	mapiproxy/dcesrv_mapiproxy_module.po
	@$(CC) -o $@ $(DSOOPT) -Wl,-soname,libmapiproxy.$(SHLIBEXT).$(LIBMAPIPROXY_SO_VERSION) $^ -L. $(LIBS)

mapiproxy/libmapiproxy.$(SHLIBEXT).$(LIBMAPIPROXY_SO_VERSION): libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION)
	ln -fs $< $@


####################
# mapiproxy modules
####################

mapiproxy-modules:	mapiproxy/modules/mpm_downgrade.$(SHLIBEXT)	\
			mapiproxy/modules/mpm_pack.$(SHLIBEXT)		\
			mapiproxy/modules/mpm_cache.$(SHLIBEXT)		\
			mapiproxy/modules/mpm_dummy.$(SHLIBEXT)		

mapiproxy-modules-install: mapiproxy-modules
	$(INSTALL) -d $(DESTDIR)$(modulesdir)/dcerpc_mapiproxy/
	$(INSTALL) -m 0755 mapiproxy/modules/mpm_downgrade.$(SHLIBEXT) $(DESTDIR)$(modulesdir)/dcerpc_mapiproxy/
	$(INSTALL) -m 0755 mapiproxy/modules/mpm_pack.$(SHLIBEXT) $(DESTDIR)$(modulesdir)/dcerpc_mapiproxy/
	$(INSTALL) -m 0755 mapiproxy/modules/mpm_cache.$(SHLIBEXT) $(DESTDIR)$(modulesdir)/dcerpc_mapiproxy/
	$(INSTALL) -m 0755 mapiproxy/modules/mpm_dummy.$(SHLIBEXT) $(DESTDIR)$(modulesdir)/dcerpc_mapiproxy/

mapiproxy-modules-uninstall:
	rm -rf $(DESTDIR)$(modulesdir)/dcerpc_mapiproxy

mapiproxy-modules-clean::
	rm -f mapiproxy/modules/*.o mapiproxy/modules/*.po
	rm -f mapiproxy/modules/*.so

clean:: mapiproxy-modules-clean

mapiproxy/modules/mpm_downgrade.$(SHLIBEXT): mapiproxy/modules/mpm_downgrade.po
	@echo "Linking $@"
	@$(CC) -o $@ $(DSOOPT) $^ -L. $(LIBS) -Lmapiproxy mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION)

mapiproxy/modules/mpm_pack.$(SHLIBEXT):	mapiproxy/modules/mpm_pack.po	\
					ndr_mapi.po			\
					gen_ndr/ndr_exchange.po
	@echo "Linking $@"
	@$(CC) -o $@ $(DSOOPT) $^ -L. $(LIBS) -Lmapiproxy mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION)

mapiproxy/modules/mpm_cache.$(SHLIBEXT): mapiproxy/modules/mpm_cache.po		\
					 mapiproxy/modules/mpm_cache_ldb.po	\
					 mapiproxy/modules/mpm_cache_stream.po	\
					 ndr_mapi.po				\
					 gen_ndr/ndr_exchange.po
	@echo "Linking $@"
	@$(CC) -o $@ $(DSOOPT) $^ -L. $(LIBS) -Lmapiproxy mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION) libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)

mapiproxy/modules/mpm_dummy.$(SHLIBEXT): mapiproxy/modules/mpm_dummy.po
	@echo "Linking $@"
	@$(CC) -o $@ $(DSOOPT) $^ -L. $(LIBS) -Lmapiproxy mapiproxy/libmapiproxy.$(SHLIBEXT).$(PACKAGE_VERSION)

#################################################################
# Tools compilation rules
#################################################################

###################
# openchangeclient
###################

openchangeclient:	bin/openchangeclient

openchangeclient-install:
	$(INSTALL) -d $(DESTDIR)$(bindir) 
	$(INSTALL) -m 0755 bin/openchangeclient $(DESTDIR)$(bindir)

openchangeclient-uninstall:
	rm -f $(DESTDIR)$(bindir)/openchangeclient

openchangeclient-clean::
	rm -f bin/openchangeclient
	rm -f utils/openchangeclient.o
	rm -f utils/openchange-tools.o	

clean:: openchangeclient-clean

bin/openchangeclient: 	utils/openchangeclient.o			\
			utils/openchange-tools.o			\
			libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)		\
			libocpf.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) -lpopt


##############
# mapiprofile
##############

mapiprofile:		bin/mapiprofile

mapiprofile-install:
	$(INSTALL) -d $(DESTDIR)$(bindir) 
	$(INSTALL) -m 0755 bin/mapiprofile $(DESTDIR)$(bindir)

mapiprofile-uninstall:
	rm -f $(DESTDIR)$(bindir)/mapiprofile

mapiprofile-clean::
	rm -f bin/mapiprofile
	rm -f utils/mapiprofile.o

clean:: mapiprofile-clean

bin/mapiprofile: utils/mapiprofile.o libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) -lpopt


###################
#openchangepfadmin
###################

openchangepfadmin:	bin/openchangepfadmin

openchangepfadmin-install:
	$(INSTALL) -d $(DESTDIR)$(bindir) 
	$(INSTALL) -m 0755 bin/openchangepfadmin $(DESTDIR)$(bindir)

openchangepfadmin-uninstall:
	rm -f $(DESTDIR)$(bindir)/openchangepfadmin

openchangepfadmin-clean::
	rm -f bin/openchangepfadmin
	rm -f utils/openchangepfadmin.o

clean:: openchangepfadmin-clean

bin/openchangepfadmin:	utils/openchangepfadmin.o			\
			libmapi.$(SHLIBEXT).$(PACKAGE_VERSION) 		\
			libmapiadmin.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) $(LIBMAPIADMIN_LIBS) -lpopt			


###################
# exchange2mbox
###################

exchange2mbox:		bin/exchange2mbox

exchange2mbox-install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) -m 0755 bin/exchange2mbox $(DESTDIR)$(bindir)

exchange2mbox-uninstall:
	rm -f $(DESTDIR)$(bindir)/exchange2mbox

exchange2mbox-clean::
	rm -f bin/exchange2mbox
	rm -f utils/exchange2mbox.o
	rm -f utils/openchange-tools.o	

clean:: exchange2mbox-clean

bin/exchange2mbox:	utils/exchange2mbox.o				\
			utils/openchange-tools.o			\
			libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) -lpopt  $(MAGIC_LIBS)


###################
# exchange2ical
###################

exchange2ical:		bin/exchange2ical

exchange2ical-install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) -m 0755 bin/exchange2ical $(DESTDIR)$(bindir)

exchange2ical-uninstall:
	rm -f $(DESTDIR)$(bindir)/exchange2ical

exchange2ical-clean::
	rm -f bin/exchange2ical
	rm -f utils/exchange2ical/exchange2ical.o
	rm -f utils/exchange2ical/exchange2ical_utils.o
	rm -f utils/exchange2ical/exchange2ical_component.o
	rm -f utils/exchange2ical/exchange2ical_property.o
	rm -f utils/openchange-tools.o	

clean:: exchange2ical-clean

bin/exchange2ical:	utils/exchange2ical/exchange2ical.o		\
			utils/exchange2ical/exchange2ical_component.o	\
			utils/exchange2ical/exchange2ical_property.o	\
			utils/exchange2ical/exchange2ical_utils.o	\
			utils/openchange-tools.o			\
			libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) -lpopt


###################
# mapitest
###################

mapitest:	libmapi			\
		utils/mapitest/proto.h 	\
		bin/mapitest

mapitest-install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) -m 0755 bin/mapitest $(DESTDIR)$(bindir)

mapitest-uninstall:
	rm -f $(DESTDIR)$(bindir)/mapitest

mapitest-clean:
	rm -f bin/mapitest
	rm -f utils/mapitest/*.o
	rm -f utils/mapitest/modules/*.o
	rm -f utils/mapitest/proto.h
	rm -f utils/mapitest/mapitest_proto.h

clean:: mapitest-clean

bin/mapitest:	utils/mapitest/mapitest.o			\
		utils/mapitest/mapitest_suite.o			\
		utils/mapitest/mapitest_print.o			\
		utils/mapitest/mapitest_stat.o			\
		utils/mapitest/mapitest_common.o		\
		utils/mapitest/module.o				\
		utils/mapitest/modules/module_oxcstor.o		\
		utils/mapitest/modules/module_oxcfold.o		\
		utils/mapitest/modules/module_oxomsg.o		\
		utils/mapitest/modules/module_oxcmsg.o		\
		utils/mapitest/modules/module_oxcprpt.o		\
		utils/mapitest/modules/module_oxctable.o	\
		utils/mapitest/modules/module_oxorule.o		\
		utils/mapitest/modules/module_oxcfxics.o	\
		utils/mapitest/modules/module_nspi.o		\
		utils/mapitest/modules/module_noserver.o	\
		libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)		
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) -lpopt

utils/mapitest/proto.h:					\
	utils/mapitest/mapitest_suite.c			\
	utils/mapitest/mapitest_print.c			\
	utils/mapitest/mapitest_stat.c			\
	utils/mapitest/mapitest_common.c		\
	utils/mapitest/module.c				\
	utils/mapitest/modules/module_oxcstor.c		\
	utils/mapitest/modules/module_oxcfold.c		\
	utils/mapitest/modules/module_oxomsg.c		\
	utils/mapitest/modules/module_oxcmsg.c		\
	utils/mapitest/modules/module_oxcprpt.c		\
	utils/mapitest/modules/module_oxctable.c	\
	utils/mapitest/modules/module_oxorule.c		\
	utils/mapitest/modules/module_oxcfxics.c	\
	utils/mapitest/modules/module_nspi.c		\
	utils/mapitest/modules/module_noserver.c	
	@echo "Generating $@"
	@./script/mkproto.pl --private=utils/mapitest/mapitest_proto.h --public=utils/mapitest/proto.h $^

#####################
# openchangemapidump
#####################

openchangemapidump:		bin/openchangemapidump

openchangemapidump-install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) -m 0755 bin/openchangemapidump $(DESTDIR)$(bindir)

openchangemapidump-uninstall:
	rm -f bin/openchangemapidump
	rm -f $(DESTDIR)$(bindir)/openchangemapidump

openchangemapidump-clean::
	rm -f bin/openchangemapidump
	rm -f utils/backup/openchangemapidump.o
	rm -f utils/backup/openchangebackup.o

clean:: openchangemapidump-clean

bin/openchangemapidump:	utils/backup/openchangemapidump.o		\
			utils/backup/openchangebackup.o			\
			libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) -lpopt


###############
# schemaIDGUID
###############

schemaIDGUID:		bin/schemaIDGUID

schemaIDGUID-install:
	$(INSTALL) -m 0755 bin/schemaIDGUID $(DESTDIR)$(bindir)

schemaIDGUID-uninstall:
	rm -f $(DESTDIR)$(bindir)/schemaIDGUID

schemaIDGUID-clean::
	rm -f bin/schemaIDGUID
	rm -f utils/schemaIDGUID.o

clean:: schemaIDGUID-clean

bin/schemaIDGUID: utils/schemaIDGUID.o
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS)


##################
# locale_codepage
##################

locale_codepage:	bin/locale_codepage

locale_codepage-install:
	$(INSTALL) -m 0755 bin/locale_codepage $(DESTDIR)$(bindir)

locale_codepage-uninstall:
	rm -f bin/locale_codepage
	rm -f $(DESTDIR)$(bindir)/locale_codepage

locale_codepage-clean::
	rm -f bin/locale_codepage
	rm -f libmapi/tests/locale_codepage.o

clean:: locale_codepage-clean

bin/locale_codepage: libmapi/tests/locale_codepage.o libmapi.$(SHLIBEXT).$(PACKAGE_VERSION)
	@echo "Linking $@"
	@$(CC) -o $@ $^ $(LIBS) -lpopt

###################
# python code
###################

pythonscriptdir = python

PYTHON_MODULES = $(patsubst $(pythonscriptdir)/%,%,$(shell find  $(pythonscriptdir) -name "*.py"))

python-install::
	@echo "Installing Python modules"
	@$(foreach MODULE, $(PYTHON_MODULES), \
		$(INSTALL) -d $(DESTDIR)$(pythondir)/$(dir $(MODULE)); \
		$(INSTALL) -m 0644 $(pythonscriptdir)/$(MODULE) $(DESTDIR)$(pythondir)/$(dir $(MODULE)); \
	)

python-uninstall::
	rm -rf $(DESTDIR)$(pythondir)/openchange

###################
# nagios plugin
###################

nagiosdir = $(libdir)/nagios

installnagios:
	$(INSTALL) -d $(DESTDIR)$(nagiosdir)
	$(INSTALL) -m 0755 script/check_exchange $(DESTDIR)$(nagiosdir)

###################
# libmapi examples
###################
examples:
	cd doc/examples && make && cd ${OLD_PWD}

examples-clean::
	rm -f doc/examples/mapi_sample1
	rm -f doc/examples/fetchappointment
	rm -f doc/examples/fetchmail

clean:: examples-clean

examples-install examples-uninstall:

manpages = \
		doc/man/man1/exchange2mbox.1				\
		doc/man/man1/mapiprofile.1				\
		doc/man/man1/openchangeclient.1				\
		doc/man/man1/openchangepfadmin.1			\
		$(wildcard apidocs/man/man3/*)

installman: doxygen
	@./script/installman.sh $(DESTDIR)$(mandir) $(manpages)


uninstallman:
	@./script/uninstallman.sh $(DESTDIR)$(mandir) $(manpages)

doxygen:	
	@if test ! -d apidocs ; then						\
		echo "Doxify API documentation: HTML and man pages";		\
		mkdir -p apidocs/html;						\
		mkdir -p apidocs/man;						\
		$(DOXYGEN) Doxyfile;						\
		$(DOXYGEN) libmapi/Doxyfile;					\
		$(DOXYGEN) libmapiadmin/Doxyfile;				\
		$(DOXYGEN) libocpf/Doxyfile;					\
		$(DOXYGEN) libmapi++/Doxyfile;					\
		$(DOXYGEN) mapiproxy/Doxyfile;					\
		$(DOXYGEN) utils/mapitest/Doxyfile;				\
		cp -f doc/doxygen/index.html apidocs/html;			\
		cp -f doc/doxygen/pictures/* apidocs/html/overview;		\
		cp -f doc/doxygen/pictures/* apidocs/html/libmapi;		\
		cp -f doc/doxygen/pictures/* apidocs/html/libmapiadmin;		\
		cp -f doc/doxygen/pictures/* apidocs/html/libmapi++;		\
		cp -f doc/doxygen/pictures/* apidocs/html/libocpf;		\
		cp -f doc/doxygen/pictures/* apidocs/html/mapitest;		\
		cp -f doc/doxygen/pictures/* apidocs/html/mapiproxy;		\
		cp -f mapiproxy/documentation/pictures/* apidocs/html/mapiproxy;\
	fi								

etags:
	etags `find $(srcdir) -name "*.[ch]"`

ctags:
	ctags `find $(srcdir) -name "*.[ch]"`

swigperl-all:
	@echo "Creating Perl bindings ..."
	@$(MAKE) -C swig/perl all

swigperl-install:
	@echo "Install Perl bindings ..."
	@$(MAKE) -C swig/perl install

swigperl-uninstall:
	@echo "Uninstall Perl bindings ..."
	@$(MAKE) -C swig/perl uninstall

distclean::
	@$(MAKE) -C swig/perl distclean

clean::
	@echo "Cleaning Perl bindings ..."
	@$(MAKE) -C swig/perl clean

.PRECIOUS: exchange.h gen_ndr/ndr_exchange.h gen_ndr/ndr_exchange.c gen_ndr/ndr_exchange_c.c gen_ndr/ndr_exchange_c.h

test:: check

check:: torture/openchange.$(SHLIBEXT) libmapi.$(SHLIBEXT).$(LIBMAPI_SO_VERSION)
	# FIXME: Set up server
	LD_LIBRARY_PATH=`pwd` $(SMBTORTURE) --load-module torture/openchange.$(SHLIBEXT) ncalrpc: OPENCHANGE
	./bin/mapitest --mapi-calls 

# This should be the last line in the makefile since other distclean rules may 
# need config.mk
distclean::
	rm -f config.mk
