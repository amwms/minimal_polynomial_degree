PROJECT = polynomial_degree

NASM = nasm
NASMFLAGS = -f elf64 -w+all -w+error
OBJS = polynomial_degree_example.o polynomial_degree.o
CC = gcc
CFLAGS = -Wall -Wextra -std=c17 -O2
LDFLAGS =

.PHONY : all clean valgrind

all : $(PROJECT)

$(PROJECT) : $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

%.o : %.asm
	$(NASM) $(NASMFLAGS) $< -o $@

polynomial_degree_example.o : polynomial_degree_example.c
polynomials.o : polynomials.c

clean :
	rm -f $(PROJECT) $(OBJS)

valgrind : $(PROJECT)
	valgrind --error-exitcode=123 --leak-check=full \
	--show-leak-kinds=all --errors-for-leak-kinds=all ./$(PROJECT)