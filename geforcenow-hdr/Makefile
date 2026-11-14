CFLAGS ?= -O2 -Wall -Wextra

redirect.so: redirect.c
	$(CC) $(CFLAGS) -shared -fPIC -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -fno-stack-protector -o $@ $<

clean:
	rm -f redirect.so
