CC      = mpicc
CFLAGS+ = -W -Wall
INSTALL?=install
PREFIX?=/usr/local/

SRCS=mpicat.c
OBJS=$(SRCS:.c=.o)
DEPS=$(OBJS:.o=.d)

.PHONY: all clean
all: mpicat

mpicat: mpicat.o

-include $(DEPS)  # this makes magic happen


install: mpicat
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/bin/
	$(INSTALL) -m 755 mpicat $(DESTDIR)$(PREFIX)/bin/

clean:
	rm -f mpicat
	rm -f $(DEPS) $(OBJS)
