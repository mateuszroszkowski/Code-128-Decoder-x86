#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

#define BMP_SIGNATURE 0x4d42

int decode(unsigned char* img);

int main(int argc, char* argv[]) {
    char* buffer = NULL;
    int descriptor;
    int width;
    int height;
    unsigned short bpp;
    size_t  bmp_size;
    short signature;
    int result;


    if(argc != 2) {
        fprintf(stderr, "Incorrect number of arguments.\n");
        return 1;
    } 

    struct stat bmp;
    stat(argv[1], &bmp);

    buffer = (char*)malloc(bmp.st_size);
    if(buffer == NULL) {
        fprintf(stderr, "Cannot allocate memory. Check name of the file.\n");
        return 2;
    }

    descriptor = open(argv[1], O_RDONLY, 0);
    if(descriptor < 0) {
        fprintf(stderr, "Cannot access file.\n");
        free(buffer);
        return 3;
    }

    int mem = read(descriptor, buffer, bmp.st_size);
    if(mem < 0) {
        fprintf(stderr, "File read error.\n");
        free(buffer);
        return 4;
    }

    signature = *(short*)(buffer);
    if(signature != BMP_SIGNATURE) {
        fprintf(stderr, "Not a bitmap.\n");
        free(buffer);
        return 5;
    }

    width = *(int*)(buffer + 18);
    height = *(int*)(buffer + 22);
    bpp =  *(unsigned short*)(buffer + 28);
    bmp_size = *(size_t*)(buffer + 34);
    signature = *(short*)(buffer);
    if(bpp == 24 && width == 600 && height == 50) {
        //fwrite(buffer+58, 1, bmp_size, stdout);
        result = decode(buffer + 54);
    }
    free(buffer);
    close(descriptor);
    return 0;
}