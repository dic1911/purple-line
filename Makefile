CXX = g++
CXXFLAGS = -g -Wall -shared -fPIC \
	-DHAVE_INTTYPES_H -DHAVE_CONFIG_H -DPURPLE_PLUGINS \
	`pkg-config --cflags purple thrift`
THRIFT = thrift

LIBS = `pkg-config --libs purple thrift`

PURPLE_PLUGIN_DIR:=$(shell pkg-config --variable=plugindir purple)
PURPLE_DATA_ROOT_DIR:=$(shell pkg-config --variable=datarootdir purple)

MAIN = libline.so

GEN_SRCS = thrift_line/line_main_constants.cpp thrift_line/line_main_types.cpp \
	thrift_line/TalkService.cpp
REAL_SRCS = pluginmain.cpp linehttptransport.cpp thriftclient.cpp httpclient.cpp \
	purpleline.cpp purpleline_login.cpp purpleline_blist.cpp purpleline_chats.cpp \
	poller.cpp pinverifier.cpp
SRCS += $(GEN_SRCS)
SRCS += $(REAL_SRCS)

OBJS = $(SRCS:.cpp=.o)

all: $(MAIN)

$(MAIN): $(OBJS)
	$(CXX) $(CXXFLAGS) -Wl,-z,defs -o $(MAIN) $(OBJS) $(LIBS)

.cpp.o:
	$(CXX) $(CXXFLAGS) -std=c++11 -c $< -o $@

thrift_line: line_main.thrift
	mkdir -p thrift_line
	$(THRIFT) --gen cpp -out thrift_line line_main.thrift

.PHONY: clean
clean:
	rm -f $(MAIN)
	rm -f *.o
	rm -rf thrift_line

.PHONY: user-install
user-install: all
	install -D $(MAIN) ~/.purple/plugins/$(MAIN)

.PHONY: user-uninstall
user-uninstall:
	rm -f ~/.purple/plugins/$(MAIN)

.PHONY: install
install: all
	install -D $(MAIN) $(DESTDIR)$(PURPLE_PLUGIN_DIR)/$(MAIN)

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PURPLE_PLUGIN_DIR)/$(MAIN)

depend: .depend

.depend: thrift_line $(REAL_SRCS)
	rm -f .depend
	$(CXX) $(CXXFLAGS) -MM $(REAL_SRCS) >>.depend

-include .depend
