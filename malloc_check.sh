#!/bin/bash

# Find main.c and append the malloc interceptor code
find . -name "main.c" -type f | while read -r file; do
    cat >> "$file" << 'EOL'

#include <dlfcn.h>
#ifndef FAIL_NUM
# define FAIL_NUM 20
#endif
int		cnt = 1;
void	*malloc(size_t st)
{
	if (cnt++ == FAIL_NUM)
		return (NULL);
	void	*(*libc_malloc)(size_t) = (void *(*)(size_t))dlsym(RTLD_NEXT,
				"malloc");
	return (libc_malloc(st));
}
EOL
done

# Find Makefile and add CFLAGS line
MAKEFILE=$(find . -name "Makefile" -type f | awk -F'/' '{print NF-1, $0}' | sort -n | head -1 | cut -d' ' -f2)
if [ -f "$MAKEFILE" ]; then
    echo 'CFLAGS += -DFAIL_NUM=$(FAIL_NUM)' >> "$MAKEFILE"
fi

# Run the test command
echo 'for i in {1..30}; do
    echo "Testing FAIL_NUM=${i}"
    make FAIL_NUM=${i} && ./a.out
done'

