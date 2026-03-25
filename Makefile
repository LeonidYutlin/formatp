BINARY_PATH   := bin
ARTIFACT_PATH := build

all: ensure_directories_exist $(BINARY_PATH)/formatp

run: all
	./$(BINARY_PATH)/formatp

$(BINARY_PATH)/formatp: $(ARTIFACT_PATH)/main.o	$(ARTIFACT_PATH)/formatp.o
	gcc -no-pie $^ -o $@ -lc

$(ARTIFACT_PATH)/main.o: main.c
	gcc -c -Wall -Wextra $< -o $@ -lc 

$(ARTIFACT_PATH)/formatp.o: formatp.s
	nasm -f elf64 -l $(ARTIFACT_PATH)/formatp.lst $< -o $@

.PHONY: ensure_directories_exist clean all run

ensure_directories_exist:
	mkdir -p $(BINARY_PATH) $(ARTIFACT_PATH)

clean:
	rm -f $(ARTIFACT_PATH)/formatp.o $(ARTIFACT_PATH)/main.o $(BINARY_PATH)/formatp 
