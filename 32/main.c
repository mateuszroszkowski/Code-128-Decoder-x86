#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

#define BMP_SIGNATURE 0x4d42

#define SUCCESS         0x00000000
#define NO_BARCODE      0x00000001
#define TOO_WIDE_BAR    0x00000002
#define WRONG_SET       0x00000003
#define WRONG_CHECKSUM  0x00000004
#define WRONG_CODE      0x00000005

int decode(unsigned char* img, int scan_line_no, char* text);
void eval_error(int err);

int main(int argc, char* argv[]) {
    char* buffer = NULL;
    int descriptor;
    int width;
    int height;
    unsigned short bpp;
    size_t  bmp_size;
    short signature;
    int result;
    int line;
    unsigned int data_offset;

    if(argc != 3) {
        fprintf(stderr, "Incorrect number of arguments.\n");
        return 1;
    } 

    struct stat bmp;
    stat(argv[1], &bmp);

    buffer = (char*)malloc(bmp.st_size);
    if(buffer == NULL) {
        fprintf(stderr, "Cannot allocate memory. Check name of the file and/or cli args order.\n");
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
    data_offset = *(unsigned int*)(buffer + 10);
    bmp_size = *(size_t*)(buffer + 34);

    if(bpp == 24 && width == 600 && height == 50) {
        line = atoi(argv[2]);
        if(line >= 0 && line <= 49) {
            printf("Chosen line number:\t%d\n", line);
            char output[100];
            result = decode(buffer + data_offset, line, output);
            if(result == 0) {
                printf("Decoded text:\t\t%s\n", output);
            }
            else {
                eval_error(result);
            }
        }
        else {
            fprintf(stderr, "Line number must fit interval [0;49]\n");
        }
    }
    free(buffer);
    close(descriptor);
    return 0;
}

void eval_error(int err) {
    switch(err) {
        case NO_BARCODE:
            fprintf(stderr, "No barcode found in the bitmap!");
            break;
        case TOO_WIDE_BAR:
            fprintf(stderr, "Width of black bar exceeded limit. No barcode would fit!");
            break;
        case WRONG_SET:
            fprintf(stderr, "Character starting the set B or C detected!");
            break;
        case WRONG_CHECKSUM:
            fprintf(stderr, "Wrong checksum value!");
            break;
        case WRONG_CODE:
            fprintf(stderr, "Unknown character detected!");
            break;
        default:
            fprintf(stderr, "Unknown error detected!");
    }
}